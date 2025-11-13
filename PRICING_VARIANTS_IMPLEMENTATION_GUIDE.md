# Pricing Variants Implementation Guide

**Status**: Ready for Implementation
**Files to Modify**: 3 core files
**Estimated Time**: 3-4 hours

---

## Summary

This guide implements support for **4 distributor commission pricing structures**:

1. **BPS** (Current, default): Upfront percentage (e.g., 100 bps = 1%)
2. **BPS_SPLIT** (New): Upfront + Deferred split (e.g., 50 bps now, 50 bps later)
3. **FIXED** (New): Fixed dollar amount per contribution (e.g., $1,000)
4. **MGMT_FEE** (Parked): Percentage of management fees (blocked, requires ledger)

---

## Part 1: Database Migration (DONE ✅)

**File**: `supabase/migrations/20251110000000_add_pricing_variants.sql`

**Run via**:
```powershell
.\run_pricing_variants_migration.ps1
```

Or manually in Supabase SQL Editor:
1. Open SQL from migration file
2. Paste and run
3. Verify: `SELECT pricing_variant, COUNT(*) FROM agreement_custom_terms GROUP BY pricing_variant;`
   - Should show all existing as 'BPS'

---

## Part 2: Update Commission Compute Engine

**File**: `supabase/functions/api-v1/commissionCompute.ts`

### Change Location: Lines 524-566 (Party-Level Legacy Computation)

**Current Code**:
```typescript
// PARTY-LEVEL AGREEMENT COMPUTATION (LEGACY)
const partySnapshot = snapshot as PartyCommissionTermSnapshot;

if (!partySnapshot.terms || partySnapshot.terms.length === 0) {
  throw new Error(`Agreement ${agreement.id} has no terms in snapshot_json`);
}

// Find term that covers contribution.paid_in_date
const applicableTerm = partySnapshot.terms.find(term => {
  const termFrom = new Date(term.from);
  const termTo = term.to ? new Date(term.to) : null;
  const contribDate = new Date(contribution.paid_in_date);

  return contribDate >= termFrom && (!termTo || contribDate < termTo);
});

if (!applicableTerm) {
  throw new Error(
    `No term in agreement ${agreement.id} covers date ${contribution.paid_in_date}`
  );
}

// Base commission = amount × (rate_bps / 10,000)
const rateBps = applicableTerm.rate_bps;
baseAmount = round2(contributionAmount * rateBps / 10000);

computationDetails = {
  agreement_type: 'party_level_legacy',
  rate_bps: rateBps,
  applicable_term: applicableTerm,
  calculation: `${contributionAmount} × (${rateBps} / 10000) = ${baseAmount}`
};

// VAT calculation
if (applicableTerm.vat_mode === 'on_top' && applicableTerm.vat_rate > 0) {
  vatAmount = round2(baseAmount * applicableTerm.vat_rate);
}
```

