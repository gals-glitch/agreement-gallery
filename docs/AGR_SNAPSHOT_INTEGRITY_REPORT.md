# Agreement Snapshot Integrity Verification Report
## v1.8.0 - Investor Fee Workflow E2E

**Date:** 2025-10-21
**Ticket:** AGR-01, AGR-02
**Status:** Complete

---

## Executive Summary

This report provides comprehensive verification tools for agreement snapshot integrity in the Investor Fee Workflow system. Agreement snapshots are immutable records created when agreements are approved, capturing pricing configuration (upfront/deferred BPS, VAT rates) required for charge computation.

### Critical Dependencies

The charge computation engine (`chargeCompute.ts`) relies on the `agreement_rate_snapshots` table to:

1. Calculate base fees: `contribution_amount × (upfront_bps + deferred_bps) / 10000`
2. Apply VAT based on party country and `vat_rate_percent`
3. Generate immutable `charges.snapshot_json` for audit trails

**If snapshots are missing or incomplete, charge computation will fail with "No approved agreement found" errors.**

### Deliverables

1. **Health Check Queries** (`AGR_HEALTH_CHECK_QUERIES.sql`): 7 diagnostic queries to detect missing/invalid snapshots
2. **Fix Scripts** (`AGR_FIX_SCRIPTS.sql`): 6 repair scripts for common data integrity issues
3. **Deployment Procedure** (this document): Step-by-step guide for running health checks
4. **API Endpoint Specification** (Optional): REST API for automated health checks

---

## Architecture Overview

### Data Model

```
agreements (party × fund/deal pricing configuration)
├── id (BIGINT)
├── party_id (BIGINT) → parties.id
├── scope (agreement_scope: FUND | DEAL)
├── fund_id / deal_id (BIGINT, XOR constraint)
├── pricing_mode (pricing_mode: TRACK | CUSTOM)
├── selected_track (track_code: A | B | C)
├── effective_from / effective_to (DATE)
├── vat_included (BOOLEAN)
└── status (agreement_status: DRAFT | AWAITING_APPROVAL | APPROVED | SUPERSEDED)

agreement_rate_snapshots (immutable snapshots created on approval)
├── id (BIGSERIAL)
├── agreement_id (BIGINT) → agreements.id (UNIQUE)
├── scope (agreement_scope)
├── pricing_mode (pricing_mode)
├── track_code (track_code)
├── resolved_upfront_bps (INT, required) ← Fee calculation input
├── resolved_deferred_bps (INT, required) ← Fee calculation input
├── vat_included (BOOLEAN)
├── vat_rate_percent (NUMERIC(5,2), 0-100) ← VAT calculation input
├── vat_policy (TEXT: EXCLUSIVE | INCLUSIVE | EXEMPT)
├── effective_from / effective_to (DATE)
├── seed_version (INT, for TRACK mode)
├── approved_at (TIMESTAMPTZ)
├── snapshotted_at (TIMESTAMPTZ)
└── tiers / caps / discounts (JSONB, future use)

charges (computed fees on contributions)
├── snapshot_json (JSONB) ← Built from agreement_rate_snapshots
└── ... (other fields)
```

### Snapshot Creation Trigger

When `agreements.status` transitions to `'APPROVED'`, the `snapshot_rates_on_approval()` trigger:

1. Resolves pricing:
   - **TRACK mode**: Looks up `fund_tracks` for selected track (`upfront_bps`, `deferred_bps`, `seed_version`)
   - **CUSTOM mode**: Reads `agreement_custom_terms` (`upfront_bps`, `deferred_bps`)
2. Resolves VAT rate:
   - Looks up `vat_rates` by party's country code and effective date
   - Returns `rate_percentage` (0-100) or NULL if not found
3. Inserts immutable snapshot into `agreement_rate_snapshots`
4. Fails approval if pricing resolution fails (exception raised)

**Key Insight:** The trigger is the **only** source of snapshots. Manual status updates or trigger failures leave agreements without snapshots.

---

## Issue Types and Severity

