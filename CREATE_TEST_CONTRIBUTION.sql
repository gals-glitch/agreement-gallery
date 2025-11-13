-- Create a new test contribution for investor 201 to test credit workflow
-- This will be a second contribution from Rakefet Kuperman

INSERT INTO contributions (
  investor_id,
  fund_id,
  deal_id,
  amount,
  currency,
  paid_in_date
)
VALUES (
  201,                -- investor_id (Rakefet Kuperman)
  NULL,               -- fund_id (deal-level)
  1,                  -- deal_id (Test Deal Alpha)
  50000.00,           -- amount ($50,000 contribution)
  'USD',              -- currency
  '2025-10-20'        -- paid_in_date (today)
)
RETURNING
  id as contribution_id,
  investor_id,
  deal_id,
  amount,
  currency,
  paid_in_date;
