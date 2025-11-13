# RBAC API Documentation

**Version:** 1.6.0
**Last Updated:** 2025-10-19
**Base URL:** `/functions/v1/api-v1`

---

## Overview

The RBAC (Role-Based Access Control) API provides endpoints for managing user roles, permissions, and audit trails. This system replaces the legacy `app_role` enum with a flexible, many-to-many role assignment system.

**Key Features:**
- 5 canonical roles: admin, finance, ops, manager, viewer
- Many-to-many user-role assignments (users can have multiple roles)
- Comprehensive audit logging for all role changes
- Admin-only access enforcement via RLS policies
- Service role authentication required for all operations

---

## Authentication

All RBAC endpoints require **service role authentication** (admin-level access).

```javascript
const headers = {
  'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
  'Content-Type': 'application/json'
};
```

**Why Service Role?** Role management is a privileged operation that bypasses RLS policies to enable centralized access control.

---

## Endpoints

### List Users with Roles

**Endpoint:** `GET /api-v1/admin/users`

**Description:** Retrieve all users with their assigned roles. Supports optional search query.

**Query Parameters:**
- `query` (optional) - Search term to filter users by email or name (case-insensitive partial match)

**Request Example:**

```bash
# List all users
curl -X GET "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1/admin/users" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}"

# Search users by email/name
curl -X GET "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1/admin/users?query=john" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}"
```

**Response (200 OK):**

```json
[
  {
    "id": "fabb1e21-691e-4005-8a9d-66fc381011a2",
    "email": "gals@buligocapital.com",
    "raw_user_meta_data": {
      "full_name": "Gal Samionov"
    },
    "created_at": "2025-10-15T10:30:00Z",
    "roles": [
      {
        "role_key": "admin",
        "granted_at": "2025-10-19T08:00:00Z",
        "granted_by": "fabb1e21-691e-4005-8a9d-66fc381011a2",
        "role": {
          "key": "admin",
          "name": "Administrator",
          "description": "Full system access: manage users, roles, settings, approve all workflows"
        }
      }
    ]
  },
  {
    "id": "b3c4d5e6-f7g8-h9i0-j1k2-l3m4n5o6p7q8",
    "email": "john.doe@buligocapital.com",
    "raw_user_meta_data": {
      "full_name": "John Doe"
    },
    "created_at": "2025-10-16T14:20:00Z",
    "roles": [
      {
        "role_key": "finance",
        "granted_at": "2025-10-19T09:15:00Z",
        "granted_by": "fabb1e21-691e-4005-8a9d-66fc381011a2",
        "role": {
          "key": "finance",
          "name": "Finance Manager",
          "description": "Approve charges, manage VAT rates, view financial reports, create invoices"
        }
      },
      {
        "role_key": "ops",
        "granted_at": "2025-10-19T09:16:00Z",
        "granted_by": "fabb1e21-691e-4005-8a9d-66fc381011a2",
        "role": {
          "key": "ops",
          "name": "Operations",
          "description": "View and create charges, manage agreements, import data"
        }
      }
    ]
  }
]
```

**Error Responses:**

| Status | Condition | Response |
|--------|-----------|----------|
| 401 | Missing or invalid service role token | `{ "error": "Unauthorized" }` |
| 500 | Database error | `{ "error": "Failed to fetch users" }` |

---

### Grant Role to User

**Endpoint:** `POST /api-v1/admin/users/:userId/roles`

**Description:** Assign a role to a user. Creates audit log entry automatically.

**Path Parameters:**
- `userId` (required) - UUID of the user to grant the role to

**Request Body:**

```json
{
  "roleKey": "finance"
}
```

**Valid Role Keys:**
- `admin` - Full system access
- `finance` - Financial operations and approvals
- `ops` - Operational tasks and data entry
- `manager` - Agreement approvals and reporting
- `viewer` - Read-only access

**Request Example:**

```bash
curl -X POST "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1/admin/users/b3c4d5e6-f7g8-h9i0-j1k2-l3m4n5o6p7q8/roles" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "roleKey": "finance"
  }'
```

**Response (201 Created):**

```json
{
  "user_id": "b3c4d5e6-f7g8-h9i0-j1k2-l3m4n5o6p7q8",
  "role_key": "finance",
  "granted_by": "fabb1e21-691e-4005-8a9d-66fc381011a2",
  "granted_at": "2025-10-19T10:30:00Z"
}
```

**Audit Log Entry Created:**

