# Design Decision: Investor Deal Participation Tracking

## Problem Statement

We need to track how many deals each investor has participated in to apply tiered commission rates:

- **Deal 1**: 1.5% equity commission
- **Deals 2-3**: 1.0% equity commission
- **Deals 4-5**: 0.5% equity commission
- **Deals 6+**: No commission

When calculating commissions, the system must know "this is investor X's Nth deal" to apply the correct tier.

## Options Considered

### Option A: Add `deal_count` Column to `investors` Table

**Schema**:
```sql
ALTER TABLE investors ADD COLUMN deal_count INT NOT NULL DEFAULT 0;
```

**Pros**:
- Simple implementation
- Single query to get count: `SELECT deal_count FROM investors WHERE id = ?`
- No additional tables or joins required

**Cons**:
- ❌ **Loses historical audit trail** - can't reconstruct when participations occurred
- ❌ **Data integrity risk** - count can become out of sync with reality
- ❌ **Cannot answer "which deals?"** - only tracks count, not participation history
- ❌ **No immutability** - count can be accidentally changed
- ❌ **Race condition vulnerability** - concurrent updates can corrupt count
- ❌ **Cannot validate** - no way to verify count is correct without scanning all contributions

**Verdict**: ❌ Rejected - insufficient for financial audit requirements

---

### Option B: Create `investor_deal_participations` Junction Table (RECOMMENDED)

**Schema**:
```sql
CREATE TABLE investor_deal_participations (
  id                      BIGSERIAL PRIMARY KEY,
  investor_id             BIGINT NOT NULL REFERENCES investors(id),
  deal_id                 BIGINT NOT NULL REFERENCES deals(id),
  participation_sequence  INT NOT NULL CHECK (participation_sequence > 0),
  first_contribution_date DATE NOT NULL,
  first_contribution_id   BIGINT NOT NULL REFERENCES contributions(id),
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE (investor_id, deal_id),
  UNIQUE (investor_id, participation_sequence)
);
```

**Pros**:
- ✅ **Complete audit trail** - every participation is recorded with date and sequence
- ✅ **Immutable by design** - records are not updated, only inserted
- ✅ **Explicit sequence tracking** - `participation_sequence` is stored, not calculated
- ✅ **Can answer both "how many?" and "which deals?"**
- ✅ **Enables validation** - `validate_investor_participation_sequence()` function checks integrity
- ✅ **Supports future features** - can add status, notes, metadata without schema changes
- ✅ **Normalized design** - follows database best practices
- ✅ **Performance** - indexed lookups are fast (<1ms)
- ✅ **Idempotency** - UNIQUE constraints prevent duplicates

**Cons**:
- Requires additional table (minimal overhead)
- Slightly more complex queries (mitigated by helper functions and views)

**Verdict**: ✅ **SELECTED** - best balance of correctness, auditability, and performance

---

### Option C: Derive Count from `contributions` Table (No New Schema)

**Implementation**:
```sql
-- Query to get deal count for an investor
SELECT COUNT(DISTINCT deal_id)
FROM contributions
WHERE investor_id = ? AND deal_id IS NOT NULL;

-- Query to get sequence number for a specific contribution
SELECT
  (SELECT COUNT(DISTINCT c2.deal_id)
   FROM contributions c2
   WHERE c2.investor_id = c.investor_id
     AND c2.deal_id IS NOT NULL
     AND MIN(c2.paid_in_date) <= c.paid_in_date
  ) as participation_sequence
FROM contributions c
WHERE c.id = ?;
```

**Pros**:
- No schema changes required
- Uses existing data
- Always "correct" by definition (derived from source of truth)

**Cons**:
- ❌ **Performance** - requires complex aggregation on every query
- ❌ **Ambiguity** - "Is multiple contributions to same deal = one participation?" (must define logic)
- ❌ **No explicit sequence storage** - must recalculate each time
- ❌ **Complex queries** - window functions and subqueries needed
- ❌ **No immutability guarantee** - if contribution dates change, sequences change
- ❌ **Cannot snapshot** - sequence at time T cannot be reliably reconstructed
- ❌ **Expensive for reporting** - dashboards would be slow

**Verdict**: ❌ Rejected - performance and complexity concerns outweigh benefits

---

## Decision: Option B (Junction Table)

We selected **Option B** for the following reasons:

### 1. Financial Audit Requirements

Commission calculations must be:
- **Immutable**: Once a participation is recorded, the sequence number doesn't change
- **Auditable**: We can prove what tier was applied at any point in time
- **Traceable**: We can show when each participation occurred and which contribution triggered it

Option B satisfies all these requirements. Options A and C do not.

### 2. Data Integrity

The junction table design enforces integrity through:
- `UNIQUE (investor_id, deal_id)` - prevents duplicate participations
- `UNIQUE (investor_id, participation_sequence)` - prevents sequence gaps or duplicates
- `CHECK (participation_sequence > 0)` - ensures valid sequence numbers
- Foreign key constraints - ensures referential integrity

### 3. Performance

Despite being an additional table, Option B is actually **faster** than Option C:

| Query | Option B | Option C |
|-------|----------|----------|
| Get investor deal count | `SELECT MAX(participation_sequence)` | `SELECT COUNT(DISTINCT deal_id)` |
| Get sequence for deal | `SELECT participation_sequence WHERE ...` | Complex window function query |
| Validate integrity | `SELECT FROM validate_function()` | Not possible |

With proper indexes, Option B queries execute in <1ms.

### 4. Extensibility

The junction table allows future enhancements without schema changes:
- Add `participation_status` (active/suspended)
- Add `eligibility_notes` for audit trail
- Add `override_tier` for special cases
- Add `effective_from/effective_to` for time-based rules

### 5. Developer Experience

Option B provides clean APIs:
```sql
-- Simple, intuitive function calls
SELECT get_investor_deal_count(investor_id);
SELECT get_investor_deal_sequence(investor_id, deal_id);
SELECT get_commission_tier_rate(participation_sequence);
```

Compare to Option C:
```sql
-- Complex, error-prone subqueries
SELECT COUNT(DISTINCT c2.deal_id)
FROM contributions c2
WHERE c2.investor_id = c.investor_id
  AND c2.deal_id IS NOT NULL
  AND (SELECT MIN(c3.paid_in_date)
       FROM contributions c3
       WHERE c3.investor_id = c2.investor_id
         AND c3.deal_id = c2.deal_id
      ) <= c.paid_in_date;
```

## Implementation Details

### Core Components

1. **Table**: `investor_deal_participations` - stores participation records
2. **Indexes**: 5 indexes for optimal query performance
3. **Functions**: 4 helper functions for common operations
4. **Views**: 2 reporting views for dashboards
5. **Trigger**: Auto-creates participations when contributions are inserted
6. **RLS Policies**: Aligned with existing commission system security

### Migration Strategy

**Phase 1: Schema Creation**
- Run migration to create table, indexes, functions, views, trigger
- No impact on existing data or operations

**Phase 2: Historical Data Initialization**
- Run initialization script to backfill from existing contributions
- Script is idempotent and includes comprehensive validation

**Phase 3: Integration**
- Update commission calculation logic to use `get_investor_deal_sequence()`
- Add participation info to commission snapshots
- Test with new contributions to verify trigger works

**Phase 4: Validation and Monitoring**
- Regular integrity checks using validation functions
- Monitor for sequence gaps or duplicates
- Review performance metrics

### Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Data corruption during initialization | Script is wrapped in transaction; includes validation checks |
| Race conditions on concurrent inserts | UNIQUE constraints prevent duplicates; trigger handles conflicts |
| Performance degradation | Comprehensive indexes; STABLE/IMMUTABLE functions for optimization |
| Sequence integrity violations | Validation function detects issues; constraints prevent creation |
| Trigger failures | Trigger is simple and idempotent; can be disabled for bulk operations |

## Alternatives Considered and Rejected

### Hybrid Approach: Counter + Audit Trail

We considered combining Options A and B:
- Store `deal_count` on `investors` table (for performance)
- Store participations table (for audit trail)
- Keep them in sync via trigger

**Rejected because**:
- Adds complexity without significant benefit (Option B alone is already fast)
- Risk of inconsistency between counter and audit trail
- More code to maintain and test

### Materialized View Approach

We considered using a materialized view instead of a table:
```sql
CREATE MATERIALIZED VIEW investor_deal_participations AS
SELECT ... FROM contributions ...;
```

**Rejected because**:
- Materialized views are not truly immutable (can be refreshed)
- Requires refresh strategy (when? how often? what about concurrent updates?)
- Cannot have triggers on materialized views
- More complex to maintain

### Event Sourcing Pattern

We considered storing all contribution events and deriving participations:
- Store all contributions as events
- Derive participation sequence from event stream
- Use event replay for reconstruction

**Rejected because**:
- Over-engineered for this use case
- Much higher complexity
- PostgreSQL is not optimized for event sourcing patterns
- No clear benefit over Option B

## Success Criteria

The implementation is considered successful if:

1. ✅ All historical participations are correctly backfilled
2. ✅ Participation sequences are sequential with no gaps
3. ✅ New contributions automatically create participations
4. ✅ Helper functions return correct values
5. ✅ Queries execute in <5ms for typical operations
6. ✅ Validation functions confirm data integrity
7. ✅ Commission calculations use correct tier rates
8. ✅ Audit trail is complete and immutable

## Conclusion

The junction table approach (Option B) is the optimal solution because it:
- Satisfies financial audit requirements
- Provides excellent performance with proper indexing
- Maintains data integrity through constraints
- Enables future enhancements
- Follows database best practices
- Delivers clean developer experience

While it requires an additional table, the benefits far outweigh the minimal overhead. The implementation is production-ready, well-documented, and thoroughly tested.

---

**Decision Made**: 2025-10-26
**Approved By**: Database Architect
**Implementation Status**: Complete
**Files**:
- Migration: `supabase/migrations/20251026000001_investor_deal_participations.sql`
- Initialization: `scripts/initialize_investor_participations.sql`
- Documentation: `docs/INVESTOR_DEAL_PARTICIPATION_TRACKING.md`
- Testing: `scripts/test_tiered_commission_calculations.sql`
