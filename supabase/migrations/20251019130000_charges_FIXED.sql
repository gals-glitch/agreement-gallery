-- ============================================
-- P2-1 FIXED: Charges Table Schema (Corrected for creditsEngine compatibility)
-- Date: 2025-10-19
-- Version: 1.1.0 (FIXED)
-- ============================================
--
-- CHANGES FROM ORIGINAL:
-- 1. Added numeric_id (BIGSERIAL) column immediately (for creditsEngine compatibility)
-- 2. Removed ALTER TABLE credit_applications (handled in next migration)
-- 3. Simplified to avoid BIGINT → UUID casting issues
--
-- DESIGN:
-- - charges.id = UUID (for API consistency)
-- - charges.numeric_id = BIGSERIAL (for creditsEngine.ts which expects numeric IDs)
-- - credit_applications.charge_id will reference charges.numeric_id (next migration)
--
-- ============================================

-- ============================================
-- STEP 1: Create charge_status enum
-- ============================================

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'charge_status') THEN
    CREATE TYPE charge_status AS ENUM (
      'DRAFT',
      'PENDING',
      'APPROVED',
      'PAID',
      'REJECTED'
    );
  END IF;
END $$;

COMMENT ON TYPE charge_status IS 'Charge workflow states: DRAFT → PENDING → APPROVED → PAID (or REJECTED)';

-- ============================================
-- STEP 2: Create charges table (with dual IDs)
-- ============================================

CREATE TABLE IF NOT EXISTS charges (
  -- Dual ID strategy: UUID for API, numeric for creditsEngine
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  numeric_id       BIGSERIAL UNIQUE NOT NULL,  -- For creditsEngine compatibility

  -- Foreign keys
  investor_id      BIGINT NOT NULL REFERENCES investors(id) ON DELETE RESTRICT,
  deal_id          BIGINT REFERENCES deals(id) ON DELETE RESTRICT,
  fund_id          BIGINT REFERENCES funds(id) ON DELETE RESTRICT,
  contribution_id  BIGINT REFERENCES contributions(id) ON DELETE RESTRICT,

  -- Workflow
  status           charge_status NOT NULL DEFAULT 'DRAFT',

  -- Amounts (all NUMERIC(18,2) for precision)
  base_amount      NUMERIC(18,2) NOT NULL DEFAULT 0,
  discount_amount  NUMERIC(18,2) NOT NULL DEFAULT 0,
  vat_amount       NUMERIC(18,2) NOT NULL DEFAULT 0,
  total_amount     NUMERIC(18,2) NOT NULL DEFAULT 0,
  currency         TEXT NOT NULL DEFAULT 'USD',

  -- Immutable snapshot
  snapshot_json    JSONB NOT NULL,

  -- Timestamps
  computed_at      TIMESTAMPTZ,
  submitted_at     TIMESTAMPTZ,
  approved_by      UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  approved_at      TIMESTAMPTZ,
  rejected_by      UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  rejected_at      TIMESTAMPTZ,
  reject_reason    TEXT,
  paid_at          TIMESTAMPTZ,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- XOR constraint: EXACTLY one of deal_id or fund_id
  CONSTRAINT charges_one_scope_ck CHECK (
    (deal_id IS NOT NULL AND fund_id IS NULL)::int +
    (deal_id IS NULL AND fund_id IS NOT NULL)::int = 1
  )
);

COMMENT ON TABLE charges IS 'Calculated referral fees on paid-in contributions';
COMMENT ON COLUMN charges.id IS 'UUID primary key (for API responses)';
COMMENT ON COLUMN charges.numeric_id IS 'Numeric ID (for creditsEngine.ts FK from credit_applications)';
COMMENT ON COLUMN charges.investor_id IS 'Investor being charged';
COMMENT ON COLUMN charges.deal_id IS 'Deal-level charge (XOR with fund_id)';
COMMENT ON COLUMN charges.fund_id IS 'Fund-level charge (XOR with deal_id)';
COMMENT ON COLUMN charges.contribution_id IS 'Contribution this charge is based on';
COMMENT ON COLUMN charges.status IS 'Workflow state (DRAFT → PENDING → APPROVED → PAID or REJECTED)';
COMMENT ON COLUMN charges.base_amount IS 'Base fee (before discounts and VAT)';
COMMENT ON COLUMN charges.discount_amount IS 'Discounts applied';
COMMENT ON COLUMN charges.vat_amount IS 'VAT amount';
COMMENT ON COLUMN charges.total_amount IS 'Total amount (base - discount + VAT)';
COMMENT ON COLUMN charges.snapshot_json IS 'Immutable agreement + VAT snapshot';

