-- Find contributions that match the existing approved agreements
-- We have agreements for party_id=1 with deal_id IN (1, 2)

SELECT
  c.id as contribution_id,
  c.investor_id,
  i.name as investor_name,
  c.amount,
  c.currency,
  c.paid_in_date,
  c.fund_id,
  c.deal_id,
  a.id as agreement_id,
  a.status as agreement_status,
  a.scope as agreement_scope
FROM contributions c
JOIN investors i ON c.investor_id = i.id
JOIN agreements a ON (
  a.party_id = c.investor_id
  AND (
    (c.deal_id IS NOT NULL AND a.deal_id = c.deal_id)
    OR (c.fund_id IS NOT NULL AND a.fund_id = c.fund_id)
  )
)
WHERE a.status = 'APPROVED'
ORDER BY c.id
LIMIT 5;

-- Alternative: Check all contributions for investor 1
SELECT
  id as contribution_id,
  investor_id,
  amount,
  currency,
  paid_in_date,
  fund_id,
  deal_id
FROM contributions
WHERE investor_id = 1
ORDER BY id;
