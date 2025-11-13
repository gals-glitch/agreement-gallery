-- Add UNIQUE constraint to external_id on investors table
-- Run in Supabase SQL Editor

ALTER TABLE investors
ADD CONSTRAINT investors_external_id_unique UNIQUE (external_id);

-- Verify
SELECT constraint_name, constraint_type
FROM information_schema.table_constraints
WHERE table_name = 'investors';
