# DB-02: Party Alias Remediation (72 Blocked Contributions)

**Type**: Data Operations
**Priority**: High
**Estimated Effort**: 6 hours (3 hours analysis + 3 hours execution)
**Status**: Ready for Development

---

## Objective

Map the 72 Vantage-imported investors (currently without party links) to their introducing parties using automated fuzzy matching and manual review, enabling commission computation for their contributions.

---

## Background

**Current State:**
- 100 contributions processed in batch compute
- 28 successes (party-linked investors with agreements)
- 72 errors: "investor has no introduced_by_party_id"

**Root Cause:**
- Vantage API sync imported 973 investors without "Introduced by:" notes
- Gate A fuzzy matching only works on investors with notes containing party hints
- These 72 contributions represent potential additional commissions worth ~$7,000-$10,000

**Goal:**
- Identify introducing parties for unlinked investors
- Add mappings to `party_aliases` table
- Re-run Gate A backfill to link investors
- Re-run batch compute to generate commissions

---

## Acceptance Criteria

### Phase 1: Analysis & Discovery

- [ ] **Identify Blocked Investors**
  - Query all investors with contributions but no party link
  - Rank by total contribution value (prioritize high-value)
  - Export to CSV for manual review

- [ ] **Auto-Suggest Party Matches**
  - Run fuzzy matching on any text hints in investor names or notes
  - Generate suggestions with similarity scores (≥60%)
  - Export suggestions to CSV for validation

- [ ] **Estimate Impact**
  - Calculate total blocked contribution value
  - Estimate potential commission value (at 100 bps)
  - Report to stakeholders for prioritization

### Phase 2: Manual Review & Validation

- [ ] **Review Auto-Suggestions**
  - Finance/ops team reviews fuzzy match suggestions
  - Accepts or rejects each suggested party mapping
  - Documents any manual overrides or corrections

- [ ] **Research Unmatched Investors**
  - For investors with no auto-suggestions:
    - Check CRM records
    - Review email correspondence
    - Contact investor/deal managers
  - Document findings in spreadsheet

- [ ] **Create Alias Mapping**
  - Build final mapping: `investor_name → party_id`
  - Include confidence level (high/medium/low)
  - Get approval from finance lead

### Phase 3: Execution

- [ ] **Bulk Insert Aliases**
  - Insert validated mappings into `party_aliases` table
  - Use idempotent INSERT ON CONFLICT for safety

- [ ] **Backfill Party Links**
  - Re-run Gate A backfill query to populate `introduced_by_party_id`
  - Verify expected number of investors linked

- [ ] **Create Missing Agreements**
  - Identify new party-deal pairs needing agreements
  - Run COV-01 style seeder for default agreements (100 bps, 17% VAT)
  - Approve agreements

- [ ] **Recompute Commissions**
  - Run batch compute on newly-linked contributions
  - Verify new draft commissions created
  - Report final success count

### Phase 4: Verification & Documentation

- [ ] **Verify Coverage**
  - Run coverage query: should now be >95%
  - Compare before/after commission totals
  - Spot-check 5 random new commissions for accuracy

- [ ] **Document Mappings**
  - Save alias mappings to version-controlled CSV
  - Document any manual overrides or exceptions
  - Update party_aliases admin UI (future ticket)

- [ ] **Update Runbook**
  - Add "Party Alias Remediation" procedure to ops runbook
  - Include SQL scripts for future batches
  - Train finance team on validation process

---

## Implementation Guide

### Step 1: Run Analysis Queries

**Query Pack A: Blocked Investor Report**

```sql
-- Copy to clipboard and run in Supabase SQL Editor
-- A1) Top 50 blocked investors by contribution value
SELECT
  i.id AS investor_id,
  i.name AS investor_name,
  COUNT(c.id) AS contribution_count,
  SUM(c.amount) AS total_contribution_value,
  ROUND(SUM(c.amount) * 0.01, 2) AS potential_commission_100bps
FROM investors i
JOIN contributions c ON c.investor_id = i.id
WHERE i.introduced_by_party_id IS NULL
GROUP BY i.id, i.name
ORDER BY total_contribution_value DESC
LIMIT 50;

-- A2) Summary statistics
SELECT
  COUNT(DISTINCT i.id) AS blocked_investors,
  COUNT(c.id) AS blocked_contributions,
  SUM(c.amount) AS total_blocked_value,
  ROUND(SUM(c.amount) * 0.01, 2) AS potential_commissions_100bps,
  ROUND(AVG(c.amount), 2) AS avg_contribution_size
FROM investors i
JOIN contributions c ON c.investor_id = i.id
WHERE i.introduced_by_party_id IS NULL;

-- A3) Distribution by deal
SELECT
  d.name AS deal_name,
  COUNT(DISTINCT i.id) AS blocked_investors,
  COUNT(c.id) AS contributions,
  SUM(c.amount) AS total_value
FROM contributions c
JOIN investors i ON i.id = c.investor_id
JOIN deals d ON d.id = c.deal_id
WHERE i.introduced_by_party_id IS NULL
GROUP BY d.name
ORDER BY total_value DESC
LIMIT 20;
```

