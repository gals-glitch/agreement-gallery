-- ============================================
-- Check what test data exists for T01+T02
-- ============================================

-- 1. Check contributions and their agreements
SELECT
    c.id AS contribution_id,
    c.investor_id,
    c.deal_id,
    c.amount,
    c.currency,
    a.id AS agreement_id,
    a.status AS agreement_status,
    a.snapshot_json->>'resolved_upfront_bps' AS upfront_bps,
    a.snapshot_json->>'vat_rate' AS vat_rate
FROM contributions c
LEFT JOIN agreements a ON a.party_id = c.investor_id
    AND a.deal_id = c.deal_id
    AND a.status = 'APPROVED'
WHERE c.id IN (1, 2, 3, 4, 5)
ORDER BY c.id;

-- 2. Check available credits
SELECT
    id,
    investor_id,
    deal_id,
    original_amount,
    available_amount,
    status,
    currency,
    created_at
FROM credits_ledger
WHERE status = 'AVAILABLE'
    AND available_amount > 0
ORDER BY investor_id, created_at;

-- 3. Check existing charges
SELECT
    id,
    contribution_id,
    investor_id,
    deal_id,
    status,
    base_amount,
    vat_amount,
    total_amount,
    credits_applied_amount,
    net_amount
FROM charges
ORDER BY created_at DESC
LIMIT 5;
