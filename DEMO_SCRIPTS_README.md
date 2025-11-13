# Commissions Demo Scripts

**Created:** 2025-10-30
**Purpose:** End-to-end demo execution for commissions system
**Time Required:** 60-90 minutes

---

## 🚀 Quick Start

### Option 1: Run Everything with Master Script (Recommended)

```powershell
cd "C:\Users\GalSamionov\Buligo Capital\Buligo Capital - Shared Documents\Information Systems\Gal\agreement-gallery-main"
.\RUN_DEMO.ps1
```

This will guide you through all steps interactively.

### Option 2: Run Steps Manually

1. **Enable Feature Flag:**
   ```powershell
   .\00_run_sql_step.ps1 -Step 1
   # Then paste in Supabase SQL Editor
   ```

2. **Fix Agreements Mapping:**
   ```powershell
   .\00_run_sql_step.ps1 -Step 2
   # Then paste in Supabase SQL Editor and customize
   ```

3. **Compute Commissions:**
   ```powershell
   .\03_compute_commissions.ps1
   ```

4. **Test Workflow:**
   ```powershell
   .\04_workflow_test.ps1
   ```

5. **Verify & Report:**
   ```powershell
   .\00_run_sql_step.ps1 -Step 5
   # Then paste in Supabase SQL Editor
   ```

6. **UI Test:**
   - Navigate to http://localhost:8081/commissions
   - Click through tabs and test actions

---

## 📁 Files Overview

### Execution Scripts

| File | Purpose | Type | Time |
|------|---------|------|------|
| `RUN_DEMO.ps1` | Master orchestrator script | PowerShell | 60-90 min |
| `00_run_sql_step.ps1` | SQL clipboard helper | PowerShell | - |
| `03_compute_commissions.ps1` | Compute commissions via API | PowerShell | 5 min |
| `04_workflow_test.ps1` | Test draft→paid workflow | PowerShell | 5 min |

### SQL Scripts

| File | Purpose | Run In | Time |
|------|---------|--------|------|
| `01_enable_commissions_flag.sql` | Enable feature flag | Supabase | 1 min |
| `02_fix_agreements_deal_mapping.sql` | Map parties to deals | Supabase | 10 min |
| `05_verification.sql` | Reports & validation | Supabase | 5 min |

### Documentation

| File | Purpose |
|------|---------|
| `DEMO_EXECUTION_GUIDE.md` | Complete step-by-step guide |
| `DEMO_SCRIPTS_README.md` | This file |

---

## 🔧 Prerequisites

Before running any scripts:

1. **Dev Server Running:**
   ```bash
   npm run dev
   ```
   Verify at: http://localhost:8081

2. **Admin JWT Token:**
   ```powershell
   # Get token from browser console:
   # (await supabase.auth.getSession()).data.session.access_token

   $env:ADMIN_JWT = "your-token-here"
   ```

3. **Supabase Access:**
   - URL: https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys/sql/new
   - Must have write access to database

---

## 📊 What Gets Tested

### Database
- ✅ Feature flag enabled
- ✅ Agreements mapped to correct deals
- ✅ Commissions computed with correct amounts
- ✅ VAT calculated properly
- ✅ Snapshots stored

### API
- ✅ `POST /commissions/compute` - Single computation
- ✅ `POST /commissions/batch-compute` - Batch computation
- ✅ `GET /commissions?status=draft` - List filtering
- ✅ `POST /commissions/:id/submit` - State transition
- ✅ `POST /commissions/:id/approve` - Admin approval
- ✅ `POST /commissions/:id/mark-paid` - Payment recording

### UI
- ✅ Commissions list page loads
- ✅ Tabs work (All, Draft, Pending, Approved, Paid)
- ✅ Detail page shows correct data
- ✅ Workflow actions work
- ✅ RBAC enforced (admin-only actions)

### Reports
- ✅ Party payout summary
- ✅ Outstanding payments
- ✅ Paid commissions history
- ✅ Timeline analysis

---

## 🎯 Expected Outcomes

### After Step 1: Enable Flag
- Sidebar shows "Commissions" menu item for admin/finance
- Feature flag query returns `enabled=true`

### After Step 2: Fix Mapping
- Agreements distributed across different deals
- No agreements orphaned on deal_id=1

### After Step 3: Compute
- X commissions created in DRAFT status
- Each has base_amount, vat_amount, total_amount
- Snapshots contain agreement terms

### After Step 4: Workflow
- 1 commission goes through: DRAFT → PENDING → APPROVED → PAID
- Payment ref recorded
- Timestamps populated

### After Step 5: Verify
- Reports show correct totals
- Data quality checks pass (0 errors)
- Party payout summary matches expectations

### After Step 6: UI Test
- All pages load without errors
- Actions work correctly
- State changes reflect immediately

---

## 🐛 Troubleshooting

### "No commissions computed"
**Cause:** Missing investor → party links or agreements

**Fix:**
```sql
-- Check investor links
SELECT i.id, i.name, p.name as introduced_by
FROM investors i
LEFT JOIN parties p ON i.introduced_by = p.id
WHERE i.introduced_by IS NOT NULL;

-- Check agreements
SELECT a.id, p.name, a.deal_id, a.status
FROM agreements a
JOIN parties p ON a.party_id = p.id
WHERE a.kind = 'distributor_commission' AND a.status = 'APPROVED';
```

### "403 Forbidden" errors
**Cause:** JWT token expired or wrong role

**Fix:**
```powershell
# Get fresh token
$env:ADMIN_JWT = "new-token-here"

# Or check role in database
# SELECT * FROM user_roles WHERE user_id = 'your-user-id';
```

### "Feature not visible in UI"
**Cause:** Flag not enabled or browser cache

**Fix:**
1. Verify flag: `SELECT * FROM feature_flags WHERE key='commissions_engine'`
2. Clear browser cache and reload
3. Check user role matches `allowed_roles`

---

## 📈 Success Metrics

| Metric | Target | Actual |
|--------|--------|--------|
| Commissions computed | > 0 | ___ |
| Workflow transitions | 3/3 | ___ |
| API errors | 0 | ___ |
| UI console errors | 0 | ___ |
| Data quality checks | 0 failures | ___ |
| Party payout accuracy | 100% | ___ |

---

## 🚦 Demo Readiness Checklist

- [ ] All scripts executed successfully
- [ ] At least 1 commission in PAID status
- [ ] Party payout report shows correct amounts
- [ ] UI loads without errors
- [ ] Workflow actions work for admin
- [ ] Workflow actions blocked for non-admin
- [ ] Service key blocked from mark-paid
- [ ] Reports export-ready for finance

---

## 📞 Support

**Issues?** Check:
1. `DEMO_EXECUTION_GUIDE.md` - Detailed troubleshooting
2. `CURRENT_STATUS.md` - System status and context
3. Browser console for frontend errors
4. Supabase logs for backend errors

**Next Steps After Demo:**
- Implement tiered rates (time-windowed terms)
- Add CSV export for payouts
- Run full QA suite
- Deploy to production

---

_Last Updated: 2025-10-30_
_Version: v1.9.0 Commissions MVP_
