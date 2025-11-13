#!/bin/bash
# ============================================
# T02 Charge Workflow - cURL Test Script
# Version: v1.9.0
# Date: 2025-10-21
# ============================================
# Tests: Approve, Reject, Mark-Paid endpoints
#
# Usage:
#   ./tests/t02-charges-workflow-curl.sh
#
# Prerequisites:
#   - Supabase project running
#   - Feature flag 'charges_engine' enabled
#   - Admin user JWT token
#   - Test charge in PENDING status

set -e

# ============================================
# CONFIGURATION
# ============================================
API_BASE="${SUPABASE_URL:-http://localhost:54321}/functions/v1/api-v1"
ADMIN_JWT="${ADMIN_JWT:-your-admin-jwt-token}"
SERVICE_KEY="${SUPABASE_SERVICE_KEY:-your-service-key}"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test results
PASSED=0
FAILED=0

# ============================================
# HELPER FUNCTIONS
# ============================================

print_header() {
  echo ""
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}========================================${NC}"
}

print_test() {
  echo -e "${YELLOW}TEST:${NC} $1"
}

print_success() {
  echo -e "${GREEN}✓ PASS:${NC} $1"
  ((PASSED++))
}

print_fail() {
  echo -e "${RED}✗ FAIL:${NC} $1"
  ((FAILED++))
}

# ============================================
# PREREQUISITE: Create Test Charge
# ============================================

print_header "SETUP: Creating Test Charges"

# Create investor, fund, contribution, credits, and charges
# (Assumes you have these endpoints available or manually create test data)

# For this demo, we'll use placeholder IDs
# Replace these with actual IDs from your test database
TEST_CHARGE_PENDING="00000000-0000-0000-0000-000000000001"
TEST_CHARGE_DRAFT="00000000-0000-0000-0000-000000000002"
TEST_CHARGE_APPROVED="00000000-0000-0000-0000-000000000003"

echo "Using test charge IDs:"
echo "  PENDING:  $TEST_CHARGE_PENDING"
echo "  DRAFT:    $TEST_CHARGE_DRAFT"
echo "  APPROVED: $TEST_CHARGE_APPROVED"

# ============================================
# TEST SUITE: APPROVE
# ============================================

print_header "TEST SUITE: POST /charges/:id/approve"

# Test 1: Approve PENDING charge (Happy Path)
print_test "1. Approve PENDING charge → 200 OK"
RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST "$API_BASE/charges/$TEST_CHARGE_PENDING/approve" \
  -H "Authorization: Bearer $ADMIN_JWT" \
  -H "Content-Type: application/json" \
  -d '{"comment":"Approved via cURL test"}')

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
  STATUS=$(echo "$BODY" | jq -r '.data.status')
  if [ "$STATUS" = "APPROVED" ]; then
    print_success "Charge approved successfully"
    echo "  Status: $STATUS"
    echo "  Approved at: $(echo "$BODY" | jq -r '.data.approved_at')"
  else
    print_fail "Expected status APPROVED, got: $STATUS"
  fi
else
  print_fail "Expected 200, got: $HTTP_CODE"
  echo "$BODY" | jq .
fi

# Test 2: Idempotent re-approve
print_test "2. Re-approve APPROVED charge → 200 OK (idempotent)"
RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST "$API_BASE/charges/$TEST_CHARGE_PENDING/approve" \
  -H "Authorization: Bearer $ADMIN_JWT" \
  -H "Content-Type: application/json")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

if [ "$HTTP_CODE" = "200" ]; then
  print_success "Idempotent re-approve returned 200"
else
  print_fail "Expected 200, got: $HTTP_CODE"
fi

# Test 3: Approve DRAFT charge → 409 Conflict
print_test "3. Approve DRAFT charge → 409 Conflict"
RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST "$API_BASE/charges/$TEST_CHARGE_DRAFT/approve" \
  -H "Authorization: Bearer $ADMIN_JWT" \
  -H "Content-Type: application/json")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

if [ "$HTTP_CODE" = "409" ]; then
  print_success "Correctly rejected DRAFT with 409"
else
  print_fail "Expected 409, got: $HTTP_CODE"
fi

# Test 4: Service key can approve
print_test "4. Approve with service key → 200 OK"
RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST "$API_BASE/charges/$TEST_CHARGE_PENDING/approve" \
  -H "Authorization: Bearer $SERVICE_KEY" \
  -H "Content-Type: application/json")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

if [ "$HTTP_CODE" = "200" ]; then
  print_success "Service key allowed for approve"
else
  print_fail "Expected 200, got: $HTTP_CODE"
fi

# ============================================
# TEST SUITE: REJECT
# ============================================

print_header "TEST SUITE: POST /charges/:id/reject"

# Test 5: Reject PENDING charge (Happy Path)
print_test "5. Reject PENDING charge with reason → 200 OK"
RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST "$API_BASE/charges/$TEST_CHARGE_PENDING/reject" \
  -H "Authorization: Bearer $ADMIN_JWT" \
  -H "Content-Type: application/json" \
  -d '{"reason":"Wrong amount calculated"}')

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
  STATUS=$(echo "$BODY" | jq -r '.data.status')
  REASON=$(echo "$BODY" | jq -r '.data.reject_reason')
  CREDITS_APPLIED=$(echo "$BODY" | jq -r '.data.credits_applied_amount')

  if [ "$STATUS" = "REJECTED" ] && [ "$CREDITS_APPLIED" = "0" ]; then
    print_success "Charge rejected and credits restored"
    echo "  Status: $STATUS"
    echo "  Reason: $REASON"
    echo "  Credits applied: $CREDITS_APPLIED (should be 0)"
  else
    print_fail "Unexpected state: status=$STATUS, credits=$CREDITS_APPLIED"
  fi
