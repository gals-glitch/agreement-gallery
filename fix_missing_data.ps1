# ============================================================================
# Fix Missing Investors and Parties for Agreement Creation
# ============================================================================
# PURPOSE: Generate SQL to:
#   1. Create missing investors (47)
#   2. Create missing parties (7)
#   3. Fix introduced_by relationships (57 - 3 = 54)
# ============================================================================

Write-Host "=== Generating Fix SQL for Missing Data ===" -ForegroundColor Cyan

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

Write-Host "Investors with equity: $($investorsWithEquity.Count)" -ForegroundColor Yellow

# Generate comprehensive diagnostic and fix SQL
$outputPath = "C:\Users\GalSamionov\Buligo Capital\Buligo Capital - Shared Documents\Information Systems\Gal\agreement-gallery-main\FIX_missing_data.sql"

$sqlLines = @()
$sqlLines += "-- ============================================================================"
$sqlLines += "-- [FIX] Create Missing Investors/Parties and Fix Relationships"
$sqlLines += "-- ============================================================================"
$sqlLines += "-- Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$sqlLines += "--"
$sqlLines += "-- DIAGNOSTIC SUMMARY:"
$sqlLines += "-- - 110 investor-party mappings with equity percentages"
$sqlLines += "-- - 57 have both investor and party in database"
$sqlLines += "-- - 47 investors are MISSING"
$sqlLines += "-- - 7 parties are MISSING"
$sqlLines += "-- - Only 3/57 agreements created (introduced_by mismatch)"
$sqlLines += "-- ============================================================================"
$sqlLines += ""
$sqlLines += "-- Step 1: Create temp table with all mappings"
$sqlLines += "CREATE TEMP TABLE tmp_fix_mappings ("
$sqlLines += "    investor_name TEXT,"
$sqlLines += "    party_name TEXT,"
$sqlLines += "    equity_bps INTEGER"
$sqlLines += ");"
$sqlLines += ""
$sqlLines += "INSERT INTO tmp_fix_mappings VALUES"

$values = @()
foreach ($inv in $investorsWithEquity) {
    $invEscaped = $inv.InvestorName.Replace("'", "''")
    $partyEscaped = $inv.PartyName.Replace("'", "''")
    $values += "('$invEscaped', '$partyEscaped', $($inv.EquityBps))"
}

