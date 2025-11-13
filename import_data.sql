-- ============================================================================
-- COMMISSION DATA IMPORT SCRIPT
-- ============================================================================
-- Import distributors (parties), investors, and commission agreements from CSV
--
-- PREREQUISITES:
-- 1. Fill out the CSV templates in import_templates/ folder
-- 2. Upload CSV files to Supabase (or paste data below)
-- 3. Run this script in Supabase SQL Editor
-- ============================================================================

-- ============================================================================
-- STEP 1: Import Parties (Distributors/Referrers)
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '=== STEP 1: Importing Parties ===';
END $$;

-- Create temporary table for CSV data
CREATE TEMP TABLE temp_parties (
    party_name TEXT,
    contact_email TEXT,
    contact_phone TEXT,
    notes TEXT
);

-- PASTE YOUR PARTIES CSV DATA HERE (without headers):
-- Example:
-- INSERT INTO temp_parties VALUES
-- ('Example Distributor Ltd', 'contact@example.com', '+972-50-1234567', 'Primary distributor'),
-- ('Partner Capital', 'info@partnercapital.com', '+1-212-555-0100', 'Strategic partner');

-- Insert parties into main table (skip duplicates by name)
INSERT INTO parties (name, created_at, updated_at)
SELECT
    party_name,
    NOW(),
    NOW()
FROM temp_parties
ON CONFLICT (name) DO NOTHING;

-- Show imported parties
SELECT
    id,
    name,
    created_at
FROM parties
WHERE name IN (SELECT party_name FROM temp_parties)
ORDER BY created_at DESC;

-- ============================================================================
-- STEP 2: Import Investors with Party Links
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '=== STEP 2: Importing Investors ===';
END $$;

-- Create temporary table for investor CSV data
CREATE TEMP TABLE temp_investors (
    investor_name TEXT,
    party_name TEXT,
    email TEXT,
    phone TEXT,
    notes TEXT
);

-- PASTE YOUR INVESTORS CSV DATA HERE (without headers):
-- Example:
-- INSERT INTO temp_investors VALUES
-- ('John Smith', 'Example Distributor Ltd', 'john.smith@email.com', '+972-50-9876543', 'VIP investor'),
-- ('Sarah Cohen', 'Partner Capital', 'sarah.cohen@email.com', '+1-917-555-0200', 'Introduced Q1 2024');

-- Insert investors with party links
INSERT INTO investors (name, introduced_by, created_at, updated_at)
SELECT
    ti.investor_name,
    p.id,
    NOW(),
    NOW()
FROM temp_investors ti
INNER JOIN parties p ON p.name = ti.party_name
ON CONFLICT (name) DO UPDATE
SET introduced_by = EXCLUDED.introduced_by,
    updated_at = NOW();

-- Show imported investors with party links
SELECT
    i.id,
    i.name as investor_name,
    p.name as party_name,
    i.introduced_by as party_id,
    i.created_at
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE i.name IN (SELECT investor_name FROM temp_investors)
ORDER BY p.name, i.name;

-- ============================================================================
-- STEP 3: Import Commission Agreements
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '=== STEP 3: Importing Commission Agreements ===';
END $$;

-- Create temporary table for agreements CSV data
CREATE TEMP TABLE temp_agreements (
    party_name TEXT,
    scope_type TEXT,  -- 'FUND' or 'DEAL'
    fund_id BIGINT,
    deal_id BIGINT,
    rate_bps INTEGER,
    vat_mode TEXT,  -- 'on_top' or 'included'
    vat_rate NUMERIC,
    effective_from DATE,
    effective_to DATE,
    status TEXT  -- 'APPROVED', 'DRAFT', etc.
);

-- PASTE YOUR AGREEMENTS CSV DATA HERE (without headers):
-- Example:
-- INSERT INTO temp_agreements VALUES
-- ('Example Distributor Ltd', 'DEAL', NULL, 1, 100, 'on_top', 0.20, '2020-01-01', NULL, 'APPROVED'),
-- ('Partner Capital', 'FUND', 1, NULL, 150, 'on_top', 0.20, '2024-01-01', '2024-12-31', 'APPROVED');

