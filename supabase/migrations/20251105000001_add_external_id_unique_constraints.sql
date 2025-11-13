-- ============================================
-- Add External ID Unique Constraints
-- Purpose: Enable idempotent upserts for Vantage ETL sync
-- Date: 2025-11-05
-- ============================================

-- ============================================
-- INVESTORS: Add unique constraint on external_id
-- ============================================

-- Create unique index on external_id (allows NULLs, only unique when not NULL)
CREATE UNIQUE INDEX IF NOT EXISTS idx_investors_external_id_unique
  ON investors(external_id)
  WHERE external_id IS NOT NULL;

COMMENT ON INDEX idx_investors_external_id_unique IS 'Ensures external_id from Vantage is unique for idempotent upserts';

-- ============================================
-- FUNDS: Add external_id column if missing
-- ============================================

ALTER TABLE funds
  ADD COLUMN IF NOT EXISTS external_id TEXT;

COMMENT ON COLUMN funds.external_id IS 'External ID from Vantage system';

-- Create index on external_id
CREATE INDEX IF NOT EXISTS idx_funds_external_id
  ON funds(external_id);

-- Create unique index on external_id (allows NULLs, only unique when not NULL)
CREATE UNIQUE INDEX IF NOT EXISTS idx_funds_external_id_unique
  ON funds(external_id)
  WHERE external_id IS NOT NULL;

COMMENT ON INDEX idx_funds_external_id_unique IS 'Ensures external_id from Vantage is unique for idempotent upserts';

-- ============================================
-- VERIFICATION
-- ============================================

DO $$
BEGIN
  RAISE NOTICE 'External ID unique constraints created successfully';
  RAISE NOTICE 'Investors table: external_id unique index active';
  RAISE NOTICE 'Funds table: external_id column added with unique index';
END $$;
