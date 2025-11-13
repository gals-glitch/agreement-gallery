# Post-MVP Development Plan

## 🎉 MVP Status: COMPLETE

**Achieved:**
- ✅ 7 commissions computed successfully ($11,620 total)
- ✅ Workflow tested: draft → pending → approved → paid
- ✅ Service role authentication working
- ✅ UI running on http://localhost:8080
- ✅ Tiered pricing + VAT calculation verified

**Current Blockers:**
- 27 investors missing `introduced_by_party_id` (blocked from computing commissions)
- 93 contributions failed due to missing party links or agreements

---

## Remaining Work (4 Tickets)

### DB-01: Migration for `introduced_by_party_id` + Index + Backfill

**Owner:** Backend
**Files:** `supabase/migrations/20251102_add_investor_party_fk.sql`, optional `party_aliases` seed data

**Goal:** Make the data model first-class (no reliance on notes), and backfill what we can.

**Deliverables:**
1. Migration file (see `supabase/migrations/20251102_add_investor_party_fk.sql`)
2. Index on `investors.introduced_by_party_id`
3. Regex-based backfill from `investors.notes` pattern: "Introduced by: <party name>"
4. Optional `party_aliases` table for fuzzy matching

**Acceptance Criteria:**
- Column exists + indexed
- Backfill sets links for any investor whose notes include a known party or alias
- Remaining nulls are listed by verification query
- Team can add rows to `party_aliases` and re-run UPDATEs if needed

---

### IMP-01: Imports API with Staging + Preview/Commit

**Owner:** Backend
**Files:** `supabase/functions/api-v1/imports.ts`, staging tables migration

**Goal:** Stop pasting SQL; make CSV loads repeatable & safe.

**Deliverables:**

**1. Staging tables & metadata:**
- `stg_parties`, `stg_investors`, `stg_agreements`, `stg_contributions`
- `import_runs(id, kind, mode, created_by, created_at, stats jsonb)`

**2. API Endpoints (service_role only):**
```
POST /import/:entity?mode=preview|commit
```
Where `:entity` ∈ {parties, investors, agreements, contributions}

**Body:** Array of rows (parsed CSV) or `{ rows: [...] }`

**Preview mode:**
- Validates, fuzzy-matches names
- Returns stats: `{insert: n, update: m, skip: k, errors:[...], matches:{exact, fuzzy}}`
- **Never mutates base tables**

**Commit mode:**
- Same validation, then upserts into base tables
- Logs `import_runs` with final stats

**3. Matching rules (server-side):**
- **Deals:** Exact on name or prefix (`LIKE '<csv_name>%'`)
- **Parties:** Exact on name, else join via `party_aliases`
- **Investors:** Exact on name; if missing, create investor (notes include `source=import:YYYY-MM-DD`)
- **Agreements:** Upsert by `(party_id, deal_id, effective_from, kind)`; set `pricing_mode='CUSTOM'`; snapshot from payload; enforce no date overlaps (pre-check)
- **Contributions:** Require (investor, deal) to resolve; create investor if missing; currency default USD unless given

**Acceptance Criteria:**
- Preview never mutates base tables and returns counts
- Commit writes rows; a run appears in `import_runs` with final stats
- Bad rows are rejected with clear reasons (e.g., "deal not resolved")

---

### IMP-02: CLI Wiring - `npm run import:all`

**Owner:** Backend
**Files:** `scripts/importAll.ts`, `package.json`

**Goal:** One command to import the four CSVs in order.

**Usage:**
```bash
SUPABASE_URL=... \
SUPABASE_SERVICE_ROLE_KEY=... \
npm run import:all -- \
  --dir "C:\Users\GalSamionov\Downloads" \
  --mode preview   # or commit
```

**Implementation:**
1. Read CSVs in order: `01_parties.csv` → `02_investors.csv` → `03_agreements.csv` → `04_contributions.csv`
2. POST each to `/import/<entity>?mode=${mode}` with `apikey` + `Authorization: Bearer` = service role key
3. Pretty-print stats; non-zero errors → `exit(1)`

**Acceptance Criteria:**
- Running with `preview` shows a summary and zero DB mutations
- Running with `commit` loads and returns green stats
- Re-running is idempotent

---

### UI-01: Admin "Compute Eligible" Button + Show Applied Agreement

