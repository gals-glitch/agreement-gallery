# ORC-001: Feature Flags System

**Status:** Complete
**Date:** 2025-10-19
**Owner:** Orchestrator/Backend/Frontend

---

## Overview

Implements a complete feature flag system for safe, gradual rollout of new features with role-based access control.

### Architecture

```
┌─────────────────┐
│   PostgreSQL    │
│ feature_flags   │
│   (RLS)         │
└────────┬────────┘
         │
         ├─────────────────┐
         │                 │
┌────────▼────────┐  ┌────▼─────────────┐
│  Backend API    │  │  Frontend Hook   │
│  /feature-flags │  │ useFeatureFlag() │
└────────┬────────┘  └────┬─────────────┘
         │                │
         └────────┬───────┘
                  │
         ┌────────▼────────┐
         │  Admin UI       │
         │  FeatureGuard   │
         └─────────────────┘
```

---

## Implementation Details

### 1. Database Layer

**File:** `supabase/migrations/20251019100010_feature_flags.sql`

**Schema:**
```sql
CREATE TABLE feature_flags (
  key TEXT PRIMARY KEY,
  enabled BOOLEAN DEFAULT FALSE NOT NULL,
  enabled_for_roles TEXT[],
  description TEXT NOT NULL,
  rollout_percentage INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

**RLS Policies:**
- All users can **read** flags (SELECT)
- Only **admin** users can write (INSERT, UPDATE, DELETE)

**Seed Flags:**
- `docs_repository` - Document management features
- `charges_engine` - Automated fee calculations
- `credits_management` - Credits ledger system
- `vat_admin` - VAT configuration
- `reports_dashboard` - Advanced reporting

---

### 2. Backend API

**File:** `supabase/functions/api-v1/featureFlags.ts`

**Endpoints:**

#### GET /api-v1/feature-flags
Returns all flags with `isEnabledForUser` computed for current user's role.

**Response:**
```json
[
  {
    "key": "docs_repository",
    "enabled": false,
    "isEnabledForUser": false,
    "description": "Enable document repository and PDF upload features",
    "enabled_for_roles": ["admin"],
    "rollout_percentage": 0
  }
]
```

#### PUT /api-v1/feature-flags/:key
Update flag configuration (admin-only).

**Request:**
```json
{
  "enabled": true,
  "enabled_for_roles": ["admin", "finance"],
  "rollout_percentage": 100
}
```

**Response:**
```json
{
  "ok": true,
  "flag": { /* updated flag */ }
}
```

**Middleware:**
```typescript
// Check if feature is enabled for user
const flagError = await checkFeatureFlag(supabase, userId, 'docs_repository', corsHeaders);
if (flagError) return flagError; // 403 if disabled
```

---

### 3. Frontend Hook

**File:** `src/hooks/useFeatureFlags.ts`

**Usage:**

```tsx
import { useFeatureFlag, useFeatureFlags } from '@/hooks/useFeatureFlags';

// Check single flag
function MyComponent() {
  const { isEnabled, isLoading } = useFeatureFlag('docs_repository');

  if (!isEnabled) return null;

  return <div>Feature is enabled!</div>;
}

// Fetch all flags
function AdminPanel() {
  const { data: flags, isLoading, error } = useFeatureFlags();

  return (
    <div>
      {flags?.map(flag => (
        <div key={flag.key}>{flag.description}</div>
      ))}
    </div>
  );
}

