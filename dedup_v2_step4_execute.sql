-- STEP 4: Execute all merges
-- Runs merge_investors() for each pair in the plan
-- Returns JSON with per-merge FK update counts
-- IMPORTANT: Only run this AFTER reviewing the plan from Step 3!
-- IMPORTANT: Must be run in the SAME SQL Editor tab as Step 3 (temp table must exist)!

-- Execute all planned merges
SELECT
  p.src_id AS distributor_id,
  p.dst_id AS vantage_id,
  public.merge_investors(p.src_id, p.dst_id, p.reason) AS result
FROM investor_merge_plan p
ORDER BY p.src_id;

-- Show summary of what was merged
SELECT
  COUNT(*) AS total_merges_executed,
  COUNT(DISTINCT src_id) AS distributor_records_merged,
  COUNT(DISTINCT dst_id) AS vantage_records_kept
FROM public.investor_merge_log
WHERE run_at >= now() - interval '5 minutes';

-- Show the merge log (last 50 entries)
SELECT
  id,
  src_id AS distributor_id,
  dst_id AS vantage_id,
  reason,
  moved_fk,
  run_by,
  run_at
FROM public.investor_merge_log
ORDER BY run_at DESC, id DESC
LIMIT 50;
