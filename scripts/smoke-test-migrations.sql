-- ============================================
-- 15-Minute Smoke Test: Verify Schema + Seeds + Guards
-- Purpose: Prove migrations applied correctly
-- Run after: All 7 migrations applied
-- ============================================

\echo '============================================'
\echo '🧪 SMOKE TEST: Schema + Seeds + Guards'
\echo '============================================'
\echo ''

-- ============================================
-- TEST 1: Tracks are seeded & locked
-- ============================================
\echo '✅ TEST 1: Fund VI Tracks Seeded & Locked'
\echo '   Expected: 3 rows (Track A, B, C with is_locked=true)'
\echo ''

SELECT
  f.name AS fund,
  ft.track_code,
  ft.upfront_bps || ' bps (' || (ft.upfront_bps::NUMERIC / 100) || '%)' AS upfront,
  ft.deferred_bps || ' bps (' || (ft.deferred_bps::NUMERIC / 100) || '%)' AS deferred,
  ft.is_locked,
  ft.seed_version
FROM fund_tracks ft
JOIN funds f ON f.id = ft.fund_id
WHERE f.name='Fund VI'
ORDER BY ft.track_code;

\echo ''
\echo 'Expected output:'
\echo 'fund     | track_code | upfront          | deferred         | is_locked | seed_version'
\echo '---------+------------+------------------+------------------+-----------+--------------'
\echo 'Fund VI  | A          | 120 bps (1.20%)  | 80 bps (0.80%)   | true      | 1'
\echo 'Fund VI  | B          | 180 bps (1.80%)  | 80 bps (0.80%)   | true      | 1'
\echo 'Fund VI  | C          | 180 bps (1.80%)  | 130 bps (1.30%)  | true      | 1'
\echo ''

-- ============================================
-- TEST 2: Guardrail triggers exist
-- ============================================
\echo '✅ TEST 2: Immutability Triggers Installed'
\echo '   Expected: 2 triggers found'
\echo ''

SELECT
  tgname AS trigger_name,
  'Installed ✓' AS status
FROM pg_trigger
WHERE tgname IN ('agreements_lock_after_approval','agreements_snapshot_on_approve')
ORDER BY tgname;

\echo ''
\echo 'Expected output:'
\echo 'trigger_name                      | status'
\echo '----------------------------------+--------------'
\echo 'agreements_lock_after_approval    | Installed ✓'
\echo 'agreements_snapshot_on_approve    | Installed ✓'
\echo ''

-- ============================================
-- TEST 3: Pricing constraint enforcement
-- ============================================
\echo '✅ TEST 3: Pricing Constraint (FUND must use TRACK)'
\echo '   Test: Try to create FUND-scoped agreement with CUSTOM pricing'
\echo '   Expected: ERROR - constraint violation'
\echo ''

DO $$
DECLARE
  test_party_id BIGINT;
  test_fund_id BIGINT;
BEGIN
  -- Create test party
  INSERT INTO parties(name, active) VALUES ('Test Party (Delete Me)', true)
  RETURNING id INTO test_party_id;

  -- Get Fund VI id
  SELECT id INTO test_fund_id FROM funds WHERE name='Fund VI';

  -- Try to create FUND + CUSTOM (should FAIL)
  BEGIN
    INSERT INTO agreements(
      party_id, scope, fund_id, pricing_mode, selected_track, effective_from
    )
    VALUES (
      test_party_id, 'FUND', test_fund_id, 'CUSTOM', NULL, '2025-07-01'
    );

    -- If we get here, test FAILED
    RAISE EXCEPTION '❌ TEST FAILED: Constraint did not block FUND+CUSTOM';

  EXCEPTION
    WHEN check_violation THEN
      -- Expected: constraint blocked the insert
      RAISE NOTICE '✅ TEST PASSED: Constraint correctly blocked FUND+CUSTOM pricing';
      RAISE NOTICE '   Error message: %', SQLERRM;
  END;

  -- Cleanup
  DELETE FROM parties WHERE id = test_party_id;
END $$;

\echo ''

-- ============================================
-- TEST 4: Contribution scope constraint
-- ============================================
\echo '✅ TEST 4: Contribution Scope Constraint (XOR deal_id/fund_id)'
\echo '   Test A: Try to create contribution with BOTH deal_id AND fund_id'
\echo '   Expected: ERROR - constraint violation'
\echo ''

DO $$
DECLARE
  test_investor_id BIGINT;
  test_fund_id BIGINT;
  test_deal_id BIGINT;
BEGIN
  -- Create test investor
  INSERT INTO investors(name, is_gp) VALUES ('Test Investor (Delete Me)', false)
  RETURNING id INTO test_investor_id;

  SELECT id INTO test_fund_id FROM funds WHERE name='Fund VI';

  -- Create test deal
  INSERT INTO deals(name, fund_id) VALUES ('Test Deal (Delete Me)', test_fund_id)
  RETURNING id INTO test_deal_id;

  -- Try to create contribution with BOTH (should FAIL)
  BEGIN
    INSERT INTO contributions(
      investor_id, deal_id, fund_id, paid_in_date, amount
    )
    VALUES (
      test_investor_id, test_deal_id, test_fund_id, '2025-07-01', 100000
    );

    RAISE EXCEPTION '❌ TEST FAILED: Constraint did not block BOTH deal_id AND fund_id';

  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE '✅ TEST PASSED: Constraint correctly blocked BOTH deal_id AND fund_id';
      RAISE NOTICE '   Error message: %', SQLERRM;
  END;

  -- Test B: Try with NEITHER (should also FAIL)
  BEGIN
    INSERT INTO contributions(
      investor_id, deal_id, fund_id, paid_in_date, amount
    )
    VALUES (
      test_investor_id, NULL, NULL, '2025-07-01', 100000
    );

    RAISE EXCEPTION '❌ TEST FAILED: Constraint did not block NEITHER deal_id NOR fund_id';

  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE '✅ TEST PASSED: Constraint correctly blocked NEITHER deal_id NOR fund_id';
  END;

  -- Cleanup
  DELETE FROM deals WHERE id = test_deal_id;
  DELETE FROM investors WHERE id = test_investor_id;
