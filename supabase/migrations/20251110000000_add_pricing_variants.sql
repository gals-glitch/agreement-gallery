-- ============================================================================
-- Migration: Add Pricing Variants to Agreement Custom Terms
-- Date: 2025-11-10
-- Purpose: Enable Fixed Fee, BPS Split, and Mgmt Fee commission structures
--
-- Changes:
-- 1. Add pricing_variant column (BPS, BPS_SPLIT, FIXED, MGMT_FEE)
-- 2. Add fixed_amount_cents for fixed-fee agreements
-- 3. Add mgmt_fee_bps for management fee agreements
-- 4. Backfill existing agreements to pricing_variant='BPS'
--
-- Backward compatible: All existing agreements keep working with default 'BPS'
-- ============================================================================

BEGIN;

-- Step 1: Add pricing_variant column with safe default
ALTER TABLE agreement_custom_terms
  ADD COLUMN IF NOT EXISTS pricing_variant TEXT NOT NULL DEFAULT 'BPS';

-- Step 2: Add constraint for valid variants (drop first if exists)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'chk_pricing_variant_valid'
    AND conrelid = 'agreement_custom_terms'::regclass
  ) THEN
    ALTER TABLE agreement_custom_terms DROP CONSTRAINT chk_pricing_variant_valid;
  END IF;
END $$;

ALTER TABLE agreement_custom_terms
  ADD CONSTRAINT chk_pricing_variant_valid
  CHECK (pricing_variant IN ('BPS', 'BPS_SPLIT', 'FIXED', 'MGMT_FEE'));

-- Step 3: Add fixed_amount_cents column (nullable, only used for FIXED)
ALTER TABLE agreement_custom_terms
  ADD COLUMN IF NOT EXISTS fixed_amount_cents BIGINT;

-- Step 4: Add mgmt_fee_bps column (nullable, only used for MGMT_FEE)
ALTER TABLE agreement_custom_terms
  ADD COLUMN IF NOT EXISTS mgmt_fee_bps INTEGER;

-- Step 5: Add validation constraints for each variant type
DO $$
BEGIN
  -- Drop existing constraints if they exist
  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_bps_variant' AND conrelid = 'agreement_custom_terms'::regclass) THEN
    ALTER TABLE agreement_custom_terms DROP CONSTRAINT chk_bps_variant;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_fixed_variant' AND conrelid = 'agreement_custom_terms'::regclass) THEN
    ALTER TABLE agreement_custom_terms DROP CONSTRAINT chk_fixed_variant;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_mgmt_fee_variant' AND conrelid = 'agreement_custom_terms'::regclass) THEN
    ALTER TABLE agreement_custom_terms DROP CONSTRAINT chk_mgmt_fee_variant;
  END IF;
END $$;

ALTER TABLE agreement_custom_terms
  ADD CONSTRAINT chk_bps_variant
  CHECK (
    pricing_variant != 'BPS' OR (upfront_bps > 0 AND deferred_bps = 0)
  );

ALTER TABLE agreement_custom_terms
  ADD CONSTRAINT chk_fixed_variant
  CHECK (
    pricing_variant != 'FIXED' OR (fixed_amount_cents > 0)
  );

ALTER TABLE agreement_custom_terms
  ADD CONSTRAINT chk_mgmt_fee_variant
  CHECK (
    pricing_variant != 'MGMT_FEE' OR (mgmt_fee_bps > 0)
  );

-- Step 6: Backfill existing rows to 'BPS' (already done by DEFAULT, but explicit for safety)
UPDATE agreement_custom_terms
SET pricing_variant = 'BPS'
WHERE pricing_variant IS NULL;

-- Step 7: Add helpful comments
COMMENT ON COLUMN agreement_custom_terms.pricing_variant IS 'Commission structure type: BPS (upfront %), BPS_SPLIT (upfront + deferred %), FIXED (flat fee), MGMT_FEE (% of mgmt fees)';
COMMENT ON COLUMN agreement_custom_terms.fixed_amount_cents IS 'Fixed dollar amount in cents (e.g., 100000 = $1,000.00) - only used when pricing_variant=FIXED';
COMMENT ON COLUMN agreement_custom_terms.mgmt_fee_bps IS 'Management fee percentage in bps (e.g., 1000 = 10.00%) - only used when pricing_variant=MGMT_FEE';

-- Step 8: Create index for variant filtering (optional optimization)
CREATE INDEX IF NOT EXISTS idx_agreement_custom_terms_variant
  ON agreement_custom_terms(pricing_variant);

COMMIT;

-- ============================================================================
-- Verification Queries (run after migration)
-- ============================================================================

-- Verify all existing agreements are 'BPS'
-- SELECT pricing_variant, COUNT(*) FROM agreement_custom_terms GROUP BY pricing_variant;
-- Expected: All rows show 'BPS'

-- Verify constraints work
-- INSERT INTO agreement_custom_terms (agreement_id, upfront_bps, deferred_bps, pricing_variant, fixed_amount_cents)
-- VALUES (999, 100, 0, 'FIXED', 100000);
-- Expected: Success (fixed variant with fixed_amount_cents)

-- INSERT INTO agreement_custom_terms (agreement_id, upfront_bps, deferred_bps, pricing_variant)
-- VALUES (998, 100, 0, 'FIXED');
-- Expected: Failure (fixed variant without fixed_amount_cents)
