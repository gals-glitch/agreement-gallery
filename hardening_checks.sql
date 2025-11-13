-- Final hardening checks for Vantage sync
-- All checks should return 0 or expected values

-- ============================================
-- CHECK A: Every Vantage investor has external_id
-- ============================================
SELECT
  'A. Missing external_id' AS check_name,
  COUNT(*) AS count,
  CASE
    WHEN COUNT(*) = 0 THEN 'PASS'
    ELSE 'FAIL'
  END AS status
FROM public.investors
WHERE LOWER(source_kind::text) = 'vantage'
  AND external_id IS NULL;

-- ============================================
-- CHECK B: No duplicate external_id
-- ============================================
-- B1: Investors
SELECT
  'B1. Duplicate investor external_ids' AS check_name,
  COUNT(*) AS count,
  CASE
    WHEN COUNT(*) = 0 THEN 'PASS'
    ELSE 'FAIL'
  END AS status
FROM (
  SELECT external_id, COUNT(*) AS c
  FROM public.investors
  WHERE external_id IS NOT NULL
  GROUP BY external_id
  HAVING COUNT(*) > 1
) dupes;

-- B2: Deals (Funds)
SELECT
  'B2. Duplicate deals external_ids' AS check_name,
  COUNT(*) AS count,
  CASE
    WHEN COUNT(*) = 0 THEN 'PASS'
    ELSE 'FAIL'
  END AS status
FROM (
  SELECT external_id, COUNT(*) AS c
  FROM public.deals
  WHERE external_id IS NOT NULL
  GROUP BY external_id
  HAVING COUNT(*) > 1
) dupes;

-- ============================================
-- CHECK C: Sync state is healthy
-- ============================================
SELECT
  'C. Sync state health' AS check_name,
  resource,
  last_sync_status,
  records_synced,
  completed_at,
  CASE
    WHEN last_sync_status = 'success' THEN 'PASS'
    WHEN last_sync_status IS NULL THEN 'WARNING: No sync yet'
    ELSE 'FAIL'
  END AS status
FROM public.vantage_sync_state
ORDER BY completed_at DESC NULLS LAST;

-- ============================================
-- CHECK D: Merged distributor investors
-- ============================================
SELECT
  'D. Merged DISTRIBUTOR investors' AS check_name,
  COUNT(*) AS count,
  CASE
    WHEN COUNT(*) = 22 THEN 'PASS (22 merged as expected)'
    WHEN COUNT(*) > 0 THEN 'PARTIAL (' || COUNT(*) || ' merged)'
    ELSE 'WARNING: No merges found'
  END AS status
FROM public.investors
WHERE source_kind = 'DISTRIBUTOR'
  AND merged_into_id IS NOT NULL
  AND COALESCE(is_active, FALSE) = FALSE;

-- ============================================
-- CHECK E: External_id constraints exist
-- ============================================
SELECT
  'E. External_id UNIQUE constraints' AS check_name,
  table_name,
  constraint_name,
  'PASS' AS status
FROM information_schema.table_constraints
WHERE constraint_name IN ('investors_external_id_unique', 'deals_external_id_unique')
  AND constraint_type = 'UNIQUE'
ORDER BY table_name;

-- ============================================
-- SUMMARY
-- ============================================
SELECT
  '=== HARDENING CHECKS COMPLETE ===' AS summary,
  'Review results above. All checks should show PASS status.' AS instructions;
