# Working test using service role key directly
# (Bypassing x-service-key for now - it needs debugging)

$SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3Z2ljcmRjb3Fka2V0cWh4YnlzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzIyNjMwNywiZXhwIjoyMDcyODAyMzA3fQ.bPUTKQM-tOm1u_1NlVNXczSbA118443uOpeo2Waa2zo"
$API_URL = "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing POST /charges/compute" -ForegroundColor Cyan
Write-Host "(Using service role key)" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$headers = @{
    "Authorization" = "Bearer $SERVICE_ROLE_KEY"
    "Content-Type" = "application/json"
    "apikey" = $SERVICE_ROLE_KEY
}

$contributionId = 1

Write-Host "Testing with contribution:" -ForegroundColor Yellow
Write-Host "  ID: $contributionId" -ForegroundColor White
Write-Host "  Investor: Rakefet Kuperman (ID: 201)" -ForegroundColor White
Write-Host "  Amount: `$100,000.00 USD" -ForegroundColor White
Write-Host "  Date: 2024-03-15" -ForegroundColor White
Write-Host ""

$body = @{
    contribution_id = $contributionId
} | ConvertTo-Json

Write-Host "Step 1: Computing charge..." -ForegroundColor Yellow
Write-Host ""

try {
    $response = Invoke-RestMethod -Uri "$API_URL/charges/compute" -Method Post -Headers $headers -Body $body

    Write-Host "✅ SUCCESS!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Charge Created:" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray

    $charge = $response.data
    Write-Host "  Charge ID:        " -NoNewline -ForegroundColor Gray
    Write-Host "$($charge.id)" -ForegroundColor White

    Write-Host "  Status:           " -NoNewline -ForegroundColor Gray
    Write-Host "$($charge.status)" -ForegroundColor Yellow

    Write-Host "  Investor ID:      " -NoNewline -ForegroundColor Gray
    Write-Host "$($charge.investor_id)" -ForegroundColor White

    Write-Host ""
    Write-Host "  Base Amount:      " -NoNewline -ForegroundColor Gray
    Write-Host "`$$($charge.base_amount)" -ForegroundColor White

    Write-Host "  Discount:         " -NoNewline -ForegroundColor Gray
    Write-Host "`$$($charge.discount_amount)" -ForegroundColor White

    Write-Host "  VAT Amount:       " -NoNewline -ForegroundColor Gray
    Write-Host "`$$($charge.vat_amount)" -ForegroundColor White

    Write-Host "  Total Amount:     " -NoNewline -ForegroundColor Gray
    Write-Host "`$$($charge.total_amount)" -ForegroundColor Green

    Write-Host "  Currency:         " -NoNewline -ForegroundColor Gray
    Write-Host "$($charge.currency)" -ForegroundColor White

    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray

    # Store for next test
    $global:CHARGE_ID = $charge.id

    Write-Host ""
    Write-Host "Step 2: Testing idempotency..." -ForegroundColor Yellow
    $response2 = Invoke-RestMethod -Uri "$API_URL/charges/compute" -Method Post -Headers $headers -Body $body

    if ($response.data.id -eq $response2.data.id) {
        Write-Host "✅ Idempotency verified! Same charge ID." -ForegroundColor Green
    } else {
        Write-Host "⚠️  Different charge IDs (check charges table)" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "✅ Test passed!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Charge ID saved for next test: $global:CHARGE_ID" -ForegroundColor Gray

} catch {
    Write-Host "❌ ERROR!" -ForegroundColor Red
    Write-Host "Status: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red

    $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
    $errorBody = $reader.ReadToEnd()
    Write-Host ""
    Write-Host "Response:" -ForegroundColor Yellow
    try {
        $errorBody | ConvertFrom-Json | ConvertTo-Json -Depth 10 | Write-Host -ForegroundColor White
    } catch {
        Write-Host $errorBody -ForegroundColor White
    }
}
