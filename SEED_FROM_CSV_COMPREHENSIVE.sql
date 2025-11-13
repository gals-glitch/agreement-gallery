-- ============================================
-- Seed P2 Test Data from CSV
-- Source: referral_agreements_structured_FIXED_20251019_110933.csv
-- Purpose: Create parties, agreements, and contributions for smoke testing
-- Date: 2025-10-19
-- ============================================
--
-- CSV Structure:
-- - Column A: Distributor/Party (e.g., "Kuperman")
-- - Column B: Investor (e.g., "Kuperman Entity")
-- - Column C: term_type (equity_percent, commission_percent)
-- - Column D: rate_percent (1.0, 25.0, etc.)
--
-- This script creates:
-- 1. Party: "Kuperman" (distributor/referrer)
-- 2. 2 APPROVED agreements for Kuperman's investors
-- 3. 2 contributions ($100k, $50k) for testing
-- ============================================

DO $$
DECLARE
  -- IDs
  kuperman_party_id BIGINT;
  investor1_id BIGINT;
  investor2_id BIGINT;
  deal1_id BIGINT;
  deal2_id BIGINT;
  agreement1_id BIGINT;
  agreement2_id BIGINT;

  -- Names for logging
  investor1_name TEXT;
  investor2_name TEXT;
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Starting P2 Data Seed from CSV';
  RAISE NOTICE '========================================';
  RAISE NOTICE '';

  -- ============================================
  -- Step 1: Create "Kuperman" Party
  -- ============================================

  INSERT INTO parties (name, email, country, active, notes, created_at, updated_at)
  VALUES (
    'Kuperman',
    'tsahi@kupermanbros.com',
    'Israel',
    true,
    'Distributor/Referrer from CSV - Contact: Tsahi Weiss',
    NOW(),
    NOW()
  )
  RETURNING id INTO kuperman_party_id;

  RAISE NOTICE '✅ Created Party: Kuperman (ID: %)', kuperman_party_id;
  RAISE NOTICE '';

  -- ============================================
  -- Step 2: Find Existing Kuperman Investors
  -- ============================================

  SELECT id, name INTO investor1_id, investor1_name
  FROM investors
  WHERE name ILIKE '%kuperman%'
  ORDER BY id
  LIMIT 1;

  SELECT id, name INTO investor2_id, investor2_name
  FROM investors
  WHERE name ILIKE '%kuperman%'
  ORDER BY id
  OFFSET 1
  LIMIT 1;

  RAISE NOTICE 'Found Investors:';
  RAISE NOTICE '  - Investor 1: % (ID: %)', investor1_name, investor1_id;
  RAISE NOTICE '  - Investor 2: % (ID: %)', investor2_name, investor2_id;
  RAISE NOTICE '';

  -- ============================================
  -- Step 3: Get Test Deals
  -- ============================================

  SELECT id INTO deal1_id FROM deals ORDER BY id LIMIT 1;
  SELECT id INTO deal2_id FROM deals ORDER BY id OFFSET 1 LIMIT 1;

  RAISE NOTICE 'Using Deals:';
  RAISE NOTICE '  - Deal 1: ID %', deal1_id;
  RAISE NOTICE '  - Deal 2: ID %', deal2_id;
  RAISE NOTICE '';

  -- ============================================
  -- Step 4: Create Agreement 1 (1% equity)
  -- CSV Row 2: Kuperman, Kuperman Entity, equity_percent, 1.0
  -- ============================================

  IF kuperman_party_id IS NOT NULL AND investor1_id IS NOT NULL AND deal1_id IS NOT NULL THEN
    -- Create APPROVED agreement (DEAL + CUSTOM)
    INSERT INTO agreements (
      party_id,
      scope,
      deal_id,
      pricing_mode,
      effective_from,
      effective_to,
      vat_included,
      status,
      created_by,
      created_at,
      updated_at
    )
    VALUES (
      kuperman_party_id,
      'DEAL',           -- Deal-level agreement
      deal1_id,
      'CUSTOM',         -- Custom rates (not track-based)
      '2024-01-01',     -- Effective from
      NULL,             -- No end date (ongoing)
      false,            -- VAT on top (20%)
      'APPROVED',       -- Pre-approved for testing
      'system',         -- Created by system seed
      NOW(),
      NOW()
    )
    RETURNING id INTO agreement1_id;

    -- Create custom terms: 1% upfront (100 bps), 0% deferred
    INSERT INTO agreement_custom_terms (
      agreement_id,
      upfront_bps,
      deferred_bps,
      caps_json,
      tiers_json,
      created_at
    )
    VALUES (
      agreement1_id,
      100,              -- 1.00% upfront (from CSV)
      0,                -- 0% deferred
      NULL,             -- No caps
      NULL,             -- No tiers
      NOW()
    );

    -- Create immutable rate snapshot (captured at approval time)
    INSERT INTO agreement_rate_snapshots (
      agreement_id,
      scope,
      pricing_mode,
      track_code,
      resolved_upfront_bps,
      resolved_deferred_bps,
      vat_included,
      effective_from,
      effective_to,
      seed_version,
      approved_at
    )
    VALUES (
      agreement1_id,
      'DEAL',
      'CUSTOM',
      NULL,             -- No track code (CUSTOM mode)
      100,              -- 1% resolved
      0,                -- 0% deferred
      false,            -- VAT on top
      '2024-01-01',
      NULL,
      NULL,             -- No seed version (CUSTOM)
      NOW()
    );

    RAISE NOTICE '✅ Agreement 1 Created:';
    RAISE NOTICE '   - ID: %', agreement1_id;
    RAISE NOTICE '   - Party: Kuperman (ID: %)', kuperman_party_id;
    RAISE NOTICE '   - Deal: % (ID: %)', deal1_id, deal1_id;
    RAISE NOTICE '   - Rate: 1%% equity (100 bps)';
    RAISE NOTICE '   - Status: APPROVED';
    RAISE NOTICE '';

    -- Create contribution: $100,000 paid-in
    -- Expected charge: 1% × $100k = $1,000 base
    --                  + 20% VAT = $200
    --                  = $1,200 total
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
      investor1_id,
      deal1_id,
      NULL,
      100000.00,
      '2024-03-15',
      'USD',
      NOW()
    );

    RAISE NOTICE '✅ Contribution 1 Created:';
    RAISE NOTICE '   - Investor: % (ID: %)', investor1_name, investor1_id;
    RAISE NOTICE '   - Amount: $100,000';
    RAISE NOTICE '   - Expected Charge: $1,000 base + $200 VAT = $1,200';
    RAISE NOTICE '';

  ELSE
    RAISE NOTICE '⚠️ Skipping Agreement 1 - missing party, investor, or deal';
  END IF;

  -- ============================================
  -- Step 5: Create Agreement 2 (2% equity)
  -- Using second investor as different rate example
  -- ============================================

  IF kuperman_party_id IS NOT NULL AND investor2_id IS NOT NULL AND deal2_id IS NOT NULL THEN
    -- Create APPROVED agreement
    INSERT INTO agreements (
      party_id,
      scope,
      deal_id,
      pricing_mode,
      effective_from,
      effective_to,
      vat_included,
      status,
      created_by,
      created_at,
      updated_at
    )
    VALUES (
      kuperman_party_id,
      'DEAL',
      deal2_id,
      'CUSTOM',
      '2024-01-01',
      NULL,
      false,
      'APPROVED',
      'system',
      NOW(),
      NOW()
    )
    RETURNING id INTO agreement2_id;

    -- Create custom terms: 2% upfront (200 bps)
    INSERT INTO agreement_custom_terms (
      agreement_id,
      upfront_bps,
      deferred_bps,
      caps_json,
      tiers_json,
      created_at
    )
    VALUES (
      agreement2_id,
      200,              -- 2.00% upfront
      0,
      NULL,
      NULL,
      NOW()
    );

    -- Create rate snapshot
    INSERT INTO agreement_rate_snapshots (
      agreement_id,
      scope,
      pricing_mode,
      track_code,
      resolved_upfront_bps,
      resolved_deferred_bps,
      vat_included,
      effective_from,
      effective_to,
      seed_version,
      approved_at
    )
    VALUES (
      agreement2_id,
      'DEAL',
      'CUSTOM',
      NULL,
      200,              -- 2% resolved
      0,
      false,
      '2024-01-01',
      NULL,
      NULL,
      NOW()
    );

    RAISE NOTICE '✅ Agreement 2 Created:';
    RAISE NOTICE '   - ID: %', agreement2_id;
    RAISE NOTICE '   - Party: Kuperman (ID: %)', kuperman_party_id;
    RAISE NOTICE '   - Deal: % (ID: %)', deal2_id, deal2_id;
    RAISE NOTICE '   - Rate: 2%% equity (200 bps)';
    RAISE NOTICE '   - Status: APPROVED';
    RAISE NOTICE '';

    -- Create contribution: $50,000
    -- Expected charge: 2% × $50k = $1,000 base
    --                  + 20% VAT = $200
    --                  = $1,200 total
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
      investor2_id,
      deal2_id,
      NULL,
      50000.00,
      '2024-06-20',
      'USD',
      NOW()
    );

    RAISE NOTICE '✅ Contribution 2 Created:';
    RAISE NOTICE '   - Investor: % (ID: %)', investor2_name, investor2_id;
    RAISE NOTICE '   - Amount: $50,000';
    RAISE NOTICE '   - Expected Charge: $1,000 base + $200 VAT = $1,200';
    RAISE NOTICE '';

  ELSE
    RAISE NOTICE '⚠️ Skipping Agreement 2 - missing party, investor, or deal';
  END IF;

  -- ============================================
  -- Summary
  -- ============================================

  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'SEED DATA COMPLETE';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Created:';
  RAISE NOTICE '  ✅ 1 party (Kuperman)';
  RAISE NOTICE '  ✅ 2 APPROVED agreements (1%%, 2%%)';
  RAISE NOTICE '  ✅ 2 custom_terms records';
  RAISE NOTICE '  ✅ 2 rate_snapshots (immutable)';
  RAISE NOTICE '  ✅ 2 contributions ($100k, $50k)';
  RAISE NOTICE '';
  RAISE NOTICE 'Ready for smoke testing!';
  RAISE NOTICE '========================================';

END $$;
