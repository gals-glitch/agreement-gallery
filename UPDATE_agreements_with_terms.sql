-- ============================================================================
-- [UPDATE] Set Parsed Terms for All 110 Investor Agreements
-- ============================================================================
-- Agreement Types:
--   - simple_equity: Fixed equity percentage (e.g., 1% = 100 bps)
--   - upfront_promote: Separate rates for upfront and promote
--   - tiered_by_deal_count: Different rates based on deal number
--   - deal_specific_limit: Limited to specific deals or max count
--   - flat_fee: One-time payment
--
-- NOTE: Temporarily disables immutability trigger for initial data setup
-- ============================================================================

-- Step 1: Temporarily disable the immutability trigger
ALTER TABLE agreements DISABLE TRIGGER agreements_lock_after_approval;

-- Step 2: Update all agreements with their parsed terms

-- Agreement Breakdown:
--   simple_equity: 56
--   upfront_promote: 28
--   tiered_by_deal_count: 26
--   flat_fee: 1
--   deal_specific_limit: 1

-- [simple_equity] Kuperman Entity
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 100,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Kuperman Entity'
  AND p.name = 'Kuperman';

-- [upfront_promote] DGTA Ltd
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'upfront_promote',
                'upfront_rate', null,
                'promote_rate', 0.27,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'DGTA Ltd'
  AND p.name = 'Shai Sheffer';

-- [upfront_promote] Fresh Properties and Investments
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'upfront_promote',
                'upfront_rate', null,
                'promote_rate', 0.27,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Fresh Properties and Investments'
  AND p.name = 'Yoram Dvash';

-- [simple_equity] Steve Ball
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 100,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Steve Ball'
  AND p.name = 'Yoni Frieder';

-- [upfront_promote] Peter Gyenes
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'upfront_promote',
                'upfront_rate', 0.25,
                'promote_rate', null,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Peter Gyenes'
  AND p.name = 'Cross Arch Holdings -David Kirchenbaum';

-- [upfront_promote] Barry Kirschenbaum
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'upfront_promote',
                'upfront_rate', null,
                'promote_rate', 0.25,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Barry Kirschenbaum'
  AND p.name = 'Cross Arch Holdings -David Kirchenbaum';

-- [upfront_promote] Gil Shalit
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'upfront_promote',
                'upfront_rate', 0.25,
                'promote_rate', null,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Gil Shalit'
  AND p.name = 'Ronnie Maliniak';

-- [upfront_promote] Roni Atoun (Green Orka, AC Applications)
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'upfront_promote',
                'upfront_rate', null,
                'promote_rate', 0.25,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Roni Atoun (Green Orka, AC Applications)'
  AND p.name = 'Ronnie Maliniak';

-- [upfront_promote] The Service (Sheltered Housing)
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'upfront_promote',
                'upfront_rate', 0.1,
                'promote_rate', 0.1,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'The Service (Sheltered Housing)'
  AND p.name = 'Ronnie Maliniak';

-- [upfront_promote] Ehud Svirsky
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'upfront_promote',
                'upfront_rate', 0.25,
                'promote_rate', null,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Ehud Svirsky'
  AND p.name = 'Ilanit Tirosh';

-- [upfront_promote] Miri Kerbs (A-T Management)
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'upfront_promote',
                'upfront_rate', null,
                'promote_rate', 0.15,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Miri Kerbs (A-T Management)'
  AND p.name = 'Ilanit Tirosh';

-- [upfront_promote] Dror Nahumi
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'upfront_promote',
                'upfront_rate', 0.15,
                'promote_rate', null,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Dror Nahumi'
  AND p.name = 'Tal Simchony';

-- [upfront_promote] Any IRAs
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'upfront_promote',
                'upfront_rate', 0.05,
                'promote_rate', 0.05,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Any IRAs'
  AND p.name = 'Tal Simchony';

-- [upfront_promote] Yoram Avi-Guy
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'upfront_promote',
                'upfront_rate', 0.25,
                'promote_rate', null,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Yoram Avi-Guy'
  AND p.name = 'Yoram Shalit';

