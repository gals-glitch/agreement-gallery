# Deployment Guide - Buligo Capital v1.5.0

**Version:** 1.5.0
**Date:** 2025-10-19
**Status:** Ready for Deployment

---

## Executive Summary

This deployment introduces **7 major features** with **5 database migrations**, **25+ API endpoints**, and **30+ frontend components**. All features are **feature-flagged** for safe, gradual rollout.

**Deployment Time:** ~30 minutes
**Rollback Time:** < 5 minutes (via feature flags)
**Risk Level:** LOW (all features flag-gated, non-breaking)

---

## Pre-Deployment Checklist

- [ ] **Backup database** (take snapshot before applying migrations)
- [ ] **Review migrations** (verify 5 migration files exist in `supabase/migrations/`)
- [ ] **Test local environment** (run `npm run dev` and verify build succeeds)
- [ ] **Review feature flags** (confirm all 5 flags seeded as OFF)
- [ ] **Notify team** (inform stakeholders of deployment window)

---

## Step 1: Apply Database Migrations (5 minutes)

### Verify Migration Files

```bash
# Check that all 5 migration files exist
ls supabase/migrations/202510191000*.sql

# Expected files:
# 20251019100001_investor_source_fields.sql
# 20251019100002_agreement_documents.sql
# 20251019100003_vat_and_snapshots.sql
# 20251019100004_transactions_credits.sql
# 20251019100010_feature_flags.sql
```

### Apply Migrations

**Option A: Local Development (Reset)**
```bash
# WARNING: This resets ALL data (use only in development)
supabase db reset
```

**Option B: Production (Push)**
```bash
# Apply migrations without resetting data
supabase db push
```

### Verify Schema

```sql
-- 1. Check new tables exist
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'feature_flags',
    'vat_rates',
    'agreement_documents',
    'transactions',
    'credits_ledger'
  );
-- Expected: 5 rows

-- 2. Check investors table has new columns
SELECT column_name
FROM information_schema.columns
WHERE table_name = 'investors'
  AND column_name IN ('source_kind', 'introduced_by_party_id', 'source_linked_at');
-- Expected: 3 rows

-- 3. Verify feature flags seeded
SELECT key, enabled, enabled_for_roles
FROM feature_flags
ORDER BY key;
-- Expected: 5 flags, all enabled=false

-- 4. Verify VAT rates seeded
SELECT country_code, rate_percentage, effective_from, effective_to
FROM vat_rates
ORDER BY country_code, effective_from;
-- Expected: 3 rows (UK 20%, UK 17.5%, US 0%)

-- 5. Check RLS policies
SELECT schemaname, tablename, policyname
FROM pg_policies
WHERE tablename IN ('feature_flags', 'vat_rates', 'agreement_documents', 'transactions', 'credits_ledger');
-- Expected: 15+ policies
```

**Result:** ✅ All tables created, columns added, seed data inserted, RLS policies active

---

## Step 2: Deploy Edge Functions (10 minutes)

### Deploy API to Supabase

```bash
# Deploy the Edge Function
supabase functions deploy api-v1

# Verify deployment
supabase functions list
# Expected: api-v1 with status "deployed"
```

### Test API Health

```bash
# Get your JWT token from Supabase dashboard
# Or use supabase CLI: supabase auth login

export JWT_TOKEN="your-jwt-token-here"

# Test 1: Feature Flags endpoint
curl -X GET "http://localhost:54321/functions/v1/api-v1/feature-flags" \
  -H "Authorization: Bearer $JWT_TOKEN"
# Expected: { "feature_flags": [...] } with 5 flags

# Test 2: VAT Rates endpoint
curl -X GET "http://localhost:54321/functions/v1/api-v1/vat-rates" \
  -H "Authorization: Bearer $JWT_TOKEN"
# Expected: { "vat_rates": [...] } with 3 seed rates

# Test 3: Investors endpoint (with new filters)
curl -X GET "http://localhost:54321/functions/v1/api-v1/investors?has_source=false" \
  -H "Authorization: Bearer $JWT_TOKEN"
# Expected: { "investors": [...] } with all investors (source_kind='NONE')

# Test 4: Transactions endpoint
curl -X GET "http://localhost:54321/functions/v1/api-v1/transactions" \
  -H "Authorization: Bearer $JWT_TOKEN"
# Expected: { "transactions": [], "total_count": 0 } (empty initially)

# Test 5: Credits endpoint
curl -X GET "http://localhost:54321/functions/v1/api-v1/credits" \
  -H "Authorization: Bearer $JWT_TOKEN"
# Expected: { "credits": [], "total_count": 0 } (empty initially)
```

