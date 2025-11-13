# v1.8.0 Schema Documentation

## Overview

This document provides comprehensive schema documentation for v1.8.0 - Investor Fee Workflow E2E.

## Migration Files

### Primary Migration
- **File**: `20251021000000_v1_8_0_schema_prep.sql`
- **Date**: 2025-10-21
- **Status**: Ready to apply

### Dependencies
- `20251019130000_charges_FIXED.sql` (v1.7.0 - charges table)
- `20251020000002_fix_credits_schema.sql` (v1.7.0 - credits schema, unique index, FK fixes)
- `20251020000001_fix_rls_infinite_recursion.sql` (v1.7.0 - user_has_role() function)
- `20251019110000_rbac_settings_credits.sql` (v1.7.0 - RBAC, credits_ledger)

---

## Schema Changes

### DB-01: Unique Index on charges.contribution_id

**Purpose**: Enable idempotent charge compute via POST /charges/compute

**Status**: ✅ Already created in v1.7.0 (20251020000002_fix_credits_schema.sql)

**Index Definition**:
```sql
CREATE UNIQUE INDEX idx_charges_contribution_unique
  ON charges (contribution_id);
```

**Usage Pattern**:
```sql
INSERT INTO charges (...)
VALUES (...)
ON CONFLICT (contribution_id) DO UPDATE
SET base_amount = EXCLUDED.base_amount, ...;
```

**Benefits**:
- Prevents duplicate charges for the same contribution
- Enables idempotent API calls (calling POST /charges/compute twice with same contribution_id returns same charge)
- O(log n) lookup performance for conflict detection

---

### DB-02: FK Constraint credit_applications → credits_ledger

**Purpose**: Ensure referential integrity between credit applications and credits ledger

**Status**: ✅ Already fixed in v1.7.0 (20251020000002_fix_credits_schema.sql)

**Constraint Definition**:
```sql
ALTER TABLE credit_applications
  ADD CONSTRAINT credit_applications_credit_id_fkey
  FOREIGN KEY (credit_id)
  REFERENCES credits_ledger(id)
  ON DELETE RESTRICT;
```

**Data Types**:
- `credit_applications.credit_id`: BIGINT
- `credits_ledger.id`: BIGINT (BIGSERIAL primary key)

**ON DELETE RESTRICT**:
- Cannot delete a credit if applications exist
- Prevents orphaned credit applications
- Must reverse/delete applications before deleting credit

**Benefits**:
- Prevents orphaned credit_applications (credit_id pointing to non-existent credit)
- Ensures data integrity for FIFO credit application logic
- Database-level validation (cannot be bypassed by application bugs)

---

### DB-03: RLS Policies for Charges Table

**Purpose**: Implement granular row-level security for charges workflow

**Status**: ✅ Updated in v1.8.0 (splits old "Admin can manage" into INSERT, UPDATE, DELETE policies)

**Policies**:

#### 1. SELECT Policy: "Finance+ can read all charges"
```sql
CREATE POLICY "Finance+ can read all charges"
  ON charges
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.user_id = auth.uid()
      AND user_roles.role_key IN ('admin', 'finance', 'ops', 'manager')
    )
  );
```

**Allowed Roles**: Admin, Finance, Ops, Manager

**Use Cases**:
- View charges list in UI
- Export charges to CSV
- Generate financial reports
- Audit trail queries

---

#### 2. INSERT Policy: "charges_insert_finance_admin"
```sql
CREATE POLICY "charges_insert_finance_admin"
  ON charges
  FOR INSERT
  TO authenticated
  WITH CHECK (
    public.user_has_role(auth.uid(), 'finance') OR
    public.user_has_role(auth.uid(), 'admin')
  );
```

**Allowed Roles**: Finance, Admin

**Use Cases**:
- Manual charge creation via UI
- CSV import of charges
- POST /charges/compute endpoint (when called by finance user)

**Note**: Service role bypasses this policy for batch operations

---

#### 3. UPDATE Policy: "charges_update_admin"
```sql
CREATE POLICY "charges_update_admin"
  ON charges
  FOR UPDATE
  TO authenticated
  USING (public.user_has_role(auth.uid(), 'admin'))
  WITH CHECK (public.user_has_role(auth.uid(), 'admin'));
```

**Allowed Roles**: Admin only

**Use Cases**:
- Approve charge (DRAFT → PENDING → APPROVED)
- Reject charge (set status to REJECTED, set reject_reason)
- Mark charge as paid (APPROVED → PAID, set paid_at)
- Update charge amounts (exceptional cases)

