-- ========================================
-- Move 1.4 - Final Workflow Verification
-- ========================================
-- Date: 2025-10-21
-- Purpose: Verify complete charge workflow (submit → approve → mark-paid)
-- Charge: a0fb4b54-5e29-437b-beaf-99e4f2bcc4bd

-- ========================================
-- 1. Charge Final State
-- ========================================
\echo '\n========================================';
\echo '1. CHARGE FINAL STATE';
\echo '========================================\n';

SELECT
    id,
    numeric_id,
    status,
    total_amount,
    credits_applied_amount,
    net_amount,
    currency,
    submitted_at,
    approved_at,
    approved_by,
    paid_at,
    payment_ref,
    created_at,
    updated_at
FROM charges
WHERE id = 'a0fb4b54-5e29-437b-beaf-99e4f2bcc4bd';

-- Expected Results:
-- status: PAID
-- total_amount: 600.00
-- credits_applied_amount: 500.00
-- net_amount: 100.00
-- payment_ref: WIRE-DEMO-001
-- All timestamps should be populated

-- ========================================
-- 2. Credit Applications
-- ========================================
\echo '\n========================================';
\echo '2. CREDIT APPLICATIONS (FIFO Order)';
\echo '========================================\n';

SELECT
    ca.id,
    ca.credit_id,
    ca.charge_id,
    ca.amount_applied,
    ca.applied_at,
    ca.reversed_at,
    cl.original_amount as credit_original,
    cl.applied_amount as credit_total_applied,
    cl.available_amount as credit_remaining,
    cl.status as credit_status
FROM credit_applications ca
JOIN credits_ledger cl ON ca.credit_id = cl.id
WHERE ca.charge_id = (SELECT numeric_id FROM charges WHERE id = 'a0fb4b54-5e29-437b-beaf-99e4f2bcc4bd')
ORDER BY ca.applied_at;

-- Expected Results:
-- Should show credit_id = 2 (oldest AVAILABLE credit)
-- amount_applied: 500.00
-- reversed_at: NULL (not reversed)
-- credit should be CONSUMED or AVAILABLE with reduced balance

-- ========================================
-- 3. Credits Ledger State
-- ========================================
\echo '\n========================================';
\echo '3. CREDITS LEDGER STATE';
\echo '========================================\n';

SELECT
    id,
    investor_id,
    original_amount,
    applied_amount,
    available_amount,
    status,
    currency,
    created_at,
    updated_at
FROM credits_ledger
WHERE id IN (
    SELECT credit_id
    FROM credit_applications
    WHERE charge_id = (SELECT numeric_id FROM charges WHERE id = 'a0fb4b54-5e29-437b-beaf-99e4f2bcc4bd')
)
ORDER BY id;

-- Expected Results:
-- Credit 2:
--   original_amount: 500.00
--   applied_amount: 500.00
--   available_amount: 0.00
--   status: CONSUMED

-- ========================================
-- 4. Audit Log Entries
-- ========================================
\echo '\n========================================';
\echo '4. AUDIT LOG (Workflow Events)';
\echo '========================================\n';

SELECT
    id,
    entity_type,
    entity_id,
    action,
    actor_id,
    actor_email,
    changes,
    timestamp,
    metadata
FROM audit_log
WHERE entity_type = 'charge'
  AND entity_id = 'a0fb4b54-5e29-437b-beaf-99e4f2bcc4bd'
ORDER BY timestamp;

-- Expected Results (in chronological order):
-- 1. charge_submitted
-- 2. charge_approved
-- 3. charge_paid

-- ========================================
-- 5. All Available Credits (Sanity Check)
-- ========================================
\echo '\n========================================';
\echo '5. ALL AVAILABLE CREDITS';
\echo '========================================\n';

SELECT
    id,
    investor_id,
    original_amount,
    applied_amount,
    available_amount,
    status,
    created_at
FROM credits_ledger
WHERE status = 'AVAILABLE'
  AND available_amount > 0
ORDER BY created_at;

-- Expected: Should show any remaining credits not yet applied

-- ========================================
-- 6. Workflow State Summary
-- ========================================
\echo '\n========================================';
\echo '6. WORKFLOW STATE SUMMARY';
\echo '========================================\n';

WITH charge_data AS (
    SELECT
        status,
        total_amount,
        credits_applied_amount,
        net_amount,
        CASE
            WHEN status = 'PAID' AND paid_at IS NOT NULL THEN 'COMPLETE'
            WHEN status = 'APPROVED' AND approved_at IS NOT NULL THEN 'APPROVED_PENDING_PAYMENT'
            WHEN status = 'PENDING' AND submitted_at IS NOT NULL THEN 'SUBMITTED_PENDING_APPROVAL'
            WHEN status = 'DRAFT' THEN 'NOT_SUBMITTED'
            ELSE 'INVALID_STATE'
        END as workflow_state
    FROM charges
    WHERE id = 'a0fb4b54-5e29-437b-beaf-99e4f2bcc4bd'
),
credit_summary AS (
    SELECT
        COUNT(*) as credits_applied_count,
        SUM(amount_applied) as total_credits_applied
    FROM credit_applications
    WHERE charge_id = (SELECT numeric_id FROM charges WHERE id = 'a0fb4b54-5e29-437b-beaf-99e4f2bcc4bd')
      AND reversed_at IS NULL
)
SELECT
    cd.status,
    cd.workflow_state,
    cd.total_amount,
    cd.credits_applied_amount,
    cd.net_amount,
    cs.credits_applied_count,
    cs.total_credits_applied,
    CASE
        WHEN cd.credits_applied_amount = cs.total_credits_applied THEN '✓ MATCH'
        ELSE '✗ MISMATCH'
    END as credit_reconciliation
FROM charge_data cd
CROSS JOIN credit_summary cs;

-- Expected Results:
-- status: PAID
-- workflow_state: COMPLETE
-- credits_applied_count: 1
-- total_credits_applied: 500.00
-- credit_reconciliation: ✓ MATCH

-- ========================================
-- VERIFICATION CHECKLIST
-- ========================================
--
-- ✓ Charge status is PAID
-- ✓ Total amount is 600.00
-- ✓ Credits applied amount is 500.00
-- ✓ Net amount is 100.00
-- ✓ Payment reference is WIRE-DEMO-001
-- ✓ All timestamps are populated (submitted_at, approved_at, paid_at)
-- ✓ Credit was applied via FIFO (oldest first)
-- ✓ Credit ledger shows credit 2 as CONSUMED
-- ✓ Credit application is NOT reversed
-- ✓ Audit log shows all three workflow events
-- ✓ Credit amounts reconcile between charge and applications
--
-- ========================================
