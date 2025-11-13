# Credits Engine API Documentation

**Version:** 1.6.0
**Last Updated:** 2025-10-19
**Base URL:** `/functions/v1/api-v1`

---

## Overview

The Credits Engine provides FIFO (First-In-First-Out) automatic credit application for investor charges. Credits are created from repurchases, equalisations, or manual adjustments, and are automatically applied to future charges in chronological order.

**Key Features:**
- **FIFO Application:** Credits applied oldest-first to charges
- **Partial Credits:** Support for partial credit application (credit splits across multiple charges)
- **Scope Matching:** Credits only apply to charges in same fund or deal
- **Reversal Support:** Automatic credit reversal when charges are rejected
- **Auto-Status Updates:** Credits marked as FULLY_APPLIED when exhausted
- **Transaction Safety:** All operations wrapped in database transactions

---

## Credit Lifecycle

```
1. CREATE CREDIT
   ↓
   Status: AVAILABLE
   original_amount: $10,000
   applied_amount: $0
   available_amount: $10,000 (computed)

2. CHARGE SUBMITTED → AUTO-APPLY
   ↓
   Charge: $12,000
   Credit A (oldest): $10,000 → FULLY_APPLIED
   Credit B (next): $2,000 applied, $3,000 remaining → AVAILABLE

3. CHARGE APPROVED
   ↓
   Credits remain applied

4. CHARGE REJECTED → REVERSE
   ↓
   Credit A: AVAILABLE again ($10,000)
   Credit B: $5,000 available (restored from $3,000)
```

---

## Authentication

All Credits endpoints require **authenticated user** with appropriate role:

**Read Access:** finance, ops, manager, admin
**Write Access:** finance, admin

```javascript
const headers = {
  'Authorization': `Bearer ${userAccessToken}`,
  'Content-Type': 'application/json'
};
```

---

## Endpoints

### Auto-Apply Credits to Charge

**Endpoint:** `POST /api-v1/credits/auto-apply/:chargeId`

**Description:** Automatically apply available credits to a charge using FIFO logic. Called internally when a charge is submitted.

**Path Parameters:**
- `chargeId` (required) - ID of the charge to apply credits to

**Internal Call Only:** This endpoint is typically called by the charge submission workflow, not directly by clients.

**Request Example:**

```bash
curl -X POST "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1/credits/auto-apply/123" \
  -H "Authorization: Bearer ${USER_ACCESS_TOKEN}"
```

**Response (200 OK):**

```json
{
  "chargeId": 123,
  "totalApplied": 12000,
  "applications": [
    {
      "id": 1,
      "credit_id": 45,
      "charge_id": 123,
      "amount_applied": 10000,
      "applied_at": "2025-10-19T10:30:00Z",
      "applied_by": "user-uuid",
      "credit": {
        "id": 45,
        "reason": "REPURCHASE",
        "original_amount": 10000,
        "created_at": "2025-09-15T08:00:00Z"
      }
    },
    {
      "id": 2,
      "credit_id": 67,
      "charge_id": 123,
      "amount_applied": 2000,
      "applied_at": "2025-10-19T10:30:00Z",
      "applied_by": "user-uuid",
      "credit": {
        "id": 67,
        "reason": "EQUALISATION",
        "original_amount": 5000,
        "created_at": "2025-10-01T12:00:00Z"
      }
    }
  ]
}
```

**FIFO Logic:**
1. Query all available credits for investor (WHERE available_amount > 0)
2. Filter by scope: fund_id XOR deal_id must match charge
3. Order by created_at ASC (oldest first)
4. Apply credits sequentially until charge is satisfied or credits exhausted

**Error Responses:**

| Status | Condition | Response |
|--------|-----------|----------|
| 404 | Charge not found | `{ "error": "Charge not found" }` |
| 400 | Charge already has credits applied | `{ "error": "Credits already applied to this charge" }` |
| 500 | Database transaction error | `{ "error": "Failed to apply credits" }` |

---

### Reverse Credits for Charge

**Endpoint:** `POST /api-v1/credits/reverse/:chargeId`

**Description:** Reverse all credit applications for a charge. Called internally when a charge is rejected or deleted.

**Path Parameters:**
- `chargeId` (required) - ID of the charge to reverse credits for

**Internal Call Only:** This endpoint is typically called by the charge rejection workflow, not directly by clients.

**Request Example:**

```bash
curl -X POST "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1/credits/reverse/123" \
  -H "Authorization: Bearer ${USER_ACCESS_TOKEN}"
```

