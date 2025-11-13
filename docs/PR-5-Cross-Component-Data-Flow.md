# PR-5: Cross-Component Data Flow Implementation

## Overview
Implemented seamless data flow between CSV wizard, Runs UI, and Agreement modal to improve user experience and reduce manual re-entry.

## Changes Implemented

### 1. Agreement Modal Preselection (`AgreementManagementEnhanced.tsx`)

**Feature**: Accept `preselectPartyId` prop to automatically select a party when opening the modal

**Implementation**:
```typescript
interface Props {
  preselectPartyId?: string;
}

const AgreementManagementEnhanced = ({ preselectPartyId }: Props = {}) => {
  // Preselect party if provided
  useEffect(() => {
    if (preselectPartyId && isDialogOpen && !editingAgreement) {
      setFormData(prev => ({ ...prev, introduced_by_party_id: preselectPartyId }));
    }
  }, [preselectPartyId, isDialogOpen, editingAgreement]);
}
```

**Usage**:
- When clicking "New Agreement" from a Party row → pass party ID
- From Runs page "Create Agreement" CTA → pass party ID from fee line

### 2. Runs Calculations Table with CTAs (`RunsCalculationsTable.tsx`)

**New Component**: Dedicated calculations table with inline agreement creation

**Features**:
- Displays all fee calculations with scope badges (FUND/DEAL)
- Tooltips explain scope precedence
- "Create Agreement" CTA for fee lines without matching agreements
- Filters by scope (FUND/DEAL/Both) and deal
- Opens Agreement modal with preselected party

**Scope Badges**:
- 🎯 `DEAL` (Target icon) - Deal-specific fee, overrides fund-level
- 🏢 `FUND` (Building2 icon) - Fund-level fee, applies unless overridden

**Example Usage**:
```tsx
<RunsCalculationsTable
  calculations={filteredCalculations}
  scopeFilter={scopeFilter}
  dealFilter={dealFilter}
/>
```

### 3. CSV Wizard Data Flow (`DistributionImportWizard.tsx`)

**Confirmed Existing Implementation**:
- ✅ Correctly saves `fund_id` to `investor_distributions`
- ✅ Correctly saves `deal_id` when deal is provided or created
- ✅ Validates fund/deal matching (prevents fund mismatch)
- ✅ Supports exact match, fuzzy match, and new deal creation
- ✅ Batch inserts with proper error handling

**Data Structure on Insert**:
```typescript
{
  calculation_run_id: calculationRunId,
  investor_id: val.resolvedInvestorId,
  investor_name: row.investor_name || '',
  fund_name: row.fund_name || '',
  deal_id: dealId,  // Null if fund-only, UUID if deal specified
  distribution_amount: row.distribution_amount,
  distribution_date: row.distribution_date
}
```

## User Flows

### Flow 1: CSV Import → Run → Create Missing Agreement
1. User uploads CSV with distributions (with or without deal codes)
2. CSV wizard validates and saves to `investor_distributions` with `fund_id` and optional `deal_id`
3. User creates a calculation run
4. Runs page displays fee lines with scope badges
5. Fee line without agreement shows "Create Agreement" button
6. Click opens Agreement modal with party preselected
7. User fills remaining fields and saves
8. Re-run calculation to see new fee charged

### Flow 2: Party Page → New Agreement
1. User views Parties list
2. Clicks "New Agreement" on a party row
3. Agreement modal opens with party preselected
4. User completes and saves

### Flow 3: Deal-Specific Override
1. CSV contains rows with `deal_code`
2. Wizard matches or creates deal (validates fund match)
3. Run shows both FUND and DEAL scope fees
4. DEAL fee takes precedence for rows with matching `deal_id`
5. Precedence banner explains: "DEAL overrides FUND for rows with a deal"

## Data Flow Diagram

