# ============================================================
# 04_WORKFLOW_TEST: COMMISSION WORKFLOW HAPPY PATH TEST
# ============================================================
# Purpose: Automated test of complete commission workflow
# Flow: compute ’ draft ’ submit ’ pending ’ approve ’ mark-paid
# Validates: Each state transition, timestamps, audit fields
# ============================================================

param(
    [Parameter(Mandatory=$false)]
    [int]$ContributionId
)

$ErrorActionPreference = "Stop"

$BASE_URL = "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1"
$SUPABASE_URL = "https://qwgicrdcoqdketqhxbys.supabase.co"

# Check for service role key
if (-not $env:SUPABASE_SERVICE_ROLE_KEY) {
    Write-Host "L ERROR: SUPABASE_SERVICE_ROLE_KEY environment variable not set" -ForegroundColor Red
    exit 1
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "QA-02: COMMISSION WORKFLOW HAPPY PATH TEST" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$headers = @{
    "Authorization" = "Bearer $env:SUPABASE_SERVICE_ROLE_KEY"
    "apikey" = $env:SUPABASE_SERVICE_ROLE_KEY
    "Content-Type" = "application/json"
}

$testResults = @()
$allPassed = $true

function Test-Assertion {
    param($name, $condition, $message)

    if ($condition) {
        Write-Host "   $name" -ForegroundColor Green
        $script:testResults += [PSCustomObject]@{ Test = $name; Result = "PASS"; Message = $message }
    } else {
        Write-Host "  L $name - $message" -ForegroundColor Red
        $script:testResults += [PSCustomObject]@{ Test = $name; Result = "FAIL"; Message = $message }
        $script:allPassed = $false
    }
}

# Step 0: Find eligible contribution if not provided
if (-not $ContributionId) {
    Write-Host "=Ê Step 0: Finding eligible contribution for testing..." -ForegroundColor Yellow

    $query = "contributions?select=id,investor_id,deal_id,amount,investors!inner(introduced_by_party_id)&investors.introduced_by_party_id=not.is.null&order=id.asc&limit=1"

    try {
        $contributions = Invoke-RestMethod -Uri "$SUPABASE_URL/rest/v1/$query" -Headers $headers -Method Get

        if ($contributions.Count -eq 0) {
            Write-Host "L No eligible contributions found" -ForegroundColor Red
            Write-Host "Run scripts to set up investor-party links first" -ForegroundColor Yellow
            exit 1
        }

        $ContributionId = $contributions[0].id
        Write-Host " Using contribution: $ContributionId (Amount: $($contributions[0].amount))" -ForegroundColor Green
    } catch {
        Write-Host "L Failed to find contribution: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}
Write-Host ""

# Step 1: Compute Commission (draft)
Write-Host "=Ê Step 1: Computing commission (contribution ’ draft)..." -ForegroundColor Yellow
$computeBody = @{ contribution_id = $ContributionId } | ConvertTo-Json

try {
    $computeResult = Invoke-RestMethod -Uri "$BASE_URL/commissions/compute" -Headers $headers -Method Post -Body $computeBody
    $commission = $computeResult.data
    $commissionId = $commission.id

    Write-Host " Commission computed: $commissionId" -ForegroundColor Green

    Test-Assertion "Commission ID generated" ($commission.id -ne $null) "ID: $($commission.id)"
    Test-Assertion "Status is DRAFT" ($commission.status -eq "draft") "Got: $($commission.status)"
    Test-Assertion "Base amount is positive" ($commission.base_amount -gt 0) "Amount: $($commission.base_amount)"
    Test-Assertion "Total amount = base + VAT" ($commission.total_amount -eq ($commission.base_amount + $commission.vat_amount)) "Calculation matches"
    Test-Assertion "Created timestamp set" ($commission.created_at -ne $null) "Timestamp: $($commission.created_at)"
    Test-Assertion "Party ID set" ($commission.party_id -ne $null) "Party: $($commission.party_id)"
    Test-Assertion "Investor ID set" ($commission.investor_id -ne $null) "Investor: $($commission.investor_id)"

} catch {
    Write-Host "L Compute failed: $($_.Exception.Message)" -ForegroundColor Red
    Test-Assertion "Commission compute" $false "Failed: $($_.Exception.Message)"
    exit 1
}
Write-Host ""

# Step 2: Submit (draft ’ pending)
Write-Host "=Ê Step 2: Submitting commission (draft ’ pending)..." -ForegroundColor Yellow

try {
    $submitResult = Invoke-RestMethod -Uri "$BASE_URL/commissions/$commissionId/submit" -Headers $headers -Method Post -Body "{}"
    $commission = $submitResult.data

    Write-Host " Commission submitted" -ForegroundColor Green

    Test-Assertion "Status changed to PENDING" ($commission.status -eq "pending") "Got: $($commission.status)"
    Test-Assertion "Submitted timestamp set" ($commission.submitted_at -ne $null) "Timestamp: $($commission.submitted_at)"

} catch {
    Write-Host "L Submit failed: $($_.Exception.Message)" -ForegroundColor Red
    Test-Assertion "Commission submit" $false "Failed: $($_.Exception.Message)"
    exit 1
}
Write-Host ""

# Step 3: Approve (pending ’ approved)
Write-Host "=Ê Step 3: Approving commission (pending ’ approved)..." -ForegroundColor Yellow

try {
    $approveResult = Invoke-RestMethod -Uri "$BASE_URL/commissions/$commissionId/approve" -Headers $headers -Method Post -Body "{}"
    $commission = $approveResult.data

    Write-Host " Commission approved" -ForegroundColor Green

    Test-Assertion "Status changed to APPROVED" ($commission.status -eq "approved") "Got: $($commission.status)"
    Test-Assertion "Approved timestamp set" ($commission.approved_at -ne $null) "Timestamp: $($commission.approved_at)"

} catch {
    Write-Host "L Approve failed: $($_.Exception.Message)" -ForegroundColor Red
    Test-Assertion "Commission approve" $false "Failed: $($_.Exception.Message)"
    exit 1
}
Write-Host ""

# Step 4: Mark as Paid (approved ’ paid)
Write-Host "=Ê Step 4: Marking as paid (approved ’ paid)..." -ForegroundColor Yellow
$paymentRef = "TEST-$(Get-Date -Format 'yyyyMMddHHmmss')"
$paidBody = @{ payment_ref = $paymentRef } | ConvertTo-Json

try {
    $paidResult = Invoke-RestMethod -Uri "$BASE_URL/commissions/$commissionId/mark-paid" -Headers $headers -Method Post -Body $paidBody
    $commission = $paidResult.data

    Write-Host " Commission marked as paid" -ForegroundColor Green

    Test-Assertion "Status changed to PAID" ($commission.status -eq "paid") "Got: $($commission.status)"
    Test-Assertion "Paid timestamp set" ($commission.paid_at -ne $null) "Timestamp: $($commission.paid_at)"
    Test-Assertion "Payment reference set" ($commission.payment_ref -eq $paymentRef) "Ref: $paymentRef"

} catch {
    Write-Host "L Mark paid failed: $($_.Exception.Message)" -ForegroundColor Red
    Test-Assertion "Commission mark-paid" $false "Failed: $($_.Exception.Message)"
    exit 1
}
Write-Host ""

# Step 5: Verify Final State
Write-Host "=Ê Step 5: Verifying final state..." -ForegroundColor Yellow

try {
    $finalCommission = Invoke-RestMethod -Uri "$BASE_URL/commissions/$commissionId" -Headers $headers -Method Get
    $commission = $finalCommission.data

    Write-Host " Final state retrieved" -ForegroundColor Green

    Test-Assertion "Final status is PAID" ($commission.status -eq "paid") "Got: $($commission.status)"
    Test-Assertion "All timestamps sequential" (
        $commission.created_at -le $commission.submitted_at -and
        $commission.submitted_at -le $commission.approved_at -and
        $commission.approved_at -le $commission.paid_at
    ) "Timeline is valid"
    Test-Assertion "Snapshot JSON preserved" ($commission.snapshot_json -ne $null) "Snapshot exists"

    Write-Host ""
    Write-Host "Commission Timeline:" -ForegroundColor Cyan
    Write-Host "  Created:   $($commission.created_at)" -ForegroundColor Gray
    Write-Host "  Submitted: $($commission.submitted_at)" -ForegroundColor Gray
    Write-Host "  Approved:  $($commission.approved_at)" -ForegroundColor Gray
    Write-Host "  Paid:      $($commission.paid_at)" -ForegroundColor Gray

} catch {
    Write-Host "L Final verification failed: $($_.Exception.Message)" -ForegroundColor Red
    Test-Assertion "Final state verification" $false "Failed: $($_.Exception.Message)"
}
Write-Host ""

# Test Summary
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "TEST SUMMARY" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$passCount = ($testResults | Where-Object { $_.Result -eq "PASS" }).Count
$failCount = ($testResults | Where-Object { $_.Result -eq "FAIL" }).Count
$totalTests = $testResults.Count

Write-Host "Total Tests: $totalTests" -ForegroundColor Cyan
Write-Host "Passed:      $passCount" -ForegroundColor Green
Write-Host "Failed:      $failCount" -ForegroundColor $(if ($failCount -eq 0) { "Green" } else { "Red" })
Write-Host ""

if ($allPassed) {
    Write-Host " QA-02 PASSED: All workflow tests successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Commission ID: $commissionId" -ForegroundColor Cyan
    Write-Host "Status: PAID " -ForegroundColor Green
    Write-Host "Total Amount: $($commission.total_amount)" -ForegroundColor Cyan
    Write-Host ""
    exit 0
} else {
    Write-Host "L QA-02 FAILED: Some tests did not pass" -ForegroundColor Red
    Write-Host ""
    Write-Host "Failed Tests:" -ForegroundColor Yellow
    $testResults | Where-Object { $_.Result -eq "FAIL" } | ForEach-Object {
        Write-Host "  " $($_.Test): $($_.Message)" -ForegroundColor Red
    }
    Write-Host ""
    exit 1
}
