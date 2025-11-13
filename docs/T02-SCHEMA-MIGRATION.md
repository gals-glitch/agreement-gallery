# T02: Charge Workflow Schema Changes & Migration Guide

**Version:** v1.9.0
**Date:** 2025-10-21
**Ticket:** T02 - Complete Charge Workflow (Approve, Reject, Mark-Paid)

---

## Overview

T02 completes the charge workflow by implementing three state transition endpoints:
1. **Approve:** `pending` → `approved` (freeze credit applications)
2. **Reject:** `pending` → `rejected` (reverse credits, restore balances)
3. **Mark-Paid:** `approved` → `paid` (record payment metadata)

All schema changes are **additive only** - no existing columns modified or removed.

---

## Database Schema Changes

### 1. Charges Table (`charges`)

**New Columns:**

```sql
-- Approval tracking
ALTER TABLE charges ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ;
ALTER TABLE charges ADD COLUMN IF NOT EXISTS approved_by UUID REFERENCES auth.users(id);

-- Rejection tracking
ALTER TABLE charges ADD COLUMN IF NOT EXISTS rejected_at TIMESTAMPTZ;
ALTER TABLE charges ADD COLUMN IF NOT EXISTS rejected_by UUID REFERENCES auth.users(id);
ALTER TABLE charges ADD COLUMN IF NOT EXISTS reject_reason TEXT;

-- Payment tracking
ALTER TABLE charges ADD COLUMN IF NOT EXISTS paid_at TIMESTAMPTZ;
ALTER TABLE charges ADD COLUMN IF NOT EXISTS payment_ref TEXT;
```

**Indexes (recommended for performance):**

```sql
-- Fast status filtering
CREATE INDEX IF NOT EXISTS idx_charges_status ON charges(status);

-- Admin audit queries
CREATE INDEX IF NOT EXISTS idx_charges_approved_by ON charges(approved_by) WHERE approved_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_charges_rejected_by ON charges(rejected_by) WHERE rejected_by IS NOT NULL;

-- Payment reference lookup
CREATE INDEX IF NOT EXISTS idx_charges_payment_ref ON charges(payment_ref) WHERE payment_ref IS NOT NULL;
```

**Column Descriptions:**

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `approved_at` | `TIMESTAMPTZ` | Yes | Timestamp when charge was approved |
| `approved_by` | `UUID` | Yes | User ID who approved (foreign key to `auth.users`) |
| `rejected_at` | `TIMESTAMPTZ` | Yes | Timestamp when charge was rejected |
| `rejected_by` | `UUID` | Yes | User ID who rejected (foreign key to `auth.users`) |
| `reject_reason` | `TEXT` | Yes | Reason for rejection (min 3 chars required at API layer) |
| `paid_at` | `TIMESTAMPTZ` | Yes | Timestamp when charge was marked paid (can be set by user) |
| `payment_ref` | `TEXT` | Yes | Payment reference (e.g., wire transfer ID) |

### 2. Credit Applications Table (`credit_applications`)

**No schema changes required.** Existing columns are sufficient:

- `reversed_at` - Already exists (set when credits reversed during reject)
- `reversed_by` - Already exists (user who triggered reversal)

### 3. Audit Log Table (`audit_log`)

**No schema changes required.** New event types added:

- `charge.approved` - Charge approved
- `charge.rejected` - Charge rejected (includes reversal metadata)
- `charge.paid` - Charge marked paid

**Example audit payload:**

```json
{
  "event_type": "charge.rejected",
  "actor_id": "admin-user-id",
  "entity_type": "charge",
  "entity_id": "charge-uuid",
  "payload": {
    "charge_id": "charge-uuid",
    "reason": "Wrong amount calculated",
    "credits_restored": 600.00,
    "reversals_count": 2
  }
}
```

---

## Migration SQL Script

**File:** `supabase/migrations/20251021_t02_charge_workflow.sql`

