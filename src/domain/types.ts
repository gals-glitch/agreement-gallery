export type VatMode = 'included' | 'added';
export type CalculationBasis = 'distribution_amount' | 'cumulative_amount' | 'monthly_volume' | 'quarterly_volume' | 'annual_volume';
export type RuleType = 'percentage' | 'fixed_amount' | 'tiered' | 'hybrid' | 'conditional' | 'management_fee' | 'promote_share' | 'credit_netting' | 'discount' | 'sub_agent_split';
export type PartyType = 'distributor' | 'referrer' | 'partner';

// Shared domain types for Parties, Agreements, Deals, Tracks
export interface Party {
  id: string;
  name: string;
  party_type: PartyType;
  email?: string | null;
  phone?: string | null;
  address?: string | null;
  country?: string | null;
  tax_id?: string | null;
  is_active: boolean;
  metadata?: Record<string, any>;
  created_at: string;
  updated_at: string;
  created_by?: string | null;
}

export interface Deal {
  id: string;
  name: string;
  code: string;
  fund_id: string;
  close_date?: string | null;
  is_active: boolean;
  metadata?: Record<string, any>;
  created_at: string;
  updated_at: string;
}

export interface FundVITrack {
  id: string;
  track_key: string;
  config_version: string;
  min_raised: number;
  max_raised?: number | null;
  upfront_rate_bps: number;
  deferred_rate_bps: number;
  deferred_offset_months: number;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface Agreement {
  id: string;
  name: string;
  agreement_type: string;
  effective_from: string;
  effective_to: string | null;
  introduced_by_party_id: string;
  status: string;
  applies_scope: 'FUND' | 'DEAL';
  deal_id?: string | null;
  track_key?: string | null;
  vat_mode?: VatMode;
  inherit_fund_rates?: boolean;
  upfront_rate_bps?: number | null;
  deferred_rate_bps?: number | null;
  deferred_offset_months?: number | null;
  metadata?: Record<string, any>;
  created_at: string;
  updated_at: string;
}

export interface CommissionRule {
  id: string;
  name: string;
  description?: string;
  rule_type: RuleType;
  entity_type: string;
  entity_name?: string;
  fund_name?: string;
  base_rate?: number;
  fixed_amount?: number;
  min_amount: number;
  max_amount?: number;
  calculation_basis: CalculationBasis;
  vat_mode: VatMode;
  vat_rate_table: string;
  effective_from?: string;
  effective_to?: string;
  priority: number;
  is_active: boolean;
  rule_version: number;
  rule_checksum: string;
  tiers?: CommissionTier[];
  conditions?: RuleCondition[];
  // Scope fields (Phase 0)
  applies_scope?: 'FUND' | 'DEAL';
  deal_id?: string | null;
}

export interface CommissionTier {
  id: string;
  rule_id: string;
  tier_order: number;
  min_threshold: number;
  max_threshold?: number;
  rate: number;
  fixed_amount?: number;
  description?: string;
}

export interface RuleCondition {
  id: string;
  rule_id: string;
  condition_group: number;
  field_name: string;
  operator: string;
  value_text?: string;
  value_number?: number;
  value_date?: string;
  value_array?: string[];
  is_required: boolean;
}

export interface VatRate {
  id: string;
  country_code: string;
  rate: number;
  effective_from: string;
  effective_to?: string;
  is_default: boolean;
}

export interface Credit {
  id: string;
  investor_id: string;
  investor_name: string;
  fund_name?: string;
  credit_type: string;
  amount: number;
  remaining_balance: number;
  currency: string;
  date_posted: string;
  status: string;
  apply_policy: string;
  // Scope fields (Phase 0)
  scope: 'FUND' | 'DEAL';
  deal_id?: string | null;
}

export interface Contribution {
  id: string;
  investor_id?: string;
  investor_name: string;
  fund_name?: string;
  distributor_name?: string;
  referrer_name?: string;
  partner_name?: string;
  distribution_amount: number;
  distribution_date?: string;
  calculation_run_id?: string;
  // Deal fields (Phase 0)
  deal_id?: string | null;
  deal_code?: string | null;
  deal_name?: string | null;
}

export interface FeeLine {
  contribution_id: string;
  rule_id: string;
  rule_version: number;
  entity_type: string;
  entity_name: string;
  base_amount: number;
  applied_rate?: number;
  tier_applied?: number;
  fee_gross: number;
  vat_rate: number;
  vat_amount: number;
  fee_net: number;
  total_payable: number;
  credits_applied?: CreditApplication[];
  calculation_method: string;
  notes?: string;
  // Scope and deal fields (Phase 1)
  scope?: 'FUND' | 'DEAL';
  deal_id?: string | null;
  deal_code?: string | null;
  deal_name?: string | null;
}

export interface CreditApplication {
  credit_id: string;
  amount_applied: number;
  remaining_balance: number;
}

export interface CalculationInput {
  calculation_run_id: string;
  contributions: Contribution[];
  as_of_date: string;
}

export interface CalculationOutput {
  calculation_run_id: string;
  fee_lines: FeeLine[];
  total_gross: number;
  total_vat: number;
  total_net: number;
  ruleset_version: string;
  ruleset_checksum: string;
  scope_breakdown?: {
    FUND: { gross: number; vat: number; net: number; count: number };
    DEAL: { gross: number; vat: number; net: number; count: number };
  };
  warnings: string[];
  errors: string[];
}

export interface CalculationContext {
  distribution: Contribution;
  rules: CommissionRule[];
  vat_rates: VatRate[];
  credits: Credit[];
  historical_data?: {
    cumulative_amount: number;
    cumulative_amount_ytd: number;
    deal_count: number;
    monthly_volume: number;
    quarterly_volume: number;
    annual_volume: number;
  };
}
