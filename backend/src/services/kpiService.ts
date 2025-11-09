import type { FinancialRecord } from "../types/erp";
import type { NormalizedFlow } from "../utils/cashflow";
import { calculateXirr, type CashflowPoint } from "../utils/irr";

const navKeys = ["nav", "market_value", "marketValue", "ending_nav", "endingNav"];
const noiActualKeys = ["noi_actual", "noiActual"];
const noiBudgetKeys = ["noi_budget", "noiBudget", "noi_plan"];

const coerceNumber = (value: unknown): number | null => {
  if (value == null) {
    return null;
  }
  if (typeof value === "number") {
    return Number.isFinite(value) ? value : null;
  }
  if (typeof value === "string") {
    const normalized = value.replace(/[$,%\s]/g, "");
    const number = Number(normalized);
    return Number.isFinite(number) ? number : null;
  }
  return null;
};

export const extractNav = (financial: FinancialRecord | undefined): number | null => {
  if (!financial) {
    return null;
  }

  for (const key of navKeys) {
    const value = coerceNumber(financial.financialMetrics?.[key]);
    if (value != null) {
      return value;
    }
  }

  const marketValue = coerceNumber(financial.financialMetrics?.market_value);
  if (marketValue != null) {
    return marketValue;
  }

  return null;
};

export const extractNoi = (financial: FinancialRecord | undefined) => {
  if (!financial) {
    return {
      actual: null,
      budget: null,
    };
  }

  let actual: number | null = null;
  for (const key of noiActualKeys) {
    const value = coerceNumber(financial.financialMetrics?.[key]);
    if (value != null) {
      actual = value;
      break;
    }
  }

  let budget: number | null = null;
  for (const key of noiBudgetKeys) {
    const value = coerceNumber(financial.financialMetrics?.[key]);
    if (value != null) {
      budget = value;
      break;
    }
  }

  const variance = actual != null && budget != null ? actual - budget : null;
  const variancePct =
    actual != null && budget != null && budget !== 0 ? ((actual - budget) / Math.abs(budget)) * 100 : null;

  return {
    actual,
    budget,
    variance,
    variancePct,
  };
};

export interface FundKpiInput {
  fundId: number;
  fundName?: string | null;
  flows: NormalizedFlow[];
  financial?: FinancialRecord;
  valuationDate?: string;
  closingNavFallback?: number | null;
  terminalDate: string;
}

export const calculateFundKpis = (input: FundKpiInput) => {
  const { flows, financial, terminalDate } = input;

  const contributions = flows
    .filter((flow) => flow.type === "contribution")
    .reduce((sum, flow) => sum + flow.amount, 0);

  const distributions = flows
    .filter((flow) => flow.type === "distribution")
    .reduce((sum, flow) => sum + flow.amount, 0);

  const endingNav = extractNav(financial) ?? input.closingNavFallback ?? null;
  const totalContributions = Math.abs(contributions);
  const totalDistributions = distributions;
  const profit = endingNav != null ? totalDistributions + endingNav - totalContributions : null;

  const tvpi =
    endingNav != null && totalContributions > 0 ? (endingNav + totalDistributions) / totalContributions : null;
  const dpi = totalContributions > 0 ? totalDistributions / totalContributions : null;
  const rvpi = totalContributions > 0 && endingNav != null ? endingNav / totalContributions : null;

  const cashflowPoints: CashflowPoint[] = flows
    .filter((flow) => flow.type !== "other")
    .map((flow) => ({
      date: flow.date,
      amount: flow.amount,
    }));

  if (endingNav != null) {
    cashflowPoints.push({
      date: terminalDate,
      amount: endingNav,
    });
  }

  const irr = calculateXirr(
    cashflowPoints.sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime()),
  );

  const { actual: noiActual, budget: noiBudget, variance: noiVariance, variancePct: noiVariancePct } = extractNoi(
    financial,
  );

  return {
    contributions: totalContributions,
    distributions: totalDistributions,
    endingNav,
    profit,
    tvpi,
    dpi,
    rvpi,
    irr,
    noiActual,
    noiBudget,
    noiVariance,
    noiVariancePct,
  };
};

