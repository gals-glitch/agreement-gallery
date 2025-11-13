-- ============================================================================
-- Initialize Investor Deal Participation History (DEALS ONLY)
-- ============================================================================
-- Purpose: Populate investor DEAL participation history from historical
--          contribution data for tiered commission calculations
--
-- Business Context:
-- - Commission rates vary based on investor's DEAL participation count
--   (e.g., 1st deal = 1.5%, deals 2-3 = 1%, deals 4-5 = 0.5%)
-- - Multiple contributions to the same deal = ONE participation
-- - Sequence determined by FIRST contribution date to each deal
-- - Fund-level contributions are EXCLUDED (only tracking deals)
--
-- Prerequisites:
-- - contributions table populated with historical data
-- - investor_deal_participations table created (migration applied)
--
-- Date: 2025-10-27
-- ============================================================================

-- ============================================================================
-- STEP 1: Verify Data Before Population
-- ============================================================================

-- Check 1: How many deal contributions exist?
SELECT
    '=== DEAL CONTRIBUTIONS OVERVIEW ===' AS section,
    COUNT(*) AS total_deal_contributions,
    COUNT(DISTINCT investor_id) AS unique_investors_with_deals,
    COUNT(DISTINCT deal_id) AS unique_deals,
    MIN(paid_in_date) AS earliest_contribution,
    MAX(paid_in_date) AS latest_contribution
FROM contributions
WHERE deal_id IS NOT NULL;

-- Check 2: Top investors by deal count
SELECT
    '=== TOP INVESTORS BY DEAL COUNT ===' AS section,
    i.id,
    i.name,
    COUNT(DISTINCT c.deal_id) AS unique_deals_participated
FROM investors i
INNER JOIN contributions c ON c.investor_id = i.id
WHERE c.deal_id IS NOT NULL
GROUP BY i.id, i.name
ORDER BY unique_deals_participated DESC
LIMIT 10;

-- Check 3: Verify table is empty before insert
SELECT
    '=== PARTICIPATION TABLE STATUS ===' AS section,
    COUNT(*) AS existing_records,
    CASE
        WHEN COUNT(*) = 0 THEN 'READY FOR POPULATION'
        ELSE 'WARNING: Table already has data!'
    END AS status
FROM investor_deal_participations;

-- ============================================================================
-- STEP 2: Populate Investor Deal Participations
-- ============================================================================

-- Strategy:
-- 1. Find first contribution date for each investor-deal combination
-- 2. Assign sequence numbers based on chronological order
-- 3. Ties broken by deal_id (lowest first)
-- 4. Insert into investor_deal_participations table

WITH investor_deal_first_dates AS (
    -- For each investor-deal combo, find the first contribution date
    SELECT
        c.investor_id,
        c.deal_id,
        MIN(c.paid_in_date) AS first_paid_in_date,
        MIN(c.id) AS first_contribution_id  -- Use earliest contribution ID as reference
    FROM contributions c
    WHERE c.deal_id IS NOT NULL  -- Only deal contributions
    GROUP BY c.investor_id, c.deal_id
),
investor_deal_sequences AS (
    -- Assign sequence numbers (1, 2, 3...) per investor
    SELECT
        idfd.investor_id,
        idfd.deal_id,
        idfd.first_paid_in_date,
        idfd.first_contribution_id,
        ROW_NUMBER() OVER (
            PARTITION BY idfd.investor_id
            ORDER BY idfd.first_paid_in_date ASC, idfd.deal_id ASC
        ) AS participation_sequence
    FROM investor_deal_first_dates idfd
)
INSERT INTO investor_deal_participations (
    investor_id,
    deal_id,
    participation_sequence,
    first_contribution_date,
    first_contribution_id,
    created_at
)
SELECT
    ids.investor_id,
    ids.deal_id,
    ids.participation_sequence,
    ids.first_paid_in_date,
    ids.first_contribution_id,
    NOW()
FROM investor_deal_sequences ids
ORDER BY ids.investor_id, ids.participation_sequence;

-- ============================================================================
-- STEP 3: Verify Population Success
-- ============================================================================

-- Check 1: Total records inserted
SELECT
    '=== POPULATION RESULTS ===' AS section,
    COUNT(*) AS total_participations_created,
    COUNT(DISTINCT investor_id) AS unique_investors,
    COUNT(DISTINCT deal_id) AS unique_deals,
    MIN(participation_sequence) AS min_sequence,
    MAX(participation_sequence) AS max_sequence
FROM investor_deal_participations;

-- Check 2: Sequence integrity check
-- Every investor should have sequential numbers with no gaps
SELECT
    '=== SEQUENCE INTEGRITY CHECK ===' AS section,
    investor_id,
    i.name AS investor_name,
    COUNT(*) AS participation_count,
    MIN(participation_sequence) AS first_seq,
    MAX(participation_sequence) AS last_seq,
    CASE
        WHEN MAX(participation_sequence) = COUNT(*) THEN '✓ VALID'
        ELSE '✗ GAP DETECTED'
    END AS integrity_status
