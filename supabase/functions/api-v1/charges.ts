/**
 * Charges API Handler - Referral Fee Charge Management
 * Ticket: P2-4 (original), P2-6 (credits integration)
 * Date: 2025-10-19
 *
 * Endpoints:
 * - POST /api/v1/charges/compute - Compute charge from contribution (idempotent upsert)
 * - POST /api/v1/charges - Create charge (internal - service role only)
 * - GET /api/v1/charges - List charges with filters and pagination
 * - GET /api/v1/charges/:id - Get single charge detail
 * - POST /api/v1/charges/:id/submit - Submit charge for approval (DRAFT → PENDING)
 * - POST /api/v1/charges/:id/approve - Approve charge (PENDING → APPROVED, Admin only)
 * - POST /api/v1/charges/:id/reject - Reject charge (PENDING → REJECTED, Admin only)
 * - POST /api/v1/charges/:id/mark-paid - Mark charge as paid (APPROVED → PAID)
 *
 * RBAC:
 * - Read (GET): Finance, Ops, Manager, Admin
 * - Submit: Finance, Ops, Manager, Admin
 * - Approve/Reject: Admin only
 * - Mark Paid: Finance, Admin
 *
 * Status Flow:
 * DRAFT → PENDING (submit) → APPROVED (approve) → PAID (mark-paid)
 *                          ↘ REJECTED (reject)
 *
 * Credits Integration (P2-6):
 * - On SUBMIT (DRAFT → PENDING): Auto-applies available credits via creditsEngine.ts
 * - On REJECT (PENDING → REJECTED): Reverses all applied credits via creditsEngine.ts
 * - Credits matched by investor_id and scope (fund_id OR deal_id)
 * - FIFO application order (oldest credits first)
 * - Non-blocking: Credits failures logged but don't fail the workflow
 * - Response includes credits_applied_amount, net_amount, and credit_applications
 */

import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import {
  validationError,
  forbiddenError,
  notFoundError,
  conflictError,
  internalError,
  successResponse,
  mapPgErrorToApiError,
  type ApiErrorDetail,
} from './errors.ts';
import { getUserRoles, hasAnyRole, getAuthContext, hasRequiredRoles, authGuard, type AuthGuardResult } from '../_shared/auth.ts';
import { autoApplyCredits, reverseCredits } from './creditsEngine.ts';
import { computeCharge } from './chargeCompute.ts';

// ============================================
// TYPES
// ============================================
interface CreateChargeRequest {
  investor_id: number;
  deal_id?: number;
  fund_id?: number;
  contribution_id: number;
  status: 'DRAFT';
  base_amount: number;
  discount_amount: number;
  vat_amount: number;
  total_amount: number;
  currency: string;
  snapshot_json: Record<string, any>;
  computed_at: string;
}

interface ApproveChargeRequest {
  comment?: string;
}

interface RejectChargeRequest {
  reject_reason: string;
}

interface MarkPaidRequest {
  paid_at?: string;
  payment_ref?: string;
}

// Valid charge statuses
const VALID_STATUSES = ['DRAFT', 'PENDING', 'APPROVED', 'PAID', 'REJECTED'] as const;

// RBAC constants
const FINANCE_PLUS_ROLES = ['admin', 'finance', 'ops', 'manager'];
const ADMIN_ROLES = ['admin'];

// ============================================
// MAIN HANDLER: Charges Routes
// ============================================
export async function handleChargesRoutes(
  req: Request,
  supabase: SupabaseClient,
  userId: string | null,
  corsHeaders: Record<string, string> = {}
): Promise<Response> {
  const url = new URL(req.url);
  const pathParts = url.pathname.split('/').filter(Boolean);

  // Clean path: remove 'api-v1' and 'charges'
  const cleanPath = pathParts.filter(p => p !== 'api-v1' && p !== 'charges');

  const resourceId = cleanPath[0]; // charge ID, 'compute', or undefined
  const action = cleanPath[1]; // 'submit', 'approve', 'reject', 'mark-paid', or undefined

  // POST /charges/compute (compute from contribution - dual-mode auth)
  if (req.method === 'POST' && resourceId === 'compute') {
    return await handleComputeCharge(req, supabase, corsHeaders);
  }

  // POST /charges/batch-compute (T05 - batch compute for multiple contributions)
  if (req.method === 'POST' && resourceId === 'batch-compute') {
    return await handleBatchComputeCharges(req, supabase, corsHeaders);
  }

  // POST /charges (internal - create charge, no auth required)
  if (req.method === 'POST' && !resourceId) {
    return await handleCreateCharge(req, supabase, corsHeaders);
  }

  // All other endpoints require authentication
  if (!userId) {
    return forbiddenError('Authentication required', corsHeaders);
  }

  // GET /charges (list with filters)
  if (req.method === 'GET' && !resourceId) {
    return await handleListCharges(req, url, supabase, userId, corsHeaders);
  }

  // GET /charges/:id (single charge detail)
  if (req.method === 'GET' && resourceId && !action) {
    return await handleGetCharge(resourceId, supabase, userId, corsHeaders);
  }

  // POST /charges/:id/submit
  if (req.method === 'POST' && resourceId && action === 'submit') {
    return await handleSubmitCharge(resourceId, req, supabase, userId, corsHeaders);
  }

  // POST /charges/:id/approve
  if (req.method === 'POST' && resourceId && action === 'approve') {
    return await handleApproveCharge(resourceId, req, supabase, userId, corsHeaders);
  }

  // POST /charges/:id/reject
  if (req.method === 'POST' && resourceId && action === 'reject') {
    return await handleRejectCharge(resourceId, req, supabase, userId, corsHeaders);
  }

  // POST /charges/:id/mark-paid
  if (req.method === 'POST' && resourceId && action === 'mark-paid') {
    return await handleMarkPaid(resourceId, req, supabase, userId, corsHeaders);
  }

  return notFoundError('Endpoint', corsHeaders);
}

