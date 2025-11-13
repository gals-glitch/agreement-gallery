# PowerShell script to copy commissions migration to clipboard for Supabase SQL Editor
# Run this, then paste into: https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys/sql/new

$migrationPath = "supabase\migrations\20251022000001_commissions_schema.sql"
$content = Get-Content $migrationPath -Raw

Set-Clipboard -Value $content

Write-Host ""
Write-Host "✅ Migration SQL copied to clipboard!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Open Supabase SQL Editor:" -ForegroundColor White
Write-Host "   https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys/sql/new" -ForegroundColor Yellow
Write-Host ""
Write-Host "2. Paste the SQL (Ctrl+V)" -ForegroundColor White
Write-Host ""
Write-Host "3. Click 'Run' to execute the migration" -ForegroundColor White
Write-Host ""
Write-Host "4. Verify success - you should see:" -ForegroundColor White
Write-Host "   - commissions table created" -ForegroundColor Gray
Write-Host "   - 8 indexes created" -ForegroundColor Gray
Write-Host "   - 4 RLS policies created" -ForegroundColor Gray
Write-Host "   - commissions_summary view created" -ForegroundColor Gray
Write-Host ""
