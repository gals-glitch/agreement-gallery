# 🚀 Commissions MVP - Action Plan

**Your Step-by-Step Checklist to Complete the MVP**

---

## 📊 **Current Status**

✅ **Backend**: 100% Complete (deployed to production)
✅ **Frontend**: 100% Complete (just built, ready to test)
🔴 **Database Setup**: **BLOCKED - YOU NEED TO RUN SQL** (5 minutes)

---

## 🎯 **Action Checklist**

### Phase 1: Database Setup (5 minutes) 🔴 **START HERE**

#### Step 1.1: Run SQL Setup Script

**The SQL is already in your clipboard!** I copied it earlier.

1. Open Supabase SQL Editor:
   ```
   https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys/sql/new
   ```

2. Paste the SQL (Ctrl+V)

3. Click **Run** (or press Ctrl+Enter)

4. **IMPORTANT**: Copy the output! You'll need:
   - Party ID (Kuperman)
   - Deal ID
   - Test contribution IDs

**What this script does:**
- ✅ Enables `commissions_engine` feature flag
- ✅ Creates commission agreement for Kuperman party
- ✅ Links test investor to party
- ✅ Shows test data for API testing

**Expected Output:**
```
NOTICE: Using Party ID: <uuid>
NOTICE: Using Deal ID: <number>
NOTICE: Commission agreement created/verified
NOTICE: Linked investor <uuid> to party <uuid>

--- Then shows tables with:
- Feature flag enabled: 1
- Commission agreements: 1
- Linked investors: 1+
- Test contributions with party links
```

#### Step 1.2: Verify Setup
After running the script, verify:
```sql
-- Should return 1 row with enabled=true
SELECT * FROM feature_flags WHERE key = 'commissions_engine';

-- Should return at least 1 row
SELECT * FROM agreements WHERE kind = 'distributor_commission';

-- Should return at least 1 row
SELECT * FROM investors WHERE introduced_by IS NOT NULL;
```

---

### Phase 2: API Testing (10 minutes)

#### Step 2.1: Get JWT Token

Option A: Use helper script
```powershell
.\get_jwt_token.ps1
```

