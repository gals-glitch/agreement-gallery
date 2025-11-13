-- Migration: Add invoices, invoice_lines, payments, invoice_counters tables
-- Feature: FEATURE_INVOICES
-- Reversible: Yes (see down migration at bottom)

-- Invoice counters for sequential numbering (per year)
CREATE TABLE IF NOT EXISTS public.invoice_counters (
  year integer PRIMARY KEY,
  sequence integer NOT NULL DEFAULT 0,
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Main invoices table
CREATE TABLE IF NOT EXISTS public.invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_no text UNIQUE NOT NULL,
  party_id uuid NOT NULL REFERENCES public.parties(id),
  run_id uuid NOT NULL REFERENCES public.calculation_runs(id),
  issue_date date NOT NULL DEFAULT CURRENT_DATE,
  due_date date NOT NULL,
  currency text NOT NULL DEFAULT 'USD',
  net_amount numeric(18,2) NOT NULL CHECK (net_amount >= 0),
  vat_amount numeric(18,2) NOT NULL CHECK (vat_amount >= 0),
  gross_amount numeric(18,2) NOT NULL CHECK (gross_amount >= 0),
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'paid', 'void', 'overdue')),
  pdf_url text,
  notes text,
  created_by uuid NOT NULL REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  sent_at timestamptz,
  paid_at timestamptz
);

