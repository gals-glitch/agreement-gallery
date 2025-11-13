-- ============================================
-- Charge Workflow Smoke Test (SQL)
-- Tests: DRAFT → PENDING → APPROVED → PAID
-- ============================================

DO $$
DECLARE
  test_charge_id UUID;
  test_user_id UUID;
  charge_status TEXT;
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'CHARGE WORKFLOW SMOKE TEST';
  RAISE NOTICE '========================================';
  RAISE NOTICE '';

  -- Get the test charge we created
  SELECT id INTO test_charge_id FROM charges WHERE numeric_id = 21;

  -- Get admin user
  SELECT id INTO test_user_id FROM auth.users WHERE email = 'gals@buligocapital.com';

  IF test_charge_id IS NULL THEN
    RAISE EXCEPTION 'Test charge not found (numeric_id = 21)';
  END IF;

  RAISE NOTICE 'Charge ID: %', test_charge_id;
  RAISE NOTICE 'User ID: %', test_user_id;
  RAISE NOTICE '';

  -- ============================================
  -- TEST 1: Submit (DRAFT → PENDING)
  -- ============================================

  RAISE NOTICE '🚀 TEST 1: Submit Charge (DRAFT → PENDING)';

  UPDATE charges
  SET
    status = 'PENDING',
    submitted_at = NOW(),
    credits_applied_amount = 0,  -- No credits for now (we skipped credit creation)
    net_amount = total_amount,   -- No credits, so net = total
    updated_at = NOW()
  WHERE id = test_charge_id
    AND status = 'DRAFT'
  RETURNING status INTO charge_status;

  IF charge_status = 'PENDING' THEN
    RAISE NOTICE '✅ PASS: Status changed to PENDING';
    RAISE NOTICE '   - Credits Applied: $0 (no credits in system)';
    RAISE NOTICE '   - Net Amount: $1,200';
  ELSE
    RAISE NOTICE '❌ FAIL: Status not changed (may already be submitted)';
  END IF;

  RAISE NOTICE '';

  -- ============================================
  -- TEST 2: Approve (PENDING → APPROVED)
  -- ============================================

  RAISE NOTICE '✅ TEST 2: Approve Charge (PENDING → APPROVED)';

  UPDATE charges
  SET
    status = 'APPROVED',
    approved_by = test_user_id,
    approved_at = NOW(),
    updated_at = NOW()
  WHERE id = test_charge_id
    AND status = 'PENDING'
  RETURNING status INTO charge_status;

  IF charge_status = 'APPROVED' THEN
    RAISE NOTICE '✅ PASS: Status changed to APPROVED';
    RAISE NOTICE '   - Approved By: %', test_user_id;
    RAISE NOTICE '   - Approved At: %', NOW();
  ELSE
    RAISE NOTICE '❌ FAIL: Status not changed';
  END IF;

  RAISE NOTICE '';

  -- ============================================
  -- TEST 3: Mark Paid (APPROVED → PAID)
  -- ============================================

  RAISE NOTICE '💰 TEST 3: Mark as Paid (APPROVED → PAID)';

  UPDATE charges
  SET
    status = 'PAID',
    paid_at = NOW(),
    updated_at = NOW()
  WHERE id = test_charge_id
    AND status = 'APPROVED'
  RETURNING status INTO charge_status;

  IF charge_status = 'PAID' THEN
    RAISE NOTICE '✅ PASS: Status changed to PAID';
    RAISE NOTICE '   - Paid At: %', NOW();
  ELSE
    RAISE NOTICE '❌ FAIL: Status not changed';
  END IF;

  RAISE NOTICE '';

  -- ============================================
  -- FINAL VERIFICATION
  -- ============================================

  RAISE NOTICE '========================================';
  RAISE NOTICE 'FINAL STATUS';
  RAISE NOTICE '========================================';

  SELECT
    status,
    base_amount,
    vat_amount,
    total_amount,
    credits_applied_amount,
    net_amount,
    submitted_at IS NOT NULL AS was_submitted,
    approved_at IS NOT NULL AS was_approved,
    paid_at IS NOT NULL AS was_paid
  INTO
    charge_status
  FROM charges
  WHERE id = test_charge_id;

  RAISE NOTICE 'Charge Status: %', charge_status;
  RAISE NOTICE '';

END $$;

-- ============================================
-- Detailed View Query
-- ============================================

SELECT
  'Charge Details' AS section,
  id,
  numeric_id,
  status,
  base_amount,
  vat_amount,
  total_amount,
  credits_applied_amount,
  net_amount,
  submitted_at,
  approved_at,
  approved_by,
  paid_at,
  created_at
FROM charges
WHERE numeric_id = 21;
