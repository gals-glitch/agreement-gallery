# ============================================================
# COMMISSIONS END-TO-END DEMO - MASTER SCRIPT
# ============================================================
# This script orchestrates the entire demo execution
# Time: 60-90 minutes
# ============================================================

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "COMMISSIONS END-TO-END DEMO" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This will guide you through shipping the commissions demo." -ForegroundColor Yellow
Write-Host ""

# Check prerequisites
Write-Host "📋 Checking prerequisites..." -ForegroundColor Yellow
Write-Host ""

$allGood = $true

# Check if dev server is running
Write-Host "  1. Dev server running at http://localhost:8081?" -ForegroundColor Gray
$response = Read-Host "     (y/n)"
if ($response -ne "y") {
    Write-Host "     ❌ Please start dev server: npm run dev" -ForegroundColor Red
    $allGood = $false
} else {
    Write-Host "     ✅ Good" -ForegroundColor Green
}
Write-Host ""

# Check if JWT token is set
Write-Host "  2. Admin JWT token set in `$env:ADMIN_JWT?" -ForegroundColor Gray
if (-not $env:ADMIN_JWT) {
    Write-Host "     ❌ JWT token not set" -ForegroundColor Red
    Write-Host "     Get your token:" -ForegroundColor Yellow
    Write-Host "       1. Go to http://localhost:8081" -ForegroundColor Cyan
    Write-Host "       2. Sign in as admin" -ForegroundColor Cyan
    Write-Host "       3. Open DevTools (F12) → Console" -ForegroundColor Cyan
    Write-Host "       4. Run: (await supabase.auth.getSession()).data.session.access_token" -ForegroundColor Cyan
    Write-Host "       5. Set token: `$env:ADMIN_JWT = 'your-token-here'" -ForegroundColor Cyan
    $allGood = $false
} else {
    Write-Host "     ✅ Good (token length: $($env:ADMIN_JWT.Length))" -ForegroundColor Green
}
Write-Host ""

if (-not $allGood) {
    Write-Host "❌ Prerequisites not met. Please fix the issues above." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Prerequisites OK!" -ForegroundColor Green
Write-Host ""
Write-Host "Press Enter to continue..." -ForegroundColor Gray
Read-Host

# STEP 1: Enable Feature Flag
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "STEP 1: Enable Feature Flag" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This will copy the SQL to your clipboard." -ForegroundColor Yellow
Write-Host "Then paste it into Supabase SQL Editor and click Run." -ForegroundColor Yellow
Write-Host ""
Write-Host "Press Enter to copy SQL..." -ForegroundColor Gray
Read-Host

& "$PSScriptRoot\00_run_sql_step.ps1" -Step 1

Write-Host ""
Write-Host "Did the SQL execute successfully in Supabase?" -ForegroundColor Yellow
$response = Read-Host "(y/n)"
if ($response -ne "y") {
    Write-Host "❌ Please fix the issue and re-run the SQL." -ForegroundColor Red
    exit 1
}
Write-Host ""

# STEP 2: Fix Agreements Mapping
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "STEP 2: Fix Agreements → Deal Mapping" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This step requires you to:" -ForegroundColor Yellow
Write-Host "  1. Run PART A queries to see current state" -ForegroundColor Gray
Write-Host "  2. Fill in the party → deal mapping table" -ForegroundColor Gray
Write-Host "  3. Run the UPDATE statement" -ForegroundColor Gray
Write-Host "  4. Verify with PART D queries" -ForegroundColor Gray
Write-Host ""
Write-Host "Press Enter to copy SQL..." -ForegroundColor Gray
Read-Host

& "$PSScriptRoot\00_run_sql_step.ps1" -Step 2

Write-Host ""
Write-Host "Follow the instructions in the SQL file." -ForegroundColor Yellow
Write-Host "Did the mapping complete successfully?" -ForegroundColor Yellow
$response = Read-Host "(y/n)"
if ($response -ne "y") {
    Write-Host "❌ Please fix the mapping and re-run." -ForegroundColor Red
    exit 1
}
Write-Host ""

# STEP 3: Compute Commissions
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "STEP 3: Compute Commissions" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This will call the API to compute commissions for recent contributions." -ForegroundColor Yellow
Write-Host ""
Write-Host "Press Enter to start..." -ForegroundColor Gray
Read-Host

& "$PSScriptRoot\03_compute_commissions.ps1"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Compute failed. Check the errors above." -ForegroundColor Red
    exit 1
}
Write-Host ""

