/**
 * Transactions & Credits Ledger - Database Schema
 * Ticket: PG-401
 * Date: 2025-10-19
 *
 * Purpose: Enable tracking of investor transactions (contributions/repurchases)
 *          and credits ledger for future charge application logic
 *
 * Design:
 * - transactions: Record all investor capital movements
 * - credits_ledger: Track available credits from repurchases (stub for Phase 3)
 * - credit_applications: Link credits to charges (stub for Phase 3)
 *
 * Note: This is STUB WORK. Calculation logic for charge creation and credit
 *       application will be implemented in Phase 3.
 */

-- ============================================
-- ENUMS: Transaction and Credit Types
-- ============================================
CREATE TYPE transaction_type AS ENUM ('CONTRIBUTION', 'REPURCHASE');
CREATE TYPE transaction_source AS ENUM ('MANUAL', 'CSV_IMPORT', 'VANTAGE');
CREATE TYPE credit_type AS ENUM ('EARLY_BIRD', 'PROMOTIONAL');
CREATE TYPE credit_status AS ENUM ('AVAILABLE', 'APPLIED', 'EXPIRED');

-- ============================================
-- TABLE: transactions
-- ============================================
CREATE TABLE IF NOT EXISTS transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Investor reference
  investor_id INTEGER NOT NULL REFERENCES parties(id) ON DELETE RESTRICT,

  -- Transaction details
  type transaction_type NOT NULL,
  amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
  currency TEXT NOT NULL DEFAULT 'USD',
  transaction_date DATE NOT NULL,

  -- Scope: exactly one of fund_id OR deal_id (enforced via check constraint)
  fund_id INTEGER REFERENCES funds(id) ON DELETE RESTRICT,
  deal_id INTEGER REFERENCES deals(id) ON DELETE RESTRICT,

  -- Metadata
  notes TEXT,
  source transaction_source DEFAULT 'MANUAL' NOT NULL,
  batch_id TEXT, -- For CSV import tracking

  -- Audit
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,

  -- Constraints
  CONSTRAINT transactions_one_scope_ck CHECK (
    (fund_id IS NOT NULL AND deal_id IS NULL) OR
    (fund_id IS NULL AND deal_id IS NOT NULL)
  ),
  CONSTRAINT transactions_date_valid_ck CHECK (transaction_date <= CURRENT_DATE)
);

-- ============================================
-- TABLE: credits_ledger
-- ============================================
CREATE TABLE IF NOT EXISTS credits_ledger (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Investor reference
  investor_id INTEGER NOT NULL REFERENCES parties(id) ON DELETE RESTRICT,

  -- Credit details
  credit_type credit_type NOT NULL,
  amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
  currency TEXT NOT NULL DEFAULT 'USD',
  status credit_status DEFAULT 'AVAILABLE' NOT NULL,

  -- Lifecycle tracking (STUB - future use)
  original_amount DECIMAL(15, 2) NOT NULL CHECK (original_amount > 0),
  remaining_amount DECIMAL(15, 2) NOT NULL CHECK (remaining_amount >= 0),

  -- Link to source transaction (if created from repurchase)
  transaction_id UUID REFERENCES transactions(id) ON DELETE SET NULL,

  -- Audit
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,

  -- Constraint: remaining_amount cannot exceed original_amount
  CONSTRAINT credits_remaining_lte_original_ck CHECK (remaining_amount <= original_amount)
);

-- ============================================
-- TABLE: credit_applications (STUB for Phase 3)
-- ============================================
CREATE TABLE IF NOT EXISTS credit_applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Link to credit and charge (charge_id will reference future charges table)
  credit_id UUID NOT NULL REFERENCES credits_ledger(id) ON DELETE RESTRICT,
  charge_id UUID, -- Foreign key constraint will be added when charges table exists

  -- Application details
  amount_applied DECIMAL(15, 2) NOT NULL CHECK (amount_applied > 0),
  applied_at TIMESTAMPTZ DEFAULT now() NOT NULL,

  -- Reversal support (for future use)
  reversed_at TIMESTAMPTZ,
  reversal_reason TEXT,

  -- Audit
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL
);

-- ============================================
-- INDEXES: Performance Optimization
-- ============================================
-- Transactions
CREATE INDEX idx_transactions_investor_id ON transactions(investor_id);
CREATE INDEX idx_transactions_type ON transactions(type);
CREATE INDEX idx_transactions_transaction_date ON transactions(transaction_date);
CREATE INDEX idx_transactions_fund_id ON transactions(fund_id) WHERE fund_id IS NOT NULL;
CREATE INDEX idx_transactions_deal_id ON transactions(deal_id) WHERE deal_id IS NOT NULL;
CREATE INDEX idx_transactions_batch_id ON transactions(batch_id) WHERE batch_id IS NOT NULL;
CREATE INDEX idx_transactions_created_at ON transactions(created_at DESC);