| Issue Type                    | Severity | Impact                                    | Expected Count |
|-------------------------------|----------|-------------------------------------------|----------------|
| `MISSING_SNAPSHOT`            | CRITICAL | Charge computation fails (no agreement)   | 0              |
| `MISSING_UPFRONT_BPS`         | CRITICAL | Fee calculation fails (NULL value)        | 0              |
| `MISSING_DEFERRED_BPS`        | CRITICAL | Fee calculation fails (NULL value)        | 0              |
| `INVALID_UPFRONT_BPS`         | HIGH     | Negative fees (data corruption)           | 0              |
| `INVALID_DEFERRED_BPS`        | HIGH     | Negative fees (data corruption)           | 0              |
| `INVALID_VAT_RATE_NEGATIVE`   | HIGH     | Invalid VAT calculation                   | 0              |
| `INVALID_VAT_RATE_EXCEEDS_100`| HIGH     | Invalid VAT calculation                   | 0              |
| `OVERLAPPING_WINDOWS`         | MEDIUM   | Ambiguous agreement precedence            | 0              |
| `MISSING_VAT_RATE`            | LOW      | May be acceptable (VAT-exempt parties)    | Some (US, etc) |

### Severity Definitions

- **CRITICAL**: Blocks charge computation → immediate revenue impact → fix within 24h
- **HIGH**: Produces incorrect charges → financial/legal risk → fix within 48h
- **MEDIUM**: May cause confusion → operational risk → fix within 1 week
- **LOW**: Informational → review case-by-case → no immediate action required

---

## Health Check Procedure

### Frequency

Run health checks:

1. **Before each investor import batch** (pre-deployment validation)
2. **After approval workflow changes** (post-deployment smoke test)
3. **Weekly data quality audits** (Monday morning check)
4. **After database migrations** (schema change verification)

### Step-by-Step Guide

#### Step 1: Run Combined Health Check Summary (QUERY 6)

**Purpose:** Quick overview of all issues across all APPROVED agreements.

**Location:** `docs/AGR_HEALTH_CHECK_QUERIES.sql` → QUERY 6

**Execution:**

```sql
-- Copy QUERY 6 from AGR_HEALTH_CHECK_QUERIES.sql and run in Supabase SQL Editor
```

**Expected Output:**

```
| issue_type        | count | affected_agreement_ids |
|-------------------|-------|------------------------|
| MISSING_VAT_RATE  | 3     | {12, 15, 18}           |
```

**Interpretation:**

- **count = 0 for all issues**: ✅ **PASS** - System healthy, no action required
- **count > 0 for CRITICAL/HIGH issues**: ❌ **FAIL** - Proceed to Step 2
- **count > 0 for MISSING_VAT_RATE only**: ⚠️ **WARNING** - Review case-by-case (may be acceptable)

#### Step 2: Diagnose Critical Issues (QUERY 1-3)

If Step 1 shows critical issues, run detailed diagnostic queries:

**QUERY 1: Missing Snapshots**

```sql
-- Finds APPROVED agreements with no snapshot record
-- Run from AGR_HEALTH_CHECK_QUERIES.sql
```

Expected: 0 rows
If rows found: Trigger malfunction → use **FIX SCRIPT 1** (Create Missing Snapshots)

**QUERY 2: Missing Required Fields**

```sql
-- Finds snapshots with NULL upfront_bps or deferred_bps
-- Run from AGR_HEALTH_CHECK_QUERIES.sql
```

Expected: 0 rows
If rows found: Incomplete snapshot creation → use **FIX SCRIPT 2** (Update Incomplete Snapshots)

**QUERY 3: Invalid Values**

```sql
-- Finds snapshots with negative BPS or out-of-range VAT rates
-- Run from AGR_HEALTH_CHECK_QUERIES.sql
```

Expected: 0 rows
If rows found: Data corruption → use **FIX SCRIPT 3** or **FIX SCRIPT 5** (Correct Invalid Values)

#### Step 3: Fix Issues (AGR_FIX_SCRIPTS.sql)

For each issue found in Step 2:

1. Locate corresponding fix script in `AGR_FIX_SCRIPTS.sql`
2. **Review Step 1 (Preview)** to verify affected agreements
3. **Replace `<agreement_id>` placeholder** with actual agreement ID from health check
4. **Execute fix script** (UPDATE or INSERT statement)
5. **Run Step 3 (Verify)** to confirm fix

**Example Workflow:**

```sql
-- Issue: Agreement 42 has MISSING_UPFRONT_BPS

-- 1. Preview (from FIX SCRIPT 2, Step 1)
SELECT ... WHERE ars.agreement_id = 42;

-- 2. Review output - confirm new_upfront_bps is correct (e.g., 100)

-- 3. Execute fix (from FIX SCRIPT 2, Step 2)
UPDATE agreement_rate_snapshots ars
SET resolved_upfront_bps = ...
WHERE ars.agreement_id = 42;

-- 4. Verify fix (from FIX SCRIPT 2, Step 3)
SELECT ... WHERE ars.agreement_id = 42;
-- Expected: resolved_upfront_bps = 100 (non-NULL)
```