-- [upfront_promote] Eran & Nitsa Tal
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'upfront_promote',
                'upfront_rate', null,
                'promote_rate', 0.15,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Eran & Nitsa Tal'
  AND p.name = 'Yoram Shalit';

-- [simple_equity] Nili Karabel IRA
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 100,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Nili Karabel IRA'
  AND p.name = 'Yoram Shalit';

-- [upfront_promote] Chaim Zach (HMCA SA)
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'upfront_promote',
                'upfront_rate', 0.15,
                'promote_rate', null,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Chaim Zach (HMCA SA)'
  AND p.name = 'GW CPA';

-- [upfront_promote] Eran Farajun
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'upfront_promote',
                'upfront_rate', 0.25,
                'promote_rate', null,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Eran Farajun'
  AND p.name = 'Guy Moses';

-- [upfront_promote] Naomi Rudich
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'upfront_promote',
                'upfront_rate', null,
                'promote_rate', 0.15,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Naomi Rudich'
  AND p.name = 'Guy Moses';

-- [upfront_promote] Howard Loboda
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'upfront_promote',
                'upfront_rate', 0.15,
                'promote_rate', null,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Howard Loboda'
  AND p.name = 'Sheara Einhorn';

-- [upfront_promote] Nurit Preis
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'upfront_promote',
                'upfront_rate', 0.15,
                'promote_rate', null,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Nurit Preis'
  AND p.name = 'Lior Stinus from Freidkes & Co. CPA';

-- [upfront_promote] Shay Mizrachi
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'upfront_promote',
                'upfront_rate', 0.15,
                'promote_rate', null,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Shay Mizrachi'
  AND p.name = 'Avi Fried';

-- [upfront_promote] Shulamit Shimon
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'upfront_promote',
                'upfront_rate', 0.15,
                'promote_rate', null,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Shulamit Shimon'
  AND p.name = 'Formula Ventures Ltd- Shai Beilis';

-- [simple_equity] Moshe Friedman
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 100,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Moshe Friedman'
  AND p.name = 'Ilan Kapelner Management Services ltd- Ilan Kapelner';

-- [simple_equity] Emanuel & Netanel Parter
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 100,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Emanuel & Netanel Parter'
  AND p.name = 'Shlomo Waldmann';

-- [simple_equity] Ehud Hameiri - Ash-Hag Consultants Ltd
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 75,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Ehud Hameiri - Ash-Hag Consultants Ltd'
  AND p.name = 'Rubin Schlussel';

-- [simple_equity] Dov David & Dorit Gerecht Albukrek
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 50,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Dov David & Dorit Gerecht Albukrek'
  AND p.name = 'HNA Investments Limited Liability- Ilan Grinberg and Jacob Asia (together)';

-- [simple_equity] Yehezkel Gabai
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 100,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Yehezkel Gabai'
  AND p.name = 'Yoram Avi-Guy Lawyer- Yoram Avi Guy';

-- [simple_equity] David Michaeli
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 150,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'David Michaeli'
  AND p.name = 'HS Invest Pension Insurance Agency (2016) ltd- Hezi Schwartz';

-- [upfront_promote] Haim Helman
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'upfront_promote',
                'upfront_rate', null,
                'promote_rate', 0.1,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Haim Helman'
  AND p.name = 'HS Invest Pension Insurance Agency (2016) ltd- Hezi Schwartz';

-- [simple_equity] David Reichman - commission for himself only on Beaufort
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 100,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'David Reichman - commission for himself only on Beaufort'
  AND p.name = 'David Reichman';

-- [upfront_promote] Yoram Mizrachi
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'upfront_promote',
                'upfront_rate', null,
                'promote_rate', 0.1,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Yoram Mizrachi'
  AND p.name = 'David Reichman';

-- [simple_equity] Alin Ajami Atzmon
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 50,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Alin Ajami Atzmon'
  AND p.name = 'Agamim Commercial Real Estate- Moti Agam';

-- [simple_equity] Barak Matalon
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 7500,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Barak Matalon'
  AND p.name = 'Natai Investments- Alon Even Chen';

-- [simple_equity] Shalom Josef Hochman
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 100,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Shalom Josef Hochman'
  AND p.name = 'Wiser Finance- Michael Mann';

