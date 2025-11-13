# Investor Deal Counts Initialization - README

**Script:** `initialize_investor_deal_counts.sql`
**Schema Spec:** `docs/INVESTOR_DEAL_PARTICIPATIONS_SCHEMA.md`
**Version:** 1.0
**Date:** 2025-10-26

---

## Overview

This package provides tools to initialize and maintain investor deal participation history from historical transaction data. The participation tracking enables tiered commission calculations based on whether an investor is making their 1st, 2nd, 3rd, or nth investment.

### Business Value

- **Automated Sequencing:** Automatically determines deal order for each investor
- **Commission Tiers:** Enables different rates for first-time vs. repeat investors
- **Historical Analysis:** Provides insights into investor retention and behavior
- **Data Integrity:** Comprehensive verification ensures accurate calculations

---

## Components

### 1. Schema Specification
- **File:** `docs/INVESTOR_DEAL_PARTICIPATIONS_SCHEMA.md`
- **Purpose:** Complete technical specification for the `investor_deal_participations` table
- **Audience:** Schema agent, database administrators, developers
- **Contents:**
  - Table schema with all columns, constraints, and indexes
  - RLS policies for access control
  - Usage examples and query patterns
  - Performance considerations
  - Migration template

### 2. Initialization Script
- **File:** `scripts/initialize_investor_deal_counts.sql`
- **Purpose:** Analyze transactions and populate participation history
- **Type:** Multi-section SQL script (analysis + population + verification)
- **Execution:** Run sequentially, section by section

---

## Prerequisites

Before running the initialization script, ensure:

1. ✅ **Database Schema Ready**
   - `investors` table exists and is populated
   - `deals` table exists and is populated
   - `funds` table exists and is populated
   - `transactions` table exists with historical data
   - `investor_deal_participations` table has been created (via migration)

2. ✅ **Data Quality Validated**
   - All transactions have valid `investor_id` references
   - All transactions have either `deal_id` OR `fund_id` (XOR)
   - Transaction dates are accurate and complete
   - Transaction type is set correctly ('CONTRIBUTION' vs 'REPURCHASE')

3. ✅ **Access Permissions**
   - User has SELECT access to `investors`, `deals`, `funds`, `transactions`
   - User has INSERT access to `investor_deal_participations`
   - User has admin or finance role (for RLS policies)

---

## Execution Workflow

### Step 1: Pre-Execution Analysis (30-60 minutes)

Run **Sections 1-3** of the initialization script to analyze existing data:

```sql
-- Run these sections in your SQL client:
-- Section 1: Data Discovery & Validation
-- Section 2: Investor-Deal Participation Analysis
-- Section 3: Chronological Sequence Assignment
```

**What to Review:**

1. **Transaction Overview (Query 1.1)**
   - Verify expected number of transactions
   - Check date range makes sense
   - Confirm contribution vs. repurchase split

2. **Investor Count (Query 1.2)**
   - Verify ~110 unique investors (as stated)
   - Identify investors without transactions (if any)

3. **Participation Distribution (Query 2.2)**
   - Review how many deals per investor
   - Identify outliers (very few or very many deals)

4. **Sequence Preview (Query 3.1)**
   - Verify sequences look correct (1, 2, 3, ...)
   - Check dates are in chronological order
   - Review tie-breaking logic for same-day transactions

**Red Flags to Watch For:**

- ❌ Investor count significantly different from 110
- ❌ Transactions with NULL investor_id
- ❌ Transactions missing both deal_id and fund_id
- ❌ Sequence numbers that skip or have gaps
- ❌ Dates out of chronological order
- ❌ Unexpectedly high repurchase count

### Step 2: Create Target Table (5 minutes)

Coordinate with the schema agent to create the `investor_deal_participations` table:

```sql
-- The schema agent should run the migration from:
-- docs/INVESTOR_DEAL_PARTICIPATIONS_SCHEMA.md (Migration File Template section)
```

Verify the table was created:

```sql
SELECT
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'investor_deal_participations'
ORDER BY ordinal_position;
```

Expected columns:
- `id` (bigint, auto-increment)
- `investor_id` (bigint, not null)
- `deal_id` (bigint, nullable)
- `fund_id` (bigint, nullable)
- `first_participation_date` (date, not null)
- `participation_sequence` (integer, not null)
- `created_at` (timestamp, not null)
- `updated_at` (timestamp, not null)

### Step 3: Execute INSERT (5-10 minutes)

**IMPORTANT:** This step modifies the database. Ensure you have:
- Reviewed all analysis queries
- Validated the preview data looks correct
- Created a backup (if in production)
- Confirmed with stakeholders

