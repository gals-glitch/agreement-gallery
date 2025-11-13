# Deployment Checklist - v1.5.0

**Date:** 2025-10-19
**Version:** 1.5.0
**Estimated Time:** 30 minutes
**Risk:** LOW (feature-flagged, instant rollback)

---

## Pre-Deployment (5 minutes)

- [ ] **Backup database** (take snapshot)
  ```bash
  # If using Supabase Cloud: Use dashboard backup feature
  # If local: pg_dump or supabase db dump
  ```

- [ ] **Verify migration files exist** (5 files)
  ```bash
  ls supabase/migrations/202510191000*.sql
  # Expected: 5 files
  ```

- [ ] **Test local build**
  ```bash
  npm run build
  # Should complete with zero errors
  ```

- [ ] **Review feature flags** (confirm all OFF)
  ```sql
  SELECT key, enabled FROM feature_flags;
  -- Expected: All enabled = false (or table doesn't exist yet)
  ```

---

## Step 1: Apply Migrations (5 minutes)

- [ ] **Apply migrations to database**
  ```bash
  # Production (recommended):
  supabase db push

  # OR Local development:
  supabase db reset
  ```

- [ ] **Verify migrations applied**
  ```sql
  -- Check new tables exist
  SELECT table_name FROM information_schema.tables
  WHERE table_schema = 'public'
    AND table_name IN ('feature_flags', 'vat_rates', 'agreement_documents', 'transactions', 'credits_ledger');
  -- Expected: 5 rows

  -- Check investors has new columns
  SELECT column_name FROM information_schema.columns
  WHERE table_name = 'investors'
    AND column_name IN ('source_kind', 'introduced_by_party_id');
  -- Expected: 2 rows

  -- Check feature flags seeded
  SELECT key, enabled FROM feature_flags ORDER BY key;
  -- Expected: 5 flags, all enabled=false

  -- Check VAT rates seeded
  SELECT country_code, rate_percentage FROM vat_rates;
  -- Expected: 3 rows (UK 20%, UK 17.5%, US 0%)
  ```

- [ ] **Verify RLS policies**
  ```sql
  SELECT tablename, COUNT(*) as policy_count
  FROM pg_policies
  WHERE tablename IN ('feature_flags', 'vat_rates', 'agreement_documents', 'transactions', 'credits_ledger')
  GROUP BY tablename;
  -- Expected: 15+ policies across 5 tables
  ```

**Result:** ✅ Database schema updated successfully

---

## Step 2: Deploy Edge Functions (10 minutes)

- [ ] **Deploy API to Supabase**
  ```bash
  supabase functions deploy api-v1
  ```

- [ ] **Verify deployment**
  ```bash
  supabase functions list
  # Expected: api-v1 status "deployed"
  ```

- [ ] **Test API health** (get your JWT token first)
  ```bash
  export JWT_TOKEN="your-jwt-token-here"

  # Test 1: Feature Flags
  curl -X GET "http://localhost:54321/functions/v1/api-v1/feature-flags" \
    -H "Authorization: Bearer $JWT_TOKEN"
  # Expected: {"feature_flags": [...]} with 5 flags

  # Test 2: VAT Rates
  curl -X GET "http://localhost:54321/functions/v1/api-v1/vat-rates" \
    -H "Authorization: Bearer $JWT_TOKEN"
  # Expected: {"vat_rates": [...]} with 3 seed rates

  # Test 3: Investors (with new filters)
  curl -X GET "http://localhost:54321/functions/v1/api-v1/investors?has_source=false" \
    -H "Authorization: Bearer $JWT_TOKEN"
  # Expected: {"investors": [...]}

  # Test 4: Transactions
  curl -X GET "http://localhost:54321/functions/v1/api-v1/transactions" \
    -H "Authorization: Bearer $JWT_TOKEN"
  # Expected: {"transactions": [], "total_count": 0}

  # Test 5: Credits
  curl -X GET "http://localhost:54321/functions/v1/api-v1/credits" \
    -H "Authorization: Bearer $JWT_TOKEN"
  # Expected: {"credits": [], "total_count": 0}
  ```

**Result:** ✅ All API endpoints responding correctly

---

## Step 3: Deploy Frontend (10 minutes)

- [ ] **Build production bundle**
  ```bash
  npm install  # If dependencies changed
  npm run build
  ```

- [ ] **Verify build succeeded**
  ```bash
  ls dist/
  # Should contain assets/, index.html, etc.
  ```

- [ ] **Deploy to hosting**
  ```bash
  # For Lovable: Use Lovable UI deployment
  # For Vercel: vercel deploy --prod
  # For Netlify: netlify deploy --prod
  # For other: Follow your hosting provider's instructions
  ```

- [ ] **Verify deployment**
  - Navigate to app URL
  - Login as admin
  - Check browser console (should be zero errors)
  - Verify navigation structure:
    - **DATA:** Funds, Parties, Investors, Contributions, Fund VI Tracks ✓
    - **WORKFLOW:** Agreements, Runs ✓
    - **ADMIN:** Users & Roles, Settings, Feature Flags ✓
    - **DOCS:** Hidden (flag OFF) ✓

**Result:** ✅ Frontend deployed, navigation correct, console clean

---

## Step 4: Enable Feature Flags (5 minutes)

- [ ] **Enable flags for admin testing**
  ```bash
  # Run the prepared SQL script
  psql -f scripts/enable-flags-admin.sql

  # OR manually:
  ```
  ```sql
  UPDATE feature_flags
  SET enabled = true, enabled_for_roles = ARRAY['admin']
  WHERE key IN ('vat_admin', 'docs_repository', 'charges_engine');
  ```

