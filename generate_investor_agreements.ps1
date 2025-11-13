# ============================================================================
# Generate Investor-Level Commission Agreements
# ============================================================================
# PURPOSE: Create commission agreements for each investor based on their
#          relationship with their introducing party (distributor)
#
# INPUT: Party - Deal Mapping.csv with columns:
#   - Party Name (Distributer/Referrer)
#   - Investor Name
#   - Agreement Amount (e.g., "1% of Equity", "25% Upfront")
#   - Payment Agreement
#
# OUTPUT: SQL to create investor-level agreements with tiered rates
# ============================================================================

Write-Host "=== Generating Investor-Level Agreements ===" -ForegroundColor Cyan

# Load the party-investor mapping
$mappingPath = "C:\Users\GalSamionov\OneDrive - Buligo Capital\Desktop\Party - Deal Mapping.csv"
$mapping = Import-Csv $mappingPath

Write-Host "Loaded $($mapping.Count) rows from mapping file" -ForegroundColor Green

# Parse equity percentages from Agreement Amount column
function Parse-EquityPercentage {
    param($agreementText)

    if (-not $agreementText) {
        return $null
    }

    # Common patterns:
    # "1% of Equity" → 100 bps
    # "25% Upfront" → 2500 bps
    # "0.5% of equity" → 50 bps
    # "1.5% for first deal" → 150 bps

    if ($agreementText -match '(\d+\.?\d*)\s*%') {
        $percentage = [decimal]$matches[1]
        $bps = [int]($percentage * 100)
        return $bps
    }

    return $null
}

# Build investor agreements
$investorAgreements = @()
$skippedRows = @()

foreach ($row in $mapping) {
    $partyName = $row.'Party Name (Distributer/Referrer) '
    $investorName = $row.'Investor Name'
    $agreementAmount = $row.'Agreement Amount'
    $paymentAgreement = $row.'Payment Agreement '

    # Skip rows with no investor name or empty party
    if (-not $investorName -or -not $partyName) {
        continue
    }

    # Parse equity percentage
    $equityBps = Parse-EquityPercentage $agreementAmount

    if ($equityBps) {
        $investorAgreements += [PSCustomObject]@{
            PartyName = $partyName.Trim()
            InvestorName = $investorName.Trim()
            EquityBps = $equityBps
            AgreementText = $agreementAmount
            PaymentAgreement = $paymentAgreement
        }
    } else {
        $skippedRows += [PSCustomObject]@{
            InvestorName = $investorName
            AgreementText = $agreementAmount
            Reason = "Could not parse equity %"
        }
    }
}

Write-Host "Parsed $($investorAgreements.Count) investor agreements" -ForegroundColor Green
Write-Host "Skipped $($skippedRows.Count) rows (no parseable equity %)" -ForegroundColor Yellow

# Generate SQL
$outputPath = "C:\Users\GalSamionov\Buligo Capital\Buligo Capital - Shared Documents\Information Systems\Gal\agreement-gallery-main\DATA_02_create_investor_agreements.sql"

$sqlLines = @()
$sqlLines += "-- ============================================================================"
$sqlLines += "-- [DATA-02] Create Investor-Level Commission Agreements"
$sqlLines += "-- ============================================================================"
$sqlLines += "-- Generated from Party - Deal Mapping.csv"
$sqlLines += "-- Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$sqlLines += "-- Investor agreements: $($investorAgreements.Count)"
$sqlLines += "--"
$sqlLines += "-- STRUCTURE:"
$sqlLines += "-- - Each investor gets one agreement"
$sqlLines += "-- - Agreement specifies equity % (stored in snapshot_json)"
$sqlLines += "-- - Agreement has 4 tiered commission rates based on deal close date:"
$sqlLines += "--   * Before Feb 1, 2018: 25%"
$sqlLines += "--   * Feb 1, 2018 - Dec 12, 2019: 27%"
$sqlLines += "--   * Dec 12, 2019 - Oct 31, 2020: 30%"
$sqlLines += "--   * After Oct 31, 2020: 35%"
$sqlLines += "-- ============================================================================"
$sqlLines += ""
$sqlLines += "-- Delete old party-level agreements (from initial import)"
$sqlLines += "DELETE FROM agreements"
$sqlLines += "WHERE kind = 'distributor_commission'"
$sqlLines += "  AND investor_id IS NULL;"
$sqlLines += ""
$sqlLines += "-- Insert investor-level agreements"
$sqlLines += "INSERT INTO agreements ("
$sqlLines += "    kind,"
$sqlLines += "    party_id,"
$sqlLines += "    investor_id,"
$sqlLines += "    scope,"
$sqlLines += "    fund_id,"
$sqlLines += "    deal_id,"
$sqlLines += "    status,"
$sqlLines += "    pricing_mode,"
$sqlLines += "    effective_from,"
$sqlLines += "    effective_to,"
$sqlLines += "    snapshot_json,"
$sqlLines += "    created_at,"
$sqlLines += "    updated_at"
$sqlLines += ")"

# Group by investor to avoid duplicates
$uniqueInvestors = $investorAgreements | Group-Object -Property InvestorName

$insertStatements = @()

