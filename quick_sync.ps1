# Quick Sync - No Prompts
# Run with: powershell -ExecutionPolicy Bypass -File quick_sync.ps1

param(
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false,

    [Parameter(Mandatory=$false)]
    [int]$Limit = 0
)

Write-Host "Vantage Sync" -ForegroundColor Cyan
Write-Host "Mode: $(if ($DryRun) { 'DRY RUN (validation only)' } else { 'LIVE SYNC' })" -ForegroundColor Yellow
if ($Limit -gt 0) {
    Write-Host "Limit: First $Limit accounts" -ForegroundColor Yellow
}
Write-Host ""

$serviceRoleKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3Z2ljcmRjb3Fka2V0cWh4YnlzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzIyNjMwNywiZXhwIjoyMDcyODAyMzA3fQ.bPUTKQM-tOm1u_1NlVNXczSbA118443uOpeo2Waa2zo"

$headers = @{
    'Authorization' = "Bearer $serviceRoleKey"
    'apikey' = $serviceRoleKey
    'Content-Type' = 'application/json'
}

$url = "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/vantage-sync"

$bodyObj = @{
    mode = "full"
    resources = @("accounts")
    dryRun = $DryRun.IsPresent
}

if ($Limit -gt 0) {
    $bodyObj.limit = $Limit
}

$body = $bodyObj | ConvertTo-Json

Write-Host "Calling Edge Function..." -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body -ErrorAction Stop

    Write-Host ""
    Write-Host "SUCCESS!" -ForegroundColor Green
    Write-Host ""

    $result = $response.results.accounts
    Write-Host "Status: $($result.status)" -ForegroundColor Cyan
    Write-Host "Processed: $($result.recordsProcessed)" -ForegroundColor White
    Write-Host "Created: $($result.recordsCreated)" -ForegroundColor Green
    Write-Host "Updated: $($result.recordsUpdated)" -ForegroundColor Yellow
    Write-Host "Errors: $($result.errors.Count)" -ForegroundColor $(if ($result.errors.Count -gt 0) { 'Red' } else { 'White' })
    Write-Host "Duration: $([math]::Round($result.duration / 1000, 2))s" -ForegroundColor White

    if ($result.errors.Count -gt 0) {
        Write-Host ""
        Write-Host "Error Details:" -ForegroundColor Red
        foreach ($err in $result.errors) {
            Write-Host "  [$($err.field)] $($err.message) (Record: $($err.recordId))" -ForegroundColor Yellow
        }
    }

} catch {
    Write-Host ""
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red

    if ($_.Exception.Response) {
        try {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $responseBody = $reader.ReadToEnd()
            Write-Host ""
            Write-Host "Response:" -ForegroundColor Yellow
            Write-Host $responseBody -ForegroundColor White
        } catch {
            Write-Host "Could not read response body" -ForegroundColor Yellow
        }
    }

    exit 1
}

Write-Host ""
