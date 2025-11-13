-- Find contributions that have approved agreements
-- This will help us test the /charges/compute endpoint

-- Option 1: Find contributions with approved agreements
SELECT
  c.id as contribution_id,
  c.investor_id,
  i.name as investor_name,
  c.amount,
  c.currency,
  c.paid_in_date,
  c.fund_id,
  f.name as fund_name,
  c.deal_id,
  d.name as deal_name,
  a.id as agreement_id,
  a.status as agreement_status
FROM contributions c
LEFT JOIN investors i ON c.investor_id = i.id
LEFT JOIN funds f ON c.fund_id = f.id
LEFT JOIN deals d ON c.deal_id = d.id
LEFT JOIN agreements a ON (
  a.party_id = c.investor_id
  AND (
    (c.deal_id IS NOT NULL AND a.deal_id = c.deal_id)
    OR (c.fund_id IS NOT NULL AND a.fund_id = c.fund_id)
  )
  AND a.status = 'APPROVED'
)
WHERE a.id IS NOT NULL
LIMIT 5;

-- Option 2: Check all agreements for investor 201 (Rakefet Kuperman)
SELECT
  id,
  party_id,
  status,
  scope,
  fund_id,
  deal_id,
  effective_from,
  effective_to
FROM agreements
WHERE party_id = 201;

-- Option 3: If no approved agreements exist, approve an existing one
-- (Replace 'AGREEMENT_ID' with actual ID from Option 2)
-- UPDATE agreements
-- SET status = 'APPROVED', approved_at = now(), approved_by = (SELECT id FROM auth.users WHERE email = 'gals@buligocapital.com')
-- WHERE id = AGREEMENT_ID;
