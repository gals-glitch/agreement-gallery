# Vantage Sync Implementation - Fix Documentation

**Date**: 2025-11-06
**Status**: Complete - Ready for Testing

## Executive Summary

Successfully implemented and debugged the Vantage IR API integration for syncing investor accounts and funds (deals) into the Buligo Capital platform.

### Final Results

✅ **Accounts (Investors)**: 2,097 records synced successfully
🟡 **Funds (Deals)**: 32/290 records synced (remaining require schema constraint fix)

---

## Issues Encountered and Solutions

### 1. Authentication Issue: Bearer Token Prefix

**Problem**:
Initial implementation added "Bearer" prefix to the Authorization header based on Swagger API documentation, which caused 401 Unauthorized errors.

**Root Cause**:
Vantage IR API uses a custom authentication scheme where the token is sent directly in the Authorization header WITHOUT the "Bearer" prefix.

**Incorrect** (caused 401):
```typescript
'Authorization': `Bearer ${this.authToken}`
```

**Correct**:
```typescript
'Authorization': this.authToken  // Raw token only
```

**Evidence**:
Working Swagger curl command shows:
```bash
curl -X GET "https://buligoirapi.insightportal.info/api/AccountContactMap/Get" \
  -H "Authorization: buligodata " \
  -H "X-com-vantageir-subscriptions-clientid: bexz40aUdxK5rQDSjS2BIUg=="
```

**Files Modified**:
- `supabase/functions/_shared/vantageClient.ts` (line 50)
- `test_vantage_auth.ps1` (line 37)

---

### 2. Date Validation Issue: ISO Timestamps

**Problem**:
All 290 funds failed validation with errors like:
```
Invalid inception_date format: 2012-12-21T00:00:00
Invalid exitdate format: 2018-09-17T00:00:00
```

**Root Cause**:
The `parseVantageDate()` function expected 8-digit format (`yyyyMMdd` = `20121221`), but Vantage API returns ISO 8601 timestamps (`2012-12-21T00:00:00`).

**Solution**:
Updated `parseVantageDate()` to handle multiple date formats:
1. ISO 8601 with timestamp: `2012-12-21T00:00:00`
2. ISO 8601 date only: `2012-12-21`
3. Vantage yyyyMMdd format: `20121221`

**Code Changes** (`supabase/functions/_shared/vantageMappers.ts`, lines 711-742):
```typescript
export function parseVantageDate(dateString: string | undefined): Date | null {
  if (!dateString) return null;
  const trimmed = dateString.trim();

  // Try ISO 8601 formats first (with or without timestamp)
  if (trimmed.includes('-')) {
    const date = new Date(trimmed);
    if (!isNaN(date.getTime())) {
      return date;
    }
  }

  // Try Vantage yyyyMMdd format (8 digits, no separators)
  const digits = trimmed.replace(/\D/g, '');
  if (digits.length === 8) {
    const year = parseInt(digits.substring(0, 4), 10);
    const month = parseInt(digits.substring(4, 6), 10) - 1;
    const day = parseInt(digits.substring(6, 8), 10);
    const date = new Date(year, month, day);
    if (!isNaN(date.getTime())) {
      return date;
    }
  }

  return null;
}
```

**Result**: Date validation now passes for all 290 funds

---

### 3. Schema Mismatch: Missing `code` Column

**Problem**:
All 290 funds failed with database error:
```
Could not find the 'code' column of 'deals' in the schema cache
```

**Root Cause**:
The `FundInsert` interface and `mapVantageFundToFund()` function were trying to insert a `code` column that doesn't exist in the `deals` table.

**Actual deals table columns**:
```
id, fund_id, name, address, status, close_date, partner_company_id,
fund_group_id, sector, year_built, units, sqft, income_producing,
exclude_gp_from_commission, equity_to_raise, raised_so_far,
created_at, updated_at, external_id
```

**Solution**:
Removed `code`, `is_active`, and `metadata` fields from the mapper to match actual schema.

**Before** (`vantageMappers.ts`, lines 37-42):
```typescript
export interface FundInsert {
  name: string;
  code: string;              // ❌ Doesn't exist
  fund_id: string;
  close_date?: string | null;
  is_active?: boolean;        // ❌ Should be 'status'
  metadata?: Record<string, unknown> | null;  // ❌ Not in schema
}
```

**After**:
```typescript
export interface FundInsert {
  name: string;
  fund_id: string;
  status?: string | null;     // ✅ Matches deals.status
  close_date?: string | null;
}
```

