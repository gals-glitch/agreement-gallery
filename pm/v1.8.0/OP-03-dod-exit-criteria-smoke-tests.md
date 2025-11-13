# OP-03: Definition of Done, Exit Criteria, and Smoke Tests

**Owner:** orchestrator-pm
**Status:** APPROVED
**Last Updated:** 2025-10-21

---

## Ticket-Level Definition of Done (DoD)

All tickets must meet these criteria before closing. No exceptions.

### 1. Code Complete

- [ ] All acceptance criteria explicitly met and checked off
- [ ] Code reviewed and approved by 1+ reviewer (different from author)
- [ ] No TODO or FIXME comments in production code (or documented in backlog)
- [ ] Code follows project style guide (linting passes)
- [ ] All console.log/debug statements removed (use proper logging)

### 2. Tests Passing

- [ ] Unit tests written for new code (≥80% coverage)
- [ ] Integration tests passing (if ticket involves multiple components)
- [ ] E2E tests passing (if ticket involves UI changes)
- [ ] No test regressions (all v1.7.0 tests still pass)
- [ ] Test coverage report generated and reviewed
- [ ] Edge cases tested (null inputs, boundary values, error conditions)

### 3. Documentation

- [ ] API changes documented in OpenAPI spec (if endpoints added/modified)
- [ ] Feature changes documented in README (if user-facing changes)
- [ ] Code comments added for complex logic (why, not what)
- [ ] Migration instructions provided (if schema changes)
- [ ] Inline JSDoc comments for public functions/classes

### 4. RBAC Verified

- [ ] Role-based access controls tested (finance, ops, admin roles)
- [ ] Unauthorized access returns 403 Forbidden
- [ ] Service role key bypass tested (where applicable)
- [ ] RLS policies verified (users only see authorized data)
- [ ] Audit trail includes user_id for all actions

### 5. Performance Acceptable

- [ ] No queries >2s (excluding batch operations)
- [ ] Batch operations meet SLA (500 items <30s)
- [ ] No N+1 queries introduced (verified with query logging)
- [ ] Database indexes added for new queries (if needed)
- [ ] Frontend bundle size impact <50KB (if UI changes)

### 6. Audit Trail Complete

- [ ] All state transitions create audit entries
- [ ] Audit entries include: action, user_id, timestamp, metadata
- [ ] Audit entries are immutable (no UPDATE/DELETE)
- [ ] Audit trail queryable for troubleshooting

### 7. Feature Flag Ready

- [ ] Feature guarded by appropriate flag (if new feature)
- [ ] Flag tested in enabled state (feature works)
- [ ] Flag tested in disabled state (graceful degradation)
- [ ] Flag documented in OP-02

### 8. Error Handling

- [ ] All error cases return correct status codes (403/404/409/422)
- [ ] Error responses use consistent JSON format: `{ error: { code, message } }`
- [ ] User-friendly error messages (no stack traces in production)
- [ ] Errors logged with sufficient context for debugging

### 9. Security

- [ ] No secrets committed to repository (env vars used)
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS prevention (input sanitization, output encoding)
- [ ] CSRF protection (if applicable)
- [ ] Sensitive data not logged (PII, passwords, tokens)

### 10. Deployment Ready

- [ ] Changes tested in staging environment
- [ ] Migration scripts tested (if database changes)
- [ ] Rollback procedure documented (if risky change)
- [ ] Feature flag configured (if applicable)
- [ ] Monitoring alerts configured (if critical feature)

---

## DoD Enforcement

**Ticket cannot be closed unless:**
1. Author confirms all DoD items checked
2. Reviewer confirms all DoD items checked
3. CI/CD pipeline passes (tests, linting, build)

**PM Review:** orchestrator-pm spot-checks 20% of tickets for DoD compliance. Violations result in ticket reopening and process review.

---

## v1.8.0 Exit Criteria

Release is GO when ALL criteria met. No partial releases.

### Functional Requirements (9 criteria)

1. **CSV Import with Referrer**
   - [ ] CSV import accepts "Referrer" column
   - [ ] Charges auto-created on contribution import (status=DRAFT)
   - [ ] Referrer fuzzy matching: ≥90% auto-link, 80-89% review queue, <80% no match
   - [ ] Tested with 50+ referrer names in staging

