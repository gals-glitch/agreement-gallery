# Product Requirements Document - FundVI Fee Management System
**Version:** 2.0 (Complete)  
**Date:** 2025-10-12  
**Status:** Active - Phase 2 Complete  
**Owner**: Finance & Operations Team

---

## 1. Executive Summary

### 1.1 Purpose
Automated, auditable fee calculation platform for Buligo Capital's Fund VI distributor and referrer fees, supporting both fund-level and deal-level agreements with complete traceability.

### 1.2 Business Problem Solved
- ✅ Eliminates manual Excel calculation errors
- ✅ Provides complete audit trail for regulatory compliance
- ✅ Handles complex multi-scope agreement structures
- ✅ Automates credit application (FIFO basis)
- ✅ Supports split-timing fees (upfront + deferred)
- ✅ Ensures deterministic, reproducible results

### 1.3 Success Metrics (Achieved)
- ✅ 100% contribution-based calculations
- ✅ Zero manual VAT calculations
- ✅ Full audit trail (SHA-256 hashing)
- ✅ <5 minutes to generate finance-ready export
- ✅ Deterministic results guaranteed

---

## 2. User Personas

### 2.1 Finance Manager (Miri)
**Role**: Configure rates, approve runs, export for payments  
**Permissions**: Admin, Finance  
**Key Workflows**:
- Configure Fund VI Track rates (A/B/C)
- Review and approve calculation runs
- Export finance-ready XLSX files
- Audit historical calculations

### 2.2 Operations Analyst (Rivka)
**Role**: Data entry, run execution  
**Permissions**: Finance, Ops  
**Key Workflows**:
- Upload contribution CSV files
- Create and execute calculation runs
- Validate fee line details
- Manage agreements and parties

### 2.3 System Admin
**Role**: User management, system configuration  
**Permissions**: Admin  
**Key Workflows**:
- Manage user roles
- Configure system settings
- Access all audit logs
- Troubleshoot issues

---

## 3. Core Features

### 3.1 Fund VI Tracks Configuration
**Component**: `FundVITracksAdmin.tsx`  
**Purpose**: Manage A/B/C track rate structures

**Tracks**:
- **Track A**: ≤$3M → 1.2% upfront + 0.8% deferred (+24m)
- **Track B**: $3-6M → 1.8% upfront + 0.8% deferred (+24m)
- **Track C**: >$6M → 1.8% upfront + 1.3% deferred (+24m)

**Features**:
- Editable thresholds (min/max raised)
- Basis point rate inputs (upfront/deferred)
- Deferred offset configuration (months)
- Version control (auto-increment on save)
- Live percentage preview

### 3.2 Multi-Scope Agreements
**Component**: `AgreementManagementEnhanced.tsx`  
**Purpose**: Support both FUND and DEAL level agreements

**FUND Scope**:
- Applies to entire fund
- Uses Fund VI Track rates (A/B/C)
- Traditional approach

**DEAL Scope**:
- Applies to specific deal only
- Two rate modes:
  1. **Inherit Fund Rates**: Links to track (A/B/C)
  2. **Custom Rates**: Override with deal-specific rates
- Requires deal selection

**Precedence**:
- DEAL agreements override FUND agreements
- Warning banner when both exist
- No double-charging validation

### 3.3 Distribution Import Wizard
**Component**: `DistributionImportWizard.tsx`  
**Purpose**: Multi-step CSV/Excel import with validation

**Step 1: Upload**
- Drag-drop Excel/CSV
- Auto-parse with SheetJS

**Step 2: Map Columns**
- Auto-detect common column names
- Manual mapping dropdown
- Required: investor, fund, amount, date
- Optional: deal_code/deal_name

**Step 3: Deal Mapping** (conditional)
- Exact match algorithm
- Fuzzy matching (Levenshtein distance ≤2)
- Create new deal inline
- Fund mismatch validation

**Step 4: Validate & Preview**
- Row-level status (OK/Warning/Error)
- Investor/fund resolution
- Amount/date validation
- Preview table with badges

**Step 5: Commit**
- Batch insert (100 rows/batch)
- Transaction rollback on error
- Link to calculation run

### 3.4 Calculation Engine
**Location**: `src/engine/canonical/`  
**Type**: Deterministic, auditable

