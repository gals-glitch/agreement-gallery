# Charges Table - Quick Reference Guide

**For Developers:** Fast reference for working with the charges table

---

## Table Structure

```typescript
interface Charge {
  id: string;                      // UUID primary key
  investor_id: number;             // FK to investors
  deal_id: number | null;          // FK to deals (XOR with fund_id)
  fund_id: number | null;          // FK to funds (XOR with deal_id)
  contribution_id: number;         // FK to contributions
  status: 'DRAFT' | 'PENDING' | 'APPROVED' | 'PAID' | 'REJECTED';
  base_amount: number;             // Base fee (before discounts/VAT)
  discount_amount: number;         // Discount applied
  vat_amount: number;              // VAT/tax amount
  total_amount: number;            // Final amount (base - discount + vat)
  currency: string;                // Default 'USD'
  snapshot_json: {                 // Immutable snapshot
    agreement_snapshot: AgreementSnapshot;
    vat_snapshot: VatSnapshot;
    [key: string]: any;
  };
  computed_at: Date | null;
  submitted_at: Date | null;
  approved_by: string | null;      // UUID from auth.users
  approved_at: Date | null;
  rejected_by: string | null;      // UUID from auth.users
  rejected_at: Date | null;
  reject_reason: string | null;
  paid_at: Date | null;
  created_at: Date;
  updated_at: Date;
}
```

---

## Status Flow

```
DRAFT ──────> PENDING ──────> APPROVED ──────> PAID
                  │
                  └─────────> REJECTED
```

**Valid Transitions:**
- DRAFT → PENDING (submit)
- PENDING → APPROVED (approve)
- PENDING → REJECTED (reject)
- APPROVED → PAID (mark paid)

**Invalid Transitions:**
- DRAFT → APPROVED (must go through PENDING)
- REJECTED → anything (terminal state)
- PAID → anything (terminal state)

---

## Common Queries

### 1. Create a Charge

```sql
INSERT INTO charges (
  investor_id,
  deal_id,           -- or fund_id (exactly one must be set)
  contribution_id,
  status,
  base_amount,
  discount_amount,
  vat_amount,
  total_amount,
  currency,
  snapshot_json,
  computed_at
) VALUES (
  $1,  -- investor_id
  $2,  -- deal_id
  $3,  -- contribution_id
  'DRAFT',
  $4,  -- base_amount
  $5,  -- discount_amount
  $6,  -- vat_amount
  $7,  -- total_amount
  'USD',
  $8,  -- snapshot_json
  NOW()
) RETURNING *;
```

### 2. List Charges by Status

```sql
SELECT
  c.id,
  c.investor_id,
  i.name AS investor_name,
  c.status,
  c.total_amount,
  c.currency,
  c.created_at
FROM charges c
JOIN investors i ON i.id = c.investor_id
WHERE c.status = 'PENDING'
ORDER BY c.created_at DESC;
```

### 3. Get Charge with Applied Credits

```sql
SELECT
  c.*,
  COALESCE(SUM(ca.amount_applied) FILTER (WHERE ca.reversed_at IS NULL), 0) AS credits_applied,
  c.total_amount - COALESCE(SUM(ca.amount_applied) FILTER (WHERE ca.reversed_at IS NULL), 0) AS amount_due
FROM charges c
LEFT JOIN credit_applications ca ON ca.charge_id = c.id
WHERE c.id = $1
GROUP BY c.id;
```

### 4. Submit Charge for Approval

```sql
UPDATE charges
SET
  status = 'PENDING',
  submitted_at = NOW()
WHERE id = $1 AND status = 'DRAFT'
RETURNING *;
```

### 5. Approve Charge

```sql
UPDATE charges
SET
  status = 'APPROVED',
  approved_by = $2,
  approved_at = NOW()
WHERE id = $1 AND status = 'PENDING'
RETURNING *;
```

### 6. Reject Charge

```sql
UPDATE charges
SET
  status = 'REJECTED',
  rejected_by = $2,
  rejected_at = NOW(),
  reject_reason = $3
WHERE id = $1 AND status = 'PENDING'
RETURNING *;
```

### 7. Mark as Paid

```sql
UPDATE charges
SET
  status = 'PAID',
  paid_at = NOW()
WHERE id = $1 AND status = 'APPROVED'
RETURNING *;
```

---

## TypeScript Helpers

### Supabase Client Types

```typescript
import { Database } from '@/types/supabase';

type Charge = Database['public']['Tables']['charges']['Row'];
type ChargeInsert = Database['public']['Tables']['charges']['Insert'];
type ChargeUpdate = Database['public']['Tables']['charges']['Update'];
type ChargeStatus = Database['public']['Enums']['charge_status'];
```

### Create Charge Function

