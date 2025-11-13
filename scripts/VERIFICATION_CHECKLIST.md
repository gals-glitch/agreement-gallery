# Investor Deal Counts - Verification Checklist

**Script:** `initialize_investor_deal_counts.sql`
**Date:** 2025-10-26
**Purpose:** Ensure initialization is complete and data is accurate

---

## Pre-Execution Checks

### Prerequisites

- [ ] `investors` table exists and has ~110 records
- [ ] `deals` table exists and is populated
- [ ] `funds` table exists and is populated
- [ ] `transactions` table exists with historical data
- [ ] `investor_deal_participations` table created via migration
- [ ] User has SELECT access to all source tables
- [ ] User has INSERT access to `investor_deal_participations`
- [ ] User has `finance` or `admin` role assigned

### Data Quality

- [ ] All transactions have valid `investor_id` (no NULLs)
- [ ] All transactions have either `deal_id` OR `fund_id` (XOR)
- [ ] Transaction dates are accurate and complete
- [ ] Transaction types are set ('CONTRIBUTION' vs 'REPURCHASE')

---

## Execution Phase Checks

### Section 1: Data Discovery (REQUIRED)

Run all 3 queries and verify:

- [ ] Query 1.1: Transaction count is reasonable (not 0, not millions)
- [ ] Query 1.1: Earliest/latest dates match expected timeframe
- [ ] Query 1.1: Contribution/repurchase split makes sense
- [ ] Query 1.2: Total investors is ~110 (or documented variance)
- [ ] Query 1.2: Most investors have transactions
- [ ] Query 1.3: Distribution looks reasonable (not all 1 transaction)

**Red flags:**
- ❌ 0 transactions or 0 investors
- ❌ Huge number of investors without transactions
- ❌ All investors have exactly 1 transaction
- ❌ Dates are in the future or before 2000

### Section 2: Participation Analysis (REQUIRED)

Run all 3 queries and verify:

- [ ] Query 2.1: Unique participations list looks correct
- [ ] Query 2.1: First transaction dates are in chronological order
- [ ] Query 2.2: Participation distribution makes sense
- [ ] Query 2.2: Some investors have multiple deals
- [ ] Query 2.3: Top investors list matches expectations

**Red flags:**
- ❌ All investors have exactly 1 participation
- ❌ Dates are out of order
- ❌ Unexpected investors in top 20
- ❌ Transaction amounts are $0 or negative

### Section 3: Sequence Assignment (REQUIRED)

Run both queries and verify:

- [ ] Query 3.1: Sequences start at 1 for each investor
- [ ] Query 3.1: Sequences are continuous (1, 2, 3, ...)
- [ ] Query 3.1: Dates are in chronological order within investor
- [ ] Query 3.2: Tie-breaking logic is consistent
- [ ] Preview data matches expectations

**Red flags:**
- ❌ Sequences start at 0 or negative
- ❌ Sequences have gaps (1, 2, 4, 5)
- ❌ Dates go backwards within investor
- ❌ Tie-breaking seems random

### Section 4: INSERT Execution (CRITICAL)

Before uncommenting INSERT:

- [ ] All Section 1-3 checks passed
- [ ] Preview data looks correct (Query 4.1)
- [ ] Target table is empty or ready to be truncated
- [ ] Backup created (if in production)
- [ ] Stakeholders notified

Execute INSERT:

- [ ] TRUNCATE completed successfully
- [ ] INSERT completed without errors
- [ ] Row count matches expected participations
- [ ] No constraint violations reported
- [ ] Execution time was reasonable (< 1 second expected)

**Critical errors (STOP if any occur):**
- ❌ Foreign key constraint violation
- ❌ Unique constraint violation
- ❌ Check constraint violation
- ❌ Out of memory errors
- ❌ Deadlock or lock timeout

---

## Post-Execution Verification (MANDATORY)

### Section 5: Integrity Checks

All 5 queries MUST pass:

#### Query 5.1: Participation Count Verification
- [ ] ✅ Counts match between transactions and participations
- [ ] ✅ Unique investors match
- [ ] ✅ Total participations are reasonable

**If FAIL:**
- Stop immediately
- Review count discrepancies
- Check for orphaned records
- Investigate data corruption

#### Query 5.2: Sequence Continuity Check
- [ ] ✅ Result: "PASS: All sequences are continuous"
- [ ] ✅ No gaps reported
- [ ] ✅ All investors have 1, 2, 3... with no skips

**If FAIL:**
- Stop immediately
- Review gap details
- Check window function logic
- May need to re-run INSERT

#### Query 5.3: First Participation Check
- [ ] ✅ Result: "PASS: All investors start at sequence 1"
- [ ] ✅ No investors starting at 0 or 2+

**If FAIL:**
- Stop immediately
- Critical logic error
- Must fix and re-run

#### Query 5.4: Duplicate Check
- [ ] ✅ Result: "PASS: No duplicates found"
- [ ] ✅ No duplicate investor-deal pairs

**If FAIL:**
- Stop immediately
- Review duplicate details
- Check unique constraint
- May indicate source data issues

#### Query 5.5: Chronological Order Check
- [ ] ✅ Result: "PASS: All dates in chronological order"
- [ ] ✅ No out-of-order dates within investors

**If FAIL:**
- Stop immediately
- Review date anomalies
- Check source transaction dates
- May need data correction

### MANDATORY: All 5 Checks Must Pass

**If ANY verification fails:**
1. ✋ STOP - Do not proceed
2. 📋 Document which check failed
3. 🔍 Investigate root cause
4. 🔧 Fix source data or logic
5. 🔄 TRUNCATE and re-run INSERT
6. ✅ Re-verify until all pass

