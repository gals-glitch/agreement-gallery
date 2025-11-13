-- ============================================
-- Staging Verification Script
-- Purpose: Verify Phase 0 foundation without side effects
-- Time: 10-15 minutes
-- Run on: STAGING environment only
-- ============================================

\echo '============================================'
\echo 'Phase 0 Staging Verification'
\echo 'Started at: ' `date`
\echo '============================================'
\echo ''

-- ============================================
-- 1. DB SANITY CHECK: New tables exist, no data yet
-- ============================================
\echo '1. Checking new tables exist...'
\echo ''

SELECT
  CASE
    WHEN to_regclass('public.workflow_approvals') IS NOT NULL THEN '✅ workflow_approvals'
    ELSE '❌ workflow_approvals MISSING'
  END AS approvals_table;

SELECT
  CASE
    WHEN to_regclass('public.invoices') IS NOT NULL THEN '✅ invoices'
    ELSE '❌ invoices MISSING'
  END AS invoices_table;

SELECT
  CASE
    WHEN to_regclass('public.success_fee_events') IS NOT NULL THEN '✅ success_fee_events'
    ELSE '❌ success_fee_events MISSING'
  END AS success_fee_table;

SELECT
  CASE
    WHEN to_regclass('public.management_fee_accruals') IS NOT NULL THEN '✅ management_fee_accruals'
    ELSE '❌ management_fee_accruals MISSING'
  END AS mgmt_fee_table;

SELECT
  CASE
    WHEN to_regclass('public.distribution_staging') IS NOT NULL THEN '✅ distribution_staging'
    ELSE '❌ distribution_staging MISSING'
  END AS staging_table;

SELECT
  CASE
    WHEN to_regclass('public.payout_schedules') IS NOT NULL THEN '✅ payout_schedules'
    ELSE '❌ payout_schedules MISSING'
  END AS schedules_table;

SELECT
  CASE
    WHEN to_regclass('public.payout_splits') IS NOT NULL THEN '✅ payout_splits'
    ELSE '❌ payout_splits MISSING'
  END AS splits_table;

\echo ''
\echo 'Row counts (should all be 0 before seeding):'
SELECT
  (SELECT COUNT(*) FROM public.workflow_approvals) AS approvals_count,
  (SELECT COUNT(*) FROM public.invoices) AS invoices_count,
  (SELECT COUNT(*) FROM public.success_fee_events) AS events_count,
  (SELECT COUNT(*) FROM public.management_fee_accruals) AS accruals_count,
  (SELECT COUNT(*) FROM public.distribution_staging) AS staging_count,
  (SELECT COUNT(*) FROM public.payout_schedules) AS schedules_count,
  (SELECT COUNT(*) FROM public.payout_splits) AS splits_count;

-- ============================================
-- 2. EXISTING TABLES UNTOUCHED
-- ============================================
\echo ''
\echo '2. Verifying existing tables still intact...'
\echo ''

SELECT
  (SELECT COUNT(*) FROM public.calculation_runs) AS runs_count,
  (SELECT COUNT(*) FROM public.investor_distributions) AS distributions_count,
  (SELECT COUNT(*) FROM public.agreements) AS agreements_count,
  (SELECT COUNT(*) FROM public.parties) AS parties_count,
  (SELECT COUNT(*) FROM public.credits) AS credits_count,
  (SELECT COUNT(*) FROM public.fund_vi_tracks) AS tracks_count;

\echo ''
\echo 'Checking calculation_runs status values...'
SELECT DISTINCT status FROM public.calculation_runs ORDER BY status;

\echo ''
\echo 'Expected: draft, in_progress, completed, failed'
\echo 'New allowed (not used yet): awaiting_approval, approved, invoiced'

-- ============================================
-- 3. RLS SMOKE TEST (role enforcement)
-- ============================================
\echo ''
\echo '3. RLS policy check (should return 0 for non-admin)...'
\echo ''

-- Check if RLS is enabled on new tables
SELECT
  schemaname,
  tablename,
  CASE WHEN rowsecurity THEN '✅ RLS enabled' ELSE '❌ RLS disabled' END AS rls_status
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'workflow_approvals',
    'invoices',
    'invoice_lines',
    'payments',
    'success_fee_events',
    'management_fee_accruals',
    'distribution_staging',
    'payout_schedules',
    'payout_splits'
  )
ORDER BY tablename;

-- ============================================
-- 4. REPORTING VIEWS
-- ============================================
\echo ''
\echo '4. Checking reporting views exist...'
\echo ''

SELECT
  CASE
    WHEN to_regclass('public.vw_fees_by_investor') IS NOT NULL THEN '✅ vw_fees_by_investor'
    ELSE '❌ vw_fees_by_investor MISSING'
  END AS view1;

SELECT
  CASE
    WHEN to_regclass('public.vw_vat_summary') IS NOT NULL THEN '✅ vw_vat_summary'
    ELSE '❌ vw_vat_summary MISSING'
  END AS view2;

SELECT
  CASE
    WHEN to_regclass('public.vw_credits_outstanding') IS NOT NULL THEN '✅ vw_credits_outstanding'
    ELSE '❌ vw_credits_outstanding MISSING'
  END AS view3;

SELECT
  CASE
    WHEN to_regclass('public.vw_run_summary') IS NOT NULL THEN '✅ vw_run_summary'
    ELSE '❌ vw_run_summary MISSING'
  END AS view4;

-- ============================================
-- 5. FUNCTIONS & TRIGGERS
-- ============================================
\echo ''
\echo '5. Checking new functions exist...'
\echo ''

SELECT
  routine_name,
  '✅' AS status
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN (
    'generate_invoice_number',
    'commit_staged_distributions',
    'update_workflow_approvals_updated_at',
    'update_invoices_updated_at',
    'mark_success_fee_event_posted',
    'validate_mgmt_fee_totals',
    'validate_payout_schedule_total',
    'validate_payout_split_total'
  )
ORDER BY routine_name;

-- ============================================
-- 6. SEED DATA (if loaded)
-- ============================================
\echo ''
\echo '6. Seed data check (0 if not loaded yet)...'
\echo ''

SELECT
  (SELECT COUNT(*) FROM public.parties WHERE name LIKE '%Acme%') AS acme_party,
  (SELECT COUNT(*) FROM public.deals WHERE code LIKE 'DEAL-%') AS deals_seeded,
  (SELECT COUNT(*) FROM public.success_fee_events WHERE status = 'pending') AS pending_events;

-- ============================================
-- SUMMARY
-- ============================================
\echo ''
\echo '============================================'
\echo 'Verification Summary'
\echo '============================================'
\echo ''
\echo 'Expected Results:'
\echo '- All 7 new tables exist ✅'
\echo '- All row counts = 0 (before seeding)'
\echo '- RLS enabled on all new tables ✅'
\echo '- Existing tables untouched ✅'
\echo '- 4 reporting views exist ✅'
\echo '- 8 new functions exist ✅'
\echo ''
\echo 'If all checks pass:'
\echo '1. Load seed data: psql < supabase/seed.sql'
\echo '2. Test existing workflows (create run, upload, calculate)'
\echo '3. Confirm feature flags all OFF in app'
\echo '4. Proceed to Sprint 1 (Approvals)'
\echo ''
\echo 'Completed at: ' `date`
\echo '============================================'
