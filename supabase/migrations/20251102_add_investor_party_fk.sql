-- Migration: Add introduced_by_party_id column with backfill from notes
-- Ticket: DB-01
-- Date: 2025-11-02

BEGIN;

-- ============================================
-- 1. Add column and foreign key
-- ============================================

ALTER TABLE investors
  ADD COLUMN IF NOT EXISTS introduced_by_party_id BIGINT REFERENCES parties(id);

COMMENT ON COLUMN investors.introduced_by_party_id IS
  'Party who introduced this investor (determines commission recipient)';

-- ============================================
-- 2. Create index for performance
-- ============================================

CREATE INDEX IF NOT EXISTS idx_investors_introduced_by_party
  ON investors(introduced_by_party_id);

-- ============================================
-- 3. Backfill from notes pattern: "Introduced by: <party name>"
-- ============================================

-- Exact match on party name extracted from notes
UPDATE investors i
SET introduced_by_party_id = p.id
FROM parties p
WHERE i.introduced_by_party_id IS NULL
  AND i.notes ~ 'Introduced by:\s*'
  AND trim(regexp_replace(i.notes, '.*Introduced by:\s*([^;]+).*', '\1')) = p.name;

-- ============================================
-- 4. Create party_aliases table for fuzzy matching
-- ============================================

CREATE TABLE IF NOT EXISTS party_aliases (
  alias TEXT PRIMARY KEY,
  party_id BIGINT NOT NULL REFERENCES parties(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  created_by TEXT,
  notes TEXT
);

COMMENT ON TABLE party_aliases IS
  'Alternative names/spellings for parties to support backfill and CSV imports';

-- Example aliases (customize based on your data)
-- INSERT INTO party_aliases (alias, party_id, created_by, notes) VALUES
--   ('Avi F.', 182, 'migration', 'Short form for Avi Fried'),
--   ('Capital Link - Shiri', 187, 'migration', 'Variant spelling')
-- ON CONFLICT (alias) DO NOTHING;

-- ============================================
-- 5. Backfill using aliases where exact name didn't match
-- ============================================

UPDATE investors i
SET introduced_by_party_id = a.party_id
FROM party_aliases a
WHERE i.introduced_by_party_id IS NULL
  AND i.notes ~ 'Introduced by:\s*'
  AND trim(regexp_replace(i.notes, '.*Introduced by:\s*([^;]+).*', '\1')) = a.alias;

-- ============================================
-- 6. Log backfill results
-- ============================================

DO $$
DECLARE
  backfilled_count INT;
  remaining_count INT;
BEGIN
  SELECT COUNT(*) INTO backfilled_count
  FROM investors
  WHERE introduced_by_party_id IS NOT NULL;

  SELECT COUNT(*) INTO remaining_count
  FROM investors
  WHERE introduced_by_party_id IS NULL;

  RAISE NOTICE 'Backfill complete: % investors linked, % remain unlinked',
    backfilled_count, remaining_count;
END $$;

COMMIT;

-- ============================================
-- Post-migration verification queries
-- ============================================

-- Run these to check results:

-- 1. Show investors still missing party links
-- SELECT id, name, LEFT(notes, 100) AS notes_preview
-- FROM investors
-- WHERE introduced_by_party_id IS NULL
-- ORDER BY name
-- LIMIT 50;

-- 2. Show distribution of party links
-- SELECT
--   p.name AS party_name,
--   COUNT(i.id) AS investor_count
-- FROM parties p
-- LEFT JOIN investors i ON i.introduced_by_party_id = p.id
-- GROUP BY p.id, p.name
-- ORDER BY investor_count DESC;

-- 3. Find potential backfill candidates (notes contain "Introduced by" but not linked)
-- SELECT
--   i.name AS investor_name,
--   trim(regexp_replace(i.notes, '.*Introduced by:\s*([^;]+).*', '\1')) AS extracted_party_name
-- FROM investors i
-- WHERE i.introduced_by_party_id IS NULL
--   AND i.notes ~ 'Introduced by:\s*'
-- ORDER BY i.name;
