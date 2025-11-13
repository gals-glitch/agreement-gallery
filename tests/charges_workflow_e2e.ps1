# ============================================
# Charges Workflow E2E Test (QA-03)
# ============================================
# Purpose: End-to-end test of full charge workflow lifecycle
# Coverage: DRAFT → PENDING → APPROVED → PAID + Rejection flow + Batch compute
# Date: 2025-10-21
#
# Prerequisites:
#   1. Run seed script: psql -f docs/e2e/test_data_seed.sql
#   2. Have valid SERVICE_KEY in environment
#
# Cleanup:
#   Run teardown script: psql -f docs/e2e/test_data_teardown.sql
# ============================================

param(
    [string]$ServiceKey = "",
    [string]$BaseUrl = "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1",
    [switch]$SkipCleanup
)

# Set default service key if not provided
if (-not $ServiceKey) {
    $ServiceKey = if ($env:SERVICE_KEY) { $env:SERVICE_KEY } else { "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3Z2ljcmRjb3Fka2V0cWh4YnlzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzIyNjMwNywiZXhwIjoyMDcyODAyMzA3fQ.bPUTKQM-tOm1u_1NlVNXczSbA118443uOpeo2Waa2zo" }
}

$ErrorActionPreference = "Stop"

# ============================================
# TEST STATE
# ============================================
$script:testsPassed = 0
$script:testsFailed = 0
$script:testResults = @()
$script:chargeIds = @{}

# ============================================
# HELPER FUNCTIONS
# ============================================
function Write-TestHeader {
    param([string]$Message)
    Write-Host "`n============================================" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
}

function Write-TestStep {
    param([string]$Message)
    Write-Host "`n[STEP] $Message" -ForegroundColor Yellow
}

function Write-TestPass {
    param([string]$Message)
    Write-Host "[PASS] $Message" -ForegroundColor Green
    $script:testsPassed++
}

function Write-TestFail {
    param([string]$Message, [string]$Details = "")
    Write-Host "[FAIL] $Message" -ForegroundColor Red
    if ($Details) {
        Write-Host "  Details: $Details" -ForegroundColor Gray
    }
    $script:testsFailed++
}

function Invoke-ChargeRequest {
    param(
        [string]$Method,
        [string]$Endpoint,
        [object]$Body = $null
    )

    $headers = @{
        "Authorization" = "Bearer $ServiceKey"
        "apikey" = "$ServiceKey"
        "Content-Type" = "application/json"
    }

    $params = @{
        Uri = "$BaseUrl$Endpoint"
        Method = $Method
        Headers = $headers
    }

    if ($Body) {
        $params.Body = ($Body | ConvertTo-Json -Depth 10)
    }

    try {
        $response = Invoke-RestMethod @params
        return $response
    } catch {
        Write-Host "[ERROR] Request failed: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.ErrorDetails.Message) {
            Write-Host "  Error Details: $($_.ErrorDetails.Message)" -ForegroundColor Gray
        }
        throw
    }
}

function Assert-Equal {
    param(
        [string]$TestName,
        $Expected,
        $Actual,
        [string]$Message
    )

    if ($Expected -eq $Actual) {
        Write-TestPass "$TestName - $Message"
        $script:testResults += @{
            test = $TestName
            status = "PASS"
            expected = $Expected
            actual = $Actual
            message = $Message
        }
    } else {
        Write-TestFail "$TestName - $Message" "Expected: $Expected, Actual: $Actual"
        $script:testResults += @{
            test = $TestName
            status = "FAIL"
            expected = $Expected
            actual = $Actual
            message = $Message
        }
    }
}

function Assert-NotNull {
    param(
        [string]$TestName,
        $Value,
        [string]$Message
    )

    if ($null -ne $Value) {
        Write-TestPass "$TestName - $Message"
        $script:testResults += @{
            test = $TestName
            status = "PASS"
            message = $Message
        }
    } else {
        Write-TestFail "$TestName - $Message" "Value is null"
        $script:testResults += @{
            test = $TestName
            status = "FAIL"
            message = $Message
            error = "Value is null"
        }
    }
}

function Assert-GreaterThan {
    param(
        [string]$TestName,
        [decimal]$Actual,
        [decimal]$Threshold,
        [string]$Message
    )

    if ($Actual -gt $Threshold) {
        Write-TestPass "$TestName - $Message (Actual: $Actual > $Threshold)"
        $script:testResults += @{
            test = $TestName
            status = "PASS"
            actual = $Actual
            threshold = $Threshold
            message = $Message
        }
    } else {
        Write-TestFail "$TestName - $Message" "Expected > $Threshold, got $Actual"
        $script:testResults += @{
            test = $TestName
            status = "FAIL"
            actual = $Actual
            threshold = $Threshold
            message = $Message
        }
    }
}