**Query Pack B: Auto-Suggested Matches**

```sql
-- B1) Fuzzy match on investor names
CREATE EXTENSION IF NOT EXISTS pg_trgm;

WITH candidates AS (
  SELECT i.id, i.name, i.notes
  FROM investors i
  WHERE i.introduced_by_party_id IS NULL
),
scored AS (
  SELECT
    c.id AS investor_id,
    c.name AS investor_name,
    p.id AS suggested_party_id,
    p.name AS suggested_party_name,
    GREATEST(
      similarity(c.name, p.name),
      similarity(
        regexp_replace(c.name, '[^A-Za-zא-ת ]', '', 'g'),
        regexp_replace(p.name, '[^A-Za-zא-ת ]', '', 'g')
      )
    ) AS similarity_score
  FROM candidates c
  CROSS JOIN parties p
)
SELECT
  investor_id,
  investor_name,
  suggested_party_id,
  suggested_party_name,
  ROUND(similarity_score::numeric, 2) AS score
FROM (
  SELECT DISTINCT ON (investor_id) *
  FROM scored
  ORDER BY investor_id, similarity_score DESC
) best
WHERE similarity_score >= 0.60
ORDER BY similarity_score DESC, investor_id;

-- B2) Extract hints from notes (if any exist)
SELECT
  i.id AS investor_id,
  i.name AS investor_name,
  trim(substring(i.notes FROM 'Introduced by:\s*([^;]+)')) AS extracted_hint,
  i.notes
FROM investors i
WHERE i.introduced_by_party_id IS NULL
  AND i.notes LIKE '%Introduced by:%'
ORDER BY i.name;
```

**Export Results:**
- Copy query results to Excel/CSV
- Share with finance team for review
- Track review status in spreadsheet

---

### Step 2: Manual Review Process

**Spreadsheet Template:**

| investor_id | investor_name | suggested_party_id | suggested_party_name | score | status | validated_party_id | notes |
|-------------|---------------|-------------------|---------------------|-------|--------|-------------------|-------|
| 154 | 310 Tyson Drive GP LLC | 182 | Avi Fried | 0.65 | REVIEW | | |
| 155 | Aaron Shenhar | NULL | | 0.00 | RESEARCH | | Check CRM |

**Status Values:**
- `ACCEPTED` - Auto-suggestion approved as-is
- `OVERRIDE` - Different party manually selected
- `RESEARCH` - Needs additional investigation
- `UNKNOWN` - Cannot determine party (leave unlinked)

**Review Guidelines:**
1. Scores ≥ 0.80: High confidence, likely accept
2. Scores 0.60-0.79: Medium confidence, verify with deal manager
3. No suggestion: Research CRM, emails, or mark as UNKNOWN

---

### Step 3: Bulk Insert Validated Aliases

**After completing review spreadsheet:**

```sql
-- Insert validated party aliases (idempotent)
-- Replace values with actual investor names and party IDs from spreadsheet

INSERT INTO party_aliases (alias, party_id)
VALUES
  ('310 Tyson Drive GP LLC', 182),  -- Investor 154 → Avi Fried
  ('Aaron Shenhar', 187),           -- Investor 155 → Capital Link (manual)
  ('Abraham Fuchs', 182),           -- Investor 156 → Avi Fried (research found)
  -- ... add all validated mappings here
  ('Investor Name', party_id)
ON CONFLICT (alias) DO UPDATE
SET party_id = EXCLUDED.party_id;

-- Verify insertions
SELECT alias, party_id, p.name
FROM party_aliases pa
JOIN parties p ON p.id = pa.party_id
WHERE pa.alias IN ('310 Tyson Drive GP LLC', 'Aaron Shenhar', 'Abraham Fuchs')
ORDER BY alias;
```

**Alternatively, use CSV import:**

```sql
-- If using CSV file (recommended for large batches)
COPY party_aliases (alias, party_id)
FROM '/path/to/validated_aliases.csv'
WITH (FORMAT csv, HEADER true)
ON CONFLICT (alias) DO UPDATE SET party_id = EXCLUDED.party_id;
```

---

### Step 4: Backfill Party Links

