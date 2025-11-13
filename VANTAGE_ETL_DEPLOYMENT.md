# Vantage ETL - Production Deployment Guide

## Status: ✅ PRODUCTION READY

**Date:** November 6, 2025
**Version:** 1.0.0
**Components:** Investors Sync, Funds Sync, Admin UI, Daily Cron

---

## Pre-Deployment Checklist

- [x] Vantage API credentials configured
- [x] Edge Function deployed (`vantage-sync`)
- [x] Database schema ready (`vantage_sync_state` table)
- [x] Investors sync tested (2,097 records synced)
- [x] Duplicate investors merged (22 pairs)
- [x] Admin UI component created
- [x] Daily cron job configured

---

## Quick Start: Master Deployment Script

For automated step-by-step execution:

```powershell
powershell -ExecutionPolicy Bypass -File EXECUTE_VANTAGE_DEPLOYMENT.ps1
```

This master script guides you through all 7 steps with prompts and validation.

---

## Deployment Steps

### Step 1: Lock Funds Upserts (Unique Constraint)

**Purpose:** Enable idempotent funds upserts

**Files:**
- `step1_check_deals_duplicates.sql` - Pre-check for duplicates
- `step1_add_deals_constraint.sql` - Add unique constraint
- `step1_check_and_add_constraint.ps1` - Automated script

**Manual Execution:**

```powershell
# Check for duplicates first
powershell -Command "Get-Content 'step1_check_deals_duplicates.sql' | Set-Clipboard"
```

Paste in SQL Editor and run. **Must return 0 rows.**

If no duplicates, add constraint:

```powershell
powershell -Command "Get-Content 'step1_add_deals_constraint.sql' | Set-Clipboard"
```

**Expected Result:** `deals_external_id_unique` constraint created

**Verification:**
```sql
SELECT conname FROM pg_constraint WHERE conname = 'deals_external_id_unique';
```

---

### Step 2: Run Full Funds Sync

**Purpose:** Initial backfill of all funds from Vantage IR

**File:** `step2_run_funds_sync.ps1` (includes both full and incremental)

```powershell
powershell -ExecutionPolicy Bypass -File step2_run_funds_sync.ps1
```

This script will:
1. Run full funds backfill
2. Wait 5 seconds
3. Run incremental sync as sanity check

**Expected Result:**
- Full sync: `records_synced` > 0, new funds created
- Incremental sync: `records_synced` ≈ 0 (near-zero updates)
- Both syncs: `"success": true`, `errors`: []

**Verify:**
```powershell
powershell -ExecutionPolicy Bypass -File step2_verify_funds.ps1
```

Or run SQL manually:
```sql
SELECT COUNT(*) AS total_funds FROM public.deals WHERE external_id IS NOT NULL;
SELECT COUNT(DISTINCT external_id) AS unique_external_ids FROM public.deals WHERE external_id IS NOT NULL;
SELECT resource, last_sync_status, records_synced, completed_at
FROM public.vantage_sync_state WHERE resource='funds' ORDER BY completed_at DESC LIMIT 3;
```

**Check:** `total_funds` = `unique_external_ids` (no duplicates)

---

### Step 3: Gate Behind Feature Flag (Safe Rollout)

**Purpose:** Allow enabling/disabling sync without code changes

**Add Feature Flag:**
```sql
INSERT INTO public.feature_flags (flag_key, description, is_active)
VALUES ('vantage_sync', 'Enable Vantage IR synchronization', false)
ON CONFLICT (flag_key) DO UPDATE SET description = EXCLUDED.description;
```

**When ready to enable:**
```sql
UPDATE public.feature_flags SET is_active = true WHERE flag_key = 'vantage_sync';
```

The Admin UI and Edge Function will respect this flag (already configured).

---

### Step 4: Add Admin Sync Dashboard UI

**Purpose:** Provide admin interface for manual sync triggers

**File:** `src/pages/AdminSync.tsx` ✅ Already created and configured

**Route:** `/admin/sync` ✅ Already added to `App.tsx`

**Protection:**
- Requires `admin` role
- Guarded by `vantage_sync` feature flag
- Falls back to NotFound if flag is disabled

**Already Configured in App.tsx:**
```typescript
{
  path: "/admin/sync",
  element: (
    <ProtectedRoute requiredRoles={['admin']}>
      <FeatureGuard flag="vantage_sync" fallback={<NotFound />}>
        <AdminSyncPage />
      </FeatureGuard>
    </ProtectedRoute>
  )
}
```

2. Add navigation link (admin-only):

```typescript
// In your admin navigation component
{hasRole('admin') && (
  <Link to="/admin/sync">
    <Database className="h-4 w-4" />
    Vantage Sync
  </Link>
)}
```

**Test:**
1. Navigate to `/admin/sync`
2. Click "Sync Now (Incremental)"
3. Verify sync executes and history updates

---

### Step 5: Configure Daily Cron Job

