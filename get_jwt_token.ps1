# ============================================================================
# GET JWT TOKEN FOR API TESTING
# ============================================================================
# This script helps you get a JWT token from the browser for API testing
# ============================================================================

Write-Host ""
Write-Host "=== GET JWT TOKEN FOR API TESTING ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Follow these steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Open your browser and go to: http://localhost:8081" -ForegroundColor White
Write-Host "2. Sign in with your admin account" -ForegroundColor White
Write-Host "3. Open Developer Tools (F12)" -ForegroundColor White
Write-Host "4. Go to Console tab" -ForegroundColor White
Write-Host "5. Paste this command and press Enter:" -ForegroundColor White
Write-Host ""
Write-Host "   (await supabase.auth.getSession()).data.session.access_token" -ForegroundColor Cyan
Write-Host ""
Write-Host "   OR if that doesn't work:" -ForegroundColor Gray
Write-Host ""
Write-Host "   localStorage.getItem('sb-qwgicrdcoqdketqhxbys-auth-token')" -ForegroundColor Cyan
Write-Host ""
Write-Host "6. Copy the token (long string)" -ForegroundColor White
Write-Host "7. Paste it below when prompted" -ForegroundColor White
Write-Host ""

$token = Read-Host "Paste your JWT token here"

if ($token) {
    # Set environment variable for current session
    $env:ADMIN_JWT = $token

    Write-Host ""
    Write-Host "✅ Token saved to `$env:ADMIN_JWT for this session!" -ForegroundColor Green
    Write-Host ""
    Write-Host "To use in scripts:" -ForegroundColor Yellow
    Write-Host '  $ADMIN_JWT = $env:ADMIN_JWT' -ForegroundColor White
    Write-Host ""
    Write-Host "To make permanent (optional):" -ForegroundColor Yellow
    Write-Host "  [System.Environment]::SetEnvironmentVariable('ADMIN_JWT','$token','User')" -ForegroundColor White
    Write-Host ""
    Write-Host "Now you can run: .\test_api_commissions_smoke.ps1" -ForegroundColor Cyan
    Write-Host ""
}
else {
    Write-Host "❌ No token provided" -ForegroundColor Red
}
