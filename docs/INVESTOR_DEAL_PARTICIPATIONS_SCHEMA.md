# Investor Deal Participations Table - Schema Specification

**Version:** 1.0
**Date:** 2025-10-26
**Status:** Specification for Schema Agent Implementation
**Related Script:** `scripts/initialize_investor_deal_counts.sql`

---

## Purpose

The `investor_deal_participations` table tracks the chronological sequence of deal participations for each investor. This enables tiered commission calculations based on whether an investor is making their 1st, 2nd, 3rd, or nth investment.

### Business Context

- **Commission Tiers:** Different commission rates may apply based on investor participation history
- **First-time investors** might receive different treatment than repeat investors
- **Promotional incentives** may be triggered by participation milestones (e.g., early bird discounts)
- **Deal sequence tracking** allows for historical analysis and retention metrics

---

## Table Schema

### Table: `investor_deal_participations`

```sql
CREATE TABLE investor_deal_participations (
  id                        BIGSERIAL PRIMARY KEY,

  -- Foreign Keys
  investor_id               BIGINT NOT NULL REFERENCES investors(id) ON DELETE RESTRICT,
  deal_id                   BIGINT REFERENCES deals(id) ON DELETE RESTRICT,
  fund_id                   BIGINT REFERENCES funds(id) ON DELETE RESTRICT,

  -- Participation Tracking
  first_participation_date  DATE NOT NULL,
  participation_sequence    INTEGER NOT NULL CHECK (participation_sequence > 0),

  -- Audit Trail
  created_at                TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at                TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Constraints
  CONSTRAINT investor_deal_participations_one_scope_ck CHECK (
    (deal_id IS NOT NULL AND fund_id IS NULL) OR
    (deal_id IS NULL AND fund_id IS NOT NULL)
  ),

  -- Unique constraint: one record per investor-deal/fund combination
  CONSTRAINT investor_deal_participations_unique_ck UNIQUE (investor_id, deal_id, fund_id)
);
```

---

## Column Specifications

### Primary Key

| Column | Type | Description |
|--------|------|-------------|
| `id` | BIGSERIAL | Auto-incrementing primary key |

### Foreign Keys

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `investor_id` | BIGINT | NOT NULL, FK → investors(id) | The investor making the participation |
| `deal_id` | BIGINT | NULLABLE, FK → deals(id) | Deal-level participation (XOR with fund_id) |
| `fund_id` | BIGINT | NULLABLE, FK → funds(id) | Fund-level participation (XOR with deal_id) |

### Participation Data

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `first_participation_date` | DATE | NOT NULL | Date of first transaction to this deal/fund |
| `participation_sequence` | INTEGER | NOT NULL, > 0 | Chronological sequence number (1 = first deal, 2 = second deal, etc.) |

### Audit Trail

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Record creation timestamp |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Last update timestamp |

---

## Constraints

### Check Constraints

1. **Scope Exclusivity** (`investor_deal_participations_one_scope_ck`)
   - Ensures exactly ONE of `deal_id` or `fund_id` is set (XOR logic)
   - Prevents invalid records with both or neither set

2. **Positive Sequence** (inline CHECK)
   - `participation_sequence > 0` ensures sequences start at 1

### Unique Constraint

- **Unique Key:** `(investor_id, deal_id, fund_id)`
- Prevents duplicate participations for the same investor-deal combination
- Note: PostgreSQL treats NULL as distinct, so this works correctly with the XOR constraint

---

## Indexes

```sql
-- Lookup participations by investor (most common query pattern)
CREATE INDEX idx_investor_deal_participations_investor
  ON investor_deal_participations(investor_id);

-- Lookup by investor + sequence (for tiered commission lookups)
CREATE INDEX idx_investor_deal_participations_investor_seq
  ON investor_deal_participations(investor_id, participation_sequence);

-- Lookup participations by deal (for deal-level analytics)
CREATE INDEX idx_investor_deal_participations_deal
  ON investor_deal_participations(deal_id) WHERE deal_id IS NOT NULL;

-- Lookup participations by fund (for fund-level analytics)
CREATE INDEX idx_investor_deal_participations_fund
  ON investor_deal_participations(fund_id) WHERE fund_id IS NOT NULL;

-- Lookup by participation date (for time-series analysis)
CREATE INDEX idx_investor_deal_participations_date
  ON investor_deal_participations(first_participation_date);

-- Composite index for sequence ordering within investor
CREATE INDEX idx_investor_deal_participations_investor_date
  ON investor_deal_participations(investor_id, first_participation_date, participation_sequence);
```

