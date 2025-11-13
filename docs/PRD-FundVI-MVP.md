# Product Requirements Document (PRD)
## Buligo Capital - Fund VI Fee Management System (MVP)

**Version:** 1.0  
**Date:** 2025-10-05  
**Status:** Active Development  
**Owner:** Finance & Operations Team  

---

## 1. Executive Summary

### 1.1 Purpose
The Fund VI Fee Management System is a streamlined, auditable platform for calculating and managing distributor/referrer fees based on actual investor contributions (cash-in basis). It replaces manual Excel processes with an automated, deterministic calculation engine.

### 1.2 Business Problem
- Manual fee calculations in Excel are error-prone and time-consuming
- No audit trail for fee calculation changes
- Inconsistent treatment of VAT (included vs. on-top)
- Credit application (repurchases, equalisation) handled manually
- Split-timing fees (upfront + deferred) require manual tracking

### 1.3 Solution Overview
A web-based application that:
- **Calculates fees deterministically** using contribution amounts (not commitments)
- **Supports Fund VI distributor tracks** (A/B/C) with manual assignment to agreements
- **Handles VAT correctly** (included or on-top modes) using database-stored rates
- **Applies credits automatically** (FIFO basis, transactional)
- **Splits fees by timing** (upfront at distribution_date, deferred at distribution_date + offset_months)
- **Maintains audit trail** (config versions, run records with server-side hash)

### 1.4 Success Metrics
- ✅ 100% contribution-based calculations (no commitment basis)
- ✅ Zero manual VAT calculations
- ✅ Full audit trail for all fee runs
- ✅ <5 minutes to generate finance-ready Excel export
- ✅ Deterministic results (same inputs → same outputs)

---

## 2. Scope

### 2.1 In Scope (MVP)
- **Fund VI distributor tracks** (A/B/C) configuration
- **Contribution-based fee calculations** with upfront/deferred split
- **VAT handling** (included vs. on-top)
- **Credit application** (FIFO netting)
- **Simple CSV import** for contributions
- **Calculation run management** (create, review, export)
- **Admin UI for track configuration**
- **Role-based access** (admin, finance, ops)

### 2.2 Out of Scope (Future Phases)
- Commitment-based calculations
- Multi-fund simultaneous runs
- Success fee share calculations
- Automated Vantage API integration
- Bank payment integration
- Multi-currency support beyond USD
- Email notifications/alerts
- Advanced reporting dashboards

### 2.3 Assumptions
- All contributions are in USD
- VAT rates are stored in database (default: Israeli 17%)
- **Tracks (A/B/C) are manually assigned to agreements** (thresholds shown as guidance only)
- Data integrity: IDs used for relationships, names denormalized for display
- Finance team will manually verify first 3 calculation runs
- run_hash computed server-side (Edge Function) for determinism

---

## 3. User Personas & Roles

### 3.1 Finance Manager (Miri)
**Needs:**
- Configure Fund VI track rates (A/B/C)
- Review and approve calculation runs
- Export finance-ready Excel files
- Audit historical calculations

**Permissions:** Admin, Finance

### 3.2 Operations Analyst (Rivka)
**Needs:**
- Upload contribution CSV files
- Create and execute calculation runs
- Review fee line details
- Validate data before Finance approval

**Permissions:** Finance, Ops

### 3.3 Admin (System Owner)
**Needs:**
- Manage user roles
- Configure system settings
- Access all audit logs
- Troubleshoot issues

**Permissions:** Admin

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

### 4.2 Architecture Pattern
- **Single-page application** (SPA) with route-based navigation
- **Serverless backend** (Supabase Edge Functions)
- **Row-level security** (RLS) for all database tables
- **Optimistic concurrency via config_version; deterministic audit via server-side run_hash**

### 4.3 Key Design Principles
1. **Contribution-based only** - No commitment basis (business requirement)
2. **Deterministic** - Same inputs always produce same outputs
3. **Auditable** - All calculations stored with config snapshots
4. **Simple first** - MVP focuses on Fund VI tracks only
5. **Type-safe** - Full TypeScript coverage

