import type { Cashflow } from "../types/erp";

const CONTRIBUTION_TYPES = new Set([
  "contribution",
  "capital_call",
  "capital call",
  "capital contribution",
  "capital contribution (commitment)",
]);

const DISTRIBUTION_TYPES = new Set([
  "distribution",
  "dividend",
  "return_of_capital",
  "return of capital",
  "roc",
  "interest_distribution",
  "interest distribution",
]);

export type NormalizedFlow = {
  fundId: number;
  accountId: number;
  date: string;
  amount: number;
  type: "contribution" | "distribution" | "other";
  originalType: string;
};

export type FlowWarnings = {
  unmappedTypes: string[];
};

export const normalizeCashflows = (cashflows: Cashflow[]): { flows: NormalizedFlow[]; warnings: FlowWarnings } => {
  const unmappedTypes = new Set<string>();

  const flows = cashflows.map<NormalizedFlow>((flow) => {
    const amount = flow.transaction_amount_usd ?? flow.transaction_amount;
    const typeKey = (flow.transaction_type ?? "").toLowerCase();

    if (CONTRIBUTION_TYPES.has(typeKey)) {
      const normalizedAmount = amount < 0 ? amount : -Math.abs(amount);
      return {
        fundId: flow.fund_id,
        accountId: flow.account_id,
        date: flow.transaction_date,
        amount: normalizedAmount,
        type: "contribution",
        originalType: typeKey,
      };
    }

    if (DISTRIBUTION_TYPES.has(typeKey)) {
      const normalizedAmount = amount > 0 ? amount : Math.abs(amount);
      return {
        fundId: flow.fund_id,
        accountId: flow.account_id,
        date: flow.transaction_date,
        amount: normalizedAmount,
        type: "distribution",
        originalType: typeKey,
      };
    }

    unmappedTypes.add(typeKey || "unknown");

    return {
      fundId: flow.fund_id,
      accountId: flow.account_id,
      date: flow.transaction_date,
      amount,
      type: "other",
      originalType: typeKey,
    };
  });

  return {
    flows,
    warnings: {
      unmappedTypes: Array.from(unmappedTypes.values()),
    },
  };
};

