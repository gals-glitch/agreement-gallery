if (-not $env:SUPABASE_SERVICE_ROLE_KEY) {
    Write-Host "Run .\set_key.ps1 first" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $env:SUPABASE_SERVICE_ROLE_KEY"
    "apikey" = $env:SUPABASE_SERVICE_ROLE_KEY
    "Content-Type" = "application/json"
}

$base = "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1"
$commissionId = "17c9d2a1-be68-410d-8786-7fca386d218d"

Write-Host "COMMISSION WORKFLOW TEST" -ForegroundColor Cyan
Write-Host "Testing commission: $commissionId" -ForegroundColor Gray
Write-Host ""

# Step 1: Submit (draft -> pending)
Write-Host "Step 1: Submit (draft -> pending)" -ForegroundColor Yellow
try {
    $result = Invoke-RestMethod -Uri "$base/commissions/$commissionId/submit" -Headers $headers -Method Post
    Write-Host "  SUCCESS - Status: $($result.status)" -ForegroundColor Green
} catch {
    Write-Host "  FAILED: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
Write-Host ""

Start-Sleep -Seconds 1

# Step 2: Approve (pending -> approved)
Write-Host "Step 2: Approve (pending -> approved)" -ForegroundColor Yellow
try {
    $result = Invoke-RestMethod -Uri "$base/commissions/$commissionId/approve" -Headers $headers -Method Post
    Write-Host "  SUCCESS - Status: $($result.status)" -ForegroundColor Green
} catch {
    Write-Host "  FAILED: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
Write-Host ""

Start-Sleep -Seconds 1

# Step 3: Mark as Paid (approved -> paid)
Write-Host "Step 3: Mark as Paid (approved -> paid)" -ForegroundColor Yellow
try {
    $body = @{ payment_date = "2025-11-02" } | ConvertTo-Json
    $result = Invoke-RestMethod -Uri "$base/commissions/$commissionId/mark-paid" -Headers $headers -Method Post -Body $body
    Write-Host "  SUCCESS - Status: $($result.status)" -ForegroundColor Green
} catch {
    Write-Host "  FAILED: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Note: mark-paid might require admin user auth, not service key" -ForegroundColor Yellow
}
Write-Host ""

# Verify final state
Write-Host "Final verification:" -ForegroundColor Cyan
$restBase = "https://qwgicrdcoqdketqhxbys.supabase.co/rest/v1"
$restUrl = "$restBase/commissions?select=id,status,party_id,investor_id,base_amount,total_amount,parties(name),investors(name)&id=eq.$commissionId"
$final = (Invoke-RestMethod -Uri $restUrl -Headers $headers)[0]
Write-Host "  Commission ID: $($final.id)" -ForegroundColor Gray
Write-Host "  Status: $($final.status)" -ForegroundColor Cyan
Write-Host "  Investor: $($final.investors.name)" -ForegroundColor Gray
Write-Host "  Party: $($final.parties.name)" -ForegroundColor Gray
Write-Host "  Amount: $($final.total_amount)" -ForegroundColor Gray

Write-Host ""
Write-Host "WORKFLOW TEST COMPLETE!" -ForegroundColor Green
