# Check all constraints on investors table
$projectUrl = "https://qwgicrdcoqdketqhxbys.supabase.co"
$serviceRoleKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3Z2ljcmRjb3Fka2V0cWh4YnlzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzIyNjMwNywiZXhwIjoyMDcyODAyMzA3fQ.bPUTKQM-tOm1u_1NlVNXczSbA118443uOpeo2Waa2zo"

Write-Host "Checking constraints on investors table..." -ForegroundColor Cyan
Write-Host ""

$headers = @{
    'apikey' = $serviceRoleKey
    'Authorization' = "Bearer $serviceRoleKey"
    'Content-Type' = 'application/json'
}

$sql = @"
SELECT
    constraint_name,
    constraint_type,
    column_name
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'investors'
ORDER BY constraint_type, constraint_name;
"@

$body = @{
    query = $sql
} | ConvertTo-Json

try {
    $url = "$projectUrl/rest/v1/rpc/exec_sql"
    $result = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body

    Write-Host "Constraints:" -ForegroundColor Yellow
    $result | Format-Table -AutoSize

    Write-Host ""
    Write-Host "Checking for duplicate names in Vantage data..." -ForegroundColor Cyan

    # Copy SQL to clipboard to check for duplicates
    $checkDuplicatesSQL = @"
-- Check if there are investors with duplicate names
SELECT name, COUNT(*) as count
FROM investors
WHERE name IS NOT NULL
GROUP BY name
HAVING COUNT(*) > 1
ORDER BY count DESC
LIMIT 10;
"@

    $checkDuplicatesSQL | Set-Clipboard
    Write-Host "SQL to check for duplicate names has been copied to clipboard" -ForegroundColor Green
    Write-Host ""

} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}