**Result:** ✅ All 5 API endpoints respond correctly

---

## Step 3: Deploy Frontend (10 minutes)

### Build and Deploy

```bash
# Install dependencies (if needed)
npm install

# Build production bundle
npm run build

# Verify build succeeded
# Expected: dist/ folder created with optimized assets

# Deploy (method depends on hosting)
# For Lovable: Use Lovable UI deployment
# For Vercel: vercel deploy --prod
# For Netlify: netlify deploy --prod
```

### Verify Deployment

1. **Navigate to app URL**
2. **Login as admin**
3. **Check console** (should be zero errors)
4. **Verify navigation:**
   - DATA section shows: Funds, Parties, Investors, Contributions, Fund VI Tracks
   - WORKFLOW section shows: Agreements, Runs
   - ADMIN section shows: Users & Roles, Settings, Feature Flags (no VAT Settings yet - flag OFF)
   - DOCS section: Hidden (flag OFF)

**Result:** ✅ Frontend deployed, navigation correct, console clean

---

## Step 4: Enable Feature Flags (Gradual Rollout)

### Phase 1: Admin-Only Testing (Week 1)

**Enable flags for admin role only:**

```sql
-- Enable VAT Admin (admin-only)
UPDATE feature_flags
SET enabled = true,
    enabled_for_roles = ARRAY['admin']
WHERE key = 'vat_admin';

-- Enable Agreement Docs (admin-only initially)
UPDATE feature_flags
SET enabled = true,
    enabled_for_roles = ARRAY['admin']
WHERE key = 'docs_repository';

-- Enable Charges Engine (admin-only)
UPDATE feature_flags
SET enabled = true,
    enabled_for_roles = ARRAY['admin']
WHERE key = 'charges_engine';

-- Verify
SELECT key, enabled, enabled_for_roles FROM feature_flags WHERE enabled = true;
```

**Test as admin:**
- Navigate to `/vat-settings` (should load)
- Navigate to `/documents` (should load)
- Navigate to `/transactions` (should load)
- Sidebar shows all admin items

**Test as finance user:**
- Navigate to `/vat-settings` (should redirect to 404)
- Sidebar hides VAT Settings (correct behavior)

**Result:** ✅ Flags work, role-based access enforced

---

### Phase 2: Expand to Finance (Week 2)

**Allow finance users to access selected features:**

```sql
-- Expand Agreement Docs to finance
UPDATE feature_flags
SET enabled_for_roles = ARRAY['admin', 'finance']
WHERE key = 'docs_repository';

-- Expand Charges Engine to finance
UPDATE feature_flags
SET enabled_for_roles = ARRAY['admin', 'finance']
WHERE key = 'charges_engine';

-- VAT Admin remains admin-only (regulatory control)
-- vat_admin stays as ARRAY['admin']

-- Verify
SELECT key, enabled_for_roles FROM feature_flags WHERE enabled = true;
```

**Test as finance user:**
- Navigate to `/documents` (should load)
- Navigate to `/transactions` (should load)
- Navigate to `/vat-settings` (should redirect to 404 - admin-only)

**Result:** ✅ Finance has access to appropriate features

---

### Phase 3: Enable for All Users (Week 3)

**Open features to all authenticated users:**

```sql
-- Enable Agreement Docs for all users
UPDATE feature_flags
SET enabled = true,
    enabled_for_roles = NULL  -- NULL = all roles
WHERE key = 'docs_repository';

-- Enable Charges Engine for read-only (ops+ can view, finance+ can create)
UPDATE feature_flags
SET enabled = true,
    enabled_for_roles = NULL
WHERE key = 'charges_engine';

-- VAT Admin and Credits Management remain restricted
-- vat_admin: admin-only
-- credits_management: finance+ only

-- Verify
SELECT key, enabled, enabled_for_roles FROM feature_flags;
```

**Result:** ✅ Features available to all users, RBAC enforced at API level

