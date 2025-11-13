# Deployment Checklist - Day 2 Complete

**Version:** 1.0
**Date:** 2025-10-16
**Status:** Ready for Deployment

---

## 📋 Pre-Deployment Checklist

### **1. Database Migrations** ✅

Apply migrations in order via Supabase Dashboard → SQL Editor:

- [ ] **Migration 00**: Types (`20251016000000_redesign_00_types.sql`)
- [ ] **Migration 01**: Core Entities (`20251016000001_redesign_01_core_entities.sql`)
- [ ] **Migration 02**: Contributions (`20251016000002_redesign_02_contributions.sql`)
- [ ] **Migration 03**: Tracks (`20251016000003_redesign_03_tracks.sql`)
- [ ] **Migration 04**: Agreements (`20251016000004_redesign_04_agreements.sql`)
- [ ] **Migration 05**: Scoreboard Import (`20251016000005_redesign_05_scoreboard_import.sql`)
- [ ] **Migration 06**: Guardrails (`20251016000006_redesign_06_guards.sql`)
- [ ] **Migration 07**: Seed Data (`20251016000007_redesign_07_seed_fund_vi.sql`)
- [ ] **Migration 08 (FIX)**: Immutability Trigger Fix (`20251016000008_fix_immutability_trigger.sql`)

**Verification:**
```sql
-- Run smoke test
-- See: scripts/smoke-test-migrations.sql
```

### **2. Edge Function Deployment** ✅

**Deploy via Supabase CLI:**
```bash
supabase functions deploy api-v1
```

**Or Deploy via Dashboard:**
1. Navigate to: Edge Functions → New Function
2. Name: `api-v1`
3. Paste contents of `supabase/functions/api-v1/index.ts`
4. Click **Deploy**

**Environment Variables to Set:**
- `SUPABASE_URL` - Auto-injected by Supabase
- `SUPABASE_SERVICE_ROLE_KEY` - Auto-injected by Supabase
- No additional variables needed

**CORS Configuration:**
Already set in function code:
```typescript
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};
```

For production, update to specific domain:
```typescript
'Access-Control-Allow-Origin': 'https://yourdomain.com'
```

### **3. Frontend Configuration** ✅

**Update `.env` file:**
```bash
# Add this line with your Supabase project ref
VITE_API_V1_BASE_URL=https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1
```

**Or add reverse proxy (Vercel/NGINX):**
```nginx
# NGINX example
location /api/v1 {
  proxy_pass https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1;
  proxy_set_header Authorization $http_authorization;
}
```

**Vercel `vercel.json` example:**
```json
{
  "rewrites": [
    {
      "source": "/api/v1/:path*",
      "destination": "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1/:path*"
    }
  ]
}
```

---

## 🧪 Post-Deployment Testing

### **Phase 1: API Endpoint Smoke Test (10 minutes)**

**Import Postman Collection:**
```bash
docs/Buligo-API-v1.postman_collection.json
```

**Update Variables:**
- `{{base_url}}` → `https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1`
- `{{token}}` → Your JWT token (get from Supabase Auth)

**Run Tests in Order:**

#### **1. Parties**
- [ ] `POST /parties` - Create "Test Distributor LLC"
- [ ] `GET /parties` - Verify listed
- [ ] `GET /parties/:id` - Verify details include tax_id
- [ ] `PATCH /parties/:id` - Update tax_id

**Expected:** All 201/200 responses, tax_id field present

#### **2. Funds**
- [ ] `POST /funds` - Create "Fund VI"
- [ ] `GET /funds` - Verify listed
- [ ] `GET /funds/:id` - Verify details

**Expected:** All 201/200 responses

#### **3. Deals**
- [ ] `POST /deals` - Create "Project Alpha"
- [ ] `GET /deals` - Verify listed
- [ ] `GET /deals/:id` - Verify equity_to_raise is null (no scoreboard yet)
- [ ] `PATCH /deals/:id` - Update status to "closed"

**Expected:** All 201/200 responses

#### **4. Fund Tracks**
- [ ] `GET /fund-tracks?fund_id=1` - Should return 3 tracks (A, B, C)
- [ ] `GET /fund-tracks/1/B` - Should return Track B details

**Expected:** Track B = 180 bps upfront, 80 bps deferred

#### **5. Agreements (Critical Path)**
- [ ] `POST /agreements` - Create FUND + Track B agreement
- [ ] `POST /agreements/:id/submit` - Submit for approval
- [ ] `POST /agreements/:id/approve` - Approve (must have manager role)
- [ ] `GET /agreements/:id` - Verify snapshot created

**Expected:**
```json
{
  "id": 1,
  "status": "APPROVED",
  "snapshot": {
    "resolved_upfront_bps": 180,
    "resolved_deferred_bps": 80,
    "seed_version": 1,
    "approved_at": "2025-10-16T..."
  }
}
```

- [ ] `POST /agreements` - Try FUND + CUSTOM (should FAIL with 400)

**Expected:** Error: "FUND-scoped agreements must use TRACK pricing"

- [ ] `POST /agreements/:id/amend` - Create amendment
- [ ] `GET /agreements/1` - Verify v1 status = "SUPERSEDED"
- [ ] `GET /agreements/2` - Verify v2 status = "DRAFT"

#### **6. Runs**
- [ ] `POST /runs` - Create run for Fund VI
- [ ] `POST /runs/:id/submit` - Submit for approval
- [ ] `POST /runs/:id/approve` - Approve (requires manager role)
- [ ] `POST /runs/:id/generate` - Generate calculation

