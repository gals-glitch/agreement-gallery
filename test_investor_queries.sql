-- Test queries to verify Vantage sync integration
-- Run these in Supabase SQL Editor to explore your data

-- 1. Overview: Count investors by source
SELECT
    source_kind,
    COUNT(*) as count,
    MIN(created_at) as first_created,
    MAX(created_at) as last_created
FROM investors
GROUP BY source_kind
ORDER BY count DESC;

-- 2. Sample Vantage investors with full details
SELECT
    id,
    name,
    email,
    phone,
    external_id,
    source_kind,
    is_active,
    created_at
FROM investors
WHERE source_kind = 'vantage'
ORDER BY created_at DESC
LIMIT 20;

-- 3. Check for investors with missing critical data
SELECT
    COUNT(*) as missing_email_count
FROM investors
WHERE source_kind = 'vantage'
  AND (email IS NULL OR email = '');

SELECT
    COUNT(*) as missing_name_count
FROM investors
WHERE source_kind = 'vantage'
  AND (name IS NULL OR name = '');

-- 4. Find investors with duplicate names (expected - different people)
SELECT
    name,
    COUNT(*) as count,
    STRING_AGG(external_id::text, ', ') as external_ids
FROM investors
WHERE source_kind = 'vantage'
GROUP BY name
HAVING COUNT(*) > 1
ORDER BY count DESC
LIMIT 10;

-- 5. Verify all Vantage investors have external_id
SELECT
    COUNT(*) as total_vantage,
    COUNT(external_id) as with_external_id,
    COUNT(*) - COUNT(external_id) as missing_external_id
FROM investors
WHERE source_kind = 'vantage';

-- 6. Check active vs inactive investors
SELECT
    is_active,
    COUNT(*) as count
FROM investors
WHERE source_kind = 'vantage'
GROUP BY is_active;

-- 7. Sample investors by external_id range (to see data distribution)
SELECT
    id,
    name,
    external_id,
    email,
    created_at
FROM investors
WHERE source_kind = 'vantage'
ORDER BY external_id::integer
LIMIT 10;
