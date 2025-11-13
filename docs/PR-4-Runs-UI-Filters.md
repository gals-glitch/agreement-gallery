# PR-4: Runs UI Filters + Badges

**Status:** ✅ Implemented  
**Date:** 2025-10-05

## Overview
Enhanced the Runs UI with scope/deal filtering, precedence badges with tooltips, and automatic precedence detection banners.

## Features Implemented

### 1. Filters (Scope + Deal)
**Location:** Results tab in SimplifiedCalculationDashboard

**Scope Filter:**
- Both (FUND + DEAL) - shows all fee lines
- FUND only - shows only fund-level fees
- DEAL only - shows only deal-specific fees
- Icons: Filter, Building2 (FUND), Target (DEAL)

**Deal Filter:**
- "All Deals" - shows all deals
- Individual deal selection by name + code
- Dynamically loaded from `deals` table (active only)

**Implementation:**
```typescript
const [scopeFilter, setScopeFilter] = useState<'both' | 'FUND' | 'DEAL'>('both');
const [dealFilter, setDealFilter] = useState<string>('all');
```

Filter UI placed in a dedicated Card above Run Results in the Results tab.

---

### 2. Scope Badges + Tooltips
**Location:** Calculations table in Results → Calculations tab

**Badge Display:**
- DEAL scope: Primary variant with Target icon
- FUND scope: Secondary variant with Building2 icon
- Interactive tooltip on hover

**Tooltip Content:**
- **DEAL:** "Deal-level fee: Overrides FUND agreements for this party when deal_id is present"
- **FUND:** "Fund-level fee: Applied when no deal_id or no DEAL agreement exists for this party"

**Table Columns:**
1. Scope (with badge + tooltip)
2. Entity
3. Type
4. Deal (shows deal code or "-")
5. Gross Commission
6. VAT
7. Net Commission
8. Status

**Implementation:**
- Uses `TooltipProvider` from shadcn/ui
- Cursor-help styling for visual affordance
- Max-width constraint on tooltip for readability

---

### 3. Precedence Banner
**Location:** Results tab, above the inner Tabs (overview/calculations/exceptions/approvals)

**Trigger Logic:**
Automatically detects when:
1. Same party has both FUND and DEAL agreements
2. Checks `calculations` array for party-scope combinations
3. Uses `Map<string, Set<string>>` for efficient detection

**Banner Content:**
```
⚠️ Precedence Applied: [Party Names] has/have both FUND and DEAL agreements.
DEAL-scoped fees override FUND fees for rows with a deal_id. No duplicate charges.
```

**Example:**
- If "Acme Distributor" has both FUND and DEAL agreements
- Banner shows: "Precedence Applied: Acme Distributor has both FUND and DEAL agreements..."

**Implementation:**
```typescript
const partyScopes = new Map<string, Set<string>>();
calculations.forEach((c: any) => {
  if (!partyScopes.has(c.entity_name)) {
    partyScopes.set(c.entity_name, new Set());
  }
  partyScopes.get(c.entity_name)?.add(c.scope);
});

const partiesWithBoth = Array.from(partyScopes.entries())
  .filter(([_, scopes]) => scopes.has('FUND') && scopes.has('DEAL'))
  .map(([party]) => party);
```

---

## Technical Details

### Dependencies Added
```typescript
import { Filter, Target, Building2, Info } from 'lucide-react';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { supabase } from '@/integrations/supabase/client';
```

### State Management
```typescript
// Filters
const [scopeFilter, setScopeFilter] = useState<'both' | 'FUND' | 'DEAL'>('both');
const [dealFilter, setDealFilter] = useState<string>('all');
const [deals, setDeals] = useState<Array<{ id: string; name: string; code: string }>>([]);

// Load deals from database
const loadDeals = async () => {
  const { data, error } = await supabase
    .from('deals')
    .select('id, name, code')
    .eq('is_active', true)
    .order('name');
  if (error) throw error;
  setDeals(data || []);
};
```

### Filter Logic
```typescript
calculations
  .filter((calc: any) => {
    // Apply scope filter
    if (scopeFilter !== 'both' && calc.scope !== scopeFilter) return false;
    // Apply deal filter
    if (dealFilter !== 'all' && calc.deal_id !== dealFilter) return false;
    return true;
  })
  .slice(0, 10)
  .map((calc) => (/* render row */))
```

