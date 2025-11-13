# Day 1 Complete: Data Model Redesign

**Date:** 2025-10-16
**Status:** ✅ MIGRATIONS READY
**Duration:** ~2 hours
**Next:** Apply migrations to database + test

---

## Summary

Complete database redesign implementing the new Fund/Deal/Agreement architecture with immutability guarantees and audit trail.

---

## What Was Delivered

### **7 Migration Files** ✅

| File | Purpose | Key Features |
|------|---------|--------------|
| `20251016000000_redesign_00_types.sql` | Enum types | agreement_scope, pricing_mode, agreement_status, track_code |
| `20251016000001_redesign_01_core_entities.sql` | Core tables | funds, parties, deals, deal_closes, investors, partner_companies, fund_groups |
| `20251016000002_redesign_02_contributions.sql` | Contributions | Paid-in capital with deal_id XOR fund_id constraint |
| `20251016000003_redesign_03_tracks.sql` | Fund tracks | Locked, versioned Track A/B/C rate definitions |
| `20251016000004_redesign_04_agreements.sql` | Agreements | Party × (Fund\|Deal) with pricing_mode + snapshots |
| `20251016000005_redesign_05_scoreboard_import.sql` | Scoreboard CSV | Landing table + apply_scoreboard_metrics() function |
| `20251016000006_redesign_06_guards.sql` | Guardrails | Immutability triggers + auto-snapshot on approval |
| `20251016000007_redesign_07_seed_fund_vi.sql` | Seed data | Fund VI + Tracks A/B/C (locked, seed_version=1) |

### **CSV Templates** ✅

- `scripts/import-templates/scoreboard_deal_metrics.csv`
- `scripts/import-templates/contributions.csv`

---

## Architecture Decisions Implemented

### **1. Track Resolution**
```
✅ FIXED at agreement creation
❌ NOT dynamic based on total raised
```

**Implementation:**
- `agreements.selected_track` stores chosen track (A/B/C)
- `agreement_rate_snapshots` captures resolved rates at approval time
- `fund_tracks.tier_min/tier_max` are reference-only (NOT used for calculation)

### **2. Investor-Party Linkage**
```
✅ Agreement-level only
❌ No investors.introduced_by_party_id
```

**Implementation:**
- Relationship lives in `agreements` table
- `agreements(party_id, scope, fund_id/deal_id)`

### **3. GP Exclusion**
```
✅ investors.is_gp flag
✅ deals.exclude_gp_from_commission toggle (default=true)
```

**Implementation:**
```sql
-- In calculation engine:
IF deals.exclude_gp_from_commission = true
   AND investors.is_gp = true
THEN exclude_contribution_from_fee_base
```

### **4. Scoreboard Integration**
```
✅ CSV import (Phase 1)
⏳ API sync (Phase 2)
```

**Implementation:**
- `scoreboard_deal_metrics` table (CSV landing)
- `apply_scoreboard_metrics(batch)` function updates `deals` table
- `deals.equity_to_raise` and `raised_so_far` are read-only in UI

---

## Database Constraints

### **Business Rules Enforced at Schema Level:**

1. **Scope Exclusivity**
   ```sql
   (scope='FUND' AND fund_id IS NOT NULL AND deal_id IS NULL)
   OR
   (scope='DEAL' AND deal_id IS NOT NULL AND fund_id IS NULL)
   ```

2. **Pricing Mode Rules**
   ```sql
   -- FUND must use TRACK
   (scope='FUND' AND pricing_mode='TRACK' AND selected_track IS NOT NULL)
   OR
   -- DEAL can use TRACK or CUSTOM
   (scope='DEAL' AND (pricing_mode='TRACK' OR pricing_mode='CUSTOM'))
   ```

3. **Contribution Scope**
   ```sql
   -- Exactly one of deal_id OR fund_id must be set
   (deal_id IS NOT NULL AND fund_id IS NULL)
   OR
   (deal_id IS NULL AND fund_id IS NOT NULL)
   ```

4. **Immutability**
   ```sql
   -- Trigger: prevent_update_on_approved()
   IF OLD.status = 'APPROVED' THEN
     RAISE EXCEPTION 'Approved agreements are immutable'
   ```

---

## Trigger Automation