Option B: Manual (if script doesn't work)
1. Open http://localhost:8081 in browser
2. Sign in with admin account
3. Open DevTools (F12) → Console tab
4. Paste and run:
   ```javascript
   (await supabase.auth.getSession()).data.session.access_token
   ```
5. Copy the token (long string)
6. Set environment variable:
   ```powershell
   $env:ADMIN_JWT = "your-token-here"
   ```

#### Step 2.2: Run API Smoke Tests

```powershell
.\test_api_commissions_smoke.ps1
```

**You'll be prompted for:**
- Contribution ID (get from SQL output in Step 1.1)
- Additional contribution IDs for batch test (optional)

**Expected Results:**
- ✅ [API-01] Commission computed (returns DRAFT commission)
- ✅ [API-02-A] List shows the commission
- ✅ [API-02-B] Submit succeeds (DRAFT → pending)
- ✅ [API-02-C] Approve succeeds (pending → approved)
- ✅ [API-02-D] Service key blocked from mark-paid (403 error)
- ✅ [API-02-E] Admin JWT marks as paid (approved → paid)
- ⏭️ [API-03] Batch compute (optional)

**If tests fail:**
- Check JWT token is valid (may have expired)
- Check contribution_id exists in database
- Check investor has `introduced_by` set
- Check Supabase Edge Functions logs

---

### Phase 3: UI Testing (15 minutes)

#### Step 3.1: Start Dev Server (if not running)
```bash
npm run dev
```

#### Step 3.2: Navigate to Commissions
Open: http://localhost:8081/commissions

**Expected:**
- Sidebar shows "Commissions" under WORKFLOW section
- Page loads with 5 tabs: Draft | Pending | Approved | Paid | Rejected
- Filters for Party, Investor, Fund/Deal
- Empty state if no commissions yet

#### Step 3.3: Test Compute Commission
1. Go to Contributions page
2. Find a contribution with `introduced_by` party link
3. Click "Compute Commission" (or use API endpoint)
4. Go back to Commissions → Draft tab
5. Should see new commission

#### Step 3.4: Test Full Workflow (Happy Path)

**DRAFT → PENDING:**
1. Click on a DRAFT commission row
2. Detail page opens
3. Click **Submit** button (Finance+ role)
4. Toast: "Commission submitted"
5. Status changes to "pending"
6. Go back to list → should be in Pending tab

**PENDING → APPROVED:**
1. Open the pending commission
2. Click **Approve** button (Admin only)
3. Toast: "Commission approved"
4. Status changes to "approved"
5. Go back to list → should be in Approved tab

**APPROVED → PAID:**
1. Open the approved commission
2. Click **Mark Paid** button (Admin only)
3. Modal opens: "Mark Commission as Paid"
4. Enter payment reference: `WIRE-2025-001`
5. Click **Confirm**
6. Toast: "Commission marked as paid"
7. Status changes to "paid"
8. Go back to list → should be in Paid tab

#### Step 3.5: Test Rejection Workflow

**PENDING → REJECTED:**
1. Create another commission (compute from contribution)
2. Submit it (DRAFT → pending)
3. Open the pending commission
4. Click **Reject** button (Admin only)
5. Modal opens: "Reject Commission"
6. Enter reason: `Missing supporting documents`
7. Click **Confirm**
8. Toast: "Commission rejected"
9. Status changes to "rejected"
10. Go back to list → should be in Rejected tab

#### Step 3.6: Test RBAC

**As Finance user:**
- ✅ Can view all commissions
- ✅ Can submit DRAFT commissions
- ❌ Cannot approve, reject, or mark paid

**As Admin user:**
- ✅ Can view all commissions
- ✅ Can submit DRAFT commissions
- ✅ Can approve PENDING commissions
- ✅ Can reject PENDING commissions
- ✅ Can mark APPROVED commissions as paid

**As Ops/Manager user:**
- ✅ Can view all commissions
- ❌ Cannot submit, approve, reject, or mark paid

---

### Phase 4: Reporting (15 minutes)

#### Step 4.1: Run Party Payout Report

Open Supabase SQL Editor and run queries from:
```
party_payout_report.sql
```

**Option 1: Simple Summary**
```sql
SELECT
  party_name,
  status,
  COUNT(*) as commission_count,
  SUM(total_amount) as total_due
FROM commissions
WHERE status IN ('approved', 'paid')
GROUP BY party_name, status
ORDER BY party_name;
```

**Expected Output:**
```
party_name       | status   | commission_count | total_due
-----------------|----------|------------------|----------
Kuperman         | approved | 2                | 3000.00
Kuperman         | paid     | 1                | 1500.00
```

#### Step 4.2: Export for Payment Processing

Run Option 6 from `party_payout_report.sql`:
```sql
SELECT
  c.party_name as "Party Name",
  c.total_amount as "Total Due ($)",
  c.status as "Status",
  c.payment_ref as "Payment Reference"
FROM commissions c
WHERE c.status IN ('approved', 'paid')
ORDER BY c.party_name;
```

Copy results and paste into Excel for accounting team.

---

### Phase 5: QA & Verification (10 minutes)

#### Step 5.1: Verify Security

**Test 1: Service Key Blocked from Mark-Paid**
```powershell
# Should return 403 Forbidden
curl -X POST \
  -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
  -H "apikey: $SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"payment_ref":"WIRE-001"}' \
  https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1/commissions/<ID>/mark-paid
```

**Test 2: Non-Admin Cannot Approve**
- Sign in as Finance user
- Try to click Approve button
- Should be hidden or disabled

#### Step 5.2: Verify Data Integrity

Run verification queries:
```sql
-- All commissions should have party links
SELECT COUNT(*) FROM commissions WHERE party_id IS NULL;
-- Should return: 0

-- All paid commissions should have payment_ref
SELECT COUNT(*) FROM commissions
WHERE status = 'paid' AND payment_ref IS NULL;
-- Should return: 0

-- Rejected commissions should have reject_reason
SELECT COUNT(*) FROM commissions
WHERE status = 'rejected' AND reject_reason IS NULL;
-- Should return: 0

-- Amounts should reconcile
SELECT
  SUM(base_amount) + SUM(vat_amount) as calculated_total,
  SUM(total_amount) as stored_total
FROM commissions;
-- calculated_total should equal stored_total
```

#### Step 5.3: Test Error Cases

**Test 1: Invalid Contribution ID (404)**
```powershell
curl -X POST \
  -H "Authorization: Bearer $ADMIN_JWT" \
  -H "Content-Type: application/json" \
  -d '{"contribution_id":"00000000-0000-0000-0000-000000000000"}' \
  https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1/commissions/compute
```

**Test 2: Reject Without Reason (400)**
```powershell
curl -X POST \
  -H "Authorization: Bearer $ADMIN_JWT" \
  -H "Content-Type: application/json" \
  -d '{"reason":""}' \
  https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1/commissions/<ID>/reject
```

**Test 3: Invalid State Transition (409)**
Try to approve a DRAFT commission (should fail, must submit first)

---

### Phase 6: Documentation (5 minutes)

#### Step 6.1: Update OpenAPI Spec (Optional)

Add commissions endpoints to `docs/openapi.yaml`:
```yaml
/commissions:
  get:
    summary: List commissions
    parameters:
      - name: status
        in: query
        schema:
          type: string
          enum: [draft, pending, approved, paid, rejected]
  # ... etc
```

#### Step 6.2: Take Screenshots

For documentation/demo:
1. Commissions list page (all 5 tabs)
2. Commission detail page (overview + breakdown)
3. Modal dialogs (Reject and Mark Paid)
4. Party payout report results

---

## ✅ **Success Criteria**

At the end of this action plan, you should have:

- ✅ Feature flag enabled in database
- ✅ Test commission agreement created
- ✅ Test investor linked to party
- ✅ All 8 API endpoints tested and working
- ✅ Full workflow tested: draft → submit → approve → mark-paid
- ✅ Rejection workflow tested: pending → rejected
- ✅ UI pages accessible and functional
- ✅ RBAC enforced correctly (Finance vs Admin)
- ✅ Service key blocked from mark-paid
- ✅ Party payout report generated
- ✅ Data integrity verified

---

## 🐛 **Troubleshooting Guide**

### Issue: Feature flag not visible in UI
**Solution:**
```sql
UPDATE feature_flags
SET enabled = TRUE
WHERE key = 'commissions_engine';
```

### Issue: No commissions showing in list
**Solution:**
1. Check feature flag is enabled
2. Compute a commission from API or UI
3. Verify investor has `introduced_by` link

### Issue: "No agreement found" error when computing
**Solution:**
1. Check agreement exists: `SELECT * FROM agreements WHERE kind = 'distributor_commission'`
2. Check agreement status is APPROVED
3. Check agreement scope matches contribution (fund OR deal)
4. Check snapshot_json has terms array

### Issue: JWT token expired (401)
**Solution:**
1. Sign in again
2. Get fresh token from DevTools
3. Update `$env:ADMIN_JWT`

### Issue: API returns 403 Forbidden
**Solution:**
1. Check user has correct role (admin or finance)
2. Check JWT token is from correct user
3. For mark-paid: ensure using Admin JWT, not service key

### Issue: Commission amounts are $0.00
**Solution:**
1. Check agreement snapshot_json has rate_bps > 0
2. Check contribution amount > 0
3. Check VAT rate if applicable

---

## 📊 **Time Estimate**

| Phase | Task | Est. Time |
|-------|------|-----------|
| 1 | Database Setup | 5 min |
| 2 | API Testing | 10 min |
| 3 | UI Testing | 15 min |
| 4 | Reporting | 15 min |
| 5 | QA & Verification | 10 min |
| 6 | Documentation | 5 min |
| **Total** | | **60 min** |

---

## 🎉 **You're Ready!**

Everything is built and ready to test. Start with **Phase 1: Database Setup** and work through the checklist.

**Files Ready for You:**
- ✅ `setup_commissions_unblockers.sql` - Already in clipboard
- ✅ `test_api_commissions_smoke.ps1` - API tests
- ✅ `get_jwt_token.ps1` - JWT helper
- ✅ `party_payout_report.sql` - Reporting queries
- ✅ `COMMISSIONS_MVP_STATUS.md` - Status summary
- ✅ `ACTION_PLAN_MVP.md` - This document

**Your Next Command:**
Open Supabase SQL Editor and paste the SQL from your clipboard!

---

**Questions or Issues?** Check the troubleshooting guide above or refer to `COMMISSIONS_MVP_STATUS.md`.

Good luck! 🚀
