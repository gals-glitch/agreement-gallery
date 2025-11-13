# ============================================
# Charges Negative Test Matrix (QA-02)
# ============================================
# Purpose: Test negative paths and error handling for charge workflow
# Coverage: 20+ test cases for invalid states, permissions, and business rules
# Date: 2025-10-21

# Configuration
$SERVICE_KEY = if ($env:SERVICE_KEY) { $env:SERVICE_KEY } else { "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3Z2ljcmRjb3Fka2V0cWh4YnlzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzIyNjMwNywiZXhwIjoyMDcyODAyMzA3fQ.bPUTKQM-tOm1u_1NlVNXczSbA118443uOpeo2Waa2zo" }
$BASE_URL = "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1"

# Test counters
$script:passed = 0
$script:failed = 0
$script:results = @()

# Helper Functions
function Test-Case {
    param(
        [string]$Name,
        [string]$Method,
        [string]$Endpoint,
        [hashtable]$Body = @{},
        [int]$ExpectedStatus,
        [string]$ExpectedErrorCode,
        [string]$Description
    )

    Write-Host "`n[TEST] $Name" -ForegroundColor Cyan
    Write-Host "  Expected: $ExpectedStatus $ExpectedErrorCode" -ForegroundColor Gray

    try {
        $headers = @{
            "Authorization" = "Bearer $SERVICE_KEY"
            "apikey" = "$SERVICE_KEY"
            "Content-Type" = "application/json"
        }

        $params = @{
            Uri = "$BASE_URL$Endpoint"
            Method = $Method
            Headers = $headers
        }

        if ($Body.Count -gt 0) {
            $params.Body = ($Body | ConvertTo-Json -Depth 10)
        }

        # Make request (catch errors for expected failures)
        try {
            $response = Invoke-RestMethod @params -ErrorAction Stop
            $statusCode = 200 # Default to 200 if no error
        }
        catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
            $errorBody = $_.ErrorDetails.Message | ConvertFrom-Json -ErrorAction SilentlyContinue

            # Check if error matches expected
            if ($statusCode -eq $ExpectedStatus) {
                if ($ExpectedErrorCode -and $errorBody.code -eq $ExpectedErrorCode) {
                    Write-Host "  [PASS] Got expected error: $($errorBody.code) - $($errorBody.message)" -ForegroundColor Green
                    $script:passed++
                    $script:results += @{
                        name = $Name
                        status = "PASS"
                        expected = "$ExpectedStatus $ExpectedErrorCode"
                        actual = "$statusCode $($errorBody.code)"
                    }
                    return
                }
                elseif (-not $ExpectedErrorCode) {
                    Write-Host "  [PASS] Got expected status: $statusCode" -ForegroundColor Green
                    $script:passed++
                    $script:results += @{
                        name = $Name
                        status = "PASS"
                        expected = "$ExpectedStatus"
                        actual = "$statusCode"
                    }
                    return
                }
                else {
                    Write-Host "  [FAIL] Wrong error code. Expected: $ExpectedErrorCode, Got: $($errorBody.code)" -ForegroundColor Red
                    $script:failed++
                    $script:results += @{
                        name = $Name
                        status = "FAIL"
                        expected = "$ExpectedStatus $ExpectedErrorCode"
                        actual = "$statusCode $($errorBody.code)"
                        error = "Wrong error code"
                    }
                    return
                }
            }
            else {
                Write-Host "  [FAIL] Wrong status code. Expected: $ExpectedStatus, Got: $statusCode" -ForegroundColor Red
                $script:failed++
                $script:results += @{
                    name = $Name
                    status = "FAIL"
                    expected = "$ExpectedStatus"
                    actual = "$statusCode"
                    error = "Wrong status code"
                }
                return
            }
        }

        # If no error but we expected one
        if ($ExpectedStatus -ge 400) {
            Write-Host "  [FAIL] Expected error $ExpectedStatus but got success" -ForegroundColor Red
            $script:failed++
            $script:results += @{
                name = $Name
                status = "FAIL"
                expected = "$ExpectedStatus $ExpectedErrorCode"
                actual = "200 SUCCESS"
                error = "No error returned"
            }
        }
        else {
            Write-Host "  [PASS] Request succeeded as expected" -ForegroundColor Green
            $script:passed++
            $script:results += @{
                name = $Name
                status = "PASS"
                expected = "$ExpectedStatus"
                actual = "200"
            }
        }
    }
    catch {
        Write-Host "  [ERROR] Unexpected exception: $($_.Exception.Message)" -ForegroundColor Red
        $script:failed++
        $script:results += @{
            name = $Name
            status = "ERROR"
            expected = "$ExpectedStatus $ExpectedErrorCode"
            actual = "EXCEPTION"
            error = $_.Exception.Message
        }
    }
}