**Mapper Function** (`vantageMappers.ts`, lines 248-269):
```typescript
export function mapVantageFundToFund(
  fund: VantageFund,
  fundId: string
): FundInsert {
  const name = fund.fundname?.trim() || 'Unknown Fund';
  const status = fund.status?.trim() || null;
  const closeDate = fund.exitdate ? parseVantageDateToISO(fund.exitdate) : null;

  return {
    name,
    fund_id: fundId,
    status,
    close_date: closeDate,
  };
}
```

**Result**: Fund mapping now succeeds, 32 funds inserted

---

### 4. Database Constraint: Duplicate Fund Names

**Problem**:
After fixing schema mismatch, 32 funds succeeded but remaining 258 funds failed with:
```
duplicate key value violates unique constraint "deals_name_key"
```

**Root Cause**:
- The `deals` table has a unique constraint on the `name` column
- Vantage has multiple funds with the same name but different `fund_id` values
- Example: Multiple funds named "Unknown Fund" or same property names in different states

**Solution**:
Remove the unique constraint on `deals.name` since `external_id` is the proper unique identifier for Vantage imports.

**SQL Fix** (`remove_deals_name_constraint.sql`):
```sql
ALTER TABLE public.deals
DROP CONSTRAINT IF EXISTS deals_name_key;
```

**Rationale**:
- `name` is not a unique business identifier (same property can exist in multiple deals)
- `external_id` stores the Vantage `fund_id` and is the correct unique key
- Step 1 of deployment already adds unique constraint on `external_id`

**Status**: SQL created, ready to execute

---

## Summary of Code Changes

### Files Modified

1. **`supabase/functions/_shared/vantageClient.ts`**
   - Line 42-43: Updated comments to clarify NO Bearer prefix
   - Line 50: Removed `Bearer` prefix from Authorization header

2. **`supabase/functions/_shared/vantageMappers.ts`**
   - Lines 37-42: Updated `FundInsert` interface to match database schema
   - Lines 248-269: Simplified `mapVantageFundToFund()` to only return existing columns
   - Lines 711-742: Enhanced `parseVantageDate()` to handle ISO timestamps

3. **`test_vantage_auth.ps1`**
   - Line 37: Removed `Bearer` prefix for direct API testing

### Files Created

1. **`remove_deals_name_constraint.sql`**
   - Removes unique constraint on `deals.name` column

2. **`test_vantage_auth.ps1`** (enhanced)
   - Tests direct Vantage API connection with correct auth format

3. **`test_edge_function.ps1`**
   - Tests Edge Function with detailed error response parsing

4. **`update_vantage_credentials.ps1`**
   - Script to easily update credentials when they expire/rotate

5. **`REQUEST_NEW_VANTAGE_CREDENTIALS.md`**
   - Guide for requesting new credentials from Vantage support

6. **`VANTAGE_SYNC_FIX_DOCUMENTATION.md`** (this file)
   - Comprehensive documentation of all issues and fixes

---

## Deployment Steps

### Prerequisites Completed

✅ Step 0: Added `external_id` column to `deals` table
✅ Fixed authentication (removed Bearer prefix)
✅ Fixed date parsing (handles ISO timestamps)
✅ Fixed schema mapping (removed nonexistent columns)

### Next Step Required

**Run this SQL in Supabase SQL Editor:**
```sql
ALTER TABLE public.deals
DROP CONSTRAINT IF EXISTS deals_name_key;
```

*(Already in your clipboard - paste and run)*

### Test Again

After removing the constraint:
```powershell
.\test_edge_function.ps1
```

**Expected Result**:
- ✅ Accounts: 2,097 synced
- ✅ Funds: 290 synced

### Continue Deployment

Once testing succeeds, proceed with:
```powershell
.\EXECUTE_VANTAGE_DEPLOYMENT_FIXED.ps1
```

---

## Lessons Learned

### 1. Always Check Actual API Behavior

Don't trust API documentation alone. The Swagger docs showed "bearer: buligodata" in the security schemes, but the actual implementation doesn't use the Bearer prefix. Use browser dev tools or curl commands from working Swagger UI to see exact headers.

### 2. Database Schema First

Before writing mappers, verify the actual database schema. The `FundInsert` interface was written based on assumptions, not actual `deals` table structure.

### 3. Date Parsing Must Be Flexible

APIs evolve. Even if documentation says "yyyyMMdd", the API might return ISO 8601. Build parsers that handle multiple formats.

### 4. Unique Constraints Should Match Business Logic

A unique constraint on `name` makes sense for user-facing entities, but not for external system sync where `external_id` is the true unique key.

---

## Technical Architecture

### Data Flow

```
Vantage IR API
    ↓ (HTTP GET with custom auth)
vantageClient.ts
    ↓ (Raw JSON response)
vantageMappers.ts
    ↓ (Validated, transformed data)
Edge Function (index.ts)
    ↓ (Supabase client upsert)
PostgreSQL (investors & deals tables)
```

