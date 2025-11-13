# ✅ Vantage Sync Deployment - READY TO EXECUTE

**Status:** All scripts and documentation prepared
**Date:** November 6, 2025
**Components:** 7-step deployment checklist complete

---

## Quick Start

Run the master deployment script:

```powershell
powershell -ExecutionPolicy Bypass -File EXECUTE_VANTAGE_DEPLOYMENT.ps1
```

This interactive script will guide you through all 7 steps with prompts and validation.

---

## What's Been Prepared

### ✅ Scripts Created

**Step 1: Lock Funds Upserts**
- `step1_check_deals_duplicates.sql` - Check for duplicate external_ids
- `step1_add_deals_constraint.sql` - Add unique constraint
- `step1_check_and_add_constraint.ps1` - Automated execution

**Step 2: Run Funds Sync**
- `step2_run_funds_sync.ps1` - Full + incremental sync
- `step2_verify_funds.ps1` - Verification queries

**Step 5: Daily Cron Job**
- `step5_setup_daily_cron.sql` - Cron configuration (⚠️ edit service key first!)

**Step 6: Hardening Checks**
- `step6_hardening_checks.sql` - Comprehensive A-F checks

### ✅ UI Component Ready

**Admin Sync Dashboard:**
- Location: `src/pages/AdminSync.tsx` ✅ Created
- Route: `/admin/sync` ✅ Configured in App.tsx
- Protection: Admin-only + `vantage_sync` feature flag ✅

### ✅ Documentation Updated

- `VANTAGE_ETL_DEPLOYMENT.md` - Complete deployment guide
- `EXECUTE_VANTAGE_DEPLOYMENT.ps1` - Master orchestration script
- `VANTAGE_DEPLOYMENT_READY.md` - This file

---

## The 7 Steps

### 1. Lock funds upserts (unique deals.external_id)

Pre-check for duplicates, then add constraint.

**Files:** `step1_*.sql`

### 2. Run the Funds sync (full, then incremental)

Full backfill followed by sanity incremental check.

**Files:** `step2_run_funds_sync.ps1`, `step2_verify_funds.ps1`

### 3. Gate everything behind a feature flag

Create `vantage_sync` flag (initially disabled).

**SQL:**
```sql
INSERT INTO public.feature_flags (flag_key, description, is_active)
VALUES ('vantage_sync', 'Enable Vantage IR synchronization', false)
ON CONFLICT (flag_key) DO UPDATE SET description = EXCLUDED.description;
```

### 4. Ship Admin Sync Dashboard

✅ Already created at `src/pages/AdminSync.tsx`
✅ Already routed at `/admin/sync` with protection

### 5. Schedule daily incremental sync

⚠️ **IMPORTANT:** Edit `step5_setup_daily_cron.sql` first!
Replace `YOUR_SERVICE_ROLE_KEY_HERE` with actual service role key.

Then run in SQL Editor. Creates cron job for 00:00 UTC daily.

**File:** `step5_setup_daily_cron.sql`

### 6. Run hardening checks

Validates all components A-F. Must all return PASS.

**File:** `step6_hardening_checks.sql`

### 7. Documentation

✅ Complete. See `VANTAGE_ETL_DEPLOYMENT.md`

---

## Pre-Execution Checklist

Before running `EXECUTE_VANTAGE_DEPLOYMENT.ps1`:

- [ ] `.env` file has `SUPABASE_SERVICE_ROLE_KEY` and `SUPABASE_URL`
- [ ] Vantage Edge Function is deployed and working
- [ ] Database has `vantage_sync_state` table
- [ ] You have admin access to Supabase SQL Editor
- [ ] You've edited `step5_setup_daily_cron.sql` with service key
- [ ] You've reviewed rollback procedures

---

## Execution Order

**Option A: Automated (Recommended)**
```powershell
powershell -ExecutionPolicy Bypass -File EXECUTE_VANTAGE_DEPLOYMENT.ps1
```

**Option B: Manual**
1. Run `step1_check_and_add_constraint.ps1`
2. Run `step2_run_funds_sync.ps1`
3. Create feature flag (SQL in Step 3)
4. Verify Admin UI route (already done)
5. Run `step5_setup_daily_cron.sql` in SQL Editor
6. Run `step6_hardening_checks.sql` in SQL Editor
7. Review documentation

---

## Post-Execution

After all steps pass:

1. **Enable the feature flag:**
   ```sql
   UPDATE public.feature_flags SET is_active = true WHERE flag_key = 'vantage_sync';
   ```

2. **Add nav link** to Admin menu:
   ```typescript
   { label: "Vantage Sync", path: "/admin/sync", icon: Database, role: "admin" }
   ```

3. **Test the UI:**
   - Navigate to `/admin/sync`
   - Click "Sync Now (Incremental)"
   - Verify history displays

4. **Monitor first automated sync:**
   - Wait until 00:00 UTC next day
   - Check `vantage_sync_state` table
   - Verify status = 'success'

---

## Verification Queries

**Check constraint exists:**
```sql
SELECT conname FROM pg_constraint WHERE conname = 'deals_external_id_unique';
```

**Check funds synced:**
```sql
SELECT COUNT(*) FROM public.deals WHERE external_id IS NOT NULL;
```

**Check cron job active:**
```sql
SELECT * FROM cron.job WHERE jobname = 'vantage-daily-sync';
```

**Check feature flag:**
```sql
SELECT * FROM public.feature_flags WHERE flag_key = 'vantage_sync';
```

**Check recent syncs:**
```sql
SELECT resource, last_sync_status, records_synced, completed_at
FROM public.vantage_sync_state
ORDER BY completed_at DESC
LIMIT 5;
```

---

## Rollback

If issues arise:

**Disable immediately:**
```sql
-- Stop cron
SELECT cron.unschedule('vantage-daily-sync');

-- Disable flag
UPDATE public.feature_flags SET is_active = false WHERE flag_key = 'vantage_sync';
```

**Full rollback procedures:** See `VANTAGE_ETL_DEPLOYMENT.md` § Rollback Procedures

---

## Support

**Files:**
- 📘 Full guide: `VANTAGE_ETL_DEPLOYMENT.md`
- 🚀 Master script: `EXECUTE_VANTAGE_DEPLOYMENT.ps1`
- 📋 Quick ref: `VANTAGE_QUICK_REFERENCE.txt`

**Troubleshooting:**
- Sync fails → Check Edge Function logs
- Cron not running → Verify `pg_cron` extension enabled
- Duplicates found → Review `DEDUP_GUIDE.md`

---

## Status

✅ **All components prepared**
✅ **Scripts created**
✅ **UI ready**
✅ **Documentation complete**

🚀 **Ready to execute!**

Run: `powershell -ExecutionPolicy Bypass -File EXECUTE_VANTAGE_DEPLOYMENT.ps1`
