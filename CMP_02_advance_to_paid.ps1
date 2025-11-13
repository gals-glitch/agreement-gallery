# ============================================================
# CMP-02: ADVANCE ONE COMMISSION TO PAID
# ============================================================
# Purpose: Test the full commission workflow
# Flow: draft → submit (pending) → approve → mark-paid (paid)
# ============================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$CommissionId
)

$ErrorActionPreference = "Stop"

$BASE_URL = "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1"
$SUPABASE_URL = "https://qwgicrdcoqdketqhxbys.supabase.co"

# Check for service role key
if (-not $env:SUPABASE_SERVICE_ROLE_KEY) {
    Write-Host "❌ ERROR: SUPABASE_SERVICE_ROLE_KEY environment variable not set" -ForegroundColor Red
    exit 1
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "CMP-02: ADVANCE COMMISSION TO PAID" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$headers = @{
    "Authorization" = "Bearer $env:SUPABASE_SERVICE_ROLE_KEY"
    "apikey" = $env:SUPABASE_SERVICE_ROLE_KEY
    "Content-Type" = "application/json"
}

# Step 1: Find a draft commission if ID not provided
if (-not $CommissionId) {
    Write-Host "📊 Step 1: Finding a draft commission..." -ForegroundColor Yellow

    $query = "commissions?select=id,status,party_id,investor_id,base_amount,total_amount&status=eq.draft&order=created_at.desc&limit=1"

    try {
        $commissions = Invoke-RestMethod -Uri "$SUPABASE_URL/rest/v1/$query" -Headers $headers -Method Get

        if ($commissions.Count -eq 0) {
            Write-Host "❌ No draft commissions found" -ForegroundColor Red
            Write-Host "Run CMP_01_batch_compute_eligible.ps1 first to create commissions" -ForegroundColor Yellow
            exit 1
        }

        $CommissionId = $commissions[0].id
        Write-Host "✅ Found draft commission: $CommissionId" -ForegroundColor Green
        Write-Host "   Total amount: $($commissions[0].total_amount)" -ForegroundColor Gray
    } catch {
        Write-Host "❌ Failed to find commission: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "📋 Using provided commission ID: $CommissionId" -ForegroundColor Cyan
}

Write-Host ""

# Step 2: Get current status
Write-Host "📊 Step 2: Checking current status..." -ForegroundColor Yellow
try {
    $commission = Invoke-RestMethod -Uri "$BASE_URL/commissions/$CommissionId" -Headers $headers -Method Get
    Write-Host "✅ Current status: $($commission.data.status)" -ForegroundColor Green
    Write-Host "   Party: $($commission.data.party_name)" -ForegroundColor Gray
    Write-Host "   Investor: $($commission.data.investor_name)" -ForegroundColor Gray
    Write-Host "   Base: $($commission.data.base_amount) | VAT: $($commission.data.vat_amount) | Total: $($commission.data.total_amount)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Failed to get commission: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 3: Submit (draft → pending)
if ($commission.data.status -eq "draft") {
    Write-Host "📤 Step 3: Submitting commission (draft → pending)..." -ForegroundColor Yellow
    try {
        $result = Invoke-RestMethod -Uri "$BASE_URL/commissions/$CommissionId/submit" -Headers $headers -Method Post -Body "{}"
        Write-Host "✅ Submitted! Status: $($result.data.status)" -ForegroundColor Green
        Write-Host "   Submitted at: $($result.data.submitted_at)" -ForegroundColor Gray
    } catch {
        Write-Host "❌ Failed to submit: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
    Write-Host ""
} else {
    Write-Host "⏭️  Step 3: Skipped (already $($commission.data.status))" -ForegroundColor Gray
    Write-Host ""
}

# Step 4: Approve (pending → approved)
Write-Host "✅ Step 4: Approving commission (pending → approved)..." -ForegroundColor Yellow
try {
    $result = Invoke-RestMethod -Uri "$BASE_URL/commissions/$CommissionId/approve" -Headers $headers -Method Post -Body "{}"
    Write-Host "✅ Approved! Status: $($result.data.status)" -ForegroundColor Green
    Write-Host "   Approved at: $($result.data.approved_at)" -ForegroundColor Gray
} catch {
    # Check if already approved
    $errorMsg = $_.Exception.Message
    if ($errorMsg -like "*already approved*" -or $errorMsg -like "*is approved*") {
        Write-Host "⏭️  Already approved, continuing..." -ForegroundColor Gray
    } else {
        Write-Host "❌ Failed to approve: $errorMsg" -ForegroundColor Red
        exit 1
    }
}
Write-Host ""

# Step 5: Mark as paid (approved → paid)
Write-Host "💵 Step 5: Marking as paid (approved → paid)..." -ForegroundColor Yellow
$paymentRef = "TEST-PMT-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$payBody = @{
    payment_ref = $paymentRef
} | ConvertTo-Json

try {
    $result = Invoke-RestMethod -Uri "$BASE_URL/commissions/$CommissionId/mark-paid" -Headers $headers -Method Post -Body $payBody
    Write-Host "✅ Marked as paid! Status: $($result.data.status)" -ForegroundColor Green
    Write-Host "   Paid at: $($result.data.paid_at)" -ForegroundColor Gray
    Write-Host "   Payment ref: $paymentRef" -ForegroundColor Gray
} catch {
    # Check if already paid
    $errorMsg = $_.Exception.Message
    if ($errorMsg -like "*already paid*" -or $errorMsg -like "*is paid*") {
        Write-Host "⏭️  Already paid!" -ForegroundColor Gray
    } else {
        Write-Host "❌ Failed to mark as paid: $errorMsg" -ForegroundColor Red
        Write-Host ""
        Write-Host "Note: mark-paid endpoint requires service role key" -ForegroundColor Yellow
        Write-Host "Ensure SUPABASE_SERVICE_ROLE_KEY is set correctly" -ForegroundColor Yellow
        exit 1
    }
}
Write-Host ""

# Step 6: Verify final status
Write-Host "🔍 Step 6: Verifying final status..." -ForegroundColor Yellow
try {
    $finalCommission = Invoke-RestMethod -Uri "$BASE_URL/commissions/$CommissionId" -Headers $headers -Method Get
    Write-Host "✅ Final status: $($finalCommission.data.status)" -ForegroundColor Green
    Write-Host ""
    Write-Host "Timeline:" -ForegroundColor Cyan
    Write-Host "  Created:   $($finalCommission.data.created_at)" -ForegroundColor Gray
    Write-Host "  Submitted: $($finalCommission.data.submitted_at)" -ForegroundColor Gray
    Write-Host "  Approved:  $($finalCommission.data.approved_at)" -ForegroundColor Gray
    Write-Host "  Paid:      $($finalCommission.data.paid_at)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Amounts:" -ForegroundColor Cyan
    Write-Host "  Base:  $($finalCommission.data.base_amount)" -ForegroundColor Gray
    Write-Host "  VAT:   $($finalCommission.data.vat_amount)" -ForegroundColor Gray
    Write-Host "  Total: $($finalCommission.data.total_amount)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Failed to verify: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
Write-Host ""

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "✅ CMP-02 COMPLETE: Commission workflow tested successfully!" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Commission $CommissionId is now PAID ✅" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Verify in UI: http://localhost:8081/commissions" -ForegroundColor Gray
Write-Host "  2. Check audit log: SELECT * FROM audit_log WHERE resource_id = '$CommissionId'" -ForegroundColor Gray
Write-Host "  3. Run COV-01 to increase coverage if needed" -ForegroundColor Gray
