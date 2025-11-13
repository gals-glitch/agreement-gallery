-- ============================================
-- T02: Charge Workflow Schema Migration
-- Version: v1.9.0
-- Date: 2025-10-21
-- Ticket: T02 - Complete Charge Workflow
-- ============================================
-- Adds columns to support charge approval, rejection, and payment tracking
-- All changes are additive (no breaking changes)

BEGIN;

-- ============================================
-- APPROVAL TRACKING
-- ============================================

-- Timestamp when charge was approved
ALTER TABLE charges ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ;

-- User ID who approved the charge (foreign key to auth.users)
ALTER TABLE charges ADD COLUMN IF NOT EXISTS approved_by UUID REFERENCES auth.users(id);

-- ============================================
-- REJECTION TRACKING
-- ============================================

-- Timestamp when charge was rejected
ALTER TABLE charges ADD COLUMN IF NOT EXISTS rejected_at TIMESTAMPTZ;

-- User ID who rejected the charge (foreign key to auth.users)
ALTER TABLE charges ADD COLUMN IF NOT EXISTS rejected_by UUID REFERENCES auth.users(id);

-- Reason for rejection (required at API layer, min 3 chars)
ALTER TABLE charges ADD COLUMN IF NOT EXISTS reject_reason TEXT;

-- ============================================
-- PAYMENT TRACKING
-- ============================================

-- Timestamp when charge was marked paid (can be set manually by user)
ALTER TABLE charges ADD COLUMN IF NOT EXISTS paid_at TIMESTAMPTZ;

-- Payment reference (e.g., WIRE-2025-001, ACH-12345)
ALTER TABLE charges ADD COLUMN IF NOT EXISTS payment_ref TEXT;

-- ============================================
-- PERFORMANCE INDEXES
-- ============================================

-- Fast status filtering (used in list views)
CREATE INDEX IF NOT EXISTS idx_charges_status ON charges(status);

-- Admin audit queries (find all charges approved/rejected by user)
CREATE INDEX IF NOT EXISTS idx_charges_approved_by ON charges(approved_by) WHERE approved_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_charges_rejected_by ON charges(rejected_by) WHERE rejected_by IS NOT NULL;

-- Payment reference lookup (search by wire transfer ID)
CREATE INDEX IF NOT EXISTS idx_charges_payment_ref ON charges(payment_ref) WHERE payment_ref IS NOT NULL;

-- ============================================
-- COLUMN DOCUMENTATION
-- ============================================

COMMENT ON COLUMN charges.approved_at IS 'Timestamp when charge transitioned to APPROVED status (T02)';
COMMENT ON COLUMN charges.approved_by IS 'User ID who approved the charge (admin only) (T02)';
COMMENT ON COLUMN charges.rejected_at IS 'Timestamp when charge was rejected (T02)';
COMMENT ON COLUMN charges.rejected_by IS 'User ID who rejected the charge (admin only) (T02)';
COMMENT ON COLUMN charges.reject_reason IS 'Reason for rejection (required, min 3 chars) (T02)';
COMMENT ON COLUMN charges.paid_at IS 'Timestamp when charge was marked paid (can be set manually) (T02)';
COMMENT ON COLUMN charges.payment_ref IS 'Payment reference (e.g., WIRE-2025-001, ACH-12345) (T02)';

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Verify columns exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'charges' AND column_name = 'approved_at'
  ) THEN
    RAISE EXCEPTION 'Migration failed: approved_at column not created';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'charges' AND column_name = 'rejected_at'
  ) THEN
    RAISE EXCEPTION 'Migration failed: rejected_at column not created';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'charges' AND column_name = 'paid_at'
  ) THEN
    RAISE EXCEPTION 'Migration failed: paid_at column not created';
  END IF;

  RAISE NOTICE 'T02 migration completed successfully';
END $$;

COMMIT;