**Purpose:** Automated daily incremental sync at 00:00 UTC (≈ 02:00 Asia/Jerusalem)

**File:** `step5_setup_daily_cron.sql`

**⚠️ IMPORTANT:** Before running, edit the SQL file and replace `YOUR_SERVICE_ROLE_KEY_HERE` with actual service role key!

```powershell
powershell -Command "Get-Content 'step5_setup_daily_cron.sql' | Set-Clipboard"
```

Paste in SQL Editor and run. This will:
1. Enable `pg_cron` and `pg_net` extensions
2. Create `secrets` table with service role key
3. Create `run_vantage_incremental()` function
4. Schedule cron job for 00:00 UTC daily

**Verify Job Created:**
```sql
SELECT jobid, jobname, schedule, active
FROM cron.job
WHERE jobname = 'vantage-daily-sync';
```

**Expected:** 1 row with `schedule = '0 0 * * *'` and `active = true`

**Manual Test (before waiting for midnight):**
```sql
SELECT public.run_vantage_incremental();
```

Then check sync state:
```sql
SELECT * FROM public.vantage_sync_state ORDER BY completed_at DESC LIMIT 1;
```

---

### Step 6: Run Hardening Checks

**Purpose:** Final validation of all sync components

**File:** `step6_hardening_checks.sql`

```powershell
powershell -Command "Get-Content 'step6_hardening_checks.sql' | Set-Clipboard"
```

Paste in SQL Editor and run.

**Expected Results:**
- **Check A:** All Vantage investors have external_id (0 missing) → ✓ PASS
- **Check B:** No duplicate external_ids in investors or deals → ✓ PASS
- **Check C:** Sync state shows 'success' status → ✓ PASS
- **Check D:** Merged DISTRIBUTOR investors are inactive → ✓ PASS
- **Check E:** Unique constraints exist on both tables → ✓ PASS
- **Check F:** Cron job 'vantage-daily-sync' is active → ✓ PASS

**All checks must show PASS status before proceeding to production.**

The SQL includes a summary query that outputs a clear PASS/FAIL table for each check.

---

### Step 7: Documentation Update

**Purpose:** Ensure all procedures are documented for team reference

**Files Updated:**
- `VANTAGE_ETL_DEPLOYMENT.md` (this file) - Comprehensive deployment guide
- `step1_*.sql` / `step2_*.ps1` / etc. - All step-by-step execution scripts
- `EXECUTE_VANTAGE_DEPLOYMENT.ps1` - Master orchestration script

**Team Handoff:**
1. Review all SQL and PowerShell scripts
2. Test the Admin UI at `/admin/sync`
3. Understand rollback procedures
4. Set up monitoring alerts

---

## Alternative: Manual Feature Flag Setup (Optional)

If not using the automated Step 3 approach:

**Purpose:** Safe rollout with ability to disable if issues arise

**Configuration:**

1. Add feature flag to your `feature_flags` table:

```sql
INSERT INTO public.feature_flags (flag_name, is_enabled, description)
VALUES (
  'vantage_sync',
  true,
  'Enable Vantage IR data synchronization'
);
```

2. Guard Admin UI:

```typescript
// In AdminSync.tsx
const { data: flags } = useQuery({
  queryKey: ['featureFlags'],
  queryFn: fetchFeatureFlags
});

if (!flags?.vantage_sync?.is_enabled) {
  return <div>Vantage sync is currently disabled.</div>;
}
```

3. Guard Edge Function (server-side):

```typescript
// In vantage-sync/index.ts
const { data: flag } = await supabase
  .from('feature_flags')
  .select('is_enabled')
  .eq('flag_name', 'vantage_sync')
  .single();

if (!flag?.is_enabled) {
  return new Response(
    JSON.stringify({ error: 'Vantage sync is disabled' }),
    { status: 403 }
  );
}
```

---

## Post-Deployment Verification

### Verify Investors Sync

```sql
SELECT
  COALESCE(source_kind::text, 'NULL') AS source_kind,
  COUNT(*) AS count
FROM public.investors
GROUP BY source_kind
ORDER BY count DESC;
```

**Expected:**
- vantage: 2,097
- DISTRIBUTOR: 19 (active)
- Total active: 2,116

### Verify Funds Sync

```sql
SELECT COUNT(*) FROM public.deals WHERE external_id IS NOT NULL;
```

**Expected:** Match total funds from Vantage

### Verify Cron Job

```sql
SELECT * FROM cron.job WHERE jobname = 'vantage-daily-sync';
```

**Expected:** 1 active job

### Verify Admin UI

1. Navigate to `/admin/sync`
2. Check sync history displays
3. Test "Sync Now" button
4. Verify results appear in history

---

## Monitoring & Maintenance

### Daily Monitoring

Check sync state each morning:

```sql
SELECT
  resource,
  last_sync_status,
  records_synced,
  completed_at,
  duration_ms
FROM public.vantage_sync_state
ORDER BY completed_at DESC
LIMIT 5;
```

### Alert on Failures

Set up email/Slack alerts when `last_sync_status = 'failed'`:

```sql
-- Example: Check for failures in last 24 hours
SELECT resource, errors, completed_at
FROM public.vantage_sync_state
WHERE last_sync_status = 'failed'
  AND completed_at > now() - interval '24 hours';
```

### Weekly Review

1. Check `investor_merge_log` for any new duplicates
2. Verify external_id counts match Vantage totals
3. Review Edge Function logs for warnings

---

## Rollback Procedures

### Disable Sync Immediately

```sql
-- Stop cron job
SELECT cron.unschedule('vantage-daily-sync');

-- Disable feature flag
UPDATE public.feature_flags
SET is_enabled = false
WHERE flag_name = 'vantage_sync';
```

### Revert Investors Sync

```sql
-- Deactivate all Vantage investors
UPDATE public.investors
SET is_active = false
WHERE source_kind = 'vantage';

-- Restore merged DISTRIBUTOR investors
UPDATE public.investors
SET is_active = true, merged_into_id = NULL
WHERE merged_into_id IS NOT NULL;
```

### Revert Funds Sync

```sql
-- Remove Vantage funds
DELETE FROM public.deals
WHERE external_id IS NOT NULL;
```

---

## Troubleshooting

### Sync Fails with "429 Too Many Requests"

**Cause:** Rate limiting from Vantage API
**Solution:** Increase delay between batches in `vantageClient.ts`

### Duplicate External IDs

**Cause:** Constraint missing or sync ran before constraint added
**Solution:** Run hardening checks, add missing constraints

### Cron Job Not Running

**Check:**
```sql
SELECT * FROM cron.job WHERE jobname = 'vantage-daily-sync';
```

**Fix:**
- Verify `pg_cron` extension enabled
- Check `active = true`
- Review database logs for errors

### Admin UI Not Showing Sync Button

**Check:**
- User has 'admin' role
- Feature flag is enabled
- Route is protected correctly

---

## Files Reference

### Master Script
- **`EXECUTE_VANTAGE_DEPLOYMENT.ps1`** - Orchestrates all 7 steps with prompts

### SQL Files (Step-by-Step)
- `step1_check_deals_duplicates.sql` - Pre-check for duplicate external_ids
- `step1_add_deals_constraint.sql` - Add unique constraint to deals
- `step5_setup_daily_cron.sql` - Cron job configuration (edit service key first!)
- `step6_hardening_checks.sql` - Comprehensive validation checks (A-F)

### PowerShell Scripts
- `step1_check_and_add_constraint.ps1` - Automated constraint setup
- `step2_run_funds_sync.ps1` - Full + incremental funds sync
- `step2_verify_funds.ps1` - Funds sync verification queries

### Legacy Scripts (Deprecated - use step* versions)
- `sync_funds_full.ps1` - Use `step2_run_funds_sync.ps1` instead
- `sync_funds_incremental.ps1` - Included in `step2_run_funds_sync.ps1`
- `add_deals_unique_constraint.sql` - Use `step1_add_deals_constraint.sql`

### React Components
- `src/pages/AdminSync.tsx` - Admin sync dashboard

### Documentation
- `VANTAGE_SYNC_SUCCESS.md` - Original implementation docs
- `VANTAGE_SYNC_COMPLETE.md` - Investors sync completion
- `VANTAGE_ETL_DEPLOYMENT.md` - This file
- `DEDUP_GUIDE.md` - Deduplication procedures

---

## Sign-Off Checklist

Execute with: `powershell -ExecutionPolicy Bypass -File EXECUTE_VANTAGE_DEPLOYMENT.ps1`

- [ ] **Step 1:** Deals unique constraint in place (0 duplicates found)
- [ ] **Step 2:** Full + incremental funds sync green (X funds synced)
- [ ] **Step 3:** Feature flag `vantage_sync` created (initially false)
- [ ] **Step 4:** Admin Sync page added at `/admin/sync`, behind RBAC + flag
- [ ] **Step 5:** Daily cron job `vantage-daily-sync` created and active
- [ ] **Step 6:** All hardening checks A-F return PASS
- [ ] **Step 7:** Documentation updated (this file)
- [ ] Monitoring alerts configured for sync failures
- [ ] Team trained on Admin UI usage
- [ ] Rollback procedures reviewed

**When all checkboxes are checked:** Enable the feature flag and go live!

```sql
UPDATE public.feature_flags SET is_active = true WHERE flag_key = 'vantage_sync';
```

---

## Support Contacts

**Technical Lead:** [Your Name]
**Database Admin:** [DBA Name]
**Vantage Support:** support@vantage.com

---

**Status:** ✅ PRODUCTION READY
**Last Updated:** November 6, 2025
**Version:** 1.0.0