**Workflow States**:
```
DRAFT → PENDING → APPROVED → PAID
   ↓        ↓          ↓
        REJECTED
```

---

#### 4. DELETE Policy: "charges_delete_admin"
```sql
CREATE POLICY "charges_delete_admin"
  ON charges
  FOR DELETE
  TO authenticated
  USING (public.user_has_role(auth.uid(), 'admin'));
```

**Allowed Roles**: Admin only

**Use Cases**:
- Hard delete for data cleanup (use cautiously)
- Remove test data

**Recommendation**: Use soft delete instead (set status to DELETED or use deleted_at timestamp)

---

### DB-04: Service Role Operations

**Purpose**: Enable system-level batch operations that bypass RLS

**Status**: ✅ Documented (no code changes - Supabase default behavior)

**Behavior**:

#### User JWT (Anon Key + Auth)
- Uses `SUPABASE_ANON_KEY` with `auth.signInWith*()`
- RLS policies are enforced based on user role
- Example: Finance user can INSERT charges via UI

#### Service Role Key
- Uses `SUPABASE_SERVICE_ROLE_KEY` in `createClient()`
- Bypasses ALL RLS policies
- Full access to all tables (SELECT, INSERT, UPDATE, DELETE)
- Should ONLY be used in Edge Functions (server-side)

**Security Notes**:
- NEVER expose service role key to client-side code
- Always validate user permissions in Edge Function before using service role
- Log all service role operations to audit_log for compliance

**Example Usage**:
```typescript
// Edge Function: POST /charges/compute
import { createClient } from '@supabase/supabase-js'

const supabaseAdmin = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!  // Bypasses RLS
)

// Batch compute charges for all pending contributions
const { data, error } = await supabaseAdmin
  .from('charges')
  .insert(computedCharges)
  .select()
```

---

## RLS Policy Matrix

### Charges Table

| Role       | SELECT | INSERT | UPDATE | DELETE | Notes                                      |
|------------|--------|--------|--------|--------|--------------------------------------------|
| **admin**  | ✅     | ✅     | ✅     | ✅     | Full access (all workflow operations)      |
| **finance**| ✅     | ✅     | ❌     | ❌     | Can create charges, cannot approve/reject  |
| **ops**    | ✅     | ❌     | ❌     | ❌     | Read-only (reporting)                      |
| **manager**| ✅     | ❌     | ❌     | ❌     | Read-only (oversight)                      |
| **viewer** | ❌     | ❌     | ❌     | ❌     | No access to charges                       |
| **service**| ✅     | ✅     | ✅     | ✅     | Bypasses RLS (batch operations)            |

### Credits Ledger Table

| Role       | SELECT | INSERT | UPDATE | DELETE | Notes                                      |
|------------|--------|--------|--------|--------|--------------------------------------------|
| **admin**  | ✅     | ✅     | ✅     | ✅     | Full access                                |
| **finance**| ✅     | ✅     | ✅     | ✅     | Can manage credits (manual credits)        |
| **ops**    | ✅     | ❌     | ❌     | ❌     | Read-only                                  |
| **manager**| ✅     | ❌     | ❌     | ❌     | Read-only                                  |
| **viewer** | ❌     | ❌     | ❌     | ❌     | No access                                  |
| **service**| ✅     | ✅     | ✅     | ✅     | Bypasses RLS (auto-create from repurchase) |

### Credit Applications Table

| Role       | SELECT | INSERT | UPDATE | DELETE | Notes                                      |
|------------|--------|--------|--------|--------|--------------------------------------------|
| **admin**  | ✅     | ✅     | ✅     | ✅     | Full access                                |
| **finance**| ✅     | ✅     | ✅     | ✅     | Can apply/reverse credits                  |
| **ops**    | ✅     | ❌     | ❌     | ❌     | Read-only                                  |
| **manager**| ✅     | ❌     | ❌     | ❌     | Read-only                                  |
| **viewer** | ❌     | ❌     | ❌     | ❌     | No access                                  |
| **service**| ✅     | ✅     | ✅     | ✅     | Bypasses RLS (FIFO auto-apply)             |

---

## Index Strategy

### Charges Table

