-- Remove unique constraint on deals.name
-- Name is not a unique identifier for Vantage funds (multiple funds can have same name)
-- external_id is the proper unique identifier

-- Drop the deals_name_key constraint
ALTER TABLE public.deals
DROP CONSTRAINT IF EXISTS deals_name_key;

-- Verify the constraint was removed
SELECT conname, contype
FROM pg_constraint
WHERE conrelid = 'public.deals'::regclass
ORDER BY conname;
