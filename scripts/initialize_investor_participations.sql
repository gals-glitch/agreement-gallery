-- ============================================================================
-- Script: Initialize Investor Deal Participations from Historical Data
-- Purpose: Backfill investor_deal_participations table from existing contributions
-- Date: 2025-10-26
-- Prerequisites: Migration 20251026000001_investor_deal_participations.sql must be applied first
-- ============================================================================
--
-- OVERVIEW:
-- This script analyzes existing contributions and creates participation records
-- with correct sequence numbers based on chronological order of first contributions.
--
-- LOGIC:
-- 1. For each investor, find all deals they've contributed to
-- 2. Order deals by the date of the investor's first contribution to that deal
-- 3. Assign sequence numbers: 1, 2, 3, ... based on chronological order
-- 4. Create participation records with immutable sequence numbers
--
-- IDEMPOTENCY:
-- Safe to run multiple times. Uses INSERT ... ON CONFLICT DO NOTHING.
--
-- VALIDATION:
-- Includes comprehensive validation queries at the end.
--
-- ============================================================================

BEGIN;

-- ============================================
-- STEP 1: Pre-migration validation
-- ============================================

SELECT '=== PRE-MIGRATION VALIDATION ===' as step;

-- Check if investor_deal_participations table exists
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'investor_deal_participations') THEN
    RAISE EXCEPTION 'Table investor_deal_participations does not exist. Run migration first.';
  END IF;
END $$;

-- Count existing participations (if any)
SELECT
  'Existing participations' as metric,
  COUNT(*) as count
FROM investor_deal_participations;

-- Count total contributions by scope
SELECT
  'Total contributions' as metric,
  COUNT(*) as total_contributions,
  COUNT(*) FILTER (WHERE deal_id IS NOT NULL) as deal_contributions,
  COUNT(*) FILTER (WHERE fund_id IS NOT NULL) as fund_contributions
FROM contributions;

-- Count distinct investor-deal combinations
SELECT
  'Distinct investor-deal pairs' as metric,
  COUNT(DISTINCT (investor_id, deal_id)) as count
FROM contributions
WHERE deal_id IS NOT NULL;

-- ============================================
-- STEP 2: Analyze participation patterns
-- ============================================

SELECT '=== ANALYZING PARTICIPATION PATTERNS ===' as step;

-- Show sample of investors with multiple deals
SELECT
  'Sample: Multi-deal investors' as section,
  i.id as investor_id,
  i.name as investor_name,
  COUNT(DISTINCT c.deal_id) as deal_count,
  array_agg(DISTINCT d.name ORDER BY d.name) as deals
FROM contributions c
INNER JOIN investors i ON i.id = c.investor_id
LEFT JOIN deals d ON d.id = c.deal_id
WHERE c.deal_id IS NOT NULL
GROUP BY i.id, i.name
HAVING COUNT(DISTINCT c.deal_id) > 1
ORDER BY COUNT(DISTINCT c.deal_id) DESC
LIMIT 10;

-- Show date range of contributions
SELECT
  'Contribution date range' as metric,
  MIN(paid_in_date) as earliest_contribution,
  MAX(paid_in_date) as latest_contribution,
  MAX(paid_in_date) - MIN(paid_in_date) as days_span
FROM contributions
WHERE deal_id IS NOT NULL;

-- ============================================
-- STEP 3: Build participation records (DRY RUN - preview only)
-- ============================================

SELECT '=== DRY RUN: Preview participation records to be created ===' as step;

