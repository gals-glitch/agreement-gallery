-- ============================================
-- AGR-01: Agreement Snapshot Fix Scripts
-- Version: 1.8.0 - Investor Fee Workflow E2E
-- Date: 2025-10-21
-- ============================================
--
-- PURPOSE:
-- Provide SQL fix scripts for common agreement snapshot integrity issues.
-- These scripts repair data corruption or missing snapshots to ensure
-- charge computation can proceed without errors.
--
-- SAFETY:
-- - All scripts include WHERE clauses to prevent accidental mass updates
-- - Test scripts on staging/dev environment first
-- - Review affected rows before executing (use SELECT first, then UPDATE)
-- - Back up data before running fix scripts
--
-- WORKFLOW:
-- 1. Run health check queries (AGR_HEALTH_CHECK_QUERIES.sql)
-- 2. Identify issues and affected agreement IDs
-- 3. Select appropriate fix script below
-- 4. Replace <agreement_id> placeholders with actual IDs
-- 5. Execute fix script
-- 6. Re-run health check to verify fix
--
-- ============================================

-- ============================================
-- FIX SCRIPT 1: Create Missing Snapshots
-- ============================================
-- Use Case: APPROVED agreements without snapshots (detected by health check QUERY 1)
-- Root Cause: Trigger malfunction, manual status update, or data migration issue
--
-- How It Works:
-- - Manually recreates the snapshot that should have been created by the trigger
-- - Resolves pricing from fund_tracks (if TRACK mode) or agreement_custom_terms (if CUSTOM mode)
-- - Looks up VAT rate from party's country
-- - Inserts snapshot with current timestamp (snapshotted_at = now())
--
-- IMPORTANT:
-- - This script assumes the agreement still has access to the correct pricing data
-- - If pricing data has changed since approval, the snapshot may not reflect historical rates
-- - For production use, consider adding manual verification step

-- Step 1: Preview affected agreements (SELECT before UPDATE)
SELECT
  a.id AS agreement_id,
  a.party_id,
  p.name AS party_name,
  a.scope,
  a.pricing_mode,
  a.selected_track,
  a.effective_from,
  a.effective_to,
  a.vat_included,
  -- Resolved pricing (will be inserted into snapshot)
  CASE
    WHEN a.pricing_mode = 'TRACK' THEN (
      SELECT ft.upfront_bps
      FROM fund_tracks ft
      WHERE ft.fund_id = COALESCE(a.fund_id, (SELECT fund_id FROM deals WHERE id = a.deal_id))
        AND ft.track_code = a.selected_track
        AND ft.valid_from <= a.effective_from
        AND (ft.valid_to IS NULL OR ft.valid_to >= a.effective_from)
      ORDER BY ft.valid_from DESC
      LIMIT 1
    )
    WHEN a.pricing_mode = 'CUSTOM' THEN (
      SELECT act.upfront_bps
      FROM agreement_custom_terms act
      WHERE act.agreement_id = a.id
    )
  END AS resolved_upfront_bps,
  CASE
    WHEN a.pricing_mode = 'TRACK' THEN (
      SELECT ft.deferred_bps
      FROM fund_tracks ft
      WHERE ft.fund_id = COALESCE(a.fund_id, (SELECT fund_id FROM deals WHERE id = a.deal_id))
        AND ft.track_code = a.selected_track
        AND ft.valid_from <= a.effective_from
        AND (ft.valid_to IS NULL OR ft.valid_to >= a.effective_from)
      ORDER BY ft.valid_from DESC
      LIMIT 1
    )
    WHEN a.pricing_mode = 'CUSTOM' THEN (
      SELECT act.deferred_bps
      FROM agreement_custom_terms act
      WHERE act.agreement_id = a.id
    )
  END AS resolved_deferred_bps,
  -- VAT rate lookup
  (
    SELECT vr.rate_percentage
    FROM vat_rates vr
    WHERE vr.country_code = p.country
      AND vr.effective_from <= a.effective_from
      AND (vr.effective_to IS NULL OR vr.effective_to > a.effective_from)
    ORDER BY vr.effective_from DESC
    LIMIT 1
  ) AS vat_rate_percent
FROM agreements a
JOIN parties p ON a.party_id = p.id
WHERE a.status = 'APPROVED'
  AND NOT EXISTS (
    SELECT 1
    FROM agreement_rate_snapshots ars
    WHERE ars.agreement_id = a.id
  )
  -- SAFETY: Add specific agreement ID filter (replace <agreement_id> with actual ID)
  -- AND a.id = <agreement_id>
