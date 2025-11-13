# ORC-001 & ORC-002 Testing Guide

**Date:** 2025-10-19
**Tickets:** ORC-001 (Feature Flags), ORC-002 (Error Contract)

---

## Prerequisites

### Environment Setup

1. **Supabase Local Development:**
   ```bash
   supabase start
   ```

2. **Apply Migrations:**
   ```bash
   supabase db reset
   # Or apply specific migration
   supabase migration up 20251019100010_feature_flags
   ```

3. **Create Test Users:**
   ```sql
   -- Admin user
   INSERT INTO user_roles (user_id, role)
   VALUES ('ADMIN_USER_UUID', 'admin');

   -- Finance user
   INSERT INTO user_roles (user_id, role)
   VALUES ('FINANCE_USER_UUID', 'finance');

   -- Viewer user
   INSERT INTO user_roles (user_id, role)
   VALUES ('VIEWER_USER_UUID', 'viewer');
   ```

4. **Get JWT Tokens:**
   ```bash
   # Sign in as each user in frontend
   # Copy access token from browser DevTools > Application > Local Storage
   # Or use Supabase CLI
   supabase auth get-token
   ```

---

## ORC-001: Feature Flags Testing

### Test Plan

| Test ID | Scenario | Expected Result | Status |
|---------|----------|----------------|--------|
| FF-01 | Database migration applied | feature_flags table exists with RLS | ⬜ |
| FF-02 | Seed data loaded | 5 flags exist (all disabled) | ⬜ |
| FF-03 | GET /feature-flags (viewer) | Returns all flags, isEnabledForUser=false | ⬜ |
| FF-04 | GET /feature-flags (admin) | Returns all flags, some enabled for admin | ⬜ |
| FF-05 | PUT /feature-flags/:key (viewer) | 403 Forbidden | ⬜ |
| FF-06 | PUT /feature-flags/:key (admin) | 200 OK, flag updated | ⬜ |
| FF-07 | Frontend hook loads flags | useFeatureFlags returns data | ⬜ |
| FF-08 | Frontend flag check | useFeatureFlag('docs_repository') returns correct status | ⬜ |
| FF-09 | Admin UI renders | Table shows all flags with toggles | ⬜ |
| FF-10 | Admin UI update | Toggle flag, verify DB updated | ⬜ |
| FF-11 | FeatureGuard component | Children render only when flag enabled | ⬜ |

### Manual Test Steps

#### FF-01: Database Migration
```bash
# Check table exists
psql -U postgres -d postgres -c "SELECT * FROM feature_flags LIMIT 1;"

# Expected: Table with columns key, enabled, enabled_for_roles, etc.
```

#### FF-02: Seed Data
```bash
# Check 5 flags exist
psql -U postgres -d postgres -c "SELECT key, enabled, enabled_for_roles FROM feature_flags;"

# Expected:
# docs_repository | f | {admin}
# charges_engine | f | {admin,finance}
# credits_management | f | {admin,finance}
# vat_admin | f | {admin}
# reports_dashboard | f | {admin,finance,ops}
```

#### FF-03: GET /feature-flags (Viewer)
```bash
curl -X GET http://localhost:54321/functions/v1/api-v1/feature-flags \
  -H "Authorization: Bearer VIEWER_JWT"

# Expected (200):
[
  {
    "key": "docs_repository",
    "enabled": false,
    "isEnabledForUser": false,
    "description": "Enable document repository...",
    "enabled_for_roles": ["admin"],
    "rollout_percentage": 0
  },
  ...
]
```

#### FF-04: GET /feature-flags (Admin)
```bash
# First, enable a flag for admin
psql -U postgres -d postgres -c "UPDATE feature_flags SET enabled = true WHERE key = 'docs_repository';"

curl -X GET http://localhost:54321/functions/v1/api-v1/feature-flags \
  -H "Authorization: Bearer ADMIN_JWT"

# Expected (200):
[
  {
    "key": "docs_repository",
    "enabled": true,
    "isEnabledForUser": true,  # <- true for admin
    ...
  }
]
```