-- This query shows what will be inserted
WITH investor_deal_first_contrib AS (
  -- For each investor-deal combination, find the first contribution
  SELECT
    c.investor_id,
    c.deal_id,
    MIN(c.paid_in_date) as first_contrib_date,
    MIN(c.id) FILTER (WHERE c.paid_in_date = MIN(c.paid_in_date)) as first_contrib_id
  FROM contributions c
  WHERE c.deal_id IS NOT NULL
  GROUP BY c.investor_id, c.deal_id
),
investor_deal_sequence AS (
  -- Assign sequence numbers based on chronological order
  SELECT
    investor_id,
    deal_id,
    first_contrib_date,
    first_contrib_id,
    ROW_NUMBER() OVER (
      PARTITION BY investor_id
      ORDER BY first_contrib_date, deal_id  -- tie-breaker: deal_id for determinism
    ) as participation_sequence
  FROM investor_deal_first_contrib
)
SELECT
  'Preview' as section,
  i.name as investor_name,
  d.name as deal_name,
  ids.participation_sequence as sequence,
  get_commission_tier_rate(ids.participation_sequence) as tier_rate_bps,
  get_commission_tier_description(ids.participation_sequence) as tier_description,
  ids.first_contrib_date,
  c.amount as first_contrib_amount
FROM investor_deal_sequence ids
INNER JOIN investors i ON i.id = ids.investor_id
INNER JOIN deals d ON d.id = ids.deal_id
INNER JOIN contributions c ON c.id = ids.first_contrib_id
ORDER BY i.name, ids.participation_sequence
LIMIT 50;

-- Count participations by tier
SELECT
  'Participations by tier (preview)' as section,
  CASE
    WHEN participation_sequence = 1 THEN 'Tier 1: First Deal (1.5%)'
    WHEN participation_sequence IN (2, 3) THEN 'Tier 2: Deals 2-3 (1.0%)'
    WHEN participation_sequence IN (4, 5) THEN 'Tier 3: Deals 4-5 (0.5%)'
    ELSE 'No Commission (Deals 6+)'
  END as tier_description,
  COUNT(*) as participation_count,
  SUM(c.amount) as total_contribution_amount
FROM (
  SELECT
    c.investor_id,
    c.deal_id,
    MIN(c.paid_in_date) as first_contrib_date,
    MIN(c.id) FILTER (WHERE c.paid_in_date = MIN(c.paid_in_date)) as first_contrib_id
  FROM contributions c
  WHERE c.deal_id IS NOT NULL
  GROUP BY c.investor_id, c.deal_id
) first_contrib
CROSS JOIN LATERAL (
  SELECT
    ROW_NUMBER() OVER (
      PARTITION BY first_contrib.investor_id
      ORDER BY first_contrib.first_contrib_date, first_contrib.deal_id
    ) as participation_sequence
  FROM (SELECT first_contrib.*) sub
) seq
INNER JOIN contributions c ON c.id = first_contrib.first_contrib_id
GROUP BY
  CASE
    WHEN participation_sequence = 1 THEN 'Tier 1: First Deal (1.5%)'
    WHEN participation_sequence IN (2, 3) THEN 'Tier 2: Deals 2-3 (1.0%)'
    WHEN participation_sequence IN (4, 5) THEN 'Tier 3: Deals 4-5 (0.5%)'
    ELSE 'No Commission (Deals 6+)'
  END
ORDER BY MIN(seq.participation_sequence);

-- ============================================
-- STEP 4: Insert participation records (ACTUAL INSERTION)
-- ============================================

SELECT '=== INSERTING PARTICIPATION RECORDS ===' as step;

-- Disable the auto-create trigger temporarily to avoid conflicts
ALTER TABLE contributions DISABLE TRIGGER trigger_auto_create_participation;

