-- ============================================================================
-- [FIX] Create Missing Investors/Parties and Fix Relationships
-- ============================================================================
-- Date: 2025-10-26 15:33:00
--
-- DIAGNOSTIC SUMMARY:
-- - 110 investor-party mappings with equity percentages
-- - 57 have both investor and party in database
-- - 47 investors are MISSING
-- - 7 parties are MISSING
-- - Only 3/57 agreements created (introduced_by mismatch)
-- ============================================================================

-- Step 1: Create temp table with all mappings
CREATE TEMP TABLE tmp_fix_mappings (
    investor_name TEXT,
    party_name TEXT,
    equity_bps INTEGER
);

INSERT INTO tmp_fix_mappings VALUES
('Kuperman Entity', 'Kuperman', 100),
('Yaniv Radia', 'Kuperman', 2500),
('Gil Serok Revocable Trust', 'Kuperman', 2700),
('Gadi Gerbi', 'Kuperman', 3000),
('DGTA Ltd', 'Shai Sheffer', 2700),
('Fresh Properties and Investments', 'Yoram Dvash', 2700),
('Steve Ball', 'Yoni Frieder', 100),
('Peter Gyenes', 'Cross Arch Holdings -David Kirchenbaum', 2500),
('Barry Kirschenbaum', 'Cross Arch Holdings -David Kirchenbaum', 2500),
('Gil Shalit', 'Ronnie Maliniak', 2500),
('Roni Atoun (Green Orka, AC Applications)', 'Ronnie Maliniak', 2500),
('The Service (Sheltered Housing)', 'Ronnie Maliniak', 1000),
('Ehud Svirsky', 'Ilanit Tirosh', 2500),
('Miri Kerbs (A-T Management)', 'Ilanit Tirosh', 1500),
('Dror Nahumi', 'Tal Simchony', 1500),
('Any IRAs', 'Tal Simchony', 500),
('Yoram Avi-Guy', 'Yoram Shalit', 2500),
('Eran & Nitsa Tal', 'Yoram Shalit', 1500),
('Nili Karabel IRA', 'Yoram Shalit', 100),
('Chaim Zach (HMCA SA)', 'GW CPA', 1500),
('Eran Farajun', 'Guy Moses', 2500),
('Naomi Rudich', 'Guy Moses', 1500),
('Avraham Weiss', 'Guy Moses', 5000),
('Pladot Paldom Ltd', 'Guy Moses', 5000),
('Noam Zegman', 'Guy Moses', 5000),
('Howard Loboda', 'Sheara Einhorn', 1500),
('Nurit Preis', 'Lior Stinus from Freidkes & Co. CPA', 1500),
('Shay Mizrachi', 'Avi Fried', 1500),
('Shulamit Shimon', 'Formula Ventures Ltd- Shai Beilis', 1500),
('Moshe Friedman', 'Ilan Kapelner Management Services ltd- Ilan Kapelner', 100),
('Emanuel & Netanel Parter', 'Shlomo Waldmann', 100),
('Ehud Hameiri - Ash-Hag Consultants Ltd', 'Rubin Schlussel', 75),
('Dov David & Dorit Gerecht Albukrek', 'HNA Investments Limited Liability- Ilan Grinberg and Jacob Asia (together)', 50),
('Yehezkel Gabai', 'Yoram Avi-Guy Lawyer- Yoram Avi Guy', 100),
('David Michaeli', 'HS Invest Pension Insurance Agency (2016) ltd- Hezi Schwartz', 150),
('Haim Helman', 'HS Invest Pension Insurance Agency (2016) ltd- Hezi Schwartz', 1000),
('David Reichman - commission for himself only on Beaufort', 'David Reichman', 100),
('Yoram Mizrachi', 'David Reichman', 1000),
('Alin Ajami Atzmon', 'Agamim Commercial Real Estate- Moti Agam', 50),
('Barak Matalon', 'Natai Investments- Alon Even Chen', 7500),
('Shalom Josef Hochman', 'Wiser Finance- Michael Mann', 100),
('Yigal Ben David', 'Wiser Finance- Michael Mann', 1000),
('Rami Pais', 'Pioneer Wealth Management- Liat F', 7500),
('Shmuel Parag', 'Tal Even', 500),
('Noa Juhn Parag', 'Tal Even', 500),
('Jared Holzman', 'Tal Even', 100),
('Nissim Bar Siman Tov', 'Tal Even', 100),
('Ari Aharon Hillel - Check with Erez', 'Eyal Hrring- Financial Planning and Strategy- Eyal Herring', 50),
('Limor Sagiv', 'Yariv Avrahami', 100),
('Dan Pastenernak', 'Yariv Avrahami', 100),
('Sima Ben Chitrit', 'Yariv Avrahami', 100),
('Yury Sofman', 'ThinkWise Consulting LLC- Lior Cohen', 500),
('Ori Peled', 'Gilad Slonim Insurance Agency Ltd- Gilad Slonim', 500),
('Ogenruth Ltd', 'Gilad Slonim Insurance Agency Ltd- Gilad Slonim', 100),
('Jonathan & Tova Mann', 'Iprofit Ltd- Yifat Igler', 100),
('Nir Tzur', 'Saar Gavish', 100),
('Ariel Spivak', 'YL Consulting Inc- Yoav Lachover', 100),
('Ayal Brener', 'YL Consulting Inc- Yoav Lachover', 1000),
('RAC Advisors LLC', 'Dror Zetouni', 150),
('Adam Gotskind', 'Dror Zetouni', 150),
('Steve Feiger', 'Dror Zetouni', 150),
('Fred Margulies', 'Dror Zetouni', 150),
('David Schreiber', 'Dror Zetouni', 150),
('Stan Weissbrot', 'Dror Zetouni', 150),
('Abraham Stern', 'Dror Zetouni', 150),
('Avi Shaked', 'Dror Zetouni', 150),
('Charles Serlin', 'Dror Zetouni', 150),
('Robert Marconi', 'Dror Zetouni', 150),
('Todd Stern', 'Dror Zetouni', 150),
('Jack Faintuch', 'Dror Zetouni', 150),
('Rafael Ashkenazi', 'Lighthouse F.S Ltd- Avihay', 100),
('Shmuel Carmon', 'Lighthouse F.S Ltd- Avihay', 1000),
('Gilad Kapelushnick', 'Sparta Capital- Yonel Dvash', 100),
('Dan Krausz', 'Gil Haramati', 150),
('Nicky Stup & Wife', 'Gil Haramati', 150),
('Ofer Ben-Aharon', 'Gil Haramati', 150),
('Ofer Levy', 'Gil Haramati', 150),
('Boaz Paz', 'Beny Shafir', 150),
('Roliya Investments LLC', 'Atiela Investments Ltd- Yoav Holzer', 50),
('Tehila Ben Moshe', 'Capital Link Family Office- Shiri Hybloom', 100),
('Doron Peretz', 'Capital Link Family Office- Shiri Hybloom', 100),
('Yoram Baumann', 'Capital Link Family Office- Shiri Hybloom', 50),
('Maragret Frank', 'Isaac Fattal', 150),
('Benny Silverman', 'Stark Yoel Kadish, Lawyer (Accountant)- Yoel Stark', 50),
('Matthew Rosenbluth Rosenbluth Trust', 'Brian Horner', 100),
('Mickey Amir Hanegbee Kaplinsky', 'SRI Global Group- Daphna', 150),
('Eliezer Abramov', 'SRI Global Group- Daphna', 150),
('Yuval Shacham', 'SRI Global Group- Daphna', 150),
('Frank Cortese', 'Gabriel Taub', 150),
('Brenden Selway', 'Gabriel Taub', 150),
('Octavian Patrascu (Netcore Investments Limited)', 'Amit Zeevi', 150),
('Idan Grossman - Mangro Pty Ltd as Trustee for Mind Plus Trust', 'Amit Zeevi', 150),
('Idan Kornfeld', 'Amit Zeevi', 150),
('Ofir Rozenfeld', 'Roy Gold', 150),
('Shlomit Rosenfeld', 'Roy Gold', 150),
('Aharon Rasouli', 'Roy Gold', 150),
('Miri Rozenfeld', 'Roy Gold', 150),
('Nomi A. Holdings Ltd', 'Tzafit Pension Insurance Agency (2023) Ltd', 150),
('Gene Dattel', 'Andrew Tanzer [company:  TanzerVest LLC]', 100),
('Licia Hahn', 'Andrew Tanzer [company:  TanzerVest LLC]', 100),
('Peter Bermont', 'Andrew Tanzer [company:  TanzerVest LLC]', 100),
('John Pomfret', 'Andrew Tanzer [company:  TanzerVest LLC]', 100),
('Stephen Tanzer', 'Andrew Tanzer [company:  TanzerVest LLC]', 100),
('Tim Ferguson', 'Andrew Tanzer [company:  TanzerVest LLC]', 100),
('Eilon Sharon', 'Uri Golani', 200),
('Alon Ascher', 'Uri Golani', 200),
('Julien Barbier', 'Uri Golani', 200),
('Ling and Wang Song', 'Uri Golani', 200),
('Yee Jiun Song', 'Uri Golani', 200),
('Louis Blumberg [The AFB Fund LLC]', 'Mordechai Kubany company:  Double Kappa, LLC', 400);