FROM investor_deal_participations idp
INNER JOIN investors i ON i.id = idp.investor_id
GROUP BY investor_id, i.name
HAVING MAX(participation_sequence) != COUNT(*)
ORDER BY investor_id;

-- If above returns no rows, all sequences are valid!

-- Check 3: Sample data with tier information
SELECT
    '=== SAMPLE PARTICIPATIONS WITH TIERS ===' AS section,
    i.name AS investor_name,
    d.name AS deal_name,
    idp.participation_sequence,
    get_commission_tier_rate(idp.participation_sequence) AS tier_rate_bps,
    get_commission_tier_description(idp.participation_sequence) AS tier_description,
    idp.first_contribution_date
FROM investor_deal_participations idp
INNER JOIN investors i ON i.id = idp.investor_id
INNER JOIN deals d ON d.id = idp.deal_id
ORDER BY i.name, idp.participation_sequence
LIMIT 20;

-- Check 4: Investors with most participations
SELECT
    '=== TOP PARTICIPANTS ===' AS section,
    i.name AS investor_name,
    COUNT(*) AS total_deals,
    MIN(idp.first_contribution_date) AS first_deal_date,
    MAX(idp.first_contribution_date) AS latest_deal_date,
    array_agg(d.name ORDER BY idp.participation_sequence) AS deal_sequence
FROM investor_deal_participations idp
INNER JOIN investors i ON i.id = idp.investor_id
INNER JOIN deals d ON d.id = idp.deal_id
GROUP BY i.id, i.name
ORDER BY total_deals DESC
LIMIT 10;

-- Check 5: Detect any duplicates (should return 0 rows)
SELECT
    '=== DUPLICATE CHECK ===' AS section,
    investor_id,
    deal_id,
    COUNT(*) AS duplicate_count
FROM investor_deal_participations
GROUP BY investor_id, deal_id
HAVING COUNT(*) > 1;

-- If above returns no rows, no duplicates exist!

-- ============================================================================
-- STEP 4: Test Helper Functions
-- ============================================================================

-- Test get_investor_deal_count() function
SELECT
    '=== TEST: get_investor_deal_count() ===' AS section,
    i.id AS investor_id,
    i.name AS investor_name,
    get_investor_deal_count(i.id) AS deal_count_from_function,
    (SELECT COUNT(*) FROM investor_deal_participations WHERE investor_id = i.id) AS actual_count,
    CASE
        WHEN get_investor_deal_count(i.id) = (SELECT COUNT(*) FROM investor_deal_participations WHERE investor_id = i.id)
        THEN '✓ MATCH'
        ELSE '✗ MISMATCH'
    END AS validation
FROM investors i
WHERE EXISTS (SELECT 1 FROM investor_deal_participations WHERE investor_id = i.id)
LIMIT 10;

-- Test get_investor_deal_sequence() function
SELECT
    '=== TEST: get_investor_deal_sequence() ===' AS section,
    idp.investor_id,
    i.name AS investor_name,
    idp.deal_id,
    d.name AS deal_name,
    get_investor_deal_sequence(idp.investor_id, idp.deal_id) AS sequence_from_function,
    idp.participation_sequence AS actual_sequence,
    CASE
        WHEN get_investor_deal_sequence(idp.investor_id, idp.deal_id) = idp.participation_sequence
        THEN '✓ MATCH'
        ELSE '✗ MISMATCH'
    END AS validation
FROM investor_deal_participations idp
INNER JOIN investors i ON i.id = idp.investor_id
INNER JOIN deals d ON d.id = idp.deal_id
LIMIT 10;

-- ============================================================================
-- COMPLETION SUMMARY
-- ============================================================================

SELECT
    '========================' AS separator,
    'INITIALIZATION COMPLETE' AS status,
    '========================' AS separator2;

SELECT
    'Total Participations' AS metric,
    COUNT(*)::TEXT AS value
FROM investor_deal_participations
UNION ALL
SELECT
    'Unique Investors' AS metric,
    COUNT(DISTINCT investor_id)::TEXT AS value
FROM investor_deal_participations
UNION ALL
SELECT
    'Unique Deals' AS metric,
    COUNT(DISTINCT deal_id)::TEXT AS value
FROM investor_deal_participations
UNION ALL
SELECT
    'Date Range' AS metric,
    MIN(first_contribution_date)::TEXT || ' to ' || MAX(first_contribution_date)::TEXT AS value
FROM investor_deal_participations;

-- Next steps:
-- 1. Review the results above
-- 2. Deploy updated commissionCompute.ts
-- 3. Test with pilot contribution data
-- 4. Verify commission calculations use correct tier rates