#### Step 4: Re-run Health Check (Verification)

After applying all fixes:

```sql
-- Re-run QUERY 6 (Combined Health Check Summary)
```

Expected: **count = 0 for all critical issues**

If issues persist: Escalate to database team (may indicate schema corruption)

#### Step 5: Review Warnings (QUERY 4, 5)

**QUERY 4: Missing VAT Rates**

Review each party with NULL VAT rate:

- **UK/EU parties (GB, DE, FR, etc.)**: Should have VAT rate → use **FIX SCRIPT 4** (Add Missing VAT Rate)
- **US parties**: VAT-exempt → NULL is acceptable, or set to 0.00 with vat_policy='EXEMPT'
- **Other countries**: Check local tax regulations

**QUERY 5: Overlapping Windows**

Review overlapping agreements:

- **Different scopes (FUND vs DEAL)**: Acceptable - deal-level takes precedence (per `chargeCompute.ts` logic)
- **Same scope, same party**: Potential ambiguity - define tie-break rule or prevent overlaps
- **Action**: Document business rule or add validation to prevent overlaps

#### Step 6: Document Results

Record health check results in deployment notes:

```markdown
## Agreement Snapshot Health Check - 2025-10-21

**Environment:** Production
**Run By:** [Your Name]
**Status:** PASS ✅

**Summary:**
- Total APPROVED agreements: 47
- Critical issues: 0
- Warnings: 3 (MISSING_VAT_RATE for US parties)

**Action Taken:**
- Reviewed 3 US parties (IDs: 12, 15, 18)
- Confirmed VAT-exempt status (no fix required)

**Next Check:** 2025-10-28 (weekly audit)
```

---

## Fix Script Reference

### FIX SCRIPT 1: Create Missing Snapshots

**Use Case:** APPROVED agreements without snapshots (trigger malfunction)

**How It Works:**
1. Resolves pricing from current `fund_tracks` or `agreement_custom_terms`
2. Looks up VAT rate from party's country
3. Inserts new snapshot with current timestamp

**When to Use:**
- Health check QUERY 1 shows rows
- Agreement approved via manual status update (bypassed trigger)
- Post-migration data recovery

**Safety:**
- Uses `<agreement_id>` placeholder to prevent mass inserts
- Preview step (Step 1) shows pricing before insert

**Example:**

```sql
-- Preview pricing resolution
SELECT ... WHERE a.id = 42;

-- Insert missing snapshot
INSERT INTO agreement_rate_snapshots (...)
SELECT ... WHERE a.id = 42;

-- Verify
SELECT * FROM agreement_rate_snapshots WHERE agreement_id = 42;
```

### FIX SCRIPT 2: Update Incomplete Snapshots

**Use Case:** Snapshots with NULL `resolved_upfront_bps` or `resolved_deferred_bps`

**How It Works:**
1. Uses `COALESCE()` to preserve existing non-NULL values
2. Resolves missing BPS from current pricing sources
3. Updates snapshot in-place

**When to Use:**
- Health check QUERY 2 shows rows
- Snapshot created but pricing resolution failed
- Missing `agreement_custom_terms` or invalid track reference

**Safety:**
- Only updates NULL fields (preserves existing data)
- `<agreement_id>` placeholder prevents mass updates

### FIX SCRIPT 3: Correct Invalid BPS Values

**Use Case:** Negative BPS values (data corruption)

**Options:**
- **Option A**: Clamp to 0 (assume 0% fee intended)
- **Option B**: Set to specific correct value (if known from contract)

**When to Use:**
- Health check QUERY 3 shows negative BPS
- Manual data entry error detected
- Database constraint bypass incident

### FIX SCRIPT 4: Add Missing VAT Rate

**Use Case:** Snapshots with NULL `vat_rate_percent`

**Options:**
- **Option A**: Auto-lookup from `vat_rates` table by party's country
- **Option B**: Set to specific VAT rate (e.g., 20.00 for UK)
- **Option C**: Set to 0.00 for VAT-exempt parties (e.g., US)

**When to Use:**
- Health check QUERY 4 shows rows for VAT-applicable countries (UK, EU)
- Party's country missing from `vat_rates` table
- VAT configuration corrected after approval

### FIX SCRIPT 5: Correct Invalid VAT Rates

**Use Case:** VAT rates < 0 or > 100 (out of range)

**Options:**
- **Option A**: Clamp to 0-100 range
- **Option B**: Set to correct VAT rate (from official tax authority data)

**When to Use:**
- Health check QUERY 3 shows invalid VAT rates
- Data validation bypass detected

### FIX SCRIPT 6: Manual Snapshot Configuration

