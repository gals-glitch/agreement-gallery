-- ============================================================================
-- Phase 0 Unblockers: Commissions MVP Setup
-- ============================================================================
-- Purpose: Enable commissions system for MVP demo by setting up:
--   1. Add introduced_by column to investors table (if missing)
--   2. Feature flag for commissions engine
--   3. Pilot commission agreement
--   4. Link investor to party for testing
--
-- Safety: Idempotent - safe to run multiple times
-- Database: PostgreSQL (Supabase)
-- Environment: Production (qwgicrdcoqdketqhxbys)
-- ============================================================================

-- ============================================================================
-- [DB-00] Add introduced_by column to investors (if not exists)
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '=== [DB-00] Adding introduced_by column to investors ===';

    -- Add column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'investors' AND column_name = 'introduced_by'
    ) THEN
        ALTER TABLE investors ADD COLUMN introduced_by BIGINT REFERENCES parties(id);
        RAISE NOTICE 'Added introduced_by column to investors table';
    ELSE
        RAISE NOTICE 'Column introduced_by already exists';
    END IF;
END $$;

-- ============================================================================
-- [DB-01] Enable Feature Flag
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '=== [DB-01] Setting up Feature Flag ===';

    INSERT INTO feature_flags (key, description, enabled, enabled_for_roles)
    VALUES (
        'commissions_engine',
        'Enable commission calculation & workflow for distributors/referrers',
        TRUE,
        ARRAY['admin', 'finance']
    )
    ON CONFLICT (key) DO UPDATE
    SET
        enabled = TRUE,
        enabled_for_roles = ARRAY['admin', 'finance'],
        updated_at = NOW();

    RAISE NOTICE 'Feature flag "commissions_engine" enabled for roles: admin, finance';
END $$;

-- ============================================================================
-- [DB-02] Seed Pilot Commission Agreement
-- ============================================================================
DO $$
DECLARE
    v_party_id BIGINT;
    v_party_name TEXT;
    v_fund_id BIGINT;
    v_deal_id BIGINT;
    v_agreement_id BIGINT;
    v_snapshot JSONB;
    v_existing_agreement_id BIGINT;
BEGIN
    RAISE NOTICE '=== [DB-02] Setting up Pilot Commission Agreement ===';

    -- Find Kuperman party (case-insensitive search)
    SELECT id, name INTO v_party_id, v_party_name
    FROM parties
    WHERE LOWER(name) LIKE '%kuperman%'
    LIMIT 1;

    -- Fallback to first available party if Kuperman not found
    IF v_party_id IS NULL THEN
        SELECT id, name INTO v_party_id, v_party_name
        FROM parties
        ORDER BY created_at DESC
        LIMIT 1;
    END IF;

    -- Exit if no parties exist at all
    IF v_party_id IS NULL THEN
        RAISE EXCEPTION 'No parties found in database. Please create at least one party first.';
    END IF;

    RAISE NOTICE 'Selected party: % (ID: %)', v_party_name, v_party_id;

    -- Prefer deal_id over fund_id for scope
    SELECT id INTO v_deal_id FROM deals ORDER BY id ASC LIMIT 1;

    IF v_deal_id IS NOT NULL THEN
        v_fund_id := NULL;
        RAISE NOTICE 'Using deal scope: deal_id = %', v_deal_id;
    ELSE
        SELECT id INTO v_fund_id FROM funds ORDER BY id ASC LIMIT 1;
        IF v_fund_id IS NOT NULL THEN
            RAISE NOTICE 'Using fund scope: fund_id = %', v_fund_id;
        ELSE
            RAISE EXCEPTION 'No deals or funds found. Please create at least one deal or fund first.';
        END IF;
    END IF;

    -- Build snapshot JSON
    v_snapshot := jsonb_build_object(
        'kind', 'distributor_commission',
        'party_id', v_party_id::text,
        'party_name', v_party_name,
        'scope', jsonb_build_object('fund_id', v_fund_id, 'deal_id', v_deal_id),
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
    );

    -- Check if agreement already exists for this party + scope
    SELECT id INTO v_existing_agreement_id
    FROM agreements
    WHERE kind = 'distributor_commission'
      AND party_id = v_party_id
      AND (
          (deal_id IS NOT NULL AND deal_id = v_deal_id) OR
          (fund_id IS NOT NULL AND fund_id = v_fund_id)
      );

    IF v_existing_agreement_id IS NOT NULL THEN
        -- Update existing agreement
        UPDATE agreements
        SET
            status = 'APPROVED',
            pricing_mode = 'CUSTOM'::pricing_mode,
            effective_from = '2018-01-01'::date,
            snapshot_json = v_snapshot,
            updated_at = NOW()
        WHERE id = v_existing_agreement_id;

        RAISE NOTICE 'Updated existing commission agreement (ID: %)', v_existing_agreement_id;
        v_agreement_id := v_existing_agreement_id;
    ELSE
        -- Create new agreement
        INSERT INTO agreements (
            kind,
            party_id,
            scope,
            fund_id,
            deal_id,
            status,
            pricing_mode,
            effective_from,
            snapshot_json,
            created_at,
            updated_at
        )
        VALUES (
            'distributor_commission',
            v_party_id,
            (CASE WHEN v_deal_id IS NOT NULL THEN 'DEAL' ELSE 'FUND' END)::agreement_scope,
            v_fund_id,
            v_deal_id,
            'APPROVED',
            'CUSTOM'::pricing_mode,
            '2018-01-01'::date,
            v_snapshot,
            NOW(),
            NOW()
        )
        RETURNING id INTO v_agreement_id;

        RAISE NOTICE 'Created new APPROVED commission agreement (ID: %)', v_agreement_id;
    END IF;

