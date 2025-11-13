-- ============================================================================
-- [DATA-01] Add investor_id to Agreements Table
-- ============================================================================
-- PURPOSE: Enable investor-level commission agreements
--
-- NEW STRUCTURE:
-- - Agreement → Investor (via investor_id)
-- - Investor → Party (via introduced_by)
-- - Commission computation: Contribution → Investor → Agreement → Party
--
-- BENEFITS:
-- - Simpler: No complex party-deal mappings
-- - Accurate: Captures investor-specific terms
-- - Flexible: Each investor can have different equity %
-- ============================================================================

-- Add investor_id column to agreements table
ALTER TABLE agreements
ADD COLUMN IF NOT EXISTS investor_id BIGINT REFERENCES investors(id);

-- Create index for fast lookups
CREATE INDEX IF NOT EXISTS idx_agreements_investor_id
ON agreements(investor_id);

-- Show current agreements structure
SELECT
    '=== Current Agreements Structure ===' as section,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'agreements'
ORDER BY ordinal_position;

-- Show how many agreements we currently have (party-level from import)
SELECT
    '=== Current Agreements Count ===' as section,
    COUNT(*) as party_agreements,
    COUNT(DISTINCT party_id) as unique_parties
FROM agreements
WHERE kind = 'distributor_commission';

-- ============================================================================
-- ACCEPTANCE CRITERIA
-- ============================================================================
-- ✅ investor_id column exists in agreements table
-- ✅ Index created for performance
-- ✅ Column allows NULL (for party-level agreements if needed)
-- ✅ Foreign key constraint to investors table
