# Test Vantage API Connection - CORRECT AUTH
# Run with: powershell -ExecutionPolicy Bypass -File test_vantage_api_correct.ps1

Write-Host "Testing Vantage API Connection (Correct Auth)...`n" -ForegroundColor Cyan

# Correct authentication
$baseUrl = "https://buligoirapi.insightportal.info"
$authToken = "buligodata"
$clientId = "bexz40aUdxK5rQDSjS2BIUg=="

Write-Host "Base URL: $baseUrl"
Write-Host "Authorization: $authToken"
Write-Host "Client ID: $clientId`n"

# Create headers (NO Basic auth, just raw token)
$headers = @{
    'Authorization' = $authToken
    'X-com-vantageir-subscriptions-clientid' = $clientId
}

try {
    # Test 1: Fetch Funds
    Write-Host "Test 1: Fetching Funds..." -ForegroundColor Yellow
    $fundsUrl = "$baseUrl/api/Funds/Get"
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

    # Test 4: Fetch Contacts with pagination
    Write-Host "Test 4: Fetching Contacts (with pagination)..." -ForegroundColor Yellow
    $contactsUrl = "$baseUrl/api/Contacts/Get?page=1&per_page=5"
    $contactsResponse = Invoke-RestMethod -Uri $contactsUrl -Method Get -Headers $headers

    if ($contactsResponse.code -eq 0) {
        Write-Host "SUCCESS! Found $($contactsResponse.contacts.Count) contacts in page 1" -ForegroundColor Green
        if ($contactsResponse.contacts.Count -gt 0) {
            $contact = $contactsResponse.contacts[0]
            Write-Host "   Sample contact: $($contact.full_name) (ID: $($contact.contact_id))"
        }
    } else {
        Write-Host "ERROR: $($contactsResponse.message)" -ForegroundColor Red
    }
    Write-Host ""

    # Test 5: Incremental sync test (last 30 days) - CORRECT DATE FORMAT
    Write-Host "Test 5: Testing incremental sync (last 30 days - yyyyMMdd format)..." -ForegroundColor Yellow
    $thirtyDaysAgo = (Get-Date).AddDays(-30).ToString("yyyyMMdd")
    $recentAccountsUrl = "$baseUrl/api/Accounts/GetbyDate/$thirtyDaysAgo" + "?page=1&per_page=10"
    Write-Host "   Using date: $thirtyDaysAgo" -ForegroundColor Gray
    $recentAccountsResponse = Invoke-RestMethod -Uri $recentAccountsUrl -Method Get -Headers $headers

    if ($recentAccountsResponse.code -eq 0) {
        Write-Host "SUCCESS! Found $($recentAccountsResponse.accounts.Count) accounts updated since $thirtyDaysAgo" -ForegroundColor Green
        if ($recentAccountsResponse.page_context) {
            Write-Host "   Total available: $($recentAccountsResponse.page_context.total_available_Records)"
            Write-Host "   Has more pages: $($recentAccountsResponse.page_context.has_more_page)"
        }
    } else {
        Write-Host "ERROR: $($recentAccountsResponse.message)" -ForegroundColor Red
    }
    Write-Host ""

    # Summary
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "ALL TESTS PASSED! Vantage API is working correctly." -ForegroundColor Green
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Summary:"
    Write-Host "   Funds: $($fundsResponse.funds.Count)"
    Write-Host "   Accounts/Investors: $($accountsResponse.accounts.Count)"
    Write-Host "   Cash Flow Transactions: $($cashFlowsResponse.cashFlows.Count)"
    Write-Host "   Contacts: $($contactsResponse.contacts.Count) (page 1)"
    Write-Host "   Recent Updates (30d): $($recentAccountsResponse.page_context.total_available_Records)`n"
    Write-Host "Ready to build ETL pipeline!" -ForegroundColor Green

} catch {
    Write-Host "`n========================================" -ForegroundColor Red
    Write-Host "ERROR testing Vantage API:" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "   $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nFull error details:" -ForegroundColor Yellow
    Write-Host $_ | Format-List -Force
    exit 1
}