```sql
-- Re-run Gate A backfill (same query from gateA_close_gaps.sql)

UPDATE investors i
SET introduced_by_party_id = pa.party_id
FROM party_aliases pa
WHERE i.introduced_by_party_id IS NULL
  AND pa.alias = i.name;  -- Match on investor name directly

-- Report results
SELECT
  'Before Backfill' AS status,
  COUNT(*) AS investors_without_party
FROM investors
WHERE introduced_by_party_id IS NULL;

-- After running UPDATE, check again
SELECT
  'After Backfill' AS status,
  COUNT(*) AS investors_without_party
FROM investors
WHERE introduced_by_party_id IS NULL;

-- Should see reduction equal to number of validated aliases
```

---

### Step 5: Create Agreements for New Party-Deal Pairs

```sql
-- Find new party-deal pairs that need agreements
WITH newly_linked AS (
  SELECT DISTINCT
    i.introduced_by_party_id AS party_id,
    c.deal_id
  FROM contributions c
  JOIN investors i ON i.id = c.investor_id
  WHERE i.introduced_by_party_id IS NOT NULL
    AND NOT EXISTS (
      SELECT 1 FROM agreements a
      WHERE a.party_id = i.introduced_by_party_id
        AND a.deal_id = c.deal_id
        AND a.kind = 'distributor_commission'
        AND a.status = 'APPROVED'
    )
)
INSERT INTO agreements (
  party_id,
  scope,
  deal_id,
  kind,
  pricing_mode,
  status,
  effective_from,
  effective_to,
  snapshot_json
)
SELECT
  nl.party_id,
  'DEAL',
  nl.deal_id,
  'distributor_commission',
  'CUSTOM',
  'DRAFT',
  (SELECT MIN(paid_in_date) FROM contributions c
   JOIN investors i ON i.id = c.investor_id
   WHERE i.introduced_by_party_id = nl.party_id AND c.deal_id = nl.deal_id),
  NULL,
  jsonb_build_object(
    'terms', jsonb_build_array(
      jsonb_build_object(
        'rate_bps', 100,
        'from', (SELECT MIN(paid_in_date)::text FROM contributions c
                 JOIN investors i ON i.id = c.investor_id
                 WHERE i.introduced_by_party_id = nl.party_id AND c.deal_id = nl.deal_id),
        'to', null,
        'vat_mode', 'on_top',
        'vat_rate', 0.17
      )
    ),
    'auto_seeded', true,
    'seeded_at', NOW()::text,
    'source', 'DB-02 remediation'
  )
FROM newly_linked nl;

-- Add custom terms
INSERT INTO agreement_custom_terms (agreement_id, upfront_bps, deferred_bps)
SELECT a.id, 100, 0
FROM agreements a
WHERE a.snapshot_json->>'source' = 'DB-02 remediation'
  AND NOT EXISTS (
    SELECT 1 FROM agreement_custom_terms act WHERE act.agreement_id = a.id
  );

-- Approve new agreements
UPDATE agreements
SET status = 'APPROVED'
WHERE snapshot_json->>'source' = 'DB-02 remediation'
  AND status = 'DRAFT';

-- Report
SELECT COUNT(*) AS new_agreements_created
FROM agreements
WHERE snapshot_json->>'source' = 'DB-02 remediation';
```

---

### Step 6: Recompute Commissions

```powershell
# Run batch compute again
.\CMP_01_simple.ps1

# Or via SQL (get eligible contribution IDs first)
# Then call API endpoint with the IDs
```

---

### Step 7: Verification

```sql
-- Verify coverage improvement
WITH before AS (
  SELECT 28 AS success_count, 72 AS error_count  -- Initial results
),
after AS (
  SELECT
    COUNT(*) FILTER (WHERE i.introduced_by_party_id IS NOT NULL) AS success_count,
    COUNT(*) FILTER (WHERE i.introduced_by_party_id IS NULL) AS error_count
  FROM contributions c
  JOIN investors i ON i.id = c.investor_id
)
SELECT
  b.success_count AS before_success,
  a.success_count AS after_success,
  (a.success_count - b.success_count) AS improvement,
  b.error_count AS before_errors,
  a.error_count AS after_errors,
  (b.error_count - a.error_count) AS errors_resolved,
  ROUND(100.0 * a.success_count / (a.success_count + a.error_count), 1) AS coverage_pct
FROM before b, after a;

-- Spot-check new commissions
SELECT
  c.id,
  i.name AS investor,
  p.name AS party,
  d.name AS deal,
  c.total_amount,
  c.status
FROM commissions c
JOIN investors i ON i.id = c.investor_id
JOIN parties p ON p.id = c.party_id
JOIN deals d ON d.id = c.deal_id
WHERE c.created_at >= NOW() - INTERVAL '1 hour'
ORDER BY c.created_at DESC
LIMIT 10;
```

