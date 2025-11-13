-- Create enhanced calculation engine tables for M2

-- Import job tracking with detailed progress
ALTER TABLE excel_import_jobs ADD COLUMN IF NOT EXISTS import_type TEXT DEFAULT 'contributions';
ALTER TABLE excel_import_jobs ADD COLUMN IF NOT EXISTS mapping_template_id UUID;
ALTER TABLE excel_import_jobs ADD COLUMN IF NOT EXISTS auto_run_calculation BOOLEAN DEFAULT false;
ALTER TABLE excel_import_jobs ADD COLUMN IF NOT EXISTS business_validation_errors JSONB DEFAULT '[]'::jsonb;
ALTER TABLE excel_import_jobs ADD COLUMN IF NOT EXISTS duplicate_strategy TEXT DEFAULT 'reject';

-- Mapping templates for reusable column configurations
CREATE TABLE IF NOT EXISTS import_mapping_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  import_type TEXT NOT NULL,
  column_mappings JSONB NOT NULL, -- {excel_column: field_name}
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_default BOOLEAN DEFAULT false
);

-- Enhanced calculation runs with status tracking
ALTER TABLE calculation_runs ADD COLUMN IF NOT EXISTS scope_type TEXT DEFAULT 'full';
ALTER TABLE calculation_runs ADD COLUMN IF NOT EXISTS scope_filters JSONB DEFAULT '{}'::jsonb;
ALTER TABLE calculation_runs ADD COLUMN IF NOT EXISTS run_type TEXT DEFAULT 'manual';
ALTER TABLE calculation_runs ADD COLUMN IF NOT EXISTS is_incremental BOOLEAN DEFAULT true;
ALTER TABLE calculation_runs ADD COLUMN IF NOT EXISTS started_by UUID REFERENCES auth.users(id);
ALTER TABLE calculation_runs ADD COLUMN IF NOT EXISTS completed_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE calculation_runs ADD COLUMN IF NOT EXISTS error_message TEXT;
ALTER TABLE calculation_runs ADD COLUMN IF NOT EXISTS progress_percentage INTEGER DEFAULT 0;
ALTER TABLE calculation_runs ADD COLUMN IF NOT EXISTS estimated_completion TIMESTAMP WITH TIME ZONE;

-- Rule versioning for audit trail
CREATE TABLE IF NOT EXISTS rule_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rule_id UUID NOT NULL REFERENCES advanced_commission_rules(id),
  version_number TEXT NOT NULL, -- semantic versioning like "1.2.3"
  rule_snapshot JSONB NOT NULL, -- complete rule state at this version
  effective_from TIMESTAMP WITH TIME ZONE NOT NULL,
  effective_to TIMESTAMP WITH TIME ZONE,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  checksum TEXT NOT NULL -- for integrity verification
);

-- Detailed calculation step traces for audit
CREATE TABLE IF NOT EXISTS calculation_step_traces (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  calculation_id UUID NOT NULL REFERENCES advanced_commission_calculations(id),
  step_order INTEGER NOT NULL,
  step_type TEXT NOT NULL, -- 'base', 'tier_selection', 'rate_application', 'cap_check', 'vat_calculation'
  input_values JSONB NOT NULL,
  output_values JSONB NOT NULL,
  rule_version_id UUID REFERENCES rule_versions(id),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Import staging area for validation before commit
CREATE TABLE IF NOT EXISTS import_staging (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  import_job_id UUID NOT NULL REFERENCES excel_import_jobs(id),
  row_number INTEGER NOT NULL,
  mapped_data JSONB NOT NULL, -- standardized field names
  raw_data JSONB NOT NULL, -- original Excel row
  validation_status TEXT DEFAULT 'pending', -- pending, valid, invalid, warning
  validation_errors JSONB DEFAULT '[]'::jsonb,
  is_duplicate BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- VAT rate configuration by jurisdiction and date
CREATE TABLE IF NOT EXISTS vat_rates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  country_code TEXT NOT NULL, -- ISO 3166-1 alpha-2
  rate DECIMAL(5,4) NOT NULL, -- supports up to 99.9999%
  effective_from DATE NOT NULL,
  effective_to DATE,
  is_default BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id)
);

-- Insert default VAT rates
INSERT INTO vat_rates (country_code, rate, effective_from, is_default) VALUES
('IL', 0.17, '2000-01-01', true),
('US', 0.00, '2000-01-01', true)
ON CONFLICT DO NOTHING;

-- Export templates configuration
CREATE TABLE IF NOT EXISTS export_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  template_type TEXT NOT NULL, -- 'summary', 'detail', 'vat', 'audit'
  column_definitions JSONB NOT NULL,
  filters_schema JSONB DEFAULT '{}'::jsonb,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on new tables
ALTER TABLE import_mapping_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE rule_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE calculation_step_traces ENABLE ROW LEVEL SECURITY;
ALTER TABLE import_staging ENABLE ROW LEVEL SECURITY;
ALTER TABLE vat_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE export_templates ENABLE ROW LEVEL SECURITY;

-- RLS Policies for new tables
CREATE POLICY "Admin/Finance can access mapping templates" ON import_mapping_templates
  FOR ALL USING (is_admin_or_manager(auth.uid()));

CREATE POLICY "Admin/Finance can access rule versions" ON rule_versions
  FOR ALL USING (is_admin_or_manager(auth.uid()));

CREATE POLICY "Admin/Finance can access calculation traces" ON calculation_step_traces
  FOR ALL USING (is_admin_or_manager(auth.uid()));

CREATE POLICY "Users can access their import staging" ON import_staging
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM excel_import_jobs 
      WHERE id = import_staging.import_job_id 
      AND user_id = auth.uid()
    ) OR is_admin_or_manager(auth.uid())
  );

CREATE POLICY "Admin/Finance can access VAT rates" ON vat_rates
  FOR ALL USING (is_admin_or_manager(auth.uid()));

CREATE POLICY "Admin/Finance can access export templates" ON export_templates
  FOR ALL USING (is_admin_or_manager(auth.uid()));

-- Update triggers for timestamps
CREATE TRIGGER update_import_mapping_templates_updated_at
  BEFORE UPDATE ON import_mapping_templates
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_export_templates_updated_at
  BEFORE UPDATE ON export_templates
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Indexes for performance
CREATE INDEX idx_rule_versions_rule_id ON rule_versions(rule_id);
CREATE INDEX idx_rule_versions_effective_dates ON rule_versions(effective_from, effective_to);
CREATE INDEX idx_calculation_step_traces_calculation_id ON calculation_step_traces(calculation_id);
CREATE INDEX idx_import_staging_job_status ON import_staging(import_job_id, validation_status);
CREATE INDEX idx_vat_rates_country_date ON vat_rates(country_code, effective_from);

-- Function to get applicable VAT rate
CREATE OR REPLACE FUNCTION get_vat_rate(country TEXT, calculation_date DATE)
RETURNS DECIMAL(5,4)
LANGUAGE sql
STABLE
AS $$
  SELECT rate 
  FROM vat_rates 
  WHERE country_code = country 
    AND effective_from <= calculation_date 
    AND (effective_to IS NULL OR effective_to >= calculation_date)
  ORDER BY effective_from DESC 
  LIMIT 1;
$$;