-- ============================================================================
-- DIAGNOSTIC: Show Missing Investors
-- ============================================================================

SELECT
    '=== MISSING INVESTORS (47) ===' as section,
    m.investor_name,
    m.party_name,
    m.equity_bps
FROM tmp_fix_mappings m
LEFT JOIN investors i ON i.name = m.investor_name
WHERE i.id IS NULL
ORDER BY m.party_name, m.investor_name;

-- ============================================================================
-- DIAGNOSTIC: Show Missing Parties
-- ============================================================================

SELECT DISTINCT
    '=== MISSING PARTIES (7) ===' as section,
    m.party_name
FROM tmp_fix_mappings m
LEFT JOIN parties p ON p.name = m.party_name
WHERE p.id IS NULL
ORDER BY m.party_name;

-- ============================================================================
-- DIAGNOSTIC: Show introduced_by Mismatches (54)
-- ============================================================================

SELECT
    '=== INTRODUCED_BY MISMATCHES ===' as section,
    m.investor_name,
    m.party_name as expected_party,
    p_actual.name as actual_party,
    i.id as investor_id,
    p_expected.id as expected_party_id,
    i.introduced_by as actual_party_id
FROM tmp_fix_mappings m
INNER JOIN investors i ON i.name = m.investor_name
INNER JOIN parties p_expected ON p_expected.name = m.party_name
LEFT JOIN parties p_actual ON p_actual.id = i.introduced_by
WHERE i.introduced_by != p_expected.id OR i.introduced_by IS NULL
ORDER BY m.party_name, m.investor_name;

