-- ============================================================================
-- [DATA-02] Update Commission Agreements to Correct Deals
-- ============================================================================
-- PURPOSE: Replace placeholder deal_id=1 with actual deal IDs from mapping
--
-- PREREQUISITES:
-- 1. Run DATA_01_party_deal_mapping.sql first to create tmp_party_deal_map
-- 2. Verify the mapping looks correct
--
-- WHAT THIS DOES:
-- - Updates all 57 distributor commission agreements
-- - Sets deal_id from the tmp_party_deal_map
-- - Ensures scope='DEAL' and fund_id=NULL
-- - Only affects agreements with placeholder deal_id=1
-- ============================================================================

-- Show current state BEFORE update
SELECT
    '=== BEFORE Update ===' as section,
    COUNT(*) as agreements_with_placeholder
FROM agreements
WHERE kind='distributor_commission' AND deal_id=1;

-- Perform the update
UPDATE agreements a
SET
    deal_id = m.deal_id::BIGINT,
    fund_id = NULL,
    scope = 'DEAL'::agreement_scope,
    updated_at = NOW()
FROM tmp_party_deal_map m
INNER JOIN parties p ON p.name = m.party_name
WHERE a.kind = 'distributor_commission'
  AND a.party_id = p.id
  AND a.deal_id = 1;  -- Only update placeholders

-- Show results AFTER update
SELECT
    '=== AFTER Update ===' as section,
    COUNT(*) as agreements_still_with_placeholder
FROM agreements
WHERE kind='distributor_commission' AND deal_id=1;

-- Show updated agreements with deal names
SELECT
    '=== Updated Agreements ===' as section,
    p.name as party_name,
    a.deal_id,
    d.name as deal_name,
    (a.snapshot_json->'terms'->0->>'rate_bps')::INTEGER as rate_bps,
    a.effective_from,
    a.status
FROM agreements a
INNER JOIN parties p ON p.id = a.party_id
LEFT JOIN deals d ON d.id = a.deal_id
WHERE a.kind = 'distributor_commission'
  AND a.deal_id != 1
  AND a.updated_at >= (NOW() - INTERVAL '5 minutes')
ORDER BY p.name, d.name;

-- Final verification: Should be ZERO
SELECT
    '=== Final Check ===' as section,
    CASE
        WHEN COUNT(*) = 0 THEN 'SUCCESS: All agreements mapped to real deals'
        ELSE 'WARNING: ' || COUNT(*) || ' agreements still have placeholder deal_id=1'
    END as result
FROM agreements
WHERE kind='distributor_commission' AND deal_id=1;

-- ============================================================================
-- ACCEPTANCE CRITERIA
-- ============================================================================
-- ✅ Zero agreements with deal_id=1 for kind='distributor_commission'
-- ✅ All agreements have valid deal_id pointing to real deals
-- ✅ All agreements have scope='DEAL' and fund_id=NULL
