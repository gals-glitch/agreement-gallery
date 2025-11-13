#!/bin/bash
# ============================================
# T01+T02 Manual Test Guide
# Copy-paste these commands one by one
# ============================================

# Set your credentials first
export SUPABASE_URL="https://qwgicrdcoqdketqhxbys.supabase.co"
export SERVICE_KEY="YOUR_SERVICE_ROLE_KEY_HERE"  # Replace with actual key
export ANON_KEY="YOUR_ANON_KEY_HERE"            # Replace with actual key

# ============================================
# TEST 1: Compute charge for contribution 3
# ============================================
echo -e "\n[STEP 1] POST /charges/compute"

CHARGE_ID=$(curl -s -X POST "$SUPABASE_URL/functions/v1/api-v1/charges/compute" \
  -H "Authorization: Bearer $SERVICE_KEY" \
  -H "apikey: $ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"contribution_id": 3}' | jq -r '.data.id')

echo "Charge ID: $CHARGE_ID"

# Verify charge details
curl -s -X POST "$SUPABASE_URL/functions/v1/api-v1/charges/compute" \
  -H "Authorization: Bearer $SERVICE_KEY" \
  -H "apikey: $ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"contribution_id": 3}' | jq '.data | {id, status, base_amount, vat_amount, total_amount}'

# ============================================
# TEST 2: Submit charge (apply credits)
# ============================================
echo -e "\n[STEP 2] POST /charges/$CHARGE_ID/submit"

curl -s -X POST "$SUPABASE_URL/functions/v1/api-v1/charges/$CHARGE_ID/submit" \
  -H "Authorization: Bearer $SERVICE_KEY" \
  -H "apikey: $ANON_KEY" \
  -H "Content-Type: application/json" | jq '.data | {id, status, credits_applied_amount, net_amount, credit_applications: (.credit_applications | length)}'

# ============================================
# TEST 3: Approve charge
# ============================================
echo -e "\n[STEP 3] POST /charges/$CHARGE_ID/approve"

curl -s -X POST "$SUPABASE_URL/functions/v1/api-v1/charges/$CHARGE_ID/approve" \
  -H "Authorization: Bearer $SERVICE_KEY" \
  -H "apikey: $ANON_KEY" \
  -H "Content-Type: application/json" | jq '.data | {id, status, approved_at, approved_by}'

# ============================================
# TEST 4: Mark charge paid
# ============================================
echo -e "\n[STEP 4] POST /charges/$CHARGE_ID/mark-paid"

curl -s -X POST "$SUPABASE_URL/functions/v1/api-v1/charges/$CHARGE_ID/mark-paid" \
  -H "Authorization: Bearer $SERVICE_KEY" \
  -H "apikey: $ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "payment_ref": "WIRE-2025-TEST-001",
    "paid_at": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
  }' | jq '.data | {id, status, paid_at, payment_ref}'

# ============================================
# TEST 5: Idempotency - submit again (should work)
# ============================================
echo -e "\n[STEP 5] POST /charges/$CHARGE_ID/submit (idempotency)"

curl -s -X POST "$SUPABASE_URL/functions/v1/api-v1/charges/$CHARGE_ID/submit" \
  -H "Authorization: Bearer $SERVICE_KEY" \
  -H "apikey: $ANON_KEY" \
  -H "Content-Type: application/json" | jq '.data | {id, status}'

# ============================================
# TEST 6: Error test - reject without reason (should fail with 400)
# ============================================
echo -e "\n[STEP 6] POST /charges/$CHARGE_ID/reject (no reason - expect 400)"

curl -s -X POST "$SUPABASE_URL/functions/v1/api-v1/charges/$CHARGE_ID/reject" \
  -H "Authorization: Bearer $SERVICE_KEY" \
  -H "apikey: $ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{}' -w "\nHTTP Status: %{http_code}\n"

echo -e "\n[SUCCESS] Test suite completed"
echo "Review output above to verify:"
echo "  1. Charge computed with correct amounts"
echo "  2. Status progression: DRAFT -> PENDING -> APPROVED -> PAID"
echo "  3. Credits applied during submit"
echo "  4. Idempotency working (no errors on re-submit)"
echo "  5. Validation working (400 error for missing reject reason)"