-- [upfront_promote] Yigal Ben David
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'upfront_promote',
                'upfront_rate', null,
                'promote_rate', 0.1,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Yigal Ben David'
  AND p.name = 'Wiser Finance- Michael Mann';

-- [simple_equity] Rami Pais
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 7500,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Rami Pais'
  AND p.name = 'Pioneer Wealth Management- Liat F';

-- [simple_equity] Shmuel Parag
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 500,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Shmuel Parag'
  AND p.name = 'Tal Even';

-- [simple_equity] Noa Juhn Parag
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 500,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Noa Juhn Parag'
  AND p.name = 'Tal Even';

-- [simple_equity] Jared Holzman
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 100,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Jared Holzman'
  AND p.name = 'Tal Even';

-- [simple_equity] Nissim Bar Siman Tov
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 100,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Nissim Bar Siman Tov'
  AND p.name = 'Tal Even';

-- [simple_equity] Ari Aharon Hillel - Check with Erez
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 50,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Ari Aharon Hillel - Check with Erez'
  AND p.name = 'Eyal Hrring- Financial Planning and Strategy- Eyal Herring';

-- [simple_equity] Limor Sagiv
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 100,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Limor Sagiv'
  AND p.name = 'Yariv Avrahami';

-- [simple_equity] Dan Pastenernak
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 100,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Dan Pastenernak'
  AND p.name = 'Yariv Avrahami';

-- [simple_equity] Sima Ben Chitrit
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 100,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Sima Ben Chitrit'
  AND p.name = 'Yariv Avrahami';

-- [simple_equity] Yury Sofman
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 500,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Yury Sofman'
  AND p.name = 'ThinkWise Consulting LLC- Lior Cohen';

-- [simple_equity] Ori Peled
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 500,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Ori Peled'
  AND p.name = 'Gilad Slonim Insurance Agency Ltd- Gilad Slonim';

-- [simple_equity] Ogenruth Ltd
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 100,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Ogenruth Ltd'
  AND p.name = 'Gilad Slonim Insurance Agency Ltd- Gilad Slonim';

-- [simple_equity] Jonathan & Tova Mann
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 100,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Jonathan & Tova Mann'
  AND p.name = 'Iprofit Ltd- Yifat Igler';

-- [simple_equity] Nir Tzur
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 100,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Nir Tzur'
  AND p.name = 'Saar Gavish';

-- [simple_equity] Ariel Spivak
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 100,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Ariel Spivak'
  AND p.name = 'YL Consulting Inc- Yoav Lachover';

-- [upfront_promote] Ayal Brener
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'upfront_promote',
                'upfront_rate', null,
                'promote_rate', 0.1,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Ayal Brener'
  AND p.name = 'YL Consulting Inc- Yoav Lachover';

-- [simple_equity] RAC Advisors LLC
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 150,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'RAC Advisors LLC'
  AND p.name = 'Dror Zetouni';

-- [simple_equity] Adam Gotskind
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 150,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Adam Gotskind'
  AND p.name = 'Dror Zetouni';

-- [simple_equity] Steve Feiger
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 150,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Steve Feiger'
  AND p.name = 'Dror Zetouni';

-- [simple_equity] Fred Margulies
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 150,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Fred Margulies'
  AND p.name = 'Dror Zetouni';

-- [simple_equity] David Schreiber
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 150,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'David Schreiber'
  AND p.name = 'Dror Zetouni';

-- [simple_equity] Stan Weissbrot
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 150,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Stan Weissbrot'
  AND p.name = 'Dror Zetouni';

-- [simple_equity] Abraham Stern
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 150,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Abraham Stern'
  AND p.name = 'Dror Zetouni';

-- [simple_equity] Avi Shaked
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 150,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Avi Shaked'
  AND p.name = 'Dror Zetouni';

-- [simple_equity] Charles Serlin
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 150,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Charles Serlin'
  AND p.name = 'Dror Zetouni';

-- [simple_equity] Robert Marconi
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 150,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Robert Marconi'
  AND p.name = 'Dror Zetouni';

