# T01: POST /charges/:id/submit - Quick Start Guide

**5-Minute Setup & Test Guide**

---

## Prerequisites

- Supabase instance running (local or production)
- Service API key configured
- At least one investor with credits

---

## Quick Test (cURL)

### 1. Create Test Data

```sql
-- 1. Create test investor
INSERT INTO investors (name, party_entity_id)
VALUES ('Test Investor', 1)
RETURNING id;  -- Note this ID (e.g., 123)

-- 2. Create test fund
INSERT INTO funds (name, currency)
VALUES ('Test Fund', 'USD')
RETURNING id;  -- Note this ID (e.g., 5)

-- 3. Create test contribution
INSERT INTO contributions (investor_id, fund_id, paid_in_date, amount, currency)
VALUES (123, 5, '2025-10-01', 10000, 'USD')
RETURNING id;  -- Note this ID

-- 4. Create test credits
INSERT INTO credits_ledger (investor_id, fund_id, reason, original_amount, available_amount, currency)
VALUES
  (123, 5, 'Referral bonus', 500, 500, 'USD'),
  (123, 5, 'Promotional credit', 200, 200, 'USD');

-- 5. Enable feature flag
UPDATE feature_flags
SET is_enabled = true
WHERE flag_key = 'charges_engine';
```

### 2. Create DRAFT Charge via Compute

```bash
export API_URL="http://localhost:54321/functions/v1/api-v1"
export SERVICE_KEY="your-service-key-here"
export CONTRIBUTION_ID="contribution-uuid-from-step-3"

# Compute charge
CHARGE_RESPONSE=$(curl -s -X POST "$API_URL/charges/compute" \
  -H "x-service-key: $SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"contribution_id\": \"$CONTRIBUTION_ID\"}")

# Extract charge ID
export CHARGE_ID=$(echo "$CHARGE_RESPONSE" | jq -r '.data.id')

echo "Charge ID: $CHARGE_ID"
```

### 3. Submit Charge

```bash
# Submit with service key
curl -s -X POST "$API_URL/charges/$CHARGE_ID/submit" \
  -H "x-service-key: $SERVICE_KEY" \
  -H "Content-Type: application/json" | jq
```

**Expected Response:**

```json
{
  "data": {
    "id": "a0fb4b54-...",
    "status": "PENDING",
    "total_amount": 600.00,
    "credits_applied_amount": 600.00,
    "net_amount": 0.00,
    "credit_applications": [
      {
        "credit_id": "c1a2b3c4-...",
        "amount": 500.00,
        "applied_at": "2025-10-21T..."
      },
      {
        "credit_id": "c7a8b9c0-...",
        "amount": 100.00,
        "applied_at": "2025-10-21T..."
      }
    ]
  }
}
```

### 4. Verify Idempotency

```bash
# Submit again (should return same result)
curl -s -X POST "$API_URL/charges/$CHARGE_ID/submit" \
  -H "x-service-key: $SERVICE_KEY" \
  -H "Content-Type: application/json" | jq
```

**Expected:** Same response as step 3 (no duplicate applications)

### 5. Test Dry Run

```bash
# Create another DRAFT charge first (repeat steps 3-4 with new contribution)
export CHARGE_ID_2="new-charge-uuid"

# Dry run (preview only)
curl -s -X POST "$API_URL/charges/$CHARGE_ID_2/submit" \
  -H "x-service-key: $SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"dry_run": true}' | jq
```

**Expected:** Status still "DRAFT", but shows credits that would be applied

---

## Quick Test (TypeScript/Frontend)

```typescript
// submit-charge.ts
async function submitCharge(chargeId: string, serviceKey: string) {
  const response = await fetch(
    `http://localhost:54321/functions/v1/api-v1/charges/${chargeId}/submit`,
    {
      method: 'POST',
      headers: {
        'x-service-key': serviceKey,
        'Content-Type': 'application/json',
      },
    }
  );

  const result = await response.json();

  if (response.ok) {
    console.log('✅ Charge submitted successfully!');
    console.log(`   Status: ${result.data.status}`);
    console.log(`   Credits Applied: $${result.data.credits_applied_amount}`);
    console.log(`   Net Amount: $${result.data.net_amount}`);
    console.log(`   Applications: ${result.data.credit_applications.length}`);
  } else {
    console.error('❌ Submission failed:', result);
  }

  return result;
}

// Usage
submitCharge('your-charge-uuid', 'your-service-key');
```

---

## Quick Test (Deno)

```bash
# Run unit tests
deno test supabase/functions/api-v1/charges.submit.test.ts

# Run integration tests
deno test supabase/functions/api-v1/charges.submit.integration.test.ts

# Run all charges tests
deno test supabase/functions/api-v1/charges.*.test.ts
```

---

## Quick Test (Automated Script)

```bash
# Make executable
chmod +x docs/charges-submit-test.sh

# Set environment
export API_URL="http://localhost:54321/functions/v1/api-v1"
export SERVICE_KEY="your-service-key"
export CHARGE_ID="your-charge-uuid"

# Run all tests
./docs/charges-submit-test.sh local
```

---

## Troubleshooting

### Issue: "Feature flag disabled" (403)

```sql
-- Check and enable flag
SELECT * FROM feature_flags WHERE flag_key = 'charges_engine';
UPDATE feature_flags SET is_enabled = true WHERE flag_key = 'charges_engine';
```

### Issue: "Charge not found" (404)

```bash
# Verify charge exists and is DRAFT
psql -c "SELECT id, status FROM charges WHERE id = '$CHARGE_ID';"
```

### Issue: No credits applied (net_amount = total_amount)

```sql
-- Check available credits
SELECT id, available_amount, currency, fund_id, deal_id
FROM credits_ledger
WHERE investor_id = 123 AND available_amount > 0;
```

### Issue: "Invalid status transition" (409)

```bash
# Charge is already PENDING (this is expected for idempotent calls)
# To reset for testing:
psql -c "UPDATE charges SET status = 'DRAFT' WHERE id = '$CHARGE_ID';"
```

---

## Next Steps

1. ✅ **Test happy path** (submit DRAFT charge with credits)
2. ✅ **Test idempotency** (submit twice, verify no duplicates)
3. ✅ **Test edge cases** (no credits, scope mismatch, currency mismatch)
4. ✅ **Run full test suite** (unit + integration tests)
5. ✅ **Integrate with frontend** (add submit button to UI)
6. ✅ **Deploy to production** (after QA approval)

---

## Files Reference

| File | Purpose |
|------|---------|
| `charges.ts` | Main submit handler implementation |
| `creditsEngine.ts` | FIFO credit application logic |
| `charges.submit.test.ts` | Unit tests (10 tests) |
| `charges.submit.integration.test.ts` | Integration tests (4 tests) |
| `openapi-charges.yaml` | API specification |
| `charges-submit-test.sh` | cURL test pack (12 scenarios) |
| `T01-IMPLEMENTATION-SUMMARY.md` | Complete documentation |

---

## Support

- **Documentation:** T01-IMPLEMENTATION-SUMMARY.md
- **API Spec:** openapi-charges.yaml
- **Tests:** charges.submit.test.ts

---

**Status:** ✅ READY FOR USE

**Last Updated:** 2025-10-21
