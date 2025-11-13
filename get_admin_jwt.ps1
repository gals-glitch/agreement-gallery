# ============================================================================
# Get Admin JWT Token via Supabase Auth API
# ============================================================================

$ErrorActionPreference = "Stop"

$PROJECT_ID = "qwgicrdcoqdketqhxbys"
$SUPABASE_URL = "https://$PROJECT_ID.supabase.co"

Write-Host ""
Write-Host "=== GET ADMIN JWT TOKEN ===" -ForegroundColor Cyan
Write-Host ""

# Prompt for credentials
$email = Read-Host "Enter your admin email"
$password = Read-Host "Enter your password" -AsSecureString
$passwordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
)

Write-Host ""
Write-Host "Signing in to Supabase..." -ForegroundColor Yellow

try {
    $signInBody = @{
        email = $email
        password = $passwordPlain
    } | ConvertTo-Json

    $response = Invoke-RestMethod `
        -Uri "$SUPABASE_URL/auth/v1/token?grant_type=password" `
        -Method POST `
        -Headers @{
            "Content-Type" = "application/json"
            "apikey" = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3Z2ljcmRjb3Fka2V0cWh4YnlzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mjk0MTcxNzAsImV4cCI6MjA0NDk5MzE3MH0.VH5k7bG5SQ8C0xCJqS-VLDYUqYEoQxGPSFPKj9gF3cE"
        } `
        -Body $signInBody

    $jwt = $response.access_token

    Write-Host ""
    Write-Host "✅ Successfully signed in!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your JWT Token:" -ForegroundColor Cyan
    Write-Host $jwt -ForegroundColor White
    Write-Host ""

    # Set environment variable
    $env:ADMIN_JWT = $jwt

    Write-Host "✅ Token saved to `$env:ADMIN_JWT" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now run: .\test_phase1_api.ps1" -ForegroundColor Yellow
    Write-Host ""
}
catch {
    Write-Host ""
    Write-Host "❌ Sign in failed" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please check:" -ForegroundColor Yellow
    Write-Host "  - Email and password are correct" -ForegroundColor White
    Write-Host "  - User has admin role in Supabase" -ForegroundColor White
    Write-Host ""
    exit 1
}