**Use Case:** When automatic resolution fails (missing data sources)

**How It Works:**
- Manually constructs complete snapshot with known correct values
- Uses `INSERT ... ON CONFLICT DO UPDATE` for idempotent execution

**When to Use:**
- All other fix scripts fail (pricing sources unavailable)
- Historical data reconstruction
- One-off data migration corrections

**Example:**

```sql
-- Configure Agreement 6 with known pricing (from v1.7.0)
INSERT INTO agreement_rate_snapshots (
  agreement_id, scope, pricing_mode, track_code,
  resolved_upfront_bps, resolved_deferred_bps,
  vat_rate_percent, vat_policy, ...
)
VALUES (
  6, 'FUND', 'TRACK', 'A',
  100, 0,  -- 1% upfront, 0% deferred
  20.00, 'EXCLUSIVE', ...
)
ON CONFLICT (agreement_id) DO UPDATE ...;
```

---

## Expected Issues and Resolutions

Based on system evolution and v1.7.0 experience, common issues:

### Issue 1: Agreements Approved Before Snapshot Feature (Pre-v1.5.0)

**Symptoms:**
- `MISSING_SNAPSHOT` for older agreements
- Agreement created before migration `20251019100003_vat_and_snapshots.sql`

**Root Cause:**
- Snapshot trigger added in v1.5.0
- Legacy agreements approved before trigger existed

**Resolution:**
- Use **FIX SCRIPT 1** to create missing snapshots
- Verify pricing from historical records (contracts, emails)
- If pricing unknown, use **FIX SCRIPT 6** (Manual Configuration)

**Prevention:**
- One-time backfill script (run after snapshot migration)
- Add database check constraint: `status='APPROVED' → snapshot must exist`

### Issue 2: Missing Custom Terms (CUSTOM Pricing Mode)

**Symptoms:**
- `MISSING_UPFRONT_BPS` or `MISSING_DEFERRED_BPS`
- Agreement uses `pricing_mode='CUSTOM'` but no `agreement_custom_terms` row

**Root Cause:**
- Custom terms deleted or never created
- Data integrity issue (foreign key not enforced)

**Resolution:**
- Use **FIX SCRIPT 2** if custom terms can be recovered from other sources
- If not, use **FIX SCRIPT 6** to manually configure pricing
- Contact stakeholder for correct pricing (check signed contract)

**Prevention:**
- Add database constraint: `pricing_mode='CUSTOM' → custom_terms must exist`
- Enforce in UI workflow (cannot approve without custom terms)

### Issue 3: Invalid Track Reference (TRACK Pricing Mode)

**Symptoms:**
- `MISSING_UPFRONT_BPS` or `MISSING_DEFERRED_BPS`
- Agreement uses `pricing_mode='TRACK'` but `selected_track` not in `fund_tracks`

**Root Cause:**
- Track code changed or deleted after agreement created
- Agreement references non-existent track (A/B/C)

**Resolution:**
- Use **FIX SCRIPT 2** if correct track can be determined
- Query `fund_tracks` for available tracks: `SELECT * FROM fund_tracks WHERE fund_id = X;`
- Update `agreements.selected_track` to valid code, then re-run trigger

**Prevention:**
- Add database constraint: `selected_track` must exist in `fund_tracks`
- Prevent track deletion if referenced by approved agreements

### Issue 4: Multiple Agreements with Overlapping Dates (Same Party)

**Symptoms:**
- `OVERLAPPING_WINDOWS` in health check QUERY 5
- Two APPROVED agreements for same party with overlapping `effective_from/to`

**Root Cause:**
- Amendment workflow creates new agreement without superseding old one
- Business rule: "latest agreement wins" not enforced

**Resolution:**
- **Option A (Business Rule)**: Define precedence - latest agreement, shortest duration, or most specific scope
- **Option B (Data Fix)**: Set `effective_to` on old agreement to end before new agreement starts
- **Option C (Status Change)**: Mark old agreement as `SUPERSEDED` status

**Example Fix:**

```sql
-- Supersede old agreement (mark as SUPERSEDED)
UPDATE agreements
SET status = 'SUPERSEDED'
WHERE id = <old_agreement_id>;

-- Or: Adjust effective_to to end before new agreement
UPDATE agreements
SET effective_to = DATE '2025-06-30'
WHERE id = <old_agreement_id>;
-- (Assuming new agreement starts 2025-07-01)
```

**Prevention:**
- Add validation in approval workflow: Check for overlaps before approving
- Automatically supersede old agreements when approving amendments

### Issue 5: Missing VAT Rates for New Countries

