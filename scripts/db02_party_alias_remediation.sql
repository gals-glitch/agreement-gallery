-- ============================================================================
-- DB-02: Party Alias Remediation
--
-- Objective: Unlock 72 blocked contributions where investors.introduced_by_party_id IS NULL
-- Process: Analysis → Validation → Execution → Recompute → (Rollback if needed)
--
-- SAFETY: This script creates staging tables for review before applying changes.
-- Finance team MUST review and approve matches before executing inserts.
-- ============================================================================

-- ============================================================================
-- STEP 0: SAFETY PREP
-- ============================================================================

-- Enable similarity extension if not already enabled
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Create audit table for tracking alias insertions
CREATE TABLE IF NOT EXISTS party_aliases_audit (
  id bigserial PRIMARY KEY,
  alias text NOT NULL,
  party_id bigint NOT NULL,
  inserted_by text NOT NULL,
  inserted_at timestamptz NOT NULL DEFAULT now(),
  batch_id text,
  notes text
);

-- Create index for faster rollback lookups
CREATE INDEX IF NOT EXISTS idx_party_aliases_audit_inserted_at
  ON party_aliases_audit(inserted_at);

CREATE INDEX IF NOT EXISTS idx_party_aliases_audit_batch_id
  ON party_aliases_audit(batch_id) WHERE batch_id IS NOT NULL;

-- ============================================================================
-- STEP 1: ANALYSIS PHASE
-- ============================================================================

-- A) Identify all blocked investors (no party link)
-- These are the investors preventing commission calculation
SELECT
  i.id AS investor_id,
  i.name AS investor_name,
  COUNT(c.id) AS contribution_count,
  SUM(c.amount) AS total_value,
  STRING_AGG(DISTINCT d.name, ', ') AS deals,
  STRING_AGG(DISTINCT f.name, ', ') AS funds
FROM contributions c
JOIN investors i ON i.id = c.investor_id
LEFT JOIN deals d ON d.id = c.deal_id
LEFT JOIN funds f ON f.id = c.fund_id
WHERE i.introduced_by_party_id IS NULL
GROUP BY i.id, i.name
ORDER BY total_value DESC NULLS LAST;

-- Expected: ~72 contributions across multiple investors
-- Review this list to understand which investors are blocking the most value


-- B) Auto-suggest party matches using fuzzy matching
-- This query finds potential party matches with confidence scores ≥ 60%
WITH candidates AS (
  SELECT DISTINCT
    i.id AS investor_id,
    i.name AS investor_name
  FROM investors i
  WHERE i.introduced_by_party_id IS NULL
),
scored AS (
  SELECT
    c.investor_id,
    c.investor_name,
    p.id AS party_id,
    p.name AS party_name,
    GREATEST(
      similarity(c.investor_name, p.name),
      similarity(
        regexp_replace(c.investor_name, '[^A-Za-zא-ת ]', '', 'g'),
        regexp_replace(p.name, '[^A-Za-zא-ת ]', '', 'g')
      )
    ) AS score
  FROM candidates c
  CROSS JOIN parties p
)
SELECT
  investor_id,
  investor_name,
  party_id,
  party_name,
  ROUND(score::numeric, 3) AS confidence_score
FROM scored
WHERE score >= 0.60
ORDER BY score DESC, investor_name;

-- Expected: List of suggested matches with confidence scores
-- Scores 0.80+ are usually safe; 0.60-0.79 need manual review


-- C) Check for existing aliases to avoid duplicates
SELECT
  a.alias,
  p.name AS party_name,
  COUNT(*) AS usage_count
FROM party_aliases a
JOIN parties p ON p.id = a.party_id
GROUP BY a.alias, p.name
ORDER BY usage_count DESC;


-- D) Identify investors from Vantage imports (likely source of missing links)
-- These investors were bulk-imported and may need manual mapping
SELECT
  i.id,
  i.name,
  i.source_system,
  i.notes,
  COUNT(c.id) AS contribution_count
FROM investors i
LEFT JOIN contributions c ON c.investor_id = i.id
WHERE i.introduced_by_party_id IS NULL
  AND (i.source_system = 'vantage' OR i.notes LIKE '%Vantage%')
