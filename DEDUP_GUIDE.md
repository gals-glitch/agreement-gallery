# Investor Deduplication Guide

## Overview

This toolkit safely merges the 22 duplicate investors (DISTRIBUTOR source) into their Vantage counterparts. The process is:
- **Safe**: All changes are logged and traceable
- **Reversible**: Merged records are soft-deleted, not hard-deleted
- **Auditable**: Every FK update is logged in JSON
- **Dynamic**: Automatically finds and updates all FK references

---

## The Problem

After the Vantage sync, you have 22 investors that exist in both sources:
- **DISTRIBUTOR source** (original records, no external_id)
- **vantage source** (Vantage IR records, with external_id)

Examples:
- "Abraham Raz" - ID 157 (DISTRIBUTOR) + ID 1864 (vantage)
- "310 Tyson Drive GP LLC" - ID 154 (DISTRIBUTOR) + ID 3710 (vantage)
- "Adam Gotskind" - ID 140 (DISTRIBUTOR) + ID 2677 (vantage)

---

## The Solution

Merge DISTRIBUTOR records INTO Vantage records:
1. Update all FK references (agreements, transactions, etc.) to point to Vantage ID
2. Soft-delete the DISTRIBUTOR record (set active=false, merged_into_id)
3. Keep the Vantage record as the canonical source of truth
4. Log everything for audit trail

---

## Step-by-Step Process

### Step 0: Check Current State (Read-Only)

**File:** `dedup_step0_exact_count.sql`

Run this first to see:
- Total investors: 2138
- Vantage: 2097
- DISTRIBUTOR: 41
- Duplicate name pairs: 22

**Open:** https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys/sql/new

Copy/paste the SQL and run it. Review the counts.

---

### Step 1: Create Schema Helpers

**File:** `dedup_step1_schema_helpers.sql`

This creates:
- `investor_merge_log` table for audit trail
- `merged_into_id` column on investors table
- Verifies `external_id` unique constraint exists

**Safe to run multiple times** (all IF NOT EXISTS).

Copy/paste and run in SQL Editor.

---

### Step 2: Create Merge Function

**File:** `dedup_step2_merge_function.sql`

This creates the `merge_investors(src_id, dst_id, reason)` function that:
- Finds ALL FK references to investors table dynamically
- Updates them from src → dst
- Soft-deletes the source record
- Logs everything in investor_merge_log

**Safe to run multiple times** (CREATE OR REPLACE).

Copy/paste and run in SQL Editor.

---

### Step 3: Build Merge Plan (REVIEW BEFORE EXECUTING!)

**File:** `dedup_step3_build_plan.sql`

This creates a temp table with the 22 merge pairs and shows them for review.

**IMPORTANT:**
1. This creates a TEMP table that auto-drops when you close the SQL Editor tab
2. **REVIEW the merge plan** carefully before Step 4
3. Make sure the pairs look correct (same name, matching emails/tax_ids)
4. If you close the tab, you'll need to re-run this before Step 4

Copy/paste and run in SQL Editor. **Keep the tab open** for Step 4.

---

### Step 4: Execute Merges

**File:** `dedup_step4_execute.sql`

**⚠️ THIS IS THE DESTRUCTIVE STEP**

This runs `merge_investors()` for each of the 22 pairs.

**Prerequisites:**
- Step 3 must have been run in the **same SQL Editor tab** (temp table must still exist)
- You reviewed the merge plan and it looks correct

Copy/paste and run in SQL Editor (same tab as Step 3).

Expected output:
- 22 rows showing merge results
- Each row shows what FK tables were updated and how many rows

---

### Step 5: Validate Results

**File:** `dedup_step5_validation.sql`

This verifies:
- 22 DISTRIBUTOR records are now inactive with merged_into_id set
- No external_id duplicates exist
- All FK references updated successfully
- Merge log shows 22 entries

Copy/paste and run in SQL Editor.

**Expected Results:**
- total_investors: 2138 (unchanged)
- vantage_investors: 2097 (unchanged)
- distributor_active: 19 (was 41, now 41-22=19)
- distributor_merged: 22 (new)
- No external_id duplicates
- SUCCESS message

---

## What Happens During Merge

For each DISTRIBUTOR → Vantage pair:

1. **FK Updates** (automatic, dynamic):
   ```
   UPDATE agreements SET investor_id = <vantage_id> WHERE investor_id = <distributor_id>
   UPDATE transactions SET investor_id = <vantage_id> WHERE investor_id = <distributor_id>
   UPDATE charges SET investor_id = <vantage_id> WHERE investor_id = <distributor_id>
   ... (all FK tables automatically detected and updated)
   ```

2. **Soft-Delete DISTRIBUTOR Record**:
   ```sql
   UPDATE investors
   SET active = FALSE,
       merged_into_id = <vantage_id>,
       notes = notes || '[timestamp] merged into investor <vantage_id> (reason: name_match)'
   WHERE id = <distributor_id>
   ```

