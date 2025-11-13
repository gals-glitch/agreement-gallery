# Charges API Integration Tests (P2-4)

**Purpose:** Validate all charge management endpoints and workflow transitions.

**Prerequisites:**
- Database migrated with charges table (P2-1)
- Test users with different roles: admin, finance, ops, viewer
- Test data: investors, deals, funds, contributions

---

## Test Suite 1: POST /api/v1/charges (Create Charge - Internal)

### Test 1.1: Create valid deal-scoped charge
**Auth:** Service role (no user token)
**Request:**
```json
POST /api/v1/charges
{
  "investor_id": 1,
  "deal_id": 100,
  "contribution_id": 500,
  "status": "DRAFT",
  "base_amount": 10000.00,
  "discount_amount": 500.00,
  "vat_amount": 1950.00,
  "total_amount": 11450.00,
  "currency": "USD",
  "snapshot_json": {
    "agreement_snapshot": { "id": "abc", "upfront_bps": 100 },
    "vat_snapshot": { "rate": 0.20 }
  },
  "computed_at": "2025-10-19T12:00:00Z"
}
```
**Expected:** 201 Created with charge object
**Validates:** XOR constraint (deal_id only), all required fields

### Test 1.2: Create valid fund-scoped charge
**Auth:** Service role
**Request:**
```json
POST /api/v1/charges
{
  "investor_id": 1,
  "fund_id": 200,
  "contribution_id": 501,
  "status": "DRAFT",
  "base_amount": 5000.00,
  "discount_amount": 0,
  "vat_amount": 1000.00,
  "total_amount": 6000.00,
  "currency": "EUR",
  "snapshot_json": {
    "agreement_snapshot": { "id": "xyz", "upfront_bps": 50 },
    "vat_snapshot": { "rate": 0.20 }
  },
  "computed_at": "2025-10-19T12:00:00Z"
}
```
**Expected:** 201 Created
**Validates:** XOR constraint (fund_id only)

### Test 1.3: Fail - both deal_id and fund_id (XOR violation)
**Auth:** Service role
**Request:**
```json
POST /api/v1/charges
{
  "investor_id": 1,
  "deal_id": 100,
  "fund_id": 200,
  "contribution_id": 502,
  "status": "DRAFT",
  "base_amount": 5000.00,
  "total_amount": 6000.00,
  "currency": "USD",
  "snapshot_json": {}
}
```
**Expected:** 422 Validation Error
**Error:** "Exactly one of deal_id or fund_id is required"

### Test 1.4: Fail - missing required fields
**Auth:** Service role
**Request:**
```json
POST /api/v1/charges
{
  "investor_id": 1,
  "deal_id": 100
}
```
**Expected:** 422 Validation Error
**Error:** Multiple validation errors for missing fields

---

## Test Suite 2: GET /api/v1/charges (List Charges)

### Test 2.1: List all charges (Finance role)
**Auth:** Finance user token
**Request:** `GET /api/v1/charges`
**Expected:** 200 OK with data array and meta
**Response:**
```json
{
  "data": [
    {
      "id": "uuid",
      "investor_id": 1,
      "investor": { "id": 1, "name": "Investor A" },
      "deal_id": 100,
      "deal": { "id": 100, "name": "Deal X" },
      "contribution": { "id": 500, "amount": 100000, "paid_in_date": "2025-01-15" },
      "status": "DRAFT",
      "base_amount": 10000.00,
      "total_amount": 11450.00,
      "created_at": "2025-10-19T12:00:00Z"
    }
  ],
  "meta": {
    "total": 2,
    "limit": 50,
    "offset": 0
  }
}
```
**Validates:** Finance+ can read all charges

### Test 2.2: Filter by status
**Auth:** Admin user token
**Request:** `GET /api/v1/charges?status=PENDING`
**Expected:** 200 OK with filtered results (only PENDING charges)

### Test 2.3: Filter by investor
**Auth:** Ops user token
**Request:** `GET /api/v1/charges?investor_id=1`
**Expected:** 200 OK with filtered results (only investor 1)

### Test 2.4: Pagination
**Auth:** Manager user token
**Request:** `GET /api/v1/charges?limit=10&offset=20`
**Expected:** 200 OK with 10 items starting from offset 20

