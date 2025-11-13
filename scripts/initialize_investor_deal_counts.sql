-- ============================================================================
-- Initialize Investor Deal Participation History
-- ============================================================================
-- Purpose: Populate investor deal participation history from historical
--          transaction data for tiered commission calculations
--
-- Business Context:
-- - Commission rates may vary based on investor's deal participation count
--   (e.g., 1st deal, 2nd deal, 3rd+ deal)
-- - Multiple transactions to the same deal = ONE participation
-- - Sequence determined by FIRST transaction date to each deal
-- - This script analyzes existing transactions and generates participation records
--
-- Prerequisites:
-- - transactions table populated with historical data
-- - investor_deal_participations table created (by schema agent)
--
-- Date: 2025-10-26
-- Author: Claude Code (Automated Script)
-- ============================================================================

-- ============================================================================
-- SECTION 1: DATA DISCOVERY & VALIDATION
-- ============================================================================

-- Query 1.1: Overview of transaction data
-- Purpose: Understand the scope of data to process
SELECT
    '=== TRANSACTION DATA OVERVIEW ===' AS section,
    COUNT(DISTINCT id) AS total_transactions,
    COUNT(DISTINCT investor_id) AS unique_investors,
    COUNT(DISTINCT deal_id) AS unique_deals_transacted,
    COUNT(DISTINCT fund_id) AS unique_funds_transacted,
    MIN(paid_in_date) AS earliest_transaction,
    MAX(paid_in_date) AS latest_transaction,
    COUNT(*) AS contribution_count,
    0 AS repurchase_count  -- All rows are contributions
FROM contributions;

-- Query 1.2: Verify investor count (should be 110 as stated)
-- Purpose: Confirm expected investor count
SELECT
    '=== INVESTOR COUNT VERIFICATION ===' AS section,
    COUNT(*) AS total_investors_in_db,
    COUNT(*) FILTER (WHERE id IN (SELECT DISTINCT investor_id FROM contributions)) AS investors_with_transactions,
    COUNT(*) FILTER (WHERE id NOT IN (SELECT DISTINCT investor_id FROM contributions)) AS investors_without_transactions
FROM investors;

-- Query 1.3: Transaction distribution by investor
-- Purpose: Identify investors with multiple transactions
SELECT
    '=== TRANSACTION DISTRIBUTION ===' AS section,
    transaction_count,
    COUNT(*) AS investor_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM (
    SELECT
        investor_id,
        COUNT(*) AS transaction_count
    FROM contributions
    GROUP BY investor_id
) AS investor_txn_counts
GROUP BY transaction_count
ORDER BY transaction_count;

-- ============================================================================
-- SECTION 2: INVESTOR-DEAL PARTICIPATION ANALYSIS
-- ============================================================================

-- Query 2.1: Extract unique investor-deal combinations with first transaction date
-- Purpose: Core query to identify all investor-deal participations
-- Note: Multiple transactions to same deal = ONE participation
WITH investor_deal_participation AS (
    SELECT
        t.investor_id,
        t.deal_id,
        t.fund_id,
        MIN(t.paid_in_date) AS first_paid_in_date,
        COUNT(*) AS transaction_count,
        SUM(t.amount) AS total_amount_transacted
    FROM contributions t
    -- All rows in contributions table are contributions
    GROUP BY t.investor_id, t.deal_id, t.fund_id
)
SELECT
    '=== UNIQUE INVESTOR-DEAL PARTICIPATIONS ===' AS section,
    idp.investor_id,
    i.name AS investor_name,
    idp.deal_id,
    d.name AS deal_name,
    idp.fund_id,
    f.name AS fund_name,
    idp.first_paid_in_date,
    idp.transaction_count,
    idp.total_amount_transacted,
    idp.total_amount_transacted::TEXT || ' USD' AS formatted_amount
FROM investor_deal_participation idp
LEFT JOIN investors i ON i.id = idp.investor_id
LEFT JOIN deals d ON d.id = idp.deal_id
LEFT JOIN funds f ON f.id = idp.fund_id
ORDER BY idp.investor_id, idp.first_paid_in_date, idp.deal_id;

