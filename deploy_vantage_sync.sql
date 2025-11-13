/**
 * Vantage ETL Sync State Tracking - Database Schema
 * Ticket: ETL-001
 * Date: 2025-11-05
 *
 * Purpose: Track synchronization state for Vantage API ETL operations
 *
 * Design:
 * - Single table tracks sync status per resource type (accounts, funds, cashflows, etc.)
 * - Primary key on 'resource' ensures one row per resource type
 * - Separate timestamps for started_at/completed_at enables progress tracking
 * - JSONB 'errors' field allows flexible error structure without schema changes
 * - duration_ms helps identify performance bottlenecks and slow syncs
 * - Status transitions: never_run -> running -> success/failed -> running -> ...
 *
 * Security:
 * - RLS enabled: authenticated users can read, service role can write
 * - ETL processes use service_role for writes
 * - Frontend can query sync status for UI feedback
 */

BEGIN;

-- ============================================
-- 1. CREATE TABLE: vantage_sync_state
-- ============================================

CREATE TABLE IF NOT EXISTS vantage_sync_state (
  -- Primary identifier for the resource being synced
  -- Examples: 'accounts', 'funds', 'cashflows', 'commitments', 'investors'
  resource TEXT PRIMARY KEY,

  -- Last successful sync timestamp - used for incremental sync (WHERE modified > last_sync_time)
  -- NULL if never successfully synced
  last_sync_time TIMESTAMPTZ,

  -- Current or most recent sync status
  -- Transitions: never_run -> running -> (success | failed) -> running -> ...
  last_sync_status TEXT NOT NULL DEFAULT 'never_run'
    CHECK (last_sync_status IN ('success', 'failed', 'running', 'never_run')),

  -- Total number of records processed in last sync attempt (success or failed)
  -- Useful for monitoring data volume and detecting anomalies
  records_synced INT DEFAULT 0 CHECK (records_synced >= 0),

  -- Count of new records created in last sync
  -- Helps track data growth over time
  records_created INT DEFAULT 0 CHECK (records_created >= 0),

  -- Count of existing records updated in last sync
  -- High update count may indicate data quality issues
  records_updated INT DEFAULT 0 CHECK (records_updated >= 0),

  -- Array of error details from last sync run
  -- Structure: [{"code": "ERR_001", "message": "...", "record_id": "...", "timestamp": "..."}]
  -- Empty array [] indicates no errors
  errors JSONB DEFAULT '[]'::jsonb,

  -- When the current/last sync operation started
  -- Used with completed_at to calculate duration
  started_at TIMESTAMPTZ,

  -- When the current/last sync operation completed (success or failure)
  -- NULL if sync is currently running
  completed_at TIMESTAMPTZ,

  -- Duration of last sync in milliseconds
  -- Calculated as (completed_at - started_at), NULL if running
  -- Used for performance monitoring and alerting on slow syncs
  duration_ms INT CHECK (duration_ms >= 0),

  -- Row metadata timestamps
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,

  -- Constraint: completed_at must be after started_at
  CONSTRAINT valid_sync_timerange CHECK (
    completed_at IS NULL OR started_at IS NULL OR completed_at >= started_at
  ),

  -- Constraint: if status is 'running', completed_at should be NULL
  CONSTRAINT running_incomplete CHECK (
    last_sync_status != 'running' OR completed_at IS NULL
  ),

  -- Constraint: errors must be a valid JSON array
  CONSTRAINT errors_is_array CHECK (
    jsonb_typeof(errors) = 'array'
  )
);

-- ============================================
-- 2. TABLE COMMENTS (Documentation)
-- ============================================

COMMENT ON TABLE vantage_sync_state IS
  'Tracks ETL synchronization state per resource from Vantage API. One row per resource type.';

COMMENT ON COLUMN vantage_sync_state.resource IS
  'Resource type being synced (e.g., accounts, funds, cashflows). Primary key ensures one row per resource.';

COMMENT ON COLUMN vantage_sync_state.last_sync_time IS
  'Timestamp of last successful sync. Used for incremental sync queries (WHERE modified > last_sync_time).';

