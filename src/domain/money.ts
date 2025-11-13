import Decimal from 'decimal.js';

// Configure Decimal.js for financial calculations
Decimal.set({
  precision: 20,
  rounding: Decimal.ROUND_HALF_EVEN, // Banker's rounding
  toExpNeg: -7,
  toExpPos: 21,
});

export class Money {
  private readonly amount: Decimal;

  constructor(value: number | string | Decimal) {
    this.amount = new Decimal(value);
  }

  static zero(): Money {
    return new Money(0);
  }

  static sum(values: Money[]): Money {
    return new Money(
      values.reduce((acc, val) => acc.plus(val.amount), new Decimal(0))
    );
  }

  add(other: Money): Money {
    return new Money(this.amount.plus(other.amount));
  }

  subtract(other: Money): Money {
    return new Money(this.amount.minus(other.amount));
  }

  multiply(factor: number | string | Decimal): Money {
    return new Money(this.amount.times(factor));
  }

  divide(divisor: number | string | Decimal): Money {
    return new Money(this.amount.dividedBy(divisor));
  }

  percentage(rate: number): Money {
    return new Money(this.amount.times(rate).dividedBy(100));
  }

  greaterThan(other: Money): boolean {
    return this.amount.greaterThan(other.amount);
  }

  greaterThanOrEqual(other: Money): boolean {
    return this.amount.greaterThanOrEqualTo(other.amount);
  }

  lessThan(other: Money): boolean {
    return this.amount.lessThan(other.amount);
  }

  lessThanOrEqual(other: Money): boolean {
    return this.amount.lessThanOrEqualTo(other.amount);
  }

  equals(other: Money): boolean {
    return this.amount.equals(other.amount);
  }

  isPositive(): boolean {
    return this.amount.greaterThan(0);
  }

  isNegative(): boolean {
    return this.amount.lessThan(0);
  }

  isZero(): boolean {
    return this.amount.equals(0);
  }

  abs(): Money {
    return new Money(this.amount.abs());
  }

  negate(): Money {
    return new Money(this.amount.negated());
  }

  // Round to 2 decimal places for invoice amounts
  toInvoiceAmount(): number {
    return this.amount.toDecimalPlaces(2, Decimal.ROUND_HALF_EVEN).toNumber();
  }

  // Keep 6 decimal places for internal calculations
  toCalculationAmount(): number {
    return this.amount.toDecimalPlaces(6, Decimal.ROUND_HALF_EVEN).toNumber();
  }

  toNumber(): number {
    return this.amount.toNumber();
  }

  toString(): string {
    return this.amount.toString();
  }

  toFixed(decimals: number = 2): string {
    return this.amount.toFixed(decimals);
  }
}
