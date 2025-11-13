-- Verify data is ready for commission computation

-- 1. Overall link status
SELECT
  COUNT(*) as total_investors,
  COUNT(introduced_by_party_id) as linked_to_party,
  COUNT(*) - COUNT(introduced_by_party_id) as unlinked
FROM investors;

-- 2. Contributions with linked investors (can compute commissions)
SELECT COUNT(*) as computable_contributions
FROM contributions c
JOIN investors i ON c.investor_id = i.id
WHERE i.introduced_by_party_id IS NOT NULL;

-- 3. Contributions with unlinked investors (will be skipped)
SELECT COUNT(*) as skipped_contributions
FROM contributions c
JOIN investors i ON c.investor_id = i.id
WHERE i.introduced_by_party_id IS NULL;

-- 4. Check agreements exist for parties with linked investors
SELECT
  p.name as party_name,
  COUNT(DISTINCT i.id) as linked_investors,
  COUNT(DISTINCT c.id) as contributions,
  COUNT(DISTINCT a.id) as agreements
FROM parties p
JOIN investors i ON i.introduced_by_party_id = p.id
LEFT JOIN contributions c ON c.investor_id = i.id
LEFT JOIN agreements a ON a.party_id = p.id AND a.kind = 'distributor_commission' AND a.status = 'APPROVED'
GROUP BY p.id, p.name
ORDER BY contributions DESC
LIMIT 10;
