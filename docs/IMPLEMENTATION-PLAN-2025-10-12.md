# Implementation Plan - Non-Disruptive Feature Rollout
**Date:** 2025-10-12
**Strategy:** Add-only, Feature-flagged, Reversible
**Status:** Foundation Complete ✅

---

## Executive Summary

This document outlines the implementation plan for adding new features to the FundVI Fee Management System without disrupting existing functionality. All changes are:
- **Add-only**: New tables/columns only, no drops or renames
- **Feature-flagged**: Each feature can be independently enabled/disabled
- **Reversible**: Complete rollback scripts provided for all migrations
- **Backward-compatible**: Existing workflows remain unchanged

---

## ✅ Completed (Phase 0 - Foundation)

### 1. Feature Flags Infrastructure
**File:** `src/lib/featureFlags.ts`

All new features are gated behind flags:
- `FEATURE_APPROVALS` - Workflow approvals for calculation runs
- `FEATURE_INVOICES` - Invoice generation and payment tracking
- `FEATURE_SUCCESS_FEE` - Success fee event posting
- `FEATURE_MGMT_FEE` - Management fee accruals (Track B)
- `FEATURE_IMPORT_STAGING` - CSV import staging and error exports
- `FEATURE_PAYOUT_SPLITS` - Time-based and beneficiary payout splits
- `FEATURE_REPORTS` - Reporting dashboards

**Usage:**
```typescript
import { isFeatureEnabled } from '@/lib/featureFlags';

if (isFeatureEnabled('FEATURE_APPROVALS')) {
  // Show approval UI
}
```

**Environment Variables:**
```env
VITE_FEATURE_APPROVALS=true
VITE_FEATURE_INVOICES=false
# ... etc
```

### 2. Database Migrations (6 files created)

All migrations are **reversible** and include complete DOWN scripts.

#### Migration 1: Workflow Approvals
**File:** `20251012100000_add_workflow_approvals.sql`

**Tables:**
- `workflow_approvals` - Approval steps (ops_review, finance_review, final_approval)

**Changes:**
- Extends `calculation_runs.status` with: `awaiting_approval`, `approved`, `invoiced`
- No breaking changes to existing statuses

**Rollback:**
```sql
-- Drops workflow_approvals table
-- Restores original status constraint
```

#### Migration 2: Invoices & Payments
**File:** `20251012100001_add_invoices_payments.sql`

**Tables:**
- `invoices` - Invoice records with status workflow
- `invoice_lines` - Line items linking to fee calculations
- `payments` - Payment records against invoices
- `invoice_counters` - Sequential numbering (INV-2025-0001)

**Functions:**
- `generate_invoice_number()` - Atomic invoice numbering

**Rollback:**
```sql
-- Drops all invoice-related tables and functions
```

#### Migration 3: Success Fee Events
**File:** `20251012100002_add_success_fee_events.sql`

**Tables:**
- `success_fee_events` - Realization events posted by Finance
- `success_fee_postings` - Audit trail linking events to fee calculations

**Triggers:**
- Auto-mark event as 'posted' when success_fee_postings record created

**Rollback:**
```sql
-- Drops event tables and triggers
```

#### Migration 4: Management Fee Accruals
**File:** `20251012100003_add_management_fee_accruals.sql`

**Tables:**
- `management_fee_accruals` - Quarterly fee accruals for Track B

**Features:**
- Invested balance calculation (contributions - realizations)
- Actual/365 accrual basis
- VAT handling

**Rollback:**
```sql
-- Drops management_fee_accruals table
```

#### Migration 5: Distribution Staging
**File:** `20251012100004_add_distribution_staging.sql`

**Tables:**
- `distribution_staging` - CSV import staging with validation

**Functions:**
- `commit_staged_distributions()` - Commits valid rows to investor_distributions

**Features:**
- Row-level error tracking
- Batch import with partial success
- Error report export

**Rollback:**
```sql
-- Drops staging table and commit function
```

#### Migration 6: Payout Splits
**File:** `20251012100005_add_payout_schedules.sql`

**Tables:**
- `payout_schedules` - Time-based installments (e.g., 60% now, 40% +24m)
- `payout_splits` - Beneficiary sharing (e.g., sub-agent participation)

**Validations:**
- Sum of payout_schedules.percent must equal 100%
- Sum of payout_splits.share_percent cannot exceed 100%

**Rollback:**
```sql
-- Drops payout tables and validation triggers
```

### 3. Reporting Views
**File:** `20251012100006_add_reporting_views.sql`

