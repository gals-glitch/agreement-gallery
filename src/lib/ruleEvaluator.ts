import { CalculationContext, AdvancedCommissionRule, RuleCondition, CommissionTier, CalculationResult } from '@/types/calculationEngine';

export class RuleEvaluator {
  /**
   * Evaluate if a rule applies to a given distribution context
   */
  static evaluateRule(rule: AdvancedCommissionRule, context: CalculationContext): CalculationResult {
    const startTime = performance.now();
    
    try {
      // Check if rule is active and within effective dates
      if (!this.isRuleActive(rule)) {
        return this.createSkippedResult(rule, 'Rule is not active', performance.now() - startTime);
      }

      // Check date range
      if (!this.isWithinDateRange(rule, context)) {
        return this.createSkippedResult(rule, 'Distribution date outside rule effective range', performance.now() - startTime);
      }

      // Check entity match
      if (!this.isEntityMatch(rule, context)) {
        return this.createSkippedResult(rule, 'Entity name does not match', performance.now() - startTime);
      }

      // Evaluate conditions
      const conditionsResult = this.evaluateConditions(rule.conditions || [], context);
      if (!conditionsResult.passed) {
        return this.createSkippedResult(rule, `Conditions not met: ${conditionsResult.reason}`, performance.now() - startTime);
      }

      // Calculate commission
      const calculation = this.calculateCommission(rule, context);
      
      return {
        rule_id: rule.id,
        entity_type: rule.entity_type,
        entity_name: this.getEntityName(rule, context),
        applicable: true,
        calculation,
        conditions_met: conditionsResult.details,
        execution_time_ms: Math.round(performance.now() - startTime)
      };

    } catch (error) {
      return {
        rule_id: rule.id,
        entity_type: rule.entity_type,
        entity_name: this.getEntityName(rule, context),
        applicable: false,
        execution_time_ms: Math.round(performance.now() - startTime),
        error: error instanceof Error ? error.message : 'Unknown error'
      };
    }
  }

  private static isRuleActive(rule: AdvancedCommissionRule): boolean {
    return rule.is_active;
  }

  private static isWithinDateRange(rule: AdvancedCommissionRule, context: CalculationContext): boolean {
    if (!context.distribution.distribution_date) return true;
    
    const distributionDate = new Date(context.distribution.distribution_date);
    
    if (rule.effective_from) {
      const effectiveFrom = new Date(rule.effective_from);
      if (distributionDate < effectiveFrom) return false;
    }
    
    if (rule.effective_to) {
      const effectiveTo = new Date(rule.effective_to);
      if (distributionDate > effectiveTo) return false;
    }
    
    return true;
  }

  private static isEntityMatch(rule: AdvancedCommissionRule, context: CalculationContext): boolean {
    const entityName = this.getEntityName(rule, context);
    
    // If rule doesn't specify entity name, it applies to all
    if (!rule.entity_name || rule.entity_name === 'Default Distributor' || rule.entity_name === 'Default Referrer' || rule.entity_name === 'Default Partner') {
      return !!entityName; // Just check entity exists
    }
    
    return rule.entity_name === entityName;
  }

  private static getEntityName(rule: AdvancedCommissionRule, context: CalculationContext): string {
    switch (rule.entity_type) {
      case 'distributor':
        return context.distribution.distributor_name || '';
      case 'referrer':
        return context.distribution.referrer_name || '';
      case 'partner':
        return context.distribution.partner_name || '';
      default:
        return '';
    }
  }

  private static evaluateConditions(conditions: RuleCondition[], context: CalculationContext): { passed: boolean; reason?: string; details: Record<string, any> } {
    if (!conditions.length) {
      return { passed: true, details: {} };
    }

    const details: Record<string, any> = {};
    const groupResults: Record<number, boolean> = {};

    // Evaluate each condition
    for (const condition of conditions) {
      const result = this.evaluateCondition(condition, context);
      details[`condition_${condition.id}`] = result;

      // Group results (AND within group, OR between groups)
      if (!groupResults.hasOwnProperty(condition.condition_group)) {
        groupResults[condition.condition_group] = true;
      }
      
      if (condition.is_required && !result.passed) {
        groupResults[condition.condition_group] = false;
      }
    }

    // Check if any group passed (OR logic between groups)
    const anyGroupPassed = Object.values(groupResults).some(passed => passed);
    
    if (!anyGroupPassed) {
      return {
        passed: false,
        reason: 'Required conditions not met',
        details
      };
    }

    return { passed: true, details };
  }

