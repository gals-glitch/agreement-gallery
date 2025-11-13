# Execution Plan: Week of Nov 2-6, 2025

## 🎯 Objective
Complete remaining 4 tickets to achieve 100% commission computation coverage and production-ready CSV import system.

---

## 📋 Ticket Matrix

### DB-01: Add FK + Backfill investor→party

**Owner:** Backend (Agent–Backend)
**Timeline:** Sun Nov 2, 10:00 → 14:00 (4 hours)
**Status:** 🟡 Ready to start

**Scope:**
- Apply migration `20251102_add_investor_party_fk.sql`
- Backfill links from notes (regex pattern: "Introduced by: <party name>")
- Enable `party_aliases` for fuzzy matching
- Re-run verification scripts

**DoD / Success Criteria:**
- ✅ Migration applied and idempotent (can re-run safely)
- ✅ ≥80% of investors that mention a party in notes receive valid `introduced_by_party_id`
- ✅ `scripts/verify_ready_to_compute.sql` shows higher count of eligible contributions vs baseline
- ✅ Verification results logged with before/after counts

**Commands:**
```bash
# Apply migration
supabase db push

# Verify results
psql -f scripts/verify_ready_to_compute.sql
psql -f scripts/verify_missing_links.sql
psql -f scripts/verify_coverage_gaps.sql
```

**References:**
- Migration file: `supabase/migrations/20251102_add_investor_party_fk.sql`
- Spec: `NEXT_STEPS.md` (DB-01 section)
- Verification scripts: `scripts/verify_*.sql`

---

### IMP-01: Import Service (preview/commit)

**Owner:** DataOps + Backend (Agent–Data)
**Timeline:** Sun Nov 2, 14:00 → Mon Nov 3, 16:00 (26 hours)
**Status:** 🔴 Blocked by DB-01

**Scope:**
- Implement `imports.ts` endpoints for Parties / Investors / Agreements / Contributions
- Build preview mode (validate + diff, no mutations)
- Build commit mode (insert into prod with audit trail)
- Create staging schema: `stg_parties`, `stg_investors`, `stg_agreements`, `stg_contributions`
- Create `import_runs` audit table

**DoD / Success Criteria:**
- ✅ `POST /import/:entity?mode=preview` returns row-level validation and upsert plan
- ✅ `POST /import/:entity?mode=commit` writes exactly what preview promised (counts match)
- ✅ Audit entry recorded in `import_runs` per import with stats JSON
- ✅ Bad rows rejected with clear error messages (e.g., "deal not resolved")
- ✅ Matching rules work: exact + fuzzy via `party_aliases`

**API Endpoints:**
```
POST /import/parties?mode=preview|commit
POST /import/investors?mode=preview|commit
POST /import/agreements?mode=preview|commit
POST /import/contributions?mode=preview|commit
```

**Response Format:**
```json
{
  "mode": "preview",
  "entity": "investors",
  "stats": {
    "insert": 10,
    "update": 5,
    "skip": 2,
    "errors": 1
  },
  "matches": {
    "exact": 15,
    "fuzzy": 2
  },
  "errors": [
    {"row": 3, "field": "introduced_by", "message": "Party 'ABC Corp' not found"}
  ]
}
```

**References:**
- Spec: `NEXT_STEPS.md` (IMP-01 section)
- Matching rules defined in spec
- Service role key auth required

---

### IMP-02: CLI Harness & Scripts

**Owner:** DataOps (Agent–Tooling)
**Timeline:** Mon Nov 3, 10:00 → Tue Nov 4, 12:00 (26 hours)
**Status:** 🔴 Blocked by IMP-01

**Scope:**
- Wire `npm run import:all` to call preview/commit endpoints
- Provide PowerShell/Node runners
- Sample CSV → preview → commit flow with user confirmation
- Error handling and retry logic

**DoD / Success Criteria:**
- ✅ `npm run import:all -- --dir=./imports/demo --mode=preview` performs preview for all 4 entities
- ✅ Console summary shows inserted/updated/ignored counts per entity
- ✅ Non-zero exit code on validation errors
- ✅ Commit mode requires explicit confirmation after preview
- ✅ Works with both PowerShell and Node

**Usage:**
```bash
# Preview mode (dry run)
SUPABASE_URL=... \
SUPABASE_SERVICE_ROLE_KEY=... \
npm run import:all -- \
  --dir "C:\Users\GalSamionov\Downloads" \
  --mode preview

# Commit mode (after reviewing preview)
npm run import:all -- \
  --dir "C:\Users\GalSamionov\Downloads" \
  --mode commit
```

