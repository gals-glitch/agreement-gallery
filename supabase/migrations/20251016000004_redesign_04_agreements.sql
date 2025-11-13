-- Migration: 04_agreements.sql
-- Purpose: Create agreements, custom_terms, and rate_snapshots tables
-- Date: 2025-10-16

-- ============================================
-- AGREEMENTS (Party × (Fund OR Deal) with pricing mode)
-- ============================================
CREATE TABLE IF NOT EXISTS agreements (
  id               BIGSERIAL PRIMARY KEY,
  party_id         BIGINT NOT NULL REFERENCES parties(id) ON DELETE RESTRICT,
  scope            agreement_scope NOT NULL,
  fund_id          BIGINT REFERENCES funds(id) ON DELETE CASCADE,
  deal_id          BIGINT REFERENCES deals(id) ON DELETE CASCADE,
  pricing_mode     pricing_mode NOT NULL,
  selected_track   track_code,         -- required if pricing_mode=TRACK
  effective_from   DATE NOT NULL,
  effective_to     DATE,
  vat_included     BOOLEAN NOT NULL DEFAULT false,
  status           agreement_status NOT NULL DEFAULT 'DRAFT',
  created_by       TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- ============================================
  -- CONSTRAINTS: Business rules enforcement
  -- ============================================

  -- Scope exclusivity: either fund or deal (not both)
  CONSTRAINT agreements_scope_target_ck CHECK (
    (scope='FUND' AND fund_id IS NOT NULL AND deal_id IS NULL)
    OR
    (scope='DEAL' AND deal_id IS NOT NULL AND fund_id IS NULL)
  ),

  -- Pricing rules: FUND must use TRACK; DEAL can use TRACK or CUSTOM
  CONSTRAINT agreements_pricing_ck CHECK (
    (scope='FUND' AND pricing_mode='TRACK' AND selected_track IS NOT NULL)
    OR
    (scope='DEAL' AND (
       (pricing_mode='TRACK' AND selected_track IS NOT NULL)
       OR pricing_mode='CUSTOM'
    ))
  )
);

COMMENT ON TABLE agreements IS 'Party × (Fund OR Deal) commission agreements';
COMMENT ON COLUMN agreements.scope IS 'FUND = applies to entire fund; DEAL = applies to specific deal only';
COMMENT ON COLUMN agreements.pricing_mode IS 'TRACK = use Fund VI tracks A/B/C; CUSTOM = deal-specific rates';
COMMENT ON COLUMN agreements.selected_track IS 'Fixed track code (A/B/C) chosen at agreement creation';
COMMENT ON COLUMN agreements.vat_included IS 'If true, VAT is included in rates; if false, VAT is added on top';
COMMENT ON COLUMN agreements.status IS 'DRAFT → AWAITING_APPROVAL → APPROVED (immutable) → SUPERSEDED (by amendment)';

-- ============================================
-- AGREEMENT_CUSTOM_TERMS (for DEAL + CUSTOM pricing mode)
-- ============================================
CREATE TABLE IF NOT EXISTS agreement_custom_terms (
  agreement_id   BIGINT PRIMARY KEY REFERENCES agreements(id) ON DELETE CASCADE,
  upfront_bps    INT NOT NULL CHECK (upfront_bps >= 0),
  deferred_bps   INT NOT NULL CHECK (deferred_bps >= 0),
  caps_json      JSONB,     -- optional: caps/thresholds
  tiers_json     JSONB,     -- optional: tier structures
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE agreement_custom_terms IS 'Custom rates for DEAL-scoped agreements (when pricing_mode=CUSTOM)';
COMMENT ON COLUMN agreement_custom_terms.upfront_bps IS 'Upfront fee rate in basis points';
COMMENT ON COLUMN agreement_custom_terms.deferred_bps IS 'Deferred fee rate in basis points';

-- ============================================
-- AGREEMENT_RATE_SNAPSHOTS (immutable at approval time)
-- ============================================
CREATE TABLE IF NOT EXISTS agreement_rate_snapshots (
  id                 BIGSERIAL PRIMARY KEY,
  agreement_id       BIGINT NOT NULL REFERENCES agreements(id) ON DELETE CASCADE,
  scope              agreement_scope NOT NULL,
  pricing_mode       pricing_mode NOT NULL,
  track_code         track_code,
  resolved_upfront_bps INT NOT NULL,
  resolved_deferred_bps INT NOT NULL,
  vat_included       BOOLEAN NOT NULL,
  effective_from     DATE NOT NULL,
  effective_to       DATE,
  seed_version       INT,
  approved_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (agreement_id)
);

COMMENT ON TABLE agreement_rate_snapshots IS 'Immutable rate snapshots created when agreement is APPROVED';
COMMENT ON COLUMN agreement_rate_snapshots.resolved_upfront_bps IS 'Resolved upfront rate at approval time (from track or custom)';
COMMENT ON COLUMN agreement_rate_snapshots.resolved_deferred_bps IS 'Resolved deferred rate at approval time (from track or custom)';
COMMENT ON COLUMN agreement_rate_snapshots.seed_version IS 'Fund track seed_version used (if pricing_mode=TRACK)';
COMMENT ON COLUMN agreement_rate_snapshots.approved_at IS 'Timestamp when snapshot was created (agreement approval time)';

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_agreements_party ON agreements(party_id);
CREATE INDEX IF NOT EXISTS idx_agreements_fund ON agreements(fund_id) WHERE fund_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_agreements_deal ON agreements(deal_id) WHERE deal_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_agreements_status ON agreements(status);
CREATE INDEX IF NOT EXISTS idx_agreements_effective ON agreements(effective_from, effective_to);
CREATE INDEX IF NOT EXISTS idx_snapshots_agreement ON agreement_rate_snapshots(agreement_id);
