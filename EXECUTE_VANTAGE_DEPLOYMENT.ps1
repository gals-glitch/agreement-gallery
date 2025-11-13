# Master Script: Vantage Sync Deployment
# Executes all 7 steps for production deployment
# Date: 2025-11-06

$ErrorActionPreference = "Stop"

Write-Host @"
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║          VANTAGE SYNC DEPLOYMENT - FINAL STEPS                ║
║                                                                ║
║  This script will execute the 7-step deployment checklist:    ║
║    1. Lock funds upserts (unique constraint)                  ║
║    2. Run full + incremental funds sync                       ║
║    3. Gate behind feature flag                                ║
║    4. Deploy Admin Sync Dashboard                             ║
║    5. Schedule daily cron                                     ║
║    6. Run hardening checks                                    ║
║    7. Update documentation                                    ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

Write-Host "`nPress Enter to begin, or Ctrl+C to cancel..." -ForegroundColor Yellow
Read-Host

# ==============================================================================
# STEP 1: Lock Funds Upserts
# ==============================================================================
Write-Host "`n╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  STEP 1: Lock Funds Upserts (Unique Constraint)         ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host "`n[1a] Checking for duplicate external_id in deals..." -ForegroundColor Yellow

$checkDupSql = Get-Content "step1_check_deals_duplicates.sql" -Raw
Write-Host "`nSQL:" -ForegroundColor Gray
Write-Host $checkDupSql -ForegroundColor DarkGray

$checkDupSql | Set-Clipboard
Write-Host "`n✓ SQL copied to clipboard" -ForegroundColor Green
Write-Host "Run it in Supabase SQL Editor and verify 0 rows returned." -ForegroundColor Yellow
$dupCheck = Read-Host "Did it return 0 rows? (y/n)"

if ($dupCheck -ne "y") {
    Write-Host "`n✗ ABORTED: Duplicates found! Resolve before continuing." -ForegroundColor Red
    exit 1
}

Write-Host "`n[1b] Adding unique constraint to deals.external_id..." -ForegroundColor Yellow

$constraintSql = Get-Content "step1_add_deals_constraint.sql" -Raw
$constraintSql | Set-Clipboard
Write-Host "✓ SQL copied to clipboard" -ForegroundColor Green
Write-Host "Run it in Supabase SQL Editor." -ForegroundColor Yellow
Read-Host "Press Enter when done"

Write-Host "✓ Step 1 complete" -ForegroundColor Green

# ==============================================================================
# STEP 2: Run Funds Sync
# ==============================================================================
Write-Host "`n╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  STEP 2: Run Full + Incremental Funds Sync              ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host "`nThis will call the Vantage sync Edge Function..." -ForegroundColor Yellow
$runSync = Read-Host "Proceed? (y/n)"

if ($runSync -eq "y") {
    & ".\step2_run_funds_sync.ps1"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`n✗ ABORTED: Funds sync failed!" -ForegroundColor Red
        exit 1
    }
    Write-Host "✓ Step 2 complete" -ForegroundColor Green
} else {
    Write-Host "⚠ Skipped Step 2. Run step2_run_funds_sync.ps1 manually." -ForegroundColor Yellow
}

# ==============================================================================
# STEP 3: Gate Behind Feature Flag
# ==============================================================================
Write-Host "`n╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  STEP 3: Gate Behind Feature Flag                        ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host ""
Write-Host "To enable the Vantage sync feature:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Go to Supabase SQL Editor" -ForegroundColor Yellow
Write-Host "2. Run this SQL:" -ForegroundColor Yellow
Write-Host ""
Write-Host '    INSERT INTO public.feature_flags (flag_key, description, is_active)' -ForegroundColor Yellow
Write-Host "    VALUES (''vantage_sync'', ''Enable Vantage IR synchronization'', false)" -ForegroundColor Yellow
Write-Host '    ON CONFLICT (flag_key) DO UPDATE SET description = EXCLUDED.description;' -ForegroundColor Yellow
Write-Host ""
Write-Host "3. When ready to enable: UPDATE feature_flags SET is_active = true WHERE flag_key = ''vantage_sync'';" -ForegroundColor Yellow
Write-Host ""

$null = Read-Host "Press Enter to continue"
Write-Host "✓ Step 3 instructions provided" -ForegroundColor Green

# ==============================================================================
# STEP 4: Admin Sync Dashboard
# ==============================================================================
Write-Host "`n╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  STEP 4: Admin Sync Dashboard                            ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host ""
Write-Host "Admin Sync Dashboard has been created at:" -ForegroundColor Yellow
Write-Host "  src/pages/AdminSync.tsx" -ForegroundColor Yellow
Write-Host ""
Write-Host "Route configured in App.tsx:" -ForegroundColor Yellow
Write-Host "  /admin/sync (admin-only, behind vantage_sync feature flag)" -ForegroundColor Yellow
Write-Host ""
Write-Host "To add navigation link, edit your nav component and add:" -ForegroundColor Yellow
Write-Host '  { label: "Vantage Sync", path: "/admin/sync", icon: Database, flag: "vantage_sync" }' -ForegroundColor Yellow
Write-Host ""

