# Test Edge Function with deployed Supabase secrets

$serviceKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3Z2ljcmRjb3Fka2V0cWh4YnlzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzIyNjMwNywiZXhwIjoyMDcyODAyMzA3fQ.bPUTKQM-tOm1u_1NlVNXczSbA118443uOpeo2Waa2zo"
$url = "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/vantage-sync"

Write-Host "Testing Edge Function with Supabase secrets..." -ForegroundColor Cyan

$body = @{
    mode = "full"
    resources = @("accounts", "funds")
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest -Uri $url `
        -Method Post `
        -Headers @{
            "Authorization" = "Bearer $serviceKey"
            "Content-Type" = "application/json"
        } `
        -Body $body `
        -TimeoutSec 60

    $responseData = $response.Content | ConvertFrom-Json
    Write-Host ""
    Write-Host "[OK] Edge Function responded (Status: $($response.StatusCode)):" -ForegroundColor Green
    $responseData | ConvertTo-Json -Depth 10
}
catch {
    Write-Host ""
    Write-Host "[FAIL] HTTP Status: $($_.Exception.Response.StatusCode.Value__)" -ForegroundColor Red

    # Try to get response body with error details
    if ($_.Exception.Response) {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $responseBody = $reader.ReadToEnd()
        $reader.Close()
        $stream.Close()

        Write-Host ""
        Write-Host "Response body:" -ForegroundColor Yellow
        Write-Host $responseBody

        # Try to parse as JSON to see error details
        try {
            $jsonResponse = $responseBody | ConvertFrom-Json
            Write-Host ""
            Write-Host "Parsed error response:" -ForegroundColor Cyan
            $jsonResponse | ConvertTo-Json -Depth 10
        }
        catch {
            Write-Host "Could not parse as JSON" -ForegroundColor Gray
        }
    }
}
