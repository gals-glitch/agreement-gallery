# Vantage Sync - Quick Start Guide

## Current Status
✅ Environment configured
✅ Edge Function deployed
✅ Validation working (0 errors on 2,097 accounts)
⏳ Test sync in progress...

## Available Scripts

### 1. Diagnostics (Check Environment)
```powershell
powershell -ExecutionPolicy Bypass -File test_diagnostics.ps1
```
**Use this to:** Verify all environment variables are set correctly

---

### 2. Dry Run (Validation Only - No Database Writes)
```powershell
powershell -ExecutionPolicy Bypass -File quick_sync.ps1 -DryRun
```
**Use this to:**
- Test Vantage API connectivity
- Validate all 2,097 accounts
- Check for data quality issues
- **Does NOT write to database**

**Expected output:**
```
SUCCESS!
Status: success
Processed: 2097
Created: 0
Updated: 0
Errors: 0
Duration: ~7s
```

---

### 3. Full Sync (Production - Writes to Database)
```powershell
powershell -ExecutionPolicy Bypass -File quick_sync.ps1
```
**Use this to:**
- Sync all 2,097 accounts from Vantage to database
- Creates new investor records
- Updates existing records (idempotent via external_id)

**Expected output:**
```
SUCCESS!
Status: success
Processed: 2097
Created: 2097 (first run) or 0 (subsequent runs)
Updated: 0 (first run) or 2097 (subsequent runs)
Errors: 0
Duration: ~60-120s (estimated)
```

---

## What the Sync Does

### Data Flow
```
Vantage IR API
    ↓
Edge Function (vantage-sync)
    ↓
Validation & Transformation
    ↓
Database (entities + investors tables)
```

### Tables Updated

**1. `entities` table** (Party data)
- Created/updated for each Vantage account
- Uses `external_id` for idempotency
- Fields: name, tax_id, country

**2. `investors` table** (Investment data)
- Created/updated for each Vantage account
- Linked to entity via `party_entity_id`
- Fields: name, email, phone, address, investor_type, is_active, etc.

**3. `vantage_sync_state` table** (Sync tracking)
- One row per resource ('accounts', 'funds', etc.)
- Tracks: last_sync_time, status, records created/updated, errors, duration

---

## Verify Sync Success

### Check Investor Count
```sql
SELECT COUNT(*) FROM investors WHERE external_id IS NOT NULL;
-- Expected: 2097 after first sync
```

### Check Sync State
```sql
SELECT
  resource,
  last_sync_status,
  last_sync_time,
  records_created,
  records_updated,
  errors
FROM vantage_sync_state
WHERE resource = 'accounts';
```

### Check Recent Investors
```sql
SELECT
  name,
  email,
  phone,
  country,
  investor_type,
  external_id
FROM investors
WHERE external_id IS NOT NULL
ORDER BY created_at DESC
LIMIT 10;
```

---

## Troubleshooting

### Sync Taking Too Long?
- Expected duration: 60-120 seconds for full sync (2,097 records)
- Each record requires: validation → entity upsert → investor upsert
- Check Edge Function logs: https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys/functions

### Sync Failed?
1. Check diagnostics first:
   ```powershell
   powershell -ExecutionPolicy Bypass -File test_diagnostics.ps1
   ```

2. Check sync state for errors:
   ```sql
   SELECT errors FROM vantage_sync_state WHERE resource = 'accounts';
   ```

3. Check Edge Function logs in Supabase Dashboard

### Duplicate Records?
- The sync is idempotent - running it multiple times won't create duplicates
- Uses `external_id` (Vantage investor_id) as unique key
- First run: Creates records
- Subsequent runs: Updates existing records

---

## Next Steps After First Sync

### 1. Verify Data in UI
- Open your app
- Navigate to Investors page
- You should see 2,097 investors

### 2. Set Up Scheduled Sync (Optional)
- Daily sync to keep data fresh
- Cron schedule: `0 2 * * *` (runs at 02:00 UTC daily)
- Future Sprint 2 task

### 3. Add Frontend Admin UI (Optional)
- "Sync Now" button in Admin section
- Show last sync time and status
- Future Sprint 2 task

---

## Files Reference

| File | Purpose |
|------|---------|
| `test_diagnostics.ps1` | Verify environment configuration |
| `quick_sync.ps1` | Main sync script (dry-run or live) |
| `test_vantage_sync.ps1` | Interactive test with prompts |
| `run_full_sync.ps1` | Production sync with confirmation |
| `VANTAGE_SYNC_SUCCESS.md` | Complete implementation documentation |
| `SETUP_VANTAGE_ENV.md` | Environment setup guide |
| `QUICK_START.md` | This file |

---

## Support

**Edge Function Logs:**
https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys/functions

**Database Console:**
https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys/editor

**Test Sequence:**
1. `test_diagnostics.ps1` - Verify config
2. `quick_sync.ps1 -DryRun` - Validate data
3. `quick_sync.ps1` - Perform sync
4. SQL queries above - Verify results
