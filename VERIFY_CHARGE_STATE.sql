-- ========================================
-- Move 1.4: Verify Charge Workflow State
-- ========================================
-- Run after Admin JWT workflow test
-- Date: 2025-10-21

-- Replace with your charge UUID
\set CHARGE_UUID 'a0fb4b54-5e29-437b-beaf-99e4f2bcc4bd'

-- ========================================
-- 1. Verify Charge State
-- ========================================

SELECT
    id,
    status,
    submitted_at,
    approved_at,
    paid_at,
    total_amount,
    credits_applied_amount,
    net_amount,
    payment_ref
FROM charges
WHERE id = :'CHARGE_UUID';

-- Expected output:
-- status: PAID
-- submitted_at: <timestamp>
-- approved_at: <timestamp>
-- paid_at: <timestamp>
-- total_amount: 600.00
-- credits_applied_amount: 500.00
-- net_amount: 100.00
-- payment_ref: WIRE-DEMO-001

-- ========================================
-- 2. Verify Credit Applications
-- ========================================

SELECT
    ca.id,
    ca.credit_id,
    ca.amount_applied,
    ca.applied_by,
    ca.applied_at,
    ca.reversed_at,
    cl.original_amount,
    cl.applied_amount as credit_total_applied,
    cl.available_amount as credit_available
FROM credit_applications ca
JOIN credits_ledger cl ON ca.credit_id = cl.id
WHERE ca.charge_id = (SELECT numeric_id FROM charges WHERE id = :'CHARGE_UUID')
ORDER BY ca.applied_at;

-- Expected output:
-- credit_id: 2
-- amount_applied: 500.00
-- applied_by: <admin_user_id or NULL for service key>
-- reversed_at: NULL (not reversed)
-- credit_total_applied: 500.00
-- credit_available: 0.00

-- ========================================
-- 3. Verify Credits Ledger
-- ========================================

SELECT
    id,
    investor_id,
    original_amount,
    applied_amount,
    available_amount,
    status
FROM credits_ledger
WHERE investor_id = (SELECT investor_id FROM charges WHERE id = :'CHARGE_UUID')
ORDER BY id;

-- Expected output:
-- id: 2
-- original_amount: 500.00
-- applied_amount: 500.00
-- available_amount: 0.00
-- status: FULLY_APPLIED

-- ========================================
-- 4. Verify Audit Log Entries
-- ========================================

SELECT
    al.action,
    al.entity_type,
    al.entity_id,
    al.actor_id,
    u.email as actor_email,
    al.payload->>'status_from' as from_status,
    al.payload->>'status_to' as to_status,
    al.created_at
FROM audit_log al
LEFT JOIN auth.users u ON al.actor_id = u.id
WHERE al.entity_type = 'charge'
  AND al.entity_id = (SELECT numeric_id FROM charges WHERE id = :'CHARGE_UUID')
ORDER BY al.created_at DESC;

-- Expected output (3+ entries):
-- charge.marked_paid  | <charge_id> | <admin_uuid> | admin@example.com | APPROVED | PAID     | 2025-10-21 ...
-- charge.approved     | <charge_id> | <admin_uuid> | admin@example.com | PENDING  | APPROVED | 2025-10-21 ...
-- charge.submitted    | <charge_id> | <admin_uuid> | admin@example.com | DRAFT    | PENDING  | 2025-10-21 ...

-- ========================================
-- 5. Summary Report
-- ========================================

WITH charge_summary AS (
    SELECT
        c.id,
        c.status,
        c.total_amount,
        c.credits_applied_amount,
        c.net_amount,
        COUNT(ca.id) as credit_applications,
        SUM(ca.amount_applied) as total_credits_applied
    FROM charges c
    LEFT JOIN credit_applications ca ON ca.charge_id = c.numeric_id
    WHERE c.id = :'CHARGE_UUID'
    GROUP BY c.id, c.status, c.total_amount, c.credits_applied_amount, c.net_amount
)
SELECT
    '✅ Charge Workflow Complete' as test_result,
    status,
    total_amount,
    credits_applied_amount,
    net_amount,
    credit_applications,
    total_credits_applied,
    CASE
        WHEN status = 'PAID' THEN '✅ PASS'
        ELSE '❌ FAIL'
    END as status_check,
    CASE
        WHEN credits_applied_amount = total_credits_applied THEN '✅ PASS'
        ELSE '❌ FAIL'
    END as credits_check
FROM charge_summary;

-- Expected output:
-- test_result: ✅ Charge Workflow Complete
-- status: PAID
-- status_check: ✅ PASS
-- credits_check: ✅ PASS