| Index Name                          | Type   | Columns                      | Purpose                                    |
|-------------------------------------|--------|------------------------------|--------------------------------------------|
| `idx_charges_contribution_unique`   | UNIQUE | `contribution_id`            | Idempotent upsert, prevent duplicates      |
| `idx_charges_status`                | BTREE  | `status`                     | Filter by workflow state (DRAFT/APPROVED)  |
| `idx_charges_investor_status`       | BTREE  | `investor_id, status`        | Investor charges by status (common query)  |
| `idx_charges_deal`                  | BTREE  | `deal_id` (partial)          | Deal-level charges (WHERE deal_id IS NOT NULL) |
| `idx_charges_fund`                  | BTREE  | `fund_id` (partial)          | Fund-level charges (WHERE fund_id IS NOT NULL) |
| `idx_charges_approved_at`           | BTREE  | `approved_at` (partial)      | Audit queries (WHERE approved_at IS NOT NULL) |
| `idx_charges_paid_at`               | BTREE  | `paid_at` (partial)          | Payment tracking (WHERE paid_at IS NOT NULL) |
| `idx_charges_numeric_id`            | BTREE  | `numeric_id`                 | FK lookups from credit_applications        |
| `idx_charges_net_amount`            | BTREE  | `net_amount` (partial)       | Outstanding charges (WHERE net_amount > 0) |

### Credits Ledger Table

| Index Name                               | Type   | Columns                                | Purpose                                    |
|------------------------------------------|--------|----------------------------------------|--------------------------------------------|
| `idx_credits_ledger_investor_fund_fifo`  | BTREE  | `investor_id, fund_id, created_at ASC` | FIFO fund-scoped credits (WHERE available_amount > 0) |
| `idx_credits_ledger_investor_deal_fifo`  | BTREE  | `investor_id, deal_id, created_at ASC` | FIFO deal-scoped credits (WHERE available_amount > 0) |
| `idx_credits_ledger_available_fifo`      | BTREE  | `investor_id, created_at ASC`          | FIFO credits without scope filter          |
| `idx_credits_ledger_investor_currency`   | BTREE  | `investor_id, currency`                | Multi-currency support (WHERE available_amount > 0) |
| `idx_credits_ledger_investor_id`         | BTREE  | `investor_id`                          | General investor lookups                   |
| `idx_credits_ledger_fund_id`             | BTREE  | `fund_id` (partial)                    | Fund-level credits (WHERE fund_id IS NOT NULL) |
| `idx_credits_ledger_deal_id`             | BTREE  | `deal_id` (partial)                    | Deal-level credits (WHERE deal_id IS NOT NULL) |
| `idx_credits_ledger_status`              | BTREE  | `status`                               | Filter by AVAILABLE/FULLY_APPLIED/EXPIRED  |

### Credit Applications Table

| Index Name                              | Type   | Columns                        | Purpose                                    |
|-----------------------------------------|--------|--------------------------------|--------------------------------------------|
| `idx_credit_applications_credit_id`     | BTREE  | `credit_id`                    | FK lookups to credits_ledger               |
| `idx_credit_applications_charge_id`     | BTREE  | `charge_id` (partial)          | FK lookups to charges (WHERE charge_id IS NOT NULL) |
| `idx_credit_applications_credit_active` | BTREE  | `credit_id, applied_at DESC`   | Active applications (WHERE reversed_at IS NULL) |
| `idx_credit_applications_charge_all`    | BTREE  | `charge_id, applied_at DESC`   | All applications for charge (including reversed) |

---

## Query Patterns

### 1. Idempotent Charge Compute

```sql
INSERT INTO charges (
  investor_id, fund_id, contribution_id, status,
  base_amount, discount_amount, vat_amount, total_amount, currency, snapshot_json
)
VALUES (?, ?, ?, 'DRAFT', ?, ?, ?, ?, ?, ?::jsonb)
ON CONFLICT (contribution_id) DO UPDATE
SET
  base_amount = EXCLUDED.base_amount,
  discount_amount = EXCLUDED.discount_amount,
  vat_amount = EXCLUDED.vat_amount,
  total_amount = EXCLUDED.total_amount,
  snapshot_json = EXCLUDED.snapshot_json,
  updated_at = now()
RETURNING id, numeric_id, status;
```

**Index Used**: `idx_charges_contribution_unique`

**Performance**: O(log n) conflict detection + O(1) insert/update

---

### 2. FIFO Credit Query (Fund-Scoped)

```sql
SELECT
  id,
  available_amount,
  created_at
FROM credits_ledger
WHERE investor_id = ?
  AND fund_id = ?
  AND available_amount > 0
  AND status = 'AVAILABLE'
ORDER BY created_at ASC
LIMIT 10;
```

