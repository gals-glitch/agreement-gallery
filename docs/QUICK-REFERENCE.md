# Quick Reference Guide - Buligo Capital Fee Management System

**Version:** 1.2.0
**Last Updated:** 2025-10-16

---

## 🎯 For the Next AI Session

Hi! I'm the documentation for the next AI assistant. Here's everything you need to know about this project:

---

## 📋 Project Context

**What is this?** A fee management system for private equity funds and real estate deals.

**Latest Session:** 2025-10-16 Day 3 (see `SESSION-2025-10-16.md`)

**Version:** 1.2.0

**Status:** Global API infrastructure complete, Contributions feature deployed, 1,390 investors loaded

---

## 🗺️ Where to Find Things

### **User asks about...**

#### Authentication / Login / Password Reset
- **Implementation:** `src/hooks/useAuth.tsx` (lines 230-252 for reset)
- **Route:** `src/App.tsx` (line 38 for `/auth/reset`)
- **Config:** `.env` (VITE_PUBLIC_APP_URL variable)
- **Docs:** `docs/PASSWORD-RESET-FIX.md`
- **Quick Setup:** `docs/PASSWORD-RESET-QUICKSTART.md`

#### Contributions / Paid-in Capital
- **Frontend Page:** `src/pages/Contributions.tsx` (430 lines)
- **API Client:** `src/api/contributions.ts` (140 lines)
- **API Handler:** `supabase/functions/api-v1/index.ts` (lines 829-924)
- **Database:** `supabase/migrations/20251016000002_redesign_02_contributions.sql`
- **Docs:** `docs/CONTRIBUTIONS-API.md`
- **OpenAPI:** `docs/openapi.yaml` (lines 640-824)

#### Global API Infrastructure (NEW v1.2.0)
- **HTTP Wrapper:** `src/api/http.ts` (170 lines)
- **Contributions Client:** `src/api/contributions.ts` (140 lines)
- **All API Clients:** `src/api/clientV2.ts` (partiesAPI, fundsAPI, dealsAPI, etc.)
- **Deals Page:** `src/pages/Deals.tsx` (with API integration)

#### Data Loading
- **Investor CSV Script:** `scripts/load_investors.ps1` (PowerShell)
- **Generated SQL:** `scripts/load_investors.sql` (1,390 investors + 282 deals)

#### API Documentation
- **Full Spec:** `docs/openapi.yaml`
- **Contributions:** `docs/CONTRIBUTIONS-API.md`
- **Workflows (Agreements & Runs):** `docs/WORKFLOWS-API.md` ✨ NEW
- **Edge Function:** `supabase/functions/api-v1/index.ts`

#### Database Schema
- **Migrations:** `supabase/migrations/` directory
- **Core Tables:** `20251016000001_redesign_01_core.sql`
- **Contributions:** `20251016000002_redesign_02_contributions.sql`

#### Recent Changes
- **Session Summary:** `docs/SESSION-2025-10-16.md`
- **Changelog:** `CHANGELOG.md`
- **README:** Root `README.md`

---

## 🔑 Key Files & Line Numbers

### Frontend (React/TypeScript)
```
src/hooks/useAuth.tsx
  - Line 230-252: resetPassword() with env-aware redirect
  - Line 152-159: signIn() magic link
  - Line 183-194: signUp() email confirmation

src/App.tsx
  - Line 38: /auth/reset route alias

src/pages/ResetPassword.tsx
  - Lines 36-41: Token handling and session setting
```

### Backend (Supabase Edge Functions)
```
supabase/functions/api-v1/index.ts
  - Lines 87-92: isXor() helper
  - Lines 97-109: mapPgErrorToHttp() helper
  - Lines 114-122: validateContributionPayload()
  - Line 68: Contributions route registration
  - Lines 832-890: handleContributions() (GET/POST)
  - Lines 892-924: handleContributionsBatch() (POST)
```

### Database
```
supabase/migrations/20251016000002_redesign_02_contributions.sql
  - Lines 8-19: Contributions table definition
  - Lines 31-42: XOR constraint (contributions_one_scope_ck)
  - Lines 49-63: Additional CHECK constraints
```