```sql
-- ============================================
-- T02: Charge Workflow Schema Migration
-- Version: v1.9.0
-- Date: 2025-10-21
-- ============================================

BEGIN;

-- Add approval tracking columns
ALTER TABLE charges ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ;
ALTER TABLE charges ADD COLUMN IF NOT EXISTS approved_by UUID REFERENCES auth.users(id);

-- Add rejection tracking columns
ALTER TABLE charges ADD COLUMN IF NOT EXISTS rejected_at TIMESTAMPTZ;
ALTER TABLE charges ADD COLUMN IF NOT EXISTS rejected_by UUID REFERENCES auth.users(id);
ALTER TABLE charges ADD COLUMN IF NOT EXISTS reject_reason TEXT;

-- Add payment tracking columns
ALTER TABLE charges ADD COLUMN IF NOT EXISTS paid_at TIMESTAMPTZ;
ALTER TABLE charges ADD COLUMN IF NOT EXISTS payment_ref TEXT;

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_charges_status ON charges(status);
CREATE INDEX IF NOT EXISTS idx_charges_approved_by ON charges(approved_by) WHERE approved_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_charges_rejected_by ON charges(rejected_by) WHERE rejected_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_charges_payment_ref ON charges(payment_ref) WHERE payment_ref IS NOT NULL;

-- Add comments for documentation
COMMENT ON COLUMN charges.approved_at IS 'Timestamp when charge transitioned to APPROVED status';
COMMENT ON COLUMN charges.approved_by IS 'User ID who approved the charge';
COMMENT ON COLUMN charges.rejected_at IS 'Timestamp when charge was rejected';
COMMENT ON COLUMN charges.rejected_by IS 'User ID who rejected the charge';
COMMENT ON COLUMN charges.reject_reason IS 'Reason for rejection (required, min 3 chars)';
COMMENT ON COLUMN charges.paid_at IS 'Timestamp when charge was marked paid (can be set manually)';
COMMENT ON COLUMN charges.payment_ref IS 'Payment reference (e.g., WIRE-2025-001)';

COMMIT;
```

---

## Rollback SQL Script

**File:** `supabase/migrations/20251021_t02_charge_workflow_rollback.sql`

```sql
-- ============================================
-- T02: Charge Workflow Schema Rollback
-- Version: v1.9.0
-- Date: 2025-10-21
-- ============================================
-- WARNING: This will drop columns and lose data!

BEGIN;

-- Drop indexes
DROP INDEX IF EXISTS idx_charges_status;
DROP INDEX IF EXISTS idx_charges_approved_by;
DROP INDEX IF EXISTS idx_charges_rejected_by;
DROP INDEX IF EXISTS idx_charges_payment_ref;

-- Drop columns (WARNING: Data loss!)
ALTER TABLE charges DROP COLUMN IF EXISTS approved_at;
ALTER TABLE charges DROP COLUMN IF EXISTS approved_by;
ALTER TABLE charges DROP COLUMN IF EXISTS rejected_at;
ALTER TABLE charges DROP COLUMN IF EXISTS rejected_by;
ALTER TABLE charges DROP COLUMN IF EXISTS reject_reason;
ALTER TABLE charges DROP COLUMN IF EXISTS paid_at;
ALTER TABLE charges DROP COLUMN IF EXISTS payment_ref;

COMMIT;
```

---

## Deployment Checklist

### Pre-Deployment

- [ ] Review migration SQL for syntax errors
- [ ] Test migration on local/dev database
- [ ] Verify rollback SQL works on local/dev
- [ ] Backup production database
- [ ] Schedule maintenance window (if required)
- [ ] Notify stakeholders of deployment

### Deployment Steps

1. **Apply Migration:**
   ```bash
   supabase db push --linked
   # OR
   psql $DATABASE_URL < supabase/migrations/20251021_t02_charge_workflow.sql
   ```

2. **Verify Schema:**
   ```sql
   \d+ charges
   -- Check new columns exist and are nullable
   ```

3. **Deploy Code:**
   ```bash
   supabase functions deploy api-v1
   ```

4. **Verify Endpoints:**
   ```bash
   # Run cURL test script
   ./tests/t02-charges-workflow-curl.sh
   ```

5. **Monitor Logs:**
   ```bash
   supabase functions logs api-v1 --tail
   ```

### Post-Deployment

- [ ] Run integration tests against production
- [ ] Verify audit logs are being created
- [ ] Check credit reversal works correctly
- [ ] Test idempotency on real charges
- [ ] Update API documentation
- [ ] Notify users of new features

### Rollback Plan

If issues are detected:

1. **Immediately revert code:**
   ```bash
   # Redeploy previous version
   git checkout v1.8.0
   supabase functions deploy api-v1
   ```

