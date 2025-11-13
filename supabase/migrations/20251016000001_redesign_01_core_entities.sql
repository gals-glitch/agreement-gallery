-- Migration: 01_core_entities.sql
-- Purpose: Create funds, parties, deals, investors tables
-- Date: 2025-10-16

-- ============================================
-- FUNDS (umbrella entities like "Fund VI")
-- ============================================
CREATE TABLE IF NOT EXISTS funds (
  id              BIGSERIAL PRIMARY KEY,
  name            TEXT NOT NULL UNIQUE,
  vintage_year    INT,
  currency        TEXT DEFAULT 'USD',
  status          TEXT DEFAULT 'ACTIVE',
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE funds IS 'Umbrella fund entities (e.g., Fund VI)';
COMMENT ON COLUMN funds.name IS 'Unique fund name (e.g., "Fund VI")';
COMMENT ON COLUMN funds.vintage_year IS 'Fund vintage year';

-- ============================================
-- PARTIES (distributors/referrers earning commissions)
-- ============================================
CREATE TABLE IF NOT EXISTS parties (
  id              BIGSERIAL PRIMARY KEY,
  name            TEXT NOT NULL UNIQUE,
  email           TEXT,
  country         TEXT,
  tax_id          TEXT,
  active          BOOLEAN NOT NULL DEFAULT true,
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE parties IS 'Distributors/referrers earning commissions';
COMMENT ON COLUMN parties.tax_id IS 'Tax ID for compliance (e.g., VAT number)';
COMMENT ON COLUMN parties.active IS 'Inactive parties cannot be selected in new agreements';

-- ============================================
-- LOOKUP TABLES (optional, can be empty initially)
-- ============================================
CREATE TABLE IF NOT EXISTS partner_companies (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS fund_groups (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
);

COMMENT ON TABLE partner_companies IS 'Partner companies for deal attribution';
COMMENT ON TABLE fund_groups IS 'Fund groups for deal categorization';

-- ============================================
-- DEALS (properties/projects - what Vantage calls "funds")
-- ============================================
CREATE TABLE IF NOT EXISTS deals (
  id              BIGSERIAL PRIMARY KEY,
  fund_id         BIGINT REFERENCES funds(id) ON DELETE SET NULL,
  name            TEXT NOT NULL UNIQUE,
  address         TEXT,
  status          TEXT DEFAULT 'ACTIVE',        -- Active/Sold
  close_date      DATE,
  partner_company_id BIGINT REFERENCES partner_companies(id),
  fund_group_id   BIGINT REFERENCES fund_groups(id),
  sector          TEXT,
  year_built      INT,
  units           INT,
  sqft            NUMERIC,
  income_producing BOOLEAN DEFAULT false,
  exclude_gp_from_commission BOOLEAN NOT NULL DEFAULT true,
  equity_to_raise NUMERIC,   -- read-only in UI (from Scoreboard import)
  raised_so_far   NUMERIC,   -- read-only in UI (from Scoreboard import)
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE deals IS 'Properties/projects (what Vantage calls "funds")';
COMMENT ON COLUMN deals.exclude_gp_from_commission IS 'If true, contributions from GP investors are excluded from commission calculations';
COMMENT ON COLUMN deals.equity_to_raise IS 'Read-only: imported from Scoreboard';
COMMENT ON COLUMN deals.raised_so_far IS 'Read-only: imported from Scoreboard';

-- ============================================
-- DEAL CLOSES (supports multiple closes per deal)
-- ============================================
CREATE TABLE IF NOT EXISTS deal_closes (
  id          BIGSERIAL PRIMARY KEY,
  deal_id     BIGINT NOT NULL REFERENCES deals(id) ON DELETE CASCADE,
  close_date  DATE NOT NULL,
  amount_value NUMERIC,
  amount_imported BOOLEAN DEFAULT false,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE deal_closes IS 'Deal closing dates and amounts (typically one close per deal initially)';

-- ============================================
-- INVESTORS (LP entities investing into deals/funds)
-- ============================================
CREATE TABLE IF NOT EXISTS investors (
  id          BIGSERIAL PRIMARY KEY,
  name        TEXT NOT NULL UNIQUE,
  external_id TEXT,                 -- from Vantage
  currency    TEXT DEFAULT 'USD',
  is_gp       BOOLEAN NOT NULL DEFAULT false,
  notes       TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE investors IS 'LP entities investing into deals/funds';
COMMENT ON COLUMN investors.is_gp IS 'If true, this investor is a GP and contributions may be excluded from commissions';
COMMENT ON COLUMN investors.external_id IS 'External ID from Vantage system';

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_deals_fund ON deals(fund_id);
CREATE INDEX IF NOT EXISTS idx_deals_status ON deals(status);
CREATE INDEX IF NOT EXISTS idx_parties_active ON parties(active);
CREATE INDEX IF NOT EXISTS idx_investors_external ON investors(external_id);
