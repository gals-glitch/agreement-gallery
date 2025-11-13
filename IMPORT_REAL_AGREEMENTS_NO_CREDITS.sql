-- ============================================
-- Import Real Agreements (Without Credits)
-- Simplified version - agreements and contributions only
-- ============================================

-- ============================================
-- Agreement 1: Kuperman → Kuperman Entity (1% equity)
-- ============================================

DO $$
DECLARE
  kuperman_party_id BIGINT;
  kuperman_entity_investor_id BIGINT;
  test_deal_id BIGINT;
BEGIN
  SELECT id INTO kuperman_party_id FROM parties WHERE name ILIKE '%kuperman%' LIMIT 1;
  SELECT id INTO kuperman_entity_investor_id FROM investors WHERE name ILIKE '%kuperman%' ORDER BY id LIMIT 1;
  SELECT id INTO test_deal_id FROM deals ORDER BY id LIMIT 1;

  RAISE NOTICE 'Party: %, Investor: %, Deal: %', kuperman_party_id, kuperman_entity_investor_id, test_deal_id;

  IF kuperman_party_id IS NOT NULL AND kuperman_entity_investor_id IS NOT NULL AND test_deal_id IS NOT NULL THEN
    -- Agreement
    INSERT INTO agreements (
      party_id, deal_id, fund_id, status, effective_date,
      snapshot_json, created_at, updated_at
    )
    VALUES (
      kuperman_party_id, test_deal_id, NULL, 'APPROVED', '2024-01-01',
      jsonb_build_object(
        'agreement_id', gen_random_uuid(),
        'version', 1,
        'terms', jsonb_build_array(
          jsonb_build_object(
            'start_date', NULL,
            'end_date', NULL,
            'resolved_upfront_bps', 100,  -- 1.0%
            'resolved_deferred_bps', 0,
            'vat_mode', 'on_top',
            'discounts', jsonb_build_array(),
            'cap', NULL
          )
        ),
        'vat_rate', 0.20
      ),
      NOW(), NOW()
    )
    ON CONFLICT DO NOTHING;

    -- Contribution: $100k → 1% = $1,000 base + $200 VAT = $1,200 total
    INSERT INTO contributions (
      investor_id, deal_id, fund_id, amount, paid_in_date, currency, created_at
    )
    VALUES (
      kuperman_entity_investor_id, test_deal_id, NULL,
      100000.00, '2024-03-15', 'USD', NOW()
    )
    ON CONFLICT DO NOTHING;

    RAISE NOTICE '✅ Created: Kuperman → Kuperman Entity (1%%, $100k contribution)';
  END IF;
END $$;

-- ============================================
-- Agreement 2: Kuperman → 2nd Investor (if exists)
-- ============================================

DO $$
DECLARE
  kuperman_party_id BIGINT;
  investor2_id BIGINT;
  test_deal_id BIGINT;
BEGIN
  SELECT id INTO kuperman_party_id FROM parties WHERE name ILIKE '%kuperman%' LIMIT 1;
  SELECT id INTO investor2_id FROM investors WHERE name ILIKE '%kuperman%' ORDER BY id OFFSET 1 LIMIT 1;
  SELECT id INTO test_deal_id FROM deals ORDER BY id OFFSET 1 LIMIT 1;

  IF kuperman_party_id IS NOT NULL AND investor2_id IS NOT NULL AND test_deal_id IS NOT NULL THEN
    -- Agreement with 2% rate
    INSERT INTO agreements (
      party_id, deal_id, fund_id, status, effective_date,
      snapshot_json, created_at, updated_at
    )
    VALUES (
      kuperman_party_id, test_deal_id, NULL, 'APPROVED', '2024-01-01',
      jsonb_build_object(
        'agreement_id', gen_random_uuid(),
        'version', 1,
        'terms', jsonb_build_array(
          jsonb_build_object(
            'start_date', NULL,
            'end_date', NULL,
            'resolved_upfront_bps', 200,  -- 2.0%
            'resolved_deferred_bps', 0,
            'vat_mode', 'on_top',
            'discounts', jsonb_build_array(),
            'cap', NULL
          )
        ),
        'vat_rate', 0.20
      ),
      NOW(), NOW()
    )
    ON CONFLICT DO NOTHING;

    -- Contribution: $50k → 2% = $1,000 base + $200 VAT = $1,200 total
    INSERT INTO contributions (
      investor_id, deal_id, fund_id, amount, paid_in_date, currency, created_at
    )
    VALUES (
      investor2_id, test_deal_id, NULL,
      50000.00, '2024-06-20', 'USD', NOW()
    )
    ON CONFLICT DO NOTHING;

    RAISE NOTICE '✅ Created: Kuperman → Investor 2 (2%%, $50k contribution)';
  END IF;
END $$;

-- ============================================
-- Verification
-- ============================================

DO $$
DECLARE
  agreement_count INT;
  contribution_count INT;
BEGIN
  SELECT COUNT(*) INTO agreement_count FROM agreements WHERE status = 'APPROVED';
  SELECT COUNT(*) INTO contribution_count FROM contributions;

  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'IMPORT COMPLETE';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Agreements created: %', agreement_count;
  RAISE NOTICE 'Contributions created: %', contribution_count;
  RAISE NOTICE '';
  RAISE NOTICE 'Ready for smoke testing!';
  RAISE NOTICE 'Credits skipped (will test manually)';
  RAISE NOTICE '========================================';
END $$;
