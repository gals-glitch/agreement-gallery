-- Migration: Add payout_schedules and payout_splits tables
-- Feature: FEATURE_PAYOUT_SPLITS
-- Reversible: Yes (see down migration at bottom)

-- Time-based installment schedules (e.g., 60% now, 40% at +24 months)
CREATE TABLE IF NOT EXISTS public.payout_schedules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  agreement_id uuid NOT NULL REFERENCES public.agreements(id) ON DELETE CASCADE,
  installment_number integer NOT NULL CHECK (installment_number > 0),
  percent numeric(6,3) NOT NULL CHECK (percent > 0 AND percent <= 100),
  offset_days integer NOT NULL DEFAULT 0 CHECK (offset_days >= 0),
  description text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (agreement_id, installment_number)
);

-- Multi-beneficiary sharing (e.g., sub-agent participation)
CREATE TABLE IF NOT EXISTS public.payout_splits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  agreement_id uuid NOT NULL REFERENCES public.agreements(id) ON DELETE CASCADE,
  beneficiary_party_id uuid NOT NULL REFERENCES public.parties(id),
  share_percent numeric(6,3) NOT NULL CHECK (share_percent > 0 AND share_percent <= 100),
  effective_from date NOT NULL DEFAULT CURRENT_DATE,
  effective_to date,
  split_type text NOT NULL DEFAULT 'proportional' CHECK (split_type IN ('proportional', 'fixed_amount', 'tiered')),
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (effective_to IS NULL OR effective_to >= effective_from)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_payout_schedules_agreement ON public.payout_schedules(agreement_id);
CREATE INDEX IF NOT EXISTS idx_payout_splits_agreement ON public.payout_splits(agreement_id);
CREATE INDEX IF NOT EXISTS idx_payout_splits_beneficiary ON public.payout_splits(beneficiary_party_id);
CREATE INDEX IF NOT EXISTS idx_payout_splits_effective ON public.payout_splits(effective_from, effective_to);

-- Updated_at triggers
CREATE OR REPLACE FUNCTION update_payout_schedules_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER payout_schedules_updated_at
  BEFORE UPDATE ON public.payout_schedules
  FOR EACH ROW
  EXECUTE FUNCTION update_payout_schedules_updated_at();

CREATE OR REPLACE FUNCTION update_payout_splits_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER payout_splits_updated_at
  BEFORE UPDATE ON public.payout_splits
  FOR EACH ROW
  EXECUTE FUNCTION update_payout_splits_updated_at();

-- Validation: sum of payout_schedules.percent must equal 100 for an agreement
CREATE OR REPLACE FUNCTION validate_payout_schedule_total()
RETURNS TRIGGER AS $$
DECLARE
  v_total numeric(6,3);
BEGIN
  SELECT COALESCE(SUM(percent), 0) INTO v_total
  FROM public.payout_schedules
  WHERE agreement_id = COALESCE(NEW.agreement_id, OLD.agreement_id);

  IF v_total != 100.000 THEN
    RAISE WARNING 'Payout schedule installments for agreement % sum to %, not 100%%',
      COALESCE(NEW.agreement_id, OLD.agreement_id), v_total;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER payout_schedules_validate_total
  AFTER INSERT OR UPDATE OR DELETE ON public.payout_schedules
  FOR EACH ROW
  EXECUTE FUNCTION validate_payout_schedule_total();

-- Validation: sum of payout_splits.share_percent should not exceed 100
CREATE OR REPLACE FUNCTION validate_payout_split_total()
RETURNS TRIGGER AS $$
DECLARE
  v_total numeric(6,3);
