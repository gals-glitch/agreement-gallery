import { erpClient } from "../clients/erpClient";
import { clampRange, ensureIsoDate, yearKey } from "../utils/date";
import { normalizeCashflows } from "../utils/cashflow";
import { calculateFundKpis } from "./kpiService";
import { calculateXirr } from "../utils/irr";
import type { TimeRange, PortfolioSummary, PerFundKpi } from "../types/portfolio";
import type { Cashflow, FinancialRecord, Fund, Asset } from "../types/erp";
import { logger } from "../utils/logger";

const DEFAULT_BASE_CURRENCY = "USD";

const groupLatestFinancials = (financials: FinancialRecord[], to: string) => {
  const latestPerFund = new Map<number, FinancialRecord>();
  const limit = new Date(to).getTime();

  for (const record of financials) {
    const recordTime = new Date(record.report_date).getTime();
    if (Number.isNaN(recordTime) || recordTime > limit) {
      continue;
    }

    const current = latestPerFund.get(record.fund_id);
    if (!current || new Date(current.report_date).getTime() < recordTime) {
      latestPerFund.set(record.fund_id, record);
    }
  }

  return latestPerFund;
};

const sumBy = <T>(items: T[], selector: (item: T) => number | null | undefined) =>
  items.reduce((sum, item) => {
    const value = selector(item);
    return sum + (value ?? 0);
  }, 0);

const buildBreakdown = (
  metrics: PerFundKpi[],
  funds: Map<number, Fund>,
  assets: Asset[],
  selector: (fund: Fund | undefined, asset: Asset | undefined) => string,
) => {
  const breakdown: Record<
    string,
    { totalValue: number; contribution: number; distribution: number; positions: number }
  > = {};

  const assetsByFund = assets.reduce<Record<number, Asset[]>>((acc, asset) => {
    if (typeof asset.fund_id === "number") {
      const fundId = asset.fund_id;
      acc[fundId] = acc[fundId] ?? [];
      acc[fundId].push(asset);
    }
    return acc;
  }, {});

  for (const metric of metrics) {
    const fund = funds.get(metric.fundId);
    const fundLabel = selector(fund, undefined) || "Unspecified";
    const fundAssets = assetsByFund[metric.fundId] ?? [];
    const baseValue = metric.endingNav ?? metric.contributions;

    if (fundAssets.length === 0) {
      const bucket = breakdown[fundLabel] ?? {
        totalValue: 0,
        contribution: 0,
        distribution: 0,
        positions: 0,
      };
      bucket.totalValue += baseValue;
      bucket.contribution += metric.contributions;
      bucket.distribution += metric.distributions;
      bucket.positions += 1;
      breakdown[fundLabel] = bucket;
      continue;
    }

    for (const asset of fundAssets) {
      const label = selector(fund, asset) || "Unspecified";
      const bucket = breakdown[label] ?? {
        totalValue: 0,
        contribution: 0,
        distribution: 0,
        positions: 0,
      };
      bucket.totalValue += baseValue;
      bucket.contribution += metric.contributions;
      bucket.distribution += metric.distributions;
      bucket.positions += 1;
      breakdown[label] = bucket;
    }
  }

  return breakdown;
};

const withinRange = (date: string, from: string, to: string) => date >= from && date <= to;

export class PortfolioService {
  async searchInvestors(query: string) {
    const contacts = await erpClient.searchContacts(query);
    return contacts.map((contact) => ({
      id: contact.contact_id,
      name: contact.full_name,
      email: contact.reporting_email ?? "",
    }));
  }

