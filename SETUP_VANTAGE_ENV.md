# Set Up Vantage Environment Variables

## Problem Identified

The `vantage-sync` Edge Function is returning 500 errors because the Vantage API credentials are **missing from Supabase**.

## Diagnostic Results

```
✓ SUPABASE_URL: Set
✓ SUPABASE_SERVICE_ROLE_KEY: Set
✗ VANTAGE_API_BASE_URL: Missing
✗ VANTAGE_AUTH_TOKEN: Missing
✗ VANTAGE_CLIENT_ID: Missing
```

## Solution: Add Secrets to Supabase Dashboard

### Step 1: Open Supabase Dashboard

Go to: https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys/settings/functions

### Step 2: Add Each Secret

Click **"Add new secret"** and enter each of the following:

#### Secret 1: Vantage API Base URL
```
Name: VANTAGE_API_BASE_URL
Value: https://buligoirapi.insightportal.info
```

#### Secret 2: Vantage Auth Token
```
Name: VANTAGE_AUTH_TOKEN
Value: buligodata
```

#### Secret 3: Vantage Client ID
```
Name: VANTAGE_CLIENT_ID
Value: bexz40aUdxK5rQDSjS2BIUg==
```

### Step 3: Verify Configuration

After adding all three secrets, run:

```powershell
powershell -ExecutionPolicy Bypass -File test_diagnostics.ps1
```

You should see:
```
SUCCESS: All environment variables are configured!
```

### Step 4: Test the Sync Function

Once verification passes, run the full sync test:

```powershell
powershell -ExecutionPolicy Bypass -File test_vantage_sync.ps1
```

This will:
1. Run a dry-run validation (no DB writes)
2. Prompt you to run a small batch sync (10 accounts)

## Troubleshooting

### If secrets don't appear to update:
- Wait 1-2 minutes after adding secrets (Supabase may need time to propagate)
- Try re-deploying the function: `supabase functions deploy vantage-sync`

### If you get different errors after adding secrets:
- Check the Edge Function logs in Supabase Dashboard
- Verify the vantage_sync_state table exists:
  ```sql
  SELECT * FROM vantage_sync_state;
  ```

## Next Steps After Setup

1. ✅ Set environment variables (this document)
2. Test dry-run sync
3. Test small batch sync (10 records)
4. Run full sync for all 2,097 accounts
5. Implement frontend Admin UI
6. Set up scheduled automation

---

**Reference**: The environment variables are already in your local `.env` file, but Edge Functions run on Supabase's servers and need these secrets configured separately in the Dashboard.
