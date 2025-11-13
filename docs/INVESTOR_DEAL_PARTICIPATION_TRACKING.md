# Investor Deal Participation Tracking System

## Overview

This system tracks how many deals each investor has participated in, enabling tiered commission calculations based on deal count. When an investor makes their first contribution to a deal, a participation record is created with a sequence number (1st deal, 2nd deal, 3rd deal, etc.), which determines the applicable commission tier.

## Business Rules

### Commission Tiers

The system implements the following tiered commission structure:

| Deal Number | Commission Rate | Basis Points |
|-------------|----------------|--------------|
| 1st deal    | 1.5%           | 150 bps      |
| 2nd-3rd deal| 1.0%           | 100 bps      |
| 4th-5th deal| 0.5%           | 50 bps       |
| 6+ deals    | 0%             | 0 bps        |

### Key Principles

1. **Per-Investor Tracking**: Deal count is tracked per investor, not per party/distributor
2. **Chronological Order**: Participation sequence is based on the date of first contribution to each deal
3. **Immutability**: Once a participation is recorded, the sequence number does not change
4. **One Participation Per Deal**: Each investor-deal combination can only have one participation record
5. **Automatic Creation**: Participations are automatically created when investors make their first contribution to a deal

## Database Schema

### Table: `investor_deal_participations`

```sql
CREATE TABLE investor_deal_participations (
  id                      BIGSERIAL PRIMARY KEY,
  investor_id             BIGINT NOT NULL REFERENCES investors(id),
  deal_id                 BIGINT NOT NULL REFERENCES deals(id),
  participation_sequence  INT NOT NULL CHECK (participation_sequence > 0),
  first_contribution_date DATE NOT NULL,
  first_contribution_id   BIGINT NOT NULL REFERENCES contributions(id),
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by              UUID REFERENCES auth.users(id),
  notes                   TEXT,

  UNIQUE (investor_id, deal_id),
  UNIQUE (investor_id, participation_sequence)
);
```

### Key Columns

- **`participation_sequence`**: The Nth deal for this investor (1, 2, 3, ...). Determines commission tier.
- **`first_contribution_date`**: Date of investor's first contribution to this deal. Used to determine chronological order.
- **`first_contribution_id`**: Reference to the contribution that established this participation.

### Indexes

```sql
-- Primary lookup: get all participations for an investor
CREATE INDEX idx_investor_deal_part_investor
  ON investor_deal_participations(investor_id, participation_sequence);

-- Reverse lookup: which investors participated in a deal
CREATE INDEX idx_investor_deal_part_deal
  ON investor_deal_participations(deal_id);

-- Date-based queries
CREATE INDEX idx_investor_deal_part_contrib_date
  ON investor_deal_participations(first_contribution_date);

-- Sequence lookups
CREATE INDEX idx_investor_deal_part_sequence
  ON investor_deal_participations(participation_sequence);
```

## Helper Functions

### `get_investor_deal_count(investor_id)`

Returns the total number of deals an investor has participated in.

```sql
SELECT get_investor_deal_count(42);
-- Returns: 3 (investor has participated in 3 deals)
```

**Use Case**: Determine if investor qualifies for commission on their next deal.

### `get_investor_deal_sequence(investor_id, deal_id)`

Returns the participation sequence number for a specific investor-deal combination.

```sql
SELECT get_investor_deal_sequence(42, 100);
-- Returns: 2 (this is the investor's 2nd deal)
```

**Use Case**: Determine which tier to apply when calculating commission for a specific contribution.

### `get_commission_tier_rate(deal_sequence)`

Returns the commission rate in basis points for a given deal sequence number.

```sql
SELECT get_commission_tier_rate(1);  -- Returns: 150 bps (1.5%)
SELECT get_commission_tier_rate(2);  -- Returns: 100 bps (1.0%)
SELECT get_commission_tier_rate(4);  -- Returns: 50 bps (0.5%)
SELECT get_commission_tier_rate(6);  -- Returns: 0 bps (no commission)
```

