# Developer Finish Plan (No Manual Steps)

**Status:** 75% complete (3/4 tickets done)
**Time to completion:** 1-2 days
**Approach:** Fully automated - no SQL pasting required

---

## A) Backend Owner - Finish DB-01 + Imports (Same Day)

### Step 1: Apply Migrations via CLI

```powershell
# Pull latest from repo (if needed)
git pull

# Set Supabase credentials (if not already set)
# $env:SUPABASE_ACCESS_TOKEN = "your-token"

# Apply both migrations automatically
supabase db push
```

**What this does:**
- Applies `20251102_add_investor_party_fk.sql` (DB-01)
- Applies `20251102_create_import_infrastructure.sql` (IMP-01)
- Creates `party_aliases` table
- Backfills investor→party links from notes
- Creates staging tables for imports

**Expected output:**
```
✔ Applying migration 20251102_add_investor_party_fk.sql...
✔ Applying migration 20251102_create_import_infrastructure.sql...
Finished supabase db push.
```

---

### Step 2: Verify Automatically

```powershell
# Set service key
.\set_key.ps1

# Run automated verification
.\verify_db01.ps1
```

**Success criteria:**
- ✅ `introduced_by_party_id` column exists
- ✅ ≥80% of investors have party links
- ✅ Coverage gaps clearly identified

**If <80% coverage:**
```sql
-- Add aliases for fuzzy matching
INSERT INTO party_aliases (alias, party_id, created_by) VALUES
  ('Avi F.', 182, 'manual'),
  ('Capital Link - Shiri', 187, 'manual')
ON CONFLICT (alias) DO NOTHING;

-- Rerun backfill section from migration
UPDATE investors i
SET introduced_by_party_id = a.party_id
FROM party_aliases a
WHERE i.introduced_by_party_id IS NULL
  AND i.notes ~ 'Introduced by:\s*'
  AND trim(regexp_replace(i.notes, '.*Introduced by:\s*([^;]+).*', '\1')) = a.alias;
```

Then rerun: `.\verify_db01.ps1`

---

### Step 3: Smoke-Test Import API

```powershell
# Set environment
$env:SUPABASE_URL = "https://qwgicrdcoqdketqhxbys.supabase.co"
$env:SUPABASE_SERVICE_ROLE_KEY = "your-key"

# Preview mode (dry run - no DB writes)
npm run import:all -- --dir "./sample_csvs" --mode preview

# Review output, then commit
npm run import:all -- --dir "./sample_csvs" --mode commit
```

**Acceptance criteria:**
- ✅ Preview returns counts + diffs, **no writes to DB**
- ✅ Commit writes to staging, then promoted to prod tables
- ✅ **Idempotent:** Repeat commit → 0 duplicates

**Test idempotency:**
```powershell
# Run commit twice - second run should show 0 inserts
npm run import:all -- --dir "./sample_csvs" --mode commit
npm run import:all -- --dir "./sample_csvs" --mode commit  # Should skip all existing
```

---

### Backend Checklist

- [ ] `supabase db push` applied both migrations
- [ ] `verify_db01.ps1` shows ≥80% coverage (or alias backfill applied)
- [ ] Import API preview/commit passing
- [ ] Idempotency verified (re-run commit → 0 duplicates)
- [ ] `scripts/verify_ready_to_compute.sql` shows eligible rows

---

## B) Frontend Owner - UI-01 (1 Dev Day)

### Component 1: Commissions List - "Compute Eligible" Button

**File:** `src/pages/Commissions.tsx`

**Implementation:**
```typescript
// Add state
const [isComputing, setIsComputing] = useState(false);
const [eligibleCount, setEligibleCount] = useState(0);

// RBAC check - only show to admin
const { user } = useAuth();
const isAdmin = user?.roles?.includes('admin');

// Fetch eligible count (optional)
useEffect(() => {
  if (isAdmin) {
    fetchEligibleCount().then(setEligibleCount);
  }
}, [isAdmin]);

// Compute handler
async function handleComputeEligible() {
  setIsComputing(true);
  try {
    const response = await fetch(
      `${API_BASE}/commissions/batch-compute`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${session?.access_token}`,
          'apikey': SUPABASE_ANON_KEY,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          contribution_ids: [] // Empty = compute all eligible
        })
      }
    );

    const result = await response.json();

    toast.success(`Created ${result.count} commissions`, {
      description: `Success: ${result.results.filter(r => r.success).length}, Skipped: ${result.results.filter(r => !r.success).length}`
    });

    // Refresh list
    await refetch();
  } catch (error) {
    toast.error('Failed to compute commissions');
  } finally {
    setIsComputing(false);
  }
}

// Render button
{isAdmin && (
  <Button
    onClick={handleComputeEligible}
    disabled={isComputing}
  >
    {isComputing ? 'Computing...' : `Compute Eligible (${eligibleCount})`}
  </Button>
)}
```

---

### Component 2: Commission Detail - Applied Agreement Card

**File:** `src/pages/CommissionDetail.tsx`

**Implementation:**
```typescript
// Fetch commission with agreement snapshot
const { data: commission } = useQuery({
  queryKey: ['commission', id],
  queryFn: async () => {
    const response = await fetch(
      `${API_BASE}/commissions/${id}`,
      {
        headers: {
          'Authorization': `Bearer ${session?.access_token}`,
          'apikey': SUPABASE_ANON_KEY,
        }
      }
    );
    return response.json();
  }
});