GROUP BY i.id, i.name, i.source_system, i.notes
ORDER BY contribution_count DESC;


-- ============================================================================
-- STEP 2: STAGING FOR VALIDATION
-- ============================================================================

-- Create staging table for proposed mappings
-- Finance team will review and set approved = TRUE for valid matches
CREATE TABLE IF NOT EXISTS party_aliases_staging (
  id bigserial PRIMARY KEY,
  investor_id bigint NOT NULL,
  investor_name text NOT NULL,
  party_id bigint NOT NULL,
  party_name text NOT NULL,
  score numeric NOT NULL,
  approved boolean NOT NULL DEFAULT false,
  reviewer text,
  reviewed_at timestamptz,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Clear staging table if re-running
TRUNCATE TABLE party_aliases_staging;

-- Insert high-confidence matches (≥ 0.70) for review
INSERT INTO party_aliases_staging (investor_id, investor_name, party_id, party_name, score)
SELECT
  investor_id,
  investor_name,
  party_id,
  party_name,
  ROUND(score::numeric, 3)
FROM (
  WITH candidates AS (
    SELECT DISTINCT
      i.id AS investor_id,
      i.name AS investor_name
    FROM investors i
    WHERE i.introduced_by_party_id IS NULL
  ),
  scored AS (
    SELECT
      c.investor_id,
      c.investor_name,
      p.id AS party_id,
      p.name AS party_name,
      GREATEST(
        similarity(c.investor_name, p.name),
        similarity(
          regexp_replace(c.investor_name, '[^A-Za-zא-ת ]', '', 'g'),
          regexp_replace(p.name, '[^A-Za-zא-ת ]', '', 'g')
        )
      ) AS score
    FROM candidates c
    CROSS JOIN parties p
  )
  SELECT * FROM scored WHERE score >= 0.70
) suggestions;

-- View staged suggestions for review
SELECT
  id,
  investor_name,
  party_name,
  score,
  approved,
  reviewer,
  notes
FROM party_aliases_staging
ORDER BY score DESC;

-- ⚠️ FINANCE TEAM ACTION REQUIRED:
-- Review the staging table and update approved = TRUE for valid matches
-- Example:
--   UPDATE party_aliases_staging SET approved = TRUE, reviewer = 'finance@example.com' WHERE id IN (1, 2, 5);


-- ============================================================================
-- STEP 3: EXECUTION (Run after Finance approval)
-- ============================================================================

-- Verification: Check how many are approved
SELECT
  COUNT(*) FILTER (WHERE approved = TRUE) AS approved_count,
  COUNT(*) FILTER (WHERE approved = FALSE) AS pending_count,
  COUNT(*) AS total_count
FROM party_aliases_staging;

-- E) Insert approved aliases into production table
BEGIN;

-- Generate batch ID for tracking
DO $$
DECLARE
  batch_id text := 'db02_' || to_char(now(), 'YYYYMMDD_HH24MISS');
BEGIN
  -- Insert approved aliases
  INSERT INTO party_aliases (alias, party_id)
  SELECT DISTINCT
    s.investor_name,
    s.party_id
  FROM party_aliases_staging s
  WHERE s.approved = TRUE
  ON CONFLICT (alias) DO NOTHING;  -- Skip if alias already exists

  -- Audit trail
  INSERT INTO party_aliases_audit (alias, party_id, inserted_by, batch_id, notes)
  SELECT DISTINCT
    s.investor_name,
    s.party_id,
    COALESCE(s.reviewer, current_user),
    batch_id,
    'DB-02 remediation - Score: ' || s.score
  FROM party_aliases_staging s
  WHERE s.approved = TRUE;

  RAISE NOTICE 'Batch ID: %', batch_id;
END $$;

COMMIT;

-- Verify insertions
SELECT
  a.alias,
  p.name AS party_name,
  audit.inserted_at,
  audit.inserted_by,
  audit.batch_id
