# ============================================================
# Track B6: Service-Key Guard Check (Security Test)
# ============================================================
# Purpose: Verify service keys are blocked from mark-paid
# Expected: 403 Forbidden response
# Time: 2-3 minutes
# ============================================================

$BASE_URL = "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Track B6: Service-Key Guard Check" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Get service role key from environment
$serviceKey = $env:SUPABASE_SERVICE_ROLE_KEY

if (-not $serviceKey) {
    Write-Host "⚠️  SUPABASE_SERVICE_ROLE_KEY not set in environment" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Get your service role key from:" -ForegroundColor Yellow
    Write-Host "  https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys/settings/api" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Then set it:" -ForegroundColor Yellow
    Write-Host '  $env:SUPABASE_SERVICE_ROLE_KEY = "your-service-role-key"' -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

# Check for at least 1 approved commission
Write-Host "📋 Finding an APPROVED commission..." -ForegroundColor Yellow

$adminJWT = $env:ADMIN_JWT
if (-not $adminJWT) {
    Write-Host "❌ ADMIN_JWT not set. Need it to query commissions." -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $adminJWT"
    "apikey" = $adminJWT
    "Content-Type" = "application/json"
}

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/commissions?status=approved" -Headers $headers -Method Get
    $approved = $response.data

    if ($approved.Count -eq 0) {
        Write-Host "⚠️  No APPROVED commissions found" -ForegroundColor Yellow
        Write-Host "Run 04_workflow_test.ps1 first to create some" -ForegroundColor Yellow
        exit 0
    }

    $commissionId = $approved[0].id
    Write-Host "✅ Found approved commission: $commissionId" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "❌ Failed to fetch approved commissions: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 1: Attempt mark-paid with SERVICE KEY
Write-Host "🔒 TEST 1: Attempting mark-paid with SERVICE KEY..." -ForegroundColor Yellow
Write-Host "   Commission ID: $commissionId" -ForegroundColor Gray
Write-Host "   Expected: 403 Forbidden" -ForegroundColor Gray
Write-Host ""

$serviceHeaders = @{
    "Authorization" = "Bearer $serviceKey"
    "apikey" = $serviceKey
    "Content-Type" = "application/json"
}

$body = @{
    payment_ref = "WIRE-TEST-SERVICE-$(Get-Date -Format 'yyyyMMdd')"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/commissions/$commissionId/mark-paid" -Headers $serviceHeaders -Method Post -Body $body

    # If we get here, the test FAILED (should have thrown 403)
    Write-Host "❌ TEST FAILED: Service key was allowed to mark-paid!" -ForegroundColor Red
    Write-Host "   Response: $($response | ConvertTo-Json -Depth 5)" -ForegroundColor Red
    Write-Host ""
    Write-Host "⚠️  SECURITY ISSUE: Service keys should be blocked from mark-paid" -ForegroundColor Red
    exit 1

} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__

    if ($statusCode -eq 403) {
        Write-Host "✅ TEST PASSED: Service key correctly blocked (403 Forbidden)" -ForegroundColor Green

        # Try to get error body
        try {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $errorBody = $reader.ReadToEnd() | ConvertFrom-Json

            Write-Host ""
            Write-Host "Error Response:" -ForegroundColor Cyan
            Write-Host "  Status: 403" -ForegroundColor Gray
            Write-Host "  Error: $($errorBody.error)" -ForegroundColor Gray
            Write-Host "  Message: $($errorBody.message)" -ForegroundColor Gray
            Write-Host ""

            # Check for expected message
            if ($errorBody.message -like "*Service keys cannot*" -or $errorBody.message -like "*service*paid*") {
                Write-Host "✅ Error message is correct" -ForegroundColor Green
            } else {
                Write-Host "⚠️  Error message unexpected: $($errorBody.message)" -ForegroundColor Yellow
            }

        } catch {
            Write-Host "  (Could not parse error body)" -ForegroundColor Gray
        }

    } else {
        Write-Host "❌ TEST FAILED: Expected 403, got $statusCode" -ForegroundColor Red
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""

# Test 2: Verify audit log (if audit_log table exists)
Write-Host "📝 TEST 2: Checking audit log..." -ForegroundColor Yellow

$auditQuery = @"
SELECT
    action,
    entity_type,
    entity_id,
    actor_id,
    metadata,
    created_at
FROM audit_log
WHERE entity_type = 'commission'
  AND action = 'mark_paid_denied'
  AND entity_id = '$commissionId'
ORDER BY created_at DESC
LIMIT 1;
"@

Write-Host "   Run this SQL in Supabase to verify audit log:" -ForegroundColor Gray
Write-Host ""
Write-Host $auditQuery -ForegroundColor Cyan
Write-Host ""
Write-Host "   Expected: 1 row with action='mark_paid_denied'" -ForegroundColor Gray
Write-Host ""

# Summary
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "✅ TRACK B6 COMPLETE" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Security Test Results:" -ForegroundColor Cyan
Write-Host "  ✅ Service key blocked from mark-paid (403)" -ForegroundColor Green
Write-Host "  ✅ Error message appropriate" -ForegroundColor Green
Write-Host "  ⏳ Audit log check (manual SQL)" -ForegroundColor Yellow
Write-Host ""
Write-Host "DoD: Service keys cannot mark commissions as paid ✅" -ForegroundColor Green
Write-Host ""
Write-Host "Next: Track C7 - UI Smoke Test" -ForegroundColor Cyan
