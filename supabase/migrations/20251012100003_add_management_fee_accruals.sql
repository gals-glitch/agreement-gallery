-- Migration: Add management_fee_accruals table for Track B management fees
-- Feature: FEATURE_MGMT_FEE
-- Reversible: Yes (see down migration at bottom)

-- Management fee accruals by period (quarterly or monthly)
CREATE TABLE IF NOT EXISTS public.management_fee_accruals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  agreement_id uuid NOT NULL REFERENCES public.agreements(id) ON DELETE CASCADE,
  calculation_run_id uuid REFERENCES public.calculation_runs(id),
  period_start date NOT NULL,
  period_end date NOT NULL,
  basis_type text NOT NULL DEFAULT 'invested_balance' CHECK (basis_type IN ('invested_balance', 'committed_capital', 'deployed_capital')),
  invested_balance_avg numeric(18,2) NOT NULL CHECK (invested_balance_avg >= 0),
  mgmt_fee_rate_bps integer NOT NULL CHECK (mgmt_fee_rate_bps >= 0), -- e.g., 10, 20, 25 bps
  amount numeric(18,2) NOT NULL CHECK (amount >= 0),
  vat_amount numeric(18,2) DEFAULT 0 CHECK (vat_amount >= 0),
  total_amount numeric(18,2) NOT NULL CHECK (total_amount >= 0),
  notes text,
  created_by uuid NOT NULL REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (agreement_id, period_start, period_end)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_mgmt_fee_accruals_agreement ON public.management_fee_accruals(agreement_id);
CREATE INDEX IF NOT EXISTS idx_mgmt_fee_accruals_period ON public.management_fee_accruals(period_start, period_end);
CREATE INDEX IF NOT EXISTS idx_mgmt_fee_accruals_run ON public.management_fee_accruals(calculation_run_id);

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_management_fee_accruals_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER management_fee_accruals_updated_at
  BEFORE UPDATE ON public.management_fee_accruals
  FOR EACH ROW
  EXECUTE FUNCTION update_management_fee_accruals_updated_at();

-- Validation trigger: total = amount + vat
CREATE OR REPLACE FUNCTION validate_mgmt_fee_totals()
RETURNS TRIGGER AS $$
BEGIN
  IF ABS(NEW.total_amount - (NEW.amount + NEW.vat_amount)) > 0.01 THEN
    RAISE EXCEPTION 'Total amount must equal amount + vat_amount';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER management_fee_accruals_validate_totals
  BEFORE INSERT OR UPDATE ON public.management_fee_accruals
  FOR EACH ROW
  EXECUTE FUNCTION validate_mgmt_fee_totals();

-- Enable RLS
ALTER TABLE public.management_fee_accruals ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Admin and finance can view all management fee accruals"
  ON public.management_fee_accruals FOR SELECT
  USING (
    has_role(auth.uid(), 'admin') OR
    has_role(auth.uid(), 'finance') OR
    has_role(auth.uid(), 'manager')
  );

CREATE POLICY "Users can view accruals for their agreements"
  ON public.management_fee_accruals FOR SELECT
  USING (
    agreement_id IN (
      SELECT id FROM public.agreements
      WHERE introduced_by_party_id IN (
        SELECT id FROM public.parties WHERE created_by = auth.uid()
      )
    )
  );

CREATE POLICY "Admin and finance can create management fee accruals"
  ON public.management_fee_accruals FOR INSERT
  WITH CHECK (
    has_role(auth.uid(), 'admin') OR
    has_role(auth.uid(), 'finance') OR
    has_role(auth.uid(), 'manager')
  );

CREATE POLICY "Admin and finance can update management fee accruals"
  ON public.management_fee_accruals FOR UPDATE
  USING (
    has_role(auth.uid(), 'admin') OR
    has_role(auth.uid(), 'finance') OR
    has_role(auth.uid(), 'manager')
  );

-- Comments for documentation
COMMENT ON TABLE public.management_fee_accruals IS 'Management fee accruals for Track B agreements based on invested balance. Feature: FEATURE_MGMT_FEE';
COMMENT ON COLUMN public.management_fee_accruals.basis_type IS 'Basis: invested_balance (contributions - realizations), committed_capital, or deployed_capital';
COMMENT ON COLUMN public.management_fee_accruals.invested_balance_avg IS 'Average invested balance for the period (Actual/365 calculation)';
COMMENT ON COLUMN public.management_fee_accruals.mgmt_fee_rate_bps IS 'Management fee rate in basis points (e.g., 20 = 0.20%)';

-- ============================================
-- DOWN MIGRATION (Rollback)
-- ============================================
-- To rollback, run:
-- DROP TRIGGER IF EXISTS management_fee_accruals_updated_at ON public.management_fee_accruals;
-- DROP TRIGGER IF EXISTS management_fee_accruals_validate_totals ON public.management_fee_accruals;
-- DROP FUNCTION IF EXISTS update_management_fee_accruals_updated_at();
-- DROP FUNCTION IF EXISTS validate_mgmt_fee_totals();
-- DROP TABLE IF EXISTS public.management_fee_accruals CASCADE;
