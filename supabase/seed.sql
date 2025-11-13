-- Seed Data for FundVI Fee Management System
-- This script creates sample data for development and testing
-- Safe to run multiple times (uses INSERT ... ON CONFLICT DO NOTHING)

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================
-- 1. Parties (Distributors, Referrers, Partners)
-- ==============================================

INSERT INTO public.parties (id, name, party_type, email, country, is_active, created_at)
VALUES
  ('11111111-1111-1111-1111-111111111111', 'Acme Distributors LLC', 'distributor', 'contact@acmedist.com', 'US', true, now()),
  ('22222222-2222-2222-2222-222222222222', 'GlobalRef Partners', 'referrer', 'info@globalref.com', 'IL', true, now()),
  ('33333333-3333-3333-3333-333333333333', 'Elite Capital Group', 'partner', 'hello@elitecap.com', 'UK', true, now())
ON CONFLICT (id) DO NOTHING;

-- ==============================================
-- 2. Funds
-- ==============================================

-- Insert Fund VI as a party (using parties table for funds)
INSERT INTO public.parties (id, name, party_type, email, is_active, created_at)
VALUES
  ('ffffffff-ffff-ffff-ffff-ffffffffffff', 'Buligo Fund VI', 'distributor', 'fund6@buligo.com', 'IL', true, now())
ON CONFLICT (id) DO NOTHING;

-- ==============================================
-- 3. Deals
-- ==============================================

INSERT INTO public.deals (id, name, code, fund_id, close_date, is_active, created_at)
VALUES
  ('dddddddd-0001-0001-0001-000000000001', 'Tech Acquisition Alpha', 'DEAL-ALPHA', 'ffffffff-ffff-ffff-ffff-ffffffffffff', '2025-01-15', true, now()),
  ('dddddddd-0002-0002-0002-000000000002', 'Healthcare Expansion', 'DEAL-BETA', 'ffffffff-ffff-ffff-ffff-ffffffffffff', '2025-03-01', true, now()),
  ('dddddddd-0003-0003-0003-000000000003', 'Real Estate Portfolio', 'DEAL-GAMMA', 'ffffffff-ffff-ffff-ffff-ffffffffffff', NULL, true, now())
ON CONFLICT (id) DO NOTHING;

-- ==============================================
-- 4. Fund VI Tracks (A/B/C)
-- ==============================================

-- These should already exist, but ensure they're there
INSERT INTO public.fund_vi_tracks (id, track_key, min_raised, max_raised, upfront_rate_bps, deferred_rate_bps, deferred_offset_months, config_version, is_active)
VALUES
  (uuid_generate_v4(), 'A', 0, 3000000, 120, 80, 24, 'v1.0', true),
  (uuid_generate_v4(), 'B', 3000000, 6000000, 180, 80, 24, 'v1.0', true),
  (uuid_generate_v4(), 'C', 6000000, NULL, 180, 130, 24, 'v1.0', true)
ON CONFLICT (track_key) WHERE is_active = true DO NOTHING;

-- ==============================================
-- 5. Agreements (FUND and DEAL scoped)
-- ==============================================

-- FUND-scoped agreements
INSERT INTO public.agreements (id, name, agreement_type, effective_from, effective_to, introduced_by_party_id, status, applies_scope, track_key, vat_mode, inherit_fund_rates, created_at)
VALUES
  ('aaaaaaaa-0001-0001-0001-000000000001', 'Acme Fund VI Agreement', 'distributor_fee', '2024-01-01', NULL, '11111111-1111-1111-1111-111111111111', 'active', 'FUND', 'A', 'added', true, now()),
  ('aaaaaaaa-0002-0002-0002-000000000002', 'GlobalRef Fund VI Agreement', 'referrer_fee', '2024-01-01', NULL, '22222222-2222-2222-2222-222222222222', 'active', 'FUND', 'B', 'included', true, now())
ON CONFLICT (id) DO NOTHING;

-- DEAL-scoped agreements (inherit rates)
INSERT INTO public.agreements (id, name, agreement_type, effective_from, effective_to, introduced_by_party_id, status, applies_scope, deal_id, track_key, vat_mode, inherit_fund_rates, created_at)
VALUES
  ('aaaaaaaa-0003-0003-0003-000000000003', 'Elite DEAL-ALPHA Agreement', 'partner_fee', '2024-12-01', NULL, '33333333-3333-3333-3333-333333333333', 'active', 'DEAL', 'dddddddd-0001-0001-0001-000000000001', 'B', 'added', true, now())
