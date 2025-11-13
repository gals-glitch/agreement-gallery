-- Migration: Add success_fee_events and success_fee_postings tables
-- Feature: FEATURE_SUCCESS_FEE
-- Reversible: Yes (see down migration at bottom)

-- Success fee events posted by Finance
CREATE TABLE IF NOT EXISTS public.success_fee_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  fund_id uuid NOT NULL REFERENCES public.parties(id), -- Using parties table for funds
  deal_id uuid REFERENCES public.deals(id),
  event_date date NOT NULL,
  event_type text NOT NULL CHECK (event_type IN ('realization', 'promote_distribution', 'carry_payment')),
  currency text NOT NULL DEFAULT 'USD',
  buligo_success_fee_amount numeric(18,2) NOT NULL CHECK (buligo_success_fee_amount >= 0),
  realization_amount numeric(18,2), -- Optional: underlying deal realization
  notes text,
  source_batch_id text, -- For tracking bulk imports
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'posted', 'cancelled')),
  posted_at timestamptz,
  posted_by uuid REFERENCES auth.users(id),
  created_by uuid NOT NULL REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Link events to generated fee calculations (audit trail)
CREATE TABLE IF NOT EXISTS public.success_fee_postings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL REFERENCES public.success_fee_events(id) ON DELETE CASCADE,
  calculation_run_id uuid NOT NULL REFERENCES public.calculation_runs(id),
  fee_lines_count integer NOT NULL DEFAULT 0,
  total_distributed numeric(18,2) NOT NULL CHECK (total_distributed >= 0),
  posted_at timestamptz NOT NULL DEFAULT now(),
  posted_by uuid NOT NULL REFERENCES auth.users(id),
  UNIQUE(event_id, calculation_run_id) -- Prevent duplicate postings
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_success_fee_events_fund_id ON public.success_fee_events(fund_id);
CREATE INDEX IF NOT EXISTS idx_success_fee_events_deal_id ON public.success_fee_events(deal_id);
CREATE INDEX IF NOT EXISTS idx_success_fee_events_event_date ON public.success_fee_events(event_date DESC);
CREATE INDEX IF NOT EXISTS idx_success_fee_events_status ON public.success_fee_events(status);
CREATE INDEX IF NOT EXISTS idx_success_fee_events_type ON public.success_fee_events(event_type);

CREATE INDEX IF NOT EXISTS idx_success_fee_postings_event_id ON public.success_fee_postings(event_id);
CREATE INDEX IF NOT EXISTS idx_success_fee_postings_run_id ON public.success_fee_postings(calculation_run_id);

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_success_fee_events_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER success_fee_events_updated_at
  BEFORE UPDATE ON public.success_fee_events
  FOR EACH ROW
  EXECUTE FUNCTION update_success_fee_events_updated_at();

-- Trigger to update status when posted
CREATE OR REPLACE FUNCTION mark_success_fee_event_posted()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.success_fee_events
  SET
    status = 'posted',
    posted_at = NEW.posted_at,
    posted_by = NEW.posted_by
  WHERE id = NEW.event_id AND status = 'pending';

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER success_fee_postings_mark_posted
  AFTER INSERT ON public.success_fee_postings
  FOR EACH ROW
  EXECUTE FUNCTION mark_success_fee_event_posted();

-- Enable RLS
ALTER TABLE public.success_fee_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.success_fee_postings ENABLE ROW LEVEL SECURITY;

-- RLS Policies for success_fee_events
CREATE POLICY "Admin and finance can view all success fee events"
  ON public.success_fee_events FOR SELECT
  USING (
    has_role(auth.uid(), 'admin') OR
    has_role(auth.uid(), 'finance') OR
    has_role(auth.uid(), 'manager')
  );

CREATE POLICY "Admin and finance can create success fee events"
  ON public.success_fee_events FOR INSERT
  WITH CHECK (
    has_role(auth.uid(), 'admin') OR
    has_role(auth.uid(), 'finance') OR
    has_role(auth.uid(), 'manager')
  );

CREATE POLICY "Admin and finance can update success fee events"
  ON public.success_fee_events FOR UPDATE
  USING (
    has_role(auth.uid(), 'admin') OR
    has_role(auth.uid(), 'finance') OR
    has_role(auth.uid(), 'manager')
  )
  WITH CHECK (
    -- Can only cancel pending events
    (OLD.status = 'pending' AND NEW.status IN ('pending', 'cancelled'))
  );

-- RLS Policies for success_fee_postings
CREATE POLICY "Admin and finance can view all success fee postings"
  ON public.success_fee_postings FOR SELECT
  USING (
    has_role(auth.uid(), 'admin') OR
    has_role(auth.uid(), 'finance') OR
    has_role(auth.uid(), 'manager')
  );

CREATE POLICY "Admin and finance can create success fee postings"
  ON public.success_fee_postings FOR INSERT
  WITH CHECK (
    has_role(auth.uid(), 'admin') OR
    has_role(auth.uid(), 'finance') OR
    has_role(auth.uid(), 'manager')
  );

-- Comments for documentation
COMMENT ON TABLE public.success_fee_events IS 'Success fee realization events for Track B/C calculations. Feature: FEATURE_SUCCESS_FEE';
COMMENT ON TABLE public.success_fee_postings IS 'Audit trail linking success fee events to generated fee calculations';
COMMENT ON COLUMN public.success_fee_events.event_type IS 'Type: realization (exit), promote_distribution (interim), carry_payment (GP carry)';
COMMENT ON COLUMN public.success_fee_events.buligo_success_fee_amount IS 'Total Buligo success fee to distribute to Track B/C parties';
COMMENT ON COLUMN public.success_fee_events.status IS 'Status: pending (awaiting posting), posted (fee lines created), cancelled';

-- ============================================
-- DOWN MIGRATION (Rollback)
-- ============================================
-- To rollback, run:
-- DROP TRIGGER IF EXISTS success_fee_events_updated_at ON public.success_fee_events;
-- DROP TRIGGER IF EXISTS success_fee_postings_mark_posted ON public.success_fee_postings;
-- DROP FUNCTION IF EXISTS update_success_fee_events_updated_at();
-- DROP FUNCTION IF EXISTS mark_success_fee_event_posted();
-- DROP TABLE IF EXISTS public.success_fee_postings CASCADE;
-- DROP TABLE IF EXISTS public.success_fee_events CASCADE;
