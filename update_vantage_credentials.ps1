# Update Vantage API Credentials in Supabase
# Run this after getting new credentials from Vantage support

param(
    [Parameter(Mandatory=$false)]
    [string]$AuthToken,

    [Parameter(Mandatory=$false)]
    [string]$ClientId,

    [Parameter(Mandatory=$false)]
    [string]$BaseUrl = "https://buligoirapi.insightportal.info"
)

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  UPDATE VANTAGE API CREDENTIALS" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Prompt for credentials if not provided
if (-not $AuthToken) {
    Write-Host "Enter new Vantage Auth Token (e.g., 'buligodata'):" -ForegroundColor Yellow
    $AuthToken = Read-Host
}

if (-not $ClientId) {
    Write-Host "Enter new Vantage Client ID (e.g., 'bexz40aUdxK5rQDSjS2BIUg=='):" -ForegroundColor Yellow
    $ClientId = Read-Host
}

Write-Host ""
Write-Host "Credentials to update:" -ForegroundColor Cyan
Write-Host "  Base URL: $BaseUrl" -ForegroundColor Gray
Write-Host "  Auth Token: $AuthToken" -ForegroundColor Gray
Write-Host "  Client ID: $ClientId" -ForegroundColor Gray
Write-Host ""

$confirm = Read-Host "Update Supabase secrets with these values? (y/n)"

if ($confirm -ne "y") {
    Write-Host ""
    Write-Host "[CANCELLED] No changes made" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Updating Supabase secrets..." -ForegroundColor Yellow

# Update secrets
try {
    Write-Host "  [1/3] Updating VANTAGE_API_BASE_URL..." -ForegroundColor Gray
    supabase secrets set VANTAGE_API_BASE_URL="$BaseUrl" 2>&1 | Out-Null

    Write-Host "  [2/3] Updating VANTAGE_AUTH_TOKEN..." -ForegroundColor Gray
    supabase secrets set VANTAGE_AUTH_TOKEN="$AuthToken" 2>&1 | Out-Null

    Write-Host "  [3/3] Updating VANTAGE_CLIENT_ID..." -ForegroundColor Gray
    supabase secrets set VANTAGE_CLIENT_ID="$ClientId" 2>&1 | Out-Null

    Write-Host ""
    Write-Host "[OK] Secrets updated successfully" -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "[FAIL] Error updating secrets: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Also update .env file
Write-Host ""
Write-Host "Updating .env file..." -ForegroundColor Yellow

$envPath = ".env"
if (Test-Path $envPath) {
    $envContent = Get-Content $envPath -Raw

    # Update VANTAGE credentials (with quotes for frontend)
    $envContent = $envContent -replace 'VANTAGE_API_BASE_URL="[^"]*"', "VANTAGE_API_BASE_URL=`"$BaseUrl`""
    $envContent = $envContent -replace 'VANTAGE_AUTH_TOKEN="[^"]*"', "VANTAGE_AUTH_TOKEN=`"$AuthToken`""
    $envContent = $envContent -replace 'VANTAGE_CLIENT_ID="[^"]*"', "VANTAGE_CLIENT_ID=`"$ClientId`""

    # Update ERP credentials (without quotes for backend)
    $envContent = $envContent -replace 'ERP_API_BASE_URL=.*', "ERP_API_BASE_URL=$BaseUrl"
    $envContent = $envContent -replace 'ERP_API_KEY=.*', "ERP_API_KEY=$AuthToken"
    $envContent = $envContent -replace 'ERP_CLIENT_ID=.*', "ERP_CLIENT_ID=$ClientId"

    Set-Content -Path $envPath -Value $envContent -NoNewline

    Write-Host "[OK] .env file updated" -ForegroundColor Green
}
else {
    Write-Host "[WARNING] .env file not found, skipping" -ForegroundColor Yellow
}

# Test the connection
Write-Host ""
Write-Host "Testing connection with new credentials..." -ForegroundColor Yellow
Write-Host ""

Start-Sleep -Seconds 2

& ".\test_vantage_auth.ps1"

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "  CREDENTIALS UPDATE COMPLETE" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. If the test passed, run: .\test_edge_function.ps1" -ForegroundColor White
Write-Host "  2. If successful, continue with deployment: .\EXECUTE_VANTAGE_DEPLOYMENT_FIXED.ps1" -ForegroundColor White
Write-Host ""