-- Insert participation records
WITH investor_deal_first_contrib AS (
  -- For each investor-deal combination, find the first contribution
  SELECT
    c.investor_id,
    c.deal_id,
    MIN(c.paid_in_date) as first_contrib_date,
    MIN(c.id) FILTER (WHERE c.paid_in_date = MIN(c.paid_in_date)) as first_contrib_id
  FROM contributions c
  WHERE c.deal_id IS NOT NULL
  GROUP BY c.investor_id, c.deal_id
),
investor_deal_sequence AS (
  -- Assign sequence numbers based on chronological order
  SELECT
    investor_id,
    deal_id,
    first_contrib_date,
    first_contrib_id,
    ROW_NUMBER() OVER (
      PARTITION BY investor_id
      ORDER BY first_contrib_date, deal_id  -- tie-breaker: deal_id for determinism
    ) as participation_sequence
  FROM investor_deal_first_contrib
)
INSERT INTO investor_deal_participations (
  investor_id,
  deal_id,
  participation_sequence,
  first_contribution_date,
  first_contribution_id,
  created_at,
  notes
)
SELECT
  investor_id,
  deal_id,
  participation_sequence,
  first_contrib_date,
  first_contrib_id,
  now(),
  'Backfilled from historical contributions on ' || now()::date
FROM investor_deal_sequence
ON CONFLICT (investor_id, deal_id) DO NOTHING;

-- Re-enable the trigger
ALTER TABLE contributions ENABLE TRIGGER trigger_auto_create_participation;

-- Report insertion results
SELECT
  'Insertion complete' as status,
  COUNT(*) as records_inserted
FROM investor_deal_participations
WHERE notes LIKE '%Backfilled%';

-- ============================================
-- STEP 5: Post-migration validation
-- ============================================

SELECT '=== POST-MIGRATION VALIDATION ===' as step;

-- Total participations created
SELECT
  'Total participations' as metric,
  COUNT(*) as count
FROM investor_deal_participations;

-- Participations by tier
SELECT
  'Participations by tier' as section,
  get_commission_tier_description(participation_sequence) as tier,
  COUNT(*) as count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM investor_deal_participations
GROUP BY get_commission_tier_description(participation_sequence)
ORDER BY MIN(participation_sequence);

-- Investors with most deals
SELECT
  'Top investors by deal count' as section,
  i.name as investor_name,
  COUNT(idp.id) as total_deals,
  get_commission_tier_description(COUNT(idp.id) + 1) as next_deal_tier,
  array_agg(d.name ORDER BY idp.participation_sequence) as deal_sequence
FROM investor_deal_participations idp
INNER JOIN investors i ON i.id = idp.investor_id
INNER JOIN deals d ON d.id = idp.deal_id
GROUP BY i.id, i.name
ORDER BY COUNT(idp.id) DESC, i.name
LIMIT 10;

-- Validate sequence integrity for all investors
SELECT
  'Sequence integrity check' as section,
  investor_id,
  i.name as investor_name,
  is_valid,
  error_message,
  expected_sequence,
  actual_sequence
FROM investors i
CROSS JOIN LATERAL validate_investor_participation_sequence(i.id)
WHERE NOT is_valid;

-- If above query returns no rows, all sequences are valid!
SELECT
  CASE
    WHEN NOT EXISTS (
      SELECT 1 FROM investors i
      CROSS JOIN LATERAL validate_investor_participation_sequence(i.id)
      WHERE NOT is_valid
    )
    THEN '✅ All investor participation sequences are valid!'
    ELSE '❌ Some sequences have gaps or errors - see above'
  END as validation_result;

-- Sample: Show detailed participation history for one investor
SELECT
  'Sample: Detailed participation history' as section,
  i.name as investor_name,
  idp.participation_sequence as deal_number,
  d.name as deal_name,
  idp.first_contribution_date,
  c.amount as first_contribution_amount,
  get_commission_tier_rate(idp.participation_sequence) as tier_rate_bps,
  get_commission_tier_description(idp.participation_sequence) as tier_description
FROM investor_deal_participations idp
INNER JOIN investors i ON i.id = idp.investor_id
INNER JOIN deals d ON d.id = idp.deal_id
INNER JOIN contributions c ON c.id = idp.first_contribution_id
WHERE i.id = (
  -- Pick an investor with multiple deals
  SELECT investor_id
  FROM investor_deal_participations
  GROUP BY investor_id
  HAVING COUNT(*) > 1
  ORDER BY COUNT(*) DESC
  LIMIT 1
)
ORDER BY idp.participation_sequence;

