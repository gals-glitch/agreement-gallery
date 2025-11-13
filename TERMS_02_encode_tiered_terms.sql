-- ============================================================================
-- [TERMS-02] Encode Tiered Commission Terms in Agreement Snapshots
-- ============================================================================
-- PURPOSE: Update snapshot_json to include all 4 commission rate tiers
--          based on deal close date windows
--
-- COMMISSION STRUCTURE:
-- - Distributor gets X% of investor's equity (e.g., Kuperman = 1% = 100 bps)
-- - The COMMISSION on that equity varies by deal close date:
--     * Before Feb 1, 2018:           25% of equity (2500 bps)
--     * Feb 1, 2018 - Dec 12, 2019:   27% of equity (2700 bps)
--     * Dec 12, 2019 - Oct 31, 2020:  30% of equity (3000 bps)
--     * After Oct 31, 2020:           35% of equity (3500 bps)
--
-- EXAMPLE: Kuperman (1% equity holder)
-- - If deal closed Nov 15, 2020 → falls in Tier 4 (35%)
-- - Kuperman earns 35% of his 1% equity position
-- - On a $100k contribution: $100k * 0.01 * 0.35 = $350 commission
--
-- PREREQUISITES:
-- 1. Run DATA_02 first (agreements mapped to real deals)
-- 2. Run TERMS_01 first (deals have close_date populated)
-- ============================================================================

-- Show current agreements before update
SELECT
    '=== Current Agreement Structure ===' as section,
    p.name as party_name,
    d.id as deal_id,
    d.name as deal_name,
    d.close_date,
    a.snapshot_json->'terms'->0->>'rate_bps' as current_rate_bps,
    jsonb_array_length(a.snapshot_json->'terms') as terms_count
FROM agreements a
INNER JOIN parties p ON p.id = a.party_id
LEFT JOIN deals d ON d.id = a.deal_id
WHERE a.kind = 'distributor_commission'
ORDER BY p.name
LIMIT 10;

-- ============================================================================
-- UPDATE ALL COMMISSION AGREEMENTS WITH TIERED TERMS
-- ============================================================================

UPDATE agreements a
SET
    snapshot_json = jsonb_build_object(
        'kind', 'distributor_commission',
        'party_id', a.party_id::TEXT,
        'party_name', p.name,
        'scope', jsonb_build_object(
            'fund_id', NULL,
            'deal_id', a.deal_id
        ),
        'terms', jsonb_build_array(
            -- Tier 1: Before Feb 1, 2018 → 25% commission
            jsonb_build_object(
                'from', NULL,
                'to', '2018-02-01',
                'rate_bps', 2500,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
            -- Tier 2: Feb 1, 2018 - Dec 12, 2019 → 27% commission
            jsonb_build_object(
                'from', '2018-02-01',
                'to', '2019-12-12',
                'rate_bps', 2700,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
            -- Tier 3: Dec 12, 2019 - Oct 31, 2020 → 30% commission
            jsonb_build_object(
                'from', '2019-12-12',
                'to', '2020-10-31',
                'rate_bps', 3000,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
            -- Tier 4: After Oct 31, 2020 → 35% commission
            jsonb_build_object(
                'from', '2020-10-31',
                'to', NULL,
                'rate_bps', 3500,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            )
        ),
        'vat_admin_snapshot', jsonb_build_object(
            'jurisdiction', 'IL',
            'rate', 0.17,
            'effective_at', a.effective_from::TEXT
        )
    ),
    updated_at = NOW()
FROM parties p
WHERE a.party_id = p.id
  AND a.kind = 'distributor_commission';

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Show updated agreements with all 4 tiers
SELECT
    '=== Updated Tiered Agreements ===' as section,
    p.name as party_name,
    d.id as deal_id,
    d.name as deal_name,
    d.close_date,
    jsonb_array_length(a.snapshot_json->'terms') as tier_count,
    a.snapshot_json->'terms'->0->>'rate_bps' as tier1_rate,
    a.snapshot_json->'terms'->1->>'rate_bps' as tier2_rate,
    a.snapshot_json->'terms'->2->>'rate_bps' as tier3_rate,
    a.snapshot_json->'terms'->3->>'rate_bps' as tier4_rate
FROM agreements a
INNER JOIN parties p ON p.id = a.party_id
LEFT JOIN deals d ON d.id = a.deal_id
WHERE a.kind = 'distributor_commission'
ORDER BY p.name
LIMIT 20;

-- Show which tier would be selected for each deal
SELECT
    '=== Tier Selection by Deal ===' as section,
    d.id as deal_id,
    d.name as deal_name,
    d.close_date,
    CASE
        WHEN d.close_date < '2018-02-01' THEN 'Tier 1: 2500 bps (25%)'
        WHEN d.close_date >= '2018-02-01' AND d.close_date < '2019-12-12' THEN 'Tier 2: 2700 bps (27%)'
        WHEN d.close_date >= '2019-12-12' AND d.close_date < '2020-10-31' THEN 'Tier 3: 3000 bps (30%)'
        WHEN d.close_date >= '2020-10-31' THEN 'Tier 4: 3500 bps (35%)'
        ELSE 'No close date - ERROR'
    END as selected_tier,
    COUNT(a.id) as agreement_count
FROM deals d
INNER JOIN agreements a ON a.deal_id = d.id
WHERE a.kind = 'distributor_commission'
GROUP BY d.id, d.name, d.close_date
ORDER BY d.close_date;

-- Sample: Show full snapshot for Kuperman's agreement
SELECT
    '=== Sample: Kuperman Agreement Snapshot ===' as section,
    p.name as party_name,
    d.name as deal_name,
    d.close_date,
    jsonb_pretty(a.snapshot_json) as full_snapshot
FROM agreements a
INNER JOIN parties p ON p.id = a.party_id
LEFT JOIN deals d ON d.id = a.deal_id
WHERE a.kind = 'distributor_commission'
  AND p.name = 'Kuperman'
LIMIT 1;

-- Count of agreements by tier
SELECT
    '=== Agreement Distribution by Tier ===' as section,
    jsonb_array_length(snapshot_json->'terms') as terms_count,
    COUNT(*) as agreement_count
FROM agreements
WHERE kind = 'distributor_commission'
GROUP BY jsonb_array_length(snapshot_json->'terms');

-- ============================================================================
-- ACCEPTANCE CRITERIA
-- ============================================================================
-- ✅ All commission agreements have exactly 4 terms in snapshot_json
-- ✅ Terms array contains rate_bps: 2500, 2700, 3000, 3500
-- ✅ Each term has from/to date boundaries matching the tier windows
-- ✅ Each term has vat_mode='on_top' and vat_rate=0.17
-- ✅ Sample query shows correct tier would be selected for known deal dates
