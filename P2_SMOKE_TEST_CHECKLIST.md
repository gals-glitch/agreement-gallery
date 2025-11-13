# P2 Smoke Test Checklist

**Test Date:** _____________
**Tester:** _____________
**Environment:** Staging (qwgicrdcoqdketqhxbys)

---

## Pre-Test Setup

- [ ] All 3 migrations applied successfully
- [ ] Edge Functions deployed (check version in logs)
- [ ] Feature flag `charges_engine` enabled
- [ ] Access token obtained: `export ACCESS_TOKEN="..."`
- [ ] API base URL set: `export API_BASE="https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1"`

---

## Test 1: Create Draft Charge

**Goal:** Verify charge computation works

**Steps:**
1. Get contribution ID from SQL:
   ```sql
   SELECT id FROM contributions
   WHERE investor_id = (SELECT id FROM investors WHERE name ILIKE '%kuperman%')
   LIMIT 1;
   ```
   Contribution ID: ________________

2. Create charge (use service role key):
   ```bash
   curl -X POST "$API_BASE/charges" \
     -H "apikey: YOUR_SERVICE_ROLE_KEY" \
     -H "Content-Type: application/json" \
     -d '{"contribution_id":"CONTRIBUTION_ID"}'
   ```

3. Note charge ID: ________________

**Expected Results:**
- [ ] HTTP 201 Created
- [ ] `status = "DRAFT"`
- [ ] `base_amount > 0` (2% of contribution)
- [ ] `vat_amount > 0` (20% of base)
- [ ] `total_amount = base + vat`
- [ ] `net_amount = total_amount` (no credits yet)
- [ ] `snapshot_json` contains agreement + term + VAT rate

**Actual Results:**
- Status: ________
- Base: $________
- VAT: $________
- Total: $________
- Net: $________

**Pass/Fail:** ___________

---

## Test 2: Get Charge Details

**Goal:** Verify charge retrieval with joined data

**Steps:**
1. Get charge details:
   ```bash
   curl -X GET "$API_BASE/charges/CHARGE_ID" \
     -H "Authorization: Bearer $ACCESS_TOKEN"
   ```

**Expected Results:**
- [ ] HTTP 200 OK
- [ ] Response includes `investor.name`
- [ ] Response includes `deal.name` or `fund.name`
- [ ] Response includes `contribution.amount`
- [ ] `credit_applications` is empty array
- [ ] All amounts match Test 1

**Actual Results:**
- Investor: ________________
- Deal/Fund: ________________
- Contribution Amount: $________
- Credit Apps Count: ________

**Pass/Fail:** ___________

---

## Test 3: Submit Charge (Credits Auto-Apply)

**Goal:** Verify FIFO auto-application of credits

**Pre-Check: Credits Available?**
```sql
SELECT original_amount, available_amount, status
FROM credits_ledger
WHERE investor_id = (SELECT investor_id FROM charges WHERE id = 'CHARGE_ID')
  AND status = 'AVAILABLE';
```
Available Credits: $________ (if 0, this test will show no application)

**Steps:**
1. Submit charge:
   ```bash
   curl -X POST "$API_BASE/charges/CHARGE_ID/submit" \
     -H "Authorization: Bearer $ACCESS_TOKEN"
   ```

**Expected Results:**
- [ ] HTTP 200 OK
- [ ] `status = "PENDING"`
- [ ] `submitted_at` timestamp set
- [ ] `credits_applied_amount >= 0` (may be 0 if no credits available)
- [ ] `net_amount = total_amount - credits_applied_amount`
- [ ] Response includes `credits_applied.amount` and `credits_applied.applications`

**Actual Results:**
- Status: ________
- Credits Applied: $________
- Net Amount: $________
- Applications Count: ________

**Verify in DB:**
```sql
-- Check credits ledger updated
SELECT applied_amount, available_amount, status
FROM credits_ledger
WHERE investor_id = (SELECT investor_id FROM charges WHERE id = 'CHARGE_ID');
```
- Applied increased: [ ] Yes / [ ] No
- Available decreased: [ ] Yes / [ ] No

```sql
-- Check credit applications created
SELECT COUNT(*) FROM credit_applications
WHERE charge_id = (SELECT numeric_id FROM charges WHERE id = 'CHARGE_ID');
```
- Application records: ________ (should match `credits_applied.applications`)

**Pass/Fail:** ___________

---

## Test 4: Reject Charge (Credits Reverse)

**Goal:** Verify credit reversal on rejection