**Symptoms:**
- `MISSING_VAT_RATE` for parties in countries not in `vat_rates` table
- New country added to system without VAT configuration

**Root Cause:**
- Party's country not seeded in `vat_rates` table
- VAT rate unknown for new jurisdiction

**Resolution:**
- Research country's VAT/GST rate (official tax authority website)
- Insert into `vat_rates` table:

```sql
-- Example: Add VAT rate for Germany (19%)
INSERT INTO vat_rates (country_code, rate_percentage, effective_from, description)
VALUES ('DE', 19.00, DATE '2007-01-01', 'Germany Standard VAT rate (19%)');
```

- Re-run **FIX SCRIPT 4** to populate snapshots

**Prevention:**
- Maintain master list of VAT rates for all supported countries
- Add validation: Cannot create party without country having VAT rate

---

## Deployment Integration

### Pre-Deployment Checklist

Before deploying investor import batch:

1. ✅ Run health check QUERY 6 (Combined Summary)
2. ✅ Verify count = 0 for critical issues
3. ✅ Review and resolve any warnings (MISSING_VAT_RATE, OVERLAPPING_WINDOWS)
4. ✅ Document health check results in deployment notes

### Post-Deployment Smoke Test

After deploying new agreements:

1. ✅ Re-run health check QUERY 6
2. ✅ Compare before/after counts (should be equal or improved)
3. ✅ Test charge computation for new agreements:

```sql
-- Test charge computation for new agreement
SELECT
  a.id,
  ars.resolved_upfront_bps,
  ars.resolved_deferred_bps,
  ars.vat_rate_percent
FROM agreements a
LEFT JOIN agreement_rate_snapshots ars ON a.id = ars.agreement_id
WHERE a.id = <new_agreement_id>;

-- Expected: Non-NULL BPS values, valid VAT rate
```

4. ✅ Call charge compute API for sample contribution:

```bash
curl -X POST https://your-api.com/api/v1/charges/compute \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"contribution_id": "<test_contribution_id>"}'

# Expected: HTTP 200, charge created with snapshot_json
```

### Rollback Procedure

If health check fails after deployment:

1. **STOP**: Do not proceed with charge computation
2. **Identify**: Run diagnostic queries (QUERY 1-5) to find root cause
3. **Fix**: Apply appropriate fix script from `AGR_FIX_SCRIPTS.sql`
4. **Verify**: Re-run health check QUERY 6
5. **Resume**: Only proceed when count = 0 for critical issues

---

## API Endpoint Specification (Optional - AGR-02)

### Endpoint: GET /admin/agreements/health-check

**Purpose:** Automated health check for integration with admin dashboard or CI/CD pipeline.

**RBAC:** Admin only (requires `role_key = 'admin'`)

**Request:**

```http
GET /api/v1/admin/agreements/health-check
Authorization: Bearer <admin_token>
```

**Response (Success):**

```json
{
  "status": "healthy",
  "timestamp": "2025-10-21T10:30:00Z",
  "summary": {
    "total_approved_agreements": 47,
    "critical_issues": 0,
    "warnings": 3
  },
  "issues": [
    {
      "type": "MISSING_VAT_RATE",
      "severity": "LOW",
      "count": 3,
      "affected_agreement_ids": [12, 15, 18],
      "description": "Snapshots missing VAT rate (may be acceptable for VAT-exempt parties)"
    }
  ]
}
```

**Response (Critical Issues Found):**

```json
{
  "status": "unhealthy",
  "timestamp": "2025-10-21T10:30:00Z",
  "summary": {
    "total_approved_agreements": 47,
    "critical_issues": 2,
    "warnings": 3
  },
  "issues": [
    {
      "type": "MISSING_SNAPSHOT",
      "severity": "CRITICAL",
      "count": 1,
      "affected_agreement_ids": [42],
      "description": "APPROVED agreements without snapshots (charge computation will fail)"
    },
    {
      "type": "MISSING_UPFRONT_BPS",
      "severity": "CRITICAL",
      "count": 1,
      "affected_agreement_ids": [43],
      "description": "Snapshots missing required pricing fields (fee calculation will fail)"
    },
    {
      "type": "MISSING_VAT_RATE",
      "severity": "LOW",
      "count": 3,
      "affected_agreement_ids": [12, 15, 18],
      "description": "Snapshots missing VAT rate (may be acceptable for VAT-exempt parties)"
    }
  ]
}
```

**Implementation Guide:**

