# Charges API Architecture Diagram

## System Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           CLIENT APPLICATIONS                            │
│  (Finance UI, Admin Dashboard, Mobile App, Internal Tools)              │
└────────────┬────────────────────────────────────────────────┬───────────┘
             │                                                 │
             │ HTTP/REST                                       │ HTTP/REST
             │ (with JWT Auth)                                 │ (Service Role)
             │                                                 │
┌────────────▼─────────────────────────────────────────────────▼───────────┐
│                    SUPABASE EDGE FUNCTION: api-v1                        │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │                      Main Router (index.ts)                       │  │
│  │  • Authenticate user (except POST /charges)                       │  │
│  │  • Parse URL path                                                 │  │
│  │  • Route to appropriate handler                                   │  │
│  └───┬───────────────────────────────────────────────────────────────┘  │
│      │                                                                   │
│      │ Route: /charges                                                  │
│      │                                                                   │
│  ┌───▼───────────────────────────────────────────────────────────────┐  │
│  │              Charges Handler (charges.ts)                         │  │
│  │  ┌─────────────────────────────────────────────────────────────┐  │  │
│  │  │  handleChargesRoutes(req, supabase, userId?, corsHeaders)   │  │  │
│  │  │  • Parse path and method                                     │  │  │
│  │  │  • Route to specific endpoint handler                        │  │  │
│  │  └──┬───────────────────────────────────────────────────────────┘  │  │
│  │     │                                                               │  │
│  │     ├─► handleCreateCharge()      POST /charges (no auth)          │  │
│  │     ├─► handleListCharges()       GET /charges (Finance+)          │  │
│  │     ├─► handleGetCharge()         GET /charges/:id (Finance+)      │  │
│  │     ├─► handleSubmitCharge()      POST /charges/:id/submit         │  │
│  │     ├─► handleApproveCharge()     POST /charges/:id/approve (Admin)│  │
│  │     ├─► handleRejectCharge()      POST /charges/:id/reject (Admin) │  │
│  │     └─► handleMarkPaid()          POST /charges/:id/mark-paid      │  │
│  │                                                                       │  │
│  │  Each handler:                                                       │  │
│  │  1. Validates RBAC (getUserRoles, hasAnyRole)                       │  │
│  │  2. Validates request payload                                       │  │
│  │  3. Validates status transitions                                    │  │
│  │  4. Performs database operations                                    │  │
│  │  5. Returns standardized response (success/error)                   │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │                   Shared Utilities                                 │    │
│  │  • getUserRoles() - Get user roles from user_roles table           │    │
│  │  • hasAnyRole() - Check if user has required role                  │    │
│  │  • validationError() - 422 error response                          │    │
│  │  • forbiddenError() - 403 error response                           │    │
│  │  • notFoundError() - 404 error response                            │    │
│  │  • successResponse() - Success response                            │    │
│  │  • mapPgErrorToApiError() - Database error mapping                 │    │
│  └────────────────────────────────────────────────────────────────────┘    │
└──────────────────────────────┬───────────────────────────────────────────────┘
                               │
                               │ Postgres Protocol
                               │
┌──────────────────────────────▼───────────────────────────────────────────────┐
│                         SUPABASE POSTGRES DATABASE                           │
│  ┌────────────────────────────────────────────────────────────────────┐     │
│  │  Table: charges                                                     │     │
│  │  • id (UUID, PK)                                                    │     │
│  │  • investor_id (FK → investors)                                     │     │
│  │  • deal_id (FK → deals, XOR with fund_id)                          │     │
│  │  • fund_id (FK → funds, XOR with deal_id)                          │     │
│  │  • contribution_id (FK → contributions)                             │     │
│  │  • status (charge_status ENUM)                                      │     │
│  │  • base_amount, discount_amount, vat_amount, total_amount          │     │
│  │  • currency                                                          │     │
│  │  • snapshot_json (JSONB)                                            │     │
│  │  • computed_at, submitted_at, approved_at, rejected_at, paid_at    │     │
│  │  • approved_by, rejected_by (FK → auth.users)                      │     │
│  │  • reject_reason                                                     │     │
│  │  • created_at, updated_at                                           │     │
│  └────────────────────────────────────────────────────────────────────┘     │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐     │
│  │  Indexes                                                            │     │
│  │  • idx_charges_status                                               │     │
│  │  • idx_charges_investor_status                                      │     │
│  │  • idx_charges_deal (partial)                                       │     │
│  │  • idx_charges_fund (partial)                                       │     │
│  │  • idx_charges_contribution                                         │     │
│  │  • idx_charges_approved_at (partial)                                │     │
│  │  • idx_charges_paid_at (partial)                                    │     │
│  └────────────────────────────────────────────────────────────────────┘     │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐     │
│  │  RLS Policies                                                       │     │
│  │  • Finance+ can read all charges (SELECT)                           │     │
│  │  • Admin can manage all charges (INSERT/UPDATE/DELETE)              │     │
│  └────────────────────────────────────────────────────────────────────┘     │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐     │
│  │  Related Tables (Joins)                                             │     │
│  │  • investors (id, name)                                             │     │
│  │  • deals (id, name)                                                 │     │
│  │  • funds (id, name)                                                 │     │
│  │  • contributions (id, amount, paid_in_date)                         │     │
│  │  • user_roles (user_id, role_key) - for RBAC                       │     │
│  │  • auth.users (id) - for approved_by/rejected_by                   │     │
│  └────────────────────────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Request Flow Diagrams

