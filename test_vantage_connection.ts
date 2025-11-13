/**
 * Test script to verify Vantage API connectivity
 * Run with: deno run --allow-net --allow-env test_vantage_connection.ts
 */

import { VantageClient } from './supabase/functions/_shared/vantageClient.ts';

// Load environment variables from .env file
const envFile = await Deno.readTextFile('.env');
envFile.split('\n').forEach((line) => {
  const match = line.match(/^([^#=]+)=["']?([^"']+)["']?$/);
  if (match) {
    Deno.env.set(match[1].trim(), match[2].trim());
  }
});

async function testVantageConnection() {
  console.log('🔌 Testing Vantage API Connection...\n');

  const baseUrl = Deno.env.get('VANTAGE_API_BASE_URL');
  const username = Deno.env.get('VANTAGE_API_USERNAME');
  const password = Deno.env.get('VANTAGE_API_PASSWORD');

  console.log(`Base URL: ${baseUrl}`);
  console.log(`Username: ${username}`);
  console.log(`Password: ${password ? '***' + password.slice(-4) : 'NOT SET'}\n`);

  try {
    const client = new VantageClient({
      baseUrl: baseUrl!,
      username: username!,
      password: password!,
    });

    // Test 1: Fetch Funds
    console.log('📁 Test 1: Fetching Funds...');
    const fundsResponse = await client.getAllFunds();
    console.log(`✅ Success! Found ${fundsResponse.funds.length} funds`);
    if (fundsResponse.funds.length > 0) {
      const fund = fundsResponse.funds[0];
      console.log(`   Sample fund: ${fund.fundname} (ID: ${fund.fund_id})`);
    }
    console.log('');

    // Test 2: Fetch Accounts (Investors)
    console.log('👥 Test 2: Fetching Accounts (Investors)...');
    const accountsResponse = await client.getAllAccounts();
    console.log(`✅ Success! Found ${accountsResponse.accounts.length} accounts`);
    if (accountsResponse.accounts.length > 0) {
      const account = accountsResponse.accounts[0];
      console.log(`   Sample account: ${account.investor_name} (ID: ${account.investor_id})`);
    }
    console.log('');

    // Test 3: Fetch Cash Flows (Transactions)
    console.log('💰 Test 3: Fetching Cash Flows (Transactions)...');
    const cashFlowsResponse = await client.getAllCashFlows();
    console.log(`✅ Success! Found ${cashFlowsResponse.cashFlows.length} cash flows`);
    if (cashFlowsResponse.cashFlows.length > 0) {
      const cashFlow = cashFlowsResponse.cashFlows[0];
      console.log(
        `   Sample: ${cashFlow.transaction_type} - ${cashFlow.transaction_amount} (${cashFlow.fundshortname})`
      );
    }
    console.log('');

    // Test 4: Incremental sync test (last 30 days)
    console.log('🔄 Test 4: Testing incremental sync (last 30 days)...');
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    const startDate = thirtyDaysAgo.toISOString().split('T')[0]; // YYYY-MM-DD

    const recentAccounts = await client.getAccountsByDate(startDate, 1, 10);
    console.log(`✅ Success! Found ${recentAccounts.accounts.length} accounts updated since ${startDate}`);
    if (recentAccounts.page_context) {
      console.log(`   Total available: ${recentAccounts.page_context.total_available_Records}`);
      console.log(`   Has more pages: ${recentAccounts.page_context.has_more_page}`);
    }
    console.log('');

    console.log('🎉 All tests passed! Vantage API is working correctly.\n');

    // Summary
    console.log('📊 Summary:');
    console.log(`   • ${fundsResponse.funds.length} funds available`);
    console.log(`   • ${accountsResponse.accounts.length} accounts/investors available`);
    console.log(`   • ${cashFlowsResponse.cashFlows.length} cash flow transactions available`);
    console.log(`   • Incremental sync working (${recentAccounts.page_context?.total_available_Records || 0} recent updates)`);
    console.log('');
    console.log('✅ Ready to build ETL pipeline!');

  } catch (error) {
    console.error('❌ Error testing Vantage API:');
    if (error instanceof Error) {
      console.error(`   ${error.message}`);
      if (error.stack) {
        console.error('\nStack trace:');
        console.error(error.stack);
      }
    } else {
      console.error(error);
    }
    Deno.exit(1);
  }
}

// Run the test
testVantageConnection();
