/**
 * Vantage IR Data Mappers
 * Transform Vantage API data to internal database schema
 */

import type {
  VantageAccount,
  VantageFund,
} from './vantageTypes.ts';

// ============================================
// DATABASE INSERT TYPES
// ============================================

/**
 * Investor insert type matching actual database schema
 * Columns: id, name, external_id, currency, is_gp, notes, created_at, updated_at,
 *          introduced_by, introduced_by_party_id, source_kind, source_linked_at
 */
export interface InvestorInsert {
  name: string;
  external_id?: string | null;
  currency?: string | null;
  is_gp?: boolean | null;
  notes?: string | null;
  introduced_by?: string | null;
  introduced_by_party_id?: string | null;
  source_kind?: string | null;
  source_linked_at?: string | null;
}

/**
 * Fund/Deal insert type matching our database schema
 * Note: In our schema, Vantage "funds" map to "deals" table
 * Maps to deals table columns: name, fund_id, status, close_date, external_id
 */
export interface FundInsert {
  name: string;
  fund_id: string;
  status?: string | null;
  close_date?: string | null;
}

// ============================================
// VALIDATION TYPES
// ============================================

export interface ValidationError {
  field: string;
  message: string;
  code: string;
}

export interface ValidationResult {
  valid: boolean;
  errors: ValidationError[];
}

// ============================================
// ACCOUNT → INVESTOR MAPPING
// ============================================

/**
 * Map Vantage Account to Investor record
 *
 * Key mappings:
 * - investor_id → stored in metadata (for idempotency)
 * - investor_name → name
 * - email/contact_email → email
 * - main_phone → phone
 * - address1 → address
 * - city, state, zipcode, country → address components / country
 * - investor_name_taxid_number → tax_id
 * - currency → stored in metadata
 * - inactive → is_active (inverted)
 * - investor_type → investor_type
 * - general_partner → stored in metadata
 * - All extra Vantage fields → metadata JSONB
 *
 * @param account VantageAccount from Vantage IR API
 * @returns InvestorInsert object ready for database insertion
 */
export function mapVantageAccountToInvestor(
  account: VantageAccount
): InvestorInsert {
  // Build comprehensive notes with all contact info and metadata
  const notes = buildNotesFromAccount(account);

  return {
    name: account.investor_name?.trim() || 'Unknown Investor',
    external_id: String(account.investor_id),
    currency: account.currency?.trim()?.toUpperCase() || null,
    is_gp: account.general_partner || false,
    notes: notes,
    source_kind: 'vantage',
    source_linked_at: new Date().toISOString(),
    introduced_by: null,
    introduced_by_party_id: null,
  };
}

/**
 * Build comprehensive notes field from Vantage account data
 * Stores all contact info, address, and metadata since these columns don't exist in DB
 */
function buildNotesFromAccount(account: VantageAccount): string | null {
  const sections: string[] = [];

  // Contact Information
  const contactInfo: string[] = [];
  const email = normalizeEmail(account.email || account.contact_email);
  const phone = normalizePhone(account.main_phone);

  if (email) contactInfo.push(`Email: ${email}`);
  if (phone) contactInfo.push(`Phone: ${phone}`);
  if (account.country) contactInfo.push(`Country: ${account.country.trim()}`);
  if (account.investor_name_taxid_number) contactInfo.push(`Tax ID: ${account.investor_name_taxid_number.trim()}`);

  if (contactInfo.length > 0) {
    sections.push(`CONTACT:\n${contactInfo.join('\n')}`);
  }

  // Address
  const address = buildAddress(
    account.address1,
    account.address2,
    account.address3,
    account.city,
    account.state,
    account.zipcode
  );
  if (address) {
    sections.push(`ADDRESS:\n${address}`);
  }

  // Investor Details
  const details: string[] = [];
  if (account.investor_type) details.push(`Type: ${account.investor_type}`);
  if (account.short_name) details.push(`Short Name: ${account.short_name}`);
  if (account.inactive) details.push(`Status: Inactive`);

  if (details.length > 0) {
    sections.push(`DETAILS:\n${details.join('\n')}`);
  }

  // Original notes
  if (account.notes) {
    sections.push(`NOTES:\n${account.notes.trim()}`);
  }

  // Vantage Metadata
  const metadata: string[] = [];

  if (account.title) {
    metadata.push(`Title: ${account.title}`);
  }

  if (account.tax_type) {
    metadata.push(`Tax Type: ${account.tax_type}`);
  }

  if (account.us_tax_treatment) {
    metadata.push(`US Tax Treatment: ${account.us_tax_treatment}`);
  }

  if (account.accredited_investor_type) {
    metadata.push(`Accredited Type: ${account.accredited_investor_type}`);
  }

  if (account.general_partner) {
    metadata.push('General Partner: Yes');
  }

  if (account.erisa) {
    metadata.push('ERISA: Yes');
  }

  if (account.nasd) {
    metadata.push('NASD: Yes');
  }

  if (account.side_letter) {
    metadata.push('Side Letter: Yes');
  }

  if (account.currency && account.currency !== 'USD') {
    metadata.push(`Currency: ${account.currency}`);
  }

  if (metadata.length > 0) {
    sections.push(`METADATA:\nVantage ID: ${account.investor_id}\n${metadata.join('\n')}`);
  }

  return sections.length > 0 ? sections.join('\n\n---\n\n') : null;
}

