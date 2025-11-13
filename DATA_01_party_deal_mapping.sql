-- ============================================================================
-- [DATA-01] Party → Deal Mapping
-- ============================================================================
-- PURPOSE: Map each distributor (party) to the specific deal(s) their
--          commission agreement applies to
--
-- INSTRUCTIONS:
-- 1. Fill in the party_name and deal_id pairs below
-- 2. Use the actual party names from your imported parties
-- 3. Use deal IDs from the deals table (2-100, not placeholder deal_id=1)
-- 4. If a party has agreements with multiple deals, add multiple rows
--
-- EXAMPLE:
--   ('Kuperman', 2),          -- Kuperman's agreement applies to BULCC LLC
--   ('Kuperman', 5),          -- Kuperman also has an agreement for deal 5
--   ('Shai Sheffer', 3),      -- Shai Sheffer's agreement for BULMF LLC
--
-- ============================================================================

-- Create temporary mapping table
CREATE TEMP TABLE tmp_party_deal_map(
    party_name TEXT,
    deal_id BIGINT
);

-- ============================================================================
-- INSERT YOUR PARTY → DEAL MAPPINGS HERE
-- ============================================================================
-- Replace the examples below with your actual mappings

INSERT INTO tmp_party_deal_map (party_name, deal_id) VALUES
-- EXAMPLE ROWS - REPLACE THESE WITH YOUR ACTUAL DATA:
('Kuperman', 2),
('Shai Sheffer', 3),
('Yoram Dvash', 4);
-- ('Cross Arch Holdings -David Kirchenbaum', 5),
-- ('Ronnie Maliniak', 6),
-- ... continue for all 57 parties ...

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check how many mappings were loaded
SELECT
    '=== Mapping Summary ===' as section,
    COUNT(*) as total_mappings,
    COUNT(DISTINCT party_name) as unique_parties,
    COUNT(DISTINCT deal_id) as unique_deals
FROM tmp_party_deal_map;

-- Show sample mappings with resolved party IDs and deal names
SELECT
    '=== Sample Mappings ===' as section,
    m.party_name,
    p.id as party_id,
    m.deal_id,
    d.name as deal_name
FROM tmp_party_deal_map m
LEFT JOIN parties p ON p.name = m.party_name
LEFT JOIN deals d ON d.id = m.deal_id
ORDER BY m.party_name, m.deal_id
LIMIT 20;

-- Check for parties that don't exist in parties table
SELECT
    '=== Parties Not Found ===' as section,
    m.party_name,
    m.deal_id
FROM tmp_party_deal_map m
LEFT JOIN parties p ON p.name = m.party_name
WHERE p.id IS NULL;

-- Check for invalid deal IDs
SELECT
    '=== Invalid Deal IDs ===' as section,
    m.party_name,
    m.deal_id
FROM tmp_party_deal_map m
LEFT JOIN deals d ON d.id = m.deal_id
WHERE d.id IS NULL;

-- ============================================================================
-- NOTES
-- ============================================================================
-- After verifying the mappings look correct, proceed to DATA_02 script
-- to update the actual agreements table
