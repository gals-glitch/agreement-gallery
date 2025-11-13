# Quick Start: Investor Deal Participation Tracking

## Overview

This system tracks investor deal counts for tiered commission calculations:
- **Deal 1**: 1.5% commission
- **Deals 2-3**: 1.0% commission
- **Deals 4-5**: 0.5% commission
- **Deals 6+**: No commission

## Installation (3 Steps)

### Step 1: Apply Migration

```bash
psql -h your-db-host -U your-user -d your-database \
  -f supabase/migrations/20251026000001_investor_deal_participations.sql
```

This creates:
- `investor_deal_participations` table
- 5 indexes for performance
- 4 helper functions
- 2 reporting views
- Trigger for auto-creation
- RLS policies

### Step 2: Initialize Historical Data

```bash
psql -h your-db-host -U your-user -d your-database \
  -f scripts/initialize_investor_participations.sql
```

This backfills participation records from existing contributions with:
- Correct sequence numbers based on chronological order
- Complete validation and integrity checks
- Summary reports

### Step 3: Verify Installation

```sql
-- Check participations were created
SELECT COUNT(*) FROM investor_deal_participations;

-- View investor summary
SELECT * FROM investor_participation_summary LIMIT 10;

-- Test helper functions
SELECT get_investor_deal_count(
  (SELECT id FROM investors LIMIT 1)
);
```

## Usage Examples

### Get Investor's Total Deal Count

```sql
SELECT get_investor_deal_count(42);
-- Returns: 3 (investor has participated in 3 deals)
```

### Get Sequence for Specific Investor-Deal

```sql
SELECT get_investor_deal_sequence(42, 100);
-- Returns: 2 (this is investor 42's 2nd deal)
```

### Get Commission Rate for a Participation

```sql
SELECT get_commission_tier_rate(2);
-- Returns: 100 (1.0% = 100 bps for 2nd deal)
```

### Calculate Commission for a Contribution

```sql
SELECT
  c.id,
  i.name as investor,
  d.name as deal,
  c.amount,
  get_investor_deal_sequence(c.investor_id, c.deal_id) as deal_number,
  get_commission_tier_rate(
    get_investor_deal_sequence(c.investor_id, c.deal_id)
  ) as rate_bps,
  c.amount * get_commission_tier_rate(
    get_investor_deal_sequence(c.investor_id, c.deal_id)
  ) / 10000.0 as commission_amount
FROM contributions c
JOIN investors i ON i.id = c.investor_id
JOIN deals d ON d.id = c.deal_id
WHERE c.id = 12345;
```

### View Investor's Deal History

```sql
SELECT
  deal_name,
  participation_sequence as deal_number,
  tier_description,
  first_contribution_date,
  first_contribution_amount,
  tier_rate_bps
FROM deal_participation_with_tiers
WHERE investor_name = 'ABC Capital'
ORDER BY participation_sequence;
```

### Find Investors by Tier

```sql
-- First-time investors (Tier 1 - 1.5%)
SELECT investor_name, first_participation_date
FROM investor_participation_summary
WHERE total_deals = 1;

-- Investors at max tier (5 deals, last commission)
SELECT investor_name, total_deals, deal_sequence
FROM investor_participation_summary
WHERE total_deals = 5;

-- Investors beyond commission tiers (6+ deals)
SELECT investor_name, total_deals
FROM investor_participation_summary
WHERE total_deals >= 6;
```

## Integration with Commission System

### Option 1: Function-Based Calculation (Recommended)

```sql
-- When creating a commission record
INSERT INTO commissions (
  party_id,
  investor_id,
  contribution_id,
  deal_id,
  base_amount,
  snapshot_json
)
SELECT
  agreement.party_id,
  contrib.investor_id,
  contrib.id,
  contrib.deal_id,
  contrib.amount * get_commission_tier_rate(
    get_investor_deal_sequence(contrib.investor_id, contrib.deal_id)
  ) / 10000.0,
  jsonb_build_object(
    'participation_sequence', get_investor_deal_sequence(contrib.investor_id, contrib.deal_id),
    'tier_rate_bps', get_commission_tier_rate(get_investor_deal_sequence(contrib.investor_id, contrib.deal_id)),
    'tier_description', get_commission_tier_description(get_investor_deal_sequence(contrib.investor_id, contrib.deal_id)),
    'investor_total_deals', get_investor_deal_count(contrib.investor_id)
  )
FROM contributions contrib
JOIN agreements agreement ON agreement.deal_id = contrib.deal_id
WHERE contrib.id = ?;
```

### Option 2: Pre-Computed in Application Layer

```javascript
// TypeScript/JavaScript example
async function calculateCommission(contributionId: number) {
  const contribution = await getContribution(contributionId);

  // Get participation info
  const sequence = await db.query(
    'SELECT get_investor_deal_sequence($1, $2)',
    [contribution.investor_id, contribution.deal_id]
  );

  const tierRate = await db.query(
    'SELECT get_commission_tier_rate($1)',
    [sequence]
  );

  // Calculate commission
  const commissionAmount = contribution.amount * (tierRate / 10000);

  // Create commission record
  await createCommission({
    investor_id: contribution.investor_id,
    contribution_id: contributionId,
    base_amount: commissionAmount,
    snapshot_json: {
      participation_sequence: sequence,
      tier_rate_bps: tierRate,
      // ... other snapshot fields
    }
  });
}
```

## Automatic Participation Creation

New contributions automatically create participations via trigger:

