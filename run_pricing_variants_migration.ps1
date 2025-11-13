# Run pricing_variants migration
# This script applies the pricing_variant fields to agreement_custom_terms

Write-Host "Running pricing_variants migration..." -ForegroundColor Cyan

# Read the migration SQL
$migrationPath = Join-Path $PSScriptRoot "supabase\migrations\20251110000000_add_pricing_variants.sql"
$sqlContent = Get-Content $migrationPath -Raw

# Copy to clipboard for manual execution
$sqlContent | Set-Clipboard

Write-Host "`n✅ Migration SQL copied to clipboard!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Open Supabase Dashboard → SQL Editor"
Write-Host "2. Paste the SQL (Ctrl+V)"
Write-Host "3. Click 'Run' to execute"
Write-Host "`nOr run via connection string:" -ForegroundColor Yellow
Write-Host 'psql "$DATABASE_URL" < supabase\migrations\20251110000000_add_pricing_variants.sql'

# Also show the SQL for reference
Write-Host "`n" + ("="*80) -ForegroundColor Gray
Write-Host "Migration Preview (first 500 chars):" -ForegroundColor Gray
Write-Host ($sqlContent.Substring(0, [Math]::Min(500, $sqlContent.Length))) -ForegroundColor DarkGray
Write-Host "..." -ForegroundColor DarkGray
Write-Host ("="*80) -ForegroundColor Gray

pause