/**
 * Build address string from components
 */
function buildAddress(
  address1?: string,
  address2?: string,
  address3?: string,
  city?: string,
  state?: string,
  zipcode?: string
): string | null {
  const parts: string[] = [];

  if (address1?.trim()) parts.push(address1.trim());
  if (address2?.trim()) parts.push(address2.trim());
  if (address3?.trim()) parts.push(address3.trim());

  const cityStateParts: string[] = [];
  if (city?.trim()) cityStateParts.push(city.trim());
  if (state?.trim()) cityStateParts.push(state.trim());
  if (zipcode?.trim()) cityStateParts.push(zipcode.trim());

  if (cityStateParts.length > 0) {
    parts.push(cityStateParts.join(', '));
  }

  return parts.length > 0 ? parts.join('\n') : null;
}

// ============================================
// FUND → DEAL MAPPING
// ============================================

/**
 * Map Vantage Fund to Deal record
 *
 * Note: In our system, Vantage "funds" are mapped to "deals" (properties/projects)
 *
 * Key mappings:
 * - fund_id → stored in metadata for idempotency
 * - fundname → name
 * - shortname → code
 * - inception_date → stored in metadata
 * - currency → stored in metadata
 * - status → is_active (normalized)
 * - All extra Vantage fields → metadata JSONB
 *
 * @param fund VantageFund from Vantage IR API
 * @param fundId Required foreign key to funds table (umbrella fund entity)
 * @returns FundInsert object ready for database insertion
 */
export function mapVantageFundToFund(
  fund: VantageFund,
  fundId: string
): FundInsert {
  // Normalize name
  const name = fund.fundname?.trim() || 'Unknown Fund';

  // Map Vantage status to deal status
  // Vantage uses: Active, Closed, Liquidated, etc.
  // Keep the original status value for the deals table
  const status = fund.status?.trim() || null;

  // Parse close date if available
  const closeDate = fund.exitdate ? parseVantageDateToISO(fund.exitdate) : null;

  return {
    name,
    fund_id: fundId,
    status,
    close_date: closeDate,
  };
}

/**
 * Build metadata JSONB object from Vantage fund data
 * Stores fields that don't fit in structured columns
 */