```sql
-- Example: Insert new contribution
INSERT INTO contributions (
  investor_id,
  deal_id,
  paid_in_date,
  amount,
  currency
) VALUES (
  42,        -- investor_id
  100,       -- deal_id
  '2025-10-26',
  100000,
  'USD'
);

-- Trigger automatically creates:
-- investor_deal_participations record with:
--   - participation_sequence = (max existing sequence + 1)
--   - first_contribution_date = '2025-10-26'
--   - first_contribution_id = (new contribution id)
```

No manual intervention needed for ongoing operations!

## Validation and Monitoring

### Daily Health Check

```sql
-- Run these queries daily to ensure data integrity

-- 1. Check for sequence gaps (should return 0)
SELECT COUNT(*) as gaps
FROM (
  SELECT investor_id, MAX(participation_sequence) as max_seq, COUNT(*) as count
  FROM investor_deal_participations
  GROUP BY investor_id
  HAVING MAX(participation_sequence) != COUNT(*)
) subq;

-- 2. Check for duplicate participations (should return 0)
SELECT COUNT(*) as duplicates
FROM (
  SELECT investor_id, deal_id, COUNT(*)
  FROM investor_deal_participations
  GROUP BY investor_id, deal_id
  HAVING COUNT(*) > 1
) subq;

-- 3. Validate all sequences (should return 0)
SELECT COUNT(*) as invalid_sequences
FROM investors i
CROSS JOIN LATERAL validate_investor_participation_sequence(i.id) v
WHERE NOT v.is_valid;
```

All checks should return 0. If any return non-zero, investigate immediately.

## Common Queries

### Dashboard: Tier Distribution

```sql
SELECT
  tier_description,
  COUNT(*) as participations,
  COUNT(DISTINCT investor_id) as unique_investors,
  ROUND(AVG(first_contribution_amount), 2) as avg_contribution
FROM deal_participation_with_tiers
GROUP BY tier_description, tier_rate_bps
ORDER BY MIN(participation_sequence);
```

### Report: Investor Commission Summary

```sql
SELECT
  i.name as investor,
  COUNT(c.id) as total_contributions,
  SUM(c.amount) as total_contributed,
  SUM(
    c.amount * get_commission_tier_rate(
      get_investor_deal_sequence(c.investor_id, c.deal_id)
    ) / 10000.0
  ) as total_commissions_earned
FROM investors i
JOIN contributions c ON c.investor_id = i.id
WHERE c.deal_id IS NOT NULL
GROUP BY i.id, i.name
ORDER BY total_commissions_earned DESC;
```

### Analysis: Tier Transition Points

```sql
-- Investors who are one deal away from tier change
SELECT
  investor_name,
  total_deals,
  get_commission_tier_description(total_deals) as current_tier,
  get_commission_tier_description(total_deals + 1) as next_tier,
  deal_sequence
FROM investor_participation_summary
WHERE total_deals IN (1, 3, 5);  -- Tier boundaries
```

## Testing

Run comprehensive tests:

```bash
psql -h your-db-host -U your-user -d your-database \
  -f scripts/test_tiered_commission_calculations.sql
```

This runs 10 test sections covering:
- Basic tier testing
- Participation analysis
- Commission calculations
- Edge cases
- Data integrity validation
- Performance testing

## Troubleshooting

### Issue: Participation not created for new contribution

**Symptoms**: New contribution inserted but no participation record exists

**Check**:
```sql
SELECT tgname, tgenabled
FROM pg_trigger
WHERE tgname = 'trigger_auto_create_participation';
```

**Fix**:
```sql
-- Re-enable trigger if disabled
ALTER TABLE contributions ENABLE TRIGGER trigger_auto_create_participation;

-- Manually create participation
INSERT INTO investor_deal_participations (
  investor_id, deal_id, participation_sequence,
  first_contribution_date, first_contribution_id
)
VALUES (?, ?, ?, ?, ?);
```

### Issue: Sequence gaps detected

**Symptoms**: Validation shows gaps in participation_sequence

**Check**:
```sql
SELECT * FROM validate_investor_participation_sequence(investor_id);
```

**Fix**: Contact database administrator - manual correction required

### Issue: Incorrect commission rate applied

**Symptoms**: Commission calculated with wrong tier rate

**Check**:
```sql
-- Verify sequence for the contribution
SELECT
  get_investor_deal_sequence(investor_id, deal_id),
  get_commission_tier_rate(get_investor_deal_sequence(investor_id, deal_id))
FROM contributions
WHERE id = ?;
```

**Fix**: If sequence is correct but rate is wrong, check `get_commission_tier_rate()` function definition

## Performance Expectations

| Operation | Expected Time | Notes |
|-----------|---------------|-------|
| `get_investor_deal_count()` | <1ms | Single index lookup |
| `get_investor_deal_sequence()` | <1ms | Single index lookup |
| `investor_participation_summary` view | <50ms | For <10,000 investors |
| `deal_participation_with_tiers` view | <20ms | For <10,000 participations |
| Trigger on new contribution | <2ms | Single insert |
| Historical data initialization | ~1s per 1,000 contributions | One-time operation |

## Support

- **Documentation**: `docs/INVESTOR_DEAL_PARTICIPATION_TRACKING.md`
- **Design Rationale**: `docs/DESIGN_DECISION_INVESTOR_PARTICIPATION.md`
- **Migration SQL**: `supabase/migrations/20251026000001_investor_deal_participations.sql`
- **Init Script**: `scripts/initialize_investor_participations.sql`
- **Test Script**: `scripts/test_tiered_commission_calculations.sql`

## Next Steps

1. ✅ Apply migration
2. ✅ Initialize historical data
3. ✅ Verify installation
4. ⏳ Update commission calculation logic
5. ⏳ Test with new contributions
6. ⏳ Deploy to production
7. ⏳ Monitor for 1 week
8. ⏳ Document any issues/learnings

---

Last Updated: 2025-10-26
Version: 1.0.0
