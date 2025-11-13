# Commissions End-to-End Demo Execution Guide

**Objective:** Ship a working commissions demo in 60-90 minutes

**Date:** 2025-10-30
**Status:** Ready to Execute

---

## Prerequisites (5 minutes)

### 1. Get Your Admin JWT Token

1. Go to http://localhost:8081
2. Sign in as admin user
3. Open DevTools (F12) → Console
4. Run this command:
   ```javascript
   (await supabase.auth.getSession()).data.session.access_token
   ```
5. Copy the token
6. Set it in PowerShell:
   ```powershell
   $env:ADMIN_JWT = "your-token-here"
   ```

### 2. Start Dev Server (if not running)

```bash
npm run dev
```

### 3. Verify Supabase Connection

Open: https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys/sql/new

---

## Execution Steps

### Step 1: Enable Feature Flag (1 minute)

**File:** `01_enable_commissions_flag.sql`

1. Open Supabase SQL Editor: https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys/sql/new
2. Copy/paste the entire SQL from `01_enable_commissions_flag.sql`
3. Click **Run** (or press Ctrl+Enter)
4. Verify result shows:
   - `key`: commissions_engine
   - `enabled`: true
   - `allowed_roles`: {admin, finance}

**✅ Expected:** Feature flag enabled, sidebar will show "Commissions" menu

---

### Step 2: Fix Agreements → Deal Mapping (10 minutes)

**File:** `02_fix_agreements_deal_mapping.sql`

#### 2.1 Discovery

1. Open Supabase SQL Editor
2. Run **PART A** queries to see:
   - Current commission agreements (check if all on deal_id=1)
   - All available parties
   - All available deals

#### 2.2 Create Mapping

Based on PART A results, fill in the mapping table:

```sql
-- Example (adjust with YOUR actual data):
CREATE TEMP TABLE _party_deal_map(party_name text, deal_id int);

INSERT INTO _party_deal_map VALUES
('Kuperman', 2),
('Partner Capital', 5),
('Global Partners', 17),
('ABC Advisors', 10);
-- Add more rows based on your parties and deals
```

#### 2.3 Preview & Execute

1. Run the **PART C** preview query (SELECT with JOIN)
2. Verify the mapping looks correct
3. Uncomment the UPDATE statement
4. Run the UPDATE
5. Run **PART D** verification queries

**✅ Expected:** Agreements spread across different deals, no orphans on deal_id=1

---

### Step 3: Compute Commissions (5 minutes)

**File:** `03_compute_commissions.ps1`

```powershell
cd "C:\Users\GalSamionov\Buligo Capital\Buligo Capital - Shared Documents\Information Systems\Gal\agreement-gallery-main"
.\03_compute_commissions.ps1
```

**What it does:**
- Fetches contributions from last 7 days
- Calls `POST /commissions/compute` for each
- Shows success/skip/error counts

**✅ Expected:**
- Success: X commissions computed
- Skipped: Y (no party link or agreement)
- Errors: 0

**If you get "Skipped" warnings:**
- Check that investors have `introduced_by` party links:
  ```sql
  SELECT id, name, introduced_by FROM investors WHERE introduced_by IS NOT NULL;
  ```
- Check that approved commission agreements exist:
  ```sql
  SELECT * FROM agreements WHERE kind='distributor_commission' AND status='APPROVED';
  ```

---

### Step 4: Test Workflow (5 minutes)

**File:** `04_workflow_test.ps1`

```powershell
.\04_workflow_test.ps1
```

**What it does:**
1. Lists DRAFT commissions
2. Picks first one
3. Submits it (DRAFT → PENDING)
4. Approves it (PENDING → APPROVED)
5. Marks as paid (APPROVED → PAID)
6. Verifies final state

**✅ Expected:**
- All 3 transitions succeed
- Final status: PAID
- Payment ref: WIRE-DEMO-YYYYMMDD-HHMMSS

---

### Step 5: Verification & Reports (5 minutes)

**File:** `05_verification.sql`

1. Open Supabase SQL Editor
2. Run queries in order:
   - **PART A:** Commission state verification
   - **PART B:** Party payout reports
   - **PART C:** Detailed payout report (CSV export ready)
   - **PART D:** Data quality checks (should all return 0)
   - **PART E:** Timeline analysis
   - **PART F:** Snapshot validation

**✅ Expected:**
- Recent commissions shown with correct statuses
- Party payout summary shows amounts owed
- Data quality checks pass (0 errors)
- Snapshots present for all commissions

---

### Step 6: UI Smoke Test (10 minutes)

1. **Navigate to Commissions:**
   - Go to: http://localhost:8081/commissions
   - Should see 5 tabs: All, Draft, Pending, Approved, Paid

2. **Test List View:**
   - Click tabs to filter by status
   - Use search to find specific party/investor
   - Verify columns show correct data

3. **Test Detail View:**
   - Click on a commission row
   - Should open detail page
   - Verify all fields display correctly

