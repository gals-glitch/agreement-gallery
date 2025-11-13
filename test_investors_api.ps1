$env:SUPABASE_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3Z2ljcmRjb3Fka2V0cWh4YnlzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzIyNjMwNywiZXhwIjoyMDcyODAyMzA3fQ.bPUTKQM-tOm1u_1NlVNXczSbA118443uOpeo2Waa2zo'

$headers = @{
    'Authorization' = "Bearer $env:SUPABASE_SERVICE_ROLE_KEY"
    'apikey' = $env:SUPABASE_SERVICE_ROLE_KEY
    'Content-Type' = 'application/json'
}

Write-Host "Testing investors API endpoint..." -ForegroundColor Cyan
Write-Host ""

try {
    $response = Invoke-WebRequest -Uri 'https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1/investors?limit=10&offset=0' -Headers $headers -Method Get
    Write-Host "SUCCESS!" -ForegroundColor Green
    Write-Host "Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host ""
    Write-Host "Response:" -ForegroundColor Yellow
    $response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 5
} catch {
    Write-Host "ERROR!" -ForegroundColor Red
    Write-Host "Status: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    Write-Host ""

    if ($_.Exception.Response) {
        $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Error Response:" -ForegroundColor Yellow
        Write-Host $responseBody
    } else {
        Write-Host $_.Exception.Message
    }
}
