# Verify Vantage sync results
$projectUrl = "https://qwgicrdcoqdketqhxbys.supabase.co"
$serviceRoleKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3Z2ljcmRjb3Fka2V0cWh4YnlzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzIyNjMwNywiZXhwIjoyMDcyODAyMzA3fQ.bPUTKQM-tOm1u_1NlVNXczSbA118443uOpeo2Waa2zo"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Vantage Sync - Results Verification" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$headers = @{
    'apikey' = $serviceRoleKey
    'Authorization' = "Bearer $serviceRoleKey"
    'Content-Type' = 'application/json'
    'Prefer' = 'return=representation'
}

# Count investors by source
Write-Host "Investors by source_kind:" -ForegroundColor Yellow
$url = "$projectUrl/rest/v1/investors?select=source_kind&source_kind=not.is.null"
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

# Total investor count
Write-Host "Total investor count:" -ForegroundColor Yellow
$url = "$projectUrl/rest/v1/investors?select=count"
$headers['Prefer'] = 'count=exact'
try {
    $response = Invoke-WebRequest -Uri $url -Headers $headers -Method Head
    $count = $response.Headers['Content-Range'][0] -replace '.*/', ''
    Write-Host "  Total: $count investors" -ForegroundColor White
    Write-Host ""
} catch {
    Write-Host "  Error: $_" -ForegroundColor Red
}

# Sample Vantage investors
Write-Host "Sample Vantage investors (first 5):" -ForegroundColor Yellow
$headers['Prefer'] = 'return=representation'
$url = "$projectUrl/rest/v1/investors?select=id,name,external_id,source_kind,created_at&source_kind=eq.vantage&limit=5&order=created_at.desc"
try {
    $sample = Invoke-RestMethod -Uri $url -Headers $headers
    $sample | Format-Table -Property id, name, external_id, source_kind -AutoSize
} catch {
    Write-Host "  Error: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "Verification complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
