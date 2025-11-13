/**
 * Transactions API Handler
 * Ticket: PG-401
 * Date: 2025-10-19
 *
 * Endpoints:
 * - POST /api-v1/transactions - Create transaction (stub)
 * - GET /api-v1/transactions - List transactions with filters
 * - GET /api-v1/transactions/:id - Get single transaction with details
 *
 * STUB NOTICE: This is Phase 2 stub work. Calculation logic for charges
 * will be implemented in Phase 3.
 */

import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import {
  validationError,
  notFoundError,
  successResponse,
  mapPgErrorToApiError,
  type ApiErrorDetail,
} from './errors.ts';

// ============================================
// TYPES
// ============================================
export type TransactionType = 'CONTRIBUTION' | 'REPURCHASE';
export type TransactionSource = 'MANUAL' | 'CSV_IMPORT' | 'VANTAGE';

interface CreateTransactionRequest {
  investor_id: number;
  type: TransactionType;
  amount: number;
  currency?: string;
  transaction_date: string; // YYYY-MM-DD
  fund_id?: number;
  deal_id?: number;
  notes?: string;
  source?: TransactionSource;
  batch_id?: string;
}

interface Transaction {
  id: string;
  investor_id: number;
  type: TransactionType;
  amount: number;
  currency: string;
  transaction_date: string;
  fund_id: number | null;
  deal_id: number | null;
  notes: string | null;
  source: TransactionSource;
  batch_id: string | null;
  created_at: string;
  created_by: string | null;
}

// ============================================
// HELPER: Validate Transaction Payload
// ============================================
function validateTransactionPayload(p: any): { ok: true } | { ok: false; details: ApiErrorDetail[] } {
  const details: ApiErrorDetail[] = [];

  // Required fields
  if (!p.investor_id || typeof p.investor_id !== 'number') {
    details.push({
      field: 'investor_id',
      message: 'investor_id is required and must be a number',
      value: p.investor_id,
    });
  }

  // Type validation
  if (!p.type || !['CONTRIBUTION', 'REPURCHASE'].includes(p.type)) {
    details.push({
      field: 'type',
      message: 'type must be CONTRIBUTION or REPURCHASE',
      value: p.type,
    });
  }

  // Amount validation
  if (typeof p.amount !== 'number' || !(p.amount > 0)) {
    details.push({
      field: 'amount',
      message: 'amount must be a positive number',
      value: p.amount,
      constraint: 'amount_positive',
    });
  }

  // Date validation
  if (!p.transaction_date) {
    details.push({
      field: 'transaction_date',
      message: 'transaction_date is required (YYYY-MM-DD format)',
      value: p.transaction_date,
    });
  } else {
    const date = new Date(p.transaction_date);
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    if (date > today) {
      details.push({
        field: 'transaction_date',
        message: 'transaction_date cannot be in the future',
        value: p.transaction_date,
        constraint: 'date_not_future',
      });
    }
  }

  // XOR validation: exactly one of fund_id OR deal_id
  const hasFund = p.fund_id !== undefined && p.fund_id !== null;
  const hasDeal = p.deal_id !== undefined && p.deal_id !== null;

  if (!hasFund && !hasDeal) {
    details.push({
      field: 'fund_id/deal_id',
      message: 'Exactly one of fund_id or deal_id is required',
      value: { fund_id: p.fund_id, deal_id: p.deal_id },
    });
  } else if (hasFund && hasDeal) {
    details.push({
      field: 'fund_id/deal_id',
      message: 'Cannot specify both fund_id and deal_id',
      value: { fund_id: p.fund_id, deal_id: p.deal_id },
    });
  }

  if (details.length) return { ok: false, details };
  return { ok: true };
}

// ============================================
// HELPER: Verify Foreign Key Exists
// ============================================
async function verifyReferences(
  supabase: SupabaseClient,
  payload: CreateTransactionRequest
): Promise<ApiErrorDetail[]> {
  const errors: ApiErrorDetail[] = [];

  // Check investor exists
  const { data: investor, error: investorError } = await supabase
    .from('parties')
    .select('id')
    .eq('id', payload.investor_id)
    .single();

  if (investorError || !investor) {
    errors.push({
      field: 'investor_id',
      message: `Investor with id ${payload.investor_id} not found`,
      value: payload.investor_id,
    });
  }

  // Check fund_id if provided
  if (payload.fund_id) {
    const { data: fund, error: fundError } = await supabase
      .from('funds')
      .select('id')
      .eq('id', payload.fund_id)
      .single();

    if (fundError || !fund) {
      errors.push({
        field: 'fund_id',
        message: `Fund with id ${payload.fund_id} not found`,
        value: payload.fund_id,
      });
    }
  }

  // Check deal_id if provided
  if (payload.deal_id) {
    const { data: deal, error: dealError } = await supabase
      .from('deals')
      .select('id')
      .eq('id', payload.deal_id)
      .single();

    if (dealError || !deal) {
      errors.push({
        field: 'deal_id',
        message: `Deal with id ${payload.deal_id} not found`,
        value: payload.deal_id,
      });
    }
  }

  return errors;
}

