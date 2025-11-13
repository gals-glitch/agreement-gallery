/**
 * Vantage ETL Sync Orchestrator
 * Supabase Edge Function for syncing data from Vantage IR API
 *
 * Endpoint: POST /functions/v1/vantage-sync
 *
 * Features:
 * - Full and incremental sync modes
 * - Resource selection (accounts, funds)
 * - Idempotent upserts (ON CONFLICT external_id)
 * - Comprehensive error handling
 * - Dry-run mode for validation
 * - Progress tracking and metrics
 *
 * Schema Notes:
 * - Vantage Accounts → entities (party data) + investors (investment data)
 * - Vantage Funds → deals (properties/projects) within existing funds
 * - Uses external_id for idempotency
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { createVantageClient } from '../_shared/vantageClient.ts';
import {
  mapVantageAccountToInvestor,
  mapVantageFundToFund,
  validateInvestorData,
  validateFundData,
  formatDateForVantage,
  type InvestorInsert,
  type FundInsert,
  type ValidationError,
  type ValidationResult,
} from '../_shared/vantageMappers.ts';
import type {
  VantageAccount,
  VantageFund,
  AccountsResponse,
  FundResponse,
} from '../_shared/vantageTypes.ts';

// ============================================
// TYPES
// ============================================

interface SyncRequest {
  mode?: 'full' | 'incremental';
  resources?: string[];
  dryRun?: boolean;
}

interface ResourceResult {
  status: 'success' | 'failed';
  recordsProcessed: number;
  recordsCreated: number;
  recordsUpdated: number;
  errors: Array<{field: string; message: string; recordId?: string}>;
  duration: number;
}

interface SyncResponse {
  success: boolean;
  results: {
    [resource: string]: ResourceResult;
  };
  startedAt: string;
  completedAt: string;
}

interface SyncState {
  resource: string;
  last_sync_time?: string;
  last_sync_status?: string;
  records_synced?: number;
  started_at?: string;
  completed_at?: string;
  duration_ms?: number;
  errors?: any;
}

// ============================================
// CORS HEADERS
// ============================================

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// ============================================
// MAIN HANDLER
// ============================================

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  const startedAt = new Date().toISOString();

  try {
    // Initialize Supabase client with service role
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // ============================================
    // AUTHENTICATION CHECK
    // ============================================

    const authHeader = req.headers.get('authorization');
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    // Verify service role or admin user
    const isServiceRole = authHeader.includes(Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '');

    if (!isServiceRole) {
      const token = authHeader.replace('Bearer ', '');
      const { data: { user }, error: authError } = await supabase.auth.getUser(token);

      if (authError || !user) {
        return new Response(
          JSON.stringify({ error: 'Invalid authentication token' }),
          {
            status: 401,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          }
        );
      }

      const { data: roles } = await supabase
        .from('user_roles')
        .select('role')
        .eq('user_id', user.id);

      const isAdmin = roles?.some((r: any) => r.role === 'admin');

      if (!isAdmin) {
        return new Response(
          JSON.stringify({ error: 'Insufficient permissions. Admin role required.' }),
          {
            status: 403,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          }
        );
      }
    }

    // ============================================
    // PARSE REQUEST BODY
    // ============================================

    let requestBody: SyncRequest = {};
    try {
      const text = await req.text();
      requestBody = text ? JSON.parse(text) : {};
    } catch (e) {
      return new Response(
        JSON.stringify({ error: 'Invalid JSON in request body' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    const mode = requestBody.mode || 'incremental';
    const resources = requestBody.resources || ['accounts', 'funds'];
    const dryRun = requestBody.dryRun || false;

    console.log(`[Vantage Sync] Starting sync - Mode: ${mode}, Resources: ${resources.join(', ')}, DryRun: ${dryRun}`);

    // ============================================
    // INITIALIZE VANTAGE CLIENT
    // ============================================

    let vantageClient;
    try {
      vantageClient = createVantageClient();
    } catch (error) {
      console.error('[Vantage Sync] Failed to create Vantage client:', error);
      return new Response(
        JSON.stringify({
          error: 'Failed to initialize Vantage client. Check environment variables.',
          details: error instanceof Error ? error.message : String(error),
        }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    // ============================================
    // SYNC EACH RESOURCE
    // ============================================

    const results: { [resource: string]: ResourceResult } = {};

    for (const resource of resources) {
      if (resource === 'accounts') {
        results.accounts = await syncAccounts(vantageClient, supabase, mode, dryRun);
      } else if (resource === 'funds') {
        results.funds = await syncFunds(vantageClient, supabase, mode, dryRun);
      } else {
        console.warn(`[Vantage Sync] Unknown resource: ${resource}`);
        results[resource] = {
          status: 'failed',
          recordsProcessed: 0,
          recordsCreated: 0,
          recordsUpdated: 0,
          errors: [{ field: 'resource', message: `Unknown resource: ${resource}` }],
          duration: 0,
        };
      }
    }

    // ============================================
    // PREPARE RESPONSE
    // ============================================

    const completedAt = new Date().toISOString();
    const success = Object.values(results).every((r) => r.status === 'success');

    const response: SyncResponse = {
      success,
      results,
      startedAt,
      completedAt,
    };

    console.log(`[Vantage Sync] Completed - Success: ${success}, Duration: ${new Date(completedAt).getTime() - new Date(startedAt).getTime()}ms`);

    return new Response(JSON.stringify(response), {
      status: success ? 200 : 422,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (error) {
    console.error('[Vantage Sync] Unexpected error:', error);
    return new Response(
      JSON.stringify({
        error: 'Internal server error',
        details: error instanceof Error ? error.message : String(error),
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});

// ============================================
// SYNC ACCOUNTS (INVESTORS)
// ============================================

async function syncAccounts(
  vantageClient: any,
  supabase: any,
  mode: 'full' | 'incremental',
  dryRun: boolean
): Promise<ResourceResult> {
  const startTime = Date.now();
  const resource = 'accounts';

  console.log(`[Vantage Sync] Starting ${resource} sync (${mode})`);

  try {
    // ============================================
    // UPDATE SYNC STATE: RUNNING
    // ============================================

    await updateSyncState(supabase, {
      resource,
      last_sync_status: 'running',
      started_at: new Date().toISOString(),
    });

    // ============================================
    // FETCH DATA FROM VANTAGE
    // ============================================

    let accounts: VantageAccount[] = [];

    if (mode === 'full') {
      console.log(`[Vantage Sync] Fetching all accounts...`);
      const response: AccountsResponse = await vantageClient.getAllAccounts();
      accounts = response.accounts || [];
    } else {
      const { data: syncState } = await supabase
        .from('vantage_sync_state')
        .select('last_sync_time')
        .eq('resource', resource)
        .single();

      const lastSyncTime = syncState?.last_sync_time;

      if (lastSyncTime) {
        const startDate = formatDateForVantage(new Date(lastSyncTime));
        console.log(`[Vantage Sync] Fetching accounts updated since ${startDate}...`);
        const response = await vantageClient.getAccountsByDate(startDate);
        accounts = response.accounts || [];
      } else {
        console.log(`[Vantage Sync] No last sync time found, performing full sync...`);
        const response: AccountsResponse = await vantageClient.getAllAccounts();
        accounts = response.accounts || [];
      }
    }

    console.log(`[Vantage Sync] Fetched ${accounts.length} accounts from Vantage`);

    // ============================================
    // VALIDATE
    // ============================================

    const errors: Array<{field: string; message: string; recordId?: string}> = [];
    const validAccounts: VantageAccount[] = [];

    for (const account of accounts) {
      const validation: ValidationResult = validateInvestorData(account);

      if (!validation.valid) {
        errors.push(...validation.errors.map(e => ({
          field: e.field,
          message: e.message,
          recordId: String(account.investor_id),
        })));
        console.warn(`[Vantage Sync] Validation failed for account ${account.investor_id}:`, validation.errors);
        continue;
      }

      validAccounts.push(account);
    }

    console.log(`[Vantage Sync] Validated ${validAccounts.length} accounts (${errors.length} errors)`);

    // ============================================
    // UPSERT TO DATABASE
    // ============================================

    let recordsCreated = 0;
    let recordsUpdated = 0;

    if (!dryRun && validAccounts.length > 0) {
      console.log(`[Vantage Sync] Upserting ${validAccounts.length} accounts using chunked batch operations...`);

      try {
        // Process in chunks of 100 to avoid timeouts
        const CHUNK_SIZE = 100;
        const chunks = [];
        for (let i = 0; i < validAccounts.length; i += CHUNK_SIZE) {
          chunks.push(validAccounts.slice(i, i + CHUNK_SIZE));
        }

        console.log(`[Vantage Sync] Processing ${chunks.length} chunks of ${CHUNK_SIZE} accounts...`);

        for (let chunkIndex = 0; chunkIndex < chunks.length; chunkIndex++) {
          const chunk = chunks[chunkIndex];
          console.log(`[Vantage Sync] Processing chunk ${chunkIndex + 1}/${chunks.length} (${chunk.length} accounts)...`);

          // Map accounts to investors (no entity creation needed)
          const investors = chunk.map(account => mapVantageAccountToInvestor(account));

          if (investors.length > 0) {
            const { data: investorResult, error: investorError } = await supabase
              .from('investors')
              .upsert(investors, {
                onConflict: 'external_id',
                ignoreDuplicates: false,
              })
              .select('id');

            if (investorError) {
              console.error(`[Vantage Sync] Chunk ${chunkIndex + 1} investor upsert failed:`, investorError);
              errors.push({
                field: 'investors',
                message: `Chunk ${chunkIndex + 1} investor upsert failed: ${investorError.message}`,
              });
            } else {
              recordsCreated += investorResult?.length || 0;
              console.log(`[Vantage Sync] Chunk ${chunkIndex + 1} complete: ${investorResult?.length || 0} investors upserted`);
            }
          }
        }

        console.log(`[Vantage Sync] All chunks processed - Total created/updated: ${recordsCreated}`);
      } catch (error) {
        console.error(`[Vantage Sync] Error during chunked upsert:`, error);
        errors.push({
          field: 'batch',
          message: error instanceof Error ? error.message : String(error),
        });
      }
    }

    // ============================================
    // UPDATE SYNC STATE: COMPLETE
    // ============================================

    const duration = Date.now() - startTime;
    const status = errors.length === 0 ? 'success' : 'failed';
    const completedAt = new Date().toISOString();

    await updateSyncState(supabase, {
      resource,
      last_sync_status: status,
      records_synced: recordsCreated + recordsUpdated,
      started_at: new Date(startTime).toISOString(),
      completed_at: completedAt,
      duration_ms: duration,
      errors: errors.length > 0 ? errors : null,
    });

    return {
      status,
      recordsProcessed: accounts.length,
      recordsCreated,
      recordsUpdated,
      errors,
      duration,
    };

  } catch (error) {
    console.error(`[Vantage Sync] Error syncing ${resource}:`, error);

    await updateSyncState(supabase, {
      resource,
      last_sync_status: 'failed',
      completed_at: new Date().toISOString(),
      duration_ms: Date.now() - startTime,
      errors: [{ field: 'system', message: error instanceof Error ? error.message : String(error) }],
    });

    return {
      status: 'failed',
      recordsProcessed: 0,
      recordsCreated: 0,
      recordsUpdated: 0,
      errors: [{ field: 'system', message: error instanceof Error ? error.message : String(error) }],
      duration: Date.now() - startTime,
    };
  }
}

// ============================================
// SYNC FUNDS
// ============================================

async function syncFunds(
  vantageClient: any,
  supabase: any,
  mode: 'full' | 'incremental',
  dryRun: boolean
): Promise<ResourceResult> {
  const startTime = Date.now();
  const resource = 'funds';

  console.log(`[Vantage Sync] Starting ${resource} sync (${mode})`);

  try {
    // ============================================
    // UPDATE SYNC STATE: RUNNING
    // ============================================

    await updateSyncState(supabase, {
      resource,
      last_sync_status: 'running',
      started_at: new Date().toISOString(),
    });

    // ============================================
    // GET DEFAULT FUND (required foreign key)
    // ============================================

    // In our schema, Vantage "funds" are mapped to "deals" which require a fund_id
    // We need to get or create a default fund for Vantage imports
    const { data: defaultFund } = await supabase
      .from('funds')
      .select('id')
      .eq('name', 'Vantage Import Fund')
      .maybeSingle();

    let fundId: string;

    if (defaultFund) {
      fundId = defaultFund.id;
    } else {
      const { data: newFund, error: fundError } = await supabase
        .from('funds')
        .insert({
          name: 'Vantage Import Fund',
          vintage_year: new Date().getFullYear(),
          status: 'ACTIVE',
          notes: 'Auto-created fund for Vantage imports',
        })
        .select('id')
        .single();

      if (fundError || !newFund) {
        console.error('[Vantage Sync] Failed to create default fund:', fundError);
        return {
          status: 'failed',
          recordsProcessed: 0,
          recordsCreated: 0,
          recordsUpdated: 0,
          errors: [{ field: 'fund', message: 'Failed to create default fund for Vantage imports' }],
          duration: Date.now() - startTime,
        };
      }

      fundId = newFund.id;
      console.log(`[Vantage Sync] Created default fund: ${fundId}`);
    }

    // ============================================
    // FETCH DATA FROM VANTAGE
    // ============================================

    let funds: VantageFund[] = [];

    if (mode === 'full') {
      console.log(`[Vantage Sync] Fetching all funds...`);
      const response: FundResponse = await vantageClient.getAllFunds();
      funds = response.funds || [];
    } else {
      const { data: syncState } = await supabase
        .from('vantage_sync_state')
        .select('last_sync_time')
        .eq('resource', resource)
        .single();

      const lastSyncTime = syncState?.last_sync_time;

      if (lastSyncTime) {
        const startDate = formatDateForVantage(new Date(lastSyncTime));
        console.log(`[Vantage Sync] Fetching funds updated since ${startDate}...`);
        const response = await vantageClient.getFundsByDate(startDate);
        funds = response.funds || [];
      } else {
        console.log(`[Vantage Sync] No last sync time found, performing full sync...`);
        const response: FundResponse = await vantageClient.getAllFunds();
        funds = response.funds || [];
      }
    }

    console.log(`[Vantage Sync] Fetched ${funds.length} funds from Vantage`);

    // ============================================
    // VALIDATE
    // ============================================

    const errors: Array<{field: string; message: string; recordId?: string}> = [];
    const validFunds: VantageFund[] = [];

    for (const fund of funds) {
      const validation: ValidationResult = validateFundData(fund);

      if (!validation.valid) {
        errors.push(...validation.errors.map(e => ({
          field: e.field,
          message: e.message,
          recordId: String(fund.fund_id),
        })));
        console.warn(`[Vantage Sync] Validation failed for fund ${fund.fund_id}:`, validation.errors);
        continue;
      }

      validFunds.push(fund);
    }

    console.log(`[Vantage Sync] Validated ${validFunds.length} funds (${errors.length} errors)`);

    // ============================================
    // UPSERT TO DATABASE
    // ============================================

    let recordsCreated = 0;
    let recordsUpdated = 0;

    if (!dryRun && validFunds.length > 0) {
      console.log(`[Vantage Sync] Upserting ${validFunds.length} funds...`);

      for (const fund of validFunds) {
        try {
          // Map to deal
          const dealData = mapVantageFundToFund(fund, fundId);

          // Check if deal exists
          const { data: existing } = await supabase
            .from('deals')
            .select('id')
            .eq('external_id', String(fund.fund_id))
            .maybeSingle();

          // Upsert deal
          const upsertData = {
            ...dealData,
            external_id: String(fund.fund_id),
          };

          if (existing) {
            const { error: updateError } = await supabase
              .from('deals')
              .update(upsertData)
              .eq('id', existing.id);

            if (updateError) {
              errors.push({
                field: 'deal',
                message: updateError.message,
                recordId: String(fund.fund_id),
              });
            } else {
              recordsUpdated++;
            }
          } else {
            const { error: insertError } = await supabase
              .from('deals')
              .insert(upsertData);

            if (insertError) {
              errors.push({
                field: 'deal',
                message: insertError.message,
                recordId: String(fund.fund_id),
              });
            } else {
              recordsCreated++;
            }
          }
        } catch (error) {
          console.error(`[Vantage Sync] Error upserting fund ${fund.fund_id}:`, error);
          errors.push({
            field: 'deal',
            message: error instanceof Error ? error.message : String(error),
            recordId: String(fund.fund_id),
          });
        }
      }

      console.log(`[Vantage Sync] Upserted funds - Created: ${recordsCreated}, Updated: ${recordsUpdated}`);
    }

    // ============================================
    // UPDATE SYNC STATE: COMPLETE
    // ============================================

    const duration = Date.now() - startTime;
    const status = errors.length === 0 ? 'success' : 'failed';
    const completedAt = new Date().toISOString();

    await updateSyncState(supabase, {
      resource,
      last_sync_status: status,
      records_synced: recordsCreated + recordsUpdated,
      started_at: new Date(startTime).toISOString(),
      completed_at: completedAt,
      duration_ms: duration,
      errors: errors.length > 0 ? errors : null,
    });

    return {
      status,
      recordsProcessed: funds.length,
      recordsCreated,
      recordsUpdated,
      errors,
      duration,
    };

  } catch (error) {
    console.error(`[Vantage Sync] Error syncing ${resource}:`, error);

    await updateSyncState(supabase, {
      resource,
      last_sync_status: 'failed',
      completed_at: new Date().toISOString(),
      duration_ms: Date.now() - startTime,
      errors: [{ field: 'system', message: error instanceof Error ? error.message : String(error) }],
    });

    return {
      status: 'failed',
      recordsProcessed: 0,
      recordsCreated: 0,
      recordsUpdated: 0,
      errors: [{ field: 'system', message: error instanceof Error ? error.message : String(error) }],
      duration: Date.now() - startTime,
    };
  }
}

// ============================================
// HELPER: UPSERT ENTITY
// ============================================

async function upsertEntity(supabase: any, account: VantageAccount): Promise<string | null> {
  try {
    // Check if entity exists by external_id
    const { data: existing } = await supabase
      .from('entities')
      .select('id')
      .eq('external_id', String(account.investor_id))
      .maybeSingle();

    if (existing) {
      return existing.id;
    }

    // Create new entity
    const { data: newEntity, error } = await supabase
      .from('entities')
      .insert({
        name: account.investor_name,
        entity_type: 'distributor',
        external_id: String(account.investor_id),
        tax_id: account.investor_name_taxid_number || null,
        country: account.country || null,
      })
      .select('id')
      .single();

    if (error) {
      console.error('[Vantage Sync] Failed to create entity:', error);
      return null;
    }

    return newEntity.id;
  } catch (error) {
    console.error('[Vantage Sync] Error in upsertEntity:', error);
    return null;
  }
}

// ============================================
// SYNC STATE HELPERS
// ============================================

async function updateSyncState(supabase: any, state: SyncState): Promise<void> {
  try {
    const record: any = {
      resource: state.resource,
    };

    if (state.last_sync_status) record.last_sync_status = state.last_sync_status;
    if (state.records_synced !== undefined) record.records_synced = state.records_synced;
    if (state.started_at) record.started_at = state.started_at;
    if (state.completed_at) record.completed_at = state.completed_at;
    if (state.duration_ms !== undefined) record.duration_ms = state.duration_ms;
    if (state.errors !== undefined) record.errors = state.errors;

    if (state.last_sync_status === 'success' && state.completed_at) {
      record.last_sync_time = state.completed_at;
    }

    const { error } = await supabase
      .from('vantage_sync_state')
      .upsert(record, {
        onConflict: 'resource',
        ignoreDuplicates: false,
      });

    if (error) {
      console.error('[Vantage Sync] Failed to update sync state:', error);
    }
  } catch (error) {
    console.error('[Vantage Sync] Error updating sync state:', error);
  }
}