;

-- Step 2: Create missing snapshots (INSERT)
-- IMPORTANT: Review Step 1 output first to ensure pricing data is correct
-- Replace <agreement_id> with actual agreement ID from health check results

INSERT INTO agreement_rate_snapshots (
  agreement_id,
  scope,
  pricing_mode,
  track_code,
  resolved_upfront_bps,
  resolved_deferred_bps,
  vat_included,
  effective_from,
  effective_to,
  seed_version,
  approved_at,
  vat_rate_percent,
  vat_policy,
  snapshotted_at
)
SELECT
  a.id AS agreement_id,
  a.scope,
  a.pricing_mode,
  a.selected_track AS track_code,
  -- Resolve upfront_bps
  CASE
    WHEN a.pricing_mode = 'TRACK' THEN (
      SELECT ft.upfront_bps
      FROM fund_tracks ft
      WHERE ft.fund_id = COALESCE(a.fund_id, (SELECT fund_id FROM deals WHERE id = a.deal_id))
        AND ft.track_code = a.selected_track
        AND ft.valid_from <= a.effective_from
        AND (ft.valid_to IS NULL OR ft.valid_to >= a.effective_from)
      ORDER BY ft.valid_from DESC
      LIMIT 1
    )
    WHEN a.pricing_mode = 'CUSTOM' THEN (
      SELECT act.upfront_bps
      FROM agreement_custom_terms act
      WHERE act.agreement_id = a.id
    )
  END AS resolved_upfront_bps,
  -- Resolve deferred_bps
  CASE
    WHEN a.pricing_mode = 'TRACK' THEN (
      SELECT ft.deferred_bps
      FROM fund_tracks ft
      WHERE ft.fund_id = COALESCE(a.fund_id, (SELECT fund_id FROM deals WHERE id = a.deal_id))
        AND ft.track_code = a.selected_track
        AND ft.valid_from <= a.effective_from
        AND (ft.valid_to IS NULL OR ft.valid_to >= a.effective_from)
      ORDER BY ft.valid_from DESC
      LIMIT 1
    )
    WHEN a.pricing_mode = 'CUSTOM' THEN (
      SELECT act.deferred_bps
      FROM agreement_custom_terms act
      WHERE act.agreement_id = a.id
    )
  END AS resolved_deferred_bps,
  a.vat_included,
  a.effective_from,
  a.effective_to,
  -- Seed version (only for TRACK mode)
  CASE
    WHEN a.pricing_mode = 'TRACK' THEN (
      SELECT ft.seed_version
      FROM fund_tracks ft
      WHERE ft.fund_id = COALESCE(a.fund_id, (SELECT fund_id FROM deals WHERE id = a.deal_id))
        AND ft.track_code = a.selected_track
        AND ft.valid_from <= a.effective_from
        AND (ft.valid_to IS NULL OR ft.valid_to >= a.effective_from)
      ORDER BY ft.valid_from DESC
      LIMIT 1
    )
    ELSE NULL
  END AS seed_version,
  now() AS approved_at, -- Use current timestamp (historical timestamp unknown)
  -- Resolve VAT rate from party's country
  (
    SELECT vr.rate_percentage
    FROM vat_rates vr
    JOIN parties p ON p.id = a.party_id
    WHERE vr.country_code = p.country
      AND vr.effective_from <= a.effective_from
      AND (vr.effective_to IS NULL OR vr.effective_to > a.effective_from)
    ORDER BY vr.effective_from DESC
    LIMIT 1
  ) AS vat_rate_percent,
  CASE WHEN a.vat_included THEN 'INCLUSIVE' ELSE 'EXCLUSIVE' END AS vat_policy,
  now() AS snapshotted_at
FROM agreements a
WHERE a.status = 'APPROVED'
  AND NOT EXISTS (
    SELECT 1
    FROM agreement_rate_snapshots ars
    WHERE ars.agreement_id = a.id
  )
  -- SAFETY: Add specific agreement ID filter (replace <agreement_id> with actual ID)
  AND a.id = <agreement_id>
;

-- Step 3: Verify snapshot was created
SELECT
  ars.*
FROM agreement_rate_snapshots ars
WHERE ars.agreement_id = <agreement_id>;

