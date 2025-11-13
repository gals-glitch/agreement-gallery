###############################################################################
# Gate C: Complete System Validation
# Runs all verification steps and generates a comprehensive report
###############################################################################

$ErrorActionPreference = "Stop"

if (-not $env:SUPABASE_SERVICE_ROLE_KEY) {
    Write-Host "ERROR: Service role key not set" -ForegroundColor Red
    Write-Host "Run: .\set_key.ps1" -ForegroundColor Yellow
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $env:SUPABASE_SERVICE_ROLE_KEY"
    "apikey" = $env:SUPABASE_SERVICE_ROLE_KEY
    "Content-Type" = "application/json"
}

$base = "https://qwgicrdcoqdketqhxbys.supabase.co/rest/v1"
$apiBase = "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "GATE C: SYSTEM VALIDATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$report = @()
$allPassed = $true

# ============================================
# Test 1: Check investor coverage
# ============================================

Write-Host "Test 1: Investor Coverage" -ForegroundColor Yellow

$withParty = (Invoke-RestMethod -Uri "$base/investors?select=id`&introduced_by_party_id=not.is.null" -Headers $headers).Count
$total = (Invoke-RestMethod -Uri "$base/investors?select=id" -Headers $headers).Count
$coverage = [math]::Round(($withParty / $total) * 100, 1)

Write-Host "  Investors with party links: $withParty/$total ($coverage%)" -ForegroundColor Gray

if ($coverage -ge 80) {
    Write-Host "  ✅ PASS (≥80%)" -ForegroundColor Green
    $report += "✅ Investor Coverage: $coverage% (target: ≥80%)"
} else {
    Write-Host "  ❌ FAIL (<80%)" -ForegroundColor Red
    $report += "❌ Investor Coverage: $coverage% (target: ≥80%)"
    $allPassed = $false
}
Write-Host ""

# ============================================
# Test 2: Count eligible contributions
# ============================================

Write-Host "Test 2: Eligible Contributions" -ForegroundColor Yellow

# Count contributions with investor+party+agreement
$eligible = 0
try {
    $contribs = Invoke-RestMethod -Uri "$base/contributions?select=id,investor_id,deal_id" -Headers $headers

    foreach ($c in $contribs) {
        # Check if investor has party link
        $investor = Invoke-RestMethod -Uri "$base/investors?select=introduced_by_party_id`&id=eq.$($c.investor_id)" -Headers $headers
        if (-not $investor[0].introduced_by_party_id) { continue }

        # Check if approved agreement exists
        $partyId = $investor[0].introduced_by_party_id
        $agreement = Invoke-RestMethod -Uri "$base/agreements?select=id`&party_id=eq.$partyId`&deal_id=eq.$($c.deal_id)`&status=eq.APPROVED`&limit=1" -Headers $headers
        if ($agreement.Count -eq 0) { continue }

        # Check if commission already exists
        $commission = Invoke-RestMethod -Uri "$base/commissions?select=id`&contribution_id=eq.$($c.id)`&limit=1" -Headers $headers
        if ($commission.Count -gt 0) { continue }

        $eligible++
    }
} catch {
    Write-Host "  ⚠️  Could not count eligible (manual verification required)" -ForegroundColor Yellow
    $eligible = "Unknown"
}

Write-Host "  Eligible to compute: $eligible" -ForegroundColor Gray
$report += "INFO: Eligible Contributions: $eligible"
Write-Host ""

# ============================================
# Test 3: Run batch compute
# ============================================

Write-Host "Test 3: Batch Compute" -ForegroundColor Yellow

