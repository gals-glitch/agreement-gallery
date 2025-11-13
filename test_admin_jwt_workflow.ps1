# ========================================
# Move 1.4: Full Workflow Test with Admin JWT
# ========================================
# Tests: Submit → Approve → Mark Paid with Admin JWT (NOT service key)
# Date: 2025-10-21

# ========================================
# Configuration
# ========================================

$API_BASE = "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1"
$ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3Z2ljcmRjb3Fka2V0cWh4YnlzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcyMjYzMDcsImV4cCI6MjA3MjgwMjMwN30.6PZnjAcRXYcd_sNZHb6ZDxyg914JMtkCtqIYvHt3P1Y"

# IMPORTANT: Get these from Supabase Auth
# 1. Log into your app at http://localhost:8081
# 2. Open browser DevTools → Application → Local Storage
# 3. Find: sb-qwgicrdcoqdketqhxbys-auth-token
# 4. Copy the "access_token" value (this is your JWT)

$ADMIN_JWT = "eyJhbGciOiJIUzI1NiIsImtpZCI6IjhUL3RGUnFNYmRwWjY4WFkiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL3F3Z2ljcmRjb3Fka2V0cWh4YnlzLnN1cGFiYXNlLmNvL2F1dGgvdjEiLCJzdWIiOiJmYWJiMWUyMS02OTFlLTQwMDUtOGE5ZC02NmZjMzgxMDExYTIiLCJhdWQiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjoxNzYxMDUxMzE3LCJpYXQiOjE3NjEwNDc3MTcsImVtYWlsIjoiZ2Fsc0BidWxpZ29jYXBpdGFsLmNvbSIsInBob25lIjoiIiwiYXBwX21ldGFkYXRhIjp7InByb3ZpZGVyIjoiZW1haWwiLCJwcm92aWRlcnMiOlsiZW1haWwiXX0sInVzZXJfbWV0YWRhdGEiOnsiZW1haWxfdmVyaWZpZWQiOnRydWV9LCJyb2xlIjoiYXV0aGVudGljYXRlZCIsImFhbCI6ImFhbDEiLCJhbXIiOlt7Im1ldGhvZCI6InBhc3N3b3JkIiwidGltZXN0YW1wIjoxNzYwOTQyODkyfV0sInNlc3Npb25faWQiOiJhYzk5NzNkMy04N2Q3LTQwODEtODQxNi0yMzU1MzRjNDk4YmIiLCJpc19hbm9ueW1vdXMiOmZhbHNlfQ.pDqVtBR_0B3XAYlygyQzYO2j3DQ4yaR4DKzb-LiUCHE"
$FINANCE_JWT = "YOUR_FINANCE_JWT_HERE"  # Optional: test Finance user submit

# Test data (from existing test setup)
$CHARGE_ID = "a0fb4b54-5e29-437b-beaf-99e4f2bcc4bd"  # Replace with your charge UUID

# ========================================
# Helper Functions
# ========================================

function Invoke-ApiRequest {
    param(
        [string]$Method,
        [string]$Endpoint,
        [string]$JWT,
        [object]$Body = $null
    )

    $headers = @{
        "Authorization" = "Bearer $JWT"
        "apikey" = $ANON_KEY
        "Content-Type" = "application/json"
    }

    $uri = "$API_BASE$Endpoint"

    try {
        if ($Body) {
            $bodyJson = $Body | ConvertTo-Json -Depth 10
            $response = Invoke-RestMethod -Uri $uri -Method $Method -Headers $headers -Body $bodyJson
        } else {
            $response = Invoke-RestMethod -Uri $uri -Method $Method -Headers $headers
        }
        return @{ Success = $true; Data = $response }
    } catch {
        $errorBody = $_.ErrorDetails.Message
        return @{ Success = $false; Error = $errorBody; StatusCode = $_.Exception.Response.StatusCode.value__ }
    }
}