END $$;

-- ============================================================================
-- [DB-03] Link Investor to Party
-- ============================================================================
DO $$
DECLARE
    v_party_id BIGINT;
    v_party_name TEXT;
    v_investor_id BIGINT;
    v_investor_name TEXT;
    v_updated_count INT;
BEGIN
    RAISE NOTICE '=== [DB-03] Linking Investor to Party ===';

    -- Get the party from the commission agreement we just created
    SELECT party_id, snapshot_json->>'party_name'
    INTO v_party_id, v_party_name
    FROM agreements
    WHERE kind = 'distributor_commission'
      AND status = 'APPROVED'
    ORDER BY updated_at DESC
    LIMIT 1;

    IF v_party_id IS NULL THEN
        RAISE EXCEPTION 'No commission agreement found. DB-02 may have failed.';
    END IF;

    -- Find an investor with contributions but no party link yet
    SELECT i.id, i.name
    INTO v_investor_id, v_investor_name
    FROM investors i
    INNER JOIN contributions c ON c.investor_id = i.id
    WHERE i.introduced_by IS NULL
    LIMIT 1;

    -- If all investors already linked, pick any investor with contributions
    IF v_investor_id IS NULL THEN
        SELECT i.id, i.name
        INTO v_investor_id, v_investor_name
        FROM investors i
        INNER JOIN contributions c ON c.investor_id = i.id
        LIMIT 1;
    END IF;

    IF v_investor_id IS NULL THEN
        RAISE WARNING 'No investors with contributions found. Commission compute will fail without test data.';
    ELSE
        -- Update investor with party link
        UPDATE investors
        SET introduced_by = v_party_id,
            updated_at = NOW()
        WHERE id = v_investor_id;

        GET DIAGNOSTICS v_updated_count = ROW_COUNT;

        RAISE NOTICE 'Linked investor "%" (ID: %) to party "%" (ID: %)',
            v_investor_name, v_investor_id, v_party_name, v_party_id;
        RAISE NOTICE 'Updated % investor record(s)', v_updated_count;
    END IF;

END $$;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- [DB-01] Feature Flag Status
SELECT
    '=== [DB-01] Feature Flag Status ===' as section,
    key,
    description,
    enabled,
    enabled_for_roles
FROM feature_flags
WHERE key = 'commissions_engine';

-- [DB-02] Commission Agreement Details
SELECT
    '=== [DB-02] Commission Agreement Details ===' as section,
    id as agreement_id,
    party_id,
    scope,
    deal_id,
    fund_id,
    status,
    snapshot_json->'terms'->0->>'rate_bps' as rate_bps,
    snapshot_json->'terms'->0->>'vat_rate' as vat_rate,
    snapshot_json->'terms'->0->>'vat_mode' as vat_mode,
    created_at,
    updated_at
FROM agreements
WHERE kind = 'distributor_commission'
ORDER BY updated_at DESC
LIMIT 1;

-- [DB-03] Linked Investors Summary
SELECT
    '=== [DB-03] Linked Investors Summary ===' as section,
    i.id as investor_id,
    i.name as investor_name,
    i.introduced_by as party_id,
    p.name as party_name,
    COUNT(c.id) as contribution_count,
    SUM(c.amount) as total_contributions
FROM investors i
LEFT JOIN parties p ON p.id = i.introduced_by
LEFT JOIN contributions c ON c.investor_id = i.id
WHERE i.introduced_by IS NOT NULL
GROUP BY i.id, i.name, i.introduced_by, p.name
ORDER BY contribution_count DESC
LIMIT 10;

-- Test Contribution IDs (for API testing)
SELECT
    '=== Test Contribution IDs (for API testing) ===' as section,
    c.id as contribution_id,
    c.investor_id,
    i.name as investor_name,
    i.introduced_by as party_id,
    p.name as party_name,
    c.deal_id,
    c.fund_id,
    c.amount,
    c.currency,
    c.paid_in_date
FROM contributions c
INNER JOIN investors i ON i.id = c.investor_id
LEFT JOIN parties p ON p.id = i.introduced_by
WHERE i.introduced_by IS NOT NULL
ORDER BY c.paid_in_date DESC
LIMIT 5;

-- Scope Coverage Check
SELECT
    '=== Scope Coverage Check ===' as section,
    CURRENT_DATE as today,
    (snapshot_json->'terms'->0->>'from')::date as term_start,
    (snapshot_json->'terms'->0->>'to')::date as term_end,
    CASE
        WHEN (snapshot_json->'terms'->0->>'to') IS NULL THEN 'COVERED (no end date)'
        WHEN CURRENT_DATE >= (snapshot_json->'terms'->0->>'from')::date
         AND CURRENT_DATE <= (snapshot_json->'terms'->0->>'to')::date THEN 'COVERED'
        ELSE 'NOT COVERED'
    END as coverage_status
FROM agreements
WHERE kind = 'distributor_commission'
  AND status = 'APPROVED'
ORDER BY updated_at DESC
LIMIT 1;

-- Summary
SELECT
    '=== SETUP COMPLETE ===' as status,
    (SELECT COUNT(*) FROM feature_flags WHERE key = 'commissions_engine' AND enabled = true) as feature_flag_enabled,
    (SELECT COUNT(*) FROM agreements WHERE kind = 'distributor_commission' AND status = 'APPROVED') as commission_agreements,
    (SELECT COUNT(*) FROM investors WHERE introduced_by IS NOT NULL) as linked_investors,
    (SELECT COUNT(*) FROM contributions c INNER JOIN investors i ON i.id = c.investor_id WHERE i.introduced_by IS NOT NULL) as test_contributions_available;
