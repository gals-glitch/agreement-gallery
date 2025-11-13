-- ============================================
-- STEP 0: Apply Investor Source Fields Migration
-- RUN THIS FIRST before importing CSV data
-- ============================================

-- This migration adds the following columns to investors table:
-- - source_kind (ENUM: DISTRIBUTOR, REFERRER, NONE)
-- - introduced_by_party_id (FK to parties)
-- - source_linked_at (timestamp)

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

ALTER TABLE investors ENABLE ROW LEVEL SECURITY;

-- Policy: All authenticated users can read source fields (SELECT)
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
-- VERIFICATION
-- ============================================

-- Verify columns exist
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'investors'
AND column_name IN ('source_kind', 'introduced_by_party_id', 'source_linked_at');

-- Should return 3 rows if successful

SELECT 'Migration applied successfully! You can now run the import.' as status;
