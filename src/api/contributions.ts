/**
 * Contributions API Client
 * Handles paid-in capital tracking with XOR validation (exactly one of deal_id or fund_id)
 */

import { http, buildQueryString } from './http';

// ============================================
// TYPES
// ============================================
export interface Contribution {
  id: number;
  investor_id: number;
  investor_name?: string; // From join
  deal_id: number | null;
  deal_name?: string; // From join
  fund_id: number | null;
  fund_name?: string; // From join
  paid_in_date: string; // YYYY-MM-DD
  amount: number;
  currency: string;
  fx_rate: number | null;
  source_batch: string | null;
  created_at: string;
  updated_at: string;
}

export interface CreateContributionRequest {
  investor_id: number;
  deal_id?: number;
  fund_id?: number;
  paid_in_date: string; // YYYY-MM-DD
  amount: number;
  currency?: string; // Default: USD
  fx_rate?: number;
  source_batch?: string;
}

export interface ContributionsQueryParams {
  fund_id?: number;
  deal_id?: number;
  investor_id?: number;
  from?: string; // YYYY-MM-DD
  to?: string; // YYYY-MM-DD
  batch?: string;
}

export interface ContributionsListResponse {
  items: Contribution[];
  total: number;
}

export interface BatchImportResponse {
  inserted: number[]; // Array of created contribution IDs
}

export interface ValidationError {
  index: number;
  errors: string[];
}

export interface BatchValidationErrorResponse {
  error: 'VALIDATION';
  details: ValidationError[];
}

// ============================================
// CLIENT-SIDE VALIDATION
// ============================================
export function validateContribution(data: CreateContributionRequest): string[] {
  const errors: string[] = [];

  // XOR validation: exactly one of deal_id or fund_id
  const hasDeal = data.deal_id !== undefined && data.deal_id !== null;
  const hasFund = data.fund_id !== undefined && data.fund_id !== null;

  if (!hasDeal && !hasFund) {
    errors.push('Either deal_id or fund_id is required');
  } else if (hasDeal && hasFund) {
    errors.push('Exactly one of deal_id or fund_id is required, not both');
  }

  // Required fields
  if (!data.investor_id) {
    errors.push('investor_id is required');
  }
  if (!data.paid_in_date) {
    errors.push('paid_in_date is required');
  }
  if (typeof data.amount !== 'number' || data.amount <= 0) {
    errors.push('amount must be a positive number');
  }

  // Date format validation
  if (data.paid_in_date && !/^\d{4}-\d{2}-\d{2}$/.test(data.paid_in_date)) {
    errors.push('paid_in_date must be in YYYY-MM-DD format');
  }

  return errors;
}

export function validateContributionBatch(data: CreateContributionRequest[]): ValidationError[] {
  const errors: ValidationError[] = [];

  data.forEach((row, index) => {
    const rowErrors = validateContribution(row);
    if (rowErrors.length > 0) {
      errors.push({ index, errors: rowErrors });
    }
  });

  return errors;
}

// ============================================
// API CLIENT
// ============================================
export const contributionsAPI = {
  /**
   * List contributions with filters
   * GET /contributions?fund_id=5&from=2025-01-01
   */
  list: async (params: ContributionsQueryParams = {}): Promise<ContributionsListResponse> => {
    const query = buildQueryString(params);
    return http.get<ContributionsListResponse>(`/contributions${query}`);
  },

  /**
   * Create a single contribution
   * POST /contributions
   */
  create: async (data: CreateContributionRequest): Promise<{ id: number }> => {
    // Client-side validation
    const errors = validateContribution(data);
    if (errors.length > 0) {
      throw new Error(`Validation failed: ${errors.join(', ')}`);
    }

    return http.post<{ id: number }>('/contributions', data);
  },

  /**
   * Batch import contributions
   * POST /contributions/batch
   *
   * Pre-validates all rows before submission.
   * Returns per-row errors if validation fails.
   */
  batchImport: async (data: CreateContributionRequest[]): Promise<BatchImportResponse> => {
    // Client-side validation
    const errors = validateContributionBatch(data);
    if (errors.length > 0) {
      throw new Error(`Validation failed for ${errors.length} row(s)`);
    }

    return http.post<BatchImportResponse>('/contributions/batch', data);
  },
};

// ============================================
// EXPORT
// ============================================
export default contributionsAPI;
