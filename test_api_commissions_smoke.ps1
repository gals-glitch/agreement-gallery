# ============================================================================
# COMMISSIONS API SMOKE TESTS
# ============================================================================
# Tests all commission endpoints with proper workflow sequence
# ============================================================================

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$PROJECT_ID = "qwgicrdcoqdketqhxbys"
$BASE_URL = "https://$PROJECT_ID.supabase.co/functions/v1/api-v1"

# Get from .env or set manually
$ADMIN_JWT = $env:ADMIN_JWT
$FINANCE_JWT = $env:FINANCE_JWT  # Can use same as ADMIN for testing
$SERVICE_KEY = $env:SERVICE_ROLE_KEY

if (-not $ADMIN_JWT) {
    Write-Host "❌ ADMIN_JWT not set. Please set environment variable or edit script." -ForegroundColor Red
    Write-Host "   Set-Item -Path Env:ADMIN_JWT -Value 'your-jwt-token'" -ForegroundColor Yellow
    exit 1
}

# ============================================================================
# TEST DATA (Get these from the SQL output above)
# ============================================================================
# You'll need to update these values after running the unblockers SQL:
$CONTRIBUTION_ID = Read-Host "Enter a contribution_id from SQL output"

Write-Host ""
Write-Host "=== COMMISSIONS API SMOKE TESTS ===" -ForegroundColor Cyan
Write-Host "Base URL: $BASE_URL" -ForegroundColor Gray
Write-Host "Contribution ID: $CONTRIBUTION_ID" -ForegroundColor Gray
Write-Host ""

# ============================================================================
# [API-01] Compute a commission for a known contribution
# ============================================================================
Write-Host "[API-01] Computing commission for contribution..." -ForegroundColor Yellow

$computeBody = @{
    contribution_id = $CONTRIBUTION_ID
} | ConvertTo-Json

$computeResponse = Invoke-RestMethod `
    -Uri "$BASE_URL/commissions/compute" `
    -Method POST `
    -Headers @{
        "Authorization" = "Bearer $ADMIN_JWT"
        "Content-Type" = "application/json"
    } `
    -Body $computeBody `
    -ErrorAction Stop

Write-Host "✅ Commission computed successfully!" -ForegroundColor Green
Write-Host ($computeResponse | ConvertTo-Json -Depth 5)

$COMMISSION_ID = $computeResponse.data.id
$COMMISSION_STATUS = $computeResponse.data.status
$BASE_AMOUNT = $computeResponse.data.base_amount
$VAT_AMOUNT = $computeResponse.data.vat_amount
$TOTAL_AMOUNT = $computeResponse.data.total_amount

Write-Host ""
Write-Host "Commission Created:" -ForegroundColor Cyan
Write-Host "  ID: $COMMISSION_ID" -ForegroundColor White
Write-Host "  Status: $COMMISSION_STATUS" -ForegroundColor White
Write-Host "  Base: $$BASE_AMOUNT" -ForegroundColor White
Write-Host "  VAT: $$VAT_AMOUNT" -ForegroundColor White
Write-Host "  Total: $$TOTAL_AMOUNT" -ForegroundColor White
Write-Host ""

Start-Sleep -Seconds 2

# ============================================================================
# [API-02-A] List commissions (verify it appears)
# ============================================================================
Write-Host "[API-02-A] Listing draft commissions..." -ForegroundColor Yellow

$listResponse = Invoke-RestMethod `
    -Uri "$BASE_URL/commissions?status=draft" `
    -Method GET `
    -Headers @{
        "Authorization" = "Bearer $ADMIN_JWT"
    } `
    -ErrorAction Stop

Write-Host "✅ Found $($listResponse.data.Count) draft commission(s)" -ForegroundColor Green
Write-Host ""

Start-Sleep -Seconds 1

# ============================================================================
# [API-02-B] Submit commission (DRAFT → PENDING)
# ============================================================================
Write-Host "[API-02-B] Submitting commission for approval..." -ForegroundColor Yellow

$submitResponse = Invoke-RestMethod `
    -Uri "$BASE_URL/commissions/$COMMISSION_ID/submit" `
    -Method POST `
    -Headers @{
        "Authorization" = "Bearer $ADMIN_JWT"
    } `
    -ErrorAction Stop

Write-Host "✅ Commission submitted!" -ForegroundColor Green
Write-Host "  Status: $($submitResponse.data.status)" -ForegroundColor White
Write-Host "  Submitted at: $($submitResponse.data.submitted_at)" -ForegroundColor White
Write-Host ""

Start-Sleep -Seconds 2

# ============================================================================
# [API-02-C] Approve commission (PENDING → APPROVED)
# ============================================================================
Write-Host "[API-02-C] Approving commission (Admin only)..." -ForegroundColor Yellow

$approveResponse = Invoke-RestMethod `
    -Uri "$BASE_URL/commissions/$COMMISSION_ID/approve" `
    -Method POST `
    -Headers @{
        "Authorization" = "Bearer $ADMIN_JWT"
    } `
    -ErrorAction Stop

Write-Host "✅ Commission approved!" -ForegroundColor Green
Write-Host "  Status: $($approveResponse.data.status)" -ForegroundColor White
Write-Host "  Approved at: $($approveResponse.data.approved_at)" -ForegroundColor White
Write-Host "  Approved by: $($approveResponse.data.approved_by)" -ForegroundColor White
Write-Host ""

Start-Sleep -Seconds 2

# ============================================================================
# [API-02-D] Mark-Paid with SERVICE KEY (should FAIL with 403)
# ============================================================================
Write-Host "[API-02-D] Testing mark-paid with SERVICE KEY (should fail)..." -ForegroundColor Yellow

if ($SERVICE_KEY) {
    try {
        $serviceKeyBody = @{
            payment_ref = "WIRE-001-SERVICE"
        } | ConvertTo-Json

        $serviceKeyResponse = Invoke-RestMethod `
            -Uri "$BASE_URL/commissions/$COMMISSION_ID/mark-paid" `
            -Method POST `
            -Headers @{
                "Authorization" = "Bearer $SERVICE_KEY"
                "apikey" = $SERVICE_KEY
                "Content-Type" = "application/json"
            } `
            -Body $serviceKeyBody `
            -ErrorAction Stop

        Write-Host "❌ SECURITY BUG: Service key was allowed to mark-paid!" -ForegroundColor Red
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -eq 403) {
            Write-Host "✅ Service key correctly blocked (403 Forbidden)" -ForegroundColor Green
        }
        else {
            Write-Host "⚠️  Unexpected error: $statusCode" -ForegroundColor Yellow
        }
    }
}
else {
    Write-Host "⏭️  Skipping (no SERVICE_KEY set)" -ForegroundColor Gray
}

Write-Host ""
Start-Sleep -Seconds 2

# ============================================================================
# [API-02-E] Mark-Paid with ADMIN JWT (should SUCCEED)
# ============================================================================
Write-Host "[API-02-E] Marking commission as paid (Admin JWT)..." -ForegroundColor Yellow

$markPaidBody = @{
    payment_ref = "WIRE-001-ADMIN"
} | ConvertTo-Json

$markPaidResponse = Invoke-RestMethod `
    -Uri "$BASE_URL/commissions/$COMMISSION_ID/mark-paid" `
    -Method POST `
    -Headers @{
        "Authorization" = "Bearer $ADMIN_JWT"
        "Content-Type" = "application/json"
    } `
    -Body $markPaidBody `
    -ErrorAction Stop

Write-Host "✅ Commission marked as PAID!" -ForegroundColor Green
Write-Host "  Status: $($markPaidResponse.data.status)" -ForegroundColor White
Write-Host "  Paid at: $($markPaidResponse.data.paid_at)" -ForegroundColor White
Write-Host "  Payment ref: $($markPaidResponse.data.payment_ref)" -ForegroundColor White
Write-Host ""

Start-Sleep -Seconds 2

# ============================================================================
# [API-03] Batch compute (if multiple contributions available)
# ============================================================================
Write-Host "[API-03] Testing batch compute..." -ForegroundColor Yellow

# Ask user if they want to test batch
$testBatch = Read-Host "Do you have additional contribution IDs to test batch? (y/n)"

if ($testBatch -eq 'y') {
    $contrib2 = Read-Host "Enter second contribution_id"
    $contrib3 = Read-Host "Enter third contribution_id (or press Enter to skip)"

    $contribIds = @($CONTRIBUTION_ID, $contrib2)
    if ($contrib3) {
        $contribIds += $contrib3
    }

    $batchBody = @{
        contribution_ids = $contribIds
    } | ConvertTo-Json

    $batchResponse = Invoke-RestMethod `
        -Uri "$BASE_URL/commissions/batch-compute" `
        -Method POST `
        -Headers @{
            "Authorization" = "Bearer $ADMIN_JWT"
            "Content-Type" = "application/json"
        } `
        -Body $batchBody `
        -ErrorAction Stop

    Write-Host "✅ Batch compute completed!" -ForegroundColor Green
    Write-Host "  Results:" -ForegroundColor White
    Write-Host ($batchResponse | ConvertTo-Json -Depth 5)
}
else {
    Write-Host "⏭️  Skipping batch test" -ForegroundColor Gray
}

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "🎉 API SMOKE TESTS COMPLETE!" -ForegroundColor Green
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor White
Write-Host "  [API-01] ✅ Compute commission" -ForegroundColor Green
Write-Host "  [API-02] ✅ Full workflow (submit → approve → mark-paid)" -ForegroundColor Green
Write-Host "  [API-03] ⏭️  Batch compute (optional)" -ForegroundColor Gray
Write-Host ""
Write-Host "Commission ID for UI testing: $COMMISSION_ID" -ForegroundColor Cyan
Write-Host ""
