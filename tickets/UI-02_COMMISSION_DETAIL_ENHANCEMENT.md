# UI-02: Commission Detail Page - Applied Agreement Card

**Type**: Feature Enhancement
**Priority**: Medium
**Estimated Effort**: 3 hours
**Status**: Ready for Development

---

## Objective

Enhance the commission detail page with an "Applied Agreement" card that shows the agreement terms, rates, and calculation breakdown used to compute the commission.

---

## User Story

**As a** finance user reviewing a commission
**I want to** see which agreement was applied and how the amount was calculated
**So that** I can verify the commission is correct before approval

---

## Acceptance Criteria

### Functional Requirements

- [ ] **Card Display**
  - New card/section titled "Applied Agreement"
  - Appears on commission detail page below basic info
  - Shows for all commission statuses (draft, pending, approved, paid)
  - Data sourced from `commissions.snapshot_json`

- [ ] **Agreement Information**
  - Agreement ID (clickable link to agreement detail page)
  - Effective date range: "Valid from YYYY-MM-DD [to YYYY-MM-DD or 'ongoing']"
  - Agreement type: "Party-level" or "Investor-specific"
  - Status badge: Active/Superseded

- [ ] **Rate Details**
  - Upfront rate: "X bps (Y%)"
  - Deferred rate: "X bps (Y%)" (if applicable)
  - Total rate: "X bps (Y%)"
  - VAT handling: "17% VAT on top" or "VAT included" or "No VAT"

- [ ] **Calculation Breakdown**
  - Contribution amount: $X,XXX.XX
  - Applied rate: X bps
  - Base commission: $X,XXX.XX (calculation formula)
  - VAT amount: $X,XXX.XX (if applicable)
  - Total commission: $X,XXX.XX
  - Formula displayed: e.g., "$100,000 × (100 / 10,000) = $1,000 + $170 VAT = $1,170"

- [ ] **Snapshot Integrity**
  - Clearly indicate data is from snapshot (historical/immutable)
  - Show "Computed at: YYYY-MM-DD HH:MM" timestamp
  - Note: "This calculation is locked and cannot be changed"

### Technical Requirements

- [ ] **Data Source**
  - Read from `commissions.snapshot_json` field
  - Parse structure:
    ```json
    {
      "terms": [{
        "rate_bps": 100,
        "from": "2020-01-01",
        "to": null,
        "vat_mode": "on_top",
        "vat_rate": 0.17
      }],
      "computation_details": {
        "agreement_type": "party_level_legacy",
        "rate_bps": 100,
        "calculation": "100000 × (100 / 10000) = 1000",
        "applicable_term": {...}
      },
      "contribution_date": "2020-01-01",
      "contribution_amount": 100000,
      "agreement_id": 1126
    }
    ```

- [ ] **Fallback Handling**
  - If `snapshot_json` is missing: Show warning "No calculation details available"
  - If `agreement_id` is missing: Show "Agreement information unavailable"
  - If partial data: Show available fields, hide missing ones

- [ ] **Link to Agreement**
  - Agreement ID should be clickable
  - Links to `/agreements/[id]` detail page
  - Opens in same tab (not new window)
  - If agreement no longer exists (deleted): Show ID as plain text with "(deleted)" label

### UI/UX Requirements

- [ ] **Card Design**
  - Use standard card component (shadcn/ui)
  - Bordered, with subtle background
  - Icon: Scale/Balance icon for "agreement" theme
  - Collapsible: Expanded by default, can collapse to save space

- [ ] **Layout**
  - Two-column layout on desktop (left: agreement info, right: calculation)
  - Single column on mobile (stacked)
  - Use definition list (`<dl>`) for semantic HTML
  - Labels in muted color, values in normal weight

- [ ] **Visual Hierarchy**
  - Section headers: Bold, slightly larger
  - Rates: Monospace font for alignment
  - Formula: Code block style with light background
  - Total: Emphasized with larger font and bold

- [ ] **Accessibility**
  - Semantic HTML (dt/dd for term-definition pairs)
  - Aria-labels for icons
  - Screen reader announces "Applied Agreement details"
  - Keyboard navigable (collapsible accordion)

---

## Implementation Notes

### File Locations

**Frontend:**
- Component: `src/pages/CommissionDetailPage.tsx` or equivalent
- New component: `src/components/commissions/AppliedAgreementCard.tsx`
- Types: `src/types/commission.ts` (add `SnapshotJson` interface)

### Code Sketch

