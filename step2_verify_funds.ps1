# Step 2 Verification: Quick funds checks

$ErrorActionPreference = "Stop"

# Load environment
if (Test-Path .env) {
    Get-Content .env | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+?)\s*=\s*(.+?)\s*$') {
            [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
        }
    }
}

Write-Host "`n=== Funds Sync Verification ===" -ForegroundColor Cyan

$checks = @"
-- Quick funds checks
SELECT COUNT(*) AS total_funds
FROM public.deals
WHERE external_id IS NOT NULL;

SELECT COUNT(DISTINCT external_id) AS unique_external_ids
FROM public.deals
WHERE external_id IS NOT NULL;

SELECT resource, last_sync_status, records_synced, completed_at
FROM public.vantage_sync_state
WHERE resource='funds'
ORDER BY completed_at DESC
LIMIT 3;
"@

Write-Host "`nSQL Verification Queries:" -ForegroundColor Yellow
Write-Host $checks

$checks | Set-Clipboard
Write-Host "`n✓ Queries copied to clipboard" -ForegroundColor Green
Write-Host "Run these in Supabase SQL Editor to verify:" -ForegroundColor Cyan
Write-Host "  1. Total funds with external_id" -ForegroundColor White
Write-Host "  2. Unique external_ids (should match total)" -ForegroundColor White
Write-Host "  3. Recent sync history for 'funds' resource" -ForegroundColor White
Write-Host "`nExpected results:" -ForegroundColor Yellow
Write-Host "  - total_funds > 0" -ForegroundColor White
Write-Host "  - total_funds = unique_external_ids (no duplicates)" -ForegroundColor White
Write-Host "  - last_sync_status = 'success'" -ForegroundColor White
