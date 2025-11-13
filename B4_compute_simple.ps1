# Simple version - compute commissions for specific contribution IDs we know are ready

$ErrorActionPreference = "Stop"

$BASE_URL = "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1"
$SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3Z2ljcmRjb3Fka2V0cWh4YnlzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcyMjYzMDcsImV4cCI6MjA3MjgwMjMwN30.6PZnjAcRXYcd_sNZHb6ZDxyg914JMtkCtqIYvHt3P1Y"

Write-Host "Computing commissions for contributions with agreements..." -ForegroundColor Cyan

$headers = @{
    "apikey" = $SUPABASE_ANON_KEY
    "Authorization" = "Bearer $SUPABASE_ANON_KEY"
    "Content-Type" = "application/json"
}

# These contribution IDs have matching party+agreement (from our earlier SQL query)
$contributionIds = @(5, 9, 11, 16, 23, 76, 112, 114)

Write-Host "Processing $($contributionIds.Count) contributions..." -ForegroundColor Yellow
Write-Host ""

$successCount = 0
$errorCount = 0

foreach ($contribId in $contributionIds) {
    Write-Host "Processing contribution $contribId..." -ForegroundColor Gray

    $body = @{
        contribution_id = $contribId
    } | ConvertTo-Json

    try {
        $result = Invoke-RestMethod -Uri "$BASE_URL/commissions/compute" -Headers $headers -Method Post -Body $body

        if ($result.data) {
            Write-Host "  ✅ Success: Commission ID $($result.data.id)" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host "  ⚠️  No commission created" -ForegroundColor Yellow
        }
    } catch {
        $errorMsg = $_.Exception.Message
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            Write-Host "  ❌ Error: $responseBody" -ForegroundColor Red
        } else {
            Write-Host "  ❌ Error: $errorMsg" -ForegroundColor Red
        }
        $errorCount++
    }
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "✅ Success: $successCount" -ForegroundColor Green
Write-Host "❌ Errors: $errorCount" -ForegroundColor Red
