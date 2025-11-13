-- Get a contribution ID for testing the compute endpoint
-- Run this in Supabase SQL Editor to get a contribution ID

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
  d.name as deal_name
FROM contributions c
LEFT JOIN investors i ON c.investor_id = i.id
LEFT JOIN funds f ON c.fund_id = f.id
LEFT JOIN deals d ON c.deal_id = d.id
LIMIT 5;

-- Copy one of the contribution_id values to use in the test