---

## Business Validation (REQUIRED)

### Section 6: Summary Report

Review all 6 summary queries:

#### Query 6.1: Overall Summary
- [ ] Total investors matches expectations (~110)
- [ ] Total participations is reasonable (500-2,000)
- [ ] Average participation sequence makes sense (3-10)
- [ ] Date range covers expected timeframe

#### Query 6.2: Participation Distribution
- [ ] 100% of investors have 1st deal
- [ ] 60-80% have 2nd deal (typical retention)
- [ ] 40-60% have 3rd deal
- [ ] Distribution curve is logical

#### Query 6.3: Top Investors
- [ ] Top 25 list contains known active investors
- [ ] Deal counts are believable (not 100+ for individual)
- [ ] Investment periods make sense
- [ ] No suspicious outliers

#### Query 6.4: Monthly Trends
- [ ] Participation volume trends make sense
- [ ] Repeat investor percentage is stable or growing
- [ ] No huge unexplained spikes or drops

#### Query 6.5: Retention Analysis
- [ ] Cohort retention rates are reasonable
- [ ] Older cohorts have lower retention (expected)
- [ ] Average deals per cohort is logical

#### Query 6.6: (If applicable)
- [ ] Any custom business metrics are correct

### Section 7: Sample Data Validation

- [ ] Random sample generated (5 investors)
- [ ] Sample data reviewed manually
- [ ] Sequences match expected chronology
- [ ] Dates align with known transaction history
- [ ] Sample shared with finance team for review
- [ ] Finance team approved sample data

---

## Stakeholder Sign-Off

### Finance Team Review

- [ ] Summary report reviewed by finance manager
- [ ] Key metrics discussed and validated
- [ ] Sample data spot-checked against records
- [ ] Any discrepancies investigated and resolved
- [ ] Finance team approves for production use

**Sign-off:**
- Name: _______________________
- Role: _______________________
- Date: _______________________
- Signature: ___________________

### Technical Team Review

- [ ] Database administrator verified schema
- [ ] All verification queries passed
- [ ] Performance is acceptable
- [ ] Documentation is complete
- [ ] Maintenance procedures are clear

**Sign-off:**
- Name: _______________________
- Role: _______________________
- Date: _______________________
- Signature: ___________________

### Business Owner Approval

- [ ] Business requirements met
- [ ] Data accuracy confirmed
- [ ] Ready for integration with commission system
- [ ] Approved for production deployment

**Sign-off:**
- Name: _______________________
- Role: _______________________
- Date: _______________________
- Signature: ___________________

---

## Post-Deployment Checklist

### Immediate (Day 1)

- [ ] Monitor query performance
- [ ] Check for any user-reported issues
- [ ] Verify integration with commission calculations
- [ ] Document any anomalies or edge cases

### Short-term (Week 1)

- [ ] Re-run verification queries (Section 5)
- [ ] Generate updated summary report (Section 6)
- [ ] Review with stakeholders
- [ ] Address any concerns or questions

### Medium-term (Month 1)

- [ ] Analyze usage patterns
- [ ] Optimize indexes if needed
- [ ] Update documentation based on learnings
- [ ] Train additional users if needed

### Long-term (Ongoing)

- [ ] Schedule quarterly verification runs
- [ ] Monitor data growth and performance
- [ ] Update business logic if requirements change
- [ ] Maintain documentation

---

## Acceptance Criteria

All items below MUST be checked before marking complete:

### Data Integrity ✅
- [ ] All 5 verification queries pass (Section 5)
- [ ] No errors during INSERT execution
- [ ] Row count matches expected participations
- [ ] Sample data validated by stakeholders

### Business Logic ✅
- [ ] Sequences are chronological (1st, 2nd, 3rd...)
- [ ] Multiple transactions to same deal = ONE participation
- [ ] Tie-breaking logic works correctly
- [ ] All 110 investors accounted for

### Performance ✅
- [ ] Analysis queries run in < 2 seconds
- [ ] INSERT completes in < 1 second
- [ ] Verification queries run in < 1 second
- [ ] No performance degradation reported

### Documentation ✅
- [ ] All deliverable files created and reviewed
- [ ] Usage instructions are clear
- [ ] Troubleshooting guide is comprehensive
- [ ] Examples and queries are correct

### Stakeholder Approval ✅
- [ ] Finance team signed off
- [ ] Technical team signed off
- [ ] Business owner approved
- [ ] Ready for production use

---

## Final Sign-Off

**Project:** Investor Deal Counts Initialization
**Status:** [ ] Complete and Approved

**Completion Date:** _______________________

**Approved By:**

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Finance Manager | __________ | __________ | __________ |
| Database Administrator | __________ | __________ | __________ |
| Technical Lead | __________ | __________ | __________ |
| Business Owner | __________ | __________ | __________ |

---

## Document Control

**Version:** 1.0
**Created:** 2025-10-26
**Last Updated:** 2025-10-26
**Status:** Active

**Change Log:**

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2025-10-26 | 1.0 | Claude Code | Initial checklist created |

---

## Notes & Comments

Use this section to document any issues, exceptions, or special circumstances encountered during initialization:

```
Date: ___________
Issue: _________________________________________________
Resolution: ____________________________________________
Approved by: ___________________________________________


Date: ___________
Issue: _________________________________________________
Resolution: ____________________________________________
Approved by: ___________________________________________


Date: ___________
Issue: _________________________________________________
Resolution: ____________________________________________
Approved by: ___________________________________________
```

---

**END OF CHECKLIST**

All boxes must be checked and all sign-offs obtained before marking initialization as complete.