2. **Keep schema changes** (columns are nullable, won't break existing code)

3. **If schema rollback required:**
   ```bash
   psql $DATABASE_URL < supabase/migrations/20251021_t02_charge_workflow_rollback.sql
   ```

---

## Data Validation Queries

### Check Approved Charges

```sql
SELECT
  id,
  status,
  approved_at,
  approved_by,
  credits_applied_amount
FROM charges
WHERE status = 'APPROVED'
ORDER BY approved_at DESC
LIMIT 10;
```

### Check Rejected Charges with Credit Reversal

```sql
SELECT
  c.id,
  c.status,
  c.rejected_at,
  c.reject_reason,
  c.credits_applied_amount, -- Should be 0
  c.net_amount,             -- Should equal total_amount
  COUNT(ca.id) FILTER (WHERE ca.reversed_at IS NULL) as active_apps
FROM charges c
LEFT JOIN credit_applications ca ON ca.charge_id = c.numeric_id
WHERE c.status = 'REJECTED'
GROUP BY c.id
ORDER BY c.rejected_at DESC
LIMIT 10;
```

### Check Paid Charges

```sql
SELECT
  id,
  status,
  approved_at,
  paid_at,
  payment_ref,
  total_amount,
  credits_applied_amount,
  net_amount
FROM charges
WHERE status = 'PAID'
ORDER BY paid_at DESC
LIMIT 10;
```

### Audit Log Verification

```sql
SELECT
  event_type,
  actor_id,
  entity_id,
  payload,
  created_at
FROM audit_log
WHERE event_type IN ('charge.approved', 'charge.rejected', 'charge.paid')
ORDER BY created_at DESC
LIMIT 20;
```

---

## Testing Strategy

### Unit Tests

**File:** `supabase/functions/api-v1/charges.workflow.test.ts`

- 18+ tests covering all endpoints
- Mock-based, no database required
- Fast execution (< 1 second)

**Run:**
```bash
deno test supabase/functions/api-v1/charges.workflow.test.ts
```

### Integration Tests

**File:** `supabase/functions/api-v1/charges.workflow.integration.test.ts`

- Full database transactions
- Credit reversal verification
- Audit log validation

**Run:**
```bash
deno test --allow-net --allow-env supabase/functions/api-v1/charges.workflow.integration.test.ts
```

### Manual Tests

**File:** `tests/t02-charges-workflow-curl.sh`

- 12 cURL test cases
- Live API testing
- Visual pass/fail output

**Run:**
```bash
chmod +x tests/t02-charges-workflow-curl.sh
./tests/t02-charges-workflow-curl.sh
```

---

## Breaking Changes

**None.** T02 is fully backward compatible:

- All new columns are nullable
- Existing charges remain queryable
- Previous endpoints unchanged
- API contracts preserved

---

## Performance Considerations

### Query Performance

**Before indexes:**
- Full table scan for status filtering
- Slow admin audit queries

**After indexes:**
- O(log n) status lookups
- Fast user-specific audit trails
- Efficient payment reference lookups

**Expected impact:**
- Approve: +0.5 ms (audit log insert)
- Reject: +5-10 ms (credit reversal loop)
- Mark-Paid: +0.5 ms (audit log insert)

### Database Size

**Per charge (estimated):**
- Approval: +24 bytes (2 timestamps + 1 UUID)
- Rejection: +32 bytes (2 timestamps + 1 UUID + text)
- Payment: +24 bytes (1 timestamp + 1 text)

**Total overhead:** ~80 bytes per charge

---

## Security Notes

### RBAC Enforcement

- **Approve/Reject:** Admin only (or service key)
- **Mark-Paid:** Admin only (**NO service key** - requires human verification)

### Audit Trail

All actions create audit_log entries with:
- Actor ID (user or service)
- Timestamp
- Action metadata
- Previous state (implied)

### Idempotency

All endpoints are idempotent:
- Safe to retry on network failure
- No duplicate credit reversals
- No duplicate audit entries

---

## Troubleshooting

### Issue: Credits not reversed on reject

**Check:**
```sql
SELECT * FROM credit_applications
WHERE charge_id = <numeric_id> AND reversed_at IS NULL;
```

**Fix:**
Manually reverse if needed:
```sql
BEGIN;

-- Update credits_ledger
UPDATE credits_ledger cl
SET available_amount = cl.available_amount + ca.amount_applied
FROM credit_applications ca
WHERE ca.credit_id = cl.id
  AND ca.charge_id = <numeric_id>
  AND ca.reversed_at IS NULL;

-- Mark applications as reversed
UPDATE credit_applications
SET reversed_at = now(), reversed_by = '<admin-user-id>'
WHERE charge_id = <numeric_id> AND reversed_at IS NULL;

COMMIT;
```

### Issue: Charge stuck in PENDING

**Check status:**
```sql
SELECT id, status, submitted_at,
       now() - submitted_at as age
FROM charges
WHERE status = 'PENDING'
ORDER BY submitted_at ASC;
```

**Manual approve (if safe):**
```bash
curl -X POST "$API/charges/<id>/approve" \
  -H "Authorization: Bearer $ADMIN_JWT"
```

### Issue: Audit log missing

**Verify audit_log table:**
```sql
SELECT COUNT(*) FROM audit_log
WHERE event_type LIKE 'charge.%'
  AND created_at > now() - interval '1 hour';
```

**Check function logs:**
```bash
supabase functions logs api-v1 --tail
```

---

## References

- **T01 Documentation:** Submit endpoint with FIFO credit application
- **Credits Engine:** `supabase/functions/api-v1/creditsEngine.ts`
- **RBAC Documentation:** `docs/RBAC.md`
- **OpenAPI Spec:** `docs/openapi-charges.yaml`

---

## Support

For issues or questions:
1. Check function logs: `supabase functions logs api-v1`
2. Review audit_log table for transaction history
3. Run integration tests to verify system state
4. Contact platform team with charge ID and error details
