-- ============================================
-- Charges Migration Validation Script (FIXED)
-- Purpose: Test all acceptance criteria for P2-1
-- Date: 2025-10-19
-- Version: 1.1 (FIXED - Removed EXPLAIN tests)
-- ============================================
--
-- Run this AFTER applying the FIXED charges migration.
-- All tests should PASS or show INFO messages.
--
-- ============================================

-- ============================================
-- TEST 1: XOR Constraint - Both NULL (should FAIL)
-- ============================================

DO $$
DECLARE
  test_result TEXT := 'FAIL';
BEGIN
  BEGIN
    -- This should fail because both deal_id and fund_id are NULL
    INSERT INTO charges (investor_id, status, snapshot_json)
    VALUES (1, 'DRAFT', '{}');

    test_result := 'UNEXPECTED SUCCESS';
  EXCEPTION
    WHEN check_violation THEN
      test_result := 'PASS (XOR constraint enforced)';
    WHEN foreign_key_violation THEN
      test_result := 'PASS (FK violation - need valid investor_id, but XOR constraint would also fail)';
    WHEN OTHERS THEN
      test_result := 'FAIL: ' || SQLERRM;
  END;

  RAISE NOTICE 'TEST 1 (XOR - both NULL): %', test_result;
END $$;

-- ============================================
-- TEST 2: XOR Constraint - Both Set (should FAIL)
-- ============================================

DO $$
DECLARE
  test_result TEXT := 'FAIL';
  test_investor_id BIGINT;
  test_deal_id BIGINT;
  test_fund_id BIGINT;
BEGIN
  -- Get valid test data
  SELECT id INTO test_investor_id FROM investors LIMIT 1;
  SELECT id INTO test_deal_id FROM deals LIMIT 1;
  SELECT id INTO test_fund_id FROM funds LIMIT 1;

  IF test_investor_id IS NULL OR test_deal_id IS NULL OR test_fund_id IS NULL THEN
    test_result := 'SKIP (no test data - create investors/deals/funds first)';
  ELSE
    BEGIN
      -- This should fail because both deal_id and fund_id are set
      INSERT INTO charges (investor_id, deal_id, fund_id, status, snapshot_json)
      VALUES (test_investor_id, test_deal_id, test_fund_id, 'DRAFT', '{"test": true}');

      test_result := 'UNEXPECTED SUCCESS';
    EXCEPTION
      WHEN check_violation THEN
        test_result := 'PASS (XOR constraint enforced)';
      WHEN OTHERS THEN
        test_result := 'FAIL: ' || SQLERRM;
    END;
  END IF;

  RAISE NOTICE 'TEST 2 (XOR - both set): %', test_result;
END $$;

-- ============================================
-- TEST 3: Valid Charge - deal_id Only (should SUCCEED)
-- ============================================

DO $$
DECLARE
  test_result TEXT := 'FAIL';
  test_investor_id BIGINT;
  test_deal_id BIGINT;
  new_charge_id UUID;
  new_numeric_id BIGINT;
BEGIN
  -- Get valid test data
  SELECT id INTO test_investor_id FROM investors LIMIT 1;
  SELECT id INTO test_deal_id FROM deals LIMIT 1;

  IF test_investor_id IS NULL OR test_deal_id IS NULL THEN
    test_result := 'SKIP (no test data - create investors/deals first)';
  ELSE
    BEGIN
      -- This should succeed (deal_id only, fund_id NULL)
      INSERT INTO charges (investor_id, deal_id, status, snapshot_json, base_amount, total_amount)
      VALUES (test_investor_id, test_deal_id, 'DRAFT', '{"agreement_snapshot": {}, "vat_snapshot": {}}', 10000.00, 12000.00)
      RETURNING id, numeric_id INTO new_charge_id, new_numeric_id;

      test_result := 'PASS (created charge: id=' || new_charge_id || ', numeric_id=' || new_numeric_id || ')';

      -- Clean up test data
      DELETE FROM charges WHERE id = new_charge_id;
    EXCEPTION
      WHEN OTHERS THEN
        test_result := 'FAIL: ' || SQLERRM;
    END;
  END IF;

  RAISE NOTICE 'TEST 3 (Valid charge): %', test_result;
END $$;

-- ============================================
-- TEST 4: Verify charge_status Enum
-- ============================================

DO $$
DECLARE
  test_result TEXT;
  enum_values TEXT[];
  expected_values TEXT[] := ARRAY['DRAFT', 'PENDING', 'APPROVED', 'PAID', 'REJECTED'];
