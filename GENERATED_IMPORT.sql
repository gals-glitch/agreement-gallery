-- QUICK IMPORT - Generated 2025-10-30 11:19:43
BEGIN;

-- STEP 1: Import Parties

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Agamim Commercial Real Estate', 'moti@agamim-nadlan.co.il', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Agamim Commercial Real Estate- Moti Agam', 'moti@agamim-nadlan.co.il', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Alon Even Chen (נתאי השקעות)', 'alon.evenchen@gmail.com', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Amit Zeevi', '2017.amitz@gmail.com', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Avi Fried (פאים הולדינגס)', 'avraam_fried@yahoo.com', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Avraham Engel', 'דרך רבקה - דרך מייל של החלוקות', 'DISTRIBUTOR', 'Other', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Benny Shafir', 'shafir@yanaigroup.com', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Brian Horner', 'brianh@techcoastangels.la', 'DISTRIBUTOR', '1099', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Capital Link Family Office - Shiri Hybloom', 'shiri@clink-fo.com + yael@clink-fo.com', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Capital Link Family Office- Shiri Hybloom', 'shiri@clink-fo.com', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('David Govrin', 'דרך רבקה - דרך מייל של החלוקות', 'DISTRIBUTOR', 'Other', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('David Kirchenbaum (קרוס ארץ'' החזקות)', 'Dek7200@gmail.com', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('David Reichman', 'davidreichman@gmail.com', 'DISTRIBUTOR', '1099', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Dendrimer Capital Ltd', 'shlomi@dndrmr.com', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Doron Rivlin', 'דרך רבקה - דרך מייל של החלוקות', 'DISTRIBUTOR', 'Other', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Double Kappa, LLC', NULL, 'DISTRIBUTOR', '1099', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Eran Farajun', NULL, 'DISTRIBUTOR', 'Other', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Eran Farajun (Promote Due)', NULL, 'DISTRIBUTOR', '1099', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Erez Kleinman', NULL, 'DISTRIBUTOR', '1099', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Eyal Herring', 'eyal@herring-inv.com', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('FAIM Holding Ltd', 'avraam_fried@yahoo.com', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Formula Ventures Ltd- Shai Beilis', 'shai@formulaventures.com', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('GW CPA - Dudu Winkelstein', 'gw@netvision.net.il', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Gabriel Taub', 'gabitaub@gmail.com', 'DISTRIBUTOR', '1099', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Gil Haramati', 'diaserv@gmail.com', 'DISTRIBUTOR', '1099', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Gilad Slonim', 'gilad@balance-fp.co.il', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Glinert', 'דרך רבקה - דרך מייל של החלוקות', 'DISTRIBUTOR', '1099', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Guy Moses', 'Guy@GuyMoses.com', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Guy Moses (אופימר)', 'Guy@GuyMoses.com', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('H.A.N.A Investments LTD', 'ilan@Cpaweb.co.il', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('HS Invest Pension Insurance Agency (2016) Ltd', 'hezi@hsinvest.co.il', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Hezi Schwartz', 'hezi@hsinvest.co.il', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Hezi Schwartz (HS FAMILY OFFICE)', 'hezi@hsinvest.co.il', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Ilan Grinberg (ה.נ.א)', 'ilan@Cpaweb.co.il', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Ilanit Tirosh', 'ilaniti2000@gmail.com', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Ilanit Tirosh (רון הראל)', 'ilaniti2000@gmail.com', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Inna Magazinik', 'דרך רבקה - דרך מייל של החלוקות', 'DISTRIBUTOR', 'Other', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Jacob Cohen', 'דרך רבקה - דרך מייל של החלוקות', 'DISTRIBUTOR', '1099', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Karabel (Promote Due)', 'דרך רבקה - דרך מייל של החלוקות', 'DISTRIBUTOR', '1099', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Kleinman', 'דרך רבקה - דרך מייל של החלוקות', 'DISTRIBUTOR', '1099', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Kuperman', 'tsahi@kupermanbros.com + yradia@aol.com', 'DISTRIBUTOR', '1099', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Kuperman
(Kuperman Brothers Investments (2017) Ltd)', NULL, 'DISTRIBUTOR', 'Other', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Lior Cohen', 'sliorco@gmail.com', 'DISTRIBUTOR', '1099', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Lior Cohen (ThinkWise Consulting)', 'sliorco@gmail.com', 'DISTRIBUTOR', '1099', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Lior Stinus (Freidkes & Co. CPA)', 'lior@frcpa.co.il', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Lior Stinus (פריידקס)', 'lior@frcpa.co.il', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Logistic', 'דרך רבקה - דרך מייל של החלוקות', 'DISTRIBUTOR', 'Other', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Meirav Dvash', 'Meirav@ydvash.com', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Michael Tsukerman', 'דרך רבקה - דרך מייל של החלוקות', 'DISTRIBUTOR', 'Other', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('NLA Property Sales LLC', 'Nakselrad@gmail.com', 'DISTRIBUTOR', '1099', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Neto (ישן) Geller Finance - Global Investments LTD (איתו יש הסכם) - Elad Geler', 'eladg@neto-finance.co.il', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Pearlman', 'דרך רבקה - דרך מייל של החלוקות', 'DISTRIBUTOR', '1099', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Pini Ginsburg', 'piniginsburg@gmail.com', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Pioneer WM', 'inbarm@piowealth.com', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Ran Goren', 'rangorent1@gmail.com', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Ran Ravid', 'דרך רבקה - דרך מייל של החלוקות', 'DISTRIBUTOR', 'Other', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Ronny Maliniak', 'ronnymaliniak@gmail.com', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Roy Gold', 'GoldRoy@gmail.com', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Rubin Schlussel (אוטופיה 18)', 'Rubin@l-s.co.il', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('SRI Global Group (מועדון השקעות חברתיות)', 'daphna@wd-rei.com', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Shai Sheffer (DGTA)', 'udi@shaisheffer.com', 'DISTRIBUTOR', '1099', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Shai Sheffer (DGTA) + (MTRA)', 'udi@shaisheffer.com', 'DISTRIBUTOR', '1099', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Shai Sheffer (MTRA)', 'udi@shaisheffer.com', 'DISTRIBUTOR', '1099', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Sheara Einhorn', 'shearaeinhorn@gmail.com', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Sparta Capital- Yonel Dvash', 'YonelDvash@gmail.com + Yonel@Sparta-Capital.co.il', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Tal Even', 'tal@fraimanlaw.com', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Tal Simchony', 'Tal.Simchony@gmail.com', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('TanzerVest LLC', 'awtanzer@gmail.com', 'DISTRIBUTOR', '1099', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('TanzerVest LLC - Andrew Tanzer', 'awtanzer@gmail.com', 'DISTRIBUTOR', '1099', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('The Service', 'דרך רבקה - דרך מייל של החלוקות', 'DISTRIBUTOR', 'Other', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Total', NULL, 'DISTRIBUTOR', 'Other', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Tsukerman', 'דרך רבקה - דרך מייל של החלוקות', 'DISTRIBUTOR', 'Other', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Tsukerman (Promote Due)', 'דרך רבקה - דרך מייל של החלוקות', 'DISTRIBUTOR', '1099', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Tzafit Pension Insurance Agency (2023) Ltd', 'kordova5555@gmail.com + aviv@tazpit-f.co.il', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Unique Insurance Agency (2018) Ltd', 'yair@unique-ins.co.il', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Uri Golani', 'urigolani@gmail.com', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Vendor / Distributor', NULL, 'DISTRIBUTOR', 'Other', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)', 'michael@wiser.co.il', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('YL Consulting Inc', 'ylconsultinginc@gmail.com', 'DISTRIBUTOR', '1099', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('YL Consulting Inc (Yoav Lachover)', 'ylconsultinginc@gmail.com', 'DISTRIBUTOR', '1099', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Yariv Avrahami', 'yarivav@017.net.il', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Yoav Holzer (IKAGI דרך לצמיחה-עמלה בגין ארז וענת ברזילי)', 'yoav@facilfam.com', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Yoav Holzer (יתיאלה השקעות בעמ)', 'yoav@facilfam.com', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Yoel Stark', 'yoel@starkcpa.com', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Yoram Dvash -Fresh Properties', 'yoram@ydvash.com', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Yoram Shalit', 'Yoramsc@gmail.com', 'DISTRIBUTOR', 'Invoice', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('Zell', 'דרך רבקה - דרך מייל של החלוקות', 'DISTRIBUTOR', '1099', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

INSERT INTO parties (name, contact_email, kind, payment_method, status)
VALUES ('פורמט לשלוח לרבקה', NULL, 'DISTRIBUTOR', 'Other', 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),
    payment_method = EXCLUDED.payment_method;

-- STEP 2: Import Investors

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Assaf Feldman', NULL, (SELECT id FROM parties WHERE name = 'David Reichman' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Dov Gal', NULL, (SELECT id FROM parties WHERE name = 'David Reichman' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Dr. Guy Morag Orthopedics Ltd', NULL, (SELECT id FROM parties WHERE name = 'David Reichman' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Eran Yaniv', NULL, (SELECT id FROM parties WHERE name = 'David Reichman' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Yoram Mizrachi', NULL, (SELECT id FROM parties WHERE name = 'David Reichman' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('2224935 Ontario Inc', NULL, (SELECT id FROM parties WHERE name = 'Guy Moses' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Advisory Fee (not subject to VAT)', NULL, (SELECT id FROM parties WHERE name = 'Guy Moses' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Alon Even Chen', NULL, (SELECT id FROM parties WHERE name = 'Guy Moses' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Boaz Shiponi', NULL, (SELECT id FROM parties WHERE name = 'Guy Moses' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Dan Zur-Lior Wolf Landscape Architects Ltd', NULL, (SELECT id FROM parties WHERE name = 'Guy Moses' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Einav Itamar', NULL, (SELECT id FROM parties WHERE name = 'Guy Moses' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Guy Assif', NULL, (SELECT id FROM parties WHERE name = 'Guy Moses' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Lior Cohen', NULL, (SELECT id FROM parties WHERE name = 'Guy Moses' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Lior Yosef Wolf', NULL, (SELECT id FROM parties WHERE name = 'Guy Moses' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Placement Fee (not subject to VAT)', NULL, (SELECT id FROM parties WHERE name = 'Guy Moses' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Placement Fee (subject to VAT)', NULL, (SELECT id FROM parties WHERE name = 'Guy Moses' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Rachel Sztyglich Even Chen', NULL, (SELECT id FROM parties WHERE name = 'Guy Moses' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Sharon Kotlicki-Pery', NULL, (SELECT id FROM parties WHERE name = 'Guy Moses' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Techno Magnetic Media & Computer Supplies Inc', NULL, (SELECT id FROM parties WHERE name = 'Guy Moses' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('The Eric R Sirkin 2009 Trust', NULL, (SELECT id FROM parties WHERE name = 'Guy Moses' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Total Fee Earned By Buligo', NULL, (SELECT id FROM parties WHERE name = 'Guy Moses' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Avraham Cohen', NULL, (SELECT id FROM parties WHERE name = 'Inspire Finance' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Boaz and Orit Sokol', NULL, (SELECT id FROM parties WHERE name = 'Inspire Finance' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Comoas Holdings Ltd', NULL, (SELECT id FROM parties WHERE name = 'Inspire Finance' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Dana Witkon Sithakol and Eran Witkon', NULL, (SELECT id FROM parties WHERE name = 'Inspire Finance' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Daniella Dankner', NULL, (SELECT id FROM parties WHERE name = 'Inspire Finance' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('G. Erdinast Ltd', NULL, (SELECT id FROM parties WHERE name = 'Inspire Finance' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Gabriel Szendro Ltd', NULL, (SELECT id FROM parties WHERE name = 'Inspire Finance' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Hanna Dresner Berenbaum', NULL, (SELECT id FROM parties WHERE name = 'Inspire Finance' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Joseph Rosenblum', NULL, (SELECT id FROM parties WHERE name = 'Inspire Finance' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Labotal Scientific Equipment (1997) Ltd', NULL, (SELECT id FROM parties WHERE name = 'Inspire Finance' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Miriam Amalia Attar', NULL, (SELECT id FROM parties WHERE name = 'Inspire Finance' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Miriam Micky Tuttnauer', NULL, (SELECT id FROM parties WHERE name = 'Inspire Finance' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Nhevo and Sigalit Kaufman', NULL, (SELECT id FROM parties WHERE name = 'Inspire Finance' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Nick Shrayer', NULL, (SELECT id FROM parties WHERE name = 'Inspire Finance' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Nurith Jolanda Jaglom', NULL, (SELECT id FROM parties WHERE name = 'Inspire Finance' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Owed (including VAT)', NULL, (SELECT id FROM parties WHERE name = 'Inspire Finance' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Rachel Shoshana Roze Dankner', NULL, (SELECT id FROM parties WHERE name = 'Inspire Finance' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Rami Ben Nathan ADV', NULL, (SELECT id FROM parties WHERE name = 'Inspire Finance' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Rami and Liora Livnat', NULL, (SELECT id FROM parties WHERE name = 'Inspire Finance' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Ravit Yanko Arzi', NULL, (SELECT id FROM parties WHERE name = 'Inspire Finance' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Rivka Rubin Tautan', NULL, (SELECT id FROM parties WHERE name = 'Inspire Finance' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Sara Tovi', NULL, (SELECT id FROM parties WHERE name = 'Inspire Finance' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Sarig Electric Ltd', NULL, (SELECT id FROM parties WHERE name = 'Inspire Finance' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Tomer Coco Investments Ltd', NULL, (SELECT id FROM parties WHERE name = 'Inspire Finance' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Total', NULL, (SELECT id FROM parties WHERE name = 'Inspire Finance' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Udi Eyal Fima and Sigal Gavri', NULL, (SELECT id FROM parties WHERE name = 'Inspire Finance' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Victorya Rofeim', NULL, (SELECT id FROM parties WHERE name = 'Inspire Finance' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Yuval Hayim Katz', NULL, (SELECT id FROM parties WHERE name = 'Inspire Finance' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Gil Serok Revocable Trust', NULL, (SELECT id FROM parties WHERE name = 'Kuperman Capital' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Kuperman Brothers Investments (2017) Ltd', NULL, (SELECT id FROM parties WHERE name = 'Kuperman Capital' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Yaniv Radia', NULL, (SELECT id FROM parties WHERE name = 'Kuperman Capital' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Liad and Melissa Orr', NULL, (SELECT id FROM parties WHERE name = 'Lior Cohen' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Nir Hacohen', NULL, (SELECT id FROM parties WHERE name = 'Lior Cohen' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Yam Yosef Rubenstein', NULL, (SELECT id FROM parties WHERE name = 'Lior Cohen' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Yam Yosef Rubinstein', NULL, (SELECT id FROM parties WHERE name = 'Lior Cohen' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Yury Sofman', NULL, (SELECT id FROM parties WHERE name = 'Lior Cohen' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Boaz Israeli', NULL, (SELECT id FROM parties WHERE name = 'Michael Mann' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Buligo Fee', NULL, (SELECT id FROM parties WHERE name = 'Michael Mann' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Buligo Fees', NULL, (SELECT id FROM parties WHERE name = 'Michael Mann' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('IRA Fees', NULL, (SELECT id FROM parties WHERE name = 'Michael Mann' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Lea Golan Bengis', NULL, (SELECT id FROM parties WHERE name = 'Michael Mann' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Nahum Kaplan', NULL, (SELECT id FROM parties WHERE name = 'Michael Mann' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Orit Nir', NULL, (SELECT id FROM parties WHERE name = 'Michael Mann' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Total Fee Earned By Buligo', NULL, (SELECT id FROM parties WHERE name = 'Michael Mann' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Wiser Exit Fund 2 LP', NULL, (SELECT id FROM parties WHERE name = 'Michael Mann' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Wiser Exit Fund LP', NULL, (SELECT id FROM parties WHERE name = 'Michael Mann' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Wiser Opportunities LP', NULL, (SELECT id FROM parties WHERE name = 'Michael Mann' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('D.G.T.A Ltd', NULL, (SELECT id FROM parties WHERE name = 'Shai Sheffer' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Total Amount Due (with VAT)', NULL, (SELECT id FROM parties WHERE name = 'Shai Sheffer' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Total Fee Earned By Buligo', NULL, (SELECT id FROM parties WHERE name = 'Shai Sheffer' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Fresh Properties & Investments Ltd', NULL, (SELECT id FROM parties WHERE name = 'Yoram Dvash' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Total Amount Due (with VAT)', NULL, (SELECT id FROM parties WHERE name = 'Yoram Dvash' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Total Fee Earned By Buligo', NULL, (SELECT id FROM parties WHERE name = 'Yoram Dvash' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Advisory Fee (not subject to VAT)', NULL, (SELECT id FROM parties WHERE name = 'Yoram Shalit' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Arnon Ron', NULL, (SELECT id FROM parties WHERE name = 'Yoram Shalit' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Avi-Guy Orbach Barnea Properties Ltd', NULL, (SELECT id FROM parties WHERE name = 'Yoram Shalit' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Dalia and Yoram Shalit Cohen', NULL, (SELECT id FROM parties WHERE name = 'Yoram Shalit' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('E.M.B. Brayer Ltd', NULL, (SELECT id FROM parties WHERE name = 'Yoram Shalit' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('EMB Brayer Ltd', NULL, (SELECT id FROM parties WHERE name = 'Yoram Shalit' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Eyal Brayer', NULL, (SELECT id FROM parties WHERE name = 'Yoram Shalit' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Haggit Levy', NULL, (SELECT id FROM parties WHERE name = 'Yoram Shalit' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Haim Hoffman', NULL, (SELECT id FROM parties WHERE name = 'Yoram Shalit' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Hana Ron', NULL, (SELECT id FROM parties WHERE name = 'Yoram Shalit' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Karabel Inernational Investments', NULL, (SELECT id FROM parties WHERE name = 'Yoram Shalit' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Karabel International Investments Ltd', NULL, (SELECT id FROM parties WHERE name = 'Yoram Shalit' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Karabel International Investments ltd', NULL, (SELECT id FROM parties WHERE name = 'Yoram Shalit' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Nili Karabel', NULL, (SELECT id FROM parties WHERE name = 'Yoram Shalit' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Placement Fee (not subject to VAT)', NULL, (SELECT id FROM parties WHERE name = 'Yoram Shalit' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Placement Fee (subject to VAT)', NULL, (SELECT id FROM parties WHERE name = 'Yoram Shalit' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

INSERT INTO investors (name, email, introduced_by, status)
VALUES ('Total Fee Earned By Buligo', NULL, (SELECT id FROM parties WHERE name = 'Yoram Shalit' LIMIT 1), 'ACTIVE')
ON CONFLICT (name) DO UPDATE
SET email = COALESCE(EXCLUDED.email, investors.email),
    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);

-- STEP 3: Import Agreements

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Agamim Commercial Real Estate","deal_name":"Hoschton IL","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Agamim Commercial Real Estate' AND d.name = 'Hoschton IL'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Agamim Commercial Real Estate- Moti Agam","deal_name":"Heandersonville","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Agamim Commercial Real Estate- Moti Agam' AND d.name = 'Heandersonville'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Agamim Commercial Real Estate- Moti Agam","deal_name":"Mason","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Agamim Commercial Real Estate- Moti Agam' AND d.name = 'Mason'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Agamim Commercial Real Estate- Moti Agam","deal_name":"Riverwood","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Agamim Commercial Real Estate- Moti Agam' AND d.name = 'Riverwood'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Alon Even Chen (נתאי השקעות)","deal_name":"Bay Road (Carolina Bay)","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Alon Even Chen (נתאי השקעות)' AND d.name = 'Bay Road (Carolina Bay)'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Alon Even Chen (נתאי השקעות)","deal_name":"Brentwood","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Alon Even Chen (נתאי השקעות)' AND d.name = 'Brentwood'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Alon Even Chen (נתאי השקעות)","deal_name":"Classic city","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Alon Even Chen (נתאי השקעות)' AND d.name = 'Classic city'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Alon Even Chen (נתאי השקעות)","deal_name":"Dry Creek","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Alon Even Chen (נתאי השקעות)' AND d.name = 'Dry Creek'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Alon Even Chen (נתאי השקעות)","deal_name":"Heandersonville","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Alon Even Chen (נתאי השקעות)' AND d.name = 'Heandersonville'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Alon Even Chen (נתאי השקעות)","deal_name":"Johnstown","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Alon Even Chen (נתאי השקעות)' AND d.name = 'Johnstown'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Alon Even Chen (נתאי השקעות)","deal_name":"Ledge Rock","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Alon Even Chen (נתאי השקעות)' AND d.name = 'Ledge Rock'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Alon Even Chen (נתאי השקעות)","deal_name":"Reems Creek","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Alon Even Chen (נתאי השקעות)' AND d.name = 'Reems Creek'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Alon Even Chen (נתאי השקעות)","deal_name":"Snellville","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Alon Even Chen (נתאי השקעות)' AND d.name = 'Snellville'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Amit Zeevi","deal_name":"1000 Crosby","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Amit Zeevi' AND d.name = '1000 Crosby'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Amit Zeevi","deal_name":"Classic city","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Amit Zeevi' AND d.name = 'Classic city'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Amit Zeevi","deal_name":"Hoschton IL","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Amit Zeevi' AND d.name = 'Hoschton IL'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Amit Zeevi","deal_name":"Snellville","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Amit Zeevi' AND d.name = 'Snellville'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Amit Zeevi","deal_name":"Statesboro","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Amit Zeevi' AND d.name = 'Statesboro'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Amit Zeevi","deal_name":"Thatcher Woods","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Amit Zeevi' AND d.name = 'Thatcher Woods'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Avi Fried (פאים הולדינגס)","deal_name":"201 Triple Diamond","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Avi Fried (פאים הולדינגס)' AND d.name = '201 Triple Diamond'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Avi Fried (פאים הולדינגס)","deal_name":"2840 Orange","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Avi Fried (פאים הולדינגס)' AND d.name = '2840 Orange'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Avi Fried (פאים הולדינגס)","deal_name":"5 East Pointe Dr","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Avi Fried (פאים הולדינגס)' AND d.name = '5 East Pointe Dr'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Avi Fried (פאים הולדינגס)","deal_name":"6501 Nevada","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Avi Fried (פאים הולדינגס)' AND d.name = '6501 Nevada'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Avi Fried (פאים הולדינגס)","deal_name":"9231 Penn Ave","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Avi Fried (פאים הולדינגס)' AND d.name = '9231 Penn Ave'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Avi Fried (פאים הולדינגס)","deal_name":"Bay Road (Carolina Bay)","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Avi Fried (פאים הולדינגס)' AND d.name = 'Bay Road (Carolina Bay)'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Avi Fried (פאים הולדינגס)","deal_name":"Berwick","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Avi Fried (פאים הולדינגס)' AND d.name = 'Berwick'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Avi Fried (פאים הולדינגס)","deal_name":"Brentwood","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Avi Fried (פאים הולדינגס)' AND d.name = 'Brentwood'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Avi Fried (פאים הולדינגס)","deal_name":"Classic city","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Avi Fried (פאים הולדינגס)' AND d.name = 'Classic city'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Avi Fried (פאים הולדינגס)","deal_name":"Dry Creek","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Avi Fried (פאים הולדינגס)' AND d.name = 'Dry Creek'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Avi Fried (פאים הולדינגס)","deal_name":"East Hennepin","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Avi Fried (פאים הולדינגס)' AND d.name = 'East Hennepin'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Avi Fried (פאים הולדינגס)","deal_name":"Fitzroy","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Avi Fried (פאים הולדינגס)' AND d.name = 'Fitzroy'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Avi Fried (פאים הולדינגס)","deal_name":"Gainesville 2023","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Avi Fried (פאים הולדינגס)' AND d.name = 'Gainesville 2023'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Avi Fried (פאים הולדינגס)","deal_name":"Hiram 2024","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Avi Fried (פאים הולדינגס)' AND d.name = 'Hiram 2024'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Avi Fried (פאים הולדינגס)","deal_name":"Hoschton IL","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Avi Fried (פאים הולדינגס)' AND d.name = 'Hoschton IL'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Avi Fried (פאים הולדינגס)","deal_name":"Hudson Heritage","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Avi Fried (פאים הולדינגס)' AND d.name = 'Hudson Heritage'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Avi Fried (פאים הולדינגס)","deal_name":"Johnstown","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Avi Fried (פאים הולדינגס)' AND d.name = 'Johnstown'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Avi Fried (פאים הולדינגס)","deal_name":"Mason","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Avi Fried (פאים הולדינגס)' AND d.name = 'Mason'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Avi Fried (פאים הולדינגס)","deal_name":"Oakwood","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Avi Fried (פאים הולדינגס)' AND d.name = 'Oakwood'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Avi Fried (פאים הולדינגס)","deal_name":"Perdido","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Avi Fried (פאים הולדינגס)' AND d.name = 'Perdido'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Avi Fried (פאים הולדינגס)","deal_name":"Perdido- Phase 2","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Avi Fried (פאים הולדינגס)' AND d.name = 'Perdido- Phase 2'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Avi Fried (פאים הולדינגס)","deal_name":"River Ridge 2023","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Avi Fried (פאים הולדינגס)' AND d.name = 'River Ridge 2023'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Avi Fried (פאים הולדינגס)","deal_name":"Statesboro","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Avi Fried (פאים הולדינגס)' AND d.name = 'Statesboro'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Avi Fried (פאים הולדינגס)","deal_name":"Thatcher Woods","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Avi Fried (פאים הולדינגס)' AND d.name = 'Thatcher Woods'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Avraham Engel","deal_name":"Retreat at Weaverville","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Avraham Engel' AND d.name = 'Retreat at Weaverville'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Benny Shafir","deal_name":"Berwick","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Benny Shafir' AND d.name = 'Berwick'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Benny Shafir","deal_name":"Dry Creek","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Benny Shafir' AND d.name = 'Dry Creek'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Brian Horner","deal_name":"Perdido","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Brian Horner' AND d.name = 'Perdido'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Brian Horner","deal_name":"Perdido- Phase 2","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Brian Horner' AND d.name = 'Perdido- Phase 2'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Capital Link Family Office - Shiri Hybloom","deal_name":"Harry Hines","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Capital Link Family Office - Shiri Hybloom' AND d.name = 'Harry Hines'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Capital Link Family Office- Shiri Hybloom","deal_name":"1010 Midtown","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Capital Link Family Office- Shiri Hybloom' AND d.name = '1010 Midtown'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Capital Link Family Office- Shiri Hybloom","deal_name":"East Hennepin","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Capital Link Family Office- Shiri Hybloom' AND d.name = 'East Hennepin'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Capital Link Family Office- Shiri Hybloom","deal_name":"Perdido","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Capital Link Family Office- Shiri Hybloom' AND d.name = 'Perdido'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Capital Link Family Office- Shiri Hybloom","deal_name":"Perdido- Phase 2","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Capital Link Family Office- Shiri Hybloom' AND d.name = 'Perdido- Phase 2'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Capital Link Family Office- Shiri Hybloom","deal_name":"Skyline","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Capital Link Family Office- Shiri Hybloom' AND d.name = 'Skyline'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Govrin","deal_name":"Meadows","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Govrin' AND d.name = 'Meadows'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Govrin","deal_name":"Metro","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Govrin' AND d.name = 'Metro'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Kirchenbaum (קרוס ארץ'''' החזקות)","deal_name":"2840 Orange","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Kirchenbaum (קרוס ארץ'' החזקות)' AND d.name = '2840 Orange'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Kirchenbaum (קרוס ארץ'''' החזקות)","deal_name":"6501 Nevada","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Kirchenbaum (קרוס ארץ'' החזקות)' AND d.name = '6501 Nevada'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Kirchenbaum (קרוס ארץ'''' החזקות)","deal_name":"9231 Penn Ave","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Kirchenbaum (קרוס ארץ'' החזקות)' AND d.name = '9231 Penn Ave'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Kirchenbaum (קרוס ארץ'''' החזקות)","deal_name":"Antioch","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Kirchenbaum (קרוס ארץ'' החזקות)' AND d.name = 'Antioch'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Kirchenbaum (קרוס ארץ'''' החזקות)","deal_name":"Ascent","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Kirchenbaum (קרוס ארץ'' החזקות)' AND d.name = 'Ascent'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Kirchenbaum (קרוס ארץ'''' החזקות)","deal_name":"Brentwood","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Kirchenbaum (קרוס ארץ'' החזקות)' AND d.name = 'Brentwood'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Kirchenbaum (קרוס ארץ'''' החזקות)","deal_name":"Cheshire","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Kirchenbaum (קרוס ארץ'' החזקות)' AND d.name = 'Cheshire'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Kirchenbaum (קרוס ארץ'''' החזקות)","deal_name":"Christina","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Kirchenbaum (קרוס ארץ'' החזקות)' AND d.name = 'Christina'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Kirchenbaum (קרוס ארץ'''' החזקות)","deal_name":"Dry Creek","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Kirchenbaum (קרוס ארץ'' החזקות)' AND d.name = 'Dry Creek'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Kirchenbaum (קרוס ארץ'''' החזקות)","deal_name":"Duncen","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Kirchenbaum (קרוס ארץ'' החזקות)' AND d.name = 'Duncen'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Kirchenbaum (קרוס ארץ'''' החזקות)","deal_name":"Fitzroy","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Kirchenbaum (קרוס ארץ'' החזקות)' AND d.name = 'Fitzroy'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Kirchenbaum (קרוס ארץ'''' החזקות)","deal_name":"Fitzroy Townhomes","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Kirchenbaum (קרוס ארץ'' החזקות)' AND d.name = 'Fitzroy Townhomes'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Kirchenbaum (קרוס ארץ'''' החזקות)","deal_name":"Hartford Corners","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Kirchenbaum (קרוס ארץ'' החזקות)' AND d.name = 'Hartford Corners'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Kirchenbaum (קרוס ארץ'''' החזקות)","deal_name":"Johnstown","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Kirchenbaum (קרוס ארץ'' החזקות)' AND d.name = 'Johnstown'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Kirchenbaum (קרוס ארץ'''' החזקות)","deal_name":"Ledge Rock","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Kirchenbaum (קרוס ארץ'' החזקות)' AND d.name = 'Ledge Rock'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Kirchenbaum (קרוס ארץ'''' החזקות)","deal_name":"MLL","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Kirchenbaum (קרוס ארץ'' החזקות)' AND d.name = 'MLL'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Kirchenbaum (קרוס ארץ'''' החזקות)","deal_name":"Metro","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Kirchenbaum (קרוס ארץ'' החזקות)' AND d.name = 'Metro'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Kirchenbaum (קרוס ארץ'''' החזקות)","deal_name":"Neely","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Kirchenbaum (קרוס ארץ'' החזקות)' AND d.name = 'Neely'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Kirchenbaum (קרוס ארץ'''' החזקות)","deal_name":"Neely Phase II","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Kirchenbaum (קרוס ארץ'' החזקות)' AND d.name = 'Neely Phase II'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Kirchenbaum (קרוס ארץ'''' החזקות)","deal_name":"Oakwood","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Kirchenbaum (קרוס ארץ'' החזקות)' AND d.name = 'Oakwood'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Kirchenbaum (קרוס ארץ'''' החזקות)","deal_name":"Parkwest","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Kirchenbaum (קרוס ארץ'' החזקות)' AND d.name = 'Parkwest'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Kirchenbaum (קרוס ארץ'''' החזקות)","deal_name":"Perdido","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Kirchenbaum (קרוס ארץ'' החזקות)' AND d.name = 'Perdido'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Kirchenbaum (קרוס ארץ'''' החזקות)","deal_name":"Perdido- Phase 2","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Kirchenbaum (קרוס ארץ'' החזקות)' AND d.name = 'Perdido- Phase 2'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Kirchenbaum (קרוס ארץ'''' החזקות)","deal_name":"River Ridge","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Kirchenbaum (קרוס ארץ'' החזקות)' AND d.name = 'River Ridge'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Kirchenbaum (קרוס ארץ'''' החזקות)","deal_name":"River Ridge 2023","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Kirchenbaum (קרוס ארץ'' החזקות)' AND d.name = 'River Ridge 2023'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Kirchenbaum (קרוס ארץ'''' החזקות)","deal_name":"Thatcher Woods","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Kirchenbaum (קרוס ארץ'' החזקות)' AND d.name = 'Thatcher Woods'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Kirchenbaum (קרוס ארץ'''' החזקות)","deal_name":"White House","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Kirchenbaum (קרוס ארץ'' החזקות)' AND d.name = 'White House'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Kirchenbaum (קרוס ארץ'''' החזקות)","deal_name":"White house","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Kirchenbaum (קרוס ארץ'' החזקות)' AND d.name = 'White house'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Reichman","deal_name":"6501 Nevada","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Reichman' AND d.name = '6501 Nevada'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Reichman","deal_name":"Antioch","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Reichman' AND d.name = 'Antioch'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Reichman","deal_name":"Beaufort","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Reichman' AND d.name = 'Beaufort'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Reichman","deal_name":"Brentwood","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Reichman' AND d.name = 'Brentwood'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Reichman","deal_name":"Dry Creek","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Reichman' AND d.name = 'Dry Creek'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Reichman","deal_name":"East Hennepin","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Reichman' AND d.name = 'East Hennepin'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Reichman","deal_name":"Groton","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Reichman' AND d.name = 'Groton'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Reichman","deal_name":"Heandersonville","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Reichman' AND d.name = 'Heandersonville'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Reichman","deal_name":"Johnstown","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Reichman' AND d.name = 'Johnstown'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Reichman","deal_name":"Milagro","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Reichman' AND d.name = 'Milagro'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Reichman","deal_name":"Oak Brook","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Reichman' AND d.name = 'Oak Brook'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Reichman","deal_name":"Perdido","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Reichman' AND d.name = 'Perdido'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Reichman","deal_name":"Perdido- Phase 2","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Reichman' AND d.name = 'Perdido- Phase 2'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Reichman","deal_name":"Reems Creek","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Reichman' AND d.name = 'Reems Creek'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Reichman","deal_name":"White House","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Reichman' AND d.name = 'White House'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"David Reichman","deal_name":"White house","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'David Reichman' AND d.name = 'White house'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Dendrimer Capital Ltd","deal_name":"Hiram 2024","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Dendrimer Capital Ltd' AND d.name = 'Hiram 2024'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Dendrimer Capital Ltd","deal_name":"Hoschton IL","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Dendrimer Capital Ltd' AND d.name = 'Hoschton IL'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Dendrimer Capital Ltd","deal_name":"Ledge Rock","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Dendrimer Capital Ltd' AND d.name = 'Ledge Rock'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Dendrimer Capital Ltd","deal_name":"Tyde II","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Dendrimer Capital Ltd' AND d.name = 'Tyde II'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Doron Rivlin","deal_name":"Retreat at Weaverville","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Doron Rivlin' AND d.name = 'Retreat at Weaverville'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Double Kappa, LLC","deal_name":"Hudson Heritage","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Double Kappa, LLC' AND d.name = 'Hudson Heritage'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Eran Farajun","deal_name":"Metro","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Eran Farajun' AND d.name = 'Metro'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Eran Farajun","deal_name":"Osceola","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Eran Farajun' AND d.name = 'Osceola'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Eran Farajun (Promote Due)","deal_name":"Leland","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Eran Farajun (Promote Due)' AND d.name = 'Leland'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Erez Kleinman","deal_name":"Parkwest","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Erez Kleinman' AND d.name = 'Parkwest'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Eyal Herring","deal_name":"Hoschton IL","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Eyal Herring' AND d.name = 'Hoschton IL'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"FAIM Holding Ltd","deal_name":"100 City View","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'FAIM Holding Ltd' AND d.name = '100 City View'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"FAIM Holding Ltd","deal_name":"Ledge Rock","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'FAIM Holding Ltd' AND d.name = 'Ledge Rock'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"FAIM Holding Ltd","deal_name":"Sarasota","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'FAIM Holding Ltd' AND d.name = 'Sarasota'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Formula Ventures Ltd- Shai Beilis","deal_name":"100 City View","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Formula Ventures Ltd- Shai Beilis' AND d.name = '100 City View'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Formula Ventures Ltd- Shai Beilis","deal_name":"201 Triple Diamond","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Formula Ventures Ltd- Shai Beilis' AND d.name = '201 Triple Diamond'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Formula Ventures Ltd- Shai Beilis","deal_name":"Thatcher Woods","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Formula Ventures Ltd- Shai Beilis' AND d.name = 'Thatcher Woods'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"GW CPA - Dudu Winkelstein","deal_name":"Oakwood","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'GW CPA - Dudu Winkelstein' AND d.name = 'Oakwood'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Gabriel Taub","deal_name":"Brentwood","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Gabriel Taub' AND d.name = 'Brentwood'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Gabriel Taub","deal_name":"Hartford Corners","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Gabriel Taub' AND d.name = 'Hartford Corners'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Gil Haramati","deal_name":"100 City View","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Gil Haramati' AND d.name = '100 City View'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Gil Haramati","deal_name":"5 East Pointe Dr","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Gil Haramati' AND d.name = '5 East Pointe Dr'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Gil Haramati","deal_name":"Brentwood","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Gil Haramati' AND d.name = 'Brentwood'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Gil Haramati","deal_name":"Fitzroy","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Gil Haramati' AND d.name = 'Fitzroy'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Gil Haramati","deal_name":"Fitzroy Townhomes","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Gil Haramati' AND d.name = 'Fitzroy Townhomes'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Gil Haramati","deal_name":"Hartford Corners","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Gil Haramati' AND d.name = 'Hartford Corners'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Gilad Slonim","deal_name":"9231 Penn Ave","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Gilad Slonim' AND d.name = '9231 Penn Ave'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Gilad Slonim","deal_name":"Berwick","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Gilad Slonim' AND d.name = 'Berwick'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Gilad Slonim","deal_name":"Cheshire","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Gilad Slonim' AND d.name = 'Cheshire'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Gilad Slonim","deal_name":"Fitzroy","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Gilad Slonim' AND d.name = 'Fitzroy'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Gilad Slonim","deal_name":"Fitzroy Townhomes","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Gilad Slonim' AND d.name = 'Fitzroy Townhomes'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Gilad Slonim","deal_name":"Groton","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Gilad Slonim' AND d.name = 'Groton'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Gilad Slonim","deal_name":"Mason","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Gilad Slonim' AND d.name = 'Mason'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Gilad Slonim","deal_name":"Perdido","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Gilad Slonim' AND d.name = 'Perdido'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Gilad Slonim","deal_name":"Perdido- Phase 2","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Gilad Slonim' AND d.name = 'Perdido- Phase 2'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Glinert","deal_name":"Fairview","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Glinert' AND d.name = 'Fairview'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Glinert","deal_name":"Milagro","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Glinert' AND d.name = 'Milagro'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses","deal_name":"100 City View","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses' AND d.name = '100 City View'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses","deal_name":"Ledge Rock","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses' AND d.name = 'Ledge Rock'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"2840 Orange","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = '2840 Orange'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"571 Commerce Expansion","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = '571 Commerce Expansion'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"6501 Nevada","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = '6501 Nevada'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"9231 Penn Ave","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = '9231 Penn Ave'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Antioch","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Antioch'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Bay Road (Carolina Bay)","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Bay Road (Carolina Bay)'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Beaufort","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Beaufort'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Berwick","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Berwick'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Brentwood","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Brentwood'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"CLI","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'CLI'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"CP Phase II","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'CP Phase II'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Christina Mill","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Christina Mill'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Classic city","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Classic city'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Crescent","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Crescent'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Dry Creek","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Dry Creek'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Duncen","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Duncen'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"East Hennepin","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'East Hennepin'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Fitzroy","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Fitzroy'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Fitzroy Townhomes","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Fitzroy Townhomes'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Gainesville","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Gainesville'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Gainesville 2023","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Gainesville 2023'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Heandersonville","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Heandersonville'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Highline","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Highline'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Hiram","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Hiram'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Hiram 2024","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Hiram 2024'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Hoschton","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Hoschton'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Hoschton IL","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Hoschton IL'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Huntsville","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Huntsville'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Johnstown","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Johnstown'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Lafayette","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Lafayette'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Mason","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Mason'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Meadows","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Meadows'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Metro","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Metro'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Milagro","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Milagro'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Milagro (IRA Fund II)","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Milagro (IRA Fund II)'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Neely","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Neely'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Neely Phase II","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Neely Phase II'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Oakwood","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Oakwood'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Osceola","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Osceola'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Osceola (IRA Fund II)","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Osceola (IRA Fund II)'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Perdido","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Perdido'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Perdido- Phase 1","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Perdido- Phase 1'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Reems Creek","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Reems Creek'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Reserve","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Reserve'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Retreat at Weaverville","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Retreat at Weaverville'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"River Ridge 2023","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'River Ridge 2023'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Riverwood","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Riverwood'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Snellville","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Snellville'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Statesboro","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Statesboro'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Sugarloaf","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Sugarloaf'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Thatcher Woods","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Thatcher Woods'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר)","deal_name":"Westgate","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר)' AND d.name = 'Westgate'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Guy Moses (אופימר) (Promote)","deal_name":"Ascent","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Guy Moses (אופימר) (Promote)' AND d.name = 'Ascent'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"H.A.N.A Investments LTD","deal_name":"Hoschton IL","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'H.A.N.A Investments LTD' AND d.name = 'Hoschton IL'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"H.A.N.A Investments LTD","deal_name":"Ledge Rock","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'H.A.N.A Investments LTD' AND d.name = 'Ledge Rock'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"HS Invest Pension Insurance Agency (2016) Ltd","deal_name":"Hoschton IL","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'HS Invest Pension Insurance Agency (2016) Ltd' AND d.name = 'Hoschton IL'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"HS Invest Pension Insurance Agency (2016) Ltd","deal_name":"MLL","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'HS Invest Pension Insurance Agency (2016) Ltd' AND d.name = 'MLL'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Hezi Schwartz","deal_name":"Beaufort (IRA Fund I)","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Hezi Schwartz' AND d.name = 'Beaufort (IRA Fund I)'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Hezi Schwartz (HS FAMILY OFFICE)","deal_name":"201 Triple Diamond","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Hezi Schwartz (HS FAMILY OFFICE)' AND d.name = '201 Triple Diamond'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Hezi Schwartz (HS FAMILY OFFICE)","deal_name":"Antioch (IRA Fund I)","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Hezi Schwartz (HS FAMILY OFFICE)' AND d.name = 'Antioch (IRA Fund I)'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Hezi Schwartz (HS FAMILY OFFICE)","deal_name":"Christina Mill (Promote Fee Due)","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Hezi Schwartz (HS FAMILY OFFICE)' AND d.name = 'Christina Mill (Promote Fee Due)'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Hezi Schwartz (HS FAMILY OFFICE)","deal_name":"Duncan","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Hezi Schwartz (HS FAMILY OFFICE)' AND d.name = 'Duncan'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Hezi Schwartz (HS FAMILY OFFICE)","deal_name":"Duncan (Promote Fee Due)","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Hezi Schwartz (HS FAMILY OFFICE)' AND d.name = 'Duncan (Promote Fee Due)'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Hezi Schwartz (HS FAMILY OFFICE)","deal_name":"Leland (IRA Fund I)","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Hezi Schwartz (HS FAMILY OFFICE)' AND d.name = 'Leland (IRA Fund I)'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Hezi Schwartz (HS FAMILY OFFICE)","deal_name":"River Ridge 2023","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Hezi Schwartz (HS FAMILY OFFICE)' AND d.name = 'River Ridge 2023'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Hezi Schwartz (HS FAMILY OFFICE)","deal_name":"Roper (IRA Fund I)","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Hezi Schwartz (HS FAMILY OFFICE)' AND d.name = 'Roper (IRA Fund I)'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Ilan Grinberg (ה.נ.א)","deal_name":"1000 Crosby","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Ilan Grinberg (ה.נ.א)' AND d.name = '1000 Crosby'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Ilan Grinberg (ה.נ.א)","deal_name":"1302 Eastport","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Ilan Grinberg (ה.נ.א)' AND d.name = '1302 Eastport'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Ilan Grinberg (ה.נ.א)","deal_name":"201 Triple Diamond","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Ilan Grinberg (ה.נ.א)' AND d.name = '201 Triple Diamond'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Ilan Grinberg (ה.נ.א)","deal_name":"2840 Orange","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Ilan Grinberg (ה.נ.א)' AND d.name = '2840 Orange'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Ilan Grinberg (ה.נ.א)","deal_name":"5 East Pointe Dr","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Ilan Grinberg (ה.נ.א)' AND d.name = '5 East Pointe Dr'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Ilan Grinberg (ה.נ.א)","deal_name":"Classic city","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Ilan Grinberg (ה.נ.א)' AND d.name = 'Classic city'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Ilan Grinberg (ה.נ.א)","deal_name":"Dry Creek","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Ilan Grinberg (ה.נ.א)' AND d.name = 'Dry Creek'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Ilan Grinberg (ה.נ.א)","deal_name":"Groton","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Ilan Grinberg (ה.נ.א)' AND d.name = 'Groton'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Ilan Grinberg (ה.נ.א)","deal_name":"Hartford Corners","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Ilan Grinberg (ה.נ.א)' AND d.name = 'Hartford Corners'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Ilan Grinberg (ה.נ.א)","deal_name":"Hudson Heritage","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Ilan Grinberg (ה.נ.א)' AND d.name = 'Hudson Heritage'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Ilan Grinberg (ה.נ.א)","deal_name":"Mason","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Ilan Grinberg (ה.נ.א)' AND d.name = 'Mason'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Ilan Grinberg (ה.נ.א)","deal_name":"Oakwood","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Ilan Grinberg (ה.נ.א)' AND d.name = 'Oakwood'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Ilan Grinberg (ה.נ.א)","deal_name":"Perdido","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Ilan Grinberg (ה.נ.א)' AND d.name = 'Perdido'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Ilan Grinberg (ה.נ.א)","deal_name":"Perdido- Phase 2","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Ilan Grinberg (ה.נ.א)' AND d.name = 'Perdido- Phase 2'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Ilan Grinberg (ה.נ.א)","deal_name":"Reems Creek","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Ilan Grinberg (ה.נ.א)' AND d.name = 'Reems Creek'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Ilan Grinberg (ה.נ.א)","deal_name":"River Ridge 2023","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Ilan Grinberg (ה.נ.א)' AND d.name = 'River Ridge 2023'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Ilan Grinberg (ה.נ.א)","deal_name":"Riverwood","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Ilan Grinberg (ה.נ.א)' AND d.name = 'Riverwood'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Ilan Grinberg (ה.נ.א)","deal_name":"Sarasota","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Ilan Grinberg (ה.נ.א)' AND d.name = 'Sarasota'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Ilan Grinberg (ה.נ.א)","deal_name":"Sugarloaf","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Ilan Grinberg (ה.נ.א)' AND d.name = 'Sugarloaf'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Ilan Grinberg (ה.נ.א)","deal_name":"Thatcher Woods","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Ilan Grinberg (ה.נ.א)' AND d.name = 'Thatcher Woods'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Ilanit Tirosh","deal_name":"Dry Creek","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Ilanit Tirosh' AND d.name = 'Dry Creek'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Ilanit Tirosh","deal_name":"Hiram 2024","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Ilanit Tirosh' AND d.name = 'Hiram 2024'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Ilanit Tirosh","deal_name":"Johnstown","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Ilanit Tirosh' AND d.name = 'Johnstown'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Ilanit Tirosh","deal_name":"Milagro","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Ilanit Tirosh' AND d.name = 'Milagro'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Ilanit Tirosh (רון הראל)","deal_name":"Milagro","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Ilanit Tirosh (רון הראל)' AND d.name = 'Milagro'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Inna Magazinik","deal_name":"Meadows","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Inna Magazinik' AND d.name = 'Meadows'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Inna Magazinik","deal_name":"Metro","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Inna Magazinik' AND d.name = 'Metro'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Jacob Cohen","deal_name":"Metro","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Jacob Cohen' AND d.name = 'Metro'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Jacob Cohen","deal_name":"Milagro","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Jacob Cohen' AND d.name = 'Milagro'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Jacob Cohen","deal_name":"Osceola","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Jacob Cohen' AND d.name = 'Osceola'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Karabel (Promote Due)","deal_name":"Antioch","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Karabel (Promote Due)' AND d.name = 'Antioch'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kleinman","deal_name":"Fairview","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kleinman' AND d.name = 'Fairview'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kleinman","deal_name":"Osceola","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kleinman' AND d.name = 'Osceola'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"100 City View","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = '100 City View'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"201 Triple Diamond","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = '201 Triple Diamond'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"310 Tyson-Draft","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = '310 Tyson-Draft'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"571 Commerce Expansion","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = '571 Commerce Expansion'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"6501 Nevada","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = '6501 Nevada'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"9231 Penn Ave","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = '9231 Penn Ave'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Antioch","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Antioch'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Ascent","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Ascent'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Bay Road (Carolina Bay)","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Bay Road (Carolina Bay)'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Berwick","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Berwick'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Brentwood","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Brentwood'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"CP Phase II","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'CP Phase II'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Cheshire","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Cheshire'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Christina","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Christina'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Classic city","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Classic city'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Crescent","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Crescent'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Dry Creek","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Dry Creek'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Duncan","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Duncan'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"East Hennepin","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'East Hennepin'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Fitzroy","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Fitzroy'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Fitzroy Townhomes","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Fitzroy Townhomes'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Gainesville","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Gainesville'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Gainesville 2023","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Gainesville 2023'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Groton","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Groton'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Hartford Corners","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Hartford Corners'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Heandersonville","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Heandersonville'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Highline","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Highline'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Hiram 2024","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Hiram 2024'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Hoschton IL","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Hoschton IL'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Hudson Heritage","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Hudson Heritage'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Johnstown","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Johnstown'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Lafayette","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Lafayette'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Ledge Rock","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Ledge Rock'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Meadows","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Meadows'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Metro","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Metro'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Milagro","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Milagro'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Neely","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Neely'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Neely Phase II","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Neely Phase II'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Oakwood","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Oakwood'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Osceola","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Osceola'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Perdido","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Perdido'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Perdido- Phase 2","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Perdido- Phase 2'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Reems Creek","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Reems Creek'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Retreat at Weaverville","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Retreat at Weaverville'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"River Ridge","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'River Ridge'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"River Ridge 2023","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'River Ridge 2023'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Riverwood","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Riverwood'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Sarasota","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Sarasota'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Snellville","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Snellville'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Statesboro","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Statesboro'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Sugarloaf","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Sugarloaf'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Thatcher Woods","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Thatcher Woods'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"Tree Trail","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'Tree Trail'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"White House","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'White House'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman","deal_name":"White house","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman' AND d.name = 'White house'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman
(Kuperman Brothers Investments (2017) Ltd)","deal_name":"Sugarloaf + 
Hudson Heritage","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman
(Kuperman Brothers Investments (2017) Ltd)' AND d.name = 'Sugarloaf + 
Hudson Heritage'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman Capital","deal_name":"Marquis Crest Buligo LP","terms":[{"from":"2018-11-01","to":''2019-12-12'',"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman Capital' AND d.name = 'Marquis Crest Buligo LP'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman Capital","deal_name":"Marquis Crest Buligo LP","terms":[{"from":"2019-12-12","to":''2020-10-31'',"rate_bps":300,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman Capital' AND d.name = 'Marquis Crest Buligo LP'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Kuperman Capital","deal_name":"Marquis Crest Buligo LP","terms":[{"from":"2020-10-31","to":NULL,"rate_bps":350,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Kuperman Capital' AND d.name = 'Marquis Crest Buligo LP'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Lior Cohen","deal_name":"Oakwood + 
Hudson Heritage","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Lior Cohen' AND d.name = 'Oakwood + 
Hudson Heritage'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Lior Cohen","deal_name":"Reems Creek","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Lior Cohen' AND d.name = 'Reems Creek'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Lior Cohen (ThinkWise Consulting)","deal_name":"201 Triple Diamond","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Lior Cohen (ThinkWise Consulting)' AND d.name = '201 Triple Diamond'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Lior Cohen (ThinkWise Consulting)","deal_name":"571 Commerce Expansion","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Lior Cohen (ThinkWise Consulting)' AND d.name = '571 Commerce Expansion'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Lior Cohen (ThinkWise Consulting)","deal_name":"6501 Nevada","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Lior Cohen (ThinkWise Consulting)' AND d.name = '6501 Nevada'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Lior Cohen (ThinkWise Consulting)","deal_name":"9231 Penn Ave","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Lior Cohen (ThinkWise Consulting)' AND d.name = '9231 Penn Ave'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Lior Cohen (ThinkWise Consulting)","deal_name":"Berwick","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Lior Cohen (ThinkWise Consulting)' AND d.name = 'Berwick'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Lior Cohen (ThinkWise Consulting)","deal_name":"Dry Creek","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Lior Cohen (ThinkWise Consulting)' AND d.name = 'Dry Creek'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Lior Cohen (ThinkWise Consulting)","deal_name":"Greenway","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Lior Cohen (ThinkWise Consulting)' AND d.name = 'Greenway'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Lior Cohen (ThinkWise Consulting)","deal_name":"Hudson Heritage","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Lior Cohen (ThinkWise Consulting)' AND d.name = 'Hudson Heritage'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Lior Cohen (ThinkWise Consulting)","deal_name":"Huntsville","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Lior Cohen (ThinkWise Consulting)' AND d.name = 'Huntsville'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Lior Cohen (ThinkWise Consulting)","deal_name":"Johnstown","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Lior Cohen (ThinkWise Consulting)' AND d.name = 'Johnstown'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Lior Cohen (ThinkWise Consulting)","deal_name":"Meitav Fund","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Lior Cohen (ThinkWise Consulting)' AND d.name = 'Meitav Fund'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Lior Cohen (ThinkWise Consulting)","deal_name":"Oakwood","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Lior Cohen (ThinkWise Consulting)' AND d.name = 'Oakwood'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Lior Cohen (ThinkWise Consulting)","deal_name":"Perdido","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Lior Cohen (ThinkWise Consulting)' AND d.name = 'Perdido'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Lior Cohen (ThinkWise Consulting)","deal_name":"Perdido- Phase 2","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Lior Cohen (ThinkWise Consulting)' AND d.name = 'Perdido- Phase 2'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Lior Cohen (ThinkWise Consulting)","deal_name":"Sarasota","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Lior Cohen (ThinkWise Consulting)' AND d.name = 'Sarasota'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Lior Cohen (ThinkWise Consulting)","deal_name":"Westgate","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Lior Cohen (ThinkWise Consulting)' AND d.name = 'Westgate'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Lior Stinus (Freidkes & Co. CPA)","deal_name":"310 Tyson-Draft","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Lior Stinus (Freidkes & Co. CPA)' AND d.name = '310 Tyson-Draft'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Lior Stinus (Freidkes & Co. CPA)","deal_name":"Hudson Heritage","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Lior Stinus (Freidkes & Co. CPA)' AND d.name = 'Hudson Heritage'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Lior Stinus (פריידקס)","deal_name":"Aventine, Riverside","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Lior Stinus (פריידקס)' AND d.name = 'Aventine, Riverside'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Lior Stinus (פריידקס)","deal_name":"Cheshire","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Lior Stinus (פריידקס)' AND d.name = 'Cheshire'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Logistic","deal_name":"CP Phase II","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Logistic' AND d.name = 'CP Phase II'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Logistic","deal_name":"Duncen","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Logistic' AND d.name = 'Duncen'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Logistic","deal_name":"Meadows","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Logistic' AND d.name = 'Meadows'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Logistic","deal_name":"Metro","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Logistic' AND d.name = 'Metro'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Meirav Dvash","deal_name":"Highline","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Meirav Dvash' AND d.name = 'Highline'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Meirav Dvash","deal_name":"Hiram 2024","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Meirav Dvash' AND d.name = 'Hiram 2024'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Meirav Dvash","deal_name":"Hoschton IL","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Meirav Dvash' AND d.name = 'Hoschton IL'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Meirav Dvash","deal_name":"Ledge Rock","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Meirav Dvash' AND d.name = 'Ledge Rock'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Meirav Dvash","deal_name":"Sarasota","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Meirav Dvash' AND d.name = 'Sarasota'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Michael Tsukerman","deal_name":"Christina Mill","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Michael Tsukerman' AND d.name = 'Christina Mill'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"NLA Property Sales LLC","deal_name":"Ledge Rock","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'NLA Property Sales LLC' AND d.name = 'Ledge Rock'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"NLA Property Sales LLC","deal_name":"Sarasota","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'NLA Property Sales LLC' AND d.name = 'Sarasota'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Neto (ישן) Geller Finance - Global Investments LTD (איתו יש הסכם) - Elad Geler","deal_name":"Hudson Heritage","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Neto (ישן) Geller Finance - Global Investments LTD (איתו יש הסכם) - Elad Geler' AND d.name = 'Hudson Heritage'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Pearlman","deal_name":"Gainesville","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Pearlman' AND d.name = 'Gainesville'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Pini Ginsburg","deal_name":"Highline","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Pini Ginsburg' AND d.name = 'Highline'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Pini Ginsburg","deal_name":"MLL","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Pini Ginsburg' AND d.name = 'MLL'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Pioneer WM","deal_name":"Thatcher Woods","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Pioneer WM' AND d.name = 'Thatcher Woods'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Ran Goren","deal_name":"Hudson","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Ran Goren' AND d.name = 'Hudson'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Ran Goren","deal_name":"Ledge Rock","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Ran Goren' AND d.name = 'Ledge Rock'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Ran Ravid","deal_name":"Meadows","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Ran Ravid' AND d.name = 'Meadows'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Ronny Maliniak","deal_name":"Beaufort","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Ronny Maliniak' AND d.name = 'Beaufort'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Ronny Maliniak","deal_name":"Dry Creek","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Ronny Maliniak' AND d.name = 'Dry Creek'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Ronny Maliniak","deal_name":"Meadows","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Ronny Maliniak' AND d.name = 'Meadows'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Ronny Maliniak","deal_name":"Meitav Fund I","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Ronny Maliniak' AND d.name = 'Meitav Fund I'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Ronny Maliniak","deal_name":"Milagro","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Ronny Maliniak' AND d.name = 'Milagro'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Ronny Maliniak","deal_name":"Oak Brook","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Ronny Maliniak' AND d.name = 'Oak Brook'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Ronny Maliniak","deal_name":"Osceola","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Ronny Maliniak' AND d.name = 'Osceola'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Ronny Maliniak","deal_name":"Thatcher Woods","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Ronny Maliniak' AND d.name = 'Thatcher Woods'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Ronny Maliniak","deal_name":"Walden","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Ronny Maliniak' AND d.name = 'Walden'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Roy Gold","deal_name":"1000 Crosby","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Roy Gold' AND d.name = '1000 Crosby'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Roy Gold","deal_name":"2840 Orange","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Roy Gold' AND d.name = '2840 Orange'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Roy Gold","deal_name":"Hartford Corners","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Roy Gold' AND d.name = 'Hartford Corners'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Roy Gold","deal_name":"Mason","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Roy Gold' AND d.name = 'Mason'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Roy Gold","deal_name":"Oakwood","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Roy Gold' AND d.name = 'Oakwood'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Roy Gold","deal_name":"Reems Creek","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Roy Gold' AND d.name = 'Reems Creek'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Rubin Schlussel (אוטופיה 18)","deal_name":"100 City View","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Rubin Schlussel (אוטופיה 18)' AND d.name = '100 City View'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Rubin Schlussel (אוטופיה 18)","deal_name":"1000 Crosby","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Rubin Schlussel (אוטופיה 18)' AND d.name = '1000 Crosby'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Rubin Schlussel (אוטופיה 18)","deal_name":"310 Tyson-Draft","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Rubin Schlussel (אוטופיה 18)' AND d.name = '310 Tyson-Draft'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Rubin Schlussel (אוטופיה 18)","deal_name":"CP Phase II","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Rubin Schlussel (אוטופיה 18)' AND d.name = 'CP Phase II'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Rubin Schlussel (אוטופיה 18)","deal_name":"Christina mill","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Rubin Schlussel (אוטופיה 18)' AND d.name = 'Christina mill'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Rubin Schlussel (אוטופיה 18)","deal_name":"Classic city","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Rubin Schlussel (אוטופיה 18)' AND d.name = 'Classic city'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Rubin Schlussel (אוטופיה 18)","deal_name":"Crescent","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Rubin Schlussel (אוטופיה 18)' AND d.name = 'Crescent'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Rubin Schlussel (אוטופיה 18)","deal_name":"Dry Creek","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Rubin Schlussel (אוטופיה 18)' AND d.name = 'Dry Creek'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Rubin Schlussel (אוטופיה 18)","deal_name":"East Hennepin","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Rubin Schlussel (אוטופיה 18)' AND d.name = 'East Hennepin'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Rubin Schlussel (אוטופיה 18)","deal_name":"Encore","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Rubin Schlussel (אוטופיה 18)' AND d.name = 'Encore'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Rubin Schlussel (אוטופיה 18)","deal_name":"Enterprise","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Rubin Schlussel (אוטופיה 18)' AND d.name = 'Enterprise'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Rubin Schlussel (אוטופיה 18)","deal_name":"FoxBank","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Rubin Schlussel (אוטופיה 18)' AND d.name = 'FoxBank'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Rubin Schlussel (אוטופיה 18)","deal_name":"Groton","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Rubin Schlussel (אוטופיה 18)' AND d.name = 'Groton'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Rubin Schlussel (אוטופיה 18)","deal_name":"Hiram 2024","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Rubin Schlussel (אוטופיה 18)' AND d.name = 'Hiram 2024'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Rubin Schlussel (אוטופיה 18)","deal_name":"Milagro","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Rubin Schlussel (אוטופיה 18)' AND d.name = 'Milagro'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Rubin Schlussel (אוטופיה 18)","deal_name":"Oak Brook","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Rubin Schlussel (אוטופיה 18)' AND d.name = 'Oak Brook'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Rubin Schlussel (אוטופיה 18)","deal_name":"Oakwood","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Rubin Schlussel (אוטופיה 18)' AND d.name = 'Oakwood'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Rubin Schlussel (אוטופיה 18)","deal_name":"Osceola","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Rubin Schlussel (אוטופיה 18)' AND d.name = 'Osceola'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Rubin Schlussel (אוטופיה 18)","deal_name":"Perdido","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Rubin Schlussel (אוטופיה 18)' AND d.name = 'Perdido'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Rubin Schlussel (אוטופיה 18)","deal_name":"Perdido- Phase 2","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Rubin Schlussel (אוטופיה 18)' AND d.name = 'Perdido- Phase 2'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Rubin Schlussel (אוטופיה 18)","deal_name":"Red Willow","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Rubin Schlussel (אוטופיה 18)' AND d.name = 'Red Willow'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Rubin Schlussel (אוטופיה 18)","deal_name":"River Ridge 2023","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Rubin Schlussel (אוטופיה 18)' AND d.name = 'River Ridge 2023'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Rubin Schlussel (אוטופיה 18)","deal_name":"Riverwood","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Rubin Schlussel (אוטופיה 18)' AND d.name = 'Riverwood'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Rubin Schlussel (אוטופיה 18)","deal_name":"Sarasota","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Rubin Schlussel (אוטופיה 18)' AND d.name = 'Sarasota'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Rubin Schlussel (אוטופיה 18)","deal_name":"Sugarloaf","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Rubin Schlussel (אוטופיה 18)' AND d.name = 'Sugarloaf'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Rubin Schlussel (אוטופיה 18)","deal_name":"Thatcher Woods","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Rubin Schlussel (אוטופיה 18)' AND d.name = 'Thatcher Woods'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Rubin Schlussel (אוטופיה 18)","deal_name":"Tree trail","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Rubin Schlussel (אוטופיה 18)' AND d.name = 'Tree trail'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Rubin Schlussel (אוטופיה 18)","deal_name":"Urbandale","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Rubin Schlussel (אוטופיה 18)' AND d.name = 'Urbandale'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Rubin Schlussel (אוטופיה 18)","deal_name":"Vine","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Rubin Schlussel (אוטופיה 18)' AND d.name = 'Vine'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"SRI Global Group (מועדון השקעות חברתיות)","deal_name":"Dry Creek","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'SRI Global Group (מועדון השקעות חברתיות)' AND d.name = 'Dry Creek'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"SRI Global Group (מועדון השקעות חברתיות)","deal_name":"Meitav Fund","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'SRI Global Group (מועדון השקעות חברתיות)' AND d.name = 'Meitav Fund'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"SRI Global Group (מועדון השקעות חברתיות)","deal_name":"Snellville","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'SRI Global Group (מועדון השקעות חברתיות)' AND d.name = 'Snellville'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Shai Sheffer (DGTA)","deal_name":"Neely","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Shai Sheffer (DGTA)' AND d.name = 'Neely'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Shai Sheffer (DGTA)","deal_name":"Neely Phase II","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Shai Sheffer (DGTA)' AND d.name = 'Neely Phase II'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Shai Sheffer (DGTA)","deal_name":"River Ridge","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Shai Sheffer (DGTA)' AND d.name = 'River Ridge'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Shai Sheffer (DGTA)","deal_name":"Tree Trail","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Shai Sheffer (DGTA)' AND d.name = 'Tree Trail'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Shai Sheffer (DGTA)","deal_name":"White house","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Shai Sheffer (DGTA)' AND d.name = 'White house'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Shai Sheffer (DGTA) + (MTRA)","deal_name":"Antioch","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Shai Sheffer (DGTA) + (MTRA)' AND d.name = 'Antioch'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Shai Sheffer (DGTA) + (MTRA)","deal_name":"CP Phase II","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Shai Sheffer (DGTA) + (MTRA)' AND d.name = 'CP Phase II'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Shai Sheffer (DGTA) + (MTRA)","deal_name":"Christina","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Shai Sheffer (DGTA) + (MTRA)' AND d.name = 'Christina'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Shai Sheffer (DGTA) + (MTRA)","deal_name":"Crescent","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Shai Sheffer (DGTA) + (MTRA)' AND d.name = 'Crescent'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Shai Sheffer (DGTA) + (MTRA)","deal_name":"Duncan","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Shai Sheffer (DGTA) + (MTRA)' AND d.name = 'Duncan'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Shai Sheffer (DGTA) + (MTRA)","deal_name":"Lafayette","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Shai Sheffer (DGTA) + (MTRA)' AND d.name = 'Lafayette'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Shai Sheffer (DGTA) + (MTRA)","deal_name":"Meadows","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Shai Sheffer (DGTA) + (MTRA)' AND d.name = 'Meadows'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Shai Sheffer (DGTA) + (MTRA)","deal_name":"Milagro","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Shai Sheffer (DGTA) + (MTRA)' AND d.name = 'Milagro'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Shai Sheffer (DGTA) + (MTRA)","deal_name":"Osceola","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Shai Sheffer (DGTA) + (MTRA)' AND d.name = 'Osceola'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Shai Sheffer (DGTA) + (MTRA)","deal_name":"Retreat at Weaverville","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Shai Sheffer (DGTA) + (MTRA)' AND d.name = 'Retreat at Weaverville'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Shai Sheffer (DGTA) + (MTRA)","deal_name":"River Ridge","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Shai Sheffer (DGTA) + (MTRA)' AND d.name = 'River Ridge'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Shai Sheffer (DGTA) + (MTRA)","deal_name":"White House","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Shai Sheffer (DGTA) + (MTRA)' AND d.name = 'White House'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Shai Sheffer (MTRA)","deal_name":"River Ridge","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Shai Sheffer (MTRA)' AND d.name = 'River Ridge'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Shai Sheffer (MTRA)","deal_name":"Tree Trail","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Shai Sheffer (MTRA)' AND d.name = 'Tree Trail'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Sheara Einhorn","deal_name":"Cheshire","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Sheara Einhorn' AND d.name = 'Cheshire'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Sheara Einhorn","deal_name":"MLL","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Sheara Einhorn' AND d.name = 'MLL'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Sheara Einhorn","deal_name":"Perdido","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Sheara Einhorn' AND d.name = 'Perdido'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Sheara Einhorn","deal_name":"Perdido- Phase 2","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Sheara Einhorn' AND d.name = 'Perdido- Phase 2'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Sparta Capital- Yonel Dvash","deal_name":"Fitzroy","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Sparta Capital- Yonel Dvash' AND d.name = 'Fitzroy'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Sparta Capital- Yonel Dvash","deal_name":"Fitzroy Townhomes","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Sparta Capital- Yonel Dvash' AND d.name = 'Fitzroy Townhomes'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Even","deal_name":"1010 Midtown","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Even' AND d.name = '1010 Midtown'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Even","deal_name":"Cheshire","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Even' AND d.name = 'Cheshire'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Even","deal_name":"Classic city","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Even' AND d.name = 'Classic city'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Even","deal_name":"Huntsville","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Even' AND d.name = 'Huntsville'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Even","deal_name":"Mason","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Even' AND d.name = 'Mason'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Even","deal_name":"McGaw","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Even' AND d.name = 'McGaw'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Even","deal_name":"Osceola","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Even' AND d.name = 'Osceola'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Even","deal_name":"Red Willow","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Even' AND d.name = 'Red Willow'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Even","deal_name":"Roswell","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Even' AND d.name = 'Roswell'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Even","deal_name":"Tyson","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Even' AND d.name = 'Tyson'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Even","deal_name":"Westgate","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Even' AND d.name = 'Westgate'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Simchony","deal_name":"(סה"כ מקובץ נפרד)","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Simchony' AND d.name = '(סה"כ מקובץ נפרד)'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Simchony","deal_name":"100 City View","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Simchony' AND d.name = '100 City View'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Simchony","deal_name":"1000 Crosby","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Simchony' AND d.name = '1000 Crosby'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Simchony","deal_name":"6501 Nevada","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Simchony' AND d.name = '6501 Nevada'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Simchony","deal_name":"Antioch (IRA Fund I)","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Simchony' AND d.name = 'Antioch (IRA Fund I)'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Simchony","deal_name":"Bay Road (Carolina Bay)","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Simchony' AND d.name = 'Bay Road (Carolina Bay)'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Simchony","deal_name":"Berwick","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Simchony' AND d.name = 'Berwick'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Simchony","deal_name":"Brentwood","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Simchony' AND d.name = 'Brentwood'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Simchony","deal_name":"Cheshire","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Simchony' AND d.name = 'Cheshire'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Simchony","deal_name":"Classic city","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Simchony' AND d.name = 'Classic city'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Simchony","deal_name":"Dry Creek","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Simchony' AND d.name = 'Dry Creek'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Simchony","deal_name":"Dry Creek- IRA","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Simchony' AND d.name = 'Dry Creek- IRA'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Simchony","deal_name":"Fitzroy","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Simchony' AND d.name = 'Fitzroy'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Simchony","deal_name":"Fitzroy Townhomes","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Simchony' AND d.name = 'Fitzroy Townhomes'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Simchony","deal_name":"Gainesville 2023","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Simchony' AND d.name = 'Gainesville 2023'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Simchony","deal_name":"Heandersonville","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Simchony' AND d.name = 'Heandersonville'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Simchony","deal_name":"Hiram 2024","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Simchony' AND d.name = 'Hiram 2024'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Simchony","deal_name":"Hoschton IL","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Simchony' AND d.name = 'Hoschton IL'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Simchony","deal_name":"Hudson Heritage","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Simchony' AND d.name = 'Hudson Heritage'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Simchony","deal_name":"Johnstown","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Simchony' AND d.name = 'Johnstown'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Simchony","deal_name":"Ledge Rock","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Simchony' AND d.name = 'Ledge Rock'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Simchony","deal_name":"Mason","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Simchony' AND d.name = 'Mason'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Simchony","deal_name":"Milagro","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Simchony' AND d.name = 'Milagro'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Simchony","deal_name":"Milagro (IRA Fund II)","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Simchony' AND d.name = 'Milagro (IRA Fund II)'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Simchony","deal_name":"Osceola (IRA Fund II)","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Simchony' AND d.name = 'Osceola (IRA Fund II)'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Simchony","deal_name":"Perdido","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Simchony' AND d.name = 'Perdido'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Simchony","deal_name":"Perdido- Phase 2","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Simchony' AND d.name = 'Perdido- Phase 2'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Simchony","deal_name":"Reems Creek","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Simchony' AND d.name = 'Reems Creek'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Simchony","deal_name":"River Ridge 2023","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Simchony' AND d.name = 'River Ridge 2023'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Simchony","deal_name":"Riverwood","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Simchony' AND d.name = 'Riverwood'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Simchony","deal_name":"Statesboro","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Simchony' AND d.name = 'Statesboro'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Simchony","deal_name":"Sugarloaf","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Simchony' AND d.name = 'Sugarloaf'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Simchony","deal_name":"סה"כ Accquisition Fee מקובץ מרוכז","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Simchony' AND d.name = 'סה"כ Accquisition Fee מקובץ מרוכז'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Simchony","deal_name":"סה"כ Assets management fee מקובץ מרוכז","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Simchony' AND d.name = 'סה"כ Assets management fee מקובץ מרוכז'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tal Simchony","deal_name":"סה"כ Promote מקובץ מרוכז","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tal Simchony' AND d.name = 'סה"כ Promote מקובץ מרוכז'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"TanzerVest LLC","deal_name":"MLL","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'TanzerVest LLC' AND d.name = 'MLL'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"TanzerVest LLC - Andrew Tanzer","deal_name":"1302 Eastport","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'TanzerVest LLC - Andrew Tanzer' AND d.name = '1302 Eastport'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"TanzerVest LLC - Andrew Tanzer","deal_name":"310 Tyson-Draft","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'TanzerVest LLC - Andrew Tanzer' AND d.name = '310 Tyson-Draft'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"TanzerVest LLC - Andrew Tanzer","deal_name":"Hiram 2024","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'TanzerVest LLC - Andrew Tanzer' AND d.name = 'Hiram 2024'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"TanzerVest LLC - Andrew Tanzer","deal_name":"Hoschton IL","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'TanzerVest LLC - Andrew Tanzer' AND d.name = 'Hoschton IL'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"TanzerVest LLC - Andrew Tanzer","deal_name":"Hudson Heritage","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'TanzerVest LLC - Andrew Tanzer' AND d.name = 'Hudson Heritage'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"TanzerVest LLC - Andrew Tanzer","deal_name":"Ledge Rock","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'TanzerVest LLC - Andrew Tanzer' AND d.name = 'Ledge Rock'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"TanzerVest LLC - Andrew Tanzer","deal_name":"Statesboro","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'TanzerVest LLC - Andrew Tanzer' AND d.name = 'Statesboro'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"TanzerVest LLC - Andrew Tanzer","deal_name":"Sugarloaf","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'TanzerVest LLC - Andrew Tanzer' AND d.name = 'Sugarloaf'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"TanzerVest LLC - Andrew Tanzer","deal_name":"Sugarloaf +
 Hudson Heritage","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'TanzerVest LLC - Andrew Tanzer' AND d.name = 'Sugarloaf +
 Hudson Heritage'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"The Service","deal_name":"Hickory Flat","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'The Service' AND d.name = 'Hickory Flat'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tsukerman","deal_name":"Metro","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tsukerman' AND d.name = 'Metro'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tsukerman (Promote Due)","deal_name":"Antioch","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tsukerman (Promote Due)' AND d.name = 'Antioch'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tsukerman (Promote Due)","deal_name":"Christina","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tsukerman (Promote Due)' AND d.name = 'Christina'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tzafit Pension Insurance Agency (2023) Ltd","deal_name":"Hudson Heritage","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tzafit Pension Insurance Agency (2023) Ltd' AND d.name = 'Hudson Heritage'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tzafit Pension Insurance Agency (2023) Ltd","deal_name":"Mason","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tzafit Pension Insurance Agency (2023) Ltd' AND d.name = 'Mason'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Tzafit Pension Insurance Agency (2023) Ltd","deal_name":"Statesboro","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Tzafit Pension Insurance Agency (2023) Ltd' AND d.name = 'Statesboro'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Unique Insurance Agency (2018) Ltd","deal_name":"Riverwood","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Unique Insurance Agency (2018) Ltd' AND d.name = 'Riverwood'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Uri Golani","deal_name":"1000 Crosby","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Uri Golani' AND d.name = '1000 Crosby'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Uri Golani","deal_name":"Hoschton IL","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Uri Golani' AND d.name = 'Hoschton IL'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Uri Golani","deal_name":"Ledge Rock","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Uri Golani' AND d.name = 'Ledge Rock'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Uri Golani","deal_name":"Oakwood","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Uri Golani' AND d.name = 'Oakwood'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Uri Golani","deal_name":"Reems Creek","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Uri Golani' AND d.name = 'Reems Creek'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Uri Golani","deal_name":"Statesboro","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Uri Golani' AND d.name = 'Statesboro'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Uri Golani","deal_name":"Sugarloaf","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Uri Golani' AND d.name = 'Sugarloaf'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Vendor / Distributor","deal_name":"Details","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Vendor / Distributor' AND d.name = 'Details'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)","deal_name":"310 Tyson-Draft","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)' AND d.name = '310 Tyson-Draft'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)","deal_name":"Antioch","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)' AND d.name = 'Antioch'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)","deal_name":"Antioch (IRA Fund I)","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)' AND d.name = 'Antioch (IRA Fund I)'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)","deal_name":"Bay Road (Carolina Bay)","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)' AND d.name = 'Bay Road (Carolina Bay)'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)","deal_name":"Brentwood","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)' AND d.name = 'Brentwood'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)","deal_name":"Classic city","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)' AND d.name = 'Classic city'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)","deal_name":"Dry Creek","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)' AND d.name = 'Dry Creek'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)","deal_name":"East Hennepin","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)' AND d.name = 'East Hennepin'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)","deal_name":"Heandersonville","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)' AND d.name = 'Heandersonville'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)","deal_name":"Hoschton IL","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)' AND d.name = 'Hoschton IL'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)","deal_name":"Mason","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)' AND d.name = 'Mason'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)","deal_name":"Milagro (IRA Fund II)","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)' AND d.name = 'Milagro (IRA Fund II)'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)","deal_name":"Oak Brook","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)' AND d.name = 'Oak Brook'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)","deal_name":"Oakwood","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)' AND d.name = 'Oakwood'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)","deal_name":"Osceola (IRA Fund II)","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)' AND d.name = 'Osceola (IRA Fund II)'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)","deal_name":"Reems Creek","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)' AND d.name = 'Reems Creek'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)","deal_name":"River Ridge 2023","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)' AND d.name = 'River Ridge 2023'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)","deal_name":"Sarasota","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)' AND d.name = 'Sarasota'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)","deal_name":"Sugarloaf","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)' AND d.name = 'Sugarloaf'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)","deal_name":"Thatcher Woods","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Wiser Finance- Michael Mann (ויזר קרנות אלטרנטיביות)' AND d.name = 'Thatcher Woods'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"YL Consulting Inc","deal_name":"Highline","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'YL Consulting Inc' AND d.name = 'Highline'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"YL Consulting Inc","deal_name":"Ledge Rock","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'YL Consulting Inc' AND d.name = 'Ledge Rock'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"YL Consulting Inc (Yoav Lachover)","deal_name":"100 City View","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'YL Consulting Inc (Yoav Lachover)' AND d.name = '100 City View'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"YL Consulting Inc (Yoav Lachover)","deal_name":"1000 Crosby","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'YL Consulting Inc (Yoav Lachover)' AND d.name = '1000 Crosby'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"YL Consulting Inc (Yoav Lachover)","deal_name":"310 Tyson-Draft","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'YL Consulting Inc (Yoav Lachover)' AND d.name = '310 Tyson-Draft'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"YL Consulting Inc (Yoav Lachover)","deal_name":"9231 Penn Ave","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'YL Consulting Inc (Yoav Lachover)' AND d.name = '9231 Penn Ave'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"YL Consulting Inc (Yoav Lachover)","deal_name":"Dry Creek","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'YL Consulting Inc (Yoav Lachover)' AND d.name = 'Dry Creek'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"YL Consulting Inc (Yoav Lachover)","deal_name":"East Hennepin","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'YL Consulting Inc (Yoav Lachover)' AND d.name = 'East Hennepin'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"YL Consulting Inc (Yoav Lachover)","deal_name":"Fitzroy","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'YL Consulting Inc (Yoav Lachover)' AND d.name = 'Fitzroy'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"YL Consulting Inc (Yoav Lachover)","deal_name":"Fitzroy Townhomes","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'YL Consulting Inc (Yoav Lachover)' AND d.name = 'Fitzroy Townhomes'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"YL Consulting Inc (Yoav Lachover)","deal_name":"Gainesville 2023","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'YL Consulting Inc (Yoav Lachover)' AND d.name = 'Gainesville 2023'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"YL Consulting Inc (Yoav Lachover)","deal_name":"Heandersonville","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'YL Consulting Inc (Yoav Lachover)' AND d.name = 'Heandersonville'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"YL Consulting Inc (Yoav Lachover)","deal_name":"Hiram 2024","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'YL Consulting Inc (Yoav Lachover)' AND d.name = 'Hiram 2024'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"YL Consulting Inc (Yoav Lachover)","deal_name":"Hoschton IL","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'YL Consulting Inc (Yoav Lachover)' AND d.name = 'Hoschton IL'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"YL Consulting Inc (Yoav Lachover)","deal_name":"Johnstown","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'YL Consulting Inc (Yoav Lachover)' AND d.name = 'Johnstown'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"YL Consulting Inc (Yoav Lachover)","deal_name":"MLL","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'YL Consulting Inc (Yoav Lachover)' AND d.name = 'MLL'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"YL Consulting Inc (Yoav Lachover)","deal_name":"Mason","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'YL Consulting Inc (Yoav Lachover)' AND d.name = 'Mason'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"YL Consulting Inc (Yoav Lachover)","deal_name":"Milagro","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'YL Consulting Inc (Yoav Lachover)' AND d.name = 'Milagro'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"YL Consulting Inc (Yoav Lachover)","deal_name":"Oakwood","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'YL Consulting Inc (Yoav Lachover)' AND d.name = 'Oakwood'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"YL Consulting Inc (Yoav Lachover)","deal_name":"Perdido","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'YL Consulting Inc (Yoav Lachover)' AND d.name = 'Perdido'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"YL Consulting Inc (Yoav Lachover)","deal_name":"Perdido- Phase 2","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'YL Consulting Inc (Yoav Lachover)' AND d.name = 'Perdido- Phase 2'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"YL Consulting Inc (Yoav Lachover)","deal_name":"River Ridge 2023","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'YL Consulting Inc (Yoav Lachover)' AND d.name = 'River Ridge 2023'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"YL Consulting Inc (Yoav Lachover)","deal_name":"Statesboro","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'YL Consulting Inc (Yoav Lachover)' AND d.name = 'Statesboro'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yariv Avrahami","deal_name":"Hartford Corners","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yariv Avrahami' AND d.name = 'Hartford Corners'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yariv Avrahami","deal_name":"Osborne","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yariv Avrahami' AND d.name = 'Osborne'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yariv Avrahami","deal_name":"Tyde","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yariv Avrahami' AND d.name = 'Tyde'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yariv Avrahami","deal_name":"Via","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yariv Avrahami' AND d.name = 'Via'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoav Holzer (IKAGI דרך לצמיחה-עמלה בגין ארז וענת ברזילי)","deal_name":"6501 Nevada","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoav Holzer (IKAGI דרך לצמיחה-עמלה בגין ארז וענת ברזילי)' AND d.name = '6501 Nevada'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoav Holzer (יתיאלה השקעות בעמ)","deal_name":"Heandersonville","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoav Holzer (יתיאלה השקעות בעמ)' AND d.name = 'Heandersonville'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoav Holzer (יתיאלה השקעות בעמ)","deal_name":"Tyde","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoav Holzer (יתיאלה השקעות בעמ)' AND d.name = 'Tyde'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoel Stark","deal_name":"East Hennepin","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoel Stark' AND d.name = 'East Hennepin'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Dvash -Fresh Properties","deal_name":"CP Phase II","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Dvash -Fresh Properties' AND d.name = 'CP Phase II'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Dvash -Fresh Properties","deal_name":"Crescent","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Dvash -Fresh Properties' AND d.name = 'Crescent'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Dvash -Fresh Properties","deal_name":"Lafayette","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Dvash -Fresh Properties' AND d.name = 'Lafayette'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Dvash -Fresh Properties","deal_name":"Metro","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Dvash -Fresh Properties' AND d.name = 'Metro'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Dvash -Fresh Properties","deal_name":"Milagro","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Dvash -Fresh Properties' AND d.name = 'Milagro'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Dvash -Fresh Properties","deal_name":"Retreat at Weaverville","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Dvash -Fresh Properties' AND d.name = 'Retreat at Weaverville'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Dvash -Fresh Properties","deal_name":"Walden","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Dvash -Fresh Properties' AND d.name = 'Walden'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Dvash -Fresh Properties (Promote)","deal_name":"Ascent","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Dvash -Fresh Properties (Promote)' AND d.name = 'Ascent'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Shalit","deal_name":"100 City View","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Shalit' AND d.name = '100 City View'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Shalit","deal_name":"1000 Crosby","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Shalit' AND d.name = '1000 Crosby'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Shalit","deal_name":"201 Triple Diamond","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Shalit' AND d.name = '201 Triple Diamond'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Shalit","deal_name":"310 Tyson-Draft","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Shalit' AND d.name = '310 Tyson-Draft'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Shalit","deal_name":"Antioch","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Shalit' AND d.name = 'Antioch'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Shalit","deal_name":"Christina","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Shalit' AND d.name = 'Christina'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Shalit","deal_name":"Duncen","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Shalit' AND d.name = 'Duncen'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Shalit","deal_name":"East Hennepin","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Shalit' AND d.name = 'East Hennepin'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Shalit","deal_name":"Fairview","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Shalit' AND d.name = 'Fairview'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Shalit","deal_name":"Fairview Village","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Shalit' AND d.name = 'Fairview Village'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Shalit","deal_name":"Gainesville","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Shalit' AND d.name = 'Gainesville'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Shalit","deal_name":"Groton","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Shalit' AND d.name = 'Groton'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Shalit","deal_name":"Hartford Corners","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Shalit' AND d.name = 'Hartford Corners'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Shalit","deal_name":"Highline","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Shalit' AND d.name = 'Highline'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Shalit","deal_name":"Hoschton IL","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Shalit' AND d.name = 'Hoschton IL'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Shalit","deal_name":"Hudson Heritage","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Shalit' AND d.name = 'Hudson Heritage'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Shalit","deal_name":"Ledge Rock","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Shalit' AND d.name = 'Ledge Rock'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Shalit","deal_name":"McGaw","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Shalit' AND d.name = 'McGaw'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Shalit","deal_name":"Metro","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Shalit' AND d.name = 'Metro'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Shalit","deal_name":"Neely","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Shalit' AND d.name = 'Neely'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Shalit","deal_name":"Neely Phase II","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Shalit' AND d.name = 'Neely Phase II'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Shalit","deal_name":"Perdido","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Shalit' AND d.name = 'Perdido'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Shalit","deal_name":"Perdido- Phase 2","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Shalit' AND d.name = 'Perdido- Phase 2'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Shalit","deal_name":"Reems Creek","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Shalit' AND d.name = 'Reems Creek'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Shalit","deal_name":"River Ridge 2023 IRA Fund","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Shalit' AND d.name = 'River Ridge 2023 IRA Fund'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Shalit","deal_name":"Riverside","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Shalit' AND d.name = 'Riverside'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Shalit","deal_name":"Ryans Crossing","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Shalit' AND d.name = 'Ryans Crossing'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Shalit","deal_name":"Snellville","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Shalit' AND d.name = 'Snellville'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Shalit","deal_name":"Thatcher Woods","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Shalit' AND d.name = 'Thatcher Woods'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Shalit","deal_name":"Tree Trail","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Shalit' AND d.name = 'Tree Trail'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Shalit","deal_name":"Westgate","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Shalit' AND d.name = 'Westgate'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Yoram Shalit","deal_name":"Winters Creek","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"on_top","vat_rate":0.17}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Yoram Shalit' AND d.name = 'Winters Creek'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Zell","deal_name":"Christina","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Zell' AND d.name = 'Christina'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Zell","deal_name":"Fairview","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Zell' AND d.name = 'Fairview'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Zell","deal_name":"Fairview Village","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Zell' AND d.name = 'Fairview Village'
ON CONFLICT DO NOTHING;

INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)
SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '{"kind":"distributor_commission","party_name":"Zell","deal_name":"Lafayette","terms":[{"from":"2020-01-01","to":NULL,"rate_bps":100,"vat_mode":"included","vat_rate":0.0}]}'::jsonb, now(), now()
FROM parties p CROSS JOIN deals d
WHERE p.name = 'Zell' AND d.name = 'Lafayette'
ON CONFLICT DO NOTHING;

-- STEP 4: Import Contributions

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 10890.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = '310 Tyson Drive GP LLC' AND d.name = '310 Tyson Drive Operating LP'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 150000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Aaron Shenhar' AND d.name = '9231 Penn Avenue'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 250000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Abraham Fuchs' AND d.name = 'Arcadia'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 400000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Abraham Fuchs' AND d.name = 'Ascent 430'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 50000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Abraham Raz' AND d.name = '10793 Harry Hines'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 100000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Adam Gotskind' AND d.name = '201 Triple Diamond'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 200000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Adi Danon' AND d.name = '571 Commerce'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 250000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Adi Danon' AND d.name = 'Aventine'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 25000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Adi Grinberg' AND d.name = '100 City View Buligo LP'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 20000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Adi Grinberg' AND d.name = '201 Triple Diamond'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 100000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Adi Zwickel' AND d.name = '814 Commerce Drive'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 25000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Adi_Relatives' AND d.name = '100 City View Buligo LP'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 20000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Adi_Relatives' AND d.name = '201 Triple Diamond'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 200000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Adina Grinberg' AND d.name = '1010 Midtown'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 200000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Adina Grinberg' AND d.name = 'Aventine'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 150000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Aharon Ezra' AND d.name = '310 Tyson Drive'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 40000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Aharon Rasouli' AND d.name = '1000 W Crosby'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 100000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Ajay Shah' AND d.name = '201 Triple Diamond'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 2607765.79, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Albert Milstein' AND d.name = '5949 Jackson Road'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 250000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Alex Bernstein' AND d.name = '10793 Harry Hines'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 250000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Alex Bernstein' AND d.name = '310 Tyson Drive'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 250000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Alex Bernstein' AND d.name = '9231 Penn Avenue'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 250000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Alex Bernstein' AND d.name = 'Aventine'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 110000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Alex Gurevich' AND d.name = '100 City View Buligo LP'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 75000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Alex Gurevich' AND d.name = '201 Triple Diamond'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 50000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Alexander Partin' AND d.name = '2840 W Orange Ave'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 100000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Alexandra Barth' AND d.name = 'Autumn Ridge'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 100000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Aline Ajami Atzmon' AND d.name = '1000 W Crosby'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 50000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Almog Shimon' AND d.name = '1000 W Crosby'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 50000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Alon Ascher' AND d.name = '1000 W Crosby'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 50000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Alon Buch' AND d.name = '814 Commerce Drive'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 300000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Alon Ginsburg' AND d.name = '1000 W Crosby'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 300000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Alon Ginsburg' AND d.name = '10793 Harry Hines'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 150000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Alon Ginsburg' AND d.name = '5 East Pointe Drive'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 122700.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Alon Haramati' AND d.name = '100 City View Buligo LP'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 21200.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Alon Haramati' AND d.name = '1000 W Crosby'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 21000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Alon Haramati' AND d.name = '1010 Midtown'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 20800.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Alon Haramati' AND d.name = '10793 Harry Hines'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 21800.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Alon Haramati' AND d.name = '1302 Eastport Road'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 30300.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Alon Haramati' AND d.name = '201 Triple Diamond'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 20600.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Alon Haramati' AND d.name = '2840 W Orange Ave'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 22100.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Alon Haramati' AND d.name = '310 Tyson Drive'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 21400.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Alon Haramati' AND d.name = '5 East Pointe Drive'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 78000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Alon Haramati' AND d.name = '571 Commerce'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 43000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Alon Haramati' AND d.name = '6501 Nevada'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 30000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Alon Haramati' AND d.name = '9231 Penn Avenue'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 38000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Alon Haramati' AND d.name = 'Anchor Pointe'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 53000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Alon Haramati' AND d.name = 'Aventine'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 100000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Alon Lev Hertz' AND d.name = '100 City View Buligo LP'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 100000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Alon Lev Hertz' AND d.name = '310 Tyson Drive'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 50000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Alon Lev Hertz' AND d.name = 'Aventine'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 100000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Alon Piltz' AND d.name = '10793 Harry Hines'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 100000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Alon Piltz' AND d.name = 'Aventine'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 100000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Alon Pomeranc' AND d.name = '1000 W Crosby'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 150000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Alon Pomeranc' AND d.name = '1010 Midtown'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 100000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Alon Pomeranc' AND d.name = '9231 Penn Avenue'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 200000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Alon Pomeranc' AND d.name = 'Antioch'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 200000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Alon Reshef' AND d.name = '5 East Pointe Drive'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 250000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Alon Reshef' AND d.name = 'Anchor Pointe'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 300000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amichai Steimberg' AND d.name = 'Antioch'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 110000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amikam Sade' AND d.name = '310 Tyson Drive'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 100000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amikam Sade' AND d.name = 'Belaire Apartments'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 150000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amir Prescher' AND d.name = 'Ascent 430'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 100000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amir Prescher' AND d.name = 'Autumn Ridge'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 6700.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amir Prescher' AND d.name = 'Autumn Ridge Junior Loan'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 100000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amir Rimon' AND d.name = '131 Devoe'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 400000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amir Shapira' AND d.name = '100 City View Buligo LP'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 250000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amir Shapira' AND d.name = '1302 Eastport Road'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 250000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amir Shapira' AND d.name = '201 Triple Diamond'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 250000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amir Shapira' AND d.name = '310 Tyson Drive'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 350000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amir Shapira' AND d.name = '814 Commerce Drive'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 250000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amir Shapira' AND d.name = 'Antioch'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 235000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amir Shapira' AND d.name = 'Arcadia'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 200000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amir Shapira' AND d.name = 'Ascent 430'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 150000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amir Shinar' AND d.name = '160 West'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 21500.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amir Shinar' AND d.name = '160 West Member Loan'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 150000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amir Shinar' AND d.name = '193 Henry'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 75000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amir Shinar' AND d.name = 'Ashley Woods'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 150000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amir Shinar' AND d.name = 'Autumn Ridge'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 10000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amir Shinar' AND d.name = 'Autumn Ridge Junior Loan'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 100000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amir Shinar' AND d.name = 'Barceloneta'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 200000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amir Shinar' AND d.name = 'Belaire Apartments'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 50000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amiram Shore' AND d.name = '5 East Pointe Drive'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 150000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amiram Shore' AND d.name = '571 Commerce'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 100000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amiram Shore' AND d.name = '9231 Penn Avenue'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 200000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amit Forlit' AND d.name = '1010 Midtown'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 200000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amit Forlit' AND d.name = '814 Commerce Drive'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 100000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amit Forlit' AND d.name = 'Autumn Ridge'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 150000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amit Forlit' AND d.name = 'Belaire Apartments'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 75000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amit Gatenyo' AND d.name = 'Autumn Ridge'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 5000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amit Gatenyo' AND d.name = 'Autumn Ridge Junior Loan'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 100000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amit Gatenyo' AND d.name = 'Belaire Apartments'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 80000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amit Katz' AND d.name = '201 Triple Diamond'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 100000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amit Zeevi' AND d.name = '1010 Midtown'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 100000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amnon Duchovne Nave' AND d.name = '1010 Midtown'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 200000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amnon Duchovne Nave' AND d.name = '201 Triple Diamond'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 150000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amnon Duchovne Nave' AND d.name = 'Anchor Pointe'
ON CONFLICT DO NOTHING;

INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)
SELECT i.id, d.id, 100000.0, 'USD', '2020-01-01'::date, 'CONFIRMED', now(), now()
FROM investors i CROSS JOIN deals d
WHERE i.name = 'Amnon Kaydar' AND d.name = '100 City View Buligo LP'
ON CONFLICT DO NOTHING;

COMMIT;

-- Verification
SELECT 'Parties' as table_name, COUNT(*) as count FROM parties WHERE status = 'ACTIVE'
UNION ALL SELECT 'Investors', COUNT(*) FROM investors WHERE status = 'ACTIVE'
UNION ALL SELECT 'Agreements (Commission)', COUNT(*) FROM agreements WHERE kind = 'distributor_commission'
UNION ALL SELECT 'Contributions', COUNT(*) FROM contributions;