// Update flag (admin only)
function FlagToggle({ flagKey }: { flagKey: string }) {
  const updateFlag = useUpdateFeatureFlag();

  const toggleFlag = () => {
    updateFlag.mutate({
      key: flagKey,
      updates: { enabled: !currentEnabled },
    });
  };

  return <button onClick={toggleFlag}>Toggle</button>;
}
```

**Caching:**
- Flags are cached for **5 minutes** (staleTime)
- Automatic refetch on window focus is **disabled**
- Cache expires after **10 minutes** (gcTime)

---

### 4. Admin UI

**File:** `src/components/FeatureFlagsAdmin.tsx`

**Features:**
- View all flags in table format
- Toggle flags on/off with switches
- Edit role-based access (multi-select dialog)
- Real-time updates via TanStack Query

**Screenshot:**
```
┌─────────────────────────────────────────────────────────────┐
│ Feature Flags Management                                    │
│ Control feature rollout and role-based access              │
├─────────────┬───────────────────┬─────────┬────────┬────────┤
│ Feature     │ Description       │ Enabled │ Roles  │ Actions│
├─────────────┼───────────────────┼─────────┼────────┼────────┤
│ docs_repo   │ Document mgmt     │ [OFF]   │ admin  │ [Edit] │
│ charges_eng │ Fee calculations  │ [ON]    │ finance│ [Edit] │
└─────────────┴───────────────────┴─────────┴────────┴────────┘
```

---

### 5. Feature Guard Component

**File:** `src/components/FeatureGuard.tsx`

**Usage:**
```tsx
import { FeatureGuard } from '@/components/FeatureGuard';

function App() {
  return (
    <div>
      <FeatureGuard flag="docs_repository">
        <DocumentsTab />
      </FeatureGuard>

      <FeatureGuard
        flag="reports_dashboard"
        fallback={<div>Coming Soon</div>}
      >
        <ReportsDashboard />
      </FeatureGuard>
    </div>
  );
}
```

**Props:**
- `flag` (required) - Feature flag key
- `children` (required) - Content to show when enabled
- `fallback` (optional) - Content to show when disabled
- `showLoader` (optional) - Show loading state during fetch

---

## Testing Instructions

### Manual Testing

#### 1. Database Setup
```bash
# Apply migration
supabase db reset
# Or apply specific migration
supabase migration up 20251019100010_feature_flags
```

#### 2. Backend API Testing

**Test GET /feature-flags:**
```bash
curl -X GET http://localhost:54321/functions/v1/api-v1/feature-flags \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Expected Response:**
```json
[
  {
    "key": "docs_repository",
    "enabled": false,
    "isEnabledForUser": false,
    "description": "Enable document repository and PDF upload features",
    "enabled_for_roles": ["admin"],
    "rollout_percentage": 0
  }
]
```

**Test PUT /feature-flags/:key (requires admin role):**
```bash
curl -X PUT http://localhost:54321/functions/v1/api-v1/feature-flags/docs_repository \
  -H "Authorization: Bearer ADMIN_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "enabled": true,
    "enabled_for_roles": ["admin", "finance"]
  }'
```

**Expected Response:**
```json
{
  "ok": true,
  "flag": {
    "key": "docs_repository",
    "enabled": true,
    "enabled_for_roles": ["admin", "finance"]
  }
}
```

**Test Forbidden (non-admin user):**
```bash
curl -X PUT http://localhost:54321/functions/v1/api-v1/feature-flags/docs_repository \
  -H "Authorization: Bearer VIEWER_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"enabled": true}'
```

**Expected Response (403):**
```json
{
  "error": "Unauthorized: requires admin role"
}
```

#### 3. Frontend Testing

**Test Hook:**
```tsx
// In any component
import { useFeatureFlag } from '@/hooks/useFeatureFlags';

function TestComponent() {
  const { isEnabled, isLoading, flag } = useFeatureFlag('docs_repository');

  console.log('Flag enabled:', isEnabled);
  console.log('Flag details:', flag);

  return <div>Enabled: {isEnabled ? 'Yes' : 'No'}</div>;
}
```

**Test Admin UI:**
1. Navigate to Feature Flags admin page
2. Verify table shows all 5 seed flags
3. Toggle a flag on/off
4. Click "Edit Roles" and select/deselect roles
5. Verify changes persist after refresh

**Test Feature Guard:**
```tsx
// Wrap a component with FeatureGuard
<FeatureGuard flag="docs_repository">
  <DocumentsTab />
</FeatureGuard>
```
- With flag OFF: Component should not render
- With flag ON + correct role: Component renders
- With flag ON + wrong role: Component does not render

---

## Integration Examples

### Example 1: Conditional Navigation

