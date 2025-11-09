import { createHash } from "crypto";

import { config } from "../config/env";
import { cacheProvider } from "../infrastructure/cache";
import { portfolioService } from "./portfolioService";
import { erpClient } from "../clients/erpClient";

export interface SnapshotParams {
  from: string;
  to: string;
  base: string;
  lang?: string;
  preset?: string;
  netView: "invested" | "toInvestor";
}

export interface SnapshotResponse {
  investor: {
    id: number;
    name: string;
    email: string;
  };
  totals: {
    contributionsUsd: number;
    distributionsUsd: number;
    netInvestedUsd: number;
    netToInvestorUsd: number;
  };
  holdings: {
    count: number;
    activeInRangeCount: number;
  };
  recent90d: {
    inUsd: number;
    outUsd: number;
    flows: Array<{
      date: string;
      entityType: "fund";
      entityId: number;
      entityName: string;
      amountUsd: number;
    }>;
  };
  insights: {
    cashflowIrr: number | null;
    irrExcludesUnrealized: boolean;
  };
  exportContext: {
    preset?: string;
    base: string;
    netView: "invested" | "toInvestor";
  };
  dataNotes: string[];
}

const buildCacheKey = (investorId: number, params: SnapshotParams) =>
  [
    "snapshot",
    `v${config.snapshotCacheVersion}`,
    investorId,
    params.from,
    params.to,
    params.base,
    params.lang ?? "default",
  ].join(":");

const computeEtag = (payload: SnapshotResponse) =>
  createHash("sha256").update(JSON.stringify(payload)).digest("hex");

export class SnapshotService {
  async getSnapshot(investorId: number, params: SnapshotParams): Promise<{ payload: SnapshotResponse; etag: string }> {
    const cacheKey = buildCacheKey(investorId, params);
    const cached = await cacheProvider.get<SnapshotResponse>(cacheKey);
    if (cached) {
      return { payload: cached.value, etag: cached.etag };
    }

    const portfolio = await portfolioService.getPortfolio(investorId, {
      from: params.from,
      to: params.to,
      baseCurrency: params.base,
    });

    const contact = await erpClient.getContact(investorId);

    const contributions = portfolio.totals.contributions ?? 0;
    const distributions = portfolio.totals.distributions ?? 0;
    const netInvested = contributions - distributions;
    const netToInvestor = distributions - contributions;
    const holdingsCount = portfolio.funds.length;
    const activeHoldings = portfolio.funds.filter(
      (fund) => Math.abs(fund.contributions ?? 0) > 0 || Math.abs(fund.distributions ?? 0) > 0,
    ).length;

    const recent = portfolio.insights?.recentActivity;
    const recentFlows = recent?.flows ?? [];

    const payload: SnapshotResponse = {
      investor: {
        id: investorId,
        name: contact?.full_name ?? portfolio.contactName ?? "",
        email: contact?.reporting_email ?? "",
      },
      totals: {
        contributionsUsd: contributions,
        distributionsUsd: distributions,
        netInvestedUsd: netInvested,
        netToInvestorUsd: netToInvestor,
      },
      holdings: {
        count: holdingsCount,
        activeInRangeCount: activeHoldings,
      },
      recent90d: {
        inUsd: recent?.contributions90d ?? 0,
        outUsd: recent?.distributions90d ?? 0,
        flows: recentFlows.map((flow) => ({
          date: flow.date,
          entityType: "fund" as const,
          entityId: flow.fundId,
          entityName: flow.fundName ?? `Fund ${flow.fundId}`,
          amountUsd: flow.amount,
        })),
      },
      insights: {
        cashflowIrr: portfolio.insights?.cashflowIrr ?? null,
        irrExcludesUnrealized: true,
      },
      exportContext: {
        preset: params.preset,
        base: params.base,
        netView: params.netView,
      },
      dataNotes: [],
    };

    if (payload.insights.cashflowIrr == null) {
      payload.dataNotes.push("Cash-flow IRR unavailable for this range.");
    }

    const etag = computeEtag(payload);
    await cacheProvider.set(cacheKey, payload, etag, config.snapshotCacheTtlSeconds);

    return { payload, etag };
  }
}

export const snapshotService = new SnapshotService();