#### FF-05: PUT /feature-flags/:key (Viewer - Should Fail)
```bash
curl -X PUT http://localhost:54321/functions/v1/api-v1/feature-flags/docs_repository \
  -H "Authorization: Bearer VIEWER_JWT" \
  -H "Content-Type: application/json" \
  -d '{"enabled": true}'

# Expected (403):
{
  "error": "Unauthorized: requires admin role"
}
```

#### FF-06: PUT /feature-flags/:key (Admin - Should Succeed)
```bash
curl -X PUT http://localhost:54321/functions/v1/api-v1/feature-flags/docs_repository \
  -H "Authorization: Bearer ADMIN_JWT" \
  -H "Content-Type: application/json" \
  -d '{
    "enabled": true,
    "enabled_for_roles": ["admin", "finance"]
  }'

# Expected (200):
{
  "ok": true,
  "flag": {
    "key": "docs_repository",
    "enabled": true,
    "enabled_for_roles": ["admin", "finance"],
    ...
  }
}
```

#### FF-07: Frontend Hook
```tsx
// In any component
import { useFeatureFlags } from '@/hooks/useFeatureFlags';

function TestComponent() {
  const { data, isLoading, error } = useFeatureFlags();

  console.log('Flags:', data);
  console.log('Loading:', isLoading);
  console.log('Error:', error);

  return <pre>{JSON.stringify(data, null, 2)}</pre>;
}

// Expected: Array of flags displayed
```

#### FF-08: Frontend Flag Check
```tsx
import { useFeatureFlag } from '@/hooks/useFeatureFlags';

function TestFlag() {
  const { isEnabled, flag } = useFeatureFlag('docs_repository');

  return (
    <div>
      <p>Enabled: {isEnabled ? 'YES' : 'NO'}</p>
      <pre>{JSON.stringify(flag, null, 2)}</pre>
    </div>
  );
}

// Expected:
// - Viewer: Enabled: NO
// - Admin (with flag enabled): Enabled: YES
```

#### FF-09 & FF-10: Admin UI
1. Navigate to `/admin/feature-flags` (or wherever admin UI is mounted)
2. Verify table shows all 5 flags
3. Toggle "docs_repository" ON
4. Verify:
   - Switch shows ON state
   - Toast appears: "Feature Flag Updated"
   - Database updated: `SELECT enabled FROM feature_flags WHERE key = 'docs_repository';` → true
5. Click "Edit Roles" for a flag
6. Select/deselect roles
7. Click "Save"
8. Verify database: `SELECT enabled_for_roles FROM feature_flags WHERE key = 'docs_repository';`

#### FF-11: FeatureGuard Component
```tsx
import { FeatureGuard } from '@/components/FeatureGuard';

function TestGuard() {
  return (
    <div>
      <FeatureGuard flag="docs_repository">
        <div>This content is protected by feature flag</div>
      </FeatureGuard>

      <FeatureGuard flag="docs_repository" fallback={<div>Coming Soon</div>}>
        <div>Protected content</div>
      </FeatureGuard>
    </div>
  );
}

// Expected:
// - Flag OFF: No content or "Coming Soon"
// - Flag ON + correct role: Protected content renders
// - Flag ON + wrong role: No content
```

---

## ORC-002: Error Contract Testing

### Test Plan

| Test ID | Scenario | Expected Result | Status |
|---------|----------|----------------|--------|
| EC-01 | POST /contributions (invalid amount) | 422 with field-level error | ⬜ |
| EC-02 | POST /contributions (missing fields) | 422 with multiple errors | ⬜ |
| EC-03 | POST /contributions/batch (row errors) | 422 with row numbers | ⬜ |
| EC-04 | POST /agreements/:id/approve (viewer) | 403 with FORBIDDEN code | ⬜ |
| EC-05 | GET /agreements/:id (invalid ID) | 404 with NOT_FOUND code | ⬜ |
| EC-06 | Duplicate constraint violation | 409 with CONFLICT code | ⬜ |
| EC-07 | Frontend toast (validation) | Toast shows field errors | ⬜ |
| EC-08 | Frontend toast (CSV errors) | Toast shows row numbers | ⬜ |
| EC-09 | Frontend toast (forbidden) | Toast shows permission message | ⬜ |

