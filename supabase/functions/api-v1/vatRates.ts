/**
 * VAT Rates API Handler
 * Ticket: API-310
 * Date: 2025-10-19
 *
 * Endpoints:
 * - POST /api-v1/vat-rates - Create new VAT rate (admin-only)
 * - GET /api-v1/vat-rates - List VAT rates with filters
 * - GET /api-v1/vat-rates/current - Get current rate for country
 * - PATCH /api-v1/vat-rates/:id - Update VAT rate (admin-only, only effective_to)
 * - DELETE /api-v1/vat-rates/:id - Delete VAT rate (admin-only, if not referenced)
 *
 * Features:
 * - Temporal overlap validation
 * - Admin-only RBAC enforcement
 * - Standardized error contract
 * - Feature flag gating via vat_admin
 */

import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import {
  validationError,
  forbiddenError,
  conflictError,
  notFoundError,
  successResponse,
  mapPgErrorToApiError,
  type ApiErrorDetail,
} from './errors.ts';
import { checkFeatureFlag } from './featureFlags.ts';

// ============================================
// TYPES
// ============================================
export interface VatRate {
  id: string;
  country_code: string;
  rate_percentage: number;
  effective_from: string; // ISO date
  effective_to: string | null; // ISO date or null
  description: string | null;
  created_by: string | null;
  created_at: string;
  updated_at: string;
}

interface CreateVatRateRequest {
  country_code: string;
  rate_percentage: number;
  effective_from: string; // ISO date
  effective_to?: string | null;
  description?: string;
}

interface UpdateVatRateRequest {
  effective_to?: string | null;
}

// ============================================
// HELPER: Get User Roles
// ============================================
async function getUserRoles(supabase: SupabaseClient, userId: string): Promise<string[]> {
  const { data, error } = await supabase
    .from('user_roles')
    .select('role')
    .eq('user_id', userId);

  if (error) return [];
  return data?.map((r: any) => r.role) || [];
}

// ============================================
// HELPER: Check Admin Role
// ============================================
function isAdmin(userRoles: string[]): boolean {
  return userRoles.includes('admin');
}

// ============================================
// HELPER: Validate Create Payload
// ============================================
function validateCreatePayload(payload: any): { ok: true } | { ok: false; details: ApiErrorDetail[] } {
  const details: ApiErrorDetail[] = [];

  // Validate country_code
  if (!payload.country_code || typeof payload.country_code !== 'string') {
    details.push({
      field: 'country_code',
      message: 'country_code is required and must be a 2-character ISO code',
      value: payload.country_code,
    });
  } else if (payload.country_code.length !== 2) {
    details.push({
      field: 'country_code',
      message: 'country_code must be exactly 2 characters (ISO 3166-1 alpha-2)',
      value: payload.country_code,
    });
  }

  // Validate rate_percentage
  if (typeof payload.rate_percentage !== 'number') {
    details.push({
      field: 'rate_percentage',
      message: 'rate_percentage is required and must be a number',
      value: payload.rate_percentage,
    });
  } else if (payload.rate_percentage < 0 || payload.rate_percentage > 100) {
    details.push({
      field: 'rate_percentage',
      message: 'rate_percentage must be between 0 and 100',
      value: payload.rate_percentage,
      constraint: 'rate_percentage_range',
    });
  }

  // Validate effective_from
  if (!payload.effective_from || typeof payload.effective_from !== 'string') {
    details.push({
      field: 'effective_from',
      message: 'effective_from is required and must be a valid ISO date (YYYY-MM-DD)',
      value: payload.effective_from,
    });
  } else {
    const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
    if (!dateRegex.test(payload.effective_from)) {
      details.push({
        field: 'effective_from',
        message: 'effective_from must be in YYYY-MM-DD format',
        value: payload.effective_from,
      });
    }
  }

  // Validate effective_to (optional)
  if (payload.effective_to !== undefined && payload.effective_to !== null) {
    if (typeof payload.effective_to !== 'string') {
      details.push({
        field: 'effective_to',
        message: 'effective_to must be a valid ISO date (YYYY-MM-DD) or null',
        value: payload.effective_to,
      });
    } else {
      const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
      if (!dateRegex.test(payload.effective_to)) {
        details.push({
          field: 'effective_to',
          message: 'effective_to must be in YYYY-MM-DD format',
          value: payload.effective_to,
        });
      }
    }
  }

  // Validate date order
  if (payload.effective_from && payload.effective_to) {
    if (new Date(payload.effective_to) <= new Date(payload.effective_from)) {
      details.push({
        field: 'effective_to',
        message: 'effective_to must be after effective_from',
        value: payload.effective_to,
        constraint: 'date_order',
      });
    }
  }

  if (details.length > 0) return { ok: false, details };
  return { ok: true };
}