else
  print_fail "Expected 200, got: $HTTP_CODE"
  echo "$BODY" | jq .
fi

# Test 6: Reject without reason → 400 Bad Request
print_test "6. Reject without reason → 400 Bad Request"
RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST "$API_BASE/charges/$TEST_CHARGE_PENDING/reject" \
  -H "Authorization: Bearer $ADMIN_JWT" \
  -H "Content-Type: application/json" \
  -d '{}')

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

if [ "$HTTP_CODE" = "400" ]; then
  print_success "Correctly rejected missing reason with 400"
else
  print_fail "Expected 400, got: $HTTP_CODE"
fi

# Test 7: Reject with short reason (< 3 chars) → 400
print_test "7. Reject with reason < 3 chars → 400 Bad Request"
RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST "$API_BASE/charges/$TEST_CHARGE_PENDING/reject" \
  -H "Authorization: Bearer $ADMIN_JWT" \
  -H "Content-Type: application/json" \
  -d '{"reason":"ab"}')

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

if [ "$HTTP_CODE" = "400" ]; then
  print_success "Correctly rejected short reason with 400"
else
  print_fail "Expected 400, got: $HTTP_CODE"
fi

# Test 8: Idempotent re-reject
print_test "8. Re-reject REJECTED charge → 200 OK (idempotent)"
RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST "$API_BASE/charges/$TEST_CHARGE_PENDING/reject" \
  -H "Authorization: Bearer $ADMIN_JWT" \
  -H "Content-Type: application/json" \
  -d '{"reason":"Another reason"}')

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

if [ "$HTTP_CODE" = "200" ]; then
  print_success "Idempotent re-reject returned 200"
else
  print_fail "Expected 200, got: $HTTP_CODE"
fi

# ============================================
# TEST SUITE: MARK-PAID
# ============================================

print_header "TEST SUITE: POST /charges/:id/mark-paid"

# Test 9: Mark-paid APPROVED charge (Happy Path)
print_test "9. Mark-paid APPROVED charge → 200 OK"
RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST "$API_BASE/charges/$TEST_CHARGE_APPROVED/mark-paid" \
  -H "Authorization: Bearer $ADMIN_JWT" \
  -H "Content-Type: application/json" \
  -d '{"payment_ref":"WIRE-2025-001","paid_at":"2025-10-21T10:30:00Z"}')

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
  STATUS=$(echo "$BODY" | jq -r '.data.status')
  PAYMENT_REF=$(echo "$BODY" | jq -r '.data.payment_ref')
  PAID_AT=$(echo "$BODY" | jq -r '.data.paid_at')

  if [ "$STATUS" = "PAID" ]; then
    print_success "Charge marked paid successfully"
    echo "  Status: $STATUS"
    echo "  Payment ref: $PAYMENT_REF"
    echo "  Paid at: $PAID_AT"
  else
    print_fail "Expected status PAID, got: $STATUS"
  fi
else
  print_fail "Expected 200, got: $HTTP_CODE"
  echo "$BODY" | jq .
fi

# Test 10: Mark-paid PENDING charge → 409 Conflict
print_test "10. Mark-paid PENDING charge → 409 Conflict"
RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST "$API_BASE/charges/$TEST_CHARGE_PENDING/mark-paid" \
  -H "Authorization: Bearer $ADMIN_JWT" \
  -H "Content-Type: application/json")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

if [ "$HTTP_CODE" = "409" ]; then
  print_success "Correctly rejected PENDING with 409"
else
  print_fail "Expected 409, got: $HTTP_CODE"
fi

# Test 11: Mark-paid with service key → 403 Forbidden
print_test "11. Mark-paid with service key → 403 Forbidden"
RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST "$API_BASE/charges/$TEST_CHARGE_APPROVED/mark-paid" \
  -H "Authorization: Bearer $SERVICE_KEY" \
  -H "Content-Type: application/json")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

if [ "$HTTP_CODE" = "403" ]; then
  print_success "Service key correctly blocked with 403"
else
  print_fail "Expected 403, got: $HTTP_CODE"
fi

# Test 12: Mark-paid without payment_ref (defaults)
print_test "12. Mark-paid without payment_ref → 200 OK (defaults)"
RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST "$API_BASE/charges/$TEST_CHARGE_APPROVED/mark-paid" \
  -H "Authorization: Bearer $ADMIN_JWT" \
  -H "Content-Type: application/json" \
  -d '{}')

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
  PAID_AT=$(echo "$BODY" | jq -r '.data.paid_at')
  if [ "$PAID_AT" != "null" ] && [ -n "$PAID_AT" ]; then
    print_success "Marked paid with default timestamp"
    echo "  Paid at: $PAID_AT"
  else
    print_fail "paid_at was null or empty"
  fi
else
  print_fail "Expected 200, got: $HTTP_CODE"
fi

# ============================================
# SUMMARY
# ============================================

print_header "TEST SUMMARY"

TOTAL=$((PASSED + FAILED))
echo "Total tests: $TOTAL"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"

if [ $FAILED -eq 0 ]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed.${NC}"
  exit 1
fi
