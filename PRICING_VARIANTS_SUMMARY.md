# Pricing Variants - Implementation Summary

**Date**: 2025-11-10
**Status**: Database Ready, Code Pending
**Effort Remaining**: ~2-3 hours

---

## What's Done ✅

1. **Database Migration Created**: `20251110000000_add_pricing_variants.sql`
   - Adds `pricing_variant` column (BPS, BPS_SPLIT, FIXED, MGMT_FEE)
   - Adds `fixed_amount_cents` for fixed-fee agreements
   - Adds `mgmt_fee_bps` for management fee agreements
   - All existing agreements backfilled as 'BPS' automatically
   - Safe to run (backward compatible)

2. **Migration Runner**: `run_pricing_variants_migration.ps1`
   - Copies SQL to clipboard for easy execution
   - Run this in Supabase SQL Editor

3. **Complete Implementation Guide**: `PRICING_VARIANTS_IMPLEMENTATION_GUIDE.md`
   - Full code changes with line numbers
   - Testing procedures
   - Rollback plan

---

## What You Can Do NOW (with just SQL)

### Create a Fixed-Fee Agreement

```sql
-- Step 1: Create the agreement
INSERT INTO agreements (
  party_id,
  scope,
  deal_id,
  kind,
  pricing_mode,
  status,
  effective_from,
  snapshot_json
)
VALUES (
  187,  -- Capital Link (or any party_id)
  'DEAL',
  86,   -- Your deal_id
  'distributor_commission',
  'CUSTOM',
  'DRAFT',
  '2020-01-01',
  jsonb_build_object(
    'terms', jsonb_build_array(
      jsonb_build_object(
        'rate_bps', 0,
        'from', '2020-01-01',
        'to', null,
        'vat_mode', 'on_top',
        'vat_rate', 0.17
      )
    ),
    'pricing_variant', 'FIXED',
    'fixed_amount_cents', 100000  -- $1,000.00
  )
)
RETURNING id;

-- Step 2: Add custom terms
INSERT INTO agreement_custom_terms (
  agreement_id,
  upfront_bps,
  deferred_bps,
  pricing_variant,
  fixed_amount_cents
)
VALUES (
  <ID_FROM_STEP_1>,  -- Replace with returned ID
  0,
  0,
  'FIXED',
  100000  -- $1,000.00
);

-- Step 3: Approve it
UPDATE agreements
SET status = 'APPROVED'
WHERE id = <ID_FROM_STEP_1>;
```

**Result**: Agreement ready, but compute will fail until code is updated.

---

## What Needs Code Changes

### File 1: `supabase/functions/api-v1/commissionCompute.ts`

**Location**: Lines 524-566 (party-level computation section)

**What to change**: Replace the simple `rate_bps` calculation with a switch statement that handles:
- BPS: Current behavior (keep as-is)
- FIXED: Use fixed_amount_cents instead of rate calculation
- BPS_SPLIT: Use upfront_bps (defer deferred_bps for now)
- MGMT_FEE: Throw descriptive error (blocked)

**See**: `PRICING_VARIANTS_IMPLEMENTATION_GUIDE.md` Part 2 for full code

### File 2: `src/components/commissions/AppliedAgreementCard.tsx`

**Location**: Line ~41-46 (formula display)

**What to change**: Detect pricing_variant and show appropriate formula:
- FIXED: "Fixed: $1,000 + 17% VAT = $1,170"
- BPS: Current formula (unchanged)
- BPS_SPLIT: Show "upfront only" note
- MGMT_FEE: Show "blocked" message

**See**: `PRICING_VARIANTS_IMPLEMENTATION_GUIDE.md` Part 3 for full code

---

## Quick Implementation Steps

### Option A: Full Implementation (2-3 hours)

1. Run migration:
   ```powershell
   .\run_pricing_variants_migration.ps1
   ```
   Then paste in Supabase SQL Editor and run.

2. Update `commissionCompute.ts`:
   - Find lines 524-566
   - Replace with enhanced code from guide Part 2
   - Test with existing commissions (should work unchanged)

3. Update `AppliedAgreementCard.tsx`:
   - Find line ~41-46
   - Add pricing_variant switch for formula
   - Add variant badge

4. Test:
   - Create FIXED agreement via SQL
   - Click "Compute Eligible"
   - Verify fixed-fee commission created correctly

### Option B: Minimal (Just Migration)

1. Run migration only
2. All existing agreements continue working
3. New pricing variants stored but not yet used
4. Implement code changes later when needed

---

## What You'll Be Able to Do After Implementation

### 1. Fixed Fee Commissions
```
Example: Pay Capital Link $1,000 per contribution (regardless of amount)
- Create agreement with pricing_variant='FIXED', fixed_amount_cents=100000
- Every contribution generates $1,000 + $170 VAT = $1,170 commission
```

### 2. Upfront + Deferred Split
```
Example: Pay Avi Fried 0.5% now, 0.5% in 12 months
- Create agreement with pricing_variant='BPS_SPLIT'
- upfront_bps=50, deferred_bps=50
- Upfront commission computed immediately
- Deferred scheduled for later (future feature)
```

### 3. Management Fee Percentage
```
Example: Pay party 10% of quarterly mgmt fees
- Create agreement with pricing_variant='MGMT_FEE'
- mgmt_fee_bps=1000 (10%)
- Blocked until mgmt fee ledger implemented
- Graceful error message shown
```

---

## Current State vs. After Implementation

| Feature | Current | After Implementation |
|---------|---------|---------------------|
| Upfront BPS | ✅ Works | ✅ Works (unchanged) |
| Fixed Fee | ❌ Not supported | ✅ Fully working |
| Upfront + Deferred | ❌ Not supported | ⚠️ Upfront works, deferred parked |
| Mgmt Fee % | ❌ Not supported | ⚠️ Gracefully blocked with message |
| Tiers & Caps | ⚠️ Schema exists | ⚠️ Schema exists (not yet calculated) |

---

## Files Created

1. ✅ `supabase/migrations/20251110000000_add_pricing_variants.sql` - Database migration
2. ✅ `run_pricing_variants_migration.ps1` - Migration helper script
3. ✅ `PRICING_VARIANTS_IMPLEMENTATION_GUIDE.md` - Full implementation guide with code
4. ✅ `PRICING_VARIANTS_SUMMARY.md` - This summary document

---

## Next Actions

**To ship fixed-fee support today**:
1. Run migration (~5 min)
2. Update `commissionCompute.ts` (~45 min)
3. Update `AppliedAgreementCard.tsx` (~15 min)
4. Test with SQL-created agreement (~15 min)
5. **Total: ~1.5 hours**

**Or**:
- Run migration only now (~5 min)
- Implement code changes when you have time
- Everything continues working in the meantime

---

**All materials ready for implementation!** 🚀

See `PRICING_VARIANTS_IMPLEMENTATION_GUIDE.md` for detailed code changes.
