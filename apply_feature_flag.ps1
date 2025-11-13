# PowerShell script to copy feature flag SQL to clipboard

$sql = Get-Content "add_commissions_feature_flag.sql" -Raw
Set-Clipboard -Value $sql

Write-Host ""
Write-Host "✅ Feature flag SQL copied to clipboard!" -ForegroundColor Green
Write-Host ""
Write-Host "Run this in Supabase SQL Editor:" -ForegroundColor Cyan
Write-Host "https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys/sql/new" -ForegroundColor Yellow
Write-Host ""
Write-Host "Expected output: 1 row with commissions_engine enabled for [admin, finance]" -ForegroundColor White
Write-Host ""
