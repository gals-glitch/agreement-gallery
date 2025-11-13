if (-not $env:SUPABASE_SERVICE_ROLE_KEY) {
    Write-Host "Run .\set_key.ps1 first" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $env:SUPABASE_SERVICE_ROLE_KEY"
    "apikey" = $env:SUPABASE_SERVICE_ROLE_KEY
}

$base = "https://qwgicrdcoqdketqhxbys.supabase.co/rest/v1"

Write-Host "COMMISSION STATUS CHECK" -ForegroundColor Cyan
Write-Host ""

# Get all draft commissions
Write-Host "Draft commissions:" -ForegroundColor Yellow
$url = "$base/commissions?select=id,party_id,investor_id,status,base_amount,vat_amount,total_amount,parties(name),investors(name)&status=eq.draft&order=id"
$drafts = Invoke-RestMethod -Uri $url -Headers $headers

if ($drafts.Count -eq 0) {
    Write-Host "  No draft commissions found" -ForegroundColor Red
} else {
    Write-Host "  Found: $($drafts.Count) draft commissions" -ForegroundColor Green
    Write-Host ""
    foreach ($comm in $drafts) {
        $partyName = if ($comm.parties) { $comm.parties.name } else { "Unknown" }
        $investorName = if ($comm.investors) { $comm.investors.name } else { "Unknown" }
        Write-Host "  ID: $($comm.id)" -ForegroundColor Cyan
        Write-Host "    Investor: $investorName" -ForegroundColor Gray
        Write-Host "    Party: $partyName" -ForegroundColor Gray
        Write-Host "    Amount: $($comm.base_amount) + VAT $($comm.vat_amount) = $($comm.total_amount)" -ForegroundColor Gray
        Write-Host ""
    }
}

Write-Host "READY FOR WORKFLOW TEST:" -ForegroundColor Cyan
if ($drafts.Count -gt 0) {
    Write-Host "  YES - Pick one commission ID from above to test submit -> approve -> mark-paid" -ForegroundColor Green
    Write-Host "  Example: Use ID $($drafts[0].id)" -ForegroundColor Yellow
} else {
    Write-Host "  NO - Need to fix data issues first" -ForegroundColor Red
}
