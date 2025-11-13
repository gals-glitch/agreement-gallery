import { CalculationContext, AdvancedCommissionRule, RuleCondition, CommissionTier, CalculationResult } from '@/types/calculationEngine';

/**
 * Enhanced Rule Evaluator with improved validation and calculation logic
 */
export class AdvancedRuleEvaluator {
  
  static evaluateRule(rule: AdvancedCommissionRule, context: CalculationContext): CalculationResult {
    const startTime = performance.now();
    
    try {
      // Enhanced validation pipeline
      const validationResult = this.validateRuleApplication(rule, context);
      if (!validationResult.isValid) {
        return this.createResult(rule, context, false, validationResult.reason, performance.now() - startTime);
      }

      // Calculate commission with enhanced logic
      const calculation = this.calculateCommissionWithValidation(rule, context);
      
      return {
        rule_id: rule.id,
        entity_type: rule.entity_type,
        entity_name: this.getEntityName(rule, context),
        applicable: true,
        calculation,
        conditions_met: validationResult.conditions,
        execution_time_ms: Math.round(performance.now() - startTime)
      };

    } catch (error) {
      return this.createResult(rule, context, false, error instanceof Error ? error.message : 'Unknown error', performance.now() - startTime);
    }
  }

  private static validateRuleApplication(rule: AdvancedCommissionRule, context: CalculationContext): {
    isValid: boolean;
    reason?: string;
    conditions: Record<string, any>;
  } {
    // Rule active check
    if (!rule.is_active) {
      return { isValid: false, reason: 'Rule is inactive', conditions: {} };
    }

    // Date range validation with improved logic
    if (!this.isWithinEffectiveDateRange(rule, context)) {
      return { isValid: false, reason: 'Distribution date outside effective range', conditions: {} };
    }

    // Entity matching with fuzzy logic
    if (!this.isEntityMatchWithFallback(rule, context)) {
      return { isValid: false, reason: 'Entity name mismatch', conditions: {} };
    }

    // Enhanced condition evaluation
    const conditionsResult = this.evaluateConditionsEnhanced(rule.conditions || [], context);
    if (!conditionsResult.passed) {
      return { isValid: false, reason: conditionsResult.reason, conditions: conditionsResult.details };
    }

    return { isValid: true, conditions: conditionsResult.details };
  }

  private static isWithinEffectiveDateRange(rule: AdvancedCommissionRule, context: CalculationContext): boolean {
    if (!context.distribution.distribution_date) return true;
    
    const distributionDate = new Date(context.distribution.distribution_date);
    const now = new Date();
    
    // Check if distribution date is not in the future
    if (distributionDate > now) {
      return false;
    }
    
    if (rule.effective_from) {
      const effectiveFrom = new Date(rule.effective_from);
      if (distributionDate < effectiveFrom) return false;
    }
    
    if (rule.effective_to) {
      const effectiveTo = new Date(rule.effective_to);
      // Allow until end of effective date
      effectiveTo.setHours(23, 59, 59, 999);
      if (distributionDate > effectiveTo) return false;
    }
    
    return true;
  }

  private static isEntityMatchWithFallback(rule: AdvancedCommissionRule, context: CalculationContext): boolean {
    const entityName = this.getEntityName(rule, context);
    
    if (!entityName) return false;
    
    // If no specific entity name in rule, apply as default
    if (!rule.entity_name || this.isDefaultEntity(rule.entity_name)) {
      return true;
    }
    
    // Exact match
    if (rule.entity_name === entityName) return true;
    
    // Case-insensitive match
    if (rule.entity_name.toLowerCase() === entityName.toLowerCase()) return true;
    
    // Partial match for compound names
    const ruleNameParts = rule.entity_name.toLowerCase().split(' ');
    const entityNameParts = entityName.toLowerCase().split(' ');
    
    return ruleNameParts.every(part => 
      entityNameParts.some(entityPart => entityPart.includes(part))
    );
  }

  private static isDefaultEntity(entityName: string): boolean {
    const defaultPatterns = ['default', 'all', 'any', '*', ''];
    return defaultPatterns.some(pattern => 
      entityName.toLowerCase().includes(pattern.toLowerCase())
    );
  }

