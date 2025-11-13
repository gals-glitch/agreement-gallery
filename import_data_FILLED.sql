-- ============================================================================
-- COMMISSION DATA IMPORT SCRIPT - FILLED WITH YOUR DATA
-- ============================================================================
-- IMPORTANT NOTES:
-- 1. All agreements are set to deal_id=1 (Test Deal Alpha) as placeholder
--    UPDATE THESE after import to point to correct deals!
-- 2. VAT rate is 0.17 (17%) for all agreements
-- 3. Some party names were filtered out (invalid entries like email addresses)
-- 4. All agreements effective from 2022-05-24
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

-- Insert party data from CSV
INSERT INTO temp_parties VALUES
('Kuperman', 'tsahi@kupermanbros.com', '972-3-575-2017', 'Contact: Tsahi Weiss. Upfront - Invoice to Partners'),
('Shai Sheffer', 'udi@shaisheffer.com', '972-54-397-5960', 'Contact: Udi Sheffer. Promote - Invoice to Partners'),
('Yoram Dvash', 'yoram@ydvash.com', '972-54-397-5960', 'Contact: Yoram Dvash. Promote - Invoice to Ltd'),
('Yoni Frieder', 'yoram@ydvash.com', '972-54-397-5960', 'Contact: Yoram Dvash. '),
('Cross Arch Holdings -David Kirchenbaum', 'Dek7200@gmail.com', '972-52-464-1977', 'Contact: David Kirschenbaum. Upfront - Invoice'),
('Ronnie Maliniak', 'ronnymaliniak@gmail.com', '972-52-366-0366', 'Contact: Ronnie Maliniak. Upfront - Invoice to Ltd'),
('Ilanit Tirosh', 'ilaniti2000@gmail.com', '972-52-843-4959', 'Contact: Ilanit Tirosh. Upfront - Invoice to Ltd'),
('Tal Simchony', 'Tal.Simchony@gmail.com', '972-54-622-5433', 'Contact: Tal Simchony. Upfront - '),
('Yoram Shalit', 'Yoramsc@gmail.com', '972-52-674-4734', 'Contact: Yoram Shalit. Upfront - חשבונית עצמית'),
('GW CPA', 'gw@netvision.net.il', '972-52-674-4734', 'Contact: Dudu Winkelstein. Upfront - Invoice to Ltd'),
('Guy Moses', 'Guy@GuyMoses.com', '972-50-888-0022', 'Contact: Guy Moses. Upfront - Invoice to Ltd'),
('Sheara Einhorn', 'shearaeinhorn@gmail.com', '972-50-888-0022', 'Contact: Sheara Einhorn. Upfront - Invoice to Ltd'),
('Lior Stinus from Freidkes & Co. CPA', 'lior@frcpa.co.il', '972-3-624-2977', 'Contact: Lior Stinus. Upfront - Invoice to Ltd'),
('Avi Fried', 'avraam_fried@yahoo.com', '972-3-624-2977', 'Contact: Avi Fried. Upfront - Invoice to Ltd'),
('Formula Ventures Ltd- Shai Beilis', 'shai@formulaventures.com', '972-3-624-2977', 'Contact: Shai Beilis. Upfront - Invoice to Ltd'),
('Ilan Kapelner Management Services ltd- Ilan Kapelner', 'ilan.kapelner@focus-inv.co.il', '972-3-624-2977', 'Contact: Ilan Kapelner. Upfront - Invoice to Ltd'),
('Shlomo Waldmann', 'ilan.kapelner@focus-inv.co.il', '972-3-624-2977', 'Contact: Ilan Kapelner. '),
('Rubin Schlussel', 'Rubin@l-s.co.il', '972-8-932-4400', 'Contact: Rubin Schlussel. Upfront - Invoice to Ltd'),
('HNA Investments Limited Liability- Ilan Grinberg and Jacob Asia (together)', 'ilan@Cpaweb.co.il', '972-54-424-0086', 'Contact: Ilan Grinberg. Upfront - Invoice to Ltd'),
('Yoram Avi-Guy Lawyer- Yoram Avi Guy', 'aviguyy4@gmail.com', '972-54-234-6075', 'Contact: Yoram Avi-Guy. Upfront - Invoice to Ltd'),
('HS Invest Pension Insurance Agency (2016) ltd- Hezi Schwartz', 'hezi@hsinvest.co.il', '972-54-800-8116', 'Contact: Hezi Schwartz. Upfront - Invoice to Ltd'),
('David Reichman', 'davidreichman@gmail.com', '972-54-800-8116', 'Contact: David Reichman. Upfront - 1099 from NA'),
('Agamim Commercial Real Estate- Moti Agam', 'moti@agamim-nadlan.co.il', '972-54-397-3484', 'Contact: Moti Agam. Upfront - Invoice Ltd'),
('Natai Investments- Alon Even Chen', 'alon.evenchen@gmail.com', '972-54-663-2590', 'Contact: Alon Even Chen. Upfront - Invoice Ltd'),
('Wiser Finance- Michael Mann', 'michael@wiser.co.il', '972-54496-5999', 'Contact: Michael Mann. Upfront - Invoice to Ltd'),
('Pioneer Wealth Management- Liat F', 'inbarm@piowealth.com', '972-9-961-1355', 'Contact: Inbar Mor. Upfront - Invoice to Ltd'),
('Tal Even', 'taleven@gmail.com', '972-50-885-9427', 'Contact: Tal Even. Upfront - Invoice to Ltd'),
('Eyal Hrring- Financial Planning and Strategy- Eyal Herring', 'eyal@herring-inv.com', '972-50-885-9427', 'Contact: Eyal Herring. Upfront - Invoice to Ltd'),
('Yariv Avrahami', 'yarivav@017.net.il', '972-50-536-0073', 'Contact: Yariv Avrahami. Upfront - Invoice to Ltd'),
('ThinkWise Consulting LLC- Lior Cohen', 'sliorco@gmail.com', '646-584-7748', 'Contact: Lior Cohen. Upfront - Invoice to NA'),
('Gilad Slonim Insurance Agency Ltd- Gilad Slonim', 'gilad@balance-fp.co.il', '972-50-905-9905', 'Contact: Gilad Slonim. Upfront - Invoice to Ltd'),
('Iprofit Ltd- Yifat Igler', 'yifat@trust-wm.com', '972-50-905-9905', 'Contact: Yifat Igler. Upfront - Invoice to Ltd'),
('Saar Gavish', 'yifat@trust-wm.com', '972-50-905-9905', 'Contact: Don''t set him up as a company in Vantage. '),
('YL Consulting Inc- Yoav Lachover', 'ylconsultinginc@gmail.com', '972-50-905-9905', 'Contact: Yoav Lachover. Upfront - Invoice to NA'),
('Yair Almagor', 'ylconsultinginc@gmail.com', '972-50-905-9905', 'Contact: Yoav Lachover. Still waiting to pay him'),
('Dror Zetouni', 'dzetouni@gmail.com', '972-50-905-9905', 'Contact: Dror Zetouni. Upfront - 1099 from NA'),
('Darius Marshahzadeh', 'dzetouni@gmail.com', '972-50-905-9905', 'Contact: Don''t set him up as a company in Vantage. '),
('Lighthouse F.S Ltd- Avihay', ' Nitza@lighthouse-fs.com', '972-3-566-1333', 'Contact: Nitza Deitsch. Upfront - Invoice to Ltd'),
('Sparta Capital- Yonel Dvash', 'Yonel@Sparta-Capital.co.il', '972-54-497-4437 ', 'Contact: Yonel Dvash. Upfront - Invoice to Ltd'),
('Shirley Feit', 'Yonel@Sparta-Capital.co.il', '972-54-497-4437 ', 'Contact: Yonel Dvash. '),
('Gil Haramati', 'diaserv@gmail.com', '213-820-1622', 'Contact: Gil Haramati. Upfront - 1099 from NA'),
('Beny Shafir', 'shafir@yanaigroup.com ', '972-52-358-0005', 'Contact: Beny Shafir . Upfront - Invoice to Ltd'),
('Atiela Investments Ltd- Yoav Holzer', 'yoav@facilfam.com ', '972-50-846-0267', 'Contact: Yoav Holzer. Upfront - Invoice to Ltd'),
('Capital Link Family Office- Shiri Hybloom', 'shiri@clink-fo.com', '972-54-8335753', 'Contact: Shrir Hybloom. Upfront - Invoice to Ltd'),
('Isaac Fattal', 'isaac.fattal@ad-notam.com', '972-54-8335753', 'Contact: Isaac Fattal. Upfront - 1099 from NA'),
('Amir Dinur', 'isaac.fattal@ad-notam.com', '972-54-8335753', 'Contact: Don''t set him up as a company in Vantage. '),
('Stark Yoel Kadish, Lawyer (Accountant)- Yoel Stark', 'yoel@starkcpa.com', '972-54-8335753', 'Contact: Yoel Stark. Upfront - Invoice to Ltd'),
('Brian Horner', 'brianh@techcoastangels.la', '972-54-8335753', 'Contact: Yoel Stark. '),
('SRI Global Group- Daphna', 'daphna@wd-rei.com', '972-54-8335753', 'Contact: Daphna. '),
('Gabriel Taub', 'gabitaub@gmail.com', '510-837-1948', 'Contact: Gabi. Upfront - From NA. Either 1099 or invoice'),
('Amit Zeevi', 'gabitaub@gmail.com', '510-837-1948', 'Contact: Gabi. '),
('Roy Gold', 'gabitaub@gmail.com', '510-837-1948', 'Contact: Gabi. '),
('Tzafit Pension Insurance Agency (2023) Ltd', 'gabitaub@gmail.com', '510-837-1948', 'Contact: Aviv Kordova. '),
('Tom Arbitrage Investment Ltd', 'gabitaub@gmail.com', '510-837-1948', 'Contact: Aviv Kordova. '),
('Buligo Fund V GP LLC', 'gabitaub@gmail.com', '510-837-1948', 'Contact: Aviv Kordova. '),
('Andrew Tanzer', 'gabitaub@gmail.com', '510-837-1948', 'Contact: Aviv Kordova. '),
('TanzerVest LLC', 'gabitaub@gmail.com', '510-837-1948', 'Contact: Aviv Kordova. '),
('Uri Golani', 'gabitaub@gmail.com', '510-837-1948', 'Contact: Aviv Kordova. '),
('Yoav Zilber', 'gabitaub@gmail.com', '510-837-1948', 'Contact: Aviv Kordova. '),
('Mordechai Kubany', 'gabitaub@gmail.com', '510-837-1948', 'Contact: Aviv Kordova. Invoice'),
('Double Kappa, LLC', 'gabitaub@gmail.com', '510-837-1948', 'Contact: Aviv Kordova. '),
('Meirav Dvash', 'gabitaub@gmail.com', '510-837-1948', 'Contact: Aviv Kordova. '),
('Investor Not in Vantage', 'gabitaub@gmail.com', '510-837-1948', 'Contact: Aviv Kordova. '),
('Is a Contact but no Investors Associated', 'gabitaub@gmail.com', '510-837-1948', 'Contact: Aviv Kordova. ');

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

