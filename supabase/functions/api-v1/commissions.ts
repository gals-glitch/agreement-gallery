/**
 * Commissions API Endpoints
 *
 * Endpoints:
 * - POST /commissions/compute           - Compute commission for single contribution
 * - POST /commissions/batch-compute     - Compute commissions for multiple contributions
 * - GET  /commissions                   - List commissions with filters
 * - GET  /commissions/:id               - Get single commission
 * - POST /commissions/:id/submit        - Submit commission for approval (draft → pending)
 * - POST /commissions/:id/approve       - Approve commission (pending → approved) [Admin only]
 * - POST /commissions/:id/reject        - Reject commission (pending → rejected) [Admin only]
 * - POST /commissions/:id/mark-paid     - Mark commission as paid (approved → paid) [Admin only, NO service key]
 */

import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { computeCommissionForContribution, batchComputeCommissions } from './commissionCompute.ts';
import {
  validationError,
  forbiddenError,
  notFoundError,
  successResponse,
  mapPgErrorToApiError,
  conflictError,
  internalError,
} from './errors.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// ============================================
// Main Handler (Router)
// ============================================

export async function handleCommissions(
  req: Request,
  supabase: SupabaseClient,
  userId: string,
  url: URL
): Promise<Response> {
  const method = req.method;
  const pathParts = url.pathname.split('/').filter(Boolean);
  // Clean path: remove 'api-v1' if present (Supabase adds function name to path)
  const cleanPath = pathParts.filter(p => p !== 'api-v1');
  // cleanPath should now be: ['commissions'] or ['commissions', 'compute'] or ['commissions', 'id', 'submit']

  // POST /commissions/compute
  if (cleanPath.length === 2 && cleanPath[1] === 'compute' && method === 'POST') {
    return await handleComputeCommission(req, supabase, userId);
  }

  // POST /commissions/batch-compute
  if (cleanPath.length === 2 && cleanPath[1] === 'batch-compute' && method === 'POST') {
    return await handleBatchCompute(req, supabase, userId);
  }

  // GET /commissions (list)
  if (cleanPath.length === 1 && method === 'GET') {
    return await handleListCommissions(req, supabase, userId, url);
  }

  // GET /commissions/:id
  if (cleanPath.length === 2 && method === 'GET') {
    const commissionId = cleanPath[1];
    return await handleGetCommission(supabase, userId, commissionId);
  }

  // POST /commissions/:id/submit
  if (cleanPath.length === 3 && cleanPath[2] === 'submit' && method === 'POST') {
    const commissionId = cleanPath[1];
    return await handleSubmitCommission(supabase, userId, commissionId);
  }

  // POST /commissions/:id/approve
  if (cleanPath.length === 3 && cleanPath[2] === 'approve' && method === 'POST') {
    const commissionId = cleanPath[1];
    return await handleApproveCommission(supabase, userId, commissionId);
  }

  // POST /commissions/:id/reject
  if (cleanPath.length === 3 && cleanPath[2] === 'reject' && method === 'POST') {
    const commissionId = cleanPath[1];
    return await handleRejectCommission(req, supabase, userId, commissionId);
  }

  // POST /commissions/:id/mark-paid
  if (cleanPath.length === 3 && cleanPath[2] === 'mark-paid' && method === 'POST') {
    const commissionId = cleanPath[1];
    // Check if service key (service keys NOT allowed for mark-paid)
    if (userId === 'SERVICE') {
      return forbiddenError(
        'Service keys cannot mark commissions as paid. Use Admin JWT.',
        corsHeaders
      );
    }
    return await handleMarkPaid(req, supabase, userId, commissionId);
  }

  return validationError('Invalid commissions endpoint', corsHeaders);
}

// ============================================
// POST /commissions/compute
// ============================================

