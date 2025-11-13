# P2-4: Charges API Implementation Summary

**Ticket:** P2-4 - Implement Charges API Endpoints
**Date:** 2025-10-19
**Status:** ✅ COMPLETE

---

## Overview

Implemented 7 REST API endpoints for charge management with workflow actions (DRAFT → PENDING → APPROVED → PAID). Charges represent referral fees calculated on investor contributions, managed through an approval workflow with strict RBAC controls.

---

## Files Created/Modified

### 1. Created: `supabase/functions/api-v1/charges.ts` (654 lines)
**Purpose:** Main handler for all charge management endpoints

**Endpoints Implemented:**
1. `POST /api/v1/charges` - Create charge (internal, no auth)
2. `GET /api/v1/charges` - List charges with filters
3. `GET /api/v1/charges/:id` - Get single charge detail
4. `POST /api/v1/charges/:id/submit` - Submit for approval
5. `POST /api/v1/charges/:id/approve` - Approve charge (Admin only)
6. `POST /api/v1/charges/:id/reject` - Reject charge (Admin only)
7. `POST /api/v1/charges/:id/mark-paid` - Mark as paid

**Key Features:**
- RBAC enforcement using `getUserRoles()` and `hasAnyRole()`
- Status transition validation (prevents invalid state changes)
- XOR validation (exactly one of deal_id or fund_id)
- Comprehensive error handling (422, 403, 404)
- Response includes joined data (investor, deal, fund, contribution)
- Pagination support (limit/offset)
- Filter support (status, investor_id, deal_id, fund_id)

### 2. Modified: `supabase/functions/api-v1/index.ts`
**Changes:**
- Added `handleChargesRoutes` import
- Added special routing for `POST /charges` (no auth required)
- Added charges case in main switch statement
- Updated header comments to include charges

**Key Logic:**
```typescript
// Special case: Charges POST endpoint (internal - no auth required)
if (resource === 'charges' && req.method === 'POST' && !id) {
  return await handleChargesRoutes(req, supabase, null, corsHeaders);
}

// All other charges endpoints require auth
case 'charges':
  return await handleChargesRoutes(req, supabase, user.id, corsHeaders);
```

### 3. Created: `tests/charges-api.test.md`
**Purpose:** Comprehensive integration test suite

**Coverage:**
- 10 test suites
- 40+ test cases
- All endpoints tested
- RBAC matrix validation
- Status transition validation
- Edge cases
- Performance validation

---

## API Endpoints Reference

### 1. POST /api/v1/charges (Create Charge)

**Purpose:** Called by compute engine to create new charge records
**Auth:** Service role (no user authentication)
**RBAC:** N/A (internal use only)

**Request:**
```json
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
    "agreement_snapshot": {},
    "vat_snapshot": {}
  },
  "computed_at": "2025-10-19T12:00:00Z"
}
```

**Response:** 201 Created
```json
{
  "id": "uuid",
  "investor_id": 1,
  "deal_id": 100,
  "status": "DRAFT",
  "total_amount": 11450.00
}
```

**Validation:**
- ✓ XOR constraint (exactly one of deal_id or fund_id)
- ✓ All required fields present
- ✓ Amounts are numbers
- ✓ snapshot_json is valid object

---

### 2. GET /api/v1/charges (List Charges)

**Purpose:** List charges with filters and pagination
**Auth:** Required
**RBAC:** Finance, Ops, Manager, Admin

**Query Parameters:**
- `status` - Filter by status (DRAFT, PENDING, APPROVED, PAID, REJECTED)
- `investor_id` - Filter by investor
- `deal_id` - Filter by deal
- `fund_id` - Filter by fund
- `limit` - Pagination limit (default 50, max 100)
- `offset` - Pagination offset (default 0)

**Response:** 200 OK
```json
{
  "data": [
    {
      "id": "uuid",
      "investor_id": 1,
      "investor": { "id": 1, "name": "Investor A" },
      "deal_id": 100,
      "deal": { "id": 100, "name": "Deal X" },
      "fund_id": null,
      "fund": null,
      "contribution_id": 500,
      "contribution": { "id": 500, "amount": 100000, "paid_in_date": "2025-01-15" },
      "status": "DRAFT",
      "base_amount": 10000.00,
      "discount_amount": 500.00,
      "vat_amount": 1950.00,
      "total_amount": 11450.00,
      "currency": "USD",
      "snapshot_json": {},
      "computed_at": "2025-10-19T12:00:00Z",
      "submitted_at": null,
      "approved_by": null,
      "approved_at": null,
      "rejected_by": null,
      "rejected_at": null,
      "reject_reason": null,
      "paid_at": null,
      "created_at": "2025-10-19T12:00:00Z",
      "updated_at": "2025-10-19T12:00:00Z"
    }
  ],
  "meta": {
    "total": 1,
    "limit": 50,
    "offset": 0
  }
}
```

**Errors:**
- 403 if user not Finance+
- 422 if invalid status filter

