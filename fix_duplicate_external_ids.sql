-- Fix duplicate external_ids in deals table
-- Run this AFTER reviewing the duplicates

-- Option 1: For each duplicate, keep the oldest deal (lowest id) and NULL out the others
UPDATE public.deals
SET external_id = NULL
WHERE id IN (
  SELECT d2.id
  FROM public.deals d1
  JOIN public.deals d2 ON d1.external_id = d2.external_id AND d1.id < d2.id
  WHERE d1.external_id IS NOT NULL
);

-- Verify: This should now return 0 rows
SELECT external_id, COUNT(*) AS c
FROM public.deals
WHERE external_id IS NOT NULL
GROUP BY external_id
HAVING COUNT(*) > 1;

-- Show what we kept
SELECT id, fund_id, name, external_id
FROM public.deals
WHERE external_id IS NOT NULL
ORDER BY external_id;