-- [simple_equity] Todd Stern
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 150,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Todd Stern'
  AND p.name = 'Dror Zetouni';

-- [simple_equity] Jack Faintuch
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 150,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Jack Faintuch'
  AND p.name = 'Dror Zetouni';

-- [simple_equity] Rafael Ashkenazi
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 100,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Rafael Ashkenazi'
  AND p.name = 'Lighthouse F.S Ltd- Avihay';

-- [upfront_promote] Shmuel Carmon
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'upfront_promote',
                'upfront_rate', null,
                'promote_rate', 0.1,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Shmuel Carmon'
  AND p.name = 'Lighthouse F.S Ltd- Avihay';

-- [simple_equity] Gilad Kapelushnick
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 100,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Gilad Kapelushnick'
  AND p.name = 'Sparta Capital- Yonel Dvash';

-- [simple_equity] Dan Krausz
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 150,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Dan Krausz'
  AND p.name = 'Gil Haramati';

-- [simple_equity] Nicky Stup & Wife
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 150,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Nicky Stup & Wife'
  AND p.name = 'Gil Haramati';

-- [simple_equity] Ofer Ben-Aharon
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 150,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Ofer Ben-Aharon'
  AND p.name = 'Gil Haramati';

-- [simple_equity] Ofer Levy
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 150,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Ofer Levy'
  AND p.name = 'Gil Haramati';

-- [simple_equity] Boaz Paz
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 150,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Boaz Paz'
  AND p.name = 'Beny Shafir';

-- [simple_equity] Roliya Investments LLC
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 50,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Roliya Investments LLC'
  AND p.name = 'Atiela Investments Ltd- Yoav Holzer';

-- [simple_equity] Tehila Ben Moshe
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 100,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Tehila Ben Moshe'
  AND p.name = 'Capital Link Family Office- Shiri Hybloom';

-- [simple_equity] Doron Peretz
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 100,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Doron Peretz'
  AND p.name = 'Capital Link Family Office- Shiri Hybloom';

-- [simple_equity] Yoram Baumann
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 50,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Yoram Baumann'
  AND p.name = 'Capital Link Family Office- Shiri Hybloom';

-- [tiered_by_deal_count] Maragret Frank
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'tiered_by_deal_count',
                'tiers', jsonb_build_array(jsonb_build_object('deal_range', '1', 'equity_bps', 150), jsonb_build_object('deal_range', '2-3', 'equity_bps', 150)),
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Maragret Frank'
  AND p.name = 'Isaac Fattal';

-- [simple_equity] Benny Silverman
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 50,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Benny Silverman'
  AND p.name = 'Stark Yoel Kadish, Lawyer (Accountant)- Yoel Stark';

-- [tiered_by_deal_count] Mickey Amir Hanegbee Kaplinsky
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'tiered_by_deal_count',
                'tiers', jsonb_build_array(jsonb_build_object('deal_range', '1', 'equity_bps', 150), jsonb_build_object('deal_range', '2-3', 'equity_bps', 150)),
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Mickey Amir Hanegbee Kaplinsky'
  AND p.name = 'SRI Global Group- Daphna';

-- [tiered_by_deal_count] Eliezer Abramov
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'tiered_by_deal_count',
                'tiers', jsonb_build_array(jsonb_build_object('deal_range', '1', 'equity_bps', 150), jsonb_build_object('deal_range', '2-3', 'equity_bps', 150)),
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Eliezer Abramov'
  AND p.name = 'SRI Global Group- Daphna';

-- [tiered_by_deal_count] Yuval Shacham
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'tiered_by_deal_count',
                'tiers', jsonb_build_array(jsonb_build_object('deal_range', '1', 'equity_bps', 150), jsonb_build_object('deal_range', '2-3', 'equity_bps', 150)),
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Yuval Shacham'
  AND p.name = 'SRI Global Group- Daphna';

-- [tiered_by_deal_count] Frank Cortese
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'tiered_by_deal_count',
                'tiers', jsonb_build_array(jsonb_build_object('deal_range', '1', 'equity_bps', 150), jsonb_build_object('deal_range', '2-3', 'equity_bps', 150)),
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Frank Cortese'
  AND p.name = 'Gabriel Taub';

