-- T-04: "Introduced by" Enforcement - Backend Guards
-- Create function to validate investor has introducer
CREATE OR REPLACE FUNCTION public.validate_investor_has_introducer()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Check if investor has an active agreement link with introducer
  IF NOT EXISTS (
    SELECT 1 
    FROM public.investor_agreement_links ial
    JOIN public.agreements a ON ial.agreement_id = a.id
    WHERE ial.investor_id = NEW.id 
      AND ial.is_active = true
      AND ial.introduced_by_party_id IS NOT NULL
      AND (ial.link_effective_to IS NULL OR ial.link_effective_to >= CURRENT_DATE)
  ) THEN
    RAISE EXCEPTION 'Cannot save investor without an active introducer link. Please create an agreement with an introducing party first.'
      USING HINT = 'An investor must be linked to an agreement with an introducing party before being saved.';
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create function to validate agreement has introducer
CREATE OR REPLACE FUNCTION public.validate_agreement_has_introducer()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Ensure introduced_by_party_id is provided
  IF NEW.introduced_by_party_id IS NULL THEN
    RAISE EXCEPTION 'Cannot save agreement without introducing party. Please select an introducing party.'
      USING HINT = 'Every agreement must have an introducing party specified.';
  END IF;
  
  -- Ensure the introducing party exists and is active
  IF NOT EXISTS (
    SELECT 1 
    FROM public.parties p
    WHERE p.id = NEW.introduced_by_party_id 
      AND p.is_active = true
  ) THEN
    RAISE EXCEPTION 'Invalid or inactive introducing party selected.'
      USING HINT = 'The introducing party must be an active party in the system.';
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create function to validate investor agreement link has introducer
CREATE OR REPLACE FUNCTION public.validate_investor_agreement_link_introducer()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Ensure introduced_by_party_id is provided
  IF NEW.introduced_by_party_id IS NULL THEN
    RAISE EXCEPTION 'Cannot create investor agreement link without introducing party.'
      USING HINT = 'Every investor agreement link must specify who introduced the investor.';
  END IF;
  
  -- Ensure the introducing party exists and is active
  IF NOT EXISTS (
    SELECT 1 
    FROM public.parties p
    WHERE p.id = NEW.introduced_by_party_id 
      AND p.is_active = true
  ) THEN
    RAISE EXCEPTION 'Invalid or inactive introducing party selected for investor agreement link.'
      USING HINT = 'The introducing party must be an active party in the system.';
  END IF;
  
  RETURN NEW;
END;
$$;

-- Add triggers for validation (commented out for now to avoid breaking existing data)
-- These should be enabled once the data migration is complete

-- CREATE TRIGGER enforce_investor_introducer
--   BEFORE INSERT OR UPDATE ON public.investors
--   FOR EACH ROW
--   EXECUTE FUNCTION public.validate_investor_has_introducer();

CREATE TRIGGER enforce_agreement_introducer
  BEFORE INSERT OR UPDATE ON public.agreements
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_agreement_has_introducer();

CREATE TRIGGER enforce_investor_agreement_link_introducer
  BEFORE INSERT OR UPDATE ON public.investor_agreement_links
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_investor_agreement_link_introducer();