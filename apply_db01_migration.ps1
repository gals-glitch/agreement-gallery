if (-not $env:SUPABASE_SERVICE_ROLE_KEY) {
    Write-Host "Run .\set_key.ps1 first" -ForegroundColor Red
    exit 1
}

Write-Host "DB-01: Applying migration to add investor-party FK" -ForegroundColor Cyan
Write-Host ""

# Read the migration SQL
$migrationPath = "supabase\migrations\20251102_add_investor_party_fk.sql"
$sql = Get-Content $migrationPath -Raw

Write-Host "Executing migration..." -ForegroundColor Yellow

# Execute via Supabase SQL API
$headers = @{
    "Authorization" = "Bearer $env:SUPABASE_SERVICE_ROLE_KEY"
    "apikey" = $env:SUPABASE_SERVICE_ROLE_KEY
    "Content-Type" = "application/json"
}

$body = @{
    query = $sql
} | ConvertTo-Json

try {
    # Note: Supabase doesn't have a direct SQL execution endpoint via REST
    # We'll need to use psql or apply this via Supabase dashboard
    Write-Host "MANUAL STEP REQUIRED:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please apply the migration manually via one of these methods:" -ForegroundColor White
    Write-Host ""
    Write-Host "Method 1: Supabase Dashboard SQL Editor" -ForegroundColor Cyan
    Write-Host "  1. Go to: https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys/sql" -ForegroundColor Gray
    Write-Host "  2. Open file: $migrationPath" -ForegroundColor Gray
    Write-Host "  3. Copy contents and run in SQL Editor" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Method 2: Copy SQL to clipboard" -ForegroundColor Cyan
    Write-Host "  Run: Get-Content '$migrationPath' | Set-Clipboard" -ForegroundColor Gray
    Write-Host "  Then paste into Supabase SQL Editor" -ForegroundColor Gray
    Write-Host ""
    Write-Host "After applying, run verification:" -ForegroundColor Yellow
    Write-Host "  .\verify_db01.ps1" -ForegroundColor Gray

} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
