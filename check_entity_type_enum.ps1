# Check valid entity_type enum values

$projectUrl = "https://qwgicrdcoqdketqhxbys.supabase.co"
$serviceRoleKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3Z2ljcmRjb3Fka2V0cWh4YnlzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzIyNjMwNywiZXhwIjoyMDcyODAyMzA3fQ.bPUTKQM-tOm1u_1NlVNXczSbA118443uOpeo2Waa2zo"

Write-Host "Checking entity_type enum values..." -ForegroundColor Cyan
Write-Host ""

# Query to get enum values
$query = @"
SELECT unnest(enum_range(NULL::entity_type))::text AS entity_type_value
"@

$body = @{
    query = $query
} | ConvertTo-Json

$headers = @{
    'apikey' = $serviceRoleKey
    'Authorization' = "Bearer $serviceRoleKey"
    'Content-Type' = 'application/json'
}

try {
    # Use rpc endpoint if available, otherwise try direct query
    Write-Host "Querying database..." -ForegroundColor Yellow

    # Alternative: Just check existing entities to see what values are used
    $entitiesUrl = "$projectUrl/rest/v1/entities?select=entity_type&limit=10"
    $entities = Invoke-RestMethod -Uri $entitiesUrl -Headers $headers

    Write-Host ""
    Write-Host "Sample entity_type values from existing entities:" -ForegroundColor Green
    $uniqueTypes = $entities | Select-Object -ExpandProperty entity_type -Unique
    foreach ($type in $uniqueTypes) {
        Write-Host "  - $type" -ForegroundColor White
    }

    Write-Host ""
    Write-Host "Use one of these values in the sync code." -ForegroundColor Cyan

} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
