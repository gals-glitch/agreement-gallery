-- ============================================
-- Import Real Agreements from CSV
-- Source: referral_agreements_structured_FIXED_20251019_110933.csv
-- Purpose: Create approved agreements for distributors/investors
-- ============================================
--
-- CSV Structure:
-- distributor, investor, term_type, rate_percent, start_date, end_date, clause, invoicing
--
-- Example rows:
-- Kuperman, Kuperman Entity, equity_percent, 1.0, , , none, Upfront - Invoice to Partners
-- Kuperman, Yaniv Radia, commission_percent, 25.0, , 2018-02-01, before, Promote - Invoice to Partners
--
-- This script will:
-- 1. Find matching parties (distributors) and investors
-- 2. Create approved agreements with rates from CSV
-- 3. Handle multiple terms per investor (e.g., Gadi Gerbi has 2 terms)
-- 4. Create contributions for Kuperman investors for testing
--
-- ============================================

-- ============================================
-- Step 1: Create Approved Agreement for Kuperman Entity
-- ============================================
-- CSV Row: Kuperman, Kuperman Entity, equity_percent, 1.0%

DO $$
DECLARE
  kuperman_party_id BIGINT;
  kuperman_entity_investor_id BIGINT;
  test_deal_id BIGINT;
  admin_user_id UUID;
BEGIN
  -- Find Kuperman party (distributor)
  SELECT id INTO kuperman_party_id
  FROM parties
  WHERE name ILIKE '%kuperman%'
  ORDER BY id
  LIMIT 1;

  -- Find Kuperman Entity investor
  SELECT id INTO kuperman_entity_investor_id
  FROM investors
  WHERE name ILIKE '%kuperman%'
  ORDER BY id
  LIMIT 1;

  -- Get a test deal
  SELECT id INTO test_deal_id FROM deals ORDER BY id LIMIT 1;

  -- Get admin user
  SELECT id INTO admin_user_id FROM auth.users WHERE email = 'gals@buligocapital.com';

  RAISE NOTICE 'Kuperman party ID: %', kuperman_party_id;
  RAISE NOTICE 'Kuperman Entity investor ID: %', kuperman_entity_investor_id;
  RAISE NOTICE 'Test deal ID: %', test_deal_id;

  IF kuperman_party_id IS NOT NULL AND kuperman_entity_investor_id IS NOT NULL AND test_deal_id IS NOT NULL THEN
    -- Create approved agreement with 1% equity rate
    INSERT INTO agreements (
      party_id,
      deal_id,
      fund_id,
      status,
      effective_date,
      snapshot_json,
      created_at,
      updated_at
    )
    VALUES (
      kuperman_party_id,
      test_deal_id,
      NULL,
      'APPROVED',
      '2024-01-01',
      jsonb_build_object(
        'agreement_id', gen_random_uuid(),
        'version', 1,
        'distributor', 'Kuperman',
        'investor', 'Kuperman Entity',
        'terms', jsonb_build_array(
          jsonb_build_object(
            'start_date', NULL,  -- No start date = from beginning
            'end_date', NULL,    -- No end date = ongoing
            'resolved_upfront_bps', 100,  -- 1.0% equity = 100 bps
            'resolved_deferred_bps', 0,
            'vat_mode', 'on_top',
            'discounts', jsonb_build_array(),
            'cap', NULL,  -- No cap
            'term_type', 'equity_percent',
            'rate_percent', 1.0,
            'clause', 'none',
            'invoicing', 'Upfront - Invoice to Partners'
          )
        ),
        'vat_rate', 0.20,
        'source', 'CSV Import - referral_agreements_structured_FIXED_20251019_110933.csv'
      ),
      NOW(),
      NOW()
    )
    ON CONFLICT DO NOTHING;

    RAISE NOTICE '✅ Created agreement: Kuperman → Kuperman Entity (1%% equity)';

    -- Create test contribution for Kuperman Entity
    -- $100,000 contribution → 1% fee = $1,000 base + $200 VAT = $1,200 total
    INSERT INTO contributions (
      investor_id,
      deal_id,
      fund_id,
      amount,
      paid_in_date,
      currency,
      created_at
    )
    VALUES (
      kuperman_entity_investor_id,
      test_deal_id,
      NULL,
      100000.00,
      '2024-03-15',
      'USD',
      NOW()
    )
    ON CONFLICT DO NOTHING;

    RAISE NOTICE '✅ Created contribution: $100,000 for Kuperman Entity';

  ELSE
    RAISE NOTICE '⚠️ Skipping Kuperman Entity - missing party or investor';
  END IF;

