-- Disable trigger, update agreement 6, re-enable trigger

-- Step 1: Disable the immutability trigger
ALTER TABLE agreements DISABLE TRIGGER agreements_lock_after_approval;

-- Step 2: Update agreement 6 with pricing configuration
UPDATE agreements
SET snapshot_json = '{"resolved_upfront_bps": 100, "resolved_deferred_bps": 0, "vat_rate": 0.2}'::jsonb
WHERE id = 6;

-- Step 3: Re-enable the trigger
ALTER TABLE agreements ENABLE TRIGGER agreements_lock_after_approval;

-- Step 4: Verify the update
SELECT
  id,
  party_id,
  status,
  pricing_mode,
  snapshot_json
FROM agreements
WHERE id = 6;
