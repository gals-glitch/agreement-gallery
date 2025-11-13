# Testing Guide: Commission Golden Path

**Objective**: Verify end-to-end commission workflow from draft → pending → approved → paid

**Server**: http://localhost:8080/
**Status**: ✅ Running

---

## Pre-Test Setup

### Current State (From Sprint Review)
- ✅ **30 draft commissions** created
- ✅ **$42,435.90 total value**
- ✅ Top commission: $4,680.00 (Amir Shapira → Avi Fried)
- ✅ All agreements approved
- ✅ All calculations verified

### Test Data Available
```
Commission IDs to test with:
- a993afe3-3867-437f-89b9-dc939d0f2574 ($4,680.00 - highest value)
- 17c9d2a1-be68-410d-8786-7fca386d218d ($3,510.00)
- 7b439707-4ed9-44b1-90fe-d5a8987fe1b8 ($2,925.00)
```

---

## Test Scenario 1: View Commissions List

**Route**: `/commissions`

### Steps:
1. Open http://localhost:8080/
2. Log in with admin credentials
3. Navigate to "Commissions" in the menu
4. Verify page loads successfully

### Expected Results:
- ✅ Page title: "Commissions" or similar
- ✅ Table/list showing 30 draft commissions
- ✅ Columns visible:
  - Commission ID
  - Investor name
  - Party name
  - Deal name
  - Base amount
  - VAT amount
  - Total amount
  - Status badge (Draft)
- ✅ Status filter working (Draft selected shows 30)
- ✅ Search/filter functionality present

### Screenshots to Capture:
- Full commissions list page
- Filter panel (if present)
- Sample commission row

---

## Test Scenario 2: View Commission Detail

**Route**: `/commissions/:id`

### Steps:
1. From commissions list, click on the highest value commission
   - ID: `a993afe3-3867-437f-89b9-dc939d0f2574`
   - Investor: Amir Shapira
   - Total: $4,680.00

2. Verify detail page loads

### Expected Results:
- ✅ Commission ID displayed
- ✅ Status badge: "Draft"
- ✅ Investor information card:
  - Name: Amir Shapira
  - Link to investor detail (optional)
- ✅ Party information card:
  - Name: Avi Fried (פאים הולדינגס)
  - Link to party detail (optional)
- ✅ Deal information card:
  - Name: 100 City View Buligo LP
  - Link to deal detail (optional)
- ✅ Financial breakdown:
  - Base amount: $4,000.00
  - VAT amount: $680.00 (17%)
  - Total amount: $4,680.00
- ✅ Contribution information:
  - Contribution ID (link)
  - Contribution amount
  - Contribution date
- ✅ Computed at timestamp visible
- ✅ Action buttons visible (depends on status):
  - "Submit for Approval" button (enabled for draft)
  - "Approve" button (disabled/hidden for draft)
  - "Mark as Paid" button (disabled/hidden for draft)

### Screenshots to Capture:
- Full commission detail page
- Financial breakdown section
- Action buttons

---

## Test Scenario 3: Submit Commission for Approval

**Route**: `/commissions/:id` (detail page)

### Steps:
1. On commission detail page (draft status)
2. Click "Submit for Approval" button
3. Confirm action if dialog appears

### Expected Results:
- ✅ Button shows loading state during submission
- ✅ Success toast/notification: "Commission submitted for approval"
- ✅ Page refreshes or status updates automatically
- ✅ Status badge changes from "Draft" to "Pending"
- ✅ "Submit" button disappears or becomes disabled
- ✅ "Approve" button becomes visible/enabled (admin only)
- ✅ Database record updated:
  ```sql
  SELECT id, status FROM commissions
  WHERE id = 'a993afe3-3867-437f-89b9-dc939d0f2574';
  -- Should show: status = 'pending'
  ```

### Screenshots to Capture:
- Status badge after submit
- Updated action buttons
- Success notification

---

## Test Scenario 4: Approve Commission (Admin Only)

**Route**: `/commissions/:id` (detail page, pending status)

### Steps:
1. Ensure you're logged in as admin role
2. On commission detail page (pending status)
3. Click "Approve" button
4. Confirm action if dialog appears