  private static evaluateCondition(condition: RuleCondition, context: CalculationContext): { passed: boolean; actual_value: any; expected_value: any } {
    const fieldValue = this.getFieldValue(condition.field_name, context);
    const conditionValue = this.getConditionValue(condition);

    let passed = false;

    switch (condition.operator) {
      case 'equals':
        passed = fieldValue === conditionValue;
        break;
      case 'greater_than':
        passed = Number(fieldValue) > Number(conditionValue);
        break;
      case 'less_than':
        passed = Number(fieldValue) < Number(conditionValue);
        break;
      case 'greater_equal':
        passed = Number(fieldValue) >= Number(conditionValue);
        break;
      case 'less_equal':
        passed = Number(fieldValue) <= Number(conditionValue);
        break;
      case 'between':
        if (Array.isArray(conditionValue) && conditionValue.length === 2) {
          const [min, max] = conditionValue.map(Number);
          passed = Number(fieldValue) >= min && Number(fieldValue) <= max;
        }
        break;
      case 'in':
        passed = Array.isArray(conditionValue) && conditionValue.includes(fieldValue);
        break;
      case 'not_in':
        passed = Array.isArray(conditionValue) && !conditionValue.includes(fieldValue);
        break;
    }

    return {
      passed,
      actual_value: fieldValue,
      expected_value: conditionValue
    };
  }

  private static getFieldValue(fieldName: string, context: CalculationContext): any {
    switch (fieldName) {
      case 'distribution_amount':
        return context.distribution.distribution_amount;
      case 'fund_name':
        return context.distribution.fund_name;
      case 'investor_name':
        return context.distribution.investor_name;
      case 'cumulative_amount':
        return context.historical_data?.cumulative_amount || 0;
      case 'monthly_volume':
        return context.historical_data?.monthly_volume || 0;
      case 'quarterly_volume':
        return context.historical_data?.quarterly_volume || 0;
      case 'annual_volume':
        return context.historical_data?.annual_volume || 0;
      default:
        return context.metadata?.[fieldName];
    }
  }

  private static getConditionValue(condition: RuleCondition): any {
    if (condition.value_array) return condition.value_array;
    if (condition.value_number !== undefined) return condition.value_number;
    if (condition.value_date) return condition.value_date;
    return condition.value_text;
  }

  private static calculateCommission(rule: AdvancedCommissionRule, context: CalculationContext) {
    const baseAmount = this.getBaseAmount(rule, context);
    
    switch (rule.rule_type) {
      case 'percentage':
        return this.calculatePercentageCommission(rule, baseAmount);
      case 'fixed_amount':
        return this.calculateFixedCommission(rule, baseAmount);
      case 'tiered':
        return this.calculateTieredCommission(rule, baseAmount);
      case 'hybrid':
        return this.calculateHybridCommission(rule, baseAmount);
      default:
        throw new Error(`Unsupported rule type: ${rule.rule_type}`);
    }
  }

  private static getBaseAmount(rule: AdvancedCommissionRule, context: CalculationContext): number {
    switch (rule.calculation_basis) {
      case 'distribution_amount':
        return context.distribution.distribution_amount;
      case 'cumulative_amount':
        return context.historical_data?.cumulative_amount || context.distribution.distribution_amount;
      case 'monthly_volume':
        return context.historical_data?.monthly_volume || context.distribution.distribution_amount;
      case 'quarterly_volume':
        return context.historical_data?.quarterly_volume || context.distribution.distribution_amount;
      case 'annual_volume':
        return context.historical_data?.annual_volume || context.distribution.distribution_amount;
      default:
        return context.distribution.distribution_amount;
    }
  }

  private static calculatePercentageCommission(rule: AdvancedCommissionRule, baseAmount: number) {
    const rate = rule.base_rate || 0;
    const grossCommission = Math.max(baseAmount * rate, rule.min_amount);
    const cappedCommission = rule.max_amount ? Math.min(grossCommission, rule.max_amount) : grossCommission;
    
    // PRD-compliant VAT calculation
    const vatRate = 0.21; // This should come from rule.vat_rate_table lookup
    let vatAmount: number;
    let netCommission: number;
    
    if ((rule as any).vat_mode === 'included') {
      // VAT included: total = gross, vat = total × rate / (1 + rate), net = total - vat
      const total = cappedCommission;
      vatAmount = total * vatRate / (1 + vatRate);
      netCommission = total - vatAmount;
    } else {
      // VAT added: net = gross, vat = gross × rate, total = gross + vat
      netCommission = cappedCommission;
      vatAmount = cappedCommission * vatRate;
    }
    
    return {
      base_amount: baseAmount,
      applied_rate: rate,
      gross_commission: cappedCommission,
      vat_rate: vatRate,
      vat_amount: vatAmount,
      net_commission: netCommission,
      method: `Percentage: ${(rate * 100).toFixed(2)}% of ${baseAmount.toLocaleString()}`
    };
  }