-- Query 2.2: Count participations per investor
-- Purpose: Show distribution of deal participation counts
SELECT
    '=== PARTICIPATION COUNT DISTRIBUTION ===' AS section,
    deal_count,
    COUNT(*) AS investor_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage,
    STRING_AGG(investor_name, ', ' ORDER BY investor_name) AS sample_investors
FROM (
    SELECT
        idp.investor_id,
        i.name AS investor_name,
        COUNT(DISTINCT COALESCE(idp.deal_id::TEXT, 'fund_' || idp.fund_id::TEXT)) AS deal_count
    FROM (
        SELECT
            investor_id,
            deal_id,
            fund_id,
            MIN(paid_in_date) AS first_paid_in_date
        FROM contributions
        GROUP BY investor_id, deal_id, fund_id
    ) idp
    LEFT JOIN investors i ON i.id = idp.investor_id
    GROUP BY idp.investor_id, i.name
) investor_counts
GROUP BY deal_count
ORDER BY deal_count;

-- Query 2.3: Investors with most deal participations
-- Purpose: Identify power users for validation
SELECT
    '=== TOP 20 INVESTORS BY DEAL COUNT ===' AS section,
    i.id AS investor_id,
    i.name AS investor_name,
    COUNT(DISTINCT COALESCE(t.deal_id::TEXT, 'fund_' || t.fund_id::TEXT)) AS unique_deals,
    COUNT(*) AS total_transactions,
    SUM(t.amount) AS total_contributed,
    MIN(t.paid_in_date) AS first_transaction,
    MAX(t.paid_in_date) AS last_transaction
FROM contributions t
INNER JOIN investors i ON i.id = t.investor_id
GROUP BY i.id, i.name
ORDER BY unique_deals DESC, total_contributed DESC
LIMIT 20;

-- ============================================================================
-- SECTION 3: CHRONOLOGICAL SEQUENCE ASSIGNMENT
-- ============================================================================

-- Query 3.1: Assign sequence numbers to investor deal participations
-- Purpose: Core logic for determining 1st, 2nd, 3rd deal, etc.
-- Note: Uses ROW_NUMBER() partitioned by investor, ordered by first transaction date
WITH investor_deal_first_dates AS (
    -- Step 1: Get first transaction date for each investor-deal combination
    SELECT
        t.investor_id,
        t.deal_id,
        t.fund_id,
        MIN(t.paid_in_date) AS first_paid_in_date
    FROM contributions t
        GROUP BY t.investor_id, t.deal_id, t.fund_id
),
investor_deal_sequences AS (
    -- Step 2: Assign sequence number within each investor
    SELECT
        idfd.investor_id,
        idfd.deal_id,
        idfd.fund_id,
        idfd.first_paid_in_date,
        ROW_NUMBER() OVER (
            PARTITION BY idfd.investor_id
            ORDER BY idfd.first_paid_in_date, COALESCE(idfd.deal_id, 0), COALESCE(idfd.fund_id, 0)
        ) AS participation_sequence
    FROM investor_deal_first_dates idfd
)
SELECT
    '=== INVESTOR DEAL PARTICIPATION SEQUENCES ===' AS section,
    ids.investor_id,
    i.name AS investor_name,
    ids.deal_id,
    d.name AS deal_name,
    ids.fund_id,
    f.name AS fund_name,
    ids.first_paid_in_date,
    ids.participation_sequence,
    CASE
        WHEN ids.participation_sequence = 1 THEN '1st deal (First-time investor)'
        WHEN ids.participation_sequence = 2 THEN '2nd deal'
        WHEN ids.participation_sequence = 3 THEN '3rd deal'
        ELSE ids.participation_sequence || 'th deal'
    END AS participation_label
FROM investor_deal_sequences ids
LEFT JOIN investors i ON i.id = ids.investor_id
LEFT JOIN deals d ON d.id = ids.deal_id
LEFT JOIN funds f ON f.id = ids.fund_id
ORDER BY ids.investor_id, ids.participation_sequence;