Uncomment and execute the INSERT statement in **Section 4**:

```sql
-- 1. Clear existing data (if re-running)
TRUNCATE TABLE investor_deal_participations RESTART IDENTITY CASCADE;

-- 2. Execute the INSERT
-- (Uncomment the INSERT block in Section 4 of the script)
```

Expected results:
- INSERT should complete in < 1 second (small dataset)
- Number of rows inserted should match unique investor-deal combinations
- No errors or constraint violations

### Step 4: Verification (15-30 minutes)

Run **Section 5** verification queries:

```sql
-- Run all queries in Section 5: Verification Queries
```

**Critical Checks:**

1. **Participation Count Verification (Query 5.1)**
   - ✅ PASS: Counts from transactions match counts in participations table
   - ❌ FAIL: Investigate missing or extra records

2. **Sequence Continuity Check (Query 5.2)**
   - ✅ PASS: "All sequences are continuous"
   - ❌ FAIL: Review gaps, may indicate logic error

3. **First Participation Check (Query 5.3)**
   - ✅ PASS: "All investors start at sequence 1"
   - ❌ FAIL: Fix data or INSERT logic

4. **Duplicate Check (Query 5.4)**
   - ✅ PASS: "No duplicates found"
   - ❌ FAIL: Investigate duplicate investor-deal pairs

5. **Chronological Order Check (Query 5.5)**
   - ✅ PASS: "All dates in chronological order"
   - ❌ FAIL: Review out-of-order dates

**If ANY verification fails:**
1. STOP immediately
2. Review the failing query output for details
3. Investigate root cause (data issue vs. logic issue)
4. DO NOT proceed until all checks pass
5. If needed, TRUNCATE and re-run INSERT after fixing

### Step 5: Review Summary Report (10-15 minutes)

Run **Section 6** summary queries:

```sql
-- Run all queries in Section 6: Summary Report
```

**Business Insights to Share:**

1. **Overall Summary (Query 6.1)**
   - Total investors and participations
   - Average deals per investor
   - Date range of participations

2. **Participation Distribution (Query 6.2)**
   - How many first-time investors?
   - How many repeat investors?
   - Distribution across deal counts

3. **Top Investors (Query 6.3)**
   - Who are the most active investors?
   - Investment period and frequency

4. **Monthly Trends (Query 6.4)**
   - Participation volume over time
   - Repeat investor percentage trends

5. **Retention Analysis (Query 6.5)**
   - Cohort retention rates
   - How many investors return for 2nd, 3rd deals?

### Step 6: Sample Data Validation (5-10 minutes)

Run **Section 7** to generate sample investor histories:

```sql
-- Run Query 7.1: Sample Investor Histories
```

**Manual Validation:**
1. Pick 3-5 sample investors from the output
2. Look up their actual transaction history
3. Verify sequence numbers match chronological order
4. Confirm first_participation_date matches first transaction date
5. Check for any obvious anomalies

**Share with Stakeholders:**
- Send sample data to finance team for spot-checking
- Ask: "Do these sequences look correct based on your records?"
- Get sign-off before considering initialization complete

---

## Expected Results

### Data Volume

Based on 110 investors with varying participation levels:

- **Total Rows:** 500-2,000 records (estimated)
- **Avg Deals per Investor:** 5-15 deals
- **Range:** 1 deal (first-time investors) to 20+ deals (power investors)

### Sequence Distribution

Typical distribution (will vary):

| Sequence | Description | Expected % of Investors |
|----------|-------------|-------------------------|
| 1st deal | First-time investors | 100% (all start here) |
| 2nd deal | Returned for second investment | 60-80% |
| 3rd deal | Third-time investors | 40-60% |
| 4-5 deals | Regular investors | 20-40% |
| 6+ deals | Power investors | 5-15% |

### Performance

- **Analysis queries (Sections 1-3):** < 2 seconds each
- **INSERT execution (Section 4):** < 1 second
- **Verification queries (Section 5):** < 1 second each
- **Summary queries (Section 6):** < 2 seconds each

---

## Troubleshooting

### Issue: "Investor count is not 110"

**Possible Causes:**
- Some investors have no transactions (check Query 1.2)
- Investors were added after transactions were recorded
- External_id linking issues

**Resolution:**
- Review `investors_without_transactions` list
- Confirm expected behavior with business team
- May be acceptable if investors are newly added

### Issue: "Sequence gaps detected"

**Possible Causes:**
- Bug in ROW_NUMBER() logic
- Duplicate transaction data
- Manual deletions from transactions table

**Resolution:**
- Review Query 5.2 output for specific gaps
- Check affected investor's transaction history
- Re-run INSERT after fixing data

