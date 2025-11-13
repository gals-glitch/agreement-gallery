-- Step 1: Check charges table structure
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'charges'
ORDER BY ordinal_position;

-- Step 2: Verify the charge was created successfully
SELECT *
FROM charges
WHERE contribution_id = 1
ORDER BY created_at DESC;