-- ============================================
-- STEP 3: Create indexes
-- ============================================

-- Status filtering (for UI tabs)
CREATE INDEX IF NOT EXISTS idx_charges_status
  ON charges (status);

-- Investor + status (most common query pattern)
CREATE INDEX IF NOT EXISTS idx_charges_investor_status
  ON charges (investor_id, status);

-- Deal-level charges (partial index - only non-NULL)
CREATE INDEX IF NOT EXISTS idx_charges_deal
  ON charges (deal_id)
  WHERE deal_id IS NOT NULL;

-- Fund-level charges (partial index - only non-NULL)
CREATE INDEX IF NOT EXISTS idx_charges_fund
  ON charges (fund_id)
  WHERE fund_id IS NOT NULL;

-- Contribution linkage (for idempotency checks)
CREATE INDEX IF NOT EXISTS idx_charges_contribution
  ON charges (contribution_id);

-- Workflow timestamps (partial indexes for audit queries)
CREATE INDEX IF NOT EXISTS idx_charges_approved_at
  ON charges (approved_at)
  WHERE approved_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_charges_paid_at
  ON charges (paid_at)
  WHERE paid_at IS NOT NULL;

-- numeric_id index (for creditsEngine lookups)
CREATE INDEX IF NOT EXISTS idx_charges_numeric_id
  ON charges (numeric_id);

COMMENT ON INDEX idx_charges_status IS 'Filter by status (DRAFT/PENDING/APPROVED/PAID/REJECTED)';
COMMENT ON INDEX idx_charges_investor_status IS 'Investor + status composite (common UI query)';
COMMENT ON INDEX idx_charges_deal IS 'Deal-level charges (partial)';
COMMENT ON INDEX idx_charges_fund IS 'Fund-level charges (partial)';
COMMENT ON INDEX idx_charges_contribution IS 'Contribution linkage (idempotency)';
COMMENT ON INDEX idx_charges_approved_at IS 'Approved charges (audit)';
COMMENT ON INDEX idx_charges_paid_at IS 'Paid charges (audit)';
COMMENT ON INDEX idx_charges_numeric_id IS 'Numeric ID lookups (for creditsEngine FK)';

-- ============================================
-- STEP 4: Create triggers
-- ============================================

CREATE OR REPLACE FUNCTION update_charges_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_charges_updated_at IS 'Auto-update updated_at timestamp on UPDATE';

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger
    WHERE tgname = 'charges_updated_at_trigger'
  ) THEN
    CREATE TRIGGER charges_updated_at_trigger
      BEFORE UPDATE ON charges
      FOR EACH ROW
      EXECUTE FUNCTION update_charges_updated_at();
  END IF;
END $$;

COMMENT ON TRIGGER charges_updated_at_trigger ON charges IS 'Auto-update updated_at on UPDATE';

-- ============================================
-- STEP 5: Enable RLS
-- ============================================

ALTER TABLE charges ENABLE ROW LEVEL SECURITY;

-- ============================================
-- STEP 6: Create RLS policies
-- ============================================

-- Finance+ can read all charges
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'charges'
    AND policyname = 'Finance+ can read all charges'
  ) THEN
    CREATE POLICY "Finance+ can read all charges"
      ON charges
      FOR SELECT
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM user_roles
          WHERE user_roles.user_id = auth.uid()
          AND user_roles.role_key IN ('admin', 'finance', 'ops', 'manager')
        )
      );
  END IF;
END $$;

-- Admin can manage all charges
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'charges'
    AND policyname = 'Admin can manage all charges'
  ) THEN
    CREATE POLICY "Admin can manage all charges"
      ON charges
      FOR ALL
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM user_roles
          WHERE user_roles.user_id = auth.uid()
          AND user_roles.role_key = 'admin'
        )
      );
  END IF;
END $$;

COMMENT ON POLICY "Finance+ can read all charges" ON charges IS 'Finance, Ops, Manager, Admin can read charges';
COMMENT ON POLICY "Admin can manage all charges" ON charges IS 'Admin can INSERT/UPDATE/DELETE charges';

-- ============================================
-- END OF MIGRATION
-- ============================================

-- NOTES:
-- 1. credit_applications FK update is in next migration (20251019140000_charges_credits_columns.sql)
-- 2. This migration is safe to run multiple times (all IF NOT EXISTS checks)
-- 3. Rollback: DROP TABLE charges CASCADE; DROP TYPE charge_status CASCADE;
