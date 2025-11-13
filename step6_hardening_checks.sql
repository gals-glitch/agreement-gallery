-- Step 6: Final hardening checks for Vantage sync deployment
-- Run these and verify all results are green (0 issues)

-- ==============================================================================
-- CHECK A: Every Vantage investor has external_id
-- ==============================================================================
-- EXPECTED: 0 rows (all Vantage investors should have external_id)
SELECT COUNT(*) AS missing_extid_count,
       'FAIL: Vantage investors without external_id found!' AS issue
FROM public.investors
WHERE LOWER(source_kind) = 'vantage'
  AND external_id IS NULL
HAVING COUNT(*) > 0

UNION ALL

SELECT 0 AS missing_extid_count,
       '✓ PASS: All Vantage investors have external_id' AS status
WHERE NOT EXISTS (
    SELECT 1 FROM public.investors
    WHERE LOWER(source_kind) = 'vantage' AND external_id IS NULL
);

-- ==============================================================================
-- CHECK B: No duplicate external_id in investors or deals
-- ==============================================================================
-- EXPECTED: 0 rows (no duplicates)
SELECT 'investors' AS table_name,
       external_id,
       COUNT(*) AS duplicate_count,
       'FAIL: Duplicate external_id found!' AS issue
FROM public.investors
WHERE external_id IS NOT NULL
GROUP BY external_id
HAVING COUNT(*) > 1

UNION ALL

SELECT 'deals' AS table_name,
       external_id,
       COUNT(*) AS duplicate_count,
       'FAIL: Duplicate external_id found!' AS issue
FROM public.deals
WHERE external_id IS NOT NULL
GROUP BY external_id
HAVING COUNT(*) > 1

UNION ALL

SELECT 'both_tables' AS table_name,
       NULL AS external_id,
       0 AS duplicate_count,
       '✓ PASS: No duplicate external_ids' AS status
WHERE NOT EXISTS (
    SELECT 1 FROM public.investors
    WHERE external_id IS NOT NULL
    GROUP BY external_id HAVING COUNT(*) > 1
)
AND NOT EXISTS (
    SELECT 1 FROM public.deals
    WHERE external_id IS NOT NULL
    GROUP BY external_id HAVING COUNT(*) > 1
);

-- ==============================================================================
-- CHECK C: Sync state is healthy
-- ==============================================================================
-- EXPECTED: Last sync status should be 'success' or 'completed'
SELECT resource,
       last_sync_status,
       records_synced,
       records_created,
       records_updated,
       completed_at,
       CASE
           WHEN last_sync_status IN ('success', 'completed') THEN '✓ PASS'
           WHEN last_sync_status = 'failed' THEN '✗ FAIL'
           ELSE '⚠ WARNING'
       END AS health_status
FROM public.vantage_sync_state
ORDER BY completed_at DESC;

-- ==============================================================================
-- CHECK D: Recently merged distributor investors are inactive and linked
-- ==============================================================================
-- EXPECTED: All merged DISTRIBUTOR investors should be inactive
SELECT COUNT(*) AS correctly_merged,
       '✓ PASS: All merged distributors are inactive' AS status
FROM public.investors
WHERE source_kind = 'DISTRIBUTOR'
  AND merged_into_id IS NOT NULL
  AND COALESCE(is_active, FALSE) = FALSE;

-- Find any that are NOT correctly set
SELECT id,
       name,
       external_id,
       merged_into_id,
       is_active,
       '✗ FAIL: Merged distributor still active!' AS issue
FROM public.investors
WHERE source_kind = 'DISTRIBUTOR'
  AND merged_into_id IS NOT NULL
  AND COALESCE(is_active, FALSE) = TRUE;

-- ==============================================================================
-- BONUS CHECK E: Constraint verification
-- ==============================================================================
-- Verify the unique constraints are in place
SELECT conname AS constraint_name,
       conrelid::regclass AS table_name,
       pg_get_constraintdef(oid) AS constraint_definition,
       '✓ PASS: Constraint exists' AS status
FROM pg_constraint
WHERE conname IN ('deals_external_id_unique', 'investors_external_id_key')
ORDER BY conrelid::regclass;

-- ==============================================================================
-- BONUS CHECK F: Cron job verification
-- ==============================================================================
-- Verify the daily sync job is scheduled
SELECT jobid,
       jobname,
       schedule,
       active,
       CASE
           WHEN active THEN '✓ PASS: Cron job is active'
           ELSE '✗ FAIL: Cron job is not active'
       END AS status
FROM cron.job
WHERE jobname = 'vantage-daily-sync';

-- ==============================================================================
-- SUMMARY QUERY: Overall health check
-- ==============================================================================
WITH checks AS (
    -- Check A: Vantage investors with external_id
    SELECT 'A' AS check_id,
           'Vantage investors have external_id' AS check_name,
           CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
    FROM public.investors
    WHERE LOWER(source_kind) = 'vantage' AND external_id IS NULL

    UNION ALL

    -- Check B1: No duplicate investors
    SELECT 'B1' AS check_id,
           'No duplicate investor external_ids' AS check_name,
           CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
    FROM (
        SELECT external_id
        FROM public.investors
        WHERE external_id IS NOT NULL
        GROUP BY external_id
        HAVING COUNT(*) > 1
    ) dups

    UNION ALL

    -- Check B2: No duplicate deals
    SELECT 'B2' AS check_id,
           'No duplicate deal external_ids' AS check_name,
           CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
    FROM (
        SELECT external_id
        FROM public.deals
        WHERE external_id IS NOT NULL
        GROUP BY external_id
        HAVING COUNT(*) > 1
    ) dups

    UNION ALL

    -- Check C: Last sync successful
    SELECT 'C' AS check_id,
           'Last sync status is success' AS check_name,
           CASE WHEN last_sync_status IN ('success', 'completed') THEN 'PASS' ELSE 'FAIL' END AS result
    FROM public.vantage_sync_state
    WHERE resource = 'accounts'
    ORDER BY completed_at DESC
    LIMIT 1

    UNION ALL

    -- Check D: Merged distributors inactive
    SELECT 'D' AS check_id,
           'Merged distributors are inactive' AS check_name,
           CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
    FROM public.investors
    WHERE source_kind = 'DISTRIBUTOR'
      AND merged_into_id IS NOT NULL
      AND COALESCE(is_active, FALSE) = TRUE
)
SELECT check_id,
       check_name,
       result,
       CASE result
           WHEN 'PASS' THEN '✓'
           WHEN 'FAIL' THEN '✗'
           ELSE '⚠'
       END AS icon
FROM checks
ORDER BY check_id;

-- Final message
DO $$
DECLARE
    fail_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO fail_count
    FROM (
        SELECT 1 FROM public.investors
        WHERE LOWER(source_kind) = 'vantage' AND external_id IS NULL
        UNION ALL
        SELECT 1 FROM (
            SELECT external_id FROM public.investors
            WHERE external_id IS NOT NULL
            GROUP BY external_id HAVING COUNT(*) > 1
        ) i
        UNION ALL
        SELECT 1 FROM (
            SELECT external_id FROM public.deals
            WHERE external_id IS NOT NULL
            GROUP BY external_id HAVING COUNT(*) > 1
        ) d
    ) failures;

    IF fail_count = 0 THEN
        RAISE NOTICE '✓✓✓ ALL HARDENING CHECKS PASSED ✓✓✓';
    ELSE
        RAISE WARNING '✗✗✗ % HARDENING CHECKS FAILED ✗✗✗', fail_count;
    END IF;
END $$;
