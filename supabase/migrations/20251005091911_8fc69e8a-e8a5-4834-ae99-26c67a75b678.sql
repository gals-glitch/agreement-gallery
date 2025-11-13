-- Phase 0: Fund vs Deal Scope Foundations

-- 1) Create deals table
CREATE TABLE IF NOT EXISTS deals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  fund_id uuid NOT NULL,
  name text NOT NULL,
  code text NOT NULL UNIQUE,
  close_date date,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid,
  is_active boolean NOT NULL DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb
);

CREATE INDEX idx_deals_fund ON deals(fund_id);
CREATE INDEX idx_deals_code ON deals(code);
CREATE INDEX idx_deals_close_date ON deals(close_date);

-- Enable RLS on deals
ALTER TABLE deals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin/Manager can access deals"
ON deals FOR ALL
USING (is_admin_or_manager(auth.uid()));

-- 2) Add deal_id to investor_distributions
ALTER TABLE investor_distributions
  ADD COLUMN IF NOT EXISTS deal_id uuid REFERENCES deals(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_distributions_deal ON investor_distributions(deal_id);

-- 3) Extend agreements for scope + overrides
ALTER TABLE agreements
  ADD COLUMN IF NOT EXISTS applies_scope text NOT NULL DEFAULT 'FUND'
    CHECK (applies_scope IN ('FUND','DEAL')),
  ADD COLUMN IF NOT EXISTS deal_id uuid REFERENCES deals(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS inherit_fund_rates boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS upfront_rate_bps integer,
  ADD COLUMN IF NOT EXISTS deferred_rate_bps integer,
  ADD COLUMN IF NOT EXISTS deferred_offset_months integer;

-- Constraint: DEAL scope with override requires all 3 rate fields
ALTER TABLE agreements
  ADD CONSTRAINT chk_deal_override_rates
  CHECK (
    applies_scope != 'DEAL' OR inherit_fund_rates = true OR
    (upfront_rate_bps IS NOT NULL AND deferred_rate_bps IS NOT NULL AND deferred_offset_months IS NOT NULL)
  );

CREATE INDEX IF NOT EXISTS idx_agreements_scope_fund ON agreements(introduced_by_party_id, applies_scope)
  WHERE applies_scope = 'FUND' AND status = 'active';

CREATE INDEX IF NOT EXISTS idx_agreements_scope_deal ON agreements(introduced_by_party_id, deal_id, applies_scope)
  WHERE applies_scope = 'DEAL' AND status = 'active';

-- 4) Extend credits for scope + deal_id
ALTER TABLE credits
  ADD COLUMN IF NOT EXISTS scope text NOT NULL DEFAULT 'FUND'
    CHECK (scope IN ('FUND','DEAL')),
  ADD COLUMN IF NOT EXISTS deal_id uuid REFERENCES deals(id) ON DELETE SET NULL;

-- Constraint: DEAL-scoped credits must have a deal_id
ALTER TABLE credits
  ADD CONSTRAINT chk_deal_credit_has_deal
  CHECK (scope != 'DEAL' OR deal_id IS NOT NULL);

CREATE INDEX IF NOT EXISTS idx_credits_scope ON credits(scope, deal_id) WHERE status = 'active';

-- 5) Add scope_breakdown to run_records
ALTER TABLE run_records
  ADD COLUMN IF NOT EXISTS scope_breakdown jsonb DEFAULT '{}'::jsonb;

-- 6) Uniqueness guardrails for agreements
-- One active FUND agreement per (party, fund) per period
CREATE UNIQUE INDEX IF NOT EXISTS u_active_fund_agreement
  ON agreements(introduced_by_party_id, applies_scope)
  WHERE applies_scope = 'FUND' AND status = 'active' AND effective_to IS NULL;

-- One active DEAL agreement per (party, deal) per period
CREATE UNIQUE INDEX IF NOT EXISTS u_active_deal_agreement
  ON agreements(introduced_by_party_id, deal_id, applies_scope)
  WHERE applies_scope = 'DEAL' AND status = 'active' AND effective_to IS NULL;

-- Trigger to update deals.updated_at
DROP TRIGGER IF EXISTS update_deals_updated_at ON deals;
CREATE TRIGGER update_deals_updated_at
  BEFORE UPDATE ON deals
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();