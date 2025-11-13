import { Money } from '@/domain/money';
import { CommissionTier } from '@/domain/types';

export interface TierCalculationResult {
  base_amount: number;
  applied_rate: number;
  tier_applied?: number;
  fee_gross: number;
  calculation_method: string;
  notes?: string;
}

export class TierEngine {
  /**
   * Calculate commission using tiered rates
   * Handles both:
   * - Stepped tiers (apply different rates to slices of the amount)
   * - Threshold tiers (apply single rate based on which tier the total falls into)
   */
  static calculateTiered(
    baseAmount: number,
    tiers: CommissionTier[],
    isSteppedTiers: boolean = true
  ): TierCalculationResult {
    if (tiers.length === 0) {
      throw new Error('No tiers defined for tiered calculation');
    }

    // Sort tiers by order
    const sortedTiers = [...tiers].sort((a, b) => a.tier_order - b.tier_order);

    if (isSteppedTiers) {
      return this.calculateSteppedTiers(baseAmount, sortedTiers);
    } else {
      return this.calculateThresholdTiers(baseAmount, sortedTiers);
    }
  }

  /**
   * Stepped tiers: apply different rates to different slices of the amount
   * Example: First $1M at 2%, next $2M at 1.5%, remainder at 1%
   */
  private static calculateSteppedTiers(
    baseAmount: number,
    sortedTiers: CommissionTier[]
  ): TierCalculationResult {
    const amount = new Money(baseAmount);
    let remaining = amount;
    let totalFee = Money.zero();
    const appliedRates: number[] = [];
    const tierDetails: string[] = [];

    for (const tier of sortedTiers) {
      if (remaining.lessThanOrEqual(Money.zero())) break;

      const tierMin = new Money(tier.min_threshold);
      const tierMax = tier.max_threshold ? new Money(tier.max_threshold) : null;

      // Calculate the amount in this tier
      let amountInTier: Money;
      if (tierMax) {
        const tierRange = tierMax.subtract(tierMin);
        amountInTier = Money.zero().greaterThan(remaining.subtract(tierRange))
          ? remaining
          : tierRange;
      } else {
        // Last tier - unlimited
        amountInTier = remaining;
      }

      // Apply rate to this slice
      const tierFee = tier.fixed_amount
        ? new Money(tier.fixed_amount)
        : amountInTier.percentage(tier.rate);

      totalFee = totalFee.add(tierFee);
      remaining = remaining.subtract(amountInTier);
      appliedRates.push(tier.rate);

      tierDetails.push(
        `Tier ${tier.tier_order}: ${amountInTier.toFixed(2)} @ ${tier.rate}% = ${tierFee.toFixed(2)}`
      );
    }

    return {
      base_amount: baseAmount,
      applied_rate: appliedRates[0] || 0, // Primary rate for reporting
      tier_applied: sortedTiers[0]?.tier_order,
      fee_gross: totalFee.toInvoiceAmount(),
      calculation_method: 'stepped_tiers',
      notes: tierDetails.join('; '),
    };
  }

  /**
   * Threshold tiers: apply a single rate based on which tier the total amount falls into
   * Example: $0-$3M = 2%, $3M-$6M = 2.6%, >$6M = 3.1%
   */
  private static calculateThresholdTiers(
    baseAmount: number,
    sortedTiers: CommissionTier[]
  ): TierCalculationResult {
    const amount = new Money(baseAmount);

    // Find the tier that applies to this amount
    const applicableTier = sortedTiers
      .reverse()
      .find(tier => {
        const min = new Money(tier.min_threshold);
        const max = tier.max_threshold ? new Money(tier.max_threshold) : null;
        
        if (max) {
          return amount.greaterThanOrEqual(min) && amount.lessThan(max);
        } else {
          return amount.greaterThanOrEqual(min);
        }
      });

    if (!applicableTier) {
      // Fall back to first tier if amount is below all thresholds
      const firstTier = sortedTiers[0];
      const fee = firstTier.fixed_amount
        ? new Money(firstTier.fixed_amount)
        : amount.percentage(firstTier.rate);

      return {
        base_amount: baseAmount,
        applied_rate: firstTier.rate,
        tier_applied: firstTier.tier_order,
        fee_gross: fee.toInvoiceAmount(),
        calculation_method: 'threshold_tiers',
        notes: `Below threshold - using base tier at ${firstTier.rate}%`,
      };
    }

    const fee = applicableTier.fixed_amount
      ? new Money(applicableTier.fixed_amount)
      : amount.percentage(applicableTier.rate);

    return {
      base_amount: baseAmount,
      applied_rate: applicableTier.rate,
      tier_applied: applicableTier.tier_order,
      fee_gross: fee.toInvoiceAmount(),
      calculation_method: 'threshold_tiers',
      notes: `Tier ${applicableTier.tier_order} @ ${applicableTier.rate}%`,
    };
  }

  /**
   * Apply caps (min/max) to a fee amount
   */
  static applyCaps(
    feeAmount: number,
    minAmount: number,
    maxAmount?: number
  ): { capped_fee: number; notes?: string } {
    const fee = new Money(feeAmount);
    const min = new Money(minAmount);
    let cappedFee = fee;
    let notes: string | undefined;

    if (fee.lessThan(min)) {
      cappedFee = min;
      notes = `Applied minimum cap: ${min.toFixed(2)}`;
    } else if (maxAmount) {
      const max = new Money(maxAmount);
      if (fee.greaterThan(max)) {
        cappedFee = max;
        notes = `Applied maximum cap: ${max.toFixed(2)}`;
      }
    }

    return {
      capped_fee: cappedFee.toInvoiceAmount(),
      notes,
    };
  }
}
