-- ============================================
-- CLEAN SETUP: Drop old schema and apply redesign
-- WARNING: This will delete all existing data
-- Date: 2025-10-16
-- ============================================

-- Step 1: Drop existing tables in correct order (respecting foreign keys)
DROP TABLE IF EXISTS agreement_rate_snapshots CASCADE;
DROP TABLE IF EXISTS agreement_custom_terms CASCADE;
DROP TABLE IF EXISTS agreements CASCADE;
DROP TABLE IF EXISTS fund_tracks CASCADE;
DROP TABLE IF EXISTS scoreboard_deal_metrics CASCADE;
DROP TABLE IF EXISTS contributions CASCADE;
DROP TABLE IF EXISTS deal_closes CASCADE;
DROP TABLE IF EXISTS investors CASCADE;
DROP TABLE IF EXISTS deals CASCADE;
DROP TABLE IF EXISTS parties CASCADE;
DROP TABLE IF EXISTS fund_groups CASCADE;
DROP TABLE IF EXISTS partner_companies CASCADE;
DROP TABLE IF EXISTS funds CASCADE;

-- Step 2: Drop existing types
DROP TYPE IF EXISTS agreement_scope CASCADE;
DROP TYPE IF EXISTS pricing_mode CASCADE;
DROP TYPE IF EXISTS agreement_status CASCADE;
DROP TYPE IF EXISTS track_code CASCADE;

-- Step 3: Drop existing functions
DROP FUNCTION IF EXISTS prevent_update_on_approved() CASCADE;
DROP FUNCTION IF EXISTS snapshot_rates_on_approval() CASCADE;
DROP FUNCTION IF EXISTS apply_scoreboard_metrics(TEXT) CASCADE;

-- ============================================
-- Now apply all migrations from scratch
-- ============================================
-- Migration: 00_types.sql
-- Purpose: Create enum types for redesigned agreement system
-- Date: 2025-10-16

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'agreement_scope') THEN
    CREATE TYPE agreement_scope AS ENUM ('FUND','DEAL');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'pricing_mode') THEN
    CREATE TYPE pricing_mode AS ENUM ('TRACK','CUSTOM');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'agreement_status') THEN
    CREATE TYPE agreement_status AS ENUM ('DRAFT','AWAITING_APPROVAL','APPROVED','SUPERSEDED');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'track_code') THEN
    CREATE TYPE track_code AS ENUM ('A','B','C');
  END IF;
END $$;

COMMENT ON TYPE agreement_scope IS 'Agreement can apply to entire FUND or specific DEAL';
COMMENT ON TYPE pricing_mode IS 'TRACK = use Fund VI tracks A/B/C, CUSTOM = deal-specific rates';
COMMENT ON TYPE agreement_status IS 'Agreement lifecycle: DRAFT → AWAITING_APPROVAL → APPROVED (immutable) → SUPERSEDED (by amendment)';
COMMENT ON TYPE track_code IS 'Fund VI track codes: A (≤$3M), B ($3-6M), C (>$6M)';
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
-- Migration: 03_tracks.sql
-- Purpose: Create fund_tracks table (locked, seed-only Track A/B/C rates)
-- Date: 2025-10-16

-- ============================================
-- FUND_TRACKS (Fund VI Track A/B/C rate definitions)
-- ============================================
CREATE TABLE IF NOT EXISTS fund_tracks (
  id             BIGSERIAL PRIMARY KEY,
  fund_id        BIGINT NOT NULL REFERENCES funds(id) ON DELETE CASCADE,
  track_code     track_code NOT NULL,
  upfront_bps    INT NOT NULL CHECK (upfront_bps >= 0),  -- e.g., 180 = 1.80%
  deferred_bps   INT NOT NULL CHECK (deferred_bps >= 0), -- e.g., 80  = 0.80%
  offset_months  INT NOT NULL DEFAULT 0 CHECK (offset_months >= 0),
  tier_min       NUMERIC,          -- reference only (e.g., $0 for Track A)
  tier_max       NUMERIC,          -- reference only (e.g., $3M for Track A)
  valid_from     DATE NOT NULL DEFAULT DATE '2025-01-01',
  valid_to       DATE,
  is_locked      BOOLEAN NOT NULL DEFAULT true,
  seed_version   INT NOT NULL DEFAULT 1,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (fund_id, track_code, valid_from)
);

