-- Verify import results

-- 1. Count imported records
SELECT 'Parties' as table_name, COUNT(*) as count FROM parties WHERE active = true
UNION ALL SELECT 'Investors', COUNT(*) FROM investors
UNION ALL SELECT 'Agreements (Commission)', COUNT(*) FROM agreements WHERE kind = 'distributor_commission'
UNION ALL SELECT 'Contributions', COUNT(*) FROM contributions;

-- 2. Check investor→party links
SELECT
  COUNT(*) as total_investors,
  COUNT(introduced_by_party_id) as with_party_link,
  COUNT(*) - COUNT(introduced_by_party_id) as without_party_link
FROM investors;

-- 3. Sample investors with notes but no party link
SELECT name, notes
FROM investors
WHERE notes LIKE '%Introduced by:%'
  AND introduced_by_party_id IS NULL
LIMIT 5;

-- 4. Check if party names in notes match actual parties
SELECT DISTINCT
  SUBSTRING(notes FROM 'Introduced by: ([^;]+)') as party_from_notes,
  CASE
    WHEN EXISTS (SELECT 1 FROM parties p WHERE p.name = SUBSTRING(notes FROM 'Introduced by: ([^;]+)'))
    THEN 'EXISTS'
    ELSE 'MISSING'
  END as party_exists
FROM investors
WHERE notes LIKE '%Introduced by:%'
LIMIT 10;
