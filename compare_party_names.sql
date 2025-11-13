-- Compare party references from investors vs actual parties

-- Parties referenced in investors CSV
SELECT DISTINCT
  SUBSTRING(notes FROM 'Introduced by: ([^;]+)') as party_from_investors_csv
FROM investors
WHERE notes LIKE '%Introduced by:%'
ORDER BY 1;

-- Actual parties in parties table (first 20)
SELECT name as actual_party_name
FROM parties
WHERE active = true
ORDER BY name
LIMIT 20;

-- Check for partial matches
SELECT
  SUBSTRING(i.notes FROM 'Introduced by: ([^;]+)') as investor_party_ref,
  p.name as possible_match
FROM investors i
CROSS JOIN parties p
WHERE i.notes LIKE '%Introduced by:%'
  AND (
    p.name LIKE '%' || SUBSTRING(i.notes FROM 'Introduced by: ([^;]+)') || '%'
    OR SUBSTRING(i.notes FROM 'Introduced by: ([^;]+)') LIKE '%' || p.name || '%'
  )
GROUP BY 1, 2
ORDER BY 1, 2;
