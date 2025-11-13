-- Step 1: Check agreements table structure
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'agreements'
ORDER BY ordinal_position;

-- Step 2: Find agreements for investor 201 (Rakefet Kuperman)
SELECT id, party_id, status, fund_id, deal_id, scope
FROM agreements
WHERE party_id = 201
ORDER BY id DESC;

-- Step 3: Simple approval (just change status)
-- Replace XX with actual agreement ID from Step 2
UPDATE agreements
SET status = 'APPROVED'
WHERE id = XX;

-- Step 4: Verify the update
SELECT id, party_id, status, fund_id, deal_id
FROM agreements
WHERE party_id = 201;
