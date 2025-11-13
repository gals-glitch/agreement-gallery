-- ============================================================
-- STEP 2: Fix Agreements → Deal Mapping
-- ============================================================
-- Purpose: Update commission agreements to point to correct deals
-- Current issue: All agreements are on deal_id=1
-- Time: 5-10 minutes
-- ============================================================

-- PART A: DISCOVERY - See what we have
-- ============================================================

-- 1. Check current commission agreements (all on deal_id=1?)
SELECT
    a.id as agreement_id,
    p.name as party_name,
    a.deal_id,
    a.fund_id,
    a.scope,
    a.status,
    a.kind
FROM agreements a
LEFT JOIN parties p ON a.party_id = p.id
WHERE a.kind = 'distributor_commission'
ORDER BY p.name;

-- 2. See all available parties
SELECT id, name, kind, status
FROM parties
WHERE status = 'ACTIVE'
ORDER BY name;

-- 3. See all available deals
SELECT id, name, status, created_at
FROM deals
WHERE status = 'ACTIVE'
ORDER BY id;

-- PART B: MAPPING - Update agreements to correct deals
-- ============================================================

-- Create temporary mapping table
CREATE TEMP TABLE _party_deal_map(party_name text, deal_id int);

-- INSERT YOUR PARTY → DEAL MAPPINGS HERE:
-- Copy the party names from PART A and assign the correct deal_id from PART A
-- Example:
-- INSERT INTO _party_deal_map VALUES
-- ('Kuperman', 2),
-- ('Partner Capital', 5),
-- ('Global Partners', 17),
-- ('ABC Advisors', 10);
-- ← Add more rows as needed

-- ⚠️ UNCOMMENT THE LINES ABOVE AND FILL IN YOUR ACTUAL MAPPINGS

-- PART C: EXECUTE UPDATE
-- ============================================================

-- Preview what will change (DRY RUN)
SELECT
    a.id as agreement_id,
    p.name as party_name,
    a.deal_id as current_deal_id,
    m.deal_id as new_deal_id,
    a.scope as current_scope
FROM agreements a
JOIN parties p ON a.party_id = p.id
JOIN _party_deal_map m ON p.name = m.party_name
WHERE a.kind = 'distributor_commission';

-- If preview looks good, execute the update:
-- UPDATE agreements a
-- SET deal_id = m.deal_id,
--     scope = 'DEAL',
--     fund_id = NULL
-- FROM _party_deal_map m
-- WHERE a.kind = 'distributor_commission'
--   AND a.party_id = (SELECT id FROM parties WHERE name = m.party_name);

-- ⚠️ UNCOMMENT THE UPDATE ABOVE AFTER VERIFYING THE PREVIEW

-- PART D: VERIFICATION
-- ============================================================

-- Verify agreements are now spread across different deals
SELECT
    a.deal_id,
    COUNT(*) as agreement_count,
    STRING_AGG(p.name, ', ') as parties
FROM agreements a
LEFT JOIN parties p ON a.party_id = p.id
WHERE a.kind = 'distributor_commission'
GROUP BY a.deal_id
ORDER BY a.deal_id;

-- Check no agreements are still orphaned on deal_id=1 (unless that's valid)
SELECT
    a.id,
    p.name as party_name,
    a.deal_id,
    a.status
FROM agreements a
LEFT JOIN parties p ON a.party_id = p.id
WHERE a.kind = 'distributor_commission'
  AND a.deal_id = 1;

-- ✅ SUCCESS: Agreements are now correctly mapped to their deals
-- Next: Run 03_compute_commissions.sql
