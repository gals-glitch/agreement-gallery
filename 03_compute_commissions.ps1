# ============================================================
# STEP 3: Compute Commissions for Recent Contributions
# ============================================================
# Purpose: Calculate commissions for contributions from last 7 days
# Prerequisites: Feature flag enabled, agreements mapped to correct deals
# Time: 5-10 minutes
# ============================================================

# Configuration
$BASE_URL = "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1"
$SUPABASE_URL = "https://qwgicrdcoqdketqhxbys.supabase.co"

# Check for JWT token
if (-not $env:ADMIN_JWT) {
    Write-Host "❌ ERROR: ADMIN_JWT environment variable not set" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please set your JWT token:" -ForegroundColor Yellow
    Write-Host '  $env:ADMIN_JWT = "your-jwt-token-here"' -ForegroundColor Cyan
    Write-Host ""
    Write-Host "To get your JWT token:" -ForegroundColor Yellow
    Write-Host "  1. Go to http://localhost:8081" -ForegroundColor Cyan
    Write-Host "  2. Sign in as admin" -ForegroundColor Cyan
    Write-Host "  3. Open DevTools (F12) → Console" -ForegroundColor Cyan
    Write-Host "  4. Run: (await supabase.auth.getSession()).data.session.access_token" -ForegroundColor Cyan
    Write-Host "  5. Copy the token and set it above" -ForegroundColor Cyan
    exit 1
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "STEP 3: Compute Commissions for Recent Contributions" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# PART A: Get recent contributions
Write-Host "📊 Fetching contributions from last 7 days..." -ForegroundColor Yellow

$headers = @{
    "Authorization" = "Bearer $env:ADMIN_JWT"
    "apikey" = $env:ADMIN_JWT
    "Content-Type" = "application/json"
}

# Get contributions via Supabase REST API
$contributionsUrl = "$SUPABASE_URL/rest/v1/contributions?select=id,investor_id,deal_id,fund_id,amount,paid_in_date&created_at=gte.$(Get-Date (Get-Date).AddDays(-7) -Format 'yyyy-MM-dd')&order=created_at.desc&limit=50"

try {
    $contributions = Invoke-RestMethod -Uri $contributionsUrl -Headers $headers -Method Get
    Write-Host "✅ Found $($contributions.Count) contributions in last 7 days" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "❌ Failed to fetch contributions: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

if ($contributions.Count -eq 0) {
    Write-Host "⚠️  No contributions found in last 7 days" -ForegroundColor Yellow
    Write-Host "Try extending the date range or check the contributions table" -ForegroundColor Yellow
    exit 0
}

# Display contributions
Write-Host "Recent Contributions:" -ForegroundColor Cyan
$contributions | ForEach-Object {
    Write-Host "  • ID: $($_.id) | Investor: $($_.investor_id) | Deal: $($_.deal_id) | Fund: $($_.fund_id) | Amount: $($_.amount)" -ForegroundColor Gray
}
Write-Host ""

# PART B: Compute commissions
Write-Host "💰 Computing commissions..." -ForegroundColor Yellow
Write-Host ""

$successCount = 0
$errorCount = 0
$skippedCount = 0

foreach ($contribution in $contributions) {
    Write-Host "Processing contribution $($contribution.id)..." -ForegroundColor Gray

    $body = @{
        contribution_id = $contribution.id
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri "$BASE_URL/commissions/compute" -Headers $headers -Method Post -Body $body

        if ($response.data) {
            $commission = $response.data
            Write-Host "  ✅ Commission computed: $($commission.id)" -ForegroundColor Green
            Write-Host "     Party: $($commission.party_name)" -ForegroundColor Gray
            Write-Host "     Base: $($commission.base_amount) | VAT: $($commission.vat_amount) | Total: $($commission.total_amount)" -ForegroundColor Gray
            $successCount++
        } else {
            Write-Host "  ⚠️  No commission computed (no party link or agreement?)" -ForegroundColor Yellow
            $skippedCount++
        }
    } catch {
        Write-Host "  ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
        $errorCount++
    }

    Write-Host ""
}

# Summary
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "✅ Success: $successCount commissions computed" -ForegroundColor Green
Write-Host "⚠️  Skipped: $skippedCount (no party link or agreement)" -ForegroundColor Yellow
Write-Host "❌ Errors: $errorCount" -ForegroundColor Red
Write-Host ""

if ($successCount -gt 0) {
    Write-Host "✅ SUCCESS: Commissions computed for $successCount contributions" -ForegroundColor Green
    Write-Host "Next: Run 04_workflow_test.ps1 to test the approval workflow" -ForegroundColor Cyan
} else {
    Write-Host "⚠️  No commissions computed. Check:" -ForegroundColor Yellow
    Write-Host "  1. Investors have 'introduced_by' party links" -ForegroundColor Gray
    Write-Host "  2. Approved commission agreements exist for those parties" -ForegroundColor Gray
    Write-Host "  3. Agreement scope (deal_id/fund_id) matches contribution scope" -ForegroundColor Gray
}
