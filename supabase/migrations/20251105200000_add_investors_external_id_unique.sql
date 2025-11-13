-- Add UNIQUE constraint to external_id on investors table
-- This enables ON CONFLICT upserts in the Vantage sync process

ALTER TABLE investors
ADD CONSTRAINT investors_external_id_unique UNIQUE (external_id);

-- Verify
SELECT constraint_name, constraint_type
FROM information_schema.table_constraints
WHERE table_name = 'investors' AND constraint_name = 'investors_external_id_unique';