2. **Charge Submit with FIFO Credits**
   - [ ] Submit endpoint applies credits FIFO (oldest created_at first)
   - [ ] Scope-aware: fund↔fund, deal↔deal matching enforced
   - [ ] Credits applied correctly: available decreased, applied increased
   - [ ] Net amount = gross - credits_applied

3. **Approve Workflow**
   - [ ] Approve endpoint transitions PENDING → APPROVED
   - [ ] Dual-auth enforced (submitter cannot approve own charge)
   - [ ] Audit entry created: charge_approved, approver_id

4. **Reject Workflow**
   - [ ] Reject endpoint transitions PENDING → REJECTED
   - [ ] Credits reversed (available_amount restored)
   - [ ] Reversal_reason required and stored
   - [ ] Audit entry created: charge_rejected

5. **Mark-Paid Workflow**
   - [ ] Mark-paid endpoint transitions APPROVED → PAID
   - [ ] Payment_reference required and stored
   - [ ] Audit entry created: charge_paid

6. **Charges List View**
   - [ ] 4 tabs: Draft, Pending Approval, Approved, Paid
   - [ ] Tab counts accurate (real-time)
   - [ ] Filters: investor, date range, amount range
   - [ ] Inline submit action (draft → pending)
   - [ ] Load time <2s (with 100+ charges)

7. **Charge Detail View**
   - [ ] Accordion sections: Base, Discounts, VAT, Credits Applied, Net
   - [ ] Credits Applied shows FIFO order, amounts
   - [ ] Workflow buttons visible based on RBAC
   - [ ] Load time <1s

8. **RBAC Enforcement**
   - [ ] Finance: submit charges (403 on approve/reject/mark-paid)
   - [ ] Admin: all operations (submit, approve, reject, mark-paid)
   - [ ] Ops/Manager: read-only (view charges, no actions)
   - [ ] Service role: bypass dual-auth

9. **Referrer Review Queue**
   - [ ] Review queue shows ambiguous matches (80-89% confidence)
   - [ ] Admin can confirm or reject matches
   - [ ] Confirmed matches update contribution.introduced_by_party_id

### Technical Requirements (6 criteria)

10. **API Status Codes**
    - [ ] All endpoints return correct codes: 200/403/404/409/422
    - [ ] Error responses use consistent format: `{ error: { code, message } }`

11. **Idempotency**
    - [ ] Duplicate submissions return 409 Conflict (not 200)
    - [ ] No duplicate audit entries created
    - [ ] Concurrent submissions handled gracefully

12. **Credit FIFO Logic**
    - [ ] Credits applied in created_at ASC order (oldest first)
    - [ ] Partial credit application works (credit exceeds charge)
    - [ ] Scope matching verified (fund↔fund, deal↔deal)

13. **Credit Reversal Accuracy**
    - [ ] Reject restores exact credit amounts (no rounding errors)
    - [ ] Multiple credits reversed in correct order
    - [ ] Ledger integrity maintained (balance checks pass)

14. **Audit Trail Completeness**
    - [ ] All state transitions logged: submitted, approved, rejected, paid
    - [ ] Audit entries include: action, user_id, timestamp, metadata
    - [ ] Audit entries immutable (no updates/deletes)

15. **Performance SLAs**
    - [ ] Batch compute: 500 contributions <30s
    - [ ] Charge list: <2s load (100+ charges)
    - [ ] Charge detail: <1s load
    - [ ] Submit charge: <1s response
    - [ ] Approve/reject/mark-paid: <500ms response

### Quality Requirements (5 criteria)

16. **Smoke Tests**
    - [ ] 8/8 smoke tests passing (see smoke test suite below)
    - [ ] Smoke tests run in CI/CD pipeline
    - [ ] Smoke tests pass in staging and production

17. **No Regressions**
    - [ ] All v1.7.0 smoke tests still pass
    - [ ] Existing contribution workflows unaffected
    - [ ] Existing agreement workflows unaffected

18. **OpenAPI Contract Tests**
    - [ ] All new endpoints documented in OpenAPI spec
    - [ ] Contract tests validate request/response schemas
    - [ ] Status codes match spec

19. **E2E Tests**
    - [ ] Full workflow validated: CSV → compute → submit → approve → paid
    - [ ] UI tests pass: navigation, filters, actions
    - [ ] Tests run in CI/CD pipeline

20. **RLS Policy Matrix**
    - [ ] Charges table: users see only authorized party charges
    - [ ] Credits_ledger: users see only authorized party credits
    - [ ] Unauthorized access returns empty results (not 403)

