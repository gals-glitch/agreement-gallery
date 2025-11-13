# Smoke Test 4: Approve Charge (PENDING → APPROVED)
# Requires Admin role

$headers = @{
    "Authorization" = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3Z2ljcmRjb3Fka2V0cWh4YnlzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzIyNjMwNywiZXhwIjoyMDcyODAyMzA3fQ.bPUTKQM-tOm1u_1NlVNXczSbA118443uOpeo2Waa2zo"
    "Content-Type" = "application/json"
    "apikey" = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3Z2ljcmRjb3Fka2V0cWh4YnlzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzIyNjMwNywiZXhwIjoyMDcyODAyMzA3fQ.bPUTKQM-tOm1u_1NlVNXczSbA118443uOpeo2Waa2zo"
}

$chargeId = "35adb020-361a-4a4a-94c7-6e1f87f35a4e"
$uri = "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1/charges/$chargeId/approve"

Write-Host "✅ Approving charge..." -ForegroundColor Cyan
Write-Host "Charge ID: $chargeId" -ForegroundColor Gray
Write-Host "Expected: Status changes PENDING → APPROVED" -ForegroundColor Gray
Write-Host ""

try {
    $body = @{} | ConvertTo-Json
    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body

    Write-Host "✅ SUCCESS! Charge approved:" -ForegroundColor Green
    Write-Host ""
    $response | ConvertTo-Json -Depth 10
    Write-Host ""

    Write-Host "Key Values:" -ForegroundColor Yellow
    Write-Host "  Status: $($response.status)" -ForegroundColor White
    Write-Host "  Approved At: $($response.approved_at)" -ForegroundColor White
    Write-Host "  Approved By: $($response.approved_by)" -ForegroundColor White

} catch {
    Write-Host "❌ ERROR!" -ForegroundColor Red
    Write-Host "Status Code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    Write-Host "Error Message: $($_.Exception.Message)" -ForegroundColor Red

    if ($_.ErrorDetails.Message) {
        Write-Host ""
        Write-Host "Error Details:" -ForegroundColor Yellow
        Write-Host $_.ErrorDetails.Message -ForegroundColor White
    }

    if ($_.Exception.Response) {
        try {
            $result = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($result)
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $responseBody = $reader.ReadToEnd()
            if ($responseBody) {
                Write-Host ""
                Write-Host "Response Body:" -ForegroundColor Yellow
                Write-Host $responseBody -ForegroundColor White
            }
        } catch {
            Write-Host "Could not read response stream" -ForegroundColor Gray
        }
    }
}
