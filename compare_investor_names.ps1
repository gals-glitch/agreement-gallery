# ============================================================================
# Compare Investor Names Between Two Sources
# ============================================================================
# SOURCE 1: Party - Deal Mapping.csv (agreement terms)
# SOURCE 2: 02_investors_filled.csv (already imported to database)
# ============================================================================

Write-Host "=== Comparing Investor Names ===" -ForegroundColor Cyan

# Load Party - Deal Mapping (source 1)
$mappingPath = "C:\Users\GalSamionov\OneDrive - Buligo Capital\Desktop\Party - Deal Mapping.csv"
$mapping = Import-Csv $mappingPath

# Load 02_investors_filled.csv (source 2)
$investorsPath = "C:\Users\GalSamionov\Downloads\02_investors_filled.csv"
$investors = Import-Csv $investorsPath

# Extract unique investor names from each source
$mappingInvestors = @{}
foreach ($row in $mapping) {
    $name = $row.'Investor Name'
    if ($name) {
        $mappingInvestors[$name.Trim()] = $true
    }
}

$importedInvestors = @{}
foreach ($row in $investors) {
    $name = $row.'investor_name'
    if ($name) {
        $importedInvestors[$name.Trim()] = $true
    }
}

Write-Host ""
Write-Host "Mapping CSV investors: $($mappingInvestors.Count)" -ForegroundColor Yellow
Write-Host "Imported DB investors: $($importedInvestors.Count)" -ForegroundColor Yellow

# Find overlaps and differences
$inBothSources = @()
$onlyInMapping = @()
$onlyInImported = @()

foreach ($name in $mappingInvestors.Keys) {
    if ($importedInvestors.ContainsKey($name)) {
        $inBothSources += $name
    } else {
        $onlyInMapping += $name
    }
}

foreach ($name in $importedInvestors.Keys) {
    if (-not $mappingInvestors.ContainsKey($name)) {
        $onlyInImported += $name
    }
}

Write-Host ""
Write-Host "=== Analysis ===" -ForegroundColor Cyan
Write-Host "In BOTH sources: $($inBothSources.Count)" -ForegroundColor Green
Write-Host "Only in Mapping CSV: $($onlyInMapping.Count)" -ForegroundColor Red
Write-Host "Only in Imported DB: $($onlyInImported.Count)" -ForegroundColor Red

# Generate report
$reportPath = "C:\Users\GalSamionov\Buligo Capital\Buligo Capital - Shared Documents\Information Systems\Gal\agreement-gallery-main\investor_name_comparison.txt"

$report = @()
$report += "=" * 80
$report += "INVESTOR NAME COMPARISON"
$report += "=" * 80
$report += ""
$report += "SUMMARY:"
$report += "  Mapping CSV investors: $($mappingInvestors.Count)"
$report += "  Imported DB investors: $($importedInvestors.Count)"
$report += "  In BOTH sources: $($inBothSources.Count)"
$report += "  Only in Mapping CSV: $($onlyInMapping.Count)"
$report += "  Only in Imported DB: $($onlyInImported.Count)"
$report += ""
$report += "=" * 80
$report += "INVESTORS IN BOTH SOURCES ($($inBothSources.Count)):"
$report += "=" * 80
foreach ($name in ($inBothSources | Sort-Object)) {
    $report += "  - $name"
}

$report += ""
$report += "=" * 80
$report += "ONLY IN MAPPING CSV ($($onlyInMapping.Count)):"
$report += "=" * 80
$report += "(These have agreement terms but are NOT in the database)"
$report += ""
foreach ($name in ($onlyInMapping | Sort-Object | Select-Object -First 50)) {
    $report += "  - $name"
}
if ($onlyInMapping.Count -gt 50) {
    $report += "  ... and $($onlyInMapping.Count - 50) more"
}

$report += ""
$report += "=" * 80
$report += "ONLY IN IMPORTED DB ($($onlyInImported.Count)):"
$report += "=" * 80
$report += "(These are in database but have NO agreement terms)"
$report += ""
foreach ($name in ($onlyInImported | Sort-Object | Select-Object -First 50)) {
    $report += "  - $name"
}
if ($onlyInImported.Count -gt 50) {
    $report += "  ... and $($onlyInImported.Count - 50) more"
}

$report | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host ""
Write-Host "Full report saved to: $reportPath" -ForegroundColor Green
Write-Host ""
Write-Host "Sample investors in BOTH sources:" -ForegroundColor Cyan
foreach ($name in ($inBothSources | Sort-Object | Select-Object -First 10)) {
    Write-Host "  [YES] $name" -ForegroundColor Green
}

Write-Host ""
Write-Host "Sample investors ONLY in Mapping CSV:" -ForegroundColor Cyan
foreach ($name in ($onlyInMapping | Sort-Object | Select-Object -First 10)) {
    Write-Host "  [NO] $name" -ForegroundColor Red
}

Write-Host ""
Write-Host "Sample investors ONLY in Imported DB:" -ForegroundColor Cyan
foreach ($name in ($onlyInImported | Sort-Object | Select-Object -First 10)) {
    Write-Host "  [NO] $name" -ForegroundColor Red
}
