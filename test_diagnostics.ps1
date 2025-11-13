# Test Vantage Sync Diagnostics

Write-Host "Running Vantage Sync Diagnostics..." -ForegroundColor Cyan
Write-Host ""

$serviceRoleKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3Z2ljcmRjb3Fka2V0cWh4YnlzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzIyNjMwNywiZXhwIjoyMDcyODAyMzA3fQ.bPUTKQM-tOm1u_1NlVNXczSbA118443uOpeo2Waa2zo"

$headers = @{
    'Authorization' = "Bearer $serviceRoleKey"
    'apikey' = $serviceRoleKey
    'Content-Type' = 'application/json'
}

$url = "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/vantage-sync-diagnostics"

try {
    Write-Host "Testing environment configuration..." -ForegroundColor Yellow
    $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers

    Write-Host ""
    Write-Host "=== DIAGNOSTICS REPORT ===" -ForegroundColor Cyan
    Write-Host ($response | ConvertTo-Json -Depth 10)
    Write-Host ""

    if ($response.status -eq 'ok') {
        Write-Host "SUCCESS: All environment variables are configured!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next step: Run test_vantage_sync.ps1" -ForegroundColor Cyan
    } else {
        Write-Host "ISSUE: Configuration problems detected" -ForegroundColor Red
        Write-Host ""
        Write-Host "ACTION REQUIRED:" -ForegroundColor Yellow
        Write-Host "1. Go to Supabase Dashboard > Settings > Edge Functions" -ForegroundColor White
        Write-Host "2. Add these secrets:" -ForegroundColor White
        Write-Host "   - VANTAGE_API_BASE_URL = https://buligoirapi.insightportal.info" -ForegroundColor White
        Write-Host "   - VANTAGE_AUTH_TOKEN = buligodata" -ForegroundColor White
        Write-Host "   - VANTAGE_CLIENT_ID = bexz40aUdxK5rQDSjS2BIUg==" -ForegroundColor White
    }

} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "This might indicate the function failed to deploy or environment issues." -ForegroundColor Yellow
}

Write-Host ""
