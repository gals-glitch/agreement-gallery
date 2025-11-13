# Agreement Snapshot Integrity - Quick Start Guide
## v1.8.0 - Investor Fee Workflow E2E

**Status:** ✅ Complete | **Date:** 2025-10-21

---

## TL;DR - Run This Now

```sql
-- In Supabase SQL Editor, run this query:
-- File: docs/AGR_HEALTH_CHECK_QUERIES.sql → QUERY 6 (Combined Health Check Summary)

-- Expected output:
-- | issue_type        | count | affected_agreement_ids |
-- |-------------------|-------|------------------------|
-- | (empty result)    |       |                        |

-- If count > 0 for any issue → See "Fix Issues" section below
```

✅ **PASS**: No rows returned → All APPROVED agreements have valid snapshots
❌ **FAIL**: Rows returned → Use fix scripts in `docs/AGR_FIX_SCRIPTS.sql`

---

## Context (What You're Verifying)

The charge computation engine relies on `agreement_rate_snapshots` to calculate referral fees:

```
Contribution ($50,000)
    ↓
Agreement Snapshot Lookup (investor_id → approved agreement)
    ↓
Snapshot Data: { upfront_bps: 100, deferred_bps: 0, vat_rate: 20.0 }
    ↓
Charge Calculation:
  - Base Fee: $50,000 × 1% = $500
  - VAT: $500 × 20% = $100
  - Total: $600
```

**If snapshot is missing or incomplete → Charge computation fails**

---

## Critical Understanding

### What is a "Snapshot"?

- **Table:** `agreement_rate_snapshots`
- **Created:** Automatically when `agreements.status` → `'APPROVED'` (via trigger)
- **Contains:** Immutable pricing configuration frozen at approval time
  - `resolved_upfront_bps` (e.g., 100 = 1%)
  - `resolved_deferred_bps` (e.g., 0 = 0%)
  - `vat_rate_percent` (e.g., 20.00 = 20%)
  - `vat_policy` (EXCLUSIVE | INCLUSIVE | EXEMPT)

### Where is `snapshot_json`?

**IMPORTANT:** There is NO `agreements.snapshot_json` field!

- `agreement_rate_snapshots` table stores snapshots (separate table, not JSON field)
- `charges.snapshot_json` stores a copy of pricing data at charge computation time
- Health checks verify `agreement_rate_snapshots` table integrity

---

## Files Delivered

