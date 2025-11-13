# OP-02: Feature Flags and Rollout Plan

**Owner:** orchestrator-pm
**Status:** APPROVED
**Last Updated:** 2025-10-21

---

## Feature Flag Configuration

```json
{
  "charges_engine": {
    "enabled": true,
    "description": "Enable charge computation, submit, approve, reject, mark-paid workflows",
    "roles": ["finance", "ops", "admin"],
    "rollout_phase": "pilot",
    "endpoints": [
      "POST /charges/batch-compute",
      "POST /charges/:id/submit",
      "POST /charges/:id/approve",
      "POST /charges/:id/reject",
      "POST /charges/:id/mark-paid"
    ],
    "notes": "Core engine for charge lifecycle. Disable if critical bugs detected."
  },
  "charges_ui": {
    "enabled": true,
    "description": "Show Charges pages in navigation and enable workflow actions",
    "roles": ["finance", "admin"],
    "rollout_phase": "pilot",
    "ui_components": [
      "/charges (list view)",
      "/charges/:id (detail view)",
      "Navigation links",
      "Workflow action buttons"
    ],
    "notes": "Controls UI visibility. Users without this flag see no Charges menu item."
  },
  "referrer_fuzzy": {
    "enabled": false,
    "description": "Auto-link referrers using fuzzy matching during CSV import",
    "roles": ["admin"],
    "rollout_phase": "experimental",
    "notes": "Start DISABLED. Enable after pilot validation. Requires 95%+ accuracy to proceed to finance team."
  },
  "auto_compute_charges": {
    "enabled": true,
    "description": "Auto-compute charges when contributions are created/updated",
    "roles": ["all"],
    "rollout_phase": "active",
    "notes": "Enabled by default. Triggers charge creation on contribution import. Disable if performance issues."
  }
}
```

---

## Rollout Phases

### Phase 1 - Pilot (Week 1: Days 1-7)

**Objective:** Validate core workflows with admin user and test data.

**Configuration:**
```json
{
  "charges_engine": { "enabled": true, "roles": ["admin"] },
  "charges_ui": { "enabled": true, "roles": ["admin"] },
  "referrer_fuzzy": { "enabled": false },
  "auto_compute_charges": { "enabled": true, "roles": ["all"] }
}
```

**Participants:**
- 1 admin user (primary tester)
- 5 test investors in staging
- 1 distributor (referrer)
- 6 test contributions

**Activities:**
1. **Day 1:** Deploy to staging, enable flags for admin only
2. **Day 2-3:** Admin tests full workflow:
   - Upload CSV with "Referrer" column → verify charges created (status=DRAFT)
   - Submit charges → verify credits applied FIFO (status=PENDING_APPROVAL)
   - Approve charges → verify status=APPROVED
   - Reject charge → verify credit reversal (balance restored)
   - Mark paid → verify status=PAID
3. **Day 4-5:** Admin tests edge cases:
   - No credits available (net = gross)
   - Credits exceed charge amount (partial application)
   - Dual-auth enforcement (submit as admin, approve as different admin)
4. **Day 6-7:** Collect feedback, fix critical bugs, verify smoke tests (8/8 pass)

**Success Criteria:**
- 8/8 smoke tests passing
- Zero critical bugs (P0/P1)
- Admin confirms workflow "ready for finance team"
- Performance acceptable: list <2s, detail <1s, batch <30s

**Rollback Triggers:**
- Any smoke test fails
- Critical bug (data corruption, credit calculation errors)
- Performance degradation (>5s response times)

---

### Phase 2 - Finance Team (Week 2: Days 8-14)

**Objective:** Validate with real data and finance users.

**Configuration:**
```json
{
  "charges_engine": { "enabled": true, "roles": ["finance", "admin"] },
  "charges_ui": { "enabled": true, "roles": ["finance", "admin"] },
  "referrer_fuzzy": { "enabled": false },
  "auto_compute_charges": { "enabled": true, "roles": ["all"] }
}
```

**Participants:**
- 3-5 finance team users
- 10-20 real contributions (small batch)
- Real distributors (if available)

**Activities:**
1. **Day 8:** Enable flags for finance role in production
2. **Day 9-10:** Finance team tests workflows:
   - Import real CSV data (10-20 contributions)
   - Compute charges, review accuracy (base, VAT, credits)
   - Submit charges, verify credits applied correctly
   - Approve/reject workflows (admin approves finance submissions)
3. **Day 11-12:** Monitor production metrics:
   - Error rates (<5% acceptable)
   - Response times (meet SLAs)
   - Credit application accuracy (FIFO, scope matching)
4. **Day 13-14:** Collect finance team feedback, fix medium-priority bugs

**Success Criteria:**
- Finance team confirms "calculations accurate, ready for broader rollout"
- Error rate <5%
- No regressions in v1.7.0 functionality
- Credit FIFO logic validated with real data

**Rollback Triggers:**
- Error rate >5%
- Finance team reports calculation errors
- Credit application failures (incorrect FIFO, balance errors)

---

### Phase 3 - Broader Org (Week 3: Days 15-21)

