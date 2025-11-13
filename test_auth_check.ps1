# ============================================================
# TEST AUTH CHECK ENDPOINT
# ============================================================

$ErrorActionPreference = "Stop"

$BASE_URL = "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1"

# Check for service role key environment variable
if (-not $env:SUPABASE_SERVICE_ROLE_KEY) {
    Write-Host "❌ ERROR: SUPABASE_SERVICE_ROLE_KEY environment variable not set" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please set your service role key:" -ForegroundColor Yellow
    Write-Host '  $env:SUPABASE_SERVICE_ROLE_KEY = "your-service-role-key-here"' -ForegroundColor Cyan
    exit 1
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "TESTING AUTH CHECK ENDPOINT" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: No token
Write-Host "Test 1: No token provided..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/auth/check" -Method Get -ContentType "application/json"
    Write-Host "✅ Response:" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json -Depth 10)
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 2: With service role key in Authorization header
Write-Host "Test 2: Service role key in Authorization header..." -ForegroundColor Yellow
$headers = @{
    "Authorization" = "Bearer $env:SUPABASE_SERVICE_ROLE_KEY"
    "Content-Type" = "application/json"
}
try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/auth/check" -Headers $headers -Method Get
    Write-Host "✅ Response:" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json -Depth 10)
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 3: With service role key in apikey header
Write-Host "Test 3: Service role key in apikey header..." -ForegroundColor Yellow
$headers = @{
    "apikey" = $env:SUPABASE_SERVICE_ROLE_KEY
    "Content-Type" = "application/json"
}
try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/auth/check" -Headers $headers -Method Get
    Write-Host "✅ Response:" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json -Depth 10)
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 4: With both headers (recommended)
Write-Host "Test 4: Service role key in both Authorization and apikey headers..." -ForegroundColor Yellow
$headers = @{
    "Authorization" = "Bearer $env:SUPABASE_SERVICE_ROLE_KEY"
    "apikey" = $env:SUPABASE_SERVICE_ROLE_KEY
    "Content-Type" = "application/json"
}
try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/auth/check" -Headers $headers -Method Get
    Write-Host "✅ Response:" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json -Depth 10)
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "TEST COMPLETE" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
