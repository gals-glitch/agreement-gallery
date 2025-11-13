-- ============================================
-- P2-6 FIXED: Add Credits Columns & FK to Charges (Simplified)
-- Date: 2025-10-19
-- Version: 1.1.0 (FIXED)
-- ============================================
--
-- CHANGES FROM ORIGINAL:
-- 1. Removed numeric_id creation (already in 20251019130000_charges_FIXED.sql)
-- 2. Simplified to just add FK constraint and credits columns
-- 3. Assumes credit_applications.charge_id is already BIGINT (from P1)
--
-- OVERVIEW:
-- This migration completes the credits engine integration:
-- 1. Adds FK from credit_applications.charge_id → charges.numeric_id
-- 2. Adds credits_applied_amount column
-- 3. Adds net_amount column
--
-- ============================================

-- ============================================
-- STEP 1: Add FK constraint (credit_applications → charges)
-- ============================================

-- credit_applications.charge_id (BIGINT) → charges.numeric_id (BIGINT)
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'credit_applications_charge_numeric_id_fkey'
  ) THEN
    ALTER TABLE credit_applications
      ADD CONSTRAINT credit_applications_charge_numeric_id_fkey
      FOREIGN KEY (charge_id)
      REFERENCES charges(numeric_id)
      ON DELETE CASCADE;
  END IF;
END $$;

COMMENT ON CONSTRAINT credit_applications_charge_numeric_id_fkey ON credit_applications IS 'FK to charges.numeric_id (not charges.id UUID) for creditsEngine compatibility';

-- Add index for FK performance
CREATE INDEX IF NOT EXISTS idx_credit_applications_charge_id
  ON credit_applications (charge_id)
  WHERE charge_id IS NOT NULL;

COMMENT ON INDEX idx_credit_applications_charge_id IS 'Index for credit_applications.charge_id FK lookups';

-- ============================================
-- STEP 2: Add credits_applied_amount column
-- ============================================

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'charges'
    AND column_name = 'credits_applied_amount'
  ) THEN
    ALTER TABLE charges
      ADD COLUMN credits_applied_amount NUMERIC(18,2) DEFAULT 0 NOT NULL;
  END IF;
END $$;

COMMENT ON COLUMN charges.credits_applied_amount IS 'Total credits applied (FIFO). Updated by creditsEngine.ts';

-- ============================================
-- STEP 3: Add net_amount column
-- ============================================

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'charges'
    AND column_name = 'net_amount'
  ) THEN
    ALTER TABLE charges
      ADD COLUMN net_amount NUMERIC(18,2);
  END IF;
END $$;

COMMENT ON COLUMN charges.net_amount IS 'Amount due after credits (total_amount - credits_applied_amount)';

-- ============================================
-- STEP 4: Backfill net_amount
-- ============================================

-- Set net_amount = total_amount for existing charges (no credits applied yet)
UPDATE charges
SET net_amount = total_amount - COALESCE(credits_applied_amount, 0)
WHERE net_amount IS NULL;

-- ============================================
-- STEP 5: Make net_amount NOT NULL
-- ============================================

DO $$ BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'charges'
    AND column_name = 'net_amount'
    AND is_nullable = 'YES'
  ) THEN
    ALTER TABLE charges
      ALTER COLUMN net_amount SET DEFAULT 0,
      ALTER COLUMN net_amount SET NOT NULL;
  END IF;
END $$;

-- ============================================
-- STEP 6: Add index for net_amount queries
-- ============================================

-- Partial index for charges with remaining balance
CREATE INDEX IF NOT EXISTS idx_charges_net_amount
  ON charges (net_amount)
  WHERE net_amount > 0;

COMMENT ON INDEX idx_charges_net_amount IS 'Partial index for charges with balance (net_amount > 0)';

-- ============================================
-- END OF MIGRATION
-- ============================================

-- NOTES:
-- 1. This migration assumes charges.numeric_id already exists (from FIXED migration 1)
-- 2. This migration assumes credit_applications.charge_id is BIGINT (from P1)
-- 3. Safe to run multiple times (all IF NOT EXISTS checks)
-- 4. Rollback: ALTER TABLE charges DROP COLUMN credits_applied_amount, net_amount;