**Objective:** Enable read-only access for ops and managers.

**Configuration:**
```json
{
  "charges_engine": { "enabled": true, "roles": ["finance", "admin"] },
  "charges_ui": { "enabled": true, "roles": ["finance", "ops", "manager", "admin"] },
  "referrer_fuzzy": { "enabled": false },
  "auto_compute_charges": { "enabled": true, "roles": ["all"] }
}
```

**Participants:**
- Ops team (read-only: view charges, no workflow actions)
- Managers (read-only: view charges for their investors)
- Finance team (full access)
- Admin (full access)

**Activities:**
1. **Day 15:** Enable charges_ui for ops and manager roles
2. **Day 16-18:** Ops/managers explore UI:
   - View charge lists (all tabs)
   - View charge details (accordion breakdown)
   - Filter by investor, date range
   - No workflow actions visible (RBAC enforced)
3. **Day 19-21:** Collect feedback on UI/UX, monitor access logs

**Success Criteria:**
- Ops/managers confirm "UI intuitive, data accurate"
- RBAC enforcement verified (no unauthorized actions)
- No performance degradation with increased user load

**Rollback Triggers:**
- RBAC violations (unauthorized access)
- Performance degradation (>5s load times with increased users)

---

### Phase 4 - Fuzzy Match Experimental (Week 4: Days 22-28)

**Objective:** Test referrer fuzzy matching accuracy.

**Configuration:**
```json
{
  "charges_engine": { "enabled": true, "roles": ["finance", "admin"] },
  "charges_ui": { "enabled": true, "roles": ["finance", "ops", "manager", "admin"] },
  "referrer_fuzzy": { "enabled": true, "roles": ["admin"] },
  "auto_compute_charges": { "enabled": true, "roles": ["all"] }
}
```

**Participants:**
- Admin user (tests fuzzy matching)
- 50-100 referrers in database
- CSV imports with "Referrer" column

**Activities:**
1. **Day 22:** Enable referrer_fuzzy for admin only
2. **Day 23-25:** Admin tests fuzzy matching:
   - Import CSV with 50 referrer names
   - Review auto-link results (≥90% confidence)
   - Review queue entries (80-89% confidence)
   - Verify no match (<80% confidence)
3. **Day 26-27:** Calculate accuracy:
   - Auto-link accuracy: X% (target: ≥95%)
   - False positives: X (target: <5%)
   - Review queue size: X (target: <20% of total)
4. **Day 28:** Decision point:
   - If accuracy ≥95%: enable for finance team
   - If accuracy 90-94%: iterate on algorithm, retest
   - If accuracy <90%: disable, keep manual workflow

**Success Criteria:**
- Auto-link accuracy ≥95% (correct matches)
- False positive rate <5%
- Review queue manageable (<20% of imports)

**Rollback Triggers:**
- Auto-link accuracy <90%
- False positive rate >10%
- Review queue >50% of imports (too many ambiguous matches)

---

## Rollback Procedures

### Instant Rollback (Zero Downtime)

**Trigger:** Non-critical issues (error rate 5-10%, minor bugs, UX issues)

**Procedure:**
1. Update feature flags in configuration:
   ```json
   {
     "charges_engine": { "enabled": false },
     "charges_ui": { "enabled": false },
     "referrer_fuzzy": { "enabled": false },
     "auto_compute_charges": { "enabled": false }
   }
   ```
2. Flags take effect immediately (next API call)
3. Users see graceful degradation:
   - Charges menu hidden
   - Existing charges still viewable (read-only)
   - No new charge workflows available
4. Monitor logs for 1 hour to verify rollback success
5. Communicate to users: "Charges feature temporarily disabled for maintenance"

**Estimated Downtime:** 0 seconds (flags disable instantly)

---

### Full Rollback (Edge Function Revert)

**Trigger:** Critical issues (data corruption, security breach, error rate >10%)

**Procedure:**
1. **Immediate:** Disable feature flags (instant rollback above)
2. **Within 5 minutes:** Revert Edge Function deployment:
   ```bash
   # Revert to previous version
   supabase functions deploy charges-api --project-ref <ref> --version <previous-version>

   # Or redeploy v1.7.0 function
   git checkout v1.7.0
   supabase functions deploy charges-api --project-ref <ref>
   ```
3. **Within 10 minutes:** Verify v1.7.0 smoke tests pass (regression check)
4. **Within 30 minutes:** Database rollback (if schema changes applied):
   ```sql
   -- Drop v1.8.0 tables/indexes (if added)
   DROP INDEX IF EXISTS charges_unique_contribution_investor;

   -- Restore from backup (if data corrupted)
   -- Follow backup restoration procedure
   ```
5. **Within 1 hour:** Incident report:
   - Root cause analysis
   - Data integrity check (charges, credits, contributions)
   - Affected users count
   - Remediation plan

**Estimated Downtime:** 5-15 minutes (Edge Function redeployment)

---

### Rollback Triggers (Automated Monitoring)

