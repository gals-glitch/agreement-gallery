/**
 * API V1 Edge Function - Redesigned System
 * Base path: /api/v1
 * Handles: parties, funds, deals, fund-tracks, agreements, runs, feature-flags, admin (RBAC), charges, review (T09)
 * Date: 2025-10-16
 * Updated: 2025-10-21 (T04-T09: Charge workflow enhancements, fuzzy resolver, review queue)
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { handleFeatureFlags } from './featureFlags.ts';
import { handleVatRates } from './vatRates.ts';
import { handleTransactions } from './transactions.ts';
import { handleCredits } from './credits.ts';
import { handleAgreementDocs } from './agreementDocs.ts';
import { handleRBAC } from './rbac.ts';
import { handleChargesRoutes } from './charges.ts';
import { handleReviewQueue } from './reviewQueue.ts';
import { handlePreviewMatch, handleCommitMatches } from './fuzzyResolver.ts';
import { autoApplyCredits, reverseCredits } from './creditsEngine.ts';
import { handleCommissions } from './commissions.ts';
import { handleImports } from './imports.ts';
import {
  validationError,
  forbiddenError,
  conflictError,
  notFoundError,
  unauthorizedError,
  internalError,
  mapPgErrorToApiError,
  successResponse,
  type ApiErrorDetail,
} from './errors.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-service-key',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
};

// ============================================
// MAIN HANDLER
// ============================================
serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Parse URL and route
    const url = new URL(req.url);
    const pathParts = url.pathname.split('/').filter(Boolean);

    // Remove 'api-v1' from path if present (Supabase adds function name)
    const cleanPath = pathParts.filter(p => p !== 'api-v1');
    const resource = cleanPath[0]; // parties, funds, deals, etc.
    const id = cleanPath[1]; // resource ID
    const action = cleanPath[2]; // submit, approve, etc.

    // Health check route: GET /auth/check - returns decoded role
    if (resource === 'auth' && id === 'check' && req.method === 'GET') {
      const authHeader = req.headers.get('Authorization');
      const apikeyHeader = req.headers.get('apikey');
      const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

      // Extract token
      let token = null;
      if (authHeader) {
        token = authHeader.replace('Bearer ', '');
      } else if (apikeyHeader) {
        token = apikeyHeader;
      }

      if (!token) {
        return jsonResponse({
          authenticated: false,
          role: null,
          message: 'No token provided'
        }, 200);
      }

      // Check if service role key
      if (serviceRoleKey && token === serviceRoleKey) {
        return jsonResponse({
          authenticated: true,
          role: 'service_role',
          userId: 'SERVICE',
          message: 'Authenticated with service role key'
        }, 200);
      }

      // Check if JWT
      const { data: { user }, error: authError } = await supabase.auth.getUser(token);
      if (authError || !user) {
        return jsonResponse({
          authenticated: false,
          role: null,
          message: 'Invalid or expired JWT token'
        }, 200);
      }

      // Get user roles
      const { data: userRolesData } = await supabase
        .from('user_roles')
        .select('role_key')
        .eq('user_id', user.id);

      const roles = (userRolesData || []).map((r: any) => r.role_key);

      return jsonResponse({
        authenticated: true,
        role: 'user',
        userId: user.id,
        email: user.email,
        roles: roles,
        message: 'Authenticated with JWT token'
      }, 200);
    }

    // Special case: Charges POST endpoint (internal - no auth required)
    // All other charges endpoints require auth
    if (resource === 'charges' && req.method === 'POST' && !id) {
      return await handleChargesRoutes(req, supabase, null, corsHeaders);
    }

    // Authenticate request (supports user JWT or service role key)
    // Accept service role key from either Authorization header or apikey header
    const authHeader = req.headers.get('Authorization');
    const apikeyHeader = req.headers.get('apikey');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    // Extract token from Authorization header or apikey header
    let token = null;
    if (authHeader) {
      token = authHeader.replace('Bearer ', '');
    } else if (apikeyHeader) {
      token = apikeyHeader;
    }

    // If no token provided, return unauthorized error
    if (!token) {
      return unauthorizedError('Missing authorization header or apikey', corsHeaders);
    }

    // Check if using service role key (for internal/system requests)
    if (serviceRoleKey && token === serviceRoleKey) {
      // Service role key - bypass user auth, use 'SERVICE' marker
      // This allows internal jobs/scripts to make authenticated requests
      const userId = 'SERVICE'; // Special marker for service role requests

      console.log('✅ Authenticated with service_role key');

      // Route to appropriate handler
      switch (resource) {
        case 'charges':
          return await handleChargesRoutes(req, supabase, userId, corsHeaders);
        case 'commissions':
          return await handleCommissions(req, supabase, userId, url);
        case 'import':
          // Check if this is a CSV import endpoint (parties, investors, agreements, contributions)
          if (['parties', 'investors', 'agreements', 'contributions'].includes(id)) {
            return await handleImports(req, supabase, userId, url);
          }
          // Otherwise fall through to existing fuzzy resolver endpoints
          break;
        default:
          // Service role can access any endpoint
          break;
      }
    }

    // Regular user JWT auth
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);

    if (authError || !user) {
      return unauthorizedError('Invalid or expired token', corsHeaders);
    }

    // Route to appropriate handler
    switch (resource) {
      case 'admin':
        // /admin/users, /admin/roles (RBAC endpoints)
        return await handleRBAC(req, supabase, user.id, id, action, corsHeaders);
      case 'charges':
        // /charges (all endpoints except POST /charges which is handled above)
        return await handleChargesRoutes(req, supabase, user.id, corsHeaders);
      case 'commissions':
        // /commissions (commission payment workflow for distributors/referrers)
        return await handleCommissions(req, supabase, user.id, url);
      case 'review':
        // T09: /review/referrers?status=pending (review queue endpoints)
        return await handleReviewQueue(req, supabase, cleanPath, corsHeaders);
      case 'import':
        // T07: /import/preview, /import/commit (fuzzy resolver endpoints)
        if (id === 'preview' && req.method === 'POST') {
          return await handlePreviewMatch(req, supabase, corsHeaders);
        }
        if (id === 'commit' && req.method === 'POST') {
          return await handleCommitMatches(req, supabase, corsHeaders);
        }
        return notFoundError('Endpoint', corsHeaders);
      case 'parties':
        return await handleParties(req, supabase, user.id, id, action);
      case 'investors':
        return await handleInvestors(req, supabase, user.id, id, action);
      case 'funds':
        return await handleFunds(req, supabase, user.id, id);
      case 'deals':
        return await handleDeals(req, supabase, user.id, id);
      case 'fund-tracks':
        return await handleFundTracks(req, supabase, id, action);
      case 'agreements':
        // Check if this is a documents request (/agreements/documents or /agreements/:id/documents)
        if (id === 'documents' || action === 'documents') {
          return await handleAgreementDocs(req, supabase, user.id, cleanPath);
        }
        return await handleAgreements(req, supabase, user.id, id, action);
      case 'runs':
        return await handleRuns(req, supabase, user.id, id, action);
      case 'contributions':
        return await handleContributions(req, supabase, user.id, id, action);
      case 'feature-flags':
        return await handleFeatureFlags(req, supabase, user.id, id, corsHeaders);
      case 'vat-rates':
        return await handleVatRates(req, supabase, user.id, id, action, corsHeaders);
      case 'transactions':
        return await handleTransactions(req, supabase, user.id, id, corsHeaders);
      case 'credits':
        return await handleCredits(req, supabase, user.id, corsHeaders);
      default:
        return notFoundError('Resource', corsHeaders);
    }
  } catch (error) {
    console.error('Error:', error);
    return internalError(error.message, corsHeaders);
  }
});

// ============================================
// HELPER: JSON Response
// ============================================
function jsonResponse(data: any, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

// ============================================
// HELPER: XOR Check
// ============================================
function isXor(a: unknown, b: unknown): boolean {
  return (!!a) !== (!!b);
}

// ============================================
// HELPER: Map PostgreSQL Errors to HTTP
// ============================================
function mapPgErrorToHttp(err: any) {
  // Postgres error codes you'll commonly see through Supabase/PostgREST
  // 23514 check_violation (e.g., contributions_one_scope_ck)
  // 23503 foreign_key_violation
  // 23505 unique_violation
  // 23502 not_null_violation
  const code = err?.code;
  if (code === '23514') return jsonResponse({ error: 'CHECK_VIOLATION', detail: err.message }, 422);
  if (code === '23502') return jsonResponse({ error: 'NOT_NULL', detail: err.message }, 422);
  if (code === '23503') return jsonResponse({ error: 'FOREIGN_KEY', detail: err.message }, 422);
  if (code === '23505') return jsonResponse({ error: 'UNIQUE', detail: err.message }, 409);
  return jsonResponse({ error: 'BAD_REQUEST', detail: err?.message || 'Unknown error' }, 400);
}

// ============================================
// HELPER: Validate Contribution Payload
// ============================================
function validateContributionPayload(p: any): { ok: true } | { ok: false; details: ApiErrorDetail[] } {
  const details: ApiErrorDetail[] = [];

  if (!isXor(p.deal_id, p.fund_id)) {
    details.push({
      field: 'deal_id/fund_id',
      message: 'Exactly one of deal_id or fund_id is required',
      value: { deal_id: p.deal_id, fund_id: p.fund_id },
    });
  }

  if (!p.investor_id) {
    details.push({
      field: 'investor_id',
      message: 'investor_id is required',
      value: p.investor_id,
    });
  }

  if (!p.paid_in_date) {
    details.push({
      field: 'paid_in_date',
      message: 'paid_in_date is required (YYYY-MM-DD format)',
      value: p.paid_in_date,
    });
  }

  if (typeof p.amount !== 'number' || !(p.amount > 0)) {
    details.push({
      field: 'amount',
      message: 'amount must be a positive number',
      value: p.amount,
      constraint: 'amount_positive',
    });
  }

  if (details.length) return { ok: false, details };
  return { ok: true };
}

// ============================================
// HELPER: Get User Roles
// ============================================
async function getUserRoles(supabase: any, userId: string): Promise<string[]> {
  const { data, error } = await supabase
    .from('user_roles')
    .select('role_key')
    .eq('user_id', userId);

  if (error) return [];
  return data?.map((r: any) => r.role_key) || [];
}

// ============================================
// HELPER: Check Role
// ============================================
function hasAnyRole(userRoles: string[], requiredRoles: string[]): boolean {
  return requiredRoles.some(role => userRoles.includes(role));
}

// ============================================
// PARTIES HANDLERS
// ============================================
async function handleParties(req: Request, supabase: any, userId: string, id?: string, action?: string) {
  const url = new URL(req.url);

  switch (req.method) {
    case 'GET':
      if (id) {
        // GET /parties/:id
        const { data, error } = await supabase
          .from('parties')
          .select('*')
          .eq('id', id)
          .single();

        if (error) return jsonResponse({ error: error.message }, 404);
        return jsonResponse(data);
      } else {
        // GET /parties?q=&active=&limit=&offset=
        const q = url.searchParams.get('q');
        const active = url.searchParams.get('active');
        const limit = parseInt(url.searchParams.get('limit') || '50');
        const offset = parseInt(url.searchParams.get('offset') || '0');

        let query = supabase
          .from('parties')
          .select('*', { count: 'exact' })
          .order('name', { ascending: true })
          .range(offset, offset + limit - 1);

        if (q) {
          query = query.or(`name.ilike.%${q}%,email.ilike.%${q}%`);
        }
        if (active !== null) {
          query = query.eq('active', active === 'true');
        }

        const { data, error, count } = await query;

        if (error) return jsonResponse({ error: error.message }, 400);
        return jsonResponse({ items: data || [], total: count || 0 });
      }

    case 'POST':
      // POST /parties
      const body = await req.json();
      const { data, error } = await supabase
        .from('parties')
        .insert({
          name: body.name,
          email: body.email || null,
          country: body.country || null,
          tax_id: body.tax_id || null,
          active: body.active !== undefined ? body.active : true,
          notes: body.notes || null,
        })
        .select('id')
        .single();

      if (error) return jsonResponse({ error: error.message }, 400);
      return jsonResponse({ id: data.id }, 201);

    case 'PATCH':
      // PATCH /parties/:id
      if (!id) return jsonResponse({ error: 'ID required' }, 400);

      const patchBody = await req.json();
      const { error: updateError } = await supabase
        .from('parties')
        .update({
          ...(patchBody.name !== undefined && { name: patchBody.name }),
          ...(patchBody.email !== undefined && { email: patchBody.email }),
          ...(patchBody.country !== undefined && { country: patchBody.country }),
          ...(patchBody.tax_id !== undefined && { tax_id: patchBody.tax_id }),
          ...(patchBody.active !== undefined && { active: patchBody.active }),
          ...(patchBody.notes !== undefined && { notes: patchBody.notes }),
          updated_at: new Date().toISOString(),
        })
        .eq('id', id);

      if (updateError) return jsonResponse({ error: updateError.message }, 400);
      return jsonResponse({ ok: true });

    default:
      return jsonResponse({ error: 'Method not allowed' }, 405);
  }
}

// ============================================
// INVESTORS HANDLERS
// ============================================
async function handleInvestors(req: Request, supabase: any, userId: string, id?: string, action?: string) {
  const url = new URL(req.url);

  // Handle /investors/source-import (CSV backfill)
  if (id === 'source-import' && req.method === 'POST') {
    return await handleInvestorSourceImport(req, supabase);
  }

  switch (req.method) {
    case 'GET':
      if (id) {
        // GET /investors/:id
        const { data, error } = await supabase
          .from('investors')
          .select(`
            *,
            introduced_by_party:parties!investors_introduced_by_party_id_fkey(id, name)
          `)
          .eq('id', id)
          .single();

        if (error) return jsonResponse({ error: error.message }, 404);
        return jsonResponse(data);
      } else {
        // GET /investors?source_kind=&introduced_by_party_id=&has_source=&limit=&offset=
        const sourceKind = url.searchParams.get('source_kind');
        const introducedByPartyId = url.searchParams.get('introduced_by_party_id');
        const hasSource = url.searchParams.get('has_source');
        const limit = parseInt(url.searchParams.get('limit') || '50');
        const offset = parseInt(url.searchParams.get('offset') || '0');

        let query = supabase
          .from('investors')
          .select(`
            *,
            introduced_by_party:parties!investors_introduced_by_party_id_fkey(id, name)
          `, { count: 'exact' })
          .order('name', { ascending: true })
          .range(offset, offset + limit - 1);

        // Apply filters
        if (sourceKind && sourceKind !== 'ALL') {
          query = query.eq('source_kind', sourceKind);
        }
        if (introducedByPartyId) {
          query = query.eq('introduced_by_party_id', introducedByPartyId);
        }
        if (hasSource === 'true') {
          query = query.not('introduced_by_party_id', 'is', null);
        } else if (hasSource === 'false') {
          query = query.is('introduced_by_party_id', null);
        }

        const { data, error, count } = await query;

        if (error) return jsonResponse({ error: error.message }, 400);
        return jsonResponse({ items: data || [], total: count || 0 });
      }

    case 'POST':
      // POST /investors
      const body = await req.json();
      const insertData: any = {
        name: body.name,
        party_entity_id: body.party_entity_id,
        email: body.email || null,
        phone: body.phone || null,
        address: body.address || null,
        country: body.country || null,
        tax_id: body.tax_id || null,
        investor_type: body.investor_type || null,
        kyc_status: body.kyc_status || null,
        risk_profile: body.risk_profile || null,
        investment_capacity: body.investment_capacity || null,
        is_active: body.is_active !== undefined ? body.is_active : true,
        notes: body.notes || null,
        source_kind: body.source_kind || 'NONE',
        introduced_by_party_id: body.introduced_by_party_id || null,
      };

      // Validation: If introduced_by_party_id is set, source_kind must not be NONE
      if (insertData.introduced_by_party_id && insertData.source_kind === 'NONE') {
        return validationError([{
          field: 'source_kind',
          message: 'source_kind cannot be NONE when introduced_by_party_id is set',
          value: insertData.source_kind,
        }], corsHeaders);
      }

      // Validation: If introduced_by_party_id is set, verify party exists
      if (insertData.introduced_by_party_id) {
        const { data: party, error: partyError } = await supabase
          .from('parties')
          .select('id')
          .eq('id', insertData.introduced_by_party_id)
          .single();

        if (partyError || !party) {
          return validationError([{
            field: 'introduced_by_party_id',
            message: 'Invalid party ID - party not found',
            value: insertData.introduced_by_party_id,
          }], corsHeaders);
        }
      }

      const { data, error } = await supabase
        .from('investors')
        .insert(insertData)
        .select('id')
        .single();

      if (error) return mapPgErrorToApiError(error, corsHeaders);
      return successResponse({ id: data.id }, 201, corsHeaders);

    case 'PATCH':
      // PATCH /investors/:id
      if (!id) return jsonResponse({ error: 'ID required' }, 400);

      const patchBody = await req.json();
      const updateData: any = {
        updated_at: new Date().toISOString(),
      };

      // Update basic fields if provided
      if (patchBody.name !== undefined) updateData.name = patchBody.name;
      if (patchBody.email !== undefined) updateData.email = patchBody.email;
      if (patchBody.phone !== undefined) updateData.phone = patchBody.phone;
      if (patchBody.address !== undefined) updateData.address = patchBody.address;
      if (patchBody.country !== undefined) updateData.country = patchBody.country;
      if (patchBody.tax_id !== undefined) updateData.tax_id = patchBody.tax_id;
      if (patchBody.investor_type !== undefined) updateData.investor_type = patchBody.investor_type;
      if (patchBody.kyc_status !== undefined) updateData.kyc_status = patchBody.kyc_status;
      if (patchBody.risk_profile !== undefined) updateData.risk_profile = patchBody.risk_profile;
      if (patchBody.investment_capacity !== undefined) updateData.investment_capacity = patchBody.investment_capacity;
      if (patchBody.is_active !== undefined) updateData.is_active = patchBody.is_active;
      if (patchBody.notes !== undefined) updateData.notes = patchBody.notes;

      // Handle source fields with validation
      if (patchBody.source_kind !== undefined) {
        updateData.source_kind = patchBody.source_kind;

        // If source_kind is set to NONE, clear introduced_by_party_id
        if (patchBody.source_kind === 'NONE') {
          updateData.introduced_by_party_id = null;
        }
      }

      if (patchBody.introduced_by_party_id !== undefined) {
        const newPartyId = patchBody.introduced_by_party_id;

        // Validation: If introduced_by_party_id is being set, source_kind must not be NONE
        if (newPartyId !== null) {
          // Check current source_kind or use the one from patchBody
          const effectiveSourceKind = patchBody.source_kind || updateData.source_kind;

          if (effectiveSourceKind === 'NONE') {
            return validationError([{
              field: 'source_kind',
              message: 'source_kind cannot be NONE when introduced_by_party_id is set',
              value: effectiveSourceKind,
            }], corsHeaders);
          }

          // Verify party exists
          const { data: party, error: partyError } = await supabase
            .from('parties')
            .select('id')
            .eq('id', newPartyId)
            .single();

          if (partyError || !party) {
            return validationError([{
              field: 'introduced_by_party_id',
              message: 'Invalid party ID - party not found',
              value: newPartyId,
            }], corsHeaders);
          }
        }

        updateData.introduced_by_party_id = newPartyId;
      }

      const { error: updateError } = await supabase
        .from('investors')
        .update(updateData)
        .eq('id', id);

      if (updateError) return mapPgErrorToApiError(updateError, corsHeaders);
      return successResponse({ ok: true }, 200, corsHeaders);

    default:
      return jsonResponse({ error: 'Method not allowed' }, 405);
  }
}

// POST /investors/source-import - CSV backfill
async function handleInvestorSourceImport(req: Request, supabase: any) {
  const body = await req.json();

  // Expect array of: { investor_external_id, source_kind, party_name (optional) }
  if (!Array.isArray(body)) {
    return validationError([{
      message: 'Request body must be an array of import rows',
    }], corsHeaders);
  }

  const results = {
    success_count: 0,
    errors: [] as ApiErrorDetail[],
  };

  // Process each row
  for (let i = 0; i < body.length; i++) {
    const row = body[i];
    const rowNum = i + 1;

    try {
      // Validate required fields
      if (!row.investor_external_id) {
        results.errors.push({
          row: rowNum,
          field: 'investor_external_id',
          message: 'investor_external_id is required',
          value: row.investor_external_id,
        });
        continue;
      }

      if (!row.source_kind) {
        results.errors.push({
          row: rowNum,
          field: 'source_kind',
          message: 'source_kind is required',
          value: row.source_kind,
        });
        continue;
      }

      // Validate source_kind enum
      if (!['DISTRIBUTOR', 'REFERRER', 'NONE'].includes(row.source_kind)) {
        results.errors.push({
          row: rowNum,
          field: 'source_kind',
          message: 'source_kind must be DISTRIBUTOR, REFERRER, or NONE',
          value: row.source_kind,
        });
        continue;
      }

      // Find investor by external_id (assuming party_entity_id maps to an external identifier)
      // For now, we'll use the name field as external_id
      const { data: investor, error: investorError } = await supabase
        .from('investors')
        .select('id, name, source_kind, introduced_by_party_id')
        .eq('name', row.investor_external_id)
        .single();

      if (investorError || !investor) {
        results.errors.push({
          row: rowNum,
          field: 'investor_external_id',
          message: `Investor not found: ${row.investor_external_id}`,
          value: row.investor_external_id,
        });
        continue;
      }

      // Find party by name (if party_name provided)
      let partyId = null;
      if (row.party_name) {
        const { data: party, error: partyError } = await supabase
          .from('parties')
          .select('id, name')
          .ilike('name', row.party_name.trim())
          .single();

        if (partyError || !party) {
          results.errors.push({
            row: rowNum,
            field: 'party_name',
            message: `Party not found: ${row.party_name}`,
            value: row.party_name,
          });
          continue;
        }

        partyId = party.id;
      }

      // Prepare update
      const updatePayload: any = {
        source_kind: row.source_kind,
        updated_at: new Date().toISOString(),
      };

      // Set introduced_by_party_id based on source_kind
      if (row.source_kind === 'NONE') {
        updatePayload.introduced_by_party_id = null;
      } else if (partyId) {
        updatePayload.introduced_by_party_id = partyId;
      }

      // Update investor
      const { error: updateError } = await supabase
        .from('investors')
        .update(updatePayload)
        .eq('id', investor.id);

      if (updateError) {
        results.errors.push({
          row: rowNum,
          field: 'investor_external_id',
          message: `Update failed: ${updateError.message}`,
          value: row.investor_external_id,
        });
        continue;
      }

      results.success_count++;
    } catch (err: any) {
      results.errors.push({
        row: rowNum,
        message: `Unexpected error: ${err.message}`,
      });
    }
  }

  return successResponse(results, 200, corsHeaders);
}

// ============================================
// FUNDS HANDLERS
// ============================================
async function handleFunds(req: Request, supabase: any, userId: string, id?: string) {
  switch (req.method) {
    case 'GET':
      if (id) {
        // GET /funds/:id
        const { data, error } = await supabase
          .from('funds')
          .select('*')
          .eq('id', id)
          .single();

        if (error) return jsonResponse({ error: error.message }, 404);
        return jsonResponse(data);
      } else {
        // GET /funds
        const { data, error, count } = await supabase
          .from('funds')
          .select('*', { count: 'exact' })
          .order('vintage_year', { ascending: false, nullsFirst: false })
          .order('name', { ascending: true });

        if (error) return jsonResponse({ error: error.message }, 400);
        return jsonResponse({ items: data || [], total: count || 0 });
      }

    case 'POST':
      // POST /funds
      const body = await req.json();
      const { data, error } = await supabase
        .from('funds')
        .insert({
          name: body.name,
          vintage_year: body.vintage_year || null,
          currency: body.currency || 'USD',
          status: body.status || 'active',
          notes: body.notes || null,
        })
        .select('id')
        .single();

      if (error) return jsonResponse({ error: error.message }, 400);
      return jsonResponse({ id: data.id }, 201);

    default:
      return jsonResponse({ error: 'Method not allowed' }, 405);
  }
}

// ============================================
// DEALS HANDLERS
// ============================================
async function handleDeals(req: Request, supabase: any, userId: string, id?: string) {
  switch (req.method) {
    case 'GET':
      if (id) {
        // GET /deals/:id
        const { data, error } = await supabase
          .from('deals')
          .select('*')
          .eq('id', id)
          .single();

        if (error) return jsonResponse({ error: error.message }, 404);
        return jsonResponse(data);
      } else {
        // GET /deals
        const { data, error, count } = await supabase
          .from('deals')
          .select('*', { count: 'exact' })
          .order('name', { ascending: true });

        if (error) return jsonResponse({ error: error.message }, 400);
        return jsonResponse({ items: data || [], total: count || 0 });
      }

    case 'POST':
      // POST /deals
      const body = await req.json();
      const { data, error } = await supabase
        .from('deals')
        .insert({
          fund_id: body.fund_id || null,
          name: body.name,
          address: body.address || null,
          status: body.status || 'active',
          close_date: body.close_date || null,
          partner_company_id: body.partner_company_id || null,
          fund_group_id: body.fund_group_id || null,
          sector: body.sector || null,
          year_built: body.year_built || null,
          units: body.units || null,
          sqft: body.sqft || null,
          income_producing: body.income_producing !== undefined ? body.income_producing : false,
          exclude_gp_from_commission: body.exclude_gp_from_commission !== undefined ? body.exclude_gp_from_commission : true,
        })
        .select('id')
        .single();

      if (error) return jsonResponse({ error: error.message }, 400);
      return jsonResponse({ id: data.id }, 201);

    case 'PATCH':
      // PATCH /deals/:id
      if (!id) return jsonResponse({ error: 'ID required' }, 400);

      const patchBody = await req.json();

      // Only allow updating status and exclude_gp_from_commission
      const { error: updateError } = await supabase
        .from('deals')
        .update({
          ...(patchBody.status !== undefined && { status: patchBody.status }),
          ...(patchBody.exclude_gp_from_commission !== undefined && { exclude_gp_from_commission: patchBody.exclude_gp_from_commission }),
          updated_at: new Date().toISOString(),
        })
        .eq('id', id);

      if (updateError) return jsonResponse({ error: updateError.message }, 400);
      return jsonResponse({ ok: true });

    default:
      return jsonResponse({ error: 'Method not allowed' }, 405);
  }
}

// ============================================
// FUND TRACKS HANDLERS (read-only)
// ============================================
async function handleFundTracks(req: Request, supabase: any, fundId?: string, trackCode?: string) {
  if (req.method !== 'GET') {
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }

  if (fundId && trackCode) {
    // GET /fund-tracks/:fundId/:trackCode
    const { data, error } = await supabase
      .from('fund_tracks')
      .select('*')
      .eq('fund_id', fundId)
      .eq('track_code', trackCode)
      .single();

    if (error) return jsonResponse({ error: error.message }, 404);
    return jsonResponse(data);
  } else if (fundId) {
    // GET /fund-tracks?fund_id=:fundId
    const url = new URL(req.url);
    const queryFundId = url.searchParams.get('fund_id') || fundId;

    const { data, error } = await supabase
      .from('fund_tracks')
      .select('*')
      .eq('fund_id', queryFundId)
      .order('track_code', { ascending: true });

    if (error) return jsonResponse({ error: error.message }, 400);
    return jsonResponse(data || []);
  } else {
    return jsonResponse({ error: 'fund_id required' }, 400);
  }
}

// ============================================
// AGREEMENTS HANDLERS
// ============================================
async function handleAgreements(req: Request, supabase: any, userId: string, id?: string, action?: string) {
  const url = new URL(req.url);

  // Handle actions (submit, approve, reject, amend)
  if (id && action) {
    switch (action) {
      case 'submit':
        return await handleAgreementSubmit(supabase, id);
      case 'approve':
        return await handleAgreementApprove(supabase, userId, id);
      case 'reject':
        return await handleAgreementReject(supabase, userId, id, req);
      case 'amend':
        return await handleAgreementAmend(supabase, userId, id);
      default:
        return jsonResponse({ error: 'Invalid action' }, 400);
    }
  }

  switch (req.method) {
    case 'GET':
      if (id) {
        // GET /agreements/:id (with joined data)
        const { data, error } = await supabase
          .from('agreements')
          .select(`
            *,
            party:parties!agreements_party_id_fkey(name),
            fund:funds!agreements_fund_id_fkey(name),
            deal:deals!agreements_deal_id_fkey(name),
            custom_terms:agreement_custom_terms(*),
            snapshot:agreement_rate_snapshots(*)
          `)
          .eq('id', id)
          .single();

        if (error) return jsonResponse({ error: error.message }, 404);
        return jsonResponse(data);
      } else {
        // GET /agreements?party_id=&fund_id=&deal_id=&status=&limit=&offset=
        const partyId = url.searchParams.get('party_id');
        const fundId = url.searchParams.get('fund_id');
        const dealId = url.searchParams.get('deal_id');
        const status = url.searchParams.get('status');
        const limit = parseInt(url.searchParams.get('limit') || '50');
        const offset = parseInt(url.searchParams.get('offset') || '0');

        let query = supabase
          .from('agreements')
          .select(`
            *,
            party:parties!agreements_party_id_fkey(name),
            fund:funds!agreements_fund_id_fkey(name),
            deal:deals!agreements_deal_id_fkey(name)
          `, { count: 'exact' })
          .order('created_at', { ascending: false })
          .range(offset, offset + limit - 1);

        if (partyId) query = query.eq('party_id', partyId);
        if (fundId) query = query.eq('fund_id', fundId);
        if (dealId) query = query.eq('deal_id', dealId);
        if (status) query = query.eq('status', status);

        const { data, error, count } = await query;

        if (error) return jsonResponse({ error: error.message }, 400);
        return jsonResponse({ items: data || [], total: count || 0 });
      }

    case 'POST':
      // POST /agreements
      const body = await req.json();

      // Validate scope + pricing_mode combination
      if (body.scope === 'FUND' && body.pricing_mode !== 'TRACK') {
        return jsonResponse({ error: 'FUND-scoped agreements must use TRACK pricing' }, 400);
      }
      if (body.pricing_mode === 'TRACK' && !body.selected_track) {
        return jsonResponse({ error: 'TRACK pricing requires selected_track' }, 400);
      }

      // Insert agreement
      const { data: agreement, error: agreementError } = await supabase
        .from('agreements')
        .insert({
          party_id: body.party_id,
          investor_id: body.investor_id || null,
          kind: body.kind || 'distributor_commission',
          scope: body.scope,
          fund_id: body.fund_id || null,
          deal_id: body.deal_id || null,
          pricing_mode: body.pricing_mode,
          selected_track: body.selected_track || null,
          effective_from: body.effective_from,
          effective_to: body.effective_to || null,
          vat_included: body.vat_included !== undefined ? body.vat_included : false,
          status: 'DRAFT',
          created_by: userId,
        })
        .select('id')
        .single();

      if (agreementError) return jsonResponse({ error: agreementError.message }, 400);

      // If CUSTOM pricing, insert custom terms
      if (body.pricing_mode === 'CUSTOM' && body.custom_terms) {
        const { error: termsError } = await supabase
          .from('agreement_custom_terms')
          .insert({
            agreement_id: agreement.id,
            upfront_bps: body.custom_terms.upfront_bps,
            deferred_bps: body.custom_terms.deferred_bps,
            pricing_variant: body.custom_terms.pricing_variant || 'BPS',
            fixed_amount_cents: body.custom_terms.fixed_amount_cents || null,
            mgmt_fee_bps: body.custom_terms.mgmt_fee_bps || null,
            caps_json: body.custom_terms.caps_json || null,
            tiers_json: body.custom_terms.tiers_json || null,
          });

        if (termsError) return jsonResponse({ error: termsError.message }, 400);
      }

      return jsonResponse({ id: agreement.id }, 201);

    default:
      return jsonResponse({ error: 'Method not allowed' }, 405);
  }
}

// Agreement: Submit for approval
async function handleAgreementSubmit(supabase: any, id: string) {
  const { data, error } = await supabase
    .from('agreements')
    .update({
      status: 'AWAITING_APPROVAL',
      updated_at: new Date().toISOString(),
    })
    .eq('id', id)
    .eq('status', 'DRAFT')
    .select('status')
    .single();

  if (error) return jsonResponse({ error: 'Agreement not found or not in DRAFT status' }, 400);
  return jsonResponse({ status: data.status, message: 'Agreement submitted for approval' });
}

// Agreement: Approve (RBAC-gated)
async function handleAgreementApprove(supabase: any, userId: string, id: string) {
  // Check user roles
  const roles = await getUserRoles(supabase, userId);
  if (!hasAnyRole(roles, ['manager', 'admin'])) {
    return forbiddenError('Requires manager or admin role to approve agreements', corsHeaders);
  }

  // Update status to APPROVED (trigger will create snapshot)
  const { data, error } = await supabase
    .from('agreements')
    .update({
      status: 'APPROVED',
      updated_at: new Date().toISOString(),
    })
    .eq('id', id)
    .eq('status', 'AWAITING_APPROVAL')
    .select('status')
    .single();

  if (error) return jsonResponse({ error: 'Agreement not found or not awaiting approval' }, 400);
  return jsonResponse({ status: data.status, message: 'Agreement approved' });
}

// Agreement: Reject
async function handleAgreementReject(supabase: any, userId: string, id: string, req: Request) {
  const body = await req.json();
  if (!body.comment) {
    return jsonResponse({ error: 'Comment required for rejection' }, 400);
  }

  // Check user roles
  const roles = await getUserRoles(supabase, userId);
  if (!hasAnyRole(roles, ['manager', 'admin'])) {
    return forbiddenError('Requires manager or admin role to reject agreements', corsHeaders);
  }

  // Revert to DRAFT (removed notes field - doesn't exist in schema)
  const { data, error } = await supabase
    .from('agreements')
    .update({
      status: 'DRAFT',
      updated_at: new Date().toISOString(),
    })
    .eq('id', id)
    .eq('status', 'AWAITING_APPROVAL')
    .select('status')
    .single();

  if (error) return jsonResponse({ error: 'Agreement not found or not awaiting approval' }, 400);
  return jsonResponse({ status: data.status, message: 'Agreement rejected' });
}

// Agreement: Amend (creates new version)
async function handleAgreementAmend(supabase: any, userId: string, id: string) {
  // Get original agreement
  const { data: original, error: fetchError } = await supabase
    .from('agreements')
    .select(`
      *,
      custom_terms:agreement_custom_terms(*)
    `)
    .eq('id', id)
    .eq('status', 'APPROVED')
    .single();

  if (fetchError) return jsonResponse({ error: 'Agreement not found or not approved' }, 404);

  // Mark original as SUPERSEDED
  await supabase
    .from('agreements')
    .update({ status: 'SUPERSEDED' })
    .eq('id', id);

  // Create new DRAFT version
  const { data: newAgreement, error: insertError } = await supabase
    .from('agreements')
    .insert({
      party_id: original.party_id,
      scope: original.scope,
      fund_id: original.fund_id,
      deal_id: original.deal_id,
      pricing_mode: original.pricing_mode,
      selected_track: original.selected_track,
      effective_from: original.effective_from,
      effective_to: original.effective_to,
      vat_included: original.vat_included,
      status: 'DRAFT',
      created_by: userId,
      notes: `Amendment of Agreement #${id}`,
    })
    .select('id')
    .single();

  if (insertError) return jsonResponse({ error: insertError.message }, 400);

  // Copy custom terms if applicable
  if (original.pricing_mode === 'CUSTOM' && original.custom_terms && original.custom_terms.length > 0) {
    const terms = original.custom_terms[0];
    await supabase
      .from('agreement_custom_terms')
      .insert({
        agreement_id: newAgreement.id,
        upfront_bps: terms.upfront_bps,
        deferred_bps: terms.deferred_bps,
        caps_json: terms.caps_json,
        tiers_json: terms.tiers_json,
      });
  }

  return jsonResponse({
    new_agreement_id: newAgreement.id,
    message: `Amendment created (v2). Original #${id} marked SUPERSEDED.`
  });
}

// ============================================
// RUNS HANDLERS
// ============================================
async function handleRuns(req: Request, supabase: any, userId: string, id?: string, action?: string) {
  const url = new URL(req.url);

  // Handle actions (submit, approve, reject, generate)
  if (id && action) {
    switch (action) {
      case 'submit':
        return await handleRunSubmit(supabase, id);
      case 'approve':
        return await handleRunApprove(supabase, userId, id, req);
      case 'reject':
        return await handleRunReject(supabase, userId, id, req);
      case 'generate':
        return await handleRunGenerate(supabase, userId, id);
      default:
        return jsonResponse({ error: 'Invalid action' }, 400);
    }
  }

  switch (req.method) {
    case 'GET':
      if (id) {
        // GET /runs/:id
        const { data, error } = await supabase
          .from('calculation_runs')
          .select(`
            *,
            fund:funds!calculation_runs_fund_id_fkey(name)
          `)
          .eq('id', id)
          .single();

        if (error) return jsonResponse({ error: error.message }, 404);
        return jsonResponse(data);
      } else {
        // GET /runs?fund_id=&status=&limit=&offset=
        const fundId = url.searchParams.get('fund_id');
        const status = url.searchParams.get('status');
        const limit = parseInt(url.searchParams.get('limit') || '50');
        const offset = parseInt(url.searchParams.get('offset') || '0');

        let query = supabase
          .from('calculation_runs')
          .select(`
            *,
            fund:funds!calculation_runs_fund_id_fkey(name)
          `, { count: 'exact' })
          .order('created_at', { ascending: false })
          .range(offset, offset + limit - 1);

        if (fundId) query = query.eq('fund_id', fundId);
        if (status) query = query.eq('status', status);

        const { data, error, count } = await query;

        if (error) return jsonResponse({ error: error.message }, 400);
        return jsonResponse({ items: data || [], total: count || 0 });
      }

    case 'POST':
      // POST /runs
      const body = await req.json();
      const { data, error } = await supabase
        .from('calculation_runs')
        .insert({
          fund_id: body.fund_id,
          period_from: body.period_from,
          period_to: body.period_to,
          status: 'DRAFT',
          created_by: userId,
        })
        .select('id, status')
        .single();

      if (error) return jsonResponse({ error: error.message }, 400);
      return jsonResponse({ id: data.id, status: data.status }, 201);

    default:
      return jsonResponse({ error: 'Method not allowed' }, 405);
  }
}

// Run: Submit for approval
async function handleRunSubmit(supabase: any, id: string) {
  const { data, error } = await supabase
    .from('calculation_runs')
    .update({
      status: 'AWAITING_APPROVAL',
      updated_at: new Date().toISOString(),
    })
    .eq('id', id)
    .in('status', ['DRAFT', 'IN_PROGRESS'])
    .select('status')
    .single();

  if (error) return jsonResponse({ error: 'Run not found or invalid status' }, 400);
  return jsonResponse({ status: data.status, message: 'Run submitted for approval' });
}

// Run: Approve (RBAC-gated)
async function handleRunApprove(supabase: any, userId: string, id: string, req: Request) {
  // Check user roles
  const roles = await getUserRoles(supabase, userId);
  if (!hasAnyRole(roles, ['manager', 'admin'])) {
    return forbiddenError('Requires manager or admin role to approve runs', corsHeaders);
  }

  const body = await req.json().catch(() => ({}));

  const { data, error } = await supabase
    .from('calculation_runs')
    .update({
      status: 'APPROVED',
      updated_at: new Date().toISOString(),
    })
    .eq('id', id)
    .eq('status', 'AWAITING_APPROVAL')
    .select('status')
    .single();

  if (error) return jsonResponse({ error: 'Run not found or not awaiting approval' }, 400);
  return jsonResponse({ status: data.status, message: 'Run approved' });
}

// Run: Reject
async function handleRunReject(supabase: any, userId: string, id: string, req: Request) {
  const body = await req.json();
  if (!body.comment) {
    return jsonResponse({ error: 'Comment required for rejection' }, 400);
  }

  const { data, error } = await supabase
    .from('calculation_runs')
    .update({
      status: 'IN_PROGRESS',
      updated_at: new Date().toISOString(),
    })
    .eq('id', id)
    .eq('status', 'AWAITING_APPROVAL')
    .select('status')
    .single();

  if (error) return jsonResponse({ error: 'Run not found or not awaiting approval' }, 400);
  return jsonResponse({ status: data.status, message: 'Run rejected' });
}

// Run: Generate calculation (only when APPROVED)
async function handleRunGenerate(supabase: any, userId: string, id: string) {
  // Check run is APPROVED
  const { data: run, error: fetchError } = await supabase
    .from('calculation_runs')
    .select('id, status, fund_id, period_from, period_to')
    .eq('id', id)
    .eq('status', 'APPROVED')
    .single();

  if (fetchError) return jsonResponse({ error: 'Run not found or not approved' }, 404);

  // TODO: Implement actual calculation logic
  // For now, return mock response
  return jsonResponse({
    summary: {
      fees_total: 0,
      lines: 0,
    },
    export: {
      csv_path: `/exports/run-${id}-${new Date().toISOString()}.csv`,
    },
  });
}

// ============================================
// CONTRIBUTIONS HANDLERS
// ============================================
async function handleContributions(req: Request, supabase: any, userId: string, id?: string, action?: string) {
  const url = new URL(req.url);

  // Handle /contributions/batch
  if (id === 'batch' && req.method === 'POST') {
    return await handleContributionsBatch(req, supabase);
  }

  switch (req.method) {
    case 'GET':
      // GET /contributions?fund_id=&deal_id=&investor_id=&from=&to=&batch=
      const q = supabase.from('contributions').select('*').order('paid_in_date', { ascending: true });

      const fundId = url.searchParams.get('fund_id');
      const dealId = url.searchParams.get('deal_id');
      const invId = url.searchParams.get('investor_id');
      const from = url.searchParams.get('from');
      const to = url.searchParams.get('to');
      const batch = url.searchParams.get('batch');

      if (fundId) q.eq('fund_id', Number(fundId));
      if (dealId) q.eq('deal_id', Number(dealId));
      if (invId) q.eq('investor_id', Number(invId));
      if (batch) q.eq('source_batch', batch);
      if (from) q.gte('paid_in_date', from);
      if (to) q.lte('paid_in_date', to);

      const { data, error } = await q;
      if (error) return mapPgErrorToHttp(error);
      return jsonResponse({ items: data, total: data?.length ?? 0 });

    case 'POST':
      // POST /contributions
      const body = await req.json();
      const v = validateContributionPayload(body);
      if (!v.ok) return validationError(v.details, corsHeaders);

      const { data: insertData, error: insertError } = await supabase
        .from('contributions')
        .insert([{
          investor_id: body.investor_id,
          deal_id: body.deal_id ?? null,
          fund_id: body.fund_id ?? null,
          paid_in_date: body.paid_in_date,
          amount: body.amount,
          currency: body.currency ?? 'USD',
          fx_rate: body.fx_rate ?? null,
          source_batch: body.source_batch ?? null,
        }])
        .select()
        .single();

      if (insertError) return mapPgErrorToApiError(insertError, corsHeaders);
      return successResponse({ id: insertData.id }, 201, corsHeaders);

    default:
      return jsonResponse({ error: 'Method not allowed' }, 405);
  }
}

// POST /contributions/batch
async function handleContributionsBatch(req: Request, supabase: any) {
  const body = await req.json();

  if (!Array.isArray(body)) {
    return validationError([{ message: 'Request body must be an array of contributions' }], corsHeaders);
  }

  // Pre-validate all rows to avoid partial failures
  const pre = body.map((row, i) => ({ row: i, v: validateContributionPayload(row) }));
  const bad = pre.filter(r => !r.v.ok);

  if (bad.length) {
    // Flatten all errors with row numbers
    const allDetails: ApiErrorDetail[] = bad.flatMap(b =>
      (b.v as any).details.map((d: ApiErrorDetail) => ({
        ...d,
        row: b.row + 1, // 1-indexed for user display
      }))
    );

    return validationError(allDetails, corsHeaders);
  }

  const payload = body.map(row => ({
    investor_id: row.investor_id,
    deal_id: row.deal_id ?? null,
    fund_id: row.fund_id ?? null,
    paid_in_date: row.paid_in_date,
    amount: row.amount,
    currency: row.currency ?? 'USD',
    fx_rate: row.fx_rate ?? null,
    source_batch: row.source_batch ?? null,
  }));

  const { data, error } = await supabase.from('contributions').insert(payload).select('id');
  if (error) return mapPgErrorToApiError(error, corsHeaders);
  return successResponse({ inserted: data.map((x: any) => x.id) }, 201, corsHeaders);
}