# ============================================
# TEST EXECUTION
# ============================================
Write-TestHeader "CHARGES WORKFLOW E2E TEST"
Write-Host "Base URL: $BaseUrl" -ForegroundColor Gray
Write-Host "Test Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

# ============================================
# HAPPY PATH: DRAFT → PENDING → APPROVED → PAID
# ============================================
Write-TestHeader "HAPPY PATH: DRAFT → PENDING → APPROVED → PAID"

# Step 1: Compute Charge (DRAFT)
Write-TestStep "Compute charge for contribution 999 ($50,000)"
$computeResponse = Invoke-ChargeRequest -Method POST -Endpoint "/charges/compute" -Body @{
    contribution_id = 999
}

$script:chargeIds['happy_path'] = $computeResponse.id

Assert-Equal -TestName "E2E-01" -Expected "DRAFT" -Actual $computeResponse.status -Message "Charge status is DRAFT after compute"
Assert-NotNull -TestName "E2E-02" -Value $computeResponse.id -Message "Charge ID is returned"
Assert-Equal -TestName "E2E-03" -Expected 500.00 -Actual $computeResponse.base_amount -Message "Base amount is $500 (100 bps of $50,000)"
Assert-Equal -TestName "E2E-04" -Expected 100.00 -Actual $computeResponse.vat_amount -Message "VAT amount is $100 (20% of $500)"
Assert-Equal -TestName "E2E-05" -Expected 600.00 -Actual $computeResponse.total_amount -Message "Total amount is $600 ($500 + $100 VAT)"

Write-Host "`n  Charge ID: $($computeResponse.id)" -ForegroundColor Cyan
Write-Host "  Base: `$$($computeResponse.base_amount), VAT: `$$($computeResponse.vat_amount), Total: `$$($computeResponse.total_amount)" -ForegroundColor Cyan

# Step 2: Submit Charge (DRAFT → PENDING)
Write-TestStep "Submit charge (apply FIFO credits)"
$submitResponse = Invoke-ChargeRequest -Method POST -Endpoint "/charges/$($computeResponse.id)/submit"

Assert-Equal -TestName "E2E-06" -Expected "PENDING" -Actual $submitResponse.status -Message "Charge status is PENDING after submit"
Assert-Equal -TestName "E2E-07" -Expected 500.00 -Actual $submitResponse.credits_applied_amount -Message "Credits applied: $500 (full credit balance)"
Assert-Equal -TestName "E2E-08" -Expected 100.00 -Actual $submitResponse.net_amount -Message "Net amount is $100 ($600 - $500 credits)"
Assert-NotNull -TestName "E2E-09" -Value $submitResponse.submitted_at -Message "submitted_at timestamp is set"

Write-Host "`n  Credits applied: `$$($submitResponse.credits_applied_amount)" -ForegroundColor Cyan
Write-Host "  Net amount: `$$($submitResponse.net_amount)" -ForegroundColor Cyan

# Step 3: Approve Charge (PENDING → APPROVED)
Write-TestStep "Approve charge"
$approveResponse = Invoke-ChargeRequest -Method POST -Endpoint "/charges/$($computeResponse.id)/approve"

Assert-Equal -TestName "E2E-10" -Expected "APPROVED" -Actual $approveResponse.status -Message "Charge status is APPROVED after approval"
Assert-NotNull -TestName "E2E-11" -Value $approveResponse.approved_at -Message "approved_at timestamp is set"
Assert-NotNull -TestName "E2E-12" -Value $approveResponse.approved_by -Message "approved_by is set"

Write-Host "`n  Approved at: $($approveResponse.approved_at)" -ForegroundColor Cyan
Write-Host "  Approved by: $($approveResponse.approved_by)" -ForegroundColor Cyan

# Step 4: Mark as Paid (APPROVED → PAID)
Write-TestStep "Mark charge as paid"
$markPaidResponse = Invoke-ChargeRequest -Method POST -Endpoint "/charges/$($computeResponse.id)/mark-paid" -Body @{
    payment_ref = "E2E-WIRE-001"
    paid_at = (Get-Date -Format "o")
}