$sqlLines += ($values -join ",`n") + ";"
$sqlLines += ""
$sqlLines += "-- ============================================================================"
$sqlLines += "-- DIAGNOSTIC: Show Missing Investors"
$sqlLines += "-- ============================================================================"
$sqlLines += ""
$sqlLines += "SELECT"
$sqlLines += "    '=== MISSING INVESTORS (47) ===' as section,"
$sqlLines += "    m.investor_name,"
$sqlLines += "    m.party_name,"
$sqlLines += "    m.equity_bps"
$sqlLines += "FROM tmp_fix_mappings m"
$sqlLines += "LEFT JOIN investors i ON i.name = m.investor_name"
$sqlLines += "WHERE i.id IS NULL"
$sqlLines += "ORDER BY m.party_name, m.investor_name;"
$sqlLines += ""
$sqlLines += "-- ============================================================================"
$sqlLines += "-- DIAGNOSTIC: Show Missing Parties"
$sqlLines += "-- ============================================================================"
$sqlLines += ""
$sqlLines += "SELECT DISTINCT"
$sqlLines += "    '=== MISSING PARTIES (7) ===' as section,"
$sqlLines += "    m.party_name"
$sqlLines += "FROM tmp_fix_mappings m"
$sqlLines += "LEFT JOIN parties p ON p.name = m.party_name"
$sqlLines += "WHERE p.id IS NULL"
$sqlLines += "ORDER BY m.party_name;"
$sqlLines += ""
$sqlLines += "-- ============================================================================"
$sqlLines += "-- DIAGNOSTIC: Show introduced_by Mismatches (54)"
$sqlLines += "-- ============================================================================"
$sqlLines += ""
$sqlLines += "SELECT"
$sqlLines += "    '=== INTRODUCED_BY MISMATCHES ===' as section,"
$sqlLines += "    m.investor_name,"
$sqlLines += "    m.party_name as expected_party,"
$sqlLines += "    p_actual.name as actual_party,"
$sqlLines += "    i.id as investor_id,"
$sqlLines += "    p_expected.id as expected_party_id,"
$sqlLines += "    i.introduced_by as actual_party_id"
$sqlLines += "FROM tmp_fix_mappings m"
$sqlLines += "INNER JOIN investors i ON i.name = m.investor_name"
$sqlLines += "INNER JOIN parties p_expected ON p_expected.name = m.party_name"
$sqlLines += "LEFT JOIN parties p_actual ON p_actual.id = i.introduced_by"
$sqlLines += "WHERE i.introduced_by != p_expected.id OR i.introduced_by IS NULL"
$sqlLines += "ORDER BY m.party_name, m.investor_name;"
$sqlLines += ""
$sqlLines += "-- ============================================================================"
$sqlLines += "-- FIX STEP 1: Create Missing Parties"
$sqlLines += "-- ============================================================================"
$sqlLines += ""
$sqlLines += "INSERT INTO parties (name, created_at, updated_at)"
$sqlLines += "SELECT DISTINCT"
$sqlLines += "    m.party_name,"
$sqlLines += "    NOW(),"
$sqlLines += "    NOW()"
$sqlLines += "FROM tmp_fix_mappings m"
$sqlLines += "LEFT JOIN parties p ON p.name = m.party_name"
$sqlLines += "WHERE p.id IS NULL"
$sqlLines += "ON CONFLICT (name) DO NOTHING;"
$sqlLines += ""
$sqlLines += "-- ============================================================================"
$sqlLines += "-- FIX STEP 2: Create Missing Investors"
$sqlLines += "-- ============================================================================"
$sqlLines += ""
$sqlLines += "INSERT INTO investors (name, introduced_by, created_at, updated_at)"
$sqlLines += "SELECT"
$sqlLines += "    m.investor_name,"
$sqlLines += "    p.id,"
$sqlLines += "    NOW(),"
$sqlLines += "    NOW()"
$sqlLines += "FROM tmp_fix_mappings m"
$sqlLines += "LEFT JOIN investors i ON i.name = m.investor_name"
$sqlLines += "INNER JOIN parties p ON p.name = m.party_name"
$sqlLines += "WHERE i.id IS NULL"
$sqlLines += "ON CONFLICT (name) DO NOTHING;"
$sqlLines += ""
$sqlLines += "-- ============================================================================"
$sqlLines += "-- FIX STEP 3: Fix introduced_by Relationships"
$sqlLines += "-- ============================================================================"
$sqlLines += ""
$sqlLines += "UPDATE investors i"
$sqlLines += "SET introduced_by = p_expected.id,"
$sqlLines += "    updated_at = NOW()"
$sqlLines += "FROM tmp_fix_mappings m"
$sqlLines += "INNER JOIN parties p_expected ON p_expected.name = m.party_name"
$sqlLines += "WHERE i.name = m.investor_name"
$sqlLines += "  AND (i.introduced_by != p_expected.id OR i.introduced_by IS NULL);"
$sqlLines += ""
$sqlLines += "-- ============================================================================"
$sqlLines += "-- VERIFICATION: Check All Mappings Now Match"
$sqlLines += "-- ============================================================================"
$sqlLines += ""
$sqlLines += "SELECT"
$sqlLines += "    '=== FINAL VERIFICATION ===' as section,"
$sqlLines += "    COUNT(*) as total_mappings,"
$sqlLines += "    SUM(CASE WHEN i.id IS NOT NULL AND p.id IS NOT NULL AND i.introduced_by = p.id THEN 1 ELSE 0 END) as ready_for_agreements,"
$sqlLines += "    SUM(CASE WHEN i.id IS NULL THEN 1 ELSE 0 END) as still_missing_investor,"
$sqlLines += "    SUM(CASE WHEN p.id IS NULL THEN 1 ELSE 0 END) as still_missing_party,"
$sqlLines += "    SUM(CASE WHEN i.id IS NOT NULL AND p.id IS NOT NULL AND i.introduced_by != p.id THEN 1 ELSE 0 END) as still_wrong_relationship"
$sqlLines += "FROM tmp_fix_mappings m"
$sqlLines += "LEFT JOIN investors i ON i.name = m.investor_name"
$sqlLines += "LEFT JOIN parties p ON p.name = m.party_name;"
$sqlLines += ""
$sqlLines += "-- Expected result: ready_for_agreements = 110, all others = 0"

$sqlLines | Out-File -FilePath $outputPath -Encoding UTF8

Write-Host ""
Write-Host "Fix SQL generated: $outputPath" -ForegroundColor Green
Write-Host ""
Write-Host "This SQL will:" -ForegroundColor Yellow
Write-Host "  1. Show which 47 investors are missing" -ForegroundColor Gray
Write-Host "  2. Show which 7 parties are missing" -ForegroundColor Gray
Write-Host "  3. Show which 54 investors have wrong introduced_by" -ForegroundColor Gray
Write-Host "  4. Create all missing parties" -ForegroundColor Gray
Write-Host "  5. Create all missing investors" -ForegroundColor Gray
Write-Host "  6. Fix all introduced_by relationships" -ForegroundColor Gray
Write-Host "  7. Verify all 110 mappings are ready" -ForegroundColor Gray
Write-Host ""
Write-Host "After running this, you can run DATA_02_create_investor_agreements.sql" -ForegroundColor Green