---

### 3. GET /api/v1/charges/:id (Get Single Charge)

**Purpose:** Get detailed charge information
**Auth:** Required
**RBAC:** Finance, Ops, Manager, Admin

**Response:** 200 OK (same structure as list item)

**Errors:**
- 403 if user not Finance+
- 404 if charge not found

---

### 4. POST /api/v1/charges/:id/submit (Submit Charge)

**Purpose:** Submit charge for approval (DRAFT → PENDING)
**Auth:** Required
**RBAC:** Finance, Ops, Manager, Admin

**Request:** Empty body `{}`

**Response:** 200 OK
```json
{
  "id": "uuid",
  "status": "PENDING",
  "submitted_at": "2025-10-19T14:00:00Z",
  ...
}
```

**Business Logic:**
- Validates status = DRAFT
- Updates status = PENDING
- Sets submitted_at = now()

**Errors:**
- 403 if user not Finance+
- 404 if charge not found
- 422 if status != DRAFT

---

### 5. POST /api/v1/charges/:id/approve (Approve Charge)

**Purpose:** Approve charge (PENDING → APPROVED)
**Auth:** Required
**RBAC:** Admin only

**Request:**
```json
{
  "comment": "Approved - all looks good"
}
```

**Response:** 200 OK
```json
{
  "id": "uuid",
  "status": "APPROVED",
  "approved_by": "admin_user_id",
  "approved_at": "2025-10-19T15:00:00Z",
  ...
}
```

**Business Logic:**
- Validates status = PENDING
- Updates status = APPROVED
- Sets approved_by = current user id
- Sets approved_at = now()

**Errors:**
- 403 if user not Admin
- 404 if charge not found
- 422 if status != PENDING

---

### 6. POST /api/v1/charges/:id/reject (Reject Charge)

**Purpose:** Reject charge (PENDING → REJECTED)
**Auth:** Required
**RBAC:** Admin only

**Request:**
```json
{
  "reject_reason": "Incorrect VAT calculation"
}
```

**Response:** 200 OK
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

**Business Logic:**
- Validates status = PENDING
- Validates reject_reason is provided and not empty
- Updates status = REJECTED
- Sets rejected_by, rejected_at, reject_reason

**Errors:**
- 403 if user not Admin
- 404 if charge not found
- 422 if status != PENDING
- 422 if reject_reason missing

---

### 7. POST /api/v1/charges/:id/mark-paid (Mark Paid)

**Purpose:** Mark charge as paid (APPROVED → PAID)
**Auth:** Required
**RBAC:** Finance, Admin

**Request:**
```json
{
  "paid_at": "2025-10-19T16:00:00Z"
}
```

**Response:** 200 OK
```json
{
  "id": "uuid",
  "status": "PAID",
  "paid_at": "2025-10-19T16:00:00Z",
  ...
}
```

**Business Logic:**
- Validates status = APPROVED
- Updates status = PAID
- Sets paid_at = request.paid_at || now()

**Errors:**
- 403 if user not Finance or Admin
- 404 if charge not found
- 422 if status != APPROVED

---

## Status Workflow

```
DRAFT → PENDING → APPROVED → PAID
                ↘ REJECTED
```

**Valid Transitions:**
- DRAFT → PENDING (submit)
- PENDING → APPROVED (approve)
- PENDING → REJECTED (reject)
- APPROVED → PAID (mark-paid)

**Invalid Transitions:**
- Cannot submit non-DRAFT charges
- Cannot approve/reject non-PENDING charges
- Cannot mark-paid non-APPROVED charges
- Cannot transition from PAID or REJECTED states

---

## RBAC Matrix

| Endpoint | Admin | Finance | Ops | Manager | Viewer |
|----------|-------|---------|-----|---------|--------|
| POST /charges (create) | N/A | N/A | N/A | N/A | N/A |
| GET /charges | ✓ | ✓ | ✓ | ✓ | ✗ |
| GET /charges/:id | ✓ | ✓ | ✓ | ✓ | ✗ |
| POST /charges/:id/submit | ✓ | ✓ | ✓ | ✓ | ✗ |
| POST /charges/:id/approve | ✓ | ✗ | ✗ | ✗ | ✗ |
| POST /charges/:id/reject | ✓ | ✗ | ✗ | ✗ | ✗ |
| POST /charges/:id/mark-paid | ✓ | ✓ | ✗ | ✗ | ✗ |

**Note:** POST /charges is internal (service role) - no user authentication

---

## Error Handling

All endpoints follow standardized error response format:

**422 Validation Error:**
```json
{
  "code": "VALIDATION_ERROR",
  "message": "Validation failed: 1 error(s)",
  "details": [
    {
      "field": "status",
      "message": "Can only submit DRAFT charges",
      "value": "PENDING"
    }
  ],
  "timestamp": "2025-10-19T12:00:00Z"
}
```

