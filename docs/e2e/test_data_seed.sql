-- ============================================
-- E2E Test Data Seed (QA-03)
-- ============================================
-- Purpose: Create deterministic test data for E2E workflow tests
-- Date: 2025-10-21
-- ============================================

-- Cleanup: Remove existing test data (if exists)
DELETE FROM charges WHERE investor_id = 999;
DELETE FROM credit_applications WHERE charge_id IN (SELECT numeric_id FROM charges WHERE investor_id = 999);
DELETE FROM credits_ledger WHERE investor_id = 999;
DELETE FROM contributions WHERE investor_id = 999;
DELETE FROM agreements WHERE party_id = 999;
DELETE FROM investors WHERE id = 999;

-- ============================================
-- 1. Create Test Investor (party_id: 999)
-- ============================================
INSERT INTO investors (id, name, email, country, tax_id, active, notes, created_at, updated_at)
VALUES (
    999,
    'E2E Test Investor',
    'e2e.test@example.com',
    'US',
    'US-TAX-999',
    true,
    'Test investor for E2E workflow tests - DO NOT DELETE MANUALLY',
    NOW(),
    NOW()
)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    updated_at = NOW();

-- ============================================
-- 2. Create Test Agreement (agreement_id: 999)
-- ============================================
-- 100 bps upfront + 20% VAT
INSERT INTO agreements (
    id,
    party_id,
    scope,
    fund_id,
    deal_id,
    pricing_mode,
    selected_track,
    effective_from,
    effective_to,
    vat_included,
    status,
    created_by,
    created_at,
    updated_at,
    snapshot
)
VALUES (
    999,
    999,
    'DEAL',
    NULL,
    1, -- Assuming deal_id=1 exists
    'CUSTOM',
    NULL,
    '2025-01-01',
    NULL,
    false,
    'APPROVED',
    NULL,
    NOW(),
    NOW(),
    jsonb_build_object(
        'resolved_upfront_bps', 100,
        'resolved_deferred_bps', 0,
        'vat_rate', 0.20,
        'seed_version', 1,
        'approved_at', NOW()
    )
)
ON CONFLICT (id) DO UPDATE SET
    status = 'APPROVED',
    snapshot = EXCLUDED.snapshot,
    updated_at = NOW();

-- ============================================
-- 3. Create Test Contributions
-- ============================================
-- Contribution 999: $50,000 (main test contribution)
INSERT INTO contributions (
    id,
    investor_id,
    deal_id,
    fund_id,
    paid_in_date,
    amount,
    currency,
    fx_rate,
    source_batch,
    created_at
)
VALUES (
    999,
    999,
    1,
    NULL,
    '2025-10-01',
    50000.00,
    'USD',
    1.0,
    'E2E_TEST_BATCH',
    NOW()
)
ON CONFLICT (id) DO UPDATE SET
    amount = EXCLUDED.amount,
    paid_in_date = EXCLUDED.paid_in_date;

-- Contribution 998: $30,000 (for reject flow test)
INSERT INTO contributions (
    id,
    investor_id,
    deal_id,
    fund_id,
    paid_in_date,
    amount,
    currency,
    fx_rate,
    source_batch,
    created_at
)
VALUES (
    998,
    999,
    1,
    NULL,
    '2025-10-02',
    30000.00,
    'USD',
    1.0,
    'E2E_TEST_BATCH',
    NOW()
)
ON CONFLICT (id) DO UPDATE SET
    amount = EXCLUDED.amount,
    paid_in_date = EXCLUDED.paid_in_date;

-- Contributions 950-999: Batch test (50 contributions)
INSERT INTO contributions (
    id,
    investor_id,
    deal_id,
    fund_id,
    paid_in_date,
    amount,
    currency,
    fx_rate,
    source_batch,
    created_at
)
SELECT
    950 + n,
    999,
    1,
    NULL,
    '2025-10-10'::date + (n || ' days')::interval,
    10000.00 + (n * 100),
    'USD',
    1.0,
    'E2E_BATCH_TEST',
    NOW()
FROM generate_series(0, 49) AS n
ON CONFLICT (id) DO UPDATE SET
    amount = EXCLUDED.amount,
    paid_in_date = EXCLUDED.paid_in_date;

-- ============================================
-- 4. Create Test Credit (credit_id: 999)
-- ============================================
-- $500 available credit for investor 999
INSERT INTO credits_ledger (
    id,
    investor_id,
    deal_id,
    fund_id,
    reason,
    original_amount,
    available_amount,
    status,
    currency,
    created_at,
    created_by
)
VALUES (
    999,
    999,
    1,
    NULL,
    'E2E Test Credit - Initial balance for workflow tests',
    500.00,
    500.00,
    'ACTIVE',
    'USD',
    NOW(),
    NULL
)
ON CONFLICT (id) DO UPDATE SET
    available_amount = 500.00,
    status = 'ACTIVE';

-- ============================================
-- Summary
-- ============================================
SELECT
    'Seed data created successfully' AS status,
    (SELECT COUNT(*) FROM investors WHERE id = 999) AS investors_created,
    (SELECT COUNT(*) FROM agreements WHERE id = 999) AS agreements_created,
    (SELECT COUNT(*) FROM contributions WHERE investor_id = 999) AS contributions_created,
    (SELECT COUNT(*) FROM credits_ledger WHERE id = 999) AS credits_created;
