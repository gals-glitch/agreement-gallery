import { AdvancedCommissionRule, CalculationContext } from '@/types/calculationEngine';

export interface ValidationResult {
  isValid: boolean;
  errors: string[];
  warnings: string[];
  suggestions: string[];
}

export interface CalculationPreview {
  estimatedCommission: number;
  applicableRules: number;
  potentialIssues: string[];
  expectedExecutionTime: number;
}

/**
 * Enhanced validation and preview system for calculation logic
 */
export class EnhancedCalculationValidator {
  
  /**
   * Validate a rule configuration comprehensively
   */
  static validateRule(rule: Partial<AdvancedCommissionRule>): ValidationResult {
    const result: ValidationResult = {
      isValid: true,
      errors: [],
      warnings: [],
      suggestions: []
    };

    // Required field validation
    this.validateRequiredFields(rule, result);
    
    // Rule type specific validation
    this.validateRuleTypeConfiguration(rule, result);
    
    // Date logic validation
    this.validateDateLogic(rule, result);
    
    // Rate and amount validation
    this.validateRatesAndAmounts(rule, result);
    
    // Tier validation for tiered rules
    this.validateTiers(rule, result);
    
    // Performance and optimization suggestions
    this.addOptimizationSuggestions(rule, result);
    
    result.isValid = result.errors.length === 0;
    return result;
  }

  private static validateRequiredFields(rule: Partial<AdvancedCommissionRule>, result: ValidationResult) {
    const requiredFields = ['name', 'rule_type', 'entity_type'];
    
    for (const field of requiredFields) {
      if (!rule[field as keyof AdvancedCommissionRule]) {
        result.errors.push(`Required field missing: ${field}`);
      }
    }

    // Entity name recommendations
    if (!rule.entity_name || this.isGenericEntityName(rule.entity_name)) {
      result.warnings.push('Generic entity name may apply to unintended entities');
      result.suggestions.push('Consider specifying a more specific entity name');
    }
  }

  private static validateRuleTypeConfiguration(rule: Partial<AdvancedCommissionRule>, result: ValidationResult) {
    switch (rule.rule_type) {
      case 'percentage':
        if (!rule.base_rate) {
          result.errors.push('Percentage rules require a base_rate');
        } else if (rule.base_rate < 0 || rule.base_rate > 1) {
          result.errors.push('Base rate must be between 0 and 1 (0% to 100%)');
        }
        break;
        
      case 'fixed_amount':
        if (!rule.fixed_amount) {
          result.errors.push('Fixed amount rules require a fixed_amount');
        } else if (rule.fixed_amount < 0) {
          result.errors.push('Fixed amount must be non-negative');
        }
        break;
        
      case 'tiered':
        if (!rule.tiers || rule.tiers.length === 0) {
          result.errors.push('Tiered rules require at least one tier');
        }
        break;
        
      case 'hybrid':
        if (!rule.base_rate && !rule.fixed_amount) {
          result.errors.push('Hybrid rules require either base_rate or fixed_amount (or both)');
        }
        break;
        
      default:
        result.errors.push(`Invalid rule type: ${rule.rule_type}`);
    }
  }

  private static validateDateLogic(rule: Partial<AdvancedCommissionRule>, result: ValidationResult) {
    if (rule.effective_from && rule.effective_to) {
      const from = new Date(rule.effective_from);
      const to = new Date(rule.effective_to);
      
      if (from >= to) {
        result.errors.push('Effective from date must be before effective to date');
      }
      
      const daysDifference = (to.getTime() - from.getTime()) / (1000 * 60 * 60 * 24);
      if (daysDifference < 1) {
        result.warnings.push('Very short effective period (less than 1 day)');
      }
      
      if (to < new Date()) {
        result.warnings.push('Rule effective period has already ended');
      }
    }

    // Lag days validation
    const lagDays = (rule as any).lag_days;
    if (lagDays !== undefined) {
      if (lagDays < 0) {
        result.errors.push('Lag days cannot be negative');
      } else if (lagDays > 365) {
        result.warnings.push('Lag days exceed one year - consider if this is intentional');
      }
    }
  }

  private static validateRatesAndAmounts(rule: Partial<AdvancedCommissionRule>, result: ValidationResult) {
    // Min/Max validation
    if (rule.min_amount !== undefined && rule.max_amount !== undefined) {
      if (rule.min_amount >= rule.max_amount) {
        result.errors.push('Minimum amount must be less than maximum amount');
      }
    }

    // Rate validation for percentage rules
    if (rule.rule_type === 'percentage' && rule.base_rate) {
      if (rule.base_rate > 0.5) {
        result.warnings.push('Base rate exceeds 50% - verify this is intentional');
      }
      
      if (rule.base_rate < 0.001) {
        result.warnings.push('Base rate is very low (less than 0.1%) - verify this is intentional');
      }
    }

    // Currency validation
    const currency = (rule as any).currency;
    if (currency && !this.isValidCurrency(currency)) {
      result.warnings.push(`Currency code "${currency}" may not be standard ISO format`);
    }
  }

