-- Create an approved agreement for investor 201 (Rakefet Kuperman)
-- This will match contribution ID 1 (deal_id = 1, Test Deal Alpha)

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
  201,           -- party_id (Rakefet Kuperman)
  NULL,          -- fund_id (contribution is deal-level)
  1,             -- deal_id (Test Deal Alpha)
  'APPROVED',    -- status
  'DEAL',        -- scope (deal-level agreement)
  'CUSTOM',      -- pricing_mode
  false,         -- vat_included
  '2024-01-01',  -- effective_from (before contribution date)
  NULL           -- effective_to (no end date)
)
RETURNING *;