### Configuration
```
.env
  - VITE_PUBLIC_APP_URL: Environment-specific base URL
  - VITE_SUPABASE_URL: Supabase project URL
  - VITE_SUPABASE_PUBLISHABLE_KEY: Anon key
```

---

## ⚡ Common Tasks

### Add New API Endpoint
1. Add handler function in `supabase/functions/api-v1/index.ts`
2. Add route case in router switch (around line 55-70)
3. Update `docs/openapi.yaml` with schema and paths
4. Test locally
5. Deploy: `supabase functions deploy api-v1`

### Fix Authentication Issue
1. Check `src/hooks/useAuth.tsx` for auth logic
2. Verify `.env` has correct VITE_PUBLIC_APP_URL
3. Check Supabase redirect URLs in dashboard
4. See `docs/PASSWORD-RESET-FIX.md` for troubleshooting

### Add Database Table/Column
1. Create new migration: `supabase migration new description`
2. Write SQL in `supabase/migrations/YYYYMMDD_description.sql`
3. Apply locally: `supabase db reset` (or `supabase db push`)
4. Update types if needed
5. Deploy: `supabase db push` to production

### Update Documentation
1. Add session summary: `docs/SESSION-YYYY-MM-DD.md`
2. Update `CHANGELOG.md` with version changes
3. Update `README.md` if major features added
4. Update `docs/openapi.yaml` for API changes

---

## 🔍 Architecture Overview

### Request Flow
```
User Browser
  ↓ (HTTP Request)
Vite Dev Server (localhost:8081)
  ↓ (API Call with JWT)
Supabase Edge Function (/functions/v1/api-v1)
  ↓ (Authentication Check)
API Router (index.ts switch statement)
  ↓ (Route to handler)
Handler Function (handleContributions, etc.)
  ↓ (Validate input)
Supabase Client (database query)
  ↓ (PostgreSQL)
Database (with constraints & triggers)
  ↓ (Response)
Handler Function (format response)
  ↓ (JSON)
User Browser (display result)
```

### Authentication Flow
```
User → Login Page → useAuth.signIn()
  ↓ (supabase.auth.signInWithPassword)
Supabase Auth (JWT issued)
  ↓ (token stored in session)
AuthContext (user state updated)
  ↓ (ProtectedRoute checks)
App (authorized access granted)
```

### Contributions XOR Validation
```
POST /contributions with body
  ↓
API: validateContributionPayload()
  ├─ Check: isXor(deal_id, fund_id)
  │   ↓ (if fails)
  │   422 VALIDATION error ← (friendly message)
  │
  └─ (if passes)
      ↓
Database: INSERT INTO contributions
  ├─ CHECK constraint: contributions_one_scope_ck
  │   ↓ (if fails)
  │   PG Error 23514 ← (safety net)
  │   ↓
  │   mapPgErrorToHttp() → 422 CHECK_VIOLATION
  │
  └─ (if passes)
      ↓
      201 Created with {id: 123}
```

---

## 🚨 Important Constraints

### Contributions Table
- **XOR Rule:** Exactly ONE of `deal_id` or `fund_id` must be set
- **Amount:** Must be positive (> 0)
- **Date:** `paid_in_date` is required
- **Investor:** `investor_id` is required and must exist

### Agreements
- **FUND + TRACK:** Fund-scoped agreements must use TRACK pricing
- **TRACK pricing:** Must have `selected_track` (A, B, or C)

---

## 🎯 Feature Guides

### AgreementForm v2 - Quick Guide

**Component:** `src/components/AgreementFormV2.tsx`

**Core Workflow:**
```
1. Select Party (Investor/Distributor)
2. Choose Scope (DEAL or FUND)
3. Pick Pricing Type (auto-set based on scope)
   ├─ DEAL → DEAL pricing (custom rates)
   └─ FUND → TRACK pricing (A/B/C)
4. Configure Rates
   ├─ DEAL: Enter custom tiered rates
   └─ TRACK: Select A/B/C (rates locked from seed data)
5. Toggle GP Fee (optional)
6. Set VAT Rate
7. Submit → Awaiting Approval → Approve/Reject
```

