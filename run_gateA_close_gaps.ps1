# Run Gate A Gap Closer Script
# Target: Push introduced_by_party_id coverage to ≥80%

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Gate A: Gap Closer - Fuzzy Party Matching" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Copy SQL to clipboard for manual execution in Supabase SQL Editor
$sqlPath = "scripts\gateA_close_gaps.sql"

if (-not (Test-Path $sqlPath)) {
    Write-Host "[ERROR] Script not found: $sqlPath" -ForegroundColor Red
    exit 1
}

Write-Host "SQL script location: $sqlPath" -ForegroundColor Yellow
Write-Host ""
Write-Host "What this script does:" -ForegroundColor Cyan
Write-Host "  1. Enables pg_trgm extension for fuzzy text matching" -ForegroundColor Gray
Write-Host "  2. Creates party_aliases table for name variations" -ForegroundColor Gray
Write-Host "  3. Seeds explicit aliases for known parties:" -ForegroundColor Gray
Write-Host "     - Capital Link Family Office / Shiri Hybloom" -ForegroundColor Gray
Write-Host "     - Avi Fried / פאים הולדינגס" -ForegroundColor Gray
Write-Host "     - David Kirchenbaum / קרוס ארץ" -ForegroundColor Gray
Write-Host "  4. Uses fuzzy matching (≥60% similarity) for remaining notes" -ForegroundColor Gray
Write-Host "  5. Backfills introduced_by_party_id via aliases" -ForegroundColor Gray
Write-Host "  6. Reports coverage statistics" -ForegroundColor Gray
Write-Host ""

# Copy to clipboard
Get-Content $sqlPath -Raw | Set-Clipboard
Write-Host "[OK] SQL copied to clipboard!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Go to Supabase SQL Editor" -ForegroundColor White
Write-Host "     https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys/sql" -ForegroundColor Gray
Write-Host "  2. Paste the SQL (already in clipboard)" -ForegroundColor White
Write-Host "  3. Click 'Run'" -ForegroundColor White
Write-Host "  4. Review the coverage report at the end" -ForegroundColor White
Write-Host ""

$runNow = Read-Host "After running in Supabase, press Enter to verify coverage"

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Verifying Coverage..." -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Run verification
& ".\verify_db01.ps1"

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "  Gate A Status" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Target: ≥80% coverage for introduced_by_party_id" -ForegroundColor Cyan
Write-Host ""
Write-Host "If coverage is still < 80%:" -ForegroundColor Yellow
Write-Host "  1. Lower fuzzy threshold from 0.60 to 0.55 in the SQL script" -ForegroundColor White
Write-Host "  2. Re-run the script in Supabase SQL Editor" -ForegroundColor White
Write-Host "  3. Run this verification again" -ForegroundColor White
Write-Host ""
