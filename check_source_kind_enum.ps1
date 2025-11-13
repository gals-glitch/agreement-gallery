# Check valid investor_source_kind enum values

$projectUrl = "https://qwgicrdcoqdketqhxbys.supabase.co"
$serviceRoleKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3Z2ljcmRjb3Fka2V0cWh4YnlzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzIyNjMwNywiZXhwIjoyMDcyODAyMzA3fQ.bPUTKQM-tOm1u_1NlVNXczSbA118443uOpeo2Waa2zo"

Write-Host "Checking investor_source_kind enum values..." -ForegroundColor Cyan
Write-Host ""

$headers = @{
    'apikey' = $serviceRoleKey
    'Authorization' = "Bearer $serviceRoleKey"
    'Content-Type' = 'application/json'
}

# Check existing investors to see what source_kind values are used
$investorsUrl = "$projectUrl/rest/v1/investors?select=source_kind&limit=100"

try {
    $investors = Invoke-RestMethod -Uri $investorsUrl -Headers $headers

    Write-Host "Sample source_kind values from existing investors:" -ForegroundColor Green
    $uniqueKinds = $investors | Select-Object -ExpandProperty source_kind -Unique | Where-Object { $_ -ne $null }

    if ($uniqueKinds.Count -gt 0) {
        foreach ($kind in $uniqueKinds) {
            Write-Host "  - $kind" -ForegroundColor White
        }
    } else {
        Write-Host "  (No source_kind values found in existing investors)" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "Try using one of these values, or add 'vantage' to the enum." -ForegroundColor Cyan

} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
