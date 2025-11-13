-- Step 1: Check for duplicate external_ids in deals table
SELECT external_id, COUNT(*) AS c
FROM public.deals
WHERE external_id IS NOT NULL
GROUP BY external_id
HAVING COUNT(*) > 1;

-- If no rows returned above, run this:
-- Step 2: Add UNIQUE constraint to deals.external_id
ALTER TABLE public.deals
ADD CONSTRAINT deals_external_id_unique UNIQUE (external_id);

-- Step 3: Verify constraint was added
SELECT constraint_name, constraint_type
FROM information_schema.table_constraints
WHERE table_name = 'deals'
  AND constraint_name = 'deals_external_id_unique';
