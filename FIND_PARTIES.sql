-- Step 1: Check the parties table structure
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'parties'
ORDER BY ordinal_position;

-- Step 2: See what parties exist
SELECT *
FROM parties
ORDER BY id
LIMIT 10;

-- Step 3: Check if there's a relationship between investors and parties
-- (Maybe investors ARE parties, or there's a linking table)
SELECT
  i.id as investor_id,
  i.name as investor_name,
  p.id as party_id,
  p.name as party_name
FROM investors i
LEFT JOIN parties p ON i.id = p.id
WHERE i.id IN (201, 1338)
ORDER BY i.id;

-- Step 4: Find the party for the existing agreements
SELECT
  a.id as agreement_id,
  a.party_id,
  p.name as party_name,
  a.deal_id,
  a.fund_id
FROM agreements a
JOIN parties p ON a.party_id = p.id
ORDER BY a.id;

-- Step 5: Search for Rakefet Kuperman in parties table
SELECT *
FROM parties
WHERE name ILIKE '%Rakefet%' OR name ILIKE '%Kuperman%';