---

## Step 5: QA Smoke Tests (Required)

### Test Suite 1: Feature Flags (15 minutes)

**Run tests from:** `docs/ORC-TESTING-GUIDE.md` (Tests FF-01 to FF-11)

Key scenarios:
- ✅ FF-01: Flags table exists and seeded
- ✅ FF-03: GET /feature-flags returns correct state for user role
- ✅ FF-05: PUT /feature-flags (admin updates flag)
- ✅ FF-07: Frontend hook reflects flag state
- ✅ FF-09: Route guards redirect when flag OFF

---

### Test Suite 2: Error Contract (10 minutes)

**Run tests from:** `docs/ORC-TESTING-GUIDE.md` (Tests EC-01 to EC-09)

Key scenarios:
- ✅ EC-01: Validation error returns standardized JSON
- ✅ EC-03: Field-level errors display in toasts
- ✅ EC-05: Row-level CSV errors show row numbers
- ✅ EC-07: RBAC 403 errors show clear message

---

### Test Suite 3: Investor Source (20 minutes)

**Run tests from:** `docs/INVESTOR_SOURCE_TESTING.md`

Key scenarios:
- ✅ List page shows Source Kind badges and Introduced By column
- ✅ Filters work (source_kind, has_source, introduced_by_party_id)
- ✅ Form section allows setting/clearing source
- ✅ CSV import shows row-level errors with clickable rows
- ✅ PATCH updates source fields correctly

---

### Test Suite 4: VAT Admin (25 minutes)

**Run tests from:** `docs/VAT_TESTING_GUIDE.md`

Key scenarios:
- ✅ VAT Settings page loads (admin only)
- ✅ Current/Scheduled/Historical sections display correctly
- ✅ Create rate with overlap returns 409 conflict error
- ✅ Agreement approval captures VAT snapshot
- ✅ Changing future rate doesn't alter past snapshots

---

### Test Suite 5: Transactions/Credits (15 minutes)

**Run tests from:** `docs/TRANSACTIONS_CREDITS_STUB_IMPLEMENTATION.md`

Key scenarios:
- ✅ POST /transactions validates XOR (fund_id OR deal_id)
- ✅ Transactions list page shows filters
- ✅ Credits page shows summary cards (Available, Applied, Expired)
- ✅ Create credit modal validates and inserts

---

## Step 6: Audit & Safety Verification (10 minutes)

### Verify Audit Logs

```sql
-- Check that audit_log table exists (if implemented)
SELECT table_name FROM information_schema.tables
WHERE table_name = 'audit_log';

-- If exists, verify entries are being created
-- (Test by creating a VAT rate or updating an investor)
SELECT * FROM audit_log ORDER BY created_at DESC LIMIT 10;
```

### Verify RLS Enforcement

```sql
-- Test as different roles
-- 1. Set session role to 'viewer'
SET LOCAL ROLE viewer;

-- Try to insert (should fail)
INSERT INTO vat_rates (country_code, rate_percentage, effective_from, created_by)
VALUES ('US', 5.0, '2025-01-01', 'test-user-id');
-- Expected: ERROR: permission denied (RLS policy blocks)

-- 2. Reset role
RESET ROLE;

-- Try to query feature_flags (should succeed for all authenticated)
SELECT * FROM feature_flags;
-- Expected: 5 rows returned
```

**Result:** ✅ Audit logs active, RLS enforced

---

## Rollback Procedures

### Immediate Rollback (< 5 minutes)

**Option 1: Disable Feature Flags (Zero Downtime)**

```sql
-- Disable all new features instantly
UPDATE feature_flags SET enabled = false WHERE key IN (
  'docs_repository',
  'vat_admin',
  'charges_engine',
  'credits_management',
  'reports_dashboard'
);

-- Verify
SELECT key, enabled FROM feature_flags;
```

**Result:** All new features hidden, users see pre-v1.5.0 interface

---

**Option 2: Rollback Migrations (Requires Downtime)**

