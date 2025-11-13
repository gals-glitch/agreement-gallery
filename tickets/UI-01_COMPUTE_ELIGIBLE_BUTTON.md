# UI-01: Compute Eligible Button

**Type**: Feature Enhancement
**Priority**: High
**Estimated Effort**: 4 hours
**Status**: Ready for Development

---

## Objective

Add a "Compute Eligible" button to the commissions list page that triggers batch commission computation for all contributions with party links and approved agreements.

---

## User Story

**As an** admin user
**I want to** manually trigger commission computation on-demand
**So that** I can see newly created commissions immediately after adding agreements or party links

---

## Acceptance Criteria

### Functional Requirements

- [ ] **Button Visibility**
  - Button appears on the commissions list page
  - Only visible to users with `admin` role
  - Labeled "Compute Eligible" with compute icon
  - Positioned in page header next to existing actions

- [ ] **Button Behavior**
  - Calls POST `/api/v1/commissions/batch-compute` endpoint
  - Passes all contribution IDs where:
    - Investor has `introduced_by_party_id` (not null)
    - At least one approved agreement exists for party-deal/fund pair
  - Shows loading state while request is in progress
  - Disabled during loading (prevent double-click)

- [ ] **Success Flow**
  - On success (200 response):
    - Display toast notification: "✓ Computed X commissions (Y new, Z updated)"
    - Auto-refresh commissions list
    - Scroll to top of list
  - Show breakdown in toast:
    - Number of successes
    - Number of errors (if any)

- [ ] **Error Handling**
  - On API error (4xx/5xx):
    - Display error toast: "Failed to compute commissions: [error message]"
    - Keep button enabled for retry
  - On partial success:
    - Display warning toast: "Computed X of Y contributions (Z errors)"
    - Include link to view error log (future enhancement)

### Technical Requirements

- [ ] **API Integration**
  - Use existing `/api/v1/commissions/batch-compute` endpoint
  - Request body: `{ contribution_ids: number[] }`
  - Authorization: Bearer token (admin JWT)
  - Response includes: `{ count, results: [{ contribution_id, status, commission_id?, error? }] }`

- [ ] **Pre-flight Check**
  - Query eligible contributions before API call:
    ```sql
    SELECT c.id
    FROM contributions c
    JOIN investors i ON i.id = c.investor_id
    WHERE i.introduced_by_party_id IS NOT NULL
      AND EXISTS (
        SELECT 1 FROM agreements a
        WHERE a.party_id = i.introduced_by_party_id
          AND (a.deal_id = c.deal_id OR a.fund_id = c.fund_id)
          AND a.status = 'APPROVED'
      )
    ```
  - If zero eligible: Show info toast "No eligible contributions to compute"
  - If >100 eligible: Show confirmation dialog with count before proceeding

- [ ] **Loading State**
  - Button shows spinner icon during computation
  - Text changes to "Computing..."
  - Entire button disabled (not just icon)

### UI/UX Requirements

- [ ] **Button Design**
  - Variant: `secondary` (not primary - this is a supporting action)
  - Icon: Calculator or Refresh icon from lucide-react
  - Size: Standard (same as other action buttons)
  - Position: Right side of page header, before filter/search controls

- [ ] **Toast Notifications**
  - Success: Green checkmark icon, auto-dismiss after 5 seconds
  - Error: Red X icon, manual dismiss only
  - Warning: Yellow triangle icon, auto-dismiss after 8 seconds
  - Include action counts in toast body for transparency

- [ ] **Accessibility**
  - Aria-label: "Compute commissions for eligible contributions"
  - Keyboard accessible (Enter/Space to trigger)
  - Screen reader announces loading state
  - Focus returns to button after operation completes

---

## Implementation Notes

### File Locations

**Frontend:**
- Component: `src/pages/CommissionsPage.tsx` or equivalent
- API Hook: `src/hooks/useCommissions.ts` (add `computeEligible` mutation)
- Toast: Use existing toast system (likely shadcn/ui)

**Backend:**
- Endpoint already exists: `supabase/functions/api-v1/commissions.ts`
- No backend changes needed

### Code Sketch

```tsx
// src/pages/CommissionsPage.tsx
import { Calculator } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { useToast } from '@/components/ui/use-toast';
import { useComputeEligible } from '@/hooks/useCommissions';

export function CommissionsPage() {
  const { toast } = useToast();
  const { mutate: computeEligible, isPending } = useComputeEligible();

  const handleComputeEligible = async () => {
    // Pre-flight: get eligible contribution IDs
    const eligible = await fetchEligibleContributions();

    if (eligible.length === 0) {
      toast({
        title: 'No eligible contributions',
        description: 'All contributions either have no party link or no approved agreement.',
        variant: 'default',
      });
      return;
    }

    if (eligible.length > 100) {
      // Show confirmation dialog
      const confirmed = await confirmDialog(
        `Compute ${eligible.length} contributions?`,
        'This may take a few moments.'
      );
      if (!confirmed) return;
    }

    computeEligible(
      { contribution_ids: eligible },
      {
        onSuccess: (data) => {
          const { count, results } = data;
          const successes = results.filter(r => r.status !== 'error').length;
          const errors = results.filter(r => r.status === 'error').length;

          toast({
            title: '✓ Computation complete',
            description: `${successes} commissions computed${errors > 0 ? `, ${errors} errors` : ''}`,
            variant: successes > 0 ? 'default' : 'destructive',
          });

          // Refresh list
          queryClient.invalidateQueries(['commissions']);
        },
        onError: (error) => {
          toast({
            title: 'Computation failed',
            description: error.message,
            variant: 'destructive',
          });
        },
      }
    );
  };

  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <h1>Commissions</h1>
        <Button
          variant="secondary"
          onClick={handleComputeEligible}
          disabled={isPending}
        >
          <Calculator className="mr-2 h-4 w-4" />
          {isPending ? 'Computing...' : 'Compute Eligible'}
        </Button>
      </div>
      {/* Rest of page */}
    </div>
  );
}
```