BEGIN
  SELECT COALESCE(SUM(share_percent), 0) INTO v_total
  FROM public.payout_splits
  WHERE agreement_id = COALESCE(NEW.agreement_id, OLD.agreement_id)
    AND (
      (NEW.effective_from BETWEEN effective_from AND COALESCE(effective_to, '9999-12-31'))
      OR
      (COALESCE(NEW.effective_to, '9999-12-31') BETWEEN effective_from AND COALESCE(effective_to, '9999-12-31'))
    );

  IF v_total > 100.000 THEN
    RAISE EXCEPTION 'Payout splits for agreement % exceed 100%% for overlapping periods',
      COALESCE(NEW.agreement_id, OLD.agreement_id);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER payout_splits_validate_total
  BEFORE INSERT OR UPDATE ON public.payout_splits
  FOR EACH ROW
  EXECUTE FUNCTION validate_payout_split_total();

-- Enable RLS
ALTER TABLE public.payout_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payout_splits ENABLE ROW LEVEL SECURITY;

-- RLS Policies for payout_schedules
CREATE POLICY "Users can view payout schedules for their agreements"
  ON public.payout_schedules FOR SELECT
  USING (
    agreement_id IN (SELECT id FROM public.agreements) OR
    is_admin_or_manager(auth.uid())
  );

CREATE POLICY "Admin and finance can manage payout schedules"
  ON public.payout_schedules FOR ALL
  USING (is_admin_or_manager(auth.uid()) OR has_role(auth.uid(), 'finance'))
  WITH CHECK (is_admin_or_manager(auth.uid()) OR has_role(auth.uid(), 'finance'));

-- RLS Policies for payout_splits
CREATE POLICY "Users can view payout splits for their agreements"
  ON public.payout_splits FOR SELECT
  USING (
    agreement_id IN (SELECT id FROM public.agreements) OR
    beneficiary_party_id IN (SELECT id FROM public.parties WHERE created_by = auth.uid()) OR
    is_admin_or_manager(auth.uid())
  );

CREATE POLICY "Admin and finance can manage payout splits"
  ON public.payout_splits FOR ALL
  USING (is_admin_or_manager(auth.uid()) OR has_role(auth.uid(), 'finance'))
  WITH CHECK (is_admin_or_manager(auth.uid()) OR has_role(auth.uid(), 'finance'));

-- Comments for documentation
COMMENT ON TABLE public.payout_schedules IS 'Time-based payout installments for agreements (e.g., 60% now, 40% at +24m). Feature: FEATURE_PAYOUT_SPLITS';
COMMENT ON TABLE public.payout_splits IS 'Multi-beneficiary payout sharing for agreements (e.g., sub-agent participation). Feature: FEATURE_PAYOUT_SPLITS';
COMMENT ON COLUMN public.payout_schedules.percent IS 'Percentage of total fee for this installment (must sum to 100 across agreement)';
COMMENT ON COLUMN public.payout_schedules.offset_days IS 'Days after distribution_date to pay this installment (0 = immediate)';
COMMENT ON COLUMN public.payout_splits.share_percent IS 'Percentage share for this beneficiary (must not exceed 100 for overlapping periods)';
COMMENT ON COLUMN public.payout_splits.split_type IS 'Split type: proportional (% of fee), fixed_amount, or tiered';

-- ============================================
-- DOWN MIGRATION (Rollback)
-- ============================================
-- To rollback, run:
-- DROP TRIGGER IF EXISTS payout_schedules_updated_at ON public.payout_schedules;
-- DROP TRIGGER IF EXISTS payout_schedules_validate_total ON public.payout_schedules;
-- DROP TRIGGER IF EXISTS payout_splits_updated_at ON public.payout_splits;
-- DROP TRIGGER IF EXISTS payout_splits_validate_total ON public.payout_splits;
-- DROP FUNCTION IF EXISTS update_payout_schedules_updated_at();
-- DROP FUNCTION IF EXISTS update_payout_splits_updated_at();
-- DROP FUNCTION IF EXISTS validate_payout_schedule_total();
-- DROP FUNCTION IF EXISTS validate_payout_split_total();
-- DROP TABLE IF EXISTS public.payout_splits CASCADE;
-- DROP TABLE IF EXISTS public.payout_schedules CASCADE;
