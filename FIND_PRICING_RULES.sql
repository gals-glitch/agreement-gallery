-- Step 1: Find tables related to rules or pricing
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND (table_name LIKE '%rule%' OR table_name LIKE '%commission%')
ORDER BY table_name;

-- Step 2: Check commission_rules table structure (if it exists)
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'commission_rules'
ORDER BY ordinal_position;

-- Step 3: See all commission rules
SELECT *
FROM commission_rules
LIMIT 10;

-- Step 4: Find which rule is linked to agreement 1
-- (There might be a foreign key in agreements table pointing to commission_rules)
SELECT
  a.id as agreement_id,
  a.party_id,
  a.status,
  a.pricing_mode
FROM agreements a
WHERE a.id = 1;