-- Insert agreements with snapshot JSON
INSERT INTO agreements (
    kind,
    party_id,
    scope,
    fund_id,
    deal_id,
    status,
    pricing_mode,
    effective_from,
    effective_to,
    snapshot_json,
    created_at,
    updated_at
)
SELECT
    'distributor_commission' as kind,
    p.id as party_id,
    ta.scope_type::agreement_scope as scope,
    ta.fund_id,
    ta.deal_id,
    ta.status as status,
    'CUSTOM'::pricing_mode as pricing_mode,
    ta.effective_from,
    ta.effective_to,
    jsonb_build_object(
        'kind', 'distributor_commission',
        'party_id', p.id::text,
        'party_name', p.name,
        'scope', jsonb_build_object(
            'fund_id', ta.fund_id,
            'deal_id', ta.deal_id
        ),
        'terms', jsonb_build_array(
            jsonb_build_object(
                'from', ta.effective_from::text,
                'to', ta.effective_to::text,
                'rate_bps', ta.rate_bps,
                'vat_mode', ta.vat_mode,
                'vat_rate', ta.vat_rate
            )
        ),
        'vat_admin_snapshot', jsonb_build_object(
            'jurisdiction', 'IL',
            'rate', ta.vat_rate,
            'effective_at', ta.effective_from::text
        )
    ) as snapshot_json,
    NOW() as created_at,
    NOW() as updated_at
FROM temp_agreements ta
INNER JOIN parties p ON p.name = ta.party_name;

-- Show imported agreements
SELECT
    a.id,
    p.name as party_name,
    a.scope,
    a.deal_id,
    a.fund_id,
    a.status,
    a.effective_from,
    a.effective_to,
    a.snapshot_json->'terms'->0->>'rate_bps' as rate_bps,
    a.snapshot_json->'terms'->0->>'vat_rate' as vat_rate,
    a.created_at
FROM agreements a
INNER JOIN parties p ON p.id = a.party_id
WHERE a.kind = 'distributor_commission'
  AND a.created_at >= (NOW() - INTERVAL '1 hour')
ORDER BY p.name;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Summary of imported data
SELECT
    '=== IMPORT SUMMARY ===' as section,
    (SELECT COUNT(*) FROM parties WHERE name IN (SELECT party_name FROM temp_parties)) as parties_imported,
    (SELECT COUNT(*) FROM investors WHERE name IN (SELECT investor_name FROM temp_investors)) as investors_imported,
    (SELECT COUNT(*) FROM agreements WHERE kind = 'distributor_commission' AND created_at >= (NOW() - INTERVAL '1 hour')) as agreements_imported;

-- Check for investors without party links
SELECT
    '=== Investors Missing Party Links ===' as section,
    i.id,
    i.name,
    i.introduced_by
FROM investors i
WHERE i.introduced_by IS NULL
LIMIT 10;

-- Check for duplicate party names
SELECT
    '=== Duplicate Party Names ===' as section,
    name,
    COUNT(*) as count
FROM parties
GROUP BY name
HAVING COUNT(*) > 1;

-- Verify agreement scope (must have exactly one of fund_id OR deal_id)
SELECT
    '=== Agreement Scope Validation ===' as section,
    a.id,
    p.name as party_name,
    a.fund_id,
    a.deal_id,
    CASE
        WHEN a.fund_id IS NOT NULL AND a.deal_id IS NOT NULL THEN 'ERROR: Both fund and deal set'
        WHEN a.fund_id IS NULL AND a.deal_id IS NULL THEN 'ERROR: Neither fund nor deal set'
        ELSE 'OK'
    END as validation_status
FROM agreements a
INNER JOIN parties p ON p.id = a.party_id
WHERE a.kind = 'distributor_commission';

-- ============================================================================
-- CLEANUP (optional - comment out if you want to keep temp tables)
-- ============================================================================
-- DROP TABLE IF EXISTS temp_parties;
-- DROP TABLE IF EXISTS temp_investors;
-- DROP TABLE IF EXISTS temp_agreements;

RAISE NOTICE 'Import complete! Review the verification queries above.';
