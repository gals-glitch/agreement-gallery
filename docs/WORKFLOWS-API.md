# Workflow APIs - Agreements & Runs

**Version:** 1.0.0
**Last Updated:** 2025-10-16

This document covers the workflow action endpoints for Agreements and Calculation Runs, including state transitions, RBAC requirements, and error handling.

---

## Table of Contents

- [Agreements Workflow](#agreements-workflow)
  - [Submit Agreement](#submit-agreement)
  - [Approve Agreement](#approve-agreement)
  - [Reject Agreement](#reject-agreement)
  - [Amend Agreement](#amend-agreement)
- [Runs Workflow](#runs-workflow)
  - [Submit Run](#submit-run)
  - [Approve Run](#approve-run)
  - [Reject Run](#reject-run)
  - [Generate Run](#generate-run)
- [Common Error Responses](#common-error-responses)
- [State Transition Diagrams](#state-transition-diagrams)

---

## Agreements Workflow

Agreements follow a strict state machine: **DRAFT → AWAITING_APPROVAL → APPROVED**

Once approved, agreements become immutable. Amendments create a new agreement version with a snapshot of the previous version.

### Submit Agreement

Submit a draft agreement for approval.

**Endpoint:** `POST /api-v1/agreements/:id/submit`

**Permissions:** Any authenticated user (agreement creator)

**Valid States:** `DRAFT`, `IN_PROGRESS`

**Request:**
```http
POST /api-v1/agreements/123/submit
Authorization: Bearer <jwt_token>
```

**Response (200 OK):**
```json
{
  "id": 123,
  "status": "AWAITING_APPROVAL",
  "submitted_at": "2025-10-16T10:30:00Z",
  "submitted_by": "user@example.com"
}
```

**Error Responses:**

**403 Forbidden - Invalid State Transition:**
```json
{
  "error": "Cannot submit agreement in current state",
  "code": "INVALID_STATE_TRANSITION",
  "details": {
    "current_state": "APPROVED",
    "requested_transition": "submit",
    "allowed_states": ["DRAFT", "IN_PROGRESS"]
  }
}
```

**422 Validation Error - Missing Required Fields:**
```json
{
  "error": "Validation failed",
  "code": "VALIDATION_ERROR",
  "errors": [
    "scope is required (must be DEAL or FUND)",
    "pricing_type is required when scope is FUND"
  ]
}
```

---

### Approve Agreement

Approve a submitted agreement (requires Finance or Admin role).

**Endpoint:** `POST /api-v1/agreements/:id/approve`

**Permissions:** `finance` OR `admin` role

**Valid States:** `AWAITING_APPROVAL`

**Request:**
```http
POST /api-v1/agreements/123/approve
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "comment": "Approved - rates confirmed with finance team"
}
```

**Response (200 OK):**
```json
{
  "id": 123,
  "status": "APPROVED",
  "approved_at": "2025-10-16T11:00:00Z",
  "approved_by": "finance@example.com",
  "reviewer_comment": "Approved - rates confirmed with finance team"
}
```

**Error Responses:**

**403 Forbidden - Insufficient Permissions:**
```json
{
  "error": "Insufficient permissions",
  "code": "FORBIDDEN",
  "details": {
    "required_roles": ["finance", "admin"],
    "user_roles": ["investor"]
  }
}
```

**403 Forbidden - Invalid State:**
```json
{
  "error": "Cannot approve agreement in current state",
  "code": "INVALID_STATE_TRANSITION",
  "details": {
    "current_state": "DRAFT",
    "requested_transition": "approve",
    "allowed_states": ["AWAITING_APPROVAL"]
  }
}
```

---

### Reject Agreement

Reject a submitted agreement with a required comment (requires Finance or Admin role).

**Endpoint:** `POST /api-v1/agreements/:id/reject`

**Permissions:** `finance` OR `admin` role

**Valid States:** `AWAITING_APPROVAL`

**Request:**
```http
POST /api-v1/agreements/123/reject
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "comment": "Track rate mismatch - should be Track B not Track C"
}
```

**Response (200 OK):**
```json
{
  "id": 123,
  "status": "DRAFT",
  "rejected_at": "2025-10-16T11:15:00Z",
  "rejected_by": "finance@example.com",
  "reviewer_comment": "Track rate mismatch - should be Track B not Track C"
}
```

**Error Responses:**

**422 Validation Error - Missing Comment:**
```json
{
  "error": "Validation failed",
  "code": "VALIDATION_ERROR",
  "errors": [
    "comment is required when rejecting an agreement"
  ]
}
```

---

### Amend Agreement

Create a new version of an approved agreement (snapshots previous version).

**Endpoint:** `POST /api-v1/agreements/:id/amend`

**Permissions:** Any authenticated user

**Valid States:** `APPROVED`

**Request:**
```http
POST /api-v1/agreements/123/amend
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "reason": "Rate adjustment - moving from Track A to Track B"
}
```

**Response (201 Created):**
```json
{
  "id": 456,
  "status": "DRAFT",
  "previous_version_id": 123,
  "created_at": "2025-10-16T12:00:00Z",
  "amendment_reason": "Rate adjustment - moving from Track A to Track B",
  "snapshot": {
    "id": 123,
    "status": "APPROVED",
    "scope": "FUND",
    "pricing_type": "TRACK",
    "selected_track": "A"
  }
}
```

**Error Responses:**

**403 Forbidden - Not Approved:**
```json
{
  "error": "Cannot amend agreement in current state",
  "code": "INVALID_STATE_TRANSITION",
  "details": {
    "current_state": "DRAFT",
    "requested_transition": "amend",
    "allowed_states": ["APPROVED"]
  }
}
```

---

## Runs Workflow

Calculation Runs follow the state machine: **DRAFT → IN_PROGRESS → AWAITING_APPROVAL → APPROVED**

Only approved runs can trigger final calculation generation.

### Submit Run

Submit a calculation run for approval.

**Endpoint:** `POST /api-v1/runs/:id/submit`

**Permissions:** Any authenticated user

**Valid States:** `DRAFT`, `IN_PROGRESS`

**Request:**
```http
POST /api-v1/runs/789/submit
Authorization: Bearer <jwt_token>
```

**Response (200 OK):**
```json
{
  "id": 789,
  "status": "AWAITING_APPROVAL",
  "period_from": "2025-01-01",
  "period_to": "2025-03-31",
  "submitted_at": "2025-10-16T14:00:00Z",
  "submitted_by": "user@example.com"
}
```

**Error Responses:**

**403 Forbidden - Invalid State:**
```json
{
  "error": "Cannot submit run in current state",
  "code": "INVALID_STATE_TRANSITION",
  "details": {
    "current_state": "APPROVED",
    "requested_transition": "submit",
    "allowed_states": ["DRAFT", "IN_PROGRESS"]
  }
}
```

---

### Approve Run

Approve a submitted calculation run (requires Finance or Admin role).

**Endpoint:** `POST /api-v1/runs/:id/approve`

**Permissions:** `finance` OR `admin` role

**Valid States:** `AWAITING_APPROVAL`

**Request:**
```http
POST /api-v1/runs/789/approve
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "comment": "Q3 calculations reviewed and approved"
}
```

**Response (200 OK):**
```json
{
  "id": 789,
  "status": "APPROVED",
  "approved_at": "2025-10-16T15:00:00Z",
  "approved_by": "finance@example.com",
  "reviewer_comment": "Q3 calculations reviewed and approved"
}
```

**Error Responses:**

**403 Forbidden - Insufficient Permissions:**
```json
{
  "error": "Insufficient permissions",
  "code": "FORBIDDEN",
  "details": {
    "required_roles": ["finance", "admin"],
    "user_roles": ["operations"]
  }
}
```

---

### Reject Run

Reject a submitted run with a required comment (requires Finance or Admin role).

**Endpoint:** `POST /api-v1/runs/:id/reject`

**Permissions:** `finance` OR `admin` role

**Valid States:** `AWAITING_APPROVAL`

**Request:**
```http
POST /api-v1/runs/789/reject
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "comment": "Missing contributions for 5 deals - please verify and resubmit"
}
```

**Response (200 OK):**
```json
{
  "id": 789,
  "status": "DRAFT",
  "rejected_at": "2025-10-16T15:30:00Z",
  "rejected_by": "finance@example.com",
  "reviewer_comment": "Missing contributions for 5 deals - please verify and resubmit"
}
```

**Error Responses:**

**422 Validation Error - Missing Comment:**
```json
{
  "error": "Validation failed",
  "code": "VALIDATION_ERROR",
  "errors": [
    "comment is required when rejecting a run"
  ]
}
```

---

### Generate Run

Trigger final calculation generation (only available after approval).

**Endpoint:** `POST /api-v1/runs/:id/generate`

**Permissions:** Any authenticated user

**Valid States:** `APPROVED`

**Request:**
```http
POST /api-v1/runs/789/generate
Authorization: Bearer <jwt_token>
```

**Response (200 OK):**
```json
{
  "id": 789,
  "status": "APPROVED",
  "generated_at": "2025-10-16T16:00:00Z",
  "generated_by": "user@example.com",
  "result": {
    "total_fees": 125000.50,
    "entries_generated": 342,
    "export_url": "/exports/run-789-2025-10-16.xlsx"
  }
}
```

**Error Responses:**

**403 Forbidden - Not Approved:**
```json
{
  "error": "Cannot generate calculations for unapproved run",
  "code": "INVALID_STATE_TRANSITION",
  "details": {
    "current_state": "AWAITING_APPROVAL",
    "requested_transition": "generate",
    "allowed_states": ["APPROVED"]
  }
}
```

**422 Validation Error - Missing Data:**
```json
{
  "error": "Validation failed",
  "code": "VALIDATION_ERROR",
  "errors": [
    "No contributions found for period 2025-01-01 to 2025-03-31",
    "3 deals missing required equity_to_raise values"
  ]
}
```

---

## Common Error Responses

All endpoints follow standardized error response formats:

### 401 Unauthorized
```json
{
  "error": "Authentication required",
  "code": "UNAUTHORIZED"
}
```

### 403 Forbidden (RBAC)
```json
{
  "error": "Insufficient permissions",
  "code": "FORBIDDEN",
  "details": {
    "required_roles": ["finance", "admin"],
    "user_roles": ["investor"]
  }
}
```

### 403 Forbidden (State Transition)
```json
{
  "error": "Cannot perform action in current state",
  "code": "INVALID_STATE_TRANSITION",
  "details": {
    "current_state": "APPROVED",
    "requested_transition": "submit",
    "allowed_states": ["DRAFT", "IN_PROGRESS"]
  }
}
```

### 404 Not Found
```json
{
  "error": "Resource not found",
  "code": "NOT_FOUND",
  "resource": "agreement",
  "id": 999
}
```

### 422 Validation Error
```json
{
  "error": "Validation failed",
  "code": "VALIDATION_ERROR",
  "errors": [
    "field1 is required",
    "field2 must be positive"
  ]
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal server error",
  "code": "INTERNAL_ERROR",
  "request_id": "abc123"
}
```

---

## State Transition Diagrams

### Agreements State Machine

```
DRAFT ──submit──> AWAITING_APPROVAL ──approve──> APPROVED ──amend──> DRAFT (new version)
  │                      │
  │                      │
  └─────<────────────reject────────┘
```

**Valid Transitions:**
- `DRAFT` → `submit` → `AWAITING_APPROVAL`
- `IN_PROGRESS` → `submit` → `AWAITING_APPROVAL`
- `AWAITING_APPROVAL` → `approve` → `APPROVED`
- `AWAITING_APPROVAL` → `reject` → `DRAFT`
- `APPROVED` → `amend` → `DRAFT` (creates new version with snapshot)

**Immutability:**
- Once `APPROVED`, the original agreement cannot be modified
- Amendments create a new draft version with `previous_version_id` reference

---

### Runs State Machine

```
DRAFT ──submit──> AWAITING_APPROVAL ──approve──> APPROVED ──generate──> (calculation complete)
  │                      │
  │                      │
  └─────<────────────reject────────┘
```

**Valid Transitions:**
- `DRAFT` → `submit` → `AWAITING_APPROVAL`
- `IN_PROGRESS` → `submit` → `AWAITING_APPROVAL`
- `AWAITING_APPROVAL` → `approve` → `APPROVED`
- `AWAITING_APPROVAL` → `reject` → `DRAFT`
- `APPROVED` → `generate` → (no state change, adds generated_at timestamp)

**Generate Gating:**
- Only `APPROVED` runs can trigger final calculation generation
- Generate action is idempotent (can be called multiple times)
- Each generate call updates `generated_at` and produces new export

---

## Business Rules Reference

### Agreements

**Scope + Pricing Rules:**
- `DEAL` scope → Must use `DEAL` pricing (no track selection)
- `FUND` scope → Must use `TRACK` pricing (requires `selected_track`: A, B, or C)

**Track Rates (Fund VI):**
- Rates are locked in `fund_vi_tracks` table (seed data)
- Cannot be edited via UI (admin-only reference)
- Track selection determines all rate tiers

**GP Fee Toggle:**
- If `gp_fee_applicable = true`, GP fees are added to the calculation
- GP fee rates are stored in `gp_fee_rates` column (JSONB array)

**VAT:**
- `vat_rate` is stored as decimal (e.g., 0.17 for 17%)
- Applied to final calculated fees

---

### Runs

**Precedence Rules:**
- Deal-scoped fees override fund-scoped fees when both exist
- Deal fees are calculated independently per deal
- Fund fees apply to all contributions without deal-specific agreements

**Data Requirements:**
- Must have contributions for the run's period (`period_from` to `period_to`)
- Deals must have `equity_to_raise` and `raised_so_far` from Scoreboard imports
- All referenced agreements must be `APPROVED`

**Generate Output:**
- Creates line items in `fee_entries` table
- Calculates based on paid-in capital contributions
- Applies tiered rates (thresholds and rates)
- Includes GP fees if applicable
- Applies VAT to final amounts

---

_For implementation details, see:_
- Frontend: `src/components/AgreementFormV2.tsx`, `src/components/RunHeader.tsx`
- Backend: `supabase/functions/api-v1/index.ts`
- Workflow Helpers: `src/lib/runWorkflow.ts`