COMMENT ON COLUMN vantage_sync_state.last_sync_status IS
  'Current sync status: never_run (initial), running (in progress), success (completed ok), failed (errors occurred).';

COMMENT ON COLUMN vantage_sync_state.records_synced IS
  'Total records processed in last sync (created + updated + skipped). Used for volume monitoring.';

COMMENT ON COLUMN vantage_sync_state.records_created IS
  'Number of new records inserted in last sync. Tracks data growth.';

COMMENT ON COLUMN vantage_sync_state.records_updated IS
  'Number of existing records modified in last sync. High values may indicate data quality issues.';

COMMENT ON COLUMN vantage_sync_state.errors IS
  'JSONB array of error objects from last sync: [{"code": "...", "message": "...", "record_id": "...", "timestamp": "..."}]';

COMMENT ON COLUMN vantage_sync_state.started_at IS
  'When current/last sync started. Used with completed_at to calculate duration_ms.';

COMMENT ON COLUMN vantage_sync_state.completed_at IS
  'When sync completed (success or failure). NULL if currently running.';

COMMENT ON COLUMN vantage_sync_state.duration_ms IS
  'Sync duration in milliseconds (completed_at - started_at). Used for performance monitoring.';

-- ============================================
-- 3. INDEXES (Query Optimization)
-- ============================================

-- Index for querying by sync status (e.g., find all failed syncs)
-- Partial index only on non-success states to save space
CREATE INDEX IF NOT EXISTS idx_vantage_sync_status
  ON vantage_sync_state(last_sync_status)
  WHERE last_sync_status != 'success';

-- Index for finding stale syncs (old last_sync_time)
-- Used by monitoring to alert on syncs that haven't run recently
CREATE INDEX IF NOT EXISTS idx_vantage_sync_last_time
  ON vantage_sync_state(last_sync_time DESC NULLS LAST);

-- Index for performance monitoring (slow syncs)
-- Partial index only on completed syncs with duration
CREATE INDEX IF NOT EXISTS idx_vantage_sync_duration
  ON vantage_sync_state(duration_ms DESC)
  WHERE duration_ms IS NOT NULL;

-- ============================================
-- 4. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

ALTER TABLE vantage_sync_state ENABLE ROW LEVEL SECURITY;

-- Policy: All authenticated users can read sync state
-- Allows frontend to display sync status, last sync time, etc.
CREATE POLICY "vantage_sync_state_select_all"
  ON vantage_sync_state
  FOR SELECT
  TO authenticated
  USING (true);

-- Policy: Only service_role can insert new sync state rows
-- Typically only needed for new resource types
CREATE POLICY "vantage_sync_state_insert_service"
  ON vantage_sync_state
  FOR INSERT
  TO service_role
  WITH CHECK (true);

-- Policy: Only service_role can update sync state
-- ETL processes run with service_role credentials
CREATE POLICY "vantage_sync_state_update_service"
  ON vantage_sync_state
  FOR UPDATE
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Policy: Only service_role can delete sync state rows
-- Rarely needed, but available for cleanup/maintenance
CREATE POLICY "vantage_sync_state_delete_service"
  ON vantage_sync_state
  FOR DELETE
  TO service_role
  USING (true);

-- ============================================
-- 5. TRIGGERS (Automated Maintenance)
-- ============================================

-- Function: Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_vantage_sync_state_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Update updated_at on every row modification
CREATE TRIGGER trigger_vantage_sync_state_updated_at
  BEFORE UPDATE ON vantage_sync_state
  FOR EACH ROW
  EXECUTE FUNCTION update_vantage_sync_state_updated_at();

-- Function: Auto-calculate duration_ms when sync completes
CREATE OR REPLACE FUNCTION calculate_vantage_sync_duration()
RETURNS TRIGGER AS $$
BEGIN
  -- If completed_at is being set and started_at exists, calculate duration
  IF NEW.completed_at IS NOT NULL AND NEW.started_at IS NOT NULL THEN
    NEW.duration_ms = EXTRACT(EPOCH FROM (NEW.completed_at - NEW.started_at)) * 1000;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Calculate duration_ms automatically
