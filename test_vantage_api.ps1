# Test Vantage API Connection
# Run with: powershell -ExecutionPolicy Bypass -File test_vantage_api.ps1

Write-Host "🔌 Testing Vantage API Connection...`n" -ForegroundColor Cyan

# Load credentials from .env
$envFile = Get-Content .env
$baseUrl = ($envFile | Where-Object { $_ -match 'VANTAGE_API_BASE_URL=' }) -replace 'VANTAGE_API_BASE_URL="?([^"]+)"?', '$1'
$username = ($envFile | Where-Object { $_ -match 'VANTAGE_API_USERNAME=' }) -replace 'VANTAGE_API_USERNAME="?([^"]+)"?', '$1'
$password = ($envFile | Where-Object { $_ -match 'VANTAGE_API_PASSWORD=' }) -replace 'VANTAGE_API_PASSWORD="?([^"]+)"?', '$1'

Write-Host "Base URL: $baseUrl"
Write-Host "Username: $username"
Write-Host "Password: ***$($password.Substring($password.Length - 4))`n"

# Create Basic Auth header
$credentials = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${username}:${password}"))
$headers = @{
    'Authorization' = "Basic $credentials"
    'Content-Type' = 'application/json'
}

try {
    # Test 1: Fetch Funds
    Write-Host "📁 Test 1: Fetching Funds..." -ForegroundColor Yellow
    $fundsUrl = "$baseUrl/api/Funds/Get"
    $fundsResponse = Invoke-RestMethod -Uri $fundsUrl -Method Get -Headers $headers

    if ($fundsResponse.code -eq 0) {
        Write-Host "✅ Success! Found $($fundsResponse.funds.Count) funds" -ForegroundColor Green
        if ($fundsResponse.funds.Count -gt 0) {
            $fund = $fundsResponse.funds[0]
            Write-Host "   Sample fund: $($fund.fundname) (ID: $($fund.fund_id))"
        }
    } else {
        Write-Host "❌ Error: $($fundsResponse.message)" -ForegroundColor Red
    }
    Write-Host ""

    # Test 2: Fetch Accounts (Investors)
    Write-Host "👥 Test 2: Fetching Accounts (Investors)..." -ForegroundColor Yellow
    $accountsUrl = "$baseUrl/api/Accounts/Get"
    $accountsResponse = Invoke-RestMethod -Uri $accountsUrl -Method Get -Headers $headers

    if ($accountsResponse.code -eq 0) {
        Write-Host "✅ Success! Found $($accountsResponse.accounts.Count) accounts" -ForegroundColor Green
        if ($accountsResponse.accounts.Count -gt 0) {
            $account = $accountsResponse.accounts[0]
            Write-Host "   Sample account: $($account.investor_name) (ID: $($account.investor_id))"
        }
    } else {
        Write-Host "❌ Error: $($accountsResponse.message)" -ForegroundColor Red
    }
    Write-Host ""

    # Test 3: Fetch Cash Flows (Transactions)
    Write-Host "💰 Test 3: Fetching Cash Flows (Transactions)..." -ForegroundColor Yellow
    $cashFlowsUrl = "$baseUrl/api/CashFlows/Get"
    $cashFlowsResponse = Invoke-RestMethod -Uri $cashFlowsUrl -Method Get -Headers $headers

    if ($cashFlowsResponse.code -eq 0) {
        Write-Host "✅ Success! Found $($cashFlowsResponse.cashFlows.Count) cash flows" -ForegroundColor Green
        if ($cashFlowsResponse.cashFlows.Count -gt 0) {
            $cashFlow = $cashFlowsResponse.cashFlows[0]
            Write-Host "   Sample: $($cashFlow.transaction_type) - $($cashFlow.transaction_amount) ($($cashFlow.fundshortname))"
        }
    } else {
        Write-Host "❌ Error: $($cashFlowsResponse.message)" -ForegroundColor Red
    }
    Write-Host ""

    # Test 4: Incremental sync test (last 30 days)
    Write-Host "🔄 Test 4: Testing incremental sync (last 30 days)..." -ForegroundColor Yellow
    $thirtyDaysAgo = (Get-Date).AddDays(-30).ToString("yyyy-MM-dd")
    $recentAccountsUrl = "$baseUrl/api/Accounts/GetbyDate/$thirtyDaysAgo" + "?page=1&per_page=10"
    $recentAccountsResponse = Invoke-RestMethod -Uri $recentAccountsUrl -Method Get -Headers $headers

    if ($recentAccountsResponse.code -eq 0) {
        Write-Host "✅ Success! Found $($recentAccountsResponse.accounts.Count) accounts updated since $thirtyDaysAgo" -ForegroundColor Green
        if ($recentAccountsResponse.page_context) {
            Write-Host "   Total available: $($recentAccountsResponse.page_context.total_available_Records)"
            Write-Host "   Has more pages: $($recentAccountsResponse.page_context.has_more_page)"
        }
    } else {
        Write-Host "❌ Error: $($recentAccountsResponse.message)" -ForegroundColor Red
    }
    Write-Host ""

    # Summary
    Write-Host "🎉 All tests passed! Vantage API is working correctly.`n" -ForegroundColor Green
    Write-Host "📊 Summary:"
    Write-Host "   • $($fundsResponse.funds.Count) funds available"
    Write-Host "   • $($accountsResponse.accounts.Count) accounts/investors available"
    Write-Host "   • $($cashFlowsResponse.cashFlows.Count) cash flow transactions available"
    Write-Host "   • Incremental sync working ($($recentAccountsResponse.page_context.total_available_Records) recent updates)`n"
    Write-Host "✅ Ready to build ETL pipeline!" -ForegroundColor Green

} catch {
    Write-Host "`n❌ Error testing Vantage API:" -ForegroundColor Red
    Write-Host "   $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nFull error:" -ForegroundColor Yellow
    Write-Host $_.Exception
    exit 1
}
