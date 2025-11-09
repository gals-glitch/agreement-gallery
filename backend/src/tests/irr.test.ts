import { calculateXirr } from "../utils/irr";

describe("calculateXirr", () => {
  it("returns null when insufficient cashflows", () => {
    expect(calculateXirr([])).toBeNull();
  });

  it("computes IRR for simple case", () => {
    const irr = calculateXirr([
      { date: "2023-01-01", amount: -100000 },
      { date: "2024-01-01", amount: 120000 },
    ]);
    expect(irr).not.toBeNull();
    if (irr != null) {
      expect(irr).toBeGreaterThan(0.18);
      expect(irr).toBeLessThan(0.23);
    }
  });
});