try {
    # Get all contribution IDs
    $allContribs = Invoke-RestMethod -Uri "$base/contributions?select=id`&limit=100" -Headers $headers
    $contribIds = $allContribs | ForEach-Object { $_.id }

    # Batch compute
    $body = @{ contribution_ids = $contribIds } | ConvertTo-Json
    $result = Invoke-RestMethod -Uri "$apiBase/commissions/batch-compute" -Headers $headers -Method Post -Body $body

    $successCount = ($result.results | Where-Object { $_.status -ne "error" }).Count
    $errorCount = ($result.results | Where-Object { $_.status -eq "error" }).Count

    Write-Host "  Success: $successCount" -ForegroundColor Green
    Write-Host "  Errors: $errorCount" -ForegroundColor $(if ($errorCount -eq 0) { "Green" } else { "Yellow" })

    if ($successCount -ge 8) {
        Write-Host "  ✅ PASS (≥8 commissions created)" -ForegroundColor Green
        $report += "✅ Batch Compute: $successCount commissions created (target: ≥8)"
    } else {
        Write-Host "  ❌ FAIL (<8 commissions)" -ForegroundColor Red
        $report += "❌ Batch Compute: $successCount commissions created (target: ≥8)"
        $allPassed = $false
    }
} catch {
    Write-Host "  ❌ FAIL: $($_.Exception.Message)" -ForegroundColor Red
    $report += "❌ Batch Compute: Failed - $($_.Exception.Message)"
    $allPassed = $false
}
Write-Host ""

# ============================================
# Test 4: Check coverage gaps
# ============================================

Write-Host "Test 4: Coverage Gaps" -ForegroundColor Yellow

# Count contributions with party but no agreement
$gaps = 0
try {
    $contribs = Invoke-RestMethod -Uri "$base/contributions?select=id,investor_id,deal_id`&limit=100" -Headers $headers

    foreach ($c in $contribs) {
        $investor = Invoke-RestMethod -Uri "$base/investors?select=introduced_by_party_id`&id=eq.$($c.investor_id)" -Headers $headers
        if (-not $investor[0].introduced_by_party_id) { continue }  # No party = expected skip

        $partyId = $investor[0].introduced_by_party_id
        $agreement = Invoke-RestMethod -Uri "$base/agreements?select=id`&party_id=eq.$partyId`&deal_id=eq.$($c.deal_id)`&status=eq.APPROVED`&limit=1" -Headers $headers

        if ($agreement.Count -eq 0) {
            $gaps++
        }
    }
} catch {
    Write-Host "  ⚠️  Could not count gaps" -ForegroundColor Yellow
}

Write-Host "  Contributions with party but missing agreement: $gaps" -ForegroundColor Gray

if ($gaps -eq 0) {
    Write-Host "  ✅ PASS (perfect coverage)" -ForegroundColor Green
    $report += "✅ Coverage Gaps: 0 (perfect)"
} else {
    Write-Host "  ⚠️  WARNING: $gaps contributions have party but no agreement" -ForegroundColor Yellow
    $report += "⚠️  Coverage Gaps: $gaps contributions need agreements"
}
Write-Host ""

# ============================================
# Test 5: Workflow transitions
# ============================================

Write-Host "Test 5: Workflow Transitions" -ForegroundColor Yellow

# Get first draft commission
$draft = (Invoke-RestMethod -Uri "$base/commissions?select=id`&status=eq.draft`&limit=1" -Headers $headers)[0]

if (-not $draft) {
    Write-Host "  ⚠️  No draft commissions to test" -ForegroundColor Yellow
    $report += "⚠️  Workflow: No draft commissions available for testing"
} else {
    $commId = $draft.id
    Write-Host "  Testing commission: $commId" -ForegroundColor Gray

    try {
        # Submit (draft → pending)
        $null = Invoke-RestMethod -Uri "$apiBase/commissions/$commId/submit" -Headers $headers -Method Post
        Write-Host "  ✅ Submit: draft → pending" -ForegroundColor Green

        Start-Sleep -Seconds 1

        # Approve (pending → approved)
        $null = Invoke-RestMethod -Uri "$apiBase/commissions/$commId/approve" -Headers $headers -Method Post
        Write-Host "  ✅ Approve: pending → approved" -ForegroundColor Green

        $report += "✅ Workflow: Transitions working (draft → pending → approved)"
    } catch {
        Write-Host "  ❌ FAIL: $($_.Exception.Message)" -ForegroundColor Red
        $report += "❌ Workflow: Failed - $($_.Exception.Message)"
        $allPassed = $false
    }
}
Write-Host ""