### Test 2.5: Fail - invalid status
**Auth:** Finance user token
**Request:** `GET /api/v1/charges?status=INVALID`
**Expected:** 422 Validation Error
**Error:** "Invalid status. Must be one of: DRAFT, PENDING, APPROVED, PAID, REJECTED"

### Test 2.6: Fail - viewer role (forbidden)
**Auth:** Viewer user token (no Finance+ role)
**Request:** `GET /api/v1/charges`
**Expected:** 403 Forbidden
**Error:** "Requires Finance, Ops, Manager, or Admin role to list charges"

---

## Test Suite 3: GET /api/v1/charges/:id (Get Single Charge)

### Test 3.1: Get existing charge (Finance role)
**Auth:** Finance user token
**Request:** `GET /api/v1/charges/{charge_id}`
**Expected:** 200 OK with full charge object (with joins)
**Validates:** Joined data includes investor, deal/fund, contribution

### Test 3.2: Fail - charge not found
**Auth:** Finance user token
**Request:** `GET /api/v1/charges/00000000-0000-0000-0000-000000000000`
**Expected:** 404 Not Found
**Error:** "Charge not found"

### Test 3.3: Fail - viewer role (forbidden)
**Auth:** Viewer user token
**Request:** `GET /api/v1/charges/{charge_id}`
**Expected:** 403 Forbidden

---

## Test Suite 4: POST /api/v1/charges/:id/submit (Submit Charge)

### Test 4.1: Submit DRAFT charge (Finance role)
**Auth:** Finance user token
**Precondition:** Charge exists with status=DRAFT
**Request:** `POST /api/v1/charges/{charge_id}/submit` (empty body)
**Expected:** 200 OK
**Response:**
```json
{
  "id": "uuid",
  "status": "PENDING",
  "submitted_at": "2025-10-19T14:00:00Z",
  ...
}
```
**Validates:** Status transitions from DRAFT → PENDING, submitted_at is set

### Test 4.2: Submit DRAFT charge (Ops role)
**Auth:** Ops user token
**Precondition:** Charge exists with status=DRAFT
**Request:** `POST /api/v1/charges/{charge_id}/submit`
**Expected:** 200 OK
**Validates:** Ops can submit charges

### Test 4.3: Fail - submit non-DRAFT charge
**Auth:** Finance user token
**Precondition:** Charge exists with status=PENDING
**Request:** `POST /api/v1/charges/{charge_id}/submit`
**Expected:** 422 Validation Error
**Error:** "Can only submit DRAFT charges"

### Test 4.4: Fail - viewer role (forbidden)
**Auth:** Viewer user token
**Request:** `POST /api/v1/charges/{charge_id}/submit`
**Expected:** 403 Forbidden

---

## Test Suite 5: POST /api/v1/charges/:id/approve (Approve Charge)

### Test 5.1: Approve PENDING charge (Admin role)
**Auth:** Admin user token
**Precondition:** Charge exists with status=PENDING
**Request:**
```json
POST /api/v1/charges/{charge_id}/approve
{
  "comment": "Approved - all looks good"
}
```
**Expected:** 200 OK
**Response:**
```json
{
  "id": "uuid",
  "status": "APPROVED",
  "approved_by": "admin_user_id",
  "approved_at": "2025-10-19T15:00:00Z",
  ...
}
```
**Validates:** Status PENDING → APPROVED, approved_by and approved_at set

### Test 5.2: Fail - approve non-PENDING charge
**Auth:** Admin user token
**Precondition:** Charge exists with status=DRAFT
**Request:** `POST /api/v1/charges/{charge_id}/approve`
**Expected:** 422 Validation Error
**Error:** "Can only approve PENDING charges"

### Test 5.3: Fail - Finance role (not Admin)
**Auth:** Finance user token
**Precondition:** Charge exists with status=PENDING
**Request:** `POST /api/v1/charges/{charge_id}/approve`
**Expected:** 403 Forbidden
**Error:** "Requires Admin role to approve charges"

### Test 5.4: Fail - Ops role (not Admin)
**Auth:** Ops user token
**Request:** `POST /api/v1/charges/{charge_id}/approve`
**Expected:** 403 Forbidden

---