**Key Rules:**
- **Scope + Pricing Coupling:**
  - `DEAL` scope MUST use `DEAL` pricing (no track)
  - `FUND` scope MUST use `TRACK` pricing (requires track selection)
- **Immutability:** Once approved, agreements cannot be edited
- **Amendments:** Create new version with snapshot of previous
- **Workflow States:** DRAFT → AWAITING_APPROVAL → APPROVED
- **RBAC:** Approval requires `finance` or `admin` role

**Form Validation:**
```typescript
// Required fields
scope: 'DEAL' | 'FUND'
party_id: number (must exist)
pricing_type: 'DEAL' | 'TRACK' (auto-set from scope)

// Conditional fields
if (scope === 'FUND') {
  selected_track: 'A' | 'B' | 'C' (required)
  tiered_rates: null (auto-loaded from fund_vi_tracks)
}

if (scope === 'DEAL') {
  tiered_rates: Array<{threshold, rate}> (required, editable)
  selected_track: null
}
```

**Common Mistakes:**
- ❌ Trying to edit approved agreements → Use amend instead
- ❌ Setting track on DEAL-scoped agreements → Track only for FUND
- ❌ Leaving tiered_rates empty for DEAL pricing → Must provide custom rates
- ❌ Submitting with missing scope → Scope determines pricing type

**API Endpoints:**
- POST `/agreements` - Create draft
- POST `/agreements/:id/submit` - Submit for approval
- POST `/agreements/:id/approve` - Approve (finance/admin only)
- POST `/agreements/:id/reject` - Reject with comment (finance/admin only)
- POST `/agreements/:id/amend` - Create new version from approved

---

### Runs Workflow - Quick Guide

**Component:** `src/components/RunHeader.tsx`
**Workflow Helpers:** `src/lib/runWorkflow.ts`

**Core Workflow:**
```
1. Create Run (period_from, period_to)
2. Submit for Approval
3. Finance/Admin Reviews
   ├─ Approve → Unlocks Generate
   └─ Reject (with comment) → Back to Draft
4. Generate Final Calculations (only when APPROVED)
```

**State Machine:**
```
DRAFT ──submit──> AWAITING_APPROVAL ──approve──> APPROVED ──generate──> ✓
  ↑                       │
  └──────reject───────────┘
```

**Key Business Rules:**

1. **Generate Gating:**
   - ✅ Generate button ONLY enabled when `status = 'APPROVED'`
   - ❌ Cannot generate from DRAFT or AWAITING_APPROVAL
   - Purpose: Ensures finance approval before final calculations

2. **Deal > Fund Precedence:**
   - If investor has both deal-scoped AND fund-scoped agreements:
     - Deal-specific fee rates take precedence for that deal
     - Fund-level fees apply only to contributions without deal agreements
   - Example:
     ```
     Investor #1 has:
     - Agreement A: Fund VI, Track B (2% base)
     - Agreement B: Deal #10, Custom (3% base)

     Contribution to Deal #10 → Uses Agreement B (3% deal-specific)
     Contribution to Fund VI (no deal) → Uses Agreement A (2% fund-level)
     ```

3. **GP Fee Logic:**
   - If `agreement.gp_fee_applicable = true`:
     - GP fee rates are applied in addition to base fees
     - Stored in `gp_fee_rates` JSONB column
     - Applied per tier (threshold + rate structure)
   - Calculation: `base_fee + gp_fee`

4. **VAT Application:**
   - VAT rate stored as decimal (e.g., 0.17 = 17%)
   - Applied to final fee amount: `final_amount = fee_amount * (1 + vat_rate)`
   - VAT can be set per agreement

**RBAC Requirements:**
- Submit: Any authenticated user
- Approve: `finance` OR `admin` role
- Reject: `finance` OR `admin` role
- Generate: Any authenticated user (but only if APPROVED)

**Reject with Comment:**
- Comment is REQUIRED when rejecting
- Returns run to DRAFT status
- Preserves comment in `reviewer_comment` field
- Example: "Missing contributions for 5 deals"

**Common Mistakes:**
- ❌ Trying to generate before approval → Will fail with 403
- ❌ Forgetting deal > fund precedence → Can cause rate confusion
- ❌ Missing VAT in calculations → Check agreement.vat_rate
- ❌ Rejecting without comment → API returns 422 validation error

