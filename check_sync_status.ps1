# Check Sync Status
# Run with: powershell -ExecutionPolicy Bypass -File check_sync_status.ps1

Write-Host "Checking Vantage Sync Status..." -ForegroundColor Cyan
Write-Host ""

# Database connection string
$projectUrl = "https://qwgicrdcoqdketqhxbys.supabase.co"
$serviceRoleKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3Z2ljcmRjb3Fka2V0cWh4YnlzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzIyNjMwNywiZXhwIjoyMDcyODAyMzA3fQ.bPUTKQM-tOm1u_1NlVNXczSbA118443uOpeo2Waa2zo"

$headers = @{
    'apikey' = $serviceRoleKey
    'Authorization' = "Bearer $serviceRoleKey"
    'Content-Type' = 'application/json'
}

# Query sync state
$syncStateUrl = "$projectUrl/rest/v1/vantage_sync_state?resource=eq.accounts&select=*"

try {
    $syncState = Invoke-RestMethod -Uri $syncStateUrl -Headers $headers -Method Get

    if ($syncState -and $syncState.Count -gt 0) {
        $state = $syncState[0]

        Write-Host "=== SYNC STATE ===" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Resource: $($state.resource)" -ForegroundColor White
        Write-Host "Status: $($state.last_sync_status)" -ForegroundColor $(
            switch ($state.last_sync_status) {
                'success' { 'Green' }
                'failed' { 'Red' }
                'running' { 'Yellow' }
                default { 'White' }
            }
        )

        if ($state.last_sync_time) {
            $lastSync = [DateTime]::Parse($state.last_sync_time)
            Write-Host "Last Sync: $($lastSync.ToString('yyyy-MM-dd HH:mm:ss')) UTC" -ForegroundColor White
            $elapsed = (Get-Date).ToUniversalTime() - $lastSync
            Write-Host "Time Elapsed: $([math]::Round($elapsed.TotalMinutes, 1)) minutes ago" -ForegroundColor Gray
        } else {
            Write-Host "Last Sync: Never" -ForegroundColor Gray
        }

        Write-Host ""
        Write-Host "Records Synced: $($state.records_synced)" -ForegroundColor White
        Write-Host "Records Created: $($state.records_created)" -ForegroundColor Green
        Write-Host "Records Updated: $($state.records_updated)" -ForegroundColor Yellow

        if ($state.duration_ms) {
            Write-Host "Duration: $([math]::Round($state.duration_ms / 1000, 2))s" -ForegroundColor White
        }

        if ($state.errors -and $state.errors -ne '[]') {
            Write-Host ""
            Write-Host "Errors:" -ForegroundColor Red
            $errorObj = $state.errors | ConvertFrom-Json
            foreach ($err in $errorObj) {
                Write-Host "  - [$($err.field)] $($err.message)" -ForegroundColor Yellow
                if ($err.recordId) {
                    Write-Host "    Record ID: $($err.recordId)" -ForegroundColor Gray
                }
            }
        }

        Write-Host ""
        Write-Host "Started At: $($state.started_at)" -ForegroundColor Gray
        Write-Host "Completed At: $($state.completed_at)" -ForegroundColor Gray

    } else {
        Write-Host "No sync state found for 'accounts' resource" -ForegroundColor Yellow
        Write-Host "This might mean the first sync hasn't started yet." -ForegroundColor Gray
    }

} catch {
    Write-Host "Error querying sync state: $($_.Exception.Message)" -ForegroundColor Red
}

# Query investor count
Write-Host ""
Write-Host "=== INVESTOR COUNT ===" -ForegroundColor Cyan
Write-Host ""

$investorsUrl = "$projectUrl/rest/v1/investors?external_id=not.is.null&select=id"

try {
    $response = Invoke-RestMethod -Uri $investorsUrl -Headers $headers -Method Head
    $count = $response.Headers['Content-Range'] -replace '.*/', ''

    Write-Host "Investors with external_id: $count" -ForegroundColor White
    Write-Host "(Expected: 2097 after full sync)" -ForegroundColor Gray

} catch {
    # Try alternative method
    try {
        $investors = Invoke-RestMethod -Uri "$projectUrl/rest/v1/investors?external_id=not.is.null&select=id" -Headers $headers
        Write-Host "Investors with external_id: $($investors.Count)" -ForegroundColor White
    } catch {
        Write-Host "Could not query investor count" -ForegroundColor Yellow
    }
}

Write-Host ""
