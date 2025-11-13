-- Add external_id column to entities table for Vantage sync
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys/sql/new

BEGIN;

-- Add external_id column (if not exists)
ALTER TABLE entities ADD COLUMN IF NOT EXISTS external_id TEXT;

-- Add unique constraint
ALTER TABLE entities ADD CONSTRAINT entities_external_id_unique UNIQUE (external_id);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_entities_external_id ON entities(external_id);

-- Add comment
COMMENT ON COLUMN entities.external_id IS 'External system ID (e.g., Vantage investor_id) for idempotent sync';

COMMIT;

-- Verify
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'entities'
ORDER BY ordinal_position;
