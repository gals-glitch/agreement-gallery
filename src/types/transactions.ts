/**
 * Transactions & Credits Types
 * Ticket: PG-401
 * Date: 2025-10-19
 *
 * Type definitions for investor transactions and credits ledger.
 */

// ============================================
// TRANSACTIONS
// ============================================
export type TransactionType = 'CONTRIBUTION' | 'REPURCHASE';
export type TransactionSource = 'MANUAL' | 'CSV_IMPORT' | 'VANTAGE';

export interface Transaction {
  id: string;
  investor_id: number;
  type: TransactionType;
  amount: number;
  currency: string;
  transaction_date: string; // YYYY-MM-DD
  fund_id: number | null;
  deal_id: number | null;
  notes: string | null;
  source: TransactionSource;
  batch_id: string | null;
  created_at: string;
  created_by: string | null;
}

export interface TransactionWithRelations extends Transaction {
  investor: {
    id: number;
    name: string;
    email: string | null;
  } | null;
  fund: {
    id: number;
    name: string;
    currency: string;
  } | null;
  deal: {
    id: number;
    name: string;
    fund_id: number | null;
  } | null;
}

export interface CreateTransactionRequest {
  investor_id: number;
  type: TransactionType;
  amount: number;
  currency?: string;
  transaction_date: string;
  fund_id?: number;
  deal_id?: number;
  notes?: string;
  source?: TransactionSource;
  batch_id?: string;
}

export interface CreateTransactionResponse {
  transaction_id: string;
  message: string;
  draft_charge_id?: null; // STUB: Will be populated in Phase 3
  credit_id?: null; // STUB: Will be populated in Phase 3
}

export interface TransactionsListResponse {
  transactions: TransactionWithRelations[];
  total_count: number;
  limit: number;
  offset: number;
}

export interface TransactionFilters {
  investor_id?: number;
  type?: TransactionType;
  fund_id?: number;
  deal_id?: number;
  from?: string; // Date YYYY-MM-DD
  to?: string; // Date YYYY-MM-DD
  batch_id?: string;
  limit?: number;
  offset?: number;
}

// ============================================
// CREDITS
// ============================================
export type CreditType = 'EARLY_BIRD' | 'PROMOTIONAL';
export type CreditStatus = 'AVAILABLE' | 'APPLIED' | 'EXPIRED';

export interface Credit {
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

export interface CreditWithRelations extends Credit {
  investor: {
    id: number;
    name: string;
    email: string | null;
  } | null;
  transaction: {
    id: string;
    type: TransactionType;
    transaction_date: string;
  } | null;
}

export interface CreateCreditRequest {
  investor_id: number;
  credit_type: CreditType;
  amount: number;
  currency?: string;
  transaction_id?: string;
}

export interface CreateCreditResponse {
  credit_id: string;
  message: string;
}

export interface CreditBalance {
  total_available: number;
  total_applied: number;
  total_expired: number;
  currency: string;
}

export interface CreditsListResponse {
  credits: CreditWithRelations[];
  total_count: number;
  limit: number;
  offset: number;
  balance: CreditBalance;
}

export interface CreditFilters {
  investor_id?: number;
  credit_type?: CreditType;
  status?: CreditStatus;
  limit?: number;
  offset?: number;
}