### **Trigger 1: Lock Approved Agreements**
```sql
CREATE TRIGGER agreements_lock_after_approval
BEFORE UPDATE ON agreements
FOR EACH ROW
WHEN (OLD.status = 'APPROVED')
EXECUTE PROCEDURE prevent_update_on_approved();
```

**Behavior:**
- ✅ Blocks ANY update to APPROVED agreements
- ✅ Forces Amendment flow (clone to Draft v2)
- ✅ Raises exception with clear message

### **Trigger 2: Auto-Snapshot on Approval**
```sql
CREATE TRIGGER agreements_snapshot_on_approve
AFTER UPDATE ON agreements
FOR EACH ROW
EXECUTE PROCEDURE snapshot_rates_on_approval();
```

**Behavior:**
- ✅ Auto-creates `agreement_rate_snapshots` row when status → APPROVED
- ✅ Resolves rates from `fund_tracks` (if TRACK) or `agreement_custom_terms` (if CUSTOM)
- ✅ Captures `seed_version` for audit trail
- ✅ Raises exception if rates cannot be resolved

---

## Seed Data

### **Fund VI + Tracks**

```sql
-- Fund VI created:
funds(name='Fund VI', vintage_year=2025, currency='USD', status='ACTIVE')

-- Tracks created (LOCKED):
Track A: 120 bps upfront, 80 bps deferred, 24 months offset
Track B: 180 bps upfront, 80 bps deferred, 24 months offset
Track C: 180 bps upfront, 130 bps deferred, 24 months offset
```

**Verification Query:**
```sql
SELECT f.name AS fund, ft.track_code,
       ft.upfront_bps, ft.deferred_bps, ft.is_locked
FROM fund_tracks ft
JOIN funds f ON ft.fund_id = f.id
WHERE f.name = 'Fund VI';
```

---

## How to Apply Migrations

### **Step 1: Connect to Supabase**
```bash
supabase link --project-ref qwgicrdcoqdketqhxbys
```

### **Step 2: Apply Migrations**
```bash
supabase db push
```

### **Step 3: Verify**
```bash
supabase db remote status
```

### **Step 4: Verify Seed Data**
```sql
-- Should return 3 rows:
SELECT * FROM fund_tracks WHERE fund_id = (SELECT id FROM funds WHERE name='Fund VI');
```

---

## CSV Import Workflow

### **Scoreboard Import**

1. Load CSV into `scoreboard_deal_metrics`:
   ```sql
   COPY scoreboard_deal_metrics(deal_name, equity_to_raise, raised_so_far, import_batch)
   FROM '/path/to/scoreboard_deal_metrics.csv'
   WITH (FORMAT csv, HEADER true);
   ```

2. Apply to deals:
   ```sql
   SELECT apply_scoreboard_metrics('2025Q3');
   -- Returns: number of deals updated
   ```

3. Verify:
   ```sql
   SELECT name, equity_to_raise, raised_so_far FROM deals WHERE equity_to_raise IS NOT NULL;
   ```

### **Contributions Import**

1. Upsert investors (with `is_gp` flag):
   ```sql
   INSERT INTO investors(name, external_id, is_gp)
   VALUES ('ABC Holdings', 'INV-001', false)
   ON CONFLICT (name) DO UPDATE SET external_id=EXCLUDED.external_id, is_gp=EXCLUDED.is_gp;
   ```

2. Resolve deal_id/fund_id by name

3. Insert contributions:
   ```sql
   INSERT INTO contributions(investor_id, deal_id, fund_id, paid_in_date, amount, source_batch)
   VALUES (...);
   ```

---

## Testing Checklist

### **Schema Validation** ✅

- [ ] All 7 migrations apply without errors
- [ ] Fund VI exists with 3 locked tracks
- [ ] Constraints prevent invalid data:
  - [ ] Agreement with both fund_id AND deal_id → rejected
  - [ ] FUND-scoped agreement with CUSTOM pricing → rejected
  - [ ] Contribution with neither deal_id nor fund_id → rejected
  - [ ] Contribution with both deal_id AND fund_id → rejected

### **Immutability Tests** ✅

- [ ] Create DRAFT agreement → approve → verify snapshot created
- [ ] Try to edit APPROVED agreement → rejected with error
- [ ] Snapshot contains correct resolved_upfront_bps/resolved_deferred_bps
- [ ] Snapshot captures seed_version (for TRACK) or NULL (for CUSTOM)