FROM party_aliases a
JOIN parties p ON p.id = a.party_id
JOIN party_aliases_audit audit ON audit.alias = a.alias AND audit.party_id = a.party_id
WHERE audit.inserted_at >= now() - interval '5 minutes'
ORDER BY audit.inserted_at DESC;


-- F) Link investors by exact alias match
-- This updates investors.introduced_by_party_id for newly added aliases
BEGIN;

UPDATE investors i
SET
  introduced_by_party_id = p.id,
  updated_at = now()
FROM party_aliases a
JOIN parties p ON p.id = a.party_id
WHERE i.introduced_by_party_id IS NULL
  AND i.name = a.alias;

-- Report how many were linked
SELECT COUNT(*) AS investors_linked
FROM investors i
JOIN party_aliases a ON a.alias = i.name
WHERE i.updated_at >= now() - interval '1 minute';

COMMIT;


-- G) Verify coverage improvement
-- Compare before/after coverage
SELECT
  COUNT(*) FILTER (WHERE introduced_by_party_id IS NOT NULL) AS linked_count,
  COUNT(*) FILTER (WHERE introduced_by_party_id IS NULL) AS unlinked_count,
  ROUND(
    100.0 * COUNT(*) FILTER (WHERE introduced_by_party_id IS NOT NULL) / COUNT(*),
    2
  ) AS coverage_percent
FROM investors
WHERE EXISTS (
  SELECT 1 FROM contributions c WHERE c.investor_id = investors.id
);


-- ============================================================================
-- STEP 4: RECOMPUTE COMMISSIONS
-- ============================================================================

-- After executing the alias inserts and investor links,
-- trigger commission computation via API:
--
--   POST /api/v1/commissions/batch-compute
--   Body: { "trigger": "db02_remediation" }
--
-- Or via the UI: Click "Compute Eligible" button
--
-- This will process all newly-linked investors and create commissions


-- H) Validate new commissions created
-- Check commissions created in last 10 minutes
SELECT
  c.id,
  i.name AS investor_name,
  p.name AS party_name,
  c.total_amount,
  c.status,
  c.computed_at
FROM commissions c
JOIN investors i ON i.id = c.investor_id
JOIN parties p ON p.id = c.party_id
WHERE c.computed_at >= now() - interval '10 minutes'
ORDER BY c.computed_at DESC;


-- I) Summary report: Before/After
-- Run this before and after DB-02 execution to compare
SELECT
  'Before DB-02' AS stage,
  COUNT(DISTINCT i.id) AS blocked_investors,
  COUNT(c.id) AS blocked_contributions,
  SUM(c.amount) AS blocked_value
FROM contributions c
JOIN investors i ON i.id = c.investor_id
WHERE i.introduced_by_party_id IS NULL

UNION ALL

SELECT
  'After DB-02' AS stage,
  COUNT(DISTINCT i.id) AS remaining_blocked_investors,
  COUNT(c.id) AS remaining_contributions,
  SUM(c.amount) AS remaining_value
FROM contributions c
JOIN investors i ON i.id = c.investor_id
WHERE i.introduced_by_party_id IS NULL;


-- ============================================================================
-- STEP 5: ROLLBACK (If needed - run within 24 hours)
-- ============================================================================

-- If aliases were incorrectly added, rollback using batch_id or timestamp

-- Option A: Rollback by batch_id (recommended)
BEGIN;

-- Replace 'db02_YYYYMMDD_HHMMSS' with actual batch_id from Step 3
DELETE FROM party_aliases a
USING party_aliases_audit audit
WHERE a.alias = audit.alias
  AND a.party_id = audit.party_id
  AND audit.batch_id = 'db02_YYYYMMDD_HHMMSS';  -- Replace with actual batch_id

-- Mark audit entries as rolled back
UPDATE party_aliases_audit
SET notes = COALESCE(notes, '') || ' [ROLLED BACK]'
WHERE batch_id = 'db02_YYYYMMDD_HHMMSS';

-- Unlink investors that were linked via these aliases
UPDATE investors i
SET
  introduced_by_party_id = NULL,
  updated_at = now()
FROM party_aliases_audit audit
WHERE i.name = audit.alias
  AND i.introduced_by_party_id = audit.party_id
  AND audit.batch_id = 'db02_YYYYMMDD_HHMMSS';