COMMENT ON TABLE fund_tracks IS 'Fund VI Track A/B/C rate definitions (seed-only, locked)';
COMMENT ON COLUMN fund_tracks.track_code IS 'Track code: A, B, or C';
COMMENT ON COLUMN fund_tracks.upfront_bps IS 'Upfront fee rate in basis points (e.g., 180 = 1.80%)';
COMMENT ON COLUMN fund_tracks.deferred_bps IS 'Deferred fee rate in basis points (e.g., 80 = 0.80%)';
COMMENT ON COLUMN fund_tracks.offset_months IS 'Months to offset deferred fee payment (e.g., 24)';
COMMENT ON COLUMN fund_tracks.tier_min IS 'Tier minimum amount (reference only - NOT used for dynamic calculation)';
COMMENT ON COLUMN fund_tracks.tier_max IS 'Tier maximum amount (reference only - NOT used for dynamic calculation)';
COMMENT ON COLUMN fund_tracks.is_locked IS 'If true, rates cannot be edited (seed-only)';
COMMENT ON COLUMN fund_tracks.seed_version IS 'Seed version for audit trail';

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_fund_tracks_fund ON fund_tracks(fund_id);
CREATE INDEX IF NOT EXISTS idx_fund_tracks_code ON fund_tracks(track_code);
CREATE INDEX IF NOT EXISTS idx_fund_tracks_valid ON fund_tracks(valid_from, valid_to);
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
-- Migration: 05_scoreboard_import.sql
-- Purpose: CSV landing table for Scoreboard data imports (Phase 1)
-- Date: 2025-10-16

