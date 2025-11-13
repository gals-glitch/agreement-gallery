-- ============================================
-- Verification: Coverage gaps
-- ============================================
-- Shows investors who HAVE party links but are MISSING agreements
-- for specific deals they've contributed to
-- These need COV-01 (seed missing agreements) or manual agreement creation

SELECT
  i.id AS investor_id,
  i.name AS investor_name,
  p.id AS party_id,
  p.name AS party_name,
  d.id AS deal_id,
  d.name AS deal_name,
  COUNT(c.id) AS contributions_blocked,
  SUM(c.amount) AS total_blocked_amount,
  MIN(c.paid_in_date) AS earliest_contribution_date
FROM contributions c
JOIN investors i ON i.id = c.investor_id
JOIN parties p ON p.id = i.introduced_by_party_id  -- Has party link
JOIN deals d ON d.id = c.deal_id
LEFT JOIN agreements a ON a.party_id = i.introduced_by_party_id
                      AND a.deal_id = c.deal_id
                      AND a.status = 'APPROVED'
LEFT JOIN commissions m ON m.contribution_id = c.id
WHERE a.id IS NULL  -- Missing agreement for this (party, deal)
  AND m.id IS NULL  -- No commission exists yet
GROUP BY i.id, i.name, p.id, p.name, d.id, d.name
ORDER BY contributions_blocked DESC, total_blocked_amount DESC;

-- Summary by party
SELECT
  p.name AS party_name,
  COUNT(DISTINCT d.id) AS deals_missing_agreements,
  COUNT(DISTINCT i.id) AS affected_investors,
  COUNT(c.id) AS total_blocked_contributions,
  SUM(c.amount) AS total_blocked_amount
FROM contributions c
JOIN investors i ON i.id = c.investor_id
JOIN parties p ON p.id = i.introduced_by_party_id
JOIN deals d ON d.id = c.deal_id
LEFT JOIN agreements a ON a.party_id = i.introduced_by_party_id
                      AND a.deal_id = c.deal_id
                      AND a.status = 'APPROVED'
LEFT JOIN commissions m ON m.contribution_id = c.id
WHERE a.id IS NULL
  AND m.id IS NULL
GROUP BY p.id, p.name
ORDER BY total_blocked_contributions DESC;
