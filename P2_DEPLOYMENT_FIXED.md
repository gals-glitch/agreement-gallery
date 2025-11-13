# P2 Deployment - FIXED Migration Files

**Date:** 2025-10-19
**Issue:** Original migration failed due to BIGINT → UUID casting error
**Status:** ✅ FIXED

---

## ⚠️ Problem Summary

**Error Encountered:**
```
ERROR: 42846: cannot cast type bigint to uuid
QUERY: ALTER TABLE credit_applications
       ALTER COLUMN charge_id TYPE UUID USING charge_id::uuid
```

**Root Cause:**
- Original migration `20251019130000_charges.sql` tried to convert `credit_applications.charge_id` from BIGINT to UUID
- This fails because BIGINT cannot be directly cast to UUID
- creditsEngine.ts expects numeric IDs, not UUIDs

---

## ✅ Solution: Use FIXED Migration Files

**Fixed Approach:**
1. Keep `charges.id` as UUID (for API consistency)
2. Add `charges.numeric_id` as BIGSERIAL (for creditsEngine compatibility)
3. `credit_applications.charge_id` (BIGINT) references `charges.numeric_id` (BIGINT)

**Result:**
- ✅ API uses UUID in responses (clean, standard)
- ✅ creditsEngine uses numeric IDs internally (works without modification)
- ✅ No BIGINT → UUID conversion needed

---

## 📋 Deployment Steps (CORRECTED)

### Step 1: Use the FIXED Migrations

**IMPORTANT:** Use these files instead of the original ones:

#### Migration 1 (FIXED):
**File:** `supabase/migrations/20251019130000_charges_FIXED.sql`
**Changes:**
- ✅ Creates `charges` table with BOTH `id` (UUID) and `numeric_id` (BIGSERIAL)
- ✅ Does NOT modify `credit_applications` table
- ✅ All indexes and RLS policies included

#### Migration 2 (FIXED):
**File:** `supabase/migrations/20251019140000_charges_credits_columns_FIXED.sql`
**Changes:**
- ✅ Adds FK from `credit_applications.charge_id` → `charges.numeric_id`
- ✅ Adds `credits_applied_amount` column
- ✅ Adds `net_amount` column
- ✅ Simplified (assumes `numeric_id` already exists from Migration 1)

---

### Step 2: Apply Migrations via Supabase Dashboard

**Option A: Supabase Dashboard SQL Editor** (Recommended)

1. Go to: https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys/sql

2. **Apply Migration 1 (charges table):**
   - Copy contents of `20251019130000_charges_FIXED.sql`
   - Paste into SQL Editor
   - Click **Run**
   - Wait for "Success" message

3. **Apply Migration 2 (credits columns):**
   - Copy contents of `20251019140000_charges_credits_columns_FIXED.sql`
   - Paste into SQL Editor
   - Click **Run**
   - Wait for "Success" message

**Option B: Supabase CLI** (Alternative)

```bash
# Navigate to project
cd "C:\Users\GalSamionov\Buligo Capital\Buligo Capital - Shared Documents\Information Systems\Gal\agreement-gallery-main"

# Rename FIXED files to replace originals (backup originals first)
mv supabase/migrations/20251019130000_charges.sql supabase/migrations/20251019130000_charges_ORIGINAL.sql.bak
mv supabase/migrations/20251019140000_charges_credits_columns.sql supabase/migrations/20251019140000_charges_credits_columns_ORIGINAL.sql.bak

mv supabase/migrations/20251019130000_charges_FIXED.sql supabase/migrations/20251019130000_charges.sql
mv supabase/migrations/20251019140000_charges_credits_columns_FIXED.sql supabase/migrations/20251019140000_charges_credits_columns.sql

# Push migrations
supabase db push
```

---

### Step 3: Verify Migrations Applied Successfully

**Check 1: charges table exists with dual IDs**
```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'charges'
  AND column_name IN ('id', 'numeric_id')
ORDER BY column_name;
```