### 1. Create Charge (Internal - No Auth)

```
┌────────────┐
│  Compute   │
│  Engine    │
│  (P2-2)    │
└──────┬─────┘
       │
       │ POST /api/v1/charges
       │ {
       │   investor_id, deal_id, contribution_id,
       │   base_amount, vat_amount, total_amount,
       │   snapshot_json, ...
       │ }
       │
       ▼
┌──────────────────────────────────────┐
│  api-v1 Router                       │
│  • No auth check (service role)      │
│  • Route to handleChargesRoutes      │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│  handleCreateCharge()                │
│  • Validate XOR (deal_id XOR fund_id)│
│  • Validate required fields          │
│  • INSERT INTO charges                │
│  • Return 201 Created                │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│  Database: charges table             │
│  • New row with status=DRAFT         │
│  • Trigger: update updated_at        │
└──────────────────────────────────────┘
```

---

### 2. List Charges (Finance User)

```
┌────────────┐
│  Finance   │
│  User UI   │
└──────┬─────┘
       │
       │ GET /api/v1/charges?status=PENDING&limit=50
       │ Authorization: Bearer <jwt_token>
       │
       ▼
┌──────────────────────────────────────┐
│  api-v1 Router                       │
│  • Authenticate user (JWT)           │
│  • Extract user.id                   │
│  • Route to handleChargesRoutes      │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│  handleListCharges()                 │
│  • Check RBAC: Finance+              │
│  │  └─► getUserRoles(userId)         │
│  │  └─► hasAnyRole([finance, ...])   │
│  • Validate filters (status)         │
│  • Build query with joins            │
│  • Apply filters, pagination         │
│  • Return 200 OK + data + meta       │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│  Database Query                      │
│  SELECT c.*, i.*, d.*, f.*, contrib.*│
│  FROM charges c                      │
│  LEFT JOIN investors i ON ...        │
│  LEFT JOIN deals d ON ...            │
│  LEFT JOIN funds f ON ...            │
│  LEFT JOIN contributions contrib ON  │
│  WHERE status = 'PENDING'            │
│  ORDER BY created_at DESC            │
│  LIMIT 50 OFFSET 0                   │
│  -- Uses idx_charges_status          │
└──────────────────────────────────────┘
```

---

### 3. Submit Charge Workflow (DRAFT → PENDING)

```
┌────────────┐
│  Finance   │
│  User      │
└──────┬─────┘
       │
       │ POST /api/v1/charges/{id}/submit
       │ Authorization: Bearer <jwt_token>
       │ {}
       │
       ▼
┌──────────────────────────────────────┐
│  api-v1 Router                       │
│  • Authenticate user (JWT)           │
│  • Route to handleChargesRoutes      │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│  handleSubmitCharge()                │
│  • Check RBAC: Finance+              │
│  • Fetch charge by ID                │
│  • Validate status = DRAFT           │
│  │  └─► If not DRAFT → 422 Error     │
│  • UPDATE charges SET                │
│  │   status='PENDING',               │
│  │   submitted_at=now()              │
│  • Return 200 OK + updated charge    │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│  Database Transaction                │
│  • UPDATE charges                    │
│  • Trigger: update updated_at        │
│  • SELECT with joins (return data)   │
└──────────────────────────────────────┘
```

---

### 4. Approve Charge Workflow (PENDING → APPROVED)

