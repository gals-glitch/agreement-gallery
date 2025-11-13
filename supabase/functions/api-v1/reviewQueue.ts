/**
 * Review Queue API Handler - Referrer Matching Review Queue (T09)
 * Ticket: P2 Move 2A
 * Date: 2025-10-21
 *
 * Purpose:
 * Manage manual review and resolution of fuzzy-matched referrer names.
 * When fuzzy matching scores 80-89, matches are queued for human review.
 * Admins/Finance can view pending matches and resolve them (approve or reject).
 *
 * Endpoints:
 * - GET /api-v1/review/referrers?status=pending|resolved - List review queue items
 * - POST /api-v1/review/referrers/:id/resolve - Resolve a review item
 *
 * RBAC:
 * - Admin and Finance roles only
 *
 * Workflow:
 * 1. Import service queues ambiguous matches (score 80-89)
 * 2. Admin/Finance reviews via GET /review/referrers?status=pending
 * 3. Admin/Finance resolves via POST /review/referrers/:id/resolve
 * 4. On resolution: Update investor source fields with approved party_id
 * 5. Audit log created with "resolver.applied" event
 */

import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import {
  validationError,
  forbiddenError,
  notFoundError,
  successResponse,
  mapPgErrorToApiError,
  type ApiErrorDetail,
} from './errors.ts';
import { authGuard, type AuthGuardResult } from '../_shared/auth.ts';

// ============================================
// TYPES
// ============================================

interface ReviewQueueItem {
  id: string;
  referrer_name: string;
  suggested_party_id: number | null;
  suggested_party_name: string | null;
  fuzzy_score: number;
  status: 'pending' | 'approved' | 'rejected';
  resolved_party_id: number | null;
  resolved_at: string | null;
  resolved_by: string | null;
  resolution_notes: string | null;
  investor_id: number | null;
  import_batch_id: string | null;
  import_row_number: number | null;
  created_at: string;
  updated_at: string;
}

interface ResolveRequest {
  party_id: number;
  notes?: string;
  action: 'approve' | 'reject';
}

interface ResolveResponse {
  id: string;
  status: 'approved' | 'rejected';
  resolved_party_id: number | null;
  resolved_at: string;
  resolved_by: string;
}

// ============================================
// MAIN HANDLER: Review Queue Routes
// ============================================

/**
 * Handle review queue routes
 *
 * @param req - Request object
 * @param supabase - Supabase client
 * @param cleanPath - Cleaned path array (e.g., ['referrers'], ['referrers', 'uuid', 'resolve'])
 * @param corsHeaders - CORS headers
 */
export async function handleReviewQueue(
  req: Request,
  supabase: SupabaseClient,
  cleanPath: string[],
  corsHeaders: Record<string, string>
): Promise<Response> {
  // Auth: Admin or Finance only (NO service key allowed)
  let auth: AuthGuardResult;
  try {
    auth = await authGuard(req, supabase, ['admin', 'finance'], { allowServiceKey: false });
  } catch (error: any) {
    return forbiddenError(error.message, corsHeaders);
  }

  const resource = cleanPath[0]; // 'referrers'
  const id = cleanPath[1]; // review queue item ID or undefined
  const action = cleanPath[2]; // 'resolve' or undefined

  // GET /review/referrers?status=pending|approved|rejected
  if (req.method === 'GET' && resource === 'referrers' && !id) {
    return await handleListReviewQueue(req, supabase, corsHeaders);
  }

  // GET /review/referrers/:id (single item detail)
  if (req.method === 'GET' && resource === 'referrers' && id && !action) {
    return await handleGetReviewQueueItem(id, supabase, corsHeaders);
  }

  // POST /review/referrers/:id/resolve
  if (req.method === 'POST' && resource === 'referrers' && id && action === 'resolve') {
    return await handleResolveReviewItem(id, req, supabase, auth.userId, corsHeaders);
  }

  return notFoundError('Endpoint', corsHeaders);
}

// ============================================
// GET /review/referrers - List Review Queue Items
// ============================================

/**
 * List review queue items with filters
 *
 * Query params:
 * - status: pending|approved|rejected (default: all)
 * - investor_id: filter by investor
 * - import_batch_id: filter by import batch
 * - limit: page size (default: 50, max: 100)
 * - offset: pagination offset (default: 0)
 *
 * Response:
 * {
 *   "data": [
 *     {
 *       "id": "uuid",
 *       "referrer_name": "Acme Corporation",
 *       "suggested_party_id": 123,
 *       "suggested_party_name": "Acme Corp LLC",
 *       "fuzzy_score": 85.5,
 *       "status": "pending",
 *       "investor_id": 456,
 *       "created_at": "2025-10-21T..."
 *     }
 *   ],
 *   "meta": {
 *     "total": 10,
 *     "limit": 50,
 *     "offset": 0
 *   }
 * }
 */