**Response (200 OK):**

```json
{
  "chargeId": 123,
  "reversedCount": 2,
  "totalReversed": 12000,
  "applications": [
    {
      "id": 1,
      "credit_id": 45,
      "amount_applied": 10000,
      "reversed_at": "2025-10-19T11:00:00Z",
      "reversed_by": "user-uuid",
      "reversal_reason": "Charge rejected"
    },
    {
      "id": 2,
      "credit_id": 67,
      "amount_applied": 2000,
      "reversed_at": "2025-10-19T11:00:00Z",
      "reversed_by": "user-uuid",
      "reversal_reason": "Charge rejected"
    }
  ]
}
```

**Reversal Logic:**
1. Find all active credit_applications for charge (WHERE reversed_at IS NULL)
2. Mark each application as reversed (set reversed_at, reversed_by, reversal_reason)
3. Decrement applied_amount on each credit by amount_applied
4. Credits return to AVAILABLE status (if available_amount > 0)

**Error Responses:**

| Status | Condition | Response |
|--------|-----------|----------|
| 404 | Charge not found | `{ "error": "Charge not found" }` |
| 404 | No active credit applications found | `{ "error": "No credits to reverse for this charge" }` |
| 500 | Database transaction error | `{ "error": "Failed to reverse credits" }` |

---

### List Credits

**Endpoint:** `GET /api-v1/credits`

**Description:** Retrieve credits with optional filters. Useful for viewing investor credit balances.

**Query Parameters:**
- `investor_id` (optional) - Filter by investor
- `fund_id` (optional) - Filter by fund
- `deal_id` (optional) - Filter by deal
- `status` (optional) - Filter by status (AVAILABLE, FULLY_APPLIED)
- `reason` (optional) - Filter by reason (REPURCHASE, EQUALISATION, MANUAL, REFUND)

**Request Example:**

```bash
# List all available credits for investor
curl -X GET "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1/credits?investor_id=123&status=AVAILABLE" \
  -H "Authorization: Bearer ${USER_ACCESS_TOKEN}"

# List all credits for a fund
curl -X GET "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1/credits?fund_id=5" \
  -H "Authorization: Bearer ${USER_ACCESS_TOKEN}"
```

**Response (200 OK):**

```json
[
  {
    "id": 45,
    "investor_id": 123,
    "fund_id": 5,
    "deal_id": null,
    "reason": "REPURCHASE",
    "original_amount": 10000,
    "applied_amount": 10000,
    "available_amount": 0,
    "status": "FULLY_APPLIED",
    "notes": "Auto-generated from repurchase transaction TX-2025-001",
    "created_at": "2025-09-15T08:00:00Z",
    "created_by": "user-uuid"
  },
  {
    "id": 67,
    "investor_id": 123,
    "fund_id": 5,
    "deal_id": null,
    "reason": "EQUALISATION",
    "original_amount": 5000,
    "applied_amount": 2000,
    "available_amount": 3000,
    "status": "AVAILABLE",
    "notes": "Q3 equalisation payment",
    "created_at": "2025-10-01T12:00:00Z",
    "created_by": "user-uuid"
  }
]
```

**Error Responses:**

| Status | Condition | Response |
|--------|-----------|----------|
| 401 | Not authenticated | `{ "error": "Unauthorized" }` |
| 403 | Insufficient permissions | `{ "error": "Forbidden" }` |
| 500 | Database error | `{ "error": "Failed to fetch credits" }` |

---

### Create Manual Credit

**Endpoint:** `POST /api-v1/credits`

**Description:** Manually create a credit for an investor. Requires finance or admin role.

**Request Body:**

```json
{
  "investor_id": 123,
  "fund_id": 5,
  "deal_id": null,
  "reason": "MANUAL",
  "original_amount": 50000,
  "notes": "Manual credit adjustment for billing error"
}
```

**Field Descriptions:**
- `investor_id` (required) - Investor receiving the credit
- `fund_id` (optional) - Fund scope (XOR with deal_id)
- `deal_id` (optional) - Deal scope (XOR with fund_id)
- `reason` (required) - One of: REPURCHASE, EQUALISATION, MANUAL, REFUND
- `original_amount` (required) - Credit amount (must be positive)
- `notes` (optional) - Description or reference

**XOR Constraint:** Exactly one of fund_id or deal_id must be set, not both, not neither.

**Request Example:**