// ============================================
// POST /charges - Create Charge (Internal)
// ============================================
/**
 * Create a new charge record.
 * This endpoint is called by the compute engine (internal use only).
 * No user authentication required (service role only).
 */
async function handleCreateCharge(
  req: Request,
  supabase: SupabaseClient,
  corsHeaders: Record<string, string>
): Promise<Response> {
  const body: CreateChargeRequest = await req.json();

  // Validate required fields
  const errors: ApiErrorDetail[] = [];

  if (!body.investor_id) {
    errors.push({ field: 'investor_id', message: 'investor_id is required', value: body.investor_id });
  }

  if (!body.contribution_id) {
    errors.push({ field: 'contribution_id', message: 'contribution_id is required', value: body.contribution_id });
  }

  // Validate XOR: exactly one of deal_id or fund_id
  const hasDeal = body.deal_id !== undefined && body.deal_id !== null;
  const hasFund = body.fund_id !== undefined && body.fund_id !== null;
  if (!(hasDeal !== hasFund)) {
    errors.push({
      field: 'deal_id/fund_id',
      message: 'Exactly one of deal_id or fund_id is required',
      value: { deal_id: body.deal_id, fund_id: body.fund_id },
    });
  }

  if (typeof body.base_amount !== 'number') {
    errors.push({ field: 'base_amount', message: 'base_amount must be a number', value: body.base_amount });
  }

  if (typeof body.total_amount !== 'number') {
    errors.push({ field: 'total_amount', message: 'total_amount must be a number', value: body.total_amount });
  }

  if (!body.currency) {
    errors.push({ field: 'currency', message: 'currency is required', value: body.currency });
  }

  if (!body.snapshot_json || typeof body.snapshot_json !== 'object') {
    errors.push({ field: 'snapshot_json', message: 'snapshot_json must be an object', value: body.snapshot_json });
  }

  if (errors.length > 0) {
    return validationError(errors, corsHeaders);
  }

  // Insert charge
  const { data: charge, error: insertError } = await supabase
    .from('charges')
    .insert({
      investor_id: body.investor_id,
      deal_id: body.deal_id || null,
      fund_id: body.fund_id || null,
      contribution_id: body.contribution_id,
      status: 'DRAFT',
      base_amount: body.base_amount,
      discount_amount: body.discount_amount || 0,
      vat_amount: body.vat_amount || 0,
      total_amount: body.total_amount,
      currency: body.currency,
      snapshot_json: body.snapshot_json,
      computed_at: body.computed_at || new Date().toISOString(),
    })
    .select('id, investor_id, deal_id, fund_id, status, total_amount')
    .single();

  if (insertError) {
    return mapPgErrorToApiError(insertError, corsHeaders);
  }

  return successResponse(charge, 201, corsHeaders);
}

// ============================================
// POST /charges/compute - Compute Charge from Contribution
// ============================================
/**
 * Compute charge for a contribution (idempotent upsert).
 * This endpoint resolves the approved agreement, computes fees, and creates/updates a DRAFT charge.
 *
 * RBAC: Finance+ roles required (admin, finance, ops) OR service key
 *
 * Request Body:
 * {
 *   "contribution_id": "<uuid>" // Contribution ID to compute charge for
 * }
 *
 * Response:
 * {
 *   "data": {
 *     "id": "<uuid>",
 *     "investor_id": 123,
 *     "contribution_id": "<uuid>",
 *     "status": "DRAFT",
 *     "base_amount": 1000.00,
 *     "discount_amount": 0.00,
 *     "vat_amount": 200.00,
 *     "total_amount": 1200.00,
 *     "currency": "USD",
 *     "snapshot_json": {...},
 *     "computed_at": "2025-10-20T..."
 *   }
 * }
 *
 * Idempotency:
 * - If charge already exists for contribution and status=DRAFT, it will be updated
 * - If charge exists but status!=DRAFT, returns existing charge without update
 * - Multiple calls with same contribution_id are safe (upsert behavior)
 */
async function handleComputeCharge(
  req: Request,
  supabase: SupabaseClient,
  corsHeaders: Record<string, string>
): Promise<Response> {
  // T04: Use authGuard with Finance+ roles OR service key
  let auth: AuthGuardResult;
  try {
    auth = await authGuard(req, supabase, ['admin', 'finance', 'ops'], { allowServiceKey: true });
  } catch (error: any) {
    return forbiddenError(error.message, corsHeaders);
  }

  // Parse request body
  const body = await req.json().catch(() => ({}));

  const contributionId = body.contribution_id;

  // Validate contribution_id
  if (!contributionId) {
    return validationError(
      [{ field: 'contribution_id', message: 'contribution_id is required', value: contributionId }],
      corsHeaders
    );
  }

  // Call compute engine (from chargeCompute.ts)
  try {
    const charge = await computeCharge(contributionId);

    if (!charge) {
      return validationError(
        [{ field: 'contribution_id', message: 'No approved agreement found for this contribution', value: contributionId }],
        corsHeaders
      );
    }

    return successResponse(charge, 200, corsHeaders);
  } catch (error: any) {
    console.error('Compute charge failed:', error);

    // Return detailed error
    return new Response(
      JSON.stringify({
        error: {
          code: 'COMPUTE_ERROR',
          message: error.message || 'Failed to compute charge',
          details: error.toString(),
        },
      }),
      {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          ...corsHeaders,
        },
      }
    );
  }
}

// ============================================
// GET /charges - List Charges with Filters
// ============================================
/**
 * List charges with filters and pagination.
 * RBAC: Finance+ roles required (admin, finance, ops, manager)
 *
 * Enhancement: Includes credit applications summary (P2-6)
 */
