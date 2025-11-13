-- Migration: 02_contributions.sql
-- Purpose: Create contributions table (paid-in capital only)
-- Date: 2025-10-16

-- ============================================
-- CONTRIBUTIONS (paid-in capital driving fee calculations)
-- ============================================
CREATE TABLE IF NOT EXISTS contributions (
  id            BIGSERIAL PRIMARY KEY,
  investor_id   BIGINT NOT NULL REFERENCES investors(id) ON DELETE RESTRICT,
  deal_id       BIGINT REFERENCES deals(id) ON DELETE SET NULL,
  fund_id       BIGINT REFERENCES funds(id) ON DELETE SET NULL,
  paid_in_date  DATE NOT NULL,
  amount        NUMERIC NOT NULL CHECK (amount > 0),
  currency      TEXT DEFAULT 'USD',
  fx_rate       NUMERIC,  -- if provided for currency conversion
  source_batch  TEXT,     -- import batch tag for traceability
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE contributions IS 'Paid-in capital contributions (not commitments) - drives fee calculations';
COMMENT ON COLUMN contributions.investor_id IS 'Investor making the contribution';
COMMENT ON COLUMN contributions.deal_id IS 'Deal this contribution is for (mutually exclusive with fund_id)';
COMMENT ON COLUMN contributions.fund_id IS 'Fund this contribution is for (mutually exclusive with deal_id)';
COMMENT ON COLUMN contributions.paid_in_date IS 'Date capital was paid in';
COMMENT ON COLUMN contributions.source_batch IS 'Import batch identifier for tracking source';

-- ============================================
-- CONSTRAINT: Exactly one of deal_id or fund_id must be set (XOR)
-- ============================================
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname='contributions_one_scope_ck'
  ) THEN
    ALTER TABLE contributions ADD CONSTRAINT contributions_one_scope_ck
      CHECK (
        (deal_id IS NOT NULL AND fund_id IS NULL)
        OR
        (deal_id IS NULL AND fund_id IS NOT NULL)
      );
  END IF;
END $$;

COMMENT ON CONSTRAINT contributions_one_scope_ck ON contributions IS 'Contribution must belong to exactly one of: deal_id OR fund_id (XOR enforcement)';

-- ============================================
-- ADDITIONAL CHECK CONSTRAINTS (Safety Layer)
-- ============================================
DO $$ BEGIN
  -- Ensure amount is positive (redundant with column CHECK but explicit)
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname='contributions_amount_pos_ck'
  ) THEN
    ALTER TABLE contributions ADD CONSTRAINT contributions_amount_pos_ck CHECK (amount > 0);
  END IF;

  -- Ensure paid_in_date is not null (redundant with NOT NULL but explicit)
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname='contributions_paid_in_date_ck'
  ) THEN
    ALTER TABLE contributions ADD CONSTRAINT contributions_paid_in_date_ck CHECK (paid_in_date IS NOT NULL);
  END IF;
END $$;

COMMENT ON CONSTRAINT contributions_amount_pos_ck ON contributions IS 'Amount must be positive';
COMMENT ON CONSTRAINT contributions_paid_in_date_ck ON contributions IS 'Paid-in date is required';

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_contrib_investor ON contributions(investor_id);
CREATE INDEX IF NOT EXISTS idx_contrib_paidin ON contributions(paid_in_date);
CREATE INDEX IF NOT EXISTS idx_contrib_deal ON contributions(deal_id) WHERE deal_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_contrib_fund ON contributions(fund_id) WHERE fund_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_contrib_batch ON contributions(source_batch) WHERE source_batch IS NOT NULL;
