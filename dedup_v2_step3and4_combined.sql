-- COMBINED STEP 3 & 4: Build plan and execute merges
-- This runs both steps in one transaction to avoid temp table issues
-- IMPORTANT: Review the merge plan output before confirming execution!

-- ============================================
-- PART 1: Build the merge plan
-- ============================================

DROP TABLE IF EXISTS investor_merge_plan;

CREATE TEMP TABLE investor_merge_plan (
  src_id BIGINT,   -- DISTRIBUTOR source (will be merged INTO dst_id)
  dst_id BIGINT,   -- vantage source (canonical record)
  reason TEXT
);

-- Fill with exact normalized name matches
WITH base AS (
  SELECT
    id,
    name,
    lower(trim(regexp_replace(name, '\s+', ' ', 'g'))) AS norm_name,
    source_kind,
    external_id
  FROM public.investors
)
INSERT INTO investor_merge_plan (src_id, dst_id, reason)
SELECT d.id, v.id, 'name_match'
FROM base d
JOIN base v
  ON v.source_kind = 'vantage'
  AND d.source_kind = 'DISTRIBUTOR'
  AND v.norm_name = d.norm_name;

-- Show the merge plan for review
SELECT
  '=== MERGE PLAN - REVIEW THESE 22 PAIRS ===' AS info;

SELECT
  p.src_id AS distributor_id,
  d.name AS distributor_name,
  p.dst_id AS vantage_id,
  v.name AS vantage_name,
  v.external_id AS vant_external_id,
  p.reason
FROM investor_merge_plan p
JOIN public.investors d ON d.id = p.src_id
JOIN public.investors v ON v.id = p.dst_id
ORDER BY d.name;

-- Summary
SELECT
  COUNT(*) AS total_pairs_to_merge,
  COUNT(DISTINCT p.src_id) AS unique_distributor_records,
  COUNT(DISTINCT p.dst_id) AS unique_vantage_records
FROM investor_merge_plan p;

-- ============================================
-- PART 2: Execute the merges
-- ============================================

SELECT
  '=== EXECUTING MERGES - PLEASE WAIT ===' AS info;

-- Execute all planned merges
SELECT
  p.src_id AS distributor_id,
  p.dst_id AS vantage_id,
  public.merge_investors(p.src_id, p.dst_id, p.reason) AS result
FROM investor_merge_plan p
ORDER BY p.src_id;

-- Show summary of what was merged
SELECT
  '=== MERGE SUMMARY ===' AS info;

SELECT
  COUNT(*) AS total_merges_executed,
  COUNT(DISTINCT src_id) AS distributor_records_merged,
  COUNT(DISTINCT dst_id) AS vantage_records_kept
FROM public.investor_merge_log
WHERE run_at >= now() - interval '5 minutes';

-- Show the merge log (last 25 entries)
SELECT
  '=== MERGE LOG (Last 25) ===' AS info;

SELECT
  id,
  src_id AS distributor_id,
  dst_id AS vantage_id,
  reason,
  moved_fk,
  run_at
FROM public.investor_merge_log
ORDER BY run_at DESC, id DESC
LIMIT 25;

-- Cleanup
DROP TABLE IF EXISTS investor_merge_plan;

SELECT
  '=== EXECUTION COMPLETE ===' AS info,
  'Run dedup_v2_step5_validate.sql to verify results' AS next_step;
