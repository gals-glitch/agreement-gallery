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
