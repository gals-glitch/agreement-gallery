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
