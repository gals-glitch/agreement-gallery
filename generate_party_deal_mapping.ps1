# ============================================================================
# Generate Party → Deal Mapping from Commitment Data
# ============================================================================
# PURPOSE: Extract party→deal mappings from investor commitments
# INPUTS:
#   - Party-Deal Mapping.csv (investor→party relationships)
#   - COMMITMENTS_NORMALIZED_*.csv (investor→deal commitments)
#   - deals table (to get deal IDs from names)
#
# OUTPUT: SQL INSERT statements for DATA_01_party_deal_mapping.sql
# ============================================================================

Write-Host "=== Processing Commitment Data ===" -ForegroundColor Cyan

# Load the party→investor mapping
$partyMappingPath = "C:\Users\GalSamionov\OneDrive - Buligo Capital\Desktop\Party - Deal Mapping.csv"
$partyMapping = Import-Csv $partyMappingPath

Write-Host "Loaded $($partyMapping.Count) party-investor relationships" -ForegroundColor Green

# Create a hashtable for fast investor→party lookup
$investorToParty = @{}
foreach ($row in $partyMapping) {
    $investorName = $row.'Investor Name'
    $partyName = $row.'Party Name (Distributer/Referrer) '

    if ($investorName -and $partyName) {
        $investorToParty[$investorName.Trim()] = $partyName.Trim()
    }
}

Write-Host "Created lookup for $($investorToParty.Count) investors" -ForegroundColor Green

# Load all commitment files (manually parse due to duplicate headers)
$commitmentFiles = @(
    "C:\Users\GalSamionov\Downloads\COMMITMENTS_NORMALIZED_A-H__4COLS.csv",
    "C:\Users\GalSamionov\Downloads\COMMITMENTS_NORMALIZED_I-P__4COLS.csv",
    "C:\Users\GalSamionov\Downloads\COMMITMENTS_NORMALIZED_Q-Z__4COLS.csv"
)

$allCommitments = @()
foreach ($file in $commitmentFiles) {
    Write-Host "Reading $file..." -ForegroundColor Yellow

    # Read lines manually to avoid duplicate column header error
    $lines = Get-Content $file
    $header = $lines[0]

    for ($i = 1; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line) {
            # Parse CSV line (simple split - assumes no commas in values)
            $fields = $line -split ','

            if ($fields.Count -ge 3) {
                $allCommitments += [PSCustomObject]@{
                    InvestorName = $fields[0].Trim()
                    DealName = $fields[2].Trim()
                }
            }
        }
    }

    Write-Host "  Loaded $($lines.Count - 1) rows" -ForegroundColor Gray
}

Write-Host "Total commitment rows: $($allCommitments.Count)" -ForegroundColor Green

# Extract unique investor→deal combinations (skip "Total" rows)
$investorDeals = @{}
foreach ($commitment in $allCommitments) {
    $investorName = $commitment.InvestorName
    $dealName = $commitment.DealName

    # Skip total rows and empty values
    if ($dealName -eq 'Total' -or -not $dealName -or -not $investorName) {
        continue
    }

    $key = "$investorName|$dealName"
    $investorDeals[$key] = @{
        Investor = $investorName.Trim()
        Deal = $dealName.Trim()
    }
}

Write-Host "Found $($investorDeals.Count) unique investor-deal combinations" -ForegroundColor Green

# Map investor-deals to party-deals
$partyDeals = @{}
$unmappedInvestors = @()

foreach ($key in $investorDeals.Keys) {
    $investorDeal = $investorDeals[$key]
    $investorName = $investorDeal.Investor
    $dealName = $investorDeal.Deal

    # Look up party for this investor
    if ($investorToParty.ContainsKey($investorName)) {
        $partyName = $investorToParty[$investorName]

        # Store unique party-deal combination
        $partyDealKey = "$partyName|$dealName"
        if (-not $partyDeals.ContainsKey($partyDealKey)) {
            $partyDeals[$partyDealKey] = @{
                Party = $partyName
                Deal = $dealName
            }
        }
    } else {
        # Track unmapped investors
        if ($unmappedInvestors -notcontains $investorName) {
            $unmappedInvestors += $investorName
        }
    }
}

Write-Host "Generated $($partyDeals.Count) unique party-deal mappings" -ForegroundColor Green
Write-Host "Unmapped investors: $($unmappedInvestors.Count)" -ForegroundColor Yellow

# Output SQL INSERT statements
$outputPath = "C:\Users\GalSamionov\Buligo Capital\Buligo Capital - Shared Documents\Information Systems\Gal\agreement-gallery-main\DATA_01_party_deal_mapping_GENERATED.sql"

