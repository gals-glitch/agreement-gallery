# Test if commissions endpoints exist
$ErrorActionPreference = "Continue"

$PROJECT_ID = "qwgicrdcoqdketqhxbys"
$BASE_URL = "https://$PROJECT_ID.supabase.co/functions/v1/api-v1"
$JWT = 'eyJhbGciOiJIUzI1NiIsImtpZCI6IjhUL3RGUnFNYmRwWjY4WFkiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL3F3Z2ljcmRjb3Fka2V0cWh4YnlzLnN1cGFiYXNlLmNvL2F1dGgvdjEiLCJzdWIiOiJmYWJiMWUyMS02OTFlLTQwMDUtOGE5ZC02NmZjMzgxMDExYTIiLCJhdWQiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjoxNzYxMTIzNzkxLCJpYXQiOjE3NjExMjAxOTEsImVtYWlsIjoiZ2Fsc0BidWxpZ29jYXBpdGFsLmNvbSIsInBob25lIjoiIiwiYXBwX21ldGFkYXRhIjp7InByb3ZpZGVyIjoiZW1haWwiLCJwcm92aWRlcnMiOlsiZW1haWwiXX0sInVzZXJfbWV0YWRhdGEiOnsiZW1haWxfdmVyaWZpZWQiOnRydWV9LCJyb2xlIjoiYXV0aGVudGljYXRlZCIsImFhbCI6ImFhbDEiLCJhbXIiOlt7Im1ldGhvZCI6InBhc3N3b3JkIiwidGltZXN0YW1wIjoxNzYxMTIwMTkxfV0sInNlc3Npb25faWQiOiIxZTBlYzQwZC1iNGY5LTQzNGItOWRlYi1hMDMxYzMzYzg5ZWUiLCJpc19hbm9ueW1vdXMiOmZhbHNlfQ.0jzCLWjDgZpladJa-MpmJxB4vxArgBxswtlzhIQ14pk'

Write-Host ""
Write-Host "=== Testing Available Endpoints ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: GET /commissions (list)
Write-Host "[Test 1] GET /commissions" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest `
        -Uri "$BASE_URL/commissions" `
        -Method GET `
        -Headers @{
            "Authorization" = "Bearer $JWT"
        } `
        -UseBasicParsing

    Write-Host "✅ GET /commissions works! (Status: $($response.StatusCode))" -ForegroundColor Green
    Write-Host "Response: $($response.Content.Substring(0, [Math]::Min(200, $response.Content.Length)))..." -ForegroundColor Gray
}
catch {
    Write-Host "❌ GET /commissions failed (Status: $($_.Exception.Response.StatusCode.value__))" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd()
        Write-Host "Error: $responseBody" -ForegroundColor Gray
    }
}

Write-Host ""

# Test 2: Check Edge Functions deployment
Write-Host "[Test 2] Checking api-v1 Edge Function deployment" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest `
        -Uri "https://$PROJECT_ID.supabase.co/functions/v1/api-v1" `
        -Method GET `
        -Headers @{
            "Authorization" = "Bearer $JWT"
        } `
        -UseBasicParsing

    Write-Host "✅ api-v1 function is deployed! (Status: $($response.StatusCode))" -ForegroundColor Green
}
catch {
    Write-Host "❌ api-v1 function check failed (Status: $($_.Exception.Response.StatusCode.value__))" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd()
        Write-Host "Error: $responseBody" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "=== Diagnosis ===" -ForegroundColor Cyan
Write-Host "If both tests fail, the Edge Function may not be deployed." -ForegroundColor Yellow
Write-Host "Run: supabase functions deploy api-v1" -ForegroundColor White
Write-Host ""
