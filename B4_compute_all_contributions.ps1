# ============================================================
# COMPUTE COMMISSIONS FOR ALL CONTRIBUTIONS
# ============================================================

$ErrorActionPreference = "Stop"

$BASE_URL = "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1"

# Check for service role key environment variable
if (-not $env:SUPABASE_SERVICE_ROLE_KEY) {
    Write-Host "❌ ERROR: SUPABASE_SERVICE_ROLE_KEY environment variable not set" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please set your service role key:" -ForegroundColor Yellow
    Write-Host '  $env:SUPABASE_SERVICE_ROLE_KEY = "your-service-role-key-here"' -ForegroundColor Cyan
    Write-Host ""
    Write-Host "To get your service role key:" -ForegroundColor Yellow
    Write-Host "  1. Go to Supabase Dashboard > Settings > API" -ForegroundColor Cyan
    Write-Host "  2. Copy the service_role key (keep it secret!)" -ForegroundColor Cyan
    Write-Host "  3. Set it as an environment variable" -ForegroundColor Cyan
    exit 1
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "COMPUTE COMMISSIONS FOR ALL CONTRIBUTIONS" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$headers = @{
    "Authorization" = "Bearer $env:SUPABASE_SERVICE_ROLE_KEY"
    "apikey" = $env:SUPABASE_SERVICE_ROLE_KEY
    "Content-Type" = "application/json"
}

# Get contribution IDs that have investor→party links
Write-Host "Fetching contributions with party links..." -ForegroundColor Yellow

$query = @"
SELECT
  c.id,
  i.name as investor_name,
  d.name as deal_name,
  c.amount
FROM contributions c
JOIN investors i ON c.investor_id = i.id
JOIN deals d ON c.deal_id = d.id
WHERE i.introduced_by_party_id IS NOT NULL
ORDER BY c.id
LIMIT 50
"@

try {
    $supabaseUrl = "https://qwgicrdcoqdketqhxbys.supabase.co"
    $response = Invoke-RestMethod -Uri "$supabaseUrl/rest/v1/rpc/exec_sql" -Headers $headers -Method Post -Body (@{query=$query} | ConvertTo-Json)

    Write-Host "Note: If exec_sql doesn't exist, we'll fetch via REST API instead" -ForegroundColor Yellow
} catch {
    Write-Host "SQL RPC not available, using REST API..." -ForegroundColor Yellow

    # Fetch via REST API with joins
    $url = "$supabaseUrl/rest/v1/contributions?select=id,amount,investor:investors!inner(name,introduced_by_party_id),deal:deals(name)&investor.introduced_by_party_id=not.is.null&limit=50"
    $contributions = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
}

if ($contributions.Count -eq 0) {
    Write-Host "No contributions found with investor→party links" -ForegroundColor Red
    exit 0
}

Write-Host "Found $($contributions.Count) contributions to process" -ForegroundColor Green
Write-Host ""

# Compute commissions
$successCount = 0
$errorCount = 0
$skippedCount = 0

foreach ($contribution in $contributions) {
    $contribId = $contribution.id
    Write-Host "Processing contribution $contribId..." -ForegroundColor Gray

    $body = @{
        contribution_id = $contribId
    } | ConvertTo-Json

    try {
        $result = Invoke-RestMethod -Uri "$BASE_URL/commissions/compute" -Headers $headers -Method Post -Body $body

        if ($result.data) {
            $commission = $result.data
            Write-Host "  ✅ Commission computed: $($commission.id)" -ForegroundColor Green
            Write-Host "     Base: $($commission.base_amount) | Total: $($commission.total_amount)" -ForegroundColor Gray
            $successCount++
        } else {
            Write-Host "  ⚠️  No commission computed" -ForegroundColor Yellow
            $skippedCount++
        }
    } catch {
        Write-Host "  ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
        $errorCount++
    }
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "✅ Success: $successCount" -ForegroundColor Green
Write-Host "⚠️  Skipped: $skippedCount" -ForegroundColor Yellow
Write-Host "❌ Errors: $errorCount" -ForegroundColor Red
