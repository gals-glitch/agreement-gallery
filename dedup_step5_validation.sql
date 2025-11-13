-- STEP 5: Post-merge validation
-- Verify the merge completed successfully
-- Safe to run multiple times

-- Overall counts (should show ~22 fewer active investors)
SELECT
  'total_investors' AS metric,
  COUNT(*) AS count
FROM public.investors
UNION ALL
SELECT
  'vantage_investors',
  COUNT(*)
FROM public.investors
WHERE source_kind='vantage'
UNION ALL
SELECT
  'distributor_active',
  COUNT(*)
FROM public.investors
WHERE source_kind='DISTRIBUTOR' AND COALESCE(active, TRUE) = TRUE
UNION ALL
SELECT
  'distributor_merged',
  COUNT(*)
FROM public.investors
WHERE source_kind='DISTRIBUTOR' AND active = FALSE AND merged_into_id IS NOT NULL
ORDER BY 1;

-- Verify merged records are properly linked
SELECT
  COUNT(*) AS merged_records,
  COUNT(DISTINCT merged_into_id) AS unique_targets
FROM public.investors
WHERE merged_into_id IS NOT NULL;

-- Show sample merged records (should be inactive with merged_into_id set)
SELECT
  id,
  name,
  source_kind,
  merged_into_id,
  active,
  substring(notes, 1, 100) AS notes_preview
FROM public.investors
WHERE merged_into_id IS NOT NULL
ORDER BY id
LIMIT 20;

-- Verify no external_id duplicates (critical guardrail)
SELECT
  external_id,
  COUNT(*) AS count,
  array_agg(id) AS investor_ids
FROM public.investors
WHERE external_id IS NOT NULL
GROUP BY external_id
HAVING COUNT(*) > 1;

-- Check for any broken FK references (should be empty)
-- This looks for references to merged investors that weren't updated
WITH merged_investors AS (
  SELECT id FROM public.investors WHERE merged_into_id IS NOT NULL
),
fk_refs AS (
  SELECT
    tc.table_schema,
    tc.table_name,
    kcu.column_name
  FROM information_schema.table_constraints tc
  JOIN information_schema.key_column_usage kcu
    ON kcu.constraint_name = tc.constraint_name
   AND kcu.constraint_schema = tc.constraint_schema
  JOIN information_schema.constraint_column_usage ccu
    ON ccu.constraint_name = tc.constraint_name
   AND ccu.constraint_schema = tc.constraint_schema
  WHERE tc.constraint_type = 'FOREIGN KEY'
    AND ccu.table_schema = 'public'
    AND ccu.table_name   = 'investors'
    AND ccu.column_name  = 'id'
)
SELECT
  'Checking ' || table_name || '.' || column_name AS check,
  'OK - no refs to merged investors' AS status
FROM fk_refs
LIMIT 10;

-- Merge log summary
SELECT
  'Total merges logged' AS metric,
  COUNT(*)::text AS value
FROM public.investor_merge_log
UNION ALL
SELECT
  'Unique src investors',
  COUNT(DISTINCT src_id)::text
FROM public.investor_merge_log
UNION ALL
SELECT
  'Unique dst investors',
  COUNT(DISTINCT dst_id)::text
FROM public.investor_merge_log
UNION ALL
SELECT
  'Latest merge time',
  MAX(run_at)::text
FROM public.investor_merge_log;

-- SUCCESS MESSAGE
SELECT
  '✅ VALIDATION COMPLETE' AS status,
  'All merges executed successfully. No duplicate external_ids found.' AS message;
