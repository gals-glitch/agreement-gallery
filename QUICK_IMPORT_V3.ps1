# QUICK CSV IMPORT V3 - Correct Schema

$ErrorActionPreference = "Stop"

Write-Host "Generating import SQL (V3 - Correct Schema)..." -ForegroundColor Cyan

$importDir = "C:\Users\GalSamionov\Downloads"
$outputSql = "$PSScriptRoot\GENERATED_IMPORT_V2.sql"

$sqlLines = @()
$sqlLines += "-- QUICK IMPORT V2 - Generated $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$sqlLines += "BEGIN;"
$sqlLines += ""
$sqlLines += "-- STEP 1: Import Parties"
$sqlLines += ""

# Load parties
$parties = Import-Csv -Path "$importDir\01_parties.csv"
$partyCount = 0

foreach ($party in $parties) {
    $name = $party.party_name -replace "`r`n", " " -replace "`r", " " -replace "`n", " " -replace "'", "''"
    $email = ($party.contact_email -replace "`r`n", " " -replace "`r", " " -replace "`n", " " -replace "'", "''").Trim()
    $payment = if ($party.payment_method) { $party.payment_method } else { "Invoice" }

    if ($name) {
        $emailVal = if ($email) { "'$email'" } else { "NULL" }
        $notes = "Payment method: $payment"

        $sqlLines += "INSERT INTO parties (name, email, active, notes)"
        $sqlLines += "VALUES ('$name', $emailVal, true, '$notes')"
        $sqlLines += "ON CONFLICT (name) DO UPDATE"
        $sqlLines += "SET email = COALESCE(EXCLUDED.email, parties.email),"
        $sqlLines += "    notes = EXCLUDED.notes;"
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
    $name = $investor.investor_name -replace "`r`n", " " -replace "`r", " " -replace "`n", " " -replace "'", "''"
    $intro = ($investor.introduced_by -replace "`r`n", " " -replace "`r", " " -replace "`n", " " -replace "'", "''").Trim()
    $email = ($investor.email -replace "`r`n", " " -replace "`r", " " -replace "`n", " " -replace "'", "''").Trim()

    if ($name -and $name -ne "Totals") {
        # Build FK reference to party if introduced_by exists
        $partyIdVal = if ($intro) { "(SELECT id FROM parties WHERE name = '$intro' LIMIT 1)" } else { "NULL" }

        # Build notes with email info only (party link is in FK now)
        $notesParts = @()
        if ($intro) { $notesParts += "Introduced by: $intro" }
        if ($email) { $notesParts += "Email: $email" }
        $notes = $notesParts -join "; "
        $notesVal = if ($notes) { "'$notes'" } else { "NULL" }

        $sqlLines += "INSERT INTO investors (name, introduced_by_party_id, notes)"
        $sqlLines += "VALUES ('$name', $partyIdVal, $notesVal)"
        $sqlLines += "ON CONFLICT (name) DO UPDATE"
        $sqlLines += "SET introduced_by_party_id = COALESCE(EXCLUDED.introduced_by_party_id, investors.introduced_by_party_id),"
        $sqlLines += "    notes = COALESCE(EXCLUDED.notes, investors.notes);"
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
    # Clean party and deal names: remove line breaks and escape quotes
    $partyName = $agreement.party_name -replace "`r`n", " " -replace "`r", " " -replace "`n", " " -replace "'", "''"
    $dealName = $agreement.deal_name -replace "`r`n", " " -replace "`r", " " -replace "`n", " " -replace "'", "''"
    $rateBps = [int]$agreement.rate_bps
    $vatMode = if ($agreement.vat_mode) { $agreement.vat_mode } else { "on_top" }
    $vatRate = [decimal]$agreement.vat_rate
    $effectiveFrom = if ($agreement.effective_from) { $agreement.effective_from } else { "2020-01-01" }

    # For JSON: use quotes around date or null
    $effectiveToJson = if ($agreement.effective_to) { "`"" + $agreement.effective_to + "`"" } else { "null" }

    # For SQL: use actual date value or NULL
    $effectiveToSql = if ($agreement.effective_to) { "'$($agreement.effective_to)'::date" } else { "NULL" }

    if ($partyName -and $dealName) {
        # Escape double quotes for JSON (must be done before building JSON string)
        $partyNameJson = $partyName -replace '"', '\"'
        $dealNameJson = $dealName -replace '"', '\"'

        # Build snapshot JSON - single line, then escape single quotes for SQL
        $snapshot = "{`"kind`":`"distributor_commission`",`"party_name`":`"$partyNameJson`",`"deal_name`":`"$dealNameJson`",`"terms`":[{`"from`":`"$effectiveFrom`",`"to`":$effectiveToJson,`"rate_bps`":$rateBps,`"vat_mode`":`"$vatMode`",`"vat_rate`":$vatRate}]}"
        $snapshot = $snapshot -replace "'", "''"

        $sqlLines += "INSERT INTO agreements (party_id, deal_id, scope, kind, status, pricing_mode, effective_from, effective_to, snapshot_json)"
        $sqlLines += "SELECT p.id, d.id, 'DEAL', 'distributor_commission', 'APPROVED', 'CUSTOM', '$effectiveFrom'::date, $effectiveToSql, '$snapshot'::jsonb"
        $sqlLines += "FROM parties p CROSS JOIN deals d"
        $sqlLines += "WHERE p.name = '$partyName' AND (d.name = '$dealName' OR d.name LIKE '$dealName%')"
        $sqlLines += "ON CONFLICT DO NOTHING;"
        $sqlLines += ""
        $agreementCount++
    }
}

Write-Host "Agreements: $agreementCount" -ForegroundColor Green

# Import contributions
$sqlLines += "-- STEP 4: Import Contributions (auto-create investors if missing)"
$sqlLines += ""

$contributions = Import-Csv -Path "$importDir\04_contributions.csv"
$contributionCount = 0

foreach ($contribution in $contributions) {
    $investorName = $contribution.investor_name -replace "`r`n", " " -replace "`r", " " -replace "`n", " " -replace "'", "''"
    $dealName = $contribution.deal_name -replace "`r`n", " " -replace "`r", " " -replace "`n", " " -replace "'", "''"
    $amount = [decimal]$contribution.amount
    $paidInDate = if ($contribution.paid_in_date) { $contribution.paid_in_date } else { "2020-01-01" }

    if ($investorName -and $dealName -and $amount -gt 0) {
        # Auto-create investor if doesn't exist
        $sqlLines += "INSERT INTO investors (name) VALUES ('$investorName') ON CONFLICT (name) DO NOTHING;"

        # Insert contribution
        $sqlLines += "INSERT INTO contributions (investor_id, deal_id, amount, currency, paid_in_date)"
        $sqlLines += "SELECT i.id, d.id, $amount, 'USD', '$paidInDate'::date"
        $sqlLines += "FROM investors i CROSS JOIN deals d"
        $sqlLines += "WHERE i.name = '$investorName' AND (d.name = '$dealName' OR d.name LIKE '$dealName%')"
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
$sqlLines += "SELECT 'Parties' as table_name, COUNT(*) as count FROM parties WHERE active = true"
$sqlLines += "UNION ALL SELECT 'Investors', COUNT(*) FROM investors"
$sqlLines += "UNION ALL SELECT 'Agreements (Commission)', COUNT(*) FROM agreements WHERE kind = 'distributor_commission'"
$sqlLines += "UNION ALL SELECT 'Contributions', COUNT(*) FROM contributions;"
$sqlLines += ""
$sqlLines += "-- Check investor notes"
$sqlLines += "SELECT COUNT(*) as with_notes FROM investors WHERE notes IS NOT NULL;"

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
Write-Host "Next: Copy $outputSql contents to Supabase SQL Editor"