---

## 5. Database Schema

### 5.1 Core Tables

#### `fund_vi_tracks`
Stores A/B/C track configuration
```sql
- id: uuid (PK)
- track_key: text ('A' | 'B' | 'C')
- min_raised: numeric (threshold in USD)
- max_raised: numeric (upper bound, null = ∞)
- upfront_rate_bps: integer (basis points, e.g., 120 = 1.2%)
- deferred_rate_bps: integer (basis points)
- deferred_offset_months: integer (default 24)
- config_version: text (e.g., 'v1.0')
- is_active: boolean
- created_at, updated_at: timestamptz
```

**Default Data:**
- Track A: ≤$3M → 1.2% upfront + 0.8% at +24m
- Track B: $3-6M → 1.8% upfront + 0.8% at +24m  
- Track C: >$6M → 1.8% upfront + 1.3% at +24m

**Constraints:**
- Unique index: only one active track per track_key
- Index on config_version for performance

#### `run_records`
Audit trail for calculation runs
```sql
- id: uuid (PK)
- calculation_run_id: uuid (FK → calculation_runs)
- config_version: text (tracks version used)
- inputs: jsonb (contributions snapshot)
- outputs: jsonb (fee lines generated)
- run_hash: text (SHA-256 of inputs+config)
- created_by: uuid (FK → auth.users)
- created_at: timestamptz
```

#### `calculation_runs`
Run metadata
```sql
- id: uuid (PK)
- name: text
- status: text ('draft' | 'in_progress' | 'completed' | 'failed')
- period_start, period_end: date
- total_gross_fees, total_vat, total_net_payable: numeric
- created_by, started_by: uuid
- created_at, updated_at, completed_at: timestamptz
```

#### `investor_distributions`
Contribution data
```sql
- id: uuid (PK)
- investor_id: uuid (FK → investors, required)
- fund_id: uuid (FK → funds, required)
- agreement_id: uuid (FK → agreements, required)
- investor_name: text (denormalized for display)
- fund_name: text (denormalized for display)
- distribution_amount: numeric (CHECK >= 0)
- distribution_date: date
- calculation_run_id: uuid (nullable)
- created_at: timestamptz

-- Enforced constraint: distribution_date must fall within [period_start, period_end] of linked calculation_run
-- Implemented via trigger: enforce_distribution_within_run_period()
-- Performance index: (calculation_run_id, distribution_date)
```

#### `credits`
Available credits for netting
```sql
- id: uuid (PK)
- investor_id: uuid (FK → investors, required)
- fund_id: uuid (FK → funds, required)
- investor_name: text (denormalized for display)
- fund_name: text (denormalized for display)
- credit_type: text ('repurchase' | 'equalisation' | 'discount')
- amount: numeric
- remaining_balance: numeric (CHECK >= 0)
- date_posted: date
- status: text ('active' | 'consumed' | 'expired')
- apply_policy: text ('net_against_future_payables')
- created_at, updated_at: timestamptz
-- Partial index: CREATE INDEX ON credits (investor_id, fund_id, date_posted) WHERE status='active' AND remaining_balance>0;
```

#### `credit_applications`
Audit log for credit consumption
```sql
- id: uuid (PK)
- credit_id: uuid (FK → credits, ON DELETE RESTRICT)
- fee_line_id: uuid (references line id in run_records.outputs)
- applied_amount: numeric (CHECK >= 0)
- applied_date: timestamptz
- created_by: uuid
```