**Expected Output:**
```
column_name | data_type | is_nullable
------------+-----------+-------------
id          | uuid      | NO
numeric_id  | bigint    | NO
```

**Check 2: credit_applications FK constraint**
```sql
SELECT conname, contype, confrelid::regclass AS referenced_table
FROM pg_constraint
WHERE conrelid = 'credit_applications'::regclass
  AND conname LIKE '%charge%';
```

**Expected Output:**
```
conname                                    | contype | referenced_table
-------------------------------------------+---------+------------------
credit_applications_charge_numeric_id_fkey | f       | charges
```

**Check 3: credits columns added**
```sql
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'charges'
  AND column_name IN ('credits_applied_amount', 'net_amount')
ORDER BY column_name;
```

**Expected Output:**
```
column_name            | data_type | column_default
-----------------------+-----------+----------------
credits_applied_amount | numeric   | 0
net_amount             | numeric   | 0
```

---

### Step 4: Continue with Original Deployment Guide

Once migrations are applied successfully:

1. ✅ Migrations complete
2. ➡️ Continue with `P2_DEPLOYMENT_GUIDE.md` **Step 2: Deploy Edge Functions**
3. ➡️ Follow remaining steps (seed data, smoke tests, etc.)

---

## 🔄 Rollback (If Needed)

**If you need to rollback the FIXED migrations:**

```sql
-- Rollback Migration 2 (credits columns)
ALTER TABLE credit_applications DROP CONSTRAINT IF EXISTS credit_applications_charge_numeric_id_fkey;
ALTER TABLE charges DROP COLUMN IF EXISTS credits_applied_amount;
ALTER TABLE charges DROP COLUMN IF EXISTS net_amount;

-- Rollback Migration 1 (charges table)
DROP TABLE IF EXISTS charges CASCADE;
DROP TYPE IF EXISTS charge_status CASCADE;
```

**Warning:** This deletes all charges data. Only use if deployment is critically broken.

---

## 📊 What Changed vs Original

| Aspect | Original Migration | FIXED Migration |
|--------|-------------------|-----------------|
| **charges.id** | UUID (PK) | UUID (PK) ✅ Same |
| **charges.numeric_id** | ❌ Not included | ✅ BIGSERIAL UNIQUE (for creditsEngine) |
| **credit_applications.charge_id** | Tried to convert to UUID ❌ | Stays BIGINT, FK to charges.numeric_id ✅ |
| **API Responses** | Use charges.id (UUID) | Use charges.id (UUID) ✅ Same |
| **creditsEngine Calls** | Would fail (expects numeric) ❌ | Uses charges.numeric_id ✅ Works |

---

## 🎯 Next Steps

1. ✅ Apply FIXED migrations (Step 2 above)
2. ✅ Verify with checks (Step 3 above)
3. ➡️ Continue with `P2_DEPLOYMENT_GUIDE.md` from Step 2 onwards
4. ➡️ Deploy Edge Functions
5. ➡️ Run smoke tests
6. ➡️ Proceed to Option A (P2-8 to P2-11) after Go decision

---

## 📞 Support

**If you encounter issues:**

1. Check Supabase logs: https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys/logs/database
2. Verify table structure: `\d charges` (in psql)
3. Check constraint errors: `SELECT * FROM pg_constraint WHERE conrelid = 'charges'::regclass;`

**Common Issues:**

**Issue:** "relation 'charges' already exists"
- **Cause:** Original migration partially applied before error
- **Fix:**
  ```sql
  DROP TABLE IF EXISTS charges CASCADE;
  DROP TYPE IF EXISTS charge_status CASCADE;
  ```
  Then re-run FIXED migration.

**Issue:** "column 'numeric_id' already exists"
- **Cause:** Migration 2 FIXED running before Migration 1 FIXED
- **Fix:** Apply in correct order (1 then 2)

---

**Created:** 2025-10-19
**Updated:** 2025-10-19
**Status:** Ready for Deployment