```
┌────────────┐
│   Admin    │
│   User     │
└──────┬─────┘
       │
       │ POST /api/v1/charges/{id}/approve
       │ Authorization: Bearer <jwt_token>
       │ { "comment": "Looks good" }
       │
       ▼
┌──────────────────────────────────────┐
│  api-v1 Router                       │
│  • Authenticate user (JWT)           │
│  • Route to handleChargesRoutes      │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│  handleApproveCharge()               │
│  • Check RBAC: Admin ONLY            │
│  │  └─► If not Admin → 403 Forbidden │
│  • Fetch charge by ID                │
│  • Validate status = PENDING         │
│  │  └─► If not PENDING → 422 Error   │
│  • UPDATE charges SET                │
│  │   status='APPROVED',              │
│  │   approved_by=userId,             │
│  │   approved_at=now()               │
│  • Return 200 OK + updated charge    │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│  Database Transaction                │
│  • UPDATE charges                    │
│  • FK to auth.users (approved_by)    │
│  • Trigger: update updated_at        │
└──────────────────────────────────────┘
```

---

### 5. Reject Charge Workflow (PENDING → REJECTED)

```
┌────────────┐
│   Admin    │
│   User     │
└──────┬─────┘
       │
       │ POST /api/v1/charges/{id}/reject
       │ Authorization: Bearer <jwt_token>
       │ { "reject_reason": "Incorrect VAT" }
       │
       ▼
┌──────────────────────────────────────┐
│  api-v1 Router                       │
│  • Authenticate user (JWT)           │
│  • Route to handleChargesRoutes      │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│  handleRejectCharge()                │
│  • Check RBAC: Admin ONLY            │
│  • Validate reject_reason provided   │
│  │  └─► If empty → 422 Error          │
│  • Fetch charge by ID                │
│  • Validate status = PENDING         │
│  │  └─► If not PENDING → 422 Error   │
│  • UPDATE charges SET                │
│  │   status='REJECTED',              │
│  │   rejected_by=userId,             │
│  │   rejected_at=now(),              │
│  │   reject_reason=<reason>          │
│  • Return 200 OK + updated charge    │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│  Database Transaction                │
│  • UPDATE charges                    │
│  • FK to auth.users (rejected_by)    │
│  • Store reject_reason (audit trail) │
└──────────────────────────────────────┘
```

---

### 6. Mark Paid Workflow (APPROVED → PAID)

```
┌────────────┐
│  Finance   │
│  User      │
└──────┬─────┘
       │
       │ POST /api/v1/charges/{id}/mark-paid
       │ Authorization: Bearer <jwt_token>
       │ { "paid_at": "2025-10-19T16:00:00Z" }
       │
       ▼
┌──────────────────────────────────────┐
│  api-v1 Router                       │
│  • Authenticate user (JWT)           │
│  • Route to handleChargesRoutes      │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│  handleMarkPaid()                    │
│  • Check RBAC: Finance or Admin      │
│  │  └─► If not → 403 Forbidden        │
│  • Fetch charge by ID                │
│  • Validate status = APPROVED        │
│  │  └─► If not APPROVED → 422 Error  │
│  • UPDATE charges SET                │
│  │   status='PAID',                  │
│  │   paid_at=<provided or now()>     │
│  • Return 200 OK + updated charge    │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│  Database Transaction                │
│  • UPDATE charges                    │
│  • Index: idx_charges_paid_at        │
└──────────────────────────────────────┘
```

---

## Status State Machine

```
                  ┌───────────┐
                  │   DRAFT   │ (Created by compute engine)
                  └─────┬─────┘
                        │
                        │ submit() - Finance+
                        │
                  ┌─────▼─────┐
                  │  PENDING  │ (Awaiting approval)
                  └─────┬─────┘
                        │
           ┌────────────┼────────────┐
           │                         │
           │ approve() - Admin       │ reject() - Admin
           │                         │
    ┌──────▼───────┐          ┌─────▼─────┐
    │   APPROVED   │          │  REJECTED │ (Terminal)
    └──────┬───────┘          └───────────┘
           │
           │ mark-paid() - Finance/Admin
           │
    ┌──────▼───────┐
    │     PAID     │ (Terminal)
    └──────────────┘
```

**Valid Transitions:**
- DRAFT → PENDING (submit)
- PENDING → APPROVED (approve)
- PENDING → REJECTED (reject)
- APPROVED → PAID (mark-paid)

**Terminal States:** PAID, REJECTED (no further transitions allowed)

---

## RBAC Decision Tree

