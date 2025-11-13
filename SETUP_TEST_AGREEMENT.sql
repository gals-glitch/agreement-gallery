-- Step 1: Check agreements table schema
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'agreements'
ORDER BY ordinal_position;

-- Step 2: Find contributions that need agreements
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
JOIN investors i ON c.investor_id = i.id
LEFT JOIN funds f ON c.fund_id = f.id
LEFT JOIN deals d ON c.deal_id = d.id
ORDER BY c.id
LIMIT 5;

-- Step 3: Check if any agreements exist at all
SELECT COUNT(*) as total_agreements FROM agreements;

-- Step 4: Check existing agreements (if any)
SELECT
  id,
  party_id,
  status,
  scope,
  fund_id,
  deal_id,
  pricing_mode,
  vat_included,
  effective_from,
  effective_to
FROM agreements
LIMIT 5;

-- Step 5: Create a test agreement for contribution 1 (investor 201)
-- ONLY RUN THIS AFTER REVIEWING RESULTS ABOVE
-- Uncomment when ready:
/*
INSERT INTO agreements (
  party_id,
  fund_id,
  deal_id,
  status,
  scope,
  pricing_mode,
  vat_included,
  effective_from,
  effective_to
)
VALUES (
  201, -- investor_id from contribution 1 (Rakefet Kuperman)
  1,   -- fund_id (adjust based on contribution data)
  NULL, -- deal_id (adjust if contribution is deal-level)
  'APPROVED',
  'FUND', -- or 'DEAL' based on contribution scope
  'CUSTOM',
  false,
  '2024-01-01',
  NULL
)
RETURNING *;
*/