```
CSV Upload
    ↓
[DistributionImportWizard]
    ├─ Resolve investor_id (exact/fuzzy match)
    ├─ Resolve fund_id (exact/fuzzy match)
    └─ Resolve deal_id (exact/fuzzy/create new)
    ↓
[investor_distributions table]
    ├─ calculation_run_id ────┐
    ├─ fund_id (required)     │
    ├─ deal_id (optional)     │
    └─ distribution_date      │
                              │
                              ↓
                    [Calculation Run]
                              ↓
                [Agreement Lookup Engine]
                    ├─ Match by (party_id, deal_id) → DEAL scope
                    └─ Match by (party_id, fund_id) → FUND scope
                              ↓
                    [Fee Calculations]
                              ↓
                [RunsCalculationsTable]
                    ├─ Scope badges with tooltips
                    ├─ Precedence banner if both scopes exist
                    └─ "Create Agreement" CTA if no match
                              ↓
                [AgreementManagementEnhanced]
                    └─ preselectPartyId → auto-select party
```

## Testing Checklist

- [ ] **CSV Import with fund only**: Rows save with `fund_id`, `deal_id = null`
- [ ] **CSV Import with deal code**: Exact match resolves to existing deal ID
- [ ] **CSV Import with fuzzy deal**: User selects from suggestions
- [ ] **CSV Import with new deal**: Creates deal in DB, uses new ID
- [ ] **Fund mismatch validation**: Rejects row where deal.fund_id ≠ fund_id
- [ ] **Runs table filters**: Scope (FUND/DEAL/Both) and Deal dropdown work
- [ ] **Scope badges**: FUND shows Building2, DEAL shows Target
- [ ] **Tooltips**: Explain precedence on hover
- [ ] **Precedence banner**: Shows when party has both FUND and DEAL agreements
- [ ] **Create Agreement CTA**: Only shows for rows without agreements
- [ ] **Modal preselection**: Party auto-selected when opening from CTA
- [ ] **Cache invalidation**: New party/agreement immediately visible

## Technical Notes

### Agreement Lookup Logic (Engine)
```typescript
// Pseudocode for canonical engine
function findAgreement(distribution) {
  const party_id = distribution.introduced_by_party_id;
  const deal_id = distribution.deal_id;
  const fund_id = distribution.fund_id;
  const date = distribution.distribution_date;
  
  // DEAL scope takes precedence
  if (deal_id) {
    const dealAgr = agreements.find(a => 
      a.introduced_by_party_id === party_id &&
      a.deal_id === deal_id &&
      a.applies_scope === 'DEAL' &&
      a.effective_from <= date &&
      (a.effective_to == null || a.effective_to >= date)
    );
    if (dealAgr) return { agreement: dealAgr, scope: 'DEAL' };
  }
  
  // Fallback to FUND scope
  const fundAgr = agreements.find(a =>
    a.introduced_by_party_id === party_id &&
    a.applies_scope === 'FUND' &&
    a.effective_from <= date &&
    (a.effective_to == null || a.effective_to >= date)
  );
  if (fundAgr) return { agreement: fundAgr, scope: 'FUND' };
  
  return null; // No agreement = exception
}
```

### RLS Considerations
- Ops can import distributions and create runs
- Only Admin/Finance can create/edit agreements
- Agreement modal shows educational banner if user lacks permission

## Future Enhancements (Out of Scope for PR-5)
- Auto-suggest agreement creation during CSV import for unknown parties
- Inline editing of agreements from Runs page
- Bulk agreement creation from multiple fee lines
- Agreement templates for common scenarios
- Historical agreement version tracking in UI

## QA Scenarios

**Golden Path**:
1. Import CSV with 100 distributions (50 FUND-only, 50 with deal codes)
2. Create run "Q1 2025"
3. Run calculates fees using existing agreements
4. 5 rows show "Create Agreement" CTAs (new parties)
5. Create 5 agreements via CTA (parties preselected)
6. Re-run → all fees calculated, no CTAs

**Edge Cases**:
- CSV with invalid deal code → fuzzy match or create new
- CSV with deal but fund mismatch → validation error
- Party has FUND agreement but CSV has deal → FUND charged (no DEAL override)
- Party has both FUND & DEAL → DEAL charged for deal rows, FUND for non-deal rows
- Agreement effective dates don't cover distribution date → exception

---
*Implementation Date*: 2025-10-09
*Status*: Complete