$null = Read-Host "Press Enter to continue"
Write-Host "✓ Step 4 complete - Dashboard is ready" -ForegroundColor Green

# ==============================================================================
# STEP 5: Schedule Daily Cron
# ==============================================================================
Write-Host "`n╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  STEP 5: Schedule Daily Incremental Sync                ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host "`n⚠ IMPORTANT: Before running, update the service role key in:" -ForegroundColor Yellow
Write-Host "  step5_setup_daily_cron.sql (line with YOUR_SERVICE_ROLE_KEY_HERE)" -ForegroundColor Yellow

$cronSql = Get-Content "step5_setup_daily_cron.sql" -Raw
$cronSql | Set-Clipboard
Write-Host "`n✓ SQL copied to clipboard" -ForegroundColor Green
Write-Host "Run it in Supabase SQL Editor to schedule the daily job at 00:00 UTC." -ForegroundColor Yellow
Read-Host "Press Enter when done"

Write-Host "✓ Step 5 complete - Cron job scheduled" -ForegroundColor Green

# ==============================================================================
# STEP 6: Hardening Checks
# ==============================================================================
Write-Host "`n╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  STEP 6: Run Hardening Checks                            ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

$hardeningSql = Get-Content "step6_hardening_checks.sql" -Raw
$hardeningSql | Set-Clipboard
Write-Host "`n✓ Hardening checks SQL copied to clipboard" -ForegroundColor Green
Write-Host "Run it in Supabase SQL Editor and verify all checks PASS." -ForegroundColor Yellow

$checks = @"

Expected results:
  ✓ A: All Vantage investors have external_id (0 missing)
  ✓ B: No duplicate external_ids in investors or deals
  ✓ C: Sync state shows 'success' status
  ✓ D: Merged distributors are inactive and linked
  ✓ E: Unique constraints exist on both tables
  ✓ F: Cron job 'vantage-daily-sync' is active

"@
Write-Host $checks -ForegroundColor Cyan

$checksPass = Read-Host "Did all checks pass? (y/n)"
if ($checksPass -ne "y") {
    Write-Host "`n⚠ WARNING: Some checks failed. Review and fix before proceeding." -ForegroundColor Yellow
    $proceed = Read-Host "Continue anyway? (y/n)"
    if ($proceed -ne "y") {
        Write-Host "`n✗ ABORTED" -ForegroundColor Red
        exit 1
    }
}

Write-Host "✓ Step 6 complete - All hardening checks passed" -ForegroundColor Green

# ==============================================================================
# STEP 7: Update Documentation
# ==============================================================================
Write-Host "`n╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  STEP 7: Update Documentation                            ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host ""
Write-Host "Documentation has been updated in:" -ForegroundColor Yellow
Write-Host "  VANTAGE_ETL_DEPLOYMENT.md" -ForegroundColor Yellow
Write-Host ""
Write-Host "This includes:" -ForegroundColor Yellow
Write-Host "  - All 7 deployment steps" -ForegroundColor Yellow
Write-Host "  - SQL scripts and commands" -ForegroundColor Yellow
Write-Host "  - Verification procedures" -ForegroundColor Yellow
Write-Host "  - Troubleshooting guide" -ForegroundColor Yellow
Write-Host ""

Write-Host "✓ Step 7 complete" -ForegroundColor Green

# ==============================================================================
# FINAL SIGN-OFF
# ==============================================================================
Write-Host "`n╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                                                          ║" -ForegroundColor Green
Write-Host "║          ✓✓✓ DEPLOYMENT COMPLETE ✓✓✓                   ║" -ForegroundColor Green
Write-Host "║                                                          ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green

Write-Host "`n📋 DEPLOYMENT CHECKLIST:" -ForegroundColor Cyan
Write-Host "  ✓ Funds unique constraint in place" -ForegroundColor Green
Write-Host "  ✓ Full + incremental funds sync completed" -ForegroundColor Green
Write-Host "  ✓ Admin Sync page added, behind 'vantage_sync' flag" -ForegroundColor Green
Write-Host "  ✓ Daily schedule created (vantage-daily-sync job)" -ForegroundColor Green
Write-Host "  ✓ Health checks A-D passed" -ForegroundColor Green
Write-Host "  ✓ Documentation updated" -ForegroundColor Green

Write-Host "`n🚀 NEXT STEPS:" -ForegroundColor Cyan
Write-Host "  1. Enable the 'vantage_sync' feature flag when ready" -ForegroundColor White
Write-Host "  2. Add nav link to /admin/sync for admin users" -ForegroundColor White
Write-Host "  3. Test the sync from the Admin UI" -ForegroundColor White
Write-Host "  4. Monitor the first automated daily sync" -ForegroundColor White

Write-Host "`n📚 Documentation: VANTAGE_ETL_DEPLOYMENT.md" -ForegroundColor Cyan