**CSV Order:**
1. `01_parties.csv`
2. `02_investors.csv`
3. `03_agreements.csv`
4. `04_contributions.csv`

**References:**
- Spec: `NEXT_STEPS.md` (IMP-02 section)
- Implementation: `scripts/importAll.ts` (to be created)
- `package.json` scripts entry

---

### UI-01: Admin Compute Button + Agreement Context

**Owner:** Frontend (Agent–Frontend)
**Timeline:** Tue Nov 4, 12:00 → Thu Nov 6, 13:00 (49 hours)
**Status:** 🔴 Blocked by DB-01 (optional for basic UI work)

**Scope:**
1. **Commissions Page (`src/pages/Commissions.tsx`):**
   - Add "Compute Eligible (N)" button (admin-only)
   - Button calls `POST /commissions/batch-compute`
   - Show toast with `{computed, skipped_no_agreement, skipped_no_party, errors}`
   - Refresh commissions list without page reload

2. **Commission Detail Page (`src/pages/CommissionDetail.tsx`):**
   - Add "Applied Agreement" card showing:
     - Party name
     - `rate_bps`, `vat_mode`, `vat_rate`
     - `effective_from..to`
     - `pricing_mode`
   - Collapsible "Agreement snapshot (JSON)" section
   - Keep "mark as paid" admin-only (already enforced via RBAC)

**DoD / Success Criteria:**
- ✅ "Compute eligible" button visible to Admin only; disabled while running
- ✅ Clicking button creates ≥8 draft commissions (or more after DB-01 backfill)
- ✅ Commission Detail shows agreement card with rate & VAT (no console errors)
- ✅ Light e2e (draft→pending→approved) still passes
- ✅ "Mark paid" requires admin JWT (403 for service key)

**RBAC Check:**
```typescript
// Only show compute button if user has 'admin' role
{user?.roles?.includes('admin') && (
  <Button onClick={handleComputeEligible}>
    Compute Eligible ({eligibleCount})
  </Button>
)}
```

**References:**
- Spec: `NEXT_STEPS.md` (UI-01 section)
- Current workflow: `test_workflow.ps1` (reference for expected behavior)
- Security matrix: `docs/SECURITY_MATRIX_v1_8_0.md`

---

## 🚦 Verification & Demo Gates

### Gate A: Post-DB-01 Verification
**When:** Sun Nov 2, 15:30
**Who:** Backend

**Actions:**
```sql
-- Run all verification scripts
\i scripts/verify_ready_to_compute.sql
\i scripts/verify_missing_links.sql
\i scripts/verify_coverage_gaps.sql
```

**Expected Results:**
- Higher "eligible contributions" count vs today's baseline (currently 7)
- Reduced "investors without party" count (currently 27)
- Clear list of remaining gaps for manual resolution

**Pass Criteria:**
- ≥15 contributions ready to compute (was 7)
- ≤15 investors missing party links (was 27)

---

### Gate B: Post-IMP-01 CSV Preview
**When:** Mon Nov 3, 16:30
**Who:** DataOps + Backend

**Actions:**
```bash
# Dry-run CSV through preview
npm run import:all -- --dir=./sample_csvs --mode=preview

# Review validation results
# If clean, commit
npm run import:all -- --dir=./sample_csvs --mode=commit

# Re-verify coverage
psql -f scripts/verify_ready_to_compute.sql
```

**Expected Results:**
- Preview shows validation stats with 0 fatal errors
- Commit matches preview counts exactly
- Improved coverage after import

**Pass Criteria:**
- Preview and commit counts match
- Import run logged in `import_runs` table
- No duplicate data created on re-run (idempotent)

---

### Gate C: Full E2E + UI Demo
**When:** Thu Nov 6, 14:00
**Who:** Frontend + QA

**Actions:**
1. **From UI:**
   - Login as Admin
   - Navigate to Commissions page
   - Click "Compute eligible"
   - Confirm ≥8 new DRAFT commissions appear

2. **Workflow test:**
   ```powershell
   .\set_key.ps1
   .\test_workflow.ps1
   ```

3. **Auth verification:**
   ```bash
   # Verify service key can't mark paid
   curl -X POST https://.../commissions/{id}/mark-paid \
     -H "Authorization: Bearer $SERVICE_KEY" \
     # Expected: 403 Forbidden
   ```

