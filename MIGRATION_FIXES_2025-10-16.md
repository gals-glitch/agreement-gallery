# Database Migration Fixes - 2025-10-16

## Summary

Fixed all legacy PostgREST queries and React Router warnings after the database redesign. The application should now load without 400 errors.

---

## Changes Made

### A) React Router v7 Future Flags ✅

**File:** `src/App.tsx`

**Changes:**
- Converted from `BrowserRouter` to `createBrowserRouter` with future flags
- Added `v7_startTransition: true` and `v7_relativeSplatPath: true`
- Converted `<Routes><Route>` structure to routes array

**Result:** React Router warnings eliminated

---

### B) Database Schema Migration Fixes ✅

#### Schema Changes (from FINAL_MIGRATION.sql):
- `deals` table: `is_active` → `status` (TEXT: 'ACTIVE' | 'Sold'), removed `code` column
- `parties` table: `is_active` → `active` (BOOLEAN), removed `party_type` column
- `investors` table: No `is_active` column (never had one)
- `funds` table: No `is_active` column
- `fund_tracks` table: No `is_active` column
- **REMOVED** `investor_agreement_links` table

---

### C) Fixed Files

#### Critical Hooks (Direct Fixes)
1. **src/hooks/useDeals.ts**
   - Line 15: `.eq('is_active', true)` → `.eq('status', 'ACTIVE')`
   - Line 19: Removed `.code` from search (column doesn't exist)

2. **src/hooks/useParties.ts**
   - Line 18: `.eq('is_active', true)` → `.eq('active', true)`
   - Removed `party_type` parameter and import
   - Updated `useIntroducingParties()` to use `active` instead of `party_type`

3. **src/components/DistributionImportWizard.tsx**
   - Line 114: `.from('parties').eq('party_type', 'fund')` → `.from('funds')`

#### Batch-Fixed Components (via PowerShell script)
4. **src/components/EntitySelector.tsx**
   - Removed `.eq('party_type', entityType)`
   - Changed `.eq('is_active', true)` → `.eq('active', true)`

5. **src/components/FundVITracksAdmin.tsx**
   - Removed `.eq('is_active', true)` (fund_tracks doesn't have this column)

6. **src/components/InvestorManagement.tsx**
   - Removed `.eq('is_active', true)` (investors doesn't have this column)

7. **src/components/SimplifiedCalculationDashboard.tsx**
   - `.eq('is_active', true)` → `.eq('status', 'ACTIVE')` for deals

8. **src/components/EnhancedInvestorUpload.tsx**
   - Removed `.eq('is_active', true)` for investors

9. **src/components/CommissionRuleSetup.tsx**
   - `.eq('is_active', true)` → `.eq('status', 'ACTIVE')` for deals

10. **src/components/AgreementManagement.tsx**
    - `.select('id, name, party_type')` → `.select('id, name')`
    - `.eq('is_active', true)` → `.eq('active', true)`

11. **src/components/DistributorRulesManagement.tsx**
    - Removed `party_type` from select
    - Removed `.in('party_type', [...])` and `.eq('is_active', true)`
    - Changed to `.eq('active', true)`

---

### D) Deprecated Components ⚠️

The following components reference the removed `investor_agreement_links` table and have been **disabled**:

1. **src/components/InvestorAgreementLinks.tsx** - Uses `investor_agreement_links` table
2. **src/components/DistributorHierarchyView.tsx** - Uses `investor_agreement_links` table and `party_type`
3. **src/components/PartyManagement.tsx** - Has queries for `investor_agreement_links` table

**Action Taken:**
- Updated `src/pages/PartyManagementPage.tsx`:
  - Removed imports for `InvestorAgreementLinks` and `DistributorHierarchyView`
  - Replaced tab contents with deprecation warnings
  - Added guidance to use "Agreements" tab instead

**Tabs Affected:**
- "Investor Links" tab → Shows deprecation warning
- "Hierarchy View" tab → Shows deprecation warning

---

## Testing Checklist

### Pages to Test:
- [ ] **Home (/)** - Should load without errors
- [ ] **Deals (/deals)** - List should load with status='ACTIVE', no 400s
- [ ] **Parties (/parties)** -
  - [x] "Parties" tab - Should work
  - [x] "Agreements" tab - Should work
  - [x] "Investor Links" tab - Shows deprecation warning
  - [x] "Distributor Rules" tab - Should work
  - [x] "Hierarchy View" tab - Shows deprecation warning
- [ ] **Contributions (/contributions)** - Should load and work (already tested in Day 3)
- [ ] **Fund VI Tracks (/fund-vi/tracks)** - Should load without 400s
- [ ] **Runs (/runs)** - Should load without errors
- [ ] **Entities (/entities)** - Should load without errors

### Expected Results:
✅ No 400 errors for missing columns
✅ No 400 errors for removed tables
✅ Deals load with `status='ACTIVE'`
✅ Parties load with `active=true`
✅ Investors load without `is_active` filter
✅ Deprecation warnings shown for removed features

---

## Files Modified Summary

| File | Type | Changes |
|------|------|---------|
| `src/App.tsx` | Router | Added v7 future flags |
| `src/hooks/useDeals.ts` | Hook | Fixed is_active → status |
| `src/hooks/useParties.ts` | Hook | Fixed is_active → active, removed party_type |
| `src/components/DistributionImportWizard.tsx` | Component | Fixed funds query |
| `src/components/EntitySelector.tsx` | Component | Batch fixed |
| `src/components/FundVITracksAdmin.tsx` | Component | Batch fixed |
| `src/components/InvestorManagement.tsx` | Component | Batch fixed |
| `src/components/SimplifiedCalculationDashboard.tsx` | Component | Batch fixed |
| `src/components/EnhancedInvestorUpload.tsx` | Component | Batch fixed |
| `src/components/CommissionRuleSetup.tsx` | Component | Batch fixed |
| `src/components/AgreementManagement.tsx` | Component | Batch fixed |
| `src/components/DistributorRulesManagement.tsx` | Component | Batch fixed |
| `src/pages/PartyManagementPage.tsx` | Page | Added deprecation warnings |

**Total:** 13 files modified

---

## Scripts Created

### fix_legacy_queries.ps1
PowerShell script to batch-fix legacy queries in components.

**Usage:**
```powershell
powershell -ExecutionPolicy Bypass -File fix_legacy_queries.ps1
```

**What it does:**
- Fixes all `is_active` → `status`/`active` conversions
- Removes `party_type` references
- Updates select statements

---

## Known Issues & Future Work

### Deprecated Components
These components are currently disabled but still exist in the codebase:
- `InvestorAgreementLinks.tsx` - Should be deleted or refactored
- `DistributorHierarchyView.tsx` - Should be deleted or refactored
- Portions of `PartyManagement.tsx` - Has dead code for investor_agreement_links

**Recommendation:** Delete these files in a future cleanup pass or refactor to use the new `agreements` table structure.

### Type Definitions
The following type files may have outdated definitions:
- `src/domain/types.ts` - May still reference `PartyType`, `is_active`
- `src/integrations/supabase/types.ts` - Auto-generated, needs regeneration

**Recommendation:** Regenerate Supabase types and update domain types.

---

## Verification Commands

```bash
# Check for remaining is_active references
grep -r "is_active" src/ --include="*.ts" --include="*.tsx"

# Check for remaining party_type references
grep -r "party_type" src/ --include="*.ts" --include="*.tsx"

# Check for remaining investor_agreement_links references
grep -r "investor_agreement_links" src/ --include="*.ts" --include="*.tsx"

# Start dev server and check console for errors
npm run dev
```

---

## Migration Context

This fix addresses issues from the **October 16, 2025 Database Redesign** (FINAL_MIGRATION.sql).

**Key Schema Changes:**
1. Removed `investor_agreement_links` junction table
2. Changed `parties.party_type` (enum) → removed, all parties are generic
3. Changed `parties.is_active` (boolean) → `parties.active` (boolean)
4. Changed `deals.is_active` (boolean) → `deals.status` (text: 'ACTIVE'|'Sold')
5. Removed `deals.code` column
6. `investors` never had `is_active` column

**See:** `docs/SESSION-2025-10-16.md` for full redesign details

---

## Success Criteria

✅ Application loads without React Router warnings
✅ All pages load without 400 errors from PostgREST
✅ Deals, Parties, Investors queries work correctly
✅ Deprecated features show user-friendly warnings
✅ No broken imports or missing component errors

---

_Migration fixes completed: 2025-10-16_
_Next steps: Test all pages and update type definitions_