## Test Suite 6: POST /api/v1/charges/:id/reject (Reject Charge)

### Test 6.1: Reject PENDING charge (Admin role)
**Auth:** Admin user token
**Precondition:** Charge exists with status=PENDING
**Request:**
```json
POST /api/v1/charges/{charge_id}/reject
{
  "reject_reason": "Incorrect VAT calculation"
}
```
**Expected:** 200 OK
**Response:**
```json
{
  "id": "uuid",
  "status": "REJECTED",
  "rejected_by": "admin_user_id",
  "rejected_at": "2025-10-19T15:30:00Z",
  "reject_reason": "Incorrect VAT calculation",
  ...
}
```
**Validates:** Status PENDING → REJECTED, reject_reason stored

### Test 6.2: Fail - missing reject_reason
**Auth:** Admin user token
**Precondition:** Charge exists with status=PENDING
**Request:**
```json
POST /api/v1/charges/{charge_id}/reject
{
  "reject_reason": ""
}
```
**Expected:** 422 Validation Error
**Error:** "Reject reason is required"

### Test 6.3: Fail - reject non-PENDING charge
**Auth:** Admin user token
**Precondition:** Charge exists with status=DRAFT
**Request:**
```json
POST /api/v1/charges/{charge_id}/reject
{
  "reject_reason": "Test rejection"
}
```
**Expected:** 422 Validation Error
**Error:** "Can only reject PENDING charges"

### Test 6.4: Fail - Finance role (not Admin)
**Auth:** Finance user token
**Request:**
```json
POST /api/v1/charges/{charge_id}/reject
{
  "reject_reason": "Test"
}
```
**Expected:** 403 Forbidden
**Error:** "Requires Admin role to reject charges"

---

## Test Suite 7: POST /api/v1/charges/:id/mark-paid (Mark Paid)

### Test 7.1: Mark APPROVED charge as paid (Finance role)
**Auth:** Finance user token
**Precondition:** Charge exists with status=APPROVED
**Request:**
```json
POST /api/v1/charges/{charge_id}/mark-paid
{
  "paid_at": "2025-10-19T16:00:00Z"
}
```
**Expected:** 200 OK
**Response:**
```json
{
  "id": "uuid",
  "status": "PAID",
  "paid_at": "2025-10-19T16:00:00Z",
  ...
}
```
**Validates:** Status APPROVED → PAID, paid_at set to provided date

### Test 7.2: Mark APPROVED charge as paid with default timestamp (Admin role)
**Auth:** Admin user token
**Precondition:** Charge exists with status=APPROVED
**Request:** `POST /api/v1/charges/{charge_id}/mark-paid` (empty body)
**Expected:** 200 OK
**Validates:** paid_at defaults to current timestamp

### Test 7.3: Fail - mark non-APPROVED charge as paid
**Auth:** Finance user token
**Precondition:** Charge exists with status=PENDING
**Request:** `POST /api/v1/charges/{charge_id}/mark-paid`
**Expected:** 422 Validation Error
**Error:** "Can only mark APPROVED charges as paid"

### Test 7.4: Fail - Ops role (not Finance or Admin)
**Auth:** Ops user token
**Precondition:** Charge exists with status=APPROVED
**Request:** `POST /api/v1/charges/{charge_id}/mark-paid`
**Expected:** 403 Forbidden
**Error:** "Requires Finance or Admin role to mark charges as paid"

---

## Test Suite 8: Status Transition Validation

### Test 8.1: Valid workflow - DRAFT → PENDING → APPROVED → PAID
**Steps:**
1. Create charge (status=DRAFT)
2. Submit (DRAFT → PENDING) ✓
3. Approve (PENDING → APPROVED) ✓
4. Mark paid (APPROVED → PAID) ✓
**Expected:** All transitions succeed

### Test 8.2: Valid workflow - DRAFT → PENDING → REJECTED
**Steps:**
1. Create charge (status=DRAFT)
2. Submit (DRAFT → PENDING) ✓
3. Reject (PENDING → REJECTED) ✓
**Expected:** All transitions succeed

