# Edge Cases & Known Constraints Reference

**Version:** 1.0
**Date:** 2025-10-16
**Purpose:** Quick reference for expected failure modes and edge cases

---

## 🚨 Critical Constraints (Will Fail)

### **1. FUND-Scoped Must Use TRACK Pricing**

**Rule:** `scope='FUND'` → `pricing_mode` MUST be `'TRACK'`

**Test (Should Fail):**
```sql
-- SQL (blocked by CHECK constraint)
INSERT INTO agreements(party_id, scope, fund_id, pricing_mode, effective_from)
VALUES (1, 'FUND', 1, 'CUSTOM', '2025-07-01');
-- Expected: CHECK constraint violation
```

```bash
# API (blocked by validation)
POST /agreements
{
  "party_id": 1,
  "scope": "FUND",
  "fund_id": 1,
  "pricing_mode": "CUSTOM"  # ← Will fail
}
# Expected: 400 - "FUND-scoped agreements must use TRACK pricing"
```

**Why:** FUND-level agreements standardize on Track-based pricing. Deal-level agreements can use CUSTOM for negotiated rates.

**Fix:** Use `"pricing_mode": "TRACK"` and specify `"selected_track": "A|B|C"`

---

### **2. TRACK Pricing Requires selected_track**

**Rule:** `pricing_mode='TRACK'` → `selected_track` MUST be set

**Test (Should Fail):**
```bash
POST /agreements
{
  "scope": "FUND",
  "fund_id": 1,
  "pricing_mode": "TRACK",
  "selected_track": null  # ← Will fail
}
# Expected: 400 - "TRACK pricing requires selected_track"
```

**Fix:** Add `"selected_track": "A"` (or B/C)

---

### **3. Contribution Scope XOR (MUST Have Deal OR Fund, Not Both)**

**Rule:** `deal_id` XOR `fund_id` (exactly one must be set)

**Test (Should Fail - BOTH):**
```sql
INSERT INTO contributions(investor_id, deal_id, fund_id, paid_in_date, amount)
VALUES (1, 10, 20, '2025-07-01', 100000);
-- Expected: CHECK constraint "contributions_scope_check" violation
```

**Test (Should Fail - NEITHER):**
```sql
INSERT INTO contributions(investor_id, deal_id, fund_id, paid_in_date, amount)
VALUES (1, NULL, NULL, '2025-07-01', 100000);
-- Expected: CHECK constraint violation
```

**Why:** Contribution must be scoped to either a specific Deal OR the Fund level, but never both.

**Fix:** Set exactly one:
```sql
-- Fund-level contribution
INSERT INTO contributions(investor_id, fund_id, paid_in_date, amount)
VALUES (1, 20, '2025-07-01', 100000);

-- Deal-level contribution
INSERT INTO contributions(investor_id, deal_id, paid_in_date, amount)
VALUES (1, 10, '2025-07-01', 100000);
```

---

### **4. Approved Agreements Are Immutable**

**Rule:** Cannot edit APPROVED agreements (except status→SUPERSEDED + effective_to)

**Test (Should Fail):**
```sql
-- Try to change pricing on APPROVED agreement
UPDATE agreements
SET selected_track = 'A'
WHERE id = 123 AND status = 'APPROVED';
-- Expected: Exception - "Approved agreements are immutable..."
```

**Allowed:**
```sql
-- Mark as SUPERSEDED (via amendment flow)
UPDATE agreements
SET status = 'SUPERSEDED', effective_to = '2025-12-31'
WHERE id = 123 AND status = 'APPROVED';
-- Expected: Success
```

**Why:** Snapshots are created on approval. Editing would break audit trail.

**Fix:** Use `/agreements/:id/amend` to create v2 Draft.

---

## ⚠️ Edge Cases to Monitor

### **5. Overlapping Effective Dates**

**Scenario:** Party has multiple APPROVED agreements for same scope/entity with overlapping dates.

**Example:**
```
Agreement 1: Party A + Fund VI, effective 2025-01-01 → 2025-12-31 (APPROVED)
Agreement 2: Party A + Fund VI, effective 2025-06-01 → 2026-12-31 (APPROVED)
```

**Expected Behavior:**
- Database allows this (no UNIQUE constraint on dates)
- Calculation engine should pick the most recent APPROVED agreement that covers the contribution date
- **Warning:** API should return 409 with clear message about overlap