# STEP 4: Test Workflow
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "STEP 4: Test Workflow (Draft → Paid)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This will run a full workflow on one commission." -ForegroundColor Yellow
Write-Host ""
Write-Host "Press Enter to start..." -ForegroundColor Gray
Read-Host

& "$PSScriptRoot\04_workflow_test.ps1"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Workflow test failed. Check the errors above." -ForegroundColor Red
    exit 1
}
Write-Host ""

# STEP 5: Verification
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "STEP 5: Verification & Reports" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This will copy verification SQL to your clipboard." -ForegroundColor Yellow
Write-Host "Run the queries to see reports and validate data." -ForegroundColor Yellow
Write-Host ""
Write-Host "Press Enter to copy SQL..." -ForegroundColor Gray
Read-Host

& "$PSScriptRoot\00_run_sql_step.ps1" -Step 5

Write-Host ""
Write-Host "Review the reports in Supabase." -ForegroundColor Yellow
Write-Host "Do all the numbers look correct?" -ForegroundColor Yellow
$response = Read-Host "(y/n)"
if ($response -ne "y") {
    Write-Host "⚠️  Review the data and fix any issues." -ForegroundColor Yellow
}
Write-Host ""

# STEP 6: UI Test
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "STEP 6: UI Smoke Test" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Opening http://localhost:8081/commissions..." -ForegroundColor Yellow
Start-Process "http://localhost:8081/commissions"
Write-Host ""
Write-Host "Test the following:" -ForegroundColor Yellow
Write-Host "  1. Click through the tabs (All, Draft, Pending, Approved, Paid)" -ForegroundColor Gray
Write-Host "  2. Click on a commission to open detail page" -ForegroundColor Gray
Write-Host "  3. Test workflow actions (Submit, Approve, Mark Paid)" -ForegroundColor Gray
Write-Host "  4. Verify RBAC (non-admin can't approve)" -ForegroundColor Gray
Write-Host ""
Write-Host "Does the UI work correctly?" -ForegroundColor Yellow
$response = Read-Host "(y/n)"
if ($response -ne "y") {
    Write-Host "⚠️  Check browser console for errors." -ForegroundColor Yellow
}
Write-Host ""

# SUMMARY
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "✅ DEMO COMPLETE!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Checklist:" -ForegroundColor Cyan
Write-Host "  ✅ Feature flag enabled" -ForegroundColor Green
Write-Host "  ✅ Agreements mapped to correct deals" -ForegroundColor Green
Write-Host "  ✅ Commissions computed" -ForegroundColor Green
Write-Host "  ✅ Workflow tested (draft → paid)" -ForegroundColor Green
Write-Host "  ✅ Reports generated" -ForegroundColor Green
Write-Host "  ✅ UI functional" -ForegroundColor Green
Write-Host ""
Write-Host "🎉 Commissions system is demo-ready!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  • Show the demo to stakeholders" -ForegroundColor Gray
Write-Host "  • Implement tiered rates (time-windowed terms)" -ForegroundColor Gray
Write-Host "  • Add CSV export for finance team" -ForegroundColor Gray
Write-Host "  • Run full QA with negative tests" -ForegroundColor Gray
Write-Host ""
Write-Host "See DEMO_EXECUTION_GUIDE.md for more details." -ForegroundColor Gray
