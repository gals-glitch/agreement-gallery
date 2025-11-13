-- Migration: Fund Editor Extended Fields
-- Purpose: Add meta_json and additional fields for Fund Editor (Vantage-style)
-- Date: 2025-10-16
-- Supports: Fund Information, Fund Profile, Fees Earned, Wire Instructions, etc.

-- ============================================
-- DEALS: Add missing fields + meta_json
-- ============================================

-- Add structured columns for commonly queried fields
ALTER TABLE deals ADD COLUMN IF NOT EXISTS short_name TEXT;
ALTER TABLE deals ADD COLUMN IF NOT EXISTS tax_id TEXT;
ALTER TABLE deals ADD COLUMN IF NOT EXISTS is_fund_raising BOOLEAN DEFAULT false;
ALTER TABLE deals ADD COLUMN IF NOT EXISTS account TEXT;
ALTER TABLE deals ADD COLUMN IF NOT EXISTS city TEXT;
ALTER TABLE deals ADD COLUMN IF NOT EXISTS state TEXT;
ALTER TABLE deals ADD COLUMN IF NOT EXISTS zip TEXT;
ALTER TABLE deals ADD COLUMN IF NOT EXISTS country TEXT;
ALTER TABLE deals ADD COLUMN IF NOT EXISTS region TEXT;
ALTER TABLE deals ADD COLUMN IF NOT EXISTS inception_date DATE;
ALTER TABLE deals ADD COLUMN IF NOT EXISTS fund_size NUMERIC;
ALTER TABLE deals ADD COLUMN IF NOT EXISTS currency TEXT DEFAULT 'USD';
ALTER TABLE deals ADD COLUMN IF NOT EXISTS side_letters TEXT;
ALTER TABLE deals ADD COLUMN IF NOT EXISTS notes_extra TEXT;
ALTER TABLE deals ADD COLUMN IF NOT EXISTS property_mgmt_company TEXT;
ALTER TABLE deals ADD COLUMN IF NOT EXISTS general_contractor TEXT;
ALTER TABLE deals ADD COLUMN IF NOT EXISTS beds INT;
ALTER TABLE deals ADD COLUMN IF NOT EXISTS cum_of_closing NUMERIC;
ALTER TABLE deals ADD COLUMN IF NOT EXISTS exclude_financial_reports BOOLEAN DEFAULT false;
ALTER TABLE deals ADD COLUMN IF NOT EXISTS exclude_sreo BOOLEAN DEFAULT false;
ALTER TABLE deals ADD COLUMN IF NOT EXISTS exit_date DATE;
ALTER TABLE deals ADD COLUMN IF NOT EXISTS sale_price NUMERIC;
ALTER TABLE deals ADD COLUMN IF NOT EXISTS closing_letter_notes TEXT;

-- Add meta_json for flexible field storage (profile, fees, wire instructions, etc.)
ALTER TABLE deals ADD COLUMN IF NOT EXISTS meta_json JSONB NOT NULL DEFAULT '{}';

COMMENT ON COLUMN deals.short_name IS 'Short name/code for the deal';
COMMENT ON COLUMN deals.is_fund_raising IS 'Is this deal currently raising funds';
COMMENT ON COLUMN deals.cum_of_closing IS 'Cumulative amount of all closings (auto-computed from deal_closes)';
COMMENT ON COLUMN deals.exclude_financial_reports IS 'Exclude from financial reports if true';
COMMENT ON COLUMN deals.exclude_sreo IS 'Exclude from SREO reports if true';
COMMENT ON COLUMN deals.meta_json IS 'Flexible storage for: Fund Profile (strategy, risk_profile, net_purchase_price, project_cost), Fees Earned (preferred_return, carried_interest, admin_fee, am_fee, promote_earned, is_promote_final), Wire Instructions, and other custom fields';

-- ============================================
-- DEAL CLOSES: Add detailed fields for grid
-- ============================================

ALTER TABLE deal_closes ADD COLUMN IF NOT EXISTS close_number INT;
ALTER TABLE deal_closes ADD COLUMN IF NOT EXISTS buligo_gp_direct NUMERIC;
ALTER TABLE deal_closes ADD COLUMN IF NOT EXISTS buligo_lp_direct NUMERIC;
ALTER TABLE deal_closes ADD COLUMN IF NOT EXISTS buligo_lp_feeder NUMERIC;
ALTER TABLE deal_closes ADD COLUMN IF NOT EXISTS total_deal_equity NUMERIC;
ALTER TABLE deal_closes ADD COLUMN IF NOT EXISTS total_capitalization NUMERIC;

COMMENT ON COLUMN deal_closes.close_number IS 'Close sequence number (e.g., 1 for "Close 1")';
COMMENT ON COLUMN deal_closes.buligo_gp_direct IS 'Buligo GP contribution (direct)';
COMMENT ON COLUMN deal_closes.buligo_lp_direct IS 'Buligo LP contribution (direct)';
COMMENT ON COLUMN deal_closes.buligo_lp_feeder IS 'Buligo LP contribution (feeder)';
COMMENT ON COLUMN deal_closes.total_deal_equity IS 'Total deal equity for this close';
COMMENT ON COLUMN deal_closes.total_capitalization IS 'Total capitalization for this close';

-- ============================================
-- INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_deals_short_name ON deals(short_name);
CREATE INDEX IF NOT EXISTS idx_deals_inception_date ON deals(inception_date);
CREATE INDEX IF NOT EXISTS idx_deal_closes_close_number ON deal_closes(deal_id, close_number);

-- ============================================
-- CONSTRAINTS
-- ============================================

-- Ensure close_number is unique per deal
ALTER TABLE deal_closes DROP CONSTRAINT IF EXISTS deal_closes_unique_close_number;
ALTER TABLE deal_closes ADD CONSTRAINT deal_closes_unique_close_number
  UNIQUE(deal_id, close_number);

COMMENT ON CONSTRAINT deal_closes_unique_close_number ON deal_closes IS 'Prevents duplicate close numbers (e.g., two "Close 1" entries for the same deal)';

-- ============================================
-- FUNCTION: Auto-compute cum_of_closing
-- ============================================

CREATE OR REPLACE FUNCTION update_deal_cum_of_closing()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE deals
  SET cum_of_closing = (
    SELECT COALESCE(SUM(amount_value), 0)
    FROM deal_closes
    WHERE deal_id = COALESCE(NEW.deal_id, OLD.deal_id)
  ),
  updated_at = now()
  WHERE id = COALESCE(NEW.deal_id, OLD.deal_id);

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_deal_cum_of_closing IS 'Automatically updates cum_of_closing when deal_closes change';

-- ============================================
-- TRIGGERS
-- ============================================

DROP TRIGGER IF EXISTS trigger_update_cum_of_closing ON deal_closes;
CREATE TRIGGER trigger_update_cum_of_closing
  AFTER INSERT OR UPDATE OR DELETE ON deal_closes
  FOR EACH ROW
  EXECUTE FUNCTION update_deal_cum_of_closing();

COMMENT ON TRIGGER trigger_update_cum_of_closing ON deal_closes IS 'Recalculates cum_of_closing whenever closings are added/updated/deleted';