# ============================================
# Setup: Create test charge for state tests
# ============================================
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "NEGATIVE TEST MATRIX - SETUP" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

Write-Host "[SETUP] Creating test charge..." -ForegroundColor Yellow
$computeResponse = Invoke-RestMethod -Uri "$BASE_URL/charges/compute" `
    -Method POST `
    -Headers @{
        "Authorization" = "Bearer $SERVICE_KEY"
        "apikey" = "$SERVICE_KEY"
        "Content-Type" = "application/json"
    } `
    -Body (@{contribution_id = 3} | ConvertTo-Json)

$testChargeId = $computeResponse.id
Write-Host "[SETUP] Created charge: $testChargeId (status: DRAFT)" -ForegroundColor Green

# ============================================
# CATEGORY 1: Invalid State Transitions (409)
# ============================================
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "CATEGORY 1: Invalid State Transitions" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

Test-Case `
    -Name "NEG-01: Submit already PENDING charge (idempotent)" `
    -Method "POST" `
    -Endpoint "/charges/$testChargeId/submit" `
    -ExpectedStatus 200 `
    -Description "Re-submitting PENDING charge should be idempotent (return current state)"

# Submit to PENDING first
Invoke-RestMethod -Uri "$BASE_URL/charges/$testChargeId/submit" `
    -Method POST `
    -Headers @{
        "Authorization" = "Bearer $SERVICE_KEY"
        "apikey" = "$SERVICE_KEY"
        "Content-Type" = "application/json"
    } | Out-Null

Test-Case `
    -Name "NEG-02: Submit already PENDING charge (second time)" `
    -Method "POST" `
    -Endpoint "/charges/$testChargeId/submit" `
    -ExpectedStatus 200 `
    -Description "Second submit should also be idempotent"

Test-Case `
    -Name "NEG-03: Approve charge in DRAFT (must submit first)" `
    -Method "POST" `
    -Endpoint "/charges/$testChargeId/approve" `
    -ExpectedStatus 409 `
    -ExpectedErrorCode "CONFLICT" `
    -Description "Cannot approve DRAFT charge (must submit first)"

# Approve the charge to test further transitions
Invoke-RestMethod -Uri "$BASE_URL/charges/$testChargeId/approve" `
    -Method POST `
    -Headers @{
        "Authorization" = "Bearer $SERVICE_KEY"
        "apikey" = "$SERVICE_KEY"
        "Content-Type" = "application/json"
    } | Out-Null

Test-Case `
    -Name "NEG-04: Submit charge in APPROVED (immutable)" `
    -Method "POST" `
    -Endpoint "/charges/$testChargeId/submit" `
    -ExpectedStatus 409 `
    -ExpectedErrorCode "CONFLICT" `
    -Description "Cannot submit APPROVED charge"

Test-Case `
    -Name "NEG-05: Reject charge in APPROVED (must be PENDING)" `
    -Method "POST" `
    -Endpoint "/charges/$testChargeId/reject" `
    -Body @{reject_reason = "Test rejection"} `
    -ExpectedStatus 409 `
    -ExpectedErrorCode "CONFLICT" `
    -Description "Cannot reject APPROVED charge"

# Mark as paid for next test
Invoke-RestMethod -Uri "$BASE_URL/charges/$testChargeId/mark-paid" `
    -Method POST `
    -Headers @{
        "Authorization" = "Bearer $SERVICE_KEY"
        "apikey" = "$SERVICE_KEY"
        "Content-Type" = "application/json"
    } `
    -Body (@{payment_ref = "TEST-001"} | ConvertTo-Json) | Out-Null

Test-Case `
    -Name "NEG-06: Submit charge in PAID (terminal state)" `
    -Method "POST" `
    -Endpoint "/charges/$testChargeId/submit" `
    -ExpectedStatus 409 `
    -ExpectedErrorCode "CONFLICT" `
    -Description "Cannot submit PAID charge (terminal state)"

# ============================================
# CATEGORY 2: Missing Required Fields (422)
# ============================================
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "CATEGORY 2: Missing Required Fields" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# Create new charge for reject tests
$computeResponse2 = Invoke-RestMethod -Uri "$BASE_URL/charges/compute" `
    -Method POST `
    -Headers @{
        "Authorization" = "Bearer $SERVICE_KEY"
        "apikey" = "$SERVICE_KEY"
        "Content-Type" = "application/json"
    } `
    -Body (@{contribution_id = 3} | ConvertTo-Json)

