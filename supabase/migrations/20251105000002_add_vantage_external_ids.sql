-- ============================================
-- Add Vantage External IDs for ETL Sync
-- Purpose: Add external_id columns to investors for idempotent Vantage sync
-- Date: 2025-11-05
-- ============================================

-- ============================================
-- INVESTORS: Add external_id column
-- ============================================

ALTER TABLE investors
  ADD COLUMN IF NOT EXISTS external_id TEXT;

COMMENT ON COLUMN investors.external_id IS 'External ID from Vantage IR system (investor_id)';

-- Create unique index on external_id (allows NULLs, only unique when not NULL)
CREATE UNIQUE INDEX IF NOT EXISTS idx_investors_vantage_external_id_unique
  ON investors(external_id)
  WHERE external_id IS NOT NULL;

COMMENT ON INDEX idx_investors_vantage_external_id_unique IS 'Ensures Vantage investor_id is unique for idempotent upserts';

-- ============================================
-- DEALS: Add external_id column (Vantage funds → deals)
-- ============================================

ALTER TABLE deals
  ADD COLUMN IF NOT EXISTS external_id TEXT;

COMMENT ON COLUMN deals.external_id IS 'External ID from Vantage IR system (fund_id)';

-- Create unique index on external_id (allows NULLs, only unique when not NULL)
CREATE UNIQUE INDEX IF NOT EXISTS idx_deals_vantage_external_id_unique
  ON deals(external_id)
  WHERE external_id IS NOT NULL;

COMMENT ON INDEX idx_deals_vantage_external_id_unique IS 'Ensures Vantage fund_id is unique for idempotent upserts';

-- ============================================
-- ENTITIES: Add external_id column
-- ============================================

ALTER TABLE entities
  ADD COLUMN IF NOT EXISTS external_id TEXT;

COMMENT ON COLUMN entities.external_id IS 'External ID from Vantage IR system';

-- Create index on external_id
CREATE INDEX IF NOT EXISTS idx_entities_external_id
  ON entities(external_id);

-- Create unique index on external_id (allows NULLs, only unique when not NULL)
CREATE UNIQUE INDEX IF NOT EXISTS idx_entities_vantage_external_id_unique
  ON entities(external_id)
  WHERE external_id IS NOT NULL;

COMMENT ON INDEX idx_entities_vantage_external_id_unique IS 'Ensures Vantage IDs are unique for idempotent upserts';

-- ============================================
-- VERIFICATION
-- ============================================

DO $$
BEGIN
  RAISE NOTICE 'Vantage external_id columns created successfully:';
  RAISE NOTICE '  - investors.external_id (unique)';
  RAISE NOTICE '  - deals.external_id (unique)';
  RAISE NOTICE '  - entities.external_id (unique)';
END $$;
