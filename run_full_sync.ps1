# Run Full Vantage Sync (All 2,097 Accounts)
# Run with: powershell -ExecutionPolicy Bypass -File run_full_sync.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  VANTAGE FULL SYNC" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This will sync ALL 2,097 accounts from Vantage to the database." -ForegroundColor Yellow
Write-Host ""

$confirm = Read-Host "Are you sure you want to proceed? (yes/no)"

if ($confirm -ne 'yes') {
    Write-Host "Sync cancelled." -ForegroundColor Yellow
    exit
}

Write-Host ""
Write-Host "Starting full sync..." -ForegroundColor Green
Write-Host ""

$serviceRoleKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3Z2ljcmRjb3Fka2V0cWh4YnlzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzIyNjMwNywiZXhwIjoyMDcyODAyMzA3fQ.bPUTKQM-tOm1u_1NlVNXczSbA118443uOpeo2Waa2zo"

$headers = @{
    'Authorization' = "Bearer $serviceRoleKey"
    'apikey' = $serviceRoleKey
    'Content-Type' = 'application/json'
}

$url = "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/vantage-sync"

$body = @{
    mode = "full"
    resources = @("accounts")
    dryRun = $false
} | ConvertTo-Json

try {
    Write-Host "Syncing accounts from Vantage..." -ForegroundColor Yellow
    $startTime = Get-Date

    $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body

    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  SYNC COMPLETED SUCCESSFULLY!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""

    $result = $response.results.accounts

    Write-Host "Summary:" -ForegroundColor Cyan
    Write-Host "  Total Time: $([math]::Round($duration, 2)) seconds" -ForegroundColor White
    Write-Host "  Records Processed: $($result.recordsProcessed)" -ForegroundColor White
    Write-Host "  Records Created: $($result.recordsCreated)" -ForegroundColor White
    Write-Host "  Records Updated: $($result.recordsUpdated)" -ForegroundColor White
    Write-Host "  Errors: $($result.errors.Count)" -ForegroundColor White
    Write-Host ""

    if ($result.errors.Count -gt 0) {
        Write-Host "Errors:" -ForegroundColor Red
        foreach ($error in $result.errors) {
            Write-Host "  - Record $($error.recordId): [$($error.field)] $($error.message)" -ForegroundColor Yellow
        }
        Write-Host ""
    }

    Write-Host "Next steps:" -ForegroundColor Green
    Write-Host "1. Verify data: Open app and check Investors page" -ForegroundColor Cyan
    Write-Host "2. Check sync state: SELECT * FROM vantage_sync_state WHERE resource='accounts';" -ForegroundColor Cyan
    Write-Host "3. Sync funds: Update run_full_sync.ps1 to include 'funds' in resources array" -ForegroundColor Cyan

} catch {
    Write-Host ""
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red

    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response Body:" -ForegroundColor Yellow
        Write-Host $responseBody -ForegroundColor White
    }

    exit 1
}

Write-Host ""
