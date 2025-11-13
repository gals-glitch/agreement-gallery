# ============================================================
# SQL Step Helper - Copy SQL to Clipboard
# ============================================================
# Makes it easy to copy SQL scripts to Supabase SQL Editor
# ============================================================

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("1", "2", "5")]
    [string]$Step
)

$sqlFiles = @{
    "1" = "01_enable_commissions_flag.sql"
    "2" = "02_fix_agreements_deal_mapping.sql"
    "5" = "05_verification.sql"
}

$sqlFile = $sqlFiles[$Step]
$filePath = Join-Path $PSScriptRoot $sqlFile

if (-not (Test-Path $filePath)) {
    Write-Host "❌ ERROR: File not found: $sqlFile" -ForegroundColor Red
    exit 1
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "SQL Step Helper - Step $Step" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Copying SQL from: $sqlFile" -ForegroundColor Yellow
Write-Host ""

# Read and copy to clipboard
$sqlContent = Get-Content $filePath -Raw
Set-Clipboard $sqlContent

Write-Host "✅ SQL copied to clipboard!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Open Supabase SQL Editor:" -ForegroundColor Gray
Write-Host "     https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys/sql/new" -ForegroundColor Cyan
Write-Host ""
Write-Host "  2. Press Ctrl+V to paste the SQL" -ForegroundColor Gray
Write-Host ""
Write-Host "  3. Click 'Run' or press Ctrl+Enter" -ForegroundColor Gray
Write-Host ""
Write-Host "  4. Review the results" -ForegroundColor Gray
Write-Host ""

# Show a preview of the SQL (first 10 lines)
Write-Host "SQL Preview (first 10 lines):" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray
$sqlContent -split "`n" | Select-Object -First 10 | ForEach-Object {
    Write-Host $_ -ForegroundColor Gray
}
Write-Host "----------------------------------------" -ForegroundColor Gray
Write-Host ""
Write-Host "✅ Ready to paste in Supabase!" -ForegroundColor Green