-- Expected: 1 row with complete pricing data

-- ============================================
-- FIX SCRIPT 2: Update Incomplete Snapshots (Missing BPS Fields)
-- ============================================
-- Use Case: Snapshots with NULL resolved_upfront_bps or resolved_deferred_bps
-- Root Cause: Trigger ran but failed to resolve pricing (missing custom_terms, invalid track)
--
-- How It Works:
-- - Updates existing snapshot with missing pricing fields
-- - Resolves pricing from current fund_tracks or agreement_custom_terms
-- - Preserves all other snapshot fields (VAT, timestamps, etc.)

-- Step 1: Preview snapshots to be updated
SELECT
  ars.id AS snapshot_id,
  ars.agreement_id,
  a.pricing_mode,
  a.selected_track,
  ars.resolved_upfront_bps AS current_upfront_bps,
  ars.resolved_deferred_bps AS current_deferred_bps,
  -- New values to be set
  CASE
    WHEN a.pricing_mode = 'TRACK' THEN (
      SELECT ft.upfront_bps
      FROM fund_tracks ft
      WHERE ft.fund_id = COALESCE(a.fund_id, (SELECT fund_id FROM deals WHERE id = a.deal_id))
        AND ft.track_code = a.selected_track
        AND ft.valid_from <= a.effective_from
        AND (ft.valid_to IS NULL OR ft.valid_to >= a.effective_from)
      ORDER BY ft.valid_from DESC
      LIMIT 1
    )
    WHEN a.pricing_mode = 'CUSTOM' THEN (
      SELECT act.upfront_bps
      FROM agreement_custom_terms act
      WHERE act.agreement_id = a.id
    )
  END AS new_upfront_bps,
  CASE
    WHEN a.pricing_mode = 'TRACK' THEN (
      SELECT ft.deferred_bps
      FROM fund_tracks ft
      WHERE ft.fund_id = COALESCE(a.fund_id, (SELECT fund_id FROM deals WHERE id = a.deal_id))
        AND ft.track_code = a.selected_track
        AND ft.valid_from <= a.effective_from
        AND (ft.valid_to IS NULL OR ft.valid_to >= a.effective_from)
      ORDER BY ft.valid_from DESC
      LIMIT 1
    )
    WHEN a.pricing_mode = 'CUSTOM' THEN (
      SELECT act.deferred_bps
      FROM agreement_custom_terms act
      WHERE act.agreement_id = a.id
    )
  END AS new_deferred_bps
FROM agreement_rate_snapshots ars
JOIN agreements a ON ars.agreement_id = a.id
WHERE a.status = 'APPROVED'
  AND (
    ars.resolved_upfront_bps IS NULL
    OR ars.resolved_deferred_bps IS NULL
  )
  -- SAFETY: Add specific agreement ID filter
  -- AND ars.agreement_id = <agreement_id>
;

-- Step 2: Update snapshots with missing BPS fields
-- Replace <agreement_id> with actual agreement ID from health check results

UPDATE agreement_rate_snapshots ars
SET
  resolved_upfront_bps = COALESCE(
    ars.resolved_upfront_bps,
    CASE
      WHEN a.pricing_mode = 'TRACK' THEN (
        SELECT ft.upfront_bps
        FROM fund_tracks ft
        WHERE ft.fund_id = COALESCE(a.fund_id, (SELECT fund_id FROM deals WHERE id = a.deal_id))
          AND ft.track_code = a.selected_track
          AND ft.valid_from <= a.effective_from
          AND (ft.valid_to IS NULL OR ft.valid_to >= a.effective_from)
        ORDER BY ft.valid_from DESC
        LIMIT 1
      )
      WHEN a.pricing_mode = 'CUSTOM' THEN (
        SELECT act.upfront_bps
        FROM agreement_custom_terms act
        WHERE act.agreement_id = a.id
      )
    END
  ),
  resolved_deferred_bps = COALESCE(
    ars.resolved_deferred_bps,
    CASE
      WHEN a.pricing_mode = 'TRACK' THEN (
        SELECT ft.deferred_bps
        FROM fund_tracks ft
        WHERE ft.fund_id = COALESCE(a.fund_id, (SELECT fund_id FROM deals WHERE id = a.deal_id))
          AND ft.track_code = a.selected_track
          AND ft.valid_from <= a.effective_from
          AND (ft.valid_to IS NULL OR ft.valid_to >= a.effective_from)
        ORDER BY ft.valid_from DESC
        LIMIT 1
      )
      WHEN a.pricing_mode = 'CUSTOM' THEN (
        SELECT act.deferred_bps
        FROM agreement_custom_terms act
        WHERE act.agreement_id = a.id
      )
    END
  )