-- [tiered_by_deal_count] Brenden Selway
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'tiered_by_deal_count',
                'tiers', jsonb_build_array(jsonb_build_object('deal_range', '1', 'equity_bps', 150), jsonb_build_object('deal_range', '2-3', 'equity_bps', 150)),
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Brenden Selway'
  AND p.name = 'Gabriel Taub';

-- [tiered_by_deal_count] Octavian Patrascu (Netcore Investments Limited)
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'tiered_by_deal_count',
                'tiers', jsonb_build_array(jsonb_build_object('deal_range', '1', 'equity_bps', 150), jsonb_build_object('deal_range', '2-3', 'equity_bps', 150)),
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Octavian Patrascu (Netcore Investments Limited)'
  AND p.name = 'Amit Zeevi';

-- [tiered_by_deal_count] Idan Grossman - Mangro Pty Ltd as Trustee for Mind Plus Trust
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'tiered_by_deal_count',
                'tiers', jsonb_build_array(jsonb_build_object('deal_range', '1', 'equity_bps', 150), jsonb_build_object('deal_range', '2-3', 'equity_bps', 150)),
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Idan Grossman - Mangro Pty Ltd as Trustee for Mind Plus Trust'
  AND p.name = 'Amit Zeevi';

-- [tiered_by_deal_count] Idan Kornfeld
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'tiered_by_deal_count',
                'tiers', jsonb_build_array(jsonb_build_object('deal_range', '1', 'equity_bps', 150), jsonb_build_object('deal_range', '2-3', 'equity_bps', 150)),
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Idan Kornfeld'
  AND p.name = 'Amit Zeevi';

-- [tiered_by_deal_count] Ofir Rozenfeld
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'tiered_by_deal_count',
                'tiers', jsonb_build_array(jsonb_build_object('deal_range', '1', 'equity_bps', 150), jsonb_build_object('deal_range', '2-3', 'equity_bps', 150)),
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Ofir Rozenfeld'
  AND p.name = 'Roy Gold';

-- [tiered_by_deal_count] Shlomit Rosenfeld
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'tiered_by_deal_count',
                'tiers', jsonb_build_array(jsonb_build_object('deal_range', '1', 'equity_bps', 150), jsonb_build_object('deal_range', '2-3', 'equity_bps', 150)),
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Shlomit Rosenfeld'
  AND p.name = 'Roy Gold';

-- [tiered_by_deal_count] Aharon Rasouli
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'tiered_by_deal_count',
                'tiers', jsonb_build_array(jsonb_build_object('deal_range', '1', 'equity_bps', 150), jsonb_build_object('deal_range', '2-3', 'equity_bps', 150)),
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Aharon Rasouli'
  AND p.name = 'Roy Gold';

-- [tiered_by_deal_count] Miri Rozenfeld
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'tiered_by_deal_count',
                'tiers', jsonb_build_array(jsonb_build_object('deal_range', '1', 'equity_bps', 150), jsonb_build_object('deal_range', '2-3', 'equity_bps', 150)),
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Miri Rozenfeld'
  AND p.name = 'Roy Gold';

-- [tiered_by_deal_count] Nomi A. Holdings Ltd
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'tiered_by_deal_count',
                'tiers', jsonb_build_array(jsonb_build_object('deal_range', '1', 'equity_bps', 150), jsonb_build_object('deal_range', '2-3', 'equity_bps', 150)),
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Nomi A. Holdings Ltd'
  AND p.name = 'Tzafit Pension Insurance Agency (2023) Ltd';

-- [tiered_by_deal_count] Gene Dattel
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'tiered_by_deal_count',
                'tiers', jsonb_build_array(jsonb_build_object('deal_range', '1', 'equity_bps', 100), jsonb_build_object('deal_range', '2-3', 'equity_bps', 100)),
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Gene Dattel'
  AND p.name = 'Andrew Tanzer [company:  TanzerVest LLC]';