**Expected Results:**
- ≥8 new commissions created (or more if DB-01/IMP increased coverage)
- Workflow transitions work: draft→pending→approved
- Mark paid blocked for service key (403)
- Commission detail shows applied agreement

**Pass Criteria:**
- All 3 actions complete successfully
- No console errors in UI
- Auth enforcement working as designed

---

## ⚠️ Risks & Mitigations

### Risk 1: Name/alias mismatches between CSV and parties
**Impact:** Import fails to link investors to parties
**Mitigation:**
- Use `party_aliases` table added in DB-01
- Extend with obvious variants during IMP-01 previews
- Fail closed on ambiguous matches (manual review queue)

### Risk 2: Auth drift in Edge Functions
**Impact:** Security model breaks, service key gains admin powers
**Mitigation:**
- Keep service-role vs admin-JWT behavior exactly as documented
- Re-run `/auth/check` during Gate C to confirm role
- Review RBAC matrix before each deploy

### Risk 3: Coverage gaps (deals without agreements)
**Impact:** Commissions still can't be computed for some contributions
**Mitigation:**
- Short-term: Seed rule (100 bps + VAT) for demo datasets only
- Keep OFF in prod by default (manual agreement creation preferred)
- Optional: Implement auto-seed feature flag in future sprint

### Risk 4: Migration rollback needed
**Impact:** Backfill logic has bugs, need to revert
**Mitigation:**
- Migration is idempotent (safe to re-run)
- Test on staging DB first with sample data
- Keep verification queries handy to validate before/after

---

## 📞 Communication Cadence

### Daily Standup
**Time:** 09:30 Asia/Jerusalem
**Duration:** 10 minutes
**Format:** Async or sync, blockers only

**Template:**
- Yesterday: [ticket] completed [milestone]
- Today: Working on [ticket], targeting [gate]
- Blockers: [none | X is blocking Y]

### Gate Updates (Async)
**When:** After each gate completion
**Format:** Post command + result snippets

**Example:**
```
Gate A ✅ Complete (Sun 15:45)

Commands:
psql -f scripts/verify_ready_to_compute.sql

Results:
- Ready to compute: 18 (was 7) ✅
- Missing links: 12 (was 27) ✅
- Coverage gaps: 15 party-deal pairs need agreements

Next: Starting IMP-01
```

### Demo Prep
**When:** Thu Nov 6, 13:30
**Duration:** 30 minutes
**Who:** All owners

**Agenda:**
- Walk through each ticket deliverable
- Test e2e flow together
- Confirm Gate C criteria met
- Document any known issues for future sprint

---

## 📝 One-Line Assignments (Copy to Tracker)

```
DB-01 (Agent–Backend) — Apply migration & backfill, then run verify scripts; target Sun Nov 2, 14:00
IMP-01 (Agent–Data) — Build imports.ts with preview/commit & staging; target Mon Nov 3, 16:00
IMP-02 (Agent–Tooling) — Wire npm run import:all and wrappers; target Tue Nov 4, 12:00
UI-01 (Agent–Frontend) — Add "Compute eligible" + agreement card; target Thu Nov 6, 13:00
```

---

## 📈 Success Metrics (End of Week)

### Baseline (Nov 2, Pre-Work)
- Commissions created: 7
- Eligible contributions: 7
- Investors with party links: 14/41 (34%)
- Coverage gaps: Unknown

### Target (Nov 6, Post-Work)
- Commissions created: ≥20
- Eligible contributions: ≥50 (after DB-01 + IMP-01)
- Investors with party links: ≥35/41 (85%)
- Coverage gaps: Documented with clear resolution path
- CSV import: Fully functional preview/commit flow
- UI: Admin compute button working

### Definition of Done (Project-Level)
- ✅ All 98 contributions can compute commissions (0 blocked by missing data)
- ✅ CSV imports work via `npm run import:all --mode preview`
- ✅ Admin can click "Compute Eligible" and see new commissions appear
- ✅ Commission detail page shows which agreement was applied
- ✅ Verification scripts return 0 critical gaps
- ✅ Security model enforced (service key ≠ admin powers)

---

## 🔗 Quick Links

- **UI:** http://localhost:8080
- **API:** https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1
- **Dashboard:** https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys
- **Handoff Package:** `HANDOFF_PACKAGE.md`
- **Next Steps Spec:** `NEXT_STEPS.md`
- **Verification Scripts:** `scripts/verify_*.sql`

---

**Last Updated:** 2025-11-02 10:00 Asia/Jerusalem
**Status:** Ready to execute
