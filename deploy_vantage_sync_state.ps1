# Deploy Vantage Sync State Table
# This script applies the vantage_sync_state migration directly to Supabase

Write-Host "Deploying Vantage Sync State Table..." -ForegroundColor Cyan
Write-Host ""

# Read SQL file
$sqlContent = Get-Content "supabase\migrations\20251105132840_vantage_sync_state.sql" -Raw

# Connection details (using service role for DDL operations)
$projectRef = "qwgicrdcoqdketqhxbys"
$serviceRoleKey = Read-Host "Enter Supabase SERVICE_ROLE_KEY (from dashboard Settings > API)"

$headers = @{
    'apikey' = $serviceRoleKey
    'Authorization' = "Bearer $serviceRoleKey"
    'Content-Type' = 'application/json'
    'Prefer' = 'return=representation'
}

# Execute via Supabase REST API (using rpc or direct)
$body = @{
    query = $sqlContent
} | ConvertTo-Json

try {
    Write-Host "Executing SQL migration..." -ForegroundColor Yellow

    # Note: Supabase doesn't have a direct SQL execution endpoint
    # The best approach is to use the SQL Editor in the dashboard

    Write-Host ""
    Write-Host "MANUAL DEPLOYMENT REQUIRED" -ForegroundColor Yellow
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Please follow these steps:" -ForegroundColor Green
    Write-Host ""
    Write-Host "1. Open Supabase Dashboard: https://supabase.com/dashboard/project/$projectRef/sql/new" -ForegroundColor White
    Write-Host ""
    Write-Host "2. Copy the migration file content:"
    Write-Host "   File: supabase\migrations\20251105132840_vantage_sync_state.sql" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "3. Paste into the SQL Editor and click 'Run'" -ForegroundColor White
    Write-Host ""
    Write-Host "4. Verify success (should create vantage_sync_state table)" -ForegroundColor White
    Write-Host ""
    Write-Host "Alternative: Copy SQL to clipboard now..." -ForegroundColor Yellow

    $response = Read-Host "Copy SQL to clipboard? (y/n)"

    if ($response -eq 'y') {
        $sqlContent | Set-Clipboard
        Write-Host ""
        Write-Host "SQL copied to clipboard! Paste into Supabase SQL Editor." -ForegroundColor Green
        Write-Host "Dashboard: https://supabase.com/dashboard/project/$projectRef/sql/new" -ForegroundColor Cyan
    }

} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Once deployed, run: " -ForegroundColor Green
Write-Host "  SELECT * FROM vantage_sync_state;" -ForegroundColor Cyan
Write-Host "to verify the table was created successfully." -ForegroundColor Green
