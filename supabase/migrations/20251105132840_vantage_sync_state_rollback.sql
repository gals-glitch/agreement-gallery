/**
 * ROLLBACK Migration for Vantage ETL Sync State Tracking
 * Ticket: ETL-001
 * Date: 2025-11-05
 *
 * Purpose: Safely remove vantage_sync_state infrastructure
 *
 * WARNING: This will delete all sync state history
 * Only run this if you need to completely remove the sync tracking system
 */

BEGIN;

-- ============================================
-- 1. Drop Helper Functions
-- ============================================

DROP FUNCTION IF EXISTS fail_vantage_sync(TEXT, JSONB);
DROP FUNCTION IF EXISTS complete_vantage_sync(TEXT, INT, INT, INT);
DROP FUNCTION IF EXISTS start_vantage_sync(TEXT);

-- ============================================
-- 2. Drop Triggers
-- ============================================

DROP TRIGGER IF EXISTS trigger_calculate_vantage_sync_duration ON vantage_sync_state;
DROP TRIGGER IF EXISTS trigger_vantage_sync_state_updated_at ON vantage_sync_state;

-- ============================================
-- 3. Drop Trigger Functions
-- ============================================

DROP FUNCTION IF EXISTS calculate_vantage_sync_duration();
DROP FUNCTION IF EXISTS update_vantage_sync_state_updated_at();

-- ============================================
-- 4. Drop Table (CASCADE removes all dependencies)
-- ============================================

DROP TABLE IF EXISTS vantage_sync_state CASCADE;

COMMIT;

-- ============================================
-- VERIFICATION
-- ============================================

-- Verify table is dropped
-- SELECT EXISTS (
--   SELECT FROM information_schema.tables
--   WHERE table_schema = 'public'
--   AND table_name = 'vantage_sync_state'
-- );
-- Expected: false

-- Verify functions are dropped
-- SELECT COUNT(*) FROM pg_proc
-- WHERE proname LIKE '%vantage_sync%';
-- Expected: 0