**Flow**:
1. Load configuration (tracks, agreements, VAT, credits)
2. Sort distributions (date, ID) for determinism
3. For each distribution:
   - Find applicable agreement (DEAL precedence > FUND)
   - Resolve rates (track or override)
   - Calculate upfront & deferred fees
   - Apply VAT (included or on-top)
   - Apply credits (FIFO, scope-aware)
4. Aggregate totals with scope breakdown
5. Compute SHA-256 hash
6. Store run_record atomically

**Precision**: Decimal.js for all money operations, banker's rounding

### 3.5 Credit Management
**Tables**: `credits`, `credit_applications`  
**Purpose**: Automated FIFO credit netting

**Credit Scoping**:
- **FUND credits**: Net both FUND and DEAL fee lines
- **DEAL credits**: Only net matching deal_id

**Application Logic**:
1. Sort credits by (date_posted ASC, credit_id ASC)
2. Apply oldest first until fee satisfied
3. Update remaining_balance
4. Mark consumed if balance = 0
5. Record application link

### 3.6 Finance-Ready Exports
**Library**: XLSX.js  
**Format**: 4-sheet Excel workbook

**Sheet 1: Summary**
- Run metadata, totals
- Scope breakdown table (FUND vs DEAL)

**Sheet 2: Fee Lines**
- All fee details with scope columns

**Sheet 3: Credits Applied**
- Credit applications with scope visibility

**Sheet 4: Config Snapshot**
- Fund VI tracks used in calculation

---

## 4. Technical Architecture

### 4.1 Stack
```
Frontend:  React 18 + TypeScript + Vite
UI:        Shadcn/UI + Tailwind CSS
State:     React Query (TanStack)
Auth:      Supabase Auth
Database:  PostgreSQL (Supabase)
Backend:   Supabase Edge Functions (Deno)
Routing:   React Router v6
```

### 4.2 Database Schema (Key Tables)

**fund_vi_tracks**: Track configuration  
**agreements**: FUND/DEAL agreements  
**investor_distributions**: Contribution data  
**credits**: Nettable credits  
**calculation_runs**: Run metadata  
**run_records**: Audit trail with hash  
**parties**: Distributors/referrers  
**investors**: LP entities  
**deals**: Deal definitions  
**user_roles**: Role-based access

### 4.3 Security Model
- Row-Level Security (RLS) on all tables
- Role-based policies (admin/manager/finance/ops/user)
- Security definer functions
- Encrypted at rest
- HTTPS everywhere

---

## 5. User Workflows

### 5.1 Configure Rates
1. Navigate to Fund VI Tracks
2. Edit upfront/deferred rates
3. Save → version auto-increments
4. Success notification

### 5.2 Create DEAL Agreement
1. Navigate to Parties
2. Create/edit agreement
3. Select scope: DEAL
4. Choose deal from dropdown
5. Choose: Inherit fund rates OR Custom rates
6. If custom: Enter upfront/deferred/offset
7. Save with validation

### 5.3 Import Distributions
1. Navigate to Calculation Runs → Create Run
2. Click Import Distributions
3. Upload CSV/Excel
4. Map columns (auto-detected)
5. Resolve deal codes (exact/fuzzy/create)
6. Review validation preview
7. Commit OK rows

### 5.4 Execute Calculation Run
1. Create run (name, period)
2. Upload distributions
3. Review fee line preview
4. Execute calculation
5. Review totals and scope breakdown
6. Export XLSX

### 5.5 Apply Credits
1. Navigate to Credits
2. Add credit (type, amount, scope, deal_id)
3. Credits auto-apply during next run (FIFO)
4. Review Credits Applied sheet in export

---

## 6. Out of Scope (Future Phases)

- ❌ Commitment-based calculations
- ❌ Success fee share calculations
- ❌ Multi-currency (beyond USD)
- ❌ Automated Vantage API integration
- ❌ Bank payment file generation
- ❌ Multi-factor authentication
- ❌ Advanced analytics dashboard
- ❌ Email notifications

---

## 7. Acceptance Criteria (All Met)

✅ FUND and DEAL scoped agreements supported  
✅ DEAL precedence over FUND enforced  
✅ No double-charging validation  
✅ Scope-aware credit netting  
✅ CSV import with deal matching  
✅ 4-sheet export with scope breakdown  
✅ Deterministic run hashing  
✅ Re-exportable without recomputation  
✅ Complete audit trail  
✅ Role-based access control

---

**Last Updated**: 2025-10-12  
**Next Review**: 2025-11-12
