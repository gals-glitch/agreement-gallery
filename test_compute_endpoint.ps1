# Test /charges/compute endpoint with service key
# This tests the new idempotent compute endpoint

$SERVICE_KEY = "wxcNeAskSi7lJCjF4uLQ3RfbBZMpIzgr"
$API_URL = "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing POST /charges/compute" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# STEP 1: Provide a contribution ID
Write-Host "Step 1: Enter a contribution ID to test..." -ForegroundColor Yellow
Write-Host ""
Write-Host "To get a contribution ID:" -ForegroundColor Gray
Write-Host "  1. Go to: https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys/editor" -ForegroundColor Gray
Write-Host "  2. Run: SELECT id FROM contributions LIMIT 1;" -ForegroundColor Gray
Write-Host "  3. Copy the 'id' value" -ForegroundColor Gray
Write-Host ""
$contributionId = Read-Host "Enter contribution ID (UUID format)"

if ([string]::IsNullOrWhiteSpace($contributionId)) {
    Write-Host "❌ No contribution ID provided" -ForegroundColor Red
    exit
}

Write-Host "✅ Using contribution ID: $contributionId" -ForegroundColor Green
Write-Host ""

$headers = @{
    "x-service-key" = $SERVICE_KEY
    "Content-Type" = "application/json"
    "apikey" = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3Z2ljcmRjb3Fka2V0cWh4YnlzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzIyNjMwNywiZXhwIjoyMDcyODAyMzA3fQ.bPUTKQM-tOm1u_1NlVNXczSbA118443uOpeo2Waa2zo"
}

# Now test compute endpoint
Write-Host "Step 2: Computing charge for contribution..." -ForegroundColor Yellow
Write-Host "URL: $API_URL/charges/compute" -ForegroundColor Gray

$body = @{
    contribution_id = $contributionId
} | ConvertTo-Json

Write-Host "Body: $body" -ForegroundColor Gray
Write-Host ""

try {
    $response = Invoke-RestMethod -Uri "$API_URL/charges/compute" -Method Post -Headers $headers -Body $body

    Write-Host "✅ SUCCESS!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Charge Details:" -ForegroundColor Cyan
    Write-Host "  ID: $($response.data.id)" -ForegroundColor White
    Write-Host "  Status: $($response.data.status)" -ForegroundColor White
    Write-Host "  Investor ID: $($response.data.investor_id)" -ForegroundColor White
    Write-Host "  Base Amount: $($response.data.base_amount)" -ForegroundColor White
    Write-Host "  Discount Amount: $($response.data.discount_amount)" -ForegroundColor White
    Write-Host "  VAT Amount: $($response.data.vat_amount)" -ForegroundColor White
    Write-Host "  Total Amount: $($response.data.total_amount)" -ForegroundColor Yellow
    Write-Host "  Currency: $($response.data.currency)" -ForegroundColor White
    Write-Host "  Computed At: $($response.data.computed_at)" -ForegroundColor Gray
    Write-Host ""

    # Test idempotency - call again with same contribution
    Write-Host "Step 3: Testing idempotency (calling again with same contribution)..." -ForegroundColor Yellow

    $response2 = Invoke-RestMethod -Uri "$API_URL/charges/compute" -Method Post -Headers $headers -Body $body

    if ($response.data.id -eq $response2.data.id) {
        Write-Host "✅ Idempotency verified! Same charge ID returned: $($response2.data.id)" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Warning: Different charge ID returned (not idempotent)" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "✅ All tests passed!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan

} catch {
    Write-Host "❌ ERROR!" -ForegroundColor Red
    Write-Host "Status Code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red

    $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
    $errorBody = $reader.ReadToEnd()
    Write-Host ""
    Write-Host "Response Body:" -ForegroundColor Yellow
    $errorBody | ConvertFrom-Json | ConvertTo-Json -Depth 10 | Write-Host -ForegroundColor White
}
