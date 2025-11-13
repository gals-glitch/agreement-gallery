-- ============================================
-- Seed Pilot Data for P2 Smoke Testing
-- Purpose: Create minimal test data for charges workflow
-- ============================================
--
-- This script creates:
-- 1. 2 approved agreements (for existing Kuperman investors)
-- 2. 3 contributions (for testing charge computation)
-- 3. 2 credits (for testing FIFO auto-application)
--
-- ============================================

-- ============================================
-- Step 1: Get existing Kuperman investors
-- ============================================

DO $$
DECLARE
  investor1_id BIGINT;
  investor2_id BIGINT;
  deal1_id BIGINT;
  deal2_id BIGINT;
  party1_id BIGINT;
  party2_id BIGINT;
  admin_user_id UUID;
BEGIN
  -- Get first Kuperman investor
  SELECT id, party_id INTO investor1_id, party1_id
  FROM investors
  WHERE name ILIKE '%kuperman%'
  ORDER BY id
  LIMIT 1;

  -- Get second Kuperman investor (if exists)
  SELECT id, party_id INTO investor2_id, party2_id
  FROM investors
  WHERE name ILIKE '%kuperman%'
  ORDER BY id
  OFFSET 1
  LIMIT 1;

  -- Get two test deals
  SELECT id INTO deal1_id FROM deals ORDER BY id LIMIT 1;
  SELECT id INTO deal2_id FROM deals ORDER BY id OFFSET 1 LIMIT 1;

  -- Get admin user ID
  SELECT id INTO admin_user_id FROM auth.users WHERE email = 'gals@buligocapital.com';

  RAISE NOTICE 'Found investor 1: % (party: %)', investor1_id, party1_id;
  RAISE NOTICE 'Found investor 2: % (party: %)', investor2_id, party2_id;
  RAISE NOTICE 'Found deal 1: %', deal1_id;
  RAISE NOTICE 'Found deal 2: %', deal2_id;
  RAISE NOTICE 'Found admin user: %', admin_user_id;

  -- ============================================
  -- Step 2: Create Approved Agreements
  -- ============================================

  IF investor1_id IS NOT NULL AND deal1_id IS NOT NULL AND party1_id IS NOT NULL THEN
    -- Agreement 1: Deal-level agreement for investor 1
    -- 2% referral fee, 20% VAT, no discounts
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
      party1_id,
      deal1_id,
      NULL,
      'APPROVED',
      '2024-01-01',
      jsonb_build_object(
        'agreement_id', gen_random_uuid(),
        'version', 1,
        'terms', jsonb_build_array(
          jsonb_build_object(
            'start_date', '2024-01-01',
            'end_date', '2025-12-31',
            'resolved_upfront_bps', 200,  -- 2.00%
            'resolved_deferred_bps', 0,
            'vat_mode', 'on_top',
            'discounts', jsonb_build_array(),
            'cap', 50000
          )
        ),
        'vat_rate', 0.20
      ),
      NOW(),
      NOW()
    )
    ON CONFLICT DO NOTHING;

    RAISE NOTICE 'Created agreement 1 for investor % on deal %', investor1_id, deal1_id;
  END IF;

  IF investor2_id IS NOT NULL AND deal2_id IS NOT NULL AND party2_id IS NOT NULL THEN
    -- Agreement 2: Deal-level agreement for investor 2
    -- 1.5% referral fee, 20% VAT, no discounts
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
      party2_id,
      deal2_id,
      NULL,
      'APPROVED',
      '2024-01-01',
      jsonb_build_object(
        'agreement_id', gen_random_uuid(),
        'version', 1,
        'terms', jsonb_build_array(
          jsonb_build_object(
            'start_date', '2024-01-01',
            'end_date', '2025-12-31',
            'resolved_upfront_bps', 150,  -- 1.50%
            'resolved_deferred_bps', 0,
            'vat_mode', 'on_top',
            'discounts', jsonb_build_array(),
            'cap', 30000
          )
        ),
        'vat_rate', 0.20
      ),
      NOW(),
      NOW()
    )
    ON CONFLICT DO NOTHING;

    RAISE NOTICE 'Created agreement 2 for investor % on deal %', investor2_id, deal2_id;
  END IF;

  -- ============================================
  -- Step 3: Create Contributions
  -- ============================================

  IF investor1_id IS NOT NULL AND deal1_id IS NOT NULL THEN
    -- Contribution 1: $100,000 for investor 1
    -- Expected charge: 2% = $2,000 base + $400 VAT = $2,400 total
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
    )
    ON CONFLICT DO NOTHING;

    RAISE NOTICE 'Created contribution 1: $100,000 for investor %', investor1_id;

    -- Contribution 2: $50,000 for investor 1
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
      investor1_id,
      deal1_id,
      NULL,
      50000.00,
      '2024-06-20',
      'USD',
      NOW()
    )
    ON CONFLICT DO NOTHING;

    RAISE NOTICE 'Created contribution 2: $50,000 for investor %', investor1_id;
  END IF;

  IF investor2_id IS NOT NULL AND deal2_id IS NOT NULL THEN
    -- Contribution 3: $75,000 for investor 2
    -- Expected charge: 1.5% = $1,125 base + $225 VAT = $1,350 total
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
      75000.00,
      '2024-04-10',
      'USD',
      NOW()
    )
    ON CONFLICT DO NOTHING;

    RAISE NOTICE 'Created contribution 3: $75,000 for investor %', investor2_id;
  END IF;

  -- ============================================
  -- Step 4: Create Credits (for auto-apply testing)
  -- ============================================

  IF investor1_id IS NOT NULL AND deal1_id IS NOT NULL AND admin_user_id IS NOT NULL THEN
    -- Credit 1: $1,500 for investor 1 (deal-scoped)
    -- This will be auto-applied when charge is submitted
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
      investor1_id,
      deal1_id,
      NULL,
      1500.00,
      0,
      'AVAILABLE',
      'Test credit for smoke testing - will auto-apply to charges',
      admin_user_id,
      NOW()
    )
    ON CONFLICT DO NOTHING;

    RAISE NOTICE 'Created credit 1: $1,500 for investor % on deal %', investor1_id, deal1_id;
  END IF;

  IF investor2_id IS NOT NULL AND deal2_id IS NOT NULL AND admin_user_id IS NOT NULL THEN
    -- Credit 2: $500 for investor 2 (deal-scoped)
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
      investor2_id,
      deal2_id,
      NULL,
      500.00,
      0,
      'AVAILABLE',
      'Test credit for smoke testing - partial application test',
      admin_user_id,
      NOW()
    )
    ON CONFLICT DO NOTHING;

    RAISE NOTICE 'Created credit 2: $500 for investor % on deal %', investor2_id, deal2_id;
  END IF;

  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'SEED DATA CREATION COMPLETE';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Created:';
  RAISE NOTICE '- 2 approved agreements';
  RAISE NOTICE '- 3 contributions ($100k, $50k, $75k)';
  RAISE NOTICE '- 2 credits ($1.5k, $500)';
  RAISE NOTICE '';
  RAISE NOTICE 'Next: Run verification query to confirm';
  RAISE NOTICE '========================================';

