-- Create party and agreement for Rakefet Kuperman in a single transaction
WITH new_party AS (
  INSERT INTO parties (
    name,
    email,
    country,
    active,
    notes
  )
  VALUES (
    'Rakefet Kuperman',
    NULL,  -- Add email if known
    'Israel',
    true,
    'Investor - Created for testing charge compute workflow'
  )
  RETURNING id, name
)
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
SELECT
  np.id,    -- party_id from the newly created party
  NULL,     -- fund_id
  1,        -- deal_id (Test Deal Alpha)
  'APPROVED',
  'DEAL',
  'CUSTOM',
  false,
  '2024-01-01',
  NULL
FROM new_party np
RETURNING
  id as agreement_id,
  party_id,
  deal_id,
  status,
  scope;
