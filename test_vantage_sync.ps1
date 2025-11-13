# Test Vantage Sync Edge Function
# Run with: powershell -ExecutionPolicy Bypass -File test_vantage_sync.ps1

Write-Host "Testing Vantage Sync Edge Function..." -ForegroundColor Cyan
Write-Host ""

# Get service role key from .env
$envFile = Get-Content .env
$serviceRoleKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3Z2ljcmRjb3Fka2V0cWh4YnlzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzIyNjMwNywiZXhwIjoyMDcyODAyMzA3fQ.bPUTKQM-tOm1u_1NlVNXczSbA118443uOpeo2Waa2zo"

$headers = @{
    'Authorization' = "Bearer $serviceRoleKey"
    'apikey' = $serviceRoleKey
    'Content-Type' = 'application/json'
}

$url = "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/vantage-sync"

# Test 1: Dry Run (validate only, don't save)
Write-Host "Test 1: Dry Run (validate only)..." -ForegroundColor Yellow
$body = @{
    mode = "full"
    resources = @("accounts")
    dryRun = $true
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body
    Write-Host "SUCCESS! Dry run completed." -ForegroundColor Green
    Write-Host "Results:" -ForegroundColor Cyan
    Write-Host ($response | ConvertTo-Json -Depth 10)
    Write-Host ""
} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red

    # Try to get response body for detailed error info
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

# Test 2: Small Batch Sync (10 accounts)
Write-Host "Test 2: Small Batch Sync (first 10 accounts)..." -ForegroundColor Yellow
Write-Host "NOTE: This will actually insert data!" -ForegroundColor Yellow
$confirm = Read-Host "Continue? (y/n)"

if ($confirm -eq 'y') {
    $body = @{
        mode = "full"
        resources = @("accounts")
        dryRun = $false
        limit = 10  # Only sync first 10
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body
        Write-Host "SUCCESS! Batch sync completed." -ForegroundColor Green
        Write-Host "Results:" -ForegroundColor Cyan
        Write-Host ($response | ConvertTo-Json -Depth 10)
        Write-Host ""

        # Show records created
        if ($response.results.accounts) {
            $result = $response.results.accounts
            Write-Host "Summary:" -ForegroundColor Cyan
            Write-Host "  Records Processed: $($result.recordsProcessed)"
            Write-Host "  Records Created: $($result.recordsCreated)"
            Write-Host "  Records Updated: $($result.recordsUpdated)"
            Write-Host "  Errors: $($result.errors.Count)"
            Write-Host "  Duration: $($result.duration)ms"
        }
    } catch {
        Write-Host "ERROR: $_" -ForegroundColor Red

        # Try to get response body for detailed error info
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $responseBody = $reader.ReadToEnd()
            Write-Host "Response Body:" -ForegroundColor Yellow
            Write-Host $responseBody -ForegroundColor White
        }
    }
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Green
Write-Host "1. Check investors table: SELECT COUNT(*) FROM investors;" -ForegroundColor Cyan
Write-Host "2. Check sync state: SELECT * FROM vantage_sync_state WHERE resource='accounts';" -ForegroundColor Cyan
Write-Host "3. Run full sync for all 2,097 accounts (remove limit parameter)" -ForegroundColor Cyan