END $$;

-- ============================================
-- Verification Query (run separately)
-- ============================================

/*
-- Run this to verify seed data was created:

SELECT
  'investors' AS table_name,
  COUNT(*) AS count
FROM investors
WHERE name ILIKE '%kuperman%'

UNION ALL

SELECT 'agreements (approved)', COUNT(*)
FROM agreements
WHERE status = 'APPROVED'

UNION ALL

SELECT 'contributions', COUNT(*)
FROM contributions

UNION ALL

SELECT 'credits_ledger (available)', COUNT(*)
FROM credits_ledger
WHERE status = 'AVAILABLE'

ORDER BY table_name;

-- Expected output:
-- agreements (approved): 2
-- contributions: 3
-- credits_ledger (available): 2
-- investors: 2
*/

-- ============================================
-- Detailed View (optional - see what was created)
-- ============================================

/*
-- View agreements created
SELECT
  a.id,
  p.name AS party_name,
  d.name AS deal_name,
  a.status,
  a.snapshot_json->'terms'->0->>'resolved_upfront_bps' AS rate_bps,
  a.snapshot_json->>'vat_rate' AS vat_rate
FROM agreements a
JOIN parties p ON a.party_id = p.id
LEFT JOIN deals d ON a.deal_id = d.id
WHERE a.status = 'APPROVED'
ORDER BY a.created_at DESC;

-- View contributions created
SELECT
  c.id,
  i.name AS investor_name,
  d.name AS deal_name,
  c.amount,
  c.paid_in_date,
  c.currency
FROM contributions c
JOIN investors i ON c.investor_id = i.id
LEFT JOIN deals d ON c.deal_id = d.id
ORDER BY c.created_at DESC
LIMIT 10;

-- View credits created
SELECT
  cl.id,
  i.name AS investor_name,
  d.name AS deal_name,
  cl.original_amount,
  cl.available_amount,
  cl.status,
  cl.reason
FROM credits_ledger cl
JOIN investors i ON cl.investor_id = i.id
LEFT JOIN deals d ON cl.deal_id = d.id
WHERE cl.status = 'AVAILABLE'
ORDER BY cl.created_at DESC;
*/