END $$;

-- ============================================
-- Step 2: Create Tiered Agreement for Gadi Gerbi
-- ============================================
-- CSV Rows:
-- Kuperman, Gadi Gerbi, commission_percent, 30.0, 2020-12-12, 2020-10-31, between
-- Kuperman, Gadi Gerbi, commission_percent, 35.0, 2020-10-31, , after

DO $$
DECLARE
  kuperman_party_id BIGINT;
  gadi_gerbi_investor_id BIGINT;
  test_deal_id BIGINT;
BEGIN
  -- Find parties/investors
  SELECT id INTO kuperman_party_id FROM parties WHERE name ILIKE '%kuperman%' LIMIT 1;
  SELECT id INTO gadi_gerbi_investor_id FROM investors WHERE name ILIKE '%gadi%gerbi%' LIMIT 1;
  SELECT id INTO test_deal_id FROM deals ORDER BY id LIMIT 1;

  IF kuperman_party_id IS NOT NULL AND gadi_gerbi_investor_id IS NOT NULL AND test_deal_id IS NOT NULL THEN
    -- Multi-term agreement: 30% (Dec 12 - Oct 31, 2020), then 35% (after Oct 31, 2020)
    INSERT INTO agreements (
      party_id,
      deal_id,
      fund_id,
      status,
      effective_date,
      snapshot_json,
      created_at,
      updated_at
    )
    VALUES (
      kuperman_party_id,
      test_deal_id,
      NULL,
      'APPROVED',
      '2020-12-12',
      jsonb_build_object(
        'agreement_id', gen_random_uuid(),
        'version', 1,
        'distributor', 'Kuperman',
        'investor', 'Gadi Gerbi',
        'terms', jsonb_build_array(
          -- Term 1: 30% between Dec 12 - Oct 31, 2020
          jsonb_build_object(
            'start_date', '2020-12-12',
            'end_date', '2020-10-31',
            'resolved_upfront_bps', 3000,  -- 30% = 3000 bps
            'resolved_deferred_bps', 0,
            'vat_mode', 'on_top',
            'discounts', jsonb_build_array(),
            'cap', NULL,
            'term_type', 'commission_percent',
            'rate_percent', 30.0,
            'clause', 'between'
          ),
          -- Term 2: 35% after Oct 31, 2020
          jsonb_build_object(
            'start_date', '2020-10-31',
            'end_date', NULL,
            'resolved_upfront_bps', 3500,  -- 35% = 3500 bps
            'resolved_deferred_bps', 0,
            'vat_mode', 'on_top',
            'discounts', jsonb_build_array(),
            'cap', NULL,
            'term_type', 'commission_percent',
            'rate_percent', 35.0,
            'clause', 'after'
          )
        ),
        'vat_rate', 0.20,
        'source', 'CSV Import'
      ),
      NOW(),
      NOW()
    )
    ON CONFLICT DO NOTHING;

    RAISE NOTICE '✅ Created tiered agreement: Kuperman → Gadi Gerbi (30%% → 35%%)';

    -- Create contribution after the tier change (should use 35% rate)
    IF gadi_gerbi_investor_id IS NOT NULL THEN
      INSERT INTO contributions (
        investor_id,
        deal_id,
        fund_id,
        amount,
        paid_in_date,
        currency,
        created_at
      )
      VALUES (
        gadi_gerbi_investor_id,
        test_deal_id,
        NULL,
        50000.00,
        '2021-01-15',  -- After Oct 31, 2020 → uses 35% rate
        'USD',
        NOW()
      )
      ON CONFLICT DO NOTHING;

      RAISE NOTICE '✅ Created contribution: $50,000 for Gadi Gerbi (should use 35%% rate)';
    END IF;

  ELSE
    RAISE NOTICE '⚠️ Skipping Gadi Gerbi - missing party or investor';
  END IF;

END $$;

-- ============================================
-- Step 3: Create Agreement for Gil Serok Revocable Trust
-- ============================================
-- CSV: Kuperman, Gil Serok Revocable Trust, commission_percent, 27.0, 2018-02-01, 2019-12-12, between

DO $$
DECLARE
  kuperman_party_id BIGINT;
  gil_serok_investor_id BIGINT;
  test_deal_id BIGINT;