-- Credits Ledger
CREATE INDEX idx_credits_investor_id ON credits_ledger(investor_id);
CREATE INDEX idx_credits_status ON credits_ledger(status);
CREATE INDEX idx_credits_credit_type ON credits_ledger(credit_type);
CREATE INDEX idx_credits_transaction_id ON credits_ledger(transaction_id) WHERE transaction_id IS NOT NULL;
CREATE INDEX idx_credits_created_at ON credits_ledger(created_at DESC);

-- Credit Applications
CREATE INDEX idx_credit_applications_credit_id ON credit_applications(credit_id);
CREATE INDEX idx_credit_applications_charge_id ON credit_applications(charge_id) WHERE charge_id IS NOT NULL;
CREATE INDEX idx_credit_applications_applied_at ON credit_applications(applied_at DESC);

-- ============================================
-- RLS POLICIES
-- ============================================

-- Transactions
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "transactions_select_all"
  ON transactions
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "transactions_insert_finance"
  ON transactions
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid()
      AND role IN ('admin', 'finance')
    )
  );

CREATE POLICY "transactions_update_finance"
  ON transactions
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid()
      AND role IN ('admin', 'finance')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid()
      AND role IN ('admin', 'finance')
    )
  );

CREATE POLICY "transactions_delete_admin"
  ON transactions
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid()
      AND role = 'admin'
    )
  );

-- Credits Ledger
ALTER TABLE credits_ledger ENABLE ROW LEVEL SECURITY;

CREATE POLICY "credits_select_all"
  ON credits_ledger
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "credits_insert_finance"
  ON credits_ledger
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid()
      AND role IN ('admin', 'finance')
    )
  );

CREATE POLICY "credits_update_finance"
  ON credits_ledger
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid()
      AND role IN ('admin', 'finance')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid()
      AND role IN ('admin', 'finance')
    )
  );

CREATE POLICY "credits_delete_admin"
  ON credits_ledger
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid()
      AND role = 'admin'
    )
  );

-- Credit Applications
ALTER TABLE credit_applications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "credit_applications_select_all"
  ON credit_applications
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "credit_applications_insert_finance"
  ON credit_applications
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid()
      AND role IN ('admin', 'finance')
    )
  );

CREATE POLICY "credit_applications_update_finance"
  ON credit_applications
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid()
      AND role IN ('admin', 'finance')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid()
      AND role IN ('admin', 'finance')
    )
  );

-- ============================================
-- COMMENTS: Documentation
-- ============================================
COMMENT ON TABLE transactions IS 'Records investor capital movements (contributions and repurchases)';
COMMENT ON COLUMN transactions.type IS 'Transaction type: CONTRIBUTION (capital in) or REPURCHASE (capital out)';
COMMENT ON COLUMN transactions.fund_id IS 'Fund-level transaction (XOR with deal_id)';
COMMENT ON COLUMN transactions.deal_id IS 'Deal-level transaction (XOR with fund_id)';
COMMENT ON COLUMN transactions.batch_id IS 'CSV import batch identifier for tracking';
COMMENT ON COLUMN transactions.source IS 'Data source: MANUAL (UI), CSV_IMPORT, or VANTAGE (future integration)';

COMMENT ON TABLE credits_ledger IS 'Tracks investor credits available for charge application (STUB for Phase 3)';
COMMENT ON COLUMN credits_ledger.credit_type IS 'Credit type: EARLY_BIRD (for early investors) or PROMOTIONAL';
COMMENT ON COLUMN credits_ledger.status IS 'Credit lifecycle: AVAILABLE, APPLIED, or EXPIRED';
COMMENT ON COLUMN credits_ledger.original_amount IS 'Immutable: initial credit amount';
COMMENT ON COLUMN credits_ledger.remaining_amount IS 'Mutable: decremented as credits are applied';
COMMENT ON COLUMN credits_ledger.transaction_id IS 'Optional link to source transaction (e.g., repurchase)';

COMMENT ON TABLE credit_applications IS 'Links credits to charges (STUB for Phase 3 - requires charges table)';
COMMENT ON COLUMN credit_applications.charge_id IS 'Will reference charges.id when charges table is created';
COMMENT ON COLUMN credit_applications.reversed_at IS 'Timestamp if credit application was reversed (e.g., charge voided)';