-- Note: This is a large INSERT - broken into smaller chunks for readability
-- Chunk 1: Rows 1-50
INSERT INTO temp_investors VALUES
('Kuperman Entity', 'Kuperman', '', '', '3% on Upfront. 20% on promote'),
('Peter Gyenes', 'Cross Arch Holdings -David Kirchenbaum', '', '', '25% on Upfront. 20% on promote'),
('Eran Farajun', 'Guy Moses', '', '', '25% on Upfront. 20% on promote'),
('Meir Farajun', 'Guy Moses', '', '', '25% on Upfront. 20% on promote'),
('Levy Family Trust', 'Sheara Einhorn', '', '', '15% on Upfront. 20% on promote'),
('Assaf Buchnik', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Nadler Investments', 'Formula Ventures Ltd- Shai Beilis', '', '', '15% on Upfront. 20% on promote'),
('Yonatan Kaploun', 'Ilan Kapelner Management Services ltd- Ilan Kapelner', '', '', '1% on Upfront. 20% on promote'),
('Yanir Rahat', 'Ilan Kapelner Management Services ltd- Ilan Kapelner', '', '', '1% on Upfront. 20% on promote'),
('Shlomo Waldmann', 'Shlomo Waldmann', '', '', '1% on Upfront. 20% on promote'),
('Schussel Family Trust', 'Rubin Schlussel', '', '', '0.75% on Upfront. 20% on promote'),
('Tal Michael 8 ltd', 'HNA Investments Limited Liability- Ilan Grinberg and Jacob Asia (together)', '', '', '0.5% on Upfront. 20% on promote'),
('Shelly Rau', 'Yoram Avi-Guy Lawyer- Yoram Avi Guy', '', '', '1% on Upfront. 20% on promote'),
('Assaf Gefen', 'HS Invest Pension Insurance Agency (2016) ltd- Hezi Schwartz', '', '', '1.5% on Upfront. 20% on promote'),
('Avrumi Gross', 'David Reichman', '', '', '1% on Upfront. 20% on promote'),
('Israel Baratz', 'Agamim Commercial Real Estate- Moti Agam', '', '', '0.5% on Upfront. 20% on promote'),
('Amit Shaked', 'Natai Investments- Alon Even Chen', '', '', '0.75% on Upfront. 20% on promote'),
('MDCA Pension Agency of Ronen M', 'Wiser Finance- Michael Mann', '', '', '1% on Upfront. 20% on promote'),
('Nir Barnea', 'Pioneer Wealth Management- Liat F', '', '', '0.75% on Upfront. 20% on promote'),
('Barak Fridman', 'Tal Even', '', '', '5% on Upfront. 20% on promote'),
('Yoav Gad', 'Eyal Hrring- Financial Planning and Strategy- Eyal Herring', '', '', '0.5% on Upfront. 20% on promote'),
('Ofer Kaufman', 'Yariv Avrahami', '', '', '1% on Upfront. 20% on promote'),
('Gil Tzur', 'ThinkWise Consulting LLC- Lior Cohen', '', '', '5% on Upfront. 20% on promote'),
('Meirav Rom', 'Gilad Slonim Insurance Agency Ltd- Gilad Slonim', '', '', '5% on Upfront. 20% on promote'),
('Orit Igler', 'Iprofit Ltd- Yifat Igler', '', '', '1% on Upfront. 20% on promote'),
('Avshalom Gabay', 'Saar Gavish', '', '', '1% on Upfront. 20% on promote'),
('Guy and Miki Neeman', 'YL Consulting Inc- Yoav Lachover', '', '', '1% on Upfront. 20% on promote'),
('Meital Cohen Halevi', 'Yair Almagor', '', '', '1% on Upfront. 20% on promote'),
('Chen and Maayan Barnea', 'Dror Zetouni', '', '', '1% on Upfront. 20% on promote'),
('Ido Wiesner', 'Dror Zetouni', '', '', '1% on Upfront. 20% on promote'),
('Liad Dekel', 'Dror Zetouni', '', '', '1% on Upfront. 20% on promote'),
('Neomi & Gilad Sela', 'Dror Zetouni', '', '', '1% on Upfront. 20% on promote'),
('Roy Markowicz', 'Dror Zetouni', '', '', '0.5% on Upfront. 20% on promote'),
('Dvir Shpigel', 'Lighthouse F.S Ltd- Avihay', '', '', '1% on Upfront. 20% on promote'),
('Noam Davidovich', 'Sparta Capital- Yonel Dvash', '', '', '1% on Upfront. 20% on promote'),
('Shirley Feit', 'Shirley Feit', '', '', '1% on Upfront. 20% on promote'),
('Eldar Orenstein', 'Gil Haramati', '', '', '1% on Upfront. 20% on promote'),
('Yair Tal', 'Gil Haramati', '', '', '0.5% on Upfront. 20% on promote'),
('Daniel Weinstock', 'Beny Shafir', '', '', '1.5% on Upfront. 20% on promote'),
('Daniel Brosh', 'Beny Shafir', '', '', '0.5% on Upfront. 20% on promote'),
('Yoav Holzer', 'Atiela Investments Ltd- Yoav Holzer', '', '', '0.5% on Upfront. 20% on promote'),
('Ronit Aharon', 'Capital Link Family Office- Shiri Hybloom', '', '', '1% on Upfront. 20% on promote'),
('Amir Naor', 'Isaac Fattal', '', '', '1.5% on Upfront. 20% on promote'),
('Shai Naor', 'Isaac Fattal', '', '', '1.5% on Upfront. 20% on promote'),
('Kobi Petel', 'Amir Dinur', '', '', '1.5% on Upfront. 20% on promote'),
('Oz Investment Management llc', 'Stark Yoel Kadish, Lawyer (Accountant)- Yoel Stark', '', '', '0.5% on Upfront. 20% on promote'),
('The Agmon & Shapiro Family Trust- G Shapiro', 'Brian Horner', '', '', '1% on Upfront. 20% on promote'),
('Daphna and David Weiner', 'SRI Global Group- Daphna', '', '', '1.5% on Upfront. 20% on promote'),
('Steve Weiner', 'Gabriel Taub', '', '', '1.5% on Upfront. 20% on promote'),
('Amit Zeevi', 'Amit Zeevi', '', '', '1.5% on Upfront. 20% on promote');

-- Chunk 2: Rows 51-100
INSERT INTO temp_investors VALUES
('Yossi Amitay', 'Roy Gold', '', '', '1.5% on Upfront. 20% on promote'),
('Ronen Moshe', 'Tzafit Pension Insurance Agency (2023) Ltd', '', '', '1.5% on Upfront. 20% on promote'),
('Arbitrage Investments', 'Tom Arbitrage Investment Ltd', '', '', ''),
('Dan Frankel (Company: Elray Ressources LLC)', 'Buligo Fund V GP LLC', '', '', ''),
('Jonathan Kolber (company: Rosen Ventures LLC)', 'Buligo Fund V GP LLC', '', '', ''),
('Yaron Valler', 'Buligo Fund V GP LLC', '', '', ''),
('David Yacov', 'Buligo Fund V GP LLC', '', '', ''),
('Shlomi Shayovich', 'Buligo Fund V GP LLC', '', '', ''),
('Shlomo Weiser', 'Buligo Fund V GP LLC', '', '', ''),
('Jonathan Fox', 'Buligo Fund V GP LLC', '', '', ''),
('Eitan Marcus (company: Marcus Partners family trust)', 'Buligo Fund V GP LLC', '', '', ''),
('Yakir Elharrar (Company: Elakim Investments Ltd)', 'Buligo Fund V GP LLC', '', '', ''),
('Meyer Dabah', 'Buligo Fund V GP LLC', '', '', ''),
('Alan Swartz', 'Andrew Tanzer', '', '', '1% on Upfront. 20% on promote'),
('Yoni Iger', 'Andrew Tanzer', '', '', '1% on Upfront. 20% on promote'),
('Elan Dov Ben-Ami', 'TanzerVest LLC', '', '', ''),
('Yair Goldfinger', 'Uri Golani', '', '', '2% on Upfront. 20% on promote'),
('Eldad Tamir', 'Yoav Zilber', '', '', ''),
('Adam Berlin', 'Mordechai Kubany', '', '', '4% on Upfront. 20% on promote'),
('Noam Goldman', 'Double Kappa, LLC', '', '', ''),
('Meir Taub', 'Investor Not in Vantage', '', '', ''),
('Elad Shemesh', 'Is a Contact but no Investors Associated', '', '', ''),
('Rakefet Kuperman', 'Kuperman', '', '', '1% on Upfront. 20% on promote'),
('Orly Kuperman', 'Kuperman', '', '', '1% on Upfront. 20% on promote'),
('Eran Kali', 'Shai Sheffer', '', '', '27% on Upfront. 20% on promote'),
('Shelly Sheffer', 'Shai Sheffer', '', '', '27% on Upfront. 20% on promote'),
('Itamar and Orly Gonen', 'Yoram Dvash', '', '', '27% on Upfront. 20% on promote'),
('Oren Simanian', 'Yoram Dvash', '', '', '27% on Upfront. 20% on promote'),
('Yoni Frieder', 'Yoni Frieder', '', '', '1% on Upfront. 20% on promote'),
('David Kirchenbaum- Cross Arch Holdings LLC', 'Cross Arch Holdings -David Kirchenbaum', '', '', '25% on Upfront. 20% on promote'),
('Liad Rubin', 'Ronnie Maliniak', '', '', '25% on Upfront. 20% on promote'),
('Yaniv Rubin', 'Ronnie Maliniak', '', '', '25% on Upfront. 20% on promote'),
('Ilanit Tirosh', 'Ilanit Tirosh', '', '', '25% on Upfront. 20% on promote'),
('Matan Simchony', 'Tal Simchony', '', '', '15% on Upfront. 20% on promote'),
('Yoram Shalit', 'Yoram Shalit', '', '', '25% on Upfront. 20% on promote'),
('Winkelstein Family Trust', 'GW CPA', '', '', '15% on Upfront. 20% on promote'),
('Levy Kids Fund 2022', 'Guy Moses', '', '', '25% on Upfront. 20% on promote'),
('Guy Moses Trust', 'Guy Moses', '', '', '25% on Upfront. 20% on promote'),
('Lior Stinus', 'Lior Stinus from Freidkes & Co. CPA', '', '', '15% on Upfront. 20% on promote'),
('Shai Beilis', 'Formula Ventures Ltd- Shai Beilis', '', '', '15% on Upfront. 20% on promote'),
('Tsabary Trust', 'Ilan Kapelner Management Services ltd- Ilan Kapelner', '', '', '1% on Upfront. 20% on promote'),
('Tal M 8 Ltd', 'HNA Investments Limited Liability- Ilan Grinberg and Jacob Asia (together)', '', '', '0.5% on Upfront. 20% on promote'),
('Shiloh Berkovitz', 'Yoram Avi-Guy Lawyer- Yoram Avi Guy', '', '', '1% on Upfront. 20% on promote'),
('Nir Barnea 2', 'Pioneer Wealth Management- Liat F', '', '', '0.75% on Upfront. 20% on promote'),
('Elad Weissman', 'Tal Even', '', '', '5% on Upfront. 20% on promote'),
('Lior Cohen', 'ThinkWise Consulting LLC- Lior Cohen', '', '', '5% on Upfront. 20% on promote'),
('Tomer Hasson', 'Gilad Slonim Insurance Agency Ltd- Gilad Slonim', '', '', '5% on Upfront. 20% on promote'),
('Matan Naor', 'Saar Gavish', '', '', '1% on Upfront. 20% on promote'),
('Eran Nachmani', 'Yair Almagor', '', '', '1% on Upfront. 20% on promote');

-- Chunk 3: Rows 101-150
INSERT INTO temp_investors VALUES
('Danny Rittenberg', 'Dror Zetouni', '', '', '1% on Upfront. 20% on promote'),
('Lital Dotan', 'Dror Zetouni', '', '', '1% on Upfront. 20% on promote'),
('Daria Nitzani', 'Dror Zetouni', '', '', '0.5% on Upfront. 20% on promote'),
('Guy Yohananov', 'Darius Marshahzadeh', '', '', '1.5% on Upfront. 20% on promote'),
('Roi Weitzman', 'Lighthouse F.S Ltd- Avihay', '', '', '1% on Upfront. 20% on promote'),
('Ido Gelbard', 'Sparta Capital- Yonel Dvash', '', '', '1% on Upfront. 20% on promote'),
('Eldar Orenstein 2', 'Gil Haramati', '', '', '1.5% on Upfront. 20% on promote'),
('Joshua Hecht', 'Gil Haramati', '', '', '1.5% on Upfront. 20% on promote'),
('Scott Fischer', 'Gabriel Taub', '', '', '1.5% on Upfront. 20% on promote'),
('Assaf Frankel', 'Andrew Tanzer', '', '', '1% on Upfront. 20% on promote'),
('Yair Ravid', 'Uri Golani', '', '', '2% on Upfront. 20% on promote'),
('Shai Sheffer', 'Shai Sheffer', '', '', '27% on Upfront. 20% on promote'),
('Shai Kimchi', 'Yoram Dvash', '', '', '27% on Upfront. 20% on promote'),
('Ronnie Maliniak', 'Ronnie Maliniak', '', '', '25% on Upfront. 20% on promote'),
('Guy Moses', 'Guy Moses', '', '', '25% on Upfront. 20% on promote'),
('Nofar Biran', 'Lior Stinus from Freidkes & Co. CPA', '', '', '15% on Upfront. 20% on promote'),
('Naama Kapelner', 'Ilan Kapelner Management Services ltd- Ilan Kapelner', '', '', '1% on Upfront. 20% on promote'),
('Ilan Kapelner', 'Ilan Kapelner Management Services ltd- Ilan Kapelner', '', '', '1% on Upfront. 20% on promote'),
('Rubin Schlussel', 'Rubin Schlussel', '', '', '0.75% on Upfront. 20% on promote'),
('Yoav Tzruya', 'HNA Investments Limited Liability- Ilan Grinberg and Jacob Asia (together)', '', '', '0.5% on Upfront. 20% on promote'),
('Hezi Schwartz', 'HS Invest Pension Insurance Agency (2016) ltd- Hezi Schwartz', '', '', '1.5% on Upfront. 20% on promote'),
('Yuval Saar', 'Agamim Commercial Real Estate- Moti Agam', '', '', '0.5% on Upfront. 20% on promote'),
('Ron Shafrir', 'Natai Investments- Alon Even Chen', '', '', '0.75% on Upfront. 20% on promote'),
('Yogev Nehoray', 'Wiser Finance- Michael Mann', '', '', '1% on Upfront. 20% on promote'),
('Amital and Karin Barnea', 'Pioneer Wealth Management- Liat F', '', '', '0.75% on Upfront. 20% on promote'),
('Tal Even', 'Tal Even', '', '', '5% on Upfront. 20% on promote'),
('Eyal Herring', 'Eyal Hrring- Financial Planning and Strategy- Eyal Herring', '', '', '0.5% on Upfront. 20% on promote'),
('Yariv Avrahami', 'Yariv Avrahami', '', '', '1% on Upfront. 20% on promote'),
('Noa and Nimrod Rosenbaum', 'ThinkWise Consulting LLC- Lior Cohen', '', '', '5% on Upfront. 20% on promote'),
('Giora Eiland', 'Gilad Slonim Insurance Agency Ltd- Gilad Slonim', '', '', '5% on Upfront. 20% on promote'),
('Elad Mizrahi', 'Iprofit Ltd- Yifat Igler', '', '', '1% on Upfront. 20% on promote'),
('Amir Tzipori', 'Saar Gavish', '', '', '1% on Upfront. 20% on promote'),
('Yoav Lachover', 'YL Consulting Inc- Yoav Lachover', '', '', '1% on Upfront. 20% on promote'),
('Gil Schreibman', 'Yair Almagor', '', '', '1% on Upfront. 20% on promote'),
('Ido Ram', 'Dror Zetouni', '', '', '1% on Upfront. 20% on promote'),
('Irad Rahat', 'Dror Zetouni', '', '', '0.5% on Upfront. 20% on promote'),
('Dror Zetouni', 'Dror Zetouni', '', '', '1.5% on Upfront. 20% on promote'),
('Yonel Dvash', 'Sparta Capital- Yonel Dvash', '', '', '1% on Upfront. 20% on promote'),
('Ben Cohen', 'Gil Haramati', '', '', '1.5% on Upfront. 20% on promote'),
('Benni Shafir', 'Beny Shafir', '', '', '1.5% on Upfront. 20% on promote'),
('Shiri Hybloom', 'Capital Link Family Office- Shiri Hybloom', '', '', '1% on Upfront. 20% on promote'),
('Yoel Stark', 'Stark Yoel Kadish, Lawyer (Accountant)- Yoel Stark', '', '', '0.5% on Upfront. 20% on promote'),
('Gabriel Taub', 'Gabriel Taub', '', '', '1.5% on Upfront. 20% on promote'),
('Inbal Ziv', 'Andrew Tanzer', '', '', '1% on Upfront. 20% on promote'),
('Renana Ashkenazi', 'Uri Golani', '', '', '2% on Upfront. 20% on promote'),
('Yoav Zilber', 'Yoav Zilber', '', '', ''),
('Mordechai Kubany', 'Mordechai Kubany', '', '', '4% on Upfront. 20% on promote'),
('Meirav Dvash', 'Meirav Dvash', '', '', ''),
('Arnon Levy', 'Sheara Einhorn', '', '', '15% on Upfront. 20% on promote'),
('Yuval Benado', 'Sheara Einhorn', '', '', '15% on Upfront. 20% on promote');

-- Chunk 4: Rows 151-200
INSERT INTO temp_investors VALUES
('Noy Capital', 'Sheara Einhorn', '', '', '15% on Upfront. 20% on promote'),
('Yair Livneh', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Yasmin Lukatch', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Robert Asherian', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Tahal Shikma', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Dorin Litvak', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Einat and Omer Inbar', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Avshalom and Ronit Bloch', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Eynat and Alon Kuperman', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Omer Peer and Hadas Cohen', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Maor Dahan', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Poria Livne', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Guy Attar', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Liran Zimbler', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Ron Almog', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Ronen Portnoy', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Reshef Cohen', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Lior Netzer', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Doron Kamhi', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Yuval Fishler', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Shay Peer', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Yuval Arad', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Nir Bachar', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Guy Nahari', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Dima Melamed Zilberstein', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Guy Shimrat', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Adiel Aharoni', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Dror Schiff', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Hananel Rosh', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Ron Gold', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Assaf Tsachor', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Dalit Israel', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Ohad Weiss', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Osher Weissbuch', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Ami Danielli', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Boas Reshef', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Rotem Golan', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Ido Rosenbaum', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Dov Moran', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Amit Finkelstein', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Elad Brudmann', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Yona Golani', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Uri Chen', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Amit Duvdevani', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Oren Gershtein', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Or Sadeh', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Itay Paz', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Tzvi Zack', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Nir Porat', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('David Gabai', 'Avi Fried', '', '', '15% on Upfront. 20% on promote');

-- Chunk 5: Rows 201-250
INSERT INTO temp_investors VALUES
('Ran Shaul', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Tal Shlosberg', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Adi Sofer Teeni', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Itai Damti', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Hani Zayden', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Erez Shachar', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Lior Litwak', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Dudi Vizel', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Eran Arviv', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Nir Erez', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Oded Maimon', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Idan Edri', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Arik Maimon', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Avi Fried', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Zohar Gilon', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Adi Talmor', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Opher Mash', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Ron Amir', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Shay Rishoni', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Alon Webman', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Gilad Shacham', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Dolev Matok', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Ofer Schreiber', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Dor Lavi', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Alex Dizengof', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Ziv Tirosh', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Yael Shiff', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Alon Rubin', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Itay Sagie', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Tal Barnoach', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Niv Schwartz', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Edo Segal', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Eliram Goldenberg', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Uri Lapidot', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Ron Aharoni', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Chen Amit', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Nir Kouris', 'Avi Fried', '', '', '15% on Upfront. 20% on promote'),
('Oren Simanian', 'Yoram Dvash', '', '', '27% on Upfront. 20% on promote'),
('Maayan Zilberman', 'Ilanit Tirosh', '', '', '25% on Upfront. 20% on promote'),
('Osher Levi', 'Tal Simchony', '', '', '15% on Upfront. 20% on promote'),
('Ronit Sror', 'Tal Simchony', '', '', '15% on Upfront. 20% on promote'),
('Or Lemel', 'Tal Simchony', '', '', '15% on Upfront. 20% on promote'),
('Idan Shoef', 'Tal Simchony', '', '', '15% on Upfront. 20% on promote'),
('Elad Amsalem', 'GW CPA', '', '', '15% on Upfront. 20% on promote'),
('Harel Shapira', 'GW CPA', '', '', '15% on Upfront. 20% on promote'),
('Nofar Hasson', 'GW CPA', '', '', '15% on Upfront. 20% on promote'),
('Michal Blau', 'GW CPA', '', '', '15% on Upfront. 20% on promote'),
('Yaniv Tzafrir', 'GW CPA', '', '', '15% on Upfront. 20% on promote'),
('Lior Dekel', 'Lior Stinus from Freidkes & Co. CPA', '', '', '15% on Upfront. 20% on promote'),
('Ester Alony', 'Lior Stinus from Freidkes & Co. CPA', '', '', '15% on Upfront. 20% on promote');

-- Chunk 6: Rows 251-265
INSERT INTO temp_investors VALUES
('Yael Eckstein', 'Lior Stinus from Freidkes & Co. CPA', '', '', '15% on Upfront. 20% on promote'),
('Gal Mor', 'Lior Stinus from Freidkes & Co. CPA', '', '', '15% on Upfront. 20% on promote'),
('Ofir Azran', 'Lior Stinus from Freidkes & Co. CPA', '', '', '15% on Upfront. 20% on promote'),
('Ohad Dayan', 'Lior Stinus from Freidkes & Co. CPA', '', '', '15% on Upfront. 20% on promote'),
('Reuven Brickman', 'Lior Stinus from Freidkes & Co. CPA', '', '', '15% on Upfront. 20% on promote'),
('Aviran Mor', 'Lior Stinus from Freidkes & Co. CPA', '', '', '15% on Upfront. 20% on promote'),
('Almog Amir', 'Lior Stinus from Freidkes & Co. CPA', '', '', '15% on Upfront. 20% on promote'),
('Almog Aloni', 'Lior Stinus from Freidkes & Co. CPA', '', '', '15% on Upfront. 20% on promote'),
('Barak Anbinder', 'Lior Stinus from Freidkes & Co. CPA', '', '', '15% on Upfront. 20% on promote'),
('Avshalom Shwartz', 'Lior Stinus from Freidkes & Co. CPA', '', '', '15% on Upfront. 20% on promote'),
('Nimrod Shalev', 'Lior Stinus from Freidkes & Co. CPA', '', '', '15% on Upfront. 20% on promote'),
('Tomer Diari', 'Lior Stinus from Freidkes & Co. CPA', '', '', '15% on Upfront. 20% on promote'),
('Yair and Sharon Mevorach', 'Lior Stinus from Freidkes & Co. CPA', '', '', '15% on Upfront. 20% on promote'),
('Hen Weiss', 'Lior Stinus from Freidkes & Co. CPA', '', '', '15% on Upfront. 20% on promote'),
('Guy Ohayon', 'Lior Stinus from Freidkes & Co. CPA', '', '', '15% on Upfront. 20% on promote');

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
    scope_type TEXT,
    fund_id BIGINT,
    deal_id BIGINT,
    rate_bps INTEGER,
    vat_mode TEXT,
    vat_rate NUMERIC,
    effective_from DATE,
    effective_to DATE,
    status TEXT
);

-- ⚠️ IMPORTANT: Setting all agreements to deal_id=1 as placeholder
-- UPDATE THESE AFTER IMPORT to point to correct deals!
INSERT INTO temp_agreements VALUES
('Kuperman', 'DEAL', NULL, 1, 100, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Shai Sheffer', 'DEAL', NULL, 1, 2700, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Yoram Dvash', 'DEAL', NULL, 1, 2700, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Yoni Frieder', 'DEAL', NULL, 1, 100, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Cross Arch Holdings -David Kirchenbaum', 'DEAL', NULL, 1, 2500, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Ronnie Maliniak', 'DEAL', NULL, 1, 2500, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Ilanit Tirosh', 'DEAL', NULL, 1, 2500, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Tal Simchony', 'DEAL', NULL, 1, 1500, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Yoram Shalit', 'DEAL', NULL, 1, 2500, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('GW CPA', 'DEAL', NULL, 1, 1500, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Guy Moses', 'DEAL', NULL, 1, 2500, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Sheara Einhorn', 'DEAL', NULL, 1, 1500, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Lior Stinus from Freidkes & Co. CPA', 'DEAL', NULL, 1, 1500, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Avi Fried', 'DEAL', NULL, 1, 1500, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Formula Ventures Ltd- Shai Beilis', 'DEAL', NULL, 1, 1500, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Ilan Kapelner Management Services ltd- Ilan Kapelner', 'DEAL', NULL, 1, 100, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Shlomo Waldmann', 'DEAL', NULL, 1, 100, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Rubin Schlussel', 'DEAL', NULL, 1, 75, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('HNA Investments Limited Liability- Ilan Grinberg and Jacob Asia (together)', 'DEAL', NULL, 1, 50, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Yoram Avi-Guy Lawyer- Yoram Avi Guy', 'DEAL', NULL, 1, 100, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('HS Invest Pension Insurance Agency (2016) ltd- Hezi Schwartz', 'DEAL', NULL, 1, 150, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('David Reichman', 'DEAL', NULL, 1, 100, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Agamim Commercial Real Estate- Moti Agam', 'DEAL', NULL, 1, 50, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Natai Investments- Alon Even Chen', 'DEAL', NULL, 1, 7500, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Wiser Finance- Michael Mann', 'DEAL', NULL, 1, 100, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Pioneer Wealth Management- Liat F', 'DEAL', NULL, 1, 7500, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Tal Even', 'DEAL', NULL, 1, 500, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Eyal Hrring- Financial Planning and Strategy- Eyal Herring', 'DEAL', NULL, 1, 50, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Yariv Avrahami', 'DEAL', NULL, 1, 100, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('ThinkWise Consulting LLC- Lior Cohen', 'DEAL', NULL, 1, 500, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Gilad Slonim Insurance Agency Ltd- Gilad Slonim', 'DEAL', NULL, 1, 500, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Iprofit Ltd- Yifat Igler', 'DEAL', NULL, 1, 100, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Saar Gavish', 'DEAL', NULL, 1, 100, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('YL Consulting Inc- Yoav Lachover', 'DEAL', NULL, 1, 100, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Yair Almagor', 'DEAL', NULL, 1, 100, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Dror Zetouni', 'DEAL', NULL, 1, 150, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Darius Marshahzadeh', 'DEAL', NULL, 1, 150, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Lighthouse F.S Ltd- Avihay', 'DEAL', NULL, 1, 100, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Sparta Capital- Yonel Dvash', 'DEAL', NULL, 1, 100, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Shirley Feit', 'DEAL', NULL, 1, 100, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Gil Haramati', 'DEAL', NULL, 1, 150, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Beny Shafir', 'DEAL', NULL, 1, 150, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Atiela Investments Ltd- Yoav Holzer', 'DEAL', NULL, 1, 50, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Capital Link Family Office- Shiri Hybloom', 'DEAL', NULL, 1, 100, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Isaac Fattal', 'DEAL', NULL, 1, 150, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Amir Dinur', 'DEAL', NULL, 1, 150, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Stark Yoel Kadish, Lawyer (Accountant)- Yoel Stark', 'DEAL', NULL, 1, 50, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Brian Horner', 'DEAL', NULL, 1, 100, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('SRI Global Group- Daphna', 'DEAL', NULL, 1, 150, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Gabriel Taub', 'DEAL', NULL, 1, 150, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Amit Zeevi', 'DEAL', NULL, 1, 150, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Roy Gold', 'DEAL', NULL, 1, 150, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Tzafit Pension Insurance Agency (2023) Ltd', 'DEAL', NULL, 1, 150, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Andrew Tanzer', 'DEAL', NULL, 1, 100, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('TanzerVest LLC', 'DEAL', NULL, 1, 100, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Uri Golani', 'DEAL', NULL, 1, 200, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED'),
('Mordechai Kubany', 'DEAL', NULL, 1, 400, 'on_top', 0.17, '2022-05-24', NULL, 'APPROVED');

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
  AND i.name IN (SELECT investor_name FROM temp_investors)
LIMIT 10;

-- Check for duplicate party names
SELECT
    '=== Duplicate Party Names ===' as section,
    name,
    COUNT(*) as count
FROM parties
WHERE name IN (SELECT party_name FROM temp_parties)
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
WHERE a.kind = 'distributor_commission'
  AND a.created_at >= (NOW() - INTERVAL '1 hour');

-- Show rate distribution
SELECT
    '=== Agreement Rate Distribution ===' as section,
    (snapshot_json->'terms'->0->>'rate_bps')::INTEGER as rate_bps,
    COUNT(*) as count
FROM agreements
WHERE kind = 'distributor_commission'
  AND created_at >= (NOW() - INTERVAL '1 hour')
GROUP BY (snapshot_json->'terms'->0->>'rate_bps')::INTEGER
ORDER BY rate_bps;

-- ⚠️ ACTION REQUIRED: Update deal_id values
DO $$
BEGIN
    RAISE NOTICE '⚠️  ACTION REQUIRED: All agreements are set to deal_id=1 as placeholder!';
    RAISE NOTICE '   Run UPDATE queries to set correct deal_id for each agreement.';
    RAISE NOTICE '   Example:';
    RAISE NOTICE '   UPDATE agreements SET deal_id = 2 WHERE party_id = (SELECT id FROM parties WHERE name = ''Kuperman'');';
END $$;

-- ============================================================================
-- CLEANUP (optional - comment out if you want to keep temp tables)
-- ============================================================================
-- DROP TABLE IF EXISTS temp_parties;
-- DROP TABLE IF EXISTS temp_investors;
-- DROP TABLE IF EXISTS temp_agreements;
