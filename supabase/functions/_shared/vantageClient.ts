/**
 * Vantage IR API Client
 * Handles authentication and data fetching from Vantage ERP
 */

import type {
  AccountsResponse,
  AccountsResponseWithPaging,
  FundResponse,
  FundResponseWithPaging,
  CashFlowResponse,
  CashFlowResponseWithPaging,
  CommitmentResponse,
  CommitmentResponseWithPaging,
  ContactResponse,
  ContactResponseWithPaging,
  AccountContactMapResponse,
  AccountContactMapResponseWithPaging,
} from './vantageTypes.ts';

export interface VantageClientConfig {
  baseUrl: string;
  authToken: string; // Raw token value (e.g., "buligodata")
  clientId: string; // X-com-vantageir-subscriptions-clientid header
}

export class VantageClient {
  private baseUrl: string;
  private authToken: string;
  private clientId: string;

  constructor(config: VantageClientConfig) {
    this.baseUrl = config.baseUrl.replace(/\/$/, ''); // Remove trailing slash
    this.authToken = config.authToken;
    this.clientId = config.clientId;
  }

  /**
   * Make authenticated request to Vantage API
   *
   * IMPORTANT: Vantage authentication requires:
   * - Authorization: <token> (NO Bearer prefix, just raw token)
   * - X-com-vantageir-subscriptions-clientid: <client-id>
   */
  private async request<T>(endpoint: string): Promise<T> {
    const url = `${this.baseUrl}${endpoint}`;

    // Vantage uses custom auth: raw token (NO Bearer prefix) + client ID header
    const headers: Record<string, string> = {
      'Authorization': this.authToken, // Raw token, NO Bearer prefix
      'X-com-vantageir-subscriptions-clientid': this.clientId,
      'Content-Type': 'application/json',
    };

    try {
      const response = await fetch(url, {
        method: 'GET',
        headers,
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(
          `Vantage API error (${response.status}): ${errorText || response.statusText}`
        );
      }

      const data = await response.json();

      // Check if Vantage returned an error code
      if (data.code !== 0) {
        throw new Error(`Vantage API returned error code ${data.code}: ${data.message}`);
      }

      return data as T;
    } catch (error) {
      if (error instanceof Error) {
        throw error;
      }
      throw new Error(`Failed to fetch from Vantage API: ${String(error)}`);
    }
  }

  // ============================================
  // ACCOUNTS (Investors)
  // ============================================

  async getAllAccounts(): Promise<AccountsResponse> {
    return this.request<AccountsResponse>('/api/Accounts/Get');
  }

  async getAccountById(accountId: number): Promise<AccountsResponse> {
    return this.request<AccountsResponse>(`/api/Accounts/Get/${accountId}`);
  }

  async getAccountsByPage(page: number, perPage: number): Promise<AccountsResponseWithPaging> {
    return this.request<AccountsResponseWithPaging>(`/api/Accounts/Get/${page}&${perPage}`);
  }

  /**
   * Get accounts updated since a specific date (incremental sync)
   * @param startDate Date in yyyyMMdd format (e.g., "20240101" for Jan 1, 2024)
   *                  IMPORTANT: Must be yyyyMMdd, NOT yyyy-MM-dd
   */
  async getAccountsByDate(
    startDate: string,
    page?: number,
    perPage?: number
  ): Promise<AccountsResponseWithPaging> {
    let endpoint = `/api/Accounts/GetbyDate/${startDate}`;
    const params = new URLSearchParams();
    if (page !== undefined) params.append('page', String(page));
    if (perPage !== undefined) params.append('per_page', String(perPage));
    if (params.toString()) endpoint += `?${params.toString()}`;
    return this.request<AccountsResponseWithPaging>(endpoint);
  }

  // ============================================
  // FUNDS
  // ============================================

  async getAllFunds(): Promise<FundResponse> {
    return this.request<FundResponse>('/api/Funds/Get');
  }

  async getFundById(fundId: number): Promise<FundResponse> {
    return this.request<FundResponse>(`/api/Funds/Get/${fundId}`);
  }

  async getFundsByPage(page: number, perPage: number): Promise<FundResponseWithPaging> {
    return this.request<FundResponseWithPaging>(`/api/Funds/Get/${page}&${perPage}`);
  }

  async getFundsByDate(
    startDate: string,
    page?: number,
    perPage?: number
  ): Promise<FundResponseWithPaging> {
    let endpoint = `/api/Funds/GetbyDate/${startDate}`;
    const params = new URLSearchParams();
    if (page !== undefined) params.append('page', String(page));
    if (perPage !== undefined) params.append('per_page', String(perPage));
    if (params.toString()) endpoint += `?${params.toString()}`;
    return this.request<FundResponseWithPaging>(endpoint);
  }

  // ============================================
  // CASH FLOWS (Transactions)
  // ============================================

  async getAllCashFlows(): Promise<CashFlowResponse> {
    return this.request<CashFlowResponse>('/api/CashFlows/Get');
  }

  async getCashFlowsByFund(fundId: number): Promise<CashFlowResponse> {
    return this.request<CashFlowResponse>(`/api/CashFlows/Get/${fundId}`);
  }

  async getCashFlowsByDateRange(startDate: string, endDate: string): Promise<CashFlowResponse> {
    return this.request<CashFlowResponse>(`/api/CashFlows/Get/${startDate}&${endDate}`);
  }

  async getCashFlowsByDate(
    startDate: string,
    page?: number,
    perPage?: number
  ): Promise<CashFlowResponseWithPaging> {
    let endpoint = `/api/CashFlows/GetbyDate/${startDate}`;
    const params = new URLSearchParams();
    if (page !== undefined) params.append('page', String(page));
    if (perPage !== undefined) params.append('per_page', String(perPage));
    if (params.toString()) endpoint += `?${params.toString()}`;
    return this.request<CashFlowResponseWithPaging>(endpoint);
  }

  // ============================================
  // COMMITMENTS
  // ============================================

  async getAllCommitments(): Promise<CommitmentResponse> {
    return this.request<CommitmentResponse>('/api/Commitment/Get');
  }

  async getCommitmentsByFund(fundId: number): Promise<CommitmentResponse> {
    return this.request<CommitmentResponse>(`/api/Commitment/Get/${fundId}`);
  }

  async getCommitmentsByDateRange(startDate: string, endDate: string): Promise<CommitmentResponse> {
    return this.request<CommitmentResponse>(`/api/Commitment/Get/${startDate}&${endDate}`);
  }

  async getCommitmentsByDate(
    startDate: string,
    page?: number,
    perPage?: number
  ): Promise<CommitmentResponseWithPaging> {
    let endpoint = `/api/Commitment/GetbyDate/${startDate}`;
    const params = new URLSearchParams();
    if (page !== undefined) params.append('page', String(page));
    if (perPage !== undefined) params.append('per_page', String(perPage));
    if (params.toString()) endpoint += `?${params.toString()}`;
    return this.request<CommitmentResponseWithPaging>(endpoint);
  }

  // ============================================
  // CONTACTS
  // ============================================

  async getAllContacts(): Promise<ContactResponse> {
    return this.request<ContactResponse>('/api/Contacts/Get');
  }

  async getContactById(contactId: number): Promise<ContactResponse> {
    return this.request<ContactResponse>(`/api/Contacts/Get/${contactId}`);
  }

  async getContactsByPage(page: number, perPage: number): Promise<ContactResponseWithPaging> {
    return this.request<ContactResponseWithPaging>(`/api/Contacts/Get/${page}&${perPage}`);
  }

  async getContactsByDate(
    startDate: string,
    page?: number,
    perPage?: number
  ): Promise<ContactResponseWithPaging> {
    let endpoint = `/api/Contacts/GetbyDate/${startDate}`;
    const params = new URLSearchParams();
    if (page !== undefined) params.append('page', String(page));
    if (perPage !== undefined) params.append('per_page', String(perPage));
    if (params.toString()) endpoint += `?${params.toString()}`;
    return this.request<ContactResponseWithPaging>(endpoint);
  }

  // ============================================
  // ACCOUNT CONTACT MAP (Relationships)
  // ============================================

  async getAllAccountContactMaps(): Promise<AccountContactMapResponse> {
    return this.request<AccountContactMapResponse>('/api/AccountContactMap/Get');
  }

  async getAccountContactMapByAccount(accountId: number): Promise<AccountContactMapResponse> {
    return this.request<AccountContactMapResponse>(`/api/AccountContactMap/Get/${accountId}`);
  }

  async getAccountContactMapsByPage(
    page: number,
    perPage: number
  ): Promise<AccountContactMapResponseWithPaging> {
    return this.request<AccountContactMapResponseWithPaging>(
      `/api/AccountContactMap/Get/${page}&${perPage}`
    );
  }

  async getAccountContactMapsByDate(
    startDate: string,
    page?: number,
    perPage?: number
  ): Promise<AccountContactMapResponseWithPaging> {
    let endpoint = `/api/AccountContactMap/GetbyDate/${startDate}`;
    const params = new URLSearchParams();
    if (page !== undefined) params.append('page', String(page));
    if (perPage !== undefined) params.append('per_page', String(perPage));
    if (params.toString()) endpoint += `?${params.toString()}`;
    return this.request<AccountContactMapResponseWithPaging>(endpoint);
  }

  // ============================================
  // HELPER: Fetch all pages
  // ============================================

  /**
   * Fetch all records from a paginated endpoint
   */
  async fetchAllPages<T extends { page_context?: { has_more_page: boolean } }>(
    fetchPage: (page: number, perPage: number) => Promise<T>,
    dataKey: keyof T,
    perPage: number = 100
  ): Promise<Array<any>> {
    const allData: Array<any> = [];
    let page = 1;
    let hasMore = true;

    while (hasMore) {
      const response = await fetchPage(page, perPage);
      const pageData = response[dataKey] as Array<any>;

      if (pageData && pageData.length > 0) {
        allData.push(...pageData);
      }

      hasMore = response.page_context?.has_more_page ?? false;
      page++;

      // Safety limit to prevent infinite loops
      if (page > 1000) {
        throw new Error('Exceeded maximum page limit (1000 pages)');
      }
    }

    return allData;
  }
}

/**
 * Create a Vantage client from environment variables
 *
 * Required environment variables:
 * - VANTAGE_API_BASE_URL: Base URL (e.g., https://buligoirapi.insightportal.info)
 * - VANTAGE_AUTH_TOKEN: Raw authorization token (e.g., "buligodata")
 * - VANTAGE_CLIENT_ID: Client ID for X-com-vantageir-subscriptions-clientid header
 */
export function createVantageClient(): VantageClient {
  const baseUrl = Deno.env.get('VANTAGE_API_BASE_URL');
  const authToken = Deno.env.get('VANTAGE_AUTH_TOKEN');
  const clientId = Deno.env.get('VANTAGE_CLIENT_ID');

  if (!baseUrl || !authToken || !clientId) {
    throw new Error(
      'Missing required Vantage API credentials. Set VANTAGE_API_BASE_URL, VANTAGE_AUTH_TOKEN, and VANTAGE_CLIENT_ID environment variables.'
    );
  }

  return new VantageClient({
    baseUrl,
    authToken,
    clientId,
  });
}
