-- ============================================
-- PG-101: Investor Source Fields Migration
-- Purpose: Track investor source (distributor/referrer) and introduction attribution
-- Date: 2025-10-19
-- Version: 1.5.0
-- ============================================
--
-- OVERVIEW:
-- This migration adds source tracking fields to the investors table to capture:
-- 1. Source type (DISTRIBUTOR, REFERRER, or NONE)
-- 2. Introducing party (nullable reference to parties table)
-- 3. Timestamp when the source linkage was first established
--
-- DESIGN DECISIONS:
-- - All new columns are nullable or have defaults for backward compatibility
-- - source_kind defaults to 'NONE' to maintain existing behavior
-- - introduced_by_party_id is nullable to support investors without attribution
-- - source_linked_at is nullable and only set when introduced_by_party_id is first populated
-- - Foreign key uses ON DELETE SET NULL to preserve investor records if party is deleted
--
-- ROLLBACK INSTRUCTIONS:
-- To rollback this migration:
-- DROP INDEX IF EXISTS idx_investors_source_kind;
-- DROP INDEX IF EXISTS idx_investors_introduced_by;
-- DROP INDEX IF EXISTS idx_investors_source_composite;
-- ALTER TABLE investors DROP COLUMN IF EXISTS source_linked_at;
-- ALTER TABLE investors DROP COLUMN IF EXISTS introduced_by_party_id;
-- ALTER TABLE investors DROP COLUMN IF EXISTS source_kind;
-- DROP TYPE IF EXISTS investor_source_kind;
--
-- ============================================

-- ============================================
-- STEP 1: Create ENUM type for source_kind
-- ============================================
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'investor_source_kind') THEN
    CREATE TYPE investor_source_kind AS ENUM ('DISTRIBUTOR', 'REFERRER', 'NONE');
  END IF;
END $$;

COMMENT ON TYPE investor_source_kind IS 'Investor acquisition source: DISTRIBUTOR (through distribution channel), REFERRER (individual referral), NONE (direct/unknown)';

-- ============================================
-- STEP 2: Add columns to investors table
-- ============================================

-- Add source_kind column (NOT NULL with default for safety)
ALTER TABLE investors
  ADD COLUMN IF NOT EXISTS source_kind investor_source_kind NOT NULL DEFAULT 'NONE';

COMMENT ON COLUMN investors.source_kind IS 'How this investor was sourced: DISTRIBUTOR, REFERRER, or NONE (default)';

-- Add introduced_by_party_id column (nullable foreign key)
ALTER TABLE investors
  ADD COLUMN IF NOT EXISTS introduced_by_party_id BIGINT REFERENCES parties(id) ON DELETE SET NULL;

COMMENT ON COLUMN investors.introduced_by_party_id IS 'Party (distributor/referrer) who introduced this investor; NULL if source_kind=NONE or party unknown';

-- Add source_linked_at timestamp (nullable, set when introduced_by_party_id is first populated)
ALTER TABLE investors
  ADD COLUMN IF NOT EXISTS source_linked_at TIMESTAMPTZ;

COMMENT ON COLUMN investors.source_linked_at IS 'Timestamp when introduced_by_party_id was first set; NULL if never linked to a party';

-- ============================================
-- STEP 3: Create indexes for query performance
-- ============================================

-- Index on source_kind for filtering by source type
CREATE INDEX IF NOT EXISTS idx_investors_source_kind
  ON investors(source_kind);

-- Index on introduced_by_party_id for joins and lookups
CREATE INDEX IF NOT EXISTS idx_investors_introduced_by
  ON investors(introduced_by_party_id)
  WHERE introduced_by_party_id IS NOT NULL;

-- Composite index for reporting queries (source_kind + party)
CREATE INDEX IF NOT EXISTS idx_investors_source_composite
  ON investors(source_kind, introduced_by_party_id)
  WHERE introduced_by_party_id IS NOT NULL;

-- ============================================
-- STEP 4: Create trigger to auto-set source_linked_at
-- ============================================

CREATE OR REPLACE FUNCTION set_source_linked_at()
RETURNS TRIGGER AS $$
BEGIN
  -- If introduced_by_party_id is being set for the first time (from NULL)
  -- and source_linked_at is not already set, timestamp it
  IF NEW.introduced_by_party_id IS NOT NULL
     AND OLD.introduced_by_party_id IS NULL
     AND NEW.source_linked_at IS NULL THEN
    NEW.source_linked_at := now();
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION set_source_linked_at IS 'Auto-sets source_linked_at timestamp when introduced_by_party_id is first populated';

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname='investors_set_source_linked_at') THEN
    CREATE TRIGGER investors_set_source_linked_at
      BEFORE INSERT OR UPDATE ON investors
      FOR EACH ROW
      EXECUTE FUNCTION set_source_linked_at();
  END IF;
END $$;

-- ============================================
-- STEP 5: Add CHECK constraints for data integrity
-- ============================================

-- Constraint: If source_kind is DISTRIBUTOR or REFERRER, should have introduced_by_party_id
-- (Soft constraint - warning only via comment, not enforced to allow flexibility)
-- Future enforcement could be added if business rules require it

