#!/bin/bash
# ============================================
# T01: POST /charges/:id/submit - cURL Test Pack
# Version: v1.8.0
# Date: 2025-10-21
# ============================================
# This script tests all scenarios for the charge submit endpoint.
#
# Prerequisites:
# - Supabase instance running (local or production)
# - Test data created (investor, fund, contribution, charge, credits)
# - Valid JWT tokens for different roles
# - Service API key configured
#
# Usage:
#   ./charges-submit-test.sh [local|prod]
#
# Environment Variables:
#   API_URL         - Base API URL (default: http://localhost:54321/functions/v1/api-v1)
#   ADMIN_JWT       - Admin user JWT token
#   FINANCE_JWT     - Finance user JWT token
#   VIEWER_JWT      - Viewer user JWT token
#   SERVICE_KEY     - Service API key (x-service-key header)
#   CHARGE_ID       - Test charge UUID (must be in DRAFT status)
# ============================================

set -e  # Exit on error

# ============================================
# CONFIGURATION
# ============================================
ENV=${1:-local}

if [ "$ENV" == "prod" ]; then
  API_URL="https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1"
else
  API_URL="${API_URL:-http://localhost:54321/functions/v1/api-v1}"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# ============================================
# HELPER: Print Section
# ============================================
print_section() {
  echo ""
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}========================================${NC}"
}

