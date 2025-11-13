-- 1. AGREEMENTS AS SINGLE SOURCE OF TRUTH

-- A. Version pinning at run time
CREATE TABLE IF NOT EXISTS calc_runs_rules (
  run_id uuid REFERENCES calculation_runs(id) ON DELETE CASCADE,
  rule_id uuid NOT NULL,
  rule_version int NOT NULL DEFAULT 1,
  rule_snapshot jsonb NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  PRIMARY KEY (run_id, rule_id, rule_version)
);

-- Enable RLS
ALTER TABLE calc_runs_rules ENABLE ROW LEVEL SECURITY;

-- RLS policy for calc_runs_rules
CREATE POLICY "Admin/Manager can access calc runs rules" 
ON calc_runs_rules 
FOR ALL 
USING (is_admin_or_manager(auth.uid()));

-- B. Add rule versioning to advanced_commission_rules
ALTER TABLE advanced_commission_rules 
ADD COLUMN IF NOT EXISTS rule_version int NOT NULL DEFAULT 1,
ADD COLUMN IF NOT EXISTS rule_checksum text,
ADD COLUMN IF NOT EXISTS archived_at timestamp with time zone;

-- Create unique constraint for rule_id + rule_version
ALTER TABLE advanced_commission_rules 
DROP CONSTRAINT IF EXISTS unique_rule_version;
ALTER TABLE advanced_commission_rules 
ADD CONSTRAINT unique_rule_version UNIQUE (id, rule_version);

-- C. Add rule_snapshot to advanced_commission_calculations  
ALTER TABLE advanced_commission_calculations
ADD COLUMN IF NOT EXISTS rule_version int,
ADD COLUMN IF NOT EXISTS rule_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS input_ref uuid,
ADD COLUMN IF NOT EXISTS tier_applied_id uuid,
ADD COLUMN IF NOT EXISTS amount_before_cap numeric,
ADD COLUMN IF NOT EXISTS cap_remaining numeric,
ADD COLUMN IF NOT EXISTS actor_id uuid,
ADD COLUMN IF NOT EXISTS started_at timestamp with time zone,
ADD COLUMN IF NOT EXISTS finished_at timestamp with time zone;

-- D. Prevent deleting rules used in runs
CREATE OR REPLACE FUNCTION prevent_delete_used_rules()
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM calc_runs_rules crr
    WHERE crr.rule_id = OLD.id AND crr.rule_version = OLD.rule_version
  ) THEN
    RAISE EXCEPTION 'Cannot delete rule that is referenced by calculation runs';
  END IF;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prevent_delete_used_rules_trigger
  BEFORE DELETE ON advanced_commission_rules
  FOR EACH ROW
  EXECUTE FUNCTION prevent_delete_used_rules();

-- 2. REPLAYABILITY & AUDIT

-- A. Store deterministic inputs & checksums
CREATE TABLE IF NOT EXISTS calc_run_checksums (
  run_id uuid PRIMARY KEY REFERENCES calculation_runs(id) ON DELETE CASCADE,
  summary_checksum text NOT NULL,
  detail_checksum text NOT NULL,
  vat_checksum text NOT NULL,
  audit_checksum text NOT NULL,
  inputs_checksum text NOT NULL,
  created_at timestamp with time zone DEFAULT now()
);

-- Enable RLS
ALTER TABLE calc_run_checksums ENABLE ROW LEVEL SECURITY;

-- RLS policy
CREATE POLICY "Admin/Manager can access calc run checksums" 
ON calc_run_checksums 
FOR ALL 
USING (is_admin_or_manager(auth.uid()));

-- B. Track calculation sources
CREATE TABLE IF NOT EXISTS calc_run_sources (
  run_id uuid REFERENCES calculation_runs(id) ON DELETE CASCADE,
  source_table text NOT NULL,
  source_ids uuid[] NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  PRIMARY KEY (run_id, source_table)
);

-- Enable RLS
ALTER TABLE calc_run_sources ENABLE ROW LEVEL SECURITY;

-- RLS policy
CREATE POLICY "Admin/Manager can access calc run sources" 
ON calc_run_sources 
FOR ALL 
USING (is_admin_or_manager(auth.uid()));

-- 3. EXPORT METADATA TRACKING

-- Track export jobs and metadata
CREATE TABLE IF NOT EXISTS export_jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  run_id uuid REFERENCES calculation_runs(id) ON DELETE CASCADE,
  export_type text NOT NULL, -- 'summary', 'detail', 'vat', 'audit'
  file_name text NOT NULL,
  file_path text,
  checksum text NOT NULL,
  row_count int,
  rounding_diff numeric DEFAULT 0,
  created_by uuid,
  created_at timestamp with time zone DEFAULT now(),
  app_version text,
  metadata jsonb DEFAULT '{}'::jsonb
);

-- Enable RLS
ALTER TABLE export_jobs ENABLE ROW LEVEL SECURITY;

-- RLS policy
CREATE POLICY "Admin/Manager can access export jobs" 
ON export_jobs 
FOR ALL 
USING (is_admin_or_manager(auth.uid()));

-- Function to generate rule checksum
CREATE OR REPLACE FUNCTION generate_rule_checksum(rule_data jsonb)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT encode(sha256(rule_data::text::bytea), 'hex');
$$;

-- Function to create rule version on update
CREATE OR REPLACE FUNCTION create_rule_version()
RETURNS TRIGGER AS $$
BEGIN
  -- If this is an update to an existing rule, increment version
  IF TG_OP = 'UPDATE' AND OLD.id = NEW.id THEN
    NEW.rule_version = OLD.rule_version + 1;
    NEW.updated_at = now();
  END IF;
  
  -- Generate checksum from rule content
  NEW.rule_checksum = generate_rule_checksum(
    jsonb_build_object(
      'rule_type', NEW.rule_type,
      'base_rate', NEW.base_rate,
      'fixed_amount', NEW.fixed_amount,
      'min_amount', NEW.min_amount,
      'max_amount', NEW.max_amount,
      'calculation_basis', NEW.calculation_basis,
      'entity_type', NEW.entity_type,
      'entity_name', NEW.entity_name,
      'fund_name', NEW.fund_name,
      'vat_mode', NEW.vat_mode,
      'vat_rate_table', NEW.vat_rate_table
    )
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add trigger for rule versioning
DROP TRIGGER IF EXISTS rule_versioning_trigger ON advanced_commission_rules;
CREATE TRIGGER rule_versioning_trigger
  BEFORE INSERT OR UPDATE ON advanced_commission_rules
  FOR EACH ROW
  EXECUTE FUNCTION create_rule_version();