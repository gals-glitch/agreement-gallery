#!/bin/bash
# =============================================================================
# Approve Agreement and Backfill Commissions CLI Script
# Purpose: Approve a distributor commission agreement and recompute past commissions
# Usage: ./approve-and-backfill-commissions.sh <agreement_id> <investor_id>
# Date: 2025-11-11
# =============================================================================

set -e  # Exit on error

# Configuration
API_URL="${SUPABASE_URL}/functions/v1/api-v1"
TOKEN="${SUPABASE_TOKEN}"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check arguments
if [ "$#" -ne 2 ]; then
    echo -e "${RED}Error: Missing arguments${NC}"
    echo "Usage: $0 <agreement_id> <investor_id>"
    echo "Example: $0 abc-123-def 456"
    exit 1
fi

AGREEMENT_ID="$1"
INVESTOR_ID="$2"

# Check environment variables
if [ -z "$SUPABASE_URL" ]; then
    echo -e "${RED}Error: SUPABASE_URL environment variable not set${NC}"
    exit 1
fi

if [ -z "$SUPABASE_TOKEN" ]; then
    echo -e "${RED}Error: SUPABASE_TOKEN environment variable not set${NC}"
    exit 1
fi

echo -e "${YELLOW}==============================================================================${NC}"
echo -e "${YELLOW}Approve & Backfill Workflow${NC}"
echo -e "${YELLOW}==============================================================================${NC}"
echo -e "Agreement ID: ${AGREEMENT_ID}"
echo -e "Investor ID:  ${INVESTOR_ID}"
echo ""

# =============================================================================
# Step 1: Approve Agreement
# =============================================================================
echo -e "${YELLOW}[1/3] Approving agreement...${NC}"

APPROVE_RESPONSE=$(curl -s -X POST \
  "${API_URL}/agreements/${AGREEMENT_ID}/approve" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "apikey: ${SUPABASE_PUBLISHABLE_KEY}" \
  -w "\n%{http_code}")

HTTP_CODE=$(echo "$APPROVE_RESPONSE" | tail -n1)
APPROVE_BODY=$(echo "$APPROVE_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    echo -e "${GREEN}✓ Agreement approved successfully${NC}"
    echo -e "  Status: APPROVED"
else
    echo -e "${RED}✗ Failed to approve agreement${NC}"
    echo -e "  HTTP Code: ${HTTP_CODE}"
    echo -e "  Response: ${APPROVE_BODY}"
    exit 1
fi

echo ""

# =============================================================================
# Step 2: Fetch Contribution IDs
# =============================================================================
echo -e "${YELLOW}[2/3] Fetching contributions for investor...${NC}"

CONTRIBUTIONS_RESPONSE=$(curl -s \
  "${API_URL}/contributions?investor_id=${INVESTOR_ID}" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "apikey: ${SUPABASE_PUBLISHABLE_KEY}")

# Extract contribution IDs using jq
if command -v jq &> /dev/null; then
    CONTRIBUTION_IDS=$(echo "$CONTRIBUTIONS_RESPONSE" | jq '[.items[].id]')
    CONTRIBUTION_COUNT=$(echo "$CONTRIBUTIONS_RESPONSE" | jq '.items | length')
else
    echo -e "${RED}Error: jq is not installed. Please install jq to parse JSON.${NC}"
    exit 1
fi

if [ "$CONTRIBUTION_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}⚠ No contributions found for this investor${NC}"
    echo -e "${GREEN}✓ Agreement approved, but no commissions to recompute${NC}"
    exit 0
fi

echo -e "${GREEN}✓ Found ${CONTRIBUTION_COUNT} contribution(s)${NC}"
echo -e "  Contribution IDs: ${CONTRIBUTION_IDS}"

echo ""

# =============================================================================
# Step 3: Batch Compute Commissions
# =============================================================================
echo -e "${YELLOW}[3/3] Recomputing commissions...${NC}"

COMPUTE_RESPONSE=$(curl -s -X POST \
  "${API_URL}/commissions/batch-compute" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "apikey: ${SUPABASE_PUBLISHABLE_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"contribution_ids\": ${CONTRIBUTION_IDS}}" \
  -w "\n%{http_code}")

HTTP_CODE=$(echo "$COMPUTE_RESPONSE" | tail -n1)
COMPUTE_BODY=$(echo "$COMPUTE_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    COMPUTED_COUNT=$(echo "$COMPUTE_BODY" | jq -r '.count // 0')
    echo -e "${GREEN}✓ Successfully recomputed ${COMPUTED_COUNT} commission(s)${NC}"

    # Show summary
    echo ""
    echo -e "${GREEN}==============================================================================${NC}"
    echo -e "${GREEN}SUCCESS: Workflow completed${NC}"
    echo -e "${GREEN}==============================================================================${NC}"
    echo -e "Agreement:   ${AGREEMENT_ID} → APPROVED"
    echo -e "Investor:    ${INVESTOR_ID}"
    echo -e "Commissions: ${COMPUTED_COUNT} created"
else
    echo -e "${RED}✗ Failed to recompute commissions${NC}"
    echo -e "  HTTP Code: ${HTTP_CODE}"
    echo -e "  Response: ${COMPUTE_BODY}"
    exit 1
fi

# =============================================================================
# Optional: Display Sample Commissions
# =============================================================================
echo ""
echo -e "${YELLOW}Fetching sample commissions for verification...${NC}"

COMMISSIONS_SAMPLE=$(curl -s \
  "${API_URL}/commissions?investor_id=${INVESTOR_ID}&limit=3" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "apikey: ${SUPABASE_PUBLISHABLE_KEY}")

if command -v jq &> /dev/null; then
    echo "$COMMISSIONS_SAMPLE" | jq -r '.items[] | "  - Commission \(.id): $\(.total_amount) (\(.status))"'
fi

echo ""
echo -e "${GREEN}Done!${NC}"
