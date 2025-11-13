/**
 * Commissions API Client
 * MVP: Commissions Engine
 * Date: 2025-10-22
 *
 * Client for commission workflow API endpoints:
 * - List commissions with filters
 * - Get single commission details
 * - Submit commission (DRAFT → PENDING)
 * - Approve commission (PENDING → APPROVED, admin only)
 * - Reject commission (PENDING → REJECTED, admin only)
 * - Mark commission as paid (APPROVED → PAID, admin only)
 * - Compute commission from contribution
 */

import { http, buildQueryString } from '@/api/http';

// ============================================
// TYPES
// ============================================
export type CommissionStatus = 'draft' | 'pending' | 'approved' | 'paid' | 'rejected';

export interface Commission {
  id: string;
  party_id: string;
  party_name: string;
  investor_id: string;
  investor_name: string;
  fund_id?: number;
  fund_name?: string;
  deal_id?: number;
  deal_name?: string;
  contribution_id: string;
  contribution_amount: number;

  // Calculation fields
  base_amount: number;
  vat_amount: number;
  total_amount: number;

  // Status and metadata
  status: CommissionStatus;
  computed_at: string;
  submitted_at?: string;
  approved_at?: string;
  approved_by?: string;
  rejected_at?: string;
  rejected_by?: string;
  reject_reason?: string;
  paid_at?: string;
  payment_ref?: string;

  // Snapshot
  snapshot_json?: any;

  created_at: string;
  updated_at: string;
}

export interface CommissionBreakdown {
  base_calculation: {
    contribution_amount: number;
    rate_bps: number;
    base_amount: number;
  };
  vat: {
    mode: string;
    rate: number;
    amount: number;
  };
}

export interface CommissionDetail extends Commission {
  breakdown?: CommissionBreakdown;
  audit_trail?: {
    event: string;
    timestamp: string;
    user_name: string;
    details?: string;
  }[];
}

export interface ListCommissionsParams {
  status?: CommissionStatus;
  party_id?: string;
  investor_id?: string;
  fund_id?: number;
  deal_id?: number;
  from_date?: string;
  to_date?: string;
  page?: number;
  limit?: number;
}

export interface ListCommissionsResponse {
  data: Commission[];
  total: number;
  page?: number;
  limit?: number;
}

export interface ComputeCommissionRequest {
  contribution_id: string;
}

export interface ComputeCommissionResponse {
  data: Commission;
}

export interface SubmitCommissionResponse {
  data: Commission;
  message?: string;
}

export interface ApproveCommissionResponse {
  data: Commission;
  message?: string;
}

export interface RejectCommissionRequest {
  reason: string;
}

export interface RejectCommissionResponse {
  data: Commission;
  message?: string;
}

export interface MarkPaidCommissionRequest {
  payment_ref: string;
}

export interface MarkPaidCommissionResponse {
  data: Commission;
  message?: string;
}

// ============================================
// API CLIENT
// ============================================
export const commissionsApi = {
  /**
   * List commissions with optional filters
   */
  async listCommissions(params?: ListCommissionsParams): Promise<ListCommissionsResponse> {
    const queryString = buildQueryString(params || {});
    return await http.get<ListCommissionsResponse>(`/commissions${queryString}`);
  },

  /**
   * Get single commission by ID with full details
   */
  async getCommission(commissionId: string): Promise<{ data: CommissionDetail }> {
    return await http.get<{ data: CommissionDetail }>(`/commissions/${commissionId}`);
  },

  /**
   * Compute commission for a contribution (idempotent)
   * Finance role required
   */
  async computeCommission(
    contributionId: string
  ): Promise<ComputeCommissionResponse> {
    return await http.post<ComputeCommissionResponse>('/commissions/compute', {
      contribution_id: contributionId,
    });
  },

  /**
   * Submit commission (draft → pending)
   * Finance role required
   */
  async submitCommission(commissionId: string): Promise<SubmitCommissionResponse> {
    return await http.post<SubmitCommissionResponse>(
      `/commissions/${commissionId}/submit`
    );
  },

  /**
   * Approve commission (pending → approved)
   * Admin role required
   */
  async approveCommission(commissionId: string): Promise<ApproveCommissionResponse> {
    return await http.post<ApproveCommissionResponse>(
      `/commissions/${commissionId}/approve`
    );
  },

  /**
   * Reject commission (pending → rejected)
   * Admin role required
   */
  async rejectCommission(
    commissionId: string,
    request: RejectCommissionRequest
  ): Promise<RejectCommissionResponse> {
    return await http.post<RejectCommissionResponse>(
      `/commissions/${commissionId}/reject`,
      request
    );
  },

  /**
   * Mark commission as paid (approved → paid)
   * Admin role required (NO service key)
   */
  async markPaidCommission(
    commissionId: string,
    request: MarkPaidCommissionRequest
  ): Promise<MarkPaidCommissionResponse> {
    return await http.post<MarkPaidCommissionResponse>(
      `/commissions/${commissionId}/mark-paid`,
      request
    );
  },

  /**
   * Batch compute commissions
   * Finance role required
   */
  async batchComputeCommissions(
    contributionIds: string[]
  ): Promise<{ data: Commission[] }> {
    return await http.post<{ data: Commission[] }>('/commissions/batch-compute', {
      contribution_ids: contributionIds,
    });
  },
};
