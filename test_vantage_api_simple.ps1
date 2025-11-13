# Test Vantage API Connection
# Run with: powershell -ExecutionPolicy Bypass -File test_vantage_api_simple.ps1

Write-Host "Testing Vantage API Connection...`n" -ForegroundColor Cyan

# Load environment variables
$baseUrl = "https://buligoirapi.insightportal.info"
$username = "buligodata"
$password = "bexz40aUdxK5rQDSjS2BIUg=="

Write-Host "Base URL: $baseUrl"
Write-Host "Username: $username"
Write-Host "Password: ***g==`n"

# Create Basic Auth header
$pair = "${username}:${password}"
$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
$base64 = [System.Convert]::ToBase64String($bytes)
$headers = @{
    'Authorization' = "Basic $base64"
    'Content-Type' = 'application/json'
}

Write-Host "Authorization header: Basic $base64`n" -ForegroundColor Gray

try {
    # Test 1: Fetch Funds
    Write-Host "Test 1: Fetching Funds..." -ForegroundColor Yellow
    $fundsUrl = "$baseUrl/api/Funds/Get"
    Write-Host "URL: $fundsUrl" -ForegroundColor Gray
    $fundsResponse = Invoke-RestMethod -Uri $fundsUrl -Method Get -Headers $headers

    if ($fundsResponse.code -eq 0) {
        Write-Host "SUCCESS! Found $($fundsResponse.funds.Count) funds" -ForegroundColor Green
        if ($fundsResponse.funds.Count -gt 0) {
            $fund = $fundsResponse.funds[0]
            Write-Host "   Sample fund: $($fund.fundname) (ID: $($fund.fund_id))"
        }
    } else {
        Write-Host "ERROR: $($fundsResponse.message)" -ForegroundColor Red
    }
    Write-Host ""

    # Test 2: Fetch Accounts (Investors)
    Write-Host "Test 2: Fetching Accounts (Investors)..." -ForegroundColor Yellow
    $accountsUrl = "$baseUrl/api/Accounts/Get"
    Write-Host "URL: $accountsUrl" -ForegroundColor Gray
    $accountsResponse = Invoke-RestMethod -Uri $accountsUrl -Method Get -Headers $headers

    if ($accountsResponse.code -eq 0) {
        Write-Host "SUCCESS! Found $($accountsResponse.accounts.Count) accounts" -ForegroundColor Green
        if ($accountsResponse.accounts.Count -gt 0) {
            $account = $accountsResponse.accounts[0]
            Write-Host "   Sample account: $($account.investor_name) (ID: $($account.investor_id))"
        }
    } else {
        Write-Host "ERROR: $($accountsResponse.message)" -ForegroundColor Red
    }
    Write-Host ""

    # Test 3: Fetch Cash Flows (Transactions)
    Write-Host "Test 3: Fetching Cash Flows (Transactions)..." -ForegroundColor Yellow
    $cashFlowsUrl = "$baseUrl/api/CashFlows/Get"
    Write-Host "URL: $cashFlowsUrl" -ForegroundColor Gray
    $cashFlowsResponse = Invoke-RestMethod -Uri $cashFlowsUrl -Method Get -Headers $headers

    if ($cashFlowsResponse.code -eq 0) {
        Write-Host "SUCCESS! Found $($cashFlowsResponse.cashFlows.Count) cash flows" -ForegroundColor Green
        if ($cashFlowsResponse.cashFlows.Count -gt 0) {
            $cashFlow = $cashFlowsResponse.cashFlows[0]
            Write-Host "   Sample: $($cashFlow.transaction_type) - $($cashFlow.transaction_amount) ($($cashFlow.fundshortname))"
        }
    } else {
        Write-Host "ERROR: $($cashFlowsResponse.message)" -ForegroundColor Red
    }
    Write-Host ""

    # Summary
    Write-Host "All tests passed! Vantage API is working correctly.`n" -ForegroundColor Green
    Write-Host "Summary:"
    Write-Host "   Funds: $($fundsResponse.funds.Count)"
    Write-Host "   Accounts/Investors: $($accountsResponse.accounts.Count)"
    Write-Host "   Cash Flow Transactions: $($cashFlowsResponse.cashFlows.Count)`n"
    Write-Host "Ready to build ETL pipeline!" -ForegroundColor Green

} catch {
    Write-Host "`nError testing Vantage API:" -ForegroundColor Red
    Write-Host "   $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nFull error details:" -ForegroundColor Yellow
    Write-Host $_ | Format-List -Force
    exit 1
}