**Replace With**:
```typescript
// ============================================
// PARTY-LEVEL AGREEMENT COMPUTATION (ENHANCED)
// ============================================

const partySnapshot = snapshot as PartyCommissionTermSnapshot;

// Determine pricing variant from snapshot or custom_terms
// New field: pricing_variant from agreement_custom_terms
const pricingVariant = partySnapshot.pricing_variant || 'BPS'; // Default to BPS for backward compat

switch (pricingVariant) {
  case 'BPS': {
    // UPFRONT BPS ONLY (Current behavior)
    if (!partySnapshot.terms || partySnapshot.terms.length === 0) {
      throw new Error(`Agreement ${agreement.id} has no terms in snapshot_json`);
    }

    // Find term that covers contribution.paid_in_date
    const applicableTerm = partySnapshot.terms.find(term => {
      const termFrom = new Date(term.from);
      const termTo = term.to ? new Date(term.to) : null;
      const contribDate = new Date(contribution.paid_in_date);

      return contribDate >= termFrom && (!termTo || contribDate < termTo);
    });

    if (!applicableTerm) {
      throw new Error(
        `No term in agreement ${agreement.id} covers date ${contribution.paid_in_date}. ` +
        `Available terms: ${partySnapshot.terms.map(t => `${t.from} to ${t.to || 'open'}`).join(', ')}`
      );
    }

    // Base commission = amount × (rate_bps / 10,000)
    const rateBps = applicableTerm.rate_bps;
    baseAmount = round2(contributionAmount * rateBps / 10000);

    computationDetails = {
      agreement_type: 'party_level_bps',
      pricing_variant: 'BPS',
      rate_bps: rateBps,
      applicable_term: applicableTerm,
      calculation: `${contributionAmount} × (${rateBps} / 10000) = ${baseAmount}`
    };

    // VAT calculation
    if (applicableTerm.vat_mode === 'on_top' && applicableTerm.vat_rate > 0) {
      vatAmount = round2(baseAmount * applicableTerm.vat_rate);
    }
    break;
  }

  case 'BPS_SPLIT': {
    // UPFRONT + DEFERRED BPS (Future: schedule deferred payment)
    if (!partySnapshot.terms || partySnapshot.terms.length === 0) {
      throw new Error(`Agreement ${agreement.id} has no terms in snapshot_json`);
    }

    const applicableTerm = partySnapshot.terms.find(term => {
      const termFrom = new Date(term.from);
      const termTo = term.to ? new Date(term.to) : null;
      const contribDate = new Date(contribution.paid_in_date);

      return contribDate >= termFrom && (!termTo || contribDate < termTo);
    });

    if (!applicableTerm) {
      throw new Error(`No term covers date ${contribution.paid_in_date} for agreement ${agreement.id}`);
    }

    // For now: Only compute UPFRONT portion
    // TODO: Implement deferred payment scheduling
    const upfrontBps = partySnapshot.upfront_bps || applicableTerm.rate_bps;
    const deferredBps = partySnapshot.deferred_bps || 0;

    baseAmount = round2(contributionAmount * upfrontBps / 10000);

    computationDetails = {
      agreement_type: 'party_level_bps_split',
      pricing_variant: 'BPS_SPLIT',
      upfront_bps: upfrontBps,
      deferred_bps: deferredBps,
      calculation: `${contributionAmount} × (${upfrontBps} / 10000) = ${baseAmount} (upfront only, deferred not scheduled yet)`
    };

    // VAT on upfront portion
    if (applicableTerm.vat_mode === 'on_top' && applicableTerm.vat_rate > 0) {
      vatAmount = round2(baseAmount * applicableTerm.vat_rate);
    }
    break;
  }

  case 'FIXED': {
    // FIXED DOLLAR AMOUNT per contribution
    const fixedAmountCents = partySnapshot.fixed_amount_cents;

    if (!fixedAmountCents || fixedAmountCents <= 0) {
      throw new Error(`Agreement ${agreement.id} has FIXED pricing but no valid fixed_amount_cents`);
    }

    // Convert cents to dollars
    baseAmount = round2(fixedAmountCents / 100);

    computationDetails = {
      agreement_type: 'party_level_fixed',
      pricing_variant: 'FIXED',
      fixed_amount_usd: baseAmount,
      calculation: `Fixed: $${baseAmount.toLocaleString()} per contribution`
    };

    // VAT on fixed amount
    const vatRate = partySnapshot.terms?.[0]?.vat_rate || 0;
    const vatMode = partySnapshot.terms?.[0]?.vat_mode || null;

    if (vatMode === 'on_top' && vatRate > 0) {
      vatAmount = round2(baseAmount * vatRate);
    }
    break;
  }

  case 'MGMT_FEE': {
    // MANAGEMENT FEE PERCENTAGE (Not computable yet - requires mgmt fee ledger)
    throw new Error(
      `Agreement ${agreement.id} uses MGMT_FEE pricing which requires a management fee ledger. ` +
      `This feature is not yet implemented. Commission computation blocked.`
    );
  }

  default:
    throw new Error(`Unknown pricing_variant '${pricingVariant}' in agreement ${agreement.id}`);
}
```