---

## Comments (Documentation)

```sql
COMMENT ON TABLE investor_deal_participations IS
  'Tracks chronological sequence of investor deal participations for tiered commission calculations';

COMMENT ON COLUMN investor_deal_participations.investor_id IS
  'Investor making the participation';

COMMENT ON COLUMN investor_deal_participations.deal_id IS
  'Deal-level participation (mutually exclusive with fund_id)';

COMMENT ON COLUMN investor_deal_participations.fund_id IS
  'Fund-level participation (mutually exclusive with deal_id)';

COMMENT ON COLUMN investor_deal_participations.first_participation_date IS
  'Date of first transaction to this deal/fund (determines sequence order)';

COMMENT ON COLUMN investor_deal_participations.participation_sequence IS
  'Chronological sequence number (1 = first deal, 2 = second deal, etc.) within investor';

COMMENT ON CONSTRAINT investor_deal_participations_one_scope_ck ON investor_deal_participations IS
  'Participation must belong to exactly one of: deal_id OR fund_id (XOR enforcement)';

COMMENT ON CONSTRAINT investor_deal_participations_unique_ck ON investor_deal_participations IS
  'Prevents duplicate participations for same investor-deal/fund combination';
```

---

## Row-Level Security (RLS)

```sql
-- Enable RLS
ALTER TABLE investor_deal_participations ENABLE ROW LEVEL SECURITY;

-- Policy: All authenticated users can view participation data
CREATE POLICY "investor_deal_participations_select_all"
  ON investor_deal_participations
  FOR SELECT
  TO authenticated
  USING (true);

-- Policy: Only finance/admin can insert participation records
CREATE POLICY "investor_deal_participations_insert_finance"
  ON investor_deal_participations
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid()
      AND role IN ('admin', 'finance')
    )
  );

-- Policy: Only finance/admin can update participation records
CREATE POLICY "investor_deal_participations_update_finance"
  ON investor_deal_participations
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid()
      AND role IN ('admin', 'finance')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid()
      AND role IN ('admin', 'finance')
    )
  );

-- Policy: Only admin can delete participation records
CREATE POLICY "investor_deal_participations_delete_admin"
  ON investor_deal_participations
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid()
      AND role = 'admin'
    )
  );
```

---

## Data Population Strategy

The table is populated from historical transaction data using the initialization script:

1. **Source:** `transactions` table (type = 'CONTRIBUTION' only)
2. **Grouping:** Multiple transactions to same deal = ONE participation
3. **Sequencing:** Ordered by MIN(transaction_date) per investor-deal combination
4. **Tie-breaking:** Same-day transactions to different deals use (deal_id, fund_id) as secondary sort

### Population Logic

```sql
-- Core logic (simplified from initialization script)
WITH investor_deal_first_dates AS (
    SELECT
        investor_id,
        deal_id,
        fund_id,
        MIN(transaction_date) AS first_transaction_date
    FROM transactions
    WHERE type = 'CONTRIBUTION'
    GROUP BY investor_id, deal_id, fund_id
)
SELECT
    investor_id,
    deal_id,
    fund_id,
    first_transaction_date AS first_participation_date,
    ROW_NUMBER() OVER (
        PARTITION BY investor_id
        ORDER BY first_transaction_date, COALESCE(deal_id, 0), COALESCE(fund_id, 0)
    ) AS participation_sequence
FROM investor_deal_first_dates;
```

---

## Usage Examples

### Query 1: Get investor's participation history

```sql
SELECT
    idp.participation_sequence,
    idp.first_participation_date,
    d.name AS deal_name,
    f.name AS fund_name,
    CASE
        WHEN idp.participation_sequence = 1 THEN 'First-time investor'
        WHEN idp.participation_sequence = 2 THEN 'Second-time investor'
        WHEN idp.participation_sequence = 3 THEN 'Third-time investor'
        ELSE 'Repeat investor (' || idp.participation_sequence || ' deals)'
    END AS investor_status
FROM investor_deal_participations idp
LEFT JOIN deals d ON d.id = idp.deal_id
LEFT JOIN funds f ON f.id = idp.fund_id
WHERE idp.investor_id = 42
ORDER BY idp.participation_sequence;
```

### Query 2: Determine commission tier for a specific transaction

```sql
-- Given: investor_id = 42, deal_id = 17
-- Determine: What deal number is this for the investor?

SELECT
    idp.participation_sequence,
    CASE
        WHEN idp.participation_sequence = 1 THEN 'first_time_rate'
        WHEN idp.participation_sequence = 2 THEN 'second_time_rate'
        ELSE 'repeat_investor_rate'
    END AS applicable_rate_tier
FROM investor_deal_participations idp
WHERE idp.investor_id = 42
  AND idp.deal_id = 17;
```

