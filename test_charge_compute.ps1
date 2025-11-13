# Smoke Test 1: Compute Draft Charge
# Run this script in PowerShell: .\test_charge_compute.ps1

$headers = @{
    "Authorization" = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3Z2ljcmRjb3Fka2V0cWh4YnlzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzIyNjMwNywiZXhwIjoyMDcyODAyMzA3fQ.bPUTKQM-tOm1u_1NlVNXczSbA118443uOpeo2Waa2zo"
    "Content-Type" = "application/json"
    "apikey" = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3Z2ljcmRjb3Fka2V0cWh4YnlzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzIyNjMwNywiZXhwIjoyMDcyODAyMzA3fQ.bPUTKQM-tOm1u_1NlVNXczSbA118443uOpeo2Waa2zo"
}

$body = @{
    contribution_id = 1
} | ConvertTo-Json

Write-Host "Making POST request to create charge..." -ForegroundColor Cyan
Write-Host "URL: https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1/charges" -ForegroundColor Gray
Write-Host "Body: $body" -ForegroundColor Gray
Write-Host ""

try {
    $response = Invoke-RestMethod -Uri "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1/charges" `
                                   -Method Post `
                                   -Headers $headers `
                                   -Body $body

    Write-Host "✅ SUCCESS! Charge created:" -ForegroundColor Green
    Write-Host ""
    $response | ConvertTo-Json -Depth 10
    Write-Host ""

    # Show key values
    Write-Host "Key Values:" -ForegroundColor Yellow
    Write-Host "  Charge ID: $($response.id)" -ForegroundColor White
    Write-Host "  Numeric ID: $($response.numeric_id)" -ForegroundColor White
    Write-Host "  Status: $($response.status)" -ForegroundColor White
    Write-Host "  Base Amount: `$$($response.base_amount)" -ForegroundColor White
    Write-Host "  VAT Amount: `$$($response.vat_amount)" -ForegroundColor White
    Write-Host "  Total Amount: `$$($response.total_amount)" -ForegroundColor White

} catch {
    Write-Host "❌ ERROR!" -ForegroundColor Red
    Write-Host "Status Code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    Write-Host "Error Message: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""

    # Try to get full error details
    if ($_.ErrorDetails.Message) {
        Write-Host "Error Details:" -ForegroundColor Yellow
        Write-Host $_.ErrorDetails.Message -ForegroundColor White
    }

    # Alternative method to read response stream
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