3. **Fill Missing Data** (if Vantage record is missing email/phone/etc):
   ```sql
   UPDATE investors v
   SET email = COALESCE(v.email, d.email),
       phone = COALESCE(v.phone, d.phone)
   FROM investors d
   WHERE v.id = <vantage_id> AND d.id = <distributor_id>
   ```

4. **Log Everything**:
   ```sql
   INSERT INTO investor_merge_log (src_id, dst_id, reason, moved_fk)
   VALUES (<distributor_id>, <vantage_id>, 'name_match', '{"agreements": 3, "transactions": 12, ...}')
   ```

---

## Safety Features

### 1. No Data Loss
- Original DISTRIBUTOR records are NOT deleted
- They're soft-deleted (active=false) and linked via merged_into_id
- All relationships moved to Vantage record

### 2. Audit Trail
Every merge is logged with:
- Source and destination IDs
- Reason for merge
- Per-table FK update counts
- Timestamp and user

### 3. Reversibility
While not automatic, you can reverse merges by:
- Checking the merge log for what changed
- Updating FK references back to original IDs
- Setting active=true and merged_into_id=null

(We can write an `unmerge_investors()` function if needed)

### 4. Validation Checks
- Prevents merging an investor into itself
- Validates both IDs exist
- Checks for external_id duplicates after merge
- Reports any FK update conflicts

---

## Expected Final State

**Before Dedup:**
- Total: 2138 investors
- Vantage: 2097
- DISTRIBUTOR active: 41
- Duplicates: 22 name pairs

**After Dedup:**
- Total: 2138 investors (unchanged - records not deleted)
- Vantage: 2097 (unchanged)
- DISTRIBUTOR active: 19 (41 - 22 = 19)
- DISTRIBUTOR merged: 22 (new - these are inactive)
- Duplicates: 0 name pairs (active records only)

**In the UI:**
- Investors list will show 2,116 active investors (2097 + 19)
- 22 DISTRIBUTOR records will be hidden (active=false)
- All agreements/transactions/charges now reference Vantage records

---

## Troubleshooting

### Error: "investor_merge_plan does not exist"

**Cause:** You closed the SQL Editor tab between Step 3 and Step 4.

**Fix:** Re-run Step 3 (it creates a TEMP table that drops when you close the tab).

### Error: "duplicate key value violates unique constraint"

**Cause:** Some FK table has a unique constraint that prevents two rows with the same investor_id.

**Fix:** Tell me the table name and constraint, and I'll add conflict-safe handling.

### Merge executed but some FKs weren't updated

**Check the merge log:**
```sql
SELECT * FROM investor_merge_log ORDER BY run_at DESC LIMIT 1;
```

The `moved_fk` JSON shows which tables were updated and how many rows.

If a table is missing, it might not have a proper FK constraint set up.

---

## Running the Dedup

### Quick PowerShell Helper

Run this to copy each SQL file to clipboard in sequence:

```powershell
powershell -ExecutionPolicy Bypass -File run_dedup_steps.ps1
```

### Manual Steps

1. Open SQL Editor: https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys/sql/new
2. Run each file in order:
   - `dedup_step0_exact_count.sql` - Review counts
   - `dedup_step1_schema_helpers.sql` - Create schema
   - `dedup_step2_merge_function.sql` - Create function
   - `dedup_step3_build_plan.sql` - Build plan (KEEP TAB OPEN)
   - `dedup_step4_execute.sql` - Execute merges (SAME TAB)
   - `dedup_step5_validation.sql` - Validate results

---

## Files Created

- `dedup_step0_exact_count.sql` - Read-only counts query
- `dedup_step1_schema_helpers.sql` - Schema setup (log table, columns)
- `dedup_step2_merge_function.sql` - merge_investors() function
- `dedup_step3_build_plan.sql` - Build temp merge plan
- `dedup_step4_execute.sql` - Execute all merges
- `dedup_step5_validation.sql` - Post-merge validation
- `run_dedup_steps.ps1` - PowerShell helper to copy files to clipboard
- `DEDUP_GUIDE.md` - This file

---

## After Deduplication

### Update Your UI Filters

If you have filters for "All Investors", consider:
- Filtering WHERE active IS NOT FALSE (exclude merged records)
- Or add a checkbox "Show merged investors"

### Future Vantage Syncs

The dedup is a one-time cleanup. Future Vantage syncs will:
- Update existing Vantage records via external_id
- Not create new duplicates (external_id is unique)
- Preserve the 19 remaining DISTRIBUTOR investors (different people)

### Monitoring

Check the merge log periodically:
```sql
SELECT COUNT(*), MAX(run_at) FROM investor_merge_log;
```

---

## Questions?

- Check validation results (Step 5)
- Review merge log for specific merge details
- Check investor.notes field for merge timestamp
- All original data is preserved (soft-delete only)

---

**Status:** Ready to execute
**Risk Level:** Low (reversible, logged, soft-delete only)
**Estimated Time:** < 5 minutes for all steps
**Data Loss Risk:** None (soft-delete, full audit trail)