-- ============================================
-- SCOREBOARD_DEAL_METRICS (CSV landing table)
-- ============================================
CREATE TABLE IF NOT EXISTS scoreboard_deal_metrics (
  id            BIGSERIAL PRIMARY KEY,
  deal_name     TEXT NOT NULL,
  equity_to_raise NUMERIC,
  raised_so_far NUMERIC,
  import_batch  TEXT NOT NULL,
  imported_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE scoreboard_deal_metrics IS 'CSV landing table for Scoreboard data imports (read-only display in Deals)';
COMMENT ON COLUMN scoreboard_deal_metrics.deal_name IS 'Deal name to match against deals.name';
COMMENT ON COLUMN scoreboard_deal_metrics.equity_to_raise IS 'Total equity to raise for this deal';
COMMENT ON COLUMN scoreboard_deal_metrics.raised_so_far IS 'Amount raised so far for this deal';
COMMENT ON COLUMN scoreboard_deal_metrics.import_batch IS 'Import batch identifier (e.g., "2025Q3")';

-- ============================================
-- FUNCTION: Apply Scoreboard metrics to Deals
-- ============================================
CREATE OR REPLACE FUNCTION apply_scoreboard_metrics(p_batch TEXT)
RETURNS INT AS $$
DECLARE updated_count INT;
BEGIN
  UPDATE deals d
  SET equity_to_raise = s.equity_to_raise,
      raised_so_far   = s.raised_so_far,
      updated_at      = now()
  FROM scoreboard_deal_metrics s
  WHERE s.import_batch = p_batch
    AND s.deal_name = d.name;

  GET DIAGNOSTICS updated_count = ROW_COUNT;

  RETURN updated_count;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION apply_scoreboard_metrics IS 'Upsert Scoreboard metrics into deals table after CSV import';

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_scoreboard_batch ON scoreboard_deal_metrics(import_batch);
CREATE INDEX IF NOT EXISTS idx_scoreboard_deal_name ON scoreboard_deal_metrics(deal_name);

-- ============================================
-- EXAMPLE USAGE
-- ============================================
-- 1. Load CSV into scoreboard_deal_metrics with import_batch = '2025Q3'
-- 2. Run: SELECT apply_scoreboard_metrics('2025Q3');
-- 3. Verify: SELECT name, equity_to_raise, raised_so_far FROM deals WHERE equity_to_raise IS NOT NULL;
-- Migration: 06_guards.sql
-- Purpose: Immutability triggers and snapshot automation
-- Date: 2025-10-16

-- ============================================
-- TRIGGER 1: Prevent updates to APPROVED agreements
-- ============================================
CREATE OR REPLACE FUNCTION prevent_update_on_approved()
RETURNS trigger AS $$
BEGIN
  IF OLD.status = 'APPROVED' AND (NEW.* IS DISTINCT FROM OLD.*) THEN
    RAISE EXCEPTION 'Approved agreements are immutable. Use Amendment flow to create a new version.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname='agreements_lock_after_approval') THEN
    CREATE TRIGGER agreements_lock_after_approval
    BEFORE UPDATE ON agreements
    FOR EACH ROW
    WHEN (OLD.status = 'APPROVED')
    EXECUTE PROCEDURE prevent_update_on_approved();
  END IF;
END $$;

COMMENT ON FUNCTION prevent_update_on_approved IS 'Trigger function: Blocks any updates to APPROVED agreements';

-- ============================================
-- TRIGGER 2: Auto-create rate snapshot on approval
-- ============================================
CREATE OR REPLACE FUNCTION snapshot_rates_on_approval()
RETURNS trigger AS $$
DECLARE
  up_bps INT;
  def_bps INT;
  seed_ver INT;
  target_fund_id BIGINT;
BEGIN
  -- Only run when transitioning TO 'APPROVED'
  IF NEW.status = 'APPROVED' AND OLD.status IS DISTINCT FROM 'APPROVED' THEN

    -- Determine target fund_id for track lookup
    IF NEW.scope = 'FUND' THEN
      target_fund_id := NEW.fund_id;
    ELSIF NEW.scope = 'DEAL' THEN
      SELECT fund_id INTO target_fund_id FROM deals WHERE id = NEW.deal_id;
    END IF;

    -- Resolve rates based on pricing_mode
    IF NEW.pricing_mode = 'TRACK' THEN
      -- Look up track rates from fund_tracks
      SELECT ft.upfront_bps, ft.deferred_bps, ft.seed_version
        INTO up_bps, def_bps, seed_ver
      FROM fund_tracks ft
      WHERE ft.fund_id = target_fund_id
        AND ft.track_code = NEW.selected_track
        AND ft.valid_from <= NEW.effective_from
        AND (ft.valid_to IS NULL OR ft.valid_to >= NEW.effective_from)
      ORDER BY ft.valid_from DESC
      LIMIT 1;

      IF up_bps IS NULL OR def_bps IS NULL THEN
        RAISE EXCEPTION 'Cannot approve agreement %: Track % rates not found for fund %',
          NEW.id, NEW.selected_track, target_fund_id;
      END IF;

    ELSIF NEW.pricing_mode = 'CUSTOM' THEN
      -- Look up custom rates
      SELECT act.upfront_bps, act.deferred_bps
        INTO up_bps, def_bps
      FROM agreement_custom_terms act
      WHERE act.agreement_id = NEW.id;

      IF up_bps IS NULL OR def_bps IS NULL THEN
        RAISE EXCEPTION 'Cannot approve agreement %: Custom terms not defined', NEW.id;
      END IF;

      seed_ver := NULL;  -- No seed_version for custom rates
    END IF;

    -- Insert snapshot (idempotent via ON CONFLICT)
    INSERT INTO agreement_rate_snapshots(
      agreement_id, scope, pricing_mode, track_code,
      resolved_upfront_bps, resolved_deferred_bps, vat_included,
      effective_from, effective_to, seed_version, approved_at
    )
    VALUES (
      NEW.id, NEW.scope, NEW.pricing_mode, NEW.selected_track,
      up_bps, def_bps, NEW.vat_included,
      NEW.effective_from, NEW.effective_to, seed_ver, now()
    )
    ON CONFLICT (agreement_id) DO NOTHING;

  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname='agreements_snapshot_on_approve') THEN
    CREATE TRIGGER agreements_snapshot_on_approve
    AFTER UPDATE ON agreements
    FOR EACH ROW
    EXECUTE PROCEDURE snapshot_rates_on_approval();
  END IF;
END $$;

COMMENT ON FUNCTION snapshot_rates_on_approval IS 'Trigger function: Auto-creates immutable rate snapshot when agreement moves to APPROVED status';

-- ============================================
-- EXAMPLE: Amendment Flow
-- ============================================
-- To amend an APPROVED agreement:
--
-- 1. Clone existing agreement to new Draft:
--    INSERT INTO agreements (party_id, scope, fund_id, deal_id, pricing_mode, selected_track, ...)
--    SELECT party_id, scope, fund_id, deal_id, pricing_mode, selected_track, ...
--    FROM agreements WHERE id = [old_agreement_id];
--
-- 2. Update old agreement status to SUPERSEDED:
--    UPDATE agreements SET status = 'SUPERSEDED', effective_to = [new_effective_date] WHERE id = [old_agreement_id];
--
-- 3. Edit new Draft as needed
--
-- 4. Approve new Draft → triggers snapshot creation
-- Migration: 07_seed_fund_vi.sql
-- Purpose: Seed Fund VI and locked Track A/B/C rates
-- Date: 2025-10-16

-- ============================================
-- SEED: Fund VI
-- ============================================
INSERT INTO funds(name, vintage_year, currency, status)
VALUES ('Fund VI', 2025, 'USD', 'ACTIVE')
ON CONFLICT (name) DO NOTHING;

