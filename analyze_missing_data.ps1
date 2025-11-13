if (-not $env:SUPABASE_SERVICE_ROLE_KEY) {
    Write-Host "Run .\set_key.ps1 first" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $env:SUPABASE_SERVICE_ROLE_KEY"
    "apikey" = $env:SUPABASE_SERVICE_ROLE_KEY
}

$base = "https://qwgicrdcoqdketqhxbys.supabase.co/rest/v1"

Write-Host "MISSING DATA ANALYSIS" -ForegroundColor Cyan
Write-Host ""

# Get all investors with their party status
Write-Host "1. Investors without party links:" -ForegroundColor Yellow
$url = "$base/investors?select=id,name,introduced_by_party_id&introduced_by_party_id=is.null&order=name"
$noParty = Invoke-RestMethod -Uri $url -Headers $headers
Write-Host "   Total: $($noParty.Count) investors" -ForegroundColor Red
if ($noParty.Count -gt 0 -and $noParty.Count -le 10) {
    $noParty | ForEach-Object { Write-Host "   - $($_.name) (ID: $($_.id))" -ForegroundColor Gray }
} elseif ($noParty.Count -gt 10) {
    $noParty[0..9] | ForEach-Object { Write-Host "   - $($_.name) (ID: $($_.id))" -ForegroundColor Gray }
    Write-Host "   ... and $($noParty.Count - 10) more" -ForegroundColor Gray
}
Write-Host ""

# Get investors WITH party links
Write-Host "2. Investors WITH party links:" -ForegroundColor Yellow
$url = "$base/investors?select=id,name,introduced_by_party_id&introduced_by_party_id=not.is.null&order=name"
$withParty = Invoke-RestMethod -Uri $url -Headers $headers
Write-Host "   Total: $($withParty.Count) investors" -ForegroundColor Green
$withParty | ForEach-Object {
    Write-Host "   - $($_.name) -> Party $($_.introduced_by_party_id)" -ForegroundColor Gray
}
Write-Host ""

# Get approved agreements count
Write-Host "3. Approved agreements:" -ForegroundColor Yellow
$url = "$base/agreements?select=id&status=eq.APPROVED"
$agreements = Invoke-RestMethod -Uri $url -Headers $headers
Write-Host "   Total: $($agreements.Count) agreements" -ForegroundColor Green
Write-Host ""

Write-Host "RECOMMENDATIONS:" -ForegroundColor Cyan
Write-Host "  1. Set introduced_by_party_id for $($noParty.Count) investors without party links" -ForegroundColor Yellow
Write-Host "  2. Create missing agreements for investors who have party links but no deal coverage" -ForegroundColor Yellow
