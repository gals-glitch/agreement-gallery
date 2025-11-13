/**
 * Transactions & Credits React Query Hooks
 * Ticket: PG-401
 * Date: 2025-10-19
 *
 * Provides hooks for:
 * - Fetching transactions list with filters
 * - Fetching single transaction detail
 * - Creating transactions
 * - Fetching credits list with balance
 * - Creating credits
 */

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { toast } from '@/hooks/use-toast';
import type {
  Transaction,
  TransactionWithRelations,
  CreateTransactionRequest,
  CreateTransactionResponse,
  TransactionsListResponse,
  TransactionFilters,
  Credit,
  CreditWithRelations,
  CreateCreditRequest,
  CreateCreditResponse,
  CreditsListResponse,
  CreditFilters,
} from '@/types/transactions';

// ============================================
// HTTP CLIENT (Assuming http.ts exists)
// ============================================
// Import your existing http client that handles auth headers
import { http } from '@/api/http';

// ============================================
// QUERY KEYS
// ============================================
const TRANSACTIONS_KEY = 'transactions';
const CREDITS_KEY = 'credits';

export const transactionsKeys = {
  all: [TRANSACTIONS_KEY] as const,
  lists: () => [...transactionsKeys.all, 'list'] as const,
  list: (filters: TransactionFilters) => [...transactionsKeys.lists(), filters] as const,
  details: () => [...transactionsKeys.all, 'detail'] as const,
  detail: (id: string) => [...transactionsKeys.details(), id] as const,
};

export const creditsKeys = {
  all: [CREDITS_KEY] as const,
  lists: () => [...creditsKeys.all, 'list'] as const,
  list: (filters: CreditFilters) => [...creditsKeys.lists(), filters] as const,
};

// ============================================
// TRANSACTIONS HOOKS
// ============================================

/**
 * Fetch transactions list with filters
 */
export function useTransactions(filters: TransactionFilters = {}) {
  return useQuery<TransactionsListResponse>({
    queryKey: transactionsKeys.list(filters),
    queryFn: async () => {
      const params = new URLSearchParams();
      if (filters.investor_id) params.append('investor_id', filters.investor_id.toString());
      if (filters.type) params.append('type', filters.type);
      if (filters.fund_id) params.append('fund_id', filters.fund_id.toString());
      if (filters.deal_id) params.append('deal_id', filters.deal_id.toString());
      if (filters.from) params.append('from', filters.from);
      if (filters.to) params.append('to', filters.to);
      if (filters.batch_id) params.append('batch_id', filters.batch_id);
      if (filters.limit) params.append('limit', filters.limit.toString());
      if (filters.offset) params.append('offset', filters.offset.toString());

      const response = await http.get<TransactionsListResponse>(
        `/transactions?${params.toString()}`
      );
      return response;
    },
    staleTime: 1 * 60 * 1000, // 1 minute
  });
}

/**
 * Fetch single transaction detail
 */
export function useTransaction(id: string | undefined) {
  return useQuery<TransactionWithRelations>({
    queryKey: transactionsKeys.detail(id!),
    queryFn: async () => {
      const response = await http.get<TransactionWithRelations>(`/transactions/${id}`);
      return response;
    },
    enabled: !!id,
    staleTime: 1 * 60 * 1000,
  });
}

/**
 * Create new transaction
 */
export function useCreateTransaction() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (data: CreateTransactionRequest) => {
      return await http.post<CreateTransactionResponse>('/transactions', data);
    },
    onSuccess: (data) => {
      // Invalidate transactions lists to refetch
      queryClient.invalidateQueries({ queryKey: transactionsKeys.lists() });

      toast({
        title: 'Transaction Created',
        description: data.message || 'Transaction recorded successfully',
      });
    },
    onError: (error: any) => {
      // Error toast handled by http.ts global handler
      console.error('Failed to create transaction:', error);
    },
  });
}

// ============================================
// CREDITS HOOKS
// ============================================

/**
 * Fetch credits list with filters and balance
 */
export function useCredits(filters: CreditFilters = {}) {
  return useQuery<CreditsListResponse>({
    queryKey: creditsKeys.list(filters),
    queryFn: async () => {
      const params = new URLSearchParams();
      if (filters.investor_id) params.append('investor_id', filters.investor_id.toString());
      if (filters.credit_type) params.append('credit_type', filters.credit_type);
      if (filters.status) params.append('status', filters.status);
      if (filters.limit) params.append('limit', filters.limit.toString());
      if (filters.offset) params.append('offset', filters.offset.toString());

      const response = await http.get<CreditsListResponse>(`/credits?${params.toString()}`);
      return response;
    },
    staleTime: 1 * 60 * 1000, // 1 minute
  });
}

/**
 * Create new credit
 */
export function useCreateCredit() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (data: CreateCreditRequest) => {
      return await http.post<CreateCreditResponse>('/credits', data);
    },
    onSuccess: (data) => {
      // Invalidate credits lists to refetch
      queryClient.invalidateQueries({ queryKey: creditsKeys.lists() });

      toast({
        title: 'Credit Created',
        description: data.message || 'Credit created successfully',
      });
    },
    onError: (error: any) => {
      // Error toast handled by http.ts global handler
      console.error('Failed to create credit:', error);
    },
  });
}
