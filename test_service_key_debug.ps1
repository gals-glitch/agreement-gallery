# Debug script to check service key configuration

$SERVICE_KEY = "wxcNeAskSi7lJCjF4uLQ3RfbBZMpIzgr"
$SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3Z2ljcmRjb3Fka2V0cWh4YnlzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzIyNjMwNywiZXhwIjoyMDcyODAyMzA3fQ.bPUTKQM-tOm1u_1NlVNXczSbA118443uOpeo2Waa2zo"
$API_URL = "https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1"

Write-Host "Debugging service key authentication..." -ForegroundColor Cyan
Write-Host ""

# Test 1: Check if health endpoint works
Write-Host "Test 1: Basic health check (no auth)" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$API_URL/health" -Method Get
    Write-Host "✅ Health endpoint works: $($response.status)" -ForegroundColor Green
} catch {
    Write-Host "❌ Health endpoint failed" -ForegroundColor Red
}

Write-Host ""

# Test 2: Try service key header only
Write-Host "Test 2: Service key header only (should fail)" -ForegroundColor Yellow
$headers1 = @{
    "x-service-key" = $SERVICE_KEY
    "Content-Type" = "application/json"
}

try {
    $body = @{ contribution_id = 1 } | ConvertTo-Json
    $response = Invoke-RestMethod -Uri "$API_URL/charges/compute" -Method Post -Headers $headers1 -Body $body
    Write-Host "✅ Unexpected success" -ForegroundColor Yellow
} catch {
    Write-Host "❌ Expected failure: $($_.Exception.Message)" -ForegroundColor Gray
}

Write-Host ""

# Test 3: Try service role key only (no x-service-key)
Write-Host "Test 3: Service role key only (Authorization header)" -ForegroundColor Yellow
$headers2 = @{
    "Authorization" = "Bearer $SERVICE_ROLE_KEY"
    "Content-Type" = "application/json"
    "apikey" = $SERVICE_ROLE_KEY
}

try {
    $body = @{ contribution_id = 1 } | ConvertTo-Json
    $response = Invoke-RestMethod -Uri "$API_URL/charges/compute" -Method Post -Headers $headers2 -Body $body
    Write-Host "✅ Works with service role key!" -ForegroundColor Green
    Write-Host "Response: $($response | ConvertTo-Json -Depth 2)" -ForegroundColor White
} catch {
    Write-Host "❌ Failed: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red

    $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
    $errorBody = $reader.ReadToEnd()
    Write-Host "Error: $errorBody" -ForegroundColor Red
}

Write-Host ""

# Test 4: Try both headers together
Write-Host "Test 4: Both Authorization + x-service-key" -ForegroundColor Yellow
$headers3 = @{
    "Authorization" = "Bearer $SERVICE_ROLE_KEY"
    "x-service-key" = $SERVICE_KEY
    "Content-Type" = "application/json"
    "apikey" = $SERVICE_ROLE_KEY
}

try {
    $body = @{ contribution_id = 1 } | ConvertTo-Json
    $response = Invoke-RestMethod -Uri "$API_URL/charges/compute" -Method Post -Headers $headers3 -Body $body
    Write-Host "✅ Works with both headers!" -ForegroundColor Green
    Write-Host "Response: $($response | ConvertTo-Json -Depth 2)" -ForegroundColor White
} catch {
    Write-Host "❌ Failed: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red

    $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
    $errorBody = $reader.ReadToEnd()
    Write-Host "Error: $errorBody" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Recommendation:" -ForegroundColor Yellow
Write-Host "Use service role key as Authorization header" -ForegroundColor White
Write-Host "The x-service-key is for future internal job auth" -ForegroundColor Gray