BEGIN
  SELECT id INTO kuperman_party_id FROM parties WHERE name ILIKE '%kuperman%' LIMIT 1;
  SELECT id INTO gil_serok_investor_id FROM investors WHERE name ILIKE '%gil%serok%' LIMIT 1;
  SELECT id INTO test_deal_id FROM deals ORDER BY id LIMIT 1;

  IF kuperman_party_id IS NOT NULL AND gil_serok_investor_id IS NOT NULL AND test_deal_id IS NOT NULL THEN
    INSERT INTO agreements (
      party_id,
      deal_id,
      fund_id,
      status,
      effective_date,
      snapshot_json,
      created_at,
      updated_at
    )
    VALUES (
      kuperman_party_id,
      test_deal_id,
      NULL,
      'APPROVED',
      '2018-02-01',
      jsonb_build_object(
        'agreement_id', gen_random_uuid(),
        'version', 1,
        'distributor', 'Kuperman',
        'investor', 'Gil Serok Revocable Trust',
        'terms', jsonb_build_array(
          jsonb_build_object(
            'start_date', '2018-02-01',
            'end_date', '2019-12-12',
            'resolved_upfront_bps', 2700,  -- 27% = 2700 bps
            'resolved_deferred_bps', 0,
            'vat_mode', 'on_top',
            'discounts', jsonb_build_array(),
            'cap', NULL,
            'term_type', 'commission_percent',
            'rate_percent', 27.0,
            'clause', 'between'
          )
        ),
        'vat_rate', 0.20,
        'source', 'CSV Import'
      ),
      NOW(),
      NOW()
    )
    ON CONFLICT DO NOTHING;

    RAISE NOTICE '✅ Created agreement: Kuperman → Gil Serok Trust (27%%)';

    -- Create contribution within term window
    IF gil_serok_investor_id IS NOT NULL THEN
      INSERT INTO contributions (
        investor_id,
        deal_id,
        fund_id,
        amount,
        paid_in_date,
        currency,
        created_at
      )
      VALUES (
        gil_serok_investor_id,
        test_deal_id,
        NULL,
        75000.00,
        '2019-06-15',  -- Within Feb 2018 - Dec 2019 window
        'USD',
        NOW()
      )
      ON CONFLICT DO NOTHING;

      RAISE NOTICE '✅ Created contribution: $75,000 for Gil Serok Trust';
    END IF;

  ELSE
    RAISE NOTICE '⚠️ Skipping Gil Serok - missing party or investor';
  END IF;

END $$;

-- ============================================
-- Step 4: Create Test Credits for Auto-Apply Testing
-- ============================================

DO $$
DECLARE
  kuperman_entity_investor_id BIGINT;
  test_deal_id BIGINT;
  admin_user_id UUID;
BEGIN
  SELECT id INTO kuperman_entity_investor_id FROM investors WHERE name ILIKE '%kuperman%' ORDER BY id LIMIT 1;
  SELECT id INTO test_deal_id FROM deals ORDER BY id LIMIT 1;
  SELECT id INTO admin_user_id FROM auth.users WHERE email = 'gals@buligocapital.com';

  IF kuperman_entity_investor_id IS NOT NULL AND test_deal_id IS NOT NULL AND admin_user_id IS NOT NULL THEN
    -- Create $500 credit for Kuperman Entity (will partially offset $1,200 charge)
    INSERT INTO credits_ledger (
      investor_id,
      deal_id,
      fund_id,
      original_amount,
      applied_amount,
      status,
      reason,
      created_by,
      created_at
    )
    VALUES (
      kuperman_entity_investor_id,
      test_deal_id,
      NULL,
      500.00,
      0,
      'AVAILABLE',
      'Test credit for FIFO auto-application smoke test',
      admin_user_id,
      NOW()
    )
    ON CONFLICT DO NOTHING;

    RAISE NOTICE '✅ Created credit: $500 for Kuperman Entity';
  END IF;

END $$;

-- ============================================
-- Verification Query
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'IMPORT COMPLETE';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Run verification query to confirm:';
  RAISE NOTICE '';
  RAISE NOTICE 'SELECT';
  RAISE NOTICE '  a.id,';
  RAISE NOTICE '  p.name AS distributor,';
  RAISE NOTICE '  a.snapshot_json->''investor'' AS investor,';
  RAISE NOTICE '  a.status,';
  RAISE NOTICE '  jsonb_array_length(a.snapshot_json->''terms'') AS term_count';
  RAISE NOTICE 'FROM agreements a';
  RAISE NOTICE 'JOIN parties p ON a.party_id = p.id';
  RAISE NOTICE 'WHERE a.status = ''APPROVED''';
  RAISE NOTICE 'ORDER BY a.created_at DESC;';
  RAISE NOTICE '========================================';
END $$;
