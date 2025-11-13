-- Check constraints on investors table
SELECT
    constraint_name,
    constraint_type
FROM information_schema.table_constraints
WHERE table_name = 'investors'
ORDER BY constraint_type, constraint_name;

-- Check if there are duplicate names in existing investors
SELECT name, COUNT(*) as count
FROM investors
WHERE name IS NOT NULL
GROUP BY name
HAVING COUNT(*) > 1
ORDER BY count DESC;

-- SOLUTION: Drop the UNIQUE constraint on name
-- The external_id is the natural key for Vantage data
-- Names can be duplicates (e.g., "John Smith" appearing multiple times)
ALTER TABLE investors DROP CONSTRAINT IF EXISTS investors_name_key;

-- Verify constraint is removed
SELECT constraint_name
FROM information_schema.table_constraints
WHERE table_name = 'investors' AND constraint_name = 'investors_name_key';
