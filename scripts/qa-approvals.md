# QA Test Script: Approvals Workflow

**Feature:** FEATURE_APPROVALS
**Duration:** 30-45 minutes
**Environment:** Staging (with seed data loaded)
**Prerequisites:**
- Database migrations applied (20251012100000_add_workflow_approvals.sql)
- Seed data loaded (supabase/seed.sql)
- Edge Function deployed (approvals-api)
- Feature flag enabled: `VITE_FEATURE_APPROVALS=true`
- Test users created with roles: ops, finance, manager, admin

---

## Test Users Setup

Create these test users in Supabase Auth and assign roles via `user_roles` table:

| Email | Role | Can Approve |
|-------|------|-------------|
| ops@test.com | ops | ops_review step |
| finance@test.com | finance | finance_review step |
| manager@test.com | manager | final_approval step |
| admin@test.com | admin | All steps |
| user@test.com | user | None |

**SQL to create roles:**
```sql
-- Assuming users already exist in auth.users
INSERT INTO public.user_roles (user_id, role) VALUES
  ((SELECT id FROM auth.users WHERE email = 'ops@test.com'), 'ops'),
  ((SELECT id FROM auth.users WHERE email = 'finance@test.com'), 'finance'),
  ((SELECT id FROM auth.users WHERE email = 'manager@test.com'), 'manager'),
  ((SELECT id FROM auth.users WHERE email = 'admin@test.com'), 'admin'),
  ((SELECT id FROM auth.users WHERE email = 'user@test.com'), 'user');
```

---

## Test Suite

### Test 1: Feature Flag Gating ✅

**Scenario:** When FEATURE_APPROVALS=false, approval UI should be hidden

**Steps:**
1. Set `VITE_FEATURE_APPROVALS=false` in `.env`
2. Rebuild app: `npm run build`
3. Navigate to Calculation Runs page
4. Select any run

**Expected:**
- ❌ No "Approvals" button visible on run cards
- ❌ No "Submit for Approval" button visible
- ❌ ApprovalsDrawer does not render

**Actual:** _[Tester fills in]_

---

### Test 2: Submit Run for Approval ✅

**Scenario:** User submits a completed run for approval workflow

**Prerequisites:**
- VITE_FEATURE_APPROVALS=true
- Login as any user
- At least one run with status: draft, in_progress, or completed

**Steps:**
1. Navigate to Runs tab
2. Select a run with status = "completed"
3. Click the "Users" icon button (Approvals)
4. In the drawer, verify status shows "COMPLETED"
5. Click "Submit for Approval" button
6. Wait for toast notification

**Expected:**
- ✅ Toast: "Submitted for Approval"
- ✅ Run status changes to "AWAITING APPROVAL"
- ✅ Three approval steps created:
  - ops_review (pending)
  - finance_review (pending)
  - final_approval (pending)
- ✅ "Submit for Approval" button disappears

**Actual:** _[Tester fills in]_

**SQL Verification:**
```sql
SELECT * FROM public.workflow_approvals WHERE run_id = '[RUN_ID]';
-- Should return 3 rows, all with status = 'pending'

SELECT status FROM public.calculation_runs WHERE id = '[RUN_ID]';
-- Should return 'awaiting_approval'
```

---

### Test 3: RBAC - Ops Review Approval ✅

**Scenario:** Ops user approves ops_review step

**Prerequisites:**
- Run status = awaiting_approval
- Login as ops@test.com

**Steps:**
1. Navigate to Runs tab
2. Select the run from Test 2
3. Open Approvals drawer
4. Verify you see 3 steps:
   - ⏳ Operations Review (pending)
   - ⏳ Finance Review (pending)
   - ⏳ Final Approval (pending)
5. In "Operations Review" section:
   - Enter comment: "Distributions verified"
   - Click "Approve"

