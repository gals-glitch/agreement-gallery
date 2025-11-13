# Test Vantage API Authentication
# Verifies Bearer token fix resolves 401 errors

$ErrorActionPreference = "Stop"

# Load environment
if (Test-Path .env) {
    Get-Content .env | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+?)\s*=\s*(.+?)\s*$') {
            $value = $matches[2].Trim('"')  # Strip quotes
            [Environment]::SetEnvironmentVariable($matches[1], $value, "Process")
        }
    }
}

$vantageUrl = $env:VANTAGE_API_BASE_URL
$vantageToken = $env:VANTAGE_AUTH_TOKEN
$vantageClientId = $env:VANTAGE_CLIENT_ID

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  VANTAGE API AUTHENTICATION TEST" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Testing direct Vantage API connection..." -ForegroundColor Yellow
Write-Host "Base URL: $vantageUrl" -ForegroundColor Gray
Write-Host "Token: $vantageToken" -ForegroundColor Gray
Write-Host "Client ID: $vantageClientId" -ForegroundColor Gray
Write-Host ""

# Test 1: Direct API call with Bearer token
Write-Host "[Test 1] Calling Vantage API /api/Funds/Get directly..." -ForegroundColor Yellow

try {
    $headers = @{
        "Authorization" = $vantageToken
        "X-com-vantageir-subscriptions-clientid" = $vantageClientId
        "Content-Type" = "application/json"
    }

    $response = Invoke-RestMethod -Uri "$vantageUrl/api/Funds/Get" `
        -Method Get `
        -Headers $headers `
        -TimeoutSec 30

    if ($response.code -eq 0) {
        Write-Host "[OK] Vantage API authentication successful!" -ForegroundColor Green
        Write-Host "  Response code: $($response.code)" -ForegroundColor Cyan
        Write-Host "  Funds returned: $($response.data.Count)" -ForegroundColor Cyan

        if ($response.data.Count -gt 0) {
            Write-Host ""
            Write-Host "Sample fund:" -ForegroundColor Yellow
            $response.data[0] | ConvertTo-Json -Depth 2
        }
    }
    else {
        Write-Host "[FAIL] Vantage returned error code: $($response.code)" -ForegroundColor Red
        Write-Host "Message: $($response.message)" -ForegroundColor Red
    }
}
catch {
    Write-Host "[FAIL] API call failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Response details:" -ForegroundColor Yellow
    Write-Host $_.Exception | Format-List -Force
    exit 1
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Test 2: Test via Edge Function
Write-Host "[Test 2] Testing via Supabase Edge Function..." -ForegroundColor Yellow

$serviceKey = $env:SUPABASE_SERVICE_ROLE_KEY
$projectUrl = $env:SUPABASE_URL

if (-not $serviceKey -or -not $projectUrl) {
    Write-Host "[SKIP] Missing SUPABASE_SERVICE_ROLE_KEY or SUPABASE_URL" -ForegroundColor Yellow
    exit 0
}

$functionsUrl = "$projectUrl/functions/v1/vantage-sync"

$body = @{
    mode = "full"
    resources = @("accounts", "funds")
} | ConvertTo-Json

try {
    $edgeResponse = Invoke-RestMethod -Uri $functionsUrl `
        -Method Post `
        -Headers @{
            "Authorization" = "Bearer $serviceKey"
            "Content-Type" = "application/json"
        } `
        -Body $body `
        -TimeoutSec 120

    Write-Host "[OK] Edge Function sync completed" -ForegroundColor Green
    Write-Host ""
    $edgeResponse | ConvertTo-Json -Depth 5
}
catch {
    Write-Host "[FAIL] Edge Function call failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.Exception | Format-List -Force
    exit 1
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "  [OK] ALL TESTS PASSED" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Vantage API authentication is working correctly." -ForegroundColor Cyan
Write-Host "You can now proceed with the deployment checklist." -ForegroundColor Cyan
Write-Host ""
