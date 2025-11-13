-- Fix: Delete and recreate party with matching investor ID
-- The system expects party_id to equal investor_id for matching

-- Step 1: Delete the incorrectly created agreement
DELETE FROM agreements WHERE id = 5;

-- Step 2: Delete the incorrectly created party
DELETE FROM parties WHERE id = 2;

-- Step 3: Insert party WITH id=201 to match investor_id
-- This requires explicitly setting the ID
INSERT INTO parties (
  id,      -- Explicitly set to match investor_id
  name,
  email,
  country,
  active,
  notes
)
VALUES (
  201,     -- Must match investor.id for agreement matching
  'Rakefet Kuperman',
  NULL,
  'Israel',
  true,
  'Investor party - ID matches investor.id'
);

-- Step 4: Create agreement with party_id=201
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
  201,      -- Now matches investor_id!
  NULL,
  1,        -- deal_id (Test Deal Alpha)
  'APPROVED',
  'DEAL',
  'CUSTOM',
  false,
  '2024-01-01',
  NULL
)
RETURNING
  id as agreement_id,
  party_id,
  deal_id,
  status;