COMMIT;


-- Option B: Rollback by timestamp (use if batch_id unavailable)
BEGIN;

-- Replace '2025-11-10 08:00:00' with execution start time
DELETE FROM party_aliases a
USING party_aliases_audit audit
WHERE a.alias = audit.alias
  AND a.party_id = audit.party_id
  AND audit.inserted_at >= '2025-11-10 08:00:00'::timestamptz
  AND audit.inserted_at < '2025-11-10 09:00:00'::timestamptz;

UPDATE investors i
SET
  introduced_by_party_id = NULL,
  updated_at = now()
FROM party_aliases_audit audit
WHERE i.name = audit.alias
  AND i.introduced_by_party_id = audit.party_id
  AND audit.inserted_at >= '2025-11-10 08:00:00'::timestamptz;

COMMIT;


-- ============================================================================
-- APPENDIX: MANUAL ALIAS ADDITIONS
-- ============================================================================

-- If finance identifies additional manual mappings not caught by fuzzy matching,
-- add them here:

-- Example template:
/*
BEGIN;

INSERT INTO party_aliases (alias, party_id)
VALUES
  ('Investor Name Variant 1', (SELECT id FROM parties WHERE name = 'Canonical Party Name')),
  ('Investor Name Variant 2', (SELECT id FROM parties WHERE name = 'Canonical Party Name'))
ON CONFLICT (alias) DO NOTHING;

INSERT INTO party_aliases_audit (alias, party_id, inserted_by, notes)
VALUES
  ('Investor Name Variant 1', (SELECT id FROM parties WHERE name = 'Canonical Party Name'), 'finance@example.com', 'Manual addition - DB-02'),
  ('Investor Name Variant 2', (SELECT id FROM parties WHERE name = 'Canonical Party Name'), 'finance@example.com', 'Manual addition - DB-02');

-- Link investors
UPDATE investors i
SET introduced_by_party_id = p.id
FROM party_aliases a
JOIN parties p ON p.id = a.party_id
WHERE i.name = a.alias
  AND i.introduced_by_party_id IS NULL;

COMMIT;
*/


-- ============================================================================
-- SUCCESS METRICS
-- ============================================================================

-- Final validation: Check if we've unlocked the blocked commissions
SELECT
  'Eligible for commission computation' AS metric,
  COUNT(DISTINCT c.id) AS contribution_count,
  COUNT(DISTINCT i.id) AS investor_count,
  SUM(c.amount) AS total_value
FROM contributions c
JOIN investors i ON i.id = c.investor_id
WHERE i.introduced_by_party_id IS NOT NULL
  AND EXISTS (
    SELECT 1 FROM agreements a
    WHERE a.party_id = i.introduced_by_party_id
      AND (a.deal_id = c.deal_id OR a.fund_id = c.fund_id)
      AND a.status = 'APPROVED'
  );

-- Compare: How many commissions now exist vs. eligible contributions
SELECT
  (SELECT COUNT(*) FROM contributions c
   JOIN investors i ON i.id = c.investor_id
   WHERE i.introduced_by_party_id IS NOT NULL) AS eligible_contributions,

  (SELECT COUNT(*) FROM commissions) AS existing_commissions,

  (SELECT COUNT(*) FROM contributions c
   JOIN investors i ON i.id = c.investor_id
   WHERE i.introduced_by_party_id IS NOT NULL) -
  (SELECT COUNT(*) FROM commissions) AS gap;


-- ============================================================================
-- END OF DB-02 REMEDIATION SCRIPT
-- ============================================================================

-- 📋 CHECKLIST FOR FINANCE TEAM:
-- [ ] Run Step 1 queries to analyze blocked investors
-- [ ] Review Step 2 staging table and approve matches
-- [ ] Execute Step 3 after approvals (transaction is safe)
-- [ ] Trigger recompute via UI button or API
-- [ ] Validate Step 4 results (new commissions created)
-- [ ] Keep batch_id for potential rollback
-- [ ] Update DB-02 ticket status to "Complete"