// Render agreement card
<Card>
  <CardHeader>
    <CardTitle>Applied Agreement</CardTitle>
  </CardHeader>
  <CardContent>
    <div className="space-y-2">
      <div>
        <Label>Party</Label>
        <p>{commission.party_name}</p>
      </div>
      <div>
        <Label>Deal</Label>
        <p>{commission.deal_name}</p>
      </div>
      <div className="grid grid-cols-2 gap-4">
        <div>
          <Label>Commission Rate</Label>
          <p>{commission.snapshot_json?.rate_bps / 100}%</p>
        </div>
        <div>
          <Label>VAT Rate</Label>
          <p>{commission.snapshot_json?.vat_rate * 100}%</p>
        </div>
      </div>
      <div>
        <Label>VAT Mode</Label>
        <p>{commission.snapshot_json?.vat_mode}</p>
      </div>
      <div>
        <Label>Effective Period</Label>
        <p>{commission.snapshot_json?.effective_from} to {commission.snapshot_json?.effective_to || 'Present'}</p>
      </div>
    </div>

    {/* Collapsible JSON snapshot */}
    <Collapsible className="mt-4">
      <CollapsibleTrigger>
        <Button variant="ghost" size="sm">
          View Agreement Snapshot (JSON)
        </Button>
      </CollapsibleTrigger>
      <CollapsibleContent>
        <pre className="bg-muted p-4 rounded-lg overflow-auto text-xs">
          {JSON.stringify(commission.snapshot_json, null, 2)}
        </pre>
      </CollapsibleContent>
    </Collapsible>
  </CardContent>
</Card>
```

---

### Frontend Checklist

- [ ] "Compute eligible" button wired to `/commissions/batch-compute`
- [ ] Button only visible to admin (`user?.roles?.includes('admin')`)
- [ ] Button disabled while computing
- [ ] Toast shows success/error with counts
- [ ] List refreshes after compute completes
- [ ] Agreement card on detail shows correct terms
- [ ] JSON snapshot collapsible works
- [ ] No UI/console errors

---

## C) QA Owner - System Validation (Gate C)

### Automated Validation Script

```powershell
# Run complete validation suite
.\run_gate_c.ps1
```

**What it does:**
1. Runs `scripts/verify_ready_to_compute.sql` → captures eligible count
2. Triggers batch compute (via API)
3. Runs `scripts/verify_coverage_gaps.sql` → ensures 0 gaps
4. Tests workflow: draft → pending → approved
5. Tests auth: service key 403 on mark-paid, admin succeeds
6. Exports verification report

---

### Manual Validation Steps

**1. Check eligible contributions:**
```sql
-- Run in Supabase SQL Editor
\i scripts/verify_ready_to_compute.sql
```

**Expected output:**
```
ready_to_compute | unique_investors | unique_parties | total_value
       50        |        25        |       8        |   500000
```

---

**2. Run batch compute:**
- **Via UI:** Click "Compute Eligible" button (if UI-01 complete)
- **Via script:** `.\CMP_01_simple.ps1`

**Expected output:**
```
Success: 50
Errors: 0
```

---

**3. Check coverage gaps:**
```sql
-- Run in Supabase SQL Editor
\i scripts/verify_coverage_gaps.sql
```

**Expected output:**
```
(0 rows)  -- No gaps = perfect coverage
```

---

**4. Test workflow:**
```powershell
# Set service key
.\set_key.ps1

# Test full workflow
.\test_workflow.ps1
```

**Expected output:**
```
Step 1: Submit (draft -> pending) ✅
Step 2: Approve (pending -> approved) ✅
Step 3: Mark as Paid (approved -> paid) ❌ 403 Forbidden (expected - service key blocked)

Final status: approved
```

---

**5. Test mark-paid with admin JWT (via UI):**
- Login as admin in UI
- Navigate to commission detail
- Click "Mark as Paid"
- Expected: Status changes to "paid" ✅

---

### QA Checklist

- [ ] Coverage = Eligible == Built (0 gaps)
- [ ] Math deltas: VAT/total accurate (tolerance ±$0.01)
- [ ] Workflow transitions working (draft → pending → approved)
- [ ] Auth: service key 403 on mark-paid ✅
- [ ] Auth: admin JWT succeeds on mark-paid ✅
- [ ] Idempotency: re-run batch → 0 duplicates
- [ ] Screenshots captured (list + detail)

---

## Fast Fixes (If Something's Off)

### Issue: Coverage <80%

**Root cause:** Missing `introduced_by_party_id` or party names don't match

**Fix:**
```sql
-- Add party aliases for fuzzy matching
INSERT INTO party_aliases (alias, party_id, created_by) VALUES
  ('Avi F.', (SELECT id FROM parties WHERE name = 'Avi Fried'), 'manual'),
  ('Capital Link', (SELECT id FROM parties WHERE name LIKE 'Capital Link%' LIMIT 1), 'manual')
