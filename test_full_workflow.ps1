# Test the complete charge + credit workflow
# Contribution 3: $50,000 → Charge: $500 base + $100 VAT = $600 total
# Credit 2: $500 available → Apply to charge

$SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3Z2ljcmRjb3Fka2V0cWh4YnlzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzIyNjMwNywiZXhwIjoyMDcyODAyMzA3fQ.bPUTKQM-tOm1u_1NlVNXczSbA118443uOpeo2Waa2zo"
$API_URL = "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1"

$headers = @{
    "Authorization" = "Bearer $SERVICE_ROLE_KEY"
    "Content-Type" = "application/json"
    "apikey" = $SERVICE_ROLE_KEY
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "FULL WORKFLOW TEST: Compute + Credits + FIFO" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Compute charge for contribution 3
Write-Host "Step 1: Recomputing charge for contribution 3..." -ForegroundColor Yellow
Write-Host "  Contribution: $50,000 USD" -ForegroundColor Gray
Write-Host "  Agreement 6 NOW HAS PRICING: 100 bps + 20% VAT" -ForegroundColor Green
Write-Host "  Expected charge: $500 base + $100 VAT = $600 total" -ForegroundColor Gray
Write-Host ""

$body = @{ contribution_id = 3 } | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$API_URL/charges/compute" -Method Post -Headers $headers -Body $body
    $charge = $response.data

    Write-Host "SUCCESS! Charge computed:" -ForegroundColor Green
    Write-Host "  Charge ID: $($charge.id)" -ForegroundColor White
    Write-Host "  Status: $($charge.status)" -ForegroundColor Yellow
    Write-Host "  Base: `$$($charge.base_amount)" -ForegroundColor White
    Write-Host "  VAT: `$$($charge.vat_amount)" -ForegroundColor White
    Write-Host "  Total: `$$($charge.total_amount)" -ForegroundColor Cyan
    Write-Host "  Credits Applied: `$$($charge.credits_applied_amount)" -ForegroundColor White
    Write-Host "  Net Amount: `$$($charge.net_amount)" -ForegroundColor Green
    Write-Host ""

    $global:CHARGE_ID = $charge.id
    $global:CHARGE_TOTAL = $charge.total_amount

} catch {
    Write-Host "ERROR computing charge!" -ForegroundColor Red
    $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
    $errorBody = $reader.ReadToEnd()
    Write-Host $errorBody -ForegroundColor White
    exit 1
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Charge ID: $global:CHARGE_ID" -ForegroundColor Gray
Write-Host "Total Amount: `$$global:CHARGE_TOTAL" -ForegroundColor Gray
Write-Host ""
Write-Host "Next steps to test manually:" -ForegroundColor Yellow
Write-Host "1. Apply credit ID 2 ($500) to charge $global:CHARGE_ID" -ForegroundColor White
Write-Host "2. Submit the charge for approval" -ForegroundColor White
Write-Host "3. Approve or reject the charge" -ForegroundColor White
Write-Host "4. Test credit reversal on rejection" -ForegroundColor White
Write-Host ""