-- Query 3.2: Handle date ties (same-day transactions to different deals)
-- Purpose: Show how ties are resolved (by deal_id/fund_id as secondary sort)
WITH date_ties AS (
    SELECT
        t.investor_id,
        t.paid_in_date,
        COUNT(DISTINCT COALESCE(t.deal_id::TEXT, 'fund_' || t.fund_id::TEXT)) AS deals_on_same_day
    FROM contributions t
        GROUP BY t.investor_id, t.paid_in_date
    HAVING COUNT(DISTINCT COALESCE(t.deal_id::TEXT, 'fund_' || t.fund_id::TEXT)) > 1
)
SELECT
    '=== DATE TIE HANDLING ===' AS section,
    dt.investor_id,
    i.name AS investor_name,
    dt.paid_in_date,
    dt.deals_on_same_day,
    STRING_AGG(
        COALESCE(d.name, f.name) || ' (ID: ' || COALESCE(t.deal_id::TEXT, 'fund_' || t.fund_id::TEXT) || ')',
        ', '
        ORDER BY COALESCE(t.deal_id, 0), COALESCE(t.fund_id, 0)
    ) AS deals_with_ties
FROM date_ties dt
INNER JOIN investors i ON i.id = dt.investor_id
INNER JOIN contributions t ON t.investor_id = dt.investor_id AND t.paid_in_date = dt.paid_in_date
LEFT JOIN deals d ON d.id = t.deal_id
LEFT JOIN funds f ON f.id = t.fund_id
GROUP BY dt.investor_id, i.name, dt.paid_in_date, dt.deals_on_same_day
ORDER BY dt.investor_id, dt.paid_in_date;

-- ============================================================================
-- SECTION 4: GENERATE INSERT STATEMENTS
-- ============================================================================

-- Query 4.1: Preview of INSERT data (first 50 rows)
-- Purpose: Review data before insertion
WITH investor_deal_first_dates AS (
    SELECT
        t.investor_id,
        t.deal_id,
        t.fund_id,
        MIN(t.paid_in_date) AS first_paid_in_date
    FROM contributions t
        GROUP BY t.investor_id, t.deal_id, t.fund_id
),
investor_deal_sequences AS (
    SELECT
        idfd.investor_id,
        idfd.deal_id,
        idfd.fund_id,
        idfd.first_paid_in_date,
        ROW_NUMBER() OVER (
            PARTITION BY idfd.investor_id
            ORDER BY idfd.first_paid_in_date, COALESCE(idfd.deal_id, 0), COALESCE(idfd.fund_id, 0)
        ) AS participation_sequence
    FROM investor_deal_first_dates idfd
)
SELECT
    '=== INSERT DATA PREVIEW (First 50) ===' AS section,
    ids.investor_id,
    i.name AS investor_name,
    ids.deal_id,
    d.name AS deal_name,
    ids.fund_id,
    f.name AS fund_name,
    ids.first_paid_in_date,
    ids.participation_sequence
FROM investor_deal_sequences ids
LEFT JOIN investors i ON i.id = ids.investor_id
LEFT JOIN deals d ON d.id = ids.deal_id
LEFT JOIN funds f ON f.id = ids.fund_id
ORDER BY ids.investor_id, ids.participation_sequence
LIMIT 50;

-- ============================================================================
-- ACTUAL INSERT STATEMENT
-- ============================================================================
-- Note: This assumes the investor_deal_participations table has been created
-- Expected schema:
--   - id (primary key, auto-generated)
--   - investor_id (FK to investors)
--   - deal_id (FK to deals, nullable)
--   - fund_id (FK to funds, nullable)
--   - first_participation_date (date of first transaction)
--   - participation_sequence (1, 2, 3, etc.)
--   - created_at (timestamp)
-- ============================================================================

-- UNCOMMENT BELOW TO EXECUTE INSERT
-- First, ensure the table exists and is empty
/*
TRUNCATE TABLE investor_deal_participations RESTART IDENTITY CASCADE;
*/