$testChargeId2 = $computeResponse2.id

# Submit to PENDING
Invoke-RestMethod -Uri "$BASE_URL/charges/$testChargeId2/submit" `
    -Method POST `
    -Headers @{
        "Authorization" = "Bearer $SERVICE_KEY"
        "apikey" = "$SERVICE_KEY"
        "Content-Type" = "application/json"
    } | Out-Null

Test-Case `
    -Name "NEG-07: Reject without reject_reason" `
    -Method "POST" `
    -Endpoint "/charges/$testChargeId2/reject" `
    -Body @{} `
    -ExpectedStatus 422 `
    -ExpectedErrorCode "VALIDATION_ERROR" `
    -Description "Reject requires reject_reason field"

Test-Case `
    -Name "NEG-08: Reject with reason less than 3 chars" `
    -Method "POST" `
    -Endpoint "/charges/$testChargeId2/reject" `
    -Body @{reject_reason = "No"} `
    -ExpectedStatus 422 `
    -ExpectedErrorCode "VALIDATION_ERROR" `
    -Description "Reject reason must be at least 3 characters"

Test-Case `
    -Name "NEG-09: Compute with missing contribution_id" `
    -Method "POST" `
    -Endpoint "/charges/compute" `
    -Body @{} `
    -ExpectedStatus 422 `
    -ExpectedErrorCode "VALIDATION_ERROR" `
    -Description "Compute requires contribution_id"

Test-Case `
    -Name "NEG-10: Compute with invalid contribution_id" `
    -Method "POST" `
    -Endpoint "/charges/compute" `
    -Body @{contribution_id = 999999} `
    -ExpectedStatus 422 `
    -ExpectedErrorCode "VALIDATION_ERROR" `
    -Description "Compute fails with non-existent contribution"

# ============================================
# CATEGORY 3: Resource Not Found (404)
# ============================================
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "CATEGORY 3: Resource Not Found" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$fakeUuid = "00000000-0000-0000-0000-000000000000"

Test-Case `
    -Name "NEG-11: Submit charge with non-existent UUID" `
    -Method "POST" `
    -Endpoint "/charges/$fakeUuid/submit" `
    -ExpectedStatus 404 `
    -ExpectedErrorCode "NOT_FOUND" `
    -Description "Submit non-existent charge returns 404"

Test-Case `
    -Name "NEG-12: Approve charge with non-existent UUID" `
    -Method "POST" `
    -Endpoint "/charges/$fakeUuid/approve" `
    -ExpectedStatus 404 `
    -ExpectedErrorCode "NOT_FOUND" `
    -Description "Approve non-existent charge returns 404"

Test-Case `
    -Name "NEG-13: Reject charge with non-existent UUID" `
    -Method "POST" `
    -Endpoint "/charges/$fakeUuid/reject" `
    -Body @{reject_reason = "Test rejection"} `
    -ExpectedStatus 404 `
    -ExpectedErrorCode "NOT_FOUND" `
    -Description "Reject non-existent charge returns 404"

Test-Case `
    -Name "NEG-14: Mark paid charge with non-existent UUID" `
    -Method "POST" `
    -Endpoint "/charges/$fakeUuid/mark-paid" `
    -Body @{payment_ref = "TEST-001"} `
    -ExpectedStatus 404 `
    -ExpectedErrorCode "NOT_FOUND" `
    -Description "Mark paid non-existent charge returns 404"

Test-Case `
    -Name "NEG-15: Get charge with non-existent UUID" `
    -Method "GET" `
    -Endpoint "/charges/$fakeUuid" `
    -ExpectedStatus 404 `
    -ExpectedErrorCode "NOT_FOUND" `
    -Description "Get non-existent charge returns 404"

