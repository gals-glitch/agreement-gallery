-- Check which investors have contributions

-- 1. Total contributions count
SELECT COUNT(*) as total_contributions FROM contributions;

-- 2. Investors with contributions (top 10)
SELECT
  i.name as investor_name,
  i.introduced_by_party_id,
  i.notes,
  COUNT(c.id) as contribution_count,
  SUM(c.amount) as total_amount
FROM investors i
JOIN contributions c ON c.investor_id = i.id
GROUP BY i.id, i.name, i.introduced_by_party_id, i.notes
ORDER BY contribution_count DESC
LIMIT 10;

-- 3. Investors with party links but NO contributions
SELECT
  i.name as investor_name,
  p.name as party_name
FROM investors i
JOIN parties p ON i.introduced_by_party_id = p.id
LEFT JOIN contributions c ON c.investor_id = i.id
WHERE c.id IS NULL
LIMIT 10;

-- 4. Contributions count by party link status
SELECT
  CASE
    WHEN i.introduced_by_party_id IS NOT NULL THEN 'Has Party Link'
    ELSE 'No Party Link'
  END as status,
  COUNT(c.id) as contribution_count
FROM contributions c
JOIN investors i ON c.investor_id = i.id
GROUP BY CASE WHEN i.introduced_by_party_id IS NOT NULL THEN 'Has Party Link' ELSE 'No Party Link' END;
