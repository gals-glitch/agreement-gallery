# ============================================================
# Track D10: Negative Matrix (Spot Tests)
# ============================================================
# Purpose: Test error cases and RBAC enforcement
# Expected: Proper error codes, no 500s
# Time: 5-10 minutes
# ============================================================

$BASE_URL = "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Track D10: Negative Matrix (Spot Tests)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Check JWT tokens
if (-not $env:ADMIN_JWT) {
    Write-Host "❌ ADMIN_JWT not set" -ForegroundColor Red
    exit 1
}

if (-not $env:FINANCE_JWT) {
    Write-Host "⚠️  FINANCE_JWT not set - skipping finance role tests" -ForegroundColor Yellow
    $skipFinance = $true
}

if (-not $env:VIEWER_JWT) {
    Write-Host "⚠️  VIEWER_JWT not set - skipping viewer role tests" -ForegroundColor Yellow
    $skipViewer = $true
}

# Prepare headers
$adminHeaders = @{
    "Authorization" = "Bearer $env:ADMIN_JWT"
    "apikey" = $env:ADMIN_JWT
    "Content-Type" = "application/json"
}

# Test Results Table
$testResults = @()

function Test-Endpoint {
    param(
        [string]$TestName,
        [string]$Method,
        [string]$Url,
        [hashtable]$Headers,
        [string]$Body,
        [int]$ExpectedStatus,
        [string]$ExpectedError = ""
    )

    Write-Host "🧪 $TestName" -ForegroundColor Yellow

    try {
        $params = @{
            Uri = $Url
            Headers = $Headers
            Method = $Method
        }

        if ($Body) {
            $params.Body = $Body
        }

        $response = Invoke-RestMethod @params

        # If we get here, request succeeded (bad if we expected error)
        if ($ExpectedStatus -ge 400) {
            Write-Host "   ❌ FAIL: Expected $ExpectedStatus, got 200" -ForegroundColor Red
            $script:testResults += [PSCustomObject]@{
                Test = $TestName
                Expected = $ExpectedStatus
                Actual = 200
                Status = "FAIL"
            }
        } else {
            Write-Host "   ✅ PASS: Got 200 as expected" -ForegroundColor Green
            $script:testResults += [PSCustomObject]@{
                Test = $TestName
                Expected = $ExpectedStatus
                Actual = 200
                Status = "PASS"
            }
        }

    } catch {
        $actualStatus = $_.Exception.Response.StatusCode.value__

        if ($actualStatus -eq $ExpectedStatus) {
            Write-Host "   ✅ PASS: Got $actualStatus as expected" -ForegroundColor Green

            # Try to get error body
            try {
                $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                $errorBody = $reader.ReadToEnd() | ConvertFrom-Json
                Write-Host "      Error: $($errorBody.error)" -ForegroundColor Gray
                Write-Host "      Message: $($errorBody.message)" -ForegroundColor Gray

                if ($ExpectedError -and $errorBody.message -notlike "*$ExpectedError*") {
                    Write-Host "      ⚠️  Message doesn't match expected: $ExpectedError" -ForegroundColor Yellow
                }
            } catch {
                Write-Host "      (Could not parse error body)" -ForegroundColor Gray
            }

            $script:testResults += [PSCustomObject]@{
                Test = $TestName
                Expected = $ExpectedStatus
                Actual = $actualStatus
                Status = "PASS"
            }

        } else {
            Write-Host "   ❌ FAIL: Expected $ExpectedStatus, got $actualStatus" -ForegroundColor Red
            $script:testResults += [PSCustomObject]@{
                Test = $TestName
                Expected = $ExpectedStatus
                Actual = $actualStatus
                Status = "FAIL"
            }
        }
    }

    Write-Host ""
}

