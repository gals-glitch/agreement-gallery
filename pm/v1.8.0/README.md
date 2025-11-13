# v1.8.0 Project Management Hub

**Epic:** Investor Fee Workflow E2E
**Target Release:** Week of 2025-10-28
**Status:** READY FOR IMPLEMENTATION
**PM Owner:** orchestrator-pm

---

## Quick Links

| Document | Purpose | Status |
|----------|---------|--------|
| [OP-01: Epic & Tickets](./OP-01-epic-tickets-dependencies.md) | Complete ticket board with 24 tickets, dependency graph, owner assignments | APPROVED |
| [OP-02: Feature Flags & Rollout](./OP-02-feature-flags-rollout.md) | Feature flag configuration, 4-phase rollout plan, rollback procedures | APPROVED |
| [OP-03: DoD & Exit Criteria](./OP-03-dod-exit-criteria-smoke-tests.md) | Definition of Done, 30 exit criteria, 8 smoke tests | APPROVED |
| [OP-04: Daily Status & Risk Log](./OP-04-daily-status-risk-log-release-checklist.md) | Daily status template, 15 risks, release checklist | APPROVED |
| [OP-05: Staging Data Seed](./OP-05-staging-data-seed.md) | SQL seed script, reset script, validation queries | APPROVED |

---

## Project Overview

### Scope

**v1.8.0** delivers end-to-end investor fee workflow:

- **Backend:** Charge computation, submit with FIFO credits, approve/reject/mark-paid workflows, dual-auth
- **CSV Integration:** Batch compute, contribution hooks, referrer fuzzy matching
- **Frontend:** Charges list (4 tabs), charge detail (accordion), navigation
- **Testing:** OpenAPI validation, FIFO contract tests, E2E workflows, RLS security
- **Documentation:** README, deployment guide, changelog, UAT checklist
- **Database:** Unique indexes, FK alignment, RLS policies, SEC DEF helpers
- **Reports:** Saved queries, CSV exports
- **Agreements:** Snapshot verification, health checks

### Success Metrics

- **Performance:** <2s list load, <1s detail load, <30s batch compute (500 items)
- **Quality:** 8/8 smoke tests passing, zero critical bugs
- **Accuracy:** 95% referrer auto-link accuracy, 100% FIFO credit correctness
- **Adoption:** Pilot users complete full workflow, finance team approval

---

## Ticket Summary

**Total:** 24 tickets across 10 teams

| Team | Tickets | Size (SP) | Key Deliverables |
|------|---------|-----------|------------------|
| transaction-credit-ledger | 3 | 12 | Submit, approve/reject/mark-paid, dual-auth |
| vantage-csv-integrator | 3 | 10 | Batch compute, contribution hook, CSV referrer |
| investor-source-linker | 2 | 11 | Fuzzy resolver, review queue |
| frontend-ui-ux-architect | 3 | 11 | List view, detail view, navigation |
| qa-test-openapi-validator | 4 | 13 | OpenAPI, FIFO tests, E2E, security |
| docs-change-control | 4 | 7 | README, deployment guide, changelog, UAT |
| postgres-schema-architect | 4 | 6 | Unique index, FK, RLS, SEC DEF |
| dashboard-reports-builder | 2 | 4 | Saved queries, CSV export |
| agreement-docs-repository | 2 | 3 | Snapshot verify, health check |
| orchestrator-pm | 1 | - | Epic & coordination |

**Total Story Points:** 77

---

## Critical Path

```
DB-01/DB-02 → T01 → T02 → T04
              ↓
         UI-01 → UI-02 → QA-03 → DOC-04
```

**Estimated Duration:** 3 weeks (assuming full-time dedication)

**Key Milestones:**
- Week 1: Backend complete (T01, T02, T04), DB work done
- Week 2: Frontend complete (UI-01, UI-02, UI-03), QA started
- Week 3: QA complete, docs finalized, pilot deployment

---

## Rollout Plan

### Phase 1 - Pilot (Week 1)
- **Who:** Admin only (1 user)
- **Flags:** charges_engine, charges_ui (admin)
- **Goal:** Validate core workflows, 8/8 smoke tests pass
- **Decision:** GO/NO-GO to finance team

### Phase 2 - Finance Team (Week 2)
- **Who:** Finance role (3-5 users)
- **Flags:** charges_engine, charges_ui (finance + admin)
- **Goal:** Validate with real data, <5% error rate
- **Decision:** GO/NO-GO to broader org

### Phase 3 - Broader Org (Week 3)
- **Who:** Ops, Manager roles (read-only)
- **Flags:** charges_ui (finance + ops + manager + admin)
- **Goal:** Enable visibility, verify RBAC
- **Decision:** GO/NO-GO to fuzzy match experimental

### Phase 4 - Fuzzy Match Experimental (Week 4)
- **Who:** Admin only (fuzzy matching)
- **Flags:** referrer_fuzzy (admin)
- **Goal:** Validate 95%+ auto-link accuracy
- **Decision:** ENABLE for all / ITERATE / DISABLE

---

## Risk Management

