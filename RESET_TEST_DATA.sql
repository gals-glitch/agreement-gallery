-- ============================================
-- Reset Test Data for T01+T02 Testing
-- ============================================

-- STEP 1: Check current state
SELECT
    'CHARGE' as entity,
    id,
    status,
    base_amount,
    vat_amount,
    total_amount,
    credits_applied_amount,
    net_amount,
    contribution_id
FROM charges
WHERE id = 'a0fb4b54-5e29-437b-beaf-99e4f2bcc4bd';

SELECT
    'CREDIT_APPLICATIONS' as entity,
    ca.id,
    ca.credit_id,
    ca.charge_id,
    ca.amount_applied,
    ca.reversed_at
FROM credit_applications ca
WHERE ca.charge_id = (
    SELECT numeric_id FROM charges WHERE id = 'a0fb4b54-5e29-437b-beaf-99e4f2bcc4bd'
);

SELECT
    'CREDITS' as entity,
    id,
    investor_id,
    original_amount,
    applied_amount,
    available_amount,
    status
FROM credits_ledger
WHERE investor_id = (
    SELECT investor_id FROM charges WHERE id = 'a0fb4b54-5e29-437b-beaf-99e4f2bcc4bd'
)
ORDER BY created_at ASC;

-- STEP 2: Reset the charge to DRAFT status
UPDATE charges
SET
    status = 'DRAFT',
    submitted_at = NULL,
    approved_at = NULL,
    approved_by = NULL,
    rejected_at = NULL,
    rejected_by = NULL,
    reject_reason = NULL,
    paid_at = NULL,
    payment_ref = NULL,
    credits_applied_amount = 0,
    net_amount = 0,
    updated_at = NOW()
WHERE id = 'a0fb4b54-5e29-437b-beaf-99e4f2bcc4bd';

-- STEP 3: Reverse all credit applications for this charge
-- Mark applications as reversed
UPDATE credit_applications
SET
    reversed_at = NOW(),
    reversed_by = NULL
WHERE charge_id = (
    SELECT numeric_id FROM charges WHERE id = 'a0fb4b54-5e29-437b-beaf-99e4f2bcc4bd'
)
AND reversed_at IS NULL;

-- STEP 4: Restore credit available amounts
-- Get all applications for this charge
WITH reversed_apps AS (
    SELECT credit_id, SUM(amount_applied) as total_reversed
    FROM credit_applications
    WHERE charge_id = (
        SELECT numeric_id FROM charges WHERE id = 'a0fb4b54-5e29-437b-beaf-99e4f2bcc4bd'
    )
    AND reversed_at IS NOT NULL
    GROUP BY credit_id
)
UPDATE credits_ledger cl
SET applied_amount = GREATEST(0, cl.applied_amount - ra.total_reversed)
FROM reversed_apps ra
WHERE cl.id = ra.credit_id;

-- STEP 5: Verify reset
SELECT
    'AFTER RESET - CHARGE' as entity,
    id,
    status,
    credits_applied_amount,
    net_amount
FROM charges
WHERE id = 'a0fb4b54-5e29-437b-beaf-99e4f2bcc4bd';

SELECT
    'AFTER RESET - CREDITS' as entity,
    id,
    original_amount,
    applied_amount,
    available_amount,
    status
FROM credits_ledger
WHERE investor_id = (
    SELECT investor_id FROM charges WHERE id = 'a0fb4b54-5e29-437b-beaf-99e4f2bcc4bd'
)
ORDER BY created_at ASC;
