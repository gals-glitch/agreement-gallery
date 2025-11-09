export interface TimeRange {
  from: string;
  to: string;
  baseCurrency: string;
}

export interface PerFundKpi {
  fundId: number;
  fundName?: string | null;
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

export interface PortfolioWarnings {
  unmappedCashflowTypes: string[];
}

export interface PortfolioInsights {
  cashflowIrr: number | null;
  irrExcludesUnrealized: boolean;
  recentActivity: {
    contributions90d: number;
    distributions90d: number;
    flows: Array<{
      date: string;
      fundId: number;
      fundName?: string | null;
      type: "contribution" | "distribution";
      amount: number;
    }>;
  };
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
  warnings: PortfolioWarnings;
  investmentsCount: number;
  insights: PortfolioInsights;
  lastSynced?: string;
}