**403 Forbidden:**
```json
{
  "code": "FORBIDDEN",
  "message": "Requires Admin role to approve charges",
  "timestamp": "2025-10-19T12:00:00Z"
}
```

**404 Not Found:**
```json
{
  "code": "NOT_FOUND",
  "message": "Charge not found",
  "timestamp": "2025-10-19T12:00:00Z"
}
```

---

## Database Integration

**Table:** `charges` (created in P2-1 migration)

**Indexes Used:**
- `idx_charges_status` - Status filtering
- `idx_charges_investor_status` - Investor + status queries
- `idx_charges_deal` - Deal lookups (partial index)
- `idx_charges_fund` - Fund lookups (partial index)
- `idx_charges_contribution` - Contribution linkage

**Joins:**
- `investors` - Investor details
- `deals` - Deal details (when deal_id not null)
- `funds` - Fund details (when fund_id not null)
- `contributions` - Contribution details

**RLS Policies:**
- "Finance+ can read all charges" - SELECT for Finance/Ops/Manager/Admin
- "Admin can manage all charges" - INSERT/UPDATE/DELETE for Admin

---

## Security Considerations

1. **Service Role Access:** POST /charges bypasses user auth (uses service role key)
   - Only accessible from internal compute engine
   - Validated at application layer

2. **RBAC Enforcement:**
   - All read operations: Finance+ roles
   - Submit: Finance+ roles
   - Approve/Reject: Admin only
   - Mark Paid: Finance + Admin only

3. **Status Transition Guards:**
   - Prevents invalid state changes
   - Validates current status before transition
   - Returns 422 on invalid transitions

4. **Audit Trail:**
   - All workflow actions record user_id and timestamp
   - approved_by, rejected_by track approvers
   - Immutable snapshot_json prevents recalculation

---

## Integration Points

### Upstream (Called By)
- **Compute Engine (P2-2):** Calls POST /charges to create new charges
- **Credits Engine (P2-6):** Will auto-apply credits when charge transitions to PENDING

### Downstream (Calls To)
- **getUserRoles():** RBAC validation
- **hasAnyRole():** Permission checking
- **Error helpers:** Standardized error responses

---

## Next Steps (Future Enhancements)

1. **P2-5: Integration Tests**
   - Implement automated tests from `tests/charges-api.test.md`
   - Set up CI/CD test pipeline

2. **P2-6: Credits Auto-Application**
   - Call `autoApplyCredits()` when charge status → PENDING
   - Call `reverseCredits()` when charge reverts from PENDING

3. **UI Integration:**
   - Charge list view with status tabs
   - Approval workflow UI
   - Bulk operations (approve/reject multiple)

4. **Reporting:**
   - Charge aging report
   - Approval metrics dashboard
   - Payment tracking

---

## Acceptance Criteria

- [x] All 7 endpoints implemented
- [x] RBAC enforced for each endpoint
- [x] Status transitions validated
- [x] Pagination implemented for list endpoint
- [x] Error responses standardized (422, 403, 404, 500)
- [x] Timestamps recorded for all workflow actions
- [x] Reject requires reject_reason (validated)
- [x] Response includes joined investor/deal/fund/contribution data
- [x] All endpoints registered in main router (index.ts)
- [x] Integration test plan created

---

## Testing Checklist

- [ ] Deploy to dev environment
- [ ] Test POST /charges (internal - service role)
- [ ] Test GET /charges with filters (Finance role)
- [ ] Test GET /charges/:id (Finance role)
- [ ] Test submit workflow (Finance → PENDING)
- [ ] Test approve workflow (Admin → APPROVED)
- [ ] Test reject workflow (Admin → REJECTED)
- [ ] Test mark-paid workflow (Finance → PAID)
- [ ] Validate RBAC (403 for unauthorized roles)
- [ ] Validate status transitions (422 for invalid transitions)
- [ ] Validate XOR constraint (422 for both deal_id and fund_id)
- [ ] Load test (GET /charges with 1000+ records)
- [ ] Verify index usage (EXPLAIN queries)

---

## Performance Notes

**Expected Performance:**
- List charges (50 items): < 100ms
- Get single charge: < 50ms
- Submit/Approve/Reject/Mark-paid: < 100ms

**Optimization:**
- Composite indexes for common queries
- Partial indexes to reduce size
- Joined queries use efficient LEFT JOINs
- Pagination prevents large result sets

**Monitoring:**
- Track slow queries (> 500ms)
- Monitor index usage
- Alert on 500 errors
- Track workflow transition times

---

## References

- **Ticket:** P2-4 (Charges API Endpoints)
- **Migration:** P2-1 (20251019130000_charges.sql)
- **Compute Logic:** P2-2 (Charge Compute Engine)
- **Credits Engine:** P1-B5 (creditsEngine.ts)
- **RBAC:** P1-A3a (rbac.ts)
- **Error Handling:** ORC-002 (errors.ts)

---

**Implementation Status:** ✅ COMPLETE
**Review Status:** Pending
**Deployment Status:** Ready for dev deployment
