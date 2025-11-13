-- ============================================
-- E2E Test Data Teardown Script (v1.8.0)
-- ============================================
-- Purpose: Clean up deterministic test data created by test_data_seed.sql
-- Run with: psql -h <host> -U postgres -d <database> -f test_data_teardown.sql
-- Date: 2025-10-21
--
-- IMPORTANT: Run this on test/staging database ONLY
-- ============================================

-- Enable transaction for atomic cleanup
BEGIN;

\echo '============================================'
\echo 'E2E TEST DATA TEARDOWN - STARTING'
\echo '============================================'

-- ============================================
-- PRE-CLEANUP VERIFICATION
-- ============================================
\echo ''
\echo 'Pre-cleanup entity counts:'
SELECT
  (SELECT COUNT(*) FROM charges WHERE investor_id = 999) AS charges,
  (SELECT COUNT(*) FROM credit_applications WHERE credit_id IN (SELECT id FROM credits WHERE investor_id = 999)) AS credit_applications,
  (SELECT COUNT(*) FROM credits WHERE investor_id = 999) AS credits,
  (SELECT COUNT(*) FROM contributions WHERE investor_id = 999) AS contributions,
  (SELECT COUNT(*) FROM agreements WHERE party_id = 999) AS agreements,
  (SELECT COUNT(*) FROM deals WHERE id = 999) AS deals,
  (SELECT COUNT(*) FROM funds WHERE id = 999) AS funds,
  (SELECT COUNT(*) FROM parties WHERE id = 999) AS parties;

-- ============================================
-- STEP 1: Delete Charges (referencing contributions)
-- ============================================
\echo ''
\echo '[STEP 1] Deleting test charges...'

DO $$
DECLARE
  deleted_count INT;
BEGIN
  DELETE FROM charges WHERE investor_id = 999;
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RAISE NOTICE '✅ Deleted % charges', deleted_count;
END $$;

-- ============================================
-- STEP 2: Delete Credit Applications
-- ============================================
\echo ''
\echo '[STEP 2] Deleting credit applications...'

DO $$
DECLARE
  deleted_count INT;
BEGIN
  DELETE FROM credit_applications
  WHERE credit_id = '99999999-9999-9999-9999-999999999999'::UUID;
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RAISE NOTICE '✅ Deleted % credit applications', deleted_count;
END $$;

-- ============================================
-- STEP 3: Delete Credits
-- ============================================
\echo ''
\echo '[STEP 3] Deleting test credits...'

DO $$
DECLARE
  deleted_count INT;
BEGIN
  DELETE FROM credits WHERE investor_id = 999;
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RAISE NOTICE '✅ Deleted % credits', deleted_count;
END $$;

-- ============================================
-- STEP 4: Delete Contributions
-- ============================================
\echo ''
\echo '[STEP 4] Deleting test contributions...'

DO $$
DECLARE
  deleted_count INT;
BEGIN
  -- Delete contributions with IDs 948-999
  DELETE FROM contributions WHERE id BETWEEN 948 AND 999;
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RAISE NOTICE '✅ Deleted % contributions', deleted_count;
END $$;

-- ============================================
-- STEP 5: Delete Agreement Custom Terms
-- ============================================
\echo ''
\echo '[STEP 5] Deleting agreement custom terms...'

DO $$
DECLARE
  deleted_count INT;
BEGIN
  DELETE FROM agreement_custom_terms WHERE agreement_id = 999;
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RAISE NOTICE '✅ Deleted % custom terms', deleted_count;
END $$;

-- ============================================
-- STEP 6: Delete Agreement VAT Rates
-- ============================================
\echo ''
\echo '[STEP 6] Deleting agreement VAT rates...'

DO $$
DECLARE
  deleted_count INT;
BEGIN
  DELETE FROM agreement_vat_rates WHERE agreement_id = 999;
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RAISE NOTICE '✅ Deleted % VAT rates', deleted_count;
END $$;

-- ============================================
-- STEP 7: Delete Agreements
-- ============================================
\echo ''
\echo '[STEP 7] Deleting test agreements...'

DO $$
DECLARE
  deleted_count INT;
BEGIN
  DELETE FROM agreements WHERE party_id = 999;
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RAISE NOTICE '✅ Deleted % agreements', deleted_count;
END $$;

-- ============================================
-- STEP 8: Delete Deals
-- ============================================
\echo ''
\echo '[STEP 8] Deleting test deals...'

DO $$
DECLARE
  deleted_count INT;
BEGIN
  DELETE FROM deals WHERE id = 999;
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RAISE NOTICE '✅ Deleted % deals', deleted_count;
END $$;

-- ============================================
-- STEP 9: Delete Funds
-- ============================================
\echo ''
\echo '[STEP 9] Deleting test funds...'

DO $$
DECLARE
  deleted_count INT;
BEGIN
  DELETE FROM funds WHERE id = 999;
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RAISE NOTICE '✅ Deleted % funds', deleted_count;
END $$;

-- ============================================
-- STEP 10: Delete Parties (Investors)
-- ============================================
\echo ''
\echo '[STEP 10] Deleting test parties...'

DO $$
DECLARE
  deleted_count INT;
BEGIN
  DELETE FROM parties WHERE id = 999;
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RAISE NOTICE '✅ Deleted % parties', deleted_count;
END $$;

-- ============================================
-- POST-CLEANUP VERIFICATION
-- ============================================
\echo ''
\echo '============================================'
\echo 'E2E TEST DATA TEARDOWN - VERIFICATION'
\echo '============================================'

\echo ''
\echo 'Post-cleanup entity counts (should all be 0):'
SELECT
  (SELECT COUNT(*) FROM charges WHERE investor_id = 999) AS charges,
  (SELECT COUNT(*) FROM credit_applications WHERE credit_id = '99999999-9999-9999-9999-999999999999'::UUID) AS credit_applications,
  (SELECT COUNT(*) FROM credits WHERE investor_id = 999) AS credits,
  (SELECT COUNT(*) FROM contributions WHERE id BETWEEN 948 AND 999) AS contributions,
  (SELECT COUNT(*) FROM agreements WHERE party_id = 999) AS agreements,
  (SELECT COUNT(*) FROM deals WHERE id = 999) AS deals,
  (SELECT COUNT(*) FROM funds WHERE id = 999) AS funds,
  (SELECT COUNT(*) FROM parties WHERE id = 999) AS parties;

-- Check for orphaned records
\echo ''
\echo 'Checking for orphaned records...'

DO $$
DECLARE
  orphaned_charges INT;
  orphaned_credits INT;
BEGIN
  SELECT COUNT(*) INTO orphaned_charges
  FROM charges
  WHERE investor_id = 999 OR contribution_id BETWEEN 948 AND 999;

  SELECT COUNT(*) INTO orphaned_credits
  FROM credits
  WHERE investor_id = 999;

  IF orphaned_charges > 0 THEN
    RAISE WARNING '❌ Found % orphaned charges - manual cleanup required', orphaned_charges;
  ELSE
    RAISE NOTICE '✅ No orphaned charges';
  END IF;

  IF orphaned_credits > 0 THEN
    RAISE WARNING '❌ Found % orphaned credits - manual cleanup required', orphaned_credits;
  ELSE
    RAISE NOTICE '✅ No orphaned credits';
  END IF;
END $$;

COMMIT;

\echo ''
\echo '============================================'
\echo '✅ E2E TEST DATA TEARDOWN - COMPLETED'
\echo '============================================'
\echo ''
\echo 'All test data has been removed.'
\echo 'Database is ready for a fresh test run.'
\echo ''
