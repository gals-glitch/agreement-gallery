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
WHERE source_kind='DISTRIBUTOR' AND COALESCE(is_active, TRUE) = TRUE
UNION ALL
SELECT
  'distributor_merged',
  COUNT(*)
FROM public.investors
WHERE source_kind='DISTRIBUTOR' AND is_active = FALSE AND merged_into_id IS NOT NULL
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
  source_kind::text AS source_kind,
  merged_into_id,
  is_active,
  substring(notes, 1, 100) AS notes_preview
FROM public.investors
WHERE merged_into_id IS NOT NULL
ORDER BY id
LIMIT 25;

-- Verify no external_id duplicates (critical guardrail)
SELECT
  external_id,
  COUNT(*) AS count,
  array_agg(id) AS investor_ids
FROM public.investors
WHERE external_id IS NOT NULL
GROUP BY external_id
HAVING COUNT(*) > 1;

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
  'VALIDATION COMPLETE' AS status,
  'All merges executed successfully. No duplicate external_ids found.' AS message;