### Test 8.3: Invalid - cannot transition from PAID
**Precondition:** Charge with status=PAID
**Attempts:**
- Submit → 422 (cannot submit non-DRAFT)
- Approve → 422 (cannot approve non-PENDING)
- Reject → 422 (cannot reject non-PENDING)
- Mark paid → 422 (cannot mark-paid non-APPROVED)

### Test 8.4: Invalid - cannot transition from REJECTED
**Precondition:** Charge with status=REJECTED
**Attempts:** Same as Test 8.3 (all should fail)

---

## Test Suite 9: RBAC Matrix Validation

| Endpoint | Admin | Finance | Ops | Manager | Viewer |
|----------|-------|---------|-----|---------|--------|
| GET /charges | ✓ | ✓ | ✓ | ✓ | ✗ |
| GET /charges/:id | ✓ | ✓ | ✓ | ✓ | ✗ |
| POST /charges/:id/submit | ✓ | ✓ | ✓ | ✓ | ✗ |
| POST /charges/:id/approve | ✓ | ✗ | ✗ | ✗ | ✗ |
| POST /charges/:id/reject | ✓ | ✗ | ✗ | ✗ | ✗ |
| POST /charges/:id/mark-paid | ✓ | ✓ | ✗ | ✗ | ✗ |

**Validate:** Each role can only perform allowed actions

---

## Test Suite 10: Edge Cases

### Test 10.1: Charge with large amounts
**Request:**
```json
POST /api/v1/charges
{
  "investor_id": 1,
  "deal_id": 100,
  "contribution_id": 600,
  "base_amount": 999999999999.99,
  "total_amount": 999999999999.99,
  "currency": "USD",
  "snapshot_json": {},
  "status": "DRAFT"
}
```
**Expected:** 201 Created
**Validates:** NUMERIC(18,2) precision handling

### Test 10.2: Charge with negative amounts (should fail at DB level)
**Request:**
```json
POST /api/v1/charges
{
  "investor_id": 1,
  "deal_id": 100,
  "contribution_id": 601,
  "base_amount": -1000.00,
  "total_amount": -1000.00,
  "currency": "USD",
  "snapshot_json": {},
  "status": "DRAFT"
}
```
**Expected:** 422 or 500 (DB constraint violation if CHECK constraint exists)

### Test 10.3: Concurrent submit attempts
**Scenario:** Two users submit the same DRAFT charge simultaneously
**Expected:** One succeeds (200), one fails (422 - status already changed)

### Test 10.4: Filter by multiple criteria
**Request:** `GET /api/v1/charges?status=APPROVED&investor_id=1&deal_id=100`
**Expected:** 200 OK with results matching all filters

---

## Test Execution Checklist

- [ ] All 7 endpoints implemented and accessible
- [ ] RBAC enforced correctly (Finance+, Admin, Finance/Admin)
- [ ] Status transitions validated (422 on invalid transitions)
- [ ] XOR constraint enforced (deal_id XOR fund_id)
- [ ] Timestamps recorded correctly (submitted_at, approved_at, rejected_at, paid_at)
- [ ] Reject requires reject_reason (422 if missing)
- [ ] Joined data returned (investor, deal, fund, contribution)
- [ ] Pagination works correctly (limit/offset)
- [ ] Error responses follow standard format (code, message, details, timestamp)
- [ ] All endpoints registered in main router

---

## Performance Validation

### Load Test Scenario
**Endpoint:** GET /api/v1/charges
**Concurrent Users:** 10
**Requests:** 100 per user
**Expected:**
- Average response time < 200ms
- 95th percentile < 500ms
- No 500 errors

### Index Verification
**Query:** `EXPLAIN SELECT * FROM charges WHERE status = 'PENDING'`
**Expected:** Index Scan using idx_charges_status

**Query:** `EXPLAIN SELECT * FROM charges WHERE investor_id = 1 AND status = 'APPROVED'`
**Expected:** Index Scan using idx_charges_investor_status

---

## Summary

**Total Test Cases:** 40+
**Coverage:**
- ✓ All endpoints (7)
- ✓ RBAC enforcement (5 roles)
- ✓ Status transitions (5 states)
- ✓ Validation errors (422)
- ✓ Permission errors (403)
- ✓ Not found errors (404)
- ✓ Pagination
- ✓ Filtering
- ✓ Joined data
- ✓ Edge cases
