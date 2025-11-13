# Apply UNIQUE constraint to investors.external_id
# This enables ON CONFLICT upserts in the Vantage sync

$projectUrl = "https://qwgicrdcoqdketqhxbys.supabase.co"
$serviceRoleKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3Z2ljcmRjb3Fka2V0cWh4YnlzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzIyNjMwNywiZXhwIjoyMDcyODAyMzA3fQ.bPUTKQM-tOm1u_1NlVNXczSbA118443uOpeo2Waa2zo"

Write-Host "Applying UNIQUE constraint to investors.external_id..." -ForegroundColor Cyan
Write-Host ""

# Read the SQL from the migration file
$sql = @"
ALTER TABLE investors
ADD CONSTRAINT investors_external_id_unique UNIQUE (external_id);
"@

$body = @{
    query = $sql
} | ConvertTo-Json

$headers = @{
    'apikey' = $serviceRoleKey
    'Authorization' = "Bearer $serviceRoleKey"
    'Content-Type' = 'application/json'
}

try {
    # Execute via PostgREST query endpoint
    $queryUrl = "$projectUrl/rest/v1/rpc/exec_sql"

    # Alternative: Use the Supabase SQL query endpoint
    # First, let's try to query the current constraints
    Write-Host "Checking if constraint already exists..." -ForegroundColor Yellow

    $checkUrl = "$projectUrl/rest/v1/rpc/check_constraint"

    # Since we can't use RPC directly, let's check via information_schema
    $constraintsUrl = "$projectUrl/rest/v1/table_constraints?table_name=eq.investors&constraint_name=eq.investors_external_id_unique&select=constraint_name"

    $existingConstraint = Invoke-RestMethod -Uri $constraintsUrl -Headers $headers

    if ($existingConstraint.Length -gt 0) {
        Write-Host "SUCCESS: Constraint already exists!" -ForegroundColor Green
        Write-Host ""
        exit 0
    }

    Write-Host "Constraint does not exist. Need to apply it manually." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please run this SQL in the Supabase SQL Editor:" -ForegroundColor Cyan
    Write-Host "https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys/sql/new" -ForegroundColor Cyan
    Write-Host ""
    Write-Host $sql -ForegroundColor White
    Write-Host ""
    Write-Host "The SQL has been copied to clipboard." -ForegroundColor Green

    # Copy to clipboard
    $sql | Set-Clipboard

} catch {
    Write-Host "Error checking constraint: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please run this SQL manually in the Supabase SQL Editor:" -ForegroundColor Cyan
    Write-Host "https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys/sql/new" -ForegroundColor Cyan
    Write-Host ""
    Write-Host $sql -ForegroundColor White
    Write-Host ""

    # Copy to clipboard
    $sql | Set-Clipboard
    Write-Host "The SQL has been copied to clipboard." -ForegroundColor Green
}

Write-Host ""
