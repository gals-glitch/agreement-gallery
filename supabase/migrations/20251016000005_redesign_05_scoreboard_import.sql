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