  async getPortfolio(contactId: number, range: Partial<TimeRange>): Promise<PortfolioSummary> {
    const { from, to } = clampRange(
      ensureIsoDate(range.from ?? "2010-01-01"),
      ensureIsoDate(range.to ?? new Date().toISOString().slice(0, 10)),
    );
    const baseCurrency = range.baseCurrency ?? DEFAULT_BASE_CURRENCY;

    const contact = await erpClient.getContact(contactId);
    if (!contact) {
      throw new Error(`Contact ${contactId} not found`);
    }

    const mappings = await erpClient.getAccountContactMappings(contactId);
    const accountIds = [...new Set(mappings.map((map) => map.account_id))];

    const buildEmptySummary = (): PortfolioSummary => ({
      contactId,
      contactName: contact.full_name,
      timeRange: { from, to, baseCurrency },
      funds: [],
      totals: {
        contributions: 0,
        distributions: 0,
        endingNav: 0,
        profit: 0,
        tvpi: null,
        dpi: null,
        rvpi: null,
      },
      annualBuckets: {},
      sectorBreakdown: {},
      countryBreakdown: {},
      warnings: {
        unmappedCashflowTypes: [],
      },
      investmentsCount: 0,
      insights: {
        cashflowIrr: null,
        irrExcludesUnrealized: true,
        recentActivity: {
          contributions90d: 0,
          distributions90d: 0,
          flows: [],
        },
      },
      lastSynced: new Date().toISOString(),
    });

    if (accountIds.length === 0) {
      return buildEmptySummary();
    }

    const accountIdSet = new Set(accountIds);
    const fundIdSet = new Set<number>();
    for (const mapping of mappings) {
      if (typeof mapping.fund_id === "number") {
        fundIdSet.add(mapping.fund_id);
      }
    }

    const commitments = await erpClient.getCommitments();
    for (const commitment of commitments) {
      if (accountIdSet.has(commitment.account_id)) {
        fundIdSet.add(commitment.fund_id);
      }
    }

    const cashflows = await this.fetchCashflows({ accountIds, to });
    const { flows, warnings } = normalizeCashflows(cashflows);
    const flowsInRange = flows.filter((flow) => withinRange(flow.date, from, to));

    for (const flow of flows) {
      if (accountIds.includes(flow.accountId)) {
        fundIdSet.add(flow.fundId);
      }
    }

    const fundIds = [...fundIdSet];
    if (fundIds.length === 0) {
      return buildEmptySummary();
    }

    const [fundsList, assetsList] = await Promise.all([erpClient.getFunds(), erpClient.getAssets()]);
    const fundsById = new Map<number, Fund>();
    for (const fund of fundsList) {
      fundsById.set(fund.fund_id, fund);
    }

    const financials = await erpClient.getFinancials({
      startDate: "1900-01-01",
      endDate: to,
    });
    const latestFinancials = groupLatestFinancials(financials, to);

    const fundMetrics: PerFundKpi[] = fundIds.map((fundId) => {
      const fundAllFlows = flows.filter((flow) => flow.fundId === fundId && accountIds.includes(flow.accountId));
      const fundFlows = fundAllFlows.filter((flow) => withinRange(flow.date, from, to));
      const financial = latestFinancials.get(fundId);
      const fundInfo = fundsById.get(fundId);
      const closingNavFallback =
        typeof fundInfo?.market_value === "number"
          ? (fundInfo.market_value as number)
          : Number(fundInfo?.market_value ?? NaN);

      const kpis = calculateFundKpis({
        fundId,
        fundName: fundInfo?.fundname ?? fundInfo?.shortname ?? null,
        flows: fundFlows,
        financial,
        closingNavFallback: Number.isFinite(closingNavFallback) ? closingNavFallback : null,
        terminalDate: to,
      });

      const flowDates = fundAllFlows.map((flow) => flow.date).sort();
      const firstFlowDate = flowDates[0] ?? null;
      const lastFlowDate = flowDates.length > 0 ? flowDates[flowDates.length - 1] : null;
      const netCash = kpis.distributions - kpis.contributions;

      return {
        fundId,
        fundName: fundInfo?.fundname ?? fundInfo?.shortname ?? `Fund ${fundId}`,
        contributions: kpis.contributions,
        distributions: kpis.distributions,
        endingNav: kpis.endingNav,
        profit: kpis.profit,
        tvpi: kpis.tvpi,
        dpi: kpis.dpi,
        rvpi: kpis.rvpi,
        irr: kpis.irr,
        noiActual: kpis.noiActual,
        noiBudget: kpis.noiBudget,
        noiVariance: kpis.noiVariance,
        noiVariancePct: kpis.noiVariancePct,
        currency: fundInfo?.currency ?? baseCurrency,
        firstFlowDate,
        lastFlowDate,
        netCash,
      };
    });

    const totals = {
      contributions: sumBy(fundMetrics, (metric) => metric.contributions),
      distributions: sumBy(fundMetrics, (metric) => metric.distributions),
      endingNav: sumBy(fundMetrics, (metric) => metric.endingNav),
      profit: sumBy(fundMetrics, (metric) => metric.profit),
      tvpi: null as number | null,
      dpi: null as number | null,
      rvpi: null as number | null,
    };

    const totalContrib = totals.contributions;
    if (totalContrib > 0) {
      totals.tvpi = (totals.endingNav + totals.distributions) / totalContrib;
      totals.dpi = totals.distributions / totalContrib;
      totals.rvpi = totals.endingNav / totalContrib;
    }

    const annualBuckets: PortfolioSummary["annualBuckets"] = {};
    for (const flow of flowsInRange) {
      const bucket = annualBuckets[yearKey(flow.date)] ?? {
        contributions: 0,
        distributions: 0,
        netCash: 0,
      };
      if (flow.type === "contribution") {
        bucket.contributions += Math.abs(flow.amount);
        bucket.netCash -= Math.abs(flow.amount);
      } else if (flow.type === "distribution") {
        bucket.distributions += flow.amount;
        bucket.netCash += flow.amount;
      }
      annualBuckets[yearKey(flow.date)] = bucket;
    }

    const sectorBreakdown = buildBreakdown(
      fundMetrics,
      fundsById,
      assetsList,
      (fund, asset) =>
        (asset?.sector as string) || (fund?.sector as string) || (fund?.strategy as string) || "Unspecified",
    );

    const countryBreakdown = buildBreakdown(
      fundMetrics,
      fundsById,
      assetsList,
      (fund, asset) => (asset?.country as string) || (fund?.region as string) || "Unspecified",
    );

    logger.debug("Portfolio summary computed", {
      contactId,
      fundCount: fundMetrics.length,
      warnings: warnings.unmappedTypes,
    });

    return {
      contactId,
      contactName: contact.full_name,
      timeRange: { from, to, baseCurrency },
      funds: fundMetrics,
      totals: {
        contributions: totals.contributions,
        distributions: totals.distributions,
        endingNav: totals.endingNav,
        profit: totals.profit,
        tvpi: totals.tvpi,
        dpi: totals.dpi,
        rvpi: totals.rvpi,
      },
      annualBuckets,
      sectorBreakdown,
      countryBreakdown,
      warnings: {
        unmappedCashflowTypes: warnings.unmappedTypes,
      },
      investmentsCount: fundMetrics.length,
      insights: this.buildInsights({
        flows,
        flowsInRange,
        fundsById,
        accountIds,
        from,
        to,
      }),
      lastSynced: new Date().toISOString(),
    };
  }