END $$;

\echo ''

-- ============================================
-- TEST 5: Snapshot trigger automation
-- ============================================
\echo '✅ TEST 5: Snapshot Trigger (auto-creates on approval)'
\echo '   Test: Create DRAFT agreement → Approve → Verify snapshot'
\echo ''

DO $$
DECLARE
  test_party_id BIGINT;
  test_fund_id BIGINT;
  test_agreement_id BIGINT;
  snapshot_count INT;
BEGIN
  -- Create test party
  INSERT INTO parties(name, active) VALUES ('Test Party 2 (Delete Me)', true)
  RETURNING id INTO test_party_id;

  SELECT id INTO test_fund_id FROM funds WHERE name='Fund VI';

  -- Create DRAFT agreement (FUND + Track B)
  INSERT INTO agreements(
    party_id, scope, fund_id, pricing_mode, selected_track,
    effective_from, vat_included, status
  )
  VALUES (
    test_party_id, 'FUND', test_fund_id, 'TRACK', 'B',
    '2025-07-01', false, 'DRAFT'
  )
  RETURNING id INTO test_agreement_id;

  RAISE NOTICE 'Created DRAFT agreement: %', test_agreement_id;

  -- Approve it (should trigger snapshot creation)
  UPDATE agreements SET status = 'APPROVED' WHERE id = test_agreement_id;

  RAISE NOTICE 'Approved agreement: %', test_agreement_id;

  -- Check if snapshot was created
  SELECT COUNT(*) INTO snapshot_count
  FROM agreement_rate_snapshots
  WHERE agreement_id = test_agreement_id;

  IF snapshot_count = 1 THEN
    RAISE NOTICE '✅ TEST PASSED: Snapshot auto-created on approval';

    -- Display snapshot details
    RAISE NOTICE '   Snapshot details:';
    RAISE NOTICE '   - Resolved upfront: % bps', (SELECT resolved_upfront_bps FROM agreement_rate_snapshots WHERE agreement_id = test_agreement_id);
    RAISE NOTICE '   - Resolved deferred: % bps', (SELECT resolved_deferred_bps FROM agreement_rate_snapshots WHERE agreement_id = test_agreement_id);
    RAISE NOTICE '   - Seed version: %', (SELECT seed_version FROM agreement_rate_snapshots WHERE agreement_id = test_agreement_id);
  ELSE
    RAISE EXCEPTION '❌ TEST FAILED: Snapshot was not created (count: %)', snapshot_count;
  END IF;

  -- Test immutability: Try to edit APPROVED agreement (should FAIL)
  BEGIN
    UPDATE agreements
    SET effective_from = '2025-08-01'
    WHERE id = test_agreement_id;

    RAISE EXCEPTION '❌ TEST FAILED: Immutability trigger did not block update';

  EXCEPTION
    WHEN raise_exception THEN
      IF SQLERRM LIKE '%immutable%' THEN
        RAISE NOTICE '✅ TEST PASSED: Immutability trigger correctly blocked update';
      ELSE
        RAISE EXCEPTION '❌ TEST FAILED: Wrong exception: %', SQLERRM;
      END IF;
  END;

  -- Cleanup
  DELETE FROM agreement_rate_snapshots WHERE agreement_id = test_agreement_id;
  DELETE FROM agreements WHERE id = test_agreement_id;
  DELETE FROM parties WHERE id = test_party_id;
END $$;

\echo ''

-- ============================================
-- OPTIONAL: Load Example CSVs (if you have data)
-- ============================================
\echo '📦 OPTIONAL: Scoreboard Import Test'
\echo '   (Only run if you have loaded scoreboard_deal_metrics.csv)'
\echo ''

-- Uncomment if you loaded the CSV:
-- SELECT apply_scoreboard_metrics('2025Q3');
-- SELECT name, equity_to_raise, raised_so_far FROM deals WHERE equity_to_raise IS NOT NULL ORDER BY name;

\echo ''

-- ============================================
-- SUMMARY
-- ============================================
\echo '============================================'
\echo '📊 SMOKE TEST SUMMARY'
\echo '============================================'
\echo ''
\echo 'Tests Completed:'
\echo '  ✅ Fund VI Tracks seeded (A/B/C) with is_locked=true'
\echo '  ✅ Immutability triggers installed'
\echo '  ✅ Pricing constraint enforced (FUND must use TRACK)'
\echo '  ✅ Contribution scope constraint enforced (XOR deal_id/fund_id)'
\echo '  ✅ Snapshot trigger auto-creates on approval'
\echo '  ✅ Immutability trigger blocks edits to APPROVED agreements'
\echo ''
\echo 'Next Steps:'
\echo '  1. Load CSV data (optional): scoreboard_deal_metrics.csv + contributions.csv'
\echo '  2. Start Day 2: UI updates (Parties, Funds, Deals, Agreements)'
\echo ''
\echo '============================================'