**API Endpoints:**
- POST `/runs/:id/submit` - Submit for approval
- POST `/runs/:id/approve` - Approve (finance/admin only)
- POST `/runs/:id/reject` - Reject with required comment (finance/admin only)
- POST `/runs/:id/generate` - Generate calculations (approved runs only)

---

## ⚠️ Gotchas & Common Pitfalls

### 1. Scope + Pricing Coupling
**Problem:** Trying to use Track pricing with Deal scope (or vice versa)

**Solution:**
- `DEAL` scope → ALWAYS use `DEAL` pricing (custom rates)
- `FUND` scope → ALWAYS use `TRACK` pricing (A/B/C selection)
- Enforced in AgreementFormV2 via auto-setting pricing_type

**Error Message:**
```json
{
  "error": "Validation failed",
  "errors": ["FUND scope requires TRACK pricing with selected_track (A, B, or C)"]
}
```

---

### 2. Approved Agreement Immutability
**Problem:** Trying to edit an approved agreement

**Solution:**
- Use the "Amend" action to create a new version
- Original agreement is preserved with snapshot
- New version starts as DRAFT

**Code Check:**
```typescript
// Wrong ❌
if (agreement.status === 'APPROVED') {
  await updateAgreement(agreement.id, { tiered_rates: newRates });
}

// Right ✅
if (agreement.status === 'APPROVED') {
  await amendAgreement(agreement.id, { reason: 'Rate update' });
  // Creates new draft version with snapshot reference
}
```

---

### 3. XOR Constraint on Contributions
**Problem:** Setting both deal_id AND fund_id (or neither)

**Solution:**
- Exactly ONE must be set
- Enforced in three layers:
  1. Client-side validation (src/api/contributions.ts)
  2. API validation (supabase/functions/api-v1/index.ts)
  3. Database constraint (contributions_one_scope_ck)

**Valid Examples:**
```javascript
// ✅ Valid - Deal only
{ investor_id: 1, deal_id: 10, paid_in_date: '2025-07-15', amount: 250000 }

// ✅ Valid - Fund only
{ investor_id: 1, fund_id: 5, paid_in_date: '2025-07-20', amount: 100000 }

// ❌ Invalid - Both set
{ investor_id: 1, deal_id: 10, fund_id: 5, paid_in_date: '2025-07-15', amount: 250000 }

// ❌ Invalid - Neither set
{ investor_id: 1, paid_in_date: '2025-07-15', amount: 250000 }
```

---

### 4. Generate Only When Approved
**Problem:** Trying to generate calculations before run approval

**Solution:**
- Check `run.status === 'APPROVED'` before enabling generate button
- API will reject with 403 if not approved
- Use workflow helpers: `canGenerate(status)` from runWorkflow.ts

**Component Pattern:**
```typescript
import { canGenerate } from '@/lib/runWorkflow';

<Button
  disabled={!canGenerate(run.status)}
  onClick={handleGenerate}
>
  Generate
</Button>
```

---

### 5. Deal > Fund Precedence
**Problem:** Confusion when investor has both deal and fund agreements

**Solution:**
- Deal-scoped fees ALWAYS override fund-scoped fees for that specific deal
- Fund fees are fallback for contributions without deal agreements
- Check precedence in calculation logic

**Example Scenario:**
```
Investor #5 has:
  - Agreement #10: Fund VI, Track B (rates: 2%, 1.5%, 1%)
  - Agreement #11: Deal #25, Custom (rates: 3%, 2.5%, 2%)

Contributions:
  1. $500k to Deal #25 → Uses Agreement #11 (deal-specific)
  2. $300k to Deal #30 → Uses Agreement #10 (fund fallback)
  3. $200k to Fund VI (no deal) → Uses Agreement #10 (fund-level)
```

---

### 6. Track Rates Are Locked
**Problem:** Trying to edit track A/B/C rates in the UI

**Solution:**
- Track rates are seed data in `fund_vi_tracks` table
- Read-only reference data (admin-only access)
- If rates need updating, requires database migration
- Regular users select track, cannot modify rates

