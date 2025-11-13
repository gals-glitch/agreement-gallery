if (-not $env:SUPABASE_SERVICE_ROLE_KEY) {
    Write-Host "Run .\set_key.ps1 first" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $env:SUPABASE_SERVICE_ROLE_KEY"
    "apikey" = $env:SUPABASE_SERVICE_ROLE_KEY
}

$base = "https://qwgicrdcoqdketqhxbys.supabase.co/rest/v1"

Write-Host "DATA DIAGNOSTIC" -ForegroundColor Cyan
Write-Host ""

# Check investors with party links
Write-Host "1. Investors with party links:" -ForegroundColor Yellow
$url = "$base/investors?select=id,name,introduced_by_party_id&introduced_by_party_id=not.is.null&limit=5"
$investors = Invoke-RestMethod -Uri $url -Headers $headers
Write-Host "   Found: $($investors.Count)" -ForegroundColor Green
if ($investors.Count -gt 0) {
    $investors | ForEach-Object { Write-Host "   - $($_.name) -> Party $($_.introduced_by_party_id)" -ForegroundColor Gray }
}
Write-Host ""

# Check agreements
Write-Host "2. Approved agreements:" -ForegroundColor Yellow
$url = "$base/agreements?select=id,party_id,deal_id,fund_id,status&status=eq.APPROVED&limit=5"
$agreements = Invoke-RestMethod -Uri $url -Headers $headers
Write-Host "   Found: $($agreements.Count)" -ForegroundColor Green
if ($agreements.Count -gt 0) {
    $agreements | ForEach-Object { Write-Host "   - Agreement $($_.id): Party $($_.party_id), Deal $($_.deal_id), Fund $($_.fund_id)" -ForegroundColor Gray }
}
Write-Host ""

# Check contribution 115 specifically
Write-Host "3. Contribution 115 details:" -ForegroundColor Yellow
$url = "$base/contributions?select=id,investor_id,deal_id,fund_id,amount,investors(id,name,introduced_by_party_id)&id=eq.115"
$contrib = (Invoke-RestMethod -Uri $url -Headers $headers)[0]
Write-Host "   Investor: $($contrib.investors.name)" -ForegroundColor Gray
Write-Host "   Party ID: $($contrib.investors.introduced_by_party_id)" -ForegroundColor Gray
Write-Host "   Deal ID: $($contrib.deal_id)" -ForegroundColor Gray
Write-Host "   Fund ID: $($contrib.fund_id)" -ForegroundColor Gray
Write-Host ""

Write-Host "DIAGNOSIS:" -ForegroundColor Cyan
if ($investors.Count -eq 0) {
    Write-Host "  PROBLEM: No investors have party links set" -ForegroundColor Red
    Write-Host "  FIX: Need to set introduced_by_party_id on investors table" -ForegroundColor Yellow
} elseif ($agreements.Count -eq 0) {
    Write-Host "  PROBLEM: No approved agreements exist" -ForegroundColor Red
    Write-Host "  FIX: Need to create and approve agreements" -ForegroundColor Yellow
} else {
    Write-Host "  Data looks OK - 500 error is a bug in server code" -ForegroundColor Yellow
}
