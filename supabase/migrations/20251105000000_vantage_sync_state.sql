-- ============================================
-- Vantage Sync State Table
-- Purpose: Track ETL sync state for Vantage IR API resources
-- Date: 2025-11-05
-- ============================================

-- ============================================
-- CREATE TABLE: vantage_sync_state
-- ============================================

CREATE TABLE IF NOT EXISTS vantage_sync_state (
  resource TEXT PRIMARY KEY,
  last_sync_time TIMESTAMPTZ,
  last_sync_status TEXT,
  records_synced INT DEFAULT 0,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  duration_ms BIGINT,
  errors JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE vantage_sync_state IS 'Tracks ETL sync state for Vantage IR API resources (accounts, funds, etc.)';

COMMENT ON COLUMN vantage_sync_state.resource IS 'Resource identifier (accounts, funds, cash_flows, etc.)';
COMMENT ON COLUMN vantage_sync_state.last_sync_time IS 'Timestamp of last successful sync completion (used for incremental syncs)';
COMMENT ON COLUMN vantage_sync_state.last_sync_status IS 'Status of last sync: running, success, or failed';
COMMENT ON COLUMN vantage_sync_state.records_synced IS 'Number of records synced in last sync';
COMMENT ON COLUMN vantage_sync_state.started_at IS 'Timestamp when last sync started';
COMMENT ON COLUMN vantage_sync_state.completed_at IS 'Timestamp when last sync completed';
COMMENT ON COLUMN vantage_sync_state.duration_ms IS 'Duration of last sync in milliseconds';
COMMENT ON COLUMN vantage_sync_state.errors IS 'Array of validation/processing errors from last sync';

-- ============================================
-- CREATE INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_vantage_sync_state_status
  ON vantage_sync_state(last_sync_status);

CREATE INDEX IF NOT EXISTS idx_vantage_sync_state_last_sync_time
  ON vantage_sync_state(last_sync_time DESC);

-- ============================================
-- ENABLE RLS
-- ============================================

ALTER TABLE vantage_sync_state ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read sync state
CREATE POLICY "Allow authenticated read vantage_sync_state"
  ON vantage_sync_state
  FOR SELECT
  TO authenticated
  USING (true);

-- Allow service role to manage sync state
CREATE POLICY "Allow service role manage vantage_sync_state"
  ON vantage_sync_state
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- ============================================
-- ADD UPDATED_AT TRIGGER
-- ============================================

-- Reuse existing updated_at trigger function if it exists
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname='vantage_sync_state_updated_at') THEN
    CREATE TRIGGER vantage_sync_state_updated_at
      BEFORE UPDATE ON vantage_sync_state
      FOR EACH ROW
      EXECUTE FUNCTION moddatetime(updated_at);
  END IF;
EXCEPTION
  WHEN undefined_function THEN
    -- If moddatetime doesn't exist, create a simple trigger function
    CREATE OR REPLACE FUNCTION update_updated_at_column()
    RETURNS TRIGGER AS $func$
    BEGIN
      NEW.updated_at = now();
      RETURN NEW;
    END;
    $func$ LANGUAGE plpgsql;

    CREATE TRIGGER vantage_sync_state_updated_at
      BEFORE UPDATE ON vantage_sync_state
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
END $$;

-- ============================================
-- SEED INITIAL STATE
-- ============================================

INSERT INTO vantage_sync_state (resource, last_sync_status)
VALUES
  ('accounts', 'pending'),
  ('funds', 'pending')
ON CONFLICT (resource) DO NOTHING;

-- ============================================
-- VERIFICATION
-- ============================================

DO $$
DECLARE
  resource_count BIGINT;
BEGIN
  SELECT COUNT(*) INTO resource_count FROM vantage_sync_state;
  RAISE NOTICE 'Vantage sync state initialized with % resources', resource_count;
END $$;