**Steps:**
1. Reject charge:
   ```bash
   curl -X POST "$API_BASE/charges/CHARGE_ID/reject" \
     -H "Authorization: Bearer $ACCESS_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"reject_reason":"Test rejection for smoke test"}'
   ```

**Expected Results:**
- [ ] HTTP 200 OK
- [ ] `status = "REJECTED"`
- [ ] `rejected_by` set to current user ID
- [ ] `rejected_at` timestamp set
- [ ] `reject_reason = "Test rejection for smoke test"`
- [ ] `credits_applied_amount = 0` (reset)
- [ ] `net_amount = total_amount` (restored)

**Actual Results:**
- Status: ________
- Credits Applied: $________ (should be 0)
- Net Amount: $________ (should equal original total)

**Verify in DB:**
```sql
-- Check credits ledger restored
SELECT applied_amount, available_amount, status
FROM credits_ledger
WHERE investor_id = (SELECT investor_id FROM charges WHERE id = 'CHARGE_ID');
```
- Applied decreased back: [ ] Yes / [ ] No
- Available restored: [ ] Yes / [ ] No
- Status = AVAILABLE: [ ] Yes / [ ] No

```sql
-- Check credit applications reversed
SELECT reversed_at, reversed_by FROM credit_applications
WHERE charge_id = (SELECT numeric_id FROM charges WHERE id = 'CHARGE_ID');
```
- Reversed timestamp set: [ ] Yes / [ ] No

**Pass/Fail:** ___________

---

## Test 5: Approve → Mark Paid Workflow

**Goal:** Test full happy path (no rejection)

**Setup: Create New Charge**
1. Get different contribution (without credits):
   ```sql
   SELECT id FROM contributions
   WHERE investor_id NOT IN (
     SELECT DISTINCT investor_id FROM credits_ledger WHERE status = 'AVAILABLE'
   )
   LIMIT 1;
   ```
   Contribution ID: ________________

2. Create charge: (same as Test 1, use new contribution ID)
   Charge ID: ________________

**Steps:**

### 5a. Submit
```bash
curl -X POST "$API_BASE/charges/NEW_CHARGE_ID/submit" \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

**Expected:**
- [ ] `status = "PENDING"`
- [ ] `net_amount = total_amount` (no credits for this investor)

**Actual:**
- Status: ________
- Net: $________

### 5b. Approve (Admin Only)
```bash
curl -X POST "$API_BASE/charges/NEW_CHARGE_ID/approve" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"comment":"Approved for smoke test"}'
```

**Expected:**
- [ ] HTTP 200 OK
- [ ] `status = "APPROVED"`
- [ ] `approved_by` set
- [ ] `approved_at` timestamp set

**Actual:**
- Status: ________
- Approved By: ________________
- Approved At: ________________

### 5c. Mark Paid
```bash
curl -X POST "$API_BASE/charges/NEW_CHARGE_ID/mark-paid" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"paid_at":"2024-10-20T00:00:00Z"}'
```

**Expected:**
- [ ] HTTP 200 OK
- [ ] `status = "PAID"`
- [ ] `paid_at = "2024-10-20T00:00:00Z"`

**Actual:**
- Status: ________
- Paid At: ________________

**Pass/Fail:** ___________

---

## Test 6: RBAC Enforcement

**Goal:** Verify Finance user permissions

**Setup: Login as Finance User**
```bash
# Get finance user token
curl -X POST https://qwgicrdcoqdketqhxbys.supabase.co/auth/v1/token?grant_type=password \
  -H "apikey: YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"email":"finance-test@buligocapital.com","password":"PASSWORD"}'

export FINANCE_TOKEN="extracted-token"
```

**Test 6a: Finance CAN Read**
```bash
curl -X GET "$API_BASE/charges" \
  -H "Authorization: Bearer $FINANCE_TOKEN"
```
- [ ] HTTP 200 OK
- [ ] Returns charges list

**Test 6b: Finance CAN Submit**
```bash
# Create new charge first, then:
curl -X POST "$API_BASE/charges/NEW_CHARGE_ID/submit" \
  -H "Authorization: Bearer $FINANCE_TOKEN"
```
- [ ] HTTP 200 OK
- [ ] Status updated to PENDING

**Test 6c: Finance CANNOT Approve**
```bash
curl -X POST "$API_BASE/charges/NEW_CHARGE_ID/approve" \
  -H "Authorization: Bearer $FINANCE_TOKEN" \
  -d '{"comment":"test"}'
