-- Create a test credit for investor 201 (Rakefet Kuperman)
-- This will be used to test FIFO credit application workflow

-- Step 1: Get the current user ID for created_by
-- (We'll use the first admin user we can find)
DO $$
DECLARE
  admin_user_id UUID;
BEGIN
  -- Try to find an admin user
  SELECT user_id INTO admin_user_id
  FROM user_roles
  WHERE role_key = 'admin'
  LIMIT 1;

  -- If no admin found, just use a placeholder UUID
  IF admin_user_id IS NULL THEN
    admin_user_id := '00000000-0000-0000-0000-000000000000';
  END IF;

  -- Create test credit for investor 201, deal 1
  INSERT INTO credits_ledger (
    investor_id,
    fund_id,
    deal_id,
    reason,
    original_amount,
    applied_amount,
    status,
    currency,
    notes,
    created_by
  )
  VALUES (
    201,              -- investor_id (Rakefet Kuperman)
    NULL,             -- fund_id (deal-level credit)
    1,                -- deal_id (Test Deal Alpha)
    'MANUAL',         -- reason
    500.00,           -- original_amount ($500 credit)
    0.00,             -- applied_amount (not yet applied)
    'AVAILABLE',      -- status
    'USD',            -- currency
    'Test credit for FIFO workflow verification',  -- notes
    admin_user_id     -- created_by
  );

  RAISE NOTICE 'Test credit created successfully';
END $$;

-- Step 2: Verify the credit was created
SELECT
  id as credit_id,
  investor_id,
  deal_id,
  reason,
  original_amount,
  applied_amount,
  available_amount,  -- This is a generated column (original - applied)
  status,
  currency,
  notes,
  created_at
FROM credits_ledger
WHERE investor_id = 201
  AND deal_id = 1
ORDER BY created_at DESC
LIMIT 1;