### Manual Test Steps

#### EC-01: Validation Error (Single Field)
```bash
curl -X POST http://localhost:54321/functions/v1/api-v1/contributions \
  -H "Authorization: Bearer YOUR_JWT" \
  -H "Content-Type: application/json" \
  -d '{
    "investor_id": 1,
    "fund_id": 1,
    "paid_in_date": "2025-01-01",
    "amount": -100
  }'

# Expected (422):
{
  "code": "VALIDATION_ERROR",
  "message": "amount must be a positive number",
  "details": [
    {
      "field": "amount",
      "message": "amount must be a positive number",
      "value": -100,
      "constraint": "amount_positive"
    }
  ],
  "timestamp": "2025-10-19T10:30:00.000Z"
}
```

#### EC-02: Validation Error (Multiple Fields)
```bash
curl -X POST http://localhost:54321/functions/v1/api-v1/contributions \
  -H "Authorization: Bearer YOUR_JWT" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": -100
  }'

# Expected (422):
{
  "code": "VALIDATION_ERROR",
  "message": "Validation failed: 3 error(s)",
  "details": [
    {
      "field": "deal_id/fund_id",
      "message": "Exactly one of deal_id or fund_id is required",
      "value": {"deal_id": null, "fund_id": null}
    },
    {
      "field": "investor_id",
      "message": "investor_id is required",
      "value": null
    },
    {
      "field": "paid_in_date",
      "message": "paid_in_date is required (YYYY-MM-DD format)",
      "value": null
    }
  ],
  "timestamp": "2025-10-19T10:30:00.000Z"
}
```

#### EC-03: Batch Validation (Row Errors)
```bash
curl -X POST http://localhost:54321/functions/v1/api-v1/contributions/batch \
  -H "Authorization: Bearer YOUR_JWT" \
  -H "Content-Type: application/json" \
  -d '[
    {
      "investor_id": 1,
      "fund_id": 1,
      "paid_in_date": "2025-01-01",
      "amount": 1000
    },
    {
      "investor_id": 1,
      "fund_id": 1,
      "paid_in_date": "2025-01-01",
      "amount": -500
    },
    {
      "investor_id": null,
      "fund_id": 1,
      "paid_in_date": "2025-01-01",
      "amount": 1000
    }
  ]'

# Expected (422):
{
  "code": "VALIDATION_ERROR",
  "message": "Validation failed: 2 error(s)",
  "details": [
    {
      "field": "amount",
      "message": "amount must be a positive number",
      "value": -500,
      "constraint": "amount_positive",
      "row": 2
    },
    {
      "field": "investor_id",
      "message": "investor_id is required",
      "value": null,
      "row": 3
    }
  ],
  "timestamp": "2025-10-19T10:30:00.000Z"
}
```

#### EC-04: Forbidden Error (RBAC)
```bash
# First, create a draft agreement and submit it for approval
# Then try to approve as viewer

curl -X POST http://localhost:54321/functions/v1/api-v1/agreements/AGREEMENT_ID/approve \
  -H "Authorization: Bearer VIEWER_JWT"

# Expected (403):
{
  "code": "FORBIDDEN",
  "message": "Requires manager or admin role to approve agreements",
  "timestamp": "2025-10-19T10:30:00.000Z"
}
```

#### EC-05: Not Found Error
```bash
curl -X GET http://localhost:54321/functions/v1/api-v1/agreements/99999 \
  -H "Authorization: Bearer YOUR_JWT"

# Expected (404):
{
  "code": "NOT_FOUND",
  "message": "Agreement not found",
  "timestamp": "2025-10-19T10:30:00.000Z"
}
```

#### EC-06: Conflict Error (Duplicate)
```bash
# Create a party with an email
curl -X POST http://localhost:54321/functions/v1/api-v1/parties \
  -H "Authorization: Bearer YOUR_JWT" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com"
  }'

# Try to create another party with the same email (if unique constraint exists)
# Expected (409):
{
  "code": "CONFLICT",
  "message": "Duplicate entry: email already exists",
  "details": [
    {
      "field": "email",
      "constraint": "23505",
      "message": "duplicate key value violates unique constraint..."
    }
  ],
  "timestamp": "2025-10-19T10:30:00.000Z"
}
```

