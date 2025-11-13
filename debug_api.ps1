# Debug API call to see full error
$ErrorActionPreference = "Continue"

$PROJECT_ID = "qwgicrdcoqdketqhxbys"
$BASE_URL = "https://$PROJECT_ID.supabase.co/functions/v1/api-v1"
$JWT = 'eyJhbGciOiJIUzI1NiIsImtpZCI6IjhUL3RGUnFNYmRwWjY4WFkiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL3F3Z2ljcmRjb3Fka2V0cWh4YnlzLnN1cGFiYXNlLmNvL2F1dGgvdjEiLCJzdWIiOiJmYWJiMWUyMS02OTFlLTQwMDUtOGE5ZC02NmZjMzgxMDExYTIiLCJhdWQiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjoxNzYxMTIzNzkxLCJpYXQiOjE3NjExMjAxOTEsImVtYWlsIjoiZ2Fsc0BidWxpZ29jYXBpdGFsLmNvbSIsInBob25lIjoiIiwiYXBwX21ldGFkYXRhIjp7InByb3ZpZGVyIjoiZW1haWwiLCJwcm92aWRlcnMiOlsiZW1haWwiXX0sInVzZXJfbWV0YWRhdGEiOnsiZW1haWxfdmVyaWZpZWQiOnRydWV9LCJyb2xlIjoiYXV0aGVudGljYXRlZCIsImFhbCI6ImFhbDEiLCJhbXIiOlt7Im1ldGhvZCI6InBhc3N3b3JkIiwidGltZXN0YW1wIjoxNzYxMTIwMTkxfV0sInNlc3Npb25faWQiOiIxZTBlYzQwZC1iNGY5LTQzNGItOWRlYi1hMDMxYzMzYzg5ZWUiLCJpc19hbm9ueW1vdXMiOmZhbHNlfQ.0jzCLWjDgZpladJa-MpmJxB4vxArgBxswtlzhIQ14pk'

Write-Host ""
Write-Host "=== DEBUG: Commission Compute API ===" -ForegroundColor Cyan
Write-Host ""

$body = @{
    contribution_id = 3
} | ConvertTo-Json

Write-Host "Request Body:" -ForegroundColor Yellow
Write-Host $body
Write-Host ""

try {
    $response = Invoke-WebRequest `
        -Uri "$BASE_URL/commissions/compute" `
        -Method POST `
        -Headers @{
            "Authorization" = "Bearer $JWT"
            "Content-Type" = "application/json"
        } `
        -Body $body `
        -UseBasicParsing

    Write-Host "✅ Success!" -ForegroundColor Green
    Write-Host "Response:" -ForegroundColor Cyan
    Write-Host $response.Content
}
catch {
    Write-Host "❌ Error Response:" -ForegroundColor Red
    Write-Host "Status Code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Yellow
    Write-Host "Status Description: $($_.Exception.Response.StatusDescription)" -ForegroundColor Yellow

    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd()

        Write-Host ""
        Write-Host "Full Error Response Body:" -ForegroundColor Yellow
        Write-Host $responseBody -ForegroundColor White
    }
}
