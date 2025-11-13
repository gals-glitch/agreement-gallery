# Simple test of /charges/compute endpoint
# Using contribution ID: 1 (Rakefet Kuperman, $100,000)

$SERVICE_KEY = "wxcNeAskSi7lJCjF4uLQ3RfbBZMpIzgr"
$API_URL = "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing POST /charges/compute" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3Z2ljcmRjb3Fka2V0cWh4YnlzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzIyNjMwNywiZXhwIjoyMDcyODAyMzA3fQ.bPUTKQM-tOm1u_1NlVNXczSbA118443uOpeo2Waa2zo"

$headers = @{
    "Authorization" = "Bearer $SERVICE_ROLE_KEY"
    "x-service-key" = $SERVICE_KEY
    "Content-Type" = "application/json"
    "apikey" = $SERVICE_ROLE_KEY
}

# Test with contribution ID 1 (Rakefet Kuperman)
$contributionId = 1

Write-Host "Testing with contribution:" -ForegroundColor Yellow
Write-Host "  ID: $contributionId" -ForegroundColor White
Write-Host "  Investor: Rakefet Kuperman (ID: 201)" -ForegroundColor White
Write-Host "  Amount: $100,000.00 USD" -ForegroundColor White
Write-Host "  Date: 2024-03-15" -ForegroundColor White
Write-Host ""

$body = @{
    contribution_id = $contributionId
} | ConvertTo-Json

Write-Host "Step 1: Computing charge..." -ForegroundColor Yellow
Write-Host "URL: $API_URL/charges/compute" -ForegroundColor Gray
Write-Host ""

try {
    $response = Invoke-RestMethod -Uri "$API_URL/charges/compute" -Method Post -Headers $headers -Body $body

    Write-Host "✅ SUCCESS!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Charge Created:" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray

    if ($response.data) {
        $charge = $response.data
        Write-Host "  Charge ID:        " -NoNewline -ForegroundColor Gray
        Write-Host "$($charge.id)" -ForegroundColor White

        Write-Host "  Status:           " -NoNewline -ForegroundColor Gray
        Write-Host "$($charge.status)" -ForegroundColor Yellow

        Write-Host "  Investor ID:      " -NoNewline -ForegroundColor Gray
        Write-Host "$($charge.investor_id)" -ForegroundColor White

        Write-Host "  Contribution ID:  " -NoNewline -ForegroundColor Gray
        Write-Host "$($charge.contribution_id)" -ForegroundColor White

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

        Write-Host ""
        Write-Host "  Computed At:      " -NoNewline -ForegroundColor Gray
        Write-Host "$($charge.computed_at)" -ForegroundColor Gray

        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray

        # Store charge ID for next test
        $global:CHARGE_ID = $charge.id

        Write-Host ""
        Write-Host "Step 2: Testing idempotency (calling again)..." -ForegroundColor Yellow

        $response2 = Invoke-RestMethod -Uri "$API_URL/charges/compute" -Method Post -Headers $headers -Body $body

        if ($response.data.id -eq $response2.data.id) {
            Write-Host "✅ Idempotency verified!" -ForegroundColor Green
            Write-Host "   Same charge ID returned: $($response2.data.id)" -ForegroundColor Gray
        } else {
            Write-Host "⚠️  Warning: Different charge ID returned" -ForegroundColor Yellow
            Write-Host "   First:  $($response.data.id)" -ForegroundColor Gray
            Write-Host "   Second: $($response2.data.id)" -ForegroundColor Gray
        }

        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "✅ Compute endpoint test passed!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Next step: Test charge submission (submit → auto-apply credits)" -ForegroundColor Yellow
        Write-Host "Charge ID for next test: $global:CHARGE_ID" -ForegroundColor Gray

    } else {
        Write-Host "⚠️  Response doesn't contain 'data' field" -ForegroundColor Yellow
        $response | ConvertTo-Json -Depth 10 | Write-Host -ForegroundColor White
    }

} catch {
    Write-Host "❌ ERROR!" -ForegroundColor Red
    Write-Host "Status Code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    Write-Host ""

    $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
    $errorBody = $reader.ReadToEnd()
    Write-Host "Response Body:" -ForegroundColor Yellow

    try {
        $errorJson = $errorBody | ConvertFrom-Json
        $errorJson | ConvertTo-Json -Depth 10 | Write-Host -ForegroundColor White

        Write-Host ""
        if ($errorJson.code -eq "VALIDATION_ERROR") {
            Write-Host "Validation errors:" -ForegroundColor Yellow
            foreach ($detail in $errorJson.details) {
                Write-Host "  • $($detail.field): $($detail.message)" -ForegroundColor Red
            }
        }
    } catch {
        Write-Host $errorBody -ForegroundColor White
    }
}
