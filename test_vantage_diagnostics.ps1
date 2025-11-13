# Test Vantage Sync Diagnostics
# Run with: powershell -ExecutionPolicy Bypass -File test_vantage_diagnostics.ps1

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
        Write-Host "✓ All environment variables are configured!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next step: Run test_vantage_sync.ps1" -ForegroundColor Cyan
    } else {
        Write-Host "✗ Configuration issues detected" -ForegroundColor Red
        Write-Host ""
        Write-Host "ACTION REQUIRED:" -ForegroundColor Yellow
        Write-Host "1. Go to: https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys/settings/functions" -ForegroundColor White
        Write-Host "2. Click 'Add new secret' for each missing variable:" -ForegroundColor White
        Write-Host ""
        Write-Host "   Name: VANTAGE_API_BASE_URL" -ForegroundColor Cyan
        Write-Host "   Value: https://buligoirapi.insightportal.info" -ForegroundColor White
        Write-Host ""
        Write-Host "   Name: VANTAGE_AUTH_TOKEN" -ForegroundColor Cyan
        Write-Host "   Value: buligodata" -ForegroundColor White
        Write-Host ""
        Write-Host "   Name: VANTAGE_CLIENT_ID" -ForegroundColor Cyan
        Write-Host "   Value: bexz40aUdxK5rQDSjS2BIUg==" -ForegroundColor White
        Write-Host ""
        Write-Host "3. After adding secrets, re-run this diagnostic" -ForegroundColor White
    }

} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    Write-Host "Response: $($_.Exception.Response)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "This might indicate the function failed to deploy." -ForegroundColor Yellow
    Write-Host "Check deployment status with: supabase functions list" -ForegroundColor Cyan
}

Write-Host ""
