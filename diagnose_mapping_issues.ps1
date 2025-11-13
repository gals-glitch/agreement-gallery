# ============================================================================
# Diagnose Investor Mapping Issues
# ============================================================================
# PURPOSE: Find out why only 3 agreements were created instead of 110
# ============================================================================

Write-Host "=== Diagnosing Investor Mapping Issues ===" -ForegroundColor Cyan

# Load the party-investor mapping
$mappingPath = "C:\Users\GalSamionov\OneDrive - Buligo Capital\Desktop\Party - Deal Mapping.csv"
$mapping = Import-Csv $mappingPath

# Parse equity percentages
function Parse-EquityPercentage {
    param($agreementText)
    if (-not $agreementText) { return $null }
    if ($agreementText -match '(\d+\.?\d*)\s*%') {
        $percentage = [decimal]$matches[1]
        return [int]($percentage * 100)
    }
    return $null
}

# Build list of investors with equity percentages
$investorsWithEquity = @()
foreach ($row in $mapping) {
    $investorName = $row.'Investor Name'
    $partyName = $row.'Party Name (Distributer/Referrer) '
    $agreementAmount = $row.'Agreement Amount'

    if (-not $investorName -or -not $partyName) { continue }

    $equityBps = Parse-EquityPercentage $agreementAmount
    if ($equityBps) {
        $investorsWithEquity += [PSCustomObject]@{
            InvestorName = $investorName.Trim()
            PartyName = $partyName.Trim()
            EquityBps = $equityBps
        }
    }
}

Write-Host "Investors with parseable equity: $($investorsWithEquity.Count)" -ForegroundColor Yellow

# Generate SQL to check which exist in database
$outputPath = "C:\Users\GalSamionov\Buligo Capital\Buligo Capital - Shared Documents\Information Systems\Gal\agreement-gallery-main\DIAGNOSTIC_check_mappings.sql"

$sqlLines = @()
$sqlLines += "-- Check which investors/parties from mapping exist in database"
$sqlLines += ""
$sqlLines += "CREATE TEMP TABLE tmp_mapping_check ("
$sqlLines += "    investor_name TEXT,"
$sqlLines += "    party_name TEXT,"
$sqlLines += "    equity_bps INTEGER"
$sqlLines += ");"
$sqlLines += ""
$sqlLines += "INSERT INTO tmp_mapping_check VALUES"

$values = @()
foreach ($inv in $investorsWithEquity) {
    $invEscaped = $inv.InvestorName.Replace("'", "''")
    $partyEscaped = $inv.PartyName.Replace("'", "''")
    $values += "('$invEscaped', '$partyEscaped', $($inv.EquityBps))"
}

$sqlLines += ($values -join ",`n") + ";"
$sqlLines += ""
$sqlLines += "-- Check matching status"
$sqlLines += "SELECT"
$sqlLines += "    m.investor_name,"
$sqlLines += "    m.party_name,"
$sqlLines += "    m.equity_bps,"
$sqlLines += "    CASE WHEN i.id IS NOT NULL THEN 'FOUND' ELSE 'MISSING' END as investor_status,"
$sqlLines += "    CASE WHEN p.id IS NOT NULL THEN 'FOUND' ELSE 'MISSING' END as party_status,"
$sqlLines += "    i.id as investor_id,"
$sqlLines += "    p.id as party_id"
$sqlLines += "FROM tmp_mapping_check m"
$sqlLines += "LEFT JOIN investors i ON i.name = m.investor_name"
$sqlLines += "LEFT JOIN parties p ON p.name = m.party_name"
$sqlLines += "ORDER BY"
$sqlLines += "    CASE WHEN i.id IS NULL THEN 0 ELSE 1 END,"
$sqlLines += "    CASE WHEN p.id IS NULL THEN 0 ELSE 1 END,"
$sqlLines += "    m.investor_name;"
$sqlLines += ""
$sqlLines += "-- Summary counts"
$sqlLines += "SELECT"
$sqlLines += "    '=== Summary ===' as section,"
$sqlLines += "    COUNT(*) as total_mappings,"
$sqlLines += "    SUM(CASE WHEN i.id IS NOT NULL AND p.id IS NOT NULL THEN 1 ELSE 0 END) as both_found,"
$sqlLines += "    SUM(CASE WHEN i.id IS NULL THEN 1 ELSE 0 END) as investor_missing,"
$sqlLines += "    SUM(CASE WHEN p.id IS NULL THEN 1 ELSE 0 END) as party_missing"
$sqlLines += "FROM tmp_mapping_check m"
$sqlLines += "LEFT JOIN investors i ON i.name = m.investor_name"
$sqlLines += "LEFT JOIN parties p ON p.name = m.party_name;"

$sqlLines | Out-File -FilePath $outputPath -Encoding UTF8

Write-Host ""
Write-Host "Diagnostic SQL generated: $outputPath" -ForegroundColor Green
Write-Host ""
Write-Host "Run this SQL in Supabase to see:" -ForegroundColor Yellow
Write-Host "  - Which investors are MISSING from database" -ForegroundColor Gray
Write-Host "  - Which parties are MISSING from database" -ForegroundColor Gray
Write-Host "  - Summary counts" -ForegroundColor Gray
