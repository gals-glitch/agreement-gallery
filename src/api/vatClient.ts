/**
 * VAT API Client
 * Ticket: API-310
 * Date: 2025-10-19
 *
 * Client functions for VAT rates API endpoints
 */

import { supabase } from '@/integrations/supabase/client';
import type {
  VatRate,
  CreateVatRateRequest,
  UpdateVatRateRequest,
  VatRateResponse,
  VatRatesListResponse,
  VatRatesFilters,
} from '@/types/vat';

const API_BASE = '/api-v1';

// ============================================
// HELPER: Get Auth Headers
// ============================================
async function getAuthHeaders(): Promise<Record<string, string>> {
  const { data: { session } } = await supabase.auth.getSession();

  if (!session) {
    throw new Error('No active session');
  }

  return {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${session.access_token}`,
  };
}

// ============================================
// HELPER: Fetch with Auth
// ============================================
async function fetchWithAuth(
  endpoint: string,
  options: RequestInit = {}
): Promise<Response> {
  const headers = await getAuthHeaders();

  const response = await fetch(endpoint, {
    ...options,
    headers: {
      ...headers,
      ...options.headers,
    },
  });

  return response;
}

// ============================================
// CREATE VAT RATE
// ============================================
export async function createVatRate(
  payload: CreateVatRateRequest
): Promise<VatRate> {
  const response = await fetchWithAuth(`${API_BASE}/vat-rates`, {
    method: 'POST',
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.message || 'Failed to create VAT rate');
  }

  const data: VatRateResponse = await response.json();
  return data.vat_rate;
}

// ============================================
// LIST VAT RATES
// ============================================
export async function listVatRates(
  filters?: VatRatesFilters
): Promise<VatRate[]> {
  const params = new URLSearchParams();

  if (filters?.country_code) {
    params.append('country_code', filters.country_code);
  }

  if (filters?.active !== undefined) {
    params.append('active', filters.active.toString());
  }

  if (filters?.effective_on) {
    params.append('effective_on', filters.effective_on);
  }

  const queryString = params.toString();
  const url = queryString
    ? `${API_BASE}/vat-rates?${queryString}`
    : `${API_BASE}/vat-rates`;

  const response = await fetchWithAuth(url);

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.message || 'Failed to fetch VAT rates');
  }

  const data: VatRatesListResponse = await response.json();
  return data.vat_rates;
}

// ============================================
// GET CURRENT VAT RATE
// ============================================
export async function getCurrentVatRate(
  countryCode: string
): Promise<VatRate | null> {
  const params = new URLSearchParams({ country_code: countryCode });
  const url = `${API_BASE}/vat-rates/current?${params.toString()}`;

  const response = await fetchWithAuth(url);

  if (response.status === 404) {
    return null;
  }

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.message || 'Failed to fetch current VAT rate');
  }

  const data: VatRateResponse = await response.json();
  return data.vat_rate;
}

// ============================================
// GET VAT RATE BY ID
// ============================================
export async function getVatRate(id: string): Promise<VatRate> {
  const response = await fetchWithAuth(`${API_BASE}/vat-rates/${id}`);

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.message || 'Failed to fetch VAT rate');
  }

  const data: VatRateResponse = await response.json();
  return data.vat_rate;
}

// ============================================
// UPDATE VAT RATE
// ============================================
export async function updateVatRate(
  id: string,
  payload: UpdateVatRateRequest
): Promise<VatRate> {
  const response = await fetchWithAuth(`${API_BASE}/vat-rates/${id}`, {
    method: 'PATCH',
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.message || 'Failed to update VAT rate');
  }

  const data: VatRateResponse = await response.json();
  return data.vat_rate;
}

// ============================================
// DELETE VAT RATE
// ============================================
export async function deleteVatRate(id: string): Promise<void> {
  const response = await fetchWithAuth(`${API_BASE}/vat-rates/${id}`, {
    method: 'DELETE',
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.message || 'Failed to delete VAT rate');
  }
}

// ============================================
// CLOSE VAT RATE (Convenience Method)
// ============================================
export async function closeVatRate(
  id: string,
  effectiveTo: string
): Promise<VatRate> {
  return updateVatRate(id, { effective_to: effectiveTo });
}