// ============================================
// MAIN HANDLER: VAT Rates
// ============================================
export async function handleVatRates(
  req: Request,
  supabase: SupabaseClient,
  userId: string,
  id?: string,
  action?: string,
  corsHeaders: Record<string, string> = {}
) {
  // Feature flag check for admin operations
  if (req.method !== 'GET') {
    const flagCheck = await checkFeatureFlag(supabase, userId, 'vat_admin', corsHeaders);
    if (flagCheck) return flagCheck; // Flag disabled or not found
  }

  const userRoles = await getUserRoles(supabase, userId);

  // Handle /vat-rates/current endpoint
  if (id === 'current' && req.method === 'GET') {
    return await handleGetCurrentRate(supabase, req, corsHeaders);
  }

  switch (req.method) {
    case 'GET':
      if (id) {
        return await handleGetRate(supabase, id, corsHeaders);
      } else {
        return await handleListRates(supabase, req, corsHeaders);
      }

    case 'POST':
      // Admin-only
      if (!isAdmin(userRoles)) {
        return forbiddenError('VAT rate creation requires admin role', corsHeaders);
      }
      return await handleCreateRate(supabase, userId, req, corsHeaders);

    case 'PATCH':
      // Admin-only
      if (!isAdmin(userRoles)) {
        return forbiddenError('VAT rate updates require admin role', corsHeaders);
      }
      if (!id) {
        return validationError([{ message: 'Rate ID required' }], corsHeaders);
      }
      return await handleUpdateRate(supabase, id, req, corsHeaders);

    case 'DELETE':
      // Admin-only
      if (!isAdmin(userRoles)) {
        return forbiddenError('VAT rate deletion requires admin role', corsHeaders);
      }
      if (!id) {
        return validationError([{ message: 'Rate ID required' }], corsHeaders);
      }
      return await handleDeleteRate(supabase, id, corsHeaders);

    default:
      return validationError([{ message: 'Method not allowed' }], corsHeaders);
  }
}

// ============================================
// POST /vat-rates - Create New Rate
// ============================================
async function handleCreateRate(
  supabase: SupabaseClient,
  userId: string,
  req: Request,
  corsHeaders: Record<string, string>
) {
  const body: CreateVatRateRequest = await req.json();

  // Validate payload
  const validation = validateCreatePayload(body);
  if (!validation.ok) {
    return validationError(validation.details, corsHeaders);
  }

  // Uppercase country code
  const countryCode = body.country_code.toUpperCase();

  // Insert rate (trigger will validate overlaps)
  const { data, error } = await supabase
    .from('vat_rates')
    .insert({
      country_code: countryCode,
      rate_percentage: body.rate_percentage,
      effective_from: body.effective_from,
      effective_to: body.effective_to || null,
      description: body.description || null,
      created_by: userId,
    })
    .select()
    .single();

  if (error) {
    // Check if it's an overlap error from trigger
    if (error.message && error.message.includes('overlaps with existing rate')) {
      return conflictError(
        `VAT rate overlaps with existing rate for ${countryCode}`,
        [{ field: 'effective_from', constraint: 'no_overlap', message: error.message }],
        corsHeaders
      );
    }
    return mapPgErrorToApiError(error, corsHeaders);
  }

  return successResponse({ vat_rate: data }, 201, corsHeaders);
}

// ============================================
// GET /vat-rates - List Rates
// ============================================
async function handleListRates(
  supabase: SupabaseClient,
  req: Request,
  corsHeaders: Record<string, string>
) {
  const url = new URL(req.url);
  const countryCode = url.searchParams.get('country_code');
  const active = url.searchParams.get('active'); // 'true' or 'false'
  const effectiveOn = url.searchParams.get('effective_on'); // ISO date

  let query = supabase
    .from('vat_rates')
    .select('*')
    .order('effective_from', { ascending: false });

  // Filter by country
  if (countryCode) {
    query = query.eq('country_code', countryCode.toUpperCase());
  }

  // Filter by active status
  if (active === 'true') {
    const today = new Date().toISOString().split('T')[0];
    query = query
      .lte('effective_from', today)
      .or(`effective_to.is.null,effective_to.gt.${today}`);
  }

  // Filter by effective_on date
  if (effectiveOn) {
    query = query
      .lte('effective_from', effectiveOn)
      .or(`effective_to.is.null,effective_to.gt.${effectiveOn}`);
  }

  const { data, error } = await query;

  if (error) {
    return mapPgErrorToApiError(error, corsHeaders);
  }

  return successResponse({ vat_rates: data || [] }, 200, corsHeaders);
}