```typescript
async function createCharge(
  supabase: SupabaseClient,
  data: {
    investor_id: number;
    deal_id?: number;
    fund_id?: number;
    contribution_id: number;
    base_amount: number;
    discount_amount: number;
    vat_amount: number;
    total_amount: number;
    snapshot_json: Record<string, any>;
  }
): Promise<Charge> {
  // Validate XOR constraint
  if ((!data.deal_id && !data.fund_id) || (data.deal_id && data.fund_id)) {
    throw new Error('Exactly one of deal_id or fund_id must be provided');
  }

  const { data: charge, error } = await supabase
    .from('charges')
    .insert({
      investor_id: data.investor_id,
      deal_id: data.deal_id || null,
      fund_id: data.fund_id || null,
      contribution_id: data.contribution_id,
      status: 'DRAFT',
      base_amount: data.base_amount,
      discount_amount: data.discount_amount,
      vat_amount: data.vat_amount,
      total_amount: data.total_amount,
      currency: 'USD',
      snapshot_json: data.snapshot_json,
      computed_at: new Date().toISOString(),
    })
    .select()
    .single();

  if (error) throw error;
  return charge;
}
```

### List Charges Function

```typescript
async function listCharges(
  supabase: SupabaseClient,
  filters?: {
    status?: ChargeStatus;
    investor_id?: number;
    deal_id?: number;
    fund_id?: number;
  }
): Promise<Charge[]> {
  let query = supabase
    .from('charges')
    .select('*, investor:investors(id, name)')
    .order('created_at', { ascending: false });

  if (filters?.status) {
    query = query.eq('status', filters.status);
  }
  if (filters?.investor_id) {
    query = query.eq('investor_id', filters.investor_id);
  }
  if (filters?.deal_id) {
    query = query.eq('deal_id', filters.deal_id);
  }
  if (filters?.fund_id) {
    query = query.eq('fund_id', filters.fund_id);
  }

  const { data, error } = await query;
  if (error) throw error;
  return data;
}
```

### Approve Charge Function

```typescript
async function approveCharge(
  supabase: SupabaseClient,
  chargeId: string,
  userId: string
): Promise<Charge> {
  const { data: charge, error } = await supabase
    .from('charges')
    .update({
      status: 'APPROVED',
      approved_by: userId,
      approved_at: new Date().toISOString(),
    })
    .eq('id', chargeId)
    .eq('status', 'PENDING') // Only approve if currently PENDING
    .select()
    .single();

  if (error) throw error;
  if (!charge) {
    throw new Error('Charge not found or not in PENDING state');
  }
  return charge;
}
```

---

## RLS Policies

**Who can do what:**

| Role | SELECT | INSERT | UPDATE | DELETE |
|------|--------|--------|--------|--------|
| admin | ✓ | ✓ | ✓ | ✓ |
| finance | ✓ | - | - | - |
| ops | ✓ | - | - | - |
| manager | ✓ | - | - | - |
| viewer | - | - | - | - |

**Note:** Use service role for system operations (creditsEngine.ts)

---

## Business Rules

### 1. XOR Constraint
**Rule:** Exactly ONE of deal_id or fund_id must be set (never both, never neither)

```typescript
// ✓ Valid: Deal-level charge
{ deal_id: 123, fund_id: null }

// ✓ Valid: Fund-level charge
{ deal_id: null, fund_id: 456 }

// ✗ Invalid: Both NULL
{ deal_id: null, fund_id: null }

// ✗ Invalid: Both set
{ deal_id: 123, fund_id: 456 }
```

### 2. Immutable Snapshot
**Rule:** snapshot_json is set once at creation and NEVER modified

```typescript
// ✓ Correct: Set at creation
const snapshot = {
  agreement_snapshot: { /* agreement details */ },
  vat_snapshot: { /* VAT rate at computation time */ },
};

// ✗ Wrong: Don't update snapshot later
// Even if agreement or VAT rate changes, keep original snapshot
```

### 3. Amount Calculations
**Formula:**
```
net_amount = base_amount - discount_amount
vat_amount = net_amount * vat_rate
total_amount = net_amount + vat_amount
```

**Example:**
```typescript
const base_amount = 10000.00;      // 10% referral on $100k contribution
const discount_amount = 500.00;    // 5% discount
const net_amount = 9500.00;        // base - discount
const vat_amount = 1900.00;        // 20% VAT on net
const total_amount = 11400.00;     // net + vat
```

### 4. Idempotency Check
**Rule:** One charge per contribution

```typescript
// Check if contribution already has a charge
const { data: existingCharge } = await supabase
  .from('charges')
  .select('id')
  .eq('contribution_id', contributionId)
  .single();

if (existingCharge) {
  throw new Error('Charge already exists for this contribution');
}
```

---

## Error Handling

### Common Errors

#### XOR Constraint Violation
```
ERROR: new row for relation "charges" violates check constraint "charges_one_scope_ck"
```
**Solution:** Ensure exactly one of deal_id or fund_id is set

#### Invalid Status
```
ERROR: invalid input value for enum charge_status: "INVALID"
```
**Solution:** Use one of: DRAFT, PENDING, APPROVED, PAID, REJECTED

#### FK Violation
```
ERROR: insert or update on table "charges" violates foreign key constraint
```
**Solution:** Verify investor_id, deal_id, fund_id, contribution_id exist

#### RLS Denial
```
ERROR: new row violates row-level security policy for table "charges"
```
**Solution:** User needs admin role, or use service role

---

## Performance Tips

