if (-not $env:SUPABASE_SERVICE_ROLE_KEY) {
    Write-Host "Run .\set_key.ps1 first" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $env:SUPABASE_SERVICE_ROLE_KEY"
    "apikey" = $env:SUPABASE_SERVICE_ROLE_KEY
}

$base = "https://qwgicrdcoqdketqhxbys.supabase.co/rest/v1"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DB-01 VERIFICATION REPORT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if column exists
Write-Host "1. Checking if introduced_by_party_id column exists..." -ForegroundColor Yellow
$url = "$base/investors?select=id,name,introduced_by_party_id&limit=1"
try {
    $test = Invoke-RestMethod -Uri $url -Headers $headers
    Write-Host "   ✅ Column exists" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Column NOT found - migration may not have been applied" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Count investors WITH party links
Write-Host "2. Investors WITH party links:" -ForegroundColor Yellow
$url = "$base/investors?select=id&introduced_by_party_id=not.is.null"
$withParty = Invoke-RestMethod -Uri $url -Headers $headers
$withPartyCount = $withParty.Count
Write-Host "   Count: $withPartyCount" -ForegroundColor Green
Write-Host ""

# Count investors WITHOUT party links
Write-Host "3. Investors WITHOUT party links:" -ForegroundColor Yellow
$url = "$base/investors?select=id&introduced_by_party_id=is.null"
$noParty = Invoke-RestMethod -Uri $url -Headers $headers
$noPartyCount = $noParty.Count
Write-Host "   Count: $noPartyCount" -ForegroundColor $(if ($noPartyCount -le 15) { "Green" } else { "Yellow" })
Write-Host ""

# Total investors
$totalInvestors = $withPartyCount + $noPartyCount
$coveragePercent = [math]::Round(($withPartyCount / $totalInvestors) * 100, 1)

Write-Host "4. Coverage summary:" -ForegroundColor Yellow
Write-Host "   Total investors: $totalInvestors" -ForegroundColor Gray
Write-Host "   With party links: $withPartyCount ($coveragePercent%)" -ForegroundColor $(if ($coveragePercent -ge 80) { "Green" } elseif ($coveragePercent -ge 50) { "Yellow" } else { "Red" })
Write-Host "   Without party links: $noPartyCount" -ForegroundColor Gray
Write-Host ""

# Show sample of investors WITH links
Write-Host "5. Sample investors WITH party links (first 5):" -ForegroundColor Yellow
$url = "$base/investors?select=id,name,introduced_by_party_id&introduced_by_party_id=not.is.null&limit=5"
$samples = Invoke-RestMethod -Uri $url -Headers $headers
foreach ($inv in $samples) {
    Write-Host "   - $($inv.name) -> Party $($inv.introduced_by_party_id)" -ForegroundColor Gray
}
Write-Host ""

# Show sample of investors WITHOUT links (potential backfill candidates)
Write-Host "6. Sample investors WITHOUT party links (first 5):" -ForegroundColor Yellow
$url = "$base/investors?select=id,name,notes&introduced_by_party_id=is.null&limit=5"
$noLinkSamples = Invoke-RestMethod -Uri $url -Headers $headers
foreach ($inv in $noLinkSamples) {
    $notesPreview = if ($inv.notes) { $inv.notes.Substring(0, [Math]::Min(50, $inv.notes.Length)) + "..." } else { "(no notes)" }
    Write-Host "   - $($inv.name): $notesPreview" -ForegroundColor Gray
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "GATE A CRITERIA" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Check Gate A success criteria
$gateAPass = $true

# Criteria 1: ≥15 investors with party links (was 14)
Write-Host "Criteria 1: ≥15 investors with party links" -ForegroundColor Yellow
if ($withPartyCount -ge 15) {
    Write-Host "   ✅ PASS ($withPartyCount investors)" -ForegroundColor Green
} else {
    Write-Host "   ❌ FAIL ($withPartyCount investors, need 15)" -ForegroundColor Red
    $gateAPass = $false
}

# Criteria 2: ≤15 investors without party links (was 27)
Write-Host "Criteria 2: ≤15 investors without party links" -ForegroundColor Yellow
if ($noPartyCount -le 15) {
    Write-Host "   ✅ PASS ($noPartyCount investors)" -ForegroundColor Green
} else {
    Write-Host "   ❌ FAIL ($noPartyCount investors, target ≤15)" -ForegroundColor Yellow
    Write-Host "   Note: This is acceptable if coverage ≥80%" -ForegroundColor Gray
}

# Criteria 3: ≥80% coverage
Write-Host "Criteria 3: ≥80% coverage" -ForegroundColor Yellow
if ($coveragePercent -ge 80) {
    Write-Host "   ✅ PASS ($coveragePercent%)" -ForegroundColor Green
} else {
    Write-Host "   ❌ FAIL ($coveragePercent%, need ≥80%)" -ForegroundColor Red
    $gateAPass = $false
}

Write-Host ""
if ($gateAPass) {
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "GATE A: ✅ PASSED" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Run: .\CMP_01_simple.ps1 to test batch compute" -ForegroundColor Gray
    Write-Host "  2. Proceed to IMP-01 (Import service)" -ForegroundColor Gray
} else {
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "GATE A: ⚠️  PARTIAL PASS" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Recommendations:" -ForegroundColor Cyan
    Write-Host "  1. Review investors without party links above" -ForegroundColor Gray
    Write-Host "  2. Add entries to party_aliases table for fuzzy matching" -ForegroundColor Gray
    Write-Host "  3. Re-run migration backfill section manually" -ForegroundColor Gray
    Write-Host "  4. Or proceed with manual data entry for remaining investors" -ForegroundColor Gray
}
