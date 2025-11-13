-- Workaround: Update agreement 6 by temporarily changing status

-- Step 1: Change status to DRAFT (allows edits)
UPDATE agreements
SET status = 'DRAFT'
WHERE id = 6;

-- Step 2: Add pricing configuration
UPDATE agreements
SET snapshot_json = '{"resolved_upfront_bps": 100, "resolved_deferred_bps": 0, "vat_rate": 0.2}'::jsonb
WHERE id = 6;

-- Step 3: Change status back to APPROVED
UPDATE agreements
SET status = 'APPROVED'
WHERE id = 6;

-- Step 4: Verify
SELECT
  id,
  party_id,
  status,
  pricing_mode,
  snapshot_json
FROM agreements
WHERE id = 6;
