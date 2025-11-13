-- Check all columns in charges table
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'charges'
ORDER BY ordinal_position;