### Expected Results:
- ✅ Button shows loading state
- ✅ Success toast: "Commission approved"
- ✅ Status badge changes to "Approved"
- ✅ "Approve" button disappears
- ✅ "Mark as Paid" button becomes visible/enabled
- ✅ Database record updated:
  ```sql
  SELECT id, status FROM commissions
  WHERE id = 'a993afe3-3867-437f-89b9-dc939d0f2574';
  -- Should show: status = 'approved'
  ```

### Screenshots to Capture:
- Approve button click
- Status change to Approved
- New action button (Mark as Paid)

---

## Test Scenario 5: Mark Commission as Paid (Admin JWT Required)

**Route**: `/commissions/:id` (detail page, approved status)

### Steps:
1. Ensure you're logged in as admin with JWT (NOT service key)
2. On commission detail page (approved status)
3. Click "Mark as Paid" button
4. If payment date picker appears, select today's date
5. Confirm action

### Expected Results:
- ✅ Button shows loading state
- ✅ Success toast: "Commission marked as paid"
- ✅ Status badge changes to "Paid"
- ✅ Payment date displayed: [Today's date]
- ✅ All action buttons disabled/hidden (workflow complete)
- ✅ Page may show "Completed" state or confetti animation
- ✅ Database record updated:
  ```sql
  SELECT id, status, paid_at FROM commissions
  WHERE id = 'a993afe3-3867-437f-89b9-dc939d0f2574';
  -- Should show: status = 'paid', paid_at = [today's timestamp]
  ```

### Screenshots to Capture:
- Mark as Paid button
- Payment confirmation dialog (if any)
- Final "Paid" status
- Paid date displayed

---

## Test Scenario 6: Verify Service Key Blocked from Mark Paid

**Route**: API endpoint directly

### Steps:
1. Open browser dev tools (F12) → Console
2. Run this JavaScript:
   ```javascript
   fetch('https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1/commissions/a993afe3-3867-437f-89b9-dc939d0f2574/mark-paid', {
     method: 'POST',
     headers: {
       'Authorization': 'Bearer [SERVICE_ROLE_KEY]',
       'Content-Type': 'application/json'
     },
     body: JSON.stringify({ paid_at: new Date().toISOString() })
   })
   .then(r => r.json())
   .then(console.log)
   .catch(console.error);
   ```
3. Replace `[SERVICE_ROLE_KEY]` with actual service key from `.env`

### Expected Results:
- ✅ Response status: 403 Forbidden
- ✅ Error message: "Service keys cannot mark commissions as paid. Use admin JWT."
- ✅ Commission status remains unchanged

### Screenshots to Capture:
- Console showing 403 error
- Error message content

---

## Test Scenario 7: Verify Workflow Immutability

**Route**: Multiple checks

### Steps:
1. Try to submit already-pending commission
2. Try to approve already-approved commission
3. Try to mark already-paid commission as paid again

### Expected Results:
- ✅ Buttons are disabled or hidden for invalid transitions
- ✅ If API call is possible, returns error: "Invalid status transition"
- ✅ Commission status does not change
- ✅ User-friendly error message displayed

---

## Test Scenario 8: Verify Calculation Details

**Route**: `/commissions/:id` (detail page)

### Steps:
1. View commission detail for ID `a993afe3-3867-437f-89b9-dc939d0f2574`
2. Check if calculation breakdown is visible

### Expected Results (if UI-02 implemented):
- ✅ "Applied Agreement" card visible
- ✅ Shows:
  - Agreement ID: clickable link
  - Rate: 100 bps (1.00%)
  - VAT: 17% VAT on top
  - Formula: $40,000 × (100 / 10,000) = $4,000 + $680 VAT = $4,680
  - Effective period: 2020-01-01 to ongoing

### If not implemented:
- ℹ️ Note missing features for UI-02 ticket
- ℹ️ Verify `snapshot_json` contains calculation details via SQL:
  ```sql
  SELECT snapshot_json FROM commissions
  WHERE id = 'a993afe3-3867-437f-89b9-dc939d0f2574';
  ```

---

## Test Scenario 9: Test Multiple Commissions

**Steps**:
1. Repeat Scenarios 3-5 with two more commissions:
   - `17c9d2a1-be68-410d-8786-7fca386d218d` ($3,510.00)
   - `7b439707-4ed9-44b1-90fe-d5a8987fe1b8` ($2,925.00)

2. Verify final state:
   - 3 commissions in "paid" status
   - 27 commissions remain in "draft" status

### SQL Verification:
```sql
SELECT status, COUNT(*) as count, SUM(total_amount) as total
FROM commissions
GROUP BY status
ORDER BY status;
```

**Expected**:
```
| status   | count | total      |
|----------|-------|------------|
| draft    | 27    | ~$31,460   |
| paid     | 3     | ~$11,115   |
```

---

## Regression Tests

### Test that existing functionality still works:

1. **Contributions Page** (`/contributions`)
   - ✅ 100 contributions visible
   - ✅ Filter/search working
   - ✅ No console errors

2. **Investors Page** (`/investors`)
   - ✅ 1,014 investors visible
   - ✅ 14 show party link badge/icon
   - ✅ Filter by "Has Party Link" working

3. **Parties Page** (`/parties`)
   - ✅ All parties listed
   - ✅ Avi Fried (פאים הולדינגס) visible
   - ✅ Capital Link Family Office visible
   - ✅ David Kirchenbaum (קרוס ארץ' החזקות) visible

4. **Deals Page** (`/deals`)
   - ✅ All deals listed
   - ✅ Search working
   - ✅ Deal detail pages accessible

---

## Performance Tests

### Check page load times:

1. **Commissions List** - Should load in <2 seconds
2. **Commission Detail** - Should load in <1 second
3. **Submit/Approve/Mark Paid** - Should complete in <3 seconds

### Database Query Performance:
```sql
EXPLAIN ANALYZE
SELECT c.id, i.name, p.name, d.name, c.total_amount, c.status
FROM commissions c
JOIN investors i ON i.id = c.investor_id
JOIN parties p ON p.id = c.party_id
JOIN deals d ON d.id = c.deal_id
WHERE c.status = 'draft'
ORDER BY c.total_amount DESC;
```

**Expected**: Query time < 100ms

---

## Bug Reporting Template

If issues found, document with:

```
**Bug ID**: [AUTO-INCREMENT]
**Severity**: Critical | High | Medium | Low
**Component**: Commissions List | Commission Detail | API | Database
**Steps to Reproduce**:
1. ...
2. ...
3. ...

**Expected**: [what should happen]
**Actual**: [what actually happened]
**Screenshots**: [attach]
**Console Errors**: [paste from dev tools]
**SQL State**: [if applicable]
```

---

## Success Criteria

### Minimum for Sign-Off:
- [ ] ✅ 1+ commission in "paid" status via UI
- [ ] ✅ Service key blocked from mark-paid (403 error)
- [ ] ✅ All status transitions working (draft → pending → approved → paid)
- [ ] ✅ No console errors during workflow
- [ ] ✅ Database records accurate
- [ ] ✅ Toast notifications clear and helpful
- [ ] ✅ Calculation amounts match expected values

### Nice-to-Have:
- [ ] ⭐ 25+ commissions approved (bulk testing)
- [ ] ⭐ Applied Agreement card visible (UI-02)
- [ ] ⭐ Performance under load (100+ commissions)

---

## Next Steps After Testing

1. **Document Results**
   - Screenshot gallery
   - Bug list (if any)
   - Performance metrics

2. **Update Sprint Review**
   - Mark "Golden Path" as complete
   - Update DoD checklist in `SPRINT_REVIEW_GATE_A_COV_01.md`

3. **Proceed to DB-02**
   - Run remediation queries for 72 blocked contributions
   - Unlock remaining commission value

4. **Implement UI Enhancements**
   - UI-01: Compute Eligible button
   - UI-02: Applied Agreement card

---

**Ready to Test!** 🚀

**Start with**: http://localhost:8080/commissions

**Test Duration**: ~20 minutes for full golden path
**Priority**: Test Scenarios 1-5 (core workflow)
