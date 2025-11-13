-- ============================================================
-- 05_VERIFICATION: COMMISSIONS SYSTEM READINESS REPORT
-- ============================================================
-- Purpose: Comprehensive verification of commission system setup
-- Sections:
--   1. Data Inventory (Parties, Investors, Deals, Contributions)
--   2. Investor-Party Linkage Status
--   3. Agreement Coverage Analysis
--   4. Commission Computation Readiness
--   5. Agreement Overlap Validation
--   6. Recent Payouts Summary (Last 30 days)
--   7. System Health Checks
-- ============================================================

\echo '============================================================'
\echo 'COMMISSIONS SYSTEM VERIFICATION REPORT'
\echo '============================================================'
\echo ''

-- ============================================================
-- SECTION 1: DATA INVENTORY
-- ============================================================
\echo '1. DATA INVENTORY'
\echo '------------------------------------------------------------'

SELECT 'Parties' as entity, COUNT(*) as total, COUNT(*) FILTER (WHERE active = true) as active FROM parties
UNION ALL
SELECT 'Investors', COUNT(*), COUNT(*) FILTER (WHERE is_active = true) FROM investors
UNION ALL
SELECT 'Funds', COUNT(*), COUNT(*) FILTER (WHERE status = 'active') FROM funds
UNION ALL
SELECT 'Deals', COUNT(*), COUNT(*) FILTER (WHERE status = 'active') FROM deals
UNION ALL
SELECT 'Contributions', COUNT(*), SUM(amount) FROM contributions
UNION ALL
SELECT 'Agreements', COUNT(*), COUNT(*) FILTER (WHERE status = 'APPROVED') FROM agreements
UNION ALL
SELECT 'Commissions', COUNT(*), SUM(total_amount) FROM commissions;

\echo ''

-- ============================================================
-- SECTION 2: INVESTOR-PARTY LINKAGE STATUS
-- ============================================================
\echo '2. INVESTOR-PARTY LINKAGE STATUS'
\echo '------------------------------------------------------------'

SELECT
  'With Party Link' as status,
  COUNT(*) as investor_count,
  ROUND(100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM investors), 0), 1) as percentage
FROM investors
WHERE introduced_by_party_id IS NOT NULL

UNION ALL

SELECT
  'Without Party Link',
  COUNT(*),
  ROUND(100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM investors), 0), 1)
FROM investors
WHERE introduced_by_party_id IS NULL;

\echo ''
\echo 'Top Parties by Investor Count:'

SELECT
  p.name as party_name,
  p.party_type,
  COUNT(i.id) as investor_count,
  SUM(CASE WHEN i.is_active THEN 1 ELSE 0 END) as active_investors
FROM parties p
LEFT JOIN investors i ON i.introduced_by_party_id = p.id
GROUP BY p.id, p.name, p.party_type
HAVING COUNT(i.id) > 0
ORDER BY investor_count DESC
LIMIT 10;

\echo ''

-- ============================================================
-- SECTION 3: AGREEMENT COVERAGE ANALYSIS
-- ============================================================
\echo '3. AGREEMENT COVERAGE ANALYSIS'
\echo '------------------------------------------------------------'

SELECT
  'APPROVED Agreements' as agreement_status,
  COUNT(*) as count
FROM agreements
WHERE status = 'APPROVED'

UNION ALL

SELECT 'DRAFT Agreements', COUNT(*)
FROM agreements
WHERE status = 'DRAFT'

UNION ALL

SELECT 'AWAITING_APPROVAL', COUNT(*)
FROM agreements
WHERE status = 'AWAITING_APPROVAL'

UNION ALL

SELECT 'SUPERSEDED', COUNT(*)
FROM agreements
WHERE status = 'SUPERSEDED';

\echo ''
\echo 'Agreement Coverage by Scope:'

SELECT
  scope,
  COUNT(*) as total_agreements,
  COUNT(*) FILTER (WHERE status = 'APPROVED') as approved,
  COUNT(*) FILTER (WHERE status = 'DRAFT') as draft
FROM agreements
GROUP BY scope
ORDER BY scope;

