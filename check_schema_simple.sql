-- Check what columns exist in investors table
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'investors'
ORDER BY ordinal_position;
