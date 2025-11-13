# FundVI Fee Management System

**Version:** 2.0  
**Status:** Active Development (Phase 2 Complete)  
**Project Type:** Enterprise Fee Calculation Platform

---

## 🎯 Overview

The FundVI Fee Management System is a deterministic, auditable platform for calculating distributor and referrer fees for Buligo Capital's Fund VI. It replaces error-prone Excel processes with an automated calculation engine that handles complex fee structures, VAT calculations, credit netting, and multi-scope (FUND/DEAL) agreements.

### Key Features
- ✅ **Contribution-based calculations** (cash-in, not commitments)
- ✅ **Multi-scope support** (Fund-level & Deal-level agreements)
- ✅ **Intelligent precedence** (DEAL agreements override FUND)
- ✅ **Automated VAT handling** (included vs on-top modes)
- ✅ **FIFO credit netting** (scope-aware)
- ✅ **Split-timing fees** (upfront + deferred)
- ✅ **Complete audit trail** (deterministic hashing)
- ✅ **Finance-ready exports** (4-sheet XLSX with scope breakdown)

---

## 🚀 Quick Start

### Prerequisites
- **Node.js** 18+ or 20 LTS (recommended)
- **npm** 9+ or **pnpm** 8+
- **Supabase Account** (project already configured)

### Local Development Setup

1. **Clone the repository**
   ```bash
   git clone <YOUR_GIT_URL>
   cd agreement-gallery
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Environment configuration**
   
   Verify `.env` file exists with:
   ```env
   VITE_SUPABASE_PROJECT_ID=qwgicrdcoqdketqhxbys
   VITE_SUPABASE_URL=https://qwgicrdcoqdketqhxbys.supabase.co
   VITE_SUPABASE_PUBLISHABLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   ```

4. **Start development server**
   ```bash
   npm run dev
   ```

5. **Access the application**
   ```
   http://localhost:8080
   ```

### 🪟 Windows Users: Path Issues

If you encounter `MODULE_NOT_FOUND` errors with spaces in your path:

**Solution 1 (Recommended):** Move project to simple path
```powershell
# Move to path without spaces
C:\dev\fundvi-fees\