FROM agreements a
WHERE ars.agreement_id = a.id
  AND a.status = 'APPROVED'
  AND (
    ars.resolved_upfront_bps IS NULL
    OR ars.resolved_deferred_bps IS NULL
  )
  -- SAFETY: Add specific agreement ID filter
  AND ars.agreement_id = <agreement_id>
;

-- Step 3: Verify update
SELECT
  ars.id,
  ars.agreement_id,
  ars.resolved_upfront_bps,
  ars.resolved_deferred_bps
FROM agreement_rate_snapshots ars
WHERE ars.agreement_id = <agreement_id>;

-- Expected: resolved_upfront_bps and resolved_deferred_bps should now be non-NULL

-- ============================================
-- FIX SCRIPT 3: Correct Invalid BPS Values (Negative)
-- ============================================
-- Use Case: Snapshots with negative BPS values (detected by health check QUERY 3)
-- Root Cause: Data corruption, manual entry error, or database constraint bypass
--
-- How It Works:
-- - Updates negative BPS values to 0 (assuming 0% fee is intended)
-- - Alternatively, set to correct positive value if known

-- Step 1: Preview snapshots with invalid values
SELECT
  ars.id AS snapshot_id,
  ars.agreement_id,
  a.party_id,
  p.name AS party_name,
  ars.resolved_upfront_bps,
  ars.resolved_deferred_bps
FROM agreement_rate_snapshots ars
JOIN agreements a ON ars.agreement_id = a.id
JOIN parties p ON a.party_id = p.id
WHERE a.status = 'APPROVED'
  AND (
    ars.resolved_upfront_bps < 0
    OR ars.resolved_deferred_bps < 0
  )
  -- SAFETY: Add specific agreement ID filter
  -- AND ars.agreement_id = <agreement_id>
;

-- Step 2: Fix negative BPS values (Option A: Set to 0)
-- Replace <agreement_id> with actual agreement ID

UPDATE agreement_rate_snapshots ars
SET
  resolved_upfront_bps = CASE
    WHEN ars.resolved_upfront_bps < 0 THEN 0
    ELSE ars.resolved_upfront_bps
  END,
  resolved_deferred_bps = CASE
    WHEN ars.resolved_deferred_bps < 0 THEN 0
    ELSE ars.resolved_deferred_bps
  END
WHERE ars.agreement_id = <agreement_id>
  AND (
    ars.resolved_upfront_bps < 0
    OR ars.resolved_deferred_bps < 0
  )
;

-- Step 2 (Option B): Set to specific correct values (if known)
-- Replace <agreement_id>, <correct_upfront_bps>, <correct_deferred_bps> with actual values

UPDATE agreement_rate_snapshots ars
SET
  resolved_upfront_bps = <correct_upfront_bps>,
  resolved_deferred_bps = <correct_deferred_bps>
WHERE ars.agreement_id = <agreement_id>;

-- Step 3: Verify fix
SELECT
  ars.id,
  ars.agreement_id,
  ars.resolved_upfront_bps,
  ars.resolved_deferred_bps
FROM agreement_rate_snapshots ars
WHERE ars.agreement_id = <agreement_id>;

-- Expected: Both BPS values should be >= 0

-- ============================================
-- FIX SCRIPT 4: Add Missing VAT Rate
-- ============================================
-- Use Case: Snapshots with NULL vat_rate_percent (detected by health check QUERY 4)
-- Root Cause: Party's country not in vat_rates table, or VAT rate lookup failed
--
-- How It Works:
-- - Looks up current VAT rate for party's country
-- - Updates snapshot with resolved VAT rate
-- - If no VAT rate found, manually sets to 0 (VAT-exempt) or specific rate

-- Step 1: Preview snapshots with missing VAT rates
SELECT
  ars.id AS snapshot_id,
  ars.agreement_id,
  a.party_id,
  p.name AS party_name,
  p.country AS party_country,
  ars.vat_rate_percent AS current_vat_rate,
  -- Lookup current VAT rate for party's country
  (
    SELECT vr.rate_percentage
    FROM vat_rates vr
    WHERE vr.country_code = p.country
      AND vr.effective_from <= CURRENT_DATE
      AND (vr.effective_to IS NULL OR vr.effective_to > CURRENT_DATE)
    ORDER BY vr.effective_from DESC
    LIMIT 1
  ) AS new_vat_rate
