-- Step 1: Check advanced_commission_rules table structure
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'advanced_commission_rules'
ORDER BY ordinal_position;

-- Step 2: See all advanced commission rules
SELECT *
FROM advanced_commission_rules
LIMIT 10;

-- Step 3: Find how agreements link to rules
-- (Check if agreements table has a rule_id column)
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'agreements'
  AND column_name LIKE '%rule%'
ORDER BY ordinal_position;

-- Step 4: Check if there's a linking table between agreements and rules
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND (table_name LIKE '%agreement%rule%' OR table_name LIKE '%rule%agreement%')
ORDER BY table_name;

-- Step 5: Get more columns from agreements table to see what we missed
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'agreements'
ORDER BY ordinal_position;