-- Invoice line items
CREATE TABLE IF NOT EXISTS public.invoice_lines (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id uuid NOT NULL REFERENCES public.invoices(id) ON DELETE CASCADE,
  description text NOT NULL,
  fee_type text, -- 'upfront', 'deferred', 'management_fee', 'success_fee'
  investor_name text,
  fund_name text,
  deal_name text,
  scope text, -- 'FUND' or 'DEAL'
  net_amount numeric(18,2) NOT NULL CHECK (net_amount >= 0),
  vat_amount numeric(18,2) NOT NULL CHECK (vat_amount >= 0),
  gross_amount numeric(18,2) NOT NULL CHECK (gross_amount >= 0),
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Payment records
CREATE TABLE IF NOT EXISTS public.payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id uuid NOT NULL REFERENCES public.invoices(id) ON DELETE CASCADE,
  payment_date date NOT NULL DEFAULT CURRENT_DATE,
  reference text,
  amount numeric(18,2) NOT NULL CHECK (amount > 0),
  payment_method text, -- 'wire', 'check', 'ach', etc.
  notes text,
  created_by uuid NOT NULL REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_invoices_party_id ON public.invoices(party_id);
CREATE INDEX IF NOT EXISTS idx_invoices_run_id ON public.invoices(run_id);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON public.invoices(status);
CREATE INDEX IF NOT EXISTS idx_invoices_issue_date ON public.invoices(issue_date DESC);
CREATE INDEX IF NOT EXISTS idx_invoices_due_date ON public.invoices(due_date) WHERE status IN ('sent', 'overdue');

CREATE INDEX IF NOT EXISTS idx_invoice_lines_invoice_id ON public.invoice_lines(invoice_id);
CREATE INDEX IF NOT EXISTS idx_payments_invoice_id ON public.payments(invoice_id);
CREATE INDEX IF NOT EXISTS idx_payments_payment_date ON public.payments(payment_date DESC);

-- Constraint: gross = net + vat (enforced at application level, validated here)
ALTER TABLE public.invoices ADD CONSTRAINT invoices_gross_calc_check
  CHECK (ABS(gross_amount - (net_amount + vat_amount)) < 0.01);

ALTER TABLE public.invoice_lines ADD CONSTRAINT invoice_lines_gross_calc_check
  CHECK (ABS(gross_amount - (net_amount + vat_amount)) < 0.01);

-- Updated_at triggers
CREATE OR REPLACE FUNCTION update_invoices_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER invoices_updated_at
  BEFORE UPDATE ON public.invoices
  FOR EACH ROW
  EXECUTE FUNCTION update_invoices_updated_at();

CREATE OR REPLACE FUNCTION update_invoice_counters_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER invoice_counters_updated_at
  BEFORE UPDATE ON public.invoice_counters
  FOR EACH ROW
  EXECUTE FUNCTION update_invoice_counters_updated_at();

-- Function to generate next invoice number
CREATE OR REPLACE FUNCTION generate_invoice_number()
RETURNS text AS $$
DECLARE
  current_year integer;
  next_seq integer;
  invoice_no text;
BEGIN
  current_year := EXTRACT(YEAR FROM CURRENT_DATE);

  -- Upsert counter
  INSERT INTO public.invoice_counters (year, sequence)
  VALUES (current_year, 1)
  ON CONFLICT (year) DO UPDATE
    SET sequence = public.invoice_counters.sequence + 1
  RETURNING sequence INTO next_seq;

  -- Format: INV-2025-0001
  invoice_no := 'INV-' || current_year || '-' || LPAD(next_seq::text, 4, '0');

  RETURN invoice_no;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable RLS
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoice_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoice_counters ENABLE ROW LEVEL SECURITY;

-- RLS Policies for invoices
CREATE POLICY "Admin and finance can view all invoices"
  ON public.invoices FOR SELECT
  USING (
    has_role(auth.uid(), 'admin') OR
    has_role(auth.uid(), 'finance') OR
    has_role(auth.uid(), 'manager')
  );

CREATE POLICY "Parties can view their own invoices"
  ON public.invoices FOR SELECT
  USING (
    party_id IN (
      SELECT id FROM public.parties WHERE created_by = auth.uid()
    )
  );

CREATE POLICY "Admin and finance can insert invoices"
  ON public.invoices FOR INSERT
  WITH CHECK (
    has_role(auth.uid(), 'admin') OR
    has_role(auth.uid(), 'finance') OR
    has_role(auth.uid(), 'manager')
  );

CREATE POLICY "Admin and finance can update invoices"
  ON public.invoices FOR UPDATE
  USING (
    has_role(auth.uid(), 'admin') OR
    has_role(auth.uid(), 'finance') OR
    has_role(auth.uid(), 'manager')
  );

-- RLS Policies for invoice_lines
CREATE POLICY "Invoice lines inherit invoice policies for select"
  ON public.invoice_lines FOR SELECT
  USING (
    invoice_id IN (SELECT id FROM public.invoices)
  );

CREATE POLICY "Admin and finance can insert invoice lines"
  ON public.invoice_lines FOR INSERT
  WITH CHECK (
    has_role(auth.uid(), 'admin') OR
    has_role(auth.uid(), 'finance') OR
    has_role(auth.uid(), 'manager')
  );

-- RLS Policies for payments
CREATE POLICY "Payments inherit invoice policies for select"
  ON public.payments FOR SELECT
  USING (
    invoice_id IN (SELECT id FROM public.invoices)
  );

CREATE POLICY "Admin and finance can insert payments"
  ON public.payments FOR INSERT
  WITH CHECK (
    has_role(auth.uid(), 'admin') OR
    has_role(auth.uid(), 'finance') OR
    has_role(auth.uid(), 'manager')
  );

-- RLS for invoice_counters (internal use only)
CREATE POLICY "Only system can access invoice counters"
  ON public.invoice_counters FOR ALL
  USING (false)
  WITH CHECK (false);

-- Comments for documentation
COMMENT ON TABLE public.invoices IS 'Invoice records for approved calculation runs. Feature: FEATURE_INVOICES';
COMMENT ON TABLE public.invoice_lines IS 'Line items for invoices, linked to fee calculations';
COMMENT ON TABLE public.payments IS 'Payment records against invoices';
COMMENT ON TABLE public.invoice_counters IS 'Sequential invoice numbering per year';
COMMENT ON FUNCTION generate_invoice_number() IS 'Generates next invoice number in format INV-YYYY-NNNN';

-- ============================================
-- DOWN MIGRATION (Rollback)
-- ============================================
-- To rollback, run:
-- DROP TRIGGER IF EXISTS invoices_updated_at ON public.invoices;
-- DROP TRIGGER IF EXISTS invoice_counters_updated_at ON public.invoice_counters;
-- DROP FUNCTION IF EXISTS update_invoices_updated_at();
-- DROP FUNCTION IF EXISTS update_invoice_counters_updated_at();
-- DROP FUNCTION IF EXISTS generate_invoice_number();
-- DROP TABLE IF EXISTS public.payments CASCADE;
-- DROP TABLE IF EXISTS public.invoice_lines CASCADE;
-- DROP TABLE IF EXISTS public.invoices CASCADE;
-- DROP TABLE IF EXISTS public.invoice_counters CASCADE;