foreach ($group in $uniqueInvestors) {
    $agreement = $group.Group[0]  # Take first if duplicates
    $partyNameEscaped = $agreement.PartyName.Replace("'", "''")
    $investorNameEscaped = $agreement.InvestorName.Replace("'", "''")
    $equityBps = $agreement.EquityBps

    # Note: We'll use a CTE to resolve party_id and investor_id from names
    $insertStatements += @"
-- $($agreement.InvestorName) → $($agreement.PartyName) ($($agreement.EquityBps) bps equity)
(
    SELECT
        'distributor_commission'::agreement_kind,
        p.id,
        i.id,
        'DEAL'::agreement_scope,  -- scope (use DEAL like old agreements)
        NULL::bigint,  -- fund_id
        1::bigint,  -- deal_id (placeholder - applies to all deals)
        'APPROVED'::agreement_status,
        'CUSTOM'::pricing_mode,  -- use CUSTOM like old agreements
        '2022-05-24'::date,
        NULL::date,
        jsonb_build_object(
            'kind', 'distributor_commission',
            'party_id', p.id::text,
            'party_name', p.name,
            'investor_id', i.id::text,
            'investor_name', i.name,
            'scope', jsonb_build_object('fund_id', null, 'deal_id', 1),
            'equity_bps', $equityBps,
            'terms', jsonb_build_array(
                jsonb_build_object(
                    'from', NULL,
                    'to', '2018-02-01',
                    'commission_rate', 0.25,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2018-02-01',
                    'to', '2019-12-12',
                    'commission_rate', 0.27,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2019-12-12',
                    'to', '2020-10-31',
                    'commission_rate', 0.30,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                ),
                jsonb_build_object(
                    'from', '2020-10-31',
                    'to', NULL,
                    'commission_rate', 0.35,
                    'vat_mode', 'on_top',
                    'vat_rate', 0.17
                )
            )
        ),
        NOW(),
        NOW()
    FROM investors i
    INNER JOIN parties p ON p.id = i.introduced_by
    WHERE i.name = '$investorNameEscaped'
      AND p.name = '$partyNameEscaped'
    LIMIT 1
)
"@
}

$sqlLines += ($insertStatements -join "`nUNION ALL`n") + ";"
$sqlLines += ""
$sqlLines += "-- ============================================================================"
$sqlLines += "-- VERIFICATION QUERIES"
$sqlLines += "-- ============================================================================"
$sqlLines += ""
$sqlLines += "-- Count of agreements by party"
$sqlLines += "SELECT"
$sqlLines += "    '=== Agreements by Party ===' as section,"
$sqlLines += "    p.name as party_name,"
$sqlLines += "    COUNT(a.id) as agreement_count"
$sqlLines += "FROM agreements a"
$sqlLines += "INNER JOIN parties p ON p.id = a.party_id"
$sqlLines += "WHERE a.kind = 'distributor_commission'"
$sqlLines += "  AND a.investor_id IS NOT NULL"
$sqlLines += "GROUP BY p.name"
$sqlLines += "ORDER BY agreement_count DESC;"
$sqlLines += ""
$sqlLines += "-- Sample agreements"
$sqlLines += "SELECT"
$sqlLines += "    '=== Sample Investor Agreements ===' as section,"
$sqlLines += "    p.name as party_name,"
$sqlLines += "    i.name as investor_name,"
$sqlLines += "    a.snapshot_json->>'equity_bps' as equity_bps,"
$sqlLines += "    jsonb_array_length(a.snapshot_json->'terms') as tier_count"
$sqlLines += "FROM agreements a"
$sqlLines += "INNER JOIN parties p ON p.id = a.party_id"
$sqlLines += "INNER JOIN investors i ON i.id = a.investor_id"
$sqlLines += "WHERE a.kind = 'distributor_commission'"
$sqlLines += "ORDER BY p.name, i.name"
$sqlLines += "LIMIT 20;"
$sqlLines += ""
$sqlLines += "-- Total count"
$sqlLines += "SELECT"
$sqlLines += "    '=== Total Investor Agreements ===' as section,"
$sqlLines += "    COUNT(*) as total_agreements"
$sqlLines += "FROM agreements"
$sqlLines += "WHERE kind = 'distributor_commission'"
$sqlLines += "  AND investor_id IS NOT NULL;"
$sqlLines += ""
$sqlLines += "-- ============================================================================"
$sqlLines += "-- SKIPPED ROWS (for reference)"
$sqlLines += "-- ============================================================================"

foreach ($skipped in ($skippedRows | Select-Object -First 50)) {
    $sqlLines += "-- SKIPPED: $($skipped.InvestorName) - $($skipped.AgreementText) ($($skipped.Reason))"
}

if ($skippedRows.Count -gt 50) {
    $sqlLines += "-- ... and $($skippedRows.Count - 50) more skipped rows"
}

# Write to file
$sqlLines | Out-File -FilePath $outputPath -Encoding UTF8

Write-Host ""
Write-Host "=== SQL Generated ===" -ForegroundColor Cyan
Write-Host "File: $outputPath" -ForegroundColor Green
Write-Host "Investor agreements: $($uniqueInvestors.Count)" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Run DATA_01_add_investor_to_agreements.sql first" -ForegroundColor Gray
Write-Host "2. Then run the generated DATA_02_create_investor_agreements.sql" -ForegroundColor Gray
Write-Host "3. Verify agreements created correctly" -ForegroundColor Gray
