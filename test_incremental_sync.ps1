# Test incremental sync to get better error details

$serviceKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3Z2ljcmRjb3Fka2V0cWh4YnlzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzIyNjMwNywiZXhwIjoyMDcyODAyMzA3fQ.bPUTKQM-tOm1u_1NlVNXczSbA118443uOpeo2Waa2zo"
$url = "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/vantage-sync"

Write-Host "Testing incremental sync..." -ForegroundColor Cyan

$body = @{
    mode = "incremental"
    resources = @("accounts", "funds")
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri $url `
        -Method Post `
        -Headers @{
            "Authorization" = "Bearer $serviceKey"
            "Content-Type" = "application/json"
        } `
        -Body $body `
        -TimeoutSec 60

    Write-Host ""
    Write-Host "[OK] Incremental sync completed:" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 5
}
catch {
    $errorDetails = $_.ErrorDetails.Message
    Write-Host ""
    Write-Host "[FAIL] Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($errorDetails) {
        Write-Host "Error details: $errorDetails" -ForegroundColor Yellow
    }
}