```bash
curl -X POST "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1/credits" \
  -H "Authorization: Bearer ${USER_ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "investor_id": 123,
    "fund_id": 5,
    "reason": "MANUAL",
    "original_amount": 50000,
    "notes": "Manual credit adjustment for billing error"
  }'
```

**Response (201 Created):**

```json
{
  "id": 89,
  "investor_id": 123,
  "fund_id": 5,
  "deal_id": null,
  "reason": "MANUAL",
  "original_amount": 50000,
  "applied_amount": 0,
  "available_amount": 50000,
  "status": "AVAILABLE",
  "notes": "Manual credit adjustment for billing error",
  "created_at": "2025-10-19T10:45:00Z",
  "created_by": "user-uuid"
}
```

**Error Responses:**

| Status | Condition | Response |
|--------|-----------|----------|
| 400 | Missing required fields | `{ "error": "investor_id, reason, and original_amount are required" }` |
| 400 | XOR violation (both or neither fund_id/deal_id) | `{ "error": "Exactly one of fund_id or deal_id must be set" }` |
| 400 | Negative amount | `{ "error": "original_amount must be positive" }` |
| 403 | Insufficient permissions (not finance/admin) | `{ "error": "Only finance or admin can create credits" }` |
| 404 | Invalid investor_id | `{ "error": "Investor not found" }` |
| 404 | Invalid fund_id or deal_id | `{ "error": "Fund/Deal not found" }` |
| 500 | Database error | `{ "error": "Failed to create credit" }` |

---

## Database Schema

### `credits_ledger` Table

| Column | Type | Description |
|--------|------|-------------|
| `id` | BIGSERIAL PRIMARY KEY | Unique credit ID |
| `investor_id` | INTEGER NOT NULL | Investor receiving credit |
| `fund_id` | INTEGER | Fund scope (XOR with deal_id) |
| `deal_id` | INTEGER | Deal scope (XOR with fund_id) |
| `reason` | TEXT NOT NULL | Credit reason (REPURCHASE, EQUALISATION, MANUAL, REFUND) |
| `original_amount` | DECIMAL(15,2) NOT NULL | Initial credit amount |
| `applied_amount` | DECIMAL(15,2) DEFAULT 0 | Amount already applied to charges |
| `available_amount` | DECIMAL(15,2) GENERATED | Computed: original_amount - applied_amount |
| `status` | TEXT DEFAULT 'AVAILABLE' | AVAILABLE or FULLY_APPLIED (auto-updated) |
| `notes` | TEXT | Optional description |
| `created_at` | TIMESTAMPTZ DEFAULT now() | Creation timestamp |
| `created_by` | UUID | User who created the credit |

**Computed Column:**
```sql
available_amount DECIMAL(15,2)
  GENERATED ALWAYS AS (original_amount - applied_amount) STORED
```

**Auto-Status Trigger:**
```sql
-- When available_amount becomes 0, status → FULLY_APPLIED
CREATE TRIGGER credits_auto_status_update
  BEFORE UPDATE ON credits_ledger
  FOR EACH ROW
  EXECUTE FUNCTION update_credit_status();
```

**Indexes:**
- `idx_credits_ledger_investor_id` - Filter by investor
- `idx_credits_ledger_fund_id` - Filter by fund
- `idx_credits_ledger_deal_id` - Filter by deal
- `idx_credits_ledger_status` - Filter by status
- `idx_credits_ledger_available_fifo` (PARTIAL) - FIFO query optimization (WHERE available_amount > 0)

### `credit_applications` Table

| Column | Type | Description |
|--------|------|-------------|
| `id` | BIGSERIAL PRIMARY KEY | Unique application ID |
| `credit_id` | BIGINT NOT NULL | Credit being applied |
| `charge_id` | BIGINT NOT NULL | Charge receiving credit |
| `amount_applied` | DECIMAL(15,2) NOT NULL | Amount of credit applied |
| `applied_at` | TIMESTAMPTZ DEFAULT now() | Application timestamp |
| `applied_by` | UUID | User who applied the credit |
| `reversed_at` | TIMESTAMPTZ | Reversal timestamp (NULL if active) |
| `reversed_by` | UUID | User who reversed the application |
| `reversal_reason` | TEXT | Reason for reversal |

**Indexes:**
- `idx_credit_applications_credit_id` - Credits → Applications
- `idx_credit_applications_charge_id` - Charges → Applications
- `idx_credit_applications_active` (PARTIAL) - Active applications (WHERE reversed_at IS NULL)

---

## FIFO Algorithm

### Detailed Implementation