#### `vat_rates`
VAT rate table by jurisdiction
```sql
- id: uuid (PK)
- country_code: text ('IL', 'US', etc.)
- rate: numeric (CHECK >= 0 AND rate <= 1)
- effective_from, effective_to: date
- is_default: boolean
- created_at: timestamptz
- created_by: uuid

-- Helper function for engine:
CREATE OR REPLACE FUNCTION get_effective_vat_rate(as_of_date date, country text DEFAULT 'IL')
RETURNS numeric AS $$
  SELECT COALESCE(
    (SELECT rate FROM vat_rates 
     WHERE country_code = country 
       AND effective_from <= as_of_date 
       AND (effective_to IS NULL OR effective_to >= as_of_date)
     ORDER BY effective_from DESC LIMIT 1),
    (SELECT rate FROM vat_rates WHERE is_default = true LIMIT 1),
    0.17 -- Fallback
  );
$$ LANGUAGE sql STABLE;
```

#### `agreements`
Agreement metadata (extended)
```sql
- id: uuid (PK)
- name, agreement_type, status: text
- track_key: text (CHECK IN ('A','B','C')) -- Manually assigned
- vat_mode: text (CHECK IN ('included','added'))
- effective_from, effective_to: date
- introduced_by_party_id: uuid (FK → parties)
- created_at, updated_at: timestamptz
- created_by: uuid
```

### 5.2 Row-Level Security (RLS)
All tables have RLS enabled with policies:
```sql
-- Admin/Manager can access all records
CREATE POLICY "Admin/Manager can access X"
  ON public.X FOR ALL
  USING (is_admin_or_manager(auth.uid()));

-- Users can view their own runs
CREATE POLICY "Users can view own runs"
  ON public.calculation_runs FOR SELECT
  USING (created_by = auth.uid() OR is_admin_or_manager(auth.uid()));
```

---

## 6. Calculation Engine

### 6.1 Engine Location
```
src/engine/simple/
  ├── types.ts          # Type definitions
  ├── calculator.ts     # Main engine
  └── index.ts          # Exports
```

### 6.2 Calculation Flow
```
1. Load config (tracks, VAT rates via get_effective_vat_rate(), credits)
2. Sort contributions by (distribution_date, contribution_id) -- determinism
3. Sort available credits by (date_posted, credit_id) -- FIFO order
4. For each contribution:
   a. Determine track from agreement.track_key (manual assignment)
   b. Calculate upfront fee (base × upfront_rate_bps / 10000)
   c. Calculate deferred fee (base × deferred_rate_bps / 10000)
   d. Apply VAT using get_effective_vat_rate(distribution_date, agreement.country)
   e. Apply credits (FIFO, transactional, update remaining_balance)
   f. Round each line to 2 decimal places (ROUND_HALF_EVEN)
5. Aggregate totals
6. Compute run_hash (server-side, SHA-256)
7. Store run_record with inputs + outputs + config snapshot
```

### 6.3 VAT Formulas
**Included Mode:**
```typescript
net = gross / (1 + vat_rate)
vat = gross - net
total = gross
```

**On-Top Mode:**
```typescript
net = gross
vat = gross × vat_rate
total = gross + vat
```

### 6.4 Credit Application (FIFO, Transactional)
```typescript
// Within a single database transaction per run:
// 1. Sort available credits by (date_posted ASC, credit_id ASC)
// 2. For each fee line:
for (const credit of availableCredits.sort((a,b) => 
  a.date_posted.localeCompare(b.date_posted) || a.id.localeCompare(b.id)
)) {
  if (remaining_due.isZero()) break;
  
  const toApply = Decimal.min(remaining_due, credit.remaining_balance);
  creditsApplied = creditsApplied.plus(toApply);
  remaining_due = remaining_due.minus(toApply);
  
  // Update credit in DB (transactional)
  await supabase.from('credits')
    .update({ 
      remaining_balance: credit.remaining_balance.minus(toApply),
      status: credit.remaining_balance.equals(toApply) ? 'consumed' : 'active'
    })
    .eq('id', credit.id);
  
  // Record application link (transactional)
  await supabase.from('credit_applications').insert({
    credit_id: credit.id,
    fee_line_id: currentLine.id,
    applied_amount: toApply,
    applied_date: new Date(),
    created_by: auth.uid()
  });
}
```