### Authentication Flow

```
Client Request
    ↓ (Bearer <service_role_key>)
Edge Function
    ↓ (Authorization: <vantage_token>) ← NO Bearer prefix!
    ↓ (X-com-vantageir-subscriptions-clientid: <client_id>)
Vantage IR API
    ↓ (200 OK + JSON response)
Edge Function
```

### Idempotency Strategy

- **Investors**: Upsert by `external_id` using Supabase's `ON CONFLICT`
- **Funds**: Manual check by `external_id`, then UPDATE or INSERT

---

## Credentials

### Current (Working) Credentials

- **Base URL**: `https://buligoirapi.insightportal.info`
- **Auth Token**: `buligodata`
- **Client ID**: `bexz40aUdxK5rQDSjS2BIUg==`

### Credential Rotation

If credentials expire:
1. Contact Vantage IR support
2. Request new token and confirm client ID
3. Run: `.\update_vantage_credentials.ps1`
4. Test: `.\test_vantage_auth.ps1`

See `REQUEST_NEW_VANTAGE_CREDENTIALS.md` for detailed instructions.

---

## Supabase Secrets Configuration

All secrets are configured and verified:
```bash
$ supabase secrets list
VANTAGE_API_BASE_URL      ✓
VANTAGE_AUTH_TOKEN        ✓
VANTAGE_CLIENT_ID         ✓
```

---

## Testing Summary

### Test 1: Direct API Call
**Command**: `.\test_vantage_auth.ps1`
**Result**: ✅ SUCCESS
**Evidence**:
```
[OK] Vantage API authentication successful!
  Response code: 0
  Funds returned: 0
```

### Test 2: Edge Function - Accounts
**Command**: `.\test_edge_function.ps1`
**Result**: ✅ SUCCESS
**Metrics**:
- Processed: 2,097
- Created: 2,097
- Updated: 0
- Errors: 0
- Duration: ~8 seconds

### Test 3: Edge Function - Funds
**Command**: `.\test_edge_function.ps1`
**Result**: 🟡 PARTIAL
**Metrics**:
- Processed: 290
- Created: 32
- Updated: 0
- Errors: 258 (all due to `deals_name_key` constraint)
- Duration: ~36 seconds

**Expected after fix**: ✅ All 290 funds will sync

---

## Performance Notes

- **Accounts sync**: ~8 seconds for 2,097 records = 262 records/second
- **Funds sync**: ~36 seconds for 290 records = 8 records/second
  - Slower due to individual INSERT/UPDATE logic (not batch)
  - Acceptable for daily sync

---

## Next Actions

1. **Immediate**: Run `remove_deals_name_constraint.sql` in Supabase SQL Editor
2. **Test**: Run `.\test_edge_function.ps1` to verify all 290 funds sync
3. **Deploy**: Run `.\EXECUTE_VANTAGE_DEPLOYMENT_FIXED.ps1` for full deployment
4. **Monitor**: Check first automated daily sync (scheduled for 00:00 UTC)

---

## Contact Information

**Vantage IR Support**:
- Website: https://www.vantageir.com/
- API Base: https://buligoirapi.insightportal.info
- Account: Buligo Capital

**Documentation References**:
- This file: `VANTAGE_SYNC_FIX_DOCUMENTATION.md`
- Deployment guide: `VANTAGE_ETL_DEPLOYMENT.md`
- Credential rotation: `REQUEST_NEW_VANTAGE_CREDENTIALS.md`

---

## Appendix: Error Messages Encountered

### 401 Unauthorized
```json
{"code":401,"message":"Unauthorized Access"}
```
**Cause**: Bearer prefix in Authorization header
**Fix**: Removed Bearer prefix

### Invalid Date Format
```
Invalid inception_date format: 2012-12-21T00:00:00
```
**Cause**: Parser expected yyyyMMdd, got ISO timestamp
**Fix**: Enhanced parser to handle ISO formats

### Column Not Found
```
Could not find the 'code' column of 'deals' in the schema cache
```
**Cause**: Mapper trying to insert non-existent column
**Fix**: Aligned FundInsert interface with actual schema

### Duplicate Key
```
duplicate key value violates unique constraint "deals_name_key"
```
**Cause**: Unique constraint on name column, multiple funds with same name
**Fix**: Removed unique constraint (use external_id instead)

---

## Version History

- **v1.0** (2025-11-06): Initial deployment with all fixes documented
  - Authentication fix (no Bearer prefix)
  - Date parsing enhancement (ISO support)
  - Schema alignment (removed code/is_active/metadata)
  - Constraint removal (deals_name_key)

---

**Status**: Ready for final testing and deployment
**Author**: Claude Code Assistant
**Review**: Pending user verification of constraint removal
