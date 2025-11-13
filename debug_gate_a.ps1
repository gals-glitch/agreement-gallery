if (-not $env:SUPABASE_SERVICE_ROLE_KEY) {
    Write-Host "Run .\set_key.ps1 first" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $env:SUPABASE_SERVICE_ROLE_KEY"
    "apikey" = $env:SUPABASE_SERVICE_ROLE_KEY
}

$base = "https://qwgicrdcoqdketqhxbys.supabase.co/rest/v1"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "GATE A DEBUG REPORT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Check if party_aliases table exists and has data
Write-Host "1. Checking party_aliases table..." -ForegroundColor Yellow
try {
    $url = "$base/party_aliases?select=alias,party_id&limit=100"
    $aliases = Invoke-RestMethod -Uri $url -Headers $headers
    Write-Host "   ✅ Table exists with $($aliases.Count) aliases" -ForegroundColor Green

    if ($aliases.Count -gt 0) {
        Write-Host "   Sample aliases:" -ForegroundColor Gray
        foreach ($a in $aliases | Select-Object -First 5) {
            Write-Host "     - '$($a.alias)' → Party $($a.party_id)" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "   ❌ Table not found or error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# 2. Check actual investor notes format
Write-Host "2. Checking investor notes format (first 5 without party links)..." -ForegroundColor Yellow
$url = "$base/investors?select=id,name,notes&introduced_by_party_id=is.null&limit=5"
$investors = Invoke-RestMethod -Uri $url -Headers $headers
foreach ($inv in $investors) {
    Write-Host "   Investor: $($inv.name)" -ForegroundColor Gray
    if ($inv.notes) {
        Write-Host "     Notes: $($inv.notes)" -ForegroundColor Gray
    } else {
        Write-Host "     Notes: (empty)" -ForegroundColor Gray
    }
    Write-Host ""
}

# 3. Check available party names
Write-Host "3. Available party names in database..." -ForegroundColor Yellow
$url = "$base/parties?select=id,name&limit=20"
$parties = Invoke-RestMethod -Uri $url -Headers $headers
Write-Host "   Total parties: $($parties.Count)" -ForegroundColor Green
Write-Host "   Sample party names:" -ForegroundColor Gray
foreach ($p in $parties | Select-Object -First 10) {
    Write-Host "     - [$($p.id)] $($p.name)" -ForegroundColor Gray
}
Write-Host ""

# 4. Try to manually extract "Introduced by:" patterns
Write-Host "4. Testing regex pattern extraction..." -ForegroundColor Yellow
$url = "$base/investors?select=id,name,notes&introduced_by_party_id=is.null&limit=20"
$allInvestors = Invoke-RestMethod -Uri $url -Headers $headers
$extractedPatterns = @()
foreach ($inv in $allInvestors) {
    if ($inv.notes -match 'Introduced by:\s*([^;]+)') {
        $extracted = $matches[1].Trim()
        $extractedPatterns += @{
            investor = $inv.name
            extracted = $extracted
        }
    }
}

if ($extractedPatterns.Count -gt 0) {
    Write-Host "   ✅ Found $($extractedPatterns.Count) investors with 'Introduced by:' pattern" -ForegroundColor Green
    Write-Host "   Sample extractions:" -ForegroundColor Gray
    foreach ($item in $extractedPatterns | Select-Object -First 10) {
        Write-Host "     - $($item.investor): '$($item.extracted)'" -ForegroundColor Gray
    }
} else {
    Write-Host "   ❌ No investors found with 'Introduced by:' pattern" -ForegroundColor Red
    Write-Host "   This means the regex pattern doesn't match the actual notes format" -ForegroundColor Yellow
}
Write-Host ""

# 5. Check pg_trgm extension
Write-Host "5. Checking pg_trgm extension..." -ForegroundColor Yellow
Write-Host "   (This requires direct DB access - check in Supabase SQL Editor)" -ForegroundColor Gray
Write-Host "   Query: SELECT * FROM pg_extension WHERE extname = 'pg_trgm';" -ForegroundColor Gray
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DIAGNOSIS COMPLETE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