**Test Query:**
```sql
-- Find overlapping agreements
SELECT a1.id AS agr1, a2.id AS agr2, a1.party_id, a1.fund_id,
       a1.effective_from AS a1_from, a1.effective_to AS a1_to,
       a2.effective_from AS a2_from, a2.effective_to AS a2_to
FROM agreements a1
JOIN agreements a2 ON a1.party_id = a2.party_id
  AND a1.scope = a2.scope
  AND COALESCE(a1.fund_id, 0) = COALESCE(a2.fund_id, 0)
  AND COALESCE(a1.deal_id, 0) = COALESCE(a2.deal_id, 0)
  AND a1.id < a2.id
WHERE a1.status = 'APPROVED' AND a2.status = 'APPROVED'
  AND a1.effective_from <= COALESCE(a2.effective_to, '9999-12-31')
  AND COALESCE(a1.effective_to, '9999-12-31') >= a2.effective_from;
```

**Recommendation:** Add application-level validation in `/agreements` POST/approve to warn on overlap.

---

### **6. Snapshot Resolution Failure**

**Scenario:** Approve agreement but custom_terms or fund_tracks data missing.

**Example:**
```sql
-- Create CUSTOM agreement without custom_terms
INSERT INTO agreements(party_id, scope, deal_id, pricing_mode, effective_from, status)
VALUES (1, 'DEAL', 10, 'CUSTOM', '2025-07-01', 'DRAFT');

-- Approve it
UPDATE agreements SET status = 'APPROVED' WHERE id = 999;
-- Expected: Trigger fails to create snapshot (no custom_terms row)
```

**Expected Behavior:**
- Trigger `snapshot_rates_on_approval()` should raise exception if resolution fails
- Status remains `AWAITING_APPROVAL` (transaction rolls back)

**Test:**
```bash
POST /agreements/:id/approve
# If custom_terms missing, expect 400/500 with trigger error
```

**Fix:** Ensure custom_terms inserted atomically with agreement in POST /agreements.

---

### **7. GP Exclusion Logic**

**Scenario:** Investor is GP (`is_gp=true`) and Deal excludes GPs (`exclude_gp_from_commission=true`).

**Expected Behavior:**
- Contribution is recorded normally
- Calculation engine MUST skip fee calculation for this contribution
- No entry in fee output CSV

**Test Query:**
```sql
-- Find GP contributions to GP-excluded deals
SELECT c.id, i.name AS investor, d.name AS deal,
       c.amount, i.is_gp, d.exclude_gp_from_commission
FROM contributions c
JOIN investors i ON i.id = c.investor_id
JOIN deals d ON d.id = c.deal_id
WHERE i.is_gp = true
  AND d.exclude_gp_from_commission = true;
```

**Verification:** These contributions should NOT appear in generated fee report.

---

### **8. Scoreboard Read-Only Fields**

**Scenario:** User tries to edit `equity_to_raise` or `raised_so_far` via API.

**Expected Behavior:**
- API ignores these fields in POST/PATCH requests
- Only `apply_scoreboard_metrics()` can update them

**Test:**
```bash
PATCH /deals/10
{
  "equity_to_raise": 999999  # ← Should be ignored
}
# Expected: 200, but equity_to_raise unchanged
```

**Verification:**
```sql
SELECT name, equity_to_raise, raised_so_far
FROM deals
WHERE id = 10;
-- Values should match scoreboard import, not API request
```

---

### **9. Amendment Effective Date Logic**

**Scenario:** Approve v2 amendment but forget to adjust v1 `effective_to`.

**Current Behavior:**
- Trigger allows marking v1 as SUPERSEDED
- v1 `effective_to` can be updated manually
- **No automatic date shortening**

**Recommendation:** Add application logic to:
1. When approving v2, update v1 `effective_to` to `v2.effective_from - 1 day`
2. Prevents gaps in coverage

**Example:**
```sql
-- Manual fix (should be automated in API)
UPDATE agreements
SET effective_to = (SELECT effective_from - INTERVAL '1 day' FROM agreements WHERE id = v2_id)
WHERE id = v1_id AND status = 'SUPERSEDED';
```

---

### **10. Missing Track Data**

**Scenario:** User selects Track B but fund_tracks table has no Track B for that fund.

**Expected Behavior:**
- Agreement creation succeeds (no FK constraint on selected_track)
- Approval FAILS when snapshot trigger tries to resolve rates

