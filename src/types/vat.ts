/**
 * VAT Types and Interfaces
 * Ticket: FE-501
 * Date: 2025-10-19
 *
 * Type definitions for VAT rates and snapshots
 */

// ============================================
// VAT RATE TYPES
// ============================================
export interface VatRate {
  id: string;
  country_code: string;
  rate_percentage: number;
  effective_from: string; // ISO date
  effective_to: string | null; // ISO date or null
  description: string | null;
  created_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface CreateVatRateRequest {
  country_code: string;
  rate_percentage: number;
  effective_from: string; // ISO date (YYYY-MM-DD)
  effective_to?: string | null;
  description?: string;
}

export interface UpdateVatRateRequest {
  effective_to?: string | null;
}

// ============================================
// API RESPONSE TYPES
// ============================================
export interface VatRateResponse {
  vat_rate: VatRate;
}

export interface VatRatesListResponse {
  vat_rates: VatRate[];
}

// ============================================
// AGREEMENT SNAPSHOT EXTENSIONS
// ============================================
export interface AgreementRateSnapshot {
  agreement_id: string;
  scope: string;
  pricing_mode: string;
  track_code: string | null;
  resolved_upfront_bps: number;
  resolved_deferred_bps: number;
  vat_included: boolean;
  effective_from: string;
  effective_to: string | null;
  seed_version: number | null;
  approved_at: string;

  // VAT fields
  vat_rate_percent: number | null;
  vat_policy: string | null;
  snapshotted_at: string | null;

  // Extended fields (JSONB)
  tiers: any | null;
  caps: any | null;
  discounts: any | null;
}

// ============================================
// QUERY PARAMETERS
// ============================================
export interface VatRatesFilters {
  country_code?: string;
  active?: boolean;
  effective_on?: string; // ISO date
}

// ============================================
// UI STATE TYPES
// ============================================
export interface VatRateFormState {
  country_code: string;
  rate_percentage: string; // String for form input
  effective_from: string;
  effective_to: string;
  description: string;
}

export interface VatRateCategory {
  title: string;
  rates: VatRate[];
  emptyMessage: string;
}

// ============================================
// CONSTANTS
// ============================================
export const VAT_POLICIES = {
  INCLUSIVE: 'INCLUSIVE',
  EXCLUSIVE: 'EXCLUSIVE',
  BEFORE_DISCOUNT: 'BEFORE_DISCOUNT',
  AFTER_DISCOUNT: 'AFTER_DISCOUNT',
} as const;

export type VatPolicy = typeof VAT_POLICIES[keyof typeof VAT_POLICIES];

// ============================================
// COUNTRY CODES
// ============================================
export const COMMON_COUNTRIES = [
  { code: 'GB', name: 'United Kingdom', flag: '🇬🇧' },
  { code: 'US', name: 'United States', flag: '🇺🇸' },
  { code: 'DE', name: 'Germany', flag: '🇩🇪' },
  { code: 'FR', name: 'France', flag: '🇫🇷' },
  { code: 'IT', name: 'Italy', flag: '🇮🇹' },
  { code: 'ES', name: 'Spain', flag: '🇪🇸' },
  { code: 'NL', name: 'Netherlands', flag: '🇳🇱' },
  { code: 'BE', name: 'Belgium', flag: '🇧🇪' },
  { code: 'CH', name: 'Switzerland', flag: '🇨🇭' },
  { code: 'AT', name: 'Austria', flag: '🇦🇹' },
  { code: 'IE', name: 'Ireland', flag: '🇮🇪' },
  { code: 'SE', name: 'Sweden', flag: '🇸🇪' },
  { code: 'DK', name: 'Denmark', flag: '🇩🇰' },
  { code: 'FI', name: 'Finland', flag: '🇫🇮' },
  { code: 'NO', name: 'Norway', flag: '🇳🇴' },
  { code: 'PL', name: 'Poland', flag: '🇵🇱' },
  { code: 'PT', name: 'Portugal', flag: '🇵🇹' },
  { code: 'GR', name: 'Greece', flag: '🇬🇷' },
  { code: 'CZ', name: 'Czech Republic', flag: '🇨🇿' },
  { code: 'HU', name: 'Hungary', flag: '🇭🇺' },
  { code: 'LU', name: 'Luxembourg', flag: '🇱🇺' },
] as const;

// ============================================
// HELPER FUNCTIONS
// ============================================
export function getCountryName(code: string): string {
  const country = COMMON_COUNTRIES.find(c => c.code === code);
  return country?.name || code;
}

export function getCountryFlag(code: string): string {
  const country = COMMON_COUNTRIES.find(c => c.code === code);
  return country?.flag || '';
}

export function isCurrentRate(rate: VatRate): boolean {
  const today = new Date().toISOString().split('T')[0];
  return (
    rate.effective_from <= today &&
    (rate.effective_to === null || rate.effective_to > today)
  );
}

export function isHistoricalRate(rate: VatRate): boolean {
  const today = new Date().toISOString().split('T')[0];
  return rate.effective_to !== null && rate.effective_to <= today;
}

export function isScheduledRate(rate: VatRate): boolean {
  const today = new Date().toISOString().split('T')[0];
  return rate.effective_from > today;
}

export function formatDate(date: string | null): string {
  if (!date) return 'Current';
  return new Date(date).toLocaleDateString('en-GB', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });
}

export function formatPercentage(value: number | null): string {
  if (value === null || value === undefined) return 'N/A';
  return `${value.toFixed(2)}%`;
}
