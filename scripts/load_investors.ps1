# PowerShell script to parse investor CSV and generate SQL INSERT statements
# Input: INVESTOR_ROLLUP_from_DETAILS.csv
# Output: SQL INSERT statements for investors and deals

$csvPath = "C:\Users\GalSamionov\Downloads\INVESTOR_ROLLUP_from_DETAILS.csv"
$outputPath = "C:\Users\GalSamionov\Buligo Capital\Buligo Capital - Shared Documents\Information Systems\Gal\agreement-gallery-main\scripts\load_investors.sql"

Write-Host "Reading CSV from: $csvPath"

# Read CSV file
$data = Import-Csv -Path $csvPath

Write-Host "Found $($data.Count) investor records"

# Initialize collections
$investorNames = [System.Collections.ArrayList]@()
$dealNames = [System.Collections.Generic.HashSet[string]]::new()

# Parse CSV rows
foreach ($row in $data) {
    $investorName = $row.'Investor Name'.Trim()
    $commitments = $row.'All Commitments (by name)'

    # Add investor
    if ($investorName) {
        [void]$investorNames.Add($investorName)
    }

    # Parse deal names from commitments
    if ($commitments) {
        $deals = $commitments.Split(',') | ForEach-Object { $_.Trim() }
        foreach ($deal in $deals) {
            if ($deal) {
                [void]$dealNames.Add($deal)
            }
        }
    }
}

Write-Host "Unique investors: $($investorNames.Count)"
Write-Host "Unique deals: $($dealNames.Count)"

# Generate SQL
$sql = @"
-- ============================================
-- Load Investors and Deals from CSV
-- Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
-- Source: INVESTOR_ROLLUP_from_DETAILS.csv
-- ============================================

-- ============================================
-- INSERT INVESTORS
-- ============================================
INSERT INTO investors (name, currency, is_gp, notes)
VALUES
"@

# Generate investor INSERT statements
$investorValues = @()
foreach ($name in $investorNames) {
    $escapedName = $name.Replace("'", "''")
    $investorValues += "  ('$escapedName', 'USD', false, 'Imported from CSV')"
}

$sql += "`n" + ($investorValues -join ",`n")
$sql += "`nON CONFLICT (name) DO NOTHING;"
$sql += "`n`n-- Verification: Check investor count"
$sql += "`n-- SELECT COUNT(*) FROM investors;"

$sql += "`n`n-- ============================================"
$sql += "`n-- INSERT DEALS (if they don't exist)"
$sql += "`n-- Note: Deals without fund_id will need to be updated later"
$sql += "`n-- ============================================"
$sql += "`nINSERT INTO deals (name, status, close_date)"
$sql += "`nVALUES"

# Generate deal INSERT statements
$dealValues = @()
foreach ($deal in $dealNames) {
    $escapedDeal = $deal.Replace("'", "''")
    $dealValues += "  ('$escapedDeal', 'Active', NULL)"
}

$sql += "`n" + ($dealValues -join ",`n")
$sql += "`nON CONFLICT (name) DO NOTHING;"
$sql += "`n`n-- Verification: Check deal count"
$sql += "`n-- SELECT COUNT(*) FROM deals;"

$sql += "`n`n-- ============================================"
$sql += "`n-- Summary"
$sql += "`n-- ============================================"
$sql += "`n-- Total investors to insert: $($investorNames.Count)"
$sql += "`n-- Total deals to insert: $($dealNames.Count)"
$sql += "`n-- Use ON CONFLICT DO NOTHING to skip duplicates"
$sql += "`n"

# Write to file
$sql | Out-File -FilePath $outputPath -Encoding UTF8

Write-Host "`nSQL file generated: $outputPath"
Write-Host "Total investors: $($investorNames.Count)"
Write-Host "Total deals: $($dealNames.Count)"
Write-Host "`nNext steps:"
Write-Host "1. Review the generated SQL file"
Write-Host "2. Execute in Supabase SQL Editor"
Write-Host "3. Verify counts with: SELECT COUNT(*) FROM investors; SELECT COUNT(*) FROM deals;"