### Issue: "Dates out of chronological order"

**Possible Causes:**
- Incorrect transaction_date values
- Time zone issues
- Manual date corrections without updating participations

**Resolution:**
- Review Query 5.5 output for specific violations
- Check source transaction data for accuracy
- Re-run INSERT after date corrections

### Issue: "INSERT fails with constraint violation"

**Possible Causes:**
- Foreign key references to non-existent investors/deals/funds
- XOR constraint violation (both or neither deal_id/fund_id set)
- Duplicate investor-deal combinations

**Resolution:**
```sql
-- Check for orphaned references
SELECT DISTINCT t.investor_id
FROM transactions t
LEFT JOIN investors i ON i.id = t.investor_id
WHERE i.id IS NULL;

-- Check for XOR violations
SELECT *
FROM transactions
WHERE (deal_id IS NOT NULL AND fund_id IS NOT NULL)
   OR (deal_id IS NULL AND fund_id IS NULL);

-- Check for duplicates in source data
SELECT investor_id, deal_id, fund_id, COUNT(*)
FROM (
    SELECT DISTINCT investor_id, deal_id, fund_id
    FROM transactions
    WHERE type = 'CONTRIBUTION'
) t
GROUP BY investor_id, deal_id, fund_id
HAVING COUNT(*) > 1;
```

### Issue: "Performance is slow"

**Possible Causes:**
- Large transaction table (100K+ rows)
- Missing indexes on transactions table
- Concurrent queries blocking execution

**Resolution:**
```sql
-- Add indexes to transactions if missing
CREATE INDEX IF NOT EXISTS idx_transactions_investor_date
  ON transactions(investor_id, transaction_date);

CREATE INDEX IF NOT EXISTS idx_transactions_type_date
  ON transactions(type, transaction_date);

-- Run ANALYZE to update statistics
ANALYZE transactions;
ANALYZE investor_deal_participations;
```

---

## Maintenance & Updates

### Adding New Participations

When new transactions are recorded, update participations:

```sql
-- Option A: Incremental update (if performance allows)
WITH new_participations AS (
    SELECT
        t.investor_id,
        t.deal_id,
        t.fund_id,
        MIN(t.transaction_date) AS first_date
    FROM transactions t
    LEFT JOIN investor_deal_participations idp
        ON idp.investor_id = t.investor_id
        AND idp.deal_id IS NOT DISTINCT FROM t.deal_id
        AND idp.fund_id IS NOT DISTINCT FROM t.fund_id
    WHERE t.type = 'CONTRIBUTION'
      AND idp.id IS NULL  -- Only new combinations
    GROUP BY t.investor_id, t.deal_id, t.fund_id
)
INSERT INTO investor_deal_participations (
    investor_id,
    deal_id,
    fund_id,
    first_participation_date,
    participation_sequence
)
SELECT
    np.investor_id,
    np.deal_id,
    np.fund_id,
    np.first_date,
    COALESCE(
        (SELECT MAX(participation_sequence)
         FROM investor_deal_participations
         WHERE investor_id = np.investor_id),
        0
    ) + ROW_NUMBER() OVER (PARTITION BY np.investor_id ORDER BY np.first_date)
FROM new_participations np;

-- Option B: Full rebuild (recommended for bulk imports)
-- Re-run the entire initialization script
```

### Recalculating All Sequences

If transaction data is corrected or historical data is imported:

```sql
-- 1. Backup current data (optional)
CREATE TABLE investor_deal_participations_backup AS
SELECT * FROM investor_deal_participations;

-- 2. Clear table
TRUNCATE TABLE investor_deal_participations RESTART IDENTITY CASCADE;

-- 3. Re-run Section 4 INSERT statement

-- 4. Verify with Section 5 queries

-- 5. Drop backup if successful
DROP TABLE investor_deal_participations_backup;
```

### Archiving Old Data

If the table grows very large (unlikely with ~110 investors):

```sql
-- Archive participations older than 10 years
CREATE TABLE investor_deal_participations_archive (
    LIKE investor_deal_participations INCLUDING ALL
);

INSERT INTO investor_deal_participations_archive
SELECT * FROM investor_deal_participations
WHERE first_participation_date < CURRENT_DATE - INTERVAL '10 years';

DELETE FROM investor_deal_participations
WHERE first_participation_date < CURRENT_DATE - INTERVAL '10 years';
```

---

## Integration with Commission Calculations

### Example: Tiered Commission Lookup