```ts
// src/hooks/useCommissions.ts
export function useComputeEligible() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ contribution_ids }: { contribution_ids: number[] }) => {
      const response = await fetch('/api/v1/commissions/batch-compute', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${getToken()}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ contribution_ids }),
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.message || 'Failed to compute commissions');
      }

      return response.json();
    },
  });
}

async function fetchEligibleContributions(): Promise<number[]> {
  // Query Supabase for eligible contribution IDs
  const { data } = await supabase
    .from('contributions')
    .select('id, investor:investors!inner(introduced_by_party_id)')
    .not('investor.introduced_by_party_id', 'is', null);

  // Filter further for those with agreements (or let backend handle this)
  return data?.map(c => c.id) || [];
}
```

---

## Testing Checklist

### Manual Testing

- [ ] **Happy Path**
  1. Create 3 contributions with party links and agreements
  2. Click "Compute Eligible"
  3. Verify toast shows "3 commissions computed"
  4. Verify 3 new draft commissions appear in list
  5. Verify list auto-refreshed

- [ ] **Zero Eligible**
  1. Ensure all contributions have commissions or no party links
  2. Click "Compute Eligible"
  3. Verify toast shows "No eligible contributions"
  4. Verify no API call made (check network tab)

- [ ] **Partial Errors**
  1. Create 5 eligible contributions (2 will fail due to missing agreement)
  2. Click "Compute Eligible"
  3. Verify toast shows "3 of 5 contributions (2 errors)"
  4. Verify only 3 commissions created

- [ ] **Permissions**
  1. Log in as non-admin user
  2. Verify button is hidden or disabled
  3. Log in as admin
  4. Verify button is visible and enabled

- [ ] **Loading State**
  1. Click "Compute Eligible" with 50+ contributions
  2. Verify button shows "Computing..." with spinner
  3. Verify button is disabled during operation
  4. Verify button returns to normal after completion

### Automated Testing

```ts
// src/pages/CommissionsPage.test.tsx
describe('Compute Eligible Button', () => {
  it('should compute eligible contributions and show success toast', async () => {
    const mockComputeEligible = vi.fn().mockResolvedValue({
      count: 3,
      results: [
        { contribution_id: 1, status: 'success', commission_id: 'uuid-1' },
        { contribution_id: 2, status: 'success', commission_id: 'uuid-2' },
        { contribution_id: 3, status: 'success', commission_id: 'uuid-3' },
      ],
    });

    render(<CommissionsPage />);

    const button = screen.getByRole('button', { name: /compute eligible/i });
    await userEvent.click(button);

    expect(mockComputeEligible).toHaveBeenCalled();
    expect(screen.getByText(/3 commissions computed/i)).toBeInTheDocument();
  });

  it('should show info toast when no eligible contributions', async () => {
    // Mock empty eligible list
    render(<CommissionsPage />);

    const button = screen.getByRole('button', { name: /compute eligible/i });
    await userEvent.click(button);

    expect(screen.getByText(/no eligible contributions/i)).toBeInTheDocument();
  });

  it('should disable button during loading', async () => {
    render(<CommissionsPage />);

    const button = screen.getByRole('button', { name: /compute eligible/i });
    await userEvent.click(button);

    expect(button).toBeDisabled();
    expect(screen.getByText(/computing/i)).toBeInTheDocument();
  });
});
```

---

## Edge Cases

1. **User navigates away during computation**
   - Abort API request on component unmount
   - Don't show toast if component is unmounted

2. **Large batch (>500 contributions)**
   - Consider chunking requests (100 at a time)
   - Show progress indicator "Computing 100/500..."

3. **Network timeout**
   - Set reasonable timeout (30 seconds)
   - Show error toast with retry option

4. **Concurrent operations**
   - Disable button if another compute is in progress
   - Queue subsequent clicks (optional enhancement)

---

## Related Tickets

- **DB-02**: Party alias remediation (will increase eligible count)
- **UI-02**: Commission detail page enhancements
- **CRON-02**: Auto-compute after agreement approval (future)

---

## Success Metrics

- **User Satisfaction**: Admins can recompute on-demand without CLI
- **Visibility**: New commissions appear immediately after agreement setup
- **Efficiency**: Reduces manual database queries by 80%

---

## Definition of Done

- [ ] Code implemented and merged to main
- [ ] Manual testing checklist completed
- [ ] Automated tests passing (>80% coverage)
- [ ] Accessible (WCAG 2.1 AA compliant)
- [ ] Documented in user guide
- [ ] Deployed to staging and tested
- [ ] Product owner sign-off

---

**Created**: 2025-11-09
**Last Updated**: 2025-11-09
**Assigned To**: TBD
**Sprint**: Next Sprint