# ========================================
# Pre-Flight Checks
# ========================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Move 1.4: Admin JWT Workflow Test" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Check if JWTs are set
if ($ADMIN_JWT -eq "YOUR_ADMIN_JWT_HERE") {
    Write-Host "❌ ERROR: ADMIN_JWT not set!" -ForegroundColor Red
    Write-Host "`nTo get your JWT:" -ForegroundColor Yellow
    Write-Host "1. Log into http://localhost:8081" -ForegroundColor Yellow
    Write-Host "2. Open DevTools → Application → Local Storage" -ForegroundColor Yellow
    Write-Host "3. Find: sb-qwgicrdcoqdketqhxbys-auth-token" -ForegroundColor Yellow
    Write-Host "4. Copy the 'access_token' value" -ForegroundColor Yellow
    Write-Host "5. Paste it into this script as `$ADMIN_JWT`n" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ Admin JWT configured" -ForegroundColor Green
Write-Host "✓ Charge ID: $CHARGE_ID" -ForegroundColor Green
Write-Host ""

# ========================================
# Step 1: Submit Charge (Finance or Admin)
# ========================================

Write-Host "`n[Step 1] Submitting charge..." -ForegroundColor Cyan
Write-Host "  Using: Admin JWT (Finance JWT also allowed)" -ForegroundColor Gray
Write-Host "  Expected: DRAFT → PENDING, credits auto-applied`n" -ForegroundColor Gray

$submitResult = Invoke-ApiRequest -Method "POST" -Endpoint "/charges/$CHARGE_ID/submit" -JWT $ADMIN_JWT

if ($submitResult.Success) {
    Write-Host "✅ Submit successful!" -ForegroundColor Green
    Write-Host "  Status: $($submitResult.Data.data.status)" -ForegroundColor Green
    Write-Host "  Credits Applied: `$$($submitResult.Data.data.credits_applied_amount)" -ForegroundColor Green
    Write-Host "  Net Amount: `$$($submitResult.Data.data.net_amount)" -ForegroundColor Green
} else {
    Write-Host "❌ Submit failed!" -ForegroundColor Red
    Write-Host "  Status Code: $($submitResult.StatusCode)" -ForegroundColor Red
    Write-Host "  Error: $($submitResult.Error)" -ForegroundColor Red

    if ($submitResult.StatusCode -eq 403) {
        Write-Host "`n  Possible causes:" -ForegroundColor Yellow
        Write-Host "  - User does not have 'finance' or 'admin' role" -ForegroundColor Yellow
        Write-Host "  - JWT is expired (get a fresh one from browser)" -ForegroundColor Yellow
    }
    exit 1
}

Start-Sleep -Seconds 1

# ========================================
# Step 2: Approve Charge (Admin only)
# ========================================

Write-Host "`n[Step 2] Approving charge..." -ForegroundColor Cyan
Write-Host "  Using: Admin JWT (REQUIRED - Finance cannot approve)" -ForegroundColor Gray
Write-Host "  Expected: PENDING → APPROVED`n" -ForegroundColor Gray

$approveResult = Invoke-ApiRequest -Method "POST" -Endpoint "/charges/$CHARGE_ID/approve" -JWT $ADMIN_JWT

if ($approveResult.Success) {
    Write-Host "✅ Approve successful!" -ForegroundColor Green
    Write-Host "  Status: $($approveResult.Data.data.status)" -ForegroundColor Green
    Write-Host "  Approved At: $($approveResult.Data.data.approved_at)" -ForegroundColor Green
    Write-Host "  Approved By: $($approveResult.Data.data.approved_by)" -ForegroundColor Green
} else {
    Write-Host "❌ Approve failed!" -ForegroundColor Red
    Write-Host "  Status Code: $($approveResult.StatusCode)" -ForegroundColor Red
    Write-Host "  Error: $($approveResult.Error)" -ForegroundColor Red

    if ($approveResult.StatusCode -eq 403) {
        Write-Host "`n  Possible causes:" -ForegroundColor Yellow
        Write-Host "  - User does not have 'admin' role (Finance cannot approve)" -ForegroundColor Yellow
        Write-Host "  - JWT is expired (get a fresh one from browser)" -ForegroundColor Yellow
    }
    exit 1
}

Start-Sleep -Seconds 1

# ========================================
# Step 3: Mark Paid (Admin only, NO service key)
# ========================================

Write-Host "`n[Step 3] Marking charge as paid..." -ForegroundColor Cyan
Write-Host "  Using: Admin JWT (REQUIRED - service key intentionally blocked)" -ForegroundColor Gray
Write-Host "  Expected: APPROVED → PAID`n" -ForegroundColor Gray

$markPaidBody = @{
    payment_ref = "WIRE-DEMO-001"
}

$markPaidResult = Invoke-ApiRequest -Method "POST" -Endpoint "/charges/$CHARGE_ID/mark-paid" -JWT $ADMIN_JWT -Body $markPaidBody

if ($markPaidResult.Success) {
    Write-Host "✅ Mark Paid successful!" -ForegroundColor Green
    Write-Host "  Status: $($markPaidResult.Data.data.status)" -ForegroundColor Green
    Write-Host "  Paid At: $($markPaidResult.Data.data.paid_at)" -ForegroundColor Green
    Write-Host "  Payment Ref: $($markPaidResult.Data.data.payment_ref)" -ForegroundColor Green
} else {
    Write-Host "❌ Mark Paid failed!" -ForegroundColor Red
    Write-Host "  Status Code: $($markPaidResult.StatusCode)" -ForegroundColor Red
    Write-Host "  Error: $($markPaidResult.Error)" -ForegroundColor Red

    if ($markPaidResult.StatusCode -eq 403) {
        Write-Host "`n  Possible causes:" -ForegroundColor Yellow
        Write-Host "  - User does not have 'admin' role" -ForegroundColor Yellow
        Write-Host "  - JWT is expired (get a fresh one from browser)" -ForegroundColor Yellow
        Write-Host "  - Service key was used (intentionally blocked for mark-paid)" -ForegroundColor Yellow
    }
    exit 1
}

# ========================================
# Summary
# ========================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "✅ WORKFLOW COMPLETE!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Final State:" -ForegroundColor Cyan
Write-Host "  Status: PAID" -ForegroundColor Green
Write-Host "  Credits Applied: Auto-applied via FIFO" -ForegroundColor Green
Write-Host "  Payment Ref: WIRE-DEMO-001" -ForegroundColor Green

Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "  1. Run VERIFY_CHARGE_STATE.sql to confirm database state" -ForegroundColor Yellow
Write-Host "  2. Check credit applications table for applied credits" -ForegroundColor Yellow
Write-Host "  3. Verify audit_log entries for all workflow steps`n" -ForegroundColor Yellow
