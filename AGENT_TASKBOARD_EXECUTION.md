# Agent Taskboard Execution Log

**Date:** 2025-10-30
**Session:** Commissions MVP Demo
**Status:** In Progress

---

## Track 0: Orchestration ✅ COMPLETE

**Owner:** PM/Claude
**Status:** Acknowledged
**Artifacts:**
- ✅ Taskboard structure confirmed
- ✅ Agent assignments distributed
- ✅ Critical path mapped
- ✅ Todo list created with 13 tasks

---

## Track A: Data & DB (Agent: DataOps)

**Owner:** DataOps Agent
**Timeline:** 15-20 minutes
**Dependencies:** None (start immediately)

### A1: Enable Commissions UI ⏳ IN PROGRESS

**Task:** Enable `commissions_engine` feature flag

**Files:**
- Input: `01_enable_commissions_flag.sql`
- Helper: `00_run_sql_step.ps1 -Step 1`

**Execution:**
```powershell
.\00_run_sql_step.ps1 -Step 1
# Then paste in Supabase SQL Editor
```

**DoD:** `enabled=true`, `allowed_roles={admin,finance}`

**Acceptance Criteria:**
```sql
SELECT key, enabled, allowed_roles
FROM feature_flags WHERE key='commissions_engine';
```

**Expected Result:**
| key | enabled | allowed_roles |
|-----|---------|--------------|
| commissions_engine | true | {admin,finance} |

**Status:** Awaiting execution
**Blocker:** None
**Notes:** SQL script ready, needs manual paste to Supabase

---

### A2: Fix Agreements → Deal Mapping ⏳ PENDING

**Task:** Update commission agreements to correct deal_id

**Files:**
- Input: `02_fix_agreements_deal_mapping.sql`
- Helper: `00_run_sql_step.ps1 -Step 2`

**Execution:**
1. Run PART A discovery queries
2. Fill in `_party_deal_map` table with actual mappings
3. Run PART C preview
4. Execute UPDATE statement
5. Run PART D verification

**DoD:** All distributor agreements point to correct deals, no placeholders

**Acceptance Criteria:**
```sql
SELECT deal_id, COUNT(*)
FROM agreements
WHERE kind='distributor_commission'
GROUP BY deal_id ORDER BY 2 DESC;
```

**Expected Result:** Multiple deals, not all on deal_id=1

**Status:** Waiting for A1 completion
**Blocker:** None
**Notes:** Requires manual mapping based on discovery

---

### A3: Seed/Confirm Minimal Pilot Data ⏳ PENDING

**Task:** Verify at least 3 recent contributions exist