**Views:**
- `vw_fees_by_investor` - Aggregated fees by investor/party/fund/period
- `vw_vat_summary` - VAT by country/party for tax filing
- `vw_credits_outstanding` - Outstanding credits with aging buckets
- `vw_run_summary` - Calculation run summaries

**Rollback:**
```sql
-- Drops all views
```

### 4. Seed Data
**File:** `supabase/seed.sql`

**Sample Data:**
- 3 parties (Acme Distributors, GlobalRef Partners, Elite Capital)
- 1 fund (Buligo Fund VI)
- 3 deals (DEAL-ALPHA, DEAL-BETA, DEAL-GAMMA)
- 4 agreements (2 FUND, 2 DEAL - inherit + custom rates)
- 5 investors
- 10 contributions (5 FUND-only, 5 DEAL-specific)
- 3 credits (1 FUND, 2 DEAL-scoped)
- 1 success-fee event (pending)

**Usage:**
```bash
psql -h <supabase-host> -U postgres -d postgres -f supabase/seed.sql
```

---

## 📋 Next Steps (Prioritized)

### Sprint 1: Approvals Workflow (Week 1)
**Goal:** Wire existing ApprovalsDrawer to run wizard

**Tasks:**
1. Update `SimplifiedCalculationDashboard.tsx`:
   - Add "Submit for Approval" button
   - Show approval status badges
   - Integrate ApprovalsDrawer component
   - Add "Approve" / "Reject" buttons per step

2. Create Edge Function:
   - `POST /fee-runs/{id}/submit-approval` - Creates workflow_approvals records
   - `POST /fee-runs/{id}/approve-step` - Updates approval status
   - `GET /fee-runs/{id}/approvals` - Fetches approval history

3. Update ApprovalsDrawer:
   - Show approval steps with status
   - Comment field per approval
   - RBAC checks (only role holders can approve)

**DoD:** Run can be submitted → approved by ops → finance → manager → status='approved'

### Sprint 2: Invoices & Payments (Week 2-3)
**Goal:** Generate invoices from approved runs

**Tasks:**
1. Create Edge Function:
   - `POST /fee-runs/{id}/generate-invoices` - Creates invoices per party
   - Uses `generate_invoice_number()` for sequential numbering
   - Groups fee lines by party_id
   - Calculates totals with VAT

2. PDF Generation:
   - Install `pdfmake` or similar library
   - Template: Buligo header, party address, fee lines table, payment terms
   - Upload to Supabase storage: `invoices/{invoice_id}.pdf`

3. UI Components:
   - `InvoicesList.tsx` - Table with status badges
   - `InvoiceDetail.tsx` - Preview with PDF viewer
   - `RecordPayment.tsx` - Modal for payment entry

4. Integration:
   - Add "Generate Invoices" button to run page (enabled after approved)
   - Party profile → "Invoices & Payments" tab

**DoD:** Approved run → generate invoices → download PDF → record payment → status='paid'

### Sprint 3: Success Fee Events (Week 4)
**Goal:** Post success-fee events and generate Track B/C fees

**Tasks:**
1. Create Page: `src/pages/SuccessFeeEvents.tsx`
   - Create event form (fund/deal, date, amount, notes)
   - List table with filters
   - "Post Event" button → generates fee lines

2. Create Edge Function:
   - `POST /success-fee-events` - Create event
   - `POST /success-fee-events/{id}/post` - Trigger engine
   - Engine: Find Track B/C agreements, resolve success_share_rate, create fee_calculations
   - Idempotency: Check success_fee_postings before re-posting

3. Engine Updates:
   - `src/engine/canonical/success-fee-engine.ts`
   - Resolves rates from agreements with track_key IN ('B', 'C')
   - Creates fee_calculations with basis_type='success_fee_event'
   - Links via success_fee_postings

**DoD:** Finance can post event → see generated fee lines → export in run

### Sprint 4: Management Fees (Week 5)
**Goal:** Accrue management fees for Track B

**Tasks:**
1. Create Engine: `src/engine/canonical/management-fee-engine.ts`
   - Compute invested balance: Σ(contributions) - Σ(realizations from events)
   - Actual/365 accrual calculation
   - Find Track B agreements with mgmt_fee_rate_bps
   - Create management_fee_accruals records

2. Integrate into Run:
   - Call management fee engine during run execution
   - Add "Management Fees" tile to run preview
   - Drill-down per agreement

3. Export Enhancement:
   - Add "Management Fees" sheet to XLSX export

**DoD:** Track B shows separate management fee lines per quarter; realizations reduce future accruals

### Sprint 5: Import Staging (Week 6)
**Goal:** Harden CSV import with error exports