async function handleComputeCommission(
  req: Request,
  supabase: SupabaseClient,
  userId: string
): Promise<Response> {
  try {
    const body = await req.json();
    const { contribution_id } = body;

    if (!contribution_id) {
      return validationError('contribution_id is required', corsHeaders);
    }

    const result = await computeCommissionForContribution({
      supabase,
      contributionId: Number(contribution_id),
    });

    return successResponse({ data: result }, 200, corsHeaders);
  } catch (error) {
    console.error('Compute commission error:', error);
    return internalError(error instanceof Error ? error.message : 'Unknown error', corsHeaders);
  }
}

// ============================================
// POST /commissions/batch-compute
// ============================================

async function handleBatchCompute(
  req: Request,
  supabase: SupabaseClient,
  userId: string
): Promise<Response> {
  try {
    const body = await req.json();
    const { contribution_ids } = body;

    if (!contribution_ids || !Array.isArray(contribution_ids)) {
      return validationError('contribution_ids array is required', corsHeaders);
    }

    const { results } = await batchComputeCommissions({
      supabase,
      contributionIds: contribution_ids.map(Number),
    });

    return successResponse({
      count: results.length,
      results,
    }, 200, corsHeaders);
  } catch (error) {
    console.error('Batch compute error:', error);
    return internalError(error instanceof Error ? error.message : 'Unknown error', corsHeaders);
  }
}

// ============================================
// GET /commissions (list with filters)
// ============================================

async function handleListCommissions(
  req: Request,
  supabase: SupabaseClient,
  userId: string,
  url: URL
): Promise<Response> {
  try {
    const status = url.searchParams.get('status');
    const partyId = url.searchParams.get('party_id');
    const investorId = url.searchParams.get('investor_id');
    const dealId = url.searchParams.get('deal_id');
    const fundId = url.searchParams.get('fund_id');
    const from = url.searchParams.get('from');
    const to = url.searchParams.get('to');

    let query = supabase
      .from('commissions')
      .select(`
        *,
        parties!commissions_party_id_fkey(id, name),
        investors!commissions_investor_id_fkey(id, name),
        deals!commissions_deal_id_fkey(id, name),
        funds!commissions_fund_id_fkey(id, name)
      `, { count: 'exact' })
      .order('created_at', { ascending: false });

    if (status) query = query.eq('status', status);
    if (partyId) query = query.eq('party_id', parseInt(partyId));
    if (investorId) query = query.eq('investor_id', parseInt(investorId));
    if (dealId) query = query.eq('deal_id', parseInt(dealId));
    if (fundId) query = query.eq('fund_id', parseInt(fundId));
    if (from) query = query.gte('computed_at', from);
    if (to) query = query.lte('computed_at', to);

    const { data, error, count } = await query;

    if (error) {
      return mapPgErrorToApiError(error, corsHeaders);
    }

    // Transform data to match frontend expectations
    const transformedData = (data || []).map((commission: any) => ({
      ...commission,
      party_name: commission.parties?.name || '',
      investor_name: commission.investors?.name || '',
      fund_name: commission.funds?.name || null,
      deal_name: commission.deals?.name || null,
      contribution_amount: commission.snapshot_json?.contribution_amount || 0,
    }));

    return successResponse({
      data: transformedData,
      total: count || 0,
    }, 200, corsHeaders);
  } catch (error) {
    console.error('List commissions error:', error);
    return internalError(error instanceof Error ? error.message : 'Unknown error', corsHeaders);
  }
}

// ============================================
// GET /commissions/:id
// ============================================

async function handleGetCommission(
  supabase: SupabaseClient,
  userId: string,
  commissionId: string
): Promise<Response> {
  try {
    const { data, error } = await supabase
      .from('commissions')
      .select(`
        *,
        parties!commissions_party_id_fkey(id, name),
        investors!commissions_investor_id_fkey(id, name),
        deals!commissions_deal_id_fkey(id, name),
        funds!commissions_fund_id_fkey(id, name),
        contributions!commissions_contribution_id_fkey(id, amount, paid_in_date)
      `)
      .eq('id', commissionId)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return notFoundError('Commission not found', corsHeaders);
      }
      return mapPgErrorToApiError(error, corsHeaders);
    }

    // Transform data to match frontend expectations
    const transformedData = {
      ...data,
      party_name: (data as any).parties?.name || '',
      investor_name: (data as any).investors?.name || '',
      fund_name: (data as any).funds?.name || null,
      deal_name: (data as any).deals?.name || null,
      contribution_amount: (data as any).contributions?.amount || (data as any).snapshot_json?.contribution_amount || 0,
    };

    return successResponse({ data: transformedData }, 200, corsHeaders);
  } catch (error) {
    console.error('Get commission error:', error);
    return internalError(error instanceof Error ? error.message : 'Unknown error', corsHeaders);
  }
}

