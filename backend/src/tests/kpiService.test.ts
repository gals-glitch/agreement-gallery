import { calculateFundKpis } from "../services/kpiService";

describe("calculateFundKpis", () => {
  it("calculates metrics with contributions and distributions", () => {
    const metrics = calculateFundKpis({
      fundId: 101,
      flows: [
        { fundId: 101, accountId: 1, date: "2023-01-01", amount: -100000, type: "contribution", originalType: "contribution" },
        { fundId: 101, accountId: 1, date: "2024-01-01", amount: 10000, type: "distribution", originalType: "distribution" },
      ],
      terminalDate: "2024-12-31",
      closingNavFallback: 120000,
    });

    expect(metrics.contributions).toBe(100000);
    expect(metrics.distributions).toBe(10000);
    expect(metrics.endingNav).toBe(120000);
    expect(metrics.tvpi).toBeCloseTo(1.3, 1);
    expect(metrics.dpi).toBeCloseTo(0.1, 1);
    expect(metrics.rvpi).toBeCloseTo(1.2, 1);
  });
});

