-- ========================================
-- Check Current Charge State
-- ========================================

-- Check the charge
SELECT
    id,
    status,
    total_amount,
    credits_applied_amount,
    net_amount,
    submitted_at,
    approved_at,
    paid_at
FROM charges
WHERE id = 'a0fb4b54-5e29-437b-beaf-99e4f2bcc4bd';

-- Check credit applications
SELECT
    ca.id,
    ca.credit_id,
    ca.amount_applied,
    ca.applied_at,
    ca.reversed_at
FROM credit_applications ca
WHERE ca.charge_id = (SELECT numeric_id FROM charges WHERE id = 'a0fb4b54-5e29-437b-beaf-99e4f2bcc4bd');

-- Check credit balance
SELECT
    id,
    original_amount,
    applied_amount,
    available_amount,
    status
FROM credits_ledger
WHERE id = 2;

-- ========================================
-- RESET CHARGE TO DRAFT (if needed)
-- ========================================
-- Only uncomment and run if charge is not in DRAFT state

-- Step 1: Delete any credit applications
-- DELETE FROM credit_applications
-- WHERE charge_id = (SELECT numeric_id FROM charges WHERE id = 'a0fb4b54-5e29-437b-beaf-99e4f2bcc4bd');

-- Step 2: Reset credit to full amount
-- UPDATE credits_ledger
-- SET applied_amount = 0, status = 'AVAILABLE'
-- WHERE id = 2;

-- Step 3: Reset charge to DRAFT
-- UPDATE charges
-- SET
--   status = 'DRAFT',
--   submitted_at = NULL,
--   approved_at = NULL,
--   approved_by = NULL,
--   rejected_at = NULL,
--   rejected_by = NULL,
--   reject_reason = NULL,
--   paid_at = NULL,
--   payment_ref = NULL,
--   credits_applied_amount = 0,
--   net_amount = total_amount
-- WHERE id = 'a0fb4b54-5e29-437b-beaf-99e4f2bcc4bd';

-- Step 4: Verify reset
-- SELECT id, status, credits_applied_amount, net_amount FROM charges WHERE id = 'a0fb4b54-5e29-437b-beaf-99e4f2bcc4bd';
-- SELECT id, available_amount FROM credits_ledger WHERE id = 2;
