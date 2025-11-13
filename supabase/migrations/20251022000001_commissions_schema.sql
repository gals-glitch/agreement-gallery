-- ============================================
-- Migration: Commissions System for Distributor/Referrer Payments
-- Purpose: Add parallel commissions stack for paying distributors/referrers
-- Date: 2025-10-22
-- Version: 1.9.0
-- ============================================
--
-- OVERVIEW:
-- This migration creates a commission tracking system for distributors/referrers.
-- It runs PARALLEL to the existing investor-fee charges system.
--
-- KEY CONCEPTS:
-- - Commissions = amounts owed TO distributors/referrers (NOT charged to investors)
-- - Triggered by investor contributions (already uploaded from external source)
-- - Commission rate based on party's approved agreement terms
-- - Workflow: draft → pending → approved → paid
--
-- DESIGN DECISIONS:
-- - Keeps existing charges system intact (for investor fees if needed later)
-- - Reuses agreement snapshots pattern for commission terms
-- - XOR constraint: deal_id OR fund_id (not both)
-- - Unique constraint on (contribution_id, party_id) for idempotency
-- - RLS mirrors charges policies (Finance read/submit, Admin approve/paid)
--
-- ============================================

-- ============================================
-- STEP 1: Create commission_status enum
-- ============================================

DO $$ BEGIN
  CREATE TYPE commission_status AS ENUM ('draft','pending','approved','paid','rejected');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

COMMENT ON TYPE commission_status IS 'Commission lifecycle states: draft → pending → approved → paid (or rejected)';

-- ============================================
-- STEP 2: Create commissions table
-- ============================================

CREATE TABLE IF NOT EXISTS commissions (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Core relationships
  party_id         BIGINT NOT NULL REFERENCES parties(id) ON DELETE RESTRICT,
  investor_id      BIGINT NOT NULL REFERENCES investors(id) ON DELETE RESTRICT,
  contribution_id  BIGINT NOT NULL REFERENCES contributions(id) ON DELETE RESTRICT,

  -- Scope (XOR: deal OR fund)
  deal_id          BIGINT REFERENCES deals(id) ON DELETE RESTRICT,
  fund_id          BIGINT REFERENCES funds(id) ON DELETE RESTRICT,

  -- Status and workflow
  status           commission_status NOT NULL DEFAULT 'draft',

  -- Financial amounts
  base_amount      NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK (base_amount >= 0),
  vat_amount       NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK (vat_amount >= 0),
  total_amount     NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK (total_amount >= 0),
  currency         TEXT NOT NULL DEFAULT 'USD',

  -- Immutable snapshot of commission terms at computation time
  snapshot_json    JSONB NOT NULL DEFAULT '{}'::jsonb,

  -- Workflow timestamps
  computed_at      TIMESTAMPTZ,
  submitted_at     TIMESTAMPTZ,
  approved_at      TIMESTAMPTZ,
  approved_by      UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  rejected_at      TIMESTAMPTZ,
  rejected_by      UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  reject_reason    TEXT,
  paid_at          TIMESTAMPTZ,
  payment_ref      TEXT,

  -- Audit timestamps
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- ============================================
  -- CONSTRAINTS
  -- ============================================

  -- XOR: exactly one of deal_id or fund_id must be set
  CONSTRAINT commissions_scope_xor_ck CHECK (
    (deal_id IS NOT NULL AND fund_id IS NULL) OR
    (fund_id IS NOT NULL AND deal_id IS NULL)
  ),

  -- Idempotency: one commission per contribution per party
  CONSTRAINT commissions_unique_contribution_party UNIQUE (contribution_id, party_id)
);