```tsx
// src/components/commissions/AppliedAgreementCard.tsx
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Scale, ChevronDown, ChevronUp } from 'lucide-react';
import { Badge } from '@/components/ui/badge';
import { Link } from 'react-router-dom';
import { useState } from 'react';

interface AppliedAgreementCardProps {
  snapshot: SnapshotJson;
  computedAt: string;
}

export function AppliedAgreementCard({ snapshot, computedAt }: AppliedAgreementCardProps) {
  const [isExpanded, setIsExpanded] = useState(true);

  const term = snapshot.terms?.[0];
  const details = snapshot.computation_details;
  const agreementId = snapshot.agreement_id;

  if (!term || !details) {
    return (
      <Card>
        <CardContent className="py-4">
          <p className="text-muted-foreground">No calculation details available</p>
        </CardContent>
      </Card>
    );
  }

  const rateBps = details.rate_bps || term.rate_bps;
  const ratePercent = (rateBps / 100).toFixed(2);
  const vatPercent = term.vat_rate ? (term.vat_rate * 100).toFixed(0) : null;

  return (
    <Card>
      <CardHeader className="cursor-pointer" onClick={() => setIsExpanded(!isExpanded)}>
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Scale className="h-5 w-5 text-muted-foreground" />
            <CardTitle>Applied Agreement</CardTitle>
          </div>
          {isExpanded ? <ChevronUp className="h-4 w-4" /> : <ChevronDown className="h-4 w-4" />}
        </div>
      </CardHeader>

      {isExpanded && (
        <CardContent className="grid gap-6 md:grid-cols-2">
          {/* Left Column: Agreement Info */}
          <div>
            <h3 className="font-semibold mb-3">Agreement Details</h3>
            <dl className="space-y-2">
              <div>
                <dt className="text-sm text-muted-foreground">Agreement ID</dt>
                <dd>
                  {agreementId ? (
                    <Link to={`/agreements/${agreementId}`} className="text-primary hover:underline">
                      #{agreementId}
                    </Link>
                  ) : (
                    <span className="text-muted-foreground">Not available</span>
                  )}
                </dd>
              </div>

              <div>
                <dt className="text-sm text-muted-foreground">Effective Period</dt>
                <dd>
                  {term.from} {term.to ? `to ${term.to}` : '(ongoing)'}
                </dd>
              </div>

              <div>
                <dt className="text-sm text-muted-foreground">Rate</dt>
                <dd className="font-mono">
                  {rateBps} bps ({ratePercent}%)
                </dd>
              </div>

              <div>
                <dt className="text-sm text-muted-foreground">VAT</dt>
                <dd>
                  {term.vat_mode === 'on_top' && vatPercent ? (
                    `${vatPercent}% VAT on top`
                  ) : term.vat_mode === 'included' && vatPercent ? (
                    `${vatPercent}% VAT included`
                  ) : (
                    'No VAT'
                  )}
                </dd>
              </div>
            </dl>
          </div>

          {/* Right Column: Calculation */}
          <div>
            <h3 className="font-semibold mb-3">Calculation</h3>
            <dl className="space-y-2">
              <div>
                <dt className="text-sm text-muted-foreground">Contribution Amount</dt>
                <dd className="font-mono">
                  ${snapshot.contribution_amount?.toLocaleString()}
                </dd>
              </div>

              <div>
                <dt className="text-sm text-muted-foreground">Formula</dt>
                <dd className="bg-muted/50 p-2 rounded text-sm font-mono">
                  {details.calculation || `$${snapshot.contribution_amount} × (${rateBps} / 10,000)`}
                </dd>
              </div>

              <div className="pt-2 border-t">
                <dt className="text-sm text-muted-foreground">Computed At</dt>
                <dd className="text-sm">
                  {new Date(computedAt).toLocaleString()}
                </dd>
              </div>
            </dl>

            <p className="text-xs text-muted-foreground mt-4 italic">
              This calculation is locked and cannot be changed
            </p>
          </div>
        </CardContent>
      )}
    </Card>
  );
}
```

```tsx
// src/pages/CommissionDetailPage.tsx
import { AppliedAgreementCard } from '@/components/commissions/AppliedAgreementCard';

export function CommissionDetailPage() {
  const { data: commission } = useCommission(commissionId);

  return (
    <div className="space-y-6">
      {/* Existing commission info cards */}
      <CommissionInfoCard commission={commission} />
      <ContributionCard contribution={commission.contribution} />

      {/* New: Applied Agreement Card */}
      <AppliedAgreementCard
        snapshot={commission.snapshot_json}
        computedAt={commission.computed_at}
      />

      {/* Existing action buttons */}
      <CommissionActions commission={commission} />
    </div>
  );
}
```

```ts
// src/types/commission.ts
export interface SnapshotJson {
  terms?: Array<{
    rate_bps: number;
    from: string;
    to: string | null;
    vat_mode: 'on_top' | 'included' | null;
    vat_rate: number | null;
  }>;
  computation_details?: {
    agreement_type: string;
    rate_bps: number;
    calculation: string;
    applicable_term?: any;
  };
  contribution_date?: string;
  contribution_amount?: number;
  agreement_id?: number;
  is_investor_level?: boolean;
}
```

---

