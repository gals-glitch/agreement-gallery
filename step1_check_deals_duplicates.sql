-- Step 1: Pre-check for duplicate external_id in deals table
-- This MUST return 0 rows before we can add the unique constraint

SELECT external_id, COUNT(*) AS c
FROM public.deals
WHERE external_id IS NOT NULL
GROUP BY external_id
HAVING COUNT(*) > 1;

-- If the above returns 0 rows, we're safe to proceed
-- Otherwise, duplicates must be resolved first
