import axios, { AxiosInstance } from "axios";
import NodeCache from "node-cache";
import { config } from "../config/env";
import { logger } from "../utils/logger";
import type {
  AccountContactMap,
  Asset,
  Cashflow,
  Commitment,
  Contact,
  FinancialRecord,
  Fund,
} from "../types/erp";
import { loadMockData } from "../mocks/sampleData";

interface PageContext {
  page: number;
  per_page: number;
  has_more_page: boolean;
  total_available_Records?: number;
}

interface PagedResponse<T> {
  page_context?: PageContext;
  [key: string]: unknown;
  data?: T[];
}

type EndpointResult<T> = {
  items: T[];
  pageContext?: PageContext;
};

const DEFAULT_START_DATE = "19000101";

const formatDateParam = (value: string) => value.replace(/-/g, "");

export class ERPClient {
  private readonly http: AxiosInstance | null;
  private readonly cache: NodeCache;
  private readonly mock = config.useMocks;
  private readonly mockData = loadMockData();

  constructor() {
    this.cache = new NodeCache({ stdTTL: config.cacheTtlSeconds });

    if (!this.mock && !config.erpBaseUrl) {
      logger.warn("ERP_BASE_URL missing – falling back to mock mode");
      this.mock = true;
    }

    if (this.mock) {
      this.http = null;
      return;
    }

    this.http = axios.create({
      baseURL: config.erpBaseUrl,
      timeout: config.erpTimeoutMs,
    });

    this.http.interceptors.request.use((request) => {
      if (config.erpApiKey) {
        request.headers.Authorization = config.erpApiKey;
      }
      if (config.erpClientId) {
        request.headers["X-com-vantageir-subscriptions-clientid"] = config.erpClientId;
      }
      return request;
    });
  }

  private buildCacheKey(path: string, params?: Record<string, unknown>) {
    return `${path}:${JSON.stringify(params ?? {})}`;
  }

  private async get<T>(path: string, params?: Record<string, unknown>, cacheKey?: string): Promise<T> {
    if (this.mock) {
      throw new Error("Direct get call not supported in mock mode");
    }
    if (!this.http) {
      throw new Error("ERP client not initialized");
    }

    const key = cacheKey ?? this.buildCacheKey(path, params);
    const cached = this.cache.get<T>(key);
    if (cached) {
      return cached;
    }

    try {
      const response = await this.http.get<T>(path, { params });
      this.cache.set(key, response.data);
      return response.data;
    } catch (error) {
      logger.error("ERP client request failed", { path, params, error });
      throw error;
    }
  }

  private async fetchPaged<T>(options: {
    path: string;
    responseKey: string;
    params?: Record<string, unknown>;
    startPage?: number;
    maxPages?: number;
  }): Promise<EndpointResult<T>> {
    if (this.mock) {
      const key = options.responseKey as keyof typeof this.mockData;
      const items = Array.isArray(this.mockData[key]) ? (this.mockData[key] as T[]) : [];
      return { items };
    }

    const { path, responseKey } = options;
    const params = { ...(options.params ?? {}) };
    let page = options.startPage ?? 1;
    const perPage = Number(params.per_page ?? 200);
    params.per_page = perPage;

    const allItems: T[] = [];
    let pageContext: PageContext | undefined;
    const maxPages = options.maxPages ?? 50;

    while (page <= maxPages) {
      params.page = page;
      const data = await this.get<PagedResponse<T>>(path, params);

      const items = (data[responseKey] as T[]) ?? [];
      allItems.push(...items);

      pageContext = data.page_context as PageContext | undefined;
      if (!pageContext?.has_more_page) {
        break;
      }
      page += 1;
    }

    return { items: allItems, pageContext };
  }

  async searchContacts(query: string): Promise<Contact[]> {
    if (this.mock) {
      const lc = query.toLowerCase();
      return this.mockData.contacts.filter((contact) =>
        [contact.full_name, contact.reporting_email].filter(Boolean).some((field) => field!.toLowerCase().includes(lc)),
      );
    }

    const { items } = await this.fetchPaged<Contact>({
      path: `/api/Contacts/GetbyDate/${DEFAULT_START_DATE}`,
      responseKey: "contacts",
    });

    if (!query) {
      return items.slice(0, 50);
    }

    const lcQuery = query.toLowerCase();
    return items
      .filter((contact) => {
        const haystack = `${contact.full_name ?? ""} ${contact.reporting_email ?? ""}`.toLowerCase();
        return haystack.includes(lcQuery);
      })
      .slice(0, 50);
  }

