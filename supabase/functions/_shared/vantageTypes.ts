/**
 * Vantage IR API Type Definitions
 * Auto-generated from Swagger spec v1
 */

export interface VantageResponse<T> {
  code: number;
  message: string;
  data?: T;
}

export interface PagingDetails {
  page: number;
  per_page: number;
  has_more_page: boolean;
  total_available_Records: number;
}

// ============================================
// ACCOUNTS (Investors)
// ============================================

export interface VantageAccount {
  investor_id: number;
  investor_name: string;
  tax_id_type?: string;
  title?: string;
  investor_name_taxid_number?: string;
  tax_name?: string;
  tax_name_taxid_number?: string;
  us_tax_treatment?: string;
  short_name?: string;
  clientref_investor_id?: string;
  investor_type?: string;
  general_partner?: boolean;
  nasd?: boolean;
  erisa?: boolean;
  is_fund?: boolean;
  fund_id?: number;
  fund_name?: string;
  tax_type?: string;
  side_letter?: boolean;
  principal_place_of_business_blue_sky_state?: string;
  foia?: boolean;
  org_under_laws_of_state_of_inc?: string;
  director?: string;
  notes?: string;
  inherit_investor_series_across_all_funds?: boolean;
  investor_series?: string;
  w8_w9?: string;
  inactive?: boolean;
  copy_utility?: string;
  copy_id?: string;
  share_contribution_across_investor?: boolean;
  copy_org_docs?: string;
  accredited_investor_type?: string;
  declaration_date?: string;
  notes_on_accredited_status?: string;
  currency?: string;
  account_group?: Array<{ acctGroupId: number; groupName: string }>;
  contacts?: Array<{ contact_id: number; contact_name: string; contact_email: string }>;
  contact_id?: number;
  contact_name?: string;
  contact_email?: string;
  attention1?: string;
  attention2?: string;
  main_phone?: string;
  phone2?: string;
  address1?: string;
  address2?: string;
  address3?: string;
  main_fax?: string;
  fax2?: string;
  email?: string;
  city?: string;
  state?: string;
  zipcode?: string;
  country?: string;
  address_notes?: string;
  set_as_resident?: boolean;
  mailing_address?: boolean;
  updated_time: string;
  record_type: string;
}

export interface AccountsResponse extends VantageResponse<never> {
  accounts: VantageAccount[];
}

export interface AccountsResponseWithPaging extends AccountsResponse {
  page_context: PagingDetails;
}

// ============================================
// FUNDS
// ============================================

export interface VantageFund {
  fund_id: number;
  shortname: string;
  clientref_id?: string;
  fundname: string;
  exclude_from_financial_reports?: boolean;
  ismaster?: boolean;
  masterfundid?: number;
  isinvestment?: boolean;
  fundgroupid?: number;
  fundgroupname?: string;
  fund_type?: string;
  address?: string;
  city?: string;
  state?: string;
  zipcode?: string;
  country?: string;
  phone_number?: string;
  fax?: string;
  tax_id?: string;
  inception_date?: string;
  noofunits?: number;
  fund_size?: number;
  lpaandamendments?: string;
  capital_call_timing?: string;
  preferred_return?: string;
  management_fees?: string;
  carried_interest?: string;
  currency?: string;
  strategy?: string;
  notes?: string;
  exitdate?: string;
  status?: string;
  filenumber?: string;
  region?: string;
  sector?: string;
  risk_profile?: string;
  side_letters?: string;
  no_of_beds?: string;
  no_of_lots?: string;
  exit_fees_due_to?: string;
  sale_allowed_as_of?: string;
  annual_asset_mgmt_fee?: string;
  annual_administration_fee?: string;
  net_purchase_price?: string;
  project_cost?: string;
  total_equity?: string;
  total_capitalization?: string;
  sf?: string;
  year_built?: string;
  amortization_start_date?: string;
  partner_company?: string;
  property_management_company?: string;
  vacant_sf?: string;
  account_address?: string;
  is_fund_raising?: boolean;
  targeted_investor_IRR?: string;
  targeted_equity_multiple?: string;
  targeted_average_cash_yield?: string;
  targeted_investment_period?: string;
  minimum_investment?: string;
  irR_on_realized_investments?: string;
  equity_multiple?: string;
  cash_yield?: string;
  market_value?: string;
  company?: string;
  brief_description?: string;
  detailed_description?: string;
  sale_price?: string;
  quarterly_report_strategy?: string;
  current_investment_status?: string;
  updated_time: string;
  record_type: string;
}

