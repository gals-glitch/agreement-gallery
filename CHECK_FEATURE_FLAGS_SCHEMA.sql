-- Check feature_flags table schema
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'feature_flags'
ORDER BY ordinal_position;

-- Check existing feature flags
SELECT * FROM feature_flags;
