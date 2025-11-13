if (-not $env:SUPABASE_SERVICE_ROLE_KEY) {
    Write-Host "Run .\set_key.ps1 first" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $env:SUPABASE_SERVICE_ROLE_KEY"
    "apikey" = $env:SUPABASE_SERVICE_ROLE_KEY
    "Content-Type" = "application/json"
}

Write-Host "Getting 3 contributions..." -ForegroundColor Cyan
$url = "https://qwgicrdcoqdketqhxbys.supabase.co/rest/v1/contributions?select=id&limit=3"
$contribs = Invoke-RestMethod -Uri $url -Headers $headers
$ids = $contribs | ForEach-Object { $_.id }

Write-Host "Contribution IDs: $($ids -join ', ')" -ForegroundColor Gray
Write-Host ""

Write-Host "Computing commissions..." -ForegroundColor Cyan
$body = @{ contribution_ids = $ids } | ConvertTo-Json
$result = Invoke-RestMethod -Uri "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1/commissions/batch-compute" -Headers $headers -Method Post -Body $body

Write-Host "RAW RESPONSE:" -ForegroundColor Yellow
$result | ConvertTo-Json -Depth 10
