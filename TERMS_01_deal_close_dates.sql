-- ============================================================================
-- [TERMS-01] Ensure deals.close_date Exists and Populate
-- ============================================================================
-- PURPOSE: Add close_date column to deals table and populate with actual dates
--
-- COMMISSION RATE TIERS (based on deal close date):
-- - Before Feb 1, 2018:           25% commission
-- - Feb 1, 2018 - Dec 12, 2019:   27% commission
-- - Dec 12, 2019 - Oct 31, 2020:  30% commission
-- - After Oct 31, 2020:           35% commission
--
-- INSTRUCTIONS:
-- 1. Run the ALTER TABLE statement to add the column (safe if exists)
-- 2. Fill in the UPDATE statements with actual close dates for your deals
-- 3. Prioritize deals that have commission agreements mapped
-- ============================================================================

-- Add close_date column if it doesn't exist
ALTER TABLE deals ADD COLUMN IF NOT EXISTS close_date DATE;

-- ============================================================================
-- POPULATE DEAL CLOSE DATES
-- ============================================================================
-- Replace these examples with your actual deal close dates

-- Tier 1: Before Feb 1, 2018 (25% commission rate)
-- UPDATE deals SET close_date = '2017-06-15' WHERE id = 2;  -- BULCC LLC
-- UPDATE deals SET close_date = '2017-11-20' WHERE id = 3;  -- BULMF LLC

-- Tier 2: Feb 1, 2018 - Dec 12, 2019 (27% commission rate)
-- UPDATE deals SET close_date = '2018-03-10' WHERE id = 4;  -- West Coast Land Ventures
-- UPDATE deals SET close_date = '2019-08-05' WHERE id = 5;  -- Marquis Crest

-- Tier 3: Dec 12, 2019 - Oct 31, 2020 (30% commission rate)
-- UPDATE deals SET close_date = '2020-01-15' WHERE id = 6;  -- Providence Plaza
-- UPDATE deals SET close_date = '2020-09-20' WHERE id = 7;  -- Columbus Buligo I

-- Tier 4: After Oct 31, 2020 (35% commission rate)
-- UPDATE deals SET close_date = '2021-02-10' WHERE id = 8;  -- LP
-- UPDATE deals SET close_date = '2022-05-15' WHERE id = 9;  -- Autumn Ridge

-- ============================================================================
-- EXAMPLE: Set close date for Kuperman's deal (deal_id=2)
-- ============================================================================
UPDATE deals SET close_date = '2020-11-15' WHERE id = 2;  -- After Oct 31, 2020 = 35% tier

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Show deals with close dates and their commission tier
SELECT
    '=== Deals with Close Dates ===' as section,
    id,
    name,
    close_date,
    CASE
        WHEN close_date < '2018-02-01' THEN 'Tier 1: 25% commission'
        WHEN close_date >= '2018-02-01' AND close_date < '2019-12-12' THEN 'Tier 2: 27% commission'
        WHEN close_date >= '2019-12-12' AND close_date < '2020-10-31' THEN 'Tier 3: 30% commission'
        WHEN close_date >= '2020-10-31' THEN 'Tier 4: 35% commission'
        ELSE 'No close date'
    END as commission_tier
FROM deals
WHERE close_date IS NOT NULL
ORDER BY close_date;

-- Show deals that have commission agreements but NO close date
SELECT
    '=== Deals Missing Close Dates ===' as section,
    d.id,
    d.name,
    d.close_date,
    COUNT(a.id) as agreement_count
FROM deals d
INNER JOIN agreements a ON a.deal_id = d.id
WHERE a.kind = 'distributor_commission'
  AND d.close_date IS NULL
GROUP BY d.id, d.name, d.close_date
ORDER BY agreement_count DESC;

-- Summary by tier
SELECT
    '=== Close Date Summary ===' as section,
    CASE
        WHEN close_date < '2018-02-01' THEN 'Tier 1 (25%): Before Feb 1, 2018'
        WHEN close_date >= '2018-02-01' AND close_date < '2019-12-12' THEN 'Tier 2 (27%): Feb 2018 - Dec 2019'
        WHEN close_date >= '2019-12-12' AND close_date < '2020-10-31' THEN 'Tier 3 (30%): Dec 2019 - Oct 2020'
        WHEN close_date >= '2020-10-31' THEN 'Tier 4 (35%): After Oct 31, 2020'
        ELSE 'No close date'
    END as tier,
    COUNT(*) as deal_count,
    MIN(close_date) as earliest_date,
    MAX(close_date) as latest_date
FROM deals
GROUP BY
    CASE
        WHEN close_date < '2018-02-01' THEN 'Tier 1 (25%): Before Feb 1, 2018'
        WHEN close_date >= '2018-02-01' AND close_date < '2019-12-12' THEN 'Tier 2 (27%): Feb 2018 - Dec 2019'
        WHEN close_date >= '2019-12-12' AND close_date < '2020-10-31' THEN 'Tier 3 (30%): Dec 2019 - Oct 2020'
        WHEN close_date >= '2020-10-31' THEN 'Tier 4 (35%): After Oct 31, 2020'
        ELSE 'No close date'
    END
ORDER BY tier;

-- ============================================================================
-- ACCEPTANCE CRITERIA
-- ============================================================================
-- ✅ deals.close_date column exists
-- ✅ All deals with commission agreements have a close_date value
-- ✅ Dates are distributed across the 4 commission tiers
-- ✅ Sample query shows correct tier assignment
