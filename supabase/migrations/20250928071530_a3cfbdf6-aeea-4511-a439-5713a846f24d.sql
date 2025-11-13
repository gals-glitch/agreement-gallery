-- 2. REPLAYABILITY & AUDIT - Create remaining tables

-- A. Store deterministic inputs & checksums
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'calc_run_checksums') THEN
    CREATE TABLE calc_run_checksums (
      run_id uuid PRIMARY KEY REFERENCES calculation_runs(id) ON DELETE CASCADE,
      summary_checksum text NOT NULL,
      detail_checksum text NOT NULL,
      vat_checksum text NOT NULL,
      audit_checksum text NOT NULL,
      inputs_checksum text NOT NULL,
      created_at timestamp with time zone DEFAULT now()
    );
    
    ALTER TABLE calc_run_checksums ENABLE ROW LEVEL SECURITY;
    
    CREATE POLICY "Admin/Manager can access calc run checksums" 
    ON calc_run_checksums 
    FOR ALL 
    USING (is_admin_or_manager(auth.uid()));
  END IF;
END $$;

-- B. Track calculation sources
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'calc_run_sources') THEN
    CREATE TABLE calc_run_sources (
      run_id uuid REFERENCES calculation_runs(id) ON DELETE CASCADE,
      source_table text NOT NULL,
      source_ids uuid[] NOT NULL,
      created_at timestamp with time zone DEFAULT now(),
      PRIMARY KEY (run_id, source_table)
    );
    
    ALTER TABLE calc_run_sources ENABLE ROW LEVEL SECURITY;
    
    CREATE POLICY "Admin/Manager can access calc run sources" 
    ON calc_run_sources 
    FOR ALL 
    USING (is_admin_or_manager(auth.uid()));
  END IF;
END $$;

-- 3. EXPORT METADATA TRACKING
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'export_jobs') THEN
    CREATE TABLE export_jobs (
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
    
    ALTER TABLE export_jobs ENABLE ROW LEVEL SECURITY;
    
    CREATE POLICY "Admin/Manager can access export jobs" 
    ON export_jobs 
    FOR ALL 
    USING (is_admin_or_manager(auth.uid()));
  END IF;
END $$;

-- Function to create rule version on update
CREATE OR REPLACE FUNCTION create_rule_version()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
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
$$;

-- Add trigger for rule versioning
DROP TRIGGER IF EXISTS rule_versioning_trigger ON advanced_commission_rules;
CREATE TRIGGER rule_versioning_trigger
  BEFORE INSERT OR UPDATE ON advanced_commission_rules
  FOR EACH ROW
  EXECUTE FUNCTION create_rule_version();