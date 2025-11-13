-- Migration: Create import infrastructure (staging tables + audit)
-- Ticket: IMP-01
-- Date: 2025-11-02

BEGIN;

-- ============================================
-- 1. Create import_runs audit table
-- ============================================

CREATE TABLE IF NOT EXISTS import_runs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity TEXT NOT NULL CHECK (entity IN ('parties', 'investors', 'agreements', 'contributions')),
  mode TEXT NOT NULL CHECK (mode IN ('preview', 'commit')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  created_by TEXT,
  stats JSONB DEFAULT '{}'::jsonb,
  errors JSONB DEFAULT '[]'::jsonb,
  batch_id TEXT,
  notes TEXT
);

COMMENT ON TABLE import_runs IS 'Audit log for CSV imports (preview + commit)';
COMMENT ON COLUMN import_runs.stats IS 'Summary: {insert, update, skip, errors, matches: {exact, fuzzy}}';
COMMENT ON COLUMN import_runs.errors IS 'Array of row-level errors: [{row, field, message}]';

CREATE INDEX IF NOT EXISTS idx_import_runs_entity_created
  ON import_runs(entity, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_import_runs_batch
  ON import_runs(batch_id);

-- ============================================
-- 2. Create staging tables
-- ============================================

-- Staging: Parties
CREATE TABLE IF NOT EXISTS stg_parties (
  id SERIAL PRIMARY KEY,
  import_run_id UUID REFERENCES import_runs(id),
  row_number INT,
  name TEXT,
  email TEXT,
  notes TEXT,
  validation_status TEXT CHECK (validation_status IN ('valid', 'invalid', 'warning')),
  validation_errors JSONB DEFAULT '[]'::jsonb,
  match_status TEXT CHECK (match_status IN ('exact', 'fuzzy', 'new', 'ambiguous')),
  matched_party_id BIGINT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Staging: Investors
CREATE TABLE IF NOT EXISTS stg_investors (
  id SERIAL PRIMARY KEY,
  import_run_id UUID REFERENCES import_runs(id),
  row_number INT,
  name TEXT,
  email TEXT,
  introduced_by TEXT,  -- Party name from CSV
  notes TEXT,
  validation_status TEXT CHECK (validation_status IN ('valid', 'invalid', 'warning')),
  validation_errors JSONB DEFAULT '[]'::jsonb,
  match_status TEXT CHECK (match_status IN ('exact', 'fuzzy', 'new', 'ambiguous')),
  matched_investor_id BIGINT,
  matched_party_id BIGINT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Staging: Agreements
CREATE TABLE IF NOT EXISTS stg_agreements (
  id SERIAL PRIMARY KEY,
  import_run_id UUID REFERENCES import_runs(id),
  row_number INT,
  party_name TEXT,
  deal_name TEXT,
  effective_from DATE,
  effective_to DATE,
  pricing_mode TEXT,
  rate_bps INT,
  vat_mode TEXT,
  vat_rate DECIMAL(5,4),
  kind TEXT,
  validation_status TEXT CHECK (validation_status IN ('valid', 'invalid', 'warning')),
  validation_errors JSONB DEFAULT '[]'::jsonb,
  match_status TEXT CHECK (match_status IN ('exact', 'fuzzy', 'new', 'ambiguous')),
  matched_party_id BIGINT,
  matched_deal_id BIGINT,
  matched_agreement_id BIGINT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Staging: Contributions
CREATE TABLE IF NOT EXISTS stg_contributions (
  id SERIAL PRIMARY KEY,
  import_run_id UUID REFERENCES import_runs(id),
  row_number INT,
  investor_name TEXT,
  deal_name TEXT,
  fund_name TEXT,
  amount DECIMAL(15,2),
  paid_in_date DATE,
  currency TEXT,
  validation_status TEXT CHECK (validation_status IN ('valid', 'invalid', 'warning')),
  validation_errors JSONB DEFAULT '[]'::jsonb,
  match_status TEXT CHECK (match_status IN ('exact', 'fuzzy', 'new', 'ambiguous')),
  matched_investor_id BIGINT,
  matched_deal_id BIGINT,
  matched_fund_id BIGINT,
  matched_contribution_id BIGINT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 3. Create indexes on staging tables
-- ============================================

CREATE INDEX IF NOT EXISTS idx_stg_parties_import_run
  ON stg_parties(import_run_id);

CREATE INDEX IF NOT EXISTS idx_stg_investors_import_run
  ON stg_investors(import_run_id);

CREATE INDEX IF NOT EXISTS idx_stg_agreements_import_run
  ON stg_agreements(import_run_id);

CREATE INDEX IF NOT EXISTS idx_stg_contributions_import_run
  ON stg_contributions(import_run_id);

-- ============================================
-- 4. Create helper function for fuzzy party matching
-- ============================================

CREATE OR REPLACE FUNCTION resolve_party_id(party_name TEXT)
RETURNS BIGINT AS $$
DECLARE
  party_id BIGINT;
BEGIN
  -- Try exact match first
  SELECT id INTO party_id FROM parties WHERE name = party_name LIMIT 1;
  IF party_id IS NOT NULL THEN
    RETURN party_id;
  END IF;

  -- Try party_aliases
  SELECT pa.party_id INTO party_id
  FROM party_aliases pa
  WHERE pa.alias = party_name
  LIMIT 1;

  RETURN party_id;  -- NULL if not found
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 5. Create helper function for fuzzy deal matching
-- ============================================

CREATE OR REPLACE FUNCTION resolve_deal_id(deal_name TEXT)
RETURNS BIGINT AS $$
DECLARE
  deal_id BIGINT;
BEGIN
  -- Try exact match first
  SELECT id INTO deal_id FROM deals WHERE name = deal_name LIMIT 1;
  IF deal_id IS NOT NULL THEN
    RETURN deal_id;
  END IF;

  -- Try code match
  SELECT id INTO deal_id FROM deals WHERE code = deal_name LIMIT 1;
  IF deal_id IS NOT NULL THEN
    RETURN deal_id;
  END IF;

  -- Try prefix match (LIKE 'name%')
  SELECT id INTO deal_id FROM deals WHERE name LIKE deal_name || '%' LIMIT 1;

  RETURN deal_id;  -- NULL if not found
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 6. Grant permissions (RLS handled by Edge Function service_role)
-- ============================================

-- Import tables are internal/admin only, accessed via service_role
COMMENT ON TABLE stg_parties IS 'Staging table for party CSV imports (admin only)';
COMMENT ON TABLE stg_investors IS 'Staging table for investor CSV imports (admin only)';
COMMENT ON TABLE stg_agreements IS 'Staging table for agreement CSV imports (admin only)';
COMMENT ON TABLE stg_contributions IS 'Staging table for contribution CSV imports (admin only)';

COMMIT;

-- ============================================
-- Verification queries
-- ============================================

-- Check tables created
-- SELECT table_name FROM information_schema.tables
-- WHERE table_schema = 'public'
--   AND table_name LIKE 'stg_%' OR table_name = 'import_runs'
-- ORDER BY table_name;

-- Check functions created
-- SELECT routine_name FROM information_schema.routines
-- WHERE routine_schema = 'public'
--   AND routine_name LIKE 'resolve_%'
-- ORDER BY routine_name;