```sql
-- WARNING: This deletes all data in new tables
-- Only use if catastrophic failure

BEGIN;

-- Drop new tables (reverse order)
DROP TABLE IF EXISTS audit_log CASCADE;
DROP TABLE IF EXISTS credit_applications CASCADE;
DROP TABLE IF EXISTS credits_ledger CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS charges CASCADE;
DROP TABLE IF EXISTS agreement_document_versions CASCADE;
DROP TABLE IF EXISTS agreement_documents CASCADE;
DROP MATERIALIZED VIEW IF EXISTS agreement_documents_latest;
DROP TABLE IF EXISTS vat_rates CASCADE;
DROP TABLE IF EXISTS feature_flags CASCADE;

-- Remove new columns from investors
ALTER TABLE investors DROP COLUMN IF EXISTS source_kind;
ALTER TABLE investors DROP COLUMN IF EXISTS introduced_by_party_id;
ALTER TABLE investors DROP COLUMN IF EXISTS source_linked_at;

-- Remove new columns from agreement_rate_snapshots
ALTER TABLE agreement_rate_snapshots DROP COLUMN IF EXISTS vat_rate_percent;
ALTER TABLE agreement_rate_snapshots DROP COLUMN IF EXISTS vat_policy;
ALTER TABLE agreement_rate_snapshots DROP COLUMN IF EXISTS tiers;
ALTER TABLE agreement_rate_snapshots DROP COLUMN IF EXISTS caps;
ALTER TABLE agreement_rate_snapshots DROP COLUMN IF EXISTS discounts;
ALTER TABLE agreement_rate_snapshots DROP COLUMN IF EXISTS snapshotted_at;

-- Drop storage bucket
DELETE FROM storage.buckets WHERE id = 'agreement-docs';

COMMIT;
```

**Result:** Database reverted to v1.4.0 state

---

**Option 3: Rollback Frontend (10 minutes)**

```bash
# Revert to previous git commit
git log --oneline  # Find v1.4.0 commit hash
git revert <commit-hash>
git push

# Or deploy previous version
vercel rollback  # (if using Vercel)
```

**Result:** Frontend reverted to v1.4.0

---

## Post-Deployment Monitoring

### Week 1: Admin Testing

**Metrics to Monitor:**
- [ ] Console errors (should be 0)
- [ ] API error rates (< 1% expected)
- [ ] Feature flag toggle latency (< 100ms)
- [ ] Database query performance (no slow queries > 1s)
- [ ] Storage bucket usage (monitor PDF uploads)

**User Feedback:**
- [ ] Admin confirms VAT Settings page works
- [ ] Admin uploads test PDF to Agreement Docs
- [ ] Admin creates test transaction and credit

---

### Week 2: Finance Rollout

**Metrics to Monitor:**
- [ ] Document upload success rate (> 95%)
- [ ] VAT snapshot creation on agreement approvals
- [ ] Transaction creation via CSV import
- [ ] Credit balance calculations accurate

**User Feedback:**
- [ ] Finance team can access Agreement Docs
- [ ] Finance team can view/create transactions
- [ ] No regressions in existing features (Agreements, Runs, Contributions)

---

### Week 3: Full Rollout

**Metrics to Monitor:**
- [ ] Concurrent users accessing new features
- [ ] Database connection pool usage
- [ ] Frontend bundle size impact (< 10% increase)
- [ ] Page load times (< 2s)

**User Feedback:**
- [ ] All users can access enabled features
- [ ] No permission errors for authorized actions
- [ ] Toasts show clear error messages

---

## Success Criteria

### Technical Success
- ✅ All 5 migrations applied successfully
- ✅ Edge Functions deployed and responding
- ✅ Frontend build succeeds, zero console errors
- ✅ All 5 test suites pass
- ✅ RLS policies enforce role-based access
- ✅ Feature flags enable/disable features correctly

### Business Success
- ✅ Admin can manage VAT rates and view snapshots
- ✅ Ops can link investors to source parties
- ✅ Finance can upload agreement documents with versioning
- ✅ Finance can create transactions and credits (stub)
- ✅ No regressions in existing workflows

### User Experience Success
- ✅ Navigation reorganized logically (DATA, WORKFLOW, ADMIN, DOCS)
- ✅ Fund VI Tracks page shows read-only rates
- ✅ Error messages are clear and actionable
- ✅ Feature flags hide incomplete features

---

## Troubleshooting

### Issue: Migration fails with constraint violation