### Additional Type Definitions

Add to **top of file** (around line 34):

```typescript
// Enhanced party-level snapshot with pricing variants
interface PartyCommissionTermSnapshot {
  kind: 'distributor_commission';
  party_id: string;
  party_name: string;
  scope: {
    fund_id: number | null;
    deal_id: number | null;
  };
  terms: Array<{
    from: string;          // ISO date
    to: string | null;     // ISO date or null for open-ended
    rate_bps: number;      // Basis points (250 = 2.5%)
    vat_mode: 'on_top' | 'included' | null;
    vat_rate: number;      // Decimal (0.2 = 20%)
  }>;
  vat_admin_snapshot?: {
    jurisdiction: string;
    rate: number;
    effective_at: string;
  };
  // NEW: Pricing variant fields
  pricing_variant?: 'BPS' | 'BPS_SPLIT' | 'FIXED' | 'MGMT_FEE';
  upfront_bps?: number;
  deferred_bps?: number;
  fixed_amount_cents?: number;
  mgmt_fee_bps?: number;
}
```

---

## Part 3: Update Applied Agreement Card (UI-02)

**File**: `src/components/commissions/AppliedAgreementCard.tsx`

### Update Formula Display

**Current Line ~41-46**:
```typescript
const formula =
  calc.formula_human ??
  `$${calc.base_amount.toLocaleString()} × (${agreement.rate_bps} / 10,000) = $${calc.commission_amount.toLocaleString()} + ${agreement.vat_percent}% VAT = $${calc.total_amount.toLocaleString()}`;
```

**Replace With**:
```typescript
// Detect pricing variant from snapshot or default to BPS
const pricingVariant = (calc as any).pricing_variant || 'BPS';

let formula: string;
switch (pricingVariant) {
  case 'FIXED':
    formula = `Fixed: $${calc.commission_amount.toLocaleString()} + ${agreement.vat_percent}% VAT = $${calc.total_amount.toLocaleString()}`;
    break;

  case 'BPS_SPLIT':
    formula = calc.formula_human ??
      `$${calc.base_amount.toLocaleString()} × (${agreement.rate_bps} / 10,000) = $${calc.commission_amount.toLocaleString()} (upfront) + ${agreement.vat_percent}% VAT`;
    break;

  case 'MGMT_FEE':
    formula = `Blocked: Requires management fee ledger (coming soon)`;
    break;

  case 'BPS':
  default:
    formula = calc.formula_human ??
      `$${calc.base_amount.toLocaleString()} × (${agreement.rate_bps} / 10,000) = $${calc.commission_amount.toLocaleString()} + ${agreement.vat_percent}% VAT = $${calc.total_amount.toLocaleString()}`;
    break;
}
```

### Add Pricing Variant Badge

**Add after line ~67** (inside the card):
```typescript
<div className="flex justify-between items-center mt-2">
  <span className="text-xs text-muted-foreground">Pricing Structure:</span>
  <Badge variant="secondary">
    {pricingVariant === 'BPS' && 'Upfront (bps)'}
    {pricingVariant === 'BPS_SPLIT' && 'Upfront + Deferred'}
    {pricingVariant === 'FIXED' && 'Fixed Fee'}
    {pricingVariant === 'MGMT_FEE' && 'Mgmt Fee %'}
  </Badge>
</div>
```

---

## Part 4: Create Agreement Form UI (Future Enhancement)

**File**: `src/components/agreements/AgreementForm.tsx` (may need to be created)

**Scaffold** (not implementing full form now, just outline):