COMMENT ON TABLE commissions IS 'Commission payments owed TO distributors/referrers for bringing investors';
COMMENT ON COLUMN commissions.id IS 'Unique commission ID (UUID)';
COMMENT ON COLUMN commissions.party_id IS 'Distributor/referrer earning this commission';
COMMENT ON COLUMN commissions.investor_id IS 'Investor who made the contribution';
COMMENT ON COLUMN commissions.contribution_id IS 'The contribution that triggered this commission';
COMMENT ON COLUMN commissions.deal_id IS 'Deal scope (if commission is deal-specific)';
COMMENT ON COLUMN commissions.fund_id IS 'Fund scope (if commission is fund-wide)';
COMMENT ON COLUMN commissions.status IS 'Workflow state: draft → pending → approved → paid (or rejected)';
COMMENT ON COLUMN commissions.base_amount IS 'Base commission amount (before VAT)';
COMMENT ON COLUMN commissions.vat_amount IS 'VAT amount (if applicable)';
COMMENT ON COLUMN commissions.total_amount IS 'Total commission owed (base + VAT)';
COMMENT ON COLUMN commissions.snapshot_json IS 'Immutable snapshot of commission terms (rate_bps, vat_mode, vat_rate, etc.) at computation time';
COMMENT ON COLUMN commissions.computed_at IS 'When the commission was first computed';
COMMENT ON COLUMN commissions.submitted_at IS 'When commission was submitted for approval';
COMMENT ON COLUMN commissions.approved_at IS 'When commission was approved for payment';
COMMENT ON COLUMN commissions.approved_by IS 'Admin user who approved this commission';
COMMENT ON COLUMN commissions.rejected_at IS 'When commission was rejected';
COMMENT ON COLUMN commissions.rejected_by IS 'Admin user who rejected this commission';
COMMENT ON COLUMN commissions.reject_reason IS 'Reason for rejection';
COMMENT ON COLUMN commissions.paid_at IS 'When commission was marked as paid';
COMMENT ON COLUMN commissions.payment_ref IS 'Payment reference (wire transfer ID, etc.)';

-- ============================================
-- STEP 3: Create indexes for performance
-- ============================================

CREATE INDEX IF NOT EXISTS idx_commissions_status
  ON commissions(status);

CREATE INDEX IF NOT EXISTS idx_commissions_party_status
  ON commissions(party_id, status);

CREATE INDEX IF NOT EXISTS idx_commissions_investor
  ON commissions(investor_id);

CREATE INDEX IF NOT EXISTS idx_commissions_contribution
  ON commissions(contribution_id);

CREATE INDEX IF NOT EXISTS idx_commissions_deal
  ON commissions(deal_id)
  WHERE deal_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_commissions_fund
  ON commissions(fund_id)
  WHERE fund_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_commissions_dates
  ON commissions(computed_at, submitted_at, approved_at, paid_at);

-- ============================================
-- STEP 4: Extend agreements table for commission terms
-- ============================================

-- Add agreement_kind enum to distinguish investor fees vs distributor commissions
DO $$ BEGIN
  CREATE TYPE agreement_kind AS ENUM ('investor_fee', 'distributor_commission');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

COMMENT ON TYPE agreement_kind IS 'Agreement type: investor_fee (charges TO investors) vs distributor_commission (payments TO distributors)';

-- Add columns to agreements table
ALTER TABLE agreements
  ADD COLUMN IF NOT EXISTS kind agreement_kind DEFAULT 'investor_fee',
  ADD COLUMN IF NOT EXISTS commission_party_id BIGINT NULL REFERENCES parties(id) ON DELETE RESTRICT;

COMMENT ON COLUMN agreements.kind IS 'Agreement type: investor_fee or distributor_commission';
COMMENT ON COLUMN agreements.commission_party_id IS 'For distributor_commission agreements: the party earning commissions (NULL for investor_fee agreements)';

-- Create index for commission agreement lookups
CREATE INDEX IF NOT EXISTS idx_agreements_commission_party
  ON agreements(commission_party_id, kind, status)
  WHERE kind = 'distributor_commission';

-- ============================================
-- STEP 5: RLS Policies for commissions table
-- ============================================

-- Enable RLS
ALTER TABLE commissions ENABLE ROW LEVEL SECURITY;

