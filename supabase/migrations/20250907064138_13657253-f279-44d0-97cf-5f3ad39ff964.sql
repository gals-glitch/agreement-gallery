-- Enhanced schema for advanced calculation engine

-- Drop existing simple commission_rules table to rebuild with advanced features
DROP TABLE IF EXISTS public.commission_calculations;
DROP TABLE IF EXISTS public.commission_rules;

-- Create advanced rule types enum
CREATE TYPE public.rule_type AS ENUM (
  'percentage',
  'fixed_amount', 
  'tiered',
  'hybrid',
  'conditional'
);

CREATE TYPE public.condition_operator AS ENUM (
  'equals',
  'greater_than',
  'less_than',
  'greater_equal',
  'less_equal',
  'between',
  'in',
  'not_in'
);

CREATE TYPE public.calculation_basis AS ENUM (
  'distribution_amount',
  'cumulative_amount',
  'monthly_volume',
  'quarterly_volume',
  'annual_volume'
);

-- Advanced commission rules with complex logic support
CREATE TABLE public.advanced_commission_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  rule_type rule_type NOT NULL,
  entity_type TEXT NOT NULL CHECK (entity_type IN ('distributor', 'referrer', 'partner')),
  entity_name TEXT,
  fund_name TEXT,
  
  -- Basic rule configuration
  base_rate DECIMAL(8,6), -- For percentage rules
  fixed_amount DECIMAL(15,2), -- For fixed amount rules
  min_amount DECIMAL(15,2) DEFAULT 0,
  max_amount DECIMAL(15,2),
  
  -- Calculation basis and timing
  calculation_basis calculation_basis DEFAULT 'distribution_amount',
  effective_from DATE,
  effective_to DATE,
  
  -- Priority for rule conflicts
  priority INTEGER DEFAULT 100,
  
  -- Rule status
  is_active BOOLEAN DEFAULT true,
  requires_approval BOOLEAN DEFAULT false,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_by UUID REFERENCES auth.users(id)
);

-- Tiered commission structures
CREATE TABLE public.commission_tiers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rule_id UUID REFERENCES public.advanced_commission_rules(id) ON DELETE CASCADE,
  tier_order INTEGER NOT NULL,
  min_threshold DECIMAL(15,2) NOT NULL,
  max_threshold DECIMAL(15,2),
  rate DECIMAL(8,6) NOT NULL,
  fixed_amount DECIMAL(15,2),
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Conditional logic for rules
CREATE TABLE public.rule_conditions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rule_id UUID REFERENCES public.advanced_commission_rules(id) ON DELETE CASCADE,
  condition_group INTEGER DEFAULT 1, -- For AND/OR grouping
  field_name TEXT NOT NULL, -- e.g., 'distribution_amount', 'fund_name', 'investor_type'
  operator condition_operator NOT NULL,
  value_text TEXT,
  value_number DECIMAL(15,2),
  value_date DATE,
  value_array TEXT[], -- For IN/NOT_IN operations
  is_required BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Enhanced commission calculations with audit trail
CREATE TABLE public.advanced_commission_calculations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  calculation_run_id UUID REFERENCES public.calculation_runs(id) ON DELETE CASCADE,
  distribution_id UUID REFERENCES public.investor_distributions(id) ON DELETE CASCADE,
  rule_id UUID REFERENCES public.advanced_commission_rules(id),
  
  -- Entity information
  commission_type TEXT NOT NULL CHECK (commission_type IN ('distributor', 'referrer', 'partner')),
  entity_name TEXT NOT NULL,
  
  -- Calculation details
  calculation_basis calculation_basis,
  base_amount DECIMAL(15,2) NOT NULL,
  applied_rate DECIMAL(8,6),
  tier_applied INTEGER, -- Which tier was used (if tiered)
  
  -- Results
  gross_commission DECIMAL(15,2) NOT NULL,
  vat_rate DECIMAL(5,4) DEFAULT 0.21,
  vat_amount DECIMAL(15,2) DEFAULT 0,
  net_commission DECIMAL(15,2) NOT NULL,
  
  -- Audit and metadata
  calculation_method TEXT, -- Description of how this was calculated
  conditions_met JSONB, -- Which conditions were evaluated and their results
  execution_time_ms INTEGER, -- Performance tracking
  
  status TEXT DEFAULT 'calculated' CHECK (status IN ('calculated', 'approved', 'paid', 'disputed')),
  notes TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  calculated_by UUID REFERENCES auth.users(id)
);

-- Rule execution history for audit
CREATE TABLE public.rule_execution_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  calculation_run_id UUID REFERENCES public.calculation_runs(id),
  rule_id UUID REFERENCES public.advanced_commission_rules(id),
  distribution_id UUID REFERENCES public.investor_distributions(id),
  
  execution_result TEXT CHECK (execution_result IN ('success', 'failed', 'skipped')),
  conditions_evaluated JSONB,
  error_message TEXT,
  execution_time_ms INTEGER,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Enable RLS on all new tables
ALTER TABLE public.advanced_commission_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.commission_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rule_conditions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.advanced_commission_calculations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rule_execution_history ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Authenticated users can access advanced commission rules" 
ON public.advanced_commission_rules FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Authenticated users can access commission tiers" 
ON public.commission_tiers FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Authenticated users can access rule conditions" 
ON public.rule_conditions FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Authenticated users can access advanced calculations" 
ON public.advanced_commission_calculations FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Authenticated users can access rule execution history" 
ON public.rule_execution_history FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Create indexes for performance
CREATE INDEX idx_advanced_rules_entity ON public.advanced_commission_rules(entity_type, entity_name);
CREATE INDEX idx_advanced_rules_active ON public.advanced_commission_rules(is_active, effective_from, effective_to);
CREATE INDEX idx_commission_tiers_rule ON public.commission_tiers(rule_id, tier_order);
CREATE INDEX idx_rule_conditions_rule ON public.rule_conditions(rule_id, condition_group);
CREATE INDEX idx_advanced_calculations_run ON public.advanced_commission_calculations(calculation_run_id);
CREATE INDEX idx_rule_execution_rule ON public.rule_execution_history(rule_id, calculation_run_id);

-- Insert sample advanced rules
INSERT INTO public.advanced_commission_rules (name, description, rule_type, entity_type, entity_name, base_rate) VALUES
('Standard Distributor Rate', 'Standard 2.5% commission for distributors', 'percentage', 'distributor', 'Default Distributor', 0.025),
('Premium Referrer Rate', 'Premium 2% commission for high-volume referrers', 'percentage', 'referrer', 'Premium Referrer', 0.02),
('Tiered Partner Commission', 'Volume-based tiered commission for partners', 'tiered', 'partner', 'Tiered Partner', NULL);

-- Insert sample tiered structure
INSERT INTO public.commission_tiers (rule_id, tier_order, min_threshold, max_threshold, rate, description) 
SELECT id, 1, 0, 100000, 0.01, 'Tier 1: 0-100K at 1%' FROM public.advanced_commission_rules WHERE name = 'Tiered Partner Commission'
UNION ALL
SELECT id, 2, 100000, 500000, 0.015, 'Tier 2: 100K-500K at 1.5%' FROM public.advanced_commission_rules WHERE name = 'Tiered Partner Commission'
UNION ALL
SELECT id, 3, 500000, NULL, 0.025, 'Tier 3: 500K+ at 2.5%' FROM public.advanced_commission_rules WHERE name = 'Tiered Partner Commission';

-- Create function for updated timestamps
CREATE TRIGGER update_advanced_commission_rules_updated_at
  BEFORE UPDATE ON public.advanced_commission_rules
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();