```typescript
async function autoApplyCredits(chargeId: number): Promise<CreditApplication[]> {
  // 1. Fetch charge details
  const charge = await supabase
    .from('charges')
    .select('investor_id, fund_id, deal_id, amount')
    .eq('id', chargeId)
    .single();

  // 2. Query available credits (FIFO order)
  const { data: credits } = await supabase
    .from('credits_ledger')
    .select('*')
    .eq('investor_id', charge.investor_id)
    .gt('available_amount', 0)
    // Scope matching: fund_id XOR deal_id
    .or(
      charge.fund_id
        ? `fund_id.eq.${charge.fund_id},deal_id.is.null`
        : `deal_id.eq.${charge.deal_id},fund_id.is.null`
    )
    .order('created_at', { ascending: true }); // FIFO: oldest first

  // 3. Apply credits until charge is satisfied
  let remainingAmount = charge.amount;
  const applications = [];

  for (const credit of credits) {
    if (remainingAmount <= 0) break;

    const amountToApply = Math.min(credit.available_amount, remainingAmount);

    // Insert credit_application
    const { data: app } = await supabase
      .from('credit_applications')
      .insert({
        credit_id: credit.id,
        charge_id: chargeId,
        amount_applied: amountToApply,
        applied_by: userId
      })
      .select()
      .single();

    // Update credit.applied_amount
    await supabase
      .from('credits_ledger')
      .update({
        applied_amount: credit.applied_amount + amountToApply
      })
      .eq('id', credit.id);

    applications.push(app);
    remainingAmount -= amountToApply;
  }

  return applications;
}
```

### FIFO Order Example

**Credits:**
- Credit A: $10,000 (created 2025-09-15) ← Oldest
- Credit B: $5,000 (created 2025-10-01)
- Credit C: $8,000 (created 2025-10-10) ← Newest

**Charge:** $12,000

**Application:**
1. Credit A: $10,000 applied → $0 remaining (FULLY_APPLIED)
2. Credit B: $2,000 applied → $3,000 remaining (AVAILABLE)
3. Credit C: $0 applied → $8,000 remaining (AVAILABLE)

**Result:**
- Charge: $12,000 satisfied
- Credits A + B (partial) applied
- Credit C untouched

---

## Scope Matching Rules

### Fund-Scoped Credit

```sql
-- Credit created for Fund #5
INSERT INTO credits_ledger (investor_id, fund_id, deal_id, ...)
VALUES (123, 5, NULL, ...);
```

**Applies To:**
- ✅ Charges for Fund #5 (fund_id = 5, deal_id IS NULL)
- ❌ Charges for Deal #10 (even if Deal #10 belongs to Fund #5)

**Rationale:** Fund-level credits are for fund-wide adjustments, not deal-specific.

### Deal-Scoped Credit

```sql
-- Credit created for Deal #10
INSERT INTO credits_ledger (investor_id, fund_id, deal_id, ...)
VALUES (123, NULL, 10, ...);
```

**Applies To:**
- ✅ Charges for Deal #10 (deal_id = 10, fund_id IS NULL)
- ❌ Charges for Fund #5 (even if Deal #10 belongs to Fund #5)

**Rationale:** Deal-level credits are for deal-specific adjustments.

### Multi-Scope Scenario

