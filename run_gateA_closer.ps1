###############################################################################
# Gate A Gap Closer - Automated Execution Helper
# Boosts investor coverage from 34% to ≥80%
###############################################################################

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "GATE A GAP CLOSER" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "This script will:" -ForegroundColor Yellow
Write-Host "  1. Copy the gap-closer SQL to your clipboard" -ForegroundColor Gray
Write-Host "  2. Open Supabase SQL Editor in your browser" -ForegroundColor Gray
Write-Host "  3. Guide you to paste and run it" -ForegroundColor Gray
Write-Host "  4. Run verification after completion" -ForegroundColor Gray
Write-Host ""

# Step 1: Copy SQL to clipboard
Write-Host "Step 1: Copying SQL to clipboard..." -ForegroundColor Yellow
Get-Content 'scripts\gateA_close_gaps.sql' | Set-Clipboard
Write-Host "  ✅ SQL copied to clipboard" -ForegroundColor Green
Write-Host ""

# Step 2: Open Supabase SQL Editor
Write-Host "Step 2: Opening Supabase SQL Editor..." -ForegroundColor Yellow
$sqlEditorUrl = "https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys/sql"
Start-Process $sqlEditorUrl
Write-Host "  ✅ Browser opened" -ForegroundColor Green
Write-Host ""

# Step 3: Instructions
Write-Host "Step 3: In the SQL Editor (browser):" -ForegroundColor Yellow
Write-Host "  1. Click 'New Query'" -ForegroundColor Gray
Write-Host "  2. Press Ctrl+V to paste the SQL" -ForegroundColor Gray
Write-Host "  3. Click 'Run' button" -ForegroundColor Gray
Write-Host "  4. Wait for completion message" -ForegroundColor Gray
Write-Host ""

Write-Host "Expected output from SQL:" -ForegroundColor Cyan
Write-Host "  total_investors | with_party_links | without_party_links | coverage_pct" -ForegroundColor Gray
Write-Host "         41       |        33+       |        8 or less    |     80.0+" -ForegroundColor Gray
Write-Host ""

# Step 4: Wait for user confirmation
Write-Host "Press any key after you've run the SQL in the browser..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
Write-Host ""

# Step 5: Run verification
Write-Host "Step 4: Running verification..." -ForegroundColor Yellow
Write-Host ""

if (-not $env:SUPABASE_SERVICE_ROLE_KEY) {
    Write-Host "Setting service key..." -ForegroundColor Gray
    .\set_key.ps1
}

.\verify_db01.ps1

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "GATE A GAP CLOSER COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Check verification results above" -ForegroundColor Gray
Write-Host "  2. If coverage ≥80%, proceed to batch compute:" -ForegroundColor Gray
Write-Host "     .\CMP_01_simple.ps1" -ForegroundColor Gray
Write-Host "  3. If coverage <80%, check FINISH_PLAN.md for fixes" -ForegroundColor Gray