### 1. Use Indexes
All common queries are indexed:
- Filter by status: `idx_charges_status`
- Filter by investor+status: `idx_charges_investor_status`
- Filter by deal: `idx_charges_deal`
- Filter by fund: `idx_charges_fund`
- Find by contribution: `idx_charges_contribution`

### 2. Limit Results
```typescript
// Good: Paginate results
const { data } = await supabase
  .from('charges')
  .select('*')
  .range(0, 49)  // First 50 results
  .order('created_at', { ascending: false });

// Bad: Fetch all rows
const { data } = await supabase.from('charges').select('*');
```

### 3. Select Only Needed Columns
```typescript
// Good: Only select what you need
const { data } = await supabase
  .from('charges')
  .select('id, investor_id, status, total_amount')
  .eq('status', 'PENDING');

// Bad: Select everything
const { data } = await supabase
  .from('charges')
  .select('*')
  .eq('status', 'PENDING');
```

### 4. Use Service Role for Bulk Operations
```typescript
// Good: Use service role for system operations
const serviceSupabase = createClient(url, serviceRoleKey);
const { data } = await serviceSupabase
  .from('charges')
  .insert(charges);  // Bypass RLS

// Bad: Use user context for bulk inserts (slow due to RLS)
const { data } = await supabase.from('charges').insert(charges);
```

---

## Testing

### Unit Test Example

```typescript
import { describe, it, expect } from 'vitest';

describe('Charge Creation', () => {
  it('should create a deal-level charge', async () => {
    const charge = await createCharge(supabase, {
      investor_id: 1,
      deal_id: 10,
      contribution_id: 100,
      base_amount: 10000,
      discount_amount: 500,
      vat_amount: 1900,
      total_amount: 11400,
      snapshot_json: { test: true },
    });

    expect(charge.status).toBe('DRAFT');
    expect(charge.deal_id).toBe(10);
    expect(charge.fund_id).toBeNull();
    expect(charge.total_amount).toBe(11400);
  });

  it('should reject charge without deal_id or fund_id', async () => {
    await expect(
      createCharge(supabase, {
        investor_id: 1,
        // Neither deal_id nor fund_id provided
        contribution_id: 100,
        base_amount: 10000,
        discount_amount: 0,
        vat_amount: 0,
        total_amount: 10000,
        snapshot_json: {},
      })
    ).rejects.toThrow('Exactly one of deal_id or fund_id must be provided');
  });
});
```

---

## Migration Commands

### Apply Migration
```bash
# Supabase CLI
supabase db push

# Or psql
psql -f supabase/migrations/20251019130000_charges.sql
```

### Run Validation
```bash
psql -f supabase/migrations/20251019130000_charges_validation.sql
```

### Check Migration Status
```bash
supabase db pull
```

---

## Useful SQL Snippets

### Count charges by status
```sql
SELECT status, COUNT(*) AS count
FROM charges
GROUP BY status
ORDER BY status;
```

### Find charges with no credits applied
```sql
SELECT c.id, c.investor_id, c.total_amount
FROM charges c
LEFT JOIN credit_applications ca ON ca.charge_id = c.id AND ca.reversed_at IS NULL
WHERE c.status = 'APPROVED'
GROUP BY c.id
HAVING COALESCE(SUM(ca.amount_applied), 0) = 0;
```

### Audit trail for all charges
```sql
SELECT
  c.id,
  c.status,
  c.created_at,
  c.submitted_at,
  c.approved_at,
  c.paid_at,
  c.approved_at - c.submitted_at AS approval_time,
  c.paid_at - c.approved_at AS payment_time
FROM charges c
WHERE c.status IN ('APPROVED', 'PAID')
ORDER BY c.created_at DESC;
```

### Charges pending for >7 days
```sql
SELECT
  c.id,
  c.investor_id,
  i.name,
  c.submitted_at,
  NOW() - c.submitted_at AS pending_duration
FROM charges c
JOIN investors i ON i.id = c.investor_id
WHERE c.status = 'PENDING'
  AND c.submitted_at < NOW() - INTERVAL '7 days'
ORDER BY c.submitted_at;
```

---

## Troubleshooting

### Issue: Can't create charge
**Check:**
1. Investor exists: `SELECT * FROM investors WHERE id = ?`
2. Deal/Fund exists: `SELECT * FROM deals WHERE id = ?`
3. Contribution exists: `SELECT * FROM contributions WHERE id = ?`
4. User has admin role: `SELECT * FROM user_roles WHERE user_id = auth.uid()`

### Issue: Can't see charges (RLS)
**Solution:**
```sql
-- Grant finance role to user
INSERT INTO user_roles (user_id, role_key)
VALUES ('user-uuid', 'finance');
```

### Issue: Charge stuck in PENDING
**Solution:**
```sql
-- Approve manually
UPDATE charges
SET status = 'APPROVED', approved_by = auth.uid(), approved_at = NOW()
WHERE id = 'charge-uuid' AND status = 'PENDING';
```

---

**Last Updated:** 2025-10-19
**Migration:** 20251019130000_charges.sql
**Full Docs:** See `20251019130000_charges_REPORT.md`
