# Approve & Backfill Workflow Guide
**Feature**: One-Click Distributor Assignment with Agreement Approval & Commission Backfill
**Date**: November 11, 2025

---

## Overview

This guide covers the end-to-end workflow for assigning distributors to investors and automatically creating, approving, and backfilling commission calculations.

### What Problem Does This Solve?

**Before**:
1. User assigns distributor to investor
2. Agreement must be manually created in admin panel
3. Agreement must be manually approved
4. Contributions must be manually identified
5. Commission compute must be manually triggered

**After**:
1. User assigns distributor → Agreement auto-created
2. Dialog appears with one-click approve + backfill buttons
3. All done in seconds, directly from Investor Detail page

---

## UI Workflow (Recommended for Most Users)

### Step 1: Navigate to Investor

1. Go to **Investors** page (`/investors`)
2. Click on investor name or "View" button
3. You're now on Investor Detail page

### Step 2: Assign Distributor

1. Click **"Edit Source"** button (top-right)
2. Select **"Distributor"** from Source Type dropdown
3. Select distributor party from dropdown
4. Click **"Save Changes"**

### Step 3: Approve & Backfill Dialog Appears

The system automatically shows a dialog:

```
┌─────────────────────────────────────────────────────────┐
│  Distributor Linked                                      │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  A default commission agreement was created in DRAFT     │
│  status. You can approve it now and optionally           │
│  recompute commissions for past contributions.           │
│                                                           │
│  ┌─────────────────────────────────────────────────┐    │
│  │ Note: The agreement must be approved before     │    │
│  │ commissions can be calculated. This investor    │    │
│  │ has 10 contribution(s) that can be recomputed.  │    │
│  └─────────────────────────────────────────────────┘    │
│                                                           │
│  [Skip for Now]  [Approve Agreement]  [Recompute Past]  │
└─────────────────────────────────────────────────────────┘
```

### Step 4: Choose Action

#### Option A: Approve Now + Backfill (Recommended)

1. Click **"Approve Agreement"**
   - Agreement status: DRAFT → APPROVED
   - Toast notification appears
   - Active Agreements section updates

2. Click **"Recompute Past Commissions"**
   - System fetches all contribution IDs
   - Batch computes commissions
   - Toast shows: "Successfully recomputed N commission(s)"
   - Dialog closes
   - Commissions section updates with new data

#### Option B: Skip for Now

Click **"Skip for Now"** if you need to:
- Review agreement terms before approving
- Coordinate with finance team
- Set up additional configuration

The agreement remains in DRAFT status and can be approved later from:
- Agreements admin panel
- Re-running this workflow by re-assigning the distributor

---

## CLI Workflow (For Operations Team)

### Prerequisites

```bash
# Required environment variables
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_TOKEN="your-service-role-key-or-user-jwt"
export SUPABASE_PUBLISHABLE_KEY="your-anon-key"

# Required tools
- curl
- jq (for JSON parsing)
```

### Usage

```bash
# Make script executable (first time only)
chmod +x scripts/approve-and-backfill-commissions.sh

# Run the workflow
./scripts/approve-and-backfill-commissions.sh <agreement_id> <investor_id>
```

### Example

```bash
# Example: Approve agreement abc-123-def for investor 456
./scripts/approve-and-backfill-commissions.sh abc-123-def 456
```

### Expected Output

```
==============================================================================
Approve & Backfill Workflow
==============================================================================
Agreement ID: abc-123-def
Investor ID:  456

[1/3] Approving agreement...
✓ Agreement approved successfully
  Status: APPROVED

[2/3] Fetching contributions for investor...
✓ Found 10 contribution(s)
  Contribution IDs: [789, 790, 791, 792, 793, 794, 795, 796, 797, 798]

[3/3] Recomputing commissions...
✓ Successfully recomputed 10 commission(s)

==============================================================================
SUCCESS: Workflow completed
==============================================================================
Agreement:   abc-123-def → APPROVED
Investor:    456
Commissions: 10 created

Fetching sample commissions for verification...
  - Commission xyz-001: $500.00 (draft)
  - Commission xyz-002: $750.00 (draft)
  - Commission xyz-003: $1000.00 (draft)

Done!
```

### Error Handling

**Agreement Not Found:**
```
✗ Failed to approve agreement
  HTTP Code: 404
  Response: {"error": "Agreement not found"}
```

**No Contributions:**
```
⚠ No contributions found for this investor
✓ Agreement approved, but no commissions to recompute
```

**Batch Compute Failed:**
```
✗ Failed to recompute commissions
  HTTP Code: 400
  Response: {"error": "contribution_ids array is required"}
```

---

## Technical Details

