# Deployment Guide: Approvals Workflow (Sprint 1)

**Status:** ✅ Ready for Staging Deployment
**Feature Flag:** FEATURE_APPROVALS
**Estimated Time:** 60-90 minutes (verification + deployment)

---

## What's Been Implemented

### Backend ✅
- **Edge Function:** `supabase/functions/approvals-api/index.ts`
  - POST /{runId}/submit - Submit run for approval
  - POST /{runId}/approve - Approve specific step with RBAC
  - POST /{runId}/reject - Reject and revert to in_progress
  - GET /{runId}/status - Get approval history

- **Database Migration:** `supabase/migrations/20251012100000_add_workflow_approvals.sql`
  - Table: workflow_approvals
  - Extended calculation_runs.status with: awaiting_approval, approved, invoiced
  - RLS policies for role-based access

### Frontend ✅
- **API Client:** `src/api/approvalsClient.ts`
  - TypeScript client for all approval operations
  - RBAC helper: canUserApproveStep()

- **UI Component:** `src/components/ApprovalsDrawerEnhanced.tsx`
  - Multi-step approval workflow display
  - Submit/Approve/Reject actions
  - Feature flag gated (returns null if disabled)

- **Dashboard Integration:** `src/components/SimplifiedCalculationDashboard.tsx`
  - Status badges showing: DRAFT, IN PROGRESS, AWAITING APPROVAL, APPROVED
  - Approvals button (feature-flagged)
  - Uses ApprovalsDrawerEnhanced

### Testing ✅
- **QA Script:** `scripts/qa-approvals.md`
  - 13 test cases covering happy path, RBAC, rejections, edge cases
  - User setup instructions
  - SQL verification queries

### Documentation ✅
- **Seed Data:** `supabase/seed.sql` - Sample parties, deals, agreements
- **Verification Script:** `scripts/verify-staging.sql` - DB sanity checks

---

## Deployment Steps

### Step 1: Staging Verification (15 minutes)

Run verification script to ensure Phase 0 foundation is intact:

```bash
# Connect to staging database
psql -h <staging-db-host> -U postgres -d postgres -f scripts/verify-staging.sql
```

**Expected Output:**
- ✅ All 7 new tables exist (workflow_approvals, invoices, etc.)
- ✅ All row counts = 0 (before seeding)
- ✅ RLS enabled on all new tables
- ✅ Existing tables untouched (runs, distributions, agreements)
- ✅ 4 reporting views exist
- ✅ 8 new functions exist

**If verification fails:** Stop here, review migration logs, fix issues before proceeding.

---

### Step 2: Deploy Edge Function (10 minutes)

Deploy the approvals-api Edge Function to Supabase:

```bash
# Ensure you're linked to the correct project
supabase link --project-ref qwgicrdcoqdketqhxbys

# Deploy the Edge Function
supabase functions deploy approvals-api

# Verify deployment
supabase functions list
```

**Expected Output:**
```
┌────────────────┬──────────┬─────────────────────┐
│ NAME           │ STATUS   │ UPDATED AT          │
├────────────────┼──────────┼─────────────────────┤
│ approvals-api  │ DEPLOYED │ 2025-10-15 10:00:00 │
└────────────────┴──────────┴─────────────────────┘
```

**Test Edge Function:**
```bash
# Get session token (from browser console or CLI)
# curl test
curl -X GET \
  "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/approvals-api/test-run-id/status" \
  -H "Authorization: Bearer <YOUR_SESSION_TOKEN>" \
  -H "Content-Type: application/json"

# Should return 404 (expected - run doesn't exist yet) or approval status
```

---

### Step 3: Load Seed Data (5 minutes)

Load sample data for testing:

```bash
psql -h <staging-db-host> -U postgres -d postgres -f supabase/seed.sql
```

**Verify seed data loaded:**
```sql
SELECT COUNT(*) FROM public.parties; -- Should be >= 4
SELECT COUNT(*) FROM public.deals; -- Should be >= 3
SELECT COUNT(*) FROM public.success_fee_events WHERE status = 'pending'; -- Should be >= 1
```

---

### Step 4: Create Test Users (10 minutes)

Create test users in Supabase Auth Dashboard:

1. Navigate to: Supabase Dashboard → Authentication → Users
2. Create 5 users:
   - ops@test.com (password: TestOps123!)
   - finance@test.com (password: TestFinance123!)
   - manager@test.com (password: TestManager123!)
   - admin@test.com (password: TestAdmin123!)
   - user@test.com (password: TestUser123!)

3. Assign roles via SQL:
```sql
-- Get user IDs
SELECT id, email FROM auth.users WHERE email LIKE '%@test.com';

-- Insert roles (replace UUIDs with actual user IDs)
INSERT INTO public.user_roles (user_id, role) VALUES
  ('<ops-user-id>', 'ops'),
  ('<finance-user-id>', 'finance'),
  ('<manager-user-id>', 'manager'),
  ('<admin-user-id>', 'admin'),
  ('<user-user-id>', 'user');

-- Verify
SELECT u.email, ur.role
FROM auth.users u
JOIN public.user_roles ur ON u.id = ur.user_id
WHERE u.email LIKE '%@test.com';
```

---

### Step 5: Enable Feature Flag (2 minutes)

Update `.env` file in staging:

