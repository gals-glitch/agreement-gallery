-- Create entity types enum
CREATE TYPE public.entity_type AS ENUM ('distributor', 'referrer', 'partner');

-- Create entities table for managing distributors, referrers, and partners
CREATE TABLE public.entities (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  entity_type public.entity_type NOT NULL,
  email TEXT,
  phone TEXT,
  address TEXT,
  country TEXT,
  tax_id TEXT,
  commission_rate NUMERIC,
  is_active BOOLEAN NOT NULL DEFAULT true,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  created_by UUID,
  
  -- Ensure unique name per entity type
  UNIQUE(name, entity_type)
);

-- Enable RLS
ALTER TABLE public.entities ENABLE ROW LEVEL SECURITY;

-- Create policies for entity access
CREATE POLICY "Authenticated users can view entities" 
ON public.entities 
FOR SELECT 
USING (true);

CREATE POLICY "Authenticated users can create entities" 
ON public.entities 
FOR INSERT 
WITH CHECK (true);

CREATE POLICY "Authenticated users can update entities" 
ON public.entities 
FOR UPDATE 
USING (true);

CREATE POLICY "Authenticated users can delete entities" 
ON public.entities 
FOR DELETE 
USING (true);

-- Create trigger for automatic timestamp updates
CREATE TRIGGER update_entities_updated_at
BEFORE UPDATE ON public.entities
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- Create index for better performance
CREATE INDEX idx_entities_type_active ON public.entities(entity_type, is_active);
CREATE INDEX idx_entities_name ON public.entities(name);