-- Create investors table with relationship to party entities
CREATE TABLE public.investors (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  address TEXT,
  tax_id TEXT,
  country TEXT,
  party_entity_id UUID NOT NULL,
  investor_type TEXT DEFAULT 'individual',
  kyc_status TEXT DEFAULT 'pending',
  investment_capacity NUMERIC,
  risk_profile TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  created_by UUID
);

-- Enable Row Level Security
ALTER TABLE public.investors ENABLE ROW LEVEL SECURITY;

-- Create policy for admin/manager access
CREATE POLICY "Admin/Manager can access investors" 
ON public.investors 
FOR ALL 
USING (is_admin_or_manager(auth.uid()));

-- Add foreign key constraint to link investors to party entities
ALTER TABLE public.investors 
ADD CONSTRAINT fk_investors_party_entity 
FOREIGN KEY (party_entity_id) REFERENCES public.entities(id) ON DELETE CASCADE;

-- Create indexes for better performance
CREATE INDEX idx_investors_party_entity_id ON public.investors(party_entity_id);
CREATE INDEX idx_investors_is_active ON public.investors(is_active);
CREATE INDEX idx_investors_name ON public.investors(name);

-- Create trigger for automatic timestamp updates
CREATE TRIGGER update_investors_updated_at
BEFORE UPDATE ON public.investors
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- Update investor_distributions table to reference the new investors table
ALTER TABLE public.investor_distributions 
ADD COLUMN investor_id UUID;

-- Create index for the new investor_id column
CREATE INDEX idx_investor_distributions_investor_id ON public.investor_distributions(investor_id);

-- Add foreign key constraint (optional, as we might have legacy data)
-- ALTER TABLE public.investor_distributions 
-- ADD CONSTRAINT fk_investor_distributions_investor_id 
-- FOREIGN KEY (investor_id) REFERENCES public.investors(id) ON DELETE SET NULL;