  private static evaluateConditionsEnhanced(conditions: RuleCondition[], context: CalculationContext): {
    passed: boolean;
    reason?: string;
    details: Record<string, any>;
  } {
    if (!conditions.length) {
      return { passed: true, details: {} };
    }

    const details: Record<string, any> = {};
    const groupResults: Record<number, { passed: boolean; requiredConditions: number; metConditions: number }> = {};

    // Group and evaluate conditions
    for (const condition of conditions) {
      const groupId = condition.condition_group || 1;
      
      if (!groupResults[groupId]) {
        groupResults[groupId] = { passed: true, requiredConditions: 0, metConditions: 0 };
      }

      const result = this.evaluateConditionEnhanced(condition, context);
      details[`condition_${condition.id}`] = result;

      if (condition.is_required) {
        groupResults[groupId].requiredConditions++;
        if (result.passed) {
          groupResults[groupId].metConditions++;
        } else {
          groupResults[groupId].passed = false;
        }
      }
    }

    // Check if any group passed (OR logic between groups)
    const passedGroups = Object.entries(groupResults).filter(([_, group]) => group.passed);
    
    if (passedGroups.length === 0) {
      return {
        passed: false,
        reason: 'No condition groups satisfied all required conditions',
        details
      };
    }

    return { passed: true, details };
  }

  private static evaluateConditionEnhanced(condition: RuleCondition, context: CalculationContext): {
    passed: boolean;
    actual_value: any;
    expected_value: any;
    validation_notes?: string;
  } {
    const fieldValue = this.getFieldValueEnhanced(condition.field_name, context);
    const conditionValue = this.getConditionValue(condition);

    let passed = false;
    let validationNotes = '';

    // Handle null/undefined values
    if (fieldValue === null || fieldValue === undefined) {
      return {
        passed: false,
        actual_value: fieldValue,
        expected_value: conditionValue,
        validation_notes: 'Field value is null or undefined'
      };
    }

    switch (condition.operator) {
      case 'equals':
        passed = this.compareValues(fieldValue, conditionValue, 'equals');
        break;
      case 'greater_than':
        passed = Number(fieldValue) > Number(conditionValue);
        validationNotes = `${fieldValue} > ${conditionValue}`;
        break;
      case 'less_than':
        passed = Number(fieldValue) < Number(conditionValue);
        validationNotes = `${fieldValue} < ${conditionValue}`;
        break;
      case 'greater_equal':
        passed = Number(fieldValue) >= Number(conditionValue);
        validationNotes = `${fieldValue} >= ${conditionValue}`;
        break;
      case 'less_equal':
        passed = Number(fieldValue) <= Number(conditionValue);
        validationNotes = `${fieldValue} <= ${conditionValue}`;
        break;
      case 'between':
        if (Array.isArray(conditionValue) && conditionValue.length === 2) {
          const [min, max] = conditionValue.map(Number);
          passed = Number(fieldValue) >= min && Number(fieldValue) <= max;
          validationNotes = `${min} <= ${fieldValue} <= ${max}`;
        }
        break;
      case 'in':
        passed = Array.isArray(conditionValue) && conditionValue.includes(fieldValue);
        validationNotes = `${fieldValue} in [${conditionValue}]`;
        break;
      case 'not_in':
        passed = Array.isArray(conditionValue) && !conditionValue.includes(fieldValue);
        validationNotes = `${fieldValue} not in [${conditionValue}]`;
        break;
    }

    return {
      passed,
      actual_value: fieldValue,
      expected_value: conditionValue,
      validation_notes: validationNotes
    };
  }

  private static compareValues(value1: any, value2: any, operator: string): boolean {
    // Type-aware comparison
    if (typeof value1 === 'string' && typeof value2 === 'string') {
      return value1.toLowerCase() === value2.toLowerCase();
    }
    
    if (typeof value1 === 'number' && typeof value2 === 'number') {
      return Math.abs(value1 - value2) < 0.01; // Handle floating point precision
    }
    
    return value1 === value2;
  }

