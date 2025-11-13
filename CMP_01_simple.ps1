$ErrorActionPreference = "Stop"
$BASE_URL = "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1"
$SUPABASE_URL = "https://qwgicrdcoqdketqhxbys.supabase.co"

if (-not $env:SUPABASE_SERVICE_ROLE_KEY) {
    Write-Host "ERROR: Service role key not set" -ForegroundColor Red
    exit 1
}

Write-Host "CMP-01: BATCH COMPUTE" -ForegroundColor Cyan
Write-Host ""

$headers = @{
    "Authorization" = "Bearer $env:SUPABASE_SERVICE_ROLE_KEY"
    "apikey" = $env:SUPABASE_SERVICE_ROLE_KEY
    "Content-Type" = "application/json"
}

Write-Host "Finding contributions..." -ForegroundColor Yellow
$url = "$SUPABASE_URL/rest/v1/contributions?select=id,amount&limit=100"
$contributions = Invoke-RestMethod -Uri $url -Headers $headers
Write-Host "Found $($contributions.Count) contributions" -ForegroundColor Green
Write-Host ""

if ($contributions.Count -eq 0) {
    Write-Host "No contributions found" -ForegroundColor Yellow
    exit 0
}

Write-Host "Computing commissions..." -ForegroundColor Yellow
$ids = $contributions | ForEach-Object { $_.id }
$body = @{ contribution_ids = $ids } | ConvertTo-Json
$result = Invoke-RestMethod -Uri "$BASE_URL/commissions/batch-compute" -Headers $headers -Method Post -Body $body

Write-Host "Batch compute completed!" -ForegroundColor Green
Write-Host "Total processed: $($result.count)" -ForegroundColor Green
Write-Host ""

$successCount = 0
$errorCount = 0
foreach ($item in $result.results) {
    if ($item.status -eq "error") {
        $errorCount++
        Write-Host "  Error: $($item.error)" -ForegroundColor Yellow
    } else {
        $successCount++
        Write-Host "  Success: Commission $($item.commission_id) - $($item.status)" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "Success: $successCount" -ForegroundColor Green
Write-Host "Errors: $errorCount" -ForegroundColor Yellow