  private async fetchCashflows(params: { accountIds: number[]; to: string }): Promise<Cashflow[]> {
    const flows = await erpClient.getCashflows({
      startDate: "1900-01-01",
      endDate: params.to,
    });

    return flows.filter((flow) => params.accountIds.includes(flow.account_id));
  }

  private buildInsights({
    flows,
    flowsInRange,
    fundsById,
    accountIds,
    from,
    to,
  }: {
    flows: ReturnType<typeof normalizeCashflows>["flows"];
    flowsInRange: ReturnType<typeof normalizeCashflows>["flows"];
    fundsById: Map<number, Fund>;
    accountIds: number[];
    from: string;
    to: string;
  }) {
    const cashflowPoints = flowsInRange
      .filter((flow) => flow.type !== "other")
      .map((flow) => ({
        date: flow.date,
        amount: flow.amount,
      }))
      .sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());

    const cashflowIrr = calculateXirr(cashflowPoints);

    const ninetyDaysAgo = new Date(to);
    ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90);
    const ninetyIso = ninetyDaysAgo.toISOString().slice(0, 10);
    const recentStart = ninetyIso > from ? ninetyIso : from;

    const recentFlows = flows
      .filter(
        (flow) =>
          flow.type !== "other" &&
          accountIds.includes(flow.accountId) &&
          flow.date >= recentStart &&
          flow.date <= to,
      )
      .sort((a, b) => b.date.localeCompare(a.date));

    const contributions90d = recentFlows
      .filter((flow) => flow.type === "contribution")
      .reduce((sum, flow) => sum + Math.abs(flow.amount), 0);

    const distributions90d = recentFlows
      .filter((flow) => flow.type === "distribution")
      .reduce((sum, flow) => sum + flow.amount, 0);

    const latestFlows = recentFlows.slice(0, 3).map((flow) => {
      const flowType: "contribution" | "distribution" = flow.type === "distribution" ? "distribution" : "contribution";
      return {
        date: flow.date,
        fundId: flow.fundId,
        fundName: fundsById.get(flow.fundId)?.fundname ?? fundsById.get(flow.fundId)?.shortname ?? `Fund ${flow.fundId}`,
        type: flowType,
        amount: flowType === "contribution" ? -Math.abs(flow.amount) : flow.amount,
      };
    });

    return {
      cashflowIrr,
      irrExcludesUnrealized: true,
      recentActivity: {
        contributions90d,
        distributions90d,
        flows: latestFlows,
      },
    };
  }
}

export const portfolioService = new PortfolioService();

