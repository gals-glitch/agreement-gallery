/**
 * Vantage Sync Diagnostics
 * Simple test function to verify environment configuration
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  console.log('[Diagnostics] Running environment diagnostics...');

  const diagnostics = {
    timestamp: new Date().toISOString(),
    supabase: {
      url: Deno.env.get('SUPABASE_URL') ? '✓ Set' : '✗ Missing',
      serviceRoleKey: Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ? '✓ Set' : '✗ Missing',
    },
    vantage: {
      baseUrl: Deno.env.get('VANTAGE_API_BASE_URL') || '✗ Missing',
      authToken: Deno.env.get('VANTAGE_AUTH_TOKEN') ? '✓ Set (hidden)' : '✗ Missing',
      clientId: Deno.env.get('VANTAGE_CLIENT_ID') ? '✓ Set (hidden)' : '✗ Missing',
    },
    runtime: {
      denoVersion: Deno.version.deno,
      v8Version: Deno.version.v8,
      typescriptVersion: Deno.version.typescript,
    },
    test: {
      canFetchVantage: false,
      vantageError: null,
    },
  };

  // Test Vantage API connectivity
  const vantageUrl = Deno.env.get('VANTAGE_API_BASE_URL');
  const vantageToken = Deno.env.get('VANTAGE_AUTH_TOKEN');
  const vantageClientId = Deno.env.get('VANTAGE_CLIENT_ID');

  if (vantageUrl && vantageToken && vantageClientId) {
    try {
      console.log('[Diagnostics] Testing Vantage API connection...');
      const testResponse = await fetch(`${vantageUrl}/api/Accounts/GetAll`, {
        method: 'GET',
        headers: {
          'Authorization': vantageToken,
          'X-com-vantageir-subscriptions-clientid': vantageClientId,
          'Content-Type': 'application/json',
        },
      });

      diagnostics.test.canFetchVantage = testResponse.ok;
      if (!testResponse.ok) {
        diagnostics.test.vantageError = `HTTP ${testResponse.status}: ${testResponse.statusText}`;
      }
      console.log(`[Diagnostics] Vantage API test: ${testResponse.status}`);
    } catch (error) {
      diagnostics.test.vantageError = error instanceof Error ? error.message : String(error);
      console.error('[Diagnostics] Vantage API test failed:', error);
    }
  } else {
    diagnostics.test.vantageError = 'Missing required environment variables';
  }

  const allGood =
    diagnostics.supabase.url.includes('✓') &&
    diagnostics.supabase.serviceRoleKey.includes('✓') &&
    diagnostics.vantage.baseUrl.includes('https://') &&
    diagnostics.vantage.authToken.includes('✓') &&
    diagnostics.vantage.clientId.includes('✓');

  console.log(`[Diagnostics] Overall status: ${allGood ? 'PASS' : 'FAIL'}`);

  return new Response(
    JSON.stringify({
      status: allGood ? 'ok' : 'config_error',
      diagnostics,
      recommendation: allGood
        ? 'All environment variables are set. vantage-sync should work.'
        : 'Missing environment variables. Set them in Supabase Dashboard > Settings > Edge Functions > Secrets',
    }, null, 2),
    {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
});