  async getContact(contactId: number): Promise<Contact | null> {
    if (this.mock) {
      return this.mockData.contacts.find((contact) => contact.contact_id === contactId) ?? null;
    }

    const response = await this.get<{ contacts: Contact[] }>(`/api/Contacts/Get/${contactId}`);
    return response?.contacts?.[0] ?? null;
  }

  async getAccountContactMappings(contactId?: number): Promise<AccountContactMap[]> {
    if (this.mock) {
      const mappings = this.mockData.accountMappings;
      return contactId ? mappings.filter((map) => map.contact_id === contactId) : mappings;
    }

    const { items } = await this.fetchPaged<AccountContactMap>({
      path: "/api/AccountContactMap/Get",
      responseKey: "mappings",
    });

    return contactId ? items.filter((map) => map.contact_id === contactId) : items;
  }

  async getCommitments(params?: { fundId?: number; startDate?: string; endDate?: string }): Promise<Commitment[]> {
    if (this.mock) {
      const all = this.mockData.commitments;
      return all.filter((commitment) => {
        if (params?.fundId && commitment.fund_id !== params.fundId) {
          return false;
        }
        return true;
      });
    }

    const startDate = params?.startDate ? formatDateParam(params.startDate) : DEFAULT_START_DATE;

    const { items } = await this.fetchPaged<Commitment>({
      path: `/api/Commitment/GetbyDate/${startDate}`,
      responseKey: "commitments",
      params: {
        page: 1,
        per_page: 500,
      },
    });

    return params?.fundId ? items.filter((item) => item.fund_id === params.fundId) : items;
  }

  async getCashflows(params: { startDate: string; endDate: string; fundId?: number }): Promise<Cashflow[]> {
    if (this.mock) {
      return this.mockData.cashflows.filter((flow) => {
        if (params.fundId && flow.fund_id !== params.fundId) {
          return false;
        }
        const date = flow.transaction_date;
        return date >= params.startDate && date <= params.endDate;
      });
    }

    if (params.fundId) {
      const response = await this.get<{ cashFlows: Cashflow[] }>(`/api/CashFlows/Get/${params.fundId}`);
      return response.cashFlows ?? [];
    }

    const start = formatDateParam(params.startDate);
    const end = formatDateParam(params.endDate);

    const response = await this.get<{ cashFlows: Cashflow[] }>(
      `/api/CashFlows/Get/${start}&${end}`,
    );

    return response.cashFlows ?? [];
  }

  async getFinancials(params: { fundId?: number; startDate: string; endDate: string; reportFrequency?: string }) {
    if (this.mock) {
      return this.mockData.financials.filter((record) => {
        if (params.fundId && record.fund_id !== params.fundId) {
          return false;
        }
        return record.report_date >= params.startDate && record.report_date <= params.endDate;
      });
    }

    const response = await this.get<{ financials: FinancialRecord[] }>("/api/Financials/Get", {
      fund_id: params.fundId,
      startdate: formatDateParam(params.startDate),
      enddate: formatDateParam(params.endDate),
      report_frequency: params.reportFrequency ?? "Quarterly",
    });

    return response.financials ?? [];
  }

  async getFunds(): Promise<Fund[]> {
    if (this.mock) {
      return this.mockData.funds;
    }

    const { items } = await this.fetchPaged<Fund>({
      path: "/api/Funds/Get",
      responseKey: "funds",
    });
    return items;
  }

  async getAssets(): Promise<Asset[]> {
    if (this.mock) {
      return this.mockData.assets;
    }

    const { items } = await this.fetchPaged<Asset>({
      path: "/api/Assets/Get",
      responseKey: "assets",
    });
    return items;
  }
}

export const erpClient = new ERPClient();