ON CONFLICT (alias) DO NOTHING;

-- Rerun backfill
UPDATE investors i
SET introduced_by_party_id = a.party_id
FROM party_aliases a
WHERE i.introduced_by_party_id IS NULL
  AND i.notes ~ 'Introduced by:\s*'
  AND trim(regexp_replace(i.notes, '.*Introduced by:\s*([^;]+).*', '\1')) = a.alias;

-- Verify
SELECT COUNT(*) * 100.0 / (SELECT COUNT(*) FROM investors) AS coverage_pct
FROM investors WHERE introduced_by_party_id IS NOT NULL;
```

---

### Issue: Coverage gaps (deals without agreements)

**Root cause:** Party-deal combinations missing approved agreements

**Fix (seed default 100 bps agreements for high-volume gaps only):**
```sql
-- Find high-volume gaps (≥5 contributions)
WITH gaps AS (
  SELECT
    i.introduced_by_party_id AS party_id,
    c.deal_id,
    COUNT(*) AS blocked_contributions
  FROM contributions c
  JOIN investors i ON i.id = c.investor_id
  LEFT JOIN agreements a ON a.party_id = i.introduced_by_party_id
                        AND a.deal_id = c.deal_id
                        AND a.status = 'APPROVED'
  WHERE a.id IS NULL
    AND i.introduced_by_party_id IS NOT NULL
  GROUP BY i.introduced_by_party_id, c.deal_id
  HAVING COUNT(*) >= 5
)
INSERT INTO agreements (party_id, deal_id, kind, pricing_mode, status, effective_from, snapshot_json)
SELECT
  party_id,
  deal_id,
  'INVESTOR',
  'CUSTOM',
  'DRAFT',  -- Review before approving
  '2020-01-01',
  '{"rate_bps": 100, "vat_mode": "on_top", "vat_rate": 0.17, "auto_seeded": true}'::jsonb
FROM gaps;

-- Review seeded agreements in UI, then approve manually
```

---

### Issue: Math deltas (VAT/total off)

**Expected formula:**
```
base_amount = contribution_amount * (rate_bps / 10000)
vat_amount = base_amount * vat_rate
total_amount = base_amount + vat_amount
```

**Validation query:**
```sql
SELECT
  id,
  base_amount,
  vat_amount,
  total_amount,
  base_amount + vat_amount AS calculated_total,
  ABS(total_amount - (base_amount + vat_amount)) AS delta
FROM commissions
WHERE ABS(total_amount - (base_amount + vat_amount)) > 0.01
LIMIT 10;
```

**If deltas found:** Check rounding in `commissionCompute.ts` (should use `Math.round(value * 100) / 100`)

---

### Issue: Auth drift (service key has admin powers)

**Root cause:** RBAC check missing or service key granted admin role

**Fix:**
```typescript
// In Edge Function - ensure service key blocked for mark-paid
if (action === 'mark-paid' && userId === 'SERVICE') {
  return forbiddenError('mark-paid requires admin user JWT', corsHeaders);
}
```

**Verify:**
```bash
# Should return 403
curl -X POST "https://.../commissions/{id}/mark-paid" \
  -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
  -d '{"payment_date": "2025-11-02"}'
```

---

## Deliverables for Review

### 1. Updated EXECUTION_STATUS.md

```markdown
| Metric | Current | Target | Status |
|--------|---------|--------|--------|
| Backend Tickets | 4/4 | 4/4 | ✅ 100% |
| Investor Coverage | 85% | 85% | ✅ Pass |
| CSV Import | Working | Working | ✅ Pass |
| UI Features | 2/2 | 2/2 | ✅ Complete |
```

---

### 2. Screenshots

**Screenshot 1:** Commissions list after batch compute
- Shows ≥50 commissions
- "Compute Eligible" button visible (admin)
- Mix of draft/pending/approved statuses

**Screenshot 2:** Commission detail with agreement card
- Party, deal, rate, VAT clearly displayed
- JSON snapshot collapsible
- Mark as paid button (admin only)

---

### 3. SQL Verification Outputs

```powershell
# Run all verification scripts and save output
.\set_key.ps1
psql -f scripts/verify_ready_to_compute.sql > verification_ready.txt
psql -f scripts/verify_missing_links.sql > verification_links.txt
psql -f scripts/verify_coverage_gaps.sql > verification_gaps.txt
```

**Expected files:**
- `verification_ready.txt` - Shows eligible count
- `verification_links.txt` - Shows <20% missing links
- `verification_gaps.txt` - Shows 0 rows (perfect coverage)

---

## Timeline

| Task | Owner | Duration | Completion |
|------|-------|----------|------------|
| Apply migrations | Backend | 30 min | Same day |
| Verify coverage | Backend | 15 min | Same day |
| Test imports | Backend | 30 min | Same day |
| Build UI | Frontend | 4-6 hours | Day 2 |
| QA validation | QA | 30 min | Day 2 |
| Screenshots | QA | 15 min | Day 2 |

**Total:** 1-2 days end-to-end

---

**Ready to execute! No manual SQL pasting required. 🚀**