| File | Purpose | When to Use |
|------|---------|-------------|
| `AGR_HEALTH_CHECK_QUERIES.sql` | 7 diagnostic queries to detect issues | Before every deployment, weekly audits |
| `AGR_FIX_SCRIPTS.sql` | 6 repair scripts for common issues | When health check finds problems |
| `AGR_SNAPSHOT_INTEGRITY_REPORT.md` | Comprehensive guide (this doc) | Deep dive, troubleshooting, reference |
| `AGR_VERIFICATION_SUMMARY.md` | Quick start (you're reading it) | Daily use, onboarding |

---

## 3-Minute Health Check Procedure

### Step 1: Run Combined Health Check (30 seconds)

```sql
-- Copy QUERY 6 from docs/AGR_HEALTH_CHECK_QUERIES.sql
-- Paste into Supabase SQL Editor → Run
```

**Interpret Results:**

| Output | Meaning | Action |
|--------|---------|--------|
| No rows | ✅ All snapshots valid | DONE - system healthy |
| `MISSING_SNAPSHOT` rows | ❌ CRITICAL | → Step 2 (Fix Script 1) |
| `MISSING_*_BPS` rows | ❌ CRITICAL | → Step 2 (Fix Script 2) |
| `INVALID_*` rows | ❌ HIGH | → Step 2 (Fix Script 3/5) |
| `MISSING_VAT_RATE` rows | ⚠️ WARNING | → Step 3 (Review case-by-case) |
| `OVERLAPPING_WINDOWS` rows | ⚠️ WARNING | → Step 3 (Review case-by-case) |

### Step 2: Fix Critical Issues (2 minutes per issue)

**Example: Fix Agreement 42 with MISSING_SNAPSHOT**

```sql
-- 1. Preview (from AGR_FIX_SCRIPTS.sql → FIX SCRIPT 1, Step 1)
SELECT ... WHERE a.id = 42;
-- Review output: Verify pricing looks correct

-- 2. Execute fix (from FIX SCRIPT 1, Step 2)
INSERT INTO agreement_rate_snapshots (...)
SELECT ... WHERE a.id = 42;

-- 3. Verify (from FIX SCRIPT 1, Step 3)
SELECT * FROM agreement_rate_snapshots WHERE agreement_id = 42;
-- Expected: 1 row with upfront_bps, deferred_bps, vat_rate populated
```

**Fix Script Quick Reference:**

| Issue Type | Fix Script | Action |
|------------|------------|--------|
| `MISSING_SNAPSHOT` | FIX SCRIPT 1 | Create missing snapshot |
| `MISSING_UPFRONT_BPS` | FIX SCRIPT 2 | Update incomplete snapshot |
| `MISSING_DEFERRED_BPS` | FIX SCRIPT 2 | Update incomplete snapshot |
| `INVALID_*_BPS` | FIX SCRIPT 3 | Correct negative values |
| `INVALID_VAT_RATE_*` | FIX SCRIPT 5 | Clamp to 0-100 range |
| `MISSING_VAT_RATE` | FIX SCRIPT 4 | Add VAT rate (or set to 0 if exempt) |

### Step 3: Review Warnings (1 minute)

**MISSING_VAT_RATE:**

- **UK/EU parties (GB, DE, FR):** Should have VAT rate → use Fix Script 4
- **US parties:** VAT-exempt → NULL acceptable (or set to 0.00)

**OVERLAPPING_WINDOWS:**

- **Different scopes (FUND vs DEAL):** Acceptable - deal-level takes precedence
- **Same scope, same party:** May need business rule clarification

---

## Common Scenarios (Fast Troubleshooting)

### Scenario: "No approved agreement found" error

**Error:**

```json
{"error": {"code": "COMPUTE_ERROR", "message": "No approved agreement found for this contribution"}}
```

**Diagnosis (30 seconds):**

```sql
-- Find contribution details
SELECT investor_id, fund_id, deal_id FROM contributions WHERE id = <contribution_id>;

-- Check for approved agreements
SELECT a.id, a.status, ars.id AS snapshot_id
FROM agreements a
LEFT JOIN agreement_rate_snapshots ars ON a.id = ars.agreement_id
WHERE a.party_id = <investor_id>
  AND (a.fund_id = <fund_id> OR a.deal_id = <deal_id>);
```

**Fixes:**

| Finding | Action |
|---------|--------|
| No agreement exists | Create and approve agreement |
| Agreement exists, status ≠ APPROVED | Approve agreement (snapshot auto-created) |
| Agreement APPROVED, snapshot_id = NULL | Use FIX SCRIPT 1 (Create Missing Snapshot) |

### Scenario: Charge computed with $0.00 (should be non-zero)

**Diagnosis (30 seconds):**

```sql
-- Check charge snapshot
SELECT snapshot_json->'computed_rules'->>'is_gp' AS is_gp,
       snapshot_json->'computed_rules'->>'rate_pct' AS rate_pct
FROM charges WHERE id = <charge_id>;
```

**Fixes:**

| Finding | Action |
|---------|--------|
| `is_gp = true` | Verify investor should be GP - check `investors.is_gp` |
| `rate_pct = 0` | Check agreement BPS values (may be correct if 0% fee) |

### Scenario: Health check fails after migration

**Diagnosis (1 minute):**

```sql
-- Verify trigger exists
SELECT tgname, tgenabled
FROM pg_trigger
WHERE tgname = 'snapshot_rates_on_approval';

-- Expected: 1 row, tgenabled = 'O'
```

**Fixes:**

| Finding | Action |
|---------|--------|
| No rows | Re-run migration `20251019100003_vat_and_snapshots.sql` |
| `tgenabled ≠ 'O'` | Enable trigger: `ALTER TABLE agreements ENABLE TRIGGER snapshot_rates_on_approval;` |
| Trigger exists but snapshots missing | Batch create using FIX SCRIPT 1 (remove `<agreement_id>` filter) |

---

## Deployment Checklist

### Before Import/Deployment

- [ ] Run health check QUERY 6
- [ ] Verify count = 0 for critical issues
- [ ] Document results in deployment notes

### After Import/Deployment

- [ ] Re-run health check QUERY 6
- [ ] Compare before/after counts
- [ ] Test charge computation for new agreements
- [ ] Verify API call succeeds: `POST /charges/compute`

---

## Emergency Contacts

If health check fails and fix scripts don't resolve:

1. **Check database logs** (Supabase Dashboard → Database → Logs)
2. **Review migration history** (Database → Migrations)
3. **Verify trigger function** (see "Scenario: Health check fails after migration")
4. **Escalate to database team** if trigger corruption suspected

---

## Key Takeaways

✅ **DO:**
- Run health check before every deployment
- Fix critical issues immediately (< 24h)
- Review warnings case-by-case
- Document fix actions in deployment notes

❌ **DON'T:**
- Deploy charges if critical issues exist
- Manually update snapshots without verification
- Delete snapshots (they're immutable for audit trail)
- Skip health checks (prevents revenue loss)

---

## Next Steps

1. **Bookmark this file** for quick reference
2. **Run QUERY 6 now** to establish baseline
3. **Schedule weekly health checks** (Monday mornings)
4. **Read full report** (`AGR_SNAPSHOT_INTEGRITY_REPORT.md`) for deep dive

**Health check takes 3 minutes. Revenue loss from missing snapshots takes 3 days to fix.**

Run the health check. 🚀
