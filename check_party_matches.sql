-- Check which party references from investors CSV exist in parties table

-- All unique "Introduced by" values from investors notes
SELECT DISTINCT
  SUBSTRING(notes FROM 'Introduced by: ([^;]+)') as party_from_notes
FROM investors
WHERE notes LIKE '%Introduced by:%'
ORDER BY 1;

-- All party names in parties table
SELECT name FROM parties WHERE active = true ORDER BY name;