```
- [ ] HTTP 403 Forbidden
- [ ] Error: "Forbidden" or "Admin role required"

**Test 6d: Finance CAN Mark Paid**
```bash
# First approve as admin, then:
curl -X POST "$API_BASE/charges/APPROVED_CHARGE_ID/mark-paid" \
  -H "Authorization: Bearer $FINANCE_TOKEN"
```
- [ ] HTTP 200 OK
- [ ] Status updated to PAID

**Pass/Fail:** ___________

---

## Test 7: Edge Cases

**Test 7a: GP Investor (Fee = $0)**

Setup:
```sql
-- Create GP investor if not exists
INSERT INTO investors (party_id, name, is_gp)
VALUES (..., 'GP Test Investor', true);

-- Create contribution for GP
INSERT INTO contributions (investor_id, deal_id, amount, paid_in_date)
VALUES ((SELECT id FROM investors WHERE is_gp = true LIMIT 1), ..., 50000, '2024-10-15');
```

Test:
```bash
# Create charge for GP contribution
curl -X POST "$API_BASE/charges" \
  -H "apikey: SERVICE_ROLE_KEY" \
  -d '{"contribution_id":"GP_CONTRIBUTION_ID"}'
```

**Expected:**
- [ ] HTTP 201 Created
- [ ] `base_amount = 0`
- [ ] `vat_amount = 0`
- [ ] `total_amount = 0`
- [ ] Charge still created (for audit)

**Actual:**
- Base: $________
- Total: $________

**Pass/Fail:** ___________

---

**Test 7b: No Approved Agreement**

Setup:
```sql
-- Create investor without approved agreement
INSERT INTO investors (party_id, name, is_gp)
VALUES (..., 'No Agreement Investor', false);

-- Create contribution
INSERT INTO contributions (investor_id, deal_id, amount, paid_in_date)
VALUES ((SELECT id FROM investors WHERE name = 'No Agreement Investor'), ..., 25000, '2024-10-15');
```

Test:
```bash
# Try to create charge (should fail or return null)
curl -X POST "$API_BASE/charges" \
  -H "apikey: SERVICE_ROLE_KEY" \
  -d '{"contribution_id":"NO_AGREEMENT_CONTRIBUTION_ID"}'
```

**Expected:**
- [ ] HTTP 200 OK but returns `null` OR HTTP 422 with error message
- [ ] No charge created in database

**Actual:**
- Response: ________________

**Verify:**
```sql
SELECT COUNT(*) FROM charges
WHERE contribution_id = 'NO_AGREEMENT_CONTRIBUTION_ID';
-- Should return: 0
```

**Pass/Fail:** ___________

---

**Test 7c: Partial Credits**

Setup:
```sql
-- Create small credit for investor with large charge
INSERT INTO credits_ledger (investor_id, deal_id, original_amount, status, reason)
VALUES (
  (SELECT investor_id FROM charges WHERE id = 'TEST_CHARGE_ID'),
  (SELECT deal_id FROM charges WHERE id = 'TEST_CHARGE_ID'),
  500,  -- Small credit for large charge
  'AVAILABLE',
  'Partial credit test'
);
```

Test:
```bash
# Create charge with total > $500, then submit
curl -X POST "$API_BASE/charges/LARGE_CHARGE_ID/submit" \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

**Expected:**
- [ ] `credits_applied_amount = 500` (all available credits used)
- [ ] `net_amount = total_amount - 500` (remaining balance)
- [ ] Credit status = FULLY_APPLIED

**Actual:**
- Credits Applied: $________
- Net Amount: $________

**Verify:**
```sql
SELECT status FROM credits_ledger WHERE id = 'SMALL_CREDIT_ID';
-- Should return: FULLY_APPLIED
```

**Pass/Fail:** ___________

---

## Summary

**Total Tests:** 10 (7 main + 3 edge cases)
**Passed:** _____ / 10
**Failed:** _____ / 10

**Critical Issues:** (if any)
_____________________________________________
_____________________________________________

**Go/No-Go Decision:**

- [ ] **GO** - All critical tests passed, proceed to Option A (P2-8 through P2-11)
- [ ] **NO-GO** - Critical issues found, debug before proceeding

**Next Steps:** (if GO)
1. P2-8: Auto-trigger compute on contribution create/update
2. P2-9: Referrer fuzzy matching in CSV import
3. P2-10: Charges list UI (tabs, filters, pagination)
4. P2-11: Charges detail panel (breakdown, actions, FIFO ledger)

**Tester Signature:** ________________
**Date:** ________________