async function handleListReviewQueue(
  req: Request,
  supabase: SupabaseClient,
  corsHeaders: Record<string, string>
): Promise<Response> {
  const url = new URL(req.url);
  const params = url.searchParams;

  // Parse query params
  const status = params.get('status'); // pending, approved, rejected, or null (all)
  const investorId = params.get('investor_id');
  const importBatchId = params.get('import_batch_id');
  const limit = Math.min(parseInt(params.get('limit') || '50'), 100);
  const offset = parseInt(params.get('offset') || '0');

  // Validate status if provided
  const validStatuses = ['pending', 'approved', 'rejected'];
  if (status && !validStatuses.includes(status)) {
    return validationError(
      [{ field: 'status', message: `Invalid status. Must be one of: ${validStatuses.join(', ')}`, value: status }],
      corsHeaders
    );
  }

  // Build query
  let query = supabase
    .from('referrer_review_queue')
    .select(`
      id,
      referrer_name,
      suggested_party_id,
      suggested_party_name,
      fuzzy_score,
      status,
      resolved_party_id,
      resolved_at,
      resolved_by,
      resolution_notes,
      investor_id,
      import_batch_id,
      import_row_number,
      created_at,
      updated_at
    `, { count: 'exact' });

  // Apply filters
  if (status) {
    query = query.eq('status', status);
  }
  if (investorId) {
    query = query.eq('investor_id', investorId);
  }
  if (importBatchId) {
    query = query.eq('import_batch_id', importBatchId);
  }

  // Apply ordering and pagination
  query = query
    .order('created_at', { ascending: false })
    .range(offset, offset + limit - 1);

  const { data, error, count } = await query;

  if (error) {
    return mapPgErrorToApiError(error, corsHeaders);
  }

  return successResponse(
    {
      data: data || [],
      meta: {
        total: count || 0,
        limit,
        offset,
      },
    },
    200,
    corsHeaders
  );
}

// ============================================
// GET /review/referrers/:id - Get Single Review Queue Item
// ============================================

/**
 * Get single review queue item detail
 *
 * Response:
 * {
 *   "data": {
 *     "id": "uuid",
 *     "referrer_name": "Acme Corporation",
 *     "suggested_party": { "id": 123, "name": "Acme Corp LLC" },
 *     "fuzzy_score": 85.5,
 *     "status": "pending",
 *     "investor": { "id": 456, "name": "John Doe" },
 *     ...
 *   }
 * }
 */
async function handleGetReviewQueueItem(
  id: string,
  supabase: SupabaseClient,
  corsHeaders: Record<string, string>
): Promise<Response> {
  // Fetch review queue item with joined data
  const { data: item, error } = await supabase
    .from('referrer_review_queue')
    .select(`
      id,
      referrer_name,
      suggested_party_id,
      suggested_party_name,
      fuzzy_score,
      status,
      resolved_party_id,
      resolved_at,
      resolved_by,
      resolution_notes,
      investor_id,
      import_batch_id,
      import_row_number,
      created_at,
      updated_at,
      suggested_party:parties!referrer_review_queue_suggested_party_id_fkey(id, name, party_type),
      investor:investors(id, name),
      resolved_party:parties!referrer_review_queue_resolved_party_id_fkey(id, name, party_type)
    `)
    .eq('id', id)
    .single();

  if (error || !item) {
    return notFoundError('Review queue item', corsHeaders);
  }

  return successResponse({ data: item }, 200, corsHeaders);
}

// ============================================
// POST /review/referrers/:id/resolve - Resolve Review Item
// ============================================

/**
 * Resolve a review queue item (approve or reject)
 *
 * Request Body:
 * {
 *   "action": "approve" | "reject",
 *   "party_id": 123, // Required for approve, optional for reject
 *   "notes": "Optional resolution notes"
 * }
 *
 * Business Rules:
 * - If action=approve:
 *   - party_id is required
 *   - Update investor.source_party_id with resolved party_id
 *   - Set status to 'approved'
 *   - Audit log: "resolver.applied"
 * - If action=reject:
 *   - Set status to 'rejected'
 *   - No investor update
 *   - Audit log: "resolver.rejected"
 *
 * Idempotency:
 * - If already resolved, returns current state
 *
 * Response:
 * {
 *   "data": {
 *     "id": "uuid",
 *     "status": "approved",
 *     "resolved_party_id": 123,
 *     "resolved_at": "2025-10-21T...",
 *     "resolved_by": "user-uuid"
 *   }
 * }
 */