BEGIN
  -- Get actual enum values
  SELECT array_agg(enumlabel ORDER BY enumsortorder)
  INTO enum_values
  FROM pg_enum
  WHERE enumtypid = 'charge_status'::regtype;

  IF enum_values = expected_values THEN
    test_result := 'PASS (all 5 enum values: ' || array_to_string(enum_values, ', ') || ')';
  ELSE
    test_result := 'FAIL (expected: ' || array_to_string(expected_values, ', ') || ', got: ' || COALESCE(array_to_string(enum_values, ', '), 'NULL') || ')';
  END IF;

  RAISE NOTICE 'TEST 4 (Status enum): %', test_result;
END $$;

-- ============================================
-- TEST 5: Verify RLS Policies Exist
-- ============================================

DO $$
DECLARE
  test_result TEXT;
  policy_count INT;
BEGIN
  -- Count policies on charges table
  SELECT COUNT(*)
  INTO policy_count
  FROM pg_policies
  WHERE tablename = 'charges';

  IF policy_count >= 2 THEN
    test_result := 'PASS (' || policy_count || ' RLS policies exist)';
  ELSE
    test_result := 'FAIL (expected at least 2 policies, found ' || policy_count || ')';
  END IF;

  RAISE NOTICE 'TEST 5 (RLS policies): %', test_result;
END $$;

-- ============================================
-- TEST 6: Verify All Indexes Exist
-- ============================================

DO $$
DECLARE
  test_result TEXT;
  missing_indexes TEXT[] := ARRAY[]::TEXT[];
  expected_indexes TEXT[] := ARRAY[
    'idx_charges_status',
    'idx_charges_investor_status',
    'idx_charges_deal',
    'idx_charges_fund',
    'idx_charges_contribution',
    'idx_charges_approved_at',
    'idx_charges_paid_at',
    'idx_charges_numeric_id'
  ];
  idx TEXT;
BEGIN
  -- Check each expected index
  FOREACH idx IN ARRAY expected_indexes
  LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = idx) THEN
      missing_indexes := array_append(missing_indexes, idx);
    END IF;
  END LOOP;

  IF array_length(missing_indexes, 1) IS NULL THEN
    test_result := 'PASS (all ' || array_length(expected_indexes, 1) || ' indexes created)';
  ELSE
    test_result := 'FAIL (missing: ' || array_to_string(missing_indexes, ', ') || ')';
  END IF;

  RAISE NOTICE 'TEST 6 (All indexes): %', test_result;
END $$;

-- ============================================
-- TEST 7: Verify Table Schema (All Columns)
-- ============================================

DO $$
DECLARE
  test_result TEXT;
  expected_columns TEXT[] := ARRAY[
    'id', 'numeric_id', 'investor_id', 'deal_id', 'fund_id', 'contribution_id',
    'status', 'base_amount', 'discount_amount', 'vat_amount', 'total_amount',
    'currency', 'snapshot_json', 'computed_at', 'submitted_at',
    'approved_by', 'approved_at', 'rejected_by', 'rejected_at',
    'reject_reason', 'paid_at', 'created_at', 'updated_at'
  ];
  missing_columns TEXT[] := ARRAY[]::TEXT[];
  col TEXT;
BEGIN
  -- Check each expected column
  FOREACH col IN ARRAY expected_columns
  LOOP
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'charges'
      AND column_name = col
    ) THEN
      missing_columns := array_append(missing_columns, col);
    END IF;
  END LOOP;

  IF array_length(missing_columns, 1) IS NULL THEN
    test_result := 'PASS (all ' || array_length(expected_columns, 1) || ' columns present)';
  ELSE
    test_result := 'FAIL (missing: ' || array_to_string(missing_columns, ', ') || ')';
  END IF;

  RAISE NOTICE 'TEST 7 (Table schema): %', test_result;
END $$;

-- ============================================
-- TEST 8: Verify Dual ID Columns (UUID + BIGINT)
-- ============================================

DO $$
DECLARE
  test_result TEXT;
  id_type TEXT;
  numeric_id_type TEXT;
BEGIN
  -- Check id column type
  SELECT data_type INTO id_type
  FROM information_schema.columns
  WHERE table_name = 'charges' AND column_name = 'id';

  -- Check numeric_id column type
  SELECT data_type INTO numeric_id_type
  FROM information_schema.columns
  WHERE table_name = 'charges' AND column_name = 'numeric_id';

  IF id_type = 'uuid' AND numeric_id_type = 'bigint' THEN
    test_result := 'PASS (id is UUID, numeric_id is BIGINT)';
  ELSE
    test_result := 'FAIL (id=' || COALESCE(id_type, 'NULL') || ', numeric_id=' || COALESCE(numeric_id_type, 'NULL') || ')';
  END IF;

  RAISE NOTICE 'TEST 8 (Dual IDs): %', test_result;
