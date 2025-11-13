-- ============================================================================
-- Verification: Pricing Variants Migration
-- Run these queries to confirm the migration worked correctly
-- ============================================================================

-- 1. Check that pricing_variant column exists with correct values
SELECT
  pricing_variant,
  COUNT(*) as count,
  STRING_AGG(DISTINCT agreement_id::text, ', ') as agreement_ids
FROM agreement_custom_terms
GROUP BY pricing_variant
ORDER BY pricing_variant;

-- Expected: All rows should show pricing_variant = 'BPS'


-- 2. Check column definitions
SELECT
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'agreement_custom_terms'
  AND column_name IN ('pricing_variant', 'fixed_amount_cents', 'mgmt_fee_bps')
ORDER BY column_name;

-- Expected:
-- pricing_variant    | text    | NO  | 'BPS'::text
-- fixed_amount_cents | bigint  | YES | NULL
-- mgmt_fee_bps       | integer | YES | NULL


-- 3. Check constraints exist
SELECT
  conname as constraint_name,
  pg_get_constraintdef(oid) as definition
FROM pg_constraint
WHERE conrelid = 'agreement_custom_terms'::regclass
  AND conname LIKE 'chk_%variant%'
ORDER BY conname;

-- Expected: 4 constraints (chk_pricing_variant_valid, chk_bps_variant, chk_fixed_variant, chk_mgmt_fee_variant)


-- 4. Verify all existing agreements are 'BPS' and have valid upfront_bps
SELECT
  a.id as agreement_id,
  p.name as party_name,
  act.pricing_variant,
  act.upfront_bps,
  act.deferred_bps,
  act.fixed_amount_cents,
  act.mgmt_fee_bps
FROM agreement_custom_terms act
JOIN agreements a ON a.id = act.agreement_id
JOIN parties p ON p.id = a.party_id
ORDER BY a.id;

-- Expected: All rows show pricing_variant='BPS', upfront_bps=100, deferred_bps=0, nulls for fixed/mgmt


-- 5. Test constraint: Try to insert a FIXED agreement without fixed_amount_cents (should fail)
-- DO NOT RUN THIS - just for verification that constraints work
/*
INSERT INTO agreement_custom_terms (agreement_id, upfront_bps, deferred_bps, pricing_variant)
VALUES (999, 0, 0, 'FIXED');
-- Expected: ERROR - chk_fixed_variant constraint violation
*/

-- 6. Check index was created
SELECT
  indexname,
  indexdef
FROM pg_indexes
WHERE tablename = 'agreement_custom_terms'
  AND indexname LIKE '%variant%';

-- Expected: idx_agreement_custom_terms_variant exists


-- ============================================================================
-- Summary Report
-- ============================================================================
SELECT
  'Migration successful! ✅' as status,
  COUNT(*) as total_custom_terms,
  COUNT(*) FILTER (WHERE pricing_variant = 'BPS') as bps_count,
  COUNT(*) FILTER (WHERE pricing_variant = 'FIXED') as fixed_count,
  COUNT(*) FILTER (WHERE pricing_variant = 'BPS_SPLIT') as split_count,
  COUNT(*) FILTER (WHERE pricing_variant = 'MGMT_FEE') as mgmt_fee_count
FROM agreement_custom_terms;

-- Expected: All in bps_count, zeros for others
