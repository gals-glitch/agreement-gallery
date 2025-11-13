# Verify constraint exists and run full sync
# This script checks if the UNIQUE constraint is applied before running the sync

$projectUrl = "https://qwgicrdcoqdketqhxbys.supabase.co"
$serviceRoleKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3Z2ljcmRjb3Fka2V0cWh4YnlzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzIyNjMwNywiZXhwIjoyMDcyODAyMzA3fQ.bPUTKQM-tOm1u_1NlVNXczSbA118443uOpeo2Waa2zo"

Write-Host ""
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "Vantage Full Sync - Pre-Flight Check" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

$headers = @{
    'apikey' = $serviceRoleKey
    'Authorization' = "Bearer $serviceRoleKey"
    'Content-Type' = 'application/json'
}

# Try to check if constraint exists by doing a test upsert
Write-Host "Checking if UNIQUE constraint on external_id exists..." -ForegroundColor Yellow

$testInvestor = @{
    name = "Test Constraint Check"
    external_id = "test-constraint-check-12345"
    currency = "USD"
}

try {
    $upsertUrl = "$projectUrl/rest/v1/investors?on_conflict=external_id"
    $body = $testInvestor | ConvertTo-Json

    $response = Invoke-RestMethod -Uri $upsertUrl -Method Post -Headers $headers -Body $body -ErrorAction Stop

    Write-Host "SUCCESS: Constraint exists!" -ForegroundColor Green
    Write-Host ""

    # Delete test record
    $deleteUrl = "$projectUrl/rest/v1/investors?external_id=eq.test-constraint-check-12345"
    Invoke-RestMethod -Uri $deleteUrl -Method Delete -Headers $headers | Out-Null

    Write-Host "Proceeding with full sync..." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "===========================================" -ForegroundColor Cyan
    Write-Host ""

    # Run the full sync
    powershell -ExecutionPolicy Bypass -File quick_sync.ps1

} catch {
    $errorMessage = $_.Exception.Message

    if ($errorMessage -like "*no unique or exclusion constraint*") {
        Write-Host "ERROR: UNIQUE constraint NOT found!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please apply this SQL in the Supabase SQL Editor first:" -ForegroundColor Yellow
        Write-Host "https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys/sql/new" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "ALTER TABLE investors" -ForegroundColor White
        Write-Host "ADD CONSTRAINT investors_external_id_unique UNIQUE (external_id);" -ForegroundColor White
        Write-Host ""
        Write-Host "The SQL has been copied to clipboard." -ForegroundColor Green

        @"
ALTER TABLE investors
ADD CONSTRAINT investors_external_id_unique UNIQUE (external_id);
"@ | Set-Clipboard

    } else {
        Write-Host "ERROR: Unexpected error during constraint check" -ForegroundColor Red
        Write-Host $errorMessage -ForegroundColor Red
    }

    Write-Host ""
    exit 1
}

Write-Host ""
