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
