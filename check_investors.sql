-- Quick check: Do investors exist?
SELECT COUNT(*) as total_investors FROM investors;

-- Sample of investors
SELECT id, name, introduced_by_party_id, notes, created_at
FROM investors
ORDER BY id
LIMIT 10;

-- Check if there are any investors at all
SELECT 
  COUNT(*) as total,
  COUNT(introduced_by_party_id) as with_party_links,
  COUNT(*) - COUNT(introduced_by_party_id) as without_party_links
FROM investors;