**Owner:** Frontend
**Files:** `src/pages/Commissions.tsx`, `src/pages/CommissionDetail.tsx`

**Goal:** One-click compute for ops; transparency of which agreement was used.

**Deliverables:**

**1. Commissions.tsx - Admin Toolbar:**
- Admin-only button: **"Compute Eligible"**
- On click: Call `POST /commissions/batch-compute` with:
  - All contributions where `investor.introduced_by_party_id IS NOT NULL`
  - AND there exists an approved agreement `(party_id, deal_id)`
  - AND no commission exists yet for that contribution
- Toast with `{computed, skipped_no_agreement, skipped_no_party, errors}`

**2. CommissionDetail.tsx - Agreement Card:**
- Display "Applied Agreement" card showing:
  - `rate_bps`, `vat_mode`, `vat_rate`
  - `effective_from..to`
  - `pricing_mode`
- Collapse/expand "Agreement snapshot (JSON)"

**Acceptance Criteria:**
- Button visible to Admin only; disabled while running
- After compute, commissions list populates without page reload
- Detail view shows the exact terms used for the calculation

---

## Optional: Coverage Booster (Server-Side)

**Feature flag:** `AUTO_SEED_MISSING_AGREEMENTS`

**Behavior:**
- When batch-compute finds `(party, deal)` missing agreement:
  - Create a draft agreement:
    - `pricing_mode='CUSTOM'`
    - `rate_bps=100`
    - `vat_mode='on_top'`
    - `vat_rate=0.17`
    - `effective_from = MIN(paid_in_date)`
  - Tag snapshot: `"auto_seeded": true`
  - Require Admin to approve seeded agreements before they're used

**Acceptance:**
- With flag ON, compute returns a `"seeded: N"` count
- UI shows a review queue for new draft agreements

---

## PR/Ownership Plan

| Ticket | Owner    | Files (main)                                                   |
|--------|----------|----------------------------------------------------------------|
| DB-01  | Backend  | `20251102_add_investor_party_fk.sql`, optional `party_aliases`|
| IMP-01 | Backend  | `api-v1/imports.ts`, staging DDL migration, `import_runs`     |
| IMP-02 | Backend  | `scripts/importAll.ts`, `package.json`                        |
| UI-01  | Frontend | `Commissions.tsx`, `CommissionDetail.tsx`, API client         |

---

## Verification Pack

After each merge, run:

### 1. Ready-to-compute contributions count
```sql
-- scripts/verify_ready_to_compute.sql
WITH eligible AS (
  SELECT c.id
  FROM contributions c
  JOIN investors i ON i.id = c.investor_id AND i.introduced_by_party_id IS NOT NULL
  JOIN agreements a ON a.party_id = i.introduced_by_party_id
                   AND a.deal_id = c.deal_id
                   AND a.status='APPROVED'
  LEFT JOIN commissions m ON m.contribution_id = c.id
  WHERE m.id IS NULL
)
SELECT COUNT(*) AS ready_to_compute FROM eligible;
```

### 2. Missing links still to backfill
```sql
-- scripts/verify_missing_links.sql
SELECT COUNT(*) AS investors_without_party
FROM investors
WHERE introduced_by_party_id IS NULL;
```

### 3. Coverage gaps (investors with party but no agreements for their deals)
```sql
-- scripts/verify_coverage_gaps.sql
SELECT
  i.name AS investor_name,
  p.name AS party_name,
  d.name AS deal_name,
  COUNT(*) AS contributions_blocked
FROM contributions c
JOIN investors i ON i.id = c.investor_id
JOIN parties p ON p.id = i.introduced_by_party_id
JOIN deals d ON d.id = c.deal_id
LEFT JOIN agreements a ON a.party_id = i.introduced_by_party_id
                      AND a.deal_id = c.deal_id
                      AND a.status = 'APPROVED'
LEFT JOIN commissions m ON m.contribution_id = c.id
WHERE a.id IS NULL
  AND m.id IS NULL
GROUP BY i.name, p.name, d.name
ORDER BY contributions_blocked DESC;
```

---

## Current MVP Metrics

- **Commissions created:** 7 (1 approved, 6 draft)
- **Total value:** $11,620 (base + VAT)
- **Coverage:** 14/41 investors have party links (34%)
- **Agreements:** 553 approved
- **UI:** http://localhost:8080
- **API:** https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1
