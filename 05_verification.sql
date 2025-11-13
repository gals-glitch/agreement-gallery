-- ============================================================
-- STEP 5: Verification & Party Payout Reports
-- ============================================================
-- Purpose: Verify commissions data and generate payout reports
-- Time: 5 minutes
-- ============================================================

-- PART A: COMMISSION STATE VERIFICATION
-- ============================================================

-- 1. Recent commissions (last 5)
SELECT
    id,
    party_id,
    investor_id,
    deal_id,
    fund_id,
    status,
    base_amount,
    vat_amount,
    total_amount,
    currency,
    computed_at,
    submitted_at,
    approved_at,
    paid_at,
    payment_ref
FROM commissions
ORDER BY updated_at DESC
LIMIT 5;

-- 2. Commission status breakdown
SELECT
    status,
    COUNT(*) as count,
    SUM(total_amount) as total_amount,
    currency
FROM commissions
GROUP BY status, currency
ORDER BY status;

-- 3. Commissions by party
SELECT
    party_id,
    party_name,
    COUNT(*) as commission_count,
    SUM(base_amount) as total_base,
    SUM(vat_amount) as total_vat,
    SUM(total_amount) as total_due,
    currency
FROM commissions
GROUP BY party_id, party_name, currency
ORDER BY total_due DESC;

-- PART B: PARTY PAYOUT REPORTS
-- ============================================================

-- 4. Party payout summary (this week) - APPROVED + PAID
SELECT
    party_id,
    party_name,
    status,
    COUNT(*) as commission_count,
    SUM(total_amount) as total_due,
    currency
FROM commissions
WHERE status IN ('approved', 'paid')
  AND paid_at::date BETWEEN CURRENT_DATE - 7 AND CURRENT_DATE
GROUP BY party_id, party_name, status, currency
ORDER BY party_name, status;

-- 5. Outstanding payouts (APPROVED but not PAID)
SELECT
    party_id,
    party_name,
    COUNT(*) as outstanding_count,
    SUM(total_amount) as outstanding_amount,
    currency,
    MIN(approved_at) as oldest_approval,
    MAX(approved_at) as newest_approval
FROM commissions
WHERE status = 'approved'
GROUP BY party_id, party_name, currency
ORDER BY outstanding_amount DESC;

-- 6. Paid commissions (for accounting)
SELECT
    party_id,
    party_name,
    id as commission_id,
    total_amount,
    currency,
    payment_ref,
    paid_at,
    approved_at,
    deal_id,
    fund_id
FROM commissions
WHERE status = 'paid'
ORDER BY paid_at DESC;

-- PART C: DETAILED PAYOUT REPORT (CSV EXPORT READY)
-- ============================================================

-- 7. Detailed party payout report (for finance team)
SELECT
    p.name as "Party Name",
    c.status as "Status",
    COUNT(c.id) as "# Commissions",
    SUM(c.base_amount) as "Base Amount",
    SUM(c.vat_amount) as "VAT Amount",
    SUM(c.total_amount) as "Total Due",
    c.currency as "Currency",
    STRING_AGG(DISTINCT d.name, ', ') as "Deals",
    MIN(c.approved_at)::date as "First Approval",
    MAX(c.approved_at)::date as "Last Approval"
FROM commissions c
JOIN parties p ON c.party_id = p.id
LEFT JOIN deals d ON c.deal_id = d.id
WHERE c.status IN ('approved', 'paid')
GROUP BY p.name, c.status, c.currency
ORDER BY p.name, c.status;

-- PART D: DATA QUALITY CHECKS
-- ============================================================

-- 8. Check for commissions missing party names
SELECT COUNT(*)
FROM commissions
WHERE party_name IS NULL;
-- Expected: 0

-- 9. Check for commissions with invalid amounts
SELECT COUNT(*)
FROM commissions
WHERE total_amount <= 0 OR base_amount <= 0;
-- Expected: 0

-- 10. Check for paid commissions missing payment_ref
SELECT COUNT(*)
FROM commissions
WHERE status = 'paid' AND payment_ref IS NULL;
-- Expected: 0

-- 11. Check for approved commissions missing approved_by
SELECT COUNT(*)
FROM commissions
WHERE status IN ('approved', 'paid') AND approved_by IS NULL;
-- Expected: 0

-- PART E: TIMELINE ANALYSIS
-- ============================================================

-- 12. Average time from computed to paid (in days)
SELECT
    AVG(EXTRACT(EPOCH FROM (paid_at - computed_at)) / 86400) as avg_days_to_payment,
    MIN(EXTRACT(EPOCH FROM (paid_at - computed_at)) / 86400) as min_days,
    MAX(EXTRACT(EPOCH FROM (paid_at - computed_at)) / 86400) as max_days
FROM commissions
WHERE status = 'paid';

-- 13. Commissions by day (last 7 days)
SELECT
    computed_at::date as date,
    COUNT(*) as commissions_computed,
    SUM(total_amount) as total_amount,
    currency
FROM commissions
WHERE computed_at >= CURRENT_DATE - 7
GROUP BY computed_at::date, currency
ORDER BY date DESC;

-- PART F: SNAPSHOT VALIDATION
-- ============================================================

-- 14. Verify snapshots are present
SELECT
    COUNT(*) as total_commissions,
    COUNT(snapshot_json) as with_snapshot,
    COUNT(*) - COUNT(snapshot_json) as missing_snapshot
FROM commissions;
-- Expected: missing_snapshot = 0

-- 15. Sample snapshot data (verify structure)
SELECT
    id,
    party_name,
    snapshot_json->'kind' as agreement_kind,
    snapshot_json->'terms' as terms_array,
    snapshot_json->'scope' as scope
FROM commissions
LIMIT 3;

-- ============================================================
-- ✅ SUCCESS: Verification complete
-- ============================================================
-- All queries should return expected results
-- Next: Test UI at http://localhost:8081/commissions
-- ============================================================
