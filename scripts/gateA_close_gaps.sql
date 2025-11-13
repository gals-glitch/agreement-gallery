-- scripts/gateA_close_gaps.sql
-- Gate A Gap Closer: Auto-link investors to parties via fuzzy matching
-- Target: ≥80% coverage for introduced_by_party_id
--
-- What it does:
-- 1. Enables pg_trgm extension for fuzzy text matching
-- 2. Creates party_aliases table for name variations
-- 3. Seeds explicit high-confidence aliases for known parties
-- 4. Uses fuzzy matching to suggest best party for each "Introduced by:" note
-- 5. Backfills introduced_by_party_id using the alias mappings
-- 6. Reports coverage statistics

BEGIN;

-- 0) Safety: extensions + table (if migration already created them, these are no-ops)
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE TABLE IF NOT EXISTS party_aliases (
  alias    text PRIMARY KEY,
  party_id bigint REFERENCES parties(id)
);

-- 1) Seed explicit, high-confidence aliases for known variations
INSERT INTO party_aliases (alias, party_id)
VALUES
  -- Capital Link
  ('Capital Link Family Office', (SELECT id FROM parties WHERE name = 'Capital Link Family Office- Shiri Hybloom' LIMIT 1)),
  ('Capital Link',               (SELECT id FROM parties WHERE name = 'Capital Link Family Office- Shiri Hybloom' LIMIT 1)),
  ('Shiri Hybloom',              (SELECT id FROM parties WHERE name = 'Capital Link Family Office- Shiri Hybloom' LIMIT 1)),
  -- Avi Fried
  ('Avi Fried',                  (SELECT id FROM parties WHERE name = 'Avi Fried (פאים הולדינגס)' LIMIT 1)),
  ('פאים הולדינגס',             (SELECT id FROM parties WHERE name = 'Avi Fried (פאים הולדינגס)' LIMIT 1)),
  -- David Kirchenbaum
  ('David Kirchenbaum',          (SELECT id FROM parties WHERE name = 'David Kirchenbaum (קרוס ארץ'' החזקות)' LIMIT 1)),
  ('קרוס ארץ',                   (SELECT id FROM parties WHERE name = 'David Kirchenbaum (קרוס ארץ'' החזקות)' LIMIT 1))
ON CONFLICT (alias) DO UPDATE SET party_id = EXCLUDED.party_id;

-- 2) Build candidates from investor notes (those still missing a link)
WITH candidates AS (
  SELECT DISTINCT
         trim(substring(i.notes FROM 'Introduced by:\s*([^;]+)')) AS raw_alias
  FROM investors i
  WHERE i.introduced_by_party_id IS NULL
    AND i.notes LIKE '%Introduced by:%'
    AND trim(substring(i.notes FROM 'Introduced by:\s*([^;]+)')) IS NOT NULL
),
scored AS (
  SELECT c.raw_alias,
         p.id   AS party_id,
         p.name AS party_name,
         GREATEST(
            similarity(c.raw_alias, p.name),
            similarity(
              regexp_replace(c.raw_alias, '[^A-Za-zא-ת ]', '', 'g'),
              regexp_replace(p.name,       '[^A-Za-zא-ת ]', '', 'g')
            )
         ) AS score
  FROM candidates c
  CROSS JOIN parties p
),
best AS (
  SELECT DISTINCT ON (raw_alias)
         raw_alias, party_id, party_name, score
  FROM scored
  ORDER BY raw_alias, score DESC
)
-- 3) Insert fuzzy matches above threshold into alias table
INSERT INTO party_aliases (alias, party_id)
SELECT raw_alias, party_id
FROM best
WHERE score >= 0.60
ON CONFLICT (alias) DO UPDATE SET party_id = EXCLUDED.party_id;

-- 4) Backfill investor FK via aliases
UPDATE investors i
SET introduced_by_party_id = pa.party_id
FROM party_aliases pa
WHERE i.introduced_by_party_id IS NULL
  AND i.notes LIKE '%Introduced by:%'
  AND trim(substring(i.notes FROM 'Introduced by:\s*([^;]+)')) = pa.alias;

COMMIT;

-- 5) Quick report
SELECT
  COUNT(*)                               AS total_investors,
  COUNT(introduced_by_party_id)          AS with_party_links,
  COUNT(*) - COUNT(introduced_by_party_id) AS without_party_links,
  ROUND(100.0 * COUNT(introduced_by_party_id) / NULLIF(COUNT(*), 0), 1) AS coverage_pct
FROM investors;

-- 6) Show top unmatched "Introduced by" values (for manual review if needed)
SELECT
  trim(substring(i.notes FROM 'Introduced by:\s*([^;]+)')) AS unmatched_introducer,
  COUNT(*) AS investor_count
FROM investors i
WHERE i.introduced_by_party_id IS NULL
  AND i.notes LIKE '%Introduced by:%'
  AND trim(substring(i.notes FROM 'Introduced by:\s*([^;]+)')) IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;
