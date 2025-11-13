-- ============================================================================
-- [DATA-02] Create Investor-Level Commission Agreements
-- ============================================================================
-- Generated from Party - Deal Mapping.csv
-- Date: 2025-10-26 15:19:06
-- Investor agreements: 110
--
-- STRUCTURE:
-- - Each investor gets one agreement
-- - Agreement specifies equity % (stored in snapshot_json)
-- - Agreement has 4 tiered commission rates based on deal close date:
--   * Before Feb 1, 2018: 25%
--   * Feb 1, 2018 - Dec 12, 2019: 27%
--   * Dec 12, 2019 - Oct 31, 2020: 30%
--   * After Oct 31, 2020: 35%
-- ============================================================================

-- Delete old party-level agreements (from initial import)
DELETE FROM agreements
WHERE kind = 'distributor_commission'
  AND investor_id IS NULL;

-- Insert investor-level agreements
INSERT INTO agreements (
    kind,
    party_id,
    investor_id,
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
-- Kuperman Entity â†’ Kuperman (100 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 100,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Kuperman Entity'
      AND p.name = 'Kuperman'
    LIMIT 1
)
UNION ALL
-- Yaniv Radia â†’ Kuperman (2500 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 2500,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Yaniv Radia'
      AND p.name = 'Kuperman'
    LIMIT 1
)
UNION ALL
-- Gil Serok Revocable Trust â†’ Kuperman (2700 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 2700,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Gil Serok Revocable Trust'
      AND p.name = 'Kuperman'
    LIMIT 1
)
UNION ALL
-- Gadi Gerbi â†’ Kuperman (3000 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 3000,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Gadi Gerbi'
      AND p.name = 'Kuperman'
    LIMIT 1
)
UNION ALL
-- DGTA Ltd â†’ Shai Sheffer (2700 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 2700,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'DGTA Ltd'
      AND p.name = 'Shai Sheffer'
    LIMIT 1
)
UNION ALL
-- Fresh Properties and Investments â†’ Yoram Dvash (2700 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 2700,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Fresh Properties and Investments'
      AND p.name = 'Yoram Dvash'
    LIMIT 1
)
UNION ALL
-- Steve Ball â†’ Yoni Frieder (100 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 100,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Steve Ball'
      AND p.name = 'Yoni Frieder'
    LIMIT 1
)
UNION ALL
-- Peter Gyenes â†’ Cross Arch Holdings -David Kirchenbaum (2500 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 2500,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Peter Gyenes'
      AND p.name = 'Cross Arch Holdings -David Kirchenbaum'
    LIMIT 1
)
UNION ALL
-- Barry Kirschenbaum â†’ Cross Arch Holdings -David Kirchenbaum (2500 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 2500,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Barry Kirschenbaum'
      AND p.name = 'Cross Arch Holdings -David Kirchenbaum'
    LIMIT 1
)
UNION ALL
-- Gil Shalit â†’ Ronnie Maliniak (2500 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 2500,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Gil Shalit'
      AND p.name = 'Ronnie Maliniak'
    LIMIT 1
)
UNION ALL
-- Roni Atoun (Green Orka, AC Applications) â†’ Ronnie Maliniak (2500 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 2500,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Roni Atoun (Green Orka, AC Applications)'
      AND p.name = 'Ronnie Maliniak'
    LIMIT 1
)
UNION ALL
-- The Service (Sheltered Housing) â†’ Ronnie Maliniak (1000 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 1000,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'The Service (Sheltered Housing)'
      AND p.name = 'Ronnie Maliniak'
    LIMIT 1
)
UNION ALL
-- Ehud Svirsky â†’ Ilanit Tirosh (2500 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 2500,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Ehud Svirsky'
      AND p.name = 'Ilanit Tirosh'
    LIMIT 1
)
UNION ALL
-- Miri Kerbs (A-T Management) â†’ Ilanit Tirosh (1500 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 1500,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Miri Kerbs (A-T Management)'
      AND p.name = 'Ilanit Tirosh'
    LIMIT 1
)
UNION ALL
-- Dror Nahumi â†’ Tal Simchony (1500 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 1500,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Dror Nahumi'
      AND p.name = 'Tal Simchony'
    LIMIT 1
)
UNION ALL
-- Any IRAs â†’ Tal Simchony (500 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 500,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Any IRAs'
      AND p.name = 'Tal Simchony'
    LIMIT 1
)
UNION ALL
-- Yoram Avi-Guy â†’ Yoram Shalit (2500 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 2500,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Yoram Avi-Guy'
      AND p.name = 'Yoram Shalit'
    LIMIT 1
)
UNION ALL
-- Eran & Nitsa Tal â†’ Yoram Shalit (1500 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 1500,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Eran & Nitsa Tal'
      AND p.name = 'Yoram Shalit'
    LIMIT 1
)
UNION ALL
-- Nili Karabel IRA â†’ Yoram Shalit (100 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 100,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Nili Karabel IRA'
      AND p.name = 'Yoram Shalit'
    LIMIT 1
)
UNION ALL
-- Chaim Zach (HMCA SA) â†’ GW CPA (1500 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 1500,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Chaim Zach (HMCA SA)'
      AND p.name = 'GW CPA'
    LIMIT 1
)
UNION ALL
-- Eran Farajun â†’ Guy Moses (2500 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 2500,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Eran Farajun'
      AND p.name = 'Guy Moses'
    LIMIT 1
)
UNION ALL
-- Naomi Rudich â†’ Guy Moses (1500 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 1500,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Naomi Rudich'
      AND p.name = 'Guy Moses'
    LIMIT 1
)
UNION ALL
-- Avraham Weiss â†’ Guy Moses (5000 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 5000,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Avraham Weiss'
      AND p.name = 'Guy Moses'
    LIMIT 1
)
UNION ALL
-- Pladot Paldom Ltd â†’ Guy Moses (5000 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 5000,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Pladot Paldom Ltd'
      AND p.name = 'Guy Moses'
    LIMIT 1
)
UNION ALL
-- Noam Zegman â†’ Guy Moses (5000 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 5000,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Noam Zegman'
      AND p.name = 'Guy Moses'
    LIMIT 1
)
UNION ALL
-- Howard Loboda â†’ Sheara Einhorn (1500 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 1500,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Howard Loboda'
      AND p.name = 'Sheara Einhorn'
    LIMIT 1
)
UNION ALL
-- Nurit Preis â†’ Lior Stinus from Freidkes & Co. CPA (1500 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 1500,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Nurit Preis'
      AND p.name = 'Lior Stinus from Freidkes & Co. CPA'
    LIMIT 1
)
UNION ALL
-- Shay Mizrachi â†’ Avi Fried (1500 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 1500,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Shay Mizrachi'
      AND p.name = 'Avi Fried'
    LIMIT 1
)
UNION ALL
-- Shulamit Shimon â†’ Formula Ventures Ltd- Shai Beilis (1500 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 1500,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Shulamit Shimon'
      AND p.name = 'Formula Ventures Ltd- Shai Beilis'
    LIMIT 1
)
UNION ALL
-- Moshe Friedman â†’ Ilan Kapelner Management Services ltd- Ilan Kapelner (100 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 100,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Moshe Friedman'
      AND p.name = 'Ilan Kapelner Management Services ltd- Ilan Kapelner'
    LIMIT 1
)
UNION ALL
-- Emanuel & Netanel Parter â†’ Shlomo Waldmann (100 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 100,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Emanuel & Netanel Parter'
      AND p.name = 'Shlomo Waldmann'
    LIMIT 1
)
UNION ALL
-- Ehud Hameiri - Ash-Hag Consultants Ltd â†’ Rubin Schlussel (75 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 75,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Ehud Hameiri - Ash-Hag Consultants Ltd'
      AND p.name = 'Rubin Schlussel'
    LIMIT 1
)
UNION ALL
-- Dov David & Dorit Gerecht Albukrek â†’ HNA Investments Limited Liability- Ilan Grinberg and Jacob Asia (together) (50 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 50,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Dov David & Dorit Gerecht Albukrek'
      AND p.name = 'HNA Investments Limited Liability- Ilan Grinberg and Jacob Asia (together)'
    LIMIT 1
)
UNION ALL
-- Yehezkel Gabai â†’ Yoram Avi-Guy Lawyer- Yoram Avi Guy (100 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 100,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Yehezkel Gabai'
      AND p.name = 'Yoram Avi-Guy Lawyer- Yoram Avi Guy'
    LIMIT 1
)
UNION ALL
-- David Michaeli â†’ HS Invest Pension Insurance Agency (2016) ltd- Hezi Schwartz (150 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 150,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'David Michaeli'
      AND p.name = 'HS Invest Pension Insurance Agency (2016) ltd- Hezi Schwartz'
    LIMIT 1
)
UNION ALL
-- Haim Helman â†’ HS Invest Pension Insurance Agency (2016) ltd- Hezi Schwartz (1000 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 1000,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Haim Helman'
      AND p.name = 'HS Invest Pension Insurance Agency (2016) ltd- Hezi Schwartz'
    LIMIT 1
)
UNION ALL
-- David Reichman - commission for himself only on Beaufort â†’ David Reichman (100 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 100,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'David Reichman - commission for himself only on Beaufort'
      AND p.name = 'David Reichman'
    LIMIT 1
)
UNION ALL
-- Yoram Mizrachi â†’ David Reichman (1000 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 1000,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Yoram Mizrachi'
      AND p.name = 'David Reichman'
    LIMIT 1
)
UNION ALL
-- Alin Ajami Atzmon â†’ Agamim Commercial Real Estate- Moti Agam (50 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 50,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Alin Ajami Atzmon'
      AND p.name = 'Agamim Commercial Real Estate- Moti Agam'
    LIMIT 1
)
UNION ALL
-- Barak Matalon â†’ Natai Investments- Alon Even Chen (7500 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 7500,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Barak Matalon'
      AND p.name = 'Natai Investments- Alon Even Chen'
    LIMIT 1
)
UNION ALL
-- Shalom Josef Hochman â†’ Wiser Finance- Michael Mann (100 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 100,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Shalom Josef Hochman'
      AND p.name = 'Wiser Finance- Michael Mann'
    LIMIT 1
)
UNION ALL
-- Yigal Ben David â†’ Wiser Finance- Michael Mann (1000 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 1000,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Yigal Ben David'
      AND p.name = 'Wiser Finance- Michael Mann'
    LIMIT 1
)
UNION ALL
-- Rami Pais â†’ Pioneer Wealth Management- Liat F (7500 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 7500,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Rami Pais'
      AND p.name = 'Pioneer Wealth Management- Liat F'
    LIMIT 1
)
UNION ALL
-- Shmuel Parag â†’ Tal Even (500 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 500,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Shmuel Parag'
      AND p.name = 'Tal Even'
    LIMIT 1
)
UNION ALL
-- Noa Juhn Parag â†’ Tal Even (500 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 500,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Noa Juhn Parag'
      AND p.name = 'Tal Even'
    LIMIT 1
)
UNION ALL
-- Jared Holzman â†’ Tal Even (100 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 100,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Jared Holzman'
      AND p.name = 'Tal Even'
    LIMIT 1
)
UNION ALL
-- Nissim Bar Siman Tov â†’ Tal Even (100 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 100,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Nissim Bar Siman Tov'
      AND p.name = 'Tal Even'
    LIMIT 1
)
UNION ALL
-- Ari Aharon Hillel - Check with Erez â†’ Eyal Hrring- Financial Planning and Strategy- Eyal Herring (50 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 50,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Ari Aharon Hillel - Check with Erez'
      AND p.name = 'Eyal Hrring- Financial Planning and Strategy- Eyal Herring'
    LIMIT 1
)
UNION ALL
-- Limor Sagiv â†’ Yariv Avrahami (100 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 100,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Limor Sagiv'
      AND p.name = 'Yariv Avrahami'
    LIMIT 1
)
UNION ALL
-- Dan Pastenernak â†’ Yariv Avrahami (100 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 100,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Dan Pastenernak'
      AND p.name = 'Yariv Avrahami'
    LIMIT 1
)
UNION ALL
-- Sima Ben Chitrit â†’ Yariv Avrahami (100 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 100,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Sima Ben Chitrit'
      AND p.name = 'Yariv Avrahami'
    LIMIT 1
)
UNION ALL
-- Yury Sofman â†’ ThinkWise Consulting LLC- Lior Cohen (500 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 500,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Yury Sofman'
      AND p.name = 'ThinkWise Consulting LLC- Lior Cohen'
    LIMIT 1
)
UNION ALL
-- Ori Peled â†’ Gilad Slonim Insurance Agency Ltd- Gilad Slonim (500 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 500,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Ori Peled'
      AND p.name = 'Gilad Slonim Insurance Agency Ltd- Gilad Slonim'
    LIMIT 1
)
UNION ALL
-- Ogenruth Ltd â†’ Gilad Slonim Insurance Agency Ltd- Gilad Slonim (100 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 100,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Ogenruth Ltd'
      AND p.name = 'Gilad Slonim Insurance Agency Ltd- Gilad Slonim'
    LIMIT 1
)
UNION ALL
-- Jonathan & Tova Mann â†’ Iprofit Ltd- Yifat Igler (100 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 100,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Jonathan & Tova Mann'
      AND p.name = 'Iprofit Ltd- Yifat Igler'
    LIMIT 1
)
UNION ALL
-- Nir Tzur â†’ Saar Gavish (100 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 100,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Nir Tzur'
      AND p.name = 'Saar Gavish'
    LIMIT 1
)
UNION ALL
-- Ariel Spivak â†’ YL Consulting Inc- Yoav Lachover (100 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 100,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Ariel Spivak'
      AND p.name = 'YL Consulting Inc- Yoav Lachover'
    LIMIT 1
)
UNION ALL
-- Ayal Brener â†’ YL Consulting Inc- Yoav Lachover (1000 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 1000,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Ayal Brener'
      AND p.name = 'YL Consulting Inc- Yoav Lachover'
    LIMIT 1
)
UNION ALL
-- RAC Advisors LLC â†’ Dror Zetouni (150 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 150,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'RAC Advisors LLC'
      AND p.name = 'Dror Zetouni'
    LIMIT 1
)
UNION ALL
-- Adam Gotskind â†’ Dror Zetouni (150 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 150,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Adam Gotskind'
      AND p.name = 'Dror Zetouni'
    LIMIT 1
)
UNION ALL
-- Steve Feiger â†’ Dror Zetouni (150 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 150,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Steve Feiger'
      AND p.name = 'Dror Zetouni'
    LIMIT 1
)
UNION ALL
-- Fred Margulies â†’ Dror Zetouni (150 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 150,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Fred Margulies'
      AND p.name = 'Dror Zetouni'
    LIMIT 1
)
UNION ALL
-- David Schreiber â†’ Dror Zetouni (150 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 150,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'David Schreiber'
      AND p.name = 'Dror Zetouni'
    LIMIT 1
)
UNION ALL
-- Stan Weissbrot â†’ Dror Zetouni (150 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 150,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Stan Weissbrot'
      AND p.name = 'Dror Zetouni'
    LIMIT 1
)
UNION ALL
-- Abraham Stern â†’ Dror Zetouni (150 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 150,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Abraham Stern'
      AND p.name = 'Dror Zetouni'
    LIMIT 1
)
UNION ALL
-- Avi Shaked â†’ Dror Zetouni (150 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 150,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Avi Shaked'
      AND p.name = 'Dror Zetouni'
    LIMIT 1
)
UNION ALL
-- Charles Serlin â†’ Dror Zetouni (150 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 150,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Charles Serlin'
      AND p.name = 'Dror Zetouni'
    LIMIT 1
)
UNION ALL
-- Robert Marconi â†’ Dror Zetouni (150 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 150,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Robert Marconi'
      AND p.name = 'Dror Zetouni'
    LIMIT 1
)
UNION ALL
-- Todd Stern â†’ Dror Zetouni (150 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 150,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Todd Stern'
      AND p.name = 'Dror Zetouni'
    LIMIT 1
)
UNION ALL
-- Jack Faintuch â†’ Dror Zetouni (150 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 150,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Jack Faintuch'
      AND p.name = 'Dror Zetouni'
    LIMIT 1
)
UNION ALL
-- Rafael Ashkenazi â†’ Lighthouse F.S Ltd- Avihay (100 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 100,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Rafael Ashkenazi'
      AND p.name = 'Lighthouse F.S Ltd- Avihay'
    LIMIT 1
)
UNION ALL
-- Shmuel Carmon â†’ Lighthouse F.S Ltd- Avihay (1000 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 1000,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Shmuel Carmon'
      AND p.name = 'Lighthouse F.S Ltd- Avihay'
    LIMIT 1
)
UNION ALL
-- Gilad Kapelushnick â†’ Sparta Capital- Yonel Dvash (100 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 100,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Gilad Kapelushnick'
      AND p.name = 'Sparta Capital- Yonel Dvash'
    LIMIT 1
)
UNION ALL
-- Dan Krausz â†’ Gil Haramati (150 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 150,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Dan Krausz'
      AND p.name = 'Gil Haramati'
    LIMIT 1
)
UNION ALL
-- Nicky Stup & Wife â†’ Gil Haramati (150 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 150,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Nicky Stup & Wife'
      AND p.name = 'Gil Haramati'
    LIMIT 1
)
UNION ALL
-- Ofer Ben-Aharon â†’ Gil Haramati (150 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 150,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Ofer Ben-Aharon'
      AND p.name = 'Gil Haramati'
    LIMIT 1
)
UNION ALL
-- Ofer Levy â†’ Gil Haramati (150 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 150,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Ofer Levy'
      AND p.name = 'Gil Haramati'
    LIMIT 1
)
UNION ALL
-- Boaz Paz â†’ Beny Shafir (150 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 150,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Boaz Paz'
      AND p.name = 'Beny Shafir'
    LIMIT 1
)
UNION ALL
-- Roliya Investments LLC â†’ Atiela Investments Ltd- Yoav Holzer (50 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 50,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Roliya Investments LLC'
      AND p.name = 'Atiela Investments Ltd- Yoav Holzer'
    LIMIT 1
)
UNION ALL
-- Tehila Ben Moshe â†’ Capital Link Family Office- Shiri Hybloom (100 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 100,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Tehila Ben Moshe'
      AND p.name = 'Capital Link Family Office- Shiri Hybloom'
    LIMIT 1
)
UNION ALL
-- Doron Peretz â†’ Capital Link Family Office- Shiri Hybloom (100 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 100,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Doron Peretz'
      AND p.name = 'Capital Link Family Office- Shiri Hybloom'
    LIMIT 1
)
UNION ALL
-- Yoram Baumann â†’ Capital Link Family Office- Shiri Hybloom (50 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 50,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Yoram Baumann'
      AND p.name = 'Capital Link Family Office- Shiri Hybloom'
    LIMIT 1
)
UNION ALL
-- Maragret Frank â†’ Isaac Fattal (150 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 150,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Maragret Frank'
      AND p.name = 'Isaac Fattal'
    LIMIT 1
)
UNION ALL
-- Benny Silverman â†’ Stark Yoel Kadish, Lawyer (Accountant)- Yoel Stark (50 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 50,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Benny Silverman'
      AND p.name = 'Stark Yoel Kadish, Lawyer (Accountant)- Yoel Stark'
    LIMIT 1
)
UNION ALL
-- Matthew Rosenbluth Rosenbluth Trust â†’ Brian Horner (100 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 100,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Matthew Rosenbluth Rosenbluth Trust'
      AND p.name = 'Brian Horner'
    LIMIT 1
)
UNION ALL
-- Mickey Amir Hanegbee Kaplinsky â†’ SRI Global Group- Daphna (150 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 150,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Mickey Amir Hanegbee Kaplinsky'
      AND p.name = 'SRI Global Group- Daphna'
    LIMIT 1
)
UNION ALL
-- Eliezer Abramov â†’ SRI Global Group- Daphna (150 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 150,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Eliezer Abramov'
      AND p.name = 'SRI Global Group- Daphna'
    LIMIT 1
)
UNION ALL
-- Yuval Shacham â†’ SRI Global Group- Daphna (150 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 150,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Yuval Shacham'
      AND p.name = 'SRI Global Group- Daphna'
    LIMIT 1
)
UNION ALL
-- Frank Cortese â†’ Gabriel Taub (150 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 150,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Frank Cortese'
      AND p.name = 'Gabriel Taub'
    LIMIT 1
)
UNION ALL
-- Brenden Selway â†’ Gabriel Taub (150 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 150,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Brenden Selway'
      AND p.name = 'Gabriel Taub'
    LIMIT 1
)
UNION ALL
-- Octavian Patrascu (Netcore Investments Limited) â†’ Amit Zeevi (150 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 150,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Octavian Patrascu (Netcore Investments Limited)'
      AND p.name = 'Amit Zeevi'
    LIMIT 1
)
UNION ALL
-- Idan Grossman - Mangro Pty Ltd as Trustee for Mind Plus Trust â†’ Amit Zeevi (150 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 150,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Idan Grossman - Mangro Pty Ltd as Trustee for Mind Plus Trust'
      AND p.name = 'Amit Zeevi'
    LIMIT 1
)
UNION ALL
-- Idan Kornfeld â†’ Amit Zeevi (150 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 150,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Idan Kornfeld'
      AND p.name = 'Amit Zeevi'
    LIMIT 1
)
UNION ALL
-- Ofir Rozenfeld â†’ Roy Gold (150 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 150,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Ofir Rozenfeld'
      AND p.name = 'Roy Gold'
    LIMIT 1
)
UNION ALL
-- Shlomit Rosenfeld â†’ Roy Gold (150 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 150,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Shlomit Rosenfeld'
      AND p.name = 'Roy Gold'
    LIMIT 1
)
UNION ALL
-- Aharon Rasouli â†’ Roy Gold (150 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 150,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Aharon Rasouli'
      AND p.name = 'Roy Gold'
    LIMIT 1
)
UNION ALL
-- Miri Rozenfeld â†’ Roy Gold (150 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 150,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Miri Rozenfeld'
      AND p.name = 'Roy Gold'
    LIMIT 1
)
UNION ALL
-- Nomi A. Holdings Ltd â†’ Tzafit Pension Insurance Agency (2023) Ltd (150 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 150,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Nomi A. Holdings Ltd'
      AND p.name = 'Tzafit Pension Insurance Agency (2023) Ltd'
    LIMIT 1
)
UNION ALL
-- Gene Dattel â†’ Andrew Tanzer [company:  TanzerVest LLC] (100 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 100,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Gene Dattel'
      AND p.name = 'Andrew Tanzer [company:  TanzerVest LLC]'
    LIMIT 1
)
UNION ALL
-- Licia Hahn â†’ Andrew Tanzer [company:  TanzerVest LLC] (100 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 100,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Licia Hahn'
      AND p.name = 'Andrew Tanzer [company:  TanzerVest LLC]'
    LIMIT 1
)
UNION ALL
-- Peter Bermont â†’ Andrew Tanzer [company:  TanzerVest LLC] (100 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 100,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Peter Bermont'
      AND p.name = 'Andrew Tanzer [company:  TanzerVest LLC]'
    LIMIT 1
)
UNION ALL
-- John Pomfret â†’ Andrew Tanzer [company:  TanzerVest LLC] (100 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 100,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'John Pomfret'
      AND p.name = 'Andrew Tanzer [company:  TanzerVest LLC]'
    LIMIT 1
)
UNION ALL
-- Stephen Tanzer â†’ Andrew Tanzer [company:  TanzerVest LLC] (100 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 100,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Stephen Tanzer'
      AND p.name = 'Andrew Tanzer [company:  TanzerVest LLC]'
    LIMIT 1
)
UNION ALL
-- Tim Ferguson â†’ Andrew Tanzer [company:  TanzerVest LLC] (100 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 100,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Tim Ferguson'
      AND p.name = 'Andrew Tanzer [company:  TanzerVest LLC]'
    LIMIT 1
)
UNION ALL
-- Eilon Sharon â†’ Uri Golani (200 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 200,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Eilon Sharon'
      AND p.name = 'Uri Golani'
    LIMIT 1
)
UNION ALL
-- Alon Ascher â†’ Uri Golani (200 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 200,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Alon Ascher'
      AND p.name = 'Uri Golani'
    LIMIT 1
)
UNION ALL
-- Julien Barbier â†’ Uri Golani (200 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 200,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Julien Barbier'
      AND p.name = 'Uri Golani'
    LIMIT 1
)
UNION ALL
-- Ling and Wang Song â†’ Uri Golani (200 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 200,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Ling and Wang Song'
      AND p.name = 'Uri Golani'
    LIMIT 1
)
UNION ALL
-- Yee Jiun Song â†’ Uri Golani (200 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 200,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Yee Jiun Song'
      AND p.name = 'Uri Golani'
    LIMIT 1
)
UNION ALL
-- Louis Blumberg [The AFB Fund LLC] â†’ Mordechai Kubany company:  Double Kappa, LLC (400 bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', 400,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = 'Louis Blumberg [The AFB Fund LLC]'
      AND p.name = 'Mordechai Kubany company:  Double Kappa, LLC'
    LIMIT 1
);

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Count of agreements by party
SELECT
    '=== Agreements by Party ===' as section,
    p.name as party_name,
    COUNT(a.id) as agreement_count
FROM agreements a
INNER JOIN parties p ON p.id = a.party_id
WHERE a.kind = 'distributor_commission'
  AND a.investor_id IS NOT NULL
GROUP BY p.name
ORDER BY agreement_count DESC;

-- Sample agreements
SELECT
    '=== Sample Investor Agreements ===' as section,
    p.name as party_name,
    i.name as investor_name,
    a.snapshot_json->>'equity_bps' as equity_bps,
    jsonb_array_length(a.snapshot_json->'terms') as tier_count
FROM agreements a
INNER JOIN parties p ON p.id = a.party_id
INNER JOIN investors i ON i.id = a.investor_id
WHERE a.kind = 'distributor_commission'
ORDER BY p.name, i.name
LIMIT 20;

-- Total count
SELECT
    '=== Total Investor Agreements ===' as section,
    COUNT(*) as total_agreements
FROM agreements
WHERE kind = 'distributor_commission'
  AND investor_id IS NOT NULL;

-- ============================================================================
-- SKIPPED ROWS (for reference)
-- ============================================================================
-- SKIPPED: MTRA Ltd -  (Could not parse equity %)
-- SKIPPED: Orchid Real Estate LLC -  (Could not parse equity %)
-- SKIPPED: Scott Tobin -  (Could not parse equity %)
-- SKIPPED: Ari Milstein -  (Could not parse equity %)
-- SKIPPED: Paul Friedman -  (Could not parse equity %)
-- SKIPPED: Andrew & Ilana Album -  (Could not parse equity %)
-- SKIPPED: Robin Sand -  (Could not parse equity %)
-- SKIPPED: C. Marc Halbfinger -  (Could not parse equity %)
-- SKIPPED: BS Partners -  (Could not parse equity %)
-- SKIPPED: BD Partnership -  (Could not parse equity %)
-- SKIPPED: Ahuva Cohen -  (Could not parse equity %)
-- SKIPPED: Diane Kirschenbaum -  (Could not parse equity %)
-- SKIPPED: Hoaloha Holdings Limited -  (Could not parse equity %)
-- SKIPPED: Jeff Theobald -  (Could not parse equity %)
-- SKIPPED: H & S Jacobson Investments LLC -  (Could not parse equity %)
-- SKIPPED: George Alex Popescu -  (Could not parse equity %)
-- SKIPPED: David Waiman (and anyone he brings with him) -  (Could not parse equity %)
-- SKIPPED: Yitzhak Meron -  (Could not parse equity %)
-- SKIPPED: I.M.R.M. Investments Ltd -  (Could not parse equity %)
-- SKIPPED: Doron Tishman (IRAs) -  (Could not parse equity %)
-- SKIPPED: Nahumi Family Trust -  (Could not parse equity %)
-- SKIPPED: Zecharia Oren -  (Could not parse equity %)
-- SKIPPED: Oren Family Trust -  (Could not parse equity %)
-- SKIPPED: Eran Inbar -  (Could not parse equity %)
-- SKIPPED: Galila Tabachnikov Oren -  (Could not parse equity %)
-- SKIPPED: Nili Karabel -  (Could not parse equity %)
-- SKIPPED: Karabel International Investments Ltd -  (Could not parse equity %)
-- SKIPPED: Arnon Ron -  (Could not parse equity %)
-- SKIPPED: Haggit Levy -  (Could not parse equity %)
-- SKIPPED: Moshe Dovev -  (Could not parse equity %)
-- SKIPPED: Mordechai Peled -  (Could not parse equity %)
-- SKIPPED: Eyal Brayer (EMB Brayer) -  (Could not parse equity %)
-- SKIPPED: Haim Hoffman -  (Could not parse equity %)
-- SKIPPED: Lior Wolf -  (Could not parse equity %)
-- SKIPPED: Yuval Naftali -  (Could not parse equity %)
-- SKIPPED: Lior Cohen -  (Could not parse equity %)
-- SKIPPED: Rachel Szytglich Even Chen -  (Could not parse equity %)
-- SKIPPED: Barak & Yael Perlman -  (Could not parse equity %)
-- SKIPPED: Alon Even Chen (not Alon Even-Chen) -  (Could not parse equity %)
-- SKIPPED: Eyal & Ruhama Ben Eliezer -  (Could not parse equity %)
-- SKIPPED: DGG Michal LLC -  (Could not parse equity %)
-- SKIPPED: Techno Magnetic Media & Computer Supplies Inc -  (Could not parse equity %)
-- SKIPPED: 2224935 Ontario Inc. -  (Could not parse equity %)
-- SKIPPED: Dan Zur-Lior Wolf Landscape Architects Ltd -  (Could not parse equity %)
-- SKIPPED: Guy Assif -  (Could not parse equity %)
-- SKIPPED: Abraham Amos -  (Could not parse equity %)
-- SKIPPED: Guy Avtalion -  (Could not parse equity %)
-- SKIPPED: Fabian Tenenbaum -  (Could not parse equity %)
-- SKIPPED: Amir Novik - IRA -  (Could not parse equity %)
-- SKIPPED: Einav Itamar -  (Could not parse equity %)
-- ... and 100 more skipped rows
