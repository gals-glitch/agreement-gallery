-- ============================================
-- RLS Policy Tests for Charge Workflow (v1.8.0)
-- ============================================
-- Purpose: Verify Row-Level Security policies are correctly enforced
-- Run with: psql -h <host> -U postgres -d <database> -f rls_policy_tests.sql
-- Date: 2025-10-21
--
-- IMPORTANT: Run this script on a test/staging database, NOT production
-- ============================================

-- Enable output formatting
\set QUIET off
\timing on

-- ============================================
-- TEST SETUP
-- ============================================
\echo ''
\echo '============================================'
\echo 'RLS POLICY TESTS - SETUP'
\echo '============================================'

-- Create test data if not exists
DO $$
DECLARE
  test_investor_id INT;
  test_contribution_id INT;
  test_charge_id UUID;
BEGIN
  -- Insert test investor
  INSERT INTO parties (id, name, active)
  VALUES (99999, 'Test Investor for RLS', true)
  ON CONFLICT (id) DO NOTHING;
  test_investor_id := 99999;

  -- Insert test contribution
  INSERT INTO contributions (id, investor_id, deal_id, paid_in_date, amount, currency)
  VALUES (99999, test_investor_id, 1, CURRENT_DATE, 50000, 'USD')
  ON CONFLICT (id) DO NOTHING;
  test_contribution_id := 99999;

  -- Insert test charge
  test_charge_id := '99999999-9999-9999-9999-999999999999'::UUID;
  INSERT INTO charges (
    id, investor_id, contribution_id, status,
    base_amount, vat_amount, total_amount, currency,
    snapshot_json, computed_at
  )
  VALUES (
    test_charge_id, test_investor_id, test_contribution_id, 'DRAFT',
    500, 100, 600, 'USD',
    '{}'::jsonb, NOW()
  )
  ON CONFLICT (id) DO NOTHING;

  RAISE NOTICE 'Test data created:';
  RAISE NOTICE '  Investor ID: %', test_investor_id;
  RAISE NOTICE '  Contribution ID: %', test_contribution_id;
  RAISE NOTICE '  Charge ID: %', test_charge_id;
END $$;

-- ============================================
-- TEST CATEGORY 1: SELECT (Read) Permissions
-- ============================================
\echo ''
\echo '============================================'
\echo 'CATEGORY 1: SELECT (Read) Permissions'
\echo '============================================'

-- Test 1: Admin can see all charges
\echo ''
\echo '[TEST 1] Admin can see all charges'
BEGIN;
SET LOCAL app.user_role = 'admin';
SELECT
  CASE
    WHEN COUNT(*) > 0 THEN '✅ PASS - Admin can see charges (count: ' || COUNT(*) || ')'
    ELSE '❌ FAIL - Admin sees 0 charges (should see at least test charge)'
  END AS result
FROM charges;
ROLLBACK;

-- Test 2: Finance can see all charges
\echo ''
\echo '[TEST 2] Finance can see all charges'
BEGIN;
SET LOCAL app.user_role = 'finance';
SELECT
  CASE
    WHEN COUNT(*) > 0 THEN '✅ PASS - Finance can see charges (count: ' || COUNT(*) || ')'
    ELSE '❌ FAIL - Finance sees 0 charges (should see at least test charge)'
  END AS result
FROM charges;
ROLLBACK;

-- Test 3: Ops can see all charges
\echo ''
\echo '[TEST 3] Ops can see all charges'
BEGIN;
SET LOCAL app.user_role = 'ops';
SELECT
  CASE
    WHEN COUNT(*) > 0 THEN '✅ PASS - Ops can see charges (count: ' || COUNT(*) || ')'
    ELSE '❌ FAIL - Ops sees 0 charges (should see at least test charge)'
  END AS result
FROM charges;
ROLLBACK;

-- Test 4: Manager can see all charges
\echo ''
\echo '[TEST 4] Manager can see all charges'
BEGIN;
SET LOCAL app.user_role = 'manager';
SELECT
  CASE
    WHEN COUNT(*) > 0 THEN '✅ PASS - Manager can see charges (count: ' || COUNT(*) || ')'
    ELSE '❌ FAIL - Manager sees 0 charges (should see at least test charge)'
  END AS result
FROM charges;
ROLLBACK;