#### EC-07: Frontend Toast (Validation)
1. Create a form component that submits invalid data
2. Submit the form
3. Observe toast notification:
   ```
   ┌─────────────────────────────┐
   │ ✕ Validation Error          │
   │ • amount: Must be positive  │
   │ • investor_id: Required     │
   └─────────────────────────────┘
   ```

**Test Code:**
```tsx
import { http } from '@/api/http';
import { Button } from '@/components/ui/button';

function TestForm() {
  const handleSubmit = async () => {
    try {
      await http.post('/contributions', {
        amount: -100, // Invalid
        // Missing required fields
      });
    } catch (error) {
      console.error('Error caught:', error);
      // Toast automatically shown by http.ts
    }
  };

  return <Button onClick={handleSubmit}>Submit Invalid Data</Button>;
}
```

#### EC-08: Frontend Toast (CSV Row Errors)
1. Create a CSV import component
2. Upload CSV with errors in rows 5, 12, 18
3. Observe toast:
   ```
   ┌─────────────────────────────────┐
   │ ✕ Validation Error              │
   │ • Row 5: amount: Must be pos.   │
   │ • Row 12: investor_id: Required │
   │ • Row 18: deal_id: Required     │
   └─────────────────────────────────┘
   ```

**Test Code:**
```tsx
import { http } from '@/api/http';

function CSVImport() {
  const handleImport = async () => {
    const invalidData = [
      { investor_id: 1, fund_id: 1, paid_in_date: '2025-01-01', amount: 1000 },
      { investor_id: 1, fund_id: 1, paid_in_date: '2025-01-01', amount: -500 }, // Row 2
      { investor_id: null, fund_id: 1, paid_in_date: '2025-01-01', amount: 1000 }, // Row 3
    ];

    try {
      await http.post('/contributions/batch', invalidData);
    } catch (error) {
      // Toast shows: "Row 2: amount...", "Row 3: investor_id..."
    }
  };

  return <Button onClick={handleImport}>Import</Button>;
}
```

#### EC-09: Frontend Toast (Forbidden)
1. Sign in as viewer
2. Try to approve an agreement
3. Observe toast:
   ```
   ┌─────────────────────────────────────────┐
   │ ✕ Permission Denied                     │
   │ Requires manager or admin role to       │
   │ approve agreements                      │
   └─────────────────────────────────────────┘
   ```

---

## Automated Testing

### Backend Unit Tests (Future)

```typescript
// tests/errors.test.ts
import { assertEquals } from 'https://deno.land/std/testing/asserts.ts';
import { validationError, forbiddenError } from '../supabase/functions/api-v1/errors.ts';

Deno.test('validationError returns 422', async () => {
  const response = validationError([
    { field: 'amount', message: 'Must be positive' }
  ]);

  assertEquals(response.status, 422);

  const body = await response.json();
  assertEquals(body.code, 'VALIDATION_ERROR');
  assertEquals(body.details.length, 1);
  assertEquals(body.details[0].field, 'amount');
});

Deno.test('forbiddenError returns 403', async () => {
  const response = forbiddenError('Requires admin role');

  assertEquals(response.status, 403);

  const body = await response.json();
  assertEquals(body.code, 'FORBIDDEN');
  assertEquals(body.message, 'Requires admin role');
});
```

### Frontend Unit Tests (Future)

```typescript
// src/lib/__tests__/errorToast.test.ts
import { describe, it, expect, vi } from 'vitest';
import { showApiError } from '../errorToast';

describe('showApiError', () => {
  it('shows validation error with field details', () => {
    const toast = vi.fn();
    const error = {
      code: 'VALIDATION_ERROR',
      message: 'Validation failed',
      details: [
        { field: 'amount', message: 'Must be positive' },
        { field: 'investor_id', message: 'Required' },
      ],
      timestamp: '2025-10-19T10:30:00.000Z',
    };

    showApiError(error, toast);

    expect(toast).toHaveBeenCalledWith({
      title: 'Validation Error',
      description: '• amount: Must be positive\n• investor_id: Required',
      variant: 'destructive',
    });
  });

  it('shows row-level errors for CSV imports', () => {
    const toast = vi.fn();
    const error = {
      code: 'VALIDATION_ERROR',
      message: 'Validation failed',
      details: [
        { field: 'amount', message: 'Must be positive', row: 5 },
        { field: 'investor_id', message: 'Required', row: 12 },
      ],
      timestamp: '2025-10-19T10:30:00.000Z',
    };

    showApiError(error, toast);

    expect(toast).toHaveBeenCalledWith({
      title: 'Validation Error',
      description: '• Row 5: amount: Must be positive\n• Row 12: investor_id: Required',
      variant: 'destructive',
    });
  });
});
```