**Index Used**: `idx_credits_ledger_investor_fund_fifo`

**Performance**: O(log n) index seek + O(k) scan (k = limit)

**Query Plan**:
```
Index Scan using idx_credits_ledger_investor_fund_fifo
  Index Cond: (investor_id = ? AND fund_id = ?)
  Filter: (available_amount > 0 AND status = 'AVAILABLE')
  Order By: created_at ASC
  Limit: 10
```

---

### 3. Apply Credit to Charge

```sql
-- Step 1: Insert credit application
INSERT INTO credit_applications (credit_id, charge_id, amount_applied)
VALUES (?, ?, ?)
RETURNING id;

-- Step 2: Update credits_ledger.applied_amount
UPDATE credits_ledger
SET applied_amount = applied_amount + ?
WHERE id = ?;

-- Step 3: Auto-update status (via trigger)
-- Trigger automatically sets status = 'FULLY_APPLIED' when available_amount = 0
```

**Indexes Used**:
- `credit_applications` PK (insert)
- `credits_ledger` PK (update)
- Trigger uses `available_amount` generated column

**Performance**: O(log n) FK lookup + O(1) insert + O(1) update

---

### 4. Charge History with Credits

```sql
SELECT
  c.id,
  c.numeric_id,
  c.investor_id,
  c.status,
  c.total_amount,
  c.credits_applied_amount,
  c.net_amount,
  ca.id AS application_id,
  ca.credit_id,
  ca.amount_applied,
  ca.applied_at,
  ca.reversed_at
FROM charges c
LEFT JOIN credit_applications ca ON ca.charge_id = c.numeric_id
WHERE c.investor_id = ?
ORDER BY c.created_at DESC;
```

**Indexes Used**:
- `idx_charges_investor_status` (charges filter)
- `idx_credit_applications_charge_all` (join)

**Performance**: O(log n) + O(m) join (m = applications per charge)

---

### 5. Reverse Credit Application

```sql
-- Step 1: Mark application as reversed
UPDATE credit_applications
SET
  reversed_at = now(),
  reversed_by = ?,
  reversal_reason = ?
WHERE id = ?
RETURNING credit_id, amount_applied;

-- Step 2: Decrease credits_ledger.applied_amount
UPDATE credits_ledger
SET applied_amount = applied_amount - ?
WHERE id = ?;

-- Step 3: Auto-update status (via trigger)
-- Trigger may revert status from 'FULLY_APPLIED' back to 'AVAILABLE'
```

**Use Cases**:
- Charge rejected by admin
- Charge cancelled
- Credit misapplied (manual correction)

---

## Data Integrity Constraints

### Charges Table

| Constraint                    | Type          | Description                                  |
|-------------------------------|---------------|----------------------------------------------|
| `charges_one_scope_ck`        | CHECK         | Exactly one of `deal_id` OR `fund_id` (XOR) |
| `idx_charges_contribution_unique` | UNIQUE    | One charge per contribution (idempotency)    |
| FK to `investors(id)`         | FOREIGN KEY   | ON DELETE RESTRICT                           |
| FK to `deals(id)`             | FOREIGN KEY   | ON DELETE RESTRICT                           |
| FK to `funds(id)`             | FOREIGN KEY   | ON DELETE RESTRICT                           |
| FK to `contributions(id)`     | FOREIGN KEY   | ON DELETE RESTRICT                           |

### Credits Ledger Table

| Constraint                    | Type          | Description                                  |
|-------------------------------|---------------|----------------------------------------------|
| `credits_scope_check`         | CHECK         | Exactly one of `deal_id` OR `fund_id` (XOR) |
| `reason` CHECK                | CHECK         | IN ('REPURCHASE', 'EQUALISATION', 'MANUAL', 'REFUND') |
| `status` CHECK                | CHECK         | IN ('AVAILABLE', 'FULLY_APPLIED', 'EXPIRED', 'CANCELLED') |
| `original_amount` CHECK       | CHECK         | > 0                                          |
| `applied_amount` CHECK        | CHECK         | >= 0 AND <= original_amount                  |
| `available_amount` GENERATED  | COMPUTED      | original_amount - applied_amount (STORED)    |
| FK to `investors(id)`         | FOREIGN KEY   | ON DELETE RESTRICT                           |
| FK to `funds(id)`             | FOREIGN KEY   | ON DELETE RESTRICT                           |
| FK to `deals(id)`             | FOREIGN KEY   | ON DELETE RESTRICT                           |

### Credit Applications Table

