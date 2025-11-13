export type RuleType = 'percentage' | 'fixed_amount' | 'tiered' | 'hybrid' | 'conditional' | 'management_fee' | 'promote_share' | 'credit_netting' | 'discount' | 'sub_agent_split';
export type ConditionOperator = 'equals' | 'greater_than' | 'less_than' | 'greater_equal' | 'less_equal' | 'between' | 'in' | 'not_in';
export type CalculationBasis = 'distribution_amount' | 'cumulative_amount' | 'monthly_volume' | 'quarterly_volume' | 'annual_volume';
export type EntityType = 'distributor' | 'referrer' | 'partner';

export interface AdvancedCommissionRule {
  id: string;
  name: string;
  description?: string;
  rule_type: RuleType;
  entity_type: EntityType;
  entity_name?: string;
  fund_name?: string;
  
  // Basic configuration
  base_rate?: number;
  fixed_amount?: number;
  min_amount: number;
  max_amount?: number;
  
  // Calculation settings
  calculation_basis: CalculationBasis;
  effective_from?: string;
  effective_to?: string;
  
  // Rule management
  priority: number;
  is_active: boolean;
  requires_approval: boolean;
  
  // Relationships
  tiers?: CommissionTier[];
  conditions?: RuleCondition[];
  
  created_at: string;
  updated_at: string;
  created_by?: string;
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
  created_at: string;
}

export interface RuleCondition {
  id: string;
  rule_id: string;
  condition_group: number;
  field_name: string;
  operator: ConditionOperator;
  value_text?: string;
  value_number?: number;
  value_date?: string;
  value_array?: string[];
  is_required: boolean;
  created_at: string;
}

export interface AdvancedCommissionCalculation {
  id: string;
  calculation_run_id: string;
  distribution_id: string;
  rule_id: string;
  
  // Entity information
  commission_type: EntityType;
  entity_name: string;
  
  // Calculation details
  calculation_basis: CalculationBasis;
  base_amount: number;
  applied_rate?: number;
  tier_applied?: number;
  
  // Results
  gross_commission: number;
  vat_rate: number;
  vat_amount: number;
  net_commission: number;
  
  // Audit
  calculation_method?: string;
  conditions_met?: Record<string, any>;
  execution_time_ms?: number;
  status: 'calculated' | 'approved' | 'paid' | 'disputed';
  notes?: string;
  
  created_at: string;
  calculated_by?: string;
}

export interface RuleExecutionHistory {
  id: string;
  calculation_run_id?: string;
  rule_id: string;
  distribution_id?: string;
  execution_result: 'success' | 'failed' | 'skipped';
  conditions_evaluated?: Record<string, any>;
  error_message?: string;
  execution_time_ms?: number;
  created_at: string;
}

export interface CalculationContext {
  distribution: {
    id: string;
    investor_name: string;
    fund_name?: string;
    distribution_amount: number;
    distributor_name?: string;
    referrer_name?: string;
    partner_name?: string;
    distribution_date?: string;
    deal_name?: string;
  };
  historical_data?: {
    cumulative_amount: number;
    cumulative_amount_ytd: number;
    cumulative_amount_term: number;
    deal_count: number;
    monthly_volume: number;
    quarterly_volume: number;
    annual_volume: number;
  };
  available_credits?: CreditBalance[];
  metadata?: Record<string, any>;
}

export interface CreditBalance {
  id: string;
  credit_type: 'repurchase' | 'equalisation';
  remaining_balance: number;
  currency: string;
  investor_name: string;
  fund_name?: string;
}

export interface EnhancedCalculationResult extends CalculationResult {
  credits_applied?: {
    credit_id: string;
    amount_applied: number;
    remaining_balance: number;
  }[];
  deal_count?: number;
  cumulative_amount?: number;
  calculation_trace?: {
    inputs: Record<string, any>;
    rule_version: string;
    formula_id: string;
    timestamp: string;
    steps: CalculationStep[];
  };
}

export interface CalculationStep {
  step_name: string;
  description: string;
  input_values: Record<string, any>;
  calculation: string;
  result: number;
}

export interface CalculationResult {
  rule_id: string;
  entity_type: EntityType;
  entity_name: string;
  applicable: boolean;
  calculation?: {
    base_amount: number;
    applied_rate?: number;
    tier_applied?: number;
    gross_commission: number;
    vat_rate: number;
    vat_amount: number;
    net_commission: number;
    method: string;
  };
  conditions_met?: Record<string, any>;
  execution_time_ms: number;
  error?: string;
}

export interface RuleBuilderConfig {
  rule_type: RuleType;
  entity_type: EntityType;
  entity_name?: string;
  fund_name?: string;
  base_rate?: number;
  fixed_amount?: number;
  min_amount: number;
  max_amount?: number;
  calculation_basis: CalculationBasis;
  tiers: Array<{
    min_threshold: number;
    max_threshold?: number;
    rate: number;
    fixed_amount?: number;
    description?: string;
  }>;
  conditions: Array<{
    condition_group: number;
    field_name: string;
    operator: ConditionOperator;
    value: any;
    is_required: boolean;
  }>;
  effective_from?: string;
  effective_to?: string;
  priority: number;
  requires_approval: boolean;
}

// Rule type display labels for UI
export const RULE_TYPE_LABELS: Record<RuleType, string> = {
  percentage: 'Percentage Rate (on cash contributions)',
  fixed_amount: 'Fixed Amount per Event',
  tiered: 'Tiered Percentage (stepped rates)',
  hybrid: 'Hybrid (Fixed + Percentage)', 
  conditional: 'Conditional Rule',
  management_fee: 'Management-Fee Percentage',
  promote_share: 'Promote/Carry Share',
  credit_netting: 'Credits/Repurchase/Equalisation Netting',
  discount: 'Discount (Negative Commission)',
  sub_agent_split: 'Sub-Agent Split'
};