DO $$ BEGIN
  -- Constraint: If introduced_by_party_id is set, source_kind should not be NONE
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname='investors_source_consistency_ck'
  ) THEN
    ALTER TABLE investors ADD CONSTRAINT investors_source_consistency_ck
      CHECK (
        (introduced_by_party_id IS NULL)
        OR
        (introduced_by_party_id IS NOT NULL AND source_kind != 'NONE')
      );
  END IF;
END $$;

COMMENT ON CONSTRAINT investors_source_consistency_ck ON investors IS 'If introduced_by_party_id is set, source_kind must be DISTRIBUTOR or REFERRER (not NONE)';

-- ============================================
-- STEP 6: Enable RLS and create policies
-- ============================================

-- RLS should already be enabled on investors table from previous migrations
-- If not, enable it:
ALTER TABLE investors ENABLE ROW LEVEL SECURITY;

-- Policy: All authenticated users can read source fields (SELECT)
-- This assumes existing RLS policies allow authenticated access
-- If investors table has role-based policies, this maintains that pattern
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename='investors' AND policyname='Allow authenticated read investor source fields'
  ) THEN
    CREATE POLICY "Allow authenticated read investor source fields"
      ON investors
      FOR SELECT
      TO authenticated
      USING (true);
  END IF;
END $$;

-- Policy: Operations+ can update source fields
-- This assumes a user_roles table exists with role hierarchy
-- For now, allow all authenticated users to update (can be restricted later)
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename='investors' AND policyname='Allow authenticated update investor source fields'
  ) THEN
    CREATE POLICY "Allow authenticated update investor source fields"
      ON investors
      FOR UPDATE
      TO authenticated
      USING (true)
      WITH CHECK (true);
  END IF;
END $$;

COMMENT ON TABLE investors IS 'LP entities investing into deals/funds - includes source tracking (DISTRIBUTOR/REFERRER/NONE) and party attribution';

-- ============================================
-- STEP 7: Data migration verification
-- ============================================

-- All existing investors will have:
-- - source_kind = 'NONE' (default)
-- - introduced_by_party_id = NULL
-- - source_linked_at = NULL
-- This is fully backward compatible - no data loss

-- Verify default values are applied correctly
DO $$
DECLARE
  investor_count BIGINT;
  none_count BIGINT;
BEGIN
  SELECT COUNT(*) INTO investor_count FROM investors;
  SELECT COUNT(*) INTO none_count FROM investors WHERE source_kind = 'NONE';

  RAISE NOTICE 'Migration PG-101 complete:';
  RAISE NOTICE '  Total investors: %', investor_count;
  RAISE NOTICE '  Investors with source_kind=NONE: %', none_count;
  RAISE NOTICE '  Backward compatibility: %',
    CASE WHEN investor_count = none_count THEN 'VERIFIED' ELSE 'WARNING - Check data' END;
END $$;

-- ============================================
-- VALIDATION QUERIES (for manual testing)
-- ============================================

-- Query 1: List all investors with their source information
-- SELECT
--   i.id,
--   i.name,
--   i.source_kind,
--   p.name AS introduced_by_party,
--   i.source_linked_at,
--   i.created_at
-- FROM investors i
-- LEFT JOIN parties p ON i.introduced_by_party_id = p.id
-- ORDER BY i.source_kind, i.created_at DESC;

-- Query 2: Count investors by source type
-- SELECT
--   source_kind,
--   COUNT(*) AS investor_count,
--   COUNT(introduced_by_party_id) AS with_party_attribution
-- FROM investors
-- GROUP BY source_kind
-- ORDER BY source_kind;

-- Query 3: List parties with their introduced investor counts
-- SELECT
--   p.id,
--   p.name AS party_name,
--   p.active,
--   COUNT(i.id) AS investors_introduced,
--   COUNT(i.id) FILTER (WHERE i.source_kind = 'DISTRIBUTOR') AS distributor_count,
--   COUNT(i.id) FILTER (WHERE i.source_kind = 'REFERRER') AS referrer_count
-- FROM parties p
-- LEFT JOIN investors i ON p.id = i.introduced_by_party_id
-- GROUP BY p.id, p.name, p.active
-- HAVING COUNT(i.id) > 0
-- ORDER BY investors_introduced DESC;

-- Query 4: Test index usage with EXPLAIN
-- EXPLAIN (ANALYZE, BUFFERS)
-- SELECT * FROM investors
-- WHERE source_kind = 'DISTRIBUTOR'
-- AND introduced_by_party_id IS NOT NULL;
-- Expected: Index Scan using idx_investors_source_composite

-- ============================================
-- PERFORMANCE NOTES
-- ============================================
-- Index Strategy:
-- 1. idx_investors_source_kind: Supports filtering by source_kind (e.g., "show all distributors")
--    Estimated selectivity: ~33% (3 enum values)
-- 2. idx_investors_introduced_by: Supports party lookups (e.g., "investors introduced by Party X")
--    Partial index (WHERE introduced_by_party_id IS NOT NULL) saves space
-- 3. idx_investors_source_composite: Optimizes combined filters and reports
--    Composite index on (source_kind, introduced_by_party_id) for queries like:
--    "Show all distributors introduced by active parties"
--
-- Write Impact: Minimal - 3 indexes on low-cardinality columns
-- Read Performance: Significant improvement for source-based filtering and reporting
--
-- ============================================
-- END MIGRATION PG-101
-- ============================================