**Test:**
```sql
-- Delete Track B
DELETE FROM fund_tracks WHERE fund_id = 1 AND track_code = 'B';

-- Create agreement with Track B
INSERT INTO agreements(party_id, scope, fund_id, pricing_mode, selected_track, effective_from, status)
VALUES (1, 'FUND', 1, 'TRACK', 'B', '2025-07-01', 'DRAFT');

-- Try to approve
UPDATE agreements SET status = 'APPROVED' WHERE id = 999;
-- Expected: Exception from snapshot trigger - "Track B not found"
```

**Fix:** Ensure fund_tracks seeded for all funds (migration 07 does this for Fund VI).

---

## 📋 Quick Test Checklist

### **Smoke Test (5 minutes)**
- [ ] FUND + CUSTOM → 400
- [ ] TRACK without selected_track → 400
- [ ] Contribution with both deal_id and fund_id → 422
- [ ] Edit APPROVED agreement pricing → Exception
- [ ] Mark APPROVED as SUPERSEDED → Success

### **Workflow Test (10 minutes)**
- [ ] Create agreement → Submit → Approve → Verify snapshot
- [ ] Approve → Amend → Verify v1=SUPERSEDED, v2=DRAFT
- [ ] GP contribution to GP-excluded deal → Not in fee output

### **RBAC Test (5 minutes)**
- [ ] Non-manager tries approve → 403
- [ ] Manager approves → 200

---

## 🔧 Debugging Queries

### **Find Agreements Without Snapshots:**
```sql
SELECT a.id, a.status, a.created_at
FROM agreements a
LEFT JOIN agreement_rate_snapshots s ON s.agreement_id = a.id
WHERE a.status = 'APPROVED' AND s.id IS NULL;
```

### **Find Duplicate Active Agreements (Same Party + Scope):**
```sql
SELECT party_id, scope, fund_id, deal_id, COUNT(*) as count
FROM agreements
WHERE status IN ('APPROVED', 'AWAITING_APPROVAL')
GROUP BY party_id, scope, fund_id, deal_id
HAVING COUNT(*) > 1;
```

### **Find GP Contributions to GP-Excluded Deals:**
```sql
SELECT c.id, i.name, d.name, c.amount
FROM contributions c
JOIN investors i ON i.id = c.investor_id
JOIN deals d ON d.id = c.deal_id
WHERE i.is_gp = true AND d.exclude_gp_from_commission = true;
```

### **Find Contributions Without Valid Agreement:**
```sql
SELECT c.id, c.investor_id, c.deal_id, c.fund_id, c.paid_in_date
FROM contributions c
WHERE NOT EXISTS (
  SELECT 1 FROM agreements a
  WHERE a.status = 'APPROVED'
    AND a.party_id = (SELECT introduced_by_party_id FROM investor_agreement_links WHERE investor_id = c.investor_id LIMIT 1)
    AND (
      (a.scope = 'DEAL' AND a.deal_id = c.deal_id)
      OR (a.scope = 'FUND' AND a.fund_id = c.fund_id)
    )
    AND c.paid_in_date >= a.effective_from
    AND (a.effective_to IS NULL OR c.paid_in_date <= a.effective_to)
);
```

---

## 🎯 Error Message Catalog

| Code | Message | Cause | Fix |
|------|---------|-------|-----|
| 400 | "FUND-scoped agreements must use TRACK pricing" | scope=FUND + pricing_mode=CUSTOM | Change to TRACK |
| 400 | "TRACK pricing requires selected_track" | pricing_mode=TRACK + selected_track=null | Add selected_track |
| 400 | "Agreement not found or not in DRAFT status" | Submit non-DRAFT | Check status |
| 403 | "Unauthorized: requires manager or admin role" | Non-manager approving | Check RBAC |
| 404 | "Agreement not found or not approved" | Amend non-APPROVED | Check status |
| 422 | CHECK constraint "contributions_scope_check" | Both or neither deal_id/fund_id | Set exactly one |
| 500 | "Approved agreements are immutable..." | Edit APPROVED directly | Use /amend |

---

## 📞 When to Escalate

- **Overlapping agreements detected** → Product decision needed on precedence rules
- **Snapshot creation fails** → Check trigger logs, verify fund_tracks data
- **GP exclusion not working** → Verify calculation engine implementation
- **Performance degradation on `/agreements` list** → Add index on (party_id, status, effective_from)

---

_Last Updated: 2025-10-16_
_Version: 1.0_
