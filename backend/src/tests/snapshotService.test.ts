import { snapshotService } from "../services/snapshotService";
import { cacheProvider } from "../infrastructure/cache";
import { config } from "../config/env";

const mockPortfolioService = {
  getPortfolio: jest.fn(),
};

const mockErpClient = {
  getContact: jest.fn(),
};

jest.mock("../services/portfolioService", () => ({
  portfolioService: mockPortfolioService,
}));

jest.mock("../clients/erpClient", () => ({
  erpClient: mockErpClient,
}));

describe("snapshotService", () => {
  const params = {
    from: "2020-01-01",
    to: "2025-01-01",
    base: "USD",
    netView: "invested" as const,
  };

  const key = `snapshot:v${config.snapshotCacheVersion}:1:${params.from}:${params.to}:${params.base}:default`;

  beforeEach(async () => {
    mockPortfolioService.getPortfolio.mockReset();
    mockErpClient.getContact.mockReset();
    await cacheProvider.del(key);
  });

  it("computes snapshot totals and holdings", async () => {
    mockPortfolioService.getPortfolio.mockResolvedValue({
      contactName: "Test Investor",
      timeRange: { from: params.from, to: params.to, baseCurrency: params.base },
      funds: [
        { contributions: 100, distributions: 20 },
        { contributions: 0, distributions: 0 },
      ],
      totals: {
        contributions: 100,
        distributions: 20,
        endingNav: 0,
        profit: 0,
        tvpi: null,
        dpi: null,
        rvpi: null,
      },
      annualBuckets: {},
      sectorBreakdown: {},
      countryBreakdown: {},
      warnings: { unmappedCashflowTypes: [] },
      investmentsCount: 2,
      insights: {
        cashflowIrr: 0.12,
        irrExcludesUnrealized: true,
        recentActivity: {
          contributions90d: 50,
          distributions90d: 10,
          flows: [
            { date: "2024-12-01", fundId: 10, fundName: "Fund 10", type: "contribution", amount: -5000 },
          ],
        },
      },
      contactId: 1,
    });

    mockErpClient.getContact.mockResolvedValue({
      contact_id: 1,
      full_name: "Test Investor",
      reporting_email: "test@example.com",
    });

    const result = await snapshotService.getSnapshot(1, params);

    expect(result.payload.totals.netInvestedUsd).toBe(80);
    expect(result.payload.holdings.count).toBe(2);
    expect(result.payload.holdings.activeInRangeCount).toBe(1);
    expect(result.payload.recent90d.flows).toHaveLength(1);
  });

  it("returns cached payload on subsequent calls", async () => {
    mockPortfolioService.getPortfolio.mockResolvedValue({
      contactName: "Test Investor",
      timeRange: { from: params.from, to: params.to, baseCurrency: params.base },
      funds: [],
      totals: { contributions: 0, distributions: 0, endingNav: 0, profit: 0, tvpi: null, dpi: null, rvpi: null },
      annualBuckets: {},
      sectorBreakdown: {},
      countryBreakdown: {},
      warnings: { unmappedCashflowTypes: [] },
      investmentsCount: 0,
      insights: {
        cashflowIrr: null,
        irrExcludesUnrealized: true,
        recentActivity: { contributions90d: 0, distributions90d: 0, flows: [] },
      },
      contactId: 1,
    });

    mockErpClient.getContact.mockResolvedValue({ contact_id: 1, full_name: "Test Investor", reporting_email: "" });

    await snapshotService.getSnapshot(1, params);
    await snapshotService.getSnapshot(1, params);

    expect(mockPortfolioService.getPortfolio).toHaveBeenCalledTimes(1);
  });
});