export interface FundResponse extends VantageResponse<never> {
  funds: VantageFund[];
}

export interface FundResponseWithPaging extends FundResponse {
  page_context: PagingDetails;
}

// ============================================
// CASH FLOWS (Transactions)
// ============================================

export interface VantageCashFlow {
  fund_id: number;
  fundshortname: string;
  account_id: number;
  account_name: string;
  transaction_date: string;
  pay_date: string;
  transaction_amount: number;
  transaction_amount_usd: number;
  transaction_type: string;
  transaction_subtype?: string;
  comments?: string;
  updated_time: string;
  cashflow_detailid: number;
  record_type: string;
}

export interface CashFlowResponse extends VantageResponse<never> {
  cashFlows: VantageCashFlow[];
}

export interface CashFlowResponseWithPaging extends CashFlowResponse {
  page_context: PagingDetails;
}

// ============================================
// COMMITMENTS
// ============================================

export interface VantageCommitment {
  fund_id: number;
  fundshortname: string;
  account_id: number;
  account_name: string;
  commitment_date: string;
  commitment_amount: number;
  updated_time: string;
  record_type: string;
}

export interface CommitmentResponse extends VantageResponse<never> {
  commitments: VantageCommitment[];
}

export interface CommitmentResponseWithPaging extends CommitmentResponse {
  page_context: PagingDetails;
}

// ============================================
// CONTACTS
// ============================================

export interface VantageContact {
  contact_id: number;
  first_name?: string;
  last_name?: string;
  middle_name?: string;
  full_name: string;
  nick_name?: string;
  contact_type?: string;
  prefix?: string;
  first_name_hebrew?: string;
  surname_hebrew?: string;
  nick_name_hebrew?: string;
  reporting_email?: string;
  email2?: string;
  internal_contact?: string;
  company_id?: number;
  company_name?: string;
  title?: string;
  investor?: boolean;
  invested?: boolean;
  suffix?: string;
  nrf?: boolean;
  pe?: boolean;
  inactive?: boolean;
  consultant?: boolean;
  address_notes?: string;
  accredited_investor_type?: string;
  declaration_date?: string;
  notes_on_accredited_status?: string;
  preferred_language?: string;
  is_family_office?: string;
  family_office_name?: string;
  updated_time: string;
  record_type: string;
  abc_model?: string;
  investment_strategy_preference?: string;
  investment_sector_preference?: string;
  do_not_send?: string;
  source?: string;
  address?: Array<{
    address_type?: string;
    address?: string;
    attention?: string;
    main_phone?: string;
    phone2?: string;
    address1?: string;
    address2?: string;
    address3?: string;
    main_fax?: string;
    fax2?: string;
    city?: string;
    state?: string;
    zipcode?: string;
    country?: string;
    mobile?: string;
    set_as_default_address?: boolean;
    set_as_mail_2?: boolean;
    updated_time?: string;
  }>;
  createdDate?: string;
}

export interface ContactResponse extends VantageResponse<never> {
  contacts: VantageContact[];
}

export interface ContactResponseWithPaging extends ContactResponse {
  page_context: PagingDetails;
}

// ============================================
// ACCOUNT CONTACT MAP (Relationships)
// ============================================

export interface VantageAccountContactMap {
  contact_id: number;
  contact_name: string;
  account_id: number;
  account_name: string;
  fund_id: number;
  fund_name: string;
  is_primary?: string;
  relationship?: string;
  updated_time: string;
  record_type: string;
}

export interface AccountContactMapResponse extends VantageResponse<never> {
  mappings: VantageAccountContactMap[];
}

export interface AccountContactMapResponseWithPaging extends AccountContactMapResponse {
  page_context: PagingDetails;
}