**Use Case**: Get the applicable commission rate for a participation sequence.

### `get_commission_tier_description(deal_sequence)`

Returns a human-readable description of the commission tier.

```sql
SELECT get_commission_tier_description(1);
-- Returns: "Tier 1: First Deal (1.5%)"

SELECT get_commission_tier_description(3);
-- Returns: "Tier 2: Deals 2-3 (1.0%)"
```

**Use Case**: Display tier information in UI or reports.

### `validate_investor_participation_sequence(investor_id)`

Validates that an investor's participation sequence is sequential with no gaps.

```sql
SELECT * FROM validate_investor_participation_sequence(42);
-- Returns: (is_valid, error_message, expected_sequence[], actual_sequence[])
```

**Use Case**: Data integrity checks and auditing.

## Reporting Views

### `investor_participation_summary`

Summary of each investor's participation history.

```sql
SELECT * FROM investor_participation_summary
WHERE total_deals > 0
ORDER BY total_deals DESC;
```

**Columns**:
- `investor_id`, `investor_name`
- `total_deals`: Number of deals participated in
- `first_participation_date`: Date of first ever participation
- `latest_participation_date`: Date of most recent participation
- `deal_sequence`: Array of deal names in participation order
- `next_deal_tier_rate_bps`: Rate that would apply to their next deal
- `next_deal_tier_description`: Description of their next tier

**Use Case**: Dashboard showing investor participation history and next applicable tier.

### `deal_participation_with_tiers`

Complete view of all participations with tier information.

```sql
SELECT * FROM deal_participation_with_tiers
WHERE investor_name = 'ABC Capital'
ORDER BY participation_sequence;
```

**Columns**:
- `investor_id`, `investor_name`
- `deal_id`, `deal_name`
- `participation_sequence`: Nth deal for this investor
- `tier_rate_bps`: Applicable commission rate
- `tier_description`: Human-readable tier name
- `first_contribution_date`: When they first contributed
- `first_contribution_amount`: Amount of first contribution

**Use Case**: Detailed participation history with commission tier information.

## Automatic Participation Creation

### Trigger: `trigger_auto_create_participation`

Automatically creates participation records when new contributions are inserted.

**Logic**:
1. Contribution is inserted to a deal (not fund-level)
2. System checks if participation already exists for this investor-deal combination
3. If not, calculates next sequence number for this investor
4. Creates participation record with:
   - `participation_sequence` = max existing sequence + 1
   - `first_contribution_date` = contribution's paid_in_date
   - `first_contribution_id` = new contribution's id

**Example**:
```sql
-- Investor makes their first contribution to Deal 123
INSERT INTO contributions (investor_id, deal_id, paid_in_date, amount)
VALUES (42, 123, '2025-10-26', 100000);

-- Trigger automatically creates:
-- investor_deal_participations: investor_id=42, deal_id=123, participation_sequence=1
```

## Usage Examples

### Example 1: Calculate Commission for a Contribution

```sql
-- Given a contribution, determine the applicable commission rate
SELECT
  c.id as contribution_id,
  c.investor_id,
  i.name as investor_name,
  c.deal_id,
  d.name as deal_name,
  c.amount as contribution_amount,
  get_investor_deal_sequence(c.investor_id, c.deal_id) as deal_sequence,
  get_commission_tier_rate(
    get_investor_deal_sequence(c.investor_id, c.deal_id)
  ) as commission_rate_bps,
  c.amount * get_commission_tier_rate(
    get_investor_deal_sequence(c.investor_id, c.deal_id)
  ) / 10000.0 as commission_amount
FROM contributions c
INNER JOIN investors i ON i.id = c.investor_id
INNER JOIN deals d ON d.id = c.deal_id
WHERE c.id = 12345;
```

### Example 2: Find All Tier 1 (First Deal) Participations

```sql
SELECT
  investor_name,
  deal_name,
  first_contribution_date,
  first_contribution_amount,
  tier_rate_bps
FROM deal_participation_with_tiers
WHERE participation_sequence = 1
ORDER BY first_contribution_date DESC;
```