FROM agreement_rate_snapshots ars
JOIN agreements a ON ars.agreement_id = a.id
JOIN parties p ON a.party_id = p.id
WHERE a.status = 'APPROVED'
  AND ars.vat_rate_percent IS NULL
  -- SAFETY: Add specific agreement ID filter
  -- AND ars.agreement_id = <agreement_id>
;

-- Step 2: Update snapshots with missing VAT rates (Option A: Auto-lookup)
-- Replace <agreement_id> with actual agreement ID

UPDATE agreement_rate_snapshots ars
SET
  vat_rate_percent = (
    SELECT vr.rate_percentage
    FROM vat_rates vr
    JOIN agreements a ON a.id = ars.agreement_id
    JOIN parties p ON p.id = a.party_id
    WHERE vr.country_code = p.country
      AND vr.effective_from <= a.effective_from
      AND (vr.effective_to IS NULL OR vr.effective_to > a.effective_from)
    ORDER BY vr.effective_from DESC
    LIMIT 1
  ),
  vat_policy = CASE WHEN ars.vat_included THEN 'INCLUSIVE' ELSE 'EXCLUSIVE' END
WHERE ars.agreement_id = <agreement_id>
  AND ars.vat_rate_percent IS NULL;

-- Step 2 (Option B): Set to specific VAT rate (if known)
-- Replace <agreement_id> and <vat_rate> with actual values (e.g., 20.00 for UK)

UPDATE agreement_rate_snapshots ars
SET
  vat_rate_percent = <vat_rate>,
  vat_policy = CASE WHEN ars.vat_included THEN 'INCLUSIVE' ELSE 'EXCLUSIVE' END
WHERE ars.agreement_id = <agreement_id>;

-- Step 2 (Option C): Set to 0 for VAT-exempt parties (e.g., US)
-- Replace <agreement_id> with actual agreement ID

UPDATE agreement_rate_snapshots ars
SET
  vat_rate_percent = 0.00,
  vat_policy = 'EXEMPT'
WHERE ars.agreement_id = <agreement_id>;

-- Step 3: Verify fix
SELECT
  ars.id,
  ars.agreement_id,
  ars.vat_rate_percent,
  ars.vat_policy
FROM agreement_rate_snapshots ars
WHERE ars.agreement_id = <agreement_id>;

-- Expected: vat_rate_percent should now be non-NULL and 0-100

-- ============================================
-- FIX SCRIPT 5: Correct Invalid VAT Rates (Out of Range)
-- ============================================
-- Use Case: Snapshots with vat_rate_percent < 0 or > 100
-- Root Cause: Data validation bypass or manual entry error
--
-- How It Works:
-- - Clamps VAT rate to valid range (0-100)
-- - Or sets to correct value if known

-- Step 1: Preview snapshots with invalid VAT rates
SELECT
  ars.id AS snapshot_id,
  ars.agreement_id,
  a.party_id,
  p.name AS party_name,
  p.country AS party_country,
  ars.vat_rate_percent AS current_vat_rate
FROM agreement_rate_snapshots ars
JOIN agreements a ON ars.agreement_id = a.id
JOIN parties p ON a.party_id = p.id
WHERE a.status = 'APPROVED'
  AND (
    ars.vat_rate_percent < 0
    OR ars.vat_rate_percent > 100
  )
  -- SAFETY: Add specific agreement ID filter
  -- AND ars.agreement_id = <agreement_id>
;

-- Step 2: Fix invalid VAT rates (Option A: Clamp to 0-100 range)
-- Replace <agreement_id> with actual agreement ID

UPDATE agreement_rate_snapshots ars
SET
  vat_rate_percent = CASE
    WHEN ars.vat_rate_percent < 0 THEN 0
    WHEN ars.vat_rate_percent > 100 THEN 100
    ELSE ars.vat_rate_percent
  END
WHERE ars.agreement_id = <agreement_id>
  AND (
    ars.vat_rate_percent < 0
    OR ars.vat_rate_percent > 100
  );

-- Step 2 (Option B): Set to correct VAT rate (if known)
-- Replace <agreement_id> and <correct_vat_rate> with actual values