\echo ''

-- ============================================================
-- SECTION 4: COMMISSION COMPUTATION READINESS
-- ============================================================
\echo '4. COMMISSION COMPUTATION READINESS'
\echo '------------------------------------------------------------'

-- Contributions with party links and approved agreements
WITH eligible_contributions AS (
  SELECT
    c.id,
    c.investor_id,
    c.deal_id,
    c.fund_id,
    i.introduced_by_party_id,
    EXISTS (
      SELECT 1 FROM agreements a
      WHERE a.party_id = i.introduced_by_party_id
        AND (
          (a.deal_id = c.deal_id AND a.deal_id IS NOT NULL) OR
          (a.fund_id = c.fund_id AND a.fund_id IS NOT NULL)
        )
        AND a.status = 'APPROVED'
        AND c.paid_in_date >= a.effective_from
        AND (a.effective_to IS NULL OR c.paid_in_date <= a.effective_to)
    ) as has_agreement
  FROM contributions c
  INNER JOIN investors i ON i.id = c.investor_id
  WHERE i.introduced_by_party_id IS NOT NULL
)
SELECT
  'Eligible (Has Party + Agreement)' as readiness_status,
  COUNT(*) FILTER (WHERE has_agreement) as contribution_count,
  ROUND(100.0 * COUNT(*) FILTER (WHERE has_agreement) / NULLIF(COUNT(*), 0), 1) as percentage
FROM eligible_contributions

UNION ALL

SELECT
  'Has Party Link, No Agreement',
  COUNT(*) FILTER (WHERE NOT has_agreement),
  ROUND(100.0 * COUNT(*) FILTER (WHERE NOT has_agreement) / NULLIF(COUNT(*), 0), 1)
FROM eligible_contributions;

\echo ''
\echo 'Already Computed Commissions:'

SELECT
  status,
  COUNT(*) as commission_count,
  SUM(base_amount) as total_base,
  SUM(vat_amount) as total_vat,
  SUM(total_amount) as total_amount
FROM commissions
GROUP BY status
ORDER BY
  CASE status
    WHEN 'paid' THEN 1
    WHEN 'approved' THEN 2
    WHEN 'pending' THEN 3
    WHEN 'draft' THEN 4
    WHEN 'rejected' THEN 5
    ELSE 6
  END;

\echo ''

-- ============================================================
-- SECTION 5: AGREEMENT OVERLAP VALIDATION
-- ============================================================
\echo '5. AGREEMENT OVERLAP VALIDATION'
\echo '------------------------------------------------------------'
\echo 'Checking for overlapping agreement date ranges...'

WITH overlaps AS (
  SELECT
    a1.id as agreement_1_id,
    a2.id as agreement_2_id,
    a1.party_id,
    p.name as party_name,
    a1.deal_id,
    a1.fund_id,
    d.name as deal_name,
    a1.effective_from as start_1,
    COALESCE(a1.effective_to, '9999-12-31'::date) as end_1,
    a2.effective_from as start_2,
    COALESCE(a2.effective_to, '9999-12-31'::date) as end_2
  FROM agreements a1
  INNER JOIN agreements a2
    ON a1.party_id = a2.party_id
    AND (
      (a1.deal_id = a2.deal_id AND a1.deal_id IS NOT NULL) OR
      (a1.fund_id = a2.fund_id AND a1.fund_id IS NOT NULL)
    )
    AND a1.id < a2.id
  LEFT JOIN parties p ON p.id = a1.party_id
  LEFT JOIN deals d ON d.id = a1.deal_id
  WHERE a1.status IN ('APPROVED', 'AWAITING_APPROVAL')
    AND a2.status IN ('APPROVED', 'AWAITING_APPROVAL')
    AND a1.effective_from <= COALESCE(a2.effective_to, '9999-12-31'::date)
    AND COALESCE(a1.effective_to, '9999-12-31'::date) >= a2.effective_from
)
SELECT
  CASE WHEN COUNT(*) = 0 THEN '✅ No overlaps detected' ELSE '❌ OVERLAPS FOUND' END as validation_result,
  COUNT(*) as overlap_count