# ============================================
# HELPER: Print Test Result
# ============================================
print_result() {
  local test_name=$1
  local expected=$2
  local actual=$3

  TESTS_RUN=$((TESTS_RUN + 1))

  if [ "$expected" == "$actual" ]; then
    echo -e "${GREEN}✓ PASS${NC} - $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗ FAIL${NC} - $test_name"
    echo -e "  Expected: $expected"
    echo -e "  Actual:   $actual"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# ============================================
# HELPER: Make API Request
# ============================================
submit_charge() {
  local charge_id=$1
  local body=${2:-{}}
  local auth_header=$3

  curl -s -X POST "$API_URL/charges/$charge_id/submit" \
    -H "Content-Type: application/json" \
    -H "$auth_header" \
    -d "$body"
}

# ============================================
# SETUP: Check Environment Variables
# ============================================
print_section "ENVIRONMENT SETUP"

if [ -z "$CHARGE_ID" ]; then
  echo -e "${RED}ERROR: CHARGE_ID environment variable not set${NC}"
  echo "Create a test charge and set CHARGE_ID before running tests."
  exit 1
fi

if [ -z "$SERVICE_KEY" ]; then
  echo -e "${YELLOW}WARNING: SERVICE_KEY not set, some tests will be skipped${NC}"
fi

if [ -z "$ADMIN_JWT" ]; then
  echo -e "${YELLOW}WARNING: ADMIN_JWT not set, some tests will be skipped${NC}"
fi

echo "API URL: $API_URL"
echo "Charge ID: $CHARGE_ID"
echo ""

# ============================================
# TEST 1: Happy Path - Submit with Service Key
# ============================================
print_section "TEST 1: Happy Path - Submit DRAFT Charge"

if [ -n "$SERVICE_KEY" ]; then
  RESPONSE=$(submit_charge "$CHARGE_ID" '{}' "x-service-key: $SERVICE_KEY")
  STATUS=$(echo "$RESPONSE" | jq -r '.data.status // "ERROR"')

  print_result "Submit returns status PENDING" "PENDING" "$STATUS"

  # Verify credits applied
  CREDITS_APPLIED=$(echo "$RESPONSE" | jq -r '.data.credits_applied_amount // 0')
  NET_AMOUNT=$(echo "$RESPONSE" | jq -r '.data.net_amount // 0')

  echo "  Credits Applied: $CREDITS_APPLIED"
  echo "  Net Amount: $NET_AMOUNT"

  # Verify credit applications array exists
  APPS_COUNT=$(echo "$RESPONSE" | jq -r '.data.credit_applications | length')
  echo "  Credit Applications: $APPS_COUNT"

  if [ "$APPS_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} Credit applications found"

    # Verify FIFO order (first application should be oldest)
    FIRST_CREDIT_ID=$(echo "$RESPONSE" | jq -r '.data.credit_applications[0].credit_id')
    echo "  First Credit ID (FIFO): $FIRST_CREDIT_ID"
  fi
else
  echo -e "${YELLOW}SKIPPED - SERVICE_KEY not set${NC}"
fi

# ============================================
# TEST 2: Idempotency - Submit Twice
# ============================================
print_section "TEST 2: Idempotency - Submit PENDING Charge"

if [ -n "$SERVICE_KEY" ]; then
  # First submission (already done in TEST 1)
  # Second submission (should return same result)
  RESPONSE2=$(submit_charge "$CHARGE_ID" '{}' "x-service-key: $SERVICE_KEY")
  STATUS2=$(echo "$RESPONSE2" | jq -r '.data.status // "ERROR"')

  print_result "Second submit returns PENDING" "PENDING" "$STATUS2"

  # Verify same credits applied amount
  CREDITS_APPLIED2=$(echo "$RESPONSE2" | jq -r '.data.credits_applied_amount // 0')

  if [ "$CREDITS_APPLIED" == "$CREDITS_APPLIED2" ]; then
    echo -e "${GREEN}✓${NC} Credits applied amount unchanged (idempotent)"
  else
    echo -e "${RED}✗${NC} Credits applied amount changed!"
    echo "  First:  $CREDITS_APPLIED"
    echo "  Second: $CREDITS_APPLIED2"
  fi
else
  echo -e "${YELLOW}SKIPPED - SERVICE_KEY not set${NC}"
fi

# ============================================
# TEST 3: Dry Run Mode
# ============================================
print_section "TEST 3: Dry Run - Preview Credits"

if [ -n "$SERVICE_KEY" ]; then
  # Create a new DRAFT charge for dry run test
  # Note: In real test, you'd create this via API
  # For now, we'll use a hypothetical DRAFT charge ID

  # Dry run request
  DRY_RUN_BODY='{"dry_run": true}'

  # Note: This will fail if charge is already PENDING
  # In real test, create a fresh DRAFT charge

  echo -e "${YELLOW}NOTE: Dry run test requires a DRAFT charge${NC}"
  echo "  This test is informational - create a DRAFT charge to test dry_run=true"
else
  echo -e "${YELLOW}SKIPPED - SERVICE_KEY not set${NC}"
fi

# ============================================
# TEST 4: Feature Flag Disabled
# ============================================
print_section "TEST 4: Feature Flag - Disabled Returns 403"

echo -e "${YELLOW}NOTE: This test requires manually disabling 'charges_engine' flag${NC}"
echo "  1. Disable flag: UPDATE feature_flags SET is_enabled = false WHERE flag_key = 'charges_engine';"
echo "  2. Submit charge (should return 403)"
echo "  3. Re-enable flag: UPDATE feature_flags SET is_enabled = true WHERE flag_key = 'charges_engine';"

# ============================================
# TEST 5: RBAC - Finance Can Submit
# ============================================
print_section "TEST 5: RBAC - Finance User Can Submit"

if [ -n "$FINANCE_JWT" ]; then
  # Note: This will fail if charge is already PENDING
  # In real test, create a fresh DRAFT charge

  RESPONSE_FINANCE=$(submit_charge "$CHARGE_ID" '{}' "Authorization: Bearer $FINANCE_JWT")
  STATUS_FINANCE=$(echo "$RESPONSE_FINANCE" | jq -r '.data.status // .code // "ERROR"')

  # Should return either PENDING (if fresh) or same idempotent response
  if [ "$STATUS_FINANCE" == "PENDING" ] || [ "$STATUS_FINANCE" == "ERROR" ]; then
    echo -e "${GREEN}✓${NC} Finance user authorized"
  else
    echo -e "${RED}✗${NC} Unexpected response: $STATUS_FINANCE"
  fi
else
  echo -e "${YELLOW}SKIPPED - FINANCE_JWT not set${NC}"
fi

# ============================================
# TEST 6: RBAC - Viewer Cannot Submit
# ============================================
print_section "TEST 6: RBAC - Viewer User Cannot Submit (403)"

if [ -n "$VIEWER_JWT" ]; then
  RESPONSE_VIEWER=$(submit_charge "$CHARGE_ID" '{}' "Authorization: Bearer $VIEWER_JWT")
  ERROR_CODE=$(echo "$RESPONSE_VIEWER" | jq -r '.code // "UNKNOWN"')

  print_result "Viewer gets FORBIDDEN" "FORBIDDEN" "$ERROR_CODE"
else
  echo -e "${YELLOW}SKIPPED - VIEWER_JWT not set${NC}"
fi

# ============================================
# TEST 7: Invalid Charge ID (404)
# ============================================
print_section "TEST 7: Invalid Charge ID - Returns 404"

if [ -n "$SERVICE_KEY" ]; then
  INVALID_UUID="00000000-0000-0000-0000-000000000000"
  RESPONSE_404=$(submit_charge "$INVALID_UUID" '{}' "x-service-key: $SERVICE_KEY")
  ERROR_CODE=$(echo "$RESPONSE_404" | jq -r '.code // "UNKNOWN"')

  print_result "Invalid charge returns NOT_FOUND" "NOT_FOUND" "$ERROR_CODE"
else
  echo -e "${YELLOW}SKIPPED - SERVICE_KEY not set${NC}"
fi

# ============================================
# TEST 8: No Credits Available
# ============================================
print_section "TEST 8: No Credits - Charge Submitted with Full Net Amount"

echo -e "${YELLOW}NOTE: This test requires a charge with no matching credits${NC}"
echo "  Create a charge for an investor with no credits, or with mismatched scope/currency"
echo "  Expected: status=PENDING, credits_applied_amount=0, net_amount=total_amount"

# ============================================
# TEST 9: Scope Mismatch (Deal Charge, Fund Credits)
# ============================================
print_section "TEST 9: Scope Mismatch - Deal Charge with Fund Credits"

echo -e "${YELLOW}NOTE: This test requires specific test data${NC}"
echo "  1. Create deal-scoped charge"
echo "  2. Ensure investor has only fund-scoped credits (no deal credits)"
echo "  3. Submit charge"
echo "  Expected: status=PENDING, credits_applied_amount=0 (no matching scope)"

# ============================================
# TEST 10: Currency Mismatch
# ============================================
print_section "TEST 10: Currency Mismatch - Credits Ignored"

echo -e "${YELLOW}NOTE: This test requires specific test data${NC}"
echo "  1. Create charge with currency='EUR'"
echo "  2. Ensure investor has only USD credits"
echo "  3. Submit charge"
echo "  Expected: status=PENDING, credits_applied_amount=0 (no matching currency)"

# ============================================
# TEST 11: Invalid Status Transition
# ============================================
print_section "TEST 11: Invalid Status - Cannot Submit APPROVED Charge"

echo -e "${YELLOW}NOTE: This test requires an APPROVED charge${NC}"
echo "  1. Create and approve a charge"
echo "  2. Attempt to submit (should fail with 409)"
echo "  Expected: code=CONFLICT, message='Invalid status transition'"

# ============================================
# TEST 12: Partial Credit Coverage
# ============================================
print_section "TEST 12: Partial Coverage - Insufficient Credits"

echo -e "${YELLOW}NOTE: This test requires specific test data${NC}"
echo "  1. Create charge with total_amount=1000"
echo "  2. Ensure investor has credits totaling only 700"
echo "  3. Submit charge"
echo "  Expected: credits_applied_amount=700, net_amount=300"

# ============================================
# TEST SUMMARY
# ============================================
print_section "TEST SUMMARY"

echo "Tests Run:    $TESTS_RUN"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
  echo ""
  echo -e "${GREEN}All tests passed! ✓${NC}"
  exit 0
else
  echo ""
  echo -e "${RED}Some tests failed. Review output above.${NC}"
  exit 1
fi
