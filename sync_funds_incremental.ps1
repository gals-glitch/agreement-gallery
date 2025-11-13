# Run incremental funds sync
$projectUrl = "https://qwgicrdcoqdketqhxbys.supabase.co"
$serviceRoleKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3Z2ljcmRjb3Fka2V0cWh4YnlzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzIyNjMwNywiZXhwIjoyMDcyODAyMzA3fQ.bPUTKQM-tOm1u_1NlVNXczSbA118443uOpeo2Waa2zo"

Write-Host ""
Write-Host "=========================================="
Write-Host "Vantage Funds Sync - INCREMENTAL"
Write-Host "=========================================="
Write-Host ""

$headers = @{
    'Authorization' = "Bearer $serviceRoleKey"
    'Content-Type' = 'application/json'
}

$body = @{
    mode = "incremental"
    resources = @("funds")
    dryRun = $false
} | ConvertTo-Json

Write-Host "Calling Edge Function..."
Write-Host ""

try {
    $response = Invoke-RestMethod -Uri "$projectUrl/functions/v1/vantage-sync" -Method Post -Headers $headers -Body $body

    Write-Host "SUCCESS!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Results:" -ForegroundColor Cyan
    $response | ConvertTo-Json -Depth 10 | Write-Host

    Write-Host ""
    Write-Host "Incremental funds sync completed successfully!" -ForegroundColor Green

} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host ""
        Write-Host "Response:" -ForegroundColor Yellow
        $_.ErrorDetails.Message | Write-Host
    }
}
