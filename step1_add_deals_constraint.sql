-- Step 1b: Add unique constraint to deals.external_id
-- Only run this after confirming no duplicates exist

ALTER TABLE public.deals
ADD CONSTRAINT deals_external_id_unique UNIQUE (external_id);

-- Verify the constraint was added
SELECT conname, contype, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'public.deals'::regclass
  AND conname = 'deals_external_id_unique';
