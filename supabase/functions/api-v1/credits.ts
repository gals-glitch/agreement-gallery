/**
 * Credits API Handler
 * Ticket: PG-401
 * Date: 2025-10-19
 *
 * Endpoints:
 * - POST /api-v1/credits - Create credit (stub)
 * - GET /api-v1/credits - List credits with filters and balance calculation
 *
 * STUB NOTICE: This is Phase 2 stub work. Credit application logic to charges
 * will be implemented in Phase 3.
 */

import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import {
  validationError,
  successResponse,
  mapPgErrorToApiError,
  type ApiErrorDetail,
} from './errors.ts';

// ============================================
// TYPES
// ============================================
export type CreditType = 'EARLY_BIRD' | 'PROMOTIONAL';
export type CreditStatus = 'AVAILABLE' | 'APPLIED' | 'EXPIRED';

interface CreateCreditRequest {
  investor_id: number;
  credit_type: CreditType;
  amount: number;
  currency?: string;
  transaction_id?: string; // Optional link to source transaction
}

interface Credit {
  id: string;
  investor_id: number;
  credit_type: CreditType;
  amount: number;
  currency: string;
  status: CreditStatus;
  original_amount: number;
  remaining_amount: number;
  transaction_id: string | null;
  created_at: string;
  created_by: string | null;
}

interface CreditBalance {
  total_available: number;
  total_applied: number;
  total_expired: number;
  currency: string;
}

// ============================================
// HELPER: Validate Credit Payload
// ============================================
function validateCreditPayload(p: any): { ok: true } | { ok: false; details: ApiErrorDetail[] } {
  const details: ApiErrorDetail[] = [];

  // Required fields
  if (!p.investor_id || typeof p.investor_id !== 'number') {
    details.push({
      field: 'investor_id',
      message: 'investor_id is required and must be a number',
      value: p.investor_id,
    });
  }

  // Credit type validation
  if (!p.credit_type || !['EARLY_BIRD', 'PROMOTIONAL'].includes(p.credit_type)) {
    details.push({
      field: 'credit_type',
      message: 'credit_type must be EARLY_BIRD or PROMOTIONAL',
      value: p.credit_type,
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

  if (details.length) return { ok: false, details };
  return { ok: true };
}

// ============================================
// HELPER: Verify Investor Exists
// ============================================
async function verifyInvestor(
  supabase: SupabaseClient,
  investorId: number
): Promise<ApiErrorDetail | null> {
  const { data: investor, error } = await supabase
    .from('parties')
    .select('id')
    .eq('id', investorId)
    .single();

  if (error || !investor) {
    return {
      field: 'investor_id',
      message: `Investor with id ${investorId} not found`,
      value: investorId,
    };
  }

  return null;
}

// ============================================
// MAIN HANDLER: Credits
// ============================================
export async function handleCredits(
  req: Request,
  supabase: SupabaseClient,
  userId: string,
  corsHeaders: Record<string, string> = {}
) {
  const url = new URL(req.url);

  switch (req.method) {
    case 'GET':
      return await handleGetCreditsList(supabase, url, corsHeaders);

    case 'POST':
      return await handleCreateCredit(supabase, userId, req, corsHeaders);

    default:
      return new Response(JSON.stringify({ error: 'Method not allowed' }), {
        status: 405,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
  }
}

// ============================================
// POST /credits - Create Credit
// ============================================
async function handleCreateCredit(
  supabase: SupabaseClient,
  userId: string,
  req: Request,
  corsHeaders: Record<string, string>
) {
  const body: CreateCreditRequest = await req.json();

  // Validate payload
  const validation = validateCreditPayload(body);
  if (!validation.ok) {
    return validationError(validation.details, corsHeaders);
  }

  // Verify investor exists
  const investorError = await verifyInvestor(supabase, body.investor_id);
  if (investorError) {
    return validationError([investorError], corsHeaders);
  }

  // Verify transaction_id if provided
  if (body.transaction_id) {
    const { data: transaction, error: txError } = await supabase
      .from('transactions')
      .select('id')
      .eq('id', body.transaction_id)
      .single();

    if (txError || !transaction) {
      return validationError(
        [
          {
            field: 'transaction_id',
            message: `Transaction with id ${body.transaction_id} not found`,
            value: body.transaction_id,
          },
        ],
        corsHeaders
      );
    }
  }

  // Insert credit
  const { data: credit, error: insertError } = await supabase
    .from('credits_ledger')
    .insert({
      investor_id: body.investor_id,
      credit_type: body.credit_type,
      amount: body.amount,
      currency: body.currency || 'USD',
      status: 'AVAILABLE',
      original_amount: body.amount, // Set to initial amount
      remaining_amount: body.amount, // Set to initial amount
      transaction_id: body.transaction_id || null,
      created_by: userId,
    })
    .select('id')
    .single();

  if (insertError) {
    return mapPgErrorToApiError(insertError, corsHeaders);
  }

  return successResponse(
    {
      credit_id: credit.id,
      message: 'Credit created successfully',
    },
    201,
    corsHeaders
  );
}

// ============================================
// GET /credits - List Credits with Balance
// ============================================
async function handleGetCreditsList(
  supabase: SupabaseClient,
  url: URL,
  corsHeaders: Record<string, string>
) {
  // Parse query parameters
  const investorId = url.searchParams.get('investor_id');
  const creditType = url.searchParams.get('credit_type');
  const status = url.searchParams.get('status');
  const limit = parseInt(url.searchParams.get('limit') || '50');
  const offset = parseInt(url.searchParams.get('offset') || '0');

  // Build query with joins
  let query = supabase
    .from('credits_ledger')
    .select(
      `
      *,
      investor:parties!credits_ledger_investor_id_fkey(id, name, email),
      transaction:transactions(id, type, transaction_date)
    `,
      { count: 'exact' }
    )
    .order('created_at', { ascending: false })
    .range(offset, offset + limit - 1);

  // Apply filters
  if (investorId) {
    query = query.eq('investor_id', parseInt(investorId));
  }
  if (creditType) {
    query = query.eq('credit_type', creditType);
  }
  if (status) {
    query = query.eq('status', status);
  }

  const { data, error, count } = await query;

  if (error) {
    return mapPgErrorToApiError(error, corsHeaders);
  }

  // Calculate balance summary
  const balance = calculateCreditBalance(data || []);

  return successResponse(
    {
      credits: data || [],
      total_count: count || 0,
      limit,
      offset,
      balance,
    },
    200,
    corsHeaders
  );
}

// ============================================
// HELPER: Calculate Credit Balance
// ============================================
function calculateCreditBalance(credits: any[]): CreditBalance {
  const balance: CreditBalance = {
    total_available: 0,
    total_applied: 0,
    total_expired: 0,
    currency: 'USD', // Assuming single currency for now
  };

  credits.forEach((credit) => {
    if (credit.status === 'AVAILABLE') {
      balance.total_available += parseFloat(credit.remaining_amount || 0);
    } else if (credit.status === 'APPLIED') {
      balance.total_applied += parseFloat(credit.original_amount || 0);
    } else if (credit.status === 'EXPIRED') {
      balance.total_expired += parseFloat(credit.original_amount || 0);
    }
  });

  // Round to 2 decimal places
  balance.total_available = Math.round(balance.total_available * 100) / 100;
  balance.total_applied = Math.round(balance.total_applied * 100) / 100;
  balance.total_expired = Math.round(balance.total_expired * 100) / 100;

  return balance;
}