CREATE TRIGGER trigger_calculate_vantage_sync_duration
  BEFORE INSERT OR UPDATE ON vantage_sync_state
  FOR EACH ROW
  EXECUTE FUNCTION calculate_vantage_sync_duration();

-- ============================================
-- 6. SEED DATA (Initial Resource Rows)
-- ============================================

-- Pre-populate rows for known Vantage resource types
-- This ensures ETL processes can UPDATE instead of INSERT (simpler logic)
INSERT INTO vantage_sync_state (resource, last_sync_status)
VALUES
  ('accounts', 'never_run'),
  ('funds', 'never_run'),
  ('cashflows', 'never_run'),
  ('commitments', 'never_run'),
  ('investors', 'never_run'),
  ('investments', 'never_run'),
  ('valuations', 'never_run')
ON CONFLICT (resource) DO NOTHING;

COMMIT;

-- ============================================
-- 7. HELPER FUNCTIONS (Optional Utilities)
-- ============================================

-- Function: Mark sync as started
-- Usage: SELECT start_vantage_sync('accounts');
CREATE OR REPLACE FUNCTION start_vantage_sync(p_resource TEXT)
RETURNS void AS $$
BEGIN
  INSERT INTO vantage_sync_state (resource, last_sync_status, started_at)
  VALUES (p_resource, 'running', now())
  ON CONFLICT (resource) DO UPDATE
  SET
    last_sync_status = 'running',
    started_at = now(),
    completed_at = NULL,
    duration_ms = NULL,
    updated_at = now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Mark sync as completed (success)
-- Usage: SELECT complete_vantage_sync('accounts', 100, 10, 90);
CREATE OR REPLACE FUNCTION complete_vantage_sync(
  p_resource TEXT,
  p_records_synced INT,
  p_records_created INT,
  p_records_updated INT
)
RETURNS void AS $$
BEGIN
  UPDATE vantage_sync_state
  SET
    last_sync_status = 'success',
    last_sync_time = now(),
    records_synced = p_records_synced,
    records_created = p_records_created,
    records_updated = p_records_updated,
    completed_at = now(),
    errors = '[]'::jsonb,
    updated_at = now()
  WHERE resource = p_resource;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Mark sync as failed
-- Usage: SELECT fail_vantage_sync('accounts', '[{"code": "ERR_001", "message": "API timeout"}]'::jsonb);
CREATE OR REPLACE FUNCTION fail_vantage_sync(
  p_resource TEXT,
  p_errors JSONB
)
RETURNS void AS $$
BEGIN
  UPDATE vantage_sync_state
  SET
    last_sync_status = 'failed',
    completed_at = now(),
    errors = p_errors,
    updated_at = now()
  WHERE resource = p_resource;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions on helper functions to service_role
GRANT EXECUTE ON FUNCTION start_vantage_sync(TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION complete_vantage_sync(TEXT, INT, INT, INT) TO service_role;
GRANT EXECUTE ON FUNCTION fail_vantage_sync(TEXT, JSONB) TO service_role;

-- ============================================
-- VERIFICATION QUERIES (For Testing)
-- ============================================

-- Check table structure
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_name = 'vantage_sync_state'
-- ORDER BY ordinal_position;

-- Check constraints
-- SELECT conname, pg_get_constraintdef(oid)
-- FROM pg_constraint
-- WHERE conrelid = 'vantage_sync_state'::regclass;

-- Check indexes
-- SELECT indexname, indexdef
-- FROM pg_indexes
-- WHERE tablename = 'vantage_sync_state'
-- ORDER BY indexname;

-- Check RLS policies
-- SELECT policyname, permissive, roles, cmd, qual, with_check
-- FROM pg_policies
-- WHERE tablename = 'vantage_sync_state'
-- ORDER BY policyname;

-- Check triggers
-- SELECT trigger_name, event_manipulation, action_statement
-- FROM information_schema.triggers
-- WHERE event_object_table = 'vantage_sync_state'
-- ORDER BY trigger_name;

-- Check seed data
-- SELECT resource, last_sync_status, last_sync_time
-- FROM vantage_sync_state
-- ORDER BY resource;