**Where Tracks Live:**
- Database: `fund_vi_tracks` table
- Frontend: Fund VI Tracks page (Data section, admin-only)
- Used by: AgreementFormV2 when `pricing_type = 'TRACK'`

---

### 7. Reject Requires Comment
**Problem:** Rejecting agreement/run without providing a reason

**Solution:**
- Both agreements and runs require `comment` field when rejecting
- API returns 422 if comment is missing
- Comment stored in `reviewer_comment` field

**API Validation:**
```typescript
// Will fail ❌
POST /runs/123/reject
{ }

// Will succeed ✅
POST /runs/123/reject
{ "comment": "Missing contributions for Deal #15" }
```

---

### 8. Scoreboard Fields Are Read-Only
**Problem:** Trying to edit `equity_to_raise` or `raised_so_far` in Deals page

**Solution:**
- These fields are sourced from external Scoreboard imports
- Marked with "Source: Scoreboard" label
- Cannot be edited in UI
- If values need updating, re-import from Scoreboard

**Where They Come From:**
- External system: Scoreboard
- Import mechanism: Manual data load (not yet automated)
- Database columns: `deals.equity_to_raise`, `deals.raised_so_far`

---

### 9. GP Fee Toggle Persistence
**Problem:** GP fee toggle not persisting across sessions

**Solution:**
- Stored in `agreements.gp_fee_applicable` boolean column
- GP fee rates stored in `gp_fee_rates` JSONB column
- Make sure both fields are saved when toggling

**Form Handling:**
```typescript
// When GP toggle changes
const handleGpToggle = (enabled: boolean) => {
  setFormData({
    ...formData,
    gp_fee_applicable: enabled,
    gp_fee_rates: enabled ? defaultGpRates : null
  });
};
```

---

### 10. REST API vs. Supabase Client
**Problem:** Mixing legacy `supabase.from()` calls with new API client

**Solution:**
- ✅ Use centralized API clients from `src/api/clientV2.ts`
- ✅ Use global HTTP wrapper from `src/api/http.ts`
- ❌ Avoid direct `supabase.from().select()` in new code
- CI check enforces no `rest/v1` usage: `npm run check:legacy`

**Migration Pattern:**
```typescript
// Old pattern ❌
const { data, error } = await supabase
  .from('contributions')
  .select('*')
  .eq('fund_id', fundId);

// New pattern ✅
import { contributionsAPI } from '@/api/contributions';
const response = await contributionsAPI.list({ fund_id: fundId });
```

---

---

## 🧪 Test Commands

### Local Development
```bash
# Start dev server
npm run dev

# Access app
http://localhost:8081

# Access Supabase Studio
http://localhost:54323
```

### API Testing
```bash
# Get JWT token from browser (dev tools → Application → Local Storage)
# Use in Authorization header: Bearer <token>

# Test GET
curl http://localhost:54321/functions/v1/api-v1/contributions?fund_id=1 \
  -H "Authorization: Bearer YOUR_TOKEN"

# Test POST
curl -X POST http://localhost:54321/functions/v1/api-v1/contributions \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"investor_id":1,"deal_id":10,"paid_in_date":"2025-07-15","amount":250000}'

# Test XOR violation (should return 422)
curl -X POST http://localhost:54321/functions/v1/api-v1/contributions \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"investor_id":1,"deal_id":10,"fund_id":5,"paid_in_date":"2025-07-15","amount":1000}'
```

### Supabase Commands
```bash
# Login
supabase login

# Link project
supabase link --project-ref qwgicrdcoqdketqhxbys

# Check status
supabase status

# Deploy Edge Function
supabase functions deploy api-v1

# Push migrations
supabase db push

# Reset local DB
supabase db reset
```

---

## 📊 Current Status

### ✅ Working (v1.2.0)
- Password reset (localhost + preview + prod)
- Magic link authentication
- Email confirmation
- **Global HTTP wrapper** for all API calls ✨ NEW
- **Contributions page** with CSV import ✨ NEW
- **Enhanced Deals page** with API integration ✨ NEW
- Contributions API (deployed)
- XOR validation (Client + API + Database)
- **1,390 investors loaded** ✨ NEW
- **282 deals loaded** ✨ NEW
- All database migrations applied
- Edge Function deployed
- RLS policies configured

