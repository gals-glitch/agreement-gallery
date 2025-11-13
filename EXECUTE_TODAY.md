# Vantage ETL - Execute Today Checklist

## Time Required: ~30 minutes

**Goal:** Complete Vantage sync pipeline and deploy to production

---

## ✅ COMPLETED

- [x] Investors sync (2,097 records)
- [x] Deduplication (22 pairs merged)
- [x] Admin UI component created
- [x] Documentation written

---

## 🚀 TO DO TODAY

### Task 1: Add Deals Unique Constraint (2 min)

```powershell
powershell -Command "Get-Content 'add_deals_unique_constraint.sql' | Set-Clipboard"
```

1. Open SQL Editor: https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys/sql/new
2. Paste and run
3. Verify: Should return 0 duplicate rows, then add constraint successfully

**Expected:** `deals_external_id_unique` constraint created

---

### Task 2: Run Full Funds Sync (5 min)

```powershell
powershell -ExecutionPolicy Bypass -File sync_funds_full.ps1
```

**Expected Output:**
```json
{
  "success": true,
  "results": {
    "funds": {
      "status": "success",
      "recordsProcessed": X,
      "recordsCreated": X,
      "errors": []
    }
  }
}
```

**Verify:**
```powershell
powershell -Command "Get-Content 'verify_funds_sync.sql' | Set-Clipboard"
```

Paste in SQL Editor and run. Check counts match.

---

### Task 3: Test Incremental Funds Sync (2 min)

```powershell
powershell -ExecutionPolicy Bypass -File sync_funds_incremental.ps1
```

**Expected:**
- `records_updated`: 0 (no changes since full sync)
- `records_created`: 0
- `success`: true

---

### Task 4: Set Up Daily Cron Job (3 min)

```powershell
powershell -Command "Get-Content 'setup_daily_cron.sql' | Set-Clipboard"
```

1. Paste in SQL Editor and run
2. Verify cron job created:

```sql
SELECT * FROM cron.job WHERE jobname = 'vantage-daily-sync';
```

**Should return:** 1 row with `active = true`, schedule = '0 0 * * *'

**Optional test:**
```sql
SELECT public.run_vantage_incremental();
```

Check `vantage_sync_state` for new entry.

---

### Task 5: Run Hardening Checks (2 min)

```powershell
powershell -Command "Get-Content 'hardening_checks.sql' | Set-Clipboard"
```

Paste in SQL Editor and run.

**Expected:** All checks show **PASS** status

- Check A: 0 missing external_ids → PASS
- Check B1: 0 duplicate investor external_ids → PASS
- Check B2: 0 duplicate deals external_ids → PASS
- Check C: All resources 'success' status → PASS
- Check D: 22 merged DISTRIBUTOR investors → PASS
- Check E: Both UNIQUE constraints exist → PASS

---

### Task 6: Add Admin UI Route (5 min)

Find your routes file (likely `App.tsx` or `src/routes.tsx`) and add:

```typescript
import AdminSync from './pages/AdminSync';

// In your routes array:
{
  path: '/admin/sync',
  element: <ProtectedRoute requiredRoles={['admin']}><AdminSync /></ProtectedRoute>
}
```

**Test:**
1. Navigate to http://localhost:8080/admin/sync
2. Should see "Vantage IR Sync" dashboard
3. Click "Sync Now (Incremental)"
4. Verify sync executes and history updates

---

### Task 7: Final Verification (5 min)

Run these queries to confirm everything is working:

```sql
-- Investors count
SELECT
  COALESCE(source_kind::text, 'NULL') AS source_kind,
  COUNT(*) AS count
FROM public.investors
GROUP BY source_kind;
-- Expected: vantage: 2,097, DISTRIBUTOR: 19

-- Funds count
SELECT COUNT(*) AS total_funds
FROM public.deals
WHERE external_id IS NOT NULL;
-- Expected: Match Vantage total

-- Sync state
SELECT resource, last_sync_status, records_synced, completed_at
FROM public.vantage_sync_state
ORDER BY completed_at DESC
LIMIT 5;
-- Expected: All 'success' status

-- Cron job
SELECT jobname, schedule, active
FROM cron.job
WHERE jobname = 'vantage-daily-sync';
-- Expected: 1 active job
```

---

## 📋 Sign-Off Checklist

After completing all tasks above, verify:

- [ ] Deals unique constraint in place
- [ ] Full funds sync completed successfully (X funds)
- [ ] Incremental funds sync tested (0 updates as expected)
- [ ] Daily cron job configured and active
- [ ] All hardening checks return PASS
- [ ] Admin UI accessible at `/admin/sync`
- [ ] Can trigger manual sync from Admin UI
- [ ] Sync history displays correctly

---

## 🎯 Success Criteria

When complete, you should have:

1. **2,097 Vantage investors** synced and active
2. **19 DISTRIBUTOR investors** active (22 merged)
3. **X Vantage funds** synced to deals table
4. **Daily cron job** running at 00:00 UTC
5. **Admin UI** for manual sync triggers
6. **Zero duplicate** external_ids
7. **All hardening checks** passing

---

## 📁 Files Created Today

### SQL Files
- `add_deals_unique_constraint.sql`
- `verify_funds_sync.sql`
- `setup_daily_cron.sql`
- `hardening_checks.sql`

### PowerShell Scripts
- `sync_funds_full.ps1`
- `sync_funds_incremental.ps1`

### React Components
- `src/pages/AdminSync.tsx`

### Documentation
- `VANTAGE_ETL_DEPLOYMENT.md` - Full deployment guide
- `EXECUTE_TODAY.md` - This checklist

---

## 🆘 If Something Goes Wrong

### Funds Sync Fails

Check Edge Function logs:
```bash
supabase functions logs vantage-sync
```

### Cron Job Not Running

```sql
SELECT * FROM cron.job WHERE jobname = 'vantage-daily-sync';
```

If missing, re-run `setup_daily_cron.sql`

### Admin UI Not Working

1. Check route is added
2. Verify user has 'admin' role
3. Check browser console for errors

### Still Stuck?

1. Check `vantage_sync_state` table for error messages
2. Review Edge Function logs
3. Re-run hardening checks to identify issue

---

## ⏱️ Estimated Timeline

- Task 1 (Constraint): 2 min
- Task 2 (Full Sync): 5 min
- Task 3 (Incremental): 2 min
- Task 4 (Cron): 3 min
- Task 5 (Checks): 2 min
- Task 6 (UI Route): 5 min
- Task 7 (Verification): 5 min

**Total: ~25 minutes**

---

## 🎉 When Done

You'll have a fully operational Vantage ETL pipeline:

- ✅ Automated daily syncs
- ✅ Admin dashboard for manual triggers
- ✅ 2,097 investors + X funds synced
- ✅ Zero duplicates
- ✅ Full audit trail
- ✅ Production-ready monitoring

**Ready to ship!** 🚀

---

**Start with Task 1 now!**