### 6.5 Determinism Guarantees
- **Config version** auto-bumped on track changes (server trigger)
- **Input snapshot** stored in run_records (sorted contributions)
- **Stable JSON serialization** (sorted keys)
- **SHA-256 hash** computed server-side (Edge Function, Deno Web Crypto)
- **Banker's rounding** (ROUND_HALF_EVEN) at 2 decimal places per fee line
- **Sort order:** contributions by (distribution_date, id); credits by (date_posted, id)

---

## 7. Frontend Components

### 7.1 Page Structure
```
src/pages/
  ├── Index.tsx                # Dashboard (home)
  ├── CalculationRuns.tsx      # Fee calculation runs
  ├── FundVITracks.tsx         # Track admin (A/B/C)
  ├── Exports.tsx              # Export center
  └── Validation.tsx           # System validation
```

### 7.2 Key Components

#### Fund VI Tracks Admin (`FundVITracksAdmin.tsx`)
**Purpose:** Configure A/B/C track rates

**Features:**
- Edit min/max raised thresholds
- Set upfront/deferred rate (basis points)
- Configure deferred offset (months)
- Save changes with version bump
- Preview rates as percentages

**UI:**
- 3-column grid (Track A | B | C)
- Input fields for all editable values
- Live percentage calculation
- Save button per track
- Config version badge

#### Calculation Dashboard (`SimplifiedCalculationDashboard.tsx`)
**Purpose:** Create and manage calculation runs

**Features:**
- List all calculation runs (status, dates, totals)
- Create new run (name, period)
- Upload contribution CSV
- Preview fee lines
- Execute calculation
- Export Excel

**UI:**
- Run list table (sortable)
- "Create Run" wizard dialog
- CSV upload with drag-drop
- Fee line preview table
- Export buttons

### 7.3 Navigation (Route-based)
```typescript
<Routes>
  <Route path="/" element={<Index />} />
  <Route path="/runs" element={<CalculationRuns />} />
  <Route path="/fund-vi/tracks" element={<FundVITracks />} />
  <Route path="/exports" element={<Exports />} />
  <Route path="/validation" element={<Validation />} />
</Routes>
```

### 7.4 Sidebar Navigation (`AppSidebar.tsx`)
```typescript
mainItems = [
  { title: "Dashboard", url: "/", icon: Star },
  { title: "Fee Runs", url: "/runs", icon: Calculator },
  { title: "Fund VI Tracks", url: "/fund-vi/tracks", icon: GitBranch },
  { title: "Parties", url: "/parties", icon: Building2 },
]

dataItems = [
  { title: "Export Center", url: "/exports", icon: FileText },
  { title: "Validation", url: "/validation", icon: TestTube },
]
```

---

## 8. User Workflows

### 8.1 Configure Fund VI Tracks (Finance Manager)
```
1. Navigate to "Fund VI Tracks"
2. Review current A/B/C configuration
3. Edit rates (e.g., Track B upfront: 180 → 200 bps)
4. Click "Save Changes"
5. System bumps config_version (v1.0 → v1.1)
6. Success toast confirmation
```

### 8.2 Run Fee Calculation (Operations Analyst)
```
1. Navigate to "Fee Runs"
2. Click "Create New Run"
3. Enter run name (e.g., "Q1 2025 Distributor Fees")
4. Select period (2025-01-01 to 2025-03-31)
5. Upload contributions CSV
6. System validates CSV (schema, business rules)
7. Preview fee lines (upfront + deferred)
8. Review totals (gross, VAT, net, credits, payable)
9. Click "Execute Calculation"
10. System generates run_record with snapshot
11. Status changes to "Completed"
12. Click "Export Excel"
13. Download finance-ready spreadsheet
```

