/**
 * Simplified types for Fund VI MVP
 */

export type VatMode = 'included' | 'added';
export type TrackKey = 'A' | 'B' | 'C';

export interface FundVITrack {
  track_key: TrackKey;
  min_raised: number;
  max_raised: number | null;
  upfront_rate_bps: number;
  deferred_rate_bps: number;
  deferred_offset_months: number;
  config_version: string;
}

export interface Contribution {
  id: string;
  investor_id: string;
  investor_name: string;
  fund_name: string;
  distribution_amount: number;
  distribution_date: string;
}

export interface Agreement {
  id: string;
  investor_id: string;
  fund_id: string;
  track_key: TrackKey;
  vat_mode: VatMode;
}

export interface Credit {
  id: string;
  investor_id: string;
  fund_name: string;
  remaining_balance: number;
  date_posted: string;
}

export interface FeeLine {
  contribution_id: string;
  investor_name: string;
  fund_name: string;
  track_key: TrackKey;
  line_type: 'upfront' | 'deferred';
  base_amount: number;
  rate_bps: number;
  fee_gross: number;
  vat_amount: number;
  fee_net: number;
  credits_applied: number;
  total_payable: number;
  payment_date: string;
  notes?: string;
}

export interface CalculationInput {
  run_id: string;
  contributions: Contribution[];
  config_version: string;
}

export interface CalculationOutput {
  run_id: string;
  config_version: string;
  fee_lines: FeeLine[];
  total_gross: number;
  total_vat: number;
  total_net: number;
  total_credits: number;
  total_payable: number;
}