ON CONFLICT (id) DO NOTHING;

-- DEAL-scoped agreement (custom rates)
INSERT INTO public.agreements (id, name, agreement_type, effective_from, effective_to, introduced_by_party_id, status, applies_scope, deal_id, vat_mode, inherit_fund_rates, upfront_rate_bps, deferred_rate_bps, deferred_offset_months, created_at)
VALUES
  ('aaaaaaaa-0004-0004-0004-000000000004', 'Acme DEAL-BETA Custom Agreement', 'distributor_fee', '2025-02-01', NULL, '11111111-1111-1111-1111-111111111111', 'active', 'DEAL', 'dddddddd-0002-0002-0002-000000000002', 'added', false, 200, 100, 18, now())
ON CONFLICT (id) DO NOTHING;

-- ==============================================
-- 6. Investors
-- ==============================================

INSERT INTO public.investors (id, name, type, email, country, is_active, created_at)
VALUES
  ('iiiiiiii-0001-0001-0001-000000000001', 'ABC Capital LP', 'institutional', 'contact@abccapital.com', 'US', true, now()),
  ('iiiiiiii-0002-0002-0002-000000000002', 'XYZ Holdings', 'institutional', 'info@xyzholdings.com', 'UK', true, now()),
  ('iiiiiiii-0003-0003-0003-000000000003', 'Individual Investor 1', 'individual', 'investor1@email.com', 'IL', true, now()),
  ('iiiiiiii-0004-0004-0004-000000000004', 'Family Office 123', 'family_office', 'fo@email.com', 'US', true, now()),
  ('iiiiiiii-0005-0005-0005-000000000005', 'Pension Fund A', 'institutional', 'pf@email.com', 'CA', true, now())
ON CONFLICT (id) DO NOTHING;

-- ==============================================
-- 7. Investor Distributions (Contributions)
-- ==============================================

INSERT INTO public.investor_distributions (id, investor_id, investor_name, fund_name, deal_id, distribution_amount, distribution_date, created_at)
VALUES
  -- FUND-only distributions
  (uuid_generate_v4(), 'iiiiiiii-0001-0001-0001-000000000001', 'ABC Capital LP', 'Buligo Fund VI', NULL, 2500000.00, '2025-01-10', now()),
  (uuid_generate_v4(), 'iiiiiiii-0002-0002-0002-000000000002', 'XYZ Holdings', 'Buligo Fund VI', NULL, 1800000.00, '2025-01-15', now()),
  (uuid_generate_v4(), 'iiiiiiii-0003-0003-0003-000000000003', 'Individual Investor 1', 'Buligo Fund VI', NULL, 500000.00, '2025-02-01', now()),
  (uuid_generate_v4(), 'iiiiiiii-0004-0004-0004-000000000004', 'Family Office 123', 'Buligo Fund VI', NULL, 3200000.00, '2025-02-10', now()),
  (uuid_generate_v4(), 'iiiiiiii-0005-0005-0005-000000000005', 'Pension Fund A', 'Buligo Fund VI', NULL, 5000000.00, '2025-02-15', now()),

  -- DEAL-specific distributions
  (uuid_generate_v4(), 'iiiiiiii-0001-0001-0001-000000000001', 'ABC Capital LP', 'Buligo Fund VI', 'dddddddd-0001-0001-0001-000000000001', 1000000.00, '2025-01-20', now()),
  (uuid_generate_v4(), 'iiiiiiii-0002-0002-0002-000000000002', 'XYZ Holdings', 'Buligo Fund VI', 'dddddddd-0001-0001-0001-000000000001', 750000.00, '2025-01-25', now()),
  (uuid_generate_v4(), 'iiiiiiii-0003-0003-0003-000000000003', 'Individual Investor 1', 'Buligo Fund VI', 'dddddddd-0002-0002-0002-000000000002', 400000.00, '2025-03-05', now()),
  (uuid_generate_v4(), 'iiiiiiii-0004-0004-0004-000000000004', 'Family Office 123', 'Buligo Fund VI', 'dddddddd-0002-0002-0002-000000000002', 1200000.00, '2025-03-10', now()),
  (uuid_generate_v4(), 'iiiiiiii-0005-0005-0005-000000000005', 'Pension Fund A', 'Buligo Fund VI', 'dddddddd-0003-0003-0003-000000000003', 2000000.00, '2025-03-15', now())
