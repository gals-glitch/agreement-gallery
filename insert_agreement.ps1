# Execute SQL via Supabase PostgREST API
$SUPABASE_URL = "https://qwgicrdcoqdketqhxbys.supabase.co"

# Get service role key from environment or prompt
$SERVICE_ROLE_KEY = $env:SUPABASE_SERVICE_ROLE_KEY

if (-not $SERVICE_ROLE_KEY) {
    Write-Host "Enter your Supabase Service Role Key (from Settings > API):" -ForegroundColor Yellow
    $SERVICE_ROLE_KEY = Read-Host -AsSecureString | ConvertFrom-SecureString -AsPlainText

    if (-not $SERVICE_ROLE_KEY) {
        Write-Host "ERROR: Service role key is required" -ForegroundColor Red
        exit 1
    }
}

# Create the agreement via direct table insert
$body = @{
    party_id = 201
    fund_id = $null
    deal_id = 1
    status = "APPROVED"
    scope = "DEAL"
    pricing_mode = "CUSTOM"
    vat_included = $false
    effective_from = "2024-01-01"
    effective_to = $null
} | ConvertTo-Json

$headers = @{
    "apikey" = $SERVICE_ROLE_KEY
    "Authorization" = "Bearer $SERVICE_ROLE_KEY"
    "Content-Type" = "application/json"
    "Prefer" = "return=representation"
}

try {
    Write-Host "Creating agreement for investor 201, deal 1..." -ForegroundColor Cyan

    $response = Invoke-RestMethod -Uri "$SUPABASE_URL/rest/v1/agreements" `
        -Method POST `
        -Headers $headers `
        -Body $body

    Write-Host "`nSUCCESS! Agreement created:" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 10 | Write-Host

} catch {
    Write-Host "`nERROR! Status: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
}