### Documentation Requirements (4 criteria)

21. **README Updates**
    - [ ] New endpoints documented (8 endpoints)
    - [ ] Workflow diagram added (DRAFT → PENDING → APPROVED → PAID)
    - [ ] Code examples provided (curl or TypeScript)

22. **Deployment Guide**
    - [ ] Feature flags documented (4 flags)
    - [ ] Rollout plan documented (4 phases)
    - [ ] Rollback procedures documented

23. **CHANGELOG**
    - [ ] v1.8.0 entry added with release date
    - [ ] New features listed (charge workflows, referrer matching)
    - [ ] API changes listed (8 new endpoints)
    - [ ] Breaking changes listed (none expected)

24. **UAT Checklist**
    - [ ] 10-minute pilot runbook created
    - [ ] Expected results documented
    - [ ] Troubleshooting guide included

### Deployment Requirements (4 criteria)

25. **Staging Validation**
    - [ ] All features deployed to staging
    - [ ] Smoke tests pass in staging (8/8)
    - [ ] Pilot users test in staging (no critical bugs)

26. **Feature Flags Configured**
    - [ ] Flags set for pilot rollout (admin only)
    - [ ] Flags tested in enabled/disabled states
    - [ ] Flag monitoring dashboard configured

27. **Rollback Procedure Tested**
    - [ ] Instant rollback tested (disable flags)
    - [ ] Full rollback tested (revert Edge Function)
    - [ ] Database rollback tested (if schema changes)

28. **Support Team Trained**
    - [ ] Support team demo completed
    - [ ] Troubleshooting guide shared
    - [ ] Common errors and resolutions documented

### Pilot Validation (2 criteria)

29. **Pilot Workflow Complete**
    - [ ] Pilot users complete 1 full workflow: CSV → compute → submit → approve → paid
    - [ ] Pilot feedback collected and reviewed
    - [ ] Critical bugs fixed before finance team rollout

30. **No Critical Bugs**
    - [ ] Zero P0 bugs (data corruption, security)
    - [ ] Zero P1 bugs (feature broken, cannot proceed)
    - [ ] P2/P3 bugs documented in backlog (not blockers)

---

## Exit Criteria Scorecard

**Status:** 0/30 criteria met

| Category | Criteria | Met | Remaining |
|----------|----------|-----|-----------|
| Functional | 9 | 0 | 9 |
| Technical | 6 | 0 | 6 |
| Quality | 5 | 0 | 5 |
| Documentation | 4 | 0 | 4 |
| Deployment | 4 | 0 | 4 |
| Pilot | 2 | 0 | 2 |
| **TOTAL** | **30** | **0** | **30** |

**Release Decision:** NO-GO (0/30 criteria met)

---

## Smoke Test Suite (8 Tests)

All smoke tests must pass in staging before production deployment. Tests must be automated and run in CI/CD pipeline.

### Test 1: CSV Import with Referrer

**Objective:** Verify CSV import with "Referrer" column auto-computes charges and performs fuzzy matching.

**Preconditions:**
- 5 distributors in database:
  - "John Smith" (exact match test)
  - "Jane Doe" (fuzzy match test: 95% confidence)
  - "Bob Johnson" (fuzzy match test: 85% confidence - review queue)
  - "Alice Williams" (fuzzy match test: 70% confidence - no match)
  - "Test Distributor" (exact match test)

**Test Data (CSV):**
```csv
Investor,Agreement,Amount,Currency,Paid Date,Referrer
Investor A,Agreement 1,50000,USD,2025-10-01,John Smith
Investor B,Agreement 2,25000,USD,2025-10-05,jane doe
Investor C,Agreement 3,100000,USD,2025-10-10,Bob J.
Investor D,Agreement 4,250000,USD,2025-10-15,A. Williams
Investor E,Agreement 5,75000,USD,2025-10-20,Test Distributor
```

**Steps:**
1. Upload CSV via /import endpoint
2. Wait for import completion (check job status)
3. Query charges table: `SELECT * FROM charges WHERE status='DRAFT' ORDER BY id`
4. Query contributions: `SELECT id, introduced_by_party_id FROM contributions WHERE investor_name IN ('Investor A', 'Investor B', 'Investor C', 'Investor D', 'Investor E')`
5. Query referrer_review_queue: `SELECT * FROM referrer_review_queue WHERE status='PENDING'`