```tsx
import { useFeatureFlags } from '@/hooks/useFeatureFlags';

function Navigation() {
  const { data: flags } = useFeatureFlags();

  return (
    <nav>
      <Link to="/">Home</Link>
      <Link to="/agreements">Agreements</Link>

      {flags?.find(f => f.key === 'reports_dashboard')?.isEnabledForUser && (
        <Link to="/reports">Reports</Link>
      )}

      {flags?.find(f => f.key === 'docs_repository')?.isEnabledForUser && (
        <Link to="/documents">Documents</Link>
      )}
    </nav>
  );
}
```

### Example 2: Protected Route

```tsx
import { Navigate } from 'react-router-dom';
import { useFeatureFlag } from '@/hooks/useFeatureFlags';

function ProtectedFeatureRoute({ flag, children }: { flag: string; children: React.ReactNode }) {
  const { isEnabled, isLoading } = useFeatureFlag(flag);

  if (isLoading) return <div>Loading...</div>;
  if (!isEnabled) return <Navigate to="/404" />;

  return <>{children}</>;
}

// In router
<Route
  path="/documents"
  element={
    <ProtectedFeatureRoute flag="docs_repository">
      <DocumentsPage />
    </ProtectedFeatureRoute>
  }
/>
```

### Example 3: Backend Endpoint Protection

```typescript
// In supabase/functions/api-v1/index.ts
import { checkFeatureFlag } from './featureFlags.ts';

async function handleDocuments(req: Request, supabase: any, userId: string) {
  // Check if feature is enabled for user
  const flagError = await checkFeatureFlag(supabase, userId, 'docs_repository', corsHeaders);
  if (flagError) return flagError; // Returns 403 if disabled

  // Feature is enabled, proceed with logic
  return handleDocumentsLogic(req, supabase);
}
```

---

## Migration Path

### Enabling a New Feature

1. **Create feature flag in database** (via seed or admin UI)
2. **Wrap feature UI with FeatureGuard**
3. **Add backend middleware** (if feature has API endpoints)
4. **Test with flag OFF** (ensure no errors)
5. **Enable for admin role only** (beta testing)
6. **Gradually expand to other roles** (ops, finance, viewer)
7. **Enable for all users** (set `enabled_for_roles` to NULL)
8. **Remove flag once stable** (after 1-2 releases)

### Deprecating a Feature

1. **Set flag to `enabled: false`**
2. **Monitor for usage** (analytics/logs)
3. **After 1 sprint with no usage**, remove:
   - Frontend components wrapped in FeatureGuard
   - Backend middleware checks
   - Database flag entry

---

## Known Limitations

1. **No User-Level Targeting:** Flags apply to all users in a role (not individual users)
   - **Workaround:** Create temporary "beta_tester" role for specific users
2. **No Percentage Rollout:** `rollout_percentage` field exists but not yet implemented
   - **Future:** Implement hash-based user sampling
3. **Client-Side Checks Only:** Frontend can't enforce flags (backend must also check)
   - **Guardrail:** Always add backend middleware for sensitive features

---

## Troubleshooting

### Issue: Flag changes not reflected in UI
**Solution:** Flags are cached for 5 minutes. Force refetch:
```tsx
const queryClient = useQueryClient();
queryClient.invalidateQueries({ queryKey: ['feature-flags'] });
```

### Issue: Non-admin user gets 403 when updating flag
**Solution:** Verify user has `admin` role in `user_roles` table:
```sql
SELECT * FROM user_roles WHERE user_id = 'USER_UUID';
```

### Issue: Flag shows enabled but component not rendering
**Solution:** Check `enabled_for_roles`:
- If `NULL`: Enabled for all roles
- If `[]`: Enabled for no roles
- If `['admin']`: Only admins see it

---

## Future Enhancements

- **Percentage Rollout:** Use user UUID hash for gradual deployment (10%, 50%, 100%)
- **Time-Based Flags:** Auto-enable/disable at specific dates
- **A/B Testing:** Support variant flags (e.g., `ui_version: 'A' | 'B'`)
- **Audit Log:** Track who enabled/disabled flags and when
- **Dependency Graph:** Flag A requires Flag B to be enabled
- **Feature Analytics:** Track usage metrics per flag
