/**
 * High-precision decimal math library for commission calculations
 * Implements M2 requirements: 9+ fractional digits internally, configurable rounding
 */

import { Decimal } from 'decimal.js';

// Configure Decimal.js for high precision
Decimal.config({
  precision: 20, // High precision for internal calculations
  rounding: Decimal.ROUND_HALF_UP,
  toExpNeg: -9,
  toExpPos: 21,
  minE: -9,
  maxE: 21
});

export class PrecisionDecimal {
  private value: Decimal;

  constructor(value: string | number | Decimal | PrecisionDecimal) {
    if (value instanceof PrecisionDecimal) {
      this.value = value.value;
    } else if (value instanceof Decimal) {
      this.value = value;
    } else {
      this.value = new Decimal(value);
    }
  }

  // Arithmetic operations
  add(other: string | number | PrecisionDecimal): PrecisionDecimal {
    const otherValue = other instanceof PrecisionDecimal ? other.value : new Decimal(other);
    return new PrecisionDecimal(this.value.add(otherValue));
  }

  subtract(other: string | number | PrecisionDecimal): PrecisionDecimal {
    const otherValue = other instanceof PrecisionDecimal ? other.value : new Decimal(other);
    return new PrecisionDecimal(this.value.sub(otherValue));
  }

  multiply(other: string | number | PrecisionDecimal): PrecisionDecimal {
    const otherValue = other instanceof PrecisionDecimal ? other.value : new Decimal(other);
    return new PrecisionDecimal(this.value.mul(otherValue));
  }

  divide(other: string | number | PrecisionDecimal): PrecisionDecimal {
    const otherValue = other instanceof PrecisionDecimal ? other.value : new Decimal(other);
    if (otherValue.isZero()) {
      throw new Error('Division by zero');
    }
    return new PrecisionDecimal(this.value.div(otherValue));
  }

  // Comparison operations
  equals(other: string | number | PrecisionDecimal): boolean {
    const otherValue = other instanceof PrecisionDecimal ? other.value : new Decimal(other);
    return this.value.equals(otherValue);
  }

  greaterThan(other: string | number | PrecisionDecimal): boolean {
    const otherValue = other instanceof PrecisionDecimal ? other.value : new Decimal(other);
    return this.value.greaterThan(otherValue);
  }

  greaterThanOrEqual(other: string | number | PrecisionDecimal): boolean {
    const otherValue = other instanceof PrecisionDecimal ? other.value : new Decimal(other);
    return this.value.greaterThanOrEqualTo(otherValue);
  }

  lessThan(other: string | number | PrecisionDecimal): boolean {
    const otherValue = other instanceof PrecisionDecimal ? other.value : new Decimal(other);
    return this.value.lessThan(otherValue);
  }

  lessThanOrEqual(other: string | number | PrecisionDecimal): boolean {
    const otherValue = other instanceof PrecisionDecimal ? other.value : new Decimal(other);
    return this.value.lessThanOrEqualTo(otherValue);
  }

  isZero(): boolean {
    return this.value.isZero();
  }

  isPositive(): boolean {
    return this.value.isPositive();
  }

  isNegative(): boolean {
    return this.value.isNegative();
  }

  // Utility methods
  abs(): PrecisionDecimal {
    return new PrecisionDecimal(this.value.abs());
  }

  min(other: string | number | PrecisionDecimal): PrecisionDecimal {
    const otherValue = other instanceof PrecisionDecimal ? other.value : new Decimal(other);
    return new PrecisionDecimal(Decimal.min(this.value, otherValue));
  }

  max(other: string | number | PrecisionDecimal): PrecisionDecimal {
    const otherValue = other instanceof PrecisionDecimal ? other.value : new Decimal(other);
    return new PrecisionDecimal(Decimal.max(this.value, otherValue));
  }

  // Formatting and rounding
  toFixed(decimals: number = 2): string {
    return this.value.toFixed(decimals);
  }

  toPercentage(decimals: number = 5): string {
    return this.value.mul(100).toFixed(decimals) + '%';
  }

  toCurrency(decimals: number = 2): string {
    return this.value.toFixed(decimals);
  }

  round(decimals: number): PrecisionDecimal {
    return new PrecisionDecimal(this.value.toDecimalPlaces(decimals));
  }

  // Raw value access
  toNumber(): number {
    return this.value.toNumber();
  }

  toString(): string {
    return this.value.toString();
  }

  toJSON(): string {
    return this.value.toString();
  }

  // Static factory methods
  static fromPercentage(percentage: string | number): PrecisionDecimal {
    return new PrecisionDecimal(new Decimal(percentage).div(100));
  }

  static zero(): PrecisionDecimal {
    return new PrecisionDecimal(0);
  }

  static sum(values: PrecisionDecimal[]): PrecisionDecimal {
    return values.reduce((acc, val) => acc.add(val), PrecisionDecimal.zero());
  }

  static max(...values: PrecisionDecimal[]): PrecisionDecimal {
    if (values.length === 0) throw new Error('Cannot find max of empty array');
    return values.reduce((max, val) => val.greaterThan(max) ? val : max);
  }

