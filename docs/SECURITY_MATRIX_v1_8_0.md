# Security Matrix - Charge Workflow API (v1.8.0)

## Overview

This document defines the security model and access control matrix for the Charge Workflow API (v1.8.0). It specifies which roles can perform which operations and documents the Row-Level Security (RLS) policies enforced at the database layer.

**Last Updated:** 2025-10-21
**Version:** 1.8.0
**Status:** Production

---

## Authentication Methods

### 1. User JWT (Supabase Auth)
- **Source:** Supabase Auth service
- **Format:** `Bearer <jwt_token>`
- **Roles:** Extracted from `app_metadata.role` claim
- **Expiry:** Configurable (default: 1 hour)
- **Use Cases:** UI operations, user-initiated actions

### 2. Service Key
- **Source:** Supabase service_role key
- **Format:** `Bearer <service_key>`
- **Roles:** Always treated as `service` role
- **Expiry:** Never (rotate manually)
- **Use Cases:** Background jobs, batch operations, system integrations

---

## Role Definitions

| Role      | Description                                    | Primary Use Case              |
|-----------|------------------------------------------------|-------------------------------|
| `admin`   | Full access to all operations                  | Finance operations manager    |
| `finance` | Can compute and submit charges                 | Finance team                  |
| `ops`     | Read-only access to charges                    | Operations team               |
| `manager` | Can view charges, approve agreements           | Senior management             |
| `viewer`  | No access to charges (blocked by RLS)          | External auditors             |
| `service` | System role (service key), limited permissions | Automated workflows, cron jobs |

---

## Endpoint Access Control Matrix

### Charge Workflow Endpoints

| Endpoint                           | Admin | Finance | Ops | Manager | Viewer | Service Key | Notes                                      |
|------------------------------------|-------|---------|-----|---------|--------|-------------|---------------------------------------------|
| **POST /charges/compute**          | ✅    | ✅      | ✅  | ❌      | ❌     | ✅          | Finance+ roles OR service key               |
| **POST /charges/batch-compute**    | ✅    | ✅      | ✅  | ❌      | ❌     | ✅          | Finance+ roles OR service key               |
| **GET /charges**                   | ✅    | ✅      | ✅  | ✅      | ❌     | ✅          | Finance+ roles (read operations)            |
| **GET /charges/:id**               | ✅    | ✅      | ✅  | ✅      | ❌     | ✅          | Finance+ roles (read operations)            |
| **POST /charges/:id/submit**       | ✅    | ✅      | ❌  | ❌      | ❌     | ✅          | Finance+ roles OR service key               |
| **POST /charges/:id/approve**      | ✅    | ❌      | ❌  | ❌      | ❌     | ❌          | **Admin only** (no service key)             |
| **POST /charges/:id/reject**       | ✅    | ❌      | ❌  | ❌      | ❌     | ❌          | **Admin only** (no service key)             |
| **POST /charges/:id/mark-paid**    | ✅    | ❌      | ❌  | ❌      | ❌     | ❌ (BLOCKED)| **Admin only, human verification required** |

### Legend
- ✅ **Allowed** - User/role can perform this operation
- ❌ **Denied** - User/role is forbidden (403 Forbidden)

---

## Service Key Restrictions

The service key has **intentional limitations** to enforce security best practices:

### Allowed Operations
- ✅ Compute charges (`POST /charges/compute`)
- ✅ Batch compute charges (`POST /charges/batch-compute`)
- ✅ Submit charges (`POST /charges/:id/submit`)
- ✅ Read charges (`GET /charges`, `GET /charges/:id`)

### Blocked Operations (Require Human Verification)
- ❌ **Approve charges** - Requires admin user review
- ❌ **Reject charges** - Requires admin user review
- ❌ **Mark charges as paid** - Requires human verification of payment

**Rationale:** Financial operations that represent irreversible state changes or money movement require explicit human approval. This prevents automated systems from accidentally approving fraudulent or incorrect charges.

---

## HTTP Error Codes

| Status | Code                | Description                                         | Example Scenario                              |
|--------|---------------------|-----------------------------------------------------|-----------------------------------------------|
| 200    | `SUCCESS`           | Request succeeded                                   | Charge computed successfully                  |
| 400    | `BAD_REQUEST`       | Malformed request (invalid JSON)                    | Missing required header, invalid JSON         |
| 401    | `UNAUTHORIZED`      | Authentication required or failed                   | Missing Bearer token, expired JWT             |
| 403    | `FORBIDDEN`         | Insufficient permissions                            | Finance user tries to approve charge          |
| 404    | `NOT_FOUND`         | Resource not found                                  | Charge UUID does not exist                    |
| 409    | `CONFLICT`          | Invalid state transition or business rule violation | Attempting to approve DRAFT charge            |
| 422    | `VALIDATION_ERROR`  | Request validation failed                           | Missing `reject_reason`, invalid contribution |
| 500    | `INTERNAL_ERROR`    | Server error (should not occur in production)       | Unhandled exception, database connection lost |

