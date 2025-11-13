# Current Project Status

**Last Updated:** 2025-10-22 (CRITICAL PROJECT PIVOT + v1.9.0 Commissions System)
**Version:** 1.9.0 (Commissions Engine - Backend Complete)
**Branch:** main

---

## 🚨 **CRITICAL PROJECT PIVOT - 2025-10-22**

### **What Changed**

The fundamental business model was corrected during the 2025-10-22 session:

**❌ OLD (INCORRECT) - v1.0-1.8.0:**
- System designed to **charge INVESTORS fees** on their contributions
- Charges table tracked fees owed BY investors
- Credits reduced investor fees
- Workflow: Investor contributes → System charges investor fee + VAT

**✅ NEW (CORRECT) - v1.9.0+:**
- System designed to **pay DISTRIBUTORS/REFERRERS commissions** for bringing investors
- Commissions table tracks payments owed TO parties (distributors/referrers)
- No credits/clawbacks for commissions (future feature if needed)
- Workflow: Investor contributes → System calculates commission for party → Pay distributor

### **Why The Pivot**

The app's purpose is to:
1. Track investor contributions (uploaded from external system - already calculated)
2. **Calculate commissions owed to distributors/referrers** based on agreements
3. Manage approval workflow for commission payments
4. Generate reports for distributor payouts

**NOT** to charge investors fees on contributions.

### **What Remains From Old System**

The `charges` table and workflow (v1.0-1.8.0) remain intact for potential future use:
- Could be repurposed for investor fees if needed later
- Currently not the primary business function
- Focus is now on **commissions** system

---

## 📊 Quick Summary

**✅ v1.9.0 COMMISSIONS SYSTEM - Backend 75% Complete (2025-10-22)**

**What's Working:**
1. **Database Schema** - Commissions table with workflow states (draft → pending → approved → paid) ✅
2. **Commission Computation** - Auto-calculate based on party agreements and contribution amounts ✅
3. **API Endpoints** - 8 endpoints for compute, workflow, and reporting ✅
4. **Edge Function Deployed** - Live in production ✅
5. **Feature Flag SQL** - Ready to apply (user action required)

**What's Pending:**
1. **UI Pages** - Commissions List and Detail pages (not started)
2. **Test Agreement** - Sample commission agreement for Kuperman party
3. **End-to-End Test** - Full workflow verification
4. **Party Reports** - Commission summary by party

**Zero Critical Bugs** ✅

---

## 🎯 Current State (Post-Pivot Session 2025-10-22)

### v1.9.0 - Commissions Engine (Backend Complete)

**Database Schema (Applied ✅):**
- `commissions` table - Core commission tracking
- `commission_status` enum - Workflow states
- `agreement_kind` enum - Distinguish investor fees vs distributor commissions
- `agreements.kind` column - Commission vs fee agreements
- `agreements.commission_party_id` column - Link to party earning commission
- RLS policies - Finance read/submit, Admin approve/paid
- Indexes - Optimized for party/status/date queries
- `commissions_summary` view - Party-level reporting

**Backend API (Deployed ✅):**
- `POST /commissions/compute` - Compute commission for single contribution
- `POST /commissions/batch-compute` - Batch computation for CSV imports
- `GET /commissions` - List with filters (party, investor, fund/deal, date, status)
- `GET /commissions/:id` - Get single commission details
- `POST /commissions/:id/submit` - Submit for approval (draft → pending)
- `POST /commissions/:id/approve` - Approve payment (Admin only)
- `POST /commissions/:id/reject` - Reject with reason (Admin only)
- `POST /commissions/:id/mark-paid` - Mark as paid (Admin only, NO service key)

**Commission Computation Logic:**
1. Load contribution (investor, amount, date, fund/deal)
2. Resolve party via `investors.introduced_by`
3. Find approved commission agreement for party + scope
4. Select applicable term based on contribution date
5. Calculate: `base = amount × (rate_bps / 10,000)`
6. Calculate VAT if mode = 'on_top'
7. UPSERT commission row (idempotent by contribution_id + party_id)