  private static validateTiers(rule: Partial<AdvancedCommissionRule>, result: ValidationResult) {
    if (rule.rule_type !== 'tiered' || !rule.tiers) return;

    const tiers = rule.tiers;
    
    // Check for gaps or overlaps
    const sortedTiers = [...tiers].sort((a, b) => a.tier_order - b.tier_order);
    
    for (let i = 0; i < sortedTiers.length - 1; i++) {
      const currentTier = sortedTiers[i];
      const nextTier = sortedTiers[i + 1];
      
      if (currentTier.max_threshold && nextTier.min_threshold) {
        if (currentTier.max_threshold < nextTier.min_threshold) {
          result.warnings.push(`Gap between tier ${currentTier.tier_order} and ${nextTier.tier_order}`);
        } else if (currentTier.max_threshold > nextTier.min_threshold) {
          result.warnings.push(`Overlap between tier ${currentTier.tier_order} and ${nextTier.tier_order}`);
        }
      }
    }

    // Check for missing rates
    for (const tier of tiers) {
      if (!tier.rate && !tier.fixed_amount) {
        result.errors.push(`Tier ${tier.tier_order} must have either a rate or fixed amount`);
      }
      
      if (tier.rate && (tier.rate < 0 || tier.rate > 1)) {
        result.errors.push(`Tier ${tier.tier_order} rate must be between 0 and 1`);
      }
    }
  }

  private static addOptimizationSuggestions(rule: Partial<AdvancedCommissionRule>, result: ValidationResult) {
    // Priority optimization
    if (rule.priority === undefined || rule.priority === 100) {
      result.suggestions.push('Consider setting a specific priority for better rule ordering');
    }

    // Calculation basis optimization
    if (rule.calculation_basis === 'distribution_amount') {
      result.suggestions.push('Consider if cumulative calculations would be more appropriate');
    }

    // VAT mode suggestions
    const vatMode = (rule as any).vat_mode;
    if (!vatMode) {
      result.suggestions.push('Specify VAT mode (added/included) for clarity');
    }
  }

  /**
   * Preview calculation results before execution
   */
  static previewCalculation(rules: AdvancedCommissionRule[], context: CalculationContext): CalculationPreview {
    const preview: CalculationPreview = {
      estimatedCommission: 0,
      applicableRules: 0,
      potentialIssues: [],
      expectedExecutionTime: 0
    };

    const startTime = performance.now();
    
    for (const rule of rules) {
      try {
        // Quick applicability check
        if (this.isRuleQuicklyApplicable(rule, context)) {
          preview.applicableRules++;
          
          // Estimate commission
          const estimatedAmount = this.estimateCommission(rule, context);
          preview.estimatedCommission += estimatedAmount;
        }
      } catch (error) {
        preview.potentialIssues.push(`Rule ${rule.name}: ${error instanceof Error ? error.message : 'Unknown error'}`);
      }
    }

    preview.expectedExecutionTime = Math.round((performance.now() - startTime) * 2); // Estimate actual execution time
    
    return preview;
  }

  private static isRuleQuicklyApplicable(rule: AdvancedCommissionRule, context: CalculationContext): boolean {
    // Quick checks without full evaluation
    if (!rule.is_active) return false;
    
    // Entity check
    const entityName = this.getEntityNameByType(rule.entity_type, context);
    if (!entityName) return false;
    
    if (rule.entity_name && !this.isGenericEntityName(rule.entity_name)) {
      if (rule.entity_name !== entityName) return false;
    }
    
    // Date check
    if (context.distribution.distribution_date && rule.effective_from) {
      const distributionDate = new Date(context.distribution.distribution_date);
      const effectiveFrom = new Date(rule.effective_from);
      if (distributionDate < effectiveFrom) return false;
    }
    
    return true;
  }

  private static estimateCommission(rule: AdvancedCommissionRule, context: CalculationContext): number {
    const baseAmount = context.distribution.distribution_amount || 0;
    
    switch (rule.rule_type) {
      case 'percentage':
        return baseAmount * (rule.base_rate || 0);
      case 'fixed_amount':
        return rule.fixed_amount || 0;
      case 'tiered':
        // Estimate using first tier
        const firstTier = rule.tiers?.[0];
        if (firstTier) {
          return firstTier.fixed_amount || (baseAmount * firstTier.rate);
        }
        return 0;
      case 'hybrid':
        return (rule.fixed_amount || 0) + (baseAmount * (rule.base_rate || 0));
      default:
        return 0;
    }
  }

  private static getEntityNameByType(entityType: string, context: CalculationContext): string {
    switch (entityType) {
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

  private static isGenericEntityName(entityName: string): boolean {
    const genericPatterns = [
      'default', 'all', 'any', 'general', 'standard', 
      'default distributor', 'default referrer', 'default partner'
    ];
    return genericPatterns.includes(entityName.toLowerCase());
  }

  private static isValidCurrency(currency: string): boolean {
    const commonCurrencies = ['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'CHF', 'CNY', 'ILS'];
    return commonCurrencies.includes(currency.toUpperCase());
  }

  /**
   * Validate calculation context data
   */
  static validateCalculationContext(context: CalculationContext): ValidationResult {
    const result: ValidationResult = {
      isValid: true,
      errors: [],
      warnings: [],
      suggestions: []
    };

    // Distribution validation
    if (!context.distribution) {
      result.errors.push('Distribution data is required');
      return result;
    }

    if (!context.distribution.distribution_amount || context.distribution.distribution_amount <= 0) {
      result.errors.push('Distribution amount must be positive');
    }

    if (!context.distribution.investor_name) {
      result.warnings.push('Missing investor name');
    }

    if (!context.distribution.distribution_date) {
      result.warnings.push('Missing distribution date');
    } else {
      const distributionDate = new Date(context.distribution.distribution_date);
      if (distributionDate > new Date()) {
        result.warnings.push('Distribution date is in the future');
      }
    }

    // Historical data validation
    if (context.historical_data) {
      if (context.historical_data.cumulative_amount < context.distribution.distribution_amount) {
        result.warnings.push('Cumulative amount is less than current distribution amount');
      }
    } else {
      result.suggestions.push('Historical data would improve calculation accuracy');
    }

    result.isValid = result.errors.length === 0;
    return result;
  }
}