import { supabase } from '@/integrations/supabase/client';
import { RuleEvaluator } from '@/lib/ruleEvaluator';
import { CalculationContext, AdvancedCommissionRule, CalculationResult, AdvancedCommissionCalculation } from '@/types/calculationEngine';

export class AdvancedCalculationEngine {
  /**
   * Execute calculations for a specific calculation run
   */
  static async executeCalculationRun(calculationRunId: string): Promise<{
    success: boolean;
    results: AdvancedCommissionCalculation[];
    errors: string[];
    execution_time_ms: number;
  }> {
    const startTime = performance.now();
    const results: AdvancedCommissionCalculation[] = [];
    const errors: string[] = [];

    try {
      // Get all distributions for this run
      const { data: distributions, error: distError } = await supabase
        .from('investor_distributions')
        .select('*')
        .eq('calculation_run_id', calculationRunId);

      if (distError) {
        throw new Error(`Failed to fetch distributions: ${distError.message}`);
      }

      if (!distributions || distributions.length === 0) {
        return {
          success: false,
          results: [],
          errors: ['No distributions found for this calculation run'],
          execution_time_ms: Math.round(performance.now() - startTime)
        };
      }

      // Get all active rules
      const { data: rules, error: rulesError } = await supabase
        .from('advanced_commission_rules')
        .select(`
          *,
          commission_tiers(*),
          rule_conditions(*)
        `)
        .eq('is_active', true)
        .order('priority', { ascending: true });

      if (rulesError) {
        throw new Error(`Failed to fetch rules: ${rulesError.message}`);
      }

      if (!rules || rules.length === 0) {
        return {
          success: false,
          results: [],
          errors: ['No active commission rules found'],
          execution_time_ms: Math.round(performance.now() - startTime)
        };
      }

      // Process each distribution
      for (const distribution of distributions) {
        try {
          const distributionResults = await this.processDistribution(
            distribution,
            rules as AdvancedCommissionRule[],
            calculationRunId
          );
          results.push(...distributionResults);
        } catch (error) {
          const errorMsg = `Error processing distribution ${distribution.id}: ${error instanceof Error ? error.message : 'Unknown error'}`;
          errors.push(errorMsg);
          
          // Log to execution history
          await this.logExecutionHistory(
            calculationRunId,
            '',
            distribution.id,
            'failed',
            {},
            errorMsg,
            0
          );
        }
      }

      // Update calculation run totals
      await this.updateCalculationRunTotals(calculationRunId, results);

      return {
        success: errors.length === 0,
        results,
        errors,
        execution_time_ms: Math.round(performance.now() - startTime)
      };

    } catch (error) {
      return {
        success: false,
        results: [],
        errors: [error instanceof Error ? error.message : 'Unknown execution error'],
        execution_time_ms: Math.round(performance.now() - startTime)
      };
    }
  }

  private static async processDistribution(
    distribution: any,
    rules: AdvancedCommissionRule[],
    calculationRunId: string
  ): Promise<AdvancedCommissionCalculation[]> {
    const context: CalculationContext = {
      distribution,
      historical_data: {
        cumulative_amount: distribution.distribution_amount,
        cumulative_amount_ytd: distribution.distribution_amount,
        cumulative_amount_term: distribution.distribution_amount,
        deal_count: 1,
        monthly_volume: distribution.distribution_amount,
        quarterly_volume: distribution.distribution_amount,
        annual_volume: distribution.distribution_amount
      },
      metadata: {}
    };

    const calculations: AdvancedCommissionCalculation[] = [];

    // Process distributor rules
    if (distribution.distributor_name) {
      const distributorRules = rules.filter(r => r.entity_type === 'distributor');
      const distributorCalc = await this.findAndApplyBestRule(
        distributorRules,
        context,
        calculationRunId,
        'distributor'
      );
      if (distributorCalc) calculations.push(distributorCalc);
    }

    // Process referrer rules
    if (distribution.referrer_name) {
      const referrerRules = rules.filter(r => r.entity_type === 'referrer');
      const referrerCalc = await this.findAndApplyBestRule(
        referrerRules,
        context,
        calculationRunId,
        'referrer'
      );
      if (referrerCalc) calculations.push(referrerCalc);
    }

    // Process partner rules
    if (distribution.partner_name) {
      const partnerRules = rules.filter(r => r.entity_type === 'partner');
      const partnerCalc = await this.findAndApplyBestRule(
        partnerRules,
        context,
        calculationRunId,
        'partner'
      );
      if (partnerCalc) calculations.push(partnerCalc);
    }

    return calculations;
  }

