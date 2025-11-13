-- Count how many contributions can actually compute commissions

-- 1. Total contributions with party links
SELECT COUNT(*) as contributions_with_party_link
FROM contributions c
JOIN investors i ON c.investor_id = i.id
WHERE i.introduced_by_party_id IS NOT NULL;

-- 2. Contributions that ALSO have matching agreements
SELECT COUNT(*) as contributions_with_agreement
FROM contributions c
JOIN investors i ON c.investor_id = i.id
JOIN agreements a ON a.party_id = i.introduced_by_party_id
  AND a.deal_id = c.deal_id
  AND a.status = 'APPROVED'
WHERE i.introduced_by_party_id IS NOT NULL;

-- 3. Breakdown by party
SELECT
  p.name as party_name,
  COUNT(DISTINCT c.id) as total_contributions,
  COUNT(DISTINCT CASE WHEN a.id IS NOT NULL THEN c.id END) as with_agreement,
  COUNT(DISTINCT CASE WHEN a.id IS NULL THEN c.id END) as without_agreement
FROM contributions c
JOIN investors i ON c.investor_id = i.id
JOIN parties p ON i.introduced_by_party_id = p.id
LEFT JOIN agreements a ON a.party_id = p.id AND a.deal_id = c.deal_id AND a.status = 'APPROVED'
GROUP BY p.name
ORDER BY total_contributions DESC;