```sql
-- Given a contribution, determine the applicable commission tier
WITH contribution_info AS (
    SELECT
        c.id AS contribution_id,
        c.investor_id,
        c.deal_id,
        c.fund_id,
        c.amount
    FROM contributions c
    WHERE c.id = :contribution_id
)
SELECT
    ci.contribution_id,
    ci.investor_id,
    ci.amount,
    idp.participation_sequence,
    CASE
        WHEN idp.participation_sequence = 1 THEN 'first_time_rate'
        WHEN idp.participation_sequence = 2 THEN 'second_time_rate'
        WHEN idp.participation_sequence >= 3 THEN 'repeat_rate'
        ELSE 'default_rate'
    END AS rate_tier,
    -- Lookup actual rates from pricing rules
    pr.rate_bps AS applicable_rate
FROM contribution_info ci
JOIN investor_deal_participations idp
    ON idp.investor_id = ci.investor_id
    AND idp.deal_id IS NOT DISTINCT FROM ci.deal_id
    AND idp.fund_id IS NOT DISTINCT FROM ci.fund_id
LEFT JOIN pricing_rules pr
    ON pr.tier = (
        CASE
            WHEN idp.participation_sequence = 1 THEN 'first_time'
            WHEN idp.participation_sequence = 2 THEN 'second_time'
            ELSE 'repeat'
        END
    );
```

### Example: Early Bird Discount Eligibility

```sql
-- Check if investor qualifies for early bird discount
-- (e.g., first 3 deals get discount)
SELECT
    i.id AS investor_id,
    i.name,
    idp.participation_sequence,
    idp.first_participation_date,
    CASE
        WHEN idp.participation_sequence <= 3 THEN true
        ELSE false
    END AS qualifies_for_early_bird
FROM investors i
JOIN investor_deal_participations idp ON idp.investor_id = i.id
WHERE i.id = :investor_id
  AND idp.deal_id = :deal_id;
```

---

## Best Practices

### DO ✅

- Run analysis queries BEFORE executing INSERT
- Verify all checks pass before considering data production-ready
- Keep schema specification document up to date
- Document any custom modifications to the script
- Test on a copy of production data first
- Create backups before re-running inserts

### DON'T ❌

- Don't skip verification queries
- Don't assume data is correct without validation
- Don't modify participation sequences manually
- Don't delete participations without recalculating sequences
- Don't run INSERT in production without testing
- Don't proceed if any verification query fails

---

## Acceptance Criteria

Before marking initialization as complete, verify:

- ✅ All 110 investors accounted for (with or without transactions)
- ✅ All verification queries pass (Section 5)
- ✅ Summary report reviewed and makes business sense (Section 6)
- ✅ Sample data validated by finance team (Section 7)
- ✅ No constraint violations or errors during INSERT
- ✅ Query performance meets expectations (< 2 seconds)
- ✅ Documentation shared with relevant stakeholders

---

## Support & Questions

### Documentation References

- **Schema Specification:** `docs/INVESTOR_DEAL_PARTICIPATIONS_SCHEMA.md`
- **Initialization Script:** `scripts/initialize_investor_deal_counts.sql`
- **Transaction Schema:** `supabase/migrations/20251019100004_transactions_credits.sql`
- **Core Entities Schema:** `supabase/migrations/20251016000001_redesign_01_core_entities.sql`

### Common Questions

**Q: How often should we run this script?**
A: Only when historical data changes or new bulk imports occur. Ongoing transactions should use incremental updates.

**Q: What if we have more than 110 investors later?**
A: The script scales automatically. Just re-run with updated transaction data.

**Q: Can we change participation sequences manually?**
A: Not recommended. Always recalculate from source transactions to maintain integrity.

**Q: What happens if we delete a transaction?**
A: You should recalculate the affected investor's entire sequence to maintain continuity.

**Q: How do we handle investor mergers or splits?**
A: Complex case. Consult with business team on merge strategy, then manually consolidate participations.

---

## Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-10-26 | Claude Code | Initial documentation |

---

## Appendix: Quick Reference Commands

### Check Table Exists
```sql
SELECT EXISTS (
    SELECT FROM information_schema.tables
    WHERE table_name = 'investor_deal_participations'
);
```

### Count Records
```sql
SELECT COUNT(*) FROM investor_deal_participations;
```

### Sample Data
```sql
SELECT * FROM investor_deal_participations LIMIT 10;
```

### Clear Table
```sql
TRUNCATE TABLE investor_deal_participations RESTART IDENTITY CASCADE;
```

### Verify Constraints
```sql
SELECT
    conname AS constraint_name,
    pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conrelid = 'investor_deal_participations'::regclass;
```

### Check Indexes
```sql
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'investor_deal_participations';
```
