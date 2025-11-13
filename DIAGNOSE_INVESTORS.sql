-- ============================================================
-- DIAGNOSE: Why investors page shows 0 results
-- ============================================================

-- 1. Check if investors exist at all
SELECT 'Total investors' as check_name, COUNT(*) as count
FROM investors;

-- 2. Check first 10 investors
SELECT id, name, introduced_by_party_id, source_kind, is_active, created_at
FROM investors
ORDER BY id
LIMIT 10;

-- 3. Check if source_kind column exists and what values it has
SELECT source_kind, COUNT(*) as count
FROM investors
GROUP BY source_kind
ORDER BY count DESC;

-- 4. Check is_active column
SELECT is_active, COUNT(*) as count
FROM investors
GROUP BY is_active;

-- 5. Check if RLS policies are blocking
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'investors';

-- 6. Test the exact query the API would run
SELECT
  i.*,
  p.id as party_id,
  p.name as party_name,
  p.party_type
FROM investors i
LEFT JOIN parties p ON i.introduced_by_party_id = p.id
ORDER BY i.name
LIMIT 10;
