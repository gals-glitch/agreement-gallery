# ============================================================
# COV-01: SEED MISSING AGREEMENTS (COVERAGE BOOST)
# ============================================================
# Purpose: Create default agreements for contributions that can't compute
# Strategy: Find party-deal combinations missing agreements, create with:
#   - pricing_mode: CUSTOM
#   - rate: 100 bps (placeholder)
#   - vat_mode: on_top
#   - vat_rate: 0.17 (Israel standard)
#   - status: DRAFT (flagged for business review)
# ============================================================

$ErrorActionPreference = "Stop"

$BASE_URL = "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1"
$SUPABASE_URL = "https://qwgicrdcoqdketqhxbys.supabase.co"

# Check for service role key
if (-not $env:SUPABASE_SERVICE_ROLE_KEY) {
    Write-Host "❌ ERROR: SUPABASE_SERVICE_ROLE_KEY environment variable not set" -ForegroundColor Red
    exit 1
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "COV-01: SEED MISSING AGREEMENTS FOR COVERAGE BOOST" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$headers = @{
    "Authorization" = "Bearer $env:SUPABASE_SERVICE_ROLE_KEY"
    "apikey" = $env:SUPABASE_SERVICE_ROLE_KEY
    "Content-Type" = "application/json"
}

# Step 1: Find party-deal combinations that need agreements
Write-Host "📊 Step 1: Finding party-deal combinations without approved agreements..." -ForegroundColor Yellow
Write-Host ""

# Query to find combinations
$query = @"
contributions?select=deal_id,fund_id,investors!inner(introduced_by_party_id,parties(id,name)),deals(id,name),funds(id,name)&investors.introduced_by_party_id=not.is.null&order=deal_id.asc&limit=200
"@

try {
    $contributions = Invoke-RestMethod -Uri "$SUPABASE_URL/rest/v1/$query" -Headers $headers -Method Get
    Write-Host "✅ Found $($contributions.Count) contributions with party links" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to fetch contributions: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Get existing agreements
Write-Host "📊 Fetching existing approved agreements..." -ForegroundColor Yellow
$agreementsQuery = "agreements?select=party_id,deal_id,fund_id,status&status=eq.APPROVED"
try {
    $existingAgreements = Invoke-RestMethod -Uri "$SUPABASE_URL/rest/v1/$agreementsQuery" -Headers $headers -Method Get
    Write-Host "✅ Found $($existingAgreements.Count) existing approved agreements" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to fetch agreements: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Build set of existing agreements
$agreementSet = @{}
foreach ($agr in $existingAgreements) {
    $key = "$($agr.party_id)-$($agr.deal_id)-$($agr.fund_id)"
    $agreementSet[$key] = $true
}

# Find missing combinations
$missingCombos = @{}
foreach ($contrib in $contributions) {
    $partyId = $contrib.investors.introduced_by_party_id
    $dealId = $contrib.deal_id
    $fundId = $contrib.fund_id

    if ($partyId -and ($dealId -or $fundId)) {
        $key = "$partyId-$dealId-$fundId"

        if (-not $agreementSet.ContainsKey($key) -and -not $missingCombos.ContainsKey($key)) {
            $partyName = if ($contrib.investors.parties) { $contrib.investors.parties.name } else { "Unknown" }
            $dealName = if ($contrib.deals) { $contrib.deals.name } else { $null }
            $fundName = if ($contrib.funds) { $contrib.funds.name } else { $null }

            $missingCombos[$key] = @{
                party_id = $partyId
                party_name = $partyName
                deal_id = $dealId
                deal_name = $dealName
                fund_id = $fundId
                fund_name = $fundName
            }
        }
    }
}

Write-Host "📊 Analysis:" -ForegroundColor Cyan
Write-Host "  Contributions analyzed: $($contributions.Count)" -ForegroundColor Gray
Write-Host "  Existing approved agreements: $($existingAgreements.Count)" -ForegroundColor Gray
Write-Host "  Missing party-deal combinations: $($missingCombos.Count)" -ForegroundColor Yellow
Write-Host ""

if ($missingCombos.Count -eq 0) {
    Write-Host "✅ No missing agreements! All contributions have matching agreements." -ForegroundColor Green
    Write-Host "You can run CMP_01_batch_compute_eligible.ps1 now" -ForegroundColor Cyan
    exit 0
}

# Display missing combinations
Write-Host "Missing Agreements:" -ForegroundColor Yellow
foreach ($combo in $missingCombos.Values) {
    $scope = if ($combo.deal_id) { "DEAL: $($combo.deal_name)" } else { "FUND: $($combo.fund_name)" }
    Write-Host "  • Party: $($combo.party_name) → $scope" -ForegroundColor Gray
}
Write-Host ""

# Step 2: Prompt for confirmation
Write-Host "⚠️  WARNING: About to create $($missingCombos.Count) DRAFT agreements" -ForegroundColor Yellow
Write-Host "These will use placeholder values:" -ForegroundColor Yellow
Write-Host "  • Pricing: CUSTOM with 100 bps (1.0%)" -ForegroundColor Gray
Write-Host "  • VAT: On top, 17%" -ForegroundColor Gray
Write-Host "  • Status: DRAFT (requires business approval)" -ForegroundColor Gray
Write-Host ""
$confirmation = Read-Host "Continue? (y/N)"
if ($confirmation -ne "y" -and $confirmation -ne "Y") {
    Write-Host "❌ Cancelled by user" -ForegroundColor Red
    exit 0
}
Write-Host ""

# Step 3: Create agreements
Write-Host "📝 Step 3: Creating DRAFT agreements..." -ForegroundColor Yellow
Write-Host ""

$successCount = 0
$errorCount = 0
$csvExport = @()

foreach ($combo in $missingCombos.Values) {
    $scope = if ($combo.deal_id) { "DEAL" } else { "FUND" }
    $scopeId = if ($combo.deal_id) { $combo.deal_id } else { $combo.fund_id }
    $scopeName = if ($combo.deal_id) { $combo.deal_name } else { $combo.fund_name }

    Write-Host "Creating agreement: $($combo.party_name) → $scope $scopeName..." -ForegroundColor Gray

    # Prepare agreement data
    $agreement = @{
        party_id = $combo.party_id
        scope = $scope
        deal_id = $combo.deal_id
        fund_id = $combo.fund_id
        pricing_mode = "CUSTOM"
        effective_from = (Get-Date).ToString("yyyy-MM-dd")
        effective_to = $null
        vat_included = $false
        status = "DRAFT"
        notes = "Auto-generated by COV-01 for coverage boost. REQUIRES BUSINESS REVIEW. Placeholder rate: 100 bps."
    }

    # Insert agreement via REST API
    $body = $agreement | ConvertTo-Json

    try {
        $result = Invoke-RestMethod -Uri "$SUPABASE_URL/rest/v1/agreements" -Headers $headers -Method Post -Body $body -ContentType "application/json"

        # The REST API should return the inserted record with 'Prefer: return=representation' header
        # For now, assume success and fetch the ID
        Write-Host "  ✅ Agreement created (DRAFT)" -ForegroundColor Green

        # Now create custom terms
        # We need the agreement ID - let's query for it
        $agreementQuery = "agreements?select=id&party_id=eq.$($combo.party_id)&deal_id=$( if ($combo.deal_id) { "eq.$($combo.deal_id)" } else { "is.null" })&fund_id=$( if ($combo.fund_id) { "eq.$($combo.fund_id)" } else { "is.null" })&status=eq.DRAFT&order=created_at.desc&limit=1"
        $agreementResult = Invoke-RestMethod -Uri "$SUPABASE_URL/rest/v1/$agreementQuery" -Headers $headers -Method Get

        if ($agreementResult.Count -gt 0) {
            $agreementId = $agreementResult[0].id

            # Create custom terms
            $customTerms = @{
                agreement_id = $agreementId
                upfront_bps = 100
                deferred_bps = 0
                caps_json = $null
                tiers_json = $null
            } | ConvertTo-Json

            Invoke-RestMethod -Uri "$SUPABASE_URL/rest/v1/agreement_custom_terms" -Headers $headers -Method Post -Body $customTerms -ContentType "application/json" | Out-Null
            Write-Host "  ✅ Custom terms added (100 bps upfront)" -ForegroundColor Green
        }

        $successCount++

        # Add to CSV export
        $csvExport += [PSCustomObject]@{
            Party = $combo.party_name
            Scope = $scope
            DealOrFund = $scopeName
            Rate_BPS = 100
            VAT_Included = "No"
            Status = "DRAFT - NEEDS REVIEW"
            Notes = "Auto-generated placeholder"
        }

    } catch {
        Write-Host "  ❌ Failed: $($_.Exception.Message)" -ForegroundColor Red
        $errorCount++
    }
}

Write-Host ""

# Step 4: Export to CSV for business review
if ($csvExport.Count -gt 0) {
    $csvPath = "scripts\COV-01_new_agreements_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    $csvExport | Export-Csv -Path $csvPath -NoTypeInformation

    Write-Host "📄 Exported agreements to: $csvPath" -ForegroundColor Cyan
    Write-Host ""
}

# Summary
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "✅ Success: $successCount agreements created" -ForegroundColor Green
Write-Host "❌ Errors: $errorCount" -ForegroundColor Red
Write-Host ""

if ($successCount -gt 0) {
    Write-Host "✅ COV-01 COMPLETE: Coverage boost applied!" -ForegroundColor Green
    Write-Host ""
    Write-Host "⚠️  IMPORTANT: These agreements are in DRAFT status" -ForegroundColor Yellow
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Review CSV export: $csvPath" -ForegroundColor Gray
    Write-Host "  2. Update rates in Supabase UI or via SQL" -ForegroundColor Gray
    Write-Host "  3. Submit and approve agreements when confirmed" -ForegroundColor Gray
    Write-Host "  4. Run: UPDATE agreements SET status='APPROVED' WHERE notes LIKE '%COV-01%' AND <your conditions>" -ForegroundColor Gray
    Write-Host "  5. Then run CMP_01_batch_compute_eligible.ps1 to compute commissions" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Quick approve all (if rates are correct):" -ForegroundColor Yellow
    Write-Host "  UPDATE agreements SET status='APPROVED' WHERE notes LIKE '%COV-01%';" -ForegroundColor Gray
} else {
    Write-Host "❌ No agreements created" -ForegroundColor Red
}
