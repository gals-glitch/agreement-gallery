# P1 Features: RBAC, Settings, and Credits

## Overview

This document describes the database schema and usage patterns for three P1 features:

1. **P1-A3a: RBAC (Role-Based Access Control)** - User roles and permissions
2. **P1-A3b: Organization Settings** - System configuration and VAT home
3. **P1-B5: Credits System** - FIFO credit linkage and reversals

**Migration File:** `supabase/migrations/20251019110000_rbac_settings_credits.sql`

---

## P1-A3a: RBAC System

### Tables

#### `roles`
Canonical system roles (seeded during migration):

| role_key | name | description |
|----------|------|-------------|
| `admin` | Administrator | Full system access: manage users, roles, settings, approve all workflows |
| `finance` | Finance Manager | Approve charges, manage VAT rates, view financial reports, create invoices |
| `ops` | Operations | View and create charges, manage agreements, import data |
| `manager` | Agreement Manager | Approve agreements, view reports, manage investors and parties |
| `viewer` | Viewer | Read-only access to all data |

#### `user_roles`
Many-to-many mapping between users and roles:

```sql
CREATE TABLE user_roles (
  user_id UUID NOT NULL REFERENCES auth.users(id),
  role_key TEXT NOT NULL REFERENCES roles(key),
  granted_by UUID REFERENCES auth.users(id),
  granted_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (user_id, role_key)
);
```

**Note:** Users can have multiple roles simultaneously.

### Usage Examples

#### Grant a Role to a User

```sql
-- 1. Find the user
SELECT id, email FROM auth.users WHERE email = 'user@example.com';

-- 2. Grant the role
INSERT INTO user_roles (user_id, role_key, granted_by)
VALUES (
  'user-uuid-here',
  'finance',
  auth.uid()  -- Current admin user
);

-- 3. Log the event (optional but recommended)
INSERT INTO audit_log (event_type, actor_id, target_id, entity_type, entity_id, payload)
VALUES (
  'role.granted',
  auth.uid(),
  'user-uuid-here',
  'user_role',
  'finance',
  jsonb_build_object(
    'granted_by', auth.uid(),
    'granted_at', now()
  )
);
```

#### Revoke a Role

```sql
-- 1. Revoke the role
DELETE FROM user_roles
WHERE user_id = 'user-uuid-here'
  AND role_key = 'finance';

-- 2. Log the event
INSERT INTO audit_log (event_type, actor_id, target_id, entity_type, entity_id, payload)
VALUES (
  'role.revoked',
  auth.uid(),
  'user-uuid-here',
  'user_role',
  'finance',
  jsonb_build_object(
    'revoked_by', auth.uid(),
    'revoked_at', now()
  )
);
```

#### Check User's Roles

```sql
SELECT r.key, r.name, r.description, ur.granted_at
FROM user_roles ur
JOIN roles r ON ur.role_key = r.key
WHERE ur.user_id = auth.uid()
ORDER BY ur.granted_at DESC;
```

#### Check if User Has Specific Role (in application code)

```sql
SELECT EXISTS (
  SELECT 1 FROM user_roles
  WHERE user_id = auth.uid()
    AND role_key = 'admin'
) AS is_admin;
```

### RLS Policies

- **SELECT on `roles`:** All authenticated users (to check available roles in UI)
- **INSERT/UPDATE/DELETE on `roles`:** Admins only
- **SELECT on `user_roles`:** All authenticated users (to check permissions)
- **INSERT/UPDATE/DELETE on `user_roles`:** Admins only

---

## P1-A3b: Organization Settings

### Table: `org_settings`

**Singleton Pattern:** Only one row allowed with `id = 1`.

```sql
CREATE TABLE org_settings (
  id INTEGER PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  org_name TEXT NOT NULL DEFAULT 'Buligo Capital',
  default_currency TEXT NOT NULL DEFAULT 'USD' CHECK (default_currency IN ('USD', 'EUR', 'GBP')),
  timezone TEXT NOT NULL DEFAULT 'UTC',
  invoice_prefix TEXT NOT NULL DEFAULT 'BC-',
  vat_display_mode TEXT NOT NULL DEFAULT 'inside_settings' CHECK (vat_display_mode IN ('inside_settings', 'separate_page')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),  -- Auto-updated via trigger
  updated_by UUID REFERENCES auth.users(id)
);
```

### Usage Examples

#### Read Settings

```sql
SELECT * FROM org_settings WHERE id = 1;
```

#### Update Settings