**Expected Results:**
- 5 charges created (status=DRAFT)
- Contribution A: introduced_by_party_id = [John Smith party_id] (exact match)
- Contribution B: introduced_by_party_id = [Jane Doe party_id] (fuzzy match ≥90%)
- Contribution C: introduced_by_party_id = NULL, review queue entry created (85% confidence)
- Contribution D: introduced_by_party_id = NULL, no review queue entry (<80% confidence)
- Contribution E: introduced_by_party_id = [Test Distributor party_id] (exact match)
- 1 entry in referrer_review_queue (Contribution C, suggested_party_id = [Bob Johnson party_id])

**Pass Criteria:**
- All 5 charges created
- 2 auto-linked (A, B, E)
- 1 review queue entry (C)
- 1 no match (D)

---

### Test 2: Charge Submit with Credits (FIFO)

**Objective:** Verify charge submission applies credits FIFO with correct calculations.

**Preconditions:**
- Create credit 1: $100 available, deal_id=1, created_at=2025-10-01
- Create credit 2: $50 available, deal_id=1, created_at=2025-10-10
- Create charge: $150 gross, deal_id=1, status=DRAFT

**Steps:**
1. POST /charges/:id/submit
2. Query charge: `SELECT * FROM charges WHERE id=:id`
3. Query credits_ledger: `SELECT * FROM credits_ledger WHERE deal_id=1 ORDER BY created_at`
4. Query audit_trail: `SELECT * FROM audit_trail WHERE charge_id=:id AND action='charge_submitted'`

**Expected Results:**
- Charge status: PENDING_APPROVAL
- Charge credits_applied: $150
- Charge net_amount: $0 ($150 gross - $150 credits)
- Credit 1: available=$0, applied=$100 (oldest, fully applied)
- Credit 2: available=$0, applied=$50 (newest, fully applied)
- Audit entry created: action=charge_submitted, metadata includes credits_applied=[$100, $50]

**Pass Criteria:**
- FIFO order respected (credit 1 applied before credit 2)
- Balances correct (credits exhausted, net=0)
- Audit trail complete

---

### Test 3: Charge Submit without Credits

**Objective:** Verify charge submission with no credits available.

**Preconditions:**
- Create charge: $200 gross, deal_id=2, status=DRAFT
- No credits available for deal_id=2

**Steps:**
1. POST /charges/:id/submit
2. Query charge: `SELECT * FROM charges WHERE id=:id`

**Expected Results:**
- Charge status: PENDING_APPROVAL
- Charge credits_applied: $0
- Charge net_amount: $200 (gross - 0 credits)

**Pass Criteria:**
- Submission succeeds even with no credits
- Net amount equals gross amount

---

### Test 4: Approve Workflow

**Objective:** Verify approve workflow transitions charge correctly.

**Preconditions:**
- Charge from Test 2 (status=PENDING_APPROVAL)
- User A submitted charge (from Test 2)
- User B (admin) will approve

**Steps:**
1. POST /charges/:id/approve (as User B)
2. Query charge: `SELECT * FROM charges WHERE id=:id`
3. Query audit_trail: `SELECT * FROM audit_trail WHERE charge_id=:id AND action='charge_approved'`

**Expected Results:**
- Charge status: APPROVED
- Audit entry: action=charge_approved, user_id=[User B id], approver_id=[User B id]

**Pass Criteria:**
- Status transition successful
- Audit trail includes approver_id

---

### Test 5: Reject Workflow with Credit Reversal

**Objective:** Verify reject workflow reverses applied credits.

**Preconditions:**
- Create credit: $50 available, deal_id=3, created_at=2025-10-01
- Create charge: $100 gross, deal_id=3, status=DRAFT
- Submit charge (applies $50 credit, net=$50)

**Steps:**
1. POST /charges/:id/reject with body: `{ reversal_reason: "Test rejection" }`
2. Query charge: `SELECT * FROM charges WHERE id=:id`
3. Query credits_ledger: `SELECT * FROM credits_ledger WHERE deal_id=3`
4. Query audit_trail: `SELECT * FROM audit_trail WHERE charge_id=:id AND action='charge_rejected'`

**Expected Results:**
- Charge status: REJECTED
- Credit available: $50 (restored from $0)
- Credit applied: $0 (reversed from $50)
- Audit entry: action=charge_rejected, reversal_reason="Test rejection"

**Pass Criteria:**
- Credit balance restored exactly (+$50)
- Audit trail includes reversal_reason

---

### Test 6: Mark Paid Workflow