| Constraint                              | Type          | Description                                  |
|-----------------------------------------|---------------|----------------------------------------------|
| `credit_applications_credit_id_fkey`    | FOREIGN KEY   | → `credits_ledger(id)` ON DELETE RESTRICT    |
| `credit_applications_charge_numeric_id_fkey` | FOREIGN KEY | → `charges(numeric_id)` ON DELETE CASCADE |
| `credit_applications_amount_positive_ck`| CHECK         | `amount_applied > 0`                         |
| Validation trigger                      | TRIGGER       | Checks available_amount, status, currency match |

---

## Triggers

### Charges Table

#### `charges_updated_at_trigger`
```sql
CREATE TRIGGER charges_updated_at_trigger
  BEFORE UPDATE ON charges
  FOR EACH ROW
  EXECUTE FUNCTION update_charges_updated_at();
```

**Purpose**: Auto-update `updated_at` timestamp on every UPDATE

---

### Credits Ledger Table

#### `credits_ledger_auto_status_update`
```sql
CREATE TRIGGER credits_ledger_auto_status_update
  BEFORE UPDATE ON credits_ledger
  FOR EACH ROW
  EXECUTE FUNCTION update_credit_status();
```

**Purpose**: Auto-update status to 'FULLY_APPLIED' when `available_amount = 0`

**Logic**:
```sql
IF NEW.available_amount = 0 AND NEW.status = 'AVAILABLE' THEN
  NEW.status := 'FULLY_APPLIED';
END IF;
```

---

### Credit Applications Table

#### `credit_applications_validate_trigger`
```sql
CREATE TRIGGER credit_applications_validate_trigger
  BEFORE INSERT ON credit_applications
  FOR EACH ROW
  EXECUTE FUNCTION validate_credit_application();
```

**Purpose**: Validate credit application before insertion

**Checks**:
1. Credit exists (`credit_id` in `credits_ledger`)
2. Credit has sufficient `available_amount >= amount_applied`
3. Credit status is 'AVAILABLE'
4. Currency matches (if `charge_id` provided)

**Raises Exception If**:
- Credit doesn't exist
- Insufficient available amount
- Credit not available
- Currency mismatch

---

## EXPLAIN Plans

### FIFO Credit Query

```sql
EXPLAIN ANALYZE
SELECT id, available_amount, created_at
FROM credits_ledger
WHERE investor_id = 1
  AND fund_id = 1
  AND available_amount > 0
  AND status = 'AVAILABLE'
ORDER BY created_at ASC
LIMIT 10;
```

**Expected Plan**:
```
Limit  (cost=0.29..8.31 rows=10 width=48)
  ->  Index Scan using idx_credits_ledger_investor_fund_fifo on credits_ledger
        (cost=0.29..8.31 rows=10 width=48)
      Index Cond: ((investor_id = 1) AND (fund_id = 1))
      Filter: ((available_amount > '0'::numeric) AND (status = 'AVAILABLE'::text))
```

**Performance**: ~0.1ms for 10 credits (indexed scan)

---

### Idempotent Charge Upsert

```sql
EXPLAIN ANALYZE
INSERT INTO charges (...)
VALUES (...)
ON CONFLICT (contribution_id) DO UPDATE SET ...;
```

**Expected Plan**:
```
Insert on charges  (cost=0.00..0.01 rows=1 width=xxx)
  Conflict Resolution: UPDATE
  Conflict Arbiter Indexes: idx_charges_contribution_unique
  ->  Result  (cost=0.00..0.01 rows=1 width=xxx)
```

**Performance**: ~1-2ms (conflict detection + insert/update)

---

## Summary

v1.8.0 schema preparation is complete with:

1. ✅ **DB-01**: Unique index on `charges.contribution_id` (idempotent compute)
2. ✅ **DB-02**: FK constraint `credit_applications.credit_id` → `credits_ledger.id`
3. ✅ **DB-03**: Granular RLS policies for `charges` (SELECT, INSERT, UPDATE, DELETE)
4. ✅ **DB-04**: Service role documentation (bypasses RLS)

**All changes are**:
- Idempotent (can be run multiple times)
- Additive-only (no data loss)
- Zero-downtime (no table locks)
- Backward compatible

**Files**:
- Migration: `20251021000000_v1_8_0_schema_prep.sql`
- Verification: `VERIFICATION_v1_8_0.md`
- Documentation: `SCHEMA_DOCUMENTATION_v1_8_0.md`

**Ready for production deployment!**