## Testing Checklist

### Manual Testing

- [ ] **Standard Commission (Party-level)**
  1. Navigate to commission detail page for draft commission
  2. Verify "Applied Agreement" card is displayed
  3. Verify all fields populated correctly
  4. Click agreement ID link → navigates to agreement detail
  5. Collapse card → verify it collapses
  6. Expand card → verify it expands

- [ ] **Commission with VAT**
  1. Open commission with VAT (17% on top)
  2. Verify VAT section shows "17% VAT on top"
  3. Verify calculation includes VAT amount
  4. Verify total = base + VAT

- [ ] **Commission without VAT**
  1. Open commission with vat_mode = null
  2. Verify VAT section shows "No VAT"
  3. Verify total = base (no VAT added)

- [ ] **Responsive Design**
  1. View on desktop (>768px) → two columns
  2. View on mobile (<768px) → single column stacked
  3. Verify all content remains readable

- [ ] **Missing Data**
  1. Mock commission with empty snapshot_json
  2. Verify fallback message "No calculation details available"
  3. Verify no errors in console

- [ ] **Deleted Agreement**
  1. Commission references agreement that no longer exists
  2. Verify ID shown as plain text with "(deleted)" label
  3. Verify no broken link

### Automated Testing

```tsx
// src/components/commissions/AppliedAgreementCard.test.tsx
describe('AppliedAgreementCard', () => {
  const mockSnapshot: SnapshotJson = {
    terms: [{
      rate_bps: 100,
      from: '2020-01-01',
      to: null,
      vat_mode: 'on_top',
      vat_rate: 0.17,
    }],
    computation_details: {
      agreement_type: 'party_level_legacy',
      rate_bps: 100,
      calculation: '100000 × (100 / 10000) = 1000',
    },
    contribution_amount: 100000,
    agreement_id: 1126,
  };

  it('should render agreement details', () => {
    render(<AppliedAgreementCard snapshot={mockSnapshot} computedAt="2025-11-09T10:00:00Z" />);

    expect(screen.getByText('#1126')).toBeInTheDocument();
    expect(screen.getByText(/2020-01-01/)).toBeInTheDocument();
    expect(screen.getByText(/100 bps/)).toBeInTheDocument();
    expect(screen.getByText(/17% VAT on top/)).toBeInTheDocument();
  });

  it('should render calculation formula', () => {
    render(<AppliedAgreementCard snapshot={mockSnapshot} computedAt="2025-11-09T10:00:00Z" />);

    expect(screen.getByText(/100000 × \(100 \/ 10000\) = 1000/)).toBeInTheDocument();
  });

  it('should show fallback for missing snapshot', () => {
    render(<AppliedAgreementCard snapshot={{}} computedAt="2025-11-09T10:00:00Z" />);

    expect(screen.getByText(/no calculation details available/i)).toBeInTheDocument();
  });

  it('should toggle collapse on header click', async () => {
    render(<AppliedAgreementCard snapshot={mockSnapshot} computedAt="2025-11-09T10:00:00Z" />);

    const header = screen.getByText('Applied Agreement');
    await userEvent.click(header);

    expect(screen.queryByText(/Effective Period/)).not.toBeInTheDocument();

    await userEvent.click(header);
    expect(screen.getByText(/Effective Period/)).toBeInTheDocument();
  });
});
```

---

## Edge Cases

1. **Multiple terms in snapshot**
   - Display only the first term (most recent effective)
   - Note: Future enhancement could show history

2. **Investor-level vs Party-level**
   - Check `snapshot.is_investor_level` flag
   - Show badge: "Investor-specific" vs "Party-level"

3. **Very long calculation formula**
   - Wrap text in code block
   - Add horizontal scroll if needed

4. **Superseded agreement**
   - Show badge "Superseded" if agreement.status = 'SUPERSEDED'
   - Note: "This agreement has been replaced but calculation remains valid"

---

## Related Tickets

- **UI-01**: Compute eligible button (creates commissions this page displays)
- **AGR-03**: Agreement detail page enhancements (link destination)
- **DB-02**: Party alias remediation (increases commission volume)

---

## Success Metrics

- **Transparency**: Finance users can verify calculations without SQL queries
- **Trust**: 90% of users understand how commission was calculated
- **Efficiency**: Reduces approval time by 30% (fewer questions to admins)

---

## Definition of Done

- [ ] Code implemented and merged to main
- [ ] Manual testing checklist completed
- [ ] Automated tests passing (>85% coverage)
- [ ] Accessible (WCAG 2.1 AA compliant)
- [ ] Responsive (mobile + desktop tested)
- [ ] Documented in user guide
- [ ] Deployed to staging and tested
- [ ] Product owner sign-off

---

**Created**: 2025-11-09
**Last Updated**: 2025-11-09
**Assigned To**: TBD
**Sprint**: Next Sprint