```sql
UPDATE org_settings
SET
  org_name = 'Buligo Capital LLC',
  invoice_prefix = 'BUL-',
  updated_by = auth.uid()
WHERE id = 1;

-- Log the change
INSERT INTO audit_log (event_type, actor_id, entity_type, payload)
VALUES (
  'settings.updated',
  auth.uid(),
  'org_settings',
  jsonb_build_object(
    'fields_updated', ARRAY['org_name', 'invoice_prefix'],
    'old_values', jsonb_build_object('org_name', 'Buligo Capital', 'invoice_prefix', 'BC-'),
    'new_values', jsonb_build_object('org_name', 'Buligo Capital LLC', 'invoice_prefix', 'BUL-')
  )
);
```

### RLS Policies

- **SELECT:** All authenticated users
- **UPDATE:** Admins only
- **INSERT/DELETE:** Blocked (singleton pattern - only one row allowed)

---

## P1-B5: Credits System

### Tables

#### `credits`
Tracks investor credits with FIFO ordering:

```sql
CREATE TABLE credits (
  id BIGSERIAL PRIMARY KEY,
  investor_id BIGINT NOT NULL REFERENCES investors(id),
  fund_id BIGINT REFERENCES funds(id),       -- XOR with deal_id
  deal_id BIGINT REFERENCES deals(id),       -- XOR with fund_id
  reason TEXT NOT NULL CHECK (reason IN ('REPURCHASE', 'EQUALISATION', 'MANUAL', 'REFUND')),
  original_amount NUMERIC(15,2) NOT NULL CHECK (original_amount > 0),
  applied_amount NUMERIC(15,2) DEFAULT 0 NOT NULL,
  available_amount NUMERIC(15,2) GENERATED ALWAYS AS (original_amount - applied_amount) STORED,
  status TEXT DEFAULT 'AVAILABLE' NOT NULL CHECK (status IN ('AVAILABLE', 'FULLY_APPLIED', 'EXPIRED', 'CANCELLED')),
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  created_by UUID REFERENCES auth.users(id),
  notes TEXT,
  CONSTRAINT credits_scope_check CHECK (
    (fund_id IS NOT NULL AND deal_id IS NULL) OR
    (fund_id IS NULL AND deal_id IS NOT NULL)
  )
);
```

**Key Features:**
- `available_amount` is a **computed column** (GENERATED ALWAYS AS)
- **FIFO ordering** via partial index: `idx_credits_available_fifo` on `(investor_id, created_at ASC) WHERE available_amount > 0`
- **Auto-status update:** Status changes to `FULLY_APPLIED` when `available_amount = 0` (via trigger)

#### `credit_applications`
Links credits to charges (with reversal support):

```sql
CREATE TABLE credit_applications (
  id BIGSERIAL PRIMARY KEY,
  credit_id BIGINT NOT NULL REFERENCES credits(id),
  charge_id BIGINT,  -- Will reference charges(id) when charges table exists
  amount_applied NUMERIC(15,2) NOT NULL CHECK (amount_applied > 0),
  applied_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  applied_by UUID REFERENCES auth.users(id),
  reversed_at TIMESTAMPTZ,
  reversed_by UUID REFERENCES auth.users(id),
  reversal_reason TEXT
);
```

### Credit Reasons

| Reason | Description | Auto/Manual |
|--------|-------------|-------------|
| `REPURCHASE` | Auto-generated when investor repurchases shares | Auto |
| `EQUALISATION` | Manual credit for equalising fees across investors | Manual |
| `MANUAL` | Admin-created credit for special cases | Manual |
| `REFUND` | Refund credit (overpayment, adjustment) | Manual |

### Usage Examples

#### Create a Credit (Auto - from Repurchase)

```sql
-- After creating a REPURCHASE transaction, create a credit
INSERT INTO credits (investor_id, fund_id, reason, original_amount, created_by, notes)
VALUES (
  123,  -- investor_id
  1,    -- fund_id (or use deal_id instead)
  'REPURCHASE',
  50000.00,
  auth.uid(),
  'Auto-generated from repurchase transaction TX-12345'
);
```

#### Create a Manual Credit (Equalisation)

```sql
INSERT INTO credits (investor_id, fund_id, reason, original_amount, created_by, notes)
VALUES (
  456,
  1,
  'EQUALISATION',
  10000.00,
  auth.uid(),
  'Manual credit to equalise fees with other investors in Fund VI'
);

-- Log the event
INSERT INTO audit_log (event_type, actor_id, target_id, entity_type, entity_id, payload)
VALUES (
  'credit.created',
  auth.uid(),
  456,  -- investor_id as target
  'credit',
  currval('credits_id_seq')::TEXT,
  jsonb_build_object(
    'investor_id', 456,
    'amount', 10000.00,
    'reason', 'EQUALISATION'
  )
);
```

#### Query Available Credits (FIFO Order)

```sql
-- Get available credits for investor (oldest first)
SELECT
  id,
  reason,
  original_amount,
  applied_amount,
  available_amount,
  created_at,
  notes
FROM credits
WHERE investor_id = 123
  AND available_amount > 0
ORDER BY created_at ASC;  -- FIFO: oldest first
```