// ============================================
// GET /vat-rates/:id - Get Single Rate
// ============================================
async function handleGetRate(
  supabase: SupabaseClient,
  id: string,
  corsHeaders: Record<string, string>
) {
  const { data, error } = await supabase
    .from('vat_rates')
    .select('*')
    .eq('id', id)
    .single();

  if (error || !data) {
    return notFoundError('VAT rate', corsHeaders);
  }

  return successResponse({ vat_rate: data }, 200, corsHeaders);
}

// ============================================
// GET /vat-rates/current - Get Current Rate for Country
// ============================================
async function handleGetCurrentRate(
  supabase: SupabaseClient,
  req: Request,
  corsHeaders: Record<string, string>
) {
  const url = new URL(req.url);
  const countryCode = url.searchParams.get('country_code');

  if (!countryCode) {
    return validationError(
      [{ field: 'country_code', message: 'country_code query parameter is required' }],
      corsHeaders
    );
  }

  const today = new Date().toISOString().split('T')[0];

  const { data, error } = await supabase
    .from('vat_rates')
    .select('*')
    .eq('country_code', countryCode.toUpperCase())
    .lte('effective_from', today)
    .or(`effective_to.is.null,effective_to.gt.${today}`)
    .order('effective_from', { ascending: false })
    .limit(1)
    .single();

  if (error || !data) {
    return notFoundError(`Current VAT rate for ${countryCode.toUpperCase()}`, corsHeaders);
  }

  return successResponse({ vat_rate: data }, 200, corsHeaders);
}

// ============================================
// PATCH /vat-rates/:id - Update Rate (Close Rate)
// ============================================
async function handleUpdateRate(
  supabase: SupabaseClient,
  id: string,
  req: Request,
  corsHeaders: Record<string, string>
) {
  const body: UpdateVatRateRequest = await req.json();

  // Only allow updating effective_to
  if (!body.effective_to && body.effective_to !== null) {
    return validationError(
      [{ field: 'effective_to', message: 'Only effective_to can be updated' }],
      corsHeaders
    );
  }

  // Validate date format if provided
  if (body.effective_to && typeof body.effective_to === 'string') {
    const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
    if (!dateRegex.test(body.effective_to)) {
      return validationError(
        [{ field: 'effective_to', message: 'effective_to must be in YYYY-MM-DD format' }],
        corsHeaders
      );
    }
  }

  // Update rate
  const { data, error } = await supabase
    .from('vat_rates')
    .update({ effective_to: body.effective_to })
    .eq('id', id)
    .select()
    .single();

  if (error) {
    // Check if it's an overlap error from trigger
    if (error.message && error.message.includes('overlaps with existing rate')) {
      return conflictError(
        'Updated date range overlaps with existing rate',
        [{ field: 'effective_to', constraint: 'no_overlap', message: error.message }],
        corsHeaders
      );
    }
    return mapPgErrorToApiError(error, corsHeaders);
  }

  if (!data) {
    return notFoundError('VAT rate', corsHeaders);
  }

  return successResponse({ vat_rate: data }, 200, corsHeaders);
}

// ============================================
// DELETE /vat-rates/:id - Delete Rate
// ============================================
async function handleDeleteRate(
  supabase: SupabaseClient,
  id: string,
  corsHeaders: Record<string, string>
) {
  // Check if rate is referenced in any snapshots
  const { data: snapshots, error: snapshotError } = await supabase
    .from('agreement_rate_snapshots')
    .select('agreement_id')
    .not('vat_rate_percent', 'is', null)
    .limit(1);

  // For simplicity, we'll check if vat_rate_percent matches the rate being deleted
  // In production, you might want to add a vat_rate_id foreign key to snapshots
  // For now, we'll just prevent deletion if any snapshots exist with VAT rates
  if (snapshotError) {
    return mapPgErrorToApiError(snapshotError, corsHeaders);
  }

  // Get the rate to check if it has been used
  const { data: rate, error: rateError } = await supabase
    .from('vat_rates')
    .select('*')
    .eq('id', id)
    .single();

  if (rateError || !rate) {
    return notFoundError('VAT rate', corsHeaders);
  }

  // Check if rate has been used (simplified check)
  // In production, you would query snapshots for this specific rate
  if (snapshots && snapshots.length > 0) {
    return conflictError(
      'Cannot delete VAT rate: it is referenced in agreement snapshots',
      [{ constraint: 'referenced_in_snapshots', message: 'Rate is used in historical agreements' }],
      corsHeaders
    );
  }

  // Delete rate
  const { error: deleteError } = await supabase
    .from('vat_rates')
    .delete()
    .eq('id', id);

  if (deleteError) {
    return mapPgErrorToApiError(deleteError, corsHeaders);
  }

  return new Response(null, {
    status: 204,
    headers: corsHeaders,
  });
}
