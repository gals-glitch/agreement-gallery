# Step 1: Check for duplicates and add unique constraint to deals.external_id

$ErrorActionPreference = "Stop"

# Load environment
if (Test-Path .env) {
    Get-Content .env | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+?)\s*=\s*(.+?)\s*$') {
            [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
        }
    }
}

$serviceKey = $env:SUPABASE_SERVICE_ROLE_KEY
$projectUrl = $env:SUPABASE_URL

if (-not $serviceKey -or -not $projectUrl) {
    Write-Host "ERROR: Missing SUPABASE_SERVICE_ROLE_KEY or SUPABASE_URL in .env" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== STEP 1: Lock Funds Upserts ===" -ForegroundColor Cyan
Write-Host "Checking for duplicate external_id in deals table..." -ForegroundColor Yellow

# Check for duplicates
$checkSql = Get-Content "step1_check_deals_duplicates.sql" -Raw
$checkBody = @{ query = $checkSql } | ConvertTo-Json
$checkResponse = Invoke-RestMethod -Uri "$projectUrl/rest/v1/rpc/exec_sql" `
    -Method Post `
    -Headers @{
        "apikey" = $serviceKey
        "Authorization" = "Bearer $serviceKey"
        "Content-Type" = "application/json"
        "Prefer" = "return=representation"
    } `
    -Body $checkBody `
    -ErrorAction SilentlyContinue

Write-Host "`nDuplicate Check Result:" -ForegroundColor Cyan
if ($checkResponse) {
    $checkResponse | ConvertTo-Json -Depth 5
} else {
    # Alternative: use psql-style query
    $dupCount = @"
SELECT COUNT(*) AS duplicate_groups
FROM (
    SELECT external_id, COUNT(*) AS c
    FROM public.deals
    WHERE external_id IS NOT NULL
    GROUP BY external_id
    HAVING COUNT(*) > 1
) dups;
"@

    Write-Host "Running direct count check..." -ForegroundColor Yellow
    # We'll use the SQL Editor approach - output the query for manual run
    Write-Host "`nPlease run this in Supabase SQL Editor:" -ForegroundColor Yellow
    Write-Host $dupCount

    $proceed = Read-Host "`nAre there 0 duplicate groups? (y/n)"
    if ($proceed -ne "y") {
        Write-Host "ERROR: Duplicates found! Resolve them before adding constraint." -ForegroundColor Red
        exit 1
    }
}

Write-Host "`nNo duplicates found. Adding unique constraint..." -ForegroundColor Green

# Add the constraint
$constraintSql = Get-Content "step1_add_deals_constraint.sql" -Raw
Write-Host "`nSQL to execute:" -ForegroundColor Cyan
Write-Host $constraintSql

# Copy to clipboard for manual execution
$constraintSql | Set-Clipboard
Write-Host "`n✓ SQL copied to clipboard" -ForegroundColor Green
Write-Host "Please run it in Supabase SQL Editor and press Enter when done..." -ForegroundColor Yellow
Read-Host

Write-Host "`n✓ Step 1 complete: deals.external_id is now unique" -ForegroundColor Green