---

## Row-Level Security (RLS) Policies

RLS policies are enforced at the **PostgreSQL database level** to prevent unauthorized data access, even if application-level checks are bypassed.

### Policy: `charges_select_policy`

**Purpose:** Control who can read charges

**SQL Definition:**
```sql
CREATE POLICY charges_select_policy ON charges
FOR SELECT
USING (
  -- Admin, Finance, Ops, Manager roles can see all charges
  current_setting('app.user_role', true) IN ('admin', 'finance', 'ops', 'manager')
  OR
  -- Service role can see all charges
  current_setting('app.user_role', true) = 'service'
);
```

**Effect:**
- ✅ `admin`, `finance`, `ops`, `manager` → Can see all charges
- ✅ `service` → Can see all charges (bypasses RLS with service key)
- ❌ `viewer` → Cannot see any charges (empty result set)

---

### Policy: `charges_insert_policy`

**Purpose:** Control who can create charges

**SQL Definition:**
```sql
CREATE POLICY charges_insert_policy ON charges
FOR INSERT
WITH CHECK (
  -- Only finance+ roles or service key can insert charges
  current_setting('app.user_role', true) IN ('admin', 'finance', 'ops')
  OR
  current_setting('app.user_role', true) = 'service'
);
```

**Effect:**
- ✅ `admin`, `finance`, `ops` → Can compute charges
- ✅ `service` → Can compute charges
- ❌ `manager`, `viewer` → Cannot create charges

---

### Policy: `charges_update_policy`

**Purpose:** Control who can update charges (submit, approve, reject, mark paid)

**SQL Definition:**
```sql
CREATE POLICY charges_update_policy ON charges
FOR UPDATE
USING (
  -- Admin can update (approve, reject, mark paid)
  current_setting('app.user_role', true) = 'admin'
  OR
  -- Finance can update (submit only - enforced by application logic)
  current_setting('app.user_role', true) IN ('finance', 'ops')
  OR
  -- Service key can update (submit only - approve/reject/mark-paid blocked by application)
  current_setting('app.user_role', true) = 'service'
);
```

**Effect:**
- ✅ `admin` → Can perform all update operations
- ✅ `finance`, `ops` → Can submit charges (application enforces submit-only)
- ✅ `service` → Can submit charges (application blocks approve/reject/mark-paid)
- ❌ `manager`, `viewer` → Cannot update charges

**Note:** Application-level RBAC provides finer-grained control (e.g., finance can only submit, not approve).

---

## Feature Flags

The charge workflow respects the following feature flags:

| Feature Flag              | Description                                  | Default | Impact When Disabled                     |
|---------------------------|----------------------------------------------|---------|------------------------------------------|
| `ENABLE_CHARGE_WORKFLOW`  | Enable entire charge workflow                | `true`  | All charge endpoints return 403 Forbidden |
| `ENABLE_CREDIT_AUTO_APPLY`| Enable automatic FIFO credit application     | `true`  | Credits not applied on submit             |

**Feature Flag Override:** Admin users with explicit `bypass_feature_flags: true` in `app_metadata` can bypass disabled feature flags.

---

## Testing the Security Matrix

### Automated RLS Policy Tests

Run the following SQL script to verify RLS policies:

**File:** `tests/rls_policy_tests.sql`

```sql
-- Test 1: Admin can see all charges
SET LOCAL app.user_role = 'admin';
SELECT COUNT(*) FROM charges; -- Should return all charges

-- Test 2: Finance can see all charges
SET LOCAL app.user_role = 'finance';
SELECT COUNT(*) FROM charges; -- Should return all charges

-- Test 3: Viewer cannot see any charges
SET LOCAL app.user_role = 'viewer';
SELECT COUNT(*) FROM charges; -- Should return 0

-- Test 4: Finance can insert charges
SET LOCAL app.user_role = 'finance';
INSERT INTO charges (id, investor_id, contribution_id, status, base_amount, vat_amount, total_amount, currency)
VALUES (gen_random_uuid(), 1, 1, 'DRAFT', 100, 20, 120, 'USD');
-- Should succeed

-- Test 5: Viewer cannot insert charges
SET LOCAL app.user_role = 'viewer';
INSERT INTO charges (id, investor_id, contribution_id, status, base_amount, vat_amount, total_amount, currency)
VALUES (gen_random_uuid(), 1, 1, 'DRAFT', 100, 20, 120, 'USD');
-- Should fail with RLS policy violation

-- Test 6: Manager cannot update charges
SET LOCAL app.user_role = 'manager';
UPDATE charges SET status = 'APPROVED' WHERE id = (SELECT id FROM charges LIMIT 1);
-- Should fail with RLS policy violation
```

### Manual RBAC Testing

Use the negative test matrix script to verify endpoint-level RBAC:

**File:** `tests/charges_negative_matrix.ps1`

