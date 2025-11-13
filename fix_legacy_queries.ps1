# PowerShell script to fix legacy PostgREST queries
# Run this from the project root directory

Write-Host "Fixing legacy PostgREST queries..." -ForegroundColor Green

# Fix 1: EntitySelector.tsx - Remove party_type and is_active
$file = "src\components\EntitySelector.tsx"
if (Test-Path $file) {
    Write-Host "Fixing $file..." -ForegroundColor Yellow
    (Get-Content $file -Raw) `
        -replace '\.eq\([''""]party_type[''""], entityType\)\s*\n\s*\.eq\([''""]is_active[''""], true\)', '.eq(''active'', true)' `
        | Set-Content $file -NoNewline
}

# Fix 2: FundVITracksAdmin.tsx - Remove is_active from fund_tracks
$file = "src\components\FundVITracksAdmin.tsx"
if (Test-Path $file) {
    Write-Host "Fixing $file..." -ForegroundColor Yellow
    (Get-Content $file -Raw) `
        -replace '\.eq\([''""]is_active[''""], true\)\s*\n', '' `
        | Set-Content $file -NoNewline
}

# Fix 3: InvestorManagement.tsx - Remove is_active from investors
$file = "src\components\InvestorManagement.tsx"
if (Test-Path $file) {
    Write-Host "Fixing $file..." -ForegroundColor Yellow
    (Get-Content $file -Raw) `
        -replace '\.eq\([''""]is_active[''""], true\)\s*\n', '' `
        | Set-Content $file -NoNewline
}

# Fix 4: SimplifiedCalculationDashboard.tsx - deals is_active -> status
$file = "src\components\SimplifiedCalculationDashboard.tsx"
if (Test-Path $file) {
    Write-Host "Fixing $file..." -ForegroundColor Yellow
    (Get-Content $file -Raw) `
        -replace "\.eq\('is_active', true\)", ".eq('status', 'ACTIVE')" `
        | Set-Content $file -NoNewline
}

# Fix 5: EnhancedInvestorUpload.tsx - Remove is_active from investors
$file = "src\components\EnhancedInvestorUpload.tsx"
if (Test-Path $file) {
    Write-Host "Fixing $file..." -ForegroundColor Yellow
    (Get-Content $file -Raw) `
        -replace '\.eq\([''""]is_active[''""], true\);', ';' `
        | Set-Content $file -NoNewline
}

# Fix 6: CommissionRuleSetup.tsx - deals is_active -> status
$file = "src\components\CommissionRuleSetup.tsx"
if (Test-Path $file) {
    Write-Host "Fixing $file..." -ForegroundColor Yellow
    (Get-Content $file -Raw) `
        -replace "\.eq\('is_active', true\)", ".eq('status', 'ACTIVE')" `
        | Set-Content $file -NoNewline
}

# Fix 7: AgreementManagement.tsx - Remove party_type and is_active
$file = "src\components\AgreementManagement.tsx"
if (Test-Path $file) {
    Write-Host "Fixing $file..." -ForegroundColor Yellow
    (Get-Content $file -Raw) `
        -replace "\.select\('id, name, party_type'\)\s*\n\s*\.eq\('is_active', true\)", ".select('id, name')`n      .eq('active', true)" `
        | Set-Content $file -NoNewline
}

# Fix 8: DistributorRulesManagement.tsx - Remove party_type and is_active
$file = "src\components\DistributorRulesManagement.tsx"
if (Test-Path $file) {
    Write-Host "Fixing $file..." -ForegroundColor Yellow
    (Get-Content $file -Raw) `
        -replace "\.select\(`"id, name, party_type`"\)\s*\n\s*\.eq\(`"is_active`", true\)\s*\n\s*\.in\(`"party_type`", \[`"distributor`", `"referrer`", `"partner`"\]\)", ".select(`"id, name`")`n      .eq(`"active`", true)" `
        -replace "\.eq\(`"is_active`", true\)\s*\n\s*\.order", ".eq(`"status`", 'ACTIVE')`n      .order" `
        | Set-Content $file -NoNewline
}

Write-Host "Done! Fixed all legacy queries." -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANT: The following components use 'investor_agreement_links' table which no longer exists:" -ForegroundColor Red
Write-Host "  - InvestorAgreementLinks.tsx" -ForegroundColor Red
Write-Host "  - DistributorHierarchyView.tsx" -ForegroundColor Red
Write-Host "  - PartyManagement.tsx" -ForegroundColor Red
Write-Host ""
Write-Host "These components should be disabled or refactored to use the new schema." -ForegroundColor Red
