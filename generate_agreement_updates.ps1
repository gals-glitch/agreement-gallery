# ============================================================================
# Generate SQL to Update All 110 Agreements with Parsed Terms
# ============================================================================
# Combines:
# - 103 parsed agreements (from parse_complex_agreements.ps1)
# - 9 manual agreements (from manual_agreements.json)
# ============================================================================

Write-Host "=== Generating Agreement Update SQL ===" -ForegroundColor Cyan

# Load parsed agreements
$parsedPath = "C:\Users\GalSamionov\Buligo Capital\Buligo Capital - Shared Documents\Information Systems\Gal\agreement-gallery-main\parsed_agreements.json"
$parsed = Get-Content $parsedPath | ConvertFrom-Json

# Load manual agreements
$manualPath = "C:\Users\GalSamionov\Buligo Capital\Buligo Capital - Shared Documents\Information Systems\Gal\agreement-gallery-main\manual_agreements.json"
$manual = Get-Content $manualPath | ConvertFrom-Json

# Combine all agreements
$allAgreements = @($parsed) + @($manual)

Write-Host "Total agreements to update: $($allAgreements.Count)" -ForegroundColor Green

# Generate SQL
$outputPath = "C:\Users\GalSamionov\Buligo Capital\Buligo Capital - Shared Documents\Information Systems\Gal\agreement-gallery-main\UPDATE_agreements_with_terms.sql"

$sqlLines = @()
$sqlLines += "-- ============================================================================"
$sqlLines += "-- [UPDATE] Set Parsed Terms for All 110 Investor Agreements"
$sqlLines += "-- ============================================================================"
$sqlLines += "-- Agreement Types:"
$sqlLines += "--   - simple_equity: Fixed equity percentage (e.g., 1% = 100 bps)"
$sqlLines += "--   - upfront_promote: Separate rates for upfront and promote"
$sqlLines += "--   - tiered_by_deal_count: Different rates based on deal number"
$sqlLines += "--   - deal_specific_limit: Limited to specific deals or max count"
$sqlLines += "--   - flat_fee: One-time payment"
$sqlLines += "--"
$sqlLines += "-- NOTE: Temporarily disables immutability trigger for initial data setup"
$sqlLines += "-- ============================================================================"
$sqlLines += ""
$sqlLines += "-- Step 1: Temporarily disable the immutability trigger"
$sqlLines += "ALTER TABLE agreements DISABLE TRIGGER agreements_lock_after_approval;"
$sqlLines += ""
$sqlLines += "-- Step 2: Update all agreements with their parsed terms"
$sqlLines += ""

# Group by type for statistics
$byType = $allAgreements | Group-Object -Property Type
$sqlLines += "-- Agreement Breakdown:"
foreach ($group in $byType) {
    $sqlLines += "--   $($group.Name): $($group.Count)"
}
$sqlLines += ""

# Generate UPDATE statements
foreach ($agreement in $allAgreements) {
    $investorNameEscaped = $agreement.InvestorName.Replace("'", "''")
    $partyNameEscaped = $agreement.PartyName.Replace("'", "''")

    # Build snapshot_json based on type
    $snapshotJson = ""

    switch ($agreement.Type) {
        "simple_equity" {
            $equityBps = $agreement.EquityBps
            $snapshotJson = @"
jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'simple_equity',
                'equity_bps', $equityBps,
                'commission_rate', 1.0,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            )
"@
        }

        "upfront_promote" {
            $upfrontRate = if ($agreement.UpfrontRate) { $agreement.UpfrontRate } else { "null" }
            $promoteRate = if ($agreement.PromoteRate) { $agreement.PromoteRate } else { "null" }
            $snapshotJson = @"
jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'upfront_promote',
                'upfront_rate', $upfrontRate,
                'promote_rate', $promoteRate,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            )
"@
        }

        "tiered_by_deal_count" {
            # Build tiers array
            $tiersJson = "jsonb_build_array("
            $tierParts = @()
            foreach ($tier in $agreement.Tiers) {
                $tierParts += @"
jsonb_build_object('deal_range', '$($tier.DealRange)', 'equity_bps', $($tier.EquityBps))
"@
            }
            $tiersJson += ($tierParts -join ", ")
            $tiersJson += ")"

            $snapshotJson = @"
jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'tiered_by_deal_count',
                'tiers', $tiersJson,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            )
"@
        }

        "deal_specific_limit" {
            $equityBps = if ($agreement.EquityBps) { $agreement.EquityBps } else { 100 }
            $maxDeals = if ($agreement.MaxDeals) { $agreement.MaxDeals } else { "null" }

            $specificDealsJson = "null"
            if ($agreement.SpecificDeals -and $agreement.SpecificDeals.Count -gt 0) {
                $dealNames = $agreement.SpecificDeals | ForEach-Object { "'$_'" }
                $specificDealsJson = "jsonb_build_array(" + ($dealNames -join ", ") + ")"
            }

            $snapshotJson = @"
jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'deal_specific_limit',
                'equity_bps', $equityBps,
                'max_deals', $maxDeals,
                'specific_deals', $specificDealsJson,
                'vat_mode', 'on_top',
                'vat_rate', 0.17
            )
