-- Drop UNIQUE constraint on investors.name
-- Reason: Vantage data contains duplicate names (different people with same name)
-- The external_id is the natural unique identifier for Vantage sync
ALTER TABLE investors DROP CONSTRAINT IF EXISTS investors_name_key;

-- Verify
SELECT constraint_name
FROM information_schema.table_constraints
WHERE table_name = 'investors' AND constraint_name = 'investors_name_key';