### 🚧 In Progress
- AgreementForm with scope/pricing rules and workflow
- Runs workflow polish

### 🚧 Potential Future Work
- Contribution edit/delete endpoints
- Contribution status tracking
- Contribution approval workflow
- Contribution history/audit trail
- Contribution summary/aggregation
- Contribution export (CSV/Excel)

---

## 🔐 Environment Variables

### Required
```bash
VITE_SUPABASE_PROJECT_ID="qwgicrdcoqdketqhxbys"
VITE_SUPABASE_PUBLISHABLE_KEY="eyJhbG..."
VITE_SUPABASE_URL="https://qwgicrdcoqdketqhxbys.supabase.co"
VITE_PUBLIC_APP_URL="http://localhost:8081"  # Changes per environment
```

### Change for Environment
```bash
# Development
VITE_PUBLIC_APP_URL="http://localhost:8081"

# Preview
VITE_PUBLIC_APP_URL="https://id-preview--6c609d70-6a32-49a2-a1a0-3daee62d2568.lovable.app"

# Production
VITE_PUBLIC_APP_URL="https://your-production-domain.com"
```

---

## 💡 Tips for Next Session

### User Says "Fix auth" or "Login not working"
→ Check `docs/PASSWORD-RESET-FIX.md` first
→ Verify `.env` has VITE_PUBLIC_APP_URL
→ Check Supabase redirect URLs configured

### User Says "Add contributions" or "Track capital"
→ Already done! See `docs/CONTRIBUTIONS-API.md`
→ Frontend: `src/pages/Contributions.tsx`
→ API Client: `src/api/contributions.ts`
→ Deployed and working

### User Says "Add new API endpoint" or "Create API client"
→ Use global HTTP wrapper from `src/api/http.ts`
→ Example: `http.get()`, `http.post()`, `http.patch()`, `http.delete()`
→ Automatic auth, error handling, toast notifications
→ See `src/api/contributions.ts` for pattern

### User Says "Load investor data" or "Import CSV"
→ Already done! 1,390 investors + 282 deals loaded
→ Script: `scripts/load_investors.ps1`
→ SQL: `scripts/load_investors.sql`

### User Says "Update API"
→ Modify `supabase/functions/api-v1/index.ts`
→ Update `docs/openapi.yaml`
→ Test locally
→ Deploy

### User Says "What did we do last session?"
→ Read `docs/SESSION-2025-10-16.md`
→ Read `CHANGELOG.md`
→ Read `README.md` (Recent Updates section)

### User Asks "Where is X?"
→ Use the "Where to Find Things" section above
→ Check file structure in README.md
→ Search specific line numbers listed in this guide

---

## 📞 Resources

### Documentation
- **Session Summary:** `docs/SESSION-2025-10-16.md` ← Start here!
- **API Guides:**
  - Contributions: `docs/CONTRIBUTIONS-API.md`
  - Workflows (Agreements & Runs): `docs/WORKFLOWS-API.md` ✨ NEW
- **Changelog:** `CHANGELOG.md`
- **README:** Root `README.md`
- **OpenAPI:** `docs/openapi.yaml`

### External Links
- **Supabase Dashboard:** https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys
- **Lovable Project:** https://lovable.dev/projects/6c609d70-6a32-49a2-a1a0-3daee62d2568

### Key Concepts
- **XOR Validation:** Exactly one of two values must be set
- **Two-layer Validation:** API validates + Database enforces
- **Environment-aware:** Base URL changes per environment
- **Edge Functions:** Serverless API on Supabase (Deno runtime)

---

## ✅ Pre-Flight Checklist

Before starting work, verify:
- [ ] Read `docs/SESSION-2025-10-16.md` for context
- [ ] Understand current project status (see above)
- [ ] Know where key files are located
- [ ] Have access to Supabase dashboard
- [ ] Dev server can start successfully (`npm run dev`)
- [ ] Understand XOR validation concept for contributions

---

_Quick Reference Guide v1.3.0_
_Last Updated: 2025-10-16 (Day 3-4 Complete)_
_For AI Assistant Use_