### 8.3 Apply Credits (Automatic)
```
1. System loads available credits (status='active', balance>0)
2. For each fee line:
   a. Find credits matching investor_name + fund_name
   b. Sort by date_posted (FIFO)
   c. Apply oldest credit first
   d. Reduce credit.remaining_balance
   e. If credit exhausted, move to next
3. Store credit_id references in fee line
4. Update credit status if fully consumed
```

### 8.4 Export Finance Report
```
1. Click "Export Excel" on completed run
2. System generates XLSX with 4 sheets:

**Sheet 1: Summary**
- run_id, name, period_start, period_end
- total_gross_fees, total_vat, total_credits_applied, total_net_payable
- config_version, created_by, created_at

**Sheet 2: Fee Lines**
- contribution_id, investor_id, investor_name, fund_id, fund_name
- agreement_id, track_key, line_type (upfront | deferred)
- base_amount, rate_bps, fee_gross, vat_amount
- credits_applied, credit_ids[], total_payable
- payment_date (distribution_date or distribution_date + offset_months)

**Sheet 3: Credits Applied**
- credit_id, investor_id, investor_name, fund_id, fund_name
- applied_to_line_id, applied_amount, remaining_balance_after
- date_posted, credit_type

**Sheet 4: Config Snapshot**
- Rows from fund_vi_tracks at config_version used in this run
- track_key, min_raised, max_raised, upfront_rate_bps, deferred_rate_bps

3. Download file: "fees_Q1_2025_<run_id>_<timestamp>.xlsx"
4. Finance team imports to accounting system
```

---

## 9. API / Edge Functions

### 9.1 Endpoints

#### `POST /functions/v1/fee-runs-api`
**Purpose:** Create and execute calculation runs

**Request:**
```json
{
  "action": "create",
  "name": "Q1 2025 Fees",
  "period_start": "2025-01-01",
  "period_end": "2025-03-31",
  "contributions": [
    {
      "investor_name": "ABC Capital",
      "fund_name": "Fund VI",
      "distribution_amount": 5000000,
      "distribution_date": "2025-01-15"
    }
  ],
  "config_version": "v1.0"
}
```

**Response:**
```json
{
  "run_id": "uuid",
  "status": "completed",
  "fee_lines": [...],
  "totals": {
    "gross": 125000,
    "vat": 21250,
    "net": 125000,
    "credits": 5000,
    "payable": 141250
  }
}
```

#### `GET /functions/v1/fee-runs-api?action=list`
**Purpose:** List all calculation runs

**Response:**
```json
{
  "runs": [
    {
      "id": "uuid",
      "name": "Q1 2025 Fees",
      "status": "completed",
      "period_start": "2025-01-01",
      "period_end": "2025-03-31",
      "total_payable": 141250,
      "created_at": "2025-10-05T10:00:00Z"
    }
  ]
}
```

### 9.2 Security
- **Supabase Auth JWT** required
- **RLS policies** enforce data access
- **Role checks** (admin, finance, ops)
- **Rate limiting** (10 req/min per user)
- **Input validation** (Zod schemas)

---

## 10. Acceptance Criteria

### 10.1 Functional
- ✅ **F1:** System calculates fees based on distribution_amount only (never commitments)
- ✅ **F2:** Fund VI tracks A/B/C manually assigned to agreements (thresholds for guidance)
- ✅ **F3:** VAT "included" mode: total = gross (net extracted)
- ✅ **F4:** VAT "on-top" mode: total = gross + VAT
- ✅ **F5:** Credits apply FIFO (oldest first, sorted by date_posted, credit_id)
- ✅ **F6:** Deferred fees: payment_date = distribution_date + deferred_offset_months (date-based calculation)
- ✅ **F7:** UI warns if assigned track deviates from threshold guidance (validation only)
- ✅ **F8:** Config version auto-bumped via trigger on fund_vi_tracks changes
- ✅ **F9:** All amounts reference entities by ID (investor_id, fund_id, agreement_id)
- ✅ **F10:** Credits transactional: remaining_balance updated atomically per run

