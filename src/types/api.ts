/**
 * API Types for Redesigned System
 * Version: 2.0
 * Date: 2025-10-16
 */

// ============================================
// ENUMS
// ============================================
export type AgreementScope = 'FUND' | 'DEAL';
export type PricingMode = 'TRACK' | 'CUSTOM';
export type AgreementStatus = 'DRAFT' | 'AWAITING_APPROVAL' | 'APPROVED' | 'SUPERSEDED';
export type TrackCode = 'A' | 'B' | 'C';
export type RunStatus = 'DRAFT' | 'IN_PROGRESS' | 'AWAITING_APPROVAL' | 'APPROVED';

// ============================================
// PARTY
// ============================================
export interface Party {
  id: number;
  name: string;
  email: string | null;
  country: string | null;
  tax_id: string | null;
  active: boolean;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface CreatePartyRequest {
  name: string;
  email?: string;
  country?: string;
  tax_id?: string;
  active?: boolean;
  notes?: string;
}

export interface PartiesListResponse {
  items: Party[];
  total: number;
}

// ============================================
// FUND
// ============================================
export interface Fund {
  id: number;
  name: string;
  vintage_year: number | null;
  currency: string;
  status: string;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface CreateFundRequest {
  name: string;
  vintage_year?: number;
  currency?: string;
  status?: string;
  notes?: string;
}

export interface FundsListResponse {
  items: Fund[];
  total: number;
}

// ============================================
// DEAL
// ============================================
export interface Deal {
  id: number;
  fund_id: number | null;
  name: string;
  address: string | null;
  status: string;
  close_date: string | null;
  partner_company_id: number | null;
  fund_group_id: number | null;
  sector: string | null;
  year_built: number | null;
  units: number | null;
  sqft: number | null;
  income_producing: boolean;
  exclude_gp_from_commission: boolean;
  equity_to_raise: number | null;  // READ-ONLY from Scoreboard
  raised_so_far: number | null;    // READ-ONLY from Scoreboard
  created_at: string;
  updated_at: string;
}

export interface CreateDealRequest {
  fund_id?: number;
  name: string;
  address?: string;
  status?: string;
  close_date?: string;
  partner_company_id?: number;
  fund_group_id?: number;
  sector?: string;
  year_built?: number;
  units?: number;
  sqft?: number;
  income_producing?: boolean;
  exclude_gp_from_commission?: boolean;
}

export interface UpdateDealRequest {
  status?: string;
  exclude_gp_from_commission?: boolean;
}

export interface DealsListResponse {
  items: Deal[];
  total: number;
}

// ============================================
// FUND TRACK
// ============================================
export interface FundTrack {
  id: number;
  fund_id: number;
  track_code: TrackCode;
  upfront_bps: number;
  deferred_bps: number;
  offset_months: number;
  tier_min: number | null;
  tier_max: number | null;
  valid_from: string;
  valid_to: string | null;
  is_locked: boolean;
  seed_version: number;
  created_at: string;
}

// ============================================
// AGREEMENT
// ============================================
export interface AgreementCustomTerms {
  upfront_bps: number;
  deferred_bps: number;
  caps_json?: any;
  tiers_json?: any;
}

export interface AgreementSnapshot {
  id: number;
  agreement_id: number;
  scope: AgreementScope;
  pricing_mode: PricingMode;
  track_code: TrackCode | null;
  resolved_upfront_bps: number;
  resolved_deferred_bps: number;
  vat_included: boolean;
  effective_from: string;
  effective_to: string | null;
  seed_version: number | null;
  approved_at: string;
}

export interface Agreement {
  id: number;
  party_id: number;
  scope: AgreementScope;
  fund_id: number | null;
  deal_id: number | null;
  pricing_mode: PricingMode;
  selected_track: TrackCode | null;
  effective_from: string;
  effective_to: string | null;
  vat_included: boolean;
  status: AgreementStatus;
  created_by: string | null;
  created_at: string;
  updated_at: string;

  // Joined data
  party?: { name: string };
  fund?: { name: string };
  deal?: { name: string; code: string };
  custom_terms?: AgreementCustomTerms;
  snapshot?: AgreementSnapshot;
}

export interface CreateAgreementRequest {
  party_id: number;
  scope: AgreementScope;
  fund_id?: number;
  deal_id?: number;
  pricing_mode: PricingMode;
  selected_track?: TrackCode;
  effective_from: string;
  effective_to?: string;
  vat_included?: boolean;
  custom_terms?: AgreementCustomTerms;
}

export interface AgreementsListResponse {
  items: Agreement[];
  total: number;
}

export interface AgreementActionResponse {
  status: AgreementStatus;
  message?: string;
}

export interface AmendAgreementResponse {
  new_agreement_id: number;
  message: string;
}

// ============================================
// RUN
// ============================================
export interface Run {
  id: number;
  fund_id: number;
  period_from: string;
  period_to: string;
  status: RunStatus;
  totals: {
    fees_total: number;
    lines_count: number;
  } | null;
  created_at: string;
  updated_at: string;

  // Joined data
  fund?: { name: string };
}

export interface CreateRunRequest {
  fund_id: number;
  period_from: string;
  period_to: string;
}

export interface RunsListResponse {
  items: Run[];
  total: number;
}

export interface RunGenerateResponse {
  summary: {
    fees_total: number;
    lines: number;
  };
  export: {
    csv_path: string;
  };
}

export interface RunActionRequest {
  comment?: string;
}

export interface RunActionResponse {
  status: RunStatus;
  message?: string;
}

// ============================================
// INVESTOR
// ============================================
export interface Investor {
  id: number;
  name: string;
  external_id: string | null;
  currency: string;
  is_gp: boolean;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

// ============================================
// CONTRIBUTION
// ============================================
export interface Contribution {
  id: number;
  investor_id: number;
  deal_id: number | null;
  fund_id: number | null;
  paid_in_date: string;
  amount: number;
  currency: string;
  fx_rate: number | null;
  source_batch: string | null;
  created_at: string;

  // Joined data
  investor?: { name: string; is_gp: boolean };
  deal?: { name: string };
  fund?: { name: string };
}

// ============================================
// API ERROR (Updated ORC-002)
// ============================================
export interface ApiErrorDetail {
  field?: string;      // Field name (e.g., 'investor_id', 'amount')
  row?: number;        // Row number for CSV/batch operations
  value?: any;         // Invalid value provided
  constraint?: string; // Constraint name (e.g., 'amount_positive', 'unique_email')
  message?: string;    // Human-readable error message
}

export interface ApiError {
  code: string;              // Error code (e.g., 'VALIDATION_ERROR', 'FORBIDDEN')
  message: string;           // Human-readable summary
  details?: ApiErrorDetail[]; // Optional field-level or row-level errors
  timestamp: string;         // ISO 8601 timestamp
  requestId?: string;        // Optional request tracking ID
}

// Legacy support - will be removed in future versions
export interface APIError {
  error: string;
  details?: any;
  code?: string;
}

// ============================================
// PAGINATION
// ============================================
export interface PaginationParams {
  limit?: number;
  offset?: number;
}

// ============================================
// QUERY PARAMS
// ============================================
export interface PartiesQueryParams extends PaginationParams {
  q?: string;
  active?: boolean;
}

export interface AgreementsQueryParams extends PaginationParams {
  party_id?: number;
  fund_id?: number;
  deal_id?: number;
  status?: AgreementStatus;
}

export interface RunsQueryParams extends PaginationParams {
  fund_id?: number;
  status?: RunStatus;
}