-- Execute the INSERT
/*
WITH investor_deal_first_dates AS (
    SELECT
        t.investor_id,
        t.deal_id,
        t.fund_id,
        MIN(t.paid_in_date) AS first_paid_in_date
    FROM contributions t
        GROUP BY t.investor_id, t.deal_id, t.fund_id
),
investor_deal_sequences AS (
    SELECT
        idfd.investor_id,
        idfd.deal_id,
        idfd.fund_id,
        idfd.first_paid_in_date,
        ROW_NUMBER() OVER (
            PARTITION BY idfd.investor_id
            ORDER BY idfd.first_paid_in_date, COALESCE(idfd.deal_id, 0), COALESCE(idfd.fund_id, 0)
        ) AS participation_sequence
    FROM investor_deal_first_dates idfd
)
INSERT INTO investor_deal_participations (
    investor_id,
    deal_id,
    fund_id,
    first_participation_date,
    participation_sequence,
    created_at
)
SELECT
    ids.investor_id,
    ids.deal_id,
    ids.fund_id,
    ids.first_paid_in_date,
    ids.participation_sequence,
    NOW()
FROM investor_deal_sequences ids
ORDER BY ids.investor_id, ids.participation_sequence;
*/

-- ============================================================================
-- SECTION 5: VERIFICATION QUERIES
-- ============================================================================

-- Query 5.1: Verify all investors have correct participation counts
-- Purpose: Ensure no investor was missed or duplicated
SELECT
    '=== PARTICIPATION COUNT VERIFICATION ===' AS section,
    'From Transactions' AS source,
    COUNT(DISTINCT investor_id) AS unique_investors,
    COUNT(*) AS total_participations
FROM (
    SELECT
        investor_id,
        deal_id,
        fund_id,
        MIN(paid_in_date) AS first_date
    FROM contributions
    GROUP BY investor_id, deal_id, fund_id
) t
UNION ALL
SELECT
    '=== PARTICIPATION COUNT VERIFICATION ===' AS section,
    'From Participations Table' AS source,
    COUNT(DISTINCT investor_id) AS unique_investors,
    COUNT(*) AS total_participations
FROM investor_deal_participations;

-- Query 5.2: Verify sequence numbers are continuous (no gaps)
-- Purpose: Ensure each investor has 1, 2, 3... with no skips
WITH investor_sequences AS (
    SELECT
        investor_id,
        participation_sequence,
        LAG(participation_sequence) OVER (PARTITION BY investor_id ORDER BY participation_sequence) AS prev_sequence
    FROM investor_deal_participations
)
SELECT
    '=== SEQUENCE CONTINUITY CHECK ===' AS section,
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS: All sequences are continuous'
        ELSE 'FAIL: Found ' || COUNT(*) || ' sequence gaps'
    END AS result,
    COALESCE(STRING_AGG(
        'Investor ' || investor_id || ': gap between ' || prev_sequence || ' and ' || participation_sequence,
        '; '
    ), 'No gaps found') AS details
FROM investor_sequences
WHERE prev_sequence IS NOT NULL AND participation_sequence != prev_sequence + 1;

-- Query 5.3: Verify first participation has sequence = 1
-- Purpose: Ensure all investors start at sequence 1
SELECT
    '=== FIRST PARTICIPATION CHECK ===' AS section,
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS: All investors start at sequence 1'
        ELSE 'FAIL: Found ' || COUNT(*) || ' investors not starting at 1'
    END AS result
FROM (
    SELECT investor_id, MIN(participation_sequence) AS first_seq
    FROM investor_deal_participations
    GROUP BY investor_id
    HAVING MIN(participation_sequence) != 1
) bad_starts;

-- Query 5.4: Verify no duplicate investor-deal combinations
-- Purpose: Ensure uniqueness constraint
SELECT
    '=== DUPLICATE CHECK ===' AS section,
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS: No duplicates found'
        ELSE 'FAIL: Found ' || COUNT(*) || ' duplicate investor-deal pairs'
    END AS result
FROM (
    SELECT
        investor_id,
        deal_id,
        fund_id,
        COUNT(*) AS occurrence_count
    FROM investor_deal_participations
    GROUP BY investor_id, deal_id, fund_id
    HAVING COUNT(*) > 1
) duplicates;