**EXPLAIN Plan (estimated):**
```
Index Scan using idx_credits_available_fifo on credits
  Index Cond: (investor_id = 123)
  Filter: (available_amount > 0)
  Rows: ~10
```

#### Apply Credit to Charge (FIFO)

```sql
-- Scenario: Charge amount = $30,000
-- Available credits: Credit #1 ($20,000 available), Credit #2 ($15,000 available)
-- Result: Apply $20,000 from Credit #1 + $10,000 from Credit #2

-- Step 1: Apply first credit (fully)
INSERT INTO credit_applications (credit_id, charge_id, amount_applied, applied_by)
VALUES (1, 456, 20000.00, auth.uid());

UPDATE credits
SET applied_amount = applied_amount + 20000.00
WHERE id = 1;
-- Status auto-updates to FULLY_APPLIED via trigger (available_amount = 0)

-- Step 2: Apply partial amount from second credit
INSERT INTO credit_applications (credit_id, charge_id, amount_applied, applied_by)
VALUES (2, 456, 10000.00, auth.uid());

UPDATE credits
SET applied_amount = applied_amount + 10000.00
WHERE id = 2;
-- Credit #2 still has $5,000 available (status remains AVAILABLE)
```

#### Reverse Credit Application (Charge Rejected)

```sql
-- When charge is rejected, reverse all credit applications

-- Step 1: Mark application as reversed
UPDATE credit_applications
SET
  reversed_at = now(),
  reversed_by = auth.uid(),
  reversal_reason = 'Charge #456 rejected by finance'
WHERE charge_id = 456
  AND reversed_at IS NULL;  -- Only reverse active applications

-- Step 2: Decrement applied_amount on credits (restore availability)
UPDATE credits
SET applied_amount = applied_amount - (
  SELECT SUM(amount_applied)
  FROM credit_applications
  WHERE credit_id = credits.id
    AND charge_id = 456
    AND reversed_at = now()  -- Only reverse from this operation
)
WHERE id IN (
  SELECT credit_id
  FROM credit_applications
  WHERE charge_id = 456
    AND reversed_at = now()
);

-- Step 3: Log reversal
INSERT INTO audit_log (event_type, actor_id, entity_type, entity_id, payload)
VALUES (
  'credit.reversed',
  auth.uid(),
  'credit_application',
  456::TEXT,  -- charge_id
  jsonb_build_object(
    'charge_id', 456,
    'reason', 'Charge rejected',
    'amount_reversed', (SELECT SUM(amount_applied) FROM credit_applications WHERE charge_id = 456 AND reversed_at IS NOT NULL)
  )
);
```

### FIFO Logic (Step-by-Step)

**Scenario:** Investor has 3 available credits, charge amount is $50,000

| Credit ID | Created At | Available Amount |
|-----------|------------|------------------|
| 1 | 2025-01-01 | $20,000 |
| 2 | 2025-02-01 | $15,000 |
| 3 | 2025-03-01 | $30,000 |

**FIFO Application:**
1. Apply $20,000 from Credit #1 (fully consumed, status → FULLY_APPLIED)
2. Apply $15,000 from Credit #2 (fully consumed, status → FULLY_APPLIED)
3. Apply $15,000 from Credit #3 (partial, $15,000 still available)

**SQL:**
```sql
-- Loop through credits in FIFO order (application code)
WITH available_credits AS (
  SELECT id, available_amount, created_at
  FROM credits
  WHERE investor_id = 123
    AND available_amount > 0
  ORDER BY created_at ASC
)
SELECT * FROM available_credits;

-- For each credit, apply min(available_amount, remaining_charge_amount)
-- until charge is fully satisfied
```

### RLS Policies

- **SELECT on `credits`:** Finance, Ops, Manager, Admin roles
- **INSERT/UPDATE/DELETE on `credits`:** Finance, Admin roles only
- **SELECT on `credit_applications`:** Finance, Ops, Manager, Admin roles
- **INSERT/UPDATE/DELETE on `credit_applications`:** Finance, Admin roles only

---

## Audit Log

### Table: `audit_log`

Comprehensive audit trail for all system events:

```sql
CREATE TABLE audit_log (
  id BIGSERIAL PRIMARY KEY,
  event_type TEXT NOT NULL,  -- 'role.granted', 'settings.updated', 'credit.applied', etc.
  actor_id UUID REFERENCES auth.users(id),  -- User who performed action (NULL for system)
  target_id UUID,  -- Target entity (user_id, investor_id, etc.)
  entity_type TEXT,  -- 'user_role', 'settings', 'credit', 'charge'
  entity_id TEXT,  -- Entity identifier (role_key, credit ID, etc.)
  payload JSONB,  -- Flexible event data
  timestamp TIMESTAMPTZ DEFAULT now(),
  ip_address INET,
  user_agent TEXT
);
```