ON CONFLICT DO NOTHING;

-- ==============================================
-- 8. Credits
-- ==============================================

INSERT INTO public.credits (id, investor_id, investor_name, fund_name, credit_type, amount, remaining_balance, currency, date_posted, status, apply_policy, scope, deal_id, created_at)
VALUES
  -- FUND-scoped credit
  (uuid_generate_v4(), 'iiiiiiii-0001-0001-0001-000000000001', 'ABC Capital LP', 'Buligo Fund VI', 'repurchase', 5000.00, 5000.00, 'USD', '2024-12-01', 'active', 'net_against_future_payables', 'FUND', NULL, now()),

  -- DEAL-scoped credits
  (uuid_generate_v4(), 'iiiiiiii-0002-0002-0002-000000000002', 'XYZ Holdings', 'Buligo Fund VI', 'equalisation', 2500.00, 2500.00, 'USD', '2025-01-05', 'active', 'net_against_future_payables', 'DEAL', 'dddddddd-0001-0001-0001-000000000001', now()),
  (uuid_generate_v4(), 'iiiiiiii-0004-0004-0004-000000000004', 'Family Office 123', 'Buligo Fund VI', 'discount', 3000.00, 3000.00, 'USD', '2025-02-01', 'active', 'net_against_future_payables', 'DEAL', 'dddddddd-0002-0002-0002-000000000002', now())
ON CONFLICT DO NOTHING;

-- ==============================================
-- 9. VAT Rates
-- ==============================================

INSERT INTO public.vat_rates (id, country_code, rate, effective_from, effective_to, is_default, created_at)
VALUES
  (uuid_generate_v4(), 'IL', 0.17, '2020-01-01', NULL, true, now()),
  (uuid_generate_v4(), 'US', 0.00, '2020-01-01', NULL, false, now()),
  (uuid_generate_v4(), 'UK', 0.20, '2020-01-01', NULL, false, now()),
  (uuid_generate_v4(), 'CA', 0.05, '2020-01-01', NULL, false, now())
ON CONFLICT (country_code, effective_from) DO NOTHING;

-- ==============================================
-- 10. Success Fee Event (for testing)
-- ==============================================

INSERT INTO public.success_fee_events (id, fund_id, deal_id, event_date, event_type, currency, buligo_success_fee_amount, realization_amount, notes, status, created_by, created_at)
VALUES
  (uuid_generate_v4(), 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'dddddddd-0001-0001-0001-000000000001', '2025-03-01', 'realization', 'USD', 500000.00, 10000000.00, 'DEAL-ALPHA partial exit - 20% stake sold', 'pending', (SELECT id FROM auth.users LIMIT 1), now())
ON CONFLICT DO NOTHING;

-- ==============================================
-- Summary
-- ==============================================

DO $$
DECLARE
  v_parties_count integer;
  v_deals_count integer;
  v_agreements_count integer;
  v_investors_count integer;
  v_distributions_count integer;
  v_credits_count integer;
BEGIN
  SELECT COUNT(*) INTO v_parties_count FROM public.parties;
  SELECT COUNT(*) INTO v_deals_count FROM public.deals;
  SELECT COUNT(*) INTO v_agreements_count FROM public.agreements;
  SELECT COUNT(*) INTO v_investors_count FROM public.investors;
  SELECT COUNT(*) INTO v_distributions_count FROM public.investor_distributions;
  SELECT COUNT(*) INTO v_credits_count FROM public.credits;

  RAISE NOTICE '==============================================';
  RAISE NOTICE 'Seed data loaded successfully!';
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'Parties: %', v_parties_count;
  RAISE NOTICE 'Deals: %', v_deals_count;
  RAISE NOTICE 'Agreements: % (2 FUND, 2 DEAL)', v_agreements_count;
  RAISE NOTICE 'Investors: %', v_investors_count;
  RAISE NOTICE 'Distributions: % (5 FUND-only, 5 DEAL-specific)', v_distributions_count;
  RAISE NOTICE 'Credits: % (1 FUND, 2 DEAL)', v_credits_count;
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'Next steps:';
  RAISE NOTICE '1. Create a calculation run via UI';
  RAISE NOTICE '2. Upload distributions or use seeded data';
  RAISE NOTICE '3. Execute calculation to generate fee lines';
  RAISE NOTICE '4. Test approvals, invoices, and exports';
  RAISE NOTICE '==============================================';
END $$;
