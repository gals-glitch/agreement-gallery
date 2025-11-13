-- Step 1: Check commission_tiers table structure
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'commission_tiers'
ORDER BY ordinal_position;

-- Step 2: See what tiers exist for agreement 1
SELECT *
FROM commission_tiers
WHERE agreement_id = 1
ORDER BY tier_number;

-- Step 3: Copy tiers from agreement 1 to agreement 6
-- (Run this after reviewing the results above)
/*
INSERT INTO commission_tiers (
  agreement_id,
  tier_number,
  from_amount,
  to_amount,
  rate_bps,
  rate_percent
)
SELECT
  6 as agreement_id,  -- New agreement ID
  tier_number,
  from_amount,
  to_amount,
  rate_bps,
  rate_percent
FROM commission_tiers
WHERE agreement_id = 1
ORDER BY tier_number;
*/

-- Step 4: Verify tiers were created for agreement 6
/*
SELECT *
FROM commission_tiers
WHERE agreement_id = 6
ORDER BY tier_number;
*/