```
                    ┌─────────────────┐
                    │  Incoming Request│
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │ POST /charges?   │
                    │ (Create charge)  │
                    └────────┬─────────┘
                             │
                      ┌──────┴──────┐
                      │ YES         │ NO
                      │             │
              ┌───────▼────┐   ┌────▼────────┐
              │ No Auth    │   │ Auth Required│
              │ Required   │   │ Check JWT   │
              │ (Service)  │   └────┬────────┘
              └────────────┘        │
                                    │
                            ┌───────▼────────┐
                            │ Extract user_id │
                            │ Get user roles  │
                            └───────┬────────┘
                                    │
                            ┌───────▼────────┐
                            │  Which Endpoint?│
                            └───────┬────────┘
                                    │
        ┌───────────────────────────┼────────────────────────┐
        │                           │                        │
  ┌─────▼─────┐            ┌────────▼────────┐     ┌────────▼────────┐
  │GET/Submit │            │ Approve/Reject  │     │   Mark Paid     │
  └─────┬─────┘            └────────┬────────┘     └────────┬────────┘
        │                           │                       │
  ┌─────▼─────┐            ┌────────▼────────┐     ┌────────▼────────┐
  │Has Finance+│            │   Has Admin?    │     │Has Finance/Admin│
  │  Role?     │            │                 │     │     Role?       │
  └─────┬─────┘            └────────┬────────┘     └────────┬────────┘
        │                           │                       │
   ┌────┴────┐               ┌──────┴──────┐         ┌──────┴──────┐
   │ YES│ NO │               │ YES    │ NO │         │ YES    │ NO │
   │    │    │               │        │    │         │        │    │
   │  ✓ │ ✗  │               │  ✓     │ ✗  │         │  ✓     │ ✗  │
   │    │    │               │        │    │         │        │    │
   │    │ 403│               │     403│    │         │     403│    │
   └────┴────┘               └─────────────┘         └─────────────┘

Legend:
  ✓ = Proceed to handler
  ✗ = Return 403 Forbidden
```

---

## Error Flow

```
┌──────────────┐
│   Request    │
└──────┬───────┘
       │
       ▼
┌──────────────────────┐
│  Handler validates   │
│  • RBAC              │
│  • Request payload   │
│  • Status transition │
│  • Business rules    │
└──────┬───────────────┘
       │
       ├─► Validation Error (422)
       │   • validationError([{ field, message, value }])
       │   • Returns: { code: "VALIDATION_ERROR", message, details, timestamp }
       │
       ├─► Permission Error (403)
       │   • forbiddenError("Requires Admin role...")
       │   • Returns: { code: "FORBIDDEN", message, timestamp }
       │
       ├─► Not Found Error (404)
       │   • notFoundError("Charge")
       │   • Returns: { code: "NOT_FOUND", message: "Charge not found", timestamp }
       │
       └─► Database Error (500/422/409)
           • mapPgErrorToApiError(error)
           • Maps PG error codes to API errors
           • Returns: { code, message, details, timestamp }
```

---

## Integration Points

### Upstream Consumers
1. **Compute Engine (P2-2):**
   - Calls `POST /charges` to create charges
   - Uses service role key (no user auth)

2. **Finance UI:**
   - Lists charges: `GET /charges?status=PENDING`
   - Submits charges: `POST /charges/:id/submit`
   - Marks paid: `POST /charges/:id/mark-paid`

3. **Admin Dashboard:**
   - Approves charges: `POST /charges/:id/approve`
   - Rejects charges: `POST /charges/:id/reject`

### Downstream Dependencies
1. **Auth Module (`_shared/auth.ts`):**
   - `getUserRoles(supabase, userId)` - Get user's roles
   - `hasAnyRole(userRoles, requiredRoles)` - Check permissions

2. **Error Module (`errors.ts`):**
   - Standardized error responses
   - Database error mapping

3. **Database (Postgres):**
   - `charges` table with RLS policies
   - Related tables: investors, deals, funds, contributions, user_roles

### Future Integration (P2-6)
- **Credits Engine:** Auto-apply credits when charge → PENDING
- **Notifications:** Send emails/alerts on status changes
- **Audit Log:** Track all workflow actions

---

## Performance Characteristics

**Expected Performance:**
- List charges (50 items): < 100ms
- Get single charge: < 50ms
- Workflow actions: < 100ms

**Optimizations:**
- Indexed queries (7 indexes on charges table)
- Efficient joins (LEFT JOIN for optional relations)
- Pagination prevents large result sets
- RLS policies use indexed user_roles lookups

**Monitoring Points:**
- Track slow queries (> 500ms)
- Monitor endpoint response times
- Alert on 500 errors
- Track workflow transition times