-- Test 5: Viewer CANNOT see any charges
\echo ''
\echo '[TEST 5] Viewer CANNOT see any charges (RLS blocks)'
BEGIN;
SET LOCAL app.user_role = 'viewer';
SELECT
  CASE
    WHEN COUNT(*) = 0 THEN '✅ PASS - Viewer sees 0 charges (RLS blocked correctly)'
    ELSE '❌ FAIL - Viewer can see charges (count: ' || COUNT(*) || ') - RLS not working!'
  END AS result
FROM charges;
ROLLBACK;

-- Test 6: Service role can see all charges
\echo ''
\echo '[TEST 6] Service role can see all charges'
BEGIN;
SET LOCAL app.user_role = 'service';
SELECT
  CASE
    WHEN COUNT(*) > 0 THEN '✅ PASS - Service can see charges (count: ' || COUNT(*) || ')'
    ELSE '❌ FAIL - Service sees 0 charges (should bypass RLS)'
  END AS result
FROM charges;
ROLLBACK;

-- ============================================
-- TEST CATEGORY 2: INSERT Permissions
-- ============================================
\echo ''
\echo '============================================'
\echo 'CATEGORY 2: INSERT Permissions'
\echo '============================================'

-- Test 7: Admin can insert charges
\echo ''
\echo '[TEST 7] Admin can insert charges'
BEGIN;
SET LOCAL app.user_role = 'admin';
DO $$
BEGIN
  INSERT INTO charges (
    id, investor_id, contribution_id, status,
    base_amount, vat_amount, total_amount, currency,
    snapshot_json, computed_at
  )
  VALUES (
    gen_random_uuid(), 99999, 99999, 'DRAFT',
    100, 20, 120, 'USD',
    '{}'::jsonb, NOW()
  );
  RAISE NOTICE '✅ PASS - Admin can insert charges';
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE '❌ FAIL - Admin cannot insert: %', SQLERRM;
END $$;
ROLLBACK;

-- Test 8: Finance can insert charges
\echo ''
\echo '[TEST 8] Finance can insert charges'
BEGIN;
SET LOCAL app.user_role = 'finance';
DO $$
BEGIN
  INSERT INTO charges (
    id, investor_id, contribution_id, status,
    base_amount, vat_amount, total_amount, currency,
    snapshot_json, computed_at
  )
  VALUES (
    gen_random_uuid(), 99999, 99999, 'DRAFT',
    100, 20, 120, 'USD',
    '{}'::jsonb, NOW()
  );
  RAISE NOTICE '✅ PASS - Finance can insert charges';
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE '❌ FAIL - Finance cannot insert: %', SQLERRM;
END $$;
ROLLBACK;

-- Test 9: Ops can insert charges
\echo ''
\echo '[TEST 9] Ops can insert charges'
BEGIN;
SET LOCAL app.user_role = 'ops';
DO $$
BEGIN
  INSERT INTO charges (
    id, investor_id, contribution_id, status,
    base_amount, vat_amount, total_amount, currency,
    snapshot_json, computed_at
  )
  VALUES (
    gen_random_uuid(), 99999, 99999, 'DRAFT',
    100, 20, 120, 'USD',
    '{}'::jsonb, NOW()
  );
  RAISE NOTICE '✅ PASS - Ops can insert charges';
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE '❌ FAIL - Ops cannot insert: %', SQLERRM;
END $$;
ROLLBACK;

-- Test 10: Manager CANNOT insert charges
\echo ''
\echo '[TEST 10] Manager CANNOT insert charges'
BEGIN;
SET LOCAL app.user_role = 'manager';
DO $$
BEGIN
  INSERT INTO charges (
    id, investor_id, contribution_id, status,
    base_amount, vat_amount, total_amount, currency,
    snapshot_json, computed_at
  )
  VALUES (
    gen_random_uuid(), 99999, 99999, 'DRAFT',
    100, 20, 120, 'USD',
    '{}'::jsonb, NOW()
  );
  RAISE NOTICE '❌ FAIL - Manager can insert charges (RLS not working!)';
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE '✅ PASS - Manager cannot insert (RLS blocked correctly): %', SQLERRM;
END $$;
ROLLBACK;