**Top 5 Critical/High Risks:**

1. **R1 (Critical):** Credit reversal edge cases
   - Mitigation: Comprehensive tests, 2+ code reviewers
   - Owner: transaction-credit-ledger

2. **R6 (Medium):** FIFO credit application bugs
   - Mitigation: Unit tests, integration tests, contract tests
   - Owner: transaction-credit-ledger

3. **R7 (Medium):** Dual-auth bypass
   - Mitigation: Security tests, monitoring alerts
   - Owner: qa-test-openapi-validator

4. **R8 (Medium):** Database migration failures
   - Mitigation: Test in staging first, rollback script ready
   - Owner: postgres-schema-architect

5. **R11 (Medium):** RLS policy gaps
   - Mitigation: Comprehensive tests, security audit
   - Owner: postgres-schema-architect

**See:** [OP-04: Risk Log](./OP-04-daily-status-risk-log-release-checklist.md#risk-log) for all 15 risks

---

## Exit Criteria Checklist

**Status:** 0/30 criteria met

| Category | Total | Met | Status |
|----------|-------|-----|--------|
| Functional | 9 | 0 | NOT STARTED |
| Technical | 6 | 0 | NOT STARTED |
| Quality | 5 | 0 | NOT STARTED |
| Documentation | 4 | 0 | NOT STARTED |
| Deployment | 4 | 0 | NOT STARTED |
| Pilot | 2 | 0 | NOT STARTED |

**Release Decision:** NO-GO (must meet all 30 criteria)

**See:** [OP-03: Exit Criteria](./OP-03-dod-exit-criteria-smoke-tests.md#v180-exit-criteria) for full checklist

---

## Smoke Tests

**Status:** 0/8 passing

1. CSV import with referrer → charges created, fuzzy matching works
2. Charge submit with credits → FIFO applied, balances correct
3. Charge submit without credits → net=gross
4. Approve workflow → status transition, audit trail
5. Reject workflow → credit reversal, balances restored
6. Mark paid workflow → status transition, payment reference
7. Charges list UI → tabs, filters, inline actions
8. Charge detail UI → accordion, workflow buttons

**See:** [OP-03: Smoke Tests](./OP-03-dod-exit-criteria-smoke-tests.md#smoke-test-suite-8-tests) for detailed test cases

---

## Daily Operations

### Daily Standup Format

- **What shipped yesterday:** [Ticket IDs closed]
- **What's shipping today:** [Ticket IDs in progress]
- **Blockers:** [List blockers, owners, ETAs]

**Daily Status Reports:** Store in `pm/v1.8.0/daily-status/YYYY-MM-DD.md`

**Template:** [OP-04: Daily Status Template](./OP-04-daily-status-risk-log-release-checklist.md#daily-status-template)

### Weekly Reviews

- **Monday:** Sprint planning, prioritize top 3 tickets
- **Wednesday:** Mid-sprint check-in, risk review
- **Friday:** Sprint review, update exit criteria progress

---

## Release Checklist

### Pre-Cut (Day -3)
- [ ] All 24 tickets closed (DoD met)
- [ ] 8/8 smoke tests passing in staging
- [ ] Code freeze announced

### Cut Day (Day 0)
- [ ] Final smoke tests (8/8 pass)
- [ ] Feature flags configured (pilot)
- [ ] Stakeholder approval

### Deployment (Day 0)
- [ ] Database migration applied
- [ ] Edge Functions deployed
- [ ] Health checks passing
- [ ] Smoke tests passing in production (8/8)

### Post-Deploy (Day +1)
- [ ] Pilot users complete 1 full workflow
- [ ] Error rate <5%
- [ ] No critical bugs (P0/P1)

**See:** [OP-04: Release Checklist](./OP-04-daily-status-risk-log-release-checklist.md#release-cut-checklist) for full procedure

---

## Staging Environment

### Seed Data

**Entities:** 5 investors, 1 distributor, 5 agreements, 6 contributions, 3 credits, 6 charges

**Seed Script:** `pm/v1.8.0/staging-seed.sql`

**Validation Queries:** `pm/v1.8.0/staging-validation.sql`

**Reset Script:** `pm/v1.8.0/staging-reset.sql`

**See:** [OP-05: Staging Data Seed](./OP-05-staging-data-seed.md) for SQL scripts

### Test Scenarios

1. FIFO credit application (oldest first)
2. Multiple credits FIFO ordering
3. Scope matching (fund↔fund, deal↔deal)
4. Credit reversal on reject
5. Referrer fuzzy matching (exact, fuzzy, review queue)

---

## Communication Plan

### Stakeholder Updates

- **Weekly:** Email with progress summary, risks, ETA
- **Blockers:** Immediate Slack notification to stakeholder
- **Release:** Announcement with release notes, rollout plan

### Team Coordination

- **Daily:** Standup in Slack (async)
- **Blockers:** Tag relevant teams immediately
- **Cross-team dependencies:** Coordinate handoffs in advance

### User Communication

- **Pilot Phase:** Direct message to admin users with UAT checklist
- **Finance Team:** Training session, documentation links
- **Broader Org:** Release notes, feature announcement

---

## Rollback Procedures

### Instant Rollback (0 seconds downtime)
1. Disable feature flags: `charges_engine`, `charges_ui`, `referrer_fuzzy`
2. Verify: Charges menu hidden, existing data viewable (read-only)

### Full Rollback (5-15 minutes downtime)
1. Instant rollback (disable flags)
2. Revert Edge Function deployment to v1.7.0
3. Rollback database migrations (if applied)
4. Verify: v1.7.0 smoke tests pass

**Triggers:**
- Error rate >5% for 10 min → instant rollback
- Error rate >10% for 5 min → full rollback
- Credit calculation errors → full rollback immediately
- RLS violations → full rollback immediately

**See:** [OP-02: Rollback Procedures](./OP-02-feature-flags-rollout.md#rollback-procedures) for details

---

## Escalation Path

### Blocker Escalation

1. **Team Level:** Agent resolves within team (same day)
2. **Cross-Team:** orchestrator-pm coordinates (within 24h)
3. **Stakeholder:** orchestrator-pm escalates to stakeholder (within 48h)

### Bug Escalation

- **P0 (Critical):** Immediate escalation to orchestrator-pm + stakeholder, full rollback
- **P1 (High):** Same-day escalation to orchestrator-pm, consider rollback
- **P2 (Medium):** Add to backlog, fix in next sprint
- **P3 (Low):** Add to backlog, prioritize by impact

---

## Definition of Done (Reminder)

All tickets must meet 10 criteria:

1. Code complete (all ACs met)
2. Tests passing (≥80% coverage)
3. Documentation (API changes documented)
4. RBAC verified (403 for unauthorized)
5. Performance acceptable (<2s queries)
6. Audit trail complete (all transitions logged)
7. Feature flag ready (enabled/disabled states tested)
8. Error handling (correct status codes)
9. Security (no secrets, no SQL injection)
10. Deployment ready (tested in staging)

**See:** [OP-03: Definition of Done](./OP-03-dod-exit-criteria-smoke-tests.md#ticket-level-definition-of-done-dod) for full checklist

---

## Next Actions (Start Immediately)

### DB Team (postgres-schema-architect)
- [ ] Start DB-01 (unique index)
- [ ] Start DB-02 (FK alignment)
- [ ] Start DB-03 (RLS verification)
- [ ] Start DB-04 (SEC DEF helpers)

**Rationale:** Foundational work, blocks backend T01

### PM (orchestrator-pm)
- [ ] Complete OP-02 verification (feature flags configured)
- [ ] Schedule kickoff meeting (all teams)
- [ ] Set up daily status tracking (Slack channel or dashboard)

**Rationale:** Coordination infrastructure, unblocks DOC-02

### Agreements Team (agreement-docs-repository)
- [ ] Start AGR-01 (snapshot verification)
- [ ] Start AGR-02 (health check)

**Rationale:** Parallel track, no dependencies

### Linker Team (investor-source-linker)
- [ ] Start T07 (fuzzy resolver)

**Rationale:** Parallel track, blocks T08 and T09

### All Other Teams
- [ ] Review assigned tickets in OP-01
- [ ] Understand acceptance criteria and DoD
- [ ] Wait for dependencies to complete before starting

**Rationale:** Avoid premature work, respect dependency graph

---

## Project Status Dashboard

**Current Sprint:** Week 0 (Planning)
**Next Sprint:** Week 1 (Implementation starts)

### Velocity (Projected)

- **Team Capacity:** 8 teams × 40 hrs/week = 320 hrs/week
- **Story Points:** 77 total
- **Estimated Duration:** 3 weeks (assuming velocity ~25 SP/week)

### Burndown (Projected)

| Week | SP Remaining | Tickets Remaining | On Track? |
|------|--------------|-------------------|-----------|
| Week 0 | 77 | 24 | - |
| Week 1 | ~52 | ~16 | TBD |
| Week 2 | ~27 | ~8 | TBD |
| Week 3 | ~0 | ~0 | TBD |

**Note:** Actual burndown tracked in daily status reports

---

## Success Criteria Summary

**Release is GO when:**
- [x] All 24 tickets closed (DoD met)
- [x] 30/30 exit criteria met
- [x] 8/8 smoke tests passing in production
- [x] Pilot users complete full workflow (no critical bugs)
- [x] Finance team approves (ready for broader rollout)
- [x] Error rate <5%, performance SLAs met

**Current Status:** NOT READY (0/6 criteria met)

---

## Document Control

**Document Owner:** orchestrator-pm
**Last Updated:** 2025-10-21
**Next Review:** Daily during implementation
**Version:** 1.0

**Change Log:**
- 2025-10-21: Initial PM infrastructure setup (OP-01 through OP-05)

---

## Support & Questions

**PM Questions:** Contact orchestrator-pm via Slack
**Technical Questions:** Contact relevant team lead (see ticket owner in OP-01)
**Escalations:** Use escalation path above

---

**Ready to begin implementation. All teams proceed to assigned tickets per dependency graph in OP-01.**
