-- ============================================
-- Seed P2 Test Data (Corrected Schema)
-- Purpose: Create minimal test data for charges workflow
-- Date: 2025-10-19
-- ============================================
--
-- This script creates:
-- 1. 2 APPROVED agreements (DEAL + CUSTOM pricing)
-- 2. 2 contributions ($100k, $50k)
-- 3. (Credits skipped - constraint issue)
--
-- Schema:
-- - agreements: scope=DEAL, pricing_mode=CUSTOM, status=APPROVED
-- - agreement_custom_terms: upfront_bps, deferred_bps
-- - contributions: linked to deals
-- ============================================

DO $$
DECLARE
  investor1_id BIGINT;
  investor2_id BIGINT;
  party1_id BIGINT;
  party2_id BIGINT;
  deal1_id BIGINT;
  deal2_id BIGINT;
  agreement1_id BIGINT;
  agreement2_id BIGINT;
BEGIN
  -- ============================================
  -- Step 1: Find existing Kuperman investors
  -- ============================================

  SELECT id, party_id INTO investor1_id, party1_id
  FROM investors
  WHERE name ILIKE '%kuperman%'
  ORDER BY id
  LIMIT 1;

  SELECT id, party_id INTO investor2_id, party2_id
  FROM investors
  WHERE name ILIKE '%kuperman%'
  ORDER BY id
  OFFSET 1
  LIMIT 1;

  -- Get two test deals
  SELECT id INTO deal1_id FROM deals ORDER BY id LIMIT 1;
  SELECT id INTO deal2_id FROM deals ORDER BY id OFFSET 1 LIMIT 1;

  RAISE NOTICE 'Found:';
  RAISE NOTICE '  Investor 1: % (party: %)', investor1_id, party1_id;
  RAISE NOTICE '  Investor 2: % (party: %)', investor2_id, party2_id;
  RAISE NOTICE '  Deal 1: %', deal1_id;
  RAISE NOTICE '  Deal 2: %', deal2_id;

  -- ============================================
  -- Step 2: Create Agreement 1 (1% equity)
  -- ============================================

  IF party1_id IS NOT NULL AND deal1_id IS NOT NULL THEN
    -- Create APPROVED agreement with DEAL scope + CUSTOM pricing
    INSERT INTO agreements (
      party_id,
      scope,
      deal_id,
      pricing_mode,
      effective_from,
      effective_to,
      vat_included,
      status,
      created_at,
      updated_at
    )
    VALUES (
      party1_id,
      'DEAL',           -- Deal-level agreement
      deal1_id,
      'CUSTOM',         -- Custom rates (not track-based)
      '2024-01-01',     -- Start date
      NULL,             -- No end date (ongoing)
      false,            -- VAT added on top (not included)
      'APPROVED',       -- Pre-approved for testing
      NOW(),
      NOW()
    )
    RETURNING id INTO agreement1_id;

    -- Create custom terms: 1% upfront (100 bps), 0% deferred
    INSERT INTO agreement_custom_terms (
      agreement_id,
      upfront_bps,
      deferred_bps,
      created_at
    )
    VALUES (
      agreement1_id,
      100,              -- 1.00% upfront
      0,                -- 0% deferred
      NOW()
    );

    -- Create rate snapshot (immutable at approval time)
    INSERT INTO agreement_rate_snapshots (
      agreement_id,
      scope,
      pricing_mode,
      resolved_upfront_bps,
      resolved_deferred_bps,
      vat_included,
      effective_from,
      effective_to,
      approved_at
    )
    VALUES (
      agreement1_id,
      'DEAL',
      'CUSTOM',
      100,              -- 1% resolved
      0,
      false,
      '2024-01-01',
      NULL,
      NOW()
    );

    RAISE NOTICE '✅ Created Agreement 1: Party % → Deal % (1%% equity)', party1_id, deal1_id;

    -- Create contribution: $100,000
    -- Expected charge: 1% = $1,000 base + $200 VAT (20%) = $1,200 total
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

    RAISE NOTICE '✅ Created Contribution 1: $100k for investor %', investor1_id;
  ELSE
    RAISE NOTICE '⚠️ Skipping Agreement 1 - missing party or deal';
  END IF;

  -- ============================================
  -- Step 3: Create Agreement 2 (2% equity)
  -- ============================================

  IF party2_id IS NOT NULL AND deal2_id IS NOT NULL THEN
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
      created_at,
      updated_at
    )
    VALUES (
      party2_id,
      'DEAL',
      deal2_id,
      'CUSTOM',
      '2024-01-01',
      NULL,
      false,
      'APPROVED',
      NOW(),
      NOW()
    )
    RETURNING id INTO agreement2_id;

    -- Create custom terms: 2% upfront (200 bps)
    INSERT INTO agreement_custom_terms (
      agreement_id,
      upfront_bps,
      deferred_bps,
      created_at
    )
    VALUES (
      agreement2_id,
      200,              -- 2.00% upfront
      0,
      NOW()
    );

    -- Create rate snapshot
    INSERT INTO agreement_rate_snapshots (
      agreement_id,
      scope,
      pricing_mode,
      resolved_upfront_bps,
      resolved_deferred_bps,
      vat_included,
      effective_from,
      effective_to,
      approved_at
    )
    VALUES (
      agreement2_id,
      'DEAL',
      'CUSTOM',
      200,              -- 2% resolved
      0,
      false,
      '2024-01-01',
      NULL,
      NOW()
    );

    RAISE NOTICE '✅ Created Agreement 2: Party % → Deal % (2%% equity)', party2_id, deal2_id;

    -- Create contribution: $50,000
    -- Expected charge: 2% = $1,000 base + $200 VAT = $1,200 total
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

    RAISE NOTICE '✅ Created Contribution 2: $50k for investor %', investor2_id;
  ELSE
    RAISE NOTICE '⚠️ Skipping Agreement 2 - missing party or deal';
  END IF;

  -- ============================================
  -- Summary
  -- ============================================

  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'SEED DATA COMPLETE';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Created:';
  RAISE NOTICE '  - 2 APPROVED agreements (DEAL + CUSTOM)';
  RAISE NOTICE '  - 2 contributions ($100k, $50k)';
  RAISE NOTICE '  - 2 rate snapshots';
  RAISE NOTICE '';
  RAISE NOTICE 'Next: Verify with count query';
  RAISE NOTICE '========================================';

END $$;

-- ============================================
-- Verification Query (run after seed completes)
-- ============================================

/*
Run this to verify:

SELECT
  'Agreements (APPROVED)' AS entity,
  COUNT(*) AS count
FROM agreements
WHERE status = 'APPROVED'

UNION ALL

SELECT
  'Custom Terms' AS entity,
  COUNT(*) AS count
FROM agreement_custom_terms

UNION ALL

SELECT
  'Rate Snapshots' AS entity,
  COUNT(*) AS count
FROM agreement_rate_snapshots

UNION ALL

SELECT
  'Contributions' AS entity,
  COUNT(*) AS count
FROM contributions

ORDER BY entity;

Expected:
- Agreements (APPROVED): 2
- Contributions: 2
- Custom Terms: 2
- Rate Snapshots: 2
*/
