import type { Investor, PortfolioSummary, SnapshotResponse, NetView } from "./types";

const API_BASE = import.meta.env.VITE_API_BASE ?? "/api";

const handleResponse = async <T>(response: Response): Promise<T> => {
  if (!response.ok) {
    const body = await response.text();
    throw new Error(body || `Request failed with status ${response.status}`);
  }
  return response.json() as Promise<T>;
};

export const searchInvestors = async (query: string): Promise<Investor[]> => {
  const url = new URL(`${API_BASE}/investors/search`, window.location.origin);
  if (query) {
    url.searchParams.set("q", query);
  }
  const response = await fetch(url.toString().replace(window.location.origin, ""));
  const data = await handleResponse<{ results: Investor[] }>(response);
  return data.results;
};

export const fetchPortfolio = async (
  contactId: number,
  params: { from?: string; to?: string; baseCurrency?: string },
): Promise<PortfolioSummary> => {
  const url = new URL(`${API_BASE}/investors/${contactId}/portfolio`, window.location.origin);
  if (params.from) {
    url.searchParams.set("from", params.from);
  }
  if (params.to) {
    url.searchParams.set("to", params.to);
  }
  if (params.baseCurrency) {
    url.searchParams.set("base", params.baseCurrency);
  }
  const response = await fetch(url.toString().replace(window.location.origin, ""));
  return handleResponse<PortfolioSummary>(response);
};


export const fetchSnapshot = async (
  contactId: number,
  params: { from: string; to: string; base: string; lang?: string; preset?: string; netView: NetView },
  options?: { signal?: AbortSignal }
): Promise<{ data?: SnapshotResponse; etag?: string; notModified: boolean }> => {
  const url = new URL(`${API_BASE}/investor/${contactId}/snapshot`, window.location.origin);
  url.searchParams.set("from", params.from);
  url.searchParams.set("to", params.to);
  url.searchParams.set("base", params.base);
  if (params.lang) {
    url.searchParams.set("lang", params.lang);
  }
  if (params.preset) {
    url.searchParams.set("preset", params.preset);
  }
  url.searchParams.set("netView", params.netView);

  const response = await fetch(url.toString().replace(window.location.origin, ""), {
    signal: options?.signal,
  });

  if (response.status === 304) {
    return { notModified: true };
  }

  if (!response.ok) {
    const body = await response.text();
    throw new Error(body || `Request failed with status ${response.status}`);
  }

  const data = (await response.json()) as SnapshotResponse;
  return { data, etag: response.headers.get("ETag") ?? undefined, notModified: false };
};