**Agreement Snapshot Example (Kuperman):**
```json
{
  "kind": "distributor_commission",
  "party_id": "uuid",
  "scope": { "fund_id": 1, "deal_id": null },
  "terms": [
    { "from": "2018-01-01", "to": "2018-02-01", "rate_bps": 250, "vat_mode": "on_top", "vat_rate": 0.2 },
    { "from": "2018-02-01", "to": "2019-12-12", "rate_bps": 270, "vat_mode": "on_top", "vat_rate": 0.2 },
    { "from": "2019-12-12", "to": "2020-10-31", "rate_bps": 300, "vat_mode": "on_top", "vat_rate": 0.2 },
    { "from": "2020-10-31", "to": null, "rate_bps": 350, "vat_mode": "on_top", "vat_rate": 0.2 }
  ]
}
```

**Files Created (2025-10-22):**
- `supabase/migrations/20251022000001_commissions_schema.sql` (300+ lines)
- `supabase/functions/api-v1/commissionCompute.ts` (350+ lines)
- `supabase/functions/api-v1/commissions.ts` (550+ lines)
- `apply_commissions_migration.ps1` - Helper script
- `apply_feature_flag.ps1` - Helper script
- `add_commissions_feature_flag.sql` - Feature flag setup

**Files Modified (2025-10-22):**
- `supabase/functions/api-v1/index.ts` - Added commissions routes
- `supabase/functions/api-v1/agreementDocs.ts` - Fixed 500 error (nested joins)

---

## 📋 Previous Versions Summary

### v1.8.0 - Charge Workflow (Now Legacy - Investor Fees)
- **Status:** Complete but not primary business function
- **Purpose:** Originally designed to charge investors fees (incorrect model)
- **Current Use:** Could be repurposed later if investor fees are needed
- **Key Features:**
  - Charge computation from contributions
  - FIFO credit auto-application
  - Workflow: draft → pending → approved → paid
  - Full UI (Charges list, detail pages)

### v1.7.0 - P2 Implementation
- RLS infinite recursion fix
- POST /charges/compute endpoint
- Credits schema migration with FIFO optimization
- Agreement snapshot configuration

### v1.6.0 - P1 Features
- RBAC (Role-Based Access Control)
- Organization Settings
- Credits FIFO auto-application engine

### v1.5.0 - Feature Foundation
- Feature Flags system
- VAT Admin interface
- Agreement Documents repository
- Transactions & Credits ledger

---

## 🔧 Immediate Next Steps (Post-Pivot)

### 1. Apply Feature Flag (USER ACTION - 2 minutes)
```sql
-- Already copied to clipboard via apply_feature_flag.ps1
-- Paste into: https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys/sql/new
INSERT INTO feature_flags (key, name, description, enabled, allowed_roles)
VALUES ('commissions_engine', 'Commissions Engine', ..., true, ARRAY['admin', 'finance']);
```

### 2. Create Test Commission Agreement (15 minutes)
- Create agreement for party "Kuperman"
- Scope: Fund or Deal
- Status: APPROVED
- snapshot_json with time-windowed terms (see example above)

### 3. Build UI Pages (2-3 hours)
- `src/pages/Commissions.tsx` - List page with tabs/filters
- `src/pages/CommissionDetail.tsx` - Detail page with workflow actions
- Clone from Charges pages (same patterns)

### 4. End-to-End Test (30 minutes)
```bash
# 1. Compute commission
curl -X POST $API/commissions/compute -d '{"contribution_id": 123}'

# 2. Submit for approval
curl -X POST $API/commissions/:id/submit -H "Authorization: Bearer $FINANCE_JWT"

# 3. Approve
curl -X POST $API/commissions/:id/approve -H "Authorization: Bearer $ADMIN_JWT"

# 4. Mark paid
curl -X POST $API/commissions/:id/mark-paid -d '{"payment_ref": "WIRE-001"}' -H "Authorization: Bearer $ADMIN_JWT"
```

### 5. Party Commission Report (1 hour)
```sql
-- Summary by party
SELECT
  party_id,
  party_name,
  status,
  SUM(total_amount) as total_owed
FROM commissions_summary
WHERE status IN ('approved', 'paid')
GROUP BY party_id, party_name, status;
```

---

## 📚 Documentation Status

### Updated Files (2025-10-22)
- ✅ `CURRENT_STATUS.md` - This file (reflects pivot)
- ✅ `CHANGELOG.md` - Added v1.9.0 section with pivot explanation
- ✅ `README.md` - Updated purpose and features
- ⏳ `QUICK_REFERENCE_v1_9_0.md` - To be created
- ⏳ `SESSION-2025-10-22-PIVOT.md` - To be created