**Expected:**
- ✅ Toast: "Step Approved - Operations Review has been approved"
- ✅ ops_review step shows:
  - ✅ Status badge: "approved"
  - ✅ Approved by: ops@test.com
  - ✅ Timestamp displayed
  - ✅ Comment: "Distributions verified"
- ✅ finance_review and final_approval still pending
- ✅ Run status still "awaiting_approval"

**Actual:** _[Tester fills in]_

---

### Test 4: RBAC - Permission Denied ✅

**Scenario:** User without finance role tries to approve finance_review step

**Prerequisites:**
- Run status = awaiting_approval
- ops_review = approved
- Login as ops@test.com (no finance role)

**Steps:**
1. Open Approvals drawer for same run
2. Try to click "Approve" on finance_review step

**Expected:**
- ✅ Toast: "Permission Denied - You need finance role to approve this step"
- ❌ finance_review status unchanged (pending)

**Actual:** _[Tester fills in]_

---

### Test 5: Finance Review Approval ✅

**Scenario:** Finance user approves finance_review step

**Prerequisites:**
- ops_review = approved
- Login as finance@test.com

**Steps:**
1. Open Approvals drawer
2. Verify ops_review shows ✅ approved
3. In "Finance Review" section:
   - Enter comment: "VAT calculations correct"
   - Click "Approve"

**Expected:**
- ✅ Toast: "Step Approved - Finance Review has been approved"
- ✅ finance_review status = approved
- ✅ Run status still "awaiting_approval" (final step pending)

**Actual:** _[Tester fills in]_

---

### Test 6: Final Approval (All Steps Complete) ✅

**Scenario:** Manager approves final step, run transitions to 'approved'

**Prerequisites:**
- ops_review = approved
- finance_review = approved
- Login as manager@test.com

**Steps:**
1. Open Approvals drawer
2. Verify first two steps show ✅ approved
3. In "Final Approval" section:
   - Enter comment: "Ready for invoicing"
   - Click "Approve"

**Expected:**
- ✅ Toast: "Step Approved - Final Approval has been approved"
- ✅ final_approval status = approved
- ✅ Run status changes to "APPROVED"
- ✅ Green success banner appears:
  - "Approved for Export"
  - "This run can now generate invoices and be exported"
- ✅ All three steps show green checkmarks

**Actual:** _[Tester fills in]_

**SQL Verification:**
```sql
SELECT status FROM public.workflow_approvals WHERE run_id = '[RUN_ID]';
-- All 3 should return 'approved'

SELECT status FROM public.calculation_runs WHERE id = '[RUN_ID]';
-- Should return 'approved'
```

---

### Test 7: Rejection Workflow ✅

**Scenario:** Finance user rejects a step, run reverts to 'in_progress'

**Prerequisites:**
- Create new run and submit for approval
- Ops approves ops_review
- Login as finance@test.com

**Steps:**
1. Open Approvals drawer
2. In "Finance Review" section:
   - Leave comment field empty
   - Click "Reject"

**Expected:**
- ✅ Toast: "Comment Required - Please provide a reason for rejection"
- ❌ finance_review status unchanged

**Steps (continued):**
3. Enter comment: "VAT rates need correction for UK investors"
4. Click "Reject"

**Expected:**
- ✅ Toast: "Step Rejected - Run has been returned to In Progress status"
- ✅ finance_review status = rejected
- ✅ Run status changes to "IN PROGRESS"
- ✅ Comment visible in drawer

**Actual:** _[Tester fills in]_

**SQL Verification:**
```sql
SELECT status, comment FROM public.workflow_approvals
WHERE run_id = '[RUN_ID]' AND step = 'finance_review';
-- Should show status = 'rejected', comment = 'VAT rates need...'

SELECT status FROM public.calculation_runs WHERE id = '[RUN_ID]';
-- Should return 'in_progress'
```

---

### Test 8: Admin Override ✅

**Scenario:** Admin user can approve any step

**Prerequisites:**
- Run status = awaiting_approval
- All steps pending
- Login as admin@test.com