### 10.2 Non-Functional
- ✅ **NF1:** Calculation completes in <10 seconds for 1,000 contributions
- ✅ **NF2:** Same inputs + config version produce identical outputs (server-side hash)
- ✅ **NF3:** Run record stored atomically (inputs, outputs, hash, config_version)
- ✅ **NF4:** All currency amounts use Decimal.js (no floating-point errors)
- ✅ **NF5:** Banker's rounding (ROUND_HALF_EVEN) at 2 decimal places per line
- ✅ **NF6:** RLS enabled on all tables (fund_vi_tracks, run_records, credits, etc.)
- ✅ **NF7:** Audit trail includes inputs, outputs, config_version, run_hash, user, timestamp
- ✅ **NF8:** VAT rates enforced: 0 ≤ rate ≤ 1 (DB constraint)
- ✅ **NF9:** Credits: remaining_balance ≥ 0 (DB constraint + partial index)
- ✅ **NF10:** Distribution period enforcement: distribution_date within run period (trigger)

### 10.3 UI/UX
- ✅ **UX1:** Track admin shows percentage conversion (180 bps → 1.80%)
- ✅ **UX2:** CSV upload provides row-level validation errors
- ✅ **UX3:** Fee line preview shows upfront/deferred separately
- ✅ **UX4:** Export button disabled until run status='completed'
- ✅ **UX5:** Toast notifications for all state changes
- ✅ **UX6:** Sidebar highlights active route
- ✅ **UX7:** Loading states for all async operations

---

## 11. Data Migration

### 11.1 Seeding Fund VI Tracks + Auto Version Bump
```sql
-- Seed initial tracks (trigger will set config_version automatically)
INSERT INTO fund_vi_tracks (track_key, min_raised, max_raised, upfront_rate_bps, deferred_rate_bps)
VALUES
  ('A', 0, 3000000, 120, 80),
  ('B', 3000000, 6000000, 180, 80),
  ('C', 6000000, NULL, 180, 130);

-- Auto-bump config_version on any track update
CREATE OR REPLACE FUNCTION bump_tracks_version()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  NEW.config_version := 'v' || to_char(clock_timestamp(), 'YYYYMMDDHH24MISS');
  NEW.updated_at := now();
  RETURN NEW;
END$$;

CREATE TRIGGER trg_fund_vi_tracks_version
BEFORE INSERT OR UPDATE ON fund_vi_tracks
FOR EACH ROW EXECUTE FUNCTION bump_tracks_version();
```

### 11.2 VAT Rate Setup
```sql
INSERT INTO vat_rates (country_code, rate, effective_from, is_default)
VALUES ('IL', 0.17, '2020-01-01', true);
```

### 11.3 Historical Data Import
- **Contributions:** CSV import via UI (manual or batch)
- **Credits:** CSV import with validation
- **Agreements:** Assign track_key, vat_mode retroactively

---

## 12. Security & Compliance

### 12.1 Authentication
- **Supabase Auth** with email/password
- **MFA** available (optional for MVP)
- **Session timeout** 7 days

### 12.2 Authorization
- **Role-based access control** (RBAC)
- **RLS policies** on all tables
- **Admin/Finance/Ops** permission tiers

### 12.3 Audit Trail
- **run_records** table logs all calculations
- **activity_log** table tracks user actions
- **Immutable snapshots** (inputs, config, outputs)

### 12.4 Data Privacy
- **No PII** in fee calculations (investor names only)
- **GDPR-ready** (delete capability)
- **Encrypted at rest** (Supabase default)

---

## 13. Testing Strategy

### 13.1 Unit Tests
- Money class arithmetic
- VAT calculation formulas
- FIFO credit application
- Track determination logic

### 13.2 Integration Tests
- Full calculation flow (CSV → fee lines)
- Database constraints (RLS, foreign keys)
- API endpoints (auth, validation)

