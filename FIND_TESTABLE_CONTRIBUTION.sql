-- Find contributions from investors who have agreements
-- This will give us a contribution we can actually compute a charge for

SELECT
  c.id as contribution_id,
  c.investor_id,
  i.name as investor_name,
  c.amount,
  c.currency,
  c.paid_in_date,
  a.id as agreement_id,
  a.status as agreement_status,
  a.fund_id as agreement_fund_id,
  a.deal_id as agreement_deal_id
FROM contributions c
JOIN investors i ON c.investor_id = i.id
JOIN agreements a ON (
  a.party_id = c.investor_id
  AND (
    (c.deal_id IS NOT NULL AND a.deal_id = c.deal_id)
    OR (c.fund_id IS NOT NULL AND a.fund_id = c.fund_id)
  )
)
ORDER BY c.id
LIMIT 10;

-- If the above returns results but status != 'APPROVED',
-- approve one using the agreement_id from the results:
-- UPDATE agreements SET status = 'APPROVED' WHERE id = XX;
