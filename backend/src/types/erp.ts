export interface Contact {
  contact_id: number;
  full_name: string;
  reporting_email?: string;
  updated_time?: string;
}

export interface AccountContactMap {
  contact_id: number;
  contact_name: string;
  account_id: number;
  account_name: string;
  fund_id: number | null;
  fund_name: string | null;
  relationship?: string;
  is_primary?: string;
  updated_time?: string;
}

export interface Commitment {
  fund_id: number;
  fundshortname?: string;
  account_id: number;
  account_name?: string;
  commitment_date?: string;
  commitment_amount: number;
  currency?: string;
}

export interface Cashflow {
  fund_id: number;
  fundshortname?: string;
  account_id: number;
  account_name?: string;
  transaction_date: string;
  pay_date?: string;
  transaction_amount: number;
  transaction_amount_usd?: number;
  transaction_type: string;
  transaction_subtype?: string;
  comments?: string;
  currency?: string;
}

export interface FinancialMetrics {
  [key: string]: unknown;
}

export interface FinancialRecord {
  fund_id: number;
  fund_name?: string;
  financialtype?: string;
  report_frequency?: string;
  report_date: string;
  financialMetrics: FinancialMetrics;
}

export interface Fund {
  fund_id: number;
  fundname?: string;
  shortname?: string;
  status?: string;
  currency?: string;
  market_value?: number | string;
  strategy?: string;
  sector?: string;
  region?: string;
  updated_time?: string;
}

export interface Asset {
  asset_id: number;
  asset_name?: string;
  asset_long_name?: string;
  fund_id?: number;
  fund_name?: string;
  sector?: string | number;
  sub_sector?: string | number;
  country?: string | number;
  region?: string | number;
}

