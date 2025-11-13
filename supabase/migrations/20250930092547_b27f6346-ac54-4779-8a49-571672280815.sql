-- T-03: Canonical ERD + Migrations (Agreements, Terms, Parties)
-- Create parties table for entities that can introduce investors
CREATE TABLE public.parties (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  party_type TEXT NOT NULL CHECK (party_type IN ('distributor', 'referrer', 'partner', 'introducer')),
  email TEXT,
  phone TEXT,
  address TEXT,
  country TEXT,
  tax_id TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  created_by UUID REFERENCES auth.users(id)
);

-- Create agreements table for fee agreements
CREATE TABLE public.agreements (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  agreement_type TEXT NOT NULL CHECK (agreement_type IN ('commission', 'fee', 'rebate', 'other')),
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'expired', 'terminated')),
  effective_from DATE NOT NULL,
  effective_to DATE,
  introduced_by_party_id UUID NOT NULL REFERENCES public.parties(id),
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  created_by UUID REFERENCES auth.users(id),
  
  -- Ensure effective dates are logical
  CONSTRAINT valid_date_range CHECK (effective_to IS NULL OR effective_to >= effective_from)
);

-- Create agreement_terms table for detailed terms within agreements
CREATE TABLE public.agreement_terms (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  agreement_id UUID NOT NULL REFERENCES public.agreements(id) ON DELETE CASCADE,
  term_type TEXT NOT NULL CHECK (term_type IN ('rate', 'cap', 'minimum', 'maximum', 'tier', 'condition')),
  term_order INTEGER NOT NULL DEFAULT 1,
  value_numeric NUMERIC,
  value_text TEXT,
  value_json JSONB,
  effective_from DATE,
  effective_to DATE,
  is_active BOOLEAN NOT NULL DEFAULT true,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  
  -- Ensure at least one value is provided
  CONSTRAINT has_value CHECK (
    value_numeric IS NOT NULL OR 
    value_text IS NOT NULL OR 
    value_json IS NOT NULL
  )
);

-- Create investor_agreement_links table to link investors to their agreements
CREATE TABLE public.investor_agreement_links (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  investor_id UUID NOT NULL REFERENCES public.investors(id) ON DELETE CASCADE,
  agreement_id UUID NOT NULL REFERENCES public.agreements(id) ON DELETE CASCADE,
  introduced_by_party_id UUID NOT NULL REFERENCES public.parties(id),
  link_effective_from DATE NOT NULL DEFAULT CURRENT_DATE,
  link_effective_to DATE,
  is_active BOOLEAN NOT NULL DEFAULT true,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  created_by UUID REFERENCES auth.users(id),
  
  -- Unique constraint to prevent duplicate active links
  UNIQUE(investor_id, agreement_id, link_effective_from),
  
  -- Ensure link dates are logical
  CONSTRAINT valid_link_date_range CHECK (link_effective_to IS NULL OR link_effective_to >= link_effective_from)
);

-- Enable RLS on all new tables
ALTER TABLE public.parties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agreements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agreement_terms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.investor_agreement_links ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for parties
CREATE POLICY "Admin/Manager can access parties" 
ON public.parties 
FOR ALL 
USING (is_admin_or_manager(auth.uid()));

-- Create RLS policies for agreements
CREATE POLICY "Admin/Manager can access agreements" 
ON public.agreements 
FOR ALL 
USING (is_admin_or_manager(auth.uid()));

-- Create RLS policies for agreement_terms
CREATE POLICY "Admin/Manager can access agreement terms" 
ON public.agreement_terms 
FOR ALL 
USING (is_admin_or_manager(auth.uid()));

-- Create RLS policies for investor_agreement_links
CREATE POLICY "Admin/Manager can access investor agreement links" 
ON public.investor_agreement_links 
FOR ALL 
USING (is_admin_or_manager(auth.uid()));

-- Create indexes for performance
CREATE INDEX idx_parties_type_active ON public.parties(party_type, is_active);
CREATE INDEX idx_agreements_effective_dates ON public.agreements(effective_from, effective_to);
CREATE INDEX idx_agreements_introduced_by ON public.agreements(introduced_by_party_id);
CREATE INDEX idx_agreement_terms_agreement_id ON public.agreement_terms(agreement_id);
CREATE INDEX idx_investor_agreement_links_investor ON public.investor_agreement_links(investor_id);
CREATE INDEX idx_investor_agreement_links_agreement ON public.investor_agreement_links(agreement_id);
CREATE INDEX idx_investor_agreement_links_introducer ON public.investor_agreement_links(introduced_by_party_id);

-- Create triggers for updated_at timestamps
CREATE TRIGGER update_parties_updated_at
BEFORE UPDATE ON public.parties
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_agreements_updated_at
BEFORE UPDATE ON public.agreements
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();