```powershell
# Run with different user tokens
.\tests\charges_negative_matrix.ps1 `
    -AdminToken "eyJhbGc..." `
    -FinanceToken "eyJhbGc..." `
    -OpsToken "eyJhbGc..."
```

**Expected Results:**
- ✅ 22+ tests pass
- ❌ 0 tests fail
- All 403 Forbidden errors are returned for unauthorized operations

---

## Security Best Practices

### 1. Token Rotation
- **User JWTs:** Automatically expire after 1 hour (configurable)
- **Service Key:** Rotate quarterly or when compromised
- **Recommendation:** Use short-lived tokens for UI, long-lived service keys only for background jobs

### 2. Least Privilege Principle
- Assign users the **minimum role** required for their job function
- Avoid granting `admin` role unless absolutely necessary
- Use `finance` role for day-to-day operations

### 3. Audit Logging
- All charge state transitions are logged with:
  - `submitted_at`, `submitted_by`
  - `approved_at`, `approved_by`
  - `rejected_at`, `rejected_by`
  - `paid_at` (no `paid_by` to prevent service key usage)

### 4. Service Key Protection
- **Never commit** service keys to version control
- Store in environment variables or secrets manager (AWS Secrets Manager, Vault)
- Use separate service keys for staging and production

### 5. RLS as Last Line of Defense
- Always enforce RBAC at **both application and database layers**
- RLS prevents data leaks even if application code has bugs
- Test RLS policies regularly with automated SQL scripts

---

## Threat Model

### Threat 1: Service Key Compromise
**Impact:** Attacker can compute and submit charges, but cannot approve or mark as paid (blocked by application logic).

**Mitigation:**
- Service key cannot approve/reject/mark-paid (requires admin user)
- Monitor service key usage for anomalies
- Rotate service key quarterly

### Threat 2: Privilege Escalation (Finance → Admin)
**Impact:** Attacker with finance role tries to approve charges by forging JWT.

**Mitigation:**
- JWT signature verification (Supabase validates `iss` and `exp` claims)
- RLS policies enforce role-based access at database level
- Application-level RBAC checks role from JWT claims

### Threat 3: IDOR (Insecure Direct Object Reference)
**Impact:** User tries to approve charge belonging to different organization.

**Mitigation:**
- RLS policies filter charges by organization (if multi-tenant)
- UUID-based charge IDs prevent enumeration attacks
- Application validates charge ownership before state transitions

### Threat 4: Replay Attacks
**Impact:** Attacker intercepts and replays valid JWT token.

**Mitigation:**
- Short-lived JWTs (1 hour expiry)
- Idempotency keys for state-changing operations
- Audit logs track duplicate operations

---

## Compliance Notes

### PCI DSS (Payment Card Industry)
- **Requirement 7.1:** Limit access to charge data based on business need-to-know
  - ✅ Implemented via RBAC and RLS policies
- **Requirement 8.3:** Secure authentication for all system access
  - ✅ JWT-based authentication with Supabase Auth
- **Requirement 10.2:** Audit trail for all access to charge data
  - ✅ Audit fields: `created_at`, `submitted_at`, `approved_at`, etc.

### SOC 2 Type II
- **CC6.1:** Logical access controls restrict access to authorized users
  - ✅ RBAC matrix enforced at API and database layers
- **CC6.2:** Prior to issuing credentials, system registers and authorizes users
  - ✅ User provisioning via Supabase Auth admin console

---

## Appendix: Role Provisioning

### Assigning Roles to Users

Roles are stored in the `app_metadata.role` field of Supabase Auth users.

**Using Supabase SQL Editor:**
```sql
-- Grant admin role to user
UPDATE auth.users
SET raw_app_meta_data = jsonb_set(raw_app_meta_data, '{role}', '"admin"')
WHERE email = 'admin@buligocapital.com';
```

**Using Supabase Dashboard:**
1. Navigate to Authentication → Users
2. Select user
3. Edit `app_metadata`
4. Add: `{ "role": "admin" }`
5. Save

### Verifying User Role

**SQL Query:**
```sql
SELECT
  email,
  raw_app_meta_data->>'role' as role
FROM auth.users
WHERE email = 'user@example.com';
```

**API Request:**
```bash
curl -X GET "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1/me" \
  -H "Authorization: Bearer <jwt_token>"

# Response:
# {
#   "user_id": "uuid",
#   "email": "user@example.com",
#   "role": "finance"
# }
```

---

## Change Log

| Date       | Version | Changes                                                    |
|------------|---------|-------------------------------------------------------------|
| 2025-10-21 | 1.8.0   | Initial security matrix for charge workflow                |
| 2025-10-21 | 1.8.0   | Added service key restrictions for mark-paid endpoint       |
| 2025-10-21 | 1.8.0   | Documented RLS policies and RBAC matrix                     |

---

## Contact

**Security Issues:** security@buligocapital.com
**Documentation Feedback:** dev@buligocapital.com
**Access Requests:** admin@buligocapital.com