---

## Regression Testing

### Before Each Release

1. **Feature Flags:**
   - [ ] All flags load correctly
   - [ ] Admin can toggle flags
   - [ ] Non-admin users see correct enabled status
   - [ ] FeatureGuard works for all roles
   - [ ] Flag changes reflect immediately (after cache expires)

2. **Error Contract:**
   - [ ] Validation errors show field-level details
   - [ ] CSV imports show row numbers
   - [ ] RBAC errors show permission messages
   - [ ] Toast notifications display correctly
   - [ ] Legacy error format still works (backward compatibility)

---

## Performance Testing

### Feature Flags Caching

```typescript
// Verify flags are cached for 5 minutes
import { useFeatureFlags } from '@/hooks/useFeatureFlags';

function TestCache() {
  const { data, dataUpdatedAt, isStale } = useFeatureFlags();

  console.log('Last updated:', new Date(dataUpdatedAt).toLocaleString());
  console.log('Is stale:', isStale);

  return (
    <div>
      <p>Last Fetch: {new Date(dataUpdatedAt).toLocaleString()}</p>
      <p>Stale: {isStale ? 'Yes' : 'No'}</p>
    </div>
  );
}

// Expected:
// - First load: Fresh data
// - Within 5 minutes: isStale = false
// - After 5 minutes: isStale = true, refetch triggered
```

### Error Response Time

```bash
# Measure response time for validation errors
time curl -X POST http://localhost:54321/functions/v1/api-v1/contributions \
  -H "Authorization: Bearer YOUR_JWT" \
  -H "Content-Type: application/json" \
  -d '{"amount": -100}'

# Expected: < 100ms
```

---

## Sign-Off Checklist

Before marking tickets as DONE:

### ORC-001: Feature Flags
- [ ] All 11 tests pass (FF-01 through FF-11)
- [ ] Database migration applied successfully
- [ ] Admin UI functional
- [ ] Frontend hooks work with caching
- [ ] Documentation complete
- [ ] No breaking changes to existing features

### ORC-002: Error Contract
- [ ] All 9 tests pass (EC-01 through EC-09)
- [ ] Backend error factory used in 4+ endpoints
- [ ] Frontend toast mapper displays all error types
- [ ] CSV imports show row-level errors
- [ ] RBAC errors clear and actionable
- [ ] Documentation complete
- [ ] Backward compatibility maintained

---

## Rollback Plan

### If Feature Flags Break Production

1. **Disable flag checks:**
   ```sql
   -- Temporarily enable all flags for all users
   UPDATE feature_flags SET enabled = true, enabled_for_roles = NULL;
   ```

2. **Remove feature guards:**
   ```tsx
   // Comment out FeatureGuard wrappers
   // <FeatureGuard flag="docs_repository">
   <DocumentsTab />
   // </FeatureGuard>
   ```

3. **Revert migration:**
   ```bash
   supabase migration revert 20251019100010_feature_flags
   ```

### If Error Contract Breaks Production

1. **Revert http.ts:**
   ```bash
   git revert <commit-hash-for-http.ts-changes>
   ```

2. **Disable new error format in backend:**
   ```typescript
   // In errors.ts, temporarily return legacy format
   export function validationError(details: ApiErrorDetail[]) {
     return jsonResponse({ error: 'Validation failed', details }, 422);
   }
   ```

3. **Monitor error logs:**
   - Check Supabase logs for malformed error responses
   - Verify frontend toast displays correctly