# Get test data (1 pending commission)
Write-Host "📋 Getting test data..." -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/commissions?status=pending" -Headers $adminHeaders -Method Get
    $pending = $response.data

    if ($pending.Count -eq 0) {
        Write-Host "⚠️  No PENDING commissions found. Creating one..." -ForegroundColor Yellow

        # Get a draft and submit it
        $response = Invoke-RestMethod -Uri "$BASE_URL/commissions?status=draft" -Headers $adminHeaders -Method Get
        $drafts = $response.data

        if ($drafts.Count -gt 0) {
            $draftId = $drafts[0].id
            $null = Invoke-RestMethod -Uri "$BASE_URL/commissions/$draftId/submit" -Headers $adminHeaders -Method Post
            $pendingId = $draftId
            Write-Host "   ✅ Created pending commission: $pendingId" -ForegroundColor Green
        } else {
            Write-Host "   ❌ No draft commissions available either. Run compute first." -ForegroundColor Red
            exit 1
        }
    } else {
        $pendingId = $pending[0].id
        Write-Host "   ✅ Using pending commission: $pendingId" -ForegroundColor Green
    }

} catch {
    Write-Host "❌ Failed to get test data: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# ============================================================
# TEST SUITE
# ============================================================

Write-Host "Running negative test suite..." -ForegroundColor Cyan
Write-Host ""

# TEST 1: Reject without reason (400 Bad Request)
Test-Endpoint `
    -TestName "TEST 1: Reject without reason" `
    -Method "Post" `
    -Url "$BASE_URL/commissions/$pendingId/reject" `
    -Headers $adminHeaders `
    -Body '{}' `
    -ExpectedStatus 400 `
    -ExpectedError "reason"

# TEST 2: Reject with empty reason (400 Bad Request)
Test-Endpoint `
    -TestName "TEST 2: Reject with empty reason" `
    -Method "Post" `
    -Url "$BASE_URL/commissions/$pendingId/reject" `
    -Headers $adminHeaders `
    -Body '{"reject_reason":""}' `
    -ExpectedStatus 400 `
    -ExpectedError "reason"

# TEST 3: Non-admin approve (403 Forbidden)
if (-not $skipFinance) {
    $financeHeaders = @{
        "Authorization" = "Bearer $env:FINANCE_JWT"
        "apikey" = $env:FINANCE_JWT
        "Content-Type" = "application/json"
    }

    Test-Endpoint `
        -TestName "TEST 3: Non-admin (finance) approve" `
        -Method "Post" `
        -Url "$BASE_URL/commissions/$pendingId/approve" `
        -Headers $financeHeaders `
        -Body '{}' `
        -ExpectedStatus 403 `
        -ExpectedError "admin"
}

# TEST 4: Viewer list commissions (403 Forbidden)
if (-not $skipViewer) {
    $viewerHeaders = @{
        "Authorization" = "Bearer $env:VIEWER_JWT"
        "apikey" = $env:VIEWER_JWT
        "Content-Type" = "application/json"
    }

    Test-Endpoint `
        -TestName "TEST 4: Viewer list commissions" `
        -Method "Get" `
        -Url "$BASE_URL/commissions" `
        -Headers $viewerHeaders `
        -Body $null `
        -ExpectedStatus 403 `
        -ExpectedError "permission"
}

# TEST 5: Viewer get single commission (403 Forbidden)
if (-not $skipViewer) {
    Test-Endpoint `
        -TestName "TEST 5: Viewer get commission detail" `
        -Method "Get" `
        -Url "$BASE_URL/commissions/$pendingId" `
        -Headers $viewerHeaders `
        -Body $null `
        -ExpectedStatus 403 `
        -ExpectedError "permission"
}

# TEST 6: Invalid status transition (draft → approved, skip pending) (400)
try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/commissions?status=draft" -Headers $adminHeaders -Method Get
    $drafts = $response.data

    if ($drafts.Count -gt 0) {
        $draftId = $drafts[0].id

        Test-Endpoint `
            -TestName "TEST 6: Invalid transition (draft → approved)" `
            -Method "Post" `
            -Url "$BASE_URL/commissions/$draftId/approve" `
            -Headers $adminHeaders `
            -Body '{}' `
            -ExpectedStatus 400 `
            -ExpectedError "pending"
    }
} catch {
    Write-Host "⚠️  Skipping TEST 6 (no draft commissions)" -ForegroundColor Yellow
}

# TEST 7: Mark-paid without payment_ref (400)
try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/commissions?status=approved" -Headers $adminHeaders -Method Get
    $approved = $response.data

    if ($approved.Count -gt 0) {
        $approvedId = $approved[0].id

        Test-Endpoint `
            -TestName "TEST 7: Mark-paid without payment_ref" `
            -Method "Post" `
            -Url "$BASE_URL/commissions/$approvedId/mark-paid" `
            -Headers $adminHeaders `
            -Body '{}' `
            -ExpectedStatus 400 `
            -ExpectedError "payment_ref"
    }
} catch {
    Write-Host "⚠️  Skipping TEST 7 (no approved commissions)" -ForegroundColor Yellow
}

# TEST 8: Compute without contribution_id (400)
Test-Endpoint `
    -TestName "TEST 8: Compute without contribution_id" `
    -Method "Post" `
    -Url "$BASE_URL/commissions/compute" `
    -Headers $adminHeaders `
    -Body '{}' `
    -ExpectedStatus 400 `
    -ExpectedError "contribution_id"

# TEST 9: Compute with non-existent contribution (404)
$fakeUuid = "00000000-0000-0000-0000-000000000000"
Test-Endpoint `
    -TestName "TEST 9: Compute with fake contribution_id" `
    -Method "Post" `
    -Url "$BASE_URL/commissions/compute" `
    -Headers $adminHeaders `
    -Body "{`"contribution_id`":`"$fakeUuid`"}" `
    -ExpectedStatus 404 `
    -ExpectedError "not found"

# ============================================================
# RESULTS TABLE
# ============================================================

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "TEST RESULTS" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$testResults | Format-Table -AutoSize

$passed = ($testResults | Where-Object { $_.Status -eq "PASS" }).Count
$failed = ($testResults | Where-Object { $_.Status -eq "FAIL" }).Count
$total = $testResults.Count

Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  ✅ Passed: $passed / $total" -ForegroundColor Green
Write-Host "  ❌ Failed: $failed / $total" -ForegroundColor Red
Write-Host ""

if ($failed -eq 0) {
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "✅ TRACK D10 COMPLETE - All tests passed!" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "DoD: All return standardized errors, 0× 500s ✅" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next: Track E11 - Demo Guide Checkoff" -ForegroundColor Cyan
    exit 0
} else {
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "❌ TRACK D10 INCOMPLETE - $failed test(s) failed" -ForegroundColor Red
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Review failed tests above and fix issues." -ForegroundColor Yellow
    exit 1
}