  private static calculateFixedCommission(rule: AdvancedCommissionRule, baseAmount: number) {
    const fixedAmount = rule.fixed_amount || 0;
    
    // PRD-compliant VAT calculation
    const vatRate = 0.21;
    let vatAmount: number;
    let netCommission: number;
    
    if ((rule as any).vat_mode === 'included') {
      const total = fixedAmount;
      vatAmount = total * vatRate / (1 + vatRate);
      netCommission = total - vatAmount;
    } else {
      netCommission = fixedAmount;
      vatAmount = fixedAmount * vatRate;
    }
    
    return {
      base_amount: baseAmount,
      gross_commission: fixedAmount,
      vat_rate: vatRate,
      vat_amount: vatAmount,
      net_commission: netCommission,
      method: `Fixed amount: ${fixedAmount.toLocaleString()}`
    };
  }

  private static calculateTieredCommission(rule: AdvancedCommissionRule, baseAmount: number) {
    if (!rule.tiers || rule.tiers.length === 0) {
      throw new Error('Tiered rule must have tiers defined');
    }

    // Find applicable tier
    const applicableTier = rule.tiers
      .sort((a, b) => a.tier_order - b.tier_order)
      .find(tier => {
        const aboveMin = baseAmount >= tier.min_threshold;
        const belowMax = !tier.max_threshold || baseAmount <= tier.max_threshold;
        return aboveMin && belowMax;
      });

    if (!applicableTier) {
      throw new Error('No applicable tier found for amount');
    }

    const grossCommission = applicableTier.fixed_amount || (baseAmount * applicableTier.rate);
    const cappedCommission = rule.max_amount ? Math.min(grossCommission, rule.max_amount) : grossCommission;
    
    // PRD-compliant VAT calculation
    const vatRate = 0.21;
    let vatAmount: number;
    let netCommission: number;
    
    if ((rule as any).vat_mode === 'included') {
      const total = cappedCommission;
      vatAmount = total * vatRate / (1 + vatRate);
      netCommission = total - vatAmount;
    } else {
      netCommission = cappedCommission;
      vatAmount = cappedCommission * vatRate;
    }

    return {
      base_amount: baseAmount,
      applied_rate: applicableTier.rate,
      tier_applied: applicableTier.tier_order,
      gross_commission: cappedCommission,
      vat_rate: vatRate,
      vat_amount: vatAmount,
      net_commission: netCommission,
      method: `Tier ${applicableTier.tier_order}: ${applicableTier.description || 'No description'}`
    };
  }

  private static calculateHybridCommission(rule: AdvancedCommissionRule, baseAmount: number) {
    // Hybrid: combination of fixed + percentage
    const fixedPart = rule.fixed_amount || 0;
    const percentagePart = (rule.base_rate || 0) * baseAmount;
    const totalGross = fixedPart + percentagePart;
    const cappedCommission = rule.max_amount ? Math.min(totalGross, rule.max_amount) : totalGross;
    
    // PRD-compliant VAT calculation
    const vatRate = 0.21;
    let vatAmount: number;
    let netCommission: number;
    
    if ((rule as any).vat_mode === 'included') {
      const total = cappedCommission;
      vatAmount = total * vatRate / (1 + vatRate);
      netCommission = total - vatAmount;
    } else {
      netCommission = cappedCommission;
      vatAmount = cappedCommission * vatRate;
    }

    return {
      base_amount: baseAmount,
      applied_rate: rule.base_rate,
      gross_commission: cappedCommission,
      vat_rate: vatRate,
      vat_amount: vatAmount,
      net_commission: netCommission,
      method: `Hybrid: ${fixedPart.toLocaleString()} fixed + ${((rule.base_rate || 0) * 100).toFixed(2)}% of ${baseAmount.toLocaleString()}`
    };
  }

  private static createSkippedResult(rule: AdvancedCommissionRule, reason: string, executionTime: number): CalculationResult {
    return {
      rule_id: rule.id,
      entity_type: rule.entity_type,
      entity_name: rule.entity_name || '',
      applicable: false,
      execution_time_ms: Math.round(executionTime),
      error: reason
    };
  }
}