# Clean install
Remove-Item -Recurse -Force node_modules, package-lock.json
npm install
npm run dev
```

**Solution 2:** Use npx directly
```powershell
npx vite
```

---

## 🏗️ Architecture

### Technology Stack

```
┌─────────────────────────────────────────┐
│         Frontend (React SPA)            │
├─────────────────────────────────────────┤
│  React 18 + TypeScript + Vite           │
│  Shadcn/UI + Tailwind CSS               │
│  React Query (TanStack)                 │
│  React Router v6                        │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│    Backend (Supabase + Edge Functions)  │
├─────────────────────────────────────────┤
│  PostgreSQL (RLS enabled)               │
│  Supabase Auth                          │
│  Edge Functions (Deno runtime)          │
│  Storage (Excel/CSV, PDFs)              │
└─────────────────────────────────────────┘
```

### Core Modules

**Calculation Engine** (`src/engine/canonical/`)
- `calculator.ts` - Main calculation orchestrator
- `precedence-engine.ts` - DEAL→FUND scope precedence
- `credits-scoping-engine.ts` - Scope-aware credit netting
- `rate-resolver.ts` - Track & agreement rate resolution
- `tier-engine.ts` - Tiered rate calculations
- `vat-engine.ts` - VAT computation (included/on-top)

**API Integration** (`src/api/`)
- `runsClient.ts` - Calculation runs API client

**Data Domain** (`src/domain/`)
- `types.ts` - Core type definitions
- `money.ts` - Decimal precision handling
- `hash.ts` - Deterministic hashing utilities

**Edge Functions** (`supabase/functions/`)
- `fee-runs-api/` - Calculation execution & run management
- `create-calculation-run/` - Run initialization
- `replay-calculation-run/` - Re-run with locked config
- `export-commission-data/` - Legacy export
- `enhanced-export-commission-data/` - V2 export with scope breakdown

---

## 📂 Project Structure

```
agreement-gallery/
├── src/
│   ├── components/          # React components
│   │   ├── ui/             # Shadcn UI components
│   │   ├── SimplifiedCalculationDashboard.tsx
│   │   ├── FundVITracksAdmin.tsx
│   │   ├── AgreementManagementEnhanced.tsx
│   │   ├── DistributionImportWizard.tsx
│   │   └── ...
│   ├── pages/              # Route pages
│   │   ├── Index.tsx       # Dashboard
│   │   ├── CalculationRuns.tsx
│   │   ├── FundVITracks.tsx
│   │   ├── Deals.tsx
│   │   ├── PartyManagementPage.tsx
│   │   └── ...
│   ├── engine/             # Calculation engines
│   │   ├── canonical/      # Production engine
│   │   └── simple/         # Legacy/testing
│   ├── lib/                # Utilities
│   │   ├── exportV2.ts     # XLSX export generator
│   │   ├── excel.ts        # Excel parsing
│   │   └── ...
│   ├── api/                # API clients
│   ├── domain/             # Business logic
│   ├── hooks/              # React hooks
│   ├── integrations/       # Supabase client
│   └── types/              # TypeScript types
├── supabase/
│   ├── functions/          # Edge functions
│   │   ├── fee-runs-api/
│   │   └── ...
│   ├── migrations/         # Database migrations
│   └── config.toml         # Supabase config
├── docs/                   # Documentation
│   ├── PRD-COMPLETE.md     # Comprehensive PRD
│   ├── STATUS-REPORT.md    # Current status
│   └── ...
└── README.md              # This file
```

---

## 🗄️ Database Schema

### Core Tables

**`fund_vi_tracks`** - Fee rate configuration (A/B/C tracks)
```sql
track_key: 'A' | 'B' | 'C'
min_raised, max_raised: numeric  -- Thresholds (USD)
upfront_rate_bps: integer        -- e.g., 120 = 1.2%
deferred_rate_bps: integer
deferred_offset_months: integer  -- Default: 24
config_version: text
```

**`agreements`** - Fee agreements (FUND/DEAL scoped)
```sql
applies_scope: 'FUND' | 'DEAL'
deal_id: uuid (nullable)
track_key: text (for FUND scope)
inherit_fund_rates: boolean
upfront_rate_bps, deferred_rate_bps: integer (overrides)
vat_mode: 'included' | 'added'
introduced_by_party_id: uuid
```

**`investor_distributions`** - Contribution data
```sql
investor_id, fund_id, deal_id: uuid
distribution_amount: numeric
distribution_date: date
calculation_run_id: uuid
```

**`credits`** - Nettable credits
```sql
scope: 'FUND' | 'DEAL'
deal_id: uuid (nullable)
credit_type: 'repurchase' | 'equalisation' | 'discount'
remaining_balance: numeric
status: 'active' | 'consumed' | 'expired'
```

**`calculation_runs`** - Run metadata
```sql
name, status: text
period_start, period_end: date
total_gross_fees, total_vat, total_net_payable: numeric
```

**`run_records`** - Audit trail
```sql
calculation_run_id: uuid
config_version, run_hash: text
inputs, outputs, scope_breakdown: jsonb
```

### Row-Level Security (RLS)

All tables have RLS enabled. Access controlled via `user_roles`:
- **Admin/Manager**: Full access
- **Finance**: Read all, write calculation runs
- **Ops**: Read all, write distributions
- **User**: Read own data only

---

## 🧮 Calculation Flow

```
1. Load Configuration
   ├─ Fund VI tracks (A/B/C rates)
   ├─ Active agreements (FUND + DEAL scoped)
   ├─ VAT rates (by country, date)
   └─ Available credits (FIFO sorted)

2. Process Each Distribution
   ├─ Find applicable agreement (DEAL precedence > FUND)
   ├─ Resolve rates (track lookup or override)
   ├─ Calculate upfront & deferred fees
   ├─ Apply VAT (included or on-top mode)
   ├─ Apply credits (FIFO, scope-aware)
   └─ Generate fee line

3. Generate Run Record
   ├─ Aggregate totals (gross, VAT, net)
   ├─ Compute scope breakdown (FUND vs DEAL)
   ├─ Hash inputs + config (SHA-256)
   └─ Store atomically with snapshot
```

### Precedence Rules
- **Row has `deal_id` + DEAL agreement exists** → Use DEAL agreement
- **Row has `deal_id` but no DEAL agreement** → Fallback to FUND agreement
- **Row has no `deal_id`** → Use FUND agreement only
- **No agreement found** → Skip row (warning)

### Credit Scoping
- **FUND credits** → Can net both FUND and DEAL fee lines
- **DEAL credits** → Only net DEAL fee lines with matching `deal_id`
- **FIFO order** → `(date_posted ASC, credit_id ASC)`

---

## 📊 Export Format

### 4-Sheet XLSX Structure

**Sheet 1: Summary**
- Run metadata (ID, name, period, config version, run hash)
- Overall totals (gross, VAT, net payable)
- **Scope Breakdown Table:**
  ```
  Scope | Gross Fees | VAT | Net Payable | Line Count
  FUND  | $50,000    | $10 | $41,250     | 12
  DEAL  | $30,000    | $6  | $24,750     | 8
  ```

**Sheet 2: Fee Lines**
- All fee line details
- Columns: Scope, Deal ID, Deal Code, Deal Name, Investor, Fund, Amount, VAT, etc.

**Sheet 3: Credits Applied**
- Credit applications with scope visibility
- Columns: Credit ID, Type, Scope, Deal ID, Amount Applied, etc.

**Sheet 4: Config Snapshot**
- Fund VI tracks used in calculation
- Exact rates, thresholds, offsets

---

## 🔐 Authentication & Roles

### User Roles (via `user_roles` table)
- **admin** - Full system access, user management
- **manager** - Configure tracks, approve runs
- **finance** - Create runs, export data
- **ops** - Upload distributions, view data
- **user** - Read-only access

### Security Functions
```sql
has_role(user_id, role) → boolean
is_admin_or_manager(user_id) → boolean
```

### RLS Policy Pattern
```sql
CREATE POLICY "Admin/Manager full access"
ON table_name FOR ALL
USING (is_admin_or_manager(auth.uid()));