**Expected:** All 201/200 responses

---

### **Phase 2: RBAC Testing (5 minutes)**

**Setup:**
1. Create test user WITHOUT manager role
2. Get JWT token for that user

**Tests:**
- [ ] `POST /agreements/:id/approve` - Should return 403
- [ ] `POST /runs/:id/approve` - Should return 403

**Expected:** Both return:
```json
{
  "error": "Unauthorized: requires manager or admin role"
}
```

---

### **Phase 3: Constraint Testing (5 minutes)**

#### **Test 1: FUND + CUSTOM (should fail)**
```bash
POST /agreements
{
  "scope": "FUND",
  "fund_id": 1,
  "pricing_mode": "CUSTOM"  # ← Should fail
}
```
**Expected:** 400 error

#### **Test 2: Immutability (should fail)**
```sql
-- Directly in SQL Editor
UPDATE agreements
SET selected_track = 'A'
WHERE id = 1 AND status = 'APPROVED';
```
**Expected:** Exception: "Approved agreements are immutable"

#### **Test 3: SUPERSEDED Transition (should succeed)**
```sql
-- Directly in SQL Editor
UPDATE agreements
SET status = 'SUPERSEDED', effective_to = '2025-12-31'
WHERE id = 1 AND status = 'APPROVED';
```
**Expected:** Success (trigger allows this specific transition)

---

## 🚨 Critical Issues Resolved

### **Issue #1: Immutability Trigger Blocking Amendment**

**Problem:** Original trigger blocked ALL updates to APPROVED agreements, including marking as SUPERSEDED.

**Fix Applied:** Migration 08 allows ONLY:
- `status: APPROVED → SUPERSEDED`
- `effective_to` change
- All other fields must remain unchanged

**Verification:**
```sql
-- Run test from migration 08
-- Should show: ✅ TEST 2 PASSED: Trigger allowed SUPERSEDED transition
```

### **Issue #2: Edge Function Routing**

**Problem:** Frontend calling `/api/v1` but function is at `/functions/v1/api-v1`

**Fix Applied:**
1. Updated `src/api/clientV2.ts` to read `VITE_API_V1_BASE_URL` from env
2. Documented reverse proxy setup for production

**Verification:**
Check frontend network tab shows correct URL.

---

## 📊 Test Matrix (Acceptance Criteria)

| Test Case | Expected Result | Status |
|-----------|----------------|--------|
| **FUND + Track only** | FUND + CUSTOM returns 400 | ⏳ |
| **Deal overrides Fund** | Create both, verify Deal-level terms used | ⏳ |
| **GP exclusion** | investor.is_gp=true + deal.exclude_gp=true excludes | ⏳ |
| **Snapshots** | Approving creates snapshot with resolved rates | ⏳ |
| **Amend flow** | v2 DRAFT created, v1 marked SUPERSEDED | ⏳ |
| **RBAC** | Non-manager cannot approve | ⏳ |
| **Track resolution** | Snapshot captures seed_version | ⏳ |
| **Read-only fields** | equity_to_raise not editable via API | ⏳ |

---

## 🔒 Security Checklist

- [ ] RLS enabled on all tables (do NOT disable)
- [ ] Service role key used server-side only (never exposed to client)
- [ ] JWT validation on every request
- [ ] RBAC enforced for approve/reject endpoints
- [ ] CORS configured for production domain
- [ ] Sensitive env vars stored in Supabase Secrets (not committed to git)

---

## 📝 Rollback Plan

If deployment fails, rollback steps:

### **1. Rollback Edge Function**
```bash
supabase functions deploy api-v1 --legacy-bundle=<previous-version>
```

### **2. Rollback Database (if needed)**
```sql
-- Drop new tables in reverse order
DROP TABLE IF EXISTS agreement_rate_snapshots CASCADE;
DROP TABLE IF EXISTS agreement_custom_terms CASCADE;
DROP TABLE IF EXISTS agreements CASCADE;
DROP TABLE IF EXISTS fund_tracks CASCADE;
DROP TABLE IF EXISTS contributions CASCADE;
DROP TABLE IF EXISTS deals CASCADE;
DROP TABLE IF EXISTS funds CASCADE;
DROP TABLE IF EXISTS parties CASCADE;

-- Drop types
DROP TYPE IF EXISTS agreement_status CASCADE;
DROP TYPE IF EXISTS pricing_mode CASCADE;
DROP TYPE IF EXISTS agreement_scope CASCADE;
DROP TYPE IF EXISTS track_code CASCADE;
```

**WARNING:** This destroys all data! Only use in emergency.

---

## ✅ Sign-Off

**Completed By:** _____________
**Date:** _____________
**Deployment Status:** ⏳ Pending / ✅ Complete / ❌ Failed

**Notes:**
_______________________________________________
_______________________________________________

---

## 📞 Support Contacts

- **Database Issues:** Supabase Support (https://supabase.com/support)
- **Edge Functions:** Supabase Docs (https://supabase.com/docs/guides/functions)
- **Frontend Issues:** Check browser console + network tab

---

## 🎯 Next Steps After Deployment

1. ✅ Verify all smoke tests pass
2. ✅ Create test data (parties, funds, deals, agreements)
3. ✅ Test end-to-end workflow: Create party → Create agreement → Submit → Approve → Verify snapshot
4. ⏳ Load CSV scoreboard data (optional)
5. ⏳ Continue with UI components (Funds page, Deals page, AgreementForm redesign)

---

_Last Updated: 2025-10-16_
_Version: 1.0_