```typescript
// Pricing Structure Selector
<Select value={pricingVariant} onValueChange={setPricingVariant}>
  <SelectItem value="BPS">Upfront (bps)</SelectItem>
  <SelectItem value="BPS_SPLIT">Upfront + Deferred</SelectItem>
  <SelectItem value="FIXED">Fixed (per contribution)</SelectItem>
  <SelectItem value="MGMT_FEE" disabled>Mgmt Fee % (coming soon)</SelectItem>
</Select>

{/* Conditional Fields */}
{pricingVariant === 'BPS' && (
  <NumberField name="upfront_bps" label="Upfront Rate (bps)" required />
)}

{pricingVariant === 'BPS_SPLIT' && (
  <>
    <NumberField name="upfront_bps" label="Upfront (bps)" required />
    <NumberField name="deferred_bps" label="Deferred (bps)" required />
    <Alert variant="warning">
      Deferred payout scheduling not yet implemented
    </Alert>
  </>
)}

{pricingVariant === 'FIXED' && (
  <CurrencyField name="fixed_amount" label="Fixed Amount (USD)" required />
)}

{pricingVariant === 'MGMT_FEE' && (
  <>
    <NumberField name="mgmt_fee_bps" label="Mgmt Fee (bps)" disabled />
    <Alert variant="info">
      Blocked until management fee ledger is implemented
    </Alert>
  </>
)}
```

---

## Testing Plan

### Test 1: BPS (Existing Behavior)
1. No changes needed
2. All existing 30 commissions continue working
3. Verify: Totals unchanged ($42,435.90)

### Test 2: FIXED Fee
1. Create new agreement via SQL:
```sql
-- Create agreement
INSERT INTO agreements (party_id, scope, deal_id, kind, pricing_mode, status, effective_from)
VALUES (187, 'DEAL', 86, 'distributor_commission', 'CUSTOM', 'APPROVED', '2020-01-01');

-- Add custom terms with FIXED pricing
INSERT INTO agreement_custom_terms (agreement_id, upfront_bps, deferred_bps, pricing_variant, fixed_amount_cents)
VALUES (
  (SELECT id FROM agreements WHERE party_id = 187 AND deal_id = 86 ORDER BY created_at DESC LIMIT 1),
  0,  -- No BPS
  0,
  'FIXED',
  100000  -- $1,000.00
);
```

2. Update snapshot_json to include pricing_variant:
```sql
UPDATE agreements
SET snapshot_json = snapshot_json || '{"pricing_variant": "FIXED", "fixed_amount_cents": 100000}'::jsonb
WHERE id = (SELECT id FROM agreements WHERE party_id = 187 AND deal_id = 86 ORDER BY created_at DESC LIMIT 1);
```

3. Click "Compute Eligible" button
4. Expected: New commission shows $1,000 + $170 VAT = $1,170

### Test 3: MGMT_FEE (Blocked)
1. Create agreement with MGMT_FEE variant
2. Try to compute
3. Expected: Error message "requires management fee ledger"
4. Commission NOT created (blocked gracefully)

---

## Rollback Plan

If issues arise:

1. **Revert Migration**:
```sql
BEGIN;
ALTER TABLE agreement_custom_terms DROP COLUMN pricing_variant;
ALTER TABLE agreement_custom_terms DROP COLUMN fixed_amount_cents;
ALTER TABLE agreement_custom_terms DROP COLUMN mgmt_fee_bps;
COMMIT;
```

2. **Revert Code**: Git revert the compute engine changes

3. **Verify**: All existing commissions still compute correctly

---

## Success Criteria

- [ ] Migration runs without errors
- [ ] All existing BPS agreements continue working (30 commissions unchanged)
- [ ] Can create FIXED agreement via SQL and compute commission
- [ ] Fixed-fee commission shows correct formula in UI
- [ ] MGMT_FEE agreements are gracefully blocked with clear error
- [ ] "Compute Eligible" button includes fixed-fee results in toast
- [ ] Applied Agreement Card shows pricing variant badge

---

## Next Steps After Implementation

1. **UI Form** (2-3 hours): Build full agreement creation UI with pricing picker
2. **Deferred Scheduling** (4-6 hours): Implement deferred payment logic
3. **Mgmt Fee Ledger** (8-12 hours): Build management fee tracking system
4. **Tiers & Caps** (6-8 hours): Implement tiered rates and cap limits

---

**Ready to implement! Start with Part 2 (Compute Engine) since migration is already done.**