---

## QA Checklist

### Precedence Tests
- [x] Row with `deal_id` + DEAL agreement → charges at DEAL rate
- [x] Same party's FUND agreement → ignored for that row (no duplicate)
- [x] Row without `deal_id` → FUND agreement applies
- [x] Banner appears when party has both FUND & DEAL

### Credits Tests
- [ ] FUND credit nets against both FUND and DEAL scope lines
- [ ] DEAL credit nets only against lines with matching `deal_id`
- [ ] Credits scoping verified in export

### VAT & Rounding Tests
- [ ] Included vs. on-top math verified
- [ ] 2dp ROUND_HALF_EVEN at line end
- [ ] Export shows correct VAT calculation mode

### Re-Export Tests
- [ ] Re-download from stored `run_record` (no recompute)
- [ ] Hash unchanged on re-export
- [ ] All scope/deal data preserved in export

### Export V2 Tests
- [ ] Summary sheet shows FUND vs DEAL totals
- [ ] Fee Lines include: scope, deal_id, deal_code, deal_name
- [ ] Credits Applied sheet populated
- [ ] Config Snapshot includes Fund VI tracks

---

## UI/UX Improvements

### Visual Hierarchy
1. Filters Card at top for quick access
2. Precedence banner when relevant (not cluttering otherwise)
3. Scope badges as first column for easy scanning
4. Tooltips provide context without overwhelming

### Accessibility
- Tooltips use `cursor-help` for visual affordance
- Icons paired with text labels in filters
- Color + icon redundancy (not color-only)
- Keyboard-accessible Select components

### Performance
- Deals loaded once on mount
- Filter logic runs client-side (instant feedback)
- Precedence detection computed only when visible
- Table limits to 10 rows for initial render

---

## Future Enhancements (Post PR-4)

### CSV Presets per User
- Remember column mappings per user
- Save/load import templates
- Quick-select previous configurations

### Deals Quick-Create
- Add deal from importer flow
- Auto-link to fund
- Validation for fund matching

### Export Filename Format
```
FeeRun_{RunName}_{RunID}_{YYYYMMDDHHmm}.xlsx
```
Example: `FeeRun_Q1-2025_abc123_202510051430.xlsx`

### Runs List Enhancements
- Show scope counts (e.g., "15 FUND / 8 DEAL")
- Quick filter buttons in runs list
- Visual indicators for mixed-scope runs

---

## Files Modified

### Components
- `src/components/SimplifiedCalculationDashboard.tsx` (major changes)
  - Added filters state and UI
  - Enhanced calculations table with scope column
  - Added precedence banner logic
  - Integrated TooltipProvider

### Pages
- `src/pages/CalculationRuns.tsx` (unchanged - uses SimplifiedCalculationDashboard)

### No Legacy Components
✅ Confirmed only simplified components are rendered
✅ No old CalculationEngine or FeeCalculationDashboard references
✅ Clean separation of concerns

---

## Testing Notes

### Manual Testing
1. Create mixed FUND/DEAL agreements for same party
2. Import distributions with and without `deal_id`
3. Run calculation
4. Verify filters work correctly
5. Check precedence banner appears
6. Hover tooltips on scope badges
7. Export and verify scope breakdown

### Automated Testing (Future)
- Unit tests for filter logic
- Integration tests for precedence detection
- E2E tests for full workflow
- Snapshot tests for banner rendering

---

## Deployment Checklist

### Staging
- [x] Code deployed
- [ ] QA precedence scenarios
- [ ] Validate exports
- [ ] Check RLS policies (Admin/Finance/Ops)

### Production
- [ ] Feature flag: enable DEAL scope
- [ ] Pilot run with Finance validation
- [ ] Monitor for performance issues
- [ ] User training on new filters

---

## Related PRs
- **PR-1:** Engine Precedence + Scoping
- **PR-2:** Run Record + Hash + Scope Breakdown  
- **PR-3:** Export v2 (XLSX with 4 sheets)
- **PR-4:** Runs UI Filters + Badges (this PR)

---

## Notes
- All filtering happens client-side for instant feedback
- Precedence logic matches engine implementation
- Tooltips provide contextual help without cluttering UI
- Banner only shows when actually relevant (smart detection)
