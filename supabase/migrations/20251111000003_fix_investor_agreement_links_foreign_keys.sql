-- ============================================================================
-- Migration: Fix Investor Agreement Links Foreign Key Type Mismatch
-- Date: 2025-11-11
-- Purpose: Change investor_id and introduced_by_party_id from UUID to BIGINT
--
-- Problem: investors.id and parties.id are BIGINT but investor_agreement_links
-- has UUID columns, causing type mismatch errors
-- ============================================================================

-- First check if there's any data
-- SELECT COUNT(*) FROM investor_agreement_links;

-- Fix investor_id
ALTER TABLE investor_agreement_links
DROP COLUMN IF EXISTS investor_id;

ALTER TABLE investor_agreement_links
ADD COLUMN investor_id BIGINT REFERENCES investors(id);

-- Fix introduced_by_party_id
ALTER TABLE investor_agreement_links
DROP COLUMN IF EXISTS introduced_by_party_id;

ALTER TABLE investor_agreement_links
ADD COLUMN introduced_by_party_id BIGINT REFERENCES parties(id);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_investor_agreement_links_investor_id
ON investor_agreement_links(investor_id);

CREATE INDEX IF NOT EXISTS idx_investor_agreement_links_party_id
ON investor_agreement_links(introduced_by_party_id);

-- Add helpful comments
COMMENT ON COLUMN investor_agreement_links.investor_id IS 'Foreign key to investors.id (BIGINT)';
COMMENT ON COLUMN investor_agreement_links.introduced_by_party_id IS 'Foreign key to parties.id (BIGINT)';

-- ============================================================================
-- Verification Queries (run after migration)
-- ============================================================================

-- Verify column types match
-- SELECT
--   'investors.id' as column_ref, data_type
-- FROM information_schema.columns
-- WHERE table_name = 'investors' AND column_name = 'id'
-- UNION ALL
-- SELECT
--   'investor_agreement_links.investor_id', data_type
-- FROM information_schema.columns
-- WHERE table_name = 'investor_agreement_links' AND column_name = 'investor_id'
-- UNION ALL
-- SELECT
--   'parties.id', data_type
-- FROM information_schema.columns
-- WHERE table_name = 'parties' AND column_name = 'id'
-- UNION ALL
-- SELECT
--   'investor_agreement_links.introduced_by_party_id', data_type
-- FROM information_schema.columns
-- WHERE table_name = 'investor_agreement_links' AND column_name = 'introduced_by_party_id';
-- Expected: All should be 'bigint'