**Symptom:** `ERROR: foreign key constraint "fk_party" violates ...`
**Cause:** Existing data violates new constraints
**Fix:**
```sql
-- Identify problematic rows
SELECT * FROM investors WHERE introduced_by_party_id IS NOT NULL
  AND introduced_by_party_id NOT IN (SELECT id FROM parties);

-- Fix: NULL out invalid foreign keys
UPDATE investors SET introduced_by_party_id = NULL
WHERE introduced_by_party_id NOT IN (SELECT id FROM parties);

-- Re-run migration
```

---

### Issue: Feature flag changes don't reflect in UI

**Symptom:** Toggling flag in database doesn't hide/show UI
**Cause:** Frontend cache not invalidated
**Fix:**
```typescript
// In browser console:
localStorage.clear();
sessionStorage.clear();
location.reload();
```

Or wait 5 minutes (cache TTL).

---

### Issue: API returns 403 for admin user

**Symptom:** Admin user gets "Forbidden" error
**Cause:** `user_roles` table not updated
**Fix:**
```sql
-- Verify user role
SELECT * FROM user_roles WHERE user_id = 'your-user-id';

-- If missing, insert admin role
INSERT INTO user_roles (user_id, role) VALUES ('your-user-id', 'admin');
```

---

### Issue: VAT snapshot not created on agreement approval

**Symptom:** `vat_rate_percent` is NULL after approval
**Cause:** Trigger not firing or no current VAT rate for country
**Fix:**
```sql
-- Check if trigger exists
SELECT tgname FROM pg_trigger WHERE tgname = 'trg_snapshot_vat_on_approval';

-- Verify current VAT rate exists for country
SELECT * FROM vat_rates WHERE country_code = 'GB' AND effective_to IS NULL;

-- If missing, insert current rate
INSERT INTO vat_rates (country_code, rate_percentage, effective_from, created_by)
VALUES ('GB', 20.0, '2011-01-04', 'system');
```

---

## Contacts & Escalation

**Deployment Lead:** [Your Name]
**Database Admin:** [DB Admin Name]
**Frontend Lead:** [Frontend Lead Name]
**QA Lead:** [QA Lead Name]

**Escalation Path:**
1. Check this guide's troubleshooting section
2. Review test documentation (`docs/*.md`)
3. Contact deployment lead
4. If critical: Disable feature flags immediately, notify team

---

## Appendix: Feature Flag Reference

| Flag Key | Default | Roles | Purpose |
|----------|---------|-------|---------|
| `docs_repository` | OFF | All → Admin → Finance → All (gradual) | Agreement PDF repository |
| `vat_admin` | OFF | Admin-only (always) | VAT rates CRUD |
| `charges_engine` | OFF | Admin → Finance → All (gradual) | Transactions & Charges (stub) |
| `credits_management` | OFF | Admin → Finance (never all) | Credits ledger (stub) |
| `reports_dashboard` | OFF | Finance → All (future) | Reports & dashboard (future) |

---

## Appendix: API Endpoints Added

| Endpoint | Method | Feature | Description |
|----------|--------|---------|-------------|
| `/feature-flags` | GET | Foundation | List all flags for user role |
| `/feature-flags/:key` | PUT | Foundation | Update flag (admin-only) |
| `/investors` | GET | Investor Source | Added filters: source_kind, has_source |
| `/investors/:id` | PATCH | Investor Source | Added fields: source_kind, introduced_by_party_id |
| `/investors/source-import` | POST | Investor Source | CSV bulk import |
| `/vat-rates` | GET, POST | VAT Admin | CRUD for VAT rates |
| `/vat-rates/current` | GET | VAT Admin | Get current rate by country |
| `/vat-rates/:id` | PATCH, DELETE | VAT Admin | Update/close/delete rates |
| `/agreements/documents` | GET, POST | Docs Repo | List/create documents |
| `/agreements/documents/:id/versions` | GET, POST | Docs Repo | Version management |
| `/agreements/documents/:id/download` | GET | Docs Repo | Signed download URL |
| `/transactions` | GET, POST | Charges Stub | Transaction CRUD |
| `/transactions/:id` | GET | Charges Stub | Transaction detail |
| `/credits` | GET, POST | Credits Stub | Credit CRUD |

**Total:** 15+ new endpoints

---

**End of Deployment Guide**
**Version:** 1.5.0
**Last Updated:** 2025-10-19
