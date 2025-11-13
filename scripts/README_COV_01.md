# COV-01: Default Agreement Seeder

## Purpose

Creates default agreements for party-deal pairs that have contributions but no agreement. This enables:
- Commission computation for those pairs
- More visible data in demo/testing environments
- Baseline agreements that can be customized later

## Current Gap

**Before COV-01:**
- Many contributions exist without corresponding agreements
- These contributions cannot generate commissions (no pricing terms)
- Demo/testing shows limited commission data

**After COV-01:**
- All party-deal pairs with contributions get default agreements
- Commissions can be computed for all contributions
- Demo/testing shows comprehensive commission data

---

## Quick Start

### Option A: Automated (PowerShell)

```powershell
.\run_COV_01.ps1
```

### Option B: Manual (Supabase SQL Editor)

1. Copy SQL to clipboard:
   ```powershell
   Get-Content scripts\COV-01_default_agreements.sql -Raw | Set-Clipboard
   ```

2. Go to [Supabase SQL Editor](https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys/sql)

3. Paste and click **"Run"**

4. Review the output:
   - Number of default agreements created
   - Sample agreements with party and deal names
   - Remaining gaps (should be 0)

---

## Default Agreement Terms

All seeded agreements use these standard terms:

| Field          | Value          | Notes                                    |
|----------------|----------------|------------------------------------------|
| pricing_mode   | TIERED         | Standard tiered pricing                  |
| upfront_bps    | 100            | 1.0% upfront commission                  |
| deferred_bps   | 0              | 0.0% deferred commission                 |
| vat_rate       | 0.17           | 17% (current Israeli VAT rate)           |
| status         | active         | Agreement is active and usable           |
| snapshot_json  | {...}          | Captures rates at agreement creation     |

**Note:** These are baseline values. Admins can edit individual agreements later for custom pricing.

---

## What It Does

**Step 1: Find Gaps**
```sql
-- Identifies party-deal pairs with contributions but no agreement
SELECT DISTINCT party_id, deal_id
FROM contributions
WHERE NOT EXISTS (
  SELECT 1 FROM agreements
  WHERE agreements.party_id = contributions.party_id
    AND agreements.deal_id = contributions.deal_id
)
```

**Step 2: Create Default Agreements**
```sql
-- Inserts agreement with default terms for each gap
INSERT INTO agreements (party_id, deal_id, pricing_mode, upfront_bps, ...)
VALUES (...);
```

**Step 3: Report Results**
- Count of agreements created
- Sample agreements with party/deal names
- Verification of remaining gaps (should be 0)

---

## Expected Impact

### Before COV-01

**Example Query:**
```sql
SELECT COUNT(*) FROM contributions WHERE party_id = 182 AND deal_id = 5;
-- Returns: 10 contributions

SELECT COUNT(*) FROM agreements WHERE party_id = 182 AND deal_id = 5;
-- Returns: 0 agreements

-- Result: 10 contributions cannot generate commissions
```

### After COV-01

**Example Query:**
```sql
SELECT COUNT(*) FROM contributions WHERE party_id = 182 AND deal_id = 5;
-- Returns: 10 contributions

SELECT COUNT(*) FROM agreements WHERE party_id = 182 AND deal_id = 5;
-- Returns: 1 agreement (default terms: 100 bps upfront, 0 deferred, 17% VAT)

-- Result: 10 contributions can now generate commissions
```

---

## Safety & Idempotency

**Idempotent:** ✅ Safe to run multiple times
- Uses `NOT EXISTS` to avoid duplicates
- Only inserts agreements for party-deal pairs that don't already have one
- Re-running will create 0 new agreements (all gaps already filled)

**Rollback:** If needed, you can identify and delete seeded agreements:
```sql
-- Preview seeded agreements
SELECT * FROM agreements
WHERE upfront_bps = 100
  AND deferred_bps = 0
  AND pricing_mode = 'TIERED';

-- Delete if needed (CAREFUL!)
-- DELETE FROM agreements
-- WHERE upfront_bps = 100
--   AND deferred_bps = 0
--   AND pricing_mode = 'TIERED';
```

---

## Verification

After running COV-01, verify the results:

```powershell
# Run verification query (copies SQL to clipboard)
.\verify_COV_01.ps1
```

**Expected Results:**
- `total_contribution_pairs`: N (number of distinct party-deal pairs with contributions)
- `total_agreements`: N (should match above)
- `remaining_gaps`: 0 (all pairs now have agreements)

---

## Customization After Seeding

After COV-01 creates default agreements, admins can customize individual agreements:

**Example: Update Avi Fried's agreement for Deal #5 to 150 bps upfront**
```sql
UPDATE agreements
SET upfront_bps = 150,
    snapshot_json = jsonb_set(snapshot_json, '{resolved_upfront_bps}', '150')
WHERE party_id = 182
  AND deal_id = 5;
```

**Example: Change Capital Link's VAT policy**
```sql
UPDATE agreements
SET vat_policy_id = (SELECT id FROM vat_policies WHERE rate = 0.20 LIMIT 1),
    snapshot_json = jsonb_set(snapshot_json, '{vat_rate}', '0.20')
WHERE party_id = 187;
```

---

## Troubleshooting

**Error: "vat_policy_id violates foreign key constraint"**
- **Cause:** No VAT policy with 17% rate exists
- **Fix:** Create a VAT policy first or adjust the query to use an existing rate

```sql
-- Check available VAT policies
SELECT id, rate, effective_from FROM vat_policies ORDER BY effective_from DESC;

-- Create 17% VAT policy if needed
INSERT INTO vat_policies (rate, effective_from, description)
VALUES (0.17, '2024-01-01', 'Israeli standard VAT rate')
ON CONFLICT DO NOTHING;
```

**Error: "duplicate key value violates unique constraint"**
- **Cause:** Agreement already exists for that party-deal pair
- **Fix:** This is normal on re-runs. The script will skip duplicates automatically.

**No agreements created (count = 0)**
- **Cause:** All party-deal pairs already have agreements
- **Verification:** Run the gap check query to confirm

```sql
SELECT COUNT(DISTINCT (party_id, deal_id))
FROM contributions
WHERE party_id IS NOT NULL
  AND deal_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM agreements a
    WHERE a.party_id = contributions.party_id
      AND a.deal_id = contributions.deal_id
  );
-- Should return: 0 (no gaps remaining)
```

---

## Files

- **scripts/COV-01_default_agreements.sql** - Main seeder script
- **run_COV_01.ps1** - Automated runner (optional)
- **verify_COV_01.ps1** - Verification script (optional)
- **scripts/README_COV_01.md** - This file

---

## Next Steps After COV-01

Once default agreements are seeded:

1. **Test commission computation:**
   ```powershell
   .\CMP_01_simple.ps1
   ```

2. **Review generated commissions:**
   - Check charges queue
   - Verify commission calculations
   - Test approval workflow

3. **Customize agreements as needed:**
   - Update pricing for specific parties
   - Adjust VAT policies
   - Set deal-specific overrides

---

**Status**: Ready to run
**Prerequisites**: Gate A passed, contributions exist in database
**Impact**: Enables commission computation for all party-deal contribution pairs
**Last Updated**: 2025-11-09
**Prepared By**: Claude Code Assistant