### Event Types

| Event Type | Description | Example Payload |
|------------|-------------|-----------------|
| `role.granted` | User role granted | `{"role_key": "finance", "granted_by": "admin-uuid"}` |
| `role.revoked` | User role revoked | `{"role_key": "finance", "revoked_by": "admin-uuid"}` |
| `settings.updated` | Org settings changed | `{"fields": ["org_name"], "old_value": "X", "new_value": "Y"}` |
| `credit.created` | Credit created | `{"investor_id": 123, "amount": 50000, "reason": "REPURCHASE"}` |
| `credit.applied` | Credit applied to charge | `{"credit_id": 1, "charge_id": 456, "amount": 20000}` |
| `credit.reversed` | Credit application reversed | `{"charge_id": 456, "reason": "Charge rejected"}` |

### Usage Examples

#### Query Audit Trail for User

```sql
SELECT
  event_type,
  entity_type,
  entity_id,
  payload,
  timestamp
FROM audit_log
WHERE target_id = 'user-uuid-here'
ORDER BY timestamp DESC
LIMIT 20;
```

#### Query Recent Settings Changes

```sql
SELECT
  event_type,
  actor_id,
  payload->>'old_value' AS old_value,
  payload->>'new_value' AS new_value,
  timestamp
FROM audit_log
WHERE entity_type = 'org_settings'
ORDER BY timestamp DESC;
```

#### Query All Credit Events for Investor

```sql
SELECT
  event_type,
  payload,
  timestamp
FROM audit_log
WHERE entity_type = 'credit'
  AND (payload->>'investor_id')::BIGINT = 123
ORDER BY timestamp DESC;
```

---

## Performance Considerations

### RBAC Queries
- **user_roles lookup:** O(1) via `idx_user_roles_user_id`
- **Expected overhead:** Minimal (<1ms per permission check)
- **Scale:** <100 users × 2 roles avg = ~200 rows

### Credits FIFO Queries
- **Index:** `idx_credits_available_fifo` on `(investor_id, created_at ASC) WHERE available_amount > 0`
- **Query cost:** Index Scan (~1.0 cost for 10 credits)
- **Expected rows per investor:** <1000 active credits (typically <10)

### Audit Log
- **GIN index on payload:** Enables flexible JSONB queries
- **Growth rate:** ~1000 events/day = 365K/year
- **Future optimization:** Consider partitioning by month if >10M rows

---

## Migration Safety

This migration is **zero-downtime safe**:
- All new columns have defaults or are nullable
- Foreign keys reference existing tables (investors, funds, deals, auth.users)
- Indexes created with `IF NOT EXISTS`
- RLS policies use `DO $$ IF NOT EXISTS` blocks
- Seed data uses `ON CONFLICT DO NOTHING`
- Old incompatible structures (app_role enum, old user_roles) are dropped cleanly

**IMPORTANT:** The migration drops the old `app_role` enum and `user_roles` table from migration `20250921054238`. If you have existing role assignments in that table, migrate them first before applying this migration.

---

## Acceptance Criteria Checklist

- [x] Roles table created with 5 canonical roles (admin, finance, ops, manager, viewer)
- [x] user_roles table created with proper foreign keys and indexes
- [x] audit_log table created with JSONB payload and GIN index
- [x] org_settings table created with singleton constraint (id=1)
- [x] credits table created with FIFO index and auto-status trigger
- [x] credit_applications table created with reversal support
- [x] All indexes created for performance (FIFO, role lookups, audit queries)
- [x] RLS policies enforce admin-only writes for roles/settings
- [x] RLS policies enforce finance/admin writes for credits
- [x] Seed data inserted (5 roles, org_settings defaults)
- [x] Triggers created (updated_at auto-update, status auto-update)
- [x] All foreign keys valid (no missing tables)
- [x] Migration is additive only (except cleanup of old incompatible structures)
- [x] Comments on all tables and columns
- [x] Verification queries provided (commented in migration)

---

## Next Steps

### Application Integration

1. **RBAC:** Update auth middleware to check `user_roles` table instead of old `app_role` enum
2. **Settings:** Create Settings UI component to read/update `org_settings`
3. **Credits:** Implement FIFO auto-apply logic in charge creation workflow
4. **Audit:** Add audit log entries for all sensitive operations

### Future Enhancements

1. **RBAC:** Add permission-level granularity (currently role-based only)
2. **Credits:** Add expiration date support (`expires_at` column)
3. **Audit:** Add audit log retention policy (archive old events)
4. **Settings:** Add email templates, notification preferences

---

## Support

For questions or issues, contact the database architecture team or refer to the migration file comments.