-- ============================================================================
-- FIX STEP 1: Create Missing Parties
-- ============================================================================

INSERT INTO parties (name, created_at, updated_at)
SELECT DISTINCT
    m.party_name,
    NOW(),
    NOW()
FROM tmp_fix_mappings m
LEFT JOIN parties p ON p.name = m.party_name
WHERE p.id IS NULL
ON CONFLICT (name) DO NOTHING;

-- ============================================================================
-- FIX STEP 2: Create Missing Investors
-- ============================================================================

INSERT INTO investors (name, introduced_by, created_at, updated_at)
SELECT
    m.investor_name,
    p.id,
    NOW(),
    NOW()
FROM tmp_fix_mappings m
LEFT JOIN investors i ON i.name = m.investor_name
INNER JOIN parties p ON p.name = m.party_name
WHERE i.id IS NULL
ON CONFLICT (name) DO NOTHING;

-- ============================================================================
-- FIX STEP 3: Fix introduced_by Relationships
-- ============================================================================

UPDATE investors i
SET introduced_by = p_expected.id,
    updated_at = NOW()
FROM tmp_fix_mappings m
INNER JOIN parties p_expected ON p_expected.name = m.party_name
WHERE i.name = m.investor_name
  AND (i.introduced_by != p_expected.id OR i.introduced_by IS NULL);

-- ============================================================================
-- VERIFICATION: Check All Mappings Now Match
-- ============================================================================

SELECT
    '=== FINAL VERIFICATION ===' as section,
    COUNT(*) as total_mappings,
    SUM(CASE WHEN i.id IS NOT NULL AND p.id IS NOT NULL AND i.introduced_by = p.id THEN 1 ELSE 0 END) as ready_for_agreements,
    SUM(CASE WHEN i.id IS NULL THEN 1 ELSE 0 END) as still_missing_investor,
    SUM(CASE WHEN p.id IS NULL THEN 1 ELSE 0 END) as still_missing_party,
    SUM(CASE WHEN i.id IS NOT NULL AND p.id IS NOT NULL AND i.introduced_by != p.id THEN 1 ELSE 0 END) as still_wrong_relationship
FROM tmp_fix_mappings m
LEFT JOIN investors i ON i.name = m.investor_name
LEFT JOIN parties p ON p.name = m.party_name;

-- Expected result: ready_for_agreements = 110, all others = 0