- [ ] **Verify flags enabled**
  ```sql
  SELECT key, enabled, enabled_for_roles FROM feature_flags WHERE enabled = true;
  -- Expected: 3 rows (vat_admin, docs_repository, charges_engine)
  ```

- [ ] **Test as admin user**
  - Login as admin
  - Navigate to `/vat-settings` → Should load ✓
  - Navigate to `/documents` → Should load ✓
  - Navigate to `/transactions` → Should load ✓
  - Sidebar shows: VAT Settings, Agreements (Docs), Transactions ✓

- [ ] **Test as finance user** (if available)
  - Login as finance
  - Navigate to `/vat-settings` → Should redirect to 404 ✓
  - Sidebar hides VAT Settings ✓

**Result:** ✅ Feature flags working, role-based access enforced

---

## Step 5: Quick Smoke Tests (15 minutes)

### Test 1: Feature Flags & Route Guards

- [ ] **Route guards work**
  - Disable flag: `UPDATE feature_flags SET enabled = false WHERE key = 'vat_admin';`
  - Navigate to `/vat-settings` → Redirects to 404 ✓
  - Re-enable flag: `UPDATE feature_flags SET enabled = true WHERE key = 'vat_admin';`
  - Navigate to `/vat-settings` → Loads correctly ✓

### Test 2: Investor Source

- [ ] **List page shows source columns**
  - Navigate to `/investors`
  - "Source Kind" column visible with badges (Distributor/Referrer/None) ✓
  - "Introduced By" column visible ✓

- [ ] **Filters work**
  - Filter by Source Kind = "None" → Shows investors with no source ✓
  - Filter by "Has Source" = No → Shows same results ✓

- [ ] **Form saves source**
  - Edit an investor
  - Set Source Kind = "Distributor"
  - Select a party from "Introduced By" dropdown
  - Save → Success toast ✓
  - Reload page → Source persisted ✓

### Test 3: VAT Admin

- [ ] **VAT Settings page loads** (admin only)
  - Navigate to `/vat-settings` as admin → Loads ✓
  - See Current/Scheduled/Historical sections ✓

- [ ] **Create VAT rate**
  - Click "Create New Rate"
  - Fill: Country = "GB", Rate = 21%, Effective From = 2026-01-01
  - Save → Success toast ✓

- [ ] **Overlap validation**
  - Try to create overlapping rate (GB, 20%, 2025-01-01)
  - Should get 409 conflict error ✓

### Test 4: Transactions & Credits

- [ ] **Create transaction**
  - Navigate to `/transactions`
  - Click "Create Transaction"
  - Fill: Investor, Type=CONTRIBUTION, Amount, Date, Fund OR Deal (not both)
  - Save → Success toast ✓
  - Transaction appears in list ✓

- [ ] **XOR validation**
  - Try to create transaction with both fund_id AND deal_id
  - Should get 422 validation error ✓

- [ ] **Credits summary cards**
  - Navigate to `/credits`
  - See 3 cards: Available, Applied, Expired ✓
  - Create a credit → Available balance updates ✓

### Test 5: Documents Repository

- [ ] **Documents page loads**
  - Navigate to `/documents` as admin → Loads ✓
  - See search and filters ✓
  - Table displays (empty initially) ✓

**Result:** ✅ All smoke tests passed

---

## Step 6: Verify Audit & RLS (5 minutes)

- [ ] **Test RLS enforcement**
  ```sql
  -- Simulate viewer role
  SET LOCAL ROLE viewer;

  -- Try to insert (should fail)
  INSERT INTO vat_rates (country_code, rate_percentage, effective_from, created_by)
  VALUES ('US', 5.0, '2025-01-01', 'test-user');
  -- Expected: ERROR permission denied

  RESET ROLE;
  ```

- [ ] **Verify audit trail** (if audit_log exists)
  ```sql
  SELECT * FROM audit_log ORDER BY created_at DESC LIMIT 10;
  -- Should show recent actions
  ```

**Result:** ✅ Security enforced

---

## Post-Deployment Monitoring (Week 1)

- [ ] **Monitor console errors** (should be 0)
- [ ] **Monitor API error rates** (< 1%)
- [ ] **Check database performance** (no slow queries > 1s)
- [ ] **Gather admin feedback**
  - Admin confirms VAT Settings works
  - Admin uploads test PDF
  - Admin creates test transaction

---

## Rollback Procedure (If Needed)

### Option 1: Instant Rollback via Feature Flags (< 5 minutes)

```bash
# Run the disable script
psql -f scripts/disable-all-flags.sql
```

OR manually:

```sql
UPDATE feature_flags SET enabled = false;
```

**Result:** All new features hidden instantly, zero downtime

---

### Option 2: Rollback Migrations (Requires Downtime)

**⚠️ WARNING: This deletes all data in new tables**

```sql
-- See DEPLOYMENT_GUIDE.md → "Rollback Procedures" for full SQL
```

---

## Sign-Off

- [ ] **Deployment Team Lead:** ___________________ Date: ___________
- [ ] **QA Lead:** ___________________ Date: ___________
- [ ] **Product Owner:** ___________________ Date: ___________

---

## Status Updates

**Pre-Deployment:**
- Date: ___________
- Status: [ ] Ready [ ] Not Ready
- Issues: ___________

**Post-Deployment:**
- Date: ___________
- Status: [ ] Success [ ] Partial [ ] Failed
- Issues: ___________
- Rollback Needed: [ ] Yes [ ] No

---

## Notes

_Add any deployment notes, issues encountered, or follow-up items:_

---

**End of Checklist**
**Version:** 1.5.0
**Last Updated:** 2025-10-19
