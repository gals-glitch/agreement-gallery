/**
 * API Client V2 - Redesigned System
 * Base URL: /api/v1
 * Date: 2025-10-16
 * Updated: 2025-10-16 - Migrated to new http wrapper
 */

import { http, buildQueryString } from './http';
import type {
  // Parties
  Party,
  CreatePartyRequest,
  PartiesListResponse,
  PartiesQueryParams,
  // Funds
  Fund,
  CreateFundRequest,
  FundsListResponse,
  // Deals
  Deal,
  CreateDealRequest,
  UpdateDealRequest,
  DealsListResponse,
  // Fund Tracks
  FundTrack,
  // Agreements
  Agreement,
  CreateAgreementRequest,
  AgreementsListResponse,
  AgreementsQueryParams,
  AgreementActionResponse,
  AmendAgreementResponse,
  // Runs
  Run,
  CreateRunRequest,
  RunsListResponse,
  RunsQueryParams,
  RunGenerateResponse,
  RunActionRequest,
  RunActionResponse,
  //Common
  APIError,
} from '@/types/api';

// ============================================
// PARTIES API
// ============================================
export const partiesAPI = {
  list: async (params: PartiesQueryParams = {}): Promise<PartiesListResponse> => {
    const query = buildQueryString(params);
    return http.get<PartiesListResponse>(`/parties${query}`);
  },

  create: async (data: CreatePartyRequest): Promise<{ id: number }> => {
    return http.post<{ id: number }>('/parties', data);
  },

  get: async (id: number): Promise<Party> => {
    return http.get<Party>(`/parties/${id}`);
  },

  update: async (id: number, data: Partial<CreatePartyRequest>): Promise<{ ok: boolean }> => {
    return http.patch<{ ok: boolean }>(`/parties/${id}`, data);
  },
};

// ============================================
// FUNDS API
// ============================================
export const fundsAPI = {
  list: async (): Promise<FundsListResponse> => {
    return http.get<FundsListResponse>('/funds');
  },

  create: async (data: CreateFundRequest): Promise<{ id: number }> => {
    return http.post<{ id: number }>('/funds', data);
  },

  get: async (id: number): Promise<Fund> => {
    return http.get<Fund>(`/funds/${id}`);
  },
};

// ============================================
// DEALS API
// ============================================
export const dealsAPI = {
  list: async (): Promise<DealsListResponse> => {
    return http.get<DealsListResponse>('/deals');
  },

  create: async (data: CreateDealRequest): Promise<{ id: number }> => {
    return http.post<{ id: number }>('/deals', data);
  },

  get: async (id: number): Promise<Deal> => {
    return http.get<Deal>(`/deals/${id}`);
  },

  update: async (id: number, data: UpdateDealRequest): Promise<{ ok: boolean }> => {
    return http.patch<{ ok: boolean }>(`/deals/${id}`, data);
  },
};

// ============================================
// FUND TRACKS API (read-only)
// ============================================
export const fundTracksAPI = {
  list: async (fundId: number): Promise<FundTrack[]> => {
    return http.get<FundTrack[]>(`/fund-tracks?fund_id=${fundId}`);
  },

  get: async (fundId: number, trackCode: 'A' | 'B' | 'C'): Promise<FundTrack> => {
    return http.get<FundTrack>(`/fund-tracks/${fundId}/${trackCode}`);
  },
};

// ============================================
// AGREEMENTS API
// ============================================
export const agreementsAPI = {
  list: async (params: AgreementsQueryParams = {}): Promise<AgreementsListResponse> => {
    const query = buildQueryString(params);
    return http.get<AgreementsListResponse>(`/agreements${query}`);
  },

  create: async (data: CreateAgreementRequest): Promise<{ id: number }> => {
    return http.post<{ id: number }>('/agreements', data);
  },

  get: async (id: number): Promise<Agreement> => {
    return http.get<Agreement>(`/agreements/${id}`);
  },

  submit: async (id: number): Promise<AgreementActionResponse> => {
    return http.post<AgreementActionResponse>(`/agreements/${id}/submit`);
  },

  approve: async (id: number): Promise<AgreementActionResponse> => {
    return http.post<AgreementActionResponse>(`/agreements/${id}/approve`);
  },

  reject: async (id: number, comment: string): Promise<AgreementActionResponse> => {
    return http.post<AgreementActionResponse>(`/agreements/${id}/reject`, { comment });
  },

  amend: async (id: number): Promise<AmendAgreementResponse> => {
    return http.post<AmendAgreementResponse>(`/agreements/${id}/amend`);
  },
};

// ============================================
// RUNS API
// ============================================
export const runsAPI = {
  list: async (params: RunsQueryParams = {}): Promise<RunsListResponse> => {
    const query = buildQueryString(params);
    return http.get<RunsListResponse>(`/runs${query}`);
  },

  create: async (data: CreateRunRequest): Promise<{ id: number; status: string }> => {
    return http.post<{ id: number; status: string }>('/runs', data);
  },

  get: async (id: number): Promise<Run> => {
    return http.get<Run>(`/runs/${id}`);
  },

  submit: async (id: number): Promise<RunActionResponse> => {
    return http.post<RunActionResponse>(`/runs/${id}/submit`);
  },

  approve: async (id: number, request?: RunActionRequest): Promise<RunActionResponse> => {
    return http.post<RunActionResponse>(`/runs/${id}/approve`, request || {});
  },

  reject: async (id: number, comment: string): Promise<RunActionResponse> => {
    return http.post<RunActionResponse>(`/runs/${id}/reject`, { comment });
  },

  generate: async (id: number): Promise<RunGenerateResponse> => {
    return http.post<RunGenerateResponse>(`/runs/${id}/generate`);
  },
};

// ============================================
// CONTRIBUTIONS API (imported from separate file)
// ============================================
export { contributionsAPI } from './contributions';

// ============================================
// EXPORTS
// ============================================
export default {
  parties: partiesAPI,
  funds: fundsAPI,
  deals: dealsAPI,
  fundTracks: fundTracksAPI,
  agreements: agreementsAPI,
  runs: runsAPI,
};
