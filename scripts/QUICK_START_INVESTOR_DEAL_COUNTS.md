# Quick Start: Investor Deal Counts Initialization

**For:** Database Administrators & Schema Agents
**Time Required:** 1-2 hours
**Last Updated:** 2025-10-26

---

## What This Does

Populates investor deal participation history from transaction data to enable tiered commission calculations based on whether an investor is making their 1st, 2nd, 3rd, etc. investment.

---

## Prerequisites Checklist

- [ ] `investors` table exists and populated
- [ ] `deals` table exists and populated
- [ ] `funds` table exists and populated
- [ ] `transactions` table exists with historical data
- [ ] `investor_deal_participations` table created (see schema spec)
- [ ] User has finance or admin role
- [ ] Backup created (if running in production)

---

## 5-Step Process

### Step 1: Analyze Data (15 min)

Run Sections 1-3 of `initialize_investor_deal_counts.sql`

**Key Questions:**
- Are there ~110 unique investors? ✓
- Do sequences look continuous (1, 2, 3...)? ✓
- Are dates in chronological order? ✓
- Any red flags in the data? ✗

### Step 2: Create Table (5 min)

Use migration template from `docs/INVESTOR_DEAL_PARTICIPATIONS_SCHEMA.md`

```sql
-- Quick verify:
SELECT COUNT(*) FROM investor_deal_participations; -- Should be 0
```

### Step 3: Execute INSERT (5 min)

Uncomment and run Section 4 of `initialize_investor_deal_counts.sql`

```sql
TRUNCATE TABLE investor_deal_participations RESTART IDENTITY CASCADE;
-- Then run the INSERT statement
```

### Step 4: Verify (15 min)

Run Section 5 verification queries. ALL must pass:

- [ ] Participation counts match
- [ ] Sequences are continuous
- [ ] All start at sequence 1
- [ ] No duplicates
- [ ] Dates in chronological order

**If ANY fail: STOP and investigate before proceeding**

### Step 5: Report (10 min)

Run Section 6 summary queries and share with stakeholders:

- Total investors and participations
- Distribution by deal count
- Top investors by activity
- Retention analysis

---

## Expected Results

- **Rows:** 500-2,000 participation records
- **Time:** < 1 second for INSERT
- **Distribution:**
  - 100% of investors have 1st deal
  - 60-80% have 2nd deal
  - 40-60% have 3rd deal
  - 5-15% have 6+ deals

---

## Common Issues

| Issue | Quick Fix |
|-------|-----------|
| Wrong investor count | Check Query 1.2 - may have investors without transactions |
| Sequence gaps | Review Query 5.2 details - likely data quality issue |
| Constraint violations | Run orphaned reference checks in troubleshooting section |
| Slow performance | Add indexes to transactions table (see troubleshooting) |

---

## Files Reference

| File | Purpose |
|------|---------|
| `initialize_investor_deal_counts.sql` | Main script (7 sections) |
| `INVESTOR_DEAL_PARTICIPATIONS_SCHEMA.md` | Complete schema spec with migration |
| `INVESTOR_DEAL_COUNTS_README.md` | Full documentation (60+ pages) |
| This file | Quick reference (this document) |

---

## Critical Success Criteria

Before marking complete:

✅ All verification queries pass (Section 5)
✅ Summary report makes business sense (Section 6)
✅ Sample data validated by finance team (Section 7)
✅ No errors or warnings during execution

---

## Need Help?

1. **Data issues?** → See Troubleshooting in `INVESTOR_DEAL_COUNTS_README.md`
2. **Schema questions?** → See `INVESTOR_DEAL_PARTICIPATIONS_SCHEMA.md`
3. **Business logic?** → Review Section 2-3 analysis queries
4. **Performance?** → Check indexes section in README

---

## After Initialization

### Ongoing Maintenance

**New transactions:** Use incremental update query (see README Maintenance section)

**Bulk imports:** Re-run entire script from Step 1

**Data corrections:** TRUNCATE and re-run INSERT (maintains integrity)

### Integration

The participation data can now be used for:
- Tiered commission calculations
- Early bird discount eligibility
- Investor retention analysis
- Cohort performance tracking

---

## One-Line Summary

> Analyzes transaction history → Assigns chronological sequence numbers → Populates participation tracking table → Verifies data integrity → Enables tiered commission calculations

---

**Ready to start?** → Open `initialize_investor_deal_counts.sql` and run Section 1