### API Endpoints Used

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api-v1/agreements/:id/approve` | POST | Approve agreement (DRAFT → APPROVED) |
| `/api-v1/contributions?investor_id=X` | GET | Fetch all contributions for investor |
| `/api-v1/commissions/batch-compute` | POST | Compute commissions for multiple contributions |
| `/api-v1/commissions?investor_id=X` | GET | Verify created commissions |

### Agreement Approval Logic

```typescript
// Backend: supabase/functions/api-v1/index.ts
async function handleAgreementApprove(supabase, userId, id) {
  // Check user has manager or admin role
  const roles = await getUserRoles(supabase, userId);
  if (!hasAnyRole(roles, ['manager', 'admin'])) {
    return forbiddenError('Requires manager or admin role');
  }

  // Update agreement status
  const { data, error } = await supabase
    .from('agreements')
    .update({
      status: 'APPROVED',
      approved_at: new Date().toISOString(),
      approved_by: userId,
    })
    .eq('id', id)
    .eq('status', 'AWAITING_APPROVAL')  // Only from AWAITING_APPROVAL
    .select('status')
    .single();

  // Create immutable snapshot
  await createAgreementSnapshot(supabase, id);

  return { status: 'APPROVED' };
}
```

### Commission Compute Logic

```typescript
// Backend: supabase/functions/api-v1/commissionCompute.ts
export async function computeCommissionForContribution({
  supabase,
  contributionId,
}) {
  // 1. Load contribution details
  const contribution = await loadContribution(supabase, contributionId);

  // 2. Resolve distributor via investor.introduced_by_party_id
  const party = await resolveParty(supabase, contribution.investor_id);

  // 3. Find APPROVED agreement (investor-level preferred)
  const agreement = await resolveAgreement(supabase, {
    investor_id: contribution.investor_id,
    party_id: party.id,
    effective_date: contribution.transaction_date,
  });

  if (!agreement) {
    return { error: 'No approved agreement found' };
  }

  // 4. Compute base commission
  const baseAmount = contribution.amount * (agreement.upfront_bps / 10000);

  // 5. Compute VAT
  const vatAmount = agreement.vat_included
    ? 0
    : baseAmount * agreement.vat_rate;

  const totalAmount = baseAmount + vatAmount;

  // 6. UPSERT commission with snapshot
  const { data: commission } = await supabase
    .from('commissions')
    .upsert({
      party_id: party.id,
      investor_id: contribution.investor_id,
      contribution_id: contribution.id,
      base_amount: baseAmount,
      vat_amount: vatAmount,
      total_amount: totalAmount,
      status: 'draft',
      snapshot_json: {
        agreement_id: agreement.id,
        terms: agreement.terms,
        vat_rate: agreement.vat_rate,
        // ... immutable snapshot
      },
      computed_at: new Date(),
    }, {
      onConflict: 'contribution_id,party_id',  // Idempotent
    })
    .select()
    .single();

  return { commission };
}
```

### Batch Compute Logic

```typescript
// Backend: supabase/functions/api-v1/commissionCompute.ts
export async function batchComputeCommissions({
  supabase,
  contributionIds,
}) {
  const results = [];

  for (const contributionId of contributionIds) {
    try {
      const result = await computeCommissionForContribution({
        supabase,
        contributionId,
      });

      results.push({
        contribution_id: contributionId,
        success: !result.error,
        commission_id: result.commission?.id,
        error: result.error,
      });
    } catch (error) {
      results.push({
        contribution_id: contributionId,
        success: false,
        error: error.message,
      });
    }
  }

  return { results };
}
```

---

## Acceptance Checks

### ✅ Manual Testing Checklist

#### Test 1: Assign Distributor (No Prior Contributions)
- [ ] Navigate to investor with 0 contributions
- [ ] Click "Edit Source" → Select Distributor → Save
- [ ] Verify dialog appears
- [ ] Verify "Recompute Past Commissions" button is NOT shown
- [ ] Click "Approve Agreement"
- [ ] Verify toast: "Agreement Approved"
- [ ] Verify Active Agreements section shows APPROVED status

#### Test 2: Assign Distributor (With Prior Contributions)
- [ ] Navigate to investor with 5+ contributions
- [ ] Click "Edit Source" → Select Distributor → Save
- [ ] Verify dialog shows: "This investor has N contribution(s) that can be recomputed"
- [ ] Click "Approve Agreement"
- [ ] Verify agreement status → APPROVED
- [ ] Click "Recompute Past Commissions"
- [ ] Verify toast: "Successfully recomputed N commission(s)"
- [ ] Verify Commissions section shows new commissions
- [ ] Verify dialog closes automatically

#### Test 3: Skip Approval
- [ ] Assign distributor
- [ ] Dialog appears
- [ ] Click "Skip for Now"
- [ ] Verify toast: "Agreement is in DRAFT status..."
- [ ] Verify Active Agreements shows NO agreements (DRAFT not shown)
- [ ] Navigate to agreements admin panel
- [ ] Verify agreement exists with DRAFT status

#### Test 4: CLI Workflow
```bash
# Get agreement ID and investor ID from UI or database
AGREEMENT_ID="..." # From Active Agreements section or DB
INVESTOR_ID="..."  # From investor detail page