### Example 3: Identify Investors Approaching Tier Expiration

```sql
-- Find investors with 5 deals (last deal that earns commission)
SELECT
  investor_name,
  total_deals,
  next_deal_tier_description,
  deal_sequence
FROM investor_participation_summary
WHERE total_deals = 5;

-- These investors will earn 0% commission on their 6th deal
```

### Example 4: Commission Report by Tier

```sql
SELECT
  participation_sequence,
  tier_description,
  COUNT(*) as participation_count,
  COUNT(DISTINCT investor_id) as unique_investors,
  SUM(first_contribution_amount) as total_contributions,
  AVG(first_contribution_amount) as avg_contribution
FROM deal_participation_with_tiers
GROUP BY participation_sequence, tier_description
ORDER BY participation_sequence;
```

### Example 5: Investor Participation Timeline

```sql
-- Show chronological participation history for a specific investor
SELECT
  participation_sequence as deal_number,
  deal_name,
  first_contribution_date,
  first_contribution_amount,
  tier_rate_bps,
  tier_description,
  first_contribution_amount * tier_rate_bps / 10000.0 as estimated_commission
FROM deal_participation_with_tiers
WHERE investor_name = 'ABC Capital'
ORDER BY participation_sequence;
```

### Example 6: Validate All Participation Sequences

```sql
-- Check for any sequence integrity issues across all investors
SELECT
  i.id as investor_id,
  i.name as investor_name,
  v.is_valid,
  v.error_message,
  v.expected_sequence,
  v.actual_sequence
FROM investors i
CROSS JOIN LATERAL validate_investor_participation_sequence(i.id) v
WHERE NOT v.is_valid;

-- If this returns no rows, all sequences are valid!
```

## Integration with Commission Calculations

### Current Workflow

When calculating commissions for a contribution:

1. **Identify the investor and deal**:
   ```sql
   SELECT investor_id, deal_id FROM contributions WHERE id = ?
   ```

2. **Get the participation sequence**:
   ```sql
   SELECT get_investor_deal_sequence(investor_id, deal_id)
   ```

3. **Get the applicable commission rate**:
   ```sql
   SELECT get_commission_tier_rate(participation_sequence)
   ```

4. **Calculate commission**:
   ```sql
   commission_amount = contribution_amount * (rate_bps / 10000.0)
   ```

### Recommended: Store Participation Info in Commission Snapshot

When creating commission records, include participation information in the `snapshot_json`:

```sql
UPDATE commissions
SET snapshot_json = jsonb_set(
  snapshot_json,
  '{participation}',
  jsonb_build_object(
    'sequence', get_investor_deal_sequence(investor_id, deal_id),
    'tier_rate_bps', get_commission_tier_rate(get_investor_deal_sequence(investor_id, deal_id)),
    'tier_description', get_commission_tier_description(get_investor_deal_sequence(investor_id, deal_id)),
    'total_investor_deals', get_investor_deal_count(investor_id)
  )
)
WHERE id = ?;
```

This creates an immutable snapshot of the participation information at the time of commission calculation.

## Data Migration

### Initial Setup

1. **Apply the migration**:
   ```bash
   psql -f supabase/migrations/20251026000001_investor_deal_participations.sql
   ```

2. **Initialize historical data**:
   ```bash
   psql -f scripts/initialize_investor_participations.sql
   ```

3. **Verify results**:
   ```sql
   SELECT * FROM investor_participation_summary;
   SELECT * FROM deal_participation_with_tiers LIMIT 50;
   ```

### Post-Migration

- New contributions automatically create participations (via trigger)
- No manual intervention needed for ongoing operations
- Participation records are immutable once created

## Maintenance and Monitoring

### Regular Health Checks

Run these queries periodically to ensure data integrity:

```sql
-- 1. Check for sequence gaps
SELECT COUNT(*) as investors_with_gaps
FROM (
  SELECT investor_id, MAX(participation_sequence) as max_seq, COUNT(*) as count
  FROM investor_deal_participations
  GROUP BY investor_id
  HAVING MAX(participation_sequence) != COUNT(*)
) gaps;

-- 2. Check for duplicate participations
SELECT investor_id, deal_id, COUNT(*)
FROM investor_deal_participations
GROUP BY investor_id, deal_id
HAVING COUNT(*) > 1;

-- 3. Validate all sequences
SELECT COUNT(*) as invalid_sequences
FROM investors i
CROSS JOIN LATERAL validate_investor_participation_sequence(i.id) v
WHERE NOT v.is_valid;
```

All checks should return 0.

### Common Issues and Resolutions

**Issue**: Participation sequence has gaps
- **Cause**: Manual deletion or data corruption
- **Resolution**: Re-run initialization script or manually fix sequences

**Issue**: Duplicate participations
- **Cause**: Race condition or unique constraint violation
- **Resolution**: Delete duplicates, keeping the one with earliest created_at

**Issue**: Participation not created for new contribution
- **Cause**: Trigger disabled or error in trigger function
- **Resolution**: Check trigger status, manually create participation if needed

## Performance Considerations

### Query Performance

- **Indexed Queries**: All common lookups use indexes and execute in <1ms
- **Function Performance**: Helper functions are STABLE or IMMUTABLE, enabling query optimization
- **View Materialization**: For very large datasets, consider materializing views

### Expected Performance

| Operation | Rows | Expected Time |
|-----------|------|---------------|
| Get investor deal count | 1 | <1ms |
| Get participation sequence | 1 | <1ms |
| List investor participations | <50 | <5ms |
| Participation summary (all) | <10,000 | <100ms |
| Trigger on new contribution | 1 insert | <2ms |

### Scaling Considerations

- Current design supports millions of participations
- For 26 investors × 100 deals = 2,600 participations (very small dataset)
- No performance concerns expected for foreseeable growth

## Security and Access Control

### Row-Level Security (RLS)

Policies are aligned with existing commission system:

- **SELECT**: Finance, Ops, Manager, Admin can read all participations
- **INSERT**: Finance and Admin can create participations
- **UPDATE**: Admin only (should be rare - immutable by design)
- **DELETE**: Admin only (should be very rare)

### Audit Trail

- All records include `created_at` and `created_by` timestamps
- Historical data includes notes: "Backfilled from historical contributions"
- Participation records should never be deleted (archive deals instead)

## FAQ

**Q: What happens if an investor makes multiple contributions to the same deal?**
A: Only the first contribution creates a participation record. Subsequent contributions to the same deal don't change the participation sequence.

**Q: Can participation sequences be renumbered?**
A: No. Sequences are immutable once created to maintain financial audit integrity. If you need to correct sequences, you must delete and recreate participations (Admin only, with extreme caution).

**Q: What if I want to change the commission tier structure?**
A: Update the `get_commission_tier_rate()` function. Historical commission records should already have snapshots, so past calculations remain unchanged.

**Q: How do I handle investor mergers or splits?**
A: This requires manual intervention. Typically, create a new investor entity and migrate participations, or mark old investor inactive and create new agreements.

**Q: Can I see historical changes to participation records?**
A: The current design doesn't include change tracking. Consider adding an audit log table if detailed change history is required.

**Q: What about fund-level contributions (not deal-specific)?**
A: The trigger ignores fund-level contributions. Only deal-specific contributions create participations.

## Support and Troubleshooting

For issues, questions, or enhancements:
1. Check validation queries in the initialization script
2. Review trigger logs for errors
3. Verify RLS policies for access issues
4. Consult migration documentation for schema details

## Files Reference

- **Migration**: `supabase/migrations/20251026000001_investor_deal_participations.sql`
- **Initialization**: `scripts/initialize_investor_participations.sql`
- **Documentation**: `docs/INVESTOR_DEAL_PARTICIPATION_TRACKING.md` (this file)

---

Last Updated: 2025-10-26
Version: 1.0.0