**Objective:** Verify mark-paid workflow transitions charge correctly.

**Preconditions:**
- Charge from Test 4 (status=APPROVED)

**Steps:**
1. POST /charges/:id/mark-paid with body: `{ payment_reference: "WIRE-2025-001" }`
2. Query charge: `SELECT * FROM charges WHERE id=:id`
3. Query audit_trail: `SELECT * FROM audit_trail WHERE charge_id=:id AND action='charge_paid'`

**Expected Results:**
- Charge status: PAID
- Charge payment_reference: "WIRE-2025-001"
- Audit entry: action=charge_paid, payment_reference="WIRE-2025-001"

**Pass Criteria:**
- Status transition successful
- Payment reference stored

---

### Test 7: Charges List UI

**Objective:** Verify charges list page loads and filters work.

**Preconditions:**
- 10 charges in database:
  - 3 DRAFT
  - 2 PENDING_APPROVAL
  - 3 APPROVED
  - 2 PAID

**Steps:**
1. Navigate to /charges
2. Verify tabs show counts: Draft (3), Pending (2), Approved (3), Paid (2)
3. Click "Pending Approval" tab
4. Verify table shows 2 charges (status=PENDING_APPROVAL)
5. Filter by investor (select "Investor A")
6. Verify table shows only charges for Investor A
7. Click "Submit" on a DRAFT charge
8. Verify charge moves to "Pending Approval" tab

**Expected Results:**
- Page loads <2s
- Tab counts accurate
- Filters work (investor dropdown)
- Inline submit action works (status change)

**Pass Criteria:**
- All UI elements render correctly
- Performance acceptable (<2s load)
- Actions work (submit via inline button)

---

### Test 8: Charge Detail UI

**Objective:** Verify charge detail page shows accurate breakdown.

**Preconditions:**
- Charge from Test 2 (status=PENDING_APPROVAL, $150 gross, $150 credits applied, $0 net)

**Steps:**
1. Navigate to /charges/:id (charge from Test 2)
2. Verify header: Investor name, Agreement reference, Status badge (PENDING)
3. Expand "Base Amount" accordion section
   - Verify: paid_in_amount, upfront_bps, base calculation
4. Expand "VAT" accordion section
   - Verify: vat_rate, vat_amount
5. Expand "Credits Applied" accordion section
   - Verify: 2 credits listed (FIFO order), amounts ($100, $50), balances (both $0 available)
6. Verify "Net Amount" section: $0
7. Verify workflow buttons visible: "Approve" and "Reject" (admin user)
8. Click "Approve" button
9. Verify modal/confirmation, click confirm
10. Verify charge status changes to APPROVED

**Expected Results:**
- Page loads <1s
- All accordion sections render correctly
- Credits Applied shows FIFO order (credit 1 then credit 2)
- Workflow buttons visible (RBAC enforced)
- Approve action works (status change)

**Pass Criteria:**
- All sections accurate (amounts match database)
- Performance acceptable (<1s load)
- Workflow action works

---

## Smoke Test Automation

**Framework:** Playwright (E2E) + Jest (API/Integration)

**CI/CD Integration:**
```yaml
# .github/workflows/smoke-tests.yml
name: Smoke Tests

on:
  push:
    branches: [main, staging]
  pull_request:
    branches: [main]

jobs:
  smoke-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: 18
      - run: npm ci
      - run: npm run test:smoke
      - name: Upload test results
        if: failure()
        uses: actions/upload-artifact@v3
        with:
          name: smoke-test-results
          path: test-results/
```

**Run Locally:**
```bash
# Run all smoke tests
npm run test:smoke

# Run specific test
npm run test:smoke -- --grep "Test 2: Charge Submit with Credits"

# Run with UI (Playwright)
npm run test:smoke -- --headed
```

---

## DoD and Exit Criteria Sign-Off

**Sign-Off Required:**
- [ ] orchestrator-pm (PM verification)
- [ ] transaction-credit-ledger (backend verification)
- [ ] frontend-ui-ux-architect (UI verification)
- [ ] qa-test-openapi-validator (QA verification)
- [ ] postgres-schema-architect (DB verification)
- [ ] Stakeholder (business verification)

**Release Approval:** Requires ALL sign-offs + 30/30 exit criteria met.

---

**Document Status:** APPROVED
**Next Review:** Before each release candidate
**Escalation:** If any exit criteria fails, escalate to orchestrator-pm immediately
