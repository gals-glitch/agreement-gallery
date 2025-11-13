-- Check actual investors table schema
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'investors'
ORDER BY ordinal_position;
