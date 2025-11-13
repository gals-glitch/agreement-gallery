# ============================================================================
# Parse Complex Commission Agreements
# ============================================================================
# Handles multiple agreement types:
# 1. Simple equity % (e.g., "1% of Equity")
# 2. Upfront/Promote splits (e.g., "25% Upfront", "15% Promote")
# 3. Deal-based tiers (e.g., "1.5% first deal, 1% deals 2&3")
# 4. Deal-specific limits (e.g., "first 2 deals only")
# 5. Special cases (flat fees, modifiers)
# ============================================================================

Write-Host "=== Parsing Complex Commission Agreements ===" -ForegroundColor Cyan

# Load mapping CSV
$mappingPath = "C:\Users\GalSamionov\OneDrive - Buligo Capital\Desktop\Party - Deal Mapping.csv"
$mapping = Import-Csv $mappingPath

# Helper: Parse simple equity percentage
function Parse-SimpleEquity {
    param($text)

    if ($text -match '(\d+\.?\d*)\s*%\s*of\s+equity') {
        $percentage = [decimal]$matches[1]
        return @{
            Type = "simple_equity"
            EquityBps = [int]($percentage * 100)
        }
    }
    return $null
}

# Helper: Parse upfront/promote
function Parse-UpfrontPromote {
    param($text)

    $result = @{
        Type = "upfront_promote"
        UpfrontRate = $null
        PromoteRate = $null
    }

    # Match "25% Upfront"
    if ($text -match '(\d+\.?\d*)\s*%?\s+upfront') {
        $result.UpfrontRate = [decimal]$matches[1] / 100
    }

    # Match "15% of Promote" or "15% Promote"
    if ($text -match '(\d+\.?\d*)\s*%?\s+(?:of\s+)?promote') {
        $result.PromoteRate = [decimal]$matches[1] / 100
    }

    if ($result.UpfrontRate -or $result.PromoteRate) {
        return $result
    }
    return $null
}

# Helper: Parse tiered by deal count
function Parse-TieredByDealCount {
    param($text)

    # Pattern: "1.5% for first deal, 1% for deals 2&3, .5% for deals 4&5"
    # Pattern: "1.5% for first deal (Milagro), 1% for deals 2&3"

    $tiers = @()

    # Match "1.5% for first deal" or "1.5% of Equity for first deal"
    if ($text -match '(\d+\.?\d*)\s*%.*?(?:for\s+)?(?:the\s+)?first\s+deal') {
        $tiers += @{
            DealRange = "1"
            EquityBps = [int]([decimal]$matches[1] * 100)
        }
    }

    # Match "1% for deals 2&3" or "1% deal 2"
    if ($text -match '(\d+\.?\d*)\s*%.*?(?:for\s+)?deals?\s*(?:2\s*[&]?\s*3|2)') {
        $tiers += @{
            DealRange = "2-3"
            EquityBps = [int]([decimal]$matches[1] * 100)
        }
    }

    # Match "0.5% for deals 4&5"
    if ($text -match '(\d+\.?\d*)\s*%.*?(?:for\s+)?deals?\s*(?:4\s*[&]?\s*5|4)') {
        $tiers += @{
            DealRange = "4-5"
            EquityBps = [int]([decimal]$matches[1] * 100)
        }
    }

    # Match "2% on the first deal and 1% for deals 2,3,and 4"
    if ($text -match '(\d+\.?\d*)\s*%.*?on\s+the\s+first\s+deal') {
        if ($tiers.Count -eq 0) {
            $tiers += @{
                DealRange = "1"
                EquityBps = [int]([decimal]$matches[1] * 100)
            }
        }
    }

    if ($text -match 'and\s+(\d+\.?\d*)\s*%.*?for\s+deals?\s+2') {
        $tiers += @{
            DealRange = "2+"
            EquityBps = [int]([decimal]$matches[1] * 100)
        }
    }

    if ($tiers.Count -gt 0) {
        return @{
            Type = "tiered_by_deal_count"
            Tiers = $tiers
        }
    }
    return $null
}

# Helper: Parse deal-specific limits
function Parse-DealSpecificLimit {
    param($text)

    # Pattern: "1% of equity for first two deals (Weaverville and Tyson)"
    # Pattern: "First 2 deals only"

    $maxDeals = $null
    $specificDeals = @()

    if ($text -match 'first\s+(\d+)\s+deals?\s+only') {
        $maxDeals = [int]$matches[1]
    }
    elseif ($text -match 'for\s+(?:the\s+)?first\s+(\d+)\s+deals?') {
        $maxDeals = [int]$matches[1]
    }

    # Extract deal names in parentheses
    if ($text -match '\(([^)]+)\)') {
        $dealNames = $matches[1] -split ',|\s+and\s+'
        $specificDeals = $dealNames | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
    }

    if ($maxDeals -or $specificDeals.Count -gt 0) {
        return @{
            Type = "deal_specific_limit"
            MaxDeals = $maxDeals
            SpecificDeals = $specificDeals
        }
    }
    return $null
}