### **Trigger Tests** ✅

- [ ] Agreement with TRACK pricing → approve → snapshot uses fund_tracks rates
- [ ] Agreement with CUSTOM pricing → approve → snapshot uses agreement_custom_terms rates
- [ ] Approve agreement with missing track rates → raises exception
- [ ] Approve agreement with missing custom terms → raises exception

---

## Next Steps (Day 2)

### **Frontend Changes Required:**

1. **Update Parties UI**
   - Add `tax_id` field to form
   - Display tax_id in table

2. **Create Funds CRUD Page**
   - Simple table with name, vintage_year, currency, status
   - Add/Edit/Delete operations
   - No rate editing (tracks are separate)

3. **Create Deals CRUD Page**
   - Form with all fields from `deals` table
   - Scoreboard fields (equity_to_raise, raised_so_far) read-only
   - GP exclusion toggle (default=true)
   - Deal closes section (initially one close per deal)

4. **Redesign Agreement Form**
   - Scope picker: FUND | DEAL
   - If FUND: Track selector (A/B/C) → show read-only rates
   - If DEAL:
     - Deal picker
     - Pricing mode: TRACK | CUSTOM
     - If TRACK: Track selector → show read-only rates
     - If CUSTOM: Input fields for upfront_bps, deferred_bps
   - Remove edit capability after approval
   - Add Amendment button (clones to Draft v2)

5. **Convert FundVITracksAdmin**
   - Make all fields read-only
   - Display as reference table only
   - Show seed_version, valid_from, valid_to
   - Remove "Save Changes" button

---

## Amendment Flow (Pseudocode)

```typescript
async function amendAgreement(agreementId: string) {
  // 1. Clone to new Draft
  const newAgreement = await cloneAgreement(agreementId, {
    status: 'DRAFT',
    effective_from: newEffectiveDate
  });

  // 2. Mark old as SUPERSEDED
  await updateAgreement(agreementId, {
    status: 'SUPERSEDED',
    effective_to: newEffectiveDate
  });

  // 3. Open edit form for new Draft
  openAgreementForm(newAgreement.id);
}
```

---

## Rollback Instructions

### **If migrations fail:**

```sql
-- Run in reverse order:
DROP TABLE IF EXISTS agreement_rate_snapshots CASCADE;
DROP TABLE IF NOT EXISTS agreement_custom_terms CASCADE;
DROP TABLE IF EXISTS agreements CASCADE;
DROP TABLE IF EXISTS fund_tracks CASCADE;
DROP TABLE IF EXISTS contributions CASCADE;
DROP TABLE IF EXISTS scoreboard_deal_metrics CASCADE;
DROP TABLE IF EXISTS deal_closes CASCADE;
DROP TABLE IF EXISTS investors CASCADE;
DROP TABLE IF EXISTS deals CASCADE;
DROP TABLE IF EXISTS fund_groups CASCADE;
DROP TABLE IF EXISTS partner_companies CASCADE;
DROP TABLE IF EXISTS parties CASCADE;
DROP TABLE IF EXISTS funds CASCADE;

DROP TYPE IF EXISTS track_code CASCADE;
DROP TYPE IF EXISTS agreement_status CASCADE;
DROP TYPE IF EXISTS pricing_mode CASCADE;
DROP TYPE IF EXISTS agreement_scope CASCADE;

DROP FUNCTION IF EXISTS prevent_update_on_approved CASCADE;
DROP FUNCTION IF EXISTS snapshot_rates_on_approval CASCADE;
DROP FUNCTION IF EXISTS apply_scoreboard_metrics CASCADE;
```

---

## Success Criteria

- [x] 7 migration files created
- [x] All constraints documented
- [x] Triggers implemented
- [x] Seed data prepared
- [x] CSV templates created
- [ ] Migrations applied to database (pending)
- [ ] Schema validation tests pass (pending)
- [ ] Immutability tests pass (pending)

---

**Day 1 Status:** ✅ COMPLETE (migrations ready, not yet applied)
**Next:** Apply migrations + test + begin Day 2 (UI updates)

---

_Generated: 2025-10-16_
_Migrations Directory: `supabase/migrations/20251016000000_*`_
_CSV Templates: `scripts/import-templates/*.csv`_