# Run script
./scripts/approve-and-backfill-commissions.sh $AGREEMENT_ID $INVESTOR_ID

# Verify output shows success
# Verify database shows APPROVED status
# Verify commissions table has new rows
```

#### Test 5: Error Handling - No Contributions
```bash
# Run with investor that has no contributions
./scripts/approve-and-backfill-commissions.sh $AGREEMENT_ID $EMPTY_INVESTOR_ID

# Expected: "No contributions found" warning
# Expected: Agreement still approved
# Expected: No error code
```

#### Test 6: Error Handling - Invalid Agreement
```bash
# Run with invalid agreement ID
./scripts/approve-and-backfill-commissions.sh "invalid-id" $INVESTOR_ID

# Expected: 404 error
# Expected: Clear error message
# Expected: Exit code 1
```

---

## Troubleshooting

### Issue: Dialog Doesn't Appear After Assigning Distributor

**Possible Causes:**
1. Agreement was not actually created (check browser console for errors)
2. Agreement already exists for this investor + party combination
3. Source type is not "Distributor" (e.g., "Referrer" won't trigger dialog)

**Solution:**
- Check browser console for errors
- Check database: `SELECT * FROM agreements WHERE investor_id = X AND party_id = Y`
- Verify source_kind is 'DISTRIBUTOR'

---

### Issue: "Approve Agreement" Button Does Nothing

**Possible Causes:**
1. User doesn't have manager or admin role
2. Agreement is not in AWAITING_APPROVAL status
3. Network error

**Solution:**
- Check user roles: `SELECT * FROM user_roles WHERE user_id = auth.uid()`
- Check agreement status: `SELECT status FROM agreements WHERE id = X`
- Check browser network tab for error response

---

### Issue: Commissions Not Created After Recompute

**Possible Causes:**
1. Agreement is not APPROVED
2. Contribution dates are outside agreement effective range
3. No approved agreement found for contribution date

**Solution:**
- Verify agreement status is APPROVED
- Check agreement effective dates vs contribution dates
- Check backend logs for compute errors
- Run single compute first: `POST /commissions/compute` with one contribution_id

---

### Issue: CLI Script Fails with "jq: command not found"

**Solution:**
```bash
# Install jq on macOS
brew install jq

# Install jq on Ubuntu/Debian
sudo apt-get install jq

# Install jq on Windows (via Chocolatey)
choco install jq
```

---

### Issue: CLI Script Returns 403 Forbidden

**Possible Causes:**
1. Token is expired
2. Token doesn't have sufficient permissions
3. Using anon key instead of service role key

**Solution:**
```bash
# Use service role key (for internal scripts)
export SUPABASE_TOKEN="your-service-role-key"

# OR use user JWT (for user-context operations)
# 1. Login to app
# 2. Open browser console
# 3. Run: localStorage.getItem('supabase.auth.token')
# 4. Copy JWT from result
export SUPABASE_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

---

## Best Practices

### For UI Users

1. **Always approve immediately if possible** - This unblocks commission calculations for future contributions
2. **Use "Skip for Now" sparingly** - Only when you need to review terms or coordinate with finance
3. **Verify agreement terms in Active Agreements** section after approval
4. **Check Commissions section** after backfill to verify counts match expectations

### For Operations Team

1. **Use CLI for bulk operations** - More efficient than UI for multiple investors
2. **Always verify contribution count** before running script
3. **Check agreement terms first** - Ensure rate is correct before approving
4. **Run in dry-run mode first** (if implemented) to preview changes
5. **Keep logs** of all CLI executions for audit trail

### For Developers

1. **Monitor agreement creation errors** in browser console
2. **Check Supabase edge function logs** for backend errors
3. **Validate agreement snapshot JSON** after approval
4. **Ensure idempotency** - batch-compute can be run multiple times safely
5. **Add integration tests** for end-to-end workflow

---

## Future Enhancements

### Short-term
- [ ] Add "Dry Run" mode to CLI script to preview changes
- [ ] Add progress bar for large batch computes (100+ contributions)
- [ ] Email notification to finance team when agreements approved
- [ ] Audit log entry for all approve + backfill operations

### Long-term
- [ ] Scheduled automatic approval for agreements meeting criteria
- [ ] Bulk distributor assignment from Investors list (select multiple → assign)
- [ ] Agreement templates for different commission structures
- [ ] Real-time progress indicator during batch compute

---

## Related Documentation

- [Session Documentation](./SESSION-2025-11-11-INVESTOR-DETAIL-AGREEMENTS.md) - Full implementation details
- [Commission Computation Engine](./COMMISSION-COMPUTE-ENGINE.md) - Deep dive on calculation logic
- [Agreement Management](./AGREEMENT-MANAGEMENT.md) - Agreement lifecycle and workflows
- [API Reference](./QUICK-REFERENCE.md) - All API endpoints and parameters

---

**Document Version**: 1.0
**Last Updated**: November 11, 2025
**Maintained By**: Development Team
