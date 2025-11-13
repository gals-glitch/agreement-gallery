-- ============================================================
-- TRACK C7: UI VERIFICATION QUERIES
-- Commissions MVP Demo
-- ============================================================

-- 1. Verify feature flag is enabled
SELECT key, enabled, enabled_for_roles
FROM feature_flags
WHERE key = 'commissions_engine';

-- 2. Check if any commissions exist
SELECT
  status,
  COUNT(*) as count,
  SUM(base_amount) as total_base,
  SUM(vat_amount) as total_vat,
  SUM(total_amount) as total_amount
FROM commissions
GROUP BY status
ORDER BY
  CASE status
    WHEN 'draft' THEN 1
    WHEN 'pending' THEN 2
    WHEN 'approved' THEN 3
    WHEN 'paid' THEN 4
    WHEN 'rejected' THEN 5
  END;

-- 3. Data readiness summary
SELECT
  'Parties' as entity,
  COUNT(*) as count
FROM parties WHERE active = true
UNION ALL
SELECT 'Investors', COUNT(*) FROM investors
UNION ALL
SELECT 'Investors with party links', COUNT(*) FROM investors WHERE introduced_by_party_id IS NOT NULL
UNION ALL
SELECT 'Agreements (commission)', COUNT(*) FROM agreements WHERE kind = 'distributor_commission'
UNION ALL
SELECT 'Contributions', COUNT(*) FROM contributions
UNION ALL
SELECT 'Contributions ready for compute', COUNT(DISTINCT c.id)
FROM contributions c
JOIN investors i ON c.investor_id = i.id
JOIN agreements a ON a.party_id = i.introduced_by_party_id
  AND a.deal_id = c.deal_id
  AND a.status = 'APPROVED'
WHERE i.introduced_by_party_id IS NOT NULL;

-- 4. Sample contributions ready for commission computation
SELECT
  c.id as contribution_id,
  p.name as party_name,
  i.name as investor_name,
  d.name as deal_name,
  c.amount,
  c.paid_in_date,
  a.id as agreement_id
FROM contributions c
JOIN investors i ON c.investor_id = i.id
JOIN parties p ON i.introduced_by_party_id = p.id
JOIN deals d ON c.deal_id = d.id
JOIN agreements a ON a.party_id = i.introduced_by_party_id
  AND a.deal_id = c.deal_id
  AND a.status = 'APPROVED'
WHERE i.introduced_by_party_id IS NOT NULL
ORDER BY c.id
LIMIT 10;
