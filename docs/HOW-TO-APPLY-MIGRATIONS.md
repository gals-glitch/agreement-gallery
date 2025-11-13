# How to Apply Migrations & Run Smoke Test

**Time Required:** 15 minutes
**Prerequisites:** Access to Supabase Dashboard

---

## Step 1: Access Supabase SQL Editor (2 minutes)

1. Go to: https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys
2. Log in with your credentials
3. Click **SQL Editor** in the left sidebar

---

## Step 2: Apply Migrations in Order (8 minutes)

Run each migration file in **numerical order**. For each file:

### **Migration 1: Types**
- Open: `supabase/migrations/20251016000000_redesign_00_types.sql`
- Copy all content
- Paste into SQL Editor
- Click **RUN**
- Wait for "Success" message

### **Migration 2: Core Entities**
- Open: `supabase/migrations/20251016000001_redesign_01_core_entities.sql`
- Copy all content
- Paste into SQL Editor
- Click **RUN**

### **Migration 3: Contributions**
- Open: `supabase/migrations/20251016000002_redesign_02_contributions.sql`
- Copy, paste, run

### **Migration 4: Tracks**
- Open: `supabase/migrations/20251016000003_redesign_03_tracks.sql`
- Copy, paste, run

### **Migration 5: Agreements**
- Open: `supabase/migrations/20251016000004_redesign_04_agreements.sql`
- Copy, paste, run

### **Migration 6: Scoreboard Import**
- Open: `supabase/migrations/20251016000005_redesign_05_scoreboard_import.sql`
- Copy, paste, run

### **Migration 7: Guardrails**
- Open: `supabase/migrations/20251016000006_redesign_06_guards.sql`
- Copy, paste, run

### **Migration 8: Seed Data**
- Open: `supabase/migrations/20251016000007_redesign_07_seed_fund_vi.sql`
- Copy, paste, run

---

## Step 3: Run Smoke Test (5 minutes)

1. Open: `scripts/smoke-test-migrations.sql`
2. Copy all content
3. Paste into SQL Editor
4. Click **RUN**

**Expected Output:**
```
✅ TEST 1: Fund VI Tracks Seeded & Locked
   → Should show 3 rows (Track A, B, C)

✅ TEST 2: Immutability Triggers Installed
   → Should show 2 triggers

✅ TEST 3: Pricing Constraint
   → Should show "TEST PASSED: Constraint correctly blocked..."

✅ TEST 4: Contribution Scope Constraint
   → Should show "TEST PASSED" twice

✅ TEST 5: Snapshot Trigger
   → Should show "TEST PASSED: Snapshot auto-created"
   → Should show "TEST PASSED: Immutability trigger blocked update"
```

---

## Step 4: Verify Seed Data (Quick)

Run this query to verify Fund VI tracks:

```sql
SELECT
  f.name AS fund,
  ft.track_code,
  ft.upfront_bps || ' bps' AS upfront,
  ft.deferred_bps || ' bps' AS deferred,
  ft.is_locked,
  ft.seed_version
FROM fund_tracks ft
JOIN funds f ON f.id = ft.fund_id
WHERE f.name='Fund VI'
ORDER BY ft.track_code;
```

**Expected:**
```
fund     | track_code | upfront  | deferred | is_locked | seed_version
---------+------------+----------+----------+-----------+--------------
Fund VI  | A          | 120 bps  | 80 bps   | true      | 1
Fund VI  | B          | 180 bps  | 80 bps   | true      | 1
Fund VI  | C          | 180 bps  | 130 bps  | true      | 1
```

---

## Troubleshooting

### **Error: "relation already exists"**
- **Cause:** Migration was already applied partially
- **Fix:** Skip to next migration file

### **Error: "type already exists"**
- **Cause:** Types were created in previous run
- **Fix:** Safe to ignore, continue with next migration

### **Error: "constraint violation"**
- **Cause:** This is EXPECTED for smoke test constraint checks
- **Fix:** Look for "TEST PASSED" messages in the output

### **Error: "function does not exist"**
- **Cause:** Earlier migration didn't complete
- **Fix:** Re-run previous migrations in order

---

## What to Do After Success

Once all tests pass, you're ready for:

### **✅ Day 2: UI Updates**

**Priority 1: Parties**
- Add `tax_id` field to form
- Test: Create party with tax ID

**Priority 2: Funds**
- Create simple CRUD page
- Test: Create "Fund VI" entry

**Priority 3: Deals**
- Create CRUD with scoreboard fields (read-only)
- GP exclusion toggle
- Test: Create deal, verify scoreboard fields display

**Priority 4: Agreements**
- Redesign form with Scope/Pricing Mode logic
- Add snapshot display after approval
- Test: Create FUND + Track B agreement → approve → verify snapshot

---

## CSV Import (Optional)

If you want to test with sample data:

### **1. Scoreboard Import**
```sql
-- Load scoreboard_deal_metrics.csv via Table Editor

-- Then apply:
SELECT apply_scoreboard_metrics('2025Q3');

-- Verify:
SELECT name, equity_to_raise, raised_so_far
FROM deals
WHERE equity_to_raise IS NOT NULL;
```

### **2. Contributions Import**
```sql
-- First, create test investors:
INSERT INTO investors(name, external_id, is_gp) VALUES
('ABC Holdings', 'INV-001', false),
('Buligo GP', 'INV-002', true),
('XYZ Family Office', 'INV-003', false);

-- Then load contributions.csv via Table Editor
```

---

## Next Session

After migrations are applied and smoke test passes, ping me and I'll:

1. ✅ Update Parties UI (add tax_id)
2. ✅ Create Funds CRUD page
3. ✅ Create Deals CRUD page
4. ✅ Redesign Agreement form with new logic
5. ✅ Convert FundVITracksAdmin to read-only

**Estimated Time:** 3-4 hours for all UI updates

---

**Good luck! Let me know when smoke test passes and we'll continue with Day 2.**
