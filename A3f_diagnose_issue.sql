-- Diagnose why contributions and agreements show 0

-- 1. Check total counts
SELECT 'Parties' as table_name, COUNT(*) FROM parties
UNION ALL SELECT 'Investors', COUNT(*) FROM investors
UNION ALL SELECT 'Agreements', COUNT(*) FROM agreements
UNION ALL SELECT 'Contributions', COUNT(*) FROM contributions
UNION ALL SELECT 'Deals', COUNT(*) FROM deals;

-- 2. Sample contributions - are they linked to investors?
SELECT
  c.id as contribution_id,
  c.investor_id,
  i.name as investor_name,
  i.introduced_by_party_id,
  c.deal_id,
  c.amount
FROM contributions c
LEFT JOIN investors i ON c.investor_id = i.id
LIMIT 10;

-- 3. Sample agreements - are they linked to parties and deals?
SELECT
  a.id as agreement_id,
  a.party_id,
  p.name as party_name,
  a.deal_id,
  d.name as deal_name,
  a.kind,
  a.status
FROM agreements a
LEFT JOIN parties p ON a.party_id = p.id
LEFT JOIN deals d ON a.deal_id = d.id
LIMIT 10;

-- 4. Check if investor names in contributions match actual investors
SELECT DISTINCT
  c.investor_id,
  COUNT(*) as contribution_count
FROM contributions c
GROUP BY c.investor_id
ORDER BY contribution_count DESC
LIMIT 10;

-- 5. Check if deal names in agreements match actual deals
SELECT DISTINCT
  a.deal_id,
  COUNT(*) as agreement_count
FROM agreements a
GROUP BY a.deal_id
ORDER BY agreement_count DESC
LIMIT 10;