CREATE POLICY "Users view own data"
ON table_name FOR SELECT
USING (created_by = auth.uid() OR is_admin_or_manager(auth.uid()));
```

---

## 🧪 Testing

### Run Validation
```bash
# Access validation page
http://localhost:8080/validation
```

### Manual Test Cases
1. **Precedence**: Row with `deal_id` uses DEAL agreement (not FUND)
2. **Credits**: FUND credit nets DEAL fee; DEAL credit only nets matching deal
3. **Determinism**: Same inputs → same `run_hash`
4. **Re-export**: Export uses stored data (no recalculation)
5. **VAT modes**: Test included vs on-top calculations

---

## 📦 Deployment

### Production Deployment (Lovable)
1. Click **Publish** in Lovable editor
2. Access at: `https://your-project.lovable.app`

### Custom Domain Setup
1. Navigate to: Project → Settings → Domains
2. Add CNAME record: `your-domain.com → your-project.lovable.app`
3. Verify DNS propagation

### Environment Variables
Managed in Supabase project settings:
- Edge Function secrets: [Manage Secrets](https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys/settings/functions)

---

## 🛠️ Development Workflow

### Adding a New Feature
1. **Database changes** → Use Lovable's migration tool
2. **Types** → Auto-generated in `src/integrations/supabase/types.ts`
3. **Edge function** → Create in `supabase/functions/`
4. **UI component** → Add to `src/components/`
5. **Page** → Add route in `src/App.tsx`

### Best Practices
- ✅ Use TypeScript for all code
- ✅ Leverage React Query for data fetching
- ✅ Follow Shadcn/UI component patterns
- ✅ Implement RLS for all new tables
- ✅ Test with small datasets first
- ✅ Document complex business logic

---

## 📚 Documentation

- **[Complete PRD](docs/PRD-COMPLETE.md)** - Full product requirements
- **[Status Report](docs/STATUS-REPORT.md)** - Current implementation state
- **[Phase 1 Summary](docs/Phase-1-Implementation-Summary.md)** - Engine precedence & exports
- **[Phase 2 Session Notes](docs/PRD-Session-Updates-2025-10-05.md)** - Deal scoping & CSV import

---

## 🐛 Troubleshooting

### Common Issues

**1. `MODULE_NOT_FOUND` on Windows**
- Move project to path without spaces (e.g., `C:\dev\fundvi-fees`)
- Run `npm install` fresh

**2. Supabase connection errors**
- Verify `.env` file has correct project ID and keys
- Check network connectivity to `qwgicrdcoqdketqhxbys.supabase.co`

**3. Edge function errors**
- Check logs: [Edge Function Logs](https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys/functions/fee-runs-api/logs)
- Verify secrets are set: [Function Secrets](https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys/settings/functions)

**4. Calculation discrepancies**
- Review `run_records` table for stored inputs/outputs
- Check `config_version` matches expected tracks
- Verify VAT rates are configured for calculation date

---

## 🤝 Contributing

### Code Style
- **Formatting**: Prettier with 2-space indentation
- **Linting**: ESLint with TypeScript rules
- **Naming**: camelCase (vars/functions), PascalCase (components)

### Git Workflow
1. Create feature branch: `feature/deal-level-discounts`
2. Commit with descriptive messages
3. Push to GitHub (auto-syncs with Lovable)
4. Changes appear in Lovable editor automatically

---

## 🔗 Lovable Integration

**Edit this project online**: [Lovable Editor](https://lovable.dev/projects/6c609d70-6a32-49a2-a1a0-3daee62d2568)

Changes made via Lovable are automatically committed to this repo. Changes pushed to GitHub automatically sync to Lovable.

**Other ways to edit:**
- **Local IDE**: Clone → `npm install` → `npm run dev`
- **GitHub Web**: Click "Edit" button on any file
- **GitHub Codespaces**: Code → Codespaces → New codespace

---

## 📞 Support

**Project Repository**: [GitHub](https://github.com/your-org/agreement-gallery)  
**Lovable Project**: [Edit in Lovable](https://lovable.dev/projects/6c609d70-6a32-49a2-a1a0-3daee62d2568)  
**Supabase Dashboard**: [View Database](https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys)

---

## 📄 License

Proprietary - Buligo Capital © 2025

---

**Last Updated**: 2025-10-12  
**Maintainer**: Finance & Operations Team