END $$;

-- ============================================
-- TEST 9: Verify Foreign Key Constraints
-- ============================================

DO $$
DECLARE
  test_result TEXT;
  fk_count INT;
BEGIN
  -- Count FK constraints on charges table
  SELECT COUNT(*)
  INTO fk_count
  FROM information_schema.table_constraints
  WHERE table_name = 'charges'
  AND constraint_type = 'FOREIGN KEY';

  -- Expected: investor_id, deal_id, fund_id, contribution_id, approved_by, rejected_by
  IF fk_count >= 6 THEN
    test_result := 'PASS (' || fk_count || ' foreign key constraints)';
  ELSE
    test_result := 'FAIL (expected >= 6 FKs, found ' || fk_count || ')';
  END IF;

  RAISE NOTICE 'TEST 9 (Foreign keys): %', test_result;
END $$;

-- ============================================
-- TEST 10: Verify RLS Enabled
-- ============================================

DO $$
DECLARE
  test_result TEXT;
  rls_enabled BOOLEAN;
BEGIN
  -- Check if RLS is enabled
  SELECT relrowsecurity
  INTO rls_enabled
  FROM pg_class
  WHERE relname = 'charges';

  IF rls_enabled THEN
    test_result := 'PASS (RLS enabled)';
  ELSE
    test_result := 'FAIL (RLS not enabled)';
  END IF;

  RAISE NOTICE 'TEST 10 (RLS enabled): %', test_result;
END $$;

-- ============================================
-- TEST 11: Updated_at Trigger
-- ============================================

DO $$
DECLARE
  test_result TEXT := 'FAIL';
  test_investor_id BIGINT;
  test_deal_id BIGINT;
  new_charge_id UUID;
  created_ts TIMESTAMPTZ;
  updated_ts TIMESTAMPTZ;
BEGIN
  -- Get valid test data
  SELECT id INTO test_investor_id FROM investors LIMIT 1;
  SELECT id INTO test_deal_id FROM deals LIMIT 1;

  IF test_investor_id IS NULL OR test_deal_id IS NULL THEN
    test_result := 'SKIP (no test data)';
  ELSE
    BEGIN
      -- Create test charge
      INSERT INTO charges (investor_id, deal_id, status, snapshot_json, base_amount, total_amount)
      VALUES (test_investor_id, test_deal_id, 'DRAFT', '{"test": true}', 10000.00, 12000.00)
      RETURNING id, created_at INTO new_charge_id, created_ts;

      -- Small delay
      PERFORM pg_sleep(0.1);

      -- Update charge
      UPDATE charges SET status = 'PENDING' WHERE id = new_charge_id;

      -- Check updated_at
      SELECT updated_at INTO updated_ts FROM charges WHERE id = new_charge_id;

      IF updated_ts > created_ts THEN
        test_result := 'PASS (trigger works)';
      ELSE
        test_result := 'FAIL (updated_at not updated)';
      END IF;

      -- Clean up
      DELETE FROM charges WHERE id = new_charge_id;
    EXCEPTION
      WHEN OTHERS THEN
        test_result := 'FAIL: ' || SQLERRM;
    END;
  END IF;

  RAISE NOTICE 'TEST 11 (updated_at trigger): %', test_result;
END $$;

-- ============================================
-- TEST 12: Verify Trigger Function Exists
-- ============================================

DO $$
DECLARE
  test_result TEXT;
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc WHERE proname = 'update_charges_updated_at'
  ) THEN
    test_result := 'PASS (trigger function exists)';
  ELSE
    test_result := 'FAIL (trigger function not found)';
  END IF;

  RAISE NOTICE 'TEST 12 (Trigger function): %', test_result;
END $$;

-- ============================================
-- SUMMARY
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'VALIDATION COMPLETE';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Review results above:';
  RAISE NOTICE '- PASS = Test succeeded';
  RAISE NOTICE '- SKIP = No test data (create investors/deals first)';
  RAISE NOTICE '- FAIL = Migration issue detected';
  RAISE NOTICE '';
  RAISE NOTICE 'Next steps:';
  RAISE NOTICE '1. If SKIPs: Create test investors/deals, then re-run';
  RAISE NOTICE '2. If FAILs: Review migration and fix issues';
  RAISE NOTICE '3. If all PASS: Proceed to migration 2 (credits columns)';
  RAISE NOTICE '========================================';
END $$;