### 13.3 Acceptance Tests
```
Given: Contribution $5M, Track B (3-6M), VAT on-top 17%
When: Calculate fees
Then: 
  - Upfront: $5M × 1.8% = $90K gross, $15.3K VAT, $105.3K total
  - Deferred: $5M × 0.8% = $40K gross, $6.8K VAT, $46.8K total
  - Payment dates: today, +24 months
```

### 13.4 Golden Dataset
- 10 representative contributions
- Mix of tracks (A/B/C)
- VAT modes (included, on-top)
- Credits applied
- **Expected output spreadsheet** for regression testing

---

## 14. Deployment

### 14.1 Environments
```
Development: localhost:5173
Staging:     staging.buligo.app (lovable.app)
Production:  app.buligo.com (custom domain)
```

### 14.2 CI/CD
- **GitHub Actions** (optional)
- **Lovable auto-deploy** on git push
- **Database migrations** via Supabase CLI

### 14.3 Rollback Plan
- **Git revert** to previous commit
- **Database migration rollback** via Supabase
- **Run records immutable** (no data loss)

---

## 15. Future Enhancements

### 15.1 Phase 2 (Q2 2025)
- **Vantage API integration** (automated contribution import)
- **Success fee share** calculations (GP carry %)
- **Multi-currency support** (EUR, GBP)
- **Email notifications** (run completed, errors)

### 15.2 Phase 3 (Q3 2025)
- **Advanced reporting** (dashboards, charts)
- **Workflow approvals** (two-person rule)
- **Automated reconciliation** (bank imports)
- **Mobile responsive** optimization

### 15.3 Deferred Scope
- **Multi-fund simultaneous** runs
- **Commitment-based** calculations (legacy)
- **Custom rule builder** (generic conditions)
- **AI-powered** anomaly detection

---

## 16. Glossary

| Term | Definition |
|------|------------|
| **Contribution** | Actual cash invested by an investor (basis for fees) |
| **Commitment** | Pledged amount (NOT used for fee calculation) |
| **Track** | Fee tier (A/B/C) based on raised capital |
| **Upfront fee** | Portion paid at fundraising close |
| **Deferred fee** | Portion paid 24 months after close |
| **VAT included** | Tax embedded in fee amount |
| **VAT on-top** | Tax added to fee amount |
| **FIFO** | First-In-First-Out (credit application order) |
| **Config version** | Snapshot identifier for track rates |
| **Run record** | Immutable audit trail for a calculation |
| **Basis points (bps)** | 1/100th of 1% (e.g., 180 bps = 1.8%) |

---

## 17. Appendices

### A. Sample CSV Import Format
```csv
investor_name,fund_name,distribution_amount,distribution_date
ABC Capital,Fund VI,5000000,2025-01-15
XYZ Holdings,Fund VI,2000000,2025-02-01
```

### B. Sample Fee Line Output
```json
{
  "contribution_id": "uuid-contrib-001",
  "investor_id": "uuid-inv-abc",
  "investor_name": "ABC Capital",
  "fund_id": "uuid-fund-vi",
  "fund_name": "Fund VI",
  "agreement_id": "uuid-agr-123",
  "track_key": "B",
  "line_type": "upfront",
  "base_amount": 5000000.00,
  "rate_bps": 180,
  "fee_gross": 90000.00,
  "vat_amount": 15300.00,
  "fee_net": 90000.00,
  "credits_applied": 0.00,
  "credit_ids": [],
  "total_payable": 105300.00,
  "payment_date": "2025-01-15",
  "distribution_date": "2025-01-15"
}
```

### C. Database ERD
```
fund_vi_tracks ──┐
                 │
calculation_runs ├─── run_records
                 │
investor_distributions ──┤
                         │
agreements ──────────────┤
                         │
credits ─────────────────┘
```

---

**Document Status:** Active  
**Next Review:** 2025-11-01  
**Stakeholders:** Finance (Miri), Operations (Rivka), Engineering  
**Approvals:** ✅ Finance, ✅ Operations, ⏳ Engineering Lead