1. Create new endpoint in `supabase/functions/api-v1/admin.ts`
2. Query same logic as QUERY 6 (Combined Health Check Summary)
3. Map SQL results to JSON response format
4. Include severity levels and descriptions
5. Add RBAC check: `hasRequiredRoles(req, supabase, ['admin'])`

**Sample Implementation (Pseudocode):**

```typescript
// File: supabase/functions/api-v1/admin.ts

export async function handleHealthCheck(
  req: Request,
  supabase: SupabaseClient,
  userId: string,
  corsHeaders: Record<string, string>
): Promise<Response> {
  // RBAC: Admin only
  const roles = await getUserRoles(supabase, userId);
  if (!hasAnyRole(roles, ['admin'])) {
    return forbiddenError('Requires Admin role', corsHeaders);
  }

  // Run health check queries (same as QUERY 6)
  const { data: issues } = await supabase.rpc('get_agreement_health_check');

  // Map to response format
  const summary = {
    total_approved_agreements: await countApprovedAgreements(supabase),
    critical_issues: issues.filter(i => i.severity === 'CRITICAL').length,
    warnings: issues.filter(i => i.severity === 'LOW').length,
  };

  const status = summary.critical_issues === 0 ? 'healthy' : 'unhealthy';

  return successResponse({
    status,
    timestamp: new Date().toISOString(),
    summary,
    issues: issues.map(i => ({
      type: i.issue_type,
      severity: getSeverity(i.issue_type),
      count: i.count,
      affected_agreement_ids: i.affected_agreement_ids,
      description: getDescription(i.issue_type),
    })),
  }, 200, corsHeaders);
}
```

**Database Function (Optional Optimization):**

```sql
-- File: supabase/migrations/20251021000000_health_check_function.sql

CREATE OR REPLACE FUNCTION get_agreement_health_check()
RETURNS TABLE (
  issue_type TEXT,
  count BIGINT,
  affected_agreement_ids BIGINT[]
) AS $$
BEGIN
  -- Same logic as QUERY 6 (Combined Health Check Summary)
  -- Returns aggregated issue counts and affected IDs
  RETURN QUERY
  WITH missing_snapshots AS (...),
       missing_fields AS (...),
       invalid_values AS (...),
       missing_vat AS (...),
       overlapping_windows AS (...),
       all_issues AS (...)
  SELECT
    issue_type,
    COUNT(*) AS count,
    ARRAY_AGG(agreement_id ORDER BY agreement_id) AS affected_agreement_ids
  FROM all_issues
  GROUP BY issue_type;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Admin Dashboard Integration:**

Add health check widget to admin dashboard:

```typescript
// Frontend: components/AdminDashboard.tsx

const HealthCheckWidget = () => {
  const { data, isLoading } = useQuery(['health-check'], async () => {
    const res = await fetch('/api/v1/admin/agreements/health-check', {
      headers: { Authorization: `Bearer ${token}` },
    });
    return res.json();
  });

  return (
    <Card>
      <CardHeader>
        <CardTitle>Agreement Snapshot Health</CardTitle>
      </CardHeader>
      <CardContent>
        {data?.status === 'healthy' ? (
          <Alert variant="success">
            ✅ All APPROVED agreements have valid snapshots
          </Alert>
        ) : (
          <Alert variant="destructive">
            ❌ {data?.summary.critical_issues} critical issues found
            <Button onClick={() => navigate('/admin/health-check')}>
              View Details
            </Button>
          </Alert>
        )}
      </CardContent>
    </Card>
  );
};
```

---

## Troubleshooting Guide

### Scenario 1: "No approved agreement found" error during charge computation

**Error Message:**

```json
{
  "error": {
    "code": "COMPUTE_ERROR",
    "message": "No approved agreement found for this contribution"
  }
}
```

**Diagnosis Steps:**

1. Identify contribution's investor and fund/deal:

```sql
SELECT
  c.id,
  c.investor_id,
  c.fund_id,
  c.deal_id,
  c.paid_in_date,
  c.amount
FROM contributions c
WHERE c.id = <contribution_id>;
```

2. Check for APPROVED agreements:

```sql
SELECT
  a.id,
  a.party_id,
  a.scope,
  a.status,
  a.effective_from,
  a.effective_to
FROM agreements a
WHERE a.party_id = <investor_id>
  AND (
    (a.fund_id = <fund_id> AND a.scope = 'FUND')
    OR
    (a.deal_id = <deal_id> AND a.scope = 'DEAL')
  )
ORDER BY a.id DESC;
```

3. If agreements exist but status ≠ 'APPROVED':
   - **Action**: Approve agreement via workflow
   - **Trigger**: Snapshot will be created automatically

4. If agreements exist and status = 'APPROVED', check snapshot:

```sql
SELECT
  ars.*