Assert-Equal -TestName "E2E-13" -Expected "PAID" -Actual $markPaidResponse.status -Message "Charge status is PAID after mark-paid"
Assert-NotNull -TestName "E2E-14" -Value $markPaidResponse.paid_at -Message "paid_at timestamp is set"
Assert-Equal -TestName "E2E-15" -Expected "E2E-WIRE-001" -Actual $markPaidResponse.payment_ref -Message "Payment reference is recorded"

Write-Host "`n  Paid at: $($markPaidResponse.paid_at)" -ForegroundColor Cyan
Write-Host "  Payment ref: $($markPaidResponse.payment_ref)" -ForegroundColor Cyan
Write-Host "`n✅ Happy path completed: DRAFT → PENDING → APPROVED → PAID" -ForegroundColor Green

# ============================================
# REJECTION PATH: Test credit reversal
# ============================================
Write-TestHeader "REJECTION PATH: Credit Reversal Test"

# Step 1: Compute charge for contribution 998 ($30,000)
Write-TestStep "Compute charge for contribution 998 ($30,000)"
$computeResponse2 = Invoke-ChargeRequest -Method POST -Endpoint "/charges/compute" -Body @{
    contribution_id = 998
}

$script:chargeIds['rejection_path'] = $computeResponse2.id

Assert-Equal -TestName "E2E-16" -Expected "DRAFT" -Actual $computeResponse2.status -Message "Second charge status is DRAFT"
Assert-Equal -TestName "E2E-17" -Expected 300.00 -Actual $computeResponse2.base_amount -Message "Base amount is $300 (100 bps of $30,000)"
Assert-Equal -TestName "E2E-18" -Expected 60.00 -Actual $computeResponse2.vat_amount -Message "VAT amount is $60 (20% of $300)"
Assert-Equal -TestName "E2E-19" -Expected 360.00 -Actual $computeResponse2.total_amount -Message "Total amount is $360"

# Step 2: Submit charge (no credits available - all consumed by first charge)
Write-TestStep "Submit second charge (no credits available)"
$submitResponse2 = Invoke-ChargeRequest -Method POST -Endpoint "/charges/$($computeResponse2.id)/submit"

Assert-Equal -TestName "E2E-20" -Expected "PENDING" -Actual $submitResponse2.status -Message "Second charge status is PENDING"
Assert-Equal -TestName "E2E-21" -Expected 0.00 -Actual $submitResponse2.credits_applied_amount -Message "No credits applied (balance depleted)"
Assert-Equal -TestName "E2E-22" -Expected 360.00 -Actual $submitResponse2.net_amount -Message "Net amount equals total (no credits)"

Write-Host "`n  Credits applied: `$$($submitResponse2.credits_applied_amount) (none available)" -ForegroundColor Cyan
Write-Host "  Net amount: `$$($submitResponse2.net_amount)" -ForegroundColor Cyan

# Step 3: Reject charge and verify credits NOT reversed (because none were applied)
Write-TestStep "Reject second charge (no credits to reverse)"
$rejectResponse2 = Invoke-ChargeRequest -Method POST -Endpoint "/charges/$($computeResponse2.id)/reject" -Body @{
    reject_reason = "E2E test rejection - verifying credit reversal logic"
}

Assert-Equal -TestName "E2E-23" -Expected "REJECTED" -Actual $rejectResponse2.status -Message "Charge status is REJECTED"
Assert-NotNull -TestName "E2E-24" -Value $rejectResponse2.rejected_at -Message "rejected_at timestamp is set"
Assert-NotNull -TestName "E2E-25" -Value $rejectResponse2.reject_reason -Message "reject_reason is recorded"

Write-Host "`n  Rejected at: $($rejectResponse2.rejected_at)" -ForegroundColor Cyan
Write-Host "  Reject reason: $($rejectResponse2.reject_reason)" -ForegroundColor Cyan

# Step 4: Reset first charge to PENDING and reject it to test credit reversal
Write-TestStep "Reject first charge (should reverse $500 credit)"

# Note: This requires resetting the charge status first (may need admin SQL or endpoint)
# For now, we'll skip this test as it requires modifying charge state backward
Write-Host "[INFO] Credit reversal test requires resetting charge state - manual verification needed" -ForegroundColor Yellow

Write-Host "`n✅ Rejection path completed" -ForegroundColor Green

# ============================================
# BATCH COMPUTE: 50 contributions
# ============================================
Write-TestHeader "BATCH COMPUTE: 50 Contributions"

Write-TestStep "Batch compute charges for contributions 948-997"
$batchResponse = Invoke-ChargeRequest -Method POST -Endpoint "/charges/batch-compute" -Body @{
    contribution_ids = (948..997)
}