-- Query 5.5: Verify chronological order within each investor
-- Purpose: Ensure participation dates are monotonically increasing
WITH date_check AS (
    SELECT
        investor_id,
        participation_sequence,
        first_participation_date,
        LAG(first_participation_date) OVER (
            PARTITION BY investor_id
            ORDER BY participation_sequence
        ) AS prev_date
    FROM investor_deal_participations
)
SELECT
    '=== CHRONOLOGICAL ORDER CHECK ===' AS section,
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS: All dates in chronological order'
        ELSE 'FAIL: Found ' || COUNT(*) || ' out-of-order dates'
    END AS result,
    COALESCE(STRING_AGG(
        'Investor ' || investor_id || ': sequence ' || participation_sequence ||
        ' date ' || first_participation_date || ' before previous ' || prev_date,
        '; '
        ORDER BY investor_id, participation_sequence
    ), 'All dates properly ordered') AS details
FROM date_check
WHERE prev_date IS NOT NULL AND first_participation_date < prev_date;

-- ============================================================================
-- SECTION 6: SUMMARY REPORT
-- ============================================================================

-- Query 6.1: Overall summary statistics
SELECT
    '=== OVERALL SUMMARY ===' AS section,
    COUNT(DISTINCT investor_id) AS total_investors,
    COUNT(*) AS total_participations,
    ROUND(AVG(participation_sequence), 2) AS avg_participation_sequence,
    MAX(participation_sequence) AS max_participation_sequence,
    MIN(first_participation_date) AS earliest_participation,
    MAX(first_participation_date) AS latest_participation,
    COUNT(*) FILTER (WHERE deal_id IS NOT NULL) AS deal_level_participations,
    COUNT(*) FILTER (WHERE fund_id IS NOT NULL) AS fund_level_participations
FROM investor_deal_participations;

-- Query 6.2: Participation distribution by sequence number
SELECT
    '=== PARTICIPATION DISTRIBUTION BY SEQUENCE ===' AS section,
    participation_sequence,
    COUNT(DISTINCT investor_id) AS investor_count,
    ROUND(100.0 * COUNT(DISTINCT investor_id) /
        (SELECT COUNT(DISTINCT investor_id) FROM investor_deal_participations), 2
    ) AS percentage_of_investors,
    CASE
        WHEN participation_sequence = 1 THEN 'First-time investors'
        WHEN participation_sequence = 2 THEN 'Second-time investors'
        WHEN participation_sequence = 3 THEN 'Third-time investors'
        WHEN participation_sequence <= 5 THEN 'Repeat investors (4-5 deals)'
        ELSE 'Power investors (6+ deals)'
    END AS investor_category
FROM investor_deal_participations
GROUP BY participation_sequence
ORDER BY participation_sequence;

-- Query 6.3: Top investors by participation count
SELECT
    '=== TOP 25 INVESTORS BY DEAL COUNT ===' AS section,
    idp.investor_id,
    i.name AS investor_name,
    MAX(idp.participation_sequence) AS total_deals,
    MIN(idp.first_participation_date) AS first_deal_date,
    MAX(idp.first_participation_date) AS most_recent_deal_date,
    MAX(idp.first_participation_date) - MIN(idp.first_participation_date) AS investment_period_days,
    ROUND(
        EXTRACT(EPOCH FROM (MAX(idp.first_participation_date) - MIN(idp.first_participation_date))) / 86400.0 /
        NULLIF(MAX(idp.participation_sequence) - 1, 0),
        0
    ) AS avg_days_between_deals
FROM investor_deal_participations idp
INNER JOIN investors i ON i.id = idp.investor_id
GROUP BY idp.investor_id, i.name
ORDER BY MAX(idp.participation_sequence) DESC, i.name
LIMIT 25;

