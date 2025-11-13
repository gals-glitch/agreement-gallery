-- Check which migrations have been applied
SELECT version, name, executed_at
FROM supabase_migrations.schema_migrations
ORDER BY executed_at DESC
LIMIT 20;

-- Check if investor_source_kind ENUM exists
SELECT typname, typtype, typcategory
FROM pg_type
WHERE typname = 'investor_source_kind';

-- Check actual investors table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'investors'
ORDER BY ordinal_position;
