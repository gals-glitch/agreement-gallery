export interface CashflowPoint {
  date: string;
  amount: number;
}

const MAX_ITERATIONS = 100;
const TOLERANCE = 1e-6;
const MIN_RATE = -0.9999;
const MAX_RATE = 10;

const daysBetween = (start: Date, end: Date) => (end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24);

const npv = (rate: number, cashflows: CashflowPoint[]): number => {
  if (cashflows.length === 0) {
    return 0;
  }
  if (Math.abs(rate) <= TOLERANCE) {
    return cashflows.reduce((sum, flow) => sum + flow.amount, 0);
  }

  const startDate = new Date(cashflows[0]!.date);

  return cashflows.reduce((sum, flow) => {
    const date = new Date(flow.date);
    const t = daysBetween(startDate, date) / 365;
    return sum + flow.amount / Math.pow(1 + rate, t);
  }, 0);
};

const npvDerivative = (rate: number, cashflows: CashflowPoint[]): number => {
  if (cashflows.length === 0) {
    return 0;
  }
  const startDate = new Date(cashflows[0]!.date);

  return cashflows.reduce((sum, flow) => {
    const date = new Date(flow.date);
    const t = daysBetween(startDate, date) / 365;
    if (rate === -1) {
      return sum;
    }
    return sum - (t * flow.amount) / Math.pow(1 + rate, t + 1);
  }, 0);
};

export const calculateXirr = (cashflows: CashflowPoint[]): number | null => {
  if (cashflows.length === 0) {
    return null;
  }

  const positive = cashflows.some((flow) => flow.amount > 0);
  const negative = cashflows.some((flow) => flow.amount < 0);
  if (!positive || !negative) {
    return null;
  }

  let rate = 0.1;

  for (let i = 0; i < MAX_ITERATIONS; i += 1) {
    const value = npv(rate, cashflows);
    const derivative = npvDerivative(rate, cashflows);

    if (Math.abs(derivative) < TOLERANCE) {
      break;
    }

    const nextRate = rate - value / derivative;

    if (Math.abs(nextRate - rate) <= TOLERANCE) {
      return nextRate;
    }

    rate = nextRate;

    if (rate <= MIN_RATE || rate >= MAX_RATE) {
      break;
    }
  }

  // Fallback to bisection
  let low = MIN_RATE;
  let high = MAX_RATE;
  let mid = (low + high) / 2;

  for (let i = 0; i < MAX_ITERATIONS; i += 1) {
    mid = (low + high) / 2;
    const value = npv(mid, cashflows);

    if (Math.abs(value) <= TOLERANCE) {
      return mid;
    }

    const lowValue = npv(low, cashflows);
    if (value > 0 === lowValue > 0) {
      low = mid;
    } else {
      high = mid;
    }
  }

  return mid;
};