function buildFundMetadata(fund: VantageFund): Record<string, unknown> {
  const metadata: Record<string, unknown> = {
    // Store Vantage ID for idempotency
    vantage_fund_id: fund.fund_id,
  };

  // Basic fund info
  if (fund.currency) metadata.currency = fund.currency;
  if (fund.fund_type) metadata.vantage_fund_type = fund.fund_type;
  if (fund.clientref_id) metadata.vantage_client_ref_id = fund.clientref_id;

  // Strategy and classification
  if (fund.strategy) metadata.strategy = fund.strategy;
  if (fund.sector) metadata.sector = fund.sector;
  if (fund.region) metadata.region = fund.region;
  if (fund.risk_profile) metadata.risk_profile = fund.risk_profile;

  // Financial details
  if (fund.fund_size) metadata.fund_size = fund.fund_size;
  if (fund.noofunits) metadata.number_of_units = fund.noofunits;
  if (fund.net_purchase_price) metadata.net_purchase_price = fund.net_purchase_price;
  if (fund.project_cost) metadata.project_cost = fund.project_cost;
  if (fund.total_equity) metadata.total_equity = fund.total_equity;
  if (fund.total_capitalization) metadata.total_capitalization = fund.total_capitalization;
  if (fund.sale_price) metadata.sale_price = fund.sale_price;
  if (fund.market_value) metadata.market_value = fund.market_value;

  // Dates
  if (fund.inception_date) metadata.inception_date = fund.inception_date;
  if (fund.exitdate) metadata.exit_date = fund.exitdate;
  if (fund.amortization_start_date) metadata.amortization_start_date = fund.amortization_start_date;
  if (fund.sale_allowed_as_of) metadata.sale_allowed_as_of = fund.sale_allowed_as_of;

  // Property details
  if (fund.address) metadata.address = fund.address;
  if (fund.city) metadata.city = fund.city;
  if (fund.state) metadata.state = fund.state;
  if (fund.zipcode) metadata.zipcode = fund.zipcode;
  if (fund.country) metadata.country = fund.country;
  if (fund.year_built) metadata.year_built = fund.year_built;
  if (fund.sf) metadata.square_feet = fund.sf;
  if (fund.vacant_sf) metadata.vacant_square_feet = fund.vacant_sf;
  if (fund.no_of_beds) metadata.number_of_beds = fund.no_of_beds;
  if (fund.no_of_lots) metadata.number_of_lots = fund.no_of_lots;

  // Fee structure
  if (fund.management_fees) metadata.management_fees = fund.management_fees;
  if (fund.carried_interest) metadata.carried_interest = fund.carried_interest;
  if (fund.preferred_return) metadata.preferred_return = fund.preferred_return;
  if (fund.annual_asset_mgmt_fee) metadata.annual_asset_mgmt_fee = fund.annual_asset_mgmt_fee;
  if (fund.annual_administration_fee) metadata.annual_administration_fee = fund.annual_administration_fee;
  if (fund.exit_fees_due_to) metadata.exit_fees_due_to = fund.exit_fees_due_to;

  // Partners and companies
  if (fund.partner_company) metadata.partner_company = fund.partner_company;
  if (fund.property_management_company) metadata.property_management_company = fund.property_management_company;
  if (fund.company) metadata.company = fund.company;

  // Investment metrics
  if (fund.targeted_investor_IRR) metadata.targeted_investor_irr = fund.targeted_investor_IRR;
  if (fund.targeted_equity_multiple) metadata.targeted_equity_multiple = fund.targeted_equity_multiple;
  if (fund.targeted_average_cash_yield) metadata.targeted_average_cash_yield = fund.targeted_average_cash_yield;
  if (fund.targeted_investment_period) metadata.targeted_investment_period = fund.targeted_investment_period;
  if (fund.minimum_investment) metadata.minimum_investment = fund.minimum_investment;
  if (fund.irR_on_realized_investments) metadata.irr_on_realized_investments = fund.irR_on_realized_investments;
  if (fund.equity_multiple) metadata.equity_multiple = fund.equity_multiple;
  if (fund.cash_yield) metadata.cash_yield = fund.cash_yield;

  // Fund structure
  if (fund.ismaster !== undefined) metadata.is_master = fund.ismaster;
  if (fund.masterfundid) metadata.master_fund_id = fund.masterfundid;
  if (fund.isinvestment !== undefined) metadata.is_investment = fund.isinvestment;
  if (fund.fundgroupid) metadata.fund_group_id = fund.fundgroupid;
  if (fund.fundgroupname) metadata.fund_group_name = fund.fundgroupname;
  if (fund.is_fund_raising !== undefined) metadata.is_fund_raising = fund.is_fund_raising;

  // Documents and reporting
  if (fund.lpaandamendments) metadata.lpa_and_amendments = fund.lpaandamendments;
  if (fund.side_letters) metadata.side_letters = fund.side_letters;
  if (fund.brief_description) metadata.brief_description = fund.brief_description;
  if (fund.detailed_description) metadata.detailed_description = fund.detailed_description;
  if (fund.quarterly_report_strategy) metadata.quarterly_report_strategy = fund.quarterly_report_strategy;
  if (fund.current_investment_status) metadata.current_investment_status = fund.current_investment_status;

  // Configuration flags
  if (fund.exclude_from_financial_reports !== undefined) {
    metadata.exclude_from_financial_reports = fund.exclude_from_financial_reports;
  }

  // Additional fields
  if (fund.tax_id) metadata.tax_id = fund.tax_id;
  if (fund.phone_number) metadata.phone_number = fund.phone_number;
  if (fund.fax) metadata.fax = fund.fax;
  if (fund.filenumber) metadata.file_number = fund.filenumber;
  if (fund.notes) metadata.notes = fund.notes;
  if (fund.capital_call_timing) metadata.capital_call_timing = fund.capital_call_timing;
  if (fund.account_address) metadata.account_address = fund.account_address;

  // Status tracking
  if (fund.status) metadata.vantage_status = fund.status;
  if (fund.updated_time) metadata.vantage_updated_time = fund.updated_time;

  return metadata;
}

