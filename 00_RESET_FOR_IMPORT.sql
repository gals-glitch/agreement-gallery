-- ============================================================
-- RESET DATABASE FOR CSV IMPORT
-- ============================================================
-- WARNING: This deletes all existing data to prepare for fresh import
-- ============================================================

BEGIN;

-- Delete in correct cascade order (children first, parents last)
DELETE FROM commissions;
DELETE FROM charges;
DELETE FROM credits_ledger;
DELETE FROM investor_deal_participations;
DELETE FROM contributions;
DELETE FROM agreements;
DELETE FROM investors;
DELETE FROM parties WHERE id > 1;

-- Reset sequences (only for tables with BIGSERIAL PKs)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_sequences WHERE schemaname = 'public' AND sequencename = 'parties_id_seq') THEN
    PERFORM setval('parties_id_seq', COALESCE((SELECT MAX(id) FROM parties), 0) + 1, false);
  END IF;
  IF EXISTS (SELECT 1 FROM pg_sequences WHERE schemaname = 'public' AND sequencename = 'investors_id_seq') THEN
    PERFORM setval('investors_id_seq', 1, false);
  END IF;
  IF EXISTS (SELECT 1 FROM pg_sequences WHERE schemaname = 'public' AND sequencename = 'agreements_id_seq') THEN
    PERFORM setval('agreements_id_seq', 1, false);
  END IF;
  IF EXISTS (SELECT 1 FROM pg_sequences WHERE schemaname = 'public' AND sequencename = 'contributions_id_seq') THEN
    PERFORM setval('contributions_id_seq', 1, false);
  END IF;
END $$;

COMMIT;

-- Verification
SELECT 'Parties' as table_name, COUNT(*) as remaining FROM parties
UNION ALL SELECT 'Investors', COUNT(*) FROM investors
UNION ALL SELECT 'Agreements', COUNT(*) FROM agreements
UNION ALL SELECT 'Contributions', COUNT(*) FROM contributions
UNION ALL SELECT 'Investor Deal Participations', COUNT(*) FROM investor_deal_participations
UNION ALL SELECT 'Charges', COUNT(*) FROM charges
UNION ALL SELECT 'Credits Ledger', COUNT(*) FROM credits_ledger
UNION ALL SELECT 'Commissions', COUNT(*) FROM commissions;