"@
        }

        "flat_fee" {
            $flatFee = $agreement.FlatFee
            $currency = $agreement.FlatFeeCurrency
            $snapshotJson = @"
jsonb_build_object(
                'kind', 'distributor_commission',
                'agreement_type', 'flat_fee',
                'flat_fee', $flatFee,
                'currency', '$currency'
            )
"@
        }
    }

    # Add comment with investor name
    $sqlLines += "-- [$($agreement.Type)] $investorNameEscaped"

    # Generate UPDATE statement
    $sqlLines += @"
UPDATE agreements
SET snapshot_json = $snapshotJson,
    updated_at = NOW()
FROM investors i
INNER JOIN parties p ON p.id = i.introduced_by
WHERE agreements.kind = 'distributor_commission'
  AND agreements.investor_id = i.id
  AND agreements.party_id = p.id
  AND i.name = '$investorNameEscaped'
  AND p.name = '$partyNameEscaped';

"@
}

$sqlLines += ""
$sqlLines += "-- ============================================================================"
$sqlLines += "-- Step 3: Re-enable the immutability trigger"
$sqlLines += "-- ============================================================================"
$sqlLines += ""
$sqlLines += "ALTER TABLE agreements ENABLE TRIGGER agreements_lock_after_approval;"
$sqlLines += ""
$sqlLines += "-- ============================================================================"
$sqlLines += "-- VERIFICATION: Check Updated Agreements"
$sqlLines += "-- ============================================================================"
$sqlLines += ""
$sqlLines += "SELECT"
$sqlLines += "    '=== Agreement Types ===' as section,"
$sqlLines += "    snapshot_json->>'agreement_type' as agreement_type,"
$sqlLines += "    COUNT(*) as count"
$sqlLines += "FROM agreements"
$sqlLines += "WHERE kind = 'distributor_commission'"
$sqlLines += "  AND investor_id IS NOT NULL"
$sqlLines += "GROUP BY snapshot_json->>'agreement_type'"
$sqlLines += "ORDER BY count DESC;"
$sqlLines += ""
$sqlLines += "-- Sample agreements by type"
$sqlLines += "SELECT"
$sqlLines += "    '=== Sample Simple Equity ===' as section,"
$sqlLines += "    i.name as investor_name,"
$sqlLines += "    snapshot_json->>'equity_bps' as equity_bps,"
$sqlLines += "    snapshot_json->>'commission_rate' as commission_rate"
$sqlLines += "FROM agreements a"
$sqlLines += "INNER JOIN investors i ON i.id = a.investor_id"
$sqlLines += "WHERE a.kind = 'distributor_commission'"
$sqlLines += "  AND a.snapshot_json->>'agreement_type' = 'simple_equity'"
$sqlLines += "LIMIT 5;"
$sqlLines += ""
$sqlLines += "SELECT"
$sqlLines += "    '=== Sample Upfront/Promote ===' as section,"
$sqlLines += "    i.name as investor_name,"
$sqlLines += "    snapshot_json->>'upfront_rate' as upfront_rate,"
$sqlLines += "    snapshot_json->>'promote_rate' as promote_rate"
$sqlLines += "FROM agreements a"
$sqlLines += "INNER JOIN investors i ON i.id = a.investor_id"
$sqlLines += "WHERE a.kind = 'distributor_commission'"
$sqlLines += "  AND a.snapshot_json->>'agreement_type' = 'upfront_promote'"
$sqlLines += "LIMIT 5;"
$sqlLines += ""
$sqlLines += "SELECT"
$sqlLines += "    '=== Sample Tiered ===' as section,"
$sqlLines += "    i.name as investor_name,"
$sqlLines += "    jsonb_array_length(snapshot_json->'tiers') as tier_count,"
$sqlLines += "    snapshot_json->'tiers'->0->>'equity_bps' as tier_1_equity_bps"
$sqlLines += "FROM agreements a"
$sqlLines += "INNER JOIN investors i ON i.id = a.investor_id"
$sqlLines += "WHERE a.kind = 'distributor_commission'"
$sqlLines += "  AND a.snapshot_json->>'agreement_type' = 'tiered_by_deal_count'"
$sqlLines += "LIMIT 5;"

$sqlLines | Out-File -FilePath $outputPath -Encoding UTF8

Write-Host ""
Write-Host "SQL generated: $outputPath" -ForegroundColor Green
Write-Host ""
Write-Host "This will update all 110 agreements with proper terms structure" -ForegroundColor Yellow
Write-Host ""
Write-Host "Agreement breakdown:" -ForegroundColor Cyan
foreach ($group in $byType) {
    Write-Host "  $($group.Name): $($group.Count)" -ForegroundColor Gray
}