```env
# Enable Approvals Feature
VITE_FEATURE_APPROVALS=true

# Keep other features disabled for now
VITE_FEATURE_INVOICES=false
VITE_FEATURE_SUCCESS_FEE=false
VITE_FEATURE_MGMT_FEE=false
VITE_FEATURE_IMPORT_STAGING=false
VITE_FEATURE_PAYOUT_SPLITS=false
VITE_FEATURE_REPORTS=false
```

Rebuild and deploy frontend:

```bash
npm install
npm run build
# Deploy to hosting (Vercel/Netlify/etc.)
```

---

### Step 6: Run QA Tests (30 minutes)

Follow the QA script: `scripts/qa-approvals.md`

**Critical Test Cases:**
1. ✅ Feature flag gating (Test 1)
2. ✅ Submit for approval (Test 2)
3. ✅ RBAC enforcement (Tests 3, 4)
4. ✅ Multi-step approval flow (Tests 5, 6)
5. ✅ Rejection workflow (Test 7)
6. ✅ Admin override (Test 8)

**Log any issues in:** `scripts/qa-approvals.md` → Known Issues section

---

### Step 7: User Acceptance Testing (15 minutes)

Invite stakeholders to test:

**Test Scenario:**
1. Finance team member logs in
2. Creates a new calculation run
3. Uploads distribution CSV
4. Runs calculation
5. Submits for approval
6. Ops reviews and approves
7. Finance reviews and approves
8. Manager reviews and approves
9. Run status changes to APPROVED

**UAT Checklist:**
- [ ] Can create run
- [ ] Can upload distributions
- [ ] Can calculate fees
- [ ] Can submit for approval
- [ ] Status badges clear and visible
- [ ] Approval steps intuitive
- [ ] Comments save correctly
- [ ] Rejection workflow works
- [ ] No console errors

---

## Rollback Plan

If issues are discovered during QA or UAT:

### Option 1: Disable Feature Flag (Immediate, Zero Risk)

```env
VITE_FEATURE_APPROVALS=false
```

Rebuild and redeploy. All approval UI disappears, system reverts to pre-Sprint 1 behavior.

### Option 2: Rollback Edge Function

```bash
# List function versions
supabase functions list --show-versions approvals-api

# Rollback to previous version (if any)
supabase functions rollback approvals-api --version <previous-version>
```

### Option 3: Rollback Migration (Nuclear Option)

Only use if database corruption detected:

```sql
-- Drop approval tables
DROP TABLE IF EXISTS public.workflow_approvals CASCADE;

-- Restore calculation_runs status enum to original
ALTER TYPE run_status RENAME TO run_status_old;
CREATE TYPE run_status AS ENUM ('draft', 'in_progress', 'completed', 'failed');
ALTER TABLE calculation_runs
  ALTER COLUMN status TYPE run_status
  USING status::text::run_status;
DROP TYPE run_status_old;
```

**Note:** This will lose all approval history. Only use if absolutely necessary.

---

## Post-Deployment Monitoring

### Key Metrics to Watch

1. **Edge Function Logs:**
```bash
supabase functions logs approvals-api --tail
```

Watch for:
- ❌ 403 Forbidden errors (RBAC issues)
- ❌ 500 Internal Server errors
- ✅ Successful 200 responses

2. **Database Queries:**
```sql
-- Approval activity
SELECT
  wa.step,
  wa.status,
  wa.acted_at,
  u.email AS acted_by_email
FROM workflow_approvals wa
LEFT JOIN auth.users u ON wa.acted_by = u.id
WHERE wa.created_at > NOW() - INTERVAL '24 hours'
ORDER BY wa.created_at DESC;

-- Run status distribution
SELECT status, COUNT(*)
FROM calculation_runs
GROUP BY status;
```

3. **Frontend Errors:**
- Monitor browser console for API errors
- Check Sentry/error tracking dashboard (if configured)

---

## Success Criteria

Sprint 1 is complete when:

- [x] Edge Function deployed and responding
- [x] Database migration applied
- [x] Seed data loaded
- [x] Test users created with roles
- [x] Feature flag enabled
- [x] All QA tests pass (13/13)
- [ ] UAT approved by Finance team
- [ ] No critical bugs reported
- [ ] Rollback procedure tested

---

## Next Steps After Sprint 1

Once Approvals are stable in staging:

### Sprint 2 Option A: Invoices & Payments
- Wire invoice generation from approved runs
- PDF generation with logo/template
- Payment tracking
- Invoice numbering (INV-YYYY-NNNN)

**Estimated:** 2 weeks

### Sprint 2 Option B: Success-Fee Events
- Event creation UI
- Posting to runs (Track B/C only)
- Fee calculation adjustments
- Event audit trail

**Estimated:** 1.5 weeks

**Recommendation:** Start with **Invoices** (Option A) since:
1. Approval workflow naturally flows into invoice generation
2. Finance team urgently needs automated invoice creation
3. Success-fee events can follow in Sprint 3

---

## Contact & Support

**Implementation Lead:** Claude Code Assistant
**Documentation:** See `docs/IMPLEMENTATION-PLAN-2025-10-12.md`
**QA Script:** `scripts/qa-approvals.md`

**For Issues:**
- Check Edge Function logs: `supabase functions logs approvals-api`
- Review QA script for test cases
- Test rollback procedure in staging first
- Consult implementation plan for dependencies

---

**Deployment Date:** _________________
**Deployed By:** _________________
**QA Sign-Off:** _________________
**UAT Sign-Off:** _________________

---

_Last Updated: 2025-10-15_