FROM agreement_rate_snapshots ars
WHERE ars.agreement_id = <agreement_id>;
```

5. If snapshot missing:
   - **Action**: Use **FIX SCRIPT 1** (Create Missing Snapshot)

6. If snapshot incomplete (NULL BPS):
   - **Action**: Use **FIX SCRIPT 2** (Update Incomplete Snapshot)

### Scenario 2: Charge computed with $0.00 total (should be non-zero)

**Error Message:** None (charge created successfully, but total_amount = 0)

**Diagnosis Steps:**

1. Fetch charge snapshot:

```sql
SELECT
  c.id,
  c.base_amount,
  c.discount_amount,
  c.vat_amount,
  c.total_amount,
  c.snapshot_json
FROM charges c
WHERE c.id = <charge_id>;
```

2. Check `snapshot_json.computed_rules`:

```json
{
  "computed_rules": {
    "is_gp": true,  // ← Investor flagged as GP (excluded from fees)
    "rate_pct": 1.0,
    "discounts": [],
    "cap": null
  }
}
```

3. If `is_gp = true`:
   - **Reason**: GP investors are excluded from fees (business rule)
   - **Action**: Verify investor should be GP - check `investors.is_gp` flag

4. If `is_gp = false` and `rate_pct = 0`:
   - **Reason**: Agreement has 0% fee rate (upfront_bps = 0, deferred_bps = 0)
   - **Action**: Check agreement snapshot BPS values:

```sql
SELECT
  ars.resolved_upfront_bps,
  ars.resolved_deferred_bps
FROM agreement_rate_snapshots ars
WHERE ars.agreement_id = (
  SELECT (c.snapshot_json->>'agreement_id')::BIGINT
  FROM charges c
  WHERE c.id = <charge_id>
);
```

5. If BPS values are 0:
   - **Verify**: Is this correct per contract? (Some investors may have 0% fees)
   - **If incorrect**: Use **FIX SCRIPT 3** to correct BPS values, then recompute charge

### Scenario 3: Health check fails after migration

**Symptoms:** QUERY 6 shows multiple critical issues after running database migration

**Diagnosis Steps:**

1. Check migration log for errors:

```bash
# In Supabase dashboard: Database → Migrations → View log
```

2. Identify failed migration:
   - Look for `ERROR` or `ROLLBACK` in log
   - Check if `snapshot_rates_on_approval` trigger was recreated

3. Verify trigger exists and is active:

```sql
SELECT
  tgname AS trigger_name,
  tgtype AS trigger_type,
  tgenabled AS enabled,
  pg_get_triggerdef(oid) AS definition
FROM pg_trigger
WHERE tgname = 'snapshot_rates_on_approval';
```

Expected: 1 row, `enabled = 'O'` (enabled)

4. If trigger missing or disabled:
   - **Action**: Re-run migration `20251019100003_vat_and_snapshots.sql`
   - **Or**: Manually recreate trigger (see migration file)

5. If trigger exists but snapshots still missing:
   - **Action**: Batch create missing snapshots using **FIX SCRIPT 1** with loop:

```sql
-- Batch create missing snapshots for all APPROVED agreements
INSERT INTO agreement_rate_snapshots (...)
SELECT ...
FROM agreements a
WHERE a.status = 'APPROVED'
  AND NOT EXISTS (
    SELECT 1 FROM agreement_rate_snapshots ars
    WHERE ars.agreement_id = a.id
  );
```

---

## Appendix A: SQL Query Quick Reference

### Quick Health Check (1-Liner)

```sql
-- Count APPROVED agreements without snapshots (should be 0)
SELECT COUNT(*)
FROM agreements a
WHERE a.status = 'APPROVED'
  AND NOT EXISTS (
    SELECT 1 FROM agreement_rate_snapshots ars
    WHERE ars.agreement_id = a.id
  );
```

### List All APPROVED Agreements with Snapshot Status

```sql
SELECT
  a.id,
  a.party_id,
  a.status,
  CASE
    WHEN ars.id IS NULL THEN 'MISSING'
    WHEN ars.resolved_upfront_bps IS NULL OR ars.resolved_deferred_bps IS NULL THEN 'INCOMPLETE'
    ELSE 'OK'
  END AS snapshot_status
