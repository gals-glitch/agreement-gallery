/**
 * Charges API Client
 * Ticket: UI-01, UI-02
 * Date: 2025-10-21
 *
 * Client for charge workflow API endpoints:
 * - List charges with filters
 * - Get single charge details
 * - Submit charge (DRAFT → PENDING)
 * - Approve charge (PENDING → APPROVED, admin only)
 * - Reject charge (PENDING → REJECTED, admin only)
 * - Mark charge as paid (APPROVED → PAID, admin only)
 */

import { http, buildQueryString } from '@/api/http';

// ============================================
// TYPES
// ============================================
export type ChargeStatus = 'DRAFT' | 'PENDING' | 'APPROVED' | 'PAID' | 'REJECTED';

export interface Charge {
  id: string;
  investor_id: string;
  investor_name: string;
  fund_id?: string;
  fund_name?: string;
  deal_id?: string;
  deal_name?: string;
  contribution_id: string;
  contribution_amount: number;

  // Calculation fields
  base_amount: number;
  discount_amount?: number;
  vat_amount: number;
  cap_amount?: number;
  credits_applied: number;
  net_amount: number;

  // Status and metadata
  status: ChargeStatus;
  submitted_at?: string;
  submitted_by?: string;
  approved_at?: string;
  approved_by?: string;
  rejected_at?: string;
  rejected_by?: string;
  rejection_reason?: string;
  paid_at?: string;
  paid_by?: string;
  payment_ref?: string;

  created_at: string;
  updated_at: string;
}

export interface ChargeBreakdown {
  base_calculation: {
    contribution_amount: number;
    rate_bps: number;
    base_amount: number;
  };
  discounts?: {
    discount_id: string;
    discount_name: string;
    amount: number;
  }[];
  vat: {
    rate: number;
    amount: number;
  };
  caps?: {
    cap_type: string;
    cap_amount: number;
    applied: boolean;
  }[];
  credits_applied: {
    credit_id: string;
    credit_source: string;
    credit_date: string;
    amount: number;
  }[];
}

export interface ChargeDetail extends Charge {
  breakdown: ChargeBreakdown;
  audit_trail: {
    event: string;
    timestamp: string;
    user_name: string;
    details?: string;
  }[];
}

export interface ListChargesParams {
  status?: ChargeStatus;
  investor_id?: string;
  fund_id?: string;
  deal_id?: string;
  page?: number;
  limit?: number;
}

export interface ListChargesResponse {
  data: Charge[];
  total: number;
  page: number;
  limit: number;
}

export interface SubmitChargeResponse {
  charge: Charge;
  message: string;
}

export interface ApproveChargeResponse {
  charge: Charge;
  message: string;
}

export interface RejectChargeRequest {
  reason: string;
}

export interface RejectChargeResponse {
  charge: Charge;
  message: string;
  credits_reversed: number;
}

export interface MarkPaidChargeRequest {
  payment_ref: string;
  paid_at?: string;
}

export interface MarkPaidChargeResponse {
  charge: Charge;
  message: string;
}

// ============================================
// API CLIENT
// ============================================
export const chargesApi = {
  /**
   * List charges with optional filters
   */
  async listCharges(params?: ListChargesParams): Promise<ListChargesResponse> {
    const queryString = buildQueryString(params || {});
    return await http.get<ListChargesResponse>(`/charges${queryString}`);
  },

  /**
   * Get single charge by ID with full details
   */
  async getCharge(chargeId: string): Promise<ChargeDetail> {
    return await http.get<ChargeDetail>(`/charges/${chargeId}`);
  },

  /**
   * Submit charge (DRAFT → PENDING)
   * Finance role required
   */
  async submitCharge(chargeId: string): Promise<SubmitChargeResponse> {
    return await http.post<SubmitChargeResponse>(`/charges/${chargeId}/submit`);
  },

  /**
   * Approve charge (PENDING → APPROVED)
   * Admin role required
   */
  async approveCharge(chargeId: string): Promise<ApproveChargeResponse> {
    return await http.post<ApproveChargeResponse>(`/charges/${chargeId}/approve`);
  },

  /**
   * Reject charge (PENDING → REJECTED)
   * Admin role required
   * Reverses applied credits
   */
  async rejectCharge(
    chargeId: string,
    request: RejectChargeRequest
  ): Promise<RejectChargeResponse> {
    return await http.post<RejectChargeResponse>(
      `/charges/${chargeId}/reject`,
      request
    );
  },

  /**
   * Mark charge as paid (APPROVED → PAID)
   * Admin role required
   */
  async markPaidCharge(
    chargeId: string,
    request: MarkPaidChargeRequest
  ): Promise<MarkPaidChargeResponse> {
    return await http.post<MarkPaidChargeResponse>(
      `/charges/${chargeId}/mark-paid`,
      request
    );
  },

  /**
   * Compute a new charge (idempotent)
   * Finance role required
   */
  async computeCharge(contributionId: string): Promise<Charge> {
    return await http.post<Charge>('/charges/compute', { contribution_id: contributionId });
  },
};