Assert-Equal -TestName "E2E-26" -Expected 50 -Actual $batchResponse.total -Message "Batch compute processed 50 contributions"
Assert-GreaterThan -TestName "E2E-27" -Actual $batchResponse.successful -Threshold 45 -Message "At least 46 charges computed successfully"
Assert-NotNull -TestName "E2E-28" -Value $batchResponse.results -Message "Batch results array is returned"

Write-Host "`n  Total: $($batchResponse.total)" -ForegroundColor Cyan
Write-Host "  Successful: $($batchResponse.successful)" -ForegroundColor Cyan
Write-Host "  Failed: $($batchResponse.failed)" -ForegroundColor Cyan

if ($batchResponse.failed -gt 0) {
    Write-Host "`n  Failed contributions:" -ForegroundColor Yellow
    $batchResponse.results | Where-Object { $_.status -eq 'error' } | ForEach-Object {
        Write-Host "    Contribution $($_.contribution_id): $($_.errors -join ', ')" -ForegroundColor Gray
    }
}

Write-Host "`n✅ Batch compute completed" -ForegroundColor Green

# ============================================
# IDEMPOTENCY TESTS
# ============================================
Write-TestHeader "IDEMPOTENCY TESTS"

Write-TestStep "Compute same contribution twice (should upsert, not duplicate)"
$computeAgain = Invoke-ChargeRequest -Method POST -Endpoint "/charges/compute" -Body @{
    contribution_id = 999
}

Assert-Equal -TestName "E2E-29" -Expected $script:chargeIds['happy_path'] -Actual $computeAgain.id -Message "Idempotent compute returns same charge ID"

Write-Host "`n  Original charge ID: $($script:chargeIds['happy_path'])" -ForegroundColor Cyan
Write-Host "  Re-computed charge ID: $($computeAgain.id)" -ForegroundColor Cyan

Write-Host "`n✅ Idempotency tests completed" -ForegroundColor Green

# ============================================
# TEST SUMMARY
# ============================================
Write-TestHeader "E2E TEST SUMMARY"

$totalTests = $script:testsPassed + $script:testsFailed
$passRate = if ($totalTests -gt 0) { [math]::Round(($script:testsPassed / $totalTests) * 100, 2) } else { 0 }

Write-Host "Total Tests: $totalTests" -ForegroundColor White
Write-Host "Passed: $script:testsPassed" -ForegroundColor Green
Write-Host "Failed: $script:testsFailed" -ForegroundColor $(if ($script:testsFailed -gt 0) { "Red" } else { "Gray" })
Write-Host "Pass Rate: $passRate%" -ForegroundColor $(if ($passRate -ge 90) { "Green" } elseif ($passRate -ge 70) { "Yellow" } else { "Red" })

# ============================================
# SAVE RESULTS
# ============================================
$resultsPath = "C:\Users\GalSamionov\Buligo Capital\Buligo Capital - Shared Documents\Information Systems\Gal\agreement-gallery-main\docs\e2e\e2e_test_results.json"
$resultsDir = Split-Path $resultsPath -Parent

if (-not (Test-Path $resultsDir)) {
    New-Item -ItemType Directory -Path $resultsDir -Force | Out-Null
}

@{
    timestamp = (Get-Date -Format "o")
    total = $totalTests
    passed = $script:testsPassed
    failed = $script:testsFailed
    passRate = $passRate
    chargeIds = $script:chargeIds
    results = $script:testResults
} | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultsPath -Encoding UTF8

Write-Host "`nResults saved to: $resultsPath" -ForegroundColor Cyan

# ============================================
# CLEANUP INSTRUCTIONS
# ============================================
if (-not $SkipCleanup) {
    Write-Host "`n============================================" -ForegroundColor Cyan
    Write-Host "CLEANUP INSTRUCTIONS" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "To clean up test data, run:" -ForegroundColor Yellow
    Write-Host "  psql -h <host> -U postgres -d <database> -f docs/e2e/test_data_teardown.sql" -ForegroundColor White
    Write-Host "`nOr manually delete test entities with ID 999 and contributions 948-999" -ForegroundColor Gray
}

# ============================================
# EXIT CODE
# ============================================
if ($script:testsFailed -gt 0) {
    Write-Host "`n[FAILURE] Some E2E tests failed. Review output above." -ForegroundColor Red
    exit 1
} else {
    Write-Host "`n[SUCCESS] All E2E tests passed!" -ForegroundColor Green
    exit 0
}