**Investor has:**
- Fund credit: $10,000 (Fund #5)
- Deal credit: $5,000 (Deal #10, which belongs to Fund #5)

**Charge 1:** $15,000 for Fund #5
- **Applied:** Fund credit ($10,000)
- **Not Applied:** Deal credit (scope mismatch)
- **Remaining:** $5,000 charge balance

**Charge 2:** $8,000 for Deal #10
- **Applied:** Deal credit ($5,000)
- **Not Applied:** Fund credit (scope mismatch)
- **Remaining:** $3,000 charge balance

---

## Reversal Scenarios

### Scenario 1: Charge Rejected

```
1. Charge submitted: $12,000
2. Credits auto-applied:
   - Credit A: $10,000
   - Credit B: $2,000
3. Charge rejected by finance
4. Credits reversed:
   - Credit A: $10,000 restored (AVAILABLE)
   - Credit B: $5,000 available again (was $3,000)
```

### Scenario 2: Charge Deleted

```
1. Charge created: $8,000
2. Credits auto-applied:
   - Credit C: $8,000 (FULLY_APPLIED)
3. Charge deleted (data correction)
4. Credits reversed:
   - Credit C: $8,000 restored (AVAILABLE)
```

### Scenario 3: Partial Reversal (Not Supported)

**Current Limitation:** Reversals are all-or-nothing per charge. Cannot reverse individual credit applications.

**Workaround:** If partial reversal needed, manually create offsetting credit.

---

## Frontend Integration

### React Hook Example

```typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { http } from '@/api/http';

export function useCredits(filters?: {
  investor_id?: number;
  fund_id?: number;
  status?: string;
}) {
  return useQuery({
    queryKey: ['credits', filters],
    queryFn: async () => {
      const params = new URLSearchParams();
      if (filters?.investor_id) params.set('investor_id', String(filters.investor_id));
      if (filters?.fund_id) params.set('fund_id', String(filters.fund_id));
      if (filters?.status) params.set('status', filters.status);

      const response = await http.get(`/credits?${params}`);
      return response.data;
    }
  });
}

export function useCreateCredit() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (payload: CreateCreditPayload) => {
      const response = await http.post('/credits', payload);
      return response.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['credits'] });
    }
  });
}

export function useAutoApplyCredits() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (chargeId: number) => {
      const response = await http.post(`/credits/auto-apply/${chargeId}`);
      return response.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['credits'] });
      queryClient.invalidateQueries({ queryKey: ['charges'] });
    }
  });
}
```

### Usage in Component

```typescript
import { useCredits, useCreateCredit } from '@/hooks/useCredits';

export function CreditsPage() {
  const [investorId, setInvestorId] = useState<number>();
  const { data: credits, isLoading } = useCredits({ investor_id: investorId, status: 'AVAILABLE' });
  const createCredit = useCreateCredit();

  const handleCreateCredit = async () => {
    try {
      await createCredit.mutateAsync({
        investor_id: investorId!,
        fund_id: 5,
        reason: 'MANUAL',
        original_amount: 50000,
        notes: 'Manual adjustment'
      });
      toast.success('Credit created successfully');
    } catch (error) {
      toast.error(`Failed to create credit: ${error.message}`);
    }
  };

  return (
    <div>
      <InvestorSelect value={investorId} onChange={setInvestorId} />
      {isLoading ? <Spinner /> : (
        <CreditsList
          credits={credits}
          onCreateCredit={handleCreateCredit}
        />
      )}
    </div>
  );
}
```

---

## Testing Guide

### Prerequisites

1. Charges table must exist (currently pending)
2. Test investors with known IDs
3. Test fund or deal with known ID
4. Finance or admin role assigned to test user

### Test Scenario 1: FIFO Application

```sql
-- Setup: Create 3 credits for investor #123
INSERT INTO credits_ledger (investor_id, fund_id, reason, original_amount, created_at)
VALUES
  (123, 5, 'REPURCHASE', 10000, '2025-09-15 08:00:00'),
  (123, 5, 'EQUALISATION', 5000, '2025-10-01 12:00:00'),
  (123, 5, 'MANUAL', 8000, '2025-10-10 09:00:00');

-- Create charge for $12,000
INSERT INTO charges (investor_id, fund_id, amount, status)
VALUES (123, 5, 12000, 'PENDING');

-- Apply credits via API
POST /api-v1/credits/auto-apply/{charge_id}

-- Verify results
SELECT * FROM credits_ledger WHERE investor_id = 123;
-- Expected:
-- Credit 1: applied_amount = 10000, available_amount = 0, status = 'FULLY_APPLIED'
-- Credit 2: applied_amount = 2000, available_amount = 3000, status = 'AVAILABLE'
-- Credit 3: applied_amount = 0, available_amount = 8000, status = 'AVAILABLE'

SELECT * FROM credit_applications WHERE charge_id = {charge_id};
-- Expected: 2 rows (Credit 1 full, Credit 2 partial)
```

### Test Scenario 2: Reversal

```sql
-- Reject the charge
UPDATE charges SET status = 'REJECTED' WHERE id = {charge_id};

-- Reverse credits via API
POST /api-v1/credits/reverse/{charge_id}

-- Verify reversal
SELECT * FROM credits_ledger WHERE investor_id = 123;
-- Expected:
-- Credit 1: applied_amount = 0, available_amount = 10000, status = 'AVAILABLE'
-- Credit 2: applied_amount = 0, available_amount = 5000, status = 'AVAILABLE'
-- Credit 3: (unchanged)

SELECT * FROM credit_applications WHERE charge_id = {charge_id};
-- Expected: 2 rows with reversed_at NOT NULL
```

### Test Scenario 3: Scope Matching

```sql
-- Create fund-scoped credit
INSERT INTO credits_ledger (investor_id, fund_id, deal_id, reason, original_amount)
VALUES (123, 5, NULL, 'MANUAL', 10000);

-- Create deal-scoped charge (Deal #10 belongs to Fund #5)
INSERT INTO charges (investor_id, fund_id, deal_id, amount)
VALUES (123, NULL, 10, 5000);

-- Apply credits
POST /api-v1/credits/auto-apply/{charge_id}

-- Verify scope mismatch
SELECT * FROM credit_applications WHERE charge_id = {charge_id};
-- Expected: 0 rows (credit not applied due to scope mismatch)

-- Create fund-scoped charge
INSERT INTO charges (investor_id, fund_id, deal_id, amount)
VALUES (123, 5, NULL, 5000);

-- Apply credits again
POST /api-v1/credits/auto-apply/{new_charge_id}

-- Verify scope match
SELECT * FROM credit_applications WHERE charge_id = {new_charge_id};
-- Expected: 1 row (credit applied, scope matches)
```

---

## Performance Considerations

### FIFO Query Optimization

The partial index `idx_credits_ledger_available_fifo` dramatically improves FIFO query performance:

```sql
-- WITHOUT partial index
EXPLAIN ANALYZE
SELECT * FROM credits_ledger
WHERE investor_id = 123 AND available_amount > 0
ORDER BY created_at ASC;
-- Cost: 15.0 (Seq Scan + Filter + Sort)

-- WITH partial index
CREATE INDEX idx_credits_ledger_available_fifo
ON credits_ledger (investor_id, created_at)
WHERE available_amount > 0;

EXPLAIN ANALYZE
SELECT * FROM credits_ledger
WHERE investor_id = 123 AND available_amount > 0
ORDER BY created_at ASC;
-- Cost: 1.5 (Index Scan)
```

**Result:** 10x performance improvement for typical FIFO queries.

### Transaction Isolation

All credit operations use database transactions to ensure consistency:

```typescript
const { data, error } = await supabase.rpc('apply_credits_fifo', {
  p_charge_id: chargeId
});
```

This prevents race conditions when multiple charges are submitted simultaneously.

---

## Security Considerations

### RLS Policies

**`credits_ledger` table:**
- SELECT: finance, ops, manager, admin
- INSERT/UPDATE: finance, admin
- DELETE: admin only

**`credit_applications` table:**
- SELECT: finance, ops, manager, admin
- INSERT/UPDATE: finance, admin (via auto-apply function)
- DELETE: Disabled (immutable audit trail)

### Reversal Immutability

Credit applications are never deleted, only marked as reversed. This provides a complete audit trail of credit movements.

---

## Troubleshooting

### Issue: Credits Not Auto-Applying

**Possible Causes:**
1. No available credits for investor
2. Scope mismatch (fund vs deal)
3. Credits already fully applied
4. Charge already has credits applied

**Debugging Steps:**
```sql
-- Check available credits
SELECT * FROM credits_ledger
WHERE investor_id = ? AND available_amount > 0
ORDER BY created_at ASC;

-- Check scope matching
SELECT * FROM credits_ledger
WHERE investor_id = ?
  AND (fund_id = ? OR deal_id = ?);

-- Check existing applications
SELECT * FROM credit_applications
WHERE charge_id = ? AND reversed_at IS NULL;
```

### Issue: Reversal Failed

**Possible Causes:**
1. No active credit applications found
2. Transaction rollback due to constraint violation

**Debugging Steps:**
```sql
-- Check for active applications
SELECT * FROM credit_applications
WHERE charge_id = ? AND reversed_at IS NULL;

-- Check credit balances
SELECT id, applied_amount, available_amount
FROM credits_ledger
WHERE id IN (
  SELECT credit_id FROM credit_applications WHERE charge_id = ?
);
```

### Issue: Partial Credit Math Error

**Possible Cause:** Floating-point precision issues

**Solution:** Use DECIMAL(15,2) consistently, never FLOAT or REAL.

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.6.0 | 2025-10-19 | Initial Credits Engine release with FIFO auto-apply, reversal support, scope matching |

---

## Support

For issues or questions:
- **Engine Implementation:** `supabase/functions/api-v1/creditsEngine.ts`
- **Database Schema:** `supabase/migrations/20251019110000_rbac_settings_credits.sql`
- **Documentation:** This file

---

**Last Updated:** 2025-10-19
**Maintained By:** Buligo Capital Development Team