FROM agreements a
LEFT JOIN agreement_rate_snapshots ars ON a.id = ars.agreement_id
WHERE a.status = 'APPROVED'
ORDER BY a.id;
```

### Find Agreement for Contribution (Diagnostic)

```sql
-- Reproduces chargeCompute.ts logic for agreement resolution
WITH contribution_info AS (
  SELECT
    c.id,
    c.investor_id,
    c.fund_id,
    c.deal_id,
    c.paid_in_date
  FROM contributions c
  WHERE c.id = <contribution_id>
)
SELECT
  a.id AS agreement_id,
  a.scope,
  a.pricing_mode,
  a.status,
  ars.resolved_upfront_bps,
  ars.resolved_deferred_bps,
  ars.vat_rate_percent
FROM contribution_info ci
LEFT JOIN agreements a ON a.party_id = ci.investor_id
  AND (
    (a.deal_id = ci.deal_id AND a.scope = 'DEAL')
    OR
    (a.fund_id = ci.fund_id AND a.scope = 'FUND')
  )
LEFT JOIN agreement_rate_snapshots ars ON ars.agreement_id = a.id
WHERE a.status = 'APPROVED'
ORDER BY a.scope DESC, a.id DESC  -- DEAL takes precedence over FUND
LIMIT 1;

-- Expected: 1 row with complete snapshot data
-- If 0 rows: No approved agreement for this contribution
-- If NULL BPS: Snapshot incomplete (use fix scripts)
```

---

## Appendix B: Testing Checklist

### Unit Test: Health Check Queries

Test data setup:

```sql
-- Create test party
INSERT INTO parties (id, name, country) VALUES (9999, 'Test Party', 'GB');

-- Create test agreement (APPROVED, missing snapshot)
INSERT INTO agreements (id, party_id, scope, fund_id, pricing_mode, selected_track, effective_from, status)
VALUES (9999, 9999, 'FUND', 1, 'TRACK', 'A', '2025-01-01', 'APPROVED');

-- Run QUERY 1 (Missing Snapshots)
-- Expected: 1 row (agreement_id = 9999)

-- Create snapshot with missing BPS
INSERT INTO agreement_rate_snapshots (agreement_id, scope, pricing_mode, resolved_upfront_bps, resolved_deferred_bps, approved_at)
VALUES (9999, 'FUND', 'TRACK', NULL, 0, now());

-- Run QUERY 2 (Missing Required Fields)
-- Expected: 1 row (agreement_id = 9999, issue_type = MISSING_UPFRONT_BPS)

-- Cleanup
DELETE FROM agreement_rate_snapshots WHERE agreement_id = 9999;
DELETE FROM agreements WHERE id = 9999;
DELETE FROM parties WHERE id = 9999;
```

### Integration Test: Charge Computation with Fixed Snapshot

```sql
-- 1. Create test agreement with snapshot
-- (Use FIX SCRIPT 6 example)

-- 2. Create test contribution
INSERT INTO contributions (investor_id, fund_id, amount, paid_in_date, currency, status)
VALUES (9999, 1, 50000.00, '2025-10-20', 'USD', 'DRAFT');

-- 3. Call charge compute API
-- (Via API client or curl)

-- 4. Verify charge created
SELECT
  c.id,
  c.base_amount,
  c.total_amount,
  c.snapshot_json->>'agreement_id' AS agreement_id
FROM charges c
WHERE c.contribution_id = (SELECT id FROM contributions WHERE investor_id = 9999);

-- Expected: base_amount = 500.00 (50000 × 1%), total_amount = 600.00 (with VAT)

-- 5. Cleanup
DELETE FROM charges WHERE contribution_id = (SELECT id FROM contributions WHERE investor_id = 9999);
DELETE FROM contributions WHERE investor_id = 9999;
DELETE FROM agreement_rate_snapshots WHERE agreement_id = 9999;
DELETE FROM agreements WHERE id = 9999;
DELETE FROM parties WHERE id = 9999;
```

---

## Appendix C: Related Documentation

- **Charge Computation Logic**: `supabase/functions/api-v1/chargeCompute.ts`
- **Charges API**: `supabase/functions/api-v1/charges.ts`
- **Agreement Schema**: `supabase/migrations/20251016000004_redesign_04_agreements.sql`
- **VAT & Snapshots Migration**: `supabase/migrations/20251019100003_vat_and_snapshots.sql`
- **Charges Schema**: `supabase/migrations/20251019130000_charges_FIXED.sql`
- **v1.7.0 Testing Notes**: `TEST_CHARGE_WORKFLOW.sql` (if exists)

---

## Changelog

| Date       | Version | Changes                                                                 |
|------------|---------|-------------------------------------------------------------------------|
| 2025-10-21 | 1.0.0   | Initial release - Health check queries and fix scripts created         |

---

**Report End**