-- Check for duplicate participations (should be 0)
SELECT
  'Duplicate check' as metric,
  COUNT(*) as duplicates
FROM (
  SELECT investor_id, deal_id, COUNT(*)
  FROM investor_deal_participations
  GROUP BY investor_id, deal_id
  HAVING COUNT(*) > 1
) dupes;

-- Check for sequence gaps (should be 0)
SELECT
  'Sequence gaps check' as metric,
  COUNT(*) as investors_with_gaps
FROM (
  SELECT
    investor_id,
    MAX(participation_sequence) as max_seq,
    COUNT(*) as participation_count
  FROM investor_deal_participations
  GROUP BY investor_id
  HAVING MAX(participation_sequence) != COUNT(*)
) gaps;

-- ============================================
-- STEP 6: Test helper functions
-- ============================================

SELECT '=== TESTING HELPER FUNCTIONS ===' as step;

-- Test get_investor_deal_count() function
SELECT
  'Sample: Investor deal counts' as section,
  i.id as investor_id,
  i.name as investor_name,
  get_investor_deal_count(i.id) as deal_count,
  (SELECT COUNT(*) FROM investor_deal_participations WHERE investor_id = i.id) as verified_count
FROM investors i
WHERE EXISTS (SELECT 1 FROM investor_deal_participations WHERE investor_id = i.id)
ORDER BY get_investor_deal_count(i.id) DESC
LIMIT 10;

-- Test get_investor_deal_sequence() function
SELECT
  'Sample: Specific investor-deal sequences' as section,
  i.name as investor_name,
  d.name as deal_name,
  get_investor_deal_sequence(i.id, d.id) as sequence_number,
  idp.participation_sequence as verified_sequence
FROM investor_deal_participations idp
INNER JOIN investors i ON i.id = idp.investor_id
INNER JOIN deals d ON d.id = idp.deal_id
ORDER BY i.name, idp.participation_sequence
LIMIT 10;

-- Test get_commission_tier_rate() function
SELECT
  'Commission tier rates' as section,
  seq as deal_sequence,
  get_commission_tier_rate(seq) as rate_bps,
  get_commission_tier_description(seq) as description
FROM generate_series(1, 7) seq;

-- ============================================
-- STEP 7: Test views
-- ============================================

SELECT '=== TESTING VIEWS ===' as step;

-- Test investor_participation_summary view
SELECT
  'Investor participation summary' as section,
  *
FROM investor_participation_summary
ORDER BY total_deals DESC, investor_name
LIMIT 10;

-- Test deal_participation_with_tiers view
SELECT
  'Deal participations with tiers' as section,
  *
FROM deal_participation_with_tiers
ORDER BY investor_name, participation_sequence
LIMIT 10;

-- ============================================
-- COMPLETION MESSAGE
-- ============================================

SELECT '
╔═══════════════════════════════════════════════════════════════╗
║  INITIALIZATION COMPLETE                                       ║
╚═══════════════════════════════════════════════════════════════╝

✅ Historical investor deal participations have been successfully initialized!

NEXT STEPS:
1. Review the validation results above
2. Test commission calculations using get_investor_deal_sequence()
3. Update commission computation logic to use tiered rates
4. Monitor the trigger for new contributions

IMPORTANT NOTES:
- Participation sequence numbers are now IMMUTABLE
- New contributions will automatically create participations (via trigger)
- Sequence integrity is validated and enforced
- Helper functions are ready for commission calculations

For any questions or issues, review the migration documentation in:
  supabase/migrations/20251026000001_investor_deal_participations.sql

' as completion_message;

COMMIT;

-- ============================================
-- ROLLBACK (if needed)
-- ============================================

-- To rollback the data (but keep the schema):
-- DELETE FROM investor_deal_participations WHERE notes LIKE '%Backfilled%';
