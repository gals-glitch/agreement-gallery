-- Get exact investor counts
-- Run in Supabase SQL Editor

-- Total count
SELECT COUNT(*) as total_investors FROM investors;

-- Count by source_kind
SELECT
    source_kind,
    COUNT(*) as count
FROM investors
GROUP BY source_kind
ORDER BY count DESC;

-- Check for duplicate external_ids (should be 0)
SELECT
    external_id,
    COUNT(*) as count
FROM investors
WHERE external_id IS NOT NULL
GROUP BY external_id
HAVING COUNT(*) > 1;

-- Summary of the situation
SELECT
    'DISTRIBUTOR' as source,
    COUNT(*) as count
FROM investors
WHERE source_kind = 'DISTRIBUTOR'
UNION ALL
SELECT
    'vantage' as source,
    COUNT(*) as count
FROM investors
WHERE source_kind = 'vantage'
UNION ALL
SELECT
    'TOTAL' as source,
    COUNT(*) as count
FROM investors;