// ============================================
// VALIDATION FUNCTIONS
// ============================================

/**
 * Validate Vantage Account data before mapping to Investor
 * Returns validation result with any errors found
 *
 * @param account VantageAccount to validate
 * @returns ValidationResult with valid flag and array of errors
 */
export function validateInvestorData(account: VantageAccount): ValidationResult {
  const errors: ValidationError[] = [];

  // Required field: investor_id
  if (!account.investor_id) {
    errors.push({
      field: 'investor_id',
      message: 'Missing required field: investor_id',
      code: 'MISSING_REQUIRED_FIELD',
    });
  }

  // Required field: investor_name
  if (!account.investor_name || account.investor_name.trim() === '') {
    errors.push({
      field: 'investor_name',
      message: 'Missing or empty investor_name',
      code: 'MISSING_REQUIRED_FIELD',
    });
  }

  // Validate name length (database constraint)
  if (account.investor_name && account.investor_name.length > 500) {
    errors.push({
      field: 'investor_name',
      message: 'investor_name exceeds maximum length (500 characters)',
      code: 'FIELD_TOO_LONG',
    });
  }

  // Validate email format if provided
  if (account.email && !isValidEmail(account.email)) {
    errors.push({
      field: 'email',
      message: `Invalid email format: ${account.email}`,
      code: 'INVALID_EMAIL_FORMAT',
    });
  }

  if (account.contact_email && !isValidEmail(account.contact_email)) {
    errors.push({
      field: 'contact_email',
      message: `Invalid email format: ${account.contact_email}`,
      code: 'INVALID_EMAIL_FORMAT',
    });
  }

  // Validate currency code if provided
  if (account.currency && !isValidCurrency(account.currency)) {
    errors.push({
      field: 'currency',
      message: `Invalid currency code: ${account.currency}. Must be valid ISO 4217 code.`,
      code: 'INVALID_CURRENCY_CODE',
    });
  }

  // Validate phone format if provided
  if (account.main_phone && !isValidPhone(account.main_phone)) {
    errors.push({
      field: 'main_phone',
      message: `Invalid phone format: ${account.main_phone}`,
      code: 'INVALID_PHONE_FORMAT',
    });
  }

  return {
    valid: errors.length === 0,
    errors,
  };
}

/**
 * Validate Vantage Fund data before mapping to Deal
 * Returns validation result with any errors found
 *
 * @param fund VantageFund to validate
 * @returns ValidationResult with valid flag and array of errors
 */
