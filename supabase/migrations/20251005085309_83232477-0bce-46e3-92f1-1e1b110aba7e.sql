-- 1) Credit applications table (audit which credits netted which fee lines)
CREATE TABLE IF NOT EXISTS credit_applications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  credit_id uuid NOT NULL REFERENCES credits(id) ON DELETE RESTRICT,
  fee_line_id uuid NOT NULL,
  applied_amount numeric NOT NULL CHECK (applied_amount >= 0),
  applied_date timestamptz NOT NULL DEFAULT now(),
  created_by uuid
);

CREATE INDEX IF NOT EXISTS idx_credit_apps_credit ON credit_applications (credit_id);

-- Enable RLS on credit_applications
ALTER TABLE credit_applications ENABLE ROW LEVEL SECURITY;

-- 2) Constraints on agreements
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'chk_agreements_track_key'
  ) THEN
    ALTER TABLE agreements ADD CONSTRAINT chk_agreements_track_key CHECK (track_key IN ('A','B','C'));
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'chk_agreements_vat_mode'
  ) THEN
    ALTER TABLE agreements ADD CONSTRAINT chk_agreements_vat_mode CHECK (vat_mode IN ('included','added'));
  END IF;
END $$;

-- 3) Unique index on fund_vi_tracks (only one active track per key)
CREATE UNIQUE INDEX IF NOT EXISTS u_fund_vi_tracks_active
  ON fund_vi_tracks(track_key) WHERE is_active = true;

-- 4) Performance indexes
CREATE INDEX IF NOT EXISTS idx_fund_vi_tracks_version ON fund_vi_tracks (config_version);
CREATE INDEX IF NOT EXISTS idx_run_records_run ON run_records (calculation_run_id);
CREATE INDEX IF NOT EXISTS idx_distributions_run_period
  ON investor_distributions (calculation_run_id, distribution_date);

-- 5) Period enforcement trigger
CREATE OR REPLACE FUNCTION enforce_distribution_within_run_period()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE ps date; pe date;
BEGIN
  IF NEW.calculation_run_id IS NULL THEN
    RETURN NEW;
  END IF;
  SELECT period_start, period_end INTO ps, pe
    FROM calculation_runs WHERE id = NEW.calculation_run_id;
  IF NEW.distribution_date < ps OR NEW.distribution_date > pe THEN
    RAISE EXCEPTION 'distribution_date % not within [%, %] for run %',
      NEW.distribution_date, ps, pe, NEW.calculation_run_id;
  END IF;
  RETURN NEW;
END$$;

DROP TRIGGER IF EXISTS trg_enforce_dist_period ON investor_distributions;
CREATE TRIGGER trg_enforce_dist_period
BEFORE INSERT OR UPDATE ON investor_distributions
FOR EACH ROW EXECUTE FUNCTION enforce_distribution_within_run_period();

-- 6) Complete RLS policies for all tables
DO $$
BEGIN
  -- fund_vi_tracks policies
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'fund_vi_tracks' AND policyname = 'Finance/Admin can manage tracks'
  ) THEN
    CREATE POLICY "Finance/Admin can manage tracks"
    ON fund_vi_tracks FOR ALL
    USING (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'manager'::app_role));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'fund_vi_tracks' AND policyname = 'Ops can view tracks'
  ) THEN
    CREATE POLICY "Ops can view tracks"
    ON fund_vi_tracks FOR SELECT
    USING (is_admin_or_manager(auth.uid()));
  END IF;

  -- vat_rates policies
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'vat_rates' AND policyname = 'All authenticated can view VAT rates'
  ) THEN
    CREATE POLICY "All authenticated can view VAT rates"
    ON vat_rates FOR SELECT
    USING (auth.uid() IS NOT NULL);
  END IF;

  -- credit_applications policies
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'credit_applications' AND policyname = 'Admin/Manager can access credit applications'
  ) THEN
    CREATE POLICY "Admin/Manager can access credit applications"
    ON credit_applications FOR ALL
    USING (is_admin_or_manager(auth.uid()));
  END IF;
END $$;