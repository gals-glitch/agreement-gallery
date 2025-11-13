-- ============================================================================
-- Migration: Fix Party Foreign Key Type Mismatch
-- Date: 2025-11-11
-- Purpose: Change distributor_id from UUID to BIGINT to match parties.id
--
-- Problem: parties.id is BIGINT but distributor_rules.distributor_id and
-- sub_agents.distributor_id are UUID, causing type mismatch errors
-- ============================================================================

-- Fix distributor_rules.distributor_id
ALTER TABLE distributor_rules
DROP COLUMN IF EXISTS distributor_id;

ALTER TABLE distributor_rules
ADD COLUMN distributor_id BIGINT REFERENCES parties(id);

CREATE INDEX IF NOT EXISTS idx_distributor_rules_distributor_id
ON distributor_rules(distributor_id);

-- Fix sub_agents.distributor_id
ALTER TABLE sub_agents
DROP COLUMN IF EXISTS distributor_id;

ALTER TABLE sub_agents
ADD COLUMN distributor_id BIGINT REFERENCES parties(id);

CREATE INDEX IF NOT EXISTS idx_sub_agents_distributor_id
ON sub_agents(distributor_id);

-- Add helpful comments
COMMENT ON COLUMN distributor_rules.distributor_id IS 'Foreign key to parties.id (BIGINT)';
COMMENT ON COLUMN sub_agents.distributor_id IS 'Foreign key to parties.id (BIGINT)';

-- ============================================================================
-- Verification Queries (run after migration)
-- ============================================================================

-- Verify column types match
-- SELECT
--   'parties.id' as column_ref, data_type
-- FROM information_schema.columns
-- WHERE table_name = 'parties' AND column_name = 'id'
-- UNION ALL
-- SELECT
--   'distributor_rules.distributor_id', data_type
-- FROM information_schema.columns
-- WHERE table_name = 'distributor_rules' AND column_name = 'distributor_id'
-- UNION ALL
-- SELECT
--   'sub_agents.distributor_id', data_type
-- FROM information_schema.columns
-- WHERE table_name = 'sub_agents' AND column_name = 'distributor_id';
-- Expected: All should be 'bigint'