-- [tiered_by_deal_count] Licia Hahn
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'tiered_by_deal_count',
                'tiers', jsonb_build_array(jsonb_build_object('deal_range', '1', 'equity_bps', 100), jsonb_build_object('deal_range', '2-3', 'equity_bps', 100)),
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Licia Hahn'
  AND p.name = 'Andrew Tanzer [company:  TanzerVest LLC]';

-- [tiered_by_deal_count] Peter Bermont
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'tiered_by_deal_count',
                'tiers', jsonb_build_array(jsonb_build_object('deal_range', '1', 'equity_bps', 100), jsonb_build_object('deal_range', '2-3', 'equity_bps', 100)),
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Peter Bermont'
  AND p.name = 'Andrew Tanzer [company:  TanzerVest LLC]';

-- [tiered_by_deal_count] John Pomfret
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'tiered_by_deal_count',
                'tiers', jsonb_build_array(jsonb_build_object('deal_range', '1', 'equity_bps', 100), jsonb_build_object('deal_range', '2-3', 'equity_bps', 100)),
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'John Pomfret'
  AND p.name = 'Andrew Tanzer [company:  TanzerVest LLC]';

-- [tiered_by_deal_count] Stephen Tanzer
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'tiered_by_deal_count',
                'tiers', jsonb_build_array(jsonb_build_object('deal_range', '1', 'equity_bps', 100), jsonb_build_object('deal_range', '2-3', 'equity_bps', 100)),
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Stephen Tanzer'
  AND p.name = 'Andrew Tanzer [company:  TanzerVest LLC]';

-- [tiered_by_deal_count] Tim Ferguson
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'tiered_by_deal_count',
                'tiers', jsonb_build_array(jsonb_build_object('deal_range', '1', 'equity_bps', 100), jsonb_build_object('deal_range', '2-3', 'equity_bps', 100)),
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Tim Ferguson'
  AND p.name = 'Andrew Tanzer [company:  TanzerVest LLC]';

-- [tiered_by_deal_count] Eilon Sharon
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'tiered_by_deal_count',
                'tiers', jsonb_build_array(jsonb_build_object('deal_range', '1', 'equity_bps', 200), jsonb_build_object('deal_range', '2-3', 'equity_bps', 200), jsonb_build_object('deal_range', '2+', 'equity_bps', 100)),
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Eilon Sharon'
  AND p.name = 'Uri Golani';

-- [tiered_by_deal_count] Alon Ascher
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'tiered_by_deal_count',
                'tiers', jsonb_build_array(jsonb_build_object('deal_range', '1', 'equity_bps', 200), jsonb_build_object('deal_range', '2-3', 'equity_bps', 200), jsonb_build_object('deal_range', '2+', 'equity_bps', 100)),
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Alon Ascher'
  AND p.name = 'Uri Golani';

-- [tiered_by_deal_count] Julien Barbier
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'tiered_by_deal_count',
                'tiers', jsonb_build_array(jsonb_build_object('deal_range', '1', 'equity_bps', 200), jsonb_build_object('deal_range', '2-3', 'equity_bps', 200), jsonb_build_object('deal_range', '2+', 'equity_bps', 100)),
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Julien Barbier'
  AND p.name = 'Uri Golani';

-- [tiered_by_deal_count] Ling and Wang Song
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'tiered_by_deal_count',
                'tiers', jsonb_build_array(jsonb_build_object('deal_range', '1', 'equity_bps', 200), jsonb_build_object('deal_range', '2-3', 'equity_bps', 200), jsonb_build_object('deal_range', '2+', 'equity_bps', 100)),
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Ling and Wang Song'
  AND p.name = 'Uri Golani';

-- [tiered_by_deal_count] Yee Jiun Song
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'tiered_by_deal_count',
                'tiers', jsonb_build_array(jsonb_build_object('deal_range', '1', 'equity_bps', 200), jsonb_build_object('deal_range', '2-3', 'equity_bps', 200), jsonb_build_object('deal_range', '2+', 'equity_bps', 100)),
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Yee Jiun Song'
  AND p.name = 'Uri Golani';

-- [simple_equity] Louis Blumberg [The AFB Fund LLC]
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 400,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Louis Blumberg [The AFB Fund LLC]'
  AND p.name = 'Mordechai Kubany company:  Double Kappa, LLC';

