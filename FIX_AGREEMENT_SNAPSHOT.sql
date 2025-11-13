-- Add snapshot_json column to agreements table and configure agreement 6

-- Step 1: Add snapshot_json column if it doesn't exist
ALTER TABLE agreements ADD COLUMN IF NOT EXISTS snapshot_json JSONB DEFAULT '{}'::jsonb;

-- Step 2: Set pricing for agreement 6 (100 bps = 1%, 20% VAT)
UPDATE agreements
SET snapshot_json = '{"resolved_upfront_bps": 100, "resolved_deferred_bps": 0, "vat_rate": 0.2}'::jsonb
WHERE id = 6;

-- Step 3: Verify the update
SELECT
  id,
  party_id,
  pricing_mode,
  snapshot_json
FROM agreements
WHERE id = 6;