$sqlLines = @()
$sqlLines += "-- ============================================================================"
$sqlLines += "-- [DATA-01] Party → Deal Mapping (GENERATED)"
$sqlLines += "-- ============================================================================"
$sqlLines += "-- Generated from investor commitment data"
$sqlLines += "-- Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$sqlLines += "-- Party-Deal combinations: $($partyDeals.Count)"
$sqlLines += "-- ============================================================================"
$sqlLines += ""
$sqlLines += "CREATE TEMP TABLE tmp_party_deal_map("
$sqlLines += "    party_name TEXT,"
$sqlLines += "    deal_name TEXT  -- Will need to map to deal_id"
$sqlLines += ");"
$sqlLines += ""
$sqlLines += "-- Party → Deal Name mappings (need to resolve deal IDs)"
$sqlLines += "INSERT INTO tmp_party_deal_map (party_name, deal_name) VALUES"

$insertValues = @()
foreach ($key in ($partyDeals.Keys | Sort-Object)) {
    $partyDeal = $partyDeals[$key]
    $partyName = $partyDeal.Party.Replace("'", "''")  # Escape quotes
    $dealName = $partyDeal.Deal.Replace("'", "''")

    $insertValues += "('$partyName', '$dealName')"
}

$sqlLines += ($insertValues -join ",`n") + ";"
$sqlLines += ""
$sqlLines += "-- ============================================================================"
$sqlLines += "-- Map deal names to deal IDs and create final mapping"
$sqlLines += "-- ============================================================================"
$sqlLines += ""
$sqlLines += "-- Show unmapped deal names (deals not in database)"
$sqlLines += "SELECT DISTINCT"
$sqlLines += "    '=== Unmapped Deal Names ===' as section,"
$sqlLines += "    m.deal_name"
$sqlLines += "FROM tmp_party_deal_map m"
$sqlLines += "LEFT JOIN deals d ON d.name = m.deal_name"
$sqlLines += "WHERE d.id IS NULL"
$sqlLines += "ORDER BY m.deal_name;"
$sqlLines += ""
$sqlLines += "-- Create final party_name → deal_id mapping"
$sqlLines += "CREATE TEMP TABLE tmp_party_deal_map_final AS"
$sqlLines += "SELECT DISTINCT"
$sqlLines += "    m.party_name,"
$sqlLines += "    d.id as deal_id,"
$sqlLines += "    d.name as deal_name"
$sqlLines += "FROM tmp_party_deal_map m"
$sqlLines += "INNER JOIN deals d ON d.name = m.deal_name"
$sqlLines += "ORDER BY m.party_name, d.id;"
$sqlLines += ""
$sqlLines += "-- Show mapping summary"
$sqlLines += "SELECT"
$sqlLines += "    '=== Mapping Summary ===' as section,"
$sqlLines += "    COUNT(*) as total_mappings,"
$sqlLines += "    COUNT(DISTINCT party_name) as unique_parties,"
$sqlLines += "    COUNT(DISTINCT deal_id) as unique_deals"
$sqlLines += "FROM tmp_party_deal_map_final;"
$sqlLines += ""
$sqlLines += "-- Show sample mappings"
$sqlLines += "SELECT"
$sqlLines += "    '=== Sample Mappings ===' as section,"
$sqlLines += "    party_name,"
$sqlLines += "    deal_id,"
$sqlLines += "    deal_name"
$sqlLines += "FROM tmp_party_deal_map_final"
$sqlLines += "ORDER BY party_name, deal_id"
$sqlLines += "LIMIT 50;"
$sqlLines += ""
$sqlLines += "-- ============================================================================"
$sqlLines += "-- UNMAPPED INVESTORS (for reference)"
$sqlLines += "-- ============================================================================"
$sqlLines += "-- These investors have commitments but no party mapping:"

foreach ($investor in ($unmappedInvestors | Sort-Object)) {
    $sqlLines += "-- - $investor"
}

# Write to file
$sqlLines | Out-File -FilePath $outputPath -Encoding UTF8

Write-Host ""
Write-Host "=== Output Generated ===" -ForegroundColor Cyan
Write-Host "File: $outputPath" -ForegroundColor Green
Write-Host "Party-Deal mappings: $($partyDeals.Count)" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Run the generated SQL in Supabase" -ForegroundColor Gray
Write-Host "2. Review unmapped deal names" -ForegroundColor Gray
Write-Host "3. Proceed to DATA_02_update_agreement_deals.sql" -ForegroundColor Gray
