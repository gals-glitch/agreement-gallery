# ========================================
# Simple Workflow Test - Service Key + Manual Admin Steps
# ========================================
# This test uses service key for submit, then shows you SQL to run for approve/mark-paid

# Configuration
$API_BASE = "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1"
$SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3Z2ljcmRjb3Fka2V0cWh4YnlzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcyODk1OTI0OCwiZXhwIjoyMDQ0NTM1MjQ4fQ.rlujT_xHCm2xtAR0rHQ2m0N4dYwjBvfCZKQKI3djjtI"

# Test charge
$CHARGE_ID = "a0fb4b54-5e29-437b-beaf-99e4f2bcc4bd"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Simple Workflow Test" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# ========================================
# Step 1: Submit with Service Key
# ========================================

Write-Host "[Step 1] Submitting charge (Service Key)..." -ForegroundColor Cyan

$headers = @{
    "Authorization" = "Bearer $SERVICE_KEY"
    "apikey" = "$SERVICE_KEY"
    "Content-Type" = "application/json"
}

try {
    $response = Invoke-RestMethod -Uri "$API_BASE/charges/$CHARGE_ID/submit" -Method POST -Headers $headers
    Write-Host "✅ Submit successful!" -ForegroundColor Green
    Write-Host "  Status: $($response.data.status)" -ForegroundColor Green
    Write-Host "  Credits Applied: `$$($response.data.credits_applied_amount)" -ForegroundColor Green
    Write-Host "  Net Amount: `$$($response.data.net_amount)" -ForegroundColor Green
} catch {
    Write-Host "❌ Submit failed!" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
    exit 1
}

# ========================================
# Step 2: Manual Approve via SQL
# ========================================

Write-Host "`n[Step 2] Approve charge (Manual SQL)..." -ForegroundColor Cyan
Write-Host "  Service key cannot approve (requires admin)" -ForegroundColor Yellow
Write-Host "`n  Run this SQL in Supabase SQL Editor:" -ForegroundColor Yellow
Write-Host "  ----------------------------------------" -ForegroundColor Gray

$approveSql = @"
-- Approve charge (simulates admin user)
UPDATE charges
SET
  status = 'APPROVED',
  approved_at = now(),
  approved_by = (SELECT id FROM auth.users WHERE email = 'gals@buligocapital.com')
WHERE id = '$CHARGE_ID'
  AND status = 'PENDING'
RETURNING id, status, approved_at;
"@

Write-Host $approveSql -ForegroundColor Gray

Write-Host "`n  Press Enter after running the SQL..." -ForegroundColor Yellow
$null = Read-Host

# ========================================
# Step 3: Manual Mark Paid via SQL
# ========================================

Write-Host "`n[Step 3] Mark charge as paid (Manual SQL)..." -ForegroundColor Cyan
Write-Host "  Run this SQL in Supabase SQL Editor:" -ForegroundColor Yellow
Write-Host "  ----------------------------------------" -ForegroundColor Gray

$markPaidSql = @"
-- Mark charge as paid
UPDATE charges
SET
  status = 'PAID',
  paid_at = now(),
  payment_ref = 'WIRE-DEMO-001'
WHERE id = '$CHARGE_ID'
  AND status = 'APPROVED'
RETURNING id, status, paid_at, payment_ref;
"@

Write-Host $markPaidSql -ForegroundColor Gray

Write-Host "`n  Press Enter after running the SQL..." -ForegroundColor Yellow
$null = Read-Host

# ========================================
# Step 4: Verify Final State
# ========================================

Write-Host "`n[Step 4] Verifying final state..." -ForegroundColor Cyan

try {
    $response = Invoke-RestMethod -Uri "$API_BASE/charges/$CHARGE_ID" -Method GET -Headers $headers
    $charge = $response.data

    Write-Host "`n✅ WORKFLOW COMPLETE!" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Cyan

    Write-Host "Final State:" -ForegroundColor Cyan
    Write-Host "  Charge ID: $($charge.id)" -ForegroundColor White
    Write-Host "  Status: $($charge.status)" -ForegroundColor Green
    Write-Host "  Total: `$$($charge.total_amount)" -ForegroundColor White
    Write-Host "  Credits Applied: `$$($charge.credits_applied_amount)" -ForegroundColor Green
    Write-Host "  Net Amount: `$$($charge.net_amount)" -ForegroundColor White
    Write-Host "  Payment Ref: $($charge.payment_ref)" -ForegroundColor White

    if ($charge.status -eq "PAID") {
        Write-Host "`n🎉 SUCCESS - Charge is PAID!" -ForegroundColor Green
    } else {
        Write-Host "`n⚠️  WARNING - Charge is not PAID (status: $($charge.status))" -ForegroundColor Yellow
    }

} catch {
    Write-Host "❌ Verification failed!" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n========================================`n" -ForegroundColor Cyan