**Tasks:**
1. Update `DistributionImportWizard.tsx`:
   - Step 4: Insert invalid rows to distribution_staging with errors array
   - "Download Error Report" button → CSV with row #, field, error message
   - "Commit Valid Rows Only" → calls commit_staged_distributions()

2. Show stats: X valid, Y errors
3. Test: Import with 50% error rate → download → verify CSV format

**DoD:** CSV import handles partial failures gracefully with error report

### Sprint 6: Reporting Dashboards (Week 7)
**Goal:** Build 3 report pages

**Tasks:**
1. `src/pages/reports/FeesByInvestor.tsx`
   - Query: vw_fees_by_investor
   - Filters: Date range, fund, party
   - Bar chart of top 10 investors (recharts)
   - Export CSV button

2. `src/pages/reports/VATSummary.tsx`
   - Query: vw_vat_summary
   - Breakdown by country/party
   - Pie chart by jurisdiction
   - Export for tax filing

3. `src/pages/reports/OutstandingCredits.tsx`
   - Query: vw_credits_outstanding
   - Aging buckets table
   - Application history per credit

**DoD:** Three report pages accessible from sidebar; <2s load time

### Sprint 7: Testing & CI (Week 8)
**Goal:** Automated testing and CI pipeline

**Tasks:**
1. Vitest Setup:
   - Install Vitest, configure `vitest.config.ts`
   - Write unit tests:
     - `calculator.trackA.spec.ts`
     - `precedence-engine.spec.ts`
     - `vat-engine.spec.ts`
     - `credits-scoping-engine.spec.ts`
     - `rate-resolver.spec.ts`
   - Coverage target: 80% for engine modules

2. Integration Tests:
   - Test fee-runs-api: Create → upload → calculate → approve → invoice
   - Test success-fee-events: Post event → verify lines → replay protection

3. GitHub Actions:
   - `.github/workflows/test.yml`:
     - Trigger: PR, push to main
     - Jobs: lint, unit tests, integration tests, build
   - Branch protection: Require green checks

**DoD:** `npm test` passes, CI green on all PRs

---

## 🚀 Deployment Strategy

### Phase 1: Foundation (Complete)
- ✅ Feature flags
- ✅ Migrations
- ✅ Seed data
- ✅ Reporting views

### Phase 2: Core Features (Weeks 1-6)
- Enable features one at a time via environment variables
- Test in staging with seed data
- User acceptance testing with Finance team
- Production rollout with gradual flag enablement

### Phase 3: Quality & Polish (Weeks 7-8)
- Automated tests
- CI/CD pipeline
- Documentation updates
- Performance optimization

---

## 🔒 Safety Mechanisms

### Rollback Plan
Each migration has complete DOWN script:
```sql
-- Example: Rollback approvals
psql < migrations/20251012100000_add_workflow_approvals.sql (DOWN section)
```

### Feature Flags
Disable any feature instantly:
```env
VITE_FEATURE_APPROVALS=false
```

### Database Integrity
- All new tables have RLS enabled
- Foreign key constraints prevent orphaned records
- Triggers validate data integrity
- Unique constraints prevent duplicates

### Monitoring
- Supabase Dashboard: Monitor Edge Function errors
- Database logs: Track migration execution
- Feature flag dashboard: View enabled features per environment

---

## 📊 Progress Tracking

| Phase | Status | Progress | ETA |
|-------|--------|----------|-----|
| **Foundation** | ✅ Complete | 100% | Done |
| **Approvals** | ⏳ Pending | 0% | Week 1 |
| **Invoices** | ⏳ Pending | 0% | Week 2-3 |
| **Success Fees** | ⏳ Pending | 0% | Week 4 |
| **Mgmt Fees** | ⏳ Pending | 0% | Week 5 |
| **Import Staging** | ⏳ Pending | 0% | Week 6 |
| **Reports** | ⏳ Pending | 0% | Week 7 |
| **Testing & CI** | ⏳ Pending | 0% | Week 8 |

---

## 📞 Support & Questions

**Next Steps:**
1. Review and approve this implementation plan
2. Answer questions about priority and sequencing
3. Begin Sprint 1 (Approvals Workflow)

**Questions to Resolve:**
1. ✅ Sequence confirmed: Approvals → Invoices → Success-Fee → Mgmt Fees
2. ✅ Mgmt-fee accrual: Quarterly basis to start
3. ✅ Feature flags: All new features gated
4. ⏳ Waterfall logic for success-fee share: Simple proportional or full waterfall?
5. ⏳ Invoice approval: Auto-send after run approval or separate workflow?
6. ⏳ Payout splits: Maximum # of beneficiaries per agreement?

**Ready to proceed when you are!**