### Query 3: Count investors by participation level

```sql
SELECT
    CASE
        WHEN participation_sequence = 1 THEN '1st deal'
        WHEN participation_sequence = 2 THEN '2nd deal'
        WHEN participation_sequence = 3 THEN '3rd deal'
        WHEN participation_sequence <= 5 THEN '4-5 deals'
        ELSE '6+ deals'
    END AS participation_group,
    COUNT(DISTINCT investor_id) AS investor_count,
    ROUND(100.0 * COUNT(DISTINCT investor_id) /
        (SELECT COUNT(DISTINCT investor_id) FROM investor_deal_participations), 2
    ) AS percentage
FROM investor_deal_participations
GROUP BY participation_group
ORDER BY MIN(participation_sequence);
```

### Query 4: Investor retention analysis

```sql
WITH investor_stats AS (
    SELECT
        investor_id,
        MIN(first_participation_date) AS first_deal_date,
        MAX(participation_sequence) AS total_deals,
        MAX(first_participation_date) - MIN(first_participation_date) AS investment_span_days
    FROM investor_deal_participations
    GROUP BY investor_id
)
SELECT
    total_deals,
    COUNT(*) AS investor_count,
    ROUND(AVG(investment_span_days), 0) AS avg_span_days,
    MIN(first_deal_date) AS earliest_cohort,
    MAX(first_deal_date) AS latest_cohort
FROM investor_stats
GROUP BY total_deals
ORDER BY total_deals;
```

---

## Data Integrity Guarantees

### Automatic Checks

1. **Sequence Continuity:** Each investor should have sequences 1, 2, 3, ... with no gaps
2. **Chronological Order:** Within each investor, `first_participation_date` should be non-decreasing as sequence increases
3. **Uniqueness:** No duplicate (investor_id, deal_id, fund_id) combinations
4. **Positive Sequences:** All sequences start at 1 and increment by 1

### Verification Queries

See `scripts/initialize_investor_deal_counts.sql` Section 5 for comprehensive verification queries.

---

## Maintenance Procedures

### Adding New Participations

When a new contribution is recorded:

1. Check if participation record already exists for this investor-deal combination
2. If not, calculate the new sequence number:
   ```sql
   SELECT COALESCE(MAX(participation_sequence), 0) + 1
   FROM investor_deal_participations
   WHERE investor_id = ?
   ```
3. Insert new record with calculated sequence

### Recalculating from Scratch

To rebuild the entire table from transactions:

```sql
-- 1. Truncate existing data
TRUNCATE TABLE investor_deal_participations RESTART IDENTITY CASCADE;

-- 2. Run the INSERT statement from scripts/initialize_investor_deal_counts.sql

-- 3. Verify integrity with Section 5 queries
```

### Updating Existing Records

Generally, participation records should be **immutable** once created. If corrections are needed:

1. Delete incorrect record(s)
2. Recalculate affected investor's entire sequence
3. Re-insert corrected records

---

## Performance Considerations

### Expected Volume

- **Rows per investor:** 1-10+ (depending on investment activity)
- **Total rows:** ~500-2000 (for 110 investors with average 5-15 deals each)
- **Growth rate:** Slow (new participations added only when new deals close)

### Query Patterns

Most common queries:
1. **Lookup by investor:** `WHERE investor_id = ?` (99% of queries)
2. **Lookup by investor + sequence:** `WHERE investor_id = ? AND participation_sequence = ?`
3. **Lookup by deal:** `WHERE deal_id = ?` (for analytics)

The proposed indexes efficiently support all these patterns.

### Maintenance

- **VACUUM:** Run weekly (small table, minimal maintenance)
- **ANALYZE:** Run after bulk inserts
- **REINDEX:** Rarely needed (low churn rate)

---

## Migration File Template

