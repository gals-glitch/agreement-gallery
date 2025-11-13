-- Quick funds verification checks

-- Total funds count
SELECT COUNT(*) AS total_funds
FROM public.deals
WHERE external_id IS NOT NULL;

-- Unique external_ids count (should match total_funds)
SELECT COUNT(DISTINCT external_id) AS unique_external_ids
FROM public.deals
WHERE external_id IS NOT NULL;

-- Sync state for funds
SELECT
  resource,
  last_sync_status,
  records_synced,
  records_created,
  records_updated,
  duration_ms,
  completed_at
FROM public.vantage_sync_state
WHERE resource='funds'
ORDER BY completed_at DESC
LIMIT 3;
