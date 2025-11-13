-- ============================================
-- AGR-01: Agreement Snapshot Integrity Health Check
-- Version: 1.8.0 - Investor Fee Workflow E2E
-- Date: 2025-10-21
-- ============================================
--
-- PURPOSE:
-- Verify that all APPROVED agreements have valid, complete rate snapshots
-- in the agreement_rate_snapshots table. This is critical for charge computation,
-- as the chargeCompute.ts engine relies on snapshot data to calculate fees.
--
-- CONTEXT:
-- - When an agreement transitions to APPROVED status, a trigger creates an immutable
--   snapshot in agreement_rate_snapshots containing:
--   - resolved_upfront_bps (required)
--   - resolved_deferred_bps (required)
--   - vat_rate_percent (optional, from party's country VAT rate)
--   - Other metadata (scope, pricing_mode, track_code, etc.)
--
-- - The charge computation logic (chargeCompute.ts) reads snapshots to:
--   - Calculate base fee = contribution × (upfront_bps + deferred_bps) / 10000
--   - Apply VAT (if applicable)
--   - Generate charges.snapshot_json for audit trail
--
-- RISK:
-- - If an APPROVED agreement lacks a snapshot or has incomplete data:
--   - Charge computation will FAIL with "No approved agreement found"
--   - Contributions cannot be processed → revenue loss
--   - Manual intervention required to fix data
--
-- FREQUENCY:
-- - Run BEFORE each investor import batch
-- - Run AFTER approval workflow changes
-- - Include in weekly data quality audits
--
-- ============================================

-- ============================================
-- QUERY 1: Find APPROVED Agreements with Missing Snapshots
-- ============================================
-- Identifies agreements that are APPROVED but have no corresponding snapshot.
-- This should NEVER happen if triggers are working correctly.

SELECT
  a.id AS agreement_id,
  a.party_id,
  p.name AS party_name,
  a.status,
  a.scope,
  a.pricing_mode,
  a.selected_track,
  a.effective_from,
  a.effective_to,
  a.created_at,
  a.updated_at,
  'MISSING_SNAPSHOT' AS issue_type,
  'No snapshot found in agreement_rate_snapshots table' AS issue_description
FROM agreements a
JOIN parties p ON a.party_id = p.id
WHERE a.status = 'APPROVED'
  AND NOT EXISTS (
    SELECT 1
    FROM agreement_rate_snapshots ars
    WHERE ars.agreement_id = a.id
  )
ORDER BY a.id ASC;

-- Expected: 0 rows (all APPROVED agreements should have snapshots)
-- If rows found: Trigger malfunction or data corruption - urgent fix required

-- ============================================
-- QUERY 2: Find Snapshots with Missing Required Fields
-- ============================================
-- Verifies that all snapshots contain required pricing fields.
-- Charge computation requires: resolved_upfront_bps, resolved_deferred_bps

SELECT
  ars.id AS snapshot_id,
  ars.agreement_id,
  a.party_id,
  p.name AS party_name,
  a.status,
  ars.resolved_upfront_bps,
  ars.resolved_deferred_bps,
  ars.vat_rate_percent,
  ars.vat_included,
  ars.approved_at,
  ars.snapshotted_at,
  CASE
    WHEN ars.resolved_upfront_bps IS NULL THEN 'MISSING_UPFRONT_BPS'
    WHEN ars.resolved_deferred_bps IS NULL THEN 'MISSING_DEFERRED_BPS'
    ELSE 'UNKNOWN'
  END AS issue_type,
  CASE
    WHEN ars.resolved_upfront_bps IS NULL THEN 'Snapshot missing resolved_upfront_bps (required for fee calculation)'
    WHEN ars.resolved_deferred_bps IS NULL THEN 'Snapshot missing resolved_deferred_bps (required for fee calculation)'
    ELSE 'Unknown issue'
  END AS issue_description
FROM agreement_rate_snapshots ars
JOIN agreements a ON ars.agreement_id = a.id
JOIN parties p ON a.party_id = p.id
WHERE a.status = 'APPROVED'
  AND (
    ars.resolved_upfront_bps IS NULL
    OR ars.resolved_deferred_bps IS NULL
  )
ORDER BY ars.agreement_id ASC;

-- Expected: 0 rows (all snapshots should have complete pricing data)
-- If rows found: Data integrity issue - snapshot was created but incomplete

-- ============================================
-- QUERY 3: Find Snapshots with Invalid Values
-- ============================================
-- Validates that all numeric values are within acceptable ranges.
-- BPS values must be >= 0, VAT rate must be 0-100

SELECT
  ars.id AS snapshot_id,
  ars.agreement_id,
  a.party_id,
  p.name AS party_name,
  a.status,
  ars.resolved_upfront_bps,
  ars.resolved_deferred_bps,
  ars.vat_rate_percent,
  ars.approved_at,
  CASE
    WHEN ars.resolved_upfront_bps < 0 THEN 'INVALID_UPFRONT_BPS'
    WHEN ars.resolved_deferred_bps < 0 THEN 'INVALID_DEFERRED_BPS'
    WHEN ars.vat_rate_percent < 0 THEN 'INVALID_VAT_RATE_NEGATIVE'
    WHEN ars.vat_rate_percent > 100 THEN 'INVALID_VAT_RATE_EXCEEDS_100'
    ELSE 'UNKNOWN'
  END AS issue_type,
  CASE
    WHEN ars.resolved_upfront_bps < 0 THEN 'Upfront BPS is negative (must be >= 0)'
    WHEN ars.resolved_deferred_bps < 0 THEN 'Deferred BPS is negative (must be >= 0)'
    WHEN ars.vat_rate_percent < 0 THEN 'VAT rate is negative (must be 0-100)'
    WHEN ars.vat_rate_percent > 100 THEN 'VAT rate exceeds 100% (must be 0-100)'
    ELSE 'Unknown issue'
  END AS issue_description
FROM agreement_rate_snapshots ars
JOIN agreements a ON ars.agreement_id = a.id
JOIN parties p ON a.party_id = p.id
WHERE a.status = 'APPROVED'
  AND (
    ars.resolved_upfront_bps < 0
    OR ars.resolved_deferred_bps < 0
    OR (ars.vat_rate_percent IS NOT NULL AND ars.vat_rate_percent < 0)
    OR (ars.vat_rate_percent IS NOT NULL AND ars.vat_rate_percent > 100)
  )
ORDER BY ars.agreement_id ASC;

-- Expected: 0 rows (all values should be within valid ranges)
-- If rows found: Data validation bypass or manual data corruption

-- ============================================
-- QUERY 4: Find Snapshots with Missing VAT Data (Warning, Not Error)
-- ============================================
-- Identifies snapshots where VAT rate is NULL.
-- This is not strictly an error (some parties may be VAT-exempt),
-- but may indicate missing VAT configuration.

SELECT
  ars.id AS snapshot_id,
  ars.agreement_id,
  a.party_id,
  p.name AS party_name,
  p.country AS party_country,
  a.status,
  ars.resolved_upfront_bps,
  ars.resolved_deferred_bps,
  ars.vat_rate_percent,
  ars.vat_included,
  ars.approved_at,
  'MISSING_VAT_RATE' AS issue_type,
  'Snapshot missing VAT rate (may be intentional for VAT-exempt parties)' AS issue_description
FROM agreement_rate_snapshots ars
JOIN agreements a ON ars.agreement_id = a.id
JOIN parties p ON a.party_id = p.id
WHERE a.status = 'APPROVED'
  AND ars.vat_rate_percent IS NULL
ORDER BY ars.agreement_id ASC;

-- Expected: Some rows may be acceptable (VAT-exempt parties)
-- Action: Review each case - if party is in GB/EU, VAT rate should be set
-- For US parties (no federal VAT), NULL is acceptable

-- ============================================
-- QUERY 5: Find Overlapping Effective Date Windows (Same Party)
-- ============================================
-- Identifies cases where a single party has multiple APPROVED agreements
-- with overlapping effective date ranges. This can cause ambiguity in
-- charge computation (which agreement applies to a given contribution?).
--
-- Note: This query checks if effective_from/effective_to columns exist.
-- If not, skip this check (overlaps cannot occur without date windows).

SELECT
  a1.id AS agreement1_id,
  a2.id AS agreement2_id,
  a1.party_id,
  p.name AS party_name,
  a1.scope AS scope1,
  a2.scope AS scope2,
  a1.pricing_mode AS mode1,
  a2.pricing_mode AS mode2,
  a1.effective_from AS start1,
  a1.effective_to AS end1,
  a2.effective_from AS start2,
  a2.effective_to AS end2,
  'OVERLAPPING_WINDOWS' AS issue_type,
  'Multiple APPROVED agreements for same party with overlapping date ranges' AS issue_description
FROM agreements a1
JOIN agreements a2 ON a1.party_id = a2.party_id AND a1.id < a2.id
JOIN parties p ON a1.party_id = p.id
WHERE a1.status = 'APPROVED'
  AND a2.status = 'APPROVED'
  AND (
    -- Check for overlap: (start1, end1) OVERLAPS (start2, end2)
    -- Overlap condition: start1 < COALESCE(end2, 'infinity') AND start2 < COALESCE(end1, 'infinity')
    (
      a1.effective_from < COALESCE(a2.effective_to, DATE '9999-12-31')
      AND
      a2.effective_from < COALESCE(a1.effective_to, DATE '9999-12-31')
    )
    OR
    -- Both open-ended (effective_to IS NULL for both)
    (a1.effective_to IS NULL AND a2.effective_to IS NULL)
  )
ORDER BY a1.party_id ASC, a1.id ASC, a2.id ASC;

-- Expected: 0 rows (no overlapping date windows for same party)
-- If rows found: Ambiguous agreement precedence - define tie-break logic or prevent overlaps
-- Note: Deal-level and fund-level agreements for same party may coexist (deal-level takes precedence)

-- ============================================
-- QUERY 6: Combined Health Check Summary
-- ============================================
-- Aggregates all issues into a single summary report.
-- Use this for quick daily/weekly health checks.

WITH missing_snapshots AS (
  SELECT
    a.id AS agreement_id,
    'MISSING_SNAPSHOT' AS issue_type
  FROM agreements a
  WHERE a.status = 'APPROVED'
    AND NOT EXISTS (
      SELECT 1
      FROM agreement_rate_snapshots ars
      WHERE ars.agreement_id = a.id
    )
),
missing_fields AS (
  SELECT
    ars.agreement_id,
    CASE
      WHEN ars.resolved_upfront_bps IS NULL THEN 'MISSING_UPFRONT_BPS'
      WHEN ars.resolved_deferred_bps IS NULL THEN 'MISSING_DEFERRED_BPS'
      ELSE 'UNKNOWN'
    END AS issue_type
  FROM agreement_rate_snapshots ars
  JOIN agreements a ON ars.agreement_id = a.id
  WHERE a.status = 'APPROVED'
    AND (
      ars.resolved_upfront_bps IS NULL
      OR ars.resolved_deferred_bps IS NULL
    )
),
invalid_values AS (
  SELECT
    ars.agreement_id,
    CASE
      WHEN ars.resolved_upfront_bps < 0 THEN 'INVALID_UPFRONT_BPS'
      WHEN ars.resolved_deferred_bps < 0 THEN 'INVALID_DEFERRED_BPS'
      WHEN ars.vat_rate_percent < 0 THEN 'INVALID_VAT_RATE_NEGATIVE'
      WHEN ars.vat_rate_percent > 100 THEN 'INVALID_VAT_RATE_EXCEEDS_100'
      ELSE 'UNKNOWN'
    END AS issue_type
  FROM agreement_rate_snapshots ars
  JOIN agreements a ON ars.agreement_id = a.id
  WHERE a.status = 'APPROVED'
    AND (
      ars.resolved_upfront_bps < 0
      OR ars.resolved_deferred_bps < 0
      OR (ars.vat_rate_percent IS NOT NULL AND ars.vat_rate_percent < 0)
      OR (ars.vat_rate_percent IS NOT NULL AND ars.vat_rate_percent > 100)
    )
),
missing_vat AS (
  SELECT
    ars.agreement_id,
    'MISSING_VAT_RATE' AS issue_type
  FROM agreement_rate_snapshots ars
  JOIN agreements a ON ars.agreement_id = a.id
  WHERE a.status = 'APPROVED'
    AND ars.vat_rate_percent IS NULL
),
overlapping_windows AS (
  SELECT
    a1.id AS agreement_id,
    'OVERLAPPING_WINDOWS' AS issue_type
  FROM agreements a1
  JOIN agreements a2 ON a1.party_id = a2.party_id AND a1.id < a2.id
  WHERE a1.status = 'APPROVED'
    AND a2.status = 'APPROVED'
    AND (
      (
        a1.effective_from < COALESCE(a2.effective_to, DATE '9999-12-31')
        AND
        a2.effective_from < COALESCE(a1.effective_to, DATE '9999-12-31')
      )
      OR
      (a1.effective_to IS NULL AND a2.effective_to IS NULL)
    )
),
all_issues AS (
  SELECT issue_type, agreement_id FROM missing_snapshots
  UNION ALL
  SELECT issue_type, agreement_id FROM missing_fields
  UNION ALL
  SELECT issue_type, agreement_id FROM invalid_values
  UNION ALL
  SELECT issue_type, agreement_id FROM missing_vat
  UNION ALL
  SELECT issue_type, agreement_id FROM overlapping_windows
)
SELECT
  issue_type,
  COUNT(*) AS count,
  ARRAY_AGG(agreement_id ORDER BY agreement_id) AS affected_agreement_ids
FROM all_issues
GROUP BY issue_type
ORDER BY
  CASE issue_type
    WHEN 'MISSING_SNAPSHOT' THEN 1
    WHEN 'MISSING_UPFRONT_BPS' THEN 2
    WHEN 'MISSING_DEFERRED_BPS' THEN 3
    WHEN 'INVALID_UPFRONT_BPS' THEN 4
    WHEN 'INVALID_DEFERRED_BPS' THEN 5
    WHEN 'INVALID_VAT_RATE_NEGATIVE' THEN 6
    WHEN 'INVALID_VAT_RATE_EXCEEDS_100' THEN 7
    WHEN 'OVERLAPPING_WINDOWS' THEN 8
    WHEN 'MISSING_VAT_RATE' THEN 9
    ELSE 10
  END;

-- Expected Output:
-- | issue_type                   | count | affected_agreement_ids |
-- |------------------------------|-------|------------------------|
-- | MISSING_VAT_RATE             | 3     | {12, 15, 18}           |
--
-- Interpretation:
-- - If count > 0 for critical issues (MISSING_SNAPSHOT, MISSING_*_BPS, INVALID_*), FIX IMMEDIATELY
-- - If count > 0 for MISSING_VAT_RATE, review case-by-case (may be acceptable)
-- - If count > 0 for OVERLAPPING_WINDOWS, define precedence rules or prevent overlaps

-- ============================================
-- QUERY 7: List All APPROVED Agreements with Snapshot Summary
-- ============================================
-- Provides a complete view of all APPROVED agreements and their snapshots.
-- Use for manual audit and verification.

SELECT
  a.id AS agreement_id,
  a.party_id,
  p.name AS party_name,
  p.country AS party_country,
  a.scope,
  a.pricing_mode,
  a.selected_track,
  a.effective_from,
  a.effective_to,
  a.status,
  a.created_at AS agreement_created_at,
  a.updated_at AS agreement_updated_at,
  ars.id AS snapshot_id,
  ars.resolved_upfront_bps,
  ars.resolved_deferred_bps,
  ars.vat_rate_percent,
  ars.vat_included,
  ars.vat_policy,
  ars.approved_at AS snapshot_approved_at,
  ars.snapshotted_at AS snapshot_created_at,
  ars.seed_version,
  -- Computed summary
  CASE
    WHEN ars.id IS NULL THEN 'MISSING_SNAPSHOT'
    WHEN ars.resolved_upfront_bps IS NULL THEN 'INCOMPLETE_SNAPSHOT'
    WHEN ars.resolved_deferred_bps IS NULL THEN 'INCOMPLETE_SNAPSHOT'
    WHEN ars.resolved_upfront_bps < 0 OR ars.resolved_deferred_bps < 0 THEN 'INVALID_VALUES'
    WHEN ars.vat_rate_percent IS NOT NULL AND (ars.vat_rate_percent < 0 OR ars.vat_rate_percent > 100) THEN 'INVALID_VAT_RATE'
    ELSE 'OK'
  END AS snapshot_status
FROM agreements a
LEFT JOIN agreement_rate_snapshots ars ON a.id = ars.agreement_id
LEFT JOIN parties p ON a.party_id = p.id
WHERE a.status = 'APPROVED'
ORDER BY a.id ASC;

-- Expected: All rows should have snapshot_status = 'OK' or 'MISSING_VAT_RATE' (acceptable)
-- If snapshot_status = 'MISSING_SNAPSHOT', 'INCOMPLETE_SNAPSHOT', or 'INVALID_*', FIX IMMEDIATELY

-- ============================================
-- VERIFICATION SUMMARY
-- ============================================
--
-- Run the following queries in order:
--
-- 1. QUERY 6 (Combined Health Check Summary)
--    - Quick overview of all issues
--    - If count = 0 for all issues: PASS ✅
--    - If count > 0 for critical issues: FAIL ❌ → Run detailed queries
--
-- 2. QUERY 1 (Missing Snapshots)
--    - Identify agreements without snapshots
--    - Expected: 0 rows
--    - Action: Create missing snapshots (see fix scripts below)
--
-- 3. QUERY 2 (Missing Required Fields)
--    - Identify incomplete snapshots
--    - Expected: 0 rows
--    - Action: Update snapshots with missing fields
--
-- 4. QUERY 3 (Invalid Values)
--    - Identify data validation errors
--    - Expected: 0 rows
--    - Action: Correct invalid values
--
-- 5. QUERY 4 (Missing VAT Data)
--    - Identify snapshots without VAT rates
--    - Expected: Some rows (VAT-exempt parties)
--    - Action: Review and update if needed
--
-- 6. QUERY 5 (Overlapping Windows)
--    - Identify ambiguous agreement precedence
--    - Expected: 0 rows
--    - Action: Define tie-break logic or prevent overlaps
--
-- 7. QUERY 7 (Full Audit List)
--    - Manual verification of all APPROVED agreements
--    - Use for periodic audits and data quality checks
--
-- ============================================
-- END OF HEALTH CHECK QUERIES
-- ============================================