**Steps:**
1. Open Approvals drawer
2. Approve ops_review (no comment)
3. Approve finance_review (comment: "Admin override")
4. Approve final_approval

**Expected:**
- ✅ All three approvals succeed
- ✅ No permission denied errors
- ✅ Run status changes to "APPROVED"
- ✅ acted_by_user shows admin@test.com for all steps

**Actual:** _[Tester fills in]_

---

### Test 9: Cannot Re-Submit Approved Run ✅

**Scenario:** Approved runs cannot be re-submitted

**Prerequisites:**
- Run status = approved

**Steps:**
1. Open Approvals drawer for approved run
2. Look for "Submit for Approval" button

**Expected:**
- ❌ "Submit for Approval" button not visible
- ✅ Only approval history shown
- ✅ Green success banner visible

**Actual:** _[Tester fills in]_

---

### Test 10: Status Badges in Run List ✅

**Scenario:** Run list shows correct status badges

**Steps:**
1. Navigate to Runs tab
2. Create multiple runs with different statuses:
   - Run A: draft
   - Run B: in_progress
   - Run C: awaiting_approval (submitted)
   - Run D: approved (all steps approved)

**Expected:**
- ✅ Run A badge: "DRAFT" (secondary variant)
- ✅ Run B badge: "IN PROGRESS" (secondary variant)
- ✅ Run C badge: "AWAITING APPROVAL" (secondary variant)
- ✅ Run D badge: "APPROVED" (default variant, green)

**Actual:** _[Tester fills in]_

---

### Test 11: Approval History Persistence ✅

**Scenario:** Approval history persists and shows correct user info

**Prerequisites:**
- Fully approved run with comments from ops, finance, manager

**Steps:**
1. Logout and login as different user
2. Open Approvals drawer for approved run
3. Review approval history

**Expected:**
- ✅ All three steps show:
  - ✅ Approved status
  - ✅ Approver email (e.g., ops@test.com)
  - ✅ Timestamp
  - ✅ Comments (if provided)
- ✅ Steps ordered: ops → finance → manager

**Actual:** _[Tester fills in]_

---

### Test 12: Edge Function Error Handling ✅

**Scenario:** Test API error handling

**Steps:**
1. Login as user@test.com (no approval roles)
2. Manually call approvals API via browser console:
```javascript
const { data: { session } } = await supabase.auth.getSession();
const response = await fetch(
  `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/approvals-api/[RUN_ID]/approve`,
  {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${session.access_token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ step: 'ops_review', comment: 'test' })
  }
);
console.log(await response.json());
```

**Expected:**
- ✅ HTTP 403 Forbidden
- ✅ Error: "Unauthorized: requires ops role"

**Actual:** _[Tester fills in]_

---

### Test 13: Multiple Concurrent Approvals ✅

**Scenario:** Test concurrency handling

**Prerequisites:**
- Two runs both awaiting approval

**Steps:**
1. Login as ops@test.com
2. Approve ops_review for Run A
3. Approve ops_review for Run B
4. Login as finance@test.com
5. Approve finance_review for Run A
6. Approve finance_review for Run B

**Expected:**
- ✅ All approvals succeed independently
- ✅ No data corruption
- ✅ Each run tracks its own approval state

**Actual:** _[Tester fills in]_

---

## Summary Checklist

- [ ] All tests passed
- [ ] Feature flag correctly gates UI
- [ ] RBAC enforced at API level
- [ ] Run status transitions correctly
- [ ] Approval history persists
- [ ] Comments required for rejection
- [ ] Admin can override all steps
- [ ] No data corruption with concurrent approvals
- [ ] Error messages are user-friendly
- [ ] No console errors during normal flow

---

## Known Issues / Notes

_[Tester adds any issues discovered]_

---

## Sign-Off

**Tested By:** _________________
**Date:** _________________
**Environment:** _________________
**Result:** ☐ PASS  ☐ FAIL  ☐ PASS WITH ISSUES

**Notes:**

