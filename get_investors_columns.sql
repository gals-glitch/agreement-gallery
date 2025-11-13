-- Get all column names from investors table
-- Copy this SQL and run it in Supabase SQL Editor
-- https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys/sql/new

SELECT column_name
FROM information_schema.columns
WHERE table_name = 'investors'
ORDER BY ordinal_position;