  static min(...values: PrecisionDecimal[]): PrecisionDecimal {
    if (values.length === 0) throw new Error('Cannot find min of empty array');
    return values.reduce((min, val) => val.lessThan(min) ? val : min);
  }
}

/**
 * Commission calculation result with detailed breakdown
 */
export interface CalculationStep {
  stepType: 'base' | 'tier_selection' | 'rate_application' | 'cap_check' | 'vat_calculation' | 'credit_application';
  inputValues: Record<string, any>;
  outputValues: Record<string, any>;
  formula: string;
  notes?: string;
}

export interface CommissionCalculationResult {
  baseAmount: PrecisionDecimal;
  grossCommission: PrecisionDecimal;
  netCommission: PrecisionDecimal;
  vatAmount: PrecisionDecimal;
  vatRate: PrecisionDecimal;
  appliedRate: PrecisionDecimal;
  tierApplied?: number;
  capReached: boolean;
  creditsApplied: PrecisionDecimal;
  steps: CalculationStep[];
  ruleVersionId: string;
  checksum: string;
}

/**
 * Tiered commission calculator
 */
export class TieredCommissionCalculator {
  private steps: CalculationStep[] = [];

  constructor(private ruleVersionId: string) {}

  /**
   * Calculate commission with tiered rates
   */
  calculateTieredCommission(
    baseAmount: PrecisionDecimal,
    tiers: Array<{
      minThreshold: PrecisionDecimal;
      maxThreshold?: PrecisionDecimal;
      rate: PrecisionDecimal;
      tierOrder: number;
    }>,
    options: {
      maxAmount?: PrecisionDecimal;
      vatRate?: PrecisionDecimal;
      vatMode?: 'included' | 'added';
      creditsAvailable?: PrecisionDecimal;
    } = {}
  ): CommissionCalculationResult {
    this.steps = [];
    
    // Step 1: Base calculation
    this.addStep('base', 
      { baseAmount: baseAmount.toString() },
      { baseAmount: baseAmount.toString() },
      'baseAmount = contributionAmount'
    );

    // Step 2: Tier selection and rate application
    let grossCommission = PrecisionDecimal.zero();
    let appliedRate = PrecisionDecimal.zero();
    let tierApplied: number | undefined;
    let remainingAmount = baseAmount;

    // Sort tiers by order
    const sortedTiers = [...tiers].sort((a, b) => a.tierOrder - b.tierOrder);
    
    for (const tier of sortedTiers) {
      if (remainingAmount.isZero() || remainingAmount.lessThanOrEqual(0)) break;
      
      const tierMin = tier.minThreshold;
      const tierMax = tier.maxThreshold || new PrecisionDecimal(Number.MAX_SAFE_INTEGER);
      
      // Calculate amount in this tier
      const tierBase = baseAmount.subtract(tierMin);
      if (tierBase.lessThanOrEqual(0)) continue;
      
      const amountInTier = PrecisionDecimal.min(
        tierBase,
        tierMax.subtract(tierMin),
        remainingAmount
      );
      
      if (amountInTier.greaterThan(0)) {
        const tierCommission = amountInTier.multiply(tier.rate);
        grossCommission = grossCommission.add(tierCommission);
        appliedRate = tier.rate; // Last applied rate
        tierApplied = tier.tierOrder;
        
        this.addStep('tier_selection',
          { 
            tierOrder: tier.tierOrder,
            tierMin: tierMin.toString(),
            tierMax: tier.maxThreshold?.toString() || 'unlimited',
            rate: tier.rate.toPercentage(),
            amountInTier: amountInTier.toString()
          },
          { tierCommission: tierCommission.toString() },
          `tier${tier.tierOrder}: ${amountInTier.toFixed(2)} × ${tier.rate.toPercentage()} = ${tierCommission.toFixed(2)}`
        );
        
        remainingAmount = remainingAmount.subtract(amountInTier);
      }
    }

    // Step 3: Apply caps
    let capReached = false;
    if (options.maxAmount && grossCommission.greaterThan(options.maxAmount)) {
      this.addStep('cap_check',
        { 
          grossCommission: grossCommission.toString(),
          maxAmount: options.maxAmount.toString()
        },
        { grossCommission: options.maxAmount.toString() },
        `Applied cap: min(${grossCommission.toFixed(2)}, ${options.maxAmount.toFixed(2)}) = ${options.maxAmount.toFixed(2)}`
      );
      
      grossCommission = options.maxAmount;
      capReached = true;
    } else {
      this.addStep('cap_check',
        { grossCommission: grossCommission.toString() },
        { grossCommission: grossCommission.toString() },
        'No cap applied'
      );
    }

    // Step 4: Apply credits
    const creditsApplied = options.creditsAvailable || PrecisionDecimal.zero();
    let netCommissionBeforeVat = grossCommission.subtract(creditsApplied);
    
    if (creditsApplied.greaterThan(0)) {
      this.addStep('credit_application',
        { 
          grossCommission: grossCommission.toString(),
          creditsApplied: creditsApplied.toString()
        },
        { netCommissionBeforeVat: netCommissionBeforeVat.toString() },
        `Applied credits: ${grossCommission.toFixed(2)} - ${creditsApplied.toFixed(2)} = ${netCommissionBeforeVat.toFixed(2)}`
      );
    }

    // Step 5: VAT calculation
    const vatRate = options.vatRate || PrecisionDecimal.zero();
    let vatAmount = PrecisionDecimal.zero();
    let netCommission = netCommissionBeforeVat;

    if (vatRate.greaterThan(0)) {
      if (options.vatMode === 'included') {
        // VAT is included in the commission
        vatAmount = netCommissionBeforeVat.multiply(vatRate).divide(new PrecisionDecimal(1).add(vatRate));
        netCommission = netCommissionBeforeVat.subtract(vatAmount);
        
        this.addStep('vat_calculation',
          { 
            grossAmount: netCommissionBeforeVat.toString(),
            vatRate: vatRate.toPercentage(),
            vatMode: 'included'
          },
          { 
            vatAmount: vatAmount.toString(),
            netCommission: netCommission.toString()
          },
          `VAT included: ${vatAmount.toFixed(2)} (${vatRate.toPercentage()}), Net: ${netCommission.toFixed(2)}`
        );
      } else {
        // VAT is added to the commission
        vatAmount = netCommissionBeforeVat.multiply(vatRate);
        netCommission = netCommissionBeforeVat.add(vatAmount);
        
        this.addStep('vat_calculation',
          { 
            baseAmount: netCommissionBeforeVat.toString(),
            vatRate: vatRate.toPercentage(),
            vatMode: 'added'
          },
          { 
            vatAmount: vatAmount.toString(),
            netCommission: netCommission.toString()
          },
          `VAT added: ${vatAmount.toFixed(2)} (${vatRate.toPercentage()}), Total: ${netCommission.toFixed(2)}`
        );
      }
    } else {
      this.addStep('vat_calculation',
        { vatRate: '0%' },
        { vatAmount: '0', netCommission: netCommission.toString() },
        'No VAT applied'
      );
    }

    // Generate checksum for audit trail
    const checksum = this.generateChecksum(baseAmount, tiers, options);

    return {
      baseAmount,
      grossCommission,
      netCommission,
      vatAmount,
      vatRate,
      appliedRate,
      tierApplied,
      capReached,
      creditsApplied,
      steps: this.steps,
      ruleVersionId: this.ruleVersionId,
      checksum
    };
  }