-- Finance/Ops/Manager/Admin can read all commissions
CREATE POLICY "Finance+ can read all commissions"
  ON commissions
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.user_id = auth.uid()
      AND user_roles.role_key IN ('admin', 'finance', 'ops', 'manager')
    )
  );

-- Finance and Admin can create commissions (for manual entries or compute)
CREATE POLICY "Finance/Admin can create commissions"
  ON commissions
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.user_id = auth.uid()
      AND user_roles.role_key IN ('admin', 'finance')
    )
  );

-- Only Admin can update commissions (approve, reject, mark paid)
CREATE POLICY "Admin can update commissions"
  ON commissions
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.user_id = auth.uid()
      AND user_roles.role_key = 'admin'
    )
  );

-- Only Admin can delete commissions
CREATE POLICY "Admin can delete commissions"
  ON commissions
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.user_id = auth.uid()
      AND user_roles.role_key = 'admin'
    )
  );

-- ============================================
-- STEP 6: Create updated_at trigger
-- ============================================

CREATE OR REPLACE FUNCTION update_commissions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER commissions_updated_at
  BEFORE UPDATE ON commissions
  FOR EACH ROW
  EXECUTE FUNCTION update_commissions_updated_at();

-- ============================================
-- STEP 7: Create helper view for reporting
-- ============================================

CREATE OR REPLACE VIEW commissions_summary AS
SELECT
  p.id as party_id,
  p.name as party_name,
  c.status,
  c.currency,
  COUNT(*) as commission_count,
  SUM(c.base_amount) as total_base,
  SUM(c.vat_amount) as total_vat,
  SUM(c.total_amount) as total_amount,
  MIN(c.computed_at) as earliest_computed,
  MAX(c.paid_at) as latest_paid
FROM commissions c
JOIN parties p ON p.id = c.party_id
GROUP BY p.id, p.name, c.status, c.currency;

COMMENT ON VIEW commissions_summary IS 'Summary of commissions grouped by party and status for reporting';

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Verify table created
-- SELECT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'commissions');

-- Verify indexes created
-- SELECT indexname FROM pg_indexes WHERE tablename = 'commissions';

-- Verify RLS enabled
-- SELECT relname, relrowsecurity FROM pg_class WHERE relname = 'commissions';

-- Verify policies created
-- SELECT policyname FROM pg_policies WHERE tablename = 'commissions';

-- ============================================
-- ROLLBACK INSTRUCTIONS
-- ============================================

-- To rollback this migration:
-- DROP VIEW IF EXISTS commissions_summary;
-- DROP TRIGGER IF EXISTS commissions_updated_at ON commissions;
-- DROP FUNCTION IF EXISTS update_commissions_updated_at();
-- DROP POLICY IF EXISTS "Finance+ can read all commissions" ON commissions;
-- DROP POLICY IF EXISTS "Finance/Admin can create commissions" ON commissions;
-- DROP POLICY IF EXISTS "Admin can update commissions" ON commissions;
-- DROP POLICY IF EXISTS "Admin can delete commissions" ON commissions;
-- DROP INDEX IF EXISTS idx_commissions_status;
-- DROP INDEX IF EXISTS idx_commissions_party_status;
-- DROP INDEX IF EXISTS idx_commissions_investor;
-- DROP INDEX IF EXISTS idx_commissions_contribution;
-- DROP INDEX IF EXISTS idx_commissions_deal;
-- DROP INDEX IF EXISTS idx_commissions_fund;
-- DROP INDEX IF EXISTS idx_commissions_dates;
-- DROP INDEX IF EXISTS idx_agreements_commission_party;
-- ALTER TABLE agreements DROP COLUMN IF EXISTS kind;
-- ALTER TABLE agreements DROP COLUMN IF EXISTS commission_party_id;
-- DROP TABLE IF EXISTS commissions CASCADE;
-- DROP TYPE IF EXISTS commission_status;
-- DROP TYPE IF EXISTS agreement_kind;