| Trigger | Threshold | Action | Owner |
|---------|-----------|--------|-------|
| Error rate | >5% for 10 min | Instant rollback (disable flags) | orchestrator-pm |
| Error rate | >10% for 5 min | Full rollback (revert function) | orchestrator-pm |
| Response time | >5s for 15 min | Instant rollback | postgres-schema-architect |
| Credit calculation error | Any occurrence | Full rollback | transaction-credit-ledger |
| RLS violation | Any occurrence | Full rollback | postgres-schema-architect |
| Data corruption | Any occurrence | Full rollback + DB restore | postgres-schema-architect |
| Security breach | Any occurrence | Full rollback + incident response | qa-test-openapi-validator |

---

## Post-Rollback Actions

1. **Root Cause Analysis (Within 24h):**
   - Identify bug/issue that triggered rollback
   - Document in incident log
   - Create tickets for fixes

2. **Data Integrity Verification:**
   - Run health checks (AGR-02)
   - Verify credit balances (ledger integrity)
   - Check for orphaned charges

3. **Communication:**
   - Notify stakeholders of rollback
   - Provide ETA for fix
   - Update status dashboard

4. **Remediation Plan:**
   - Fix bugs in development branch
   - Retest in staging (all smoke tests)
   - Schedule re-deployment (restart Phase 1)

---

## Feature Flag Implementation Guide

**Backend (Edge Functions):**
```typescript
// supabase/functions/charges-api/index.ts
import { getFeatureFlag } from './utils/feature-flags'

async function handleChargeSubmit(req: Request) {
  const flagEnabled = await getFeatureFlag('charges_engine', user.role)

  if (!flagEnabled) {
    return new Response(
      JSON.stringify({ error: { code: 'FEATURE_DISABLED', message: 'Charges feature is currently disabled' } }),
      { status: 503, headers: { 'Content-Type': 'application/json' } }
    )
  }

  // Proceed with charge submission logic
}
```

**Frontend (React):**
```typescript
// src/hooks/useFeatureFlag.ts
import { useAuth } from './useAuth'

export function useFeatureFlag(flagName: string): boolean {
  const { user } = useAuth()
  const flags = getFeatureFlagsForRole(user.role)
  return flags[flagName]?.enabled ?? false
}

// src/components/Navigation.tsx
import { useFeatureFlag } from '../hooks/useFeatureFlag'

export function Navigation() {
  const chargesUiEnabled = useFeatureFlag('charges_ui')

  return (
    <nav>
      {chargesUiEnabled && <Link to="/charges">Charges</Link>}
    </nav>
  )
}
```

**Database (Feature Flags Table):**
```sql
CREATE TABLE feature_flags (
  flag_name TEXT PRIMARY KEY,
  enabled BOOLEAN NOT NULL DEFAULT false,
  description TEXT,
  roles TEXT[] NOT NULL DEFAULT '{}',
  rollout_phase TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_by UUID REFERENCES auth.users(id)
);

-- Seed initial flags
INSERT INTO feature_flags (flag_name, enabled, description, roles, rollout_phase) VALUES
  ('charges_engine', true, 'Enable charge computation and workflows', ARRAY['admin'], 'pilot'),
  ('charges_ui', true, 'Show Charges pages in navigation', ARRAY['admin'], 'pilot'),
  ('referrer_fuzzy', false, 'Auto-link referrers using fuzzy matching', ARRAY['admin'], 'experimental'),
  ('auto_compute_charges', true, 'Auto-compute charges on contribution import', ARRAY['all'], 'active');

-- RLS policy
ALTER TABLE feature_flags ENABLE ROW LEVEL SECURITY;

CREATE POLICY feature_flags_read ON feature_flags FOR SELECT TO authenticated USING (true);
CREATE POLICY feature_flags_write ON feature_flags FOR UPDATE TO authenticated USING (auth.jwt() ->> 'role' = 'admin');
```

---

## Monitoring Dashboard

**Key Metrics (Real-Time):**
1. **Error Rate:** % of failed API calls (target: <5%)
2. **Response Times:** p50, p95, p99 (target: <2s)
3. **Charge Volume:** count by status (draft/pending/approved/paid)
4. **Credit Application:** total credits applied, FIFO accuracy
5. **User Activity:** active users, actions per minute

**Alerts:**
- Error rate >5% for 10 min → Slack alert to orchestrator-pm
- Response time >5s for 15 min → Slack alert to postgres-schema-architect
- Any credit calculation error → PagerDuty alert to transaction-credit-ledger

**Dashboard URL:** [TBD - Grafana or Datadog dashboard]

---

## Success Criteria Summary

| Phase | Duration | Success Criteria | Go/No-Go Decision |
|-------|----------|------------------|-------------------|
| Pilot | Week 1 | 8/8 smoke tests pass, zero critical bugs | Proceed to finance team |
| Finance Team | Week 2 | Error rate <5%, finance team approval | Proceed to broader org |
| Broader Org | Week 3 | RBAC verified, no performance degradation | Proceed to fuzzy match |
| Fuzzy Match | Week 4 | Auto-link accuracy ≥95% | Enable for all or iterate |

---

**Document Status:** APPROVED
**Next Review:** Daily during rollout phases
**Escalation Path:** orchestrator-pm → stakeholder
