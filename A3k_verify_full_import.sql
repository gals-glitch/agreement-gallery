-- Verify complete import results

-- 1. Total counts
SELECT 'Parties' as table_name, COUNT(*) as count FROM parties WHERE active = true
UNION ALL SELECT 'Investors (all)', COUNT(*) FROM investors
UNION ALL SELECT 'Investors (with notes)', COUNT(*) FROM investors WHERE notes IS NOT NULL
UNION ALL SELECT 'Investors (from contributions)', COUNT(*) FROM investors WHERE notes IS NULL
UNION ALL SELECT 'Agreements', COUNT(*) FROM agreements
UNION ALL SELECT 'Contributions', COUNT(*) FROM contributions;

-- 2. Sample contributions to verify they were created
SELECT
  i.name as investor_name,
  d.name as deal_name,
  c.amount,
  c.paid_in_date
FROM contributions c
JOIN investors i ON c.investor_id = i.id
JOIN deals d ON c.deal_id = d.id
LIMIT 10;

-- 3. Check investor→party links
SELECT
  COUNT(*) as total_investors,
  COUNT(introduced_by_party_id) as with_party_link,
  COUNT(*) - COUNT(introduced_by_party_id) as without_party_link
FROM investors;