# ============================================
# CATEGORY 4: Idempotency Tests
# ============================================
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "CATEGORY 4: Idempotency Tests" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# Create new charge for idempotency tests
$computeResponse3 = Invoke-RestMethod -Uri "$BASE_URL/charges/compute" `
    -Method POST `
    -Headers @{
        "Authorization" = "Bearer $SERVICE_KEY"
        "apikey" = "$SERVICE_KEY"
        "Content-Type" = "application/json"
    } `
    -Body (@{contribution_id = 3} | ConvertTo-Json)

$testChargeId3 = $computeResponse3.id

Test-Case `
    -Name "NEG-16: Compute charge twice (upsert behavior)" `
    -Method "POST" `
    -Endpoint "/charges/compute" `
    -Body @{contribution_id = 3} `
    -ExpectedStatus 200 `
    -Description "Computing same contribution twice should upsert (no duplicate)"

# Submit to PENDING
Invoke-RestMethod -Uri "$BASE_URL/charges/$testChargeId3/submit" `
    -Method POST `
    -Headers @{
        "Authorization" = "Bearer $SERVICE_KEY"
        "apikey" = "$SERVICE_KEY"
        "Content-Type" = "application/json"
    } | Out-Null

# Approve
Invoke-RestMethod -Uri "$BASE_URL/charges/$testChargeId3/approve" `
    -Method POST `
    -Headers @{
        "Authorization" = "Bearer $SERVICE_KEY"
        "apikey" = "$SERVICE_KEY"
        "Content-Type" = "application/json"
    } | Out-Null

Test-Case `
    -Name "NEG-17: Approve charge twice (idempotent)" `
    -Method "POST" `
    -Endpoint "/charges/$testChargeId3/approve" `
    -ExpectedStatus 200 `
    -Description "Re-approving APPROVED charge should be idempotent"

# Mark as paid
Invoke-RestMethod -Uri "$BASE_URL/charges/$testChargeId3/mark-paid" `
    -Method POST `
    -Headers @{
        "Authorization" = "Bearer $SERVICE_KEY"
        "apikey" = "$SERVICE_KEY"
        "Content-Type" = "application/json"
    } `
    -Body (@{payment_ref = "TEST-002"} | ConvertTo-Json) | Out-Null

Test-Case `
    -Name "NEG-18: Mark paid twice (idempotent)" `
    -Method "POST" `
    -Endpoint "/charges/$testChargeId3/mark-paid" `
    -Body @{payment_ref = "TEST-003"} `
    -ExpectedStatus 200 `
    -Description "Re-marking PAID charge should be idempotent"

# ============================================
# CATEGORY 5: Business Rule Validation
# ============================================
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "CATEGORY 5: Business Rule Validation" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

Test-Case `
    -Name "NEG-19: Batch compute with empty array" `
    -Method "POST" `
    -Endpoint "/charges/batch-compute" `
    -Body @{contribution_ids = @()} `
    -ExpectedStatus 422 `
    -ExpectedErrorCode "VALIDATION_ERROR" `
    -Description "Batch compute requires at least one contribution ID"

Test-Case `
    -Name "NEG-20: Batch compute with over 1000 IDs" `
    -Method "POST" `
    -Endpoint "/charges/batch-compute" `
    -Body @{contribution_ids = (1..1001)} `
    -ExpectedStatus 422 `
    -ExpectedErrorCode "VALIDATION_ERROR" `
    -Description "Batch compute limited to 1000 contributions"

# ============================================
# CATEGORY 6: No 500 Internal Server Errors
# ============================================
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "CATEGORY 6: No 500 Internal Server Errors" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

Test-Case `
    -Name "NEG-21: Malformed UUID in path" `
    -Method "POST" `
    -Endpoint "/charges/not-a-uuid/submit" `
    -ExpectedStatus 404 `
    -Description "Malformed UUID should return 404, not 500"

Test-Case `
    -Name "NEG-22: Invalid JSON body" `
    -Method "POST" `
    -Endpoint "/charges/$testChargeId3/reject" `
    -Body @{reject_reason = $null} `
    -ExpectedStatus 422 `
    -ExpectedErrorCode "VALIDATION_ERROR" `
    -Description "Invalid JSON should return 422, not 500"

# ============================================
# SUMMARY
# ============================================
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "TEST SUMMARY" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Total Tests: $($script:passed + $script:failed)" -ForegroundColor White
Write-Host "Passed: $script:passed" -ForegroundColor Green
Write-Host "Failed: $script:failed" -ForegroundColor $(if ($script:failed -gt 0) { "Red" } else { "Gray" })

# Export results to JSON
$resultsPath = "C:\Users\GalSamionov\Buligo Capital\Buligo Capital - Shared Documents\Information Systems\Gal\agreement-gallery-main\tests\results\charges_negative_matrix_results.json"
$resultsDir = Split-Path $resultsPath -Parent
if (-not (Test-Path $resultsDir)) {
    New-Item -ItemType Directory -Path $resultsDir -Force | Out-Null
}

@{
    timestamp = (Get-Date -Format "o")
    total = $script:passed + $script:failed
    passed = $script:passed
    failed = $script:failed
    results = $script:results
} | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultsPath -Encoding UTF8

Write-Host "`nResults saved to: $resultsPath" -ForegroundColor Cyan

if ($script:failed -eq 0) {
    Write-Host "`n[SUCCESS] All negative tests passed!" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "`n[FAILURE] Some tests failed. Review results above." -ForegroundColor Red
    exit 1
}