async function handleResolveReviewItem(
  id: string,
  req: Request,
  supabase: SupabaseClient,
  userId: string,
  corsHeaders: Record<string, string>
): Promise<Response> {
  // Parse request body
  const body: ResolveRequest = await req.json().catch(() => ({}));

  // Validate action
  if (!body.action || !['approve', 'reject'].includes(body.action)) {
    return validationError(
      [{ field: 'action', message: 'action must be "approve" or "reject"', value: body.action }],
      corsHeaders
    );
  }

  // Validate party_id for approve action
  if (body.action === 'approve' && !body.party_id) {
    return validationError(
      [{ field: 'party_id', message: 'party_id is required for approve action', value: body.party_id }],
      corsHeaders
    );
  }

  // Fetch review queue item
  const { data: reviewItem, error: fetchError } = await supabase
    .from('referrer_review_queue')
    .select('id, status, investor_id, referrer_name, suggested_party_id, suggested_party_name')
    .eq('id', id)
    .single();

  if (fetchError || !reviewItem) {
    return notFoundError('Review queue item', corsHeaders);
  }

  // IDEMPOTENT CHECK: If already resolved, return current state
  if (reviewItem.status !== 'pending') {
    const { data: resolved } = await supabase
      .from('referrer_review_queue')
      .select('id, status, resolved_party_id, resolved_at, resolved_by')
      .eq('id', id)
      .single();

    return successResponse(
      {
        data: {
          id: resolved?.id,
          status: resolved?.status,
          resolved_party_id: resolved?.resolved_party_id,
          resolved_at: resolved?.resolved_at,
          resolved_by: resolved?.resolved_by,
        },
      },
      200,
      corsHeaders
    );
  }

  // Handle APPROVE action
  if (body.action === 'approve') {
    // Verify party exists
    const { data: party, error: partyError } = await supabase
      .from('parties')
      .select('id, name')
      .eq('id', body.party_id)
      .single();

    if (partyError || !party) {
      return validationError(
        [{ field: 'party_id', message: 'Invalid party_id - party not found', value: body.party_id }],
        corsHeaders
      );
    }

    // Update review queue item to approved
    const { data: updated, error: updateError } = await supabase
      .from('referrer_review_queue')
      .update({
        status: 'approved',
        resolved_party_id: body.party_id,
        resolved_at: new Date().toISOString(),
        resolved_by: userId,
        resolution_notes: body.notes || null,
        updated_at: new Date().toISOString(),
      })
      .eq('id', id)
      .select('id, status, resolved_party_id, resolved_at, resolved_by')
      .single();

    if (updateError) {
      return mapPgErrorToApiError(updateError, corsHeaders);
    }

    // Update investor source fields (if investor_id provided)
    if (reviewItem.investor_id) {
      const { error: investorUpdateError } = await supabase
        .from('investors')
        .update({
          source_party_id: body.party_id,
          updated_at: new Date().toISOString(),
        })
        .eq('id', reviewItem.investor_id);

      if (investorUpdateError) {
        console.error('Failed to update investor source:', investorUpdateError);
        // Non-blocking: Continue even if investor update fails
      }
    }

    // Create audit log entry
    await supabase
      .from('audit_log')
      .insert({
        event_type: 'resolver.applied',
        actor_id: userId,
        entity_type: 'referrer_review_queue',
        entity_id: id,
        payload: {
          review_id: id,
          referrer_name: reviewItem.referrer_name,
          resolved_party_id: body.party_id,
          resolved_party_name: party.name,
          investor_id: reviewItem.investor_id,
          notes: body.notes || null,
        },
      });

    return successResponse(
      {
        data: {
          id: updated.id,
          status: updated.status,
          resolved_party_id: updated.resolved_party_id,
          resolved_at: updated.resolved_at,
          resolved_by: updated.resolved_by,
        },
      },
      200,
      corsHeaders
    );
  }

  // Handle REJECT action
  if (body.action === 'reject') {
    // Update review queue item to rejected (no investor update)
    const { data: updated, error: updateError } = await supabase
      .from('referrer_review_queue')
      .update({
        status: 'rejected',
        resolved_at: new Date().toISOString(),
        resolved_by: userId,
        resolution_notes: body.notes || 'Rejected by admin',
        updated_at: new Date().toISOString(),
      })
      .eq('id', id)
      .select('id, status, resolved_party_id, resolved_at, resolved_by')
      .single();

    if (updateError) {
      return mapPgErrorToApiError(updateError, corsHeaders);
    }

    // Create audit log entry
    await supabase
      .from('audit_log')
      .insert({
        event_type: 'resolver.rejected',
        actor_id: userId,
        entity_type: 'referrer_review_queue',
        entity_id: id,
        payload: {
          review_id: id,
          referrer_name: reviewItem.referrer_name,
          suggested_party_id: reviewItem.suggested_party_id,
          investor_id: reviewItem.investor_id,
          notes: body.notes || null,
        },
      });

    return successResponse(
      {
        data: {
          id: updated.id,
          status: updated.status,
          resolved_party_id: updated.resolved_party_id,
          resolved_at: updated.resolved_at,
          resolved_by: updated.resolved_by,
        },
      },
      200,
      corsHeaders
    );
  }

  // Should never reach here
  return validationError(
    [{ message: 'Invalid action' }],
    corsHeaders
  );
}