export function validateFundData(fund: VantageFund): ValidationResult {
  const errors: ValidationError[] = [];

  // Required field: fund_id
  if (!fund.fund_id) {
    errors.push({
      field: 'fund_id',
      message: 'Missing required field: fund_id',
      code: 'MISSING_REQUIRED_FIELD',
    });
  }

  // Required field: fundname
  if (!fund.fundname || fund.fundname.trim() === '') {
    errors.push({
      field: 'fundname',
      message: 'Missing or empty fundname',
      code: 'MISSING_REQUIRED_FIELD',
    });
  }

  // Required field: shortname (used as code)
  if (!fund.shortname || fund.shortname.trim() === '') {
    errors.push({
      field: 'shortname',
      message: 'Missing or empty shortname (required for code)',
      code: 'MISSING_REQUIRED_FIELD',
    });
  }

  // Validate name length (database constraint)
  if (fund.fundname && fund.fundname.length > 500) {
    errors.push({
      field: 'fundname',
      message: 'fundname exceeds maximum length (500 characters)',
      code: 'FIELD_TOO_LONG',
    });
  }

  // Validate code length (database constraint)
  if (fund.shortname && fund.shortname.length > 100) {
    errors.push({
      field: 'shortname',
      message: 'shortname exceeds maximum length (100 characters)',
      code: 'FIELD_TOO_LONG',
    });
  }

  // Validate currency code if provided
  if (fund.currency && !isValidCurrency(fund.currency)) {
    errors.push({
      field: 'currency',
      message: `Invalid currency code: ${fund.currency}. Must be valid ISO 4217 code.`,
      code: 'INVALID_CURRENCY_CODE',
    });
  }

  // Validate dates if provided
  if (fund.inception_date && !isValidDate(fund.inception_date)) {
    errors.push({
      field: 'inception_date',
      message: `Invalid inception_date format: ${fund.inception_date}`,
      code: 'INVALID_DATE_FORMAT',
    });
  }

  if (fund.exitdate && !isValidDate(fund.exitdate)) {
    errors.push({
      field: 'exitdate',
      message: `Invalid exitdate format: ${fund.exitdate}`,
      code: 'INVALID_DATE_FORMAT',
    });
  }

  return {
    valid: errors.length === 0,
    errors,
  };
}

// ============================================
// HELPER FUNCTIONS
// ============================================

/**
 * Validate email format (RFC 5322 compliant)
 * Handles multi-email formats (e.g., "email1 / email2" or "email1,email2")
 */
function isValidEmail(email: string): boolean {
  if (!email || email.trim() === '') return false;

  // Check if it's a multi-email format (contains "/" or ",")
  // For these cases, validate the first email only
  let emailToValidate = email.trim();
  if (emailToValidate.includes('/')) {
    emailToValidate = emailToValidate.split('/')[0].trim();
  } else if (emailToValidate.includes(',')) {
    emailToValidate = emailToValidate.split(',')[0].trim();
  }

  // Basic RFC 5322 regex pattern
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(emailToValidate);
}

/**
 * Validate phone format (basic check - accepts various formats)
 * Accepts "_" as a placeholder for missing phone numbers
 */
function isValidPhone(phone: string): boolean {
  if (!phone || phone.trim() === '') return false;

  // Accept "_" as valid placeholder (will be normalized to null later)
  if (phone.trim() === '_') return true;

  // Allow digits, spaces, dashes, parentheses, plus sign
  // Must have at least 7 digits
  const cleanPhone = phone.replace(/[\s\-()]/g, '');
  const digitCount = cleanPhone.replace(/[^\d]/g, '').length;

  return digitCount >= 7 && digitCount <= 15;
}

/**
 * Validate ISO 4217 currency code
 */
function isValidCurrency(currency: string): boolean {
  if (!currency || currency.trim() === '') return false;

  // Common currency codes - extend as needed
  const validCurrencies = new Set([
    'USD', 'EUR', 'GBP', 'JPY', 'CNY', 'INR', 'CAD', 'AUD', 'CHF', 'SEK',
    'NZD', 'KRW', 'SGD', 'NOK', 'MXN', 'ZAR', 'HKD', 'BRL', 'DKK', 'PLN',
    'ILS', 'RUB', 'THB', 'IDR', 'MYR', 'PHP', 'CZK', 'AED', 'CLP', 'COP',
  ]);

  return validCurrencies.has(currency.toUpperCase().trim());
}

/**
 * Validate date format (accepts yyyyMMdd or yyyy-MM-dd)
 */
function isValidDate(dateString: string): boolean {
  if (!dateString || dateString.trim() === '') return false;

  // Try to parse the date
  const parsed = parseVantageDate(dateString);
  return parsed !== null;
}

/**
 * Normalize email address (lowercase, trim)
 * For multi-email formats (separated by "/" or ","), takes the first email
 */
