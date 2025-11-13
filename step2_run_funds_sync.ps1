# Step 2: Run full and incremental funds sync

$ErrorActionPreference = "Stop"

# Load environment
if (Test-Path .env) {
    Get-Content .env | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+?)\s*=\s*(.+?)\s*$') {
            [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
        }
    }
}

$serviceKey = $env:SUPABASE_SERVICE_ROLE_KEY
$projectUrl = $env:SUPABASE_URL

if (-not $serviceKey -or -not $projectUrl) {
    Write-Host "ERROR: Missing SUPABASE_SERVICE_ROLE_KEY or SUPABASE_URL in .env" -ForegroundColor Red
    exit 1
}

$functionsUrl = "$projectUrl/functions/v1/vantage-sync"

Write-Host ""
Write-Host "=== STEP 2: Run Funds Sync ===" -ForegroundColor Cyan

# Step 2A: Full funds backfill
Write-Host ""
Write-Host "[2A] Running FULL funds backfill..." -ForegroundColor Yellow

$fullBody = @{
    mode = "full"
    resources = @("accounts", "funds")
} | ConvertTo-Json

try {
    $fullResponse = Invoke-RestMethod -Uri $functionsUrl `
        -Method Post `
        -Headers @{
            "Authorization" = "Bearer $serviceKey"
            "Content-Type" = "application/json"
        } `
        -Body $fullBody `
        -TimeoutSec 120

    Write-Host ""
    Write-Host "[OK] Full sync response:" -ForegroundColor Green
    $fullResponse | ConvertTo-Json -Depth 5

    if ($fullResponse.success -eq $true) {
        Write-Host ""
        Write-Host "[OK] Full funds sync completed successfully" -ForegroundColor Green
        Write-Host "  - Accounts synced: $($fullResponse.results.accounts.synced)" -ForegroundColor Cyan
        Write-Host "  - Funds synced: $($fullResponse.results.funds.synced)" -ForegroundColor Cyan
    }
    else {
        Write-Host ""
        Write-Host "[FAIL] Full sync reported errors" -ForegroundColor Red
        $fullResponse.results | ConvertTo-Json -Depth 5
    }
}
catch {
    Write-Host ""
    Write-Host "[FAIL] Full sync failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.Exception | Format-List -Force
    exit 1
}

# Wait a bit before incremental
Write-Host ""
Write-Host "Waiting 5 seconds before incremental sync..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Step 2B: Incremental sync (sanity check - should be near-zero updates)
Write-Host ""
Write-Host "[2B] Running INCREMENTAL funds sync (sanity check)..." -ForegroundColor Yellow

$incBody = @{
    mode = "incremental"
    resources = @("accounts", "funds")
} | ConvertTo-Json

try {
    $incResponse = Invoke-RestMethod -Uri $functionsUrl `
        -Method Post `
        -Headers @{
            "Authorization" = "Bearer $serviceKey"
            "Content-Type" = "application/json"
        } `
        -Body $incBody `
        -TimeoutSec 120

    Write-Host ""
    Write-Host "[OK] Incremental sync response:" -ForegroundColor Green
    $incResponse | ConvertTo-Json -Depth 5

    if ($incResponse.success -eq $true) {
        Write-Host ""
        Write-Host "[OK] Incremental sync completed successfully" -ForegroundColor Green
        Write-Host "  - Accounts synced: $($incResponse.results.accounts.synced)" -ForegroundColor Cyan
        Write-Host "  - Funds synced: $($incResponse.results.funds.synced)" -ForegroundColor Cyan

        if ($incResponse.results.funds.synced -gt 0) {
            Write-Host "  [WARNING] Expected near-zero updates on incremental after full sync" -ForegroundColor Yellow
        }
        else {
            Write-Host "  [OK] As expected: no updates needed" -ForegroundColor Green
        }
    }
    else {
        Write-Host ""
        Write-Host "[FAIL] Incremental sync reported errors" -ForegroundColor Red
        $incResponse.results | ConvertTo-Json -Depth 5
    }
}
catch {
    Write-Host ""
    Write-Host "[FAIL] Incremental sync failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.Exception | Format-List -Force
    exit 1
}

Write-Host ""
Write-Host "=== Step 2 Complete ===" -ForegroundColor Green
Write-Host "Run step2_verify_funds.ps1 to check the results" -ForegroundColor Cyan