-- Query 6.4: Monthly participation trends
SELECT
    '=== PARTICIPATION TRENDS BY MONTH ===' AS section,
    DATE_TRUNC('month', first_participation_date)::DATE AS month,
    COUNT(*) AS participations_started,
    COUNT(DISTINCT investor_id) AS unique_investors,
    COUNT(*) FILTER (WHERE participation_sequence = 1) AS first_time_investors,
    COUNT(*) FILTER (WHERE participation_sequence > 1) AS repeat_investors,
    ROUND(100.0 * COUNT(*) FILTER (WHERE participation_sequence > 1) / COUNT(*), 2) AS repeat_percentage
FROM investor_deal_participations
GROUP BY DATE_TRUNC('month', first_participation_date)
ORDER BY month;

-- Query 6.5: Investor retention analysis
-- Purpose: Show how many investors from each cohort continued to additional deals
WITH investor_cohorts AS (
    SELECT
        investor_id,
        MIN(first_participation_date) AS cohort_date,
        MAX(participation_sequence) AS total_deals
    FROM investor_deal_participations
    GROUP BY investor_id
)
SELECT
    '=== INVESTOR RETENTION BY INITIAL COHORT ===' AS section,
    DATE_TRUNC('quarter', cohort_date)::DATE AS cohort_quarter,
    COUNT(*) AS investors_in_cohort,
    COUNT(*) FILTER (WHERE total_deals >= 2) AS investors_with_2plus_deals,
    ROUND(100.0 * COUNT(*) FILTER (WHERE total_deals >= 2) / COUNT(*), 2) AS retention_to_2nd_deal_pct,
    COUNT(*) FILTER (WHERE total_deals >= 3) AS investors_with_3plus_deals,
    ROUND(100.0 * COUNT(*) FILTER (WHERE total_deals >= 3) / COUNT(*), 2) AS retention_to_3rd_deal_pct,
    ROUND(AVG(total_deals), 2) AS avg_total_deals
FROM investor_cohorts
GROUP BY DATE_TRUNC('quarter', cohort_date)
ORDER BY cohort_quarter;

-- ============================================================================
-- SECTION 7: SAMPLE DATA FOR VALIDATION
-- ============================================================================

-- Query 7.1: Sample 5 investors with complete participation history
SELECT
    '=== SAMPLE INVESTOR HISTORIES (5 Random Investors) ===' AS section,
    idp.investor_id,
    i.name AS investor_name,
    idp.participation_sequence,
    idp.deal_id,
    d.name AS deal_name,
    idp.fund_id,
    f.name AS fund_name,
    idp.first_participation_date,
    CASE
        WHEN idp.participation_sequence = 1 THEN '🎯 First deal'
        WHEN idp.participation_sequence = 2 THEN '✅ Second deal'
        WHEN idp.participation_sequence = 3 THEN '🏆 Third deal'
        ELSE '⭐ Deal #' || idp.participation_sequence
    END AS milestone
FROM investor_deal_participations idp
INNER JOIN investors i ON i.id = idp.investor_id
LEFT JOIN deals d ON d.id = idp.deal_id
LEFT JOIN funds f ON f.id = idp.fund_id
WHERE idp.investor_id IN (
    SELECT investor_id
    FROM investor_deal_participations
    GROUP BY investor_id
    HAVING MAX(participation_sequence) >= 3
    ORDER BY RANDOM()
    LIMIT 5
)
ORDER BY idp.investor_id, idp.participation_sequence;

-- ============================================================================
-- COMPLETION MESSAGE
-- ============================================================================

SELECT
    '=== INITIALIZATION COMPLETE ===' AS section,
    'Review the queries above to validate the data before uncommenting the INSERT statement.' AS message,
    'Expected: ~110 unique investors with participation sequences starting at 1.' AS note;

-- ============================================================================
-- USAGE INSTRUCTIONS
-- ============================================================================
--
-- 1. Run Sections 1-3 to analyze existing data and preview sequences
-- 2. Review output to ensure logic is correct
-- 3. Create investor_deal_participations table (via schema migration)
-- 4. Uncomment the INSERT statement in Section 4
-- 5. Execute the INSERT
-- 6. Run Section 5 verification queries to validate integrity
-- 7. Review Section 6 summary report for business insights
-- 8. Share Section 7 sample data with stakeholders for validation
--
-- ============================================================================