// ============================================
// POST /commissions/:id/submit
// ============================================

async function handleSubmitCommission(
  supabase: SupabaseClient,
  userId: string,
  commissionId: string
): Promise<Response> {
  try {
    // Get current commission
    const { data: commission, error: fetchError } = await supabase
      .from('commissions')
      .select('*')
      .eq('id', commissionId)
      .single();

    if (fetchError || !commission) {
      return notFoundError('Commission not found', corsHeaders);
    }

    // Check status
    if (commission.status !== 'draft') {
      return conflictError(
        `Commission is already ${commission.status}. Can only submit draft commissions.`,
        corsHeaders
      );
    }

    // Update status to pending
    const { data, error: updateError } = await supabase
      .from('commissions')
      .update({
        status: 'pending',
        submitted_at: new Date().toISOString(),
      })
      .eq('id', commissionId)
      .select()
      .single();

    if (updateError) {
      return mapPgErrorToApiError(updateError, corsHeaders);
    }

    // Log audit event
    await supabase.from('audit_log').insert({
      event_type: 'commission.submitted',
      actor_id: userId === 'SERVICE' ? null : userId,
      resource_type: 'commission',
      resource_id: commissionId,
      payload: { commission_id: commissionId, status: 'pending' },
    });

    return successResponse({ data }, 200, corsHeaders);
  } catch (error) {
    console.error('Submit commission error:', error);
    return internalError(error instanceof Error ? error.message : 'Unknown error', corsHeaders);
  }
}

// ============================================
// POST /commissions/:id/approve (Admin only)
// ============================================

async function handleApproveCommission(
  supabase: SupabaseClient,
  userId: string,
  commissionId: string
): Promise<Response> {
  try {
    // Check admin role (service keys allowed)
    const isAdmin = userId === 'SERVICE' || await checkAdminRole(supabase, userId);
    if (!isAdmin) {
      return forbiddenError('Only admins can approve commissions', corsHeaders);
    }

    // Get current commission
    const { data: commission, error: fetchError } = await supabase
      .from('commissions')
      .select('*')
      .eq('id', commissionId)
      .single();

    if (fetchError || !commission) {
      return notFoundError('Commission not found', corsHeaders);
    }

    // Check status
    if (commission.status !== 'pending') {
      return conflictError(
        `Commission is ${commission.status}. Can only approve pending commissions.`,
        corsHeaders
      );
    }

    // Update status to approved
    const { data, error: updateError } = await supabase
      .from('commissions')
      .update({
        status: 'approved',
        approved_at: new Date().toISOString(),
        approved_by: userId === 'SERVICE' ? null : userId,
      })
      .eq('id', commissionId)
      .select()
      .single();

    if (updateError) {
      return mapPgErrorToApiError(updateError, corsHeaders);
    }

    // Log audit event
    await supabase.from('audit_log').insert({
      event_type: 'commission.approved',
      actor_id: userId === 'SERVICE' ? null : userId,
      resource_type: 'commission',
      resource_id: commissionId,
      payload: { commission_id: commissionId, status: 'approved' },
    });

    return successResponse({ data }, 200, corsHeaders);
  } catch (error) {
    console.error('Approve commission error:', error);
    return internalError(error instanceof Error ? error.message : 'Unknown error', corsHeaders);
  }
}

// ============================================
// POST /commissions/:id/reject (Admin only)
// ============================================

