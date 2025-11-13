-- ============================================================================
-- COMMISSIONS MVP - UNBLOCKERS SETUP
-- ============================================================================
-- This script sets up the three unblockers for the Commissions MVP:
-- [DB-01] Enable commissions_engine feature flag
-- [DB-02] Seed 1 pilot commission agreement (Kuperman)
-- [DB-03] Ensure investors link to parties (introduced_by)
-- ============================================================================

-- ============================================================================
-- [DB-01] Enable commissions_engine feature flag
-- ============================================================================
INSERT INTO feature_flags (key, name, description, enabled, allowed_roles)
VALUES (
  'commissions_engine',
  'Commissions Engine',
  'Enable commission calculation & workflow for distributors/referrers',
  TRUE,
  ARRAY['admin','finance']
)
ON CONFLICT (key) DO UPDATE
SET enabled = TRUE,
    allowed_roles = ARRAY['admin','finance'];

-- Verify
SELECT key, name, enabled, allowed_roles
FROM feature_flags
WHERE key = 'commissions_engine';

-- ============================================================================
-- [DB-02] Seed 1 pilot commission agreement (Kuperman)
-- ============================================================================

-- First, let's find the Kuperman party (or create if needed)
DO $$
DECLARE
  v_kuperman_party_id UUID;
  v_deal_id BIGINT;
BEGIN
  -- Find Kuperman party by name (case-insensitive search)
  SELECT id INTO v_kuperman_party_id
  FROM parties
  WHERE LOWER(legal_name) LIKE '%kuperman%'
     OR LOWER(display_name) LIKE '%kuperman%'
  LIMIT 1;

  -- If no Kuperman party found, select the first available party
  IF v_kuperman_party_id IS NULL THEN
    SELECT id INTO v_kuperman_party_id
    FROM parties
    ORDER BY created_at DESC
    LIMIT 1;
  END IF;

  -- If still no party, create one for testing
  IF v_kuperman_party_id IS NULL THEN
    INSERT INTO parties (legal_name, display_name, party_type)
    VALUES ('Rakefet Kuperman', 'Kuperman', 'individual')
    RETURNING id INTO v_kuperman_party_id;
  END IF;

  -- Get a deal to use for the scope (prefer the first deal)
  SELECT id INTO v_deal_id
  FROM deals
  ORDER BY id ASC
  LIMIT 1;

  -- Output the values we'll use
  RAISE NOTICE 'Using Party ID: %', v_kuperman_party_id;
  RAISE NOTICE 'Using Deal ID: %', v_deal_id;

  -- Insert the pilot commission agreement
  INSERT INTO agreements (
    kind,
    party_id,
    scope,
    fund_id,
    deal_id,
    status,
    snapshot_json,
    created_at,
    updated_at
  )
  VALUES (
    'distributor_commission',
    v_kuperman_party_id,
    'DEAL',
    NULL,
    v_deal_id,
    'APPROVED',
    jsonb_build_object(
      'kind', 'distributor_commission',
      'party_id', v_kuperman_party_id::text,
      'scope', jsonb_build_object('fund_id', NULL, 'deal_id', v_deal_id),
      'terms', jsonb_build_array(
        jsonb_build_object(
          'from', '2018-01-01',
          'to', NULL,
          'rate_bps', 100,
          'vat_mode', 'on_top',
          'vat_rate', 0.20
        )
      ),
      'vat_admin_snapshot', jsonb_build_object(
        'jurisdiction', 'IL',
        'rate', 0.20,
        'effective_at', '2020-01-01'
      )
    ),
    NOW(),
    NOW()
  )
  ON CONFLICT DO NOTHING;

  RAISE NOTICE 'Commission agreement created/verified for party %', v_kuperman_party_id;
END $$;

-- Verify the agreement was created
SELECT
  id,
  kind,
  party_id,
  scope,
  deal_id,
  status,
  snapshot_json->'terms'->0->>'rate_bps' as rate_bps,
  created_at
FROM agreements
WHERE kind = 'distributor_commission'
ORDER BY created_at DESC
LIMIT 1;

-- ============================================================================
-- [DB-03] Ensure investors link to parties (introduced_by)
-- ============================================================================

-- Link at least one investor to the Kuperman party for testing
DO $$
DECLARE
  v_kuperman_party_id UUID;
  v_investor_id UUID;
  v_updated_count INT;
BEGIN
  -- Get the Kuperman party ID (from the agreement we just created)
  SELECT party_id INTO v_kuperman_party_id
  FROM agreements
  WHERE kind = 'distributor_commission'
  ORDER BY created_at DESC
  LIMIT 1;

  -- Find an investor who has contributions but no introduced_by link yet
  SELECT i.id INTO v_investor_id
  FROM investors i
  INNER JOIN contributions c ON c.investor_id = i.id
  WHERE i.introduced_by IS NULL
  LIMIT 1;

  -- If all investors are already linked, pick any investor with contributions
  IF v_investor_id IS NULL THEN
    SELECT i.id INTO v_investor_id
    FROM investors i
    INNER JOIN contributions c ON c.investor_id = i.id
    LIMIT 1;
  END IF;

  -- Update the investor with the party link
  IF v_investor_id IS NOT NULL THEN
    UPDATE investors
    SET introduced_by = v_kuperman_party_id,
        updated_at = NOW()
    WHERE id = v_investor_id;

    GET DIAGNOSTICS v_updated_count = ROW_COUNT;

    RAISE NOTICE 'Linked investor % to party %', v_investor_id, v_kuperman_party_id;
    RAISE NOTICE 'Updated % investor record(s)', v_updated_count;
  ELSE
    RAISE NOTICE 'No investors with contributions found to link';
  END IF;
END $$;

-- Verify investor links
SELECT
  i.id as investor_id,
  i.name as investor_name,
  i.introduced_by as party_id,
  p.display_name as party_name,
  COUNT(c.id) as contribution_count
FROM investors i
LEFT JOIN parties p ON p.id = i.introduced_by
LEFT JOIN contributions c ON c.investor_id = i.id
WHERE i.introduced_by IS NOT NULL
GROUP BY i.id, i.name, i.introduced_by, p.display_name
ORDER BY contribution_count DESC
LIMIT 10;

-- ============================================================================
-- SUMMARY: What we just set up
-- ============================================================================
SELECT
  '=== UNBLOCKERS COMPLETE ===' as status,
  (SELECT COUNT(*) FROM feature_flags WHERE key = 'commissions_engine' AND enabled = true) as feature_flag_enabled,
  (SELECT COUNT(*) FROM agreements WHERE kind = 'distributor_commission' AND status = 'APPROVED') as commission_agreements,
  (SELECT COUNT(*) FROM investors WHERE introduced_by IS NOT NULL) as linked_investors;

-- ============================================================================
-- BONUS: Find a test contribution for API smoke tests
-- ============================================================================
SELECT
  c.id as contribution_id,
  c.investor_id,
  i.name as investor_name,
  i.introduced_by as party_id,
  p.display_name as party_name,
  c.deal_id,
  c.fund_id,
  c.amount,
  c.currency,
  c.paid_in_date
FROM contributions c
INNER JOIN investors i ON i.id = c.investor_id
LEFT JOIN parties p ON p.id = i.introduced_by
WHERE i.introduced_by IS NOT NULL
  AND c.deal_id IS NOT NULL  -- Match the agreement scope
ORDER BY c.paid_in_date DESC
LIMIT 5;

-- ============================================================================
-- END OF UNBLOCKERS SETUP
-- ============================================================================