4. **Test Workflow Actions:**
   - Find a DRAFT commission → Click **Submit** → Status changes to PENDING
   - Find a PENDING commission → Click **Approve** (admin) → Status changes to APPROVED
   - Find an APPROVED commission → Click **Mark Paid** → Enter payment ref → Status changes to PAID

5. **Test Rejection (Optional):**
   - Find a PENDING commission
   - Click **Reject**
   - Enter rejection reason
   - Verify status changes to REJECTED

**✅ Expected:**
- All tabs work
- Detail page loads
- Actions only available for correct roles
- State transitions reflect in UI immediately

---

## Troubleshooting

### Issue: No commissions computed (Step 3)

**Cause:** Missing investor → party links or agreements

**Fix:**
```sql
-- Check investors with party links
SELECT i.id, i.name, p.name as introduced_by
FROM investors i
LEFT JOIN parties p ON i.introduced_by = p.id
WHERE i.introduced_by IS NOT NULL;

-- If empty, add some links:
UPDATE investors
SET introduced_by = (SELECT id FROM parties WHERE name = 'Kuperman')
WHERE id IN (201, 202);

-- Check approved commission agreements
SELECT a.id, p.name, a.deal_id, a.status, a.kind
FROM agreements a
JOIN parties p ON a.party_id = p.id
WHERE a.kind = 'distributor_commission';

-- If missing, create an agreement (see CURRENT_STATUS.md for template)
```

---

### Issue: Workflow fails with 403 Forbidden

**Cause:** JWT token expired or wrong role

**Fix:**
1. Get a fresh JWT token (see Prerequisites)
2. Verify you're admin:
   ```sql
   SELECT user_id, role_key FROM user_roles WHERE user_id = 'your-user-id';
   ```
3. Grant admin role if missing:
   ```sql
   INSERT INTO user_roles (user_id, role_key) VALUES ('your-user-id', 'admin');
   ```

---

### Issue: Feature flag not showing in UI

**Cause:** Cache or flag not enabled

**Fix:**
1. Clear browser cache and reload
2. Verify flag is enabled:
   ```sql
   SELECT * FROM feature_flags WHERE key = 'commissions_engine';
   ```
3. Check your user role:
   ```sql
   SELECT * FROM user_roles WHERE user_id = 'your-user-id';
   ```

---

### Issue: Service key blocked from mark-paid

**Cause:** Intentional security measure

**Fix:** This is expected behavior. Only human admins with JWT tokens can mark commissions as paid.

---

## Success Criteria

- ✅ Feature flag enabled
- ✅ Agreements mapped to correct deals
- ✅ At least 1 commission computed
- ✅ Full workflow completed (draft → paid)
- ✅ Party payout report shows correct amounts
- ✅ UI loads and shows commissions
- ✅ Workflow actions work in UI

---

## Next Steps (Post-Demo)

### Phase 1: Tiered Rates by Date (1 hour)

Update agreement snapshots to include time-windowed terms:

```json
{
  "kind": "distributor_commission",
  "party_id": "uuid",
  "party_name": "Kuperman",
  "scope": {"deal_id": 2},
  "terms": [
    {"from": "2018-01-01", "to": "2018-02-01", "rate_bps": 250, "vat_mode": "on_top", "vat_rate": 0.2},
    {"from": "2018-02-01", "to": "2019-12-12", "rate_bps": 270, "vat_mode": "on_top", "vat_rate": 0.2},
    {"from": "2019-12-12", "to": null, "rate_bps": 300, "vat_mode": "on_top", "vat_rate": 0.2}
  ]
}
```

### Phase 2: QA Negative Tests (30 minutes)

Test edge cases:
- Non-admin tries to approve (should get 403)
- Service key tries to mark-paid (should get 403)
- Reject without reason (should get 400)
- Invalid transitions (draft → approved, should get 400)

### Phase 3: CSV Export (30 minutes)

Add endpoint or SQL query for finance team to export payouts:

```sql
-- Export query (copy result to CSV)
COPY (
  SELECT
    p.name as "Party Name",
    c.total_amount as "Amount Due",
    c.currency,
    c.payment_ref as "Payment Ref",
    c.paid_at::date as "Paid Date"
  FROM commissions c
  JOIN parties p ON c.party_id = p.id
  WHERE c.status = 'paid'
    AND c.paid_at::date BETWEEN '2025-01-01' AND '2025-12-31'
  ORDER BY p.name, c.paid_at
) TO '/tmp/commissions_export.csv' WITH CSV HEADER;
```

---

## Summary

**Total Time:** 60-90 minutes

1. Enable flag: 1 min
2. Fix mapping: 10 min
3. Compute: 5 min
4. Workflow: 5 min
5. Verify: 5 min
6. UI test: 10 min
7. Buffer: 24-54 min

**Deliverables:**
- ✅ Commissions engine operational
- ✅ End-to-end workflow tested
- ✅ Party payout reports generated
- ✅ UI functional and accessible
- ✅ RBAC enforced

**Demo Ready:** YES

---

_Last Updated: 2025-10-30_
_Version: v1.9.0 Commissions MVP_
