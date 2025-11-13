-- ============================================
-- Simple Reset: Restore Credits to Full Amount
-- ============================================

-- Get the investor_id first
SELECT investor_id FROM charges WHERE id = 'a0fb4b54-5e29-437b-beaf-99e4f2bcc4bd';

-- Reset all credits for this investor to zero applied_amount
-- (This restores full available_amount since available = original - applied)
UPDATE credits_ledger
SET applied_amount = 0
WHERE investor_id = (
    SELECT investor_id FROM charges WHERE id = 'a0fb4b54-5e29-437b-beaf-99e4f2bcc4bd'
);

-- Delete all credit applications for this charge
-- (Clean slate - the trigger will recreate them on submit)
DELETE FROM credit_applications
WHERE charge_id = (
    SELECT numeric_id FROM charges WHERE id = 'a0fb4b54-5e29-437b-beaf-99e4f2bcc4bd'
);

-- Reset charge to DRAFT
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

-- Verify the reset
SELECT
    'CREDITS AFTER RESET' as status,
    id,
    investor_id,
    original_amount,
    applied_amount,
    available_amount,
    status
FROM credits_ledger
WHERE investor_id = (
    SELECT investor_id FROM charges WHERE id = 'a0fb4b54-5e29-437b-beaf-99e4f2bcc4bd'
);

SELECT
    'CHARGE AFTER RESET' as status,
    id,
    status,
    total_amount,
    credits_applied_amount,
    net_amount
FROM charges
WHERE id = 'a0fb4b54-5e29-437b-beaf-99e4f2bcc4bd';

SELECT
    'APPLICATIONS AFTER RESET' as status,
    COUNT(*) as count
FROM credit_applications
WHERE charge_id = (
    SELECT numeric_id FROM charges WHERE id = 'a0fb4b54-5e29-437b-beaf-99e4f2bcc4bd'
);
