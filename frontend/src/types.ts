export type NetView = "invested" | "toInvestor";

export interface Investor {
  id: number;
  name: string;
  email: string;
}

export interface TimeRange {
  from: string;
  to: string;
  baseCurrency: string;
}

export interface PerFundKpi {
  fundId: number;
  fundName?: string;
  contributions: number;
  distributions: number;
  endingNav?: number | null;
  profit?: number | null;
  tvpi?: number | null;
  dpi?: number | null;
  rvpi?: number | null;
  irr?: number | null;
  noiActual?: number | null;
  noiBudget?: number | null;
  noiVariance?: number | null;
  noiVariancePct?: number | null;
  currency?: string | null;
  firstFlowDate?: string | null;
  lastFlowDate?: string | null;
  netCash?: number | null;
}

export interface PortfolioSummary {
  contactId: number;
  contactName?: string;
  timeRange: TimeRange;
  funds: PerFundKpi[];
  totals: {
    contributions: number;
    distributions: number;
    endingNav: number;
    profit: number;
    tvpi: number | null;
    dpi: number | null;
    rvpi: number | null;
  };
  annualBuckets: Record<
    string,
    {
      contributions: number;
      distributions: number;
      netCash: number;
    }
  >;
  sectorBreakdown: Record<
    string,
    {
      totalValue: number;
      contribution: number;
      distribution: number;
      positions: number;
    }
  >;
  countryBreakdown: Record<
    string,
    {
      totalValue: number;
      contribution: number;
      distribution: number;
      positions: number;
    }
  >;
  warnings: {
    unmappedCashflowTypes: string[];
  };
  investmentsCount: number;
  insights: {
    cashflowIrr: number | null;
    irrExcludesUnrealized: boolean;
    recentActivity: {
      contributions90d: number;
      distributions90d: number;
      flows: Array<{
        date: string;
        fundId: number;
        fundName?: string;
        type: "contribution" | "distribution";
        amount: number;
      }>;
    };
  };
  lastSynced?: string;
  deltas?: {
    netCash?: number | null;
    investments?: number | null;
  };
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
    netView: NetView;
  };
  dataNotes: string[];
}