-- Test 11: Viewer CANNOT insert charges
\echo ''
\echo '[TEST 11] Viewer CANNOT insert charges'
BEGIN;
SET LOCAL app.user_role = 'viewer';
DO $$
BEGIN
  INSERT INTO charges (
    id, investor_id, contribution_id, status,
    base_amount, vat_amount, total_amount, currency,
    snapshot_json, computed_at
  )
  VALUES (
    gen_random_uuid(), 99999, 99999, 'DRAFT',
    100, 20, 120, 'USD',
    '{}'::jsonb, NOW()
  );
  RAISE NOTICE '❌ FAIL - Viewer can insert charges (RLS not working!)';
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE '✅ PASS - Viewer cannot insert (RLS blocked correctly): %', SQLERRM;
END $$;
ROLLBACK;

-- Test 12: Service can insert charges
\echo ''
\echo '[TEST 12] Service can insert charges'
BEGIN;
SET LOCAL app.user_role = 'service';
DO $$
BEGIN
  INSERT INTO charges (
    id, investor_id, contribution_id, status,
    base_amount, vat_amount, total_amount, currency,
    snapshot_json, computed_at
  )
  VALUES (
    gen_random_uuid(), 99999, 99999, 'DRAFT',
    100, 20, 120, 'USD',
    '{}'::jsonb, NOW()
  );
  RAISE NOTICE '✅ PASS - Service can insert charges';
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE '❌ FAIL - Service cannot insert: %', SQLERRM;
END $$;
ROLLBACK;

-- ============================================
-- TEST CATEGORY 3: UPDATE Permissions
-- ============================================
\echo ''
\echo '============================================'
\echo 'CATEGORY 3: UPDATE Permissions'
\echo '============================================'

-- Test 13: Admin can update charges
\echo ''
\echo '[TEST 13] Admin can update charges'
BEGIN;
SET LOCAL app.user_role = 'admin';
DO $$
BEGIN
  UPDATE charges
  SET status = 'PENDING'
  WHERE id = '99999999-9999-9999-9999-999999999999'::UUID;

  IF FOUND THEN
    RAISE NOTICE '✅ PASS - Admin can update charges';
  ELSE
    RAISE NOTICE '❌ FAIL - Admin cannot update (no rows affected)';
  END IF;
END $$;
ROLLBACK;

-- Test 14: Finance can update charges
\echo ''
\echo '[TEST 14] Finance can update charges'
BEGIN;
SET LOCAL app.user_role = 'finance';
DO $$
BEGIN
  UPDATE charges
  SET status = 'PENDING'
  WHERE id = '99999999-9999-9999-9999-999999999999'::UUID;

  IF FOUND THEN
    RAISE NOTICE '✅ PASS - Finance can update charges';
  ELSE
    RAISE NOTICE '❌ FAIL - Finance cannot update (no rows affected)';
  END IF;
END $$;
ROLLBACK;

-- Test 15: Ops can update charges
\echo ''
\echo '[TEST 15] Ops can update charges'
BEGIN;
SET LOCAL app.user_role = 'ops';
DO $$
BEGIN
  UPDATE charges
  SET status = 'PENDING'
  WHERE id = '99999999-9999-9999-9999-999999999999'::UUID;

  IF FOUND THEN
    RAISE NOTICE '✅ PASS - Ops can update charges';
  ELSE
    RAISE NOTICE '❌ FAIL - Ops cannot update (no rows affected)';
  END IF;
END $$;
ROLLBACK;

-- Test 16: Manager CANNOT update charges
\echo ''
\echo '[TEST 16] Manager CANNOT update charges'
BEGIN;
SET LOCAL app.user_role = 'manager';
DO $$
BEGIN
  UPDATE charges
  SET status = 'PENDING'
  WHERE id = '99999999-9999-9999-9999-999999999999'::UUID;

  IF FOUND THEN
    RAISE NOTICE '❌ FAIL - Manager can update charges (RLS not working!)';
  ELSE
    RAISE NOTICE '✅ PASS - Manager cannot update (RLS blocked correctly)';
  END IF;
END $$;
ROLLBACK;

-- Test 17: Viewer CANNOT update charges
\echo ''
\echo '[TEST 17] Viewer CANNOT update charges'
BEGIN;
SET LOCAL app.user_role = 'viewer';
DO $$
BEGIN
  UPDATE charges
  SET status = 'PENDING'
  WHERE id = '99999999-9999-9999-9999-999999999999'::UUID;

  IF FOUND THEN
    RAISE NOTICE '❌ FAIL - Viewer can update charges (RLS not working!)';
  ELSE
    RAISE NOTICE '✅ PASS - Viewer cannot update (RLS blocked correctly)';
  END IF;
