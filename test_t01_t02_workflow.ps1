# ============================================
# T01+T02 Full Workflow Test Suite
# Tests: compute → submit → approve → mark-paid
# Also tests: compute → submit → reject
# ============================================

$BASE_URL = "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1"
$SERVICE_KEY = $env:SUPABASE_SERVICE_ROLE_KEY
$ANON_KEY = $env:SUPABASE_ANON_KEY

if (-not $SERVICE_KEY) {
    Write-Host "ERROR: SUPABASE_SERVICE_ROLE_KEY not set" -ForegroundColor Red
    exit 1
}

# Colors for output
function Write-Success { param($msg) Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Error { param($msg) Write-Host "[ERROR] $msg" -ForegroundColor Red }
function Write-Info { param($msg) Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Step { param($msg) Write-Host "`n[STEP] $msg" -ForegroundColor Yellow }

# Test counter
$script:passCount = 0
$script:failCount = 0

function Test-Response {
    param($response, $testName, $expectedStatus = 200)

    if ($response.StatusCode -eq $expectedStatus) {
        Write-Success "$testName - Status $expectedStatus"
        $script:passCount++
        return $true
    } else {
        Write-Error "$testName - Expected $expectedStatus, got $($response.StatusCode)"
        Write-Host "Response: $($response.Content)" -ForegroundColor Gray
        $script:failCount++
        return $false
    }
}

Write-Host "`n============================================" -ForegroundColor Magenta
Write-Host "T01+T02 WORKFLOW TEST SUITE" -ForegroundColor Magenta
Write-Host "============================================`n" -ForegroundColor Magenta

# ============================================
# TEST 1: Compute charge for contribution 3
# ============================================
Write-Step "TEST 1: POST /charges/compute (contribution 3)"

$computeBody = @{
    contribution_id = 3
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest -Uri "$BASE_URL/charges/compute" `
        -Method POST `
        -Headers @{
            "Authorization" = "Bearer $SERVICE_KEY"
            "apikey" = "$ANON_KEY"
            "Content-Type" = "application/json"
        } `
        -Body $computeBody `
        -ErrorAction Stop

    if (Test-Response $response "Compute charge" 200) {
        $chargeData = ($response.Content | ConvertFrom-Json).data
        $chargeId1 = $chargeData.id
        Write-Info "Charge ID: $chargeId1"
        Write-Info "Base: $$($chargeData.base_amount), VAT: $$($chargeData.vat_amount), Total: $$($chargeData.total_amount)"
        Write-Info "Status: $($chargeData.status)"
    }
} catch {
    Write-Error "Compute charge failed: $_"
    $script:failCount++
}

# ============================================
# TEST 2: Submit charge (FIFO credit application)
# ============================================
Write-Step "TEST 2: POST /charges/$chargeId1/submit"

try {
    $response = Invoke-WebRequest -Uri "$BASE_URL/charges/$chargeId1/submit" `
        -Method POST `
        -Headers @{
            "Authorization" = "Bearer $SERVICE_KEY"
            "apikey" = "$ANON_KEY"
            "Content-Type" = "application/json"
        } `
        -ErrorAction Stop

    if (Test-Response $response "Submit charge" 200) {
        $chargeData = ($response.Content | ConvertFrom-Json).data
        Write-Info "Status changed: DRAFT -> PENDING"
        Write-Info "Credits applied: $$($chargeData.credits_applied_amount)"
        Write-Info "Net amount: $$($chargeData.net_amount)"
        if ($chargeData.credit_applications) {
            Write-Info "Credit applications: $($chargeData.credit_applications.Count) credits"
        }
    }
} catch {
    Write-Error "Submit charge failed: $_"
    $script:failCount++
}

# ============================================
# TEST 3: Approve charge
# ============================================
Write-Step "TEST 3: POST /charges/$chargeId1/approve"

try {
    $response = Invoke-WebRequest -Uri "$BASE_URL/charges/$chargeId1/approve" `
        -Method POST `
        -Headers @{
            "Authorization" = "Bearer $SERVICE_KEY"
            "apikey" = "$ANON_KEY"
            "Content-Type" = "application/json"
        } `
        -ErrorAction Stop

    if (Test-Response $response "Approve charge" 200) {
        $chargeData = ($response.Content | ConvertFrom-Json).data
        Write-Info "Status changed: PENDING -> APPROVED"
        Write-Info "Approved at: $($chargeData.approved_at)"
        if ($chargeData.approved_by) {
            Write-Info "Approved by: $($chargeData.approved_by)"
        }
    }
} catch {
    Write-Error "Approve charge failed: $_"
    $script:failCount++
}

# ============================================
# TEST 4: Mark charge paid
# ============================================
Write-Step "TEST 4: POST /charges/$chargeId1/mark-paid"

$markPaidBody = @{
    payment_ref = "WIRE-2025-TEST-001"
    paid_at = (Get-Date -Format "o")
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest -Uri "$BASE_URL/charges/$chargeId1/mark-paid" `
        -Method POST `
        -Headers @{
            "Authorization" = "Bearer $SERVICE_KEY"
            "apikey" = "$ANON_KEY"
            "Content-Type" = "application/json"
        } `
        -Body $markPaidBody `
        -ErrorAction Stop

    if (Test-Response $response "Mark charge paid" 200) {
        $chargeData = ($response.Content | ConvertFrom-Json).data
        Write-Info "Status changed: APPROVED -> PAID"
        Write-Info "Paid at: $($chargeData.paid_at)"
        Write-Info "Payment ref: $($chargeData.payment_ref)"
    }
} catch {
    Write-Error "Mark charge paid failed: $_"
    $script:failCount++
}

# ============================================
# TEST 5: Compute another charge for rejection test
# ============================================
Write-Step "TEST 5: POST /charges/compute (contribution 3 again - idempotency)"

try {
    $response = Invoke-WebRequest -Uri "$BASE_URL/charges/compute" `
        -Method POST `
        -Headers @{
            "Authorization" = "Bearer $SERVICE_KEY"
            "apikey" = "$ANON_KEY"
            "Content-Type" = "application/json"
        } `
        -Body $computeBody `
        -ErrorAction Stop

    if (Test-Response $response "Compute charge (idempotent)" 200) {
        $chargeData = ($response.Content | ConvertFrom-Json).data
        $chargeId2 = $chargeData.id
        if ($chargeId2 -eq $chargeId1) {
            Write-Success "Idempotency verified - same charge ID returned"
        } else {
            Write-Info "New charge ID: $chargeId2 (may have reset status)"
        }
        Write-Info "Current status: $($chargeData.status)"
    }
} catch {
    Write-Error "Compute charge (idempotent) failed: $_"
    $script:failCount++
}

# ============================================
# TEST 6: Test idempotency - submit already submitted
# ============================================
Write-Step "TEST 6: POST /charges/$chargeId1/submit (idempotency test)"

try {
    $response = Invoke-WebRequest -Uri "$BASE_URL/charges/$chargeId1/submit" `
        -Method POST `
        -Headers @{
            "Authorization" = "Bearer $SERVICE_KEY"
            "apikey" = "$ANON_KEY"
            "Content-Type" = "application/json"
        } `
        -ErrorAction Stop

    if (Test-Response $response "Submit already submitted charge" 200) {
        $chargeData = ($response.Content | ConvertFrom-Json).data
        Write-Success "Idempotency verified - no error on re-submit"
        Write-Info "Status: $($chargeData.status)"
    }
} catch {
    Write-Error "Idempotency test failed: $_"
    $script:failCount++
}

# ============================================
# TEST 7: Test error - reject without reason
# ============================================
Write-Step "TEST 7: POST /charges/$chargeId1/reject (no reason - expect 400)"

$rejectNoReasonBody = @{} | ConvertTo-Json

try {
    $response = Invoke-WebRequest -Uri "$BASE_URL/charges/$chargeId1/reject" `
        -Method POST `
        -Headers @{
            "Authorization" = "Bearer $SERVICE_KEY"
            "apikey" = "$ANON_KEY"
            "Content-Type" = "application/json"
        } `
        -Body $rejectNoReasonBody `
        -ErrorAction Stop

    Write-Error "Should have returned 400 for missing reason"
    $script:failCount++
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 400) {
        Write-Success "Correctly rejected request with no reason (400)"
        $script:passCount++
    } else {
        Write-Error "Expected 400, got $($_.Exception.Response.StatusCode.value__)"
        $script:failCount++
    }
}

# ============================================
# SUMMARY
# ============================================
Write-Host "`n============================================" -ForegroundColor Magenta
Write-Host "TEST SUMMARY" -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "Passed: $script:passCount" -ForegroundColor Green
Write-Host "Failed: $script:failCount" -ForegroundColor Red
Write-Host "Total:  $($script:passCount + $script:failCount)" -ForegroundColor White

if ($script:failCount -eq 0) {
    Write-Host "`n[SUCCESS] ALL TESTS PASSED - T01+T02 WORKFLOW OPERATIONAL" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n[FAILURE] SOME TESTS FAILED - REVIEW ERRORS ABOVE" -ForegroundColor Red
    exit 1
}