```json
{
  "event_type": "role.granted",
  "actor_id": "fabb1e21-691e-4005-8a9d-66fc381011a2",
  "target_id": "b3c4d5e6-f7g8-h9i0-j1k2-l3m4n5o6p7q8",
  "entity_type": "user_role",
  "entity_id": "finance",
  "payload": {
    "role_key": "finance",
    "granted_by": "fabb1e21-691e-4005-8a9d-66fc381011a2",
    "user_email": "john.doe@buligocapital.com"
  },
  "timestamp": "2025-10-19T10:30:00Z"
}
```

**Error Responses:**

| Status | Condition | Response |
|--------|-----------|----------|
| 400 | Missing `roleKey` in body | `{ "error": "roleKey is required" }` |
| 404 | Invalid role key | `{ "error": "Role not found: <roleKey>" }` |
| 404 | Invalid user ID | `{ "error": "User not found: <userId>" }` |
| 409 | User already has this role | `{ "error": "User already has role: <roleKey>" }` |
| 500 | Database error | `{ "error": "Failed to grant role" }` |

---

### Revoke Role from User

**Endpoint:** `DELETE /api-v1/admin/users/:userId/roles/:roleKey`

**Description:** Remove a role from a user. Creates audit log entry automatically.

**Path Parameters:**
- `userId` (required) - UUID of the user to revoke the role from
- `roleKey` (required) - Role key to revoke (admin, finance, ops, manager, viewer)

**Request Example:**

```bash
curl -X DELETE "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1/admin/users/b3c4d5e6-f7g8-h9i0-j1k2-l3m4n5o6p7q8/roles/finance" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}"
```

**Response (200 OK):**

```json
{
  "message": "Role revoked successfully"
}
```

**Audit Log Entry Created:**

```json
{
  "event_type": "role.revoked",
  "actor_id": "fabb1e21-691e-4005-8a9d-66fc381011a2",
  "target_id": "b3c4d5e6-f7g8-h9i0-j1k2-l3m4n5o6p7q8",
  "entity_type": "user_role",
  "entity_id": "finance",
  "payload": {
    "role_key": "finance",
    "revoked_by": "fabb1e21-691e-4005-8a9d-66fc381011a2",
    "user_email": "john.doe@buligocapital.com"
  },
  "timestamp": "2025-10-19T10:35:00Z"
}
```

**Error Responses:**

| Status | Condition | Response |
|--------|-----------|----------|
| 404 | User does not have this role | `{ "error": "User does not have role: <roleKey>" }` |
| 404 | Invalid user ID | `{ "error": "User not found: <userId>" }` |
| 500 | Database error | `{ "error": "Failed to revoke role" }` |

---

## Role Permission Matrix

| Role | Approve Runs | Approve Agreements | Manage VAT Rates | Manage Users | Manage Credits | View Reports |
|------|--------------|-------------------|------------------|--------------|----------------|--------------|
| **admin** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **finance** | ✅ | ❌ | ✅ | ❌ | ✅ | ✅ |
| **ops** | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| **manager** | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ |
| **viewer** | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |

---

## Database Schema

### `roles` Table

| Column | Type | Description |
|--------|------|-------------|
| `key` | TEXT PRIMARY KEY | Unique role identifier (admin, finance, ops, manager, viewer) |
| `name` | TEXT NOT NULL | Human-readable role name |
| `description` | TEXT | Role capabilities description |
| `created_at` | TIMESTAMPTZ | Creation timestamp |

**Seed Data:**

```sql
INSERT INTO roles (key, name, description) VALUES
  ('admin', 'Administrator', 'Full system access: manage users, roles, settings, approve all workflows'),
  ('finance', 'Finance Manager', 'Approve charges, manage VAT rates, view financial reports, create invoices'),
  ('ops', 'Operations', 'View and create charges, manage agreements, import data'),
  ('manager', 'Agreement Manager', 'Approve agreements, view reports, manage investors and parties'),
  ('viewer', 'Viewer', 'Read-only access to all data');
```

### `user_roles` Table

| Column | Type | Description |
|--------|------|-------------|
| `user_id` | UUID REFERENCES auth.users(id) | User ID |
| `role_key` | TEXT REFERENCES roles(key) | Role key |
| `granted_by` | UUID REFERENCES auth.users(id) | Admin who granted the role |
| `granted_at` | TIMESTAMPTZ DEFAULT now() | Grant timestamp |
| PRIMARY KEY | (user_id, role_key) | Composite primary key |

**Indexes:**
- `idx_user_roles_user_id` - Fast permission checks
- `idx_user_roles_role_key` - List users by role
- `idx_user_roles_granted_by` - Audit trail by granter