-- ============================================
-- SEED: Fund VI Tracks A/B/C (LOCKED)
-- ============================================
WITH f AS (SELECT id FROM funds WHERE name='Fund VI')
INSERT INTO fund_tracks (
  fund_id, track_code, upfront_bps, deferred_bps, offset_months,
  tier_min, tier_max, valid_from, is_locked, seed_version
)
SELECT f.id, 'A'::track_code, 120, 80, 24, 0,       3000000,  DATE '2025-01-01', true, 1 FROM f
UNION ALL
SELECT f.id, 'B'::track_code, 180, 80, 24, 3000001, 6000000,  DATE '2025-01-01', true, 1 FROM f
UNION ALL
SELECT f.id, 'C'::track_code, 180, 130,24, 6000001, NULL,     DATE '2025-01-01', true, 1 FROM f
ON CONFLICT (fund_id, track_code, valid_from) DO NOTHING;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================
-- View seeded data:
-- SELECT f.name AS fund, ft.track_code, ft.upfront_bps, ft.deferred_bps, ft.is_locked
-- FROM fund_tracks ft
-- JOIN funds f ON ft.fund_id = f.id
-- WHERE f.name = 'Fund VI';

-- Expected output:
-- fund     | track_code | upfront_bps | deferred_bps | is_locked
-- ---------+------------+-------------+--------------+-----------
-- Fund VI  | A          | 120         | 80           | true
-- Fund VI  | B          | 180         | 80           | true
-- Fund VI  | C          | 180         | 130          | true

COMMENT ON TABLE fund_tracks IS 'Fund VI Tracks seeded: A (1.2%/0.8%), B (1.8%/0.8%), C (1.8%/1.3%) - LOCKED';
-- ============================================
-- FIX: Immutability Trigger - Allow SUPERSEDED Transition
-- Date: 2025-10-16
-- Issue: Original trigger blocked ALL updates to APPROVED agreements,
--        preventing amendment flow from marking v1 as SUPERSEDED.
-- ============================================

CREATE OR REPLACE FUNCTION prevent_update_on_approved()
RETURNS trigger AS $$
BEGIN
  IF OLD.status = 'APPROVED' THEN
    -- Allow ONLY: status APPROVED -> SUPERSEDED and effective_to change
    -- All other fields must remain unchanged
    IF NOT (
      NEW.status = 'SUPERSEDED'
      AND (NEW.effective_to IS DISTINCT FROM OLD.effective_to OR NEW.effective_to = OLD.effective_to)
      AND NEW.selected_track IS NOT DISTINCT FROM OLD.selected_track
      AND NEW.pricing_mode  IS NOT DISTINCT FROM OLD.pricing_mode
      AND NEW.party_id      IS NOT DISTINCT FROM OLD.party_id
      AND NEW.scope         IS NOT DISTINCT FROM OLD.scope
      AND NEW.fund_id       IS NOT DISTINCT FROM OLD.fund_id
      AND NEW.deal_id       IS NOT DISTINCT FROM OLD.deal_id
      AND NEW.vat_included  IS NOT DISTINCT FROM OLD.vat_included
      AND NEW.effective_from IS NOT DISTINCT FROM OLD.effective_from
    ) THEN
      RAISE EXCEPTION 'Approved agreements are immutable. Only status->SUPERSEDED and effective_to adjustments allowed via amendment flow.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger already exists, no need to recreate
-- Just replacing the function implementation above

-- ============================================
-- VERIFICATION
-- ============================================
-- Test verification code removed - can be run manually after migration if needed
-- Migration: contributions_rls.sql
-- Purpose: Add RLS policies for contributions table
-- Date: 2025-10-16

-- Enable RLS
ALTER TABLE contributions ENABLE ROW LEVEL SECURITY;

-- Policy: Allow authenticated users to read all contributions
CREATE POLICY "Allow authenticated read access to contributions"
  ON contributions
  FOR SELECT
  TO authenticated
  USING (true);

-- Policy: Allow authenticated users to insert contributions
CREATE POLICY "Allow authenticated insert access to contributions"
  ON contributions
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Policy: Allow authenticated users to update contributions
CREATE POLICY "Allow authenticated update access to contributions"
  ON contributions
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Policy: Allow authenticated users to delete contributions
CREATE POLICY "Allow authenticated delete access to contributions"
  ON contributions
  FOR DELETE
  TO authenticated
  USING (true);

COMMENT ON TABLE contributions IS 'Contributions table with RLS enabled - all authenticated users have full access';
