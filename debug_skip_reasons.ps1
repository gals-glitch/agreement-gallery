$ErrorActionPreference = "Stop"

if (-not $env:SUPABASE_SERVICE_ROLE_KEY) {
    Write-Host "ERROR: Service role key not set" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $env:SUPABASE_SERVICE_ROLE_KEY"
    "apikey" = $env:SUPABASE_SERVICE_ROLE_KEY
    "Content-Type" = "application/json"
}

Write-Host "DEBUG: Why are contributions skipped?" -ForegroundColor Cyan
Write-Host ""

# Get first contribution
$url = "https://qwgicrdcoqdketqhxbys.supabase.co/rest/v1/contributions?select=id,investor_id&limit=1"
$contrib = (Invoke-RestMethod -Uri $url -Headers $headers)[0]

Write-Host "Testing contribution ID: $($contrib.id)" -ForegroundColor Yellow
Write-Host ""

# Try to compute it
$body = @{ contribution_id = $contrib.id } | ConvertTo-Json
$result = Invoke-RestMethod -Uri "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1/commissions/compute" -Headers $headers -Method Post -Body $body

Write-Host "Result:" -ForegroundColor Cyan
$result | ConvertTo-Json -Depth 10