### `audit_log` Table

| Column | Type | Description |
|--------|------|-------------|
| `id` | BIGSERIAL PRIMARY KEY | Auto-incrementing ID |
| `event_type` | TEXT NOT NULL | Event category (role.granted, role.revoked, settings.updated) |
| `actor_id` | UUID REFERENCES auth.users(id) | User who performed the action |
| `target_id` | UUID | User affected by the action (nullable) |
| `entity_type` | TEXT | Type of entity (user_role, org_settings) |
| `entity_id` | TEXT | Entity identifier |
| `payload` | JSONB | Event-specific metadata |
| `timestamp` | TIMESTAMPTZ DEFAULT now() | Event timestamp |

**Indexes:**
- `idx_audit_log_event_type` - Filter by event type
- `idx_audit_log_actor_id` - User activity history
- `idx_audit_log_target_id` - Events affecting user
- `idx_audit_log_timestamp_desc` - Time-series queries
- `idx_audit_log_payload` (GIN) - JSONB queries

---

## Frontend Integration

### React Hook Example

```typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { http } from '@/api/http';

export function useUsers(query?: string) {
  return useQuery({
    queryKey: ['admin', 'users', query],
    queryFn: async () => {
      const url = query
        ? `/admin/users?query=${encodeURIComponent(query)}`
        : '/admin/users';
      const response = await http.get(url);
      return response.data;
    }
  });
}

export function useGrantRole() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ userId, roleKey }: { userId: string; roleKey: string }) => {
      const response = await http.post(`/admin/users/${userId}/roles`, { roleKey });
      return response.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'users'] });
    }
  });
}

export function useRevokeRole() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ userId, roleKey }: { userId: string; roleKey: string }) => {
      const response = await http.delete(`/admin/users/${userId}/roles/${roleKey}`);
      return response.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'users'] });
    }
  });
}
```

### Usage in Component

```typescript
import { useUsers, useGrantRole, useRevokeRole } from '@/hooks/useRbac';

export function UsersPage() {
  const [search, setSearch] = useState('');
  const { data: users, isLoading } = useUsers(search);
  const grantRole = useGrantRole();
  const revokeRole = useRevokeRole();

  const handleGrantRole = async (userId: string, roleKey: string) => {
    try {
      await grantRole.mutateAsync({ userId, roleKey });
      toast.success(`Role ${roleKey} granted successfully`);
    } catch (error) {
      toast.error(`Failed to grant role: ${error.message}`);
    }
  };

  const handleRevokeRole = async (userId: string, roleKey: string) => {
    try {
      await revokeRole.mutateAsync({ userId, roleKey });
      toast.success(`Role ${roleKey} revoked successfully`);
    } catch (error) {
      toast.error(`Failed to revoke role: ${error.message}`);
    }
  };

  return (
    <div>
      <input
        type="search"
        placeholder="Search users..."
        value={search}
        onChange={(e) => setSearch(e.target.value)}
      />
      {isLoading ? <Spinner /> : (
        <UsersList
          users={users}
          onGrantRole={handleGrantRole}
          onRevokeRole={handleRevokeRole}
        />
      )}
    </div>
  );
}
```

---

## Testing Guide

### Prerequisites

1. Service role key configured in environment
2. At least one admin user exists in `user_roles` table
3. Supabase Edge Function deployed

### Test Scenario 1: Grant Role to New User

```bash
# Step 1: Create test user (via Supabase Auth)
# Assume user ID: test-user-uuid

# Step 2: Grant finance role
curl -X POST "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1/admin/users/test-user-uuid/roles" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -d '{ "roleKey": "finance" }'

# Expected: 201 Created with user_role object

# Step 3: Verify in database
SELECT * FROM user_roles WHERE user_id = 'test-user-uuid';
-- Expected: 1 row with role_key = 'finance'

# Step 4: Check audit log
SELECT * FROM audit_log WHERE event_type = 'role.granted' AND target_id = 'test-user-uuid';
-- Expected: 1 row with payload containing role details
```

### Test Scenario 2: Search Users

```bash
# Step 1: List all users
curl -X GET "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1/admin/users" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}"

# Expected: Array of users with roles

# Step 2: Search by email
curl -X GET "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1/admin/users?query=john" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}"

# Expected: Filtered array containing only users with 'john' in email/name
```

### Test Scenario 3: Revoke Role

