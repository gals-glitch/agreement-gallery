-- Create tables for commission calculations and investor distributions

-- Table for storing calculation periods/runs
CREATE TABLE public.calculation_runs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'calculating', 'completed', 'approved')),
  total_gross_fees DECIMAL(15,2) DEFAULT 0,
  total_vat DECIMAL(15,2) DEFAULT 0,
  total_net_payable DECIMAL(15,2) DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_by UUID REFERENCES auth.users(id)
);

-- Table for storing investor distribution data from uploaded Excel files
CREATE TABLE public.investor_distributions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  calculation_run_id UUID REFERENCES public.calculation_runs(id) ON DELETE CASCADE,
  investor_name TEXT NOT NULL,
  fund_name TEXT,
  distribution_amount DECIMAL(15,2) NOT NULL,
  distributor_name TEXT,
  referrer_name TEXT,
  partner_name TEXT,
  distribution_date DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Table for storing commission rules and rates
CREATE TABLE public.commission_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rule_type TEXT NOT NULL CHECK (rule_type IN ('distributor', 'referrer', 'partner')),
  entity_name TEXT NOT NULL,
  commission_rate DECIMAL(5,4) NOT NULL, -- e.g., 0.0250 for 2.5%
  min_amount DECIMAL(15,2) DEFAULT 0,
  max_amount DECIMAL(15,2),
  fund_name TEXT, -- Optional: rule specific to certain funds
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Table for storing calculated commission results
CREATE TABLE public.commission_calculations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  calculation_run_id UUID REFERENCES public.calculation_runs(id) ON DELETE CASCADE,
  distribution_id UUID REFERENCES public.investor_distributions(id) ON DELETE CASCADE,
  commission_type TEXT NOT NULL CHECK (commission_type IN ('distributor', 'referrer', 'partner')),
  entity_name TEXT NOT NULL,
  base_amount DECIMAL(15,2) NOT NULL,
  commission_rate DECIMAL(5,4) NOT NULL,
  gross_commission DECIMAL(15,2) NOT NULL,
  vat_amount DECIMAL(15,2) DEFAULT 0,
  net_commission DECIMAL(15,2) NOT NULL,
  rule_id UUID REFERENCES public.commission_rules(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Enable RLS on all tables
ALTER TABLE public.calculation_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.investor_distributions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.commission_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.commission_calculations ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (allowing all authenticated users for now - can be refined later)
CREATE POLICY "Authenticated users can access calculation runs" 
ON public.calculation_runs 
FOR ALL 
TO authenticated 
USING (true) 
WITH CHECK (true);

CREATE POLICY "Authenticated users can access investor distributions" 
ON public.investor_distributions 
FOR ALL 
TO authenticated 
USING (true) 
WITH CHECK (true);

CREATE POLICY "Authenticated users can access commission rules" 
ON public.commission_rules 
FOR ALL 
TO authenticated 
USING (true) 
WITH CHECK (true);

CREATE POLICY "Authenticated users can access commission calculations" 
ON public.commission_calculations 
FOR ALL 
TO authenticated 
USING (true) 
WITH CHECK (true);

-- Create indexes for better performance
CREATE INDEX idx_investor_distributions_run_id ON public.investor_distributions(calculation_run_id);
CREATE INDEX idx_commission_calculations_run_id ON public.commission_calculations(calculation_run_id);
CREATE INDEX idx_commission_calculations_distribution_id ON public.commission_calculations(distribution_id);
CREATE INDEX idx_commission_rules_entity_type ON public.commission_rules(entity_name, rule_type);

-- Insert some default commission rules
INSERT INTO public.commission_rules (rule_type, entity_name, commission_rate) VALUES
('distributor', 'Default Distributor', 0.0250), -- 2.5%
('referrer', 'Default Referrer', 0.0150), -- 1.5%
('partner', 'Default Partner', 0.0100); -- 1.0%

-- Function to update timestamps
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for automatic timestamp updates
CREATE TRIGGER update_calculation_runs_updated_at
  BEFORE UPDATE ON public.calculation_runs
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_commission_rules_updated_at
  BEFORE UPDATE ON public.commission_rules
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();