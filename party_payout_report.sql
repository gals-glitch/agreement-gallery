-- ============================================================================
-- PARTY PAYOUT REPORT
-- ============================================================================
-- Summary of commissions owed to each party (distributor/referrer)
-- Use this to generate payment reports for distributors
-- ============================================================================

-- ============================================================================
-- Option 1: Simple Summary (by party and status)
-- ============================================================================
SELECT
  c.party_id,
  p.name as party_name,
  c.status,
  COUNT(*) as commission_count,
  SUM(c.base_amount) as total_base,
  SUM(c.vat_amount) as total_vat,
  SUM(c.total_amount) as total_due,
  c.currency
FROM commissions c
LEFT JOIN parties p ON p.id = c.party_id
WHERE c.status IN ('approved', 'paid')
GROUP BY c.party_id, p.name, c.status, c.currency
ORDER BY p.name, c.status;

-- ============================================================================
-- Option 2: Detailed Summary with Date Range
-- ============================================================================
-- Replace $from and $to with actual dates, e.g., '2025-01-01' and '2025-12-31'
SELECT
  c.party_id,
  p.name as party_name,
  c.status,
  COUNT(*) as commission_count,
  SUM(c.base_amount) as total_base,
  SUM(c.vat_amount) as total_vat,
  SUM(c.total_amount) as total_due,
  MIN(c.computed_at) as first_commission_date,
  MAX(c.computed_at) as last_commission_date,
  c.currency
FROM commissions c
LEFT JOIN parties p ON p.id = c.party_id
WHERE c.status IN ('approved', 'paid')
  AND COALESCE(c.paid_at, c.approved_at)::date BETWEEN '2025-01-01' AND '2025-12-31'
GROUP BY c.party_id, p.name, c.status, c.currency
ORDER BY total_due DESC;

-- ============================================================================
-- Option 3: Per-Party Detail (drill-down for one party)
-- ============================================================================
-- Replace <PARTY_ID> with actual party ID (e.g., 1)
SELECT
  c.id as commission_id,
  p.name as party_name,
  i.name as investor_name,
  COALESCE(d.name, f.name) as fund_deal_name,
  c.base_amount,
  c.vat_amount,
  c.total_amount,
  c.status,
  c.computed_at,
  c.submitted_at,
  c.approved_at,
  c.paid_at,
  c.payment_ref
FROM commissions c
LEFT JOIN parties p ON p.id = c.party_id
LEFT JOIN investors i ON i.id = c.investor_id
LEFT JOIN deals d ON d.id = c.deal_id
LEFT JOIN funds f ON f.id = c.fund_id
WHERE c.party_id = 1  -- Change this to the party ID you want to drill down
  AND c.status IN ('approved', 'paid')
ORDER BY c.computed_at DESC;

-- ============================================================================
-- Option 4: Removed (commissions_summary view doesn't exist)
-- ============================================================================

-- ============================================================================
-- Option 4: Month-by-Month Breakdown
-- ============================================================================
SELECT
  p.name as party_name,
  DATE_TRUNC('month', c.computed_at) as month,
  COUNT(*) as commission_count,
  SUM(c.total_amount) as monthly_total,
  c.currency
FROM commissions c
LEFT JOIN parties p ON p.id = c.party_id
WHERE c.status IN ('approved', 'paid')
  AND c.computed_at >= DATE_TRUNC('year', CURRENT_DATE)  -- Current year
GROUP BY p.name, DATE_TRUNC('month', c.computed_at), c.currency
ORDER BY p.name, month DESC;

-- ============================================================================
-- Option 5: Export-Ready Format (CSV-friendly)
-- ============================================================================
-- Copy results and paste into Excel
SELECT
  p.name as "Party Name",
  i.name as "Investor Name",
  COALESCE(d.name, f.name) as "Fund/Deal",
  c.base_amount as "Commission Base ($)",
  c.vat_amount as "VAT ($)",
  c.total_amount as "Total Due ($)",
  c.status as "Status",
  c.computed_at::date as "Computed Date",
  c.approved_at::date as "Approved Date",
  c.paid_at::date as "Paid Date",
  c.payment_ref as "Payment Reference"
FROM commissions c
LEFT JOIN parties p ON p.id = c.party_id
LEFT JOIN investors i ON i.id = c.investor_id
LEFT JOIN deals d ON d.id = c.deal_id
LEFT JOIN funds f ON f.id = c.fund_id
WHERE c.status IN ('approved', 'paid')
ORDER BY p.name, c.computed_at DESC;

-- ============================================================================
-- Option 6: Payment Run (what needs to be paid)
-- ============================================================================
-- Show all APPROVED commissions that haven't been paid yet
SELECT
  p.name as party_name,
  COUNT(*) as pending_payment_count,
  SUM(c.total_amount) as amount_to_pay,
  MIN(c.approved_at)::date as oldest_approval_date,
  c.currency
FROM commissions c
LEFT JOIN parties p ON p.id = c.party_id
WHERE c.status = 'approved'
GROUP BY p.name, c.currency
ORDER BY amount_to_pay DESC;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check total commissions by status
SELECT
  status,
  COUNT(*) as count,
  SUM(total_amount) as total
FROM commissions
GROUP BY status
ORDER BY status;

-- Check which parties have commissions
SELECT
  p.name as party_name,
  COUNT(*) as commission_count,
  SUM(c.total_amount) as total_amount,
  MIN(c.status) as earliest_status,
  MAX(c.status) as latest_status
FROM commissions c
LEFT JOIN parties p ON p.id = c.party_id
GROUP BY p.name
ORDER BY commission_count DESC;

-- Find commissions without party links
SELECT COUNT(*)
FROM commissions c
WHERE c.party_id IS NULL;

-- Check for missing investor links
SELECT
  i.id,
  i.name,
  i.introduced_by,
  COUNT(c.id) as contribution_count
FROM investors i
LEFT JOIN contributions c ON c.investor_id = i.id
WHERE i.introduced_by IS NULL
  AND c.id IS NOT NULL
GROUP BY i.id, i.name, i.introduced_by
ORDER BY contribution_count DESC
LIMIT 20;