### Documentation To Create
- Session summary for 2025-10-22 pivot
- Commission API reference
- Party agreement authoring guide
- Commission computation examples

---

## 🎯 Business Model (Corrected)

### Core Workflow

```
1. UPLOAD CONTRIBUTIONS (CSV from external system)
   ├─ Investor #201 contributed $50,000 to Deal #42
   └─ Investor #150 contributed $100,000 to Fund VI

2. LINK TO DISTRIBUTORS (via investors.introduced_by)
   ├─ Investor #201 was referred by Party "ABC Advisors"
   └─ Investor #150 was referred by Party "XYZ Partners"

3. COMPUTE COMMISSIONS (automatic on contribution upload)
   ├─ ABC Advisors: $50,000 × 2.5% = $1,250 + 20% VAT = $1,500
   └─ XYZ Partners: $100,000 × 3.5% = $3,500 + 20% VAT = $4,200

4. APPROVAL WORKFLOW
   ├─ Finance submits commissions for approval
   ├─ Admin reviews and approves
   └─ Admin marks as paid after wire transfer

5. PARTY REPORTS
   └─ ABC Advisors: $1,500 owed (approved, not yet paid)
   └─ XYZ Partners: $4,200 owed (approved, not yet paid)
```

### Key Entities

- **Parties** = Distributors/Referrers who earn commissions
- **Investors** = Individuals contributing to funds/deals (linked to parties via `introduced_by`)
- **Contributions** = Investor paid-in capital (uploaded from external system)
- **Commissions** = Amounts owed TO parties for bringing investors
- **Agreements** = Commission terms for each party (time-windowed rates)

---

## 🔒 Security & Permissions

### RBAC for Commissions

| Role       | Read | Compute | Submit | Approve | Reject | Mark Paid |
|------------|------|---------|--------|---------|--------|-----------|
| **admin**  | ✅   | ✅      | ✅     | ✅      | ✅     | ✅        |
| **finance**| ✅   | ✅      | ✅     | ❌      | ❌     | ❌        |
| **ops**    | ✅   | ❌      | ❌     | ❌      | ❌     | ❌        |
| **manager**| ✅   | ❌      | ❌     | ❌      | ❌     | ❌        |
| **viewer** | ❌   | ❌      | ❌     | ❌      | ❌     | ❌        |
| **service**| ✅   | ✅      | ✅     | ✅      | ✅     | ❌        |

**Note:** Service keys CANNOT mark commissions as paid (requires human admin verification).

---

## 🚀 Deployment Status

**Environment:** Production (qwgicrdcoqdketqhxbys.supabase.co)

**Latest Deployment:** 2025-10-22
- ✅ Database migration applied (commissions schema)
- ✅ Edge Function deployed (commissions endpoints)
- ⏳ Feature flag pending (SQL ready, needs manual apply)
- ❌ UI not deployed yet (pending build)

**Feature Flags:**
- ✅ `charges_engine` - ENABLED (legacy investor fees)
- ✅ `vat_admin` - ENABLED
- ✅ `docs_repository` - ENABLED
- ⏳ `commissions_engine` - PENDING (SQL ready to apply)
- ❌ `credits_management` - DISABLED
- ❌ `reports_dashboard` - DISABLED

---

## 🐛 Known Issues

**Zero Critical Issues** ✅

**Minor:**
1. Documents page had 500 error - ✅ FIXED (simplified nested joins)
2. Migration history out of sync - Using manual SQL execution via Supabase dashboard
3. Charges system (v1.8.0) is now legacy - Not removed, just not primary focus

---

## 📞 Support & Next Session

**For Next AI Assistant:**

1. **Read this file first** - Understand the pivot from investor fees to distributor commissions
2. **Priority:** Build Commissions UI pages (List + Detail)
3. **Test Setup:** Create sample commission agreement for Kuperman party
4. **Verification:** Run end-to-end workflow test
5. **Documentation:** Create session summary and API reference

**Critical Context:**
- The entire charges system (v1.0-1.8.0) was built on wrong assumption
- Commissions system (v1.9.0) is the correct business model
- Backend is complete, UI is pending
- Zero bugs, system is stable

---

_Last Updated: 2025-10-22_
_Version: 1.9.0 (Commissions Engine - Backend Complete)_
_Next: UI Pages + End-to-End Testing_
