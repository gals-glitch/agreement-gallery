# ============================================================
# QUICK CSV IMPORT V2 - Simpler approach
# ============================================================

$ErrorActionPreference = "Stop"

Write-Host "Generating import SQL..." -ForegroundColor Cyan

$importDir = "$PSScriptRoot\import_templates"
$outputSql = "$PSScriptRoot\GENERATED_IMPORT.sql"

# Start SQL with header
$sqlLines = @()
$sqlLines += "-- QUICK IMPORT - Generated $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$sqlLines += "BEGIN;"
$sqlLines += ""
$sqlLines += "-- STEP 1: Import Parties"
$sqlLines += ""

# Load parties
$parties = Import-Csv -Path "$importDir\01_parties.csv"
$partyCount = 0

foreach ($party in $parties) {
    $name = $party.party_name -replace "'", "''"
    $email = ($party.contact_email -replace "'", "''").Trim()
    $payment = if ($party.payment_method) { $party.payment_method } else { "Invoice" }

    if ($name) {
        $emailVal = if ($email) { "'$email'" } else { "NULL" }

        $sqlLines += "INSERT INTO parties (name, contact_email, kind, payment_method, status)"
        $sqlLines += "VALUES ('$name', $emailVal, 'DISTRIBUTOR', '$payment', 'ACTIVE')"
        $sqlLines += "ON CONFLICT (name) DO UPDATE"
        $sqlLines += "SET contact_email = COALESCE(EXCLUDED.contact_email, parties.contact_email),"
        $sqlLines += "    payment_method = EXCLUDED.payment_method;"
        $sqlLines += ""
        $partyCount++
    }
}

Write-Host "Parties: $partyCount" -ForegroundColor Green

# Import investors
$sqlLines += "-- STEP 2: Import Investors"
$sqlLines += ""

$investors = Import-Csv -Path "$importDir\02_investors.csv"
$investorCount = 0

foreach ($investor in $investors) {
    $name = $investor.investor_name -replace "'", "''"
    $intro = ($investor.introduced_by -replace "'", "''").Trim()
    $email = ($investor.email -replace "'", "''").Trim()

    if ($name -and $name -ne "Totals") {
        $emailVal = if ($email) { "'$email'" } else { "NULL" }
        $introVal = if ($intro) { "(SELECT id FROM parties WHERE name = '$intro' LIMIT 1)" } else { "NULL" }

        $sqlLines += "INSERT INTO investors (name, email, introduced_by, status)"
        $sqlLines += "VALUES ('$name', $emailVal, $introVal, 'ACTIVE')"
        $sqlLines += "ON CONFLICT (name) DO UPDATE"
        $sqlLines += "SET email = COALESCE(EXCLUDED.email, investors.email),"
        $sqlLines += "    introduced_by = COALESCE(EXCLUDED.introduced_by, investors.introduced_by);"
        $sqlLines += ""
        $investorCount++
    }
}

Write-Host "Investors: $investorCount" -ForegroundColor Green

# Import agreements
$sqlLines += "-- STEP 3: Import Agreements"
$sqlLines += ""

$agreements = Import-Csv -Path "$importDir\03_agreements.csv"
$agreementCount = 0

foreach ($agreement in $agreements) {
    $partyName = $agreement.party_name -replace "'", "''"
    $dealName = $agreement.deal_name -replace "'", "''"
    $rateBps = [int]$agreement.rate_bps
    $vatMode = if ($agreement.vat_mode) { $agreement.vat_mode } else { "on_top" }
    $vatRate = [decimal]$agreement.vat_rate
    $effectiveFrom = if ($agreement.effective_from) { $agreement.effective_from } else { "2020-01-01" }
    $effectiveTo = if ($agreement.effective_to) { "'" + $agreement.effective_to + "'" } else { "NULL" }

    if ($partyName -and $dealName) {
        $snapshot = "{`"kind`":`"distributor_commission`",`"party_name`":`"$partyName`",`"deal_name`":`"$dealName`",`"terms`":[{`"from`":`"$effectiveFrom`",`"to`":$effectiveTo,`"rate_bps`":$rateBps,`"vat_mode`":`"$vatMode`",`"vat_rate`":$vatRate}]}"
        $snapshot = $snapshot -replace "'", "''"

        $sqlLines += "INSERT INTO agreements (party_id, deal_id, scope, kind, status, snapshot_json, created_at, updated_at)"
        $sqlLines += "SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', '$snapshot'::jsonb, now(), now()"
        $sqlLines += "FROM parties p CROSS JOIN deals d"
        $sqlLines += "WHERE p.name = '$partyName' AND d.name = '$dealName'"
        $sqlLines += "ON CONFLICT DO NOTHING;"
        $sqlLines += ""
        $agreementCount++
    }
}

Write-Host "Agreements: $agreementCount" -ForegroundColor Green

# Import contributions
$sqlLines += "-- STEP 4: Import Contributions"
$sqlLines += ""

$contributions = Import-Csv -Path "$importDir\04_contributions.csv"
$contributionCount = 0

foreach ($contribution in $contributions) {
    $investorName = $contribution.investor_name -replace "'", "''"
    $dealName = $contribution.deal_name -replace "'", "''"
    $amount = [decimal]$contribution.amount
    $paidInDate = if ($contribution.paid_in_date) { $contribution.paid_in_date } else { "2020-01-01" }

    if ($investorName -and $dealName -and $amount -gt 0) {
        $sqlLines += "INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date, status, created_at, updated_at)"
        $sqlLines += "SELECT i.id, d.id, $amount, 'USD', '$paidInDate'::date, 'CONFIRMED', now(), now()"
        $sqlLines += "FROM investors i CROSS JOIN deals d"
        $sqlLines += "WHERE i.name = '$investorName' AND d.name = '$dealName'"
        $sqlLines += "ON CONFLICT DO NOTHING;"
        $sqlLines += ""
        $contributionCount++
    }
}

Write-Host "Contributions: $contributionCount" -ForegroundColor Green

# Finish SQL
$sqlLines += "COMMIT;"
$sqlLines += ""
$sqlLines += "-- Verification"
$sqlLines += "SELECT 'Parties' as table_name, COUNT(*) as count FROM parties WHERE status = 'ACTIVE'"
$sqlLines += "UNION ALL SELECT 'Investors', COUNT(*) FROM investors WHERE status = 'ACTIVE'"
$sqlLines += "UNION ALL SELECT 'Agreements (Commission)', COUNT(*) FROM agreements WHERE kind = 'distributor_commission'"
$sqlLines += "UNION ALL SELECT 'Contributions', COUNT(*) FROM contributions;"

# Write file
$sqlLines | Out-File -FilePath $outputSql -Encoding UTF8

Write-Host ""
Write-Host "SQL generated: $outputSql" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:"
Write-Host "  Parties: $partyCount"
Write-Host "  Investors: $investorCount"
Write-Host "  Agreements: $agreementCount"
Write-Host "  Contributions: $contributionCount"
Write-Host ""
Write-Host "Next: Open $outputSql and paste into Supabase SQL Editor"
