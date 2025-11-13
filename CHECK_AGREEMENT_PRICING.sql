-- Step 1: Check agreements table structure for pricing columns
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'agreements'
ORDER BY ordinal_position;

-- Step 2: Compare agreement 1 (has pricing) vs agreement 6 (no pricing)
SELECT
  id,
  party_id,
  status,
  pricing_mode,
  vat_included
FROM agreements
WHERE id IN (1, 6)
ORDER BY id;

-- Step 3: Check if there's a separate pricing/tiers table
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND (table_name LIKE '%tier%' OR table_name LIKE '%pricing%' OR table_name LIKE '%fee%')
ORDER BY table_name;