// ============================================
// MAIN HANDLER: Transactions
// ============================================
export async function handleTransactions(
  req: Request,
  supabase: SupabaseClient,
  userId: string,
  id?: string,
  corsHeaders: Record<string, string> = {}
) {
  const url = new URL(req.url);

  switch (req.method) {
    case 'GET':
      if (id) {
        return await handleGetTransactionDetail(supabase, id, corsHeaders);
      } else {
        return await handleGetTransactionsList(supabase, url, corsHeaders);
      }

    case 'POST':
      return await handleCreateTransaction(supabase, userId, req, corsHeaders);

    default:
      return new Response(JSON.stringify({ error: 'Method not allowed' }), {
        status: 405,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
  }
}

// ============================================
// POST /transactions - Create Transaction
// ============================================
async function handleCreateTransaction(
  supabase: SupabaseClient,
  userId: string,
  req: Request,
  corsHeaders: Record<string, string>
) {
  const body: CreateTransactionRequest = await req.json();

  // Validate payload
  const validation = validateTransactionPayload(body);
  if (!validation.ok) {
    return validationError(validation.details, corsHeaders);
  }

  // Verify foreign key references
  const referenceErrors = await verifyReferences(supabase, body);
  if (referenceErrors.length > 0) {
    return validationError(referenceErrors, corsHeaders);
  }

  // Insert transaction
  const { data: transaction, error: insertError } = await supabase
    .from('transactions')
    .insert({
      investor_id: body.investor_id,
      type: body.type,
      amount: body.amount,
      currency: body.currency || 'USD',
      transaction_date: body.transaction_date,
      fund_id: body.fund_id || null,
      deal_id: body.deal_id || null,
      notes: body.notes || null,
      source: body.source || 'MANUAL',
      batch_id: body.batch_id || null,
      created_by: userId,
    })
    .select('id, type')
    .single();

  if (insertError) {
    return mapPgErrorToApiError(insertError, corsHeaders);
  }

  // Auto-create credit for REPURCHASE transactions
  let creditId = null;
  if (body.type === 'REPURCHASE') {
    const { data: credit, error: creditError } = await supabase
      .from('credits_ledger')
      .insert({
        investor_id: body.investor_id,
        fund_id: body.fund_id || null,
        deal_id: body.deal_id || null,
        reason: 'REPURCHASE',
        original_amount: body.amount,
        applied_amount: 0,
        available_amount: body.amount,
        transaction_id: transaction.id,
        created_by: userId,
      })
      .select('id')
      .single();

    if (creditError) {
      console.error('Failed to create credit:', creditError);
      // Don't fail the transaction, just log the error
    } else {
      creditId = credit.id;
    }
  }

  // STUB: Future logic
  // - If type=CONTRIBUTION: Create draft charge (Phase 3)

  const responseMessage =
    body.type === 'CONTRIBUTION'
      ? 'Transaction recorded (charge calculation pending)'
      : creditId
      ? 'Transaction recorded and credit created'
      : 'Transaction recorded (credit creation failed - check logs)';

  return successResponse(
    {
      transaction_id: transaction.id,
      message: responseMessage,
      draft_charge_id: body.type === 'CONTRIBUTION' ? null : undefined,
      credit_id: creditId,
    },
    201,
    corsHeaders
  );
}

// ============================================
// GET /transactions - List Transactions
// ============================================
async function handleGetTransactionsList(
  supabase: SupabaseClient,
  url: URL,
  corsHeaders: Record<string, string>
) {
  // Parse query parameters
  const investorId = url.searchParams.get('investor_id');
  const type = url.searchParams.get('type');
  const fundId = url.searchParams.get('fund_id');
  const dealId = url.searchParams.get('deal_id');
  const from = url.searchParams.get('from'); // date range start
  const to = url.searchParams.get('to'); // date range end
  const batchId = url.searchParams.get('batch_id');
  const limit = parseInt(url.searchParams.get('limit') || '50');
  const offset = parseInt(url.searchParams.get('offset') || '0');

  // Build query with joins
  let query = supabase
    .from('transactions')
    .select(
      `
      *,
      investor:parties!transactions_investor_id_fkey(id, name),
      fund:funds!transactions_fund_id_fkey(id, name),
      deal:deals!transactions_deal_id_fkey(id, name)
    `,
      { count: 'exact' }
    )
    .order('transaction_date', { ascending: false })
    .order('created_at', { ascending: false })
    .range(offset, offset + limit - 1);

  // Apply filters
  if (investorId) {
    query = query.eq('investor_id', parseInt(investorId));
  }
  if (type) {
    query = query.eq('type', type);
  }
  if (fundId) {
    query = query.eq('fund_id', parseInt(fundId));
  }
  if (dealId) {
    query = query.eq('deal_id', parseInt(dealId));
  }
  if (from) {
    query = query.gte('transaction_date', from);
  }
  if (to) {
    query = query.lte('transaction_date', to);
  }
  if (batchId) {
    query = query.eq('batch_id', batchId);
  }

  const { data, error, count } = await query;

  if (error) {
    return mapPgErrorToApiError(error, corsHeaders);
  }

  return successResponse(
    {
      transactions: data || [],
      total_count: count || 0,
      limit,
      offset,
    },
    200,
    corsHeaders
  );
}

// ============================================
// GET /transactions/:id - Get Transaction Detail
// ============================================
async function handleGetTransactionDetail(
  supabase: SupabaseClient,
  id: string,
  corsHeaders: Record<string, string>
) {
  const { data, error } = await supabase
    .from('transactions')
    .select(
      `
      *,
      investor:parties!transactions_investor_id_fkey(id, name, email),
      fund:funds!transactions_fund_id_fkey(id, name, currency),
      deal:deals!transactions_deal_id_fkey(id, name, fund_id)
    `
    )
    .eq('id', id)
    .single();

  if (error) {
    return notFoundError('Transaction', corsHeaders);
  }

  return successResponse(data, 200, corsHeaders);
}