```sql
-- Migration: investor_deal_participations_table
-- Purpose: Create investor deal participation tracking for tiered commissions
-- Date: 2025-10-26
-- Related: scripts/initialize_investor_deal_counts.sql

-- ============================================
-- TABLE: investor_deal_participations
-- ============================================
CREATE TABLE IF NOT EXISTS investor_deal_participations (
  id                        BIGSERIAL PRIMARY KEY,
  investor_id               BIGINT NOT NULL REFERENCES investors(id) ON DELETE RESTRICT,
  deal_id                   BIGINT REFERENCES deals(id) ON DELETE RESTRICT,
  fund_id                   BIGINT REFERENCES funds(id) ON DELETE RESTRICT,
  first_participation_date  DATE NOT NULL,
  participation_sequence    INTEGER NOT NULL CHECK (participation_sequence > 0),
  created_at                TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at                TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT investor_deal_participations_one_scope_ck CHECK (
    (deal_id IS NOT NULL AND fund_id IS NULL) OR
    (deal_id IS NULL AND fund_id IS NOT NULL)
  ),
  CONSTRAINT investor_deal_participations_unique_ck UNIQUE (investor_id, deal_id, fund_id)
);

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX idx_investor_deal_participations_investor
  ON investor_deal_participations(investor_id);

CREATE INDEX idx_investor_deal_participations_investor_seq
  ON investor_deal_participations(investor_id, participation_sequence);

CREATE INDEX idx_investor_deal_participations_deal
  ON investor_deal_participations(deal_id) WHERE deal_id IS NOT NULL;

CREATE INDEX idx_investor_deal_participations_fund
  ON investor_deal_participations(fund_id) WHERE fund_id IS NOT NULL;

CREATE INDEX idx_investor_deal_participations_date
  ON investor_deal_participations(first_participation_date);

CREATE INDEX idx_investor_deal_participations_investor_date
  ON investor_deal_participations(investor_id, first_participation_date, participation_sequence);

-- ============================================
-- COMMENTS
-- ============================================
COMMENT ON TABLE investor_deal_participations IS
  'Tracks chronological sequence of investor deal participations for tiered commission calculations';

COMMENT ON COLUMN investor_deal_participations.investor_id IS 'Investor making the participation';
COMMENT ON COLUMN investor_deal_participations.deal_id IS 'Deal-level participation (XOR with fund_id)';
COMMENT ON COLUMN investor_deal_participations.fund_id IS 'Fund-level participation (XOR with deal_id)';
COMMENT ON COLUMN investor_deal_participations.first_participation_date IS
  'Date of first transaction to this deal/fund (determines sequence order)';
COMMENT ON COLUMN investor_deal_participations.participation_sequence IS
  'Chronological sequence number (1 = first deal, 2 = second deal, etc.) within investor';

COMMENT ON CONSTRAINT investor_deal_participations_one_scope_ck ON investor_deal_participations IS
  'Participation must belong to exactly one of: deal_id OR fund_id (XOR enforcement)';
COMMENT ON CONSTRAINT investor_deal_participations_unique_ck ON investor_deal_participations IS
  'Prevents duplicate participations for same investor-deal/fund combination';

-- ============================================
-- RLS POLICIES
-- ============================================
ALTER TABLE investor_deal_participations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "investor_deal_participations_select_all"
  ON investor_deal_participations FOR SELECT TO authenticated USING (true);

CREATE POLICY "investor_deal_participations_insert_finance"
  ON investor_deal_participations FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role IN ('admin', 'finance'))
  );

CREATE POLICY "investor_deal_participations_update_finance"
  ON investor_deal_participations FOR UPDATE TO authenticated
  USING (EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role IN ('admin', 'finance')))
  WITH CHECK (EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role IN ('admin', 'finance')));

CREATE POLICY "investor_deal_participations_delete_admin"
  ON investor_deal_participations FOR DELETE TO authenticated
  USING (EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin'));
```

---

## Testing Strategy

### Unit Tests

1. **Sequence Continuity:** Verify no gaps in sequence numbers per investor
2. **Chronological Order:** Verify dates are non-decreasing within investor
3. **XOR Constraint:** Verify exactly one of deal_id/fund_id is set
4. **Uniqueness:** Verify no duplicate investor-deal combinations

### Integration Tests

1. **Transaction → Participation:** Create new transaction, verify participation record created/updated
2. **Commission Calculation:** Verify correct tier applied based on participation_sequence
3. **Bulk Import:** Import 100+ transactions, verify all participations created correctly

### Acceptance Criteria

- ✅ All 110 investors have at least one participation record
- ✅ No sequence gaps for any investor
- ✅ All dates in chronological order within each investor
- ✅ Total participations match unique investor-deal combinations from transactions
- ✅ Query performance < 50ms for investor lookup (99th percentile)

---

## Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-10-26 | Claude Code | Initial specification |

---

## References

- **Initialization Script:** `scripts/initialize_investor_deal_counts.sql`
- **Related Tables:** `investors`, `deals`, `funds`, `transactions`
- **Related Migrations:** `20251019100004_transactions_credits.sql`
