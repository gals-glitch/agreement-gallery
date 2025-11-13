if (-not $env:SUPABASE_SERVICE_ROLE_KEY) {
    Write-Host "Run .\set_key.ps1 first" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $env:SUPABASE_SERVICE_ROLE_KEY"
    "apikey" = $env:SUPABASE_SERVICE_ROLE_KEY
}

$url = "https://qwgicrdcoqdketqhxbys.supabase.co/rest/v1/investors?select=id,name,introduced_by,introduced_by_party_id&limit=1"
$result = Invoke-RestMethod -Uri $url -Headers $headers

Write-Host "Investor columns check:" -ForegroundColor Cyan
$result | ConvertTo-Json -Depth 3