-- [simple_equity] Yaniv Radia
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 350,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Yaniv Radia'
  AND p.name = 'Kuperman';

-- [simple_equity] Gil Serok Revocable Trust
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 350,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Gil Serok Revocable Trust'
  AND p.name = 'Kuperman';

-- [simple_equity] Gadi Gerbi
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', 350,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Gadi Gerbi'
  AND p.name = 'Kuperman';

-- [upfront_promote] Avraham Weiss
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'upfront_promote',
                'upfront_rate', 0.075,
                'promote_rate', 0.075,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Avraham Weiss'
  AND p.name = 'Guy Moses';

-- [upfront_promote] Pladot Paldom Ltd
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'upfront_promote',
                'upfront_rate', 0.075,
                'promote_rate', 0.075,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Pladot Paldom Ltd'
  AND p.name = 'Guy Moses';

-- [upfront_promote] Noam Zegman
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'upfront_promote',
                'upfront_rate', 0.075,
                'promote_rate', 0.075,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Noam Zegman'
  AND p.name = 'Guy Moses';

-- [flat_fee] Ariel Efrati
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'flat_fee',
                'flat_fee', 1000,
                'currency', 'USD'
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Ariel Efrati'
  AND p.name = 'Yair Almagor';

-- [tiered_by_deal_count] David Goone
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'tiered_by_deal_count',
                'tiers', jsonb_build_array(jsonb_build_object('deal_range', '1', 'equity_bps', 150), jsonb_build_object('deal_range', '2-3', 'equity_bps', 100), jsonb_build_object('deal_range', '4-5', 'equity_bps', 50)),
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'David Goone'
  AND p.name = 'Dror Zetouni ';

-- [deal_specific_limit] Matthew Rosenbluth Rosenbluth Trust
UPDATE agreements
SET snapshot_json = jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'deal_specific_limit',
                'equity_bps', 100,
                'max_deals', 3,
                'specific_deals', jsonb_build_array('Perdido'),
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            ),
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = 'Matthew Rosenbluth Rosenbluth Trust'
  AND p.name = 'Brian Horner';


-- ============================================================================
-- Step 3: Re-enable the immutability trigger
-- ============================================================================

ALTER TABLE agreements ENABLE TRIGGER agreements_lock_after_approval;

-- ============================================================================
-- VERIFICATION: Check Updated Agreements
-- ============================================================================

SELECT
    '=== Agreement Types ===' as section,
    snapshot_json->>'agreement_type' as agreement_type,
    COUNT(*) as count
FROM agreements
WHERE kind = 'distributor_commission'
  AND investor_id IS NOT NULL
GROUP BY snapshot_json->>'agreement_type'
ORDER BY count DESC;

-- Sample agreements by type
SELECT
    '=== Sample Simple Equity ===' as section,
    i.name as investor_name,
    snapshot_json->>'equity_bps' as equity_bps,
    snapshot_json->>'commission_rate' as commission_rate
FROM agreements a
INNER JOIN investors i ON i.id = a.investor_id
WHERE a.kind = 'distributor_commission'
  AND a.snapshot_json->>'agreement_type' = 'simple_equity'
LIMIT 5;

SELECT
    '=== Sample Upfront/Promote ===' as section,
    i.name as investor_name,
    snapshot_json->>'upfront_rate' as upfront_rate,
    snapshot_json->>'promote_rate' as promote_rate
FROM agreements a
INNER JOIN investors i ON i.id = a.investor_id
WHERE a.kind = 'distributor_commission'
  AND a.snapshot_json->>'agreement_type' = 'upfront_promote'
LIMIT 5;

SELECT
    '=== Sample Tiered ===' as section,
    i.name as investor_name,
    jsonb_array_length(snapshot_json->'tiers') as tier_count,
    snapshot_json->'tiers'->0->>'equity_bps' as tier_1_equity_bps
FROM agreements a
INNER JOIN investors i ON i.id = a.investor_id
WHERE a.kind = 'distributor_commission'
  AND a.snapshot_json->>'agreement_type' = 'tiered_by_deal_count'
LIMIT 5;