# Helper: Parse special modifiers
function Parse-Modifiers {
    param($text)

    $modifiers = @{}

    # Match "50% of the above fees"
    if ($text -match '(\d+)\s*%\s+of\s+the\s+above') {
        $modifiers.Multiplier = [decimal]$matches[1] / 100
    }

    # Match flat fees: "$1,000USD one time fee"
    if ($text -match '\$\s*(\d+[,\d]*)\s*(?:USD|NIS)') {
        $amount = $matches[1] -replace ',', ''
        $modifiers.FlatFee = [int]$amount
        if ($text -match 'NIS') {
            $modifiers.FlatFeeCurrency = 'NIS'
        } else {
            $modifiers.FlatFeeCurrency = 'USD'
        }
    }

    if ($modifiers.Count -gt 0) {
        return $modifiers
    }
    return $null
}

# Parse all agreements
$parsedAgreements = @()
$skipped = @()

foreach ($row in $mapping) {
    $investorName = $row.'Investor Name'
    $partyName = $row.'Party Name (Distributer/Referrer) '
    $agreementText = $row.'Agreement Amount'
    $paymentAgreement = $row.'Payment Agreement '

    if (-not $investorName -or -not $agreementText) {
        continue
    }

    # Try each parser
    $parsed = $null

    # 1. Try simple equity
    $parsed = Parse-SimpleEquity $agreementText

    # 2. Try upfront/promote
    if (-not $parsed) {
        $parsed = Parse-UpfrontPromote $agreementText
    }

    # 3. Try tiered by deal count
    if (-not $parsed) {
        $parsed = Parse-TieredByDealCount $agreementText
    }

    # 4. Try deal-specific limit (often combined with equity)
    $limitInfo = Parse-DealSpecificLimit $agreementText
    if ($limitInfo -and $parsed) {
        # Combine limit info with existing parse
        $parsed.MaxDeals = $limitInfo.MaxDeals
        $parsed.SpecificDeals = $limitInfo.SpecificDeals
    }

    # 5. Check for modifiers
    $modifiers = Parse-Modifiers $agreementText
    if ($modifiers -and $parsed) {
        $parsed.Modifiers = $modifiers
    }

    if ($parsed) {
        $parsed.InvestorName = $investorName.Trim()
        $parsed.PartyName = $partyName.Trim()
        $parsed.OriginalText = $agreementText
        $parsed.PaymentAgreement = $paymentAgreement
        $parsedAgreements += [PSCustomObject]$parsed
    } else {
        $skipped += [PSCustomObject]@{
            InvestorName = $investorName
            PartyName = $partyName
            AgreementText = $agreementText
        }
    }
}

Write-Host ""
Write-Host "=== Parsing Results ===" -ForegroundColor Cyan
Write-Host "Successfully parsed: $($parsedAgreements.Count)" -ForegroundColor Green
Write-Host "Skipped (no pattern match): $($skipped.Count)" -ForegroundColor Yellow

# Show breakdown by type
$byType = $parsedAgreements | Group-Object -Property Type
Write-Host ""
Write-Host "=== By Agreement Type ===" -ForegroundColor Cyan
foreach ($group in $byType) {
    Write-Host "  $($group.Name): $($group.Count)" -ForegroundColor Gray
}

# Export results
$parsedPath = "C:\Users\GalSamionov\Buligo Capital\Buligo Capital - Shared Documents\Information Systems\Gal\agreement-gallery-main\parsed_agreements.json"
$parsedAgreements | ConvertTo-Json -Depth 10 | Out-File -FilePath $parsedPath -Encoding UTF8

$skippedPath = "C:\Users\GalSamionov\Buligo Capital\Buligo Capital - Shared Documents\Information Systems\Gal\agreement-gallery-main\skipped_agreements.json"
$skipped | ConvertTo-Json -Depth 10 | Out-File -FilePath $skippedPath -Encoding UTF8

Write-Host ""
Write-Host "Parsed agreements saved to: $parsedPath" -ForegroundColor Green
Write-Host "Skipped agreements saved to: $skippedPath" -ForegroundColor Yellow
Write-Host ""
Write-Host "=== Sample Parsed Agreements ===" -ForegroundColor Cyan
$parsedAgreements | Select-Object -First 10 | ForEach-Object {
    Write-Host "  [$($_.Type)] $($_.InvestorName) → $($_.OriginalText)" -ForegroundColor Gray
}