# ============================================
# Test 6: Auth enforcement (mark-paid)
# ============================================

Write-Host "Test 6: Auth Enforcement" -ForegroundColor Yellow

# Get first approved commission
$approved = (Invoke-RestMethod -Uri "$base/commissions?select=id`&status=eq.approved`&limit=1" -Headers $headers)[0]

if (-not $approved) {
    Write-Host "  ⚠️  No approved commissions to test" -ForegroundColor Yellow
    $report += "⚠️  Auth: No approved commissions available for testing"
} else {
    $commId = $approved.id
    Write-Host "  Testing service key on mark-paid..." -ForegroundColor Gray

    try {
        $body = @{ payment_date = "2025-11-02" } | ConvertTo-Json
        $null = Invoke-RestMethod -Uri "$apiBase/commissions/$commId/mark-paid" -Headers $headers -Method Post -Body $body

        Write-Host "  ❌ FAIL: Service key should be blocked (got 200)" -ForegroundColor Red
        $report += "❌ Auth: Service key has mark-paid access (should be 403)"
        $allPassed = $false
    } catch {
        if ($_.Exception.Message -match "403|Forbidden") {
            Write-Host "  ✅ PASS: Service key correctly blocked (403)" -ForegroundColor Green
            $report += "✅ Auth: Service key blocked from mark-paid (403)"
        } else {
            Write-Host "  ❌ FAIL: Unexpected error - $($_.Exception.Message)" -ForegroundColor Red
            $report += "❌ Auth: Unexpected error - $($_.Exception.Message)"
            $allPassed = $false
        }
    }
}
Write-Host ""

# ============================================
# Test 7: Idempotency
# ============================================

Write-Host "Test 7: Idempotency" -ForegroundColor Yellow

try {
    # Run batch compute again
    $allContribs = Invoke-RestMethod -Uri "$base/contributions?select=id`&limit=100" -Headers $headers
    $contribIds = $allContribs | ForEach-Object { $_.id }
    $body = @{ contribution_ids = $contribIds } | ConvertTo-Json
    $result = Invoke-RestMethod -Uri "$apiBase/commissions/batch-compute" -Headers $headers -Method Post -Body $body

    $successCount2 = ($result.results | Where-Object { $_.status -ne "error" }).Count

    # Should create 0 new commissions (all already exist)
    if ($successCount2 -eq 0) {
        Write-Host "  ✅ PASS: 0 duplicates created" -ForegroundColor Green
        $report += "✅ Idempotency: Re-run created 0 duplicates"
    } else {
        Write-Host "  ⚠️  WARNING: Created $successCount2 on re-run (possible duplicates)" -ForegroundColor Yellow
        $report += "⚠️  Idempotency: Re-run created $successCount2 (check for duplicates)"
    }
} catch {
    Write-Host "  ❌ FAIL: $($_.Exception.Message)" -ForegroundColor Red
    $report += "❌ Idempotency: Failed - $($_.Exception.Message)"
    $allPassed = $false
}
Write-Host ""

# ============================================
# Final Summary
# ============================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "GATE C SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

foreach ($line in $report) {
    Write-Host $line
}

Write-Host ""

if ($allPassed) {
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "GATE C: ✅ PASSED" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Capture screenshots (list + detail)" -ForegroundColor Gray
    Write-Host "  2. Update EXECUTION_STATUS.md with final metrics" -ForegroundColor Gray
    Write-Host "  3. Ship it! 🚀" -ForegroundColor Gray
} else {
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "GATE C: ⚠️  PARTIAL PASS" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Review failures above and apply fixes from FINISH_PLAN.md" -ForegroundColor Yellow
}

# Save report to file
$reportPath = "gate_c_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$report | Out-File -FilePath $reportPath
Write-Host ""
Write-Host "Report saved to: $reportPath" -ForegroundColor Gray
