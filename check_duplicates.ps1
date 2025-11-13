# Check for duplicate investors and count total
$projectUrl = "https://qwgicrdcoqdketqhxbys.supabase.co"
$serviceRoleKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3Z2ljcmRjb3Fka2V0cWh4YnlzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzIyNjMwNywiZXhwIjoyMDcyODAyMzA3fQ.bPUTKQM-tOm1u_1NlVNXczSbA118443uOpeo2Waa2zo"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Duplicate Investors Analysis" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$headers = @{
    'apikey' = $serviceRoleKey
    'Authorization' = "Bearer $serviceRoleKey"
    'Prefer' = 'count=exact'
}

# Get total count
Write-Host "Getting total investor count..." -ForegroundColor Yellow
$url = "$projectUrl/rest/v1/investors?select=id"
try {
    $response = Invoke-WebRequest -Uri $url -Headers $headers -Method Head
    $totalCount = $response.Headers['Content-Range'][0] -replace '.*/', ''
    Write-Host "  Total investors: $totalCount" -ForegroundColor White
    Write-Host ""
} catch {
    Write-Host "  Error: $_" -ForegroundColor Red
}

# Count by source_kind
Write-Host "Counting by source_kind..." -ForegroundColor Yellow
$headers['Prefer'] = 'return=representation'
$url = "$projectUrl/rest/v1/investors?select=source_kind"
try {
    $investors = Invoke-RestMethod -Uri $url -Headers $headers
    $grouped = $investors | Group-Object -Property source_kind
    $grouped | ForEach-Object {
        Write-Host "  $($_.Name): $($_.Count)" -ForegroundColor White
    }
    Write-Host ""
} catch {
    Write-Host "  Error: $_" -ForegroundColor Red
}

# Find duplicates by name
Write-Host "Finding duplicate names..." -ForegroundColor Yellow
$url = "$projectUrl/rest/v1/investors?select=id,name,source_kind,external_id&order=name.asc"
try {
    $allInvestors = Invoke-RestMethod -Uri $url -Headers $headers
    $duplicates = $allInvestors | Group-Object -Property name | Where-Object { $_.Count -gt 1 }

    Write-Host "  Found $($duplicates.Count) duplicate names" -ForegroundColor White
    Write-Host ""

    if ($duplicates.Count -gt 0) {
        Write-Host "Sample duplicates (first 10):" -ForegroundColor Yellow
        $duplicates | Select-Object -First 10 | ForEach-Object {
            Write-Host "  $($_.Name) ($($_.Count) records):" -ForegroundColor Cyan
            $_.Group | ForEach-Object {
                Write-Host "    - ID: $($_.id), Source: $($_.source_kind), External ID: $($_.external_id)" -ForegroundColor White
            }
            Write-Host ""
        }
    }
} catch {
    Write-Host "  Error: $_" -ForegroundColor Red
}

# Count Vantage with and without external_id
Write-Host "Checking external_id population..." -ForegroundColor Yellow
$url = "$projectUrl/rest/v1/investors?select=id,external_id&source_kind=eq.vantage"
try {
    $vantageInvestors = Invoke-RestMethod -Uri $url -Headers $headers
    $withExternalId = ($vantageInvestors | Where-Object { $_.external_id -ne $null }).Count
    $withoutExternalId = ($vantageInvestors | Where-Object { $_.external_id -eq $null }).Count

    Write-Host "  Vantage investors with external_id: $withExternalId" -ForegroundColor White
    Write-Host "  Vantage investors without external_id: $withoutExternalId" -ForegroundColor White
    Write-Host ""
} catch {
    Write-Host "  Error: $_" -ForegroundColor Red
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "This analysis shows if the Vantage sync created duplicates" -ForegroundColor Gray
Write-Host "by adding new records for investors that already existed." -ForegroundColor Gray
Write-Host ""