END $$;
ROLLBACK;

-- Test 18: Service can update charges
\echo ''
\echo '[TEST 18] Service can update charges'
BEGIN;
SET LOCAL app.user_role = 'service';
DO $$
BEGIN
  UPDATE charges
  SET status = 'PENDING'
  WHERE id = '99999999-9999-9999-9999-999999999999'::UUID;

  IF FOUND THEN
    RAISE NOTICE '✅ PASS - Service can update charges';
  ELSE
    RAISE NOTICE '❌ FAIL - Service cannot update (no rows affected)';
  END IF;
END $$;
ROLLBACK;

-- ============================================
-- TEST CATEGORY 4: DELETE Permissions
-- ============================================
\echo ''
\echo '============================================'
\echo 'CATEGORY 4: DELETE Permissions'
\echo '============================================'

-- Test 19: Admin can delete charges (if policy exists)
\echo ''
\echo '[TEST 19] Admin can delete charges'
BEGIN;
SET LOCAL app.user_role = 'admin';
DO $$
DECLARE
  test_charge_id UUID;
BEGIN
  -- Create temporary charge to delete
  test_charge_id := gen_random_uuid();
  INSERT INTO charges (
    id, investor_id, contribution_id, status,
    base_amount, vat_amount, total_amount, currency,
    snapshot_json, computed_at
  )
  VALUES (
    test_charge_id, 99999, 99999, 'DRAFT',
    100, 20, 120, 'USD',
    '{}'::jsonb, NOW()
  );

  DELETE FROM charges WHERE id = test_charge_id;

  IF FOUND THEN
    RAISE NOTICE '✅ PASS - Admin can delete charges';
  ELSE
    RAISE NOTICE '❌ FAIL - Admin cannot delete';
  END IF;
END $$;
ROLLBACK;

-- Test 20: Viewer CANNOT delete charges
\echo ''
\echo '[TEST 20] Viewer CANNOT delete charges'
BEGIN;
SET LOCAL app.user_role = 'viewer';
DO $$
BEGIN
  DELETE FROM charges WHERE id = '99999999-9999-9999-9999-999999999999'::UUID;

  IF FOUND THEN
    RAISE NOTICE '❌ FAIL - Viewer can delete charges (RLS not working!)';
  ELSE
    RAISE NOTICE '✅ PASS - Viewer cannot delete (RLS blocked correctly)';
  END IF;
END $$;
ROLLBACK;

-- ============================================
-- TEST CLEANUP
-- ============================================
\echo ''
\echo '============================================'
\echo 'RLS POLICY TESTS - CLEANUP'
\echo '============================================'

-- Delete test data (optional - comment out to inspect data)
-- DELETE FROM charges WHERE id = '99999999-9999-9999-9999-999999999999'::UUID;
-- DELETE FROM contributions WHERE id = 99999;
-- DELETE FROM parties WHERE id = 99999;

\echo ''
\echo '✅ RLS policy tests completed!'
\echo 'Review output above for PASS/FAIL results'
\echo ''

-- ============================================
-- SUMMARY
-- ============================================
\echo '============================================'
\echo 'EXPECTED RESULTS SUMMARY'
\echo '============================================'
\echo ''
\echo 'SELECT (Read) Permissions:'
\echo '  ✅ Admin, Finance, Ops, Manager, Service → Can see charges'
\echo '  ❌ Viewer → Cannot see charges (RLS blocks)'
\echo ''
\echo 'INSERT Permissions:'
\echo '  ✅ Admin, Finance, Ops, Service → Can insert charges'
\echo '  ❌ Manager, Viewer → Cannot insert charges (RLS blocks)'
\echo ''
\echo 'UPDATE Permissions:'
\echo '  ✅ Admin, Finance, Ops, Service → Can update charges'
\echo '  ❌ Manager, Viewer → Cannot update charges (RLS blocks)'
\echo ''
\echo 'DELETE Permissions:'
\echo '  ✅ Admin → Can delete charges'
\echo '  ❌ Viewer → Cannot delete charges (RLS blocks)'
\echo ''
\echo '============================================'
