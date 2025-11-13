-- ============================================================
-- FIND ELIGIBLE CONTRIBUTIONS FOR COMMISSION COMPUTATION
-- ============================================================
-- Purpose: Identify contributions that can have commissions computed
-- Criteria:
--   1. Investor has introduced_by_party_id set
--   2. Approved agreement exists for (party, deal)
--   3. Contribution paid_in_date falls within agreement effective dates
-- ============================================================

SELECT
  c.id as contribution_id,
  i.id as investor_id,
  i.name as investor_name,
  i.introduced_by_party_id as party_id,
  p.name as party_name,
  c.deal_id,
  d.name as deal_name,
  c.fund_id,
  f.name as fund_name,
  c.amount as contribution_amount,
  c.paid_in_date,
  a.id as agreement_id,
  a.pricing_mode,
  a.status as agreement_status
FROM contributions c
INNER JOIN investors i ON i.id = c.investor_id
INNER JOIN parties p ON p.id = i.introduced_by_party_id
LEFT JOIN deals d ON d.id = c.deal_id
LEFT JOIN funds f ON f.id = c.fund_id
INNER JOIN agreements a ON a.party_id = i.introduced_by_party_id
  AND (
    (a.deal_id = c.deal_id AND a.deal_id IS NOT NULL) OR
    (a.fund_id = c.fund_id AND a.fund_id IS NOT NULL)
  )
  AND a.status = 'APPROVED'
  AND c.paid_in_date >= a.effective_from
  AND (a.effective_to IS NULL OR c.paid_in_date <= a.effective_to)
WHERE i.introduced_by_party_id IS NOT NULL
ORDER BY c.id;

-- Summary statistics
SELECT
  'Total eligible contributions' as metric,
  COUNT(*) as count
FROM contributions c
INNER JOIN investors i ON i.id = c.investor_id
INNER JOIN agreements a ON a.party_id = i.introduced_by_party_id
  AND (
    (a.deal_id = c.deal_id AND a.deal_id IS NOT NULL) OR
    (a.fund_id = c.fund_id AND a.fund_id IS NOT NULL)
  )
  AND a.status = 'APPROVED'
  AND c.paid_in_date >= a.effective_from
  AND (a.effective_to IS NULL OR c.paid_in_date <= a.effective_to)
WHERE i.introduced_by_party_id IS NOT NULL;