```bash
# Step 1: Revoke finance role
curl -X DELETE "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1/admin/users/test-user-uuid/roles/finance" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}"

# Expected: 200 OK with success message

# Step 2: Verify removal
SELECT * FROM user_roles WHERE user_id = 'test-user-uuid' AND role_key = 'finance';
-- Expected: 0 rows

# Step 3: Check audit log
SELECT * FROM audit_log WHERE event_type = 'role.revoked' AND target_id = 'test-user-uuid';
-- Expected: 1 row with payload containing revocation details
```

### Test Scenario 4: Error Handling

```bash
# Test 1: Grant invalid role
curl -X POST "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1/admin/users/test-user-uuid/roles" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -d '{ "roleKey": "superadmin" }'
# Expected: 404 with "Role not found: superadmin"

# Test 2: Grant duplicate role
curl -X POST "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1/admin/users/test-user-uuid/roles" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -d '{ "roleKey": "finance" }'
# (assuming finance role was already granted)
# Expected: 409 with "User already has role: finance"

# Test 3: Revoke non-existent role
curl -X DELETE "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1/admin/users/test-user-uuid/roles/admin" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}"
# (assuming admin role was never granted)
# Expected: 404 with "User does not have role: admin"
```

---

## Security Considerations

### RLS Policies

All RBAC tables have RLS policies enabled:

**`roles` table:**
- SELECT: All authenticated users can read roles
- INSERT/UPDATE/DELETE: Admins only

**`user_roles` table:**
- SELECT: All authenticated users can read role assignments
- INSERT/DELETE: Admins only

**`audit_log` table:**
- SELECT: All authenticated users can read audit log
- INSERT: Admins only (automatic via triggers)
- UPDATE/DELETE: Disabled (append-only)

### Service Role Authentication

RBAC API endpoints use service role authentication to bypass RLS and perform administrative operations. This is necessary because:

1. Admin users need to manage roles for other users
2. RLS policies would prevent cross-user modifications
3. Service role has superuser privileges

**Best Practice:** Never expose service role key to frontend. Always proxy through backend Edge Function.

### Audit Trail

Every role change creates an immutable audit log entry containing:
- Who performed the action (`actor_id`)
- Who was affected (`target_id`)
- What role was changed (`entity_id`)
- When it happened (`timestamp`)
- Additional context (`payload`)

This provides full accountability for access control changes.

---

## Migration Guide

### Migrating from Old `app_role` System

If you have existing role assignments in the old system:

```sql
-- Step 1: Backup old roles
CREATE TABLE user_roles_backup AS SELECT * FROM user_roles;

-- Step 2: Apply new migration
-- (This drops the old user_roles table and creates the new one)

-- Step 3: Migrate existing role assignments
INSERT INTO user_roles (user_id, role_key, granted_by, granted_at)
SELECT
  user_id,
  CASE
    WHEN role = 'admin' THEN 'admin'
    WHEN role = 'manager' THEN 'manager'
    ELSE 'viewer'
  END,
  user_id, -- Self-granted during migration
  granted_at
FROM user_roles_backup;

-- Step 4: Verify migration
SELECT COUNT(*) FROM user_roles; -- Should match user_roles_backup
```

---

## Troubleshooting

### Issue: "Unauthorized" Error

**Cause:** Missing or invalid service role token

**Solution:**
1. Verify `SUPABASE_SERVICE_ROLE_KEY` is set correctly
2. Check that token is being sent in `Authorization` header
3. Ensure token is prefixed with `Bearer `

### Issue: "Role not found"

**Cause:** Invalid role key in request

**Solution:**
1. Verify role key is one of: `admin`, `finance`, `ops`, `manager`, `viewer`
2. Check for typos or case sensitivity issues
3. Confirm roles table has been seeded

### Issue: "User already has role"

**Cause:** Attempting to grant a role that user already has

**Solution:**
1. Query `user_roles` table to check existing assignments
2. Use revoke endpoint first, then grant (if re-assigning)
3. Update UI to disable grant button for existing roles

### Issue: Audit log not created

**Cause:** Trigger failure or transaction rollback

**Solution:**
1. Check Supabase logs for trigger errors
2. Verify `audit_log` table exists and is writable
3. Ensure transaction completed successfully (no errors in response)

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.6.0 | 2025-10-19 | Initial RBAC API release with 3 endpoints, 5 roles, audit logging |

---

## Support

For issues or questions:
- **API Implementation:** `supabase/functions/api-v1/rbac.ts`
- **Database Schema:** `supabase/migrations/20251019110000_rbac_settings_credits.sql`
- **Frontend Example:** `src/pages/admin/Users.tsx`
- **Documentation:** This file

---

**Last Updated:** 2025-10-19
**Maintained By:** Buligo Capital Development Team