UPDATE agreement_rate_snapshots ars
SET
  vat_rate_percent = <correct_vat_rate>
WHERE ars.agreement_id = <agreement_id>;

-- Step 3: Verify fix
SELECT
  ars.id,
  ars.agreement_id,
  ars.vat_rate_percent
FROM agreement_rate_snapshots ars
WHERE ars.agreement_id = <agreement_id>;

-- Expected: vat_rate_percent should now be in range 0-100

-- ============================================
-- FIX SCRIPT 6: Manual Snapshot Configuration (Template)
-- ============================================
-- Use Case: When automatic resolution fails, manually configure snapshot
-- Examples: Missing custom_terms, invalid track, party not in system
--
-- How It Works:
-- - Manually INSERT or UPDATE snapshot with known correct values
-- - Use when automatic fix scripts fail

-- Template: Insert complete snapshot manually
-- Replace all <placeholders> with actual values

INSERT INTO agreement_rate_snapshots (
  agreement_id,
  scope,
  pricing_mode,
  track_code,
  resolved_upfront_bps,
  resolved_deferred_bps,
  vat_included,
  effective_from,
  effective_to,
  seed_version,
  approved_at,
  vat_rate_percent,
  vat_policy,
  snapshotted_at
)
VALUES (
  <agreement_id>,              -- Agreement ID (e.g., 6)
  '<scope>',                   -- 'FUND' or 'DEAL'
  '<pricing_mode>',            -- 'TRACK' or 'CUSTOM'
  '<track_code>',              -- 'A', 'B', 'C', or NULL
  <upfront_bps>,               -- Upfront BPS (e.g., 100 for 1%)
  <deferred_bps>,              -- Deferred BPS (e.g., 0)
  <vat_included>,              -- true or false
  '<effective_from>',          -- Date (e.g., '2025-01-01')
  '<effective_to>',            -- Date or NULL
  <seed_version>,              -- Integer or NULL
  '<approved_at>',             -- Timestamp (e.g., '2025-10-20T12:00:00Z')
  <vat_rate>,                  -- VAT rate (e.g., 20.00 for UK)
  '<vat_policy>',              -- 'EXCLUSIVE', 'INCLUSIVE', or 'EXEMPT'
  '<snapshotted_at>'           -- Timestamp (e.g., '2025-10-20T12:00:00Z')
)
ON CONFLICT (agreement_id) DO UPDATE
SET
  resolved_upfront_bps = EXCLUDED.resolved_upfront_bps,
  resolved_deferred_bps = EXCLUDED.resolved_deferred_bps,
  vat_rate_percent = EXCLUDED.vat_rate_percent,
  vat_policy = EXCLUDED.vat_policy,
  snapshotted_at = EXCLUDED.snapshotted_at;

-- Example: Configure snapshot for Agreement 6 (from v1.7.0)
INSERT INTO agreement_rate_snapshots (
  agreement_id,
  scope,
  pricing_mode,
  track_code,
  resolved_upfront_bps,
  resolved_deferred_bps,
  vat_included,
  effective_from,
  effective_to,
  seed_version,
  approved_at,
  vat_rate_percent,
  vat_policy,
  snapshotted_at
)
VALUES (
  6,
  'FUND',
  'TRACK',
  'A',
  100,  -- 1% upfront
  0,    -- 0% deferred
  false,
  '2025-01-01',
  NULL,
  1,
  now(),
  20.00,  -- 20% VAT (UK)
  'EXCLUSIVE',
  now()
)
ON CONFLICT (agreement_id) DO UPDATE
SET
  resolved_upfront_bps = 100,
  resolved_deferred_bps = 0,
  vat_rate_percent = 20.00,
  vat_policy = 'EXCLUSIVE',
  snapshotted_at = now();

-- ============================================
-- VERIFICATION AFTER FIXES
-- ============================================
-- After running any fix script, re-run health check QUERY 6 to verify:
--
-- SELECT issue_type, COUNT(*) AS count
-- FROM (
--   -- Health check logic here (see AGR_HEALTH_CHECK_QUERIES.sql)
-- ) AS all_issues
-- GROUP BY issue_type;
--
-- Expected: No critical issues (MISSING_SNAPSHOT, MISSING_*_BPS, INVALID_*)
--
-- ============================================
-- END OF FIX SCRIPTS
-- ============================================