  private static getFieldValueEnhanced(fieldName: string, context: CalculationContext): any {
    // Core distribution fields
    switch (fieldName) {
      case 'distribution_amount':
        return context.distribution.distribution_amount;
      case 'fund_name':
        return context.distribution.fund_name;
      case 'investor_name':
        return context.distribution.investor_name;
      case 'distributor_name':
        return context.distribution.distributor_name;
      case 'referrer_name':
        return context.distribution.referrer_name;
      case 'partner_name':
        return context.distribution.partner_name;
      case 'distribution_date':
        return context.distribution.distribution_date;
      
      // Historical data fields
      case 'cumulative_amount':
        return context.historical_data?.cumulative_amount || 0;
      case 'cumulative_amount_ytd':
        return context.historical_data?.cumulative_amount_ytd || 0;
      case 'cumulative_amount_term':
        return context.historical_data?.cumulative_amount_term || 0;
      case 'monthly_volume':
        return context.historical_data?.monthly_volume || 0;
      case 'quarterly_volume':
        return context.historical_data?.quarterly_volume || 0;
      case 'annual_volume':
        return context.historical_data?.annual_volume || 0;
      case 'deal_count':
        return context.historical_data?.deal_count || 0;
      
      // Calculated fields
      case 'distribution_month':
        if (context.distribution.distribution_date) {
          return new Date(context.distribution.distribution_date).getMonth() + 1;
        }
        return null;
      case 'distribution_quarter':
        if (context.distribution.distribution_date) {
          return Math.floor(new Date(context.distribution.distribution_date).getMonth() / 3) + 1;
        }
        return null;
      case 'distribution_year':
        if (context.distribution.distribution_date) {
          return new Date(context.distribution.distribution_date).getFullYear();
        }
        return null;
      
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

  private static calculateCommissionWithValidation(rule: AdvancedCommissionRule, context: CalculationContext) {
    const baseAmount = this.getBaseAmountEnhanced(rule, context);
    
    if (baseAmount <= 0) {
      throw new Error('Base amount must be positive for commission calculation');
    }
    
    switch (rule.rule_type) {
      case 'percentage':
        return this.calculatePercentageCommissionEnhanced(rule, baseAmount);
      case 'fixed_amount':
        return this.calculateFixedCommissionEnhanced(rule, baseAmount);
      case 'tiered':
        return this.calculateTieredCommissionEnhanced(rule, baseAmount);
      case 'hybrid':
        return this.calculateHybridCommissionEnhanced(rule, baseAmount);
      default:
        throw new Error(`Unsupported rule type: ${rule.rule_type}`);
    }
  }

  private static getBaseAmountEnhanced(rule: AdvancedCommissionRule, context: CalculationContext): number {
    let baseAmount = 0;
    
    switch (rule.calculation_basis) {
      case 'distribution_amount':
        baseAmount = context.distribution.distribution_amount || 0;
        break;
      case 'cumulative_amount':
        baseAmount = context.historical_data?.cumulative_amount || context.distribution.distribution_amount || 0;
        break;
      case 'monthly_volume':
        baseAmount = context.historical_data?.monthly_volume || context.distribution.distribution_amount || 0;
        break;
      case 'quarterly_volume':
        baseAmount = context.historical_data?.quarterly_volume || context.distribution.distribution_amount || 0;
        break;
      case 'annual_volume':
        baseAmount = context.historical_data?.annual_volume || context.distribution.distribution_amount || 0;
        break;
      default:
        baseAmount = context.distribution.distribution_amount || 0;
    }
    
    return Math.max(0, baseAmount);
  }

  private static calculatePercentageCommissionEnhanced(rule: AdvancedCommissionRule, baseAmount: number) {
    const rate = rule.base_rate || 0;
    if (rate < 0 || rate > 1) {
      throw new Error(`Invalid rate: ${rate}. Rate must be between 0 and 1`);
    }
    
    const grossCommission = baseAmount * rate;
    const cappedCommission = this.applyMinMaxConstraints(grossCommission, rule);
    
    const { vatAmount, netCommission } = this.calculateVATEnhanced(cappedCommission, rule);
    
    return {
      base_amount: baseAmount,
      applied_rate: rate,
      gross_commission: cappedCommission,
      vat_rate: this.getVATRate(rule),
      vat_amount: vatAmount,
      net_commission: netCommission,
      method: `Percentage: ${(rate * 100).toFixed(2)}% of ${baseAmount.toLocaleString()}`
    };
  }

  private static calculateFixedCommissionEnhanced(rule: AdvancedCommissionRule, baseAmount: number) {
    const fixedAmount = rule.fixed_amount || 0;
    if (fixedAmount < 0) {
      throw new Error(`Invalid fixed amount: ${fixedAmount}. Must be non-negative`);
    }
    
    const { vatAmount, netCommission } = this.calculateVATEnhanced(fixedAmount, rule);
    
    return {
      base_amount: baseAmount,
      gross_commission: fixedAmount,
      vat_rate: this.getVATRate(rule),
      vat_amount: vatAmount,
      net_commission: netCommission,
      method: `Fixed amount: ${fixedAmount.toLocaleString()}`
    };
  }

  private static calculateTieredCommissionEnhanced(rule: AdvancedCommissionRule, baseAmount: number) {
    if (!rule.tiers || rule.tiers.length === 0) {
      throw new Error('Tiered rule must have tiers defined');
    }

    const sortedTiers = [...rule.tiers].sort((a, b) => a.tier_order - b.tier_order);
    const applicableTier = this.findApplicableTier(sortedTiers, baseAmount);

    if (!applicableTier) {
      throw new Error(`No applicable tier found for amount: ${baseAmount}`);
    }

    const grossCommission = applicableTier.fixed_amount || (baseAmount * applicableTier.rate);
    const cappedCommission = this.applyMinMaxConstraints(grossCommission, rule);
    
    const { vatAmount, netCommission } = this.calculateVATEnhanced(cappedCommission, rule);

    return {
      base_amount: baseAmount,
      applied_rate: applicableTier.rate,
      tier_applied: applicableTier.tier_order,
      gross_commission: cappedCommission,
      vat_rate: this.getVATRate(rule),
      vat_amount: vatAmount,
      net_commission: netCommission,
      method: `Tier ${applicableTier.tier_order}: ${applicableTier.description || 'No description'}`
    };
  }

  private static calculateHybridCommissionEnhanced(rule: AdvancedCommissionRule, baseAmount: number) {
    const fixedPart = rule.fixed_amount || 0;
    const percentagePart = (rule.base_rate || 0) * baseAmount;
    const totalGross = fixedPart + percentagePart;
    const cappedCommission = this.applyMinMaxConstraints(totalGross, rule);
    
    const { vatAmount, netCommission } = this.calculateVATEnhanced(cappedCommission, rule);

    return {
      base_amount: baseAmount,
      applied_rate: rule.base_rate,
      gross_commission: cappedCommission,
      vat_rate: this.getVATRate(rule),
      vat_amount: vatAmount,
      net_commission: netCommission,
      method: `Hybrid: ${fixedPart.toLocaleString()} fixed + ${((rule.base_rate || 0) * 100).toFixed(2)}% of ${baseAmount.toLocaleString()}`
    };
  }

  private static findApplicableTier(tiers: CommissionTier[], amount: number): CommissionTier | null {
    for (const tier of tiers) {
      const aboveMin = amount >= tier.min_threshold;
      const belowMax = !tier.max_threshold || amount <= tier.max_threshold;
      if (aboveMin && belowMax) {
        return tier;
      }
    }
    return null;
  }

  private static applyMinMaxConstraints(amount: number, rule: AdvancedCommissionRule): number {
    let result = amount;
    
    if (rule.min_amount && result < rule.min_amount) {
      result = rule.min_amount;
    }
    
    if (rule.max_amount && result > rule.max_amount) {
      result = rule.max_amount;
    }
    
    return result;
  }

  private static calculateVATEnhanced(grossAmount: number, rule: AdvancedCommissionRule): {
    vatAmount: number;
    netCommission: number;
  } {
    const vatRate = this.getVATRate(rule);
    const vatMode = (rule as any).vat_mode || 'added';
    
    let vatAmount: number;
    let netCommission: number;
    
    if (vatMode === 'included') {
      // VAT included: total = gross, vat = total × rate / (1 + rate), net = total - vat
      vatAmount = grossAmount * vatRate / (1 + vatRate);
      netCommission = grossAmount - vatAmount;
    } else {
      // VAT added: net = gross, vat = gross × rate, total = gross + vat
      netCommission = grossAmount;
      vatAmount = grossAmount * vatRate;
    }
    
    return {
      vatAmount: Math.round(vatAmount * 100) / 100,
      netCommission: Math.round(netCommission * 100) / 100
    };
  }

  private static getVATRate(rule: AdvancedCommissionRule): number {
    // Enhanced VAT rate lookup - could be extended to use vat_rate_table
    const vatTable = (rule as any).vat_rate_table;
    
    switch (vatTable) {
      case 'IL_STANDARD':
        return 0.17; // Israel standard VAT
      case 'US_STANDARD':
        return 0.0875; // US average sales tax
      case 'EU_STANDARD':
        return 0.21; // EU standard VAT
      default:
        return 0.21; // Default
    }
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
        return rule.entity_name || '';
    }
  }

  private static createResult(rule: AdvancedCommissionRule, context: CalculationContext, applicable: boolean, error?: string, executionTime?: number): CalculationResult {
    return {
      rule_id: rule.id,
      entity_type: rule.entity_type,
      entity_name: this.getEntityName(rule, context),
      applicable,
      execution_time_ms: Math.round(executionTime || 0),
      error
    };
  }
}