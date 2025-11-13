-- 1. AGREEMENTS AS SINGLE SOURCE OF TRUTH

-- A. Version pinning at run time (skip if exists)
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'calc_runs_rules') THEN
    CREATE TABLE calc_runs_rules (
      run_id uuid REFERENCES calculation_runs(id) ON DELETE CASCADE,
      rule_id uuid NOT NULL,
      rule_version int NOT NULL DEFAULT 1,
      rule_snapshot jsonb NOT NULL,
      created_at timestamp with time zone DEFAULT now(),
      PRIMARY KEY (run_id, rule_id, rule_version)
    );
    
    ALTER TABLE calc_runs_rules ENABLE ROW LEVEL SECURITY;
    
    CREATE POLICY "Admin/Manager can access calc runs rules" 
    ON calc_runs_rules 
    FOR ALL 
    USING (is_admin_or_manager(auth.uid()));
  END IF;
END $$;

-- B. Add rule versioning to advanced_commission_rules
ALTER TABLE advanced_commission_rules 
ADD COLUMN IF NOT EXISTS rule_version int NOT NULL DEFAULT 1,
ADD COLUMN IF NOT EXISTS rule_checksum text,
ADD COLUMN IF NOT EXISTS archived_at timestamp with time zone;

-- Create unique constraint for rule_id + rule_version
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'unique_rule_version') THEN
    ALTER TABLE advanced_commission_rules 
    ADD CONSTRAINT unique_rule_version UNIQUE (id, rule_version);
  END IF;
END $$;

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

DROP TRIGGER IF EXISTS prevent_delete_used_rules_trigger ON advanced_commission_rules;
CREATE TRIGGER prevent_delete_used_rules_trigger
  BEFORE DELETE ON advanced_commission_rules
  FOR EACH ROW
  EXECUTE FUNCTION prevent_delete_used_rules();