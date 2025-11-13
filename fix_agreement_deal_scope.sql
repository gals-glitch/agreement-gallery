-- Quick fix: Ensure commission agreement has deal_id = 1 (if it's missing)

-- First, check current state
SELECT
  id,
  party_id,
  scope,
  fund_id,
  deal_id,
  status,
  effective_from,
  snapshot_json->'terms'->0->>'rate_bps' as rate_bps
FROM agreements
WHERE kind = 'distributor_commission'
  AND status = 'APPROVED';

-- Update the agreement to have deal_id = 1 if it's NULL or wrong
UPDATE agreements
SET
  deal_id = 1,
  fund_id = NULL,
  scope = 'DEAL'::agreement_scope,
  snapshot_json = jsonb_set(
    snapshot_json,
    '{scope}',
    '{"deal_id": 1, "fund_id": null}'::jsonb
  ),
  updated_at = NOW()
WHERE kind = 'distributor_commission'
  AND status = 'APPROVED'
  AND (deal_id IS NULL OR deal_id != 1);

-- Verify the fix
SELECT
  id,
  party_id,
  scope,
  fund_id,
  deal_id,
  status,
  effective_from,
  snapshot_json->'scope' as snapshot_scope,
  snapshot_json->'terms'->0->>'rate_bps' as rate_bps
FROM agreements
WHERE kind = 'distributor_commission'
  AND status = 'APPROVED';
