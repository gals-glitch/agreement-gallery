# ========================================
# Move 1.4 - Copy Verification SQL to Clipboard
# ========================================
# Date: 2025-10-21
# Purpose: Copy comprehensive verification queries to clipboard for Supabase SQL Editor

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Move 1.4 - Workflow Verification" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$sqlFile = "VERIFY_WORKFLOW_COMPLETE.sql"

if (Test-Path $sqlFile) {
    Get-Content $sqlFile | Set-Clipboard
    Write-Host "✅ Verification SQL copied to clipboard!" -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "  1. Open Supabase SQL Editor" -ForegroundColor White
    Write-Host "  2. Paste the SQL (Ctrl+V)" -ForegroundColor White
    Write-Host "  3. Click 'Run' to execute all verification queries" -ForegroundColor White
    Write-Host "`nExpected Results:" -ForegroundColor Cyan
    Write-Host "  ✓ Charge status: PAID" -ForegroundColor Green
    Write-Host "  ✓ Total: `$600.00" -ForegroundColor Green
    Write-Host "  ✓ Credits applied: `$500.00" -ForegroundColor Green
    Write-Host "  ✓ Net amount: `$100.00" -ForegroundColor Green
    Write-Host "  ✓ Payment ref: WIRE-DEMO-001" -ForegroundColor Green
    Write-Host "  ✓ Credit reconciliation: MATCH" -ForegroundColor Green
    Write-Host "`n" -ForegroundColor White
} else {
    Write-Host "❌ ERROR: $sqlFile not found!" -ForegroundColor Red
    Write-Host "  Make sure you're in the correct directory`n" -ForegroundColor Yellow
}