---

## Testing Checklist

### Pre-Execution Tests

- [ ] **Dry Run on Staging**
  - Run all queries on staging database first
  - Verify no production data corruption risk
  - Test rollback procedure (DELETE from party_aliases WHERE...)

- [ ] **Backup Verification**
  - Ensure database backup is recent (<24 hours)
  - Verify backup restoration process tested
  - Document rollback SQL for each step

### Post-Execution Tests

- [ ] **Data Integrity**
  - All party_aliases reference valid party_id (no orphans)
  - All introduced_by_party_id reference valid party_id
  - No duplicate aliases created

- [ ] **Functional Testing**
  - Batch compute runs successfully on newly-linked investors
  - New commissions have correct rates (100 bps)
  - VAT calculated correctly (17% on top)

- [ ] **Regression Testing**
  - Original 28 commissions unchanged
  - Existing party links not affected
  - Gate A fuzzy matching still works for new investors

---

## Edge Cases

1. **Investor Name Conflicts**
   - Two investors with same name → different parties
   - Solution: Use investor_id as tie-breaker, add suffix to alias

2. **Party Mergers/Renames**
   - Party was renamed after contribution
   - Solution: Add historical aliases for old party names

3. **Multi-Party Introductions**
   - Investor introduced by multiple parties over time
   - Solution: Use earliest contribution date to determine primary party

4. **Circular References**
   - Alias points to party that references same alias
   - Solution: Validate no cycles before insert

---

## Rollback Plan

**If issues discovered after execution:**

```sql
-- Step 1: Remove newly created commissions
DELETE FROM commissions
WHERE created_at >= '[execution_timestamp]';

-- Step 2: Unapprove/delete new agreements
UPDATE agreements
SET status = 'SUPERSEDED'
WHERE snapshot_json->>'source' = 'DB-02 remediation';

-- Step 3: Remove backfilled party links
UPDATE investors
SET introduced_by_party_id = NULL
WHERE name IN (
  SELECT alias FROM party_aliases
  WHERE created_at >= '[execution_timestamp]'
);

-- Step 4: Remove new aliases
DELETE FROM party_aliases
WHERE created_at >= '[execution_timestamp]';

-- Step 5: Verify rollback
SELECT
  (SELECT COUNT(*) FROM party_aliases) AS alias_count,
  (SELECT COUNT(*) FROM investors WHERE introduced_by_party_id IS NOT NULL) AS linked_investors,
  (SELECT COUNT(*) FROM commissions) AS commission_count;
-- Should match pre-execution counts
```

---

## Success Metrics

**Target Outcomes:**
- ✅ Coverage: ≥95% of contributions linked to parties (up from 28%)
- ✅ Commissions: ≥95 total (up from 30)
- ✅ Value: ≥$140,000 total commission value (up from $42,436)
- ✅ Accuracy: <2% error rate in party mappings

**Measurement:**
- Before/after comparison dashboard
- Finance team review of sample commissions
- User acceptance testing of commission approval flow

---

## Timeline

**Phase 1 (Analysis)**: 3 hours
- Hour 1: Run queries, export data
- Hour 2: Finance team review meeting
- Hour 3: Document decisions

**Phase 2 (Execution)**: 2 hours
- Hour 1: Insert aliases, backfill links
- Hour 2: Create agreements, recompute

**Phase 3 (Verification)**: 1 hour
- Verify metrics, spot-check commissions
- Sign-off from finance lead

**Total**: ~6 hours (can be split across 2 days)

---

## Related Tickets

- **GATE-A**: Party linkage fuzzy matching (foundation)
- **COV-01**: Default agreement seeder (pattern to reuse)
- **UI-01**: Compute eligible button (will trigger recompute)
- **UI-03**: Party aliases admin UI (future: make this self-service)

---

## Definition of Done

- [ ] Analysis queries executed, results reviewed
- [ ] Finance team validated all party mappings
- [ ] Aliases inserted into party_aliases table
- [ ] Party links backfilled (introduced_by_party_id populated)
- [ ] New agreements created and approved
- [ ] Batch compute re-run successfully
- [ ] Coverage metrics achieved (≥95%)
- [ ] Spot-checks passed (10 random commissions verified)
- [ ] Documentation updated (runbook, alias CSV)
- [ ] Finance team sign-off obtained

---

**Created**: 2025-11-09
**Last Updated**: 2025-11-09
**Assigned To**: TBD
**Sprint**: Current Sprint (High Priority)
**Dependencies**: None (can start immediately)