FROM overlaps;

\echo ''

SELECT
  agreement_1_id,
  agreement_2_id,
  party_name,
  deal_name,
  start_1,
  end_1,
  start_2,
  end_2
FROM (
  SELECT
    a1.id as agreement_1_id,
    a2.id as agreement_2_id,
    p.name as party_name,
    d.name as deal_name,
    a1.effective_from as start_1,
    COALESCE(a1.effective_to, '9999-12-31'::date) as end_1,
    a2.effective_from as start_2,
    COALESCE(a2.effective_to, '9999-12-31'::date) as end_2
  FROM agreements a1
  INNER JOIN agreements a2
    ON a1.party_id = a2.party_id
    AND (
      (a1.deal_id = a2.deal_id AND a1.deal_id IS NOT NULL) OR
      (a1.fund_id = a2.fund_id AND a1.fund_id IS NOT NULL)
    )
    AND a1.id < a2.id
  LEFT JOIN parties p ON p.id = a1.party_id
  LEFT JOIN deals d ON d.id = a1.deal_id
  WHERE a1.status IN ('APPROVED', 'AWAITING_APPROVAL')
    AND a2.status IN ('APPROVED', 'AWAITING_APPROVAL')
    AND a1.effective_from <= COALESCE(a2.effective_to, '9999-12-31'::date)
    AND COALESCE(a1.effective_to, '9999-12-31'::date) >= a2.effective_from
) overlaps
LIMIT 20;

\echo ''

-- ============================================================
-- SECTION 6: RECENT PAYOUTS SUMMARY (LAST 30 DAYS)
-- ============================================================
\echo '6. RECENT PAYOUTS SUMMARY (Last 30 Days)'
\echo '------------------------------------------------------------'

SELECT
  p.name as party_name,
  COUNT(c.id) as commission_count,
  SUM(c.base_amount) as total_base,
  SUM(c.vat_amount) as total_vat,
  SUM(c.total_amount) as total_payout,
  MAX(c.paid_at) as last_payment_date
FROM commissions c
INNER JOIN parties p ON p.id = c.party_id
WHERE c.status = 'paid'
  AND c.paid_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY p.id, p.name
ORDER BY total_payout DESC
LIMIT 20;

\echo ''
\echo 'Payout Status Summary (Last 30 Days):'

SELECT
  status,
  COUNT(*) as count,
  SUM(total_amount) as total
FROM commissions
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY status
ORDER BY
  CASE status
    WHEN 'paid' THEN 1
    WHEN 'approved' THEN 2
    WHEN 'pending' THEN 3
    WHEN 'draft' THEN 4
    WHEN 'rejected' THEN 5
    ELSE 6
  END;

\echo ''

-- ============================================================
-- SECTION 7: SYSTEM HEALTH CHECKS
-- ============================================================
\echo '7. SYSTEM HEALTH CHECKS'
\echo '------------------------------------------------------------'

-- Check for orphaned records
SELECT
  'Orphaned Investors' as check_name,
  COUNT(*) as issue_count,
  CASE WHEN COUNT(*) = 0 THEN '✅ OK' ELSE '⚠️ Issues Found' END as status
FROM investors i
LEFT JOIN parties p ON p.id = i.introduced_by_party_id
WHERE i.introduced_by_party_id IS NOT NULL AND p.id IS NULL

UNION ALL

SELECT
  'Orphaned Agreements',
  COUNT(*),
  CASE WHEN COUNT(*) = 0 THEN '✅ OK' ELSE '⚠️ Issues Found' END
FROM agreements a
LEFT JOIN parties p ON p.id = a.party_id
WHERE p.id IS NULL

UNION ALL

SELECT
  'Orphaned Commissions',
  COUNT(*),
  CASE WHEN COUNT(*) = 0 THEN '✅ OK' ELSE '⚠️ Issues Found' END
FROM commissions c
LEFT JOIN parties p ON p.id = c.party_id
WHERE p.id IS NULL;

\echo ''
\echo '============================================================'
\echo 'END OF VERIFICATION REPORT'
\echo '============================================================'