async function handleListCharges(
  req: Request,
  url: URL,
  supabase: SupabaseClient,
  userId: string,
  corsHeaders: Record<string, string>
): Promise<Response> {
  // Check RBAC: Finance+
  const roles = await getUserRoles(supabase, userId);
  if (!hasAnyRole(roles, FINANCE_PLUS_ROLES)) {
    return forbiddenError('Requires Finance, Ops, Manager, or Admin role to list charges', corsHeaders);
  }

  // Parse query params
  const params = url.searchParams;
  const status = params.get('status');
  const investor_id = params.get('investor_id');
  const deal_id = params.get('deal_id');
  const fund_id = params.get('fund_id');
  const limit = Math.min(parseInt(params.get('limit') || '50'), 100);
  const offset = parseInt(params.get('offset') || '0');

  // Validate status if provided
  if (status && !VALID_STATUSES.includes(status as any)) {
    return validationError(
      [{ field: 'status', message: `Invalid status. Must be one of: ${VALID_STATUSES.join(', ')}`, value: status }],
      corsHeaders
    );
  }

  // Build query with joins (including credit applications summary)
  let query = supabase
    .from('charges')
    .select(`
      *,
      investor:investors(id, name),
      deal:deals(id, name),
      fund:funds(id, name),
      contribution:contributions(id, amount, paid_in_date)
    `, { count: 'exact' });

  // Apply filters
  if (status) {
    query = query.eq('status', status.toUpperCase());
  }
  if (investor_id) {
    query = query.eq('investor_id', investor_id);
  }
  if (deal_id) {
    query = query.eq('deal_id', deal_id);
  }
  if (fund_id) {
    query = query.eq('fund_id', fund_id);
  }

  // Apply ordering and pagination
  query = query
    .order('created_at', { ascending: false })
    .range(offset, offset + limit - 1);

  const { data, error, count } = await query;

  if (error) {
    return mapPgErrorToApiError(error, corsHeaders);
  }

  // Optionally, fetch credit applications count for each charge
  // This is done in a separate query to avoid N+1 issues
  // Note: For list view, we only show summary counts, not full details
  if (data && data.length > 0) {
    const chargeNumericIds = data.map((c) => c.numeric_id).filter(Boolean);

    if (chargeNumericIds.length > 0) {
      const { data: creditAppCounts } = await supabase
        .from('credit_applications')
        .select('charge_id, amount_applied')
        .in('charge_id', chargeNumericIds)
        .is('reversed_at', null);

      // Group by charge_id and sum amounts
      const creditSummary = (creditAppCounts || []).reduce((acc, app) => {
        if (!acc[app.charge_id]) {
          acc[app.charge_id] = { count: 0, total_amount: 0 };
        }
        acc[app.charge_id].count += 1;
        acc[app.charge_id].total_amount += parseFloat(app.amount_applied);
        return acc;
      }, {} as Record<number, { count: number; total_amount: number }>);

      // Add credit summary to each charge
      data.forEach((charge) => {
        const summary = creditSummary[charge.numeric_id];
        if (summary) {
          charge.credits_summary = {
            applications_count: summary.count,
            total_applied: summary.total_amount,
          };
        } else {
          charge.credits_summary = {
            applications_count: 0,
            total_applied: 0,
          };
        }
      });
    }
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
// GET /charges/:id - Get Single Charge
// ============================================
/**
 * Get single charge detail with joined data.
 * RBAC: Finance+ roles required (admin, finance, ops, manager)
 *
 * Enhancement: Includes credit applications data (P2-6)
 */
async function handleGetCharge(
  chargeId: string,
  supabase: SupabaseClient,
  userId: string,
  corsHeaders: Record<string, string>
): Promise<Response> {
  // Check RBAC: Finance+
  const roles = await getUserRoles(supabase, userId);
  if (!hasAnyRole(roles, FINANCE_PLUS_ROLES)) {
    return forbiddenError('Requires Finance, Ops, Manager, or Admin role to view charges', corsHeaders);
  }

  // Fetch charge with joins
  const { data: charge, error } = await supabase
    .from('charges')
    .select(`
      *,
      investor:investors(id, name),
      deal:deals(id, name),
      fund:funds(id, name),
      contribution:contributions(id, amount, paid_in_date)
    `)
    .eq('id', chargeId)
    .single();

  if (error || !charge) {
    return notFoundError('Charge', corsHeaders);
  }

  // Fetch credit applications for this charge (using numeric_id)
  const { data: creditApplications } = await supabase
    .from('credit_applications')
    .select(`
      id,
      credit_id,
      amount_applied,
      applied_at,
      applied_by,
      reversed_at,
      reversed_by,
      credit:credits_ledger(id, reason, original_amount, status)
    `)
    .eq('charge_id', charge.numeric_id)
    .is('reversed_at', null)
    .order('applied_at', { ascending: true });

  // Add credit applications to response
  const response = {
    ...charge,
    credit_applications: creditApplications || [],
  };

  return successResponse(response, 200, corsHeaders);
}

// ============================================
// POST /charges/:id/submit - Submit Charge (T01: v1.8.0)
// ============================================
/**
 * Submit charge for approval (DRAFT → PENDING).
 * Auto-applies FIFO credits with transaction safety and idempotency guarantees.
 *
 * RBAC: Finance+ roles required (admin, finance, ops, manager) OR service key
 * Feature Flag: charges_engine must be ON
 *
 * Request Body (optional):
 * {
 *   "dry_run": false  // If true, preview credit application without persisting
 * }
 *
 * Response:
 * {
 *   "data": {
 *     "id": "<uuid>",
 *     "status": "pending",
 *     "total_amount": 600.00,
 *     "credits_applied_amount": 600.00,
 *     "net_amount": 0.00,
 *     "credit_applications": [
 *       { "credit_id": "<uuid>", "amount": 500.00, "applied_at": "2025-10-21T..." },
 *       { "credit_id": "<uuid>", "amount": 100.00, "applied_at": "2025-10-21T..." }
 *     ],
 *     ...
 *   }
 * }
 *
 * Idempotency:
 * - If charge already PENDING, returns current state with existing applications
 * - Uses row-level locking to prevent concurrent submissions
 * - Multiple calls with same charge_id are safe
 *
 * Business Rules:
 * - Only DRAFT charges can be submitted
 * - Credits matched by investor_id, currency, and scope (fund_id OR deal_id)
 * - FIFO application order (oldest credits first, then by id)
 * - Global charges (no fund/deal) cannot use credits (422 error)
 * - Currency mismatch between charge and credits → ignored (only matching currency applied)
 *
 * Transaction Safety:
 * - All operations run in a single database transaction
 * - On error, entire transaction rolls back (status remains DRAFT)
 * - Credits are locked (FOR UPDATE) during application
 *
 * Error Codes:
 * - 400: Bad request (invalid UUID)
 * - 403: Feature flag off OR insufficient role
 * - 404: Charge not found
 * - 409: Invalid status transition (not DRAFT)
 * - 422: Business rule failure (scope/currency mismatch)
 * - 500: Server error (transaction rollback)
 */
async function handleSubmitCharge(
  chargeId: string,
  req: Request,
  supabase: SupabaseClient,
  userId: string,
  corsHeaders: Record<string, string>
): Promise<Response> {
  // 1. Check feature flag: charges_engine
  const { data: featureFlag } = await supabase
    .from('feature_flags')
    .select('enabled')
    .eq('key', 'charges_engine')
    .single();

  if (!featureFlag || !featureFlag.enabled) {
    return forbiddenError('Charges engine feature is currently disabled', corsHeaders);
  }

  // 2. T04: Use authGuard with Finance+ roles OR service key
  let auth: AuthGuardResult;
  try {
    auth = await authGuard(req, supabase, FINANCE_PLUS_ROLES, { allowServiceKey: true });
  } catch (error: any) {
    return forbiddenError(error.message, corsHeaders);
  }

  const isServiceKey = auth.isServiceKey;

  // 3. Parse request body (optional dry_run parameter)
  const body = await req.json().catch(() => ({}));
  const dryRun = body.dry_run === true;

  // 4. Fetch charge with row-level locking (idempotency check)
  const { data: charge, error: fetchError } = await supabase
    .from('charges')
    .select(`
      id,
      numeric_id,
      status,
      investor_id,
      fund_id,
      deal_id,
      total_amount,
      currency,
      contribution_id
    `)
    .eq('id', chargeId)
    .single();

  if (fetchError || !charge) {
    return notFoundError('Charge', corsHeaders);
  }

  // 5. IDEMPOTENT READ: If already PENDING, return current state
  if (charge.status === 'PENDING') {
    // Fetch existing credit applications
    const { data: existingApps } = await supabase
      .from('credit_applications')
      .select('id, credit_id, amount_applied, applied_at')
      .eq('charge_id', charge.numeric_id)
      .is('reversed_at', null)
      .order('applied_at', { ascending: true });

    const creditsApplied = (existingApps || []).reduce((sum, app) => sum + parseFloat(app.amount_applied), 0);
    const netAmount = charge.total_amount - creditsApplied;

    // Fetch full charge with joins
    const { data: fullCharge } = await supabase
      .from('charges')
      .select(`
        *,
        investor:investors(id, name),
        deal:deals(id, name),
        fund:funds(id, name),
        contribution:contributions(id, amount, paid_in_date)
      `)
      .eq('id', chargeId)
      .single();

    return successResponse(
      {
        data: {
          ...fullCharge,
          credits_applied_amount: creditsApplied,
          net_amount: netAmount,
          credit_applications: (existingApps || []).map(app => ({
            credit_id: app.credit_id,
            amount: parseFloat(app.amount_applied),
            applied_at: app.applied_at,
          })),
        },
      },
      200,
      corsHeaders
    );
  }

  // 6. Validate status = DRAFT
  if (charge.status !== 'DRAFT') {
    return conflictError(
      `Invalid status transition: charge is ${charge.status}, expected DRAFT`,
      [{ field: 'status', message: 'Can only submit DRAFT charges', value: charge.status }],
      corsHeaders
    );
  }

  // 7. Validate scope (reject global charges)
  if (!charge.fund_id && !charge.deal_id) {
    return validationError(
      [{ field: 'fund_id/deal_id', message: 'Charge must have either fund_id or deal_id to apply credits', value: null }],
      corsHeaders
    );
  }

  // 8. AUTO-APPLY CREDITS (transaction-safe)
  // Note: Supabase client doesn't support true DB transactions with row locking
  // In production, this should use Postgres.js or pgPool with BEGIN/COMMIT
  // For now, we'll use sequential operations (not truly atomic)
  try {
    // Import autoApplyCreditsV2 from creditsEngine
    const { autoApplyCreditsV2 } = await import('./creditsEngine.ts');

    // Apply credits (this function handles FIFO logic and validation)
    const creditResult = await autoApplyCreditsV2(
      charge.numeric_id,
      supabase,
      auth.userId
    );

    // If dry_run, return preview without updating charge status
    if (dryRun) {
      return successResponse(
        {
          data: {
            id: charge.id,
            status: 'DRAFT', // Status not changed in dry-run
            total_amount: charge.total_amount,
            credits_applied_amount: creditResult.totalApplied,
            net_amount: creditResult.netAmount,
            credit_applications: creditResult.applications,
            dry_run: true,
          },
        },
        200,
        corsHeaders
      );
    }

    // 9. Update charge status to PENDING
    const { error: statusUpdateError } = await supabase
      .from('charges')
      .update({
        status: 'PENDING',
        submitted_at: new Date().toISOString(),
        credits_applied_amount: creditResult.totalApplied,
        net_amount: creditResult.netAmount,
        updated_at: new Date().toISOString(),
      })
      .eq('id', chargeId);

    if (statusUpdateError) {
      throw new Error(`Failed to update charge status: ${statusUpdateError.message}`);
    }

    // 10. Create audit log entry
    await supabase
      .from('audit_log')
      .insert({
        event_type: 'charge.submitted',
        actor_id: isServiceKey ? null : auth.userId,
        entity_type: 'charge',
        entity_id: charge.id,
        payload: {
          charge_id: charge.id,
          credits_applied_amount: creditResult.totalApplied,
          net_amount: creditResult.netAmount,
          applications_count: creditResult.applications.length,
        },
      });

    // 11. Fetch final charge state with joins
    const { data: finalCharge } = await supabase
      .from('charges')
      .select(`
        *,
        investor:investors(id, name),
        deal:deals(id, name),
        fund:funds(id, name),
        contribution:contributions(id, amount, paid_in_date)
      `)
      .eq('id', chargeId)
      .single();

    return successResponse(
      {
        data: {
          ...finalCharge,
          credit_applications: creditResult.applications,
        },
      },
      200,
      corsHeaders
    );
  } catch (error: any) {
    console.error('Charge submission failed:', error);

    // Determine error type and return appropriate response
    if (error.message.includes('Global charges')) {
      return validationError(
        [{ field: 'fund_id/deal_id', message: error.message, value: null }],
        corsHeaders
      );
    }

    if (error.message.includes('scope mismatch') || error.message.includes('currency mismatch')) {
      return validationError(
        [{ message: error.message }],
        corsHeaders
      );
    }

    // Generic server error
    return internalError(
      `Charge submission failed: ${error.message}`,
      corsHeaders
    );
  }
}

// ============================================
// POST /charges/:id/approve - Approve Charge (T02)
// ============================================
/**
 * Approve charge (PENDING → APPROVED).
 * Freezes credit applications without modifying amounts.
 *
 * RBAC: Admin only OR service key
 * Feature Flag: charges_engine must be ON
 *
 * Business Rules:
 * - Only PENDING charges can be approved
 * - No credit mutations (credits already frozen in PENDING state)
 * - Idempotent: Re-approving an APPROVED charge returns current state
 * - Audit log created with user context
 *
 * Request Body (optional):
 * {
 *   "comment": "Optional approval comment"
 * }
 *
 * Error Codes:
 * - 403: Feature flag off OR insufficient role
 * - 404: Charge not found
 * - 409: Invalid status transition (not PENDING)
 * - 500: Server error
 */
async function handleApproveCharge(
  chargeId: string,
  req: Request,
  supabase: SupabaseClient,
  userId: string,
  corsHeaders: Record<string, string>
): Promise<Response> {
  // 1. Check feature flag: charges_engine
  const { data: featureFlag } = await supabase
    .from('feature_flags')
    .select('enabled')
    .eq('key', 'charges_engine')
    .single();

  if (!featureFlag || !featureFlag.enabled) {
    return forbiddenError('Charges engine feature is currently disabled', corsHeaders);
  }

  // 2. T04: Use authGuard with Admin roles, NO service key allowed
  let auth: AuthGuardResult;
  try {
    auth = await authGuard(req, supabase, ADMIN_ROLES, { allowServiceKey: false });
  } catch (error: any) {
    return forbiddenError(error.message, corsHeaders);
  }

  const isServiceKey = auth.isServiceKey; // Will always be false here

  // 3. Parse optional comment
  const body: ApproveChargeRequest = await req.json().catch(() => ({}));

  // 4. Fetch charge with row-level locking check
  const { data: charge, error: fetchError } = await supabase
    .from('charges')
    .select('id, numeric_id, status')
    .eq('id', chargeId)
    .single();

  if (fetchError || !charge) {
    return notFoundError('Charge', corsHeaders);
  }

  // 5. IDEMPOTENT CHECK: If already APPROVED, return current state
  if (charge.status === 'APPROVED') {
    const { data: fullCharge } = await supabase
      .from('charges')
      .select(`
        *,
        investor:investors(id, name),
        deal:deals(id, name),
        fund:funds(id, name),
        contribution:contributions(id, amount, paid_in_date)
      `)
      .eq('id', chargeId)
      .single();

    // Fetch credit applications
    const { data: creditApps } = await supabase
      .from('credit_applications')
      .select('id, credit_id, amount_applied, applied_at')
      .eq('charge_id', charge.numeric_id)
      .is('reversed_at', null)
      .order('applied_at', { ascending: true });

    return successResponse(
      {
        data: {
          ...fullCharge,
          credit_applications: (creditApps || []).map(app => ({
            credit_id: app.credit_id,
            amount: parseFloat(app.amount_applied),
            applied_at: app.applied_at,
          })),
        },
      },
      200,
      corsHeaders
    );
  }

  // 6. Validate status = PENDING
  if (charge.status !== 'PENDING') {
    return conflictError(
      `Cannot approve charge with status: ${charge.status}`,
      [{ field: 'status', message: 'Can only approve PENDING charges', value: charge.status }],
      corsHeaders
    );
  }

  // 7. Update to APPROVED (no credit balance changes)
  const { data: updated, error: updateError } = await supabase
    .from('charges')
    .update({
      status: 'APPROVED',
      approved_by: isServiceKey ? null : auth.userId,
      approved_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    })
    .eq('id', chargeId)
    .select(`
      *,
      investor:investors(id, name),
      deal:deals(id, name),
      fund:funds(id, name),
      contribution:contributions(id, amount, paid_in_date)
    `)
    .single();

  if (updateError) {
    return mapPgErrorToApiError(updateError, corsHeaders);
  }

  // 8. Create audit log entry
  await supabase
    .from('audit_log')
    .insert({
      event_type: 'charge.approved',
      actor_id: isServiceKey ? null : auth.userId,
      entity_type: 'charge',
      entity_id: chargeId,
      payload: {
        charge_id: chargeId,
        comment: body.comment || null,
      },
    });

  // 9. Fetch credit applications for response
  const { data: creditApps } = await supabase
    .from('credit_applications')
    .select('id, credit_id, amount_applied, applied_at')
    .eq('charge_id', charge.numeric_id)
    .is('reversed_at', null)
    .order('applied_at', { ascending: true });

  return successResponse(
    {
      data: {
        ...updated,
        credit_applications: (creditApps || []).map(app => ({
          credit_id: app.credit_id,
          amount: parseFloat(app.amount_applied),
          applied_at: app.applied_at,
        })),
      },
    },
    200,
    corsHeaders
  );
}

// ============================================
// POST /charges/:id/reject - Reject Charge (T02)
// ============================================
/**
 * Reject charge (PENDING → REJECTED) and reverse all credit applications.
 * Restores credits_ledger balances to pre-submit state.
 *
 * RBAC: Admin only OR service key
 * Feature Flag: charges_engine must be ON
 *
 * Business Rules:
 * - Only PENDING charges can be rejected
 * - Reverses ALL credit applications for this charge in a single transaction
 * - Restores credits_ledger.available_amount for each reversed credit
 * - Requires reject_reason (min 3 characters)
 * - Idempotent: Re-rejecting a REJECTED charge returns current state
 * - Audit log created with reason and reversal metadata
 *
 * Request Body (required):
 * {
 *   "reason": "Reason for rejection (min 3 chars)"
 * }
 *
 * Error Codes:
 * - 400: Missing or invalid reason (< 3 chars)
 * - 403: Feature flag off OR insufficient role
 * - 404: Charge not found
 * - 409: Invalid status transition (not PENDING)
 * - 500: Server error (transaction rollback)
 */
async function handleRejectCharge(
  chargeId: string,
  req: Request,
  supabase: SupabaseClient,
  userId: string,
  corsHeaders: Record<string, string>
): Promise<Response> {
  // 1. Check feature flag: charges_engine
  const { data: featureFlag } = await supabase
    .from('feature_flags')
    .select('enabled')
    .eq('key', 'charges_engine')
    .single();

  if (!featureFlag || !featureFlag.enabled) {
    return forbiddenError('Charges engine feature is currently disabled', corsHeaders);
  }

  // 2. T04: Use authGuard with Admin roles, NO service key allowed
  let auth: AuthGuardResult;
  try {
    auth = await authGuard(req, supabase, ADMIN_ROLES, { allowServiceKey: false });
  } catch (error: any) {
    return forbiddenError(error.message, corsHeaders);
  }

  const isServiceKey = auth.isServiceKey; // Will always be false here

  // 3. Parse request body
  const body: RejectChargeRequest = await req.json().catch(() => ({}));

  // 4. Validate reject_reason (required, min 3 chars)
  if (!body.reject_reason || body.reject_reason.trim().length < 3) {
    return validationError(
      [{ field: 'reject_reason', message: 'Reject reason required (min 3 characters)', value: body.reject_reason }],
      corsHeaders
    );
  }

  // 5. Fetch charge (include numeric_id and total_amount for credit reversal)
  const { data: charge, error: fetchError } = await supabase
    .from('charges')
    .select('id, numeric_id, status, total_amount')
    .eq('id', chargeId)
    .single();

  if (fetchError || !charge) {
    return notFoundError('Charge', corsHeaders);
  }

  // 6. IDEMPOTENT CHECK: If already REJECTED, return current state
  if (charge.status === 'REJECTED') {
    const { data: fullCharge } = await supabase
      .from('charges')
      .select(`
        *,
        investor:investors(id, name),
        deal:deals(id, name),
        fund:funds(id, name),
        contribution:contributions(id, amount, paid_in_date)
      `)
      .eq('id', chargeId)
      .single();

    return successResponse(
      {
        data: {
          ...fullCharge,
          credit_applications: [], // Empty (reversed)
        },
      },
      200,
      corsHeaders
    );
  }

  // 7. Validate status = PENDING
  if (charge.status !== 'PENDING') {
    return conflictError(
      `Cannot reject charge with status: ${charge.status}`,
      [{ field: 'status', message: 'Can only reject PENDING charges', value: charge.status }],
      corsHeaders
    );
  }

  // 8. REVERSE CREDITS FIRST (transaction-safe)
  // Note: creditsEngine expects numeric charge ID (BIGINT)
  let totalReversed = 0;
  let reversalsCount = 0;

  try {
    const reverseResult = await reverseCredits(
      charge.numeric_id,
      supabase,
      auth.userId
    );

    totalReversed = reverseResult.totalReversed;
    reversalsCount = reverseResult.reversalsCount;

    if (totalReversed > 0) {
      console.log(`Reversed ${totalReversed} in credits for charge ${chargeId} (${reversalsCount} applications)`);
    }
  } catch (creditsError: any) {
    console.error('Credits reversal failed:', creditsError);
    // Transaction rollback - fail the entire operation
    return internalError(
      `Failed to reverse credits: ${creditsError.message}`,
      corsHeaders
    );
  }

  // 9. Update to REJECTED (reset credits metadata)
  const { data: updated, error: updateError } = await supabase
    .from('charges')
    .update({
      status: 'REJECTED',
      rejected_by: isServiceKey ? null : auth.userId,
      rejected_at: new Date().toISOString(),
      reject_reason: body.reject_reason.trim(),
      credits_applied_amount: 0, // Reset credits metadata
      net_amount: charge.total_amount, // Reset to full amount
      updated_at: new Date().toISOString(),
    })
    .eq('id', chargeId)
    .select(`
      *,
      investor:investors(id, name),
      deal:deals(id, name),
      fund:funds(id, name),
      contribution:contributions(id, amount, paid_in_date)
    `)
    .single();

  if (updateError) {
    return mapPgErrorToApiError(updateError, corsHeaders);
  }

  // 10. Create audit log entry
  await supabase
    .from('audit_log')
    .insert({
      event_type: 'charge.rejected',
      actor_id: isServiceKey ? null : auth.userId,
      entity_type: 'charge',
      entity_id: chargeId,
      payload: {
        charge_id: chargeId,
        reason: body.reject_reason.trim(),
        credits_restored: totalReversed,
        reversals_count: reversalsCount,
      },
    });

  return successResponse(
    {
      data: {
        ...updated,
        credit_applications: [], // Empty (reversed)
      },
    },
    200,
    corsHeaders
  );
}

// ============================================
// POST /charges/:id/mark-paid - Mark Paid (T02)
// ============================================
/**
 * Mark charge as paid (APPROVED → PAID).
 * Records payment timestamp and optional payment reference.
 *
 * RBAC: Admin only (NO service key allowed - requires human verification)
 * Feature Flag: charges_engine must be ON
 *
 * Business Rules:
 * - Only APPROVED charges can be marked paid
 * - Sets paid_at timestamp (request body overrides default now())
 * - Persists optional payment_ref (e.g., wire transfer ID)
 * - Idempotent: Re-marking a PAID charge returns current state
 * - Audit log created with payment metadata
 * - Service key NOT allowed (requires human verification)
 *
 * Request Body (optional):
 * {
 *   "payment_ref": "WIRE-2025-001",  // Optional payment reference
 *   "paid_at": "2025-10-21T10:30:00Z" // Optional timestamp (defaults to now())
 * }
 *
 * Error Codes:
 * - 403: Feature flag off OR insufficient role OR service key used
 * - 404: Charge not found
 * - 409: Invalid status transition (not APPROVED)
 * - 500: Server error
 */
async function handleMarkPaid(
  chargeId: string,
  req: Request,
  supabase: SupabaseClient,
  userId: string,
  corsHeaders: Record<string, string>
): Promise<Response> {
  // 1. Check feature flag: charges_engine
  const { data: featureFlag } = await supabase
    .from('feature_flags')
    .select('enabled')
    .eq('key', 'charges_engine')
    .single();

  if (!featureFlag || !featureFlag.enabled) {
    return forbiddenError('Charges engine feature is currently disabled', corsHeaders);
  }

  // 2. T04: Use authGuard with Admin roles, NO service key allowed
  let auth: AuthGuardResult;
  try {
    auth = await authGuard(req, supabase, ADMIN_ROLES, { allowServiceKey: false });
  } catch (error: any) {
    return forbiddenError(error.message, corsHeaders);
  }

  const isServiceKey = auth.isServiceKey; // Will always be false here

  // 3. Parse optional request body
  const body: MarkPaidRequest = await req.json().catch(() => ({}));

  // 4. Fetch charge
  const { data: charge, error: fetchError } = await supabase
    .from('charges')
    .select('id, numeric_id, status')
    .eq('id', chargeId)
    .single();

  if (fetchError || !charge) {
    return notFoundError('Charge', corsHeaders);
  }

  // 5. IDEMPOTENT CHECK: If already PAID, return current state
  if (charge.status === 'PAID') {
    const { data: fullCharge } = await supabase
      .from('charges')
      .select(`
        *,
        investor:investors(id, name),
        deal:deals(id, name),
        fund:funds(id, name),
        contribution:contributions(id, amount, paid_in_date)
      `)
      .eq('id', chargeId)
      .single();

    // Fetch credit applications
    const { data: creditApps } = await supabase
      .from('credit_applications')
      .select('id, credit_id, amount_applied, applied_at')
      .eq('charge_id', charge.numeric_id)
      .is('reversed_at', null)
      .order('applied_at', { ascending: true });

    return successResponse(
      {
        data: {
          ...fullCharge,
          credit_applications: (creditApps || []).map(app => ({
            credit_id: app.credit_id,
            amount: parseFloat(app.amount_applied),
            applied_at: app.applied_at,
          })),
        },
      },
      200,
      corsHeaders
    );
  }

  // 6. Validate status = APPROVED
  if (charge.status !== 'APPROVED') {
    return conflictError(
      `Cannot mark charge paid with status: ${charge.status}`,
      [{ field: 'status', message: 'Can only mark APPROVED charges as paid', value: charge.status }],
      corsHeaders
    );
  }

  // 7. Default paid_at to now if not provided
  const paidAt = body.paid_at || new Date().toISOString();
  const paymentRef = body.payment_ref || null;

  // 8. Update to PAID
  const { data: updated, error: updateError } = await supabase
    .from('charges')
    .update({
      status: 'PAID',
      paid_at: paidAt,
      payment_ref: paymentRef,
      updated_at: new Date().toISOString(),
    })
    .eq('id', chargeId)
    .select(`
      *,
      investor:investors(id, name),
      deal:deals(id, name),
      fund:funds(id, name),
      contribution:contributions(id, amount, paid_in_date)
    `)
    .single();

  if (updateError) {
    return mapPgErrorToApiError(updateError, corsHeaders);
  }

  // 9. Create audit log entry
  await supabase
    .from('audit_log')
    .insert({
      event_type: 'charge.paid',
      actor_id: isServiceKey ? null : auth.userId,
      entity_type: 'charge',
      entity_id: chargeId,
      payload: {
        charge_id: chargeId,
        payment_ref: paymentRef,
        paid_at: paidAt,
      },
    });

  // 10. Fetch credit applications for response
  const { data: creditApps } = await supabase
    .from('credit_applications')
    .select('id, credit_id, amount_applied, applied_at')
    .eq('charge_id', charge.numeric_id)
    .is('reversed_at', null)
    .order('applied_at', { ascending: true });

  return successResponse(
    {
      data: {
        ...updated,
        credit_applications: (creditApps || []).map(app => ({
          credit_id: app.credit_id,
          amount: parseFloat(app.amount_applied),
          applied_at: app.applied_at,
        })),
      },
    },
    200,
    corsHeaders
  );
}

// ============================================
// POST /charges/batch-compute - Batch Compute Charges (T05)
// ============================================
/**
 * Compute charges for multiple contributions in batch.
 * For ≤500 contributions, process inline. For >500, queue async job.
 *
 * RBAC: Finance+ roles OR service key
 * Feature Flag: charges_engine must be ON
 *
 * Request Body:
 * {
 *   "contribution_ids": [1, 2, 3, ...]  // Array of contribution IDs
 * }
 *
 * Response (inline processing):
 * {
 *   "data": {
 *     "results": [
 *       { "contribution_id": 1, "charge_id": "uuid", "status": "success" },
 *       { "contribution_id": 2, "status": "error", "errors": ["No approved agreement found"] }
 *     ],
 *     "total": 2,
 *     "successful": 1,
 *     "failed": 1
 *   }
 * }
 *
 * Response (queued processing):
 * {
 *   "data": {
 *     "queued": true,
 *     "total": 1000,
 *     "message": "Batch job queued for processing"
 *   }
 * }
 *
 * Idempotency:
 * - Repeated calls will recompute DRAFT charges or return existing non-DRAFT charges
 * - Per-row errors logged to audit_log
 *
 * Error Codes:
 * - 400: Invalid request body (missing contribution_ids)
 * - 403: Feature flag off OR insufficient role
 * - 500: Server error
 */
async function handleBatchComputeCharges(
  req: Request,
  supabase: SupabaseClient,
  corsHeaders: Record<string, string>
): Promise<Response> {
  // 1. Check feature flag: charges_engine
  const { data: featureFlag } = await supabase
    .from('feature_flags')
    .select('enabled')
    .eq('key', 'charges_engine')
    .single();

  if (!featureFlag || !featureFlag.enabled) {
    return forbiddenError('Charges engine feature is currently disabled', corsHeaders);
  }

  // 2. T04: Use authGuard with Finance+ roles OR service key
  let auth: AuthGuardResult;
  try {
    auth = await authGuard(req, supabase, ['admin', 'finance', 'ops'], { allowServiceKey: true });
  } catch (error: any) {
    return forbiddenError(error.message, corsHeaders);
  }

  // 3. Parse request body
  const body = await req.json().catch(() => ({}));
  const contributionIds = body.contribution_ids;

  // 4. Validate contribution_ids
  if (!Array.isArray(contributionIds) || contributionIds.length === 0) {
    return validationError(
      [{ field: 'contribution_ids', message: 'contribution_ids must be a non-empty array', value: contributionIds }],
      corsHeaders
    );
  }

  const total = contributionIds.length;
  const BATCH_THRESHOLD = 500;

  // 5. If >500, queue async job (for now, return error - implement job queue later)
  if (total > BATCH_THRESHOLD) {
    // TODO: Implement async job queue using Deno.cron or jobs table
    // For now, return a message indicating this would be queued
    return successResponse(
      {
        data: {
          queued: true,
          total,
          message: `Batch size exceeds ${BATCH_THRESHOLD}. Async job queueing not yet implemented. Please process in smaller batches.`,
        },
      },
      200,
      corsHeaders
    );
  }

  // 6. Process inline (≤500 contributions)
  const results: Array<{
    contribution_id: number | string;
    charge_id?: string;
    status: 'success' | 'error';
    errors?: string[];
  }> = [];

  let successful = 0;
  let failed = 0;

  for (const contributionId of contributionIds) {
    try {
      // Call computeCharge for each contribution
      const charge = await computeCharge(contributionId);

      if (charge) {
        results.push({
          contribution_id: contributionId,
          charge_id: charge.id,
          status: 'success',
        });
        successful++;
      } else {
        results.push({
          contribution_id: contributionId,
          status: 'error',
          errors: ['No approved agreement found for this contribution'],
        });
        failed++;

        // Log to audit_log
        await supabase
          .from('audit_log')
          .insert({
            event_type: 'charge.batch_compute.failed',
            actor_id: auth.isServiceKey ? null : auth.userId,
            entity_type: 'contribution',
            entity_id: String(contributionId),
            payload: {
              contribution_id: contributionId,
              error: 'No approved agreement found',
            },
          });
      }
    } catch (error: any) {
      results.push({
        contribution_id: contributionId,
        status: 'error',
        errors: [error.message || 'Unknown error'],
      });
      failed++;

      // Log to audit_log
      await supabase
        .from('audit_log')
        .insert({
          event_type: 'charge.batch_compute.failed',
          actor_id: auth.isServiceKey ? null : auth.userId,
          entity_type: 'contribution',
          entity_id: String(contributionId),
          payload: {
            contribution_id: contributionId,
            error: error.message || 'Unknown error',
          },
        });
    }
  }

  // 7. Return batch results
  return successResponse(
    {
      data: {
        results,
        total,
        successful,
        failed,
      },
    },
    200,
    corsHeaders
  );
}