**Files:**
- Input: `05_verification.sql` (PART A, query #13)

**Execution:**
```sql
SELECT id, investor_id, amount, created_at
FROM contributions
ORDER BY created_at DESC LIMIT 10;
```

**DoD:** ≥3 recent contributions available

**Acceptance Criteria:** Query returns at least 3 rows

**Status:** Waiting for A2 completion
**Blocker:** None
**Notes:** May need to create test contributions if none exist

---

## Track B: Backend (Agent: API/Edge)

**Owner:** API/Edge Agent
**Timeline:** 15-20 minutes
**Dependencies:** Track A complete

### B4: Compute Commissions (Pilot Batch) ⏳ PENDING

**Task:** Compute commissions for recent contributions

**Files:**
- Script: `03_compute_commissions.ps1`

**Execution:**
```powershell
.\03_compute_commissions.ps1
```

**DoD:** Commission rows created with snapshot_json, amounts

**Acceptance Criteria:**
```sql
SELECT id, contribution_id, status, base_amount, vat_amount, total_amount, computed_at
FROM commissions ORDER BY updated_at DESC LIMIT 10;
```

**Expected Result:** ≥3 commissions in DRAFT status

**Status:** Waiting for Track A
**Blocker:** Requires A1, A2, A3
**Notes:** Needs $env:ADMIN_JWT set

---

### B5: Workflow Happy Path (Draft→Paid) ⏳ PENDING

**Task:** Test full workflow on 1 commission

**Files:**
- Script: `04_workflow_test.ps1`

**Execution:**
```powershell
.\04_workflow_test.ps1
```

**DoD:** ≥1 row reaches PAID with payment_ref

**Acceptance Criteria:**
```sql
SELECT id, status, submitted_at, approved_at, paid_at, payment_ref
FROM commissions WHERE status='paid'
ORDER BY paid_at DESC LIMIT 5;
```

**Expected Result:** 1 commission with all timestamps set

**Status:** Waiting for B4
**Blocker:** Requires B4
**Notes:** Uses Admin JWT for approve/mark-paid

---

### B6: Service-Key Guard Check (Security) ⏳ PENDING

**Task:** Verify service key blocked from mark-paid

**Execution:** Manual cURL test (to be created)

**DoD:** 403 response, audit log entry

**Acceptance Criteria:**
- HTTP 403 response
- Error body: `{"error": "Forbidden", "message": "Service keys cannot mark commissions as paid"}`

**Status:** Waiting for B5
**Blocker:** Requires B5
**Notes:** Negative test for security validation

---

## Track C: Frontend (Agent: UI/React)

**Owner:** UI/React Agent
**Timeline:** 10-15 minutes
**Dependencies:** Track B complete

### C7: Commissions List & Detail Smoke ⏳ PENDING

**Task:** UI smoke test - list and detail pages

**Execution:**
1. Navigate to http://localhost:8081/commissions
2. Click tabs (All, Draft, Pending, Approved, Paid)
3. Open a commission row → verify detail page
4. Test actions (Submit, Approve, Mark Paid)

**DoD:** No console errors, state changes reflect immediately

**Acceptance Criteria:**
- Screenshots: List page with rows, Detail page with breakdown
- Console: 0 errors/warnings
- Actions work for correct roles

**Status:** Waiting for Track B
**Blocker:** Requires B5
**Notes:** Admin login required

---

### C8: Feature-Flag Guard & Nav ⏳ PENDING

**Task:** Verify RBAC and feature flag guards

**Execution:**
1. Login as admin → verify Commissions in sidebar
2. Login as viewer → verify Commissions hidden
3. Direct URL as viewer → verify 404 or guard message

**DoD:** Sidebar/route guards align with roles

**Acceptance Criteria:**
- Admin: Commissions visible, all actions work
- Finance: Commissions visible, approve/mark-paid blocked
- Viewer: Commissions hidden, direct URL blocked

**Status:** Waiting for C7
**Blocker:** Requires C7
**Notes:** Test with multiple user roles

---

## Track D: QA (Agent: QA/Contracts)

**Owner:** QA/Contracts Agent
**Timeline:** 10-15 minutes
**Dependencies:** Track C complete

### D9: Verification & Party Payout Report ⏳ PENDING

**Task:** Run verification queries and generate reports

**Files:**
- Input: `05_verification.sql`
- Helper: `00_run_sql_step.ps1 -Step 5`

**Execution:**
```powershell
.\00_run_sql_step.ps1 -Step 5
# Then paste in Supabase SQL Editor
```

**DoD:** Party-level totals for approved+paid; integrity checks pass

**Acceptance Criteria:**
```sql
-- Summary
SELECT party_id, SUM(total_amount) AS total_due
FROM commissions
WHERE status IN ('approved','paid')
  AND COALESCE(paid_at, approved_at)::date
      BETWEEN current_date-7 AND current_date
GROUP BY party_id ORDER BY total_due DESC;

-- Integrity
SELECT COUNT(*) AS mismatches
FROM commissions
WHERE ROUND(base_amount + vat_amount, 2) <> ROUND(total_amount, 2);
```

**Expected Result:** Mismatches = 0

**Status:** Waiting for Track C
**Blocker:** Requires C7
**Notes:** Export reports as CSV

---

### D10: Negative Matrix (Spot) ⏳ PENDING

**Task:** Test negative cases

**Cases:**
1. Reject without reason → 400
2. Non-admin approve → 403
3. Viewer all actions → 403

**DoD:** All return standardized errors, 0× 500s

**Acceptance Criteria:** Table of request → expected code → actual code

**Status:** Waiting for D9
**Blocker:** Requires D9
**Notes:** Create spot test script

---

## Track E: Docs & Handoff (Agent: Docs)

**Owner:** Docs Agent
**Timeline:** 10-15 minutes
**Dependencies:** Track D complete

### E11: Demo Guide Checkoff ⏳ PENDING

**Task:** Update DEMO_EXECUTION_GUIDE.md with results

**Execution:**
1. Add screenshots from C7
2. Add query outputs from D9
3. Update troubleshooting based on issues encountered

**DoD:** Guide reflects today's run with actual results

**Acceptance Criteria:** Updated guide with screenshots and outputs

**Status:** Waiting for Track D
**Blocker:** Requires D9, D10
**Notes:** Capture all artifacts

---

### E12: Status Snapshot ⏳ PENDING

**Task:** Update COMMISSIONS_MVP_STATUS.md

**Execution:**
1. Document what passed
2. Document what remains
3. Capture any blockers (none expected)

**DoD:** ≤1 page snapshot posted

**Acceptance Criteria:** Updated status file

**Status:** Waiting for E11
**Blocker:** Requires E11
**Notes:** Final handoff document

---

## Stretch Goals (Post-MVP)

### Tiered Rates by Deal Close Date
**Status:** Not started
**Owner:** Backend Agent
**Timeline:** 1 hour

### CSV Export for Payouts
**Status:** Not started
**Owner:** Backend Agent
**Timeline:** 30 minutes

### OpenAPI Update & E2E
**Status:** Not started
**Owner:** QA Agent
**Timeline:** 1 hour

---

## Overall Progress

**Total Tasks:** 13 (12 MVP + Track 0)
**Completed:** 1 (Track 0)
**In Progress:** 0
**Pending:** 12
**Blocked:** 0

**Estimated Time Remaining:** 60-85 minutes

---

## Blockers & Issues

**Current Blockers:** None

**Issues Encountered:** _To be filled during execution_

---

## Next Action

**Immediate:** Execute Track A1 - Enable feature flag
**Command:** `.\00_run_sql_step.ps1 -Step 1`
**Manual Step:** Paste SQL in Supabase and execute

---

_Last Updated: 2025-10-30_
_Session: Commissions MVP Demo_