  private static async findAndApplyBestRule(
    rules: AdvancedCommissionRule[],
    context: CalculationContext,
    calculationRunId: string,
    entityType: string
  ): Promise<AdvancedCommissionCalculation | null> {
    let bestResult: CalculationResult | null = null;
    let bestRule: AdvancedCommissionRule | null = null;

    // Evaluate all applicable rules
    for (const rule of rules) {
      const startTime = performance.now();
      const result = RuleEvaluator.evaluateRule(rule, context);
      
      // Log execution history
      await this.logExecutionHistory(
        calculationRunId,
        rule.id,
        context.distribution.id,
        result.applicable ? 'success' : 'skipped',
        result.conditions_met || {},
        result.error,
        result.execution_time_ms
      );

      // Select best applicable rule (highest priority = lowest priority number)
      if (result.applicable && result.calculation) {
        if (!bestResult || rule.priority < (bestRule?.priority || Infinity)) {
          bestResult = result;
          bestRule = rule;
        }
      }
    }

    // If no rule found, return null
    if (!bestResult || !bestRule || !bestResult.calculation) {
      return null;
    }

    // Save calculation to database
    const calculationData = {
      calculation_run_id: calculationRunId,
      distribution_id: context.distribution.id,
      rule_id: bestRule.id,
      commission_type: entityType,
      entity_name: this.getEntityName(entityType, context),
      calculation_basis: bestRule.calculation_basis,
      base_amount: bestResult.calculation.base_amount,
      applied_rate: bestResult.calculation.applied_rate,
      tier_applied: bestResult.calculation.tier_applied,
      gross_commission: bestResult.calculation.gross_commission,
      vat_rate: bestResult.calculation.vat_rate || 0.21,
      vat_amount: bestResult.calculation.vat_amount,
      net_commission: bestResult.calculation.net_commission,
      calculation_method: bestResult.calculation.method,
      conditions_met: bestResult.conditions_met,
      execution_time_ms: bestResult.execution_time_ms,
      status: 'calculated' as const
    };

    const { data: savedCalculation, error } = await supabase
      .from('advanced_commission_calculations')
      .insert([calculationData])
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to save calculation: ${error.message}`);
    }

    return savedCalculation as AdvancedCommissionCalculation;
  }

  private static getEntityName(entityType: string, context: CalculationContext): string {
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

  private static async getHistoricalData(distribution: any) {
    // This would fetch historical volume data for the entity
    // For now, return empty data - could be enhanced later
    return {
      cumulative_amount: distribution.distribution_amount,
      monthly_volume: distribution.distribution_amount,
      quarterly_volume: distribution.distribution_amount,
      annual_volume: distribution.distribution_amount
    };
  }

  private static async logExecutionHistory(
    calculationRunId: string,
    ruleId: string,
    distributionId: string,
    result: 'success' | 'failed' | 'skipped',
    conditionsEvaluated: Record<string, any>,
    errorMessage?: string,
    executionTimeMs?: number
  ) {
    try {
      await supabase
        .from('rule_execution_history')
        .insert([{
          calculation_run_id: calculationRunId,
          rule_id: ruleId || null,
          distribution_id: distributionId,
          execution_result: result,
          conditions_evaluated: conditionsEvaluated,
          error_message: errorMessage || null,
          execution_time_ms: executionTimeMs || 0
        }]);
    } catch (error) {
      console.error('Failed to log execution history:', error);
    }
  }

  private static async updateCalculationRunTotals(
    calculationRunId: string,
    calculations: AdvancedCommissionCalculation[]
  ) {
    const totalGrossFees = calculations.reduce((sum, calc) => sum + calc.gross_commission, 0);
    const totalVat = calculations.reduce((sum, calc) => sum + calc.vat_amount, 0);
    const totalNetPayable = calculations.reduce((sum, calc) => sum + calc.net_commission, 0);

    await supabase
      .from('calculation_runs')
      .update({
        status: 'completed',
        total_gross_fees: totalGrossFees,
        total_vat: totalVat,
        total_net_payable: totalNetPayable
      })
      .eq('id', calculationRunId);
  }

  /**
   * Validate a rule configuration
   */
  static validateRule(rule: Partial<AdvancedCommissionRule>): { valid: boolean; errors: string[] } {
    const errors: string[] = [];

    if (!rule.name) errors.push('Rule name is required');
    if (!rule.rule_type) errors.push('Rule type is required');
    if (!rule.entity_type) errors.push('Entity type is required');

    if (rule.rule_type === 'percentage' && !rule.base_rate) {
      errors.push('Base rate is required for percentage rules');
    }

    if (rule.rule_type === 'fixed_amount' && !rule.fixed_amount) {
      errors.push('Fixed amount is required for fixed amount rules');
    }

    if (rule.rule_type === 'tiered' && (!rule.tiers || rule.tiers.length === 0)) {
      errors.push('Tiers are required for tiered rules');
    }

    if (rule.effective_from && rule.effective_to) {
      const from = new Date(rule.effective_from);
      const to = new Date(rule.effective_to);
      if (from >= to) {
        errors.push('Effective from date must be before effective to date');
      }
    }

    return {
      valid: errors.length === 0,
      errors
    };
  }
}