async function handleRejectCommission(
  req: Request,
  supabase: SupabaseClient,
  userId: string,
  commissionId: string
): Promise<Response> {
  try {
    // Check admin role (service keys allowed)
    const isAdmin = userId === 'SERVICE' || await checkAdminRole(supabase, userId);
    if (!isAdmin) {
      return forbiddenError('Only admins can reject commissions', corsHeaders);
    }

    const body = await req.json();
    const { reject_reason } = body;

    if (!reject_reason) {
      return validationError('reject_reason is required', corsHeaders);
    }

    // Get current commission
    const { data: commission, error: fetchError } = await supabase
      .from('commissions')
      .select('*')
      .eq('id', commissionId)
      .single();

    if (fetchError || !commission) {
      return notFoundError('Commission not found', corsHeaders);
    }

    // Check status
    if (commission.status !== 'pending') {
      return conflictError(
        `Commission is ${commission.status}. Can only reject pending commissions.`,
        corsHeaders
      );
    }

    // Update status to rejected
    const { data, error: updateError } = await supabase
      .from('commissions')
      .update({
        status: 'rejected',
        rejected_at: new Date().toISOString(),
        rejected_by: userId === 'SERVICE' ? null : userId,
        reject_reason,
      })
      .eq('id', commissionId)
      .select()
      .single();

    if (updateError) {
      return mapPgErrorToApiError(updateError, corsHeaders);
    }

    // Log audit event
    await supabase.from('audit_log').insert({
      event_type: 'commission.rejected',
      actor_id: userId === 'SERVICE' ? null : userId,
      resource_type: 'commission',
      resource_id: commissionId,
      payload: { commission_id: commissionId, status: 'rejected', reject_reason },
    });

    return successResponse({ data }, 200, corsHeaders);
  } catch (error) {
    console.error('Reject commission error:', error);
    return internalError(error instanceof Error ? error.message : 'Unknown error', corsHeaders);
  }
}

// ============================================
// POST /commissions/:id/mark-paid (Admin only, NO service key)
// ============================================

async function handleMarkPaid(
  req: Request,
  supabase: SupabaseClient,
  userId: string,
  commissionId: string
): Promise<Response> {
  try {
    // Check admin role (NO service keys)
    const isAdmin = await checkAdminRole(supabase, userId);
    if (!isAdmin) {
      return forbiddenError('Only admins can mark commissions as paid', corsHeaders);
    }

    const body = await req.json();
    const { payment_ref } = body;

    // Get current commission
    const { data: commission, error: fetchError } = await supabase
      .from('commissions')
      .select('*')
      .eq('id', commissionId)
      .single();

    if (fetchError || !commission) {
      return notFoundError('Commission not found', corsHeaders);
    }

    // Check status
    if (commission.status !== 'approved') {
      return conflictError(
        `Commission is ${commission.status}. Can only mark approved commissions as paid.`,
        corsHeaders
      );
    }

    // Update status to paid
    const { data, error: updateError } = await supabase
      .from('commissions')
      .update({
        status: 'paid',
        paid_at: new Date().toISOString(),
        payment_ref: payment_ref || null,
      })
      .eq('id', commissionId)
      .select()
      .single();

    if (updateError) {
      return mapPgErrorToApiError(updateError, corsHeaders);
    }

    // Log audit event
    await supabase.from('audit_log').insert({
      event_type: 'commission.paid',
      actor_id: userId,
      resource_type: 'commission',
      resource_id: commissionId,
      payload: { commission_id: commissionId, status: 'paid', payment_ref },
    });

    return successResponse({ data }, 200, corsHeaders);
  } catch (error) {
    console.error('Mark paid error:', error);
    return internalError(error instanceof Error ? error.message : 'Unknown error', corsHeaders);
  }
}

// ============================================
// Helper: Check Admin Role
// ============================================

async function checkAdminRole(supabase: SupabaseClient, userId: string): Promise<boolean> {
  if (!userId || userId === 'SERVICE') return false;

  const { data, error } = await supabase
    .from('user_roles')
    .select('role_key')
    .eq('user_id', userId)
    .eq('role_key', 'admin')
    .single();

  return !error && !!data;
}