function normalizeEmail(email?: string): string | null {
  if (!email || email.trim() === '') return null;

  let emailToNormalize = email.trim();

  // Handle multi-email formats - take the first email
  if (emailToNormalize.includes('/')) {
    emailToNormalize = emailToNormalize.split('/')[0].trim();
  } else if (emailToNormalize.includes(',')) {
    emailToNormalize = emailToNormalize.split(',')[0].trim();
  }

  return emailToNormalize.toLowerCase();
}

/**
 * Normalize phone number (remove extra spaces, standardize format)
 * Maps "_" placeholder to null
 */
function normalizePhone(phone?: string): string | null {
  if (!phone || phone.trim() === '') return null;

  // Map "_" placeholder to null (common in Vantage for missing phone numbers)
  if (phone.trim() === '_') return null;

  // Keep digits, spaces, dashes, parentheses, plus sign
  // Remove multiple spaces
  return phone.trim().replace(/\s+/g, ' ');
}

/**
 * Normalize investor type from Vantage to our schema
 */
function normalizeInvestorType(type?: string): string | null {
  if (!type || type.trim() === '') return null;

  const normalized = type.toUpperCase().trim();

  // Map Vantage types to our schema
  const typeMap: Record<string, string> = {
    'INDIVIDUAL': 'Individual',
    'ENTITY': 'Entity',
    'TRUST': 'Trust',
    'PARTNERSHIP': 'Partnership',
    'CORPORATION': 'Corporation',
    'LLC': 'LLC',
    'FUND': 'Fund',
    'RETIREMENT': 'Retirement Account',
    'IRA': 'IRA',
    '401K': '401(k)',
  };

  return typeMap[normalized] || type.trim();
}

/**
 * Normalize fund status from Vantage to is_active boolean
 */
function normalizeFundStatus(status?: string): boolean {
  if (!status) return true; // Default to active

  const normalized = status.toUpperCase().trim();

  // Inactive statuses
  const inactiveStatuses = new Set([
    'CLOSED',
    'LIQUIDATED',
    'EXITED',
    'INACTIVE',
    'TERMINATED',
    'DISSOLVED',
  ]);

  return !inactiveStatuses.has(normalized);
}

/**
 * Parse Vantage date string to Date
 * Supports multiple formats:
 * - ISO 8601 with timestamp: "2012-12-21T00:00:00"
 * - ISO 8601 date only: "2012-12-21"
 * - Vantage format: "20121221" (yyyyMMdd)
 */
export function parseVantageDate(dateString: string | undefined): Date | null {
  if (!dateString) return null;

  const trimmed = dateString.trim();

  // Try ISO 8601 formats first (with or without timestamp)
  // Format: 2012-12-21T00:00:00 or 2012-12-21
  if (trimmed.includes('-')) {
    const date = new Date(trimmed);
    if (!isNaN(date.getTime())) {
      return date;
    }
  }

  // Try Vantage yyyyMMdd format (8 digits, no separators)
  const digits = trimmed.replace(/\D/g, '');

  if (digits.length === 8) {
    const year = parseInt(digits.substring(0, 4), 10);
    const month = parseInt(digits.substring(4, 6), 10) - 1; // 0-indexed
    const day = parseInt(digits.substring(6, 8), 10);

    const date = new Date(year, month, day);

    // Validate date is valid
    if (!isNaN(date.getTime())) {
      return date;
    }
  }

  return null;
}

/**
 * Parse Vantage date string to ISO string (yyyy-MM-dd)
 */
function parseVantageDateToISO(dateString: string | undefined): string | null {
  const date = parseVantageDate(dateString);
  if (!date) return null;

  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');

  return `${year}-${month}-${day}`;
}

/**
 * Format date to yyyyMMdd format for Vantage API
 * IMPORTANT: Vantage requires yyyyMMdd format, NOT yyyy-MM-dd
 *
 * @param date Date object or ISO string
 * @returns Date in yyyyMMdd format (e.g., "20240101")
 */
export function formatDateForVantage(date: Date | string): string {
  const d = typeof date === 'string' ? new Date(date) : date;

  const year = d.getFullYear();
  const month = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');

  return `${year}${month}${day}`;
}
