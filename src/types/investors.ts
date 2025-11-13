/**
 * Investor Source Linker Types
 * Ticket: FE-101, FE-102, FE-103
 * Date: 2025-10-19
 */

// ============================================
// ENUMS
// ============================================

export type InvestorSourceKind = 'DISTRIBUTOR' | 'REFERRER' | 'NONE' | 'vantage';

export const INVESTOR_SOURCE_KIND_VALUES: InvestorSourceKind[] = [
  'DISTRIBUTOR',
  'REFERRER',
  'NONE',
  'vantage',
];

export const INVESTOR_SOURCE_KIND_LABELS: Record<InvestorSourceKind, string> = {
  DISTRIBUTOR: 'Distributor',
  REFERRER: 'Referrer',
  NONE: 'None',
  vantage: 'Vantage IR',
};

// ============================================
// TYPES
// ============================================

export interface InvestorSourceFields {
  source_kind: InvestorSourceKind;
  introduced_by_party_id: string | null;
  source_linked_at: string | null;
}

export interface InvestorWithSource {
  id: string;
  name: string;
  email: string | null;
  phone: string | null;
  address: string | null;
  country: string | null;
  tax_id: string | null;
  investor_type: string | null;
  kyc_status: string | null;
  risk_profile: string | null;
  investment_capacity: number | null;
  is_active: boolean;
  notes: string | null;
  party_entity_id: string;
  created_at: string;
  updated_at: string;
  created_by: string | null;

  // Source fields
  source_kind: InvestorSourceKind;
  introduced_by_party_id: string | null;
  source_linked_at: string | null;

  // Joined data
  introduced_by_party?: {
    id: string;
    name: string;
    party_type: string;
  } | null;
}

export interface InvestorListFilters {
  source_kind?: InvestorSourceKind | 'ALL';
  introduced_by_party_id?: string;
  has_source?: boolean;
  limit?: number;
  offset?: number;
}

export interface InvestorListResponse {
  items: InvestorWithSource[];
  total: number;
}

// ============================================
// CSV IMPORT TYPES
// ============================================

export interface InvestorSourceImportRow {
  investor_external_id: string;
  source_kind: InvestorSourceKind;
  party_name?: string;
}

export interface InvestorSourceImportError {
  row: number;
  field?: string;
  message: string;
  value?: any;
}

export interface InvestorSourceImportResponse {
  success_count: number;
  errors: InvestorSourceImportError[];
}

export interface InvestorSourceImportPreviewRow extends InvestorSourceImportRow {
  status: 'valid' | 'warning' | 'error';
  error_message?: string;
  investor_id?: string;
  party_id?: string;
}

// ============================================
// FORM TYPES
// ============================================

export interface InvestorSourceFormData {
  source_kind: InvestorSourceKind;
  introduced_by_party_id: string | null;
}

export interface InvestorFormData extends InvestorSourceFormData {
  name: string;
  party_entity_id: string;
  email?: string;
  phone?: string;
  address?: string;
  country?: string;
  tax_id?: string;
  investor_type?: string;
  kyc_status?: string;
  risk_profile?: string;
  investment_capacity?: number;
  is_active?: boolean;
  notes?: string;
}

// ============================================
// API REQUEST/RESPONSE TYPES
// ============================================

export interface CreateInvestorRequest extends InvestorFormData {}

export interface UpdateInvestorRequest extends Partial<InvestorFormData> {}

export interface GetInvestorResponse extends InvestorWithSource {}

export interface GetInvestorsRequest extends InvestorListFilters {}

export interface GetInvestorsResponse extends InvestorListResponse {}