  private addStep(
    stepType: CalculationStep['stepType'],
    inputValues: Record<string, any>,
    outputValues: Record<string, any>,
    formula: string,
    notes?: string
  ) {
    this.steps.push({
      stepType,
      inputValues,
      outputValues,
      formula,
      notes
    });
  }

  private generateChecksum(
    baseAmount: PrecisionDecimal,
    tiers: any[],
    options: any
  ): string {
    const data = {
      baseAmount: baseAmount.toString(),
      tiers: tiers.map(t => ({
        min: t.minThreshold.toString(),
        max: t.maxThreshold?.toString(),
        rate: t.rate.toString(),
        order: t.tierOrder
      })),
      options: {
        maxAmount: options.maxAmount?.toString(),
        vatRate: options.vatRate?.toString(),
        vatMode: options.vatMode,
        creditsAvailable: options.creditsAvailable?.toString()
      },
      ruleVersionId: this.ruleVersionId
    };
    
    // Simple checksum - in production, use crypto hash
    return btoa(JSON.stringify(data)).slice(0, 16);
  }
}

/**
 * Utility functions for common calculations
 */
export const MathUtils = {
  /**
   * Calculate percentage of amount
   */
  percentageOf(amount: PrecisionDecimal, percentage: PrecisionDecimal): PrecisionDecimal {
    return amount.multiply(percentage);
  },

  /**
   * Apply percentage increase/decrease
   */
  applyPercentage(amount: PrecisionDecimal, percentage: PrecisionDecimal, isIncrease: boolean = true): PrecisionDecimal {
    const change = amount.multiply(percentage);
    return isIncrease ? amount.add(change) : amount.subtract(change);
  },

  /**
   * Calculate compound interest
   */
  compoundInterest(principal: PrecisionDecimal, rate: PrecisionDecimal, periods: number): PrecisionDecimal {
    const onePlusRate = new PrecisionDecimal(1).add(rate);
    let result = principal;
    
    for (let i = 0; i < periods; i++) {
      result = result.multiply(onePlusRate);
    }
    
    return result;
  },

  /**
   * Calculate proportional allocation
   */
  proportionalAllocation(
    totalAmount: PrecisionDecimal, 
    weights: PrecisionDecimal[]
  ): PrecisionDecimal[] {
    const totalWeight = PrecisionDecimal.sum(weights);
    
    if (totalWeight.isZero()) {
      throw new Error('Total weight cannot be zero');
    }
    
    return weights.map(weight => totalAmount.multiply(weight).divide(totalWeight));
  }
};