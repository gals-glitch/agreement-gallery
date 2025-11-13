# ============================================
# T01+T02 Simple PowerShell Test
# ============================================

# STEP 1: Set your credentials
$SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3Z2ljcmRjb3Fka2V0cWh4YnlzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzIyNjMwNywiZXhwIjoyMDcyODAyMzA3fQ.bPUTKQM-tOm1u_1NlVNXczSbA118443uOpeo2Waa2zo"
$ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3Z2ljcmRjb3Fka2V0cWh4YnlzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcyMjYzMDcsImV4cCI6MjA3MjgwMjMwN30.6PZnjAcRXYcd_sNZHb6ZDxyg914JMtkCtqIYvHt3P1Y"
$BASE_URL = "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1"

# STEP 2: Choose a contribution ID that has an approved agreement
# Run CHECK_TEST_DATA.sql first to see valid IDs
$CONTRIBUTION_ID = 3  # Change if needed based on query results

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "T01+T02 WORKFLOW TEST" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

# ============================================
# TEST 1: Compute Charge
# ============================================
Write-Host "[STEP 1] Computing charge for contribution $CONTRIBUTION_ID..." -ForegroundColor Yellow

try {
    $computeResponse = Invoke-RestMethod -Uri "$BASE_URL/charges/compute" `
        -Method POST `
        -Headers @{
            "Authorization" = "Bearer $SERVICE_KEY"
            "apikey" = "$SERVICE_KEY"
            "Content-Type" = "application/json"
        } `
        -Body (@{contribution_id = $CONTRIBUTION_ID} | ConvertTo-Json)

    Write-Host "[OK] Charge computed" -ForegroundColor Green

    $chargeId = $computeResponse.id
    Write-Host "Charge ID: $chargeId" -ForegroundColor Cyan

    $computeResponse | Format-List id, status, base_amount, vat_amount, total_amount, credits_applied_amount, net_amount
} catch {
    Write-Host "[ERROR] Compute failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Gray
    exit 1
}

# ============================================
# TEST 2: Submit Charge (apply credits)
# ============================================
Write-Host "`n[STEP 2] Submitting charge $chargeId..." -ForegroundColor Yellow

if (-not $chargeId) {
    Write-Host "[ERROR] No charge ID from Step 1 - cannot proceed" -ForegroundColor Red
    exit 1
}

try {
    $submitResponse = Invoke-RestMethod -Uri "$BASE_URL/charges/$chargeId/submit" `
        -Method POST `
        -Headers @{
            "Authorization" = "Bearer $SERVICE_KEY"
            "apikey" = "$SERVICE_KEY"
            "Content-Type" = "application/json"
        }

    Write-Host "[OK] Charge submitted (status: DRAFT -> PENDING)" -ForegroundColor Green
    $submitResponse | Format-List id, status, credits_applied_amount, net_amount

    if ($submitResponse.credit_applications) {
        Write-Host "[INFO] Credits applied: $($submitResponse.credit_applications.Count)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "[ERROR] Submit failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host "Error Details:" -ForegroundColor Yellow
        try {
            $errorObj = $_.ErrorDetails.Message | ConvertFrom-Json
            $errorObj | ConvertTo-Json -Depth 10 | Write-Host -ForegroundColor Gray
        } catch {
            Write-Host "Raw Error: $($_.ErrorDetails.Message)" -ForegroundColor Gray
        }
    }
    if ($_.Exception.Response) {
        Write-Host "Response Status: $($_.Exception.Response.StatusCode)" -ForegroundColor Gray
    }
    exit 1
}

# ============================================
# TEST 3: Approve Charge
# ============================================
Write-Host "`n[STEP 3] Approving charge $chargeId..." -ForegroundColor Yellow

try {
    $approveResponse = Invoke-RestMethod -Uri "$BASE_URL/charges/$chargeId/approve" `
        -Method POST `
        -Headers @{
            "Authorization" = "Bearer $SERVICE_KEY"
            "apikey" = "$SERVICE_KEY"
            "Content-Type" = "application/json"
        }

    Write-Host "[OK] Charge approved (status: PENDING -> APPROVED)" -ForegroundColor Green
    $approveResponse | Format-List id, status, approved_at, approved_by
} catch {
    Write-Host "[ERROR] Approve failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Gray
    exit 1
}

# ============================================
# TEST 4: Mark Paid
# ============================================
Write-Host "`n[STEP 4] Marking charge $chargeId as paid..." -ForegroundColor Yellow

try {
    $markPaidResponse = Invoke-RestMethod -Uri "$BASE_URL/charges/$chargeId/mark-paid" `
        -Method POST `
        -Headers @{
            "Authorization" = "Bearer $SERVICE_KEY"
            "apikey" = "$SERVICE_KEY"
            "Content-Type" = "application/json"
        } `
        -Body (@{
            payment_ref = "WIRE-2025-TEST-001"
            paid_at = (Get-Date -Format "o")
        } | ConvertTo-Json)

    Write-Host "[OK] Charge marked paid (status: APPROVED -> PAID)" -ForegroundColor Green
    $markPaidResponse | Format-List id, status, paid_at, payment_ref
} catch {
    Write-Host "[ERROR] Mark paid failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Gray
    exit 1
}

# ============================================
# SUMMARY
# ============================================
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "TEST SUMMARY" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "[SUCCESS] Full workflow completed:" -ForegroundColor Green
Write-Host "  1. Computed charge: $chargeId" -ForegroundColor White
Write-Host "  2. Status progression: DRAFT -> PENDING -> APPROVED -> PAID" -ForegroundColor White
Write-Host "  3. Base amount: `$$($computeResponse.base_amount)" -ForegroundColor White
Write-Host "  4. VAT amount: `$$($computeResponse.vat_amount)" -ForegroundColor White
Write-Host "  5. Total amount: `$$($computeResponse.total_amount)" -ForegroundColor White
if ($submitResponse.credits_applied_amount -and $submitResponse.credits_applied_amount -gt 0) {
    Write-Host "  6. Credits applied: `$$($submitResponse.credits_applied_amount)" -ForegroundColor White
}
Write-Host "  7. Final net amount: `$$($markPaidResponse.net_amount)" -ForegroundColor White
Write-Host "  8. Payment reference: $($markPaidResponse.payment_ref)" -ForegroundColor White
Write-Host "`n[READY] T01+T02 workflow is operational on staging!" -ForegroundColor Green
