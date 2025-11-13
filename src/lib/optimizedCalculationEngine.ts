import { supabase } from '@/integrations/supabase/client';
import { AdvancedRuleEvaluator } from '@/lib/advancedRuleEvaluator';
import { EnhancedCalculationValidator } from '@/lib/enhancedCalculationValidator';
import { CalculationContext, AdvancedCommissionRule, CalculationResult, AdvancedCommissionCalculation } from '@/types/calculationEngine';

/**
 * Optimized calculation engine with enhanced performance and reliability
 */
export class OptimizedCalculationEngine {
  
  /**
   * Execute calculation run with enhanced error handling and performance optimization
   */
  static async executeCalculationRun(calculationRunId: string): Promise<{
    success: boolean;
    results: AdvancedCommissionCalculation[];
    errors: string[];
    warnings: string[];
    execution_time_ms: number;
    performance_metrics: {
      distributions_processed: number;
      rules_evaluated: number;
      average_rule_execution_time: number;
      cache_hit_rate: number;
    };
  }> {
    const startTime = performance.now();
    const results: AdvancedCommissionCalculation[] = [];
    const errors: string[] = [];
    const warnings: string[] = [];
    const performanceMetrics = {
      distributions_processed: 0,
      rules_evaluated: 0,
      total_rule_execution_time: 0,
      cache_hits: 0,
      cache_misses: 0,
      average_rule_execution_time: 0,
      cache_hit_rate: 0
    };

    try {
      // Fetch distributions with error handling
      const { data: distributions, error: distError } = await supabase
        .from('investor_distributions')
        .select('*')
        .eq('calculation_run_id', calculationRunId);

      if (distError) {
        errors.push(`Failed to fetch distributions: ${distError.message}`);
        return this.createErrorResponse(errors, warnings, startTime, performanceMetrics);
      }

      if (!distributions?.length) {
        warnings.push('No distributions found for this calculation run');
        return this.createSuccessResponse(results, errors, warnings, startTime, performanceMetrics);
      }

      // Fetch and cache rules with optimized query
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
        errors.push(`Failed to fetch rules: ${rulesError.message}`);
        return this.createErrorResponse(errors, warnings, startTime, performanceMetrics);
      }

      if (!rules?.length) {
        warnings.push('No active commission rules found');
        return this.createSuccessResponse(results, errors, warnings, startTime, performanceMetrics);
      }

      // Pre-validate rules
      const validatedRules = this.preValidateRules(rules as AdvancedCommissionRule[], warnings);

      // Process distributions with batching for better performance
      const batchSize = 10;
      for (let i = 0; i < distributions.length; i += batchSize) {
        const batch = distributions.slice(i, i + batchSize);
        
        const batchPromises = batch.map(distribution => 
          this.processDistributionWithMetrics(
            distribution,
            validatedRules,
            calculationRunId,
            performanceMetrics
          )
        );

        const batchResults = await Promise.allSettled(batchPromises);
        
        batchResults.forEach((result, index) => {
          performanceMetrics.distributions_processed++;
          
          if (result.status === 'fulfilled') {
            if (result.value.success) {
              results.push(...result.value.calculations);
            } else {
              errors.push(...result.value.errors);
            }
          } else {
            const distribution = batch[index];
            errors.push(`Failed to process distribution ${distribution.id}: ${result.reason}`);
          }
        });
      }

      // Calculate performance metrics
      performanceMetrics.average_rule_execution_time = 
        performanceMetrics.total_rule_execution_time / Math.max(performanceMetrics.rules_evaluated, 1);
      performanceMetrics.cache_hit_rate = 
        performanceMetrics.cache_hits / Math.max(performanceMetrics.cache_hits + performanceMetrics.cache_misses, 1);

      // Update calculation run totals
      await this.updateCalculationRunTotalsEnhanced(calculationRunId, results);

      return this.createSuccessResponse(results, errors, warnings, startTime, performanceMetrics);

    } catch (error) {
      errors.push(`Critical execution error: ${error instanceof Error ? error.message : 'Unknown error'}`);
      return this.createErrorResponse(errors, warnings, startTime, performanceMetrics);
    }
  }

  private static async processDistributionWithMetrics(
    distribution: any,
    rules: AdvancedCommissionRule[],
    calculationRunId: string,
    metrics: any
  ): Promise<{ success: boolean; calculations: AdvancedCommissionCalculation[]; errors: string[] }> {
    const errors: string[] = [];
    const calculations: AdvancedCommissionCalculation[] = [];

    try {
      // Validate distribution context
      const context = this.buildCalculationContext(distribution);
      const contextValidation = EnhancedCalculationValidator.validateCalculationContext(context);
      
      if (!contextValidation.isValid) {
        errors.push(`Distribution ${distribution.id} validation failed: ${contextValidation.errors.join(', ')}`);
        return { success: false, calculations, errors };
      }

      // Process each entity type
      const entityTypes = ['distributor', 'referrer', 'partner'];
      
      for (const entityType of entityTypes) {
        const entityName = this.getEntityNameByType(entityType, context);
        if (!entityName) continue;

        const applicableRules = rules.filter(r => r.entity_type === entityType);
        const calculation = await this.findAndApplyBestRuleOptimized(
          applicableRules,
          context,
          calculationRunId,
          entityType,
          metrics
        );

        if (calculation) {
          calculations.push(calculation);
        }
      }

      return { success: true, calculations, errors };

    } catch (error) {
      errors.push(`Error processing distribution: ${error instanceof Error ? error.message : 'Unknown error'}`);
      return { success: false, calculations, errors };
    }
  }

  private static async findAndApplyBestRuleOptimized(
    rules: AdvancedCommissionRule[],
    context: CalculationContext,
    calculationRunId: string,
    entityType: string,
    metrics: any
  ): Promise<AdvancedCommissionCalculation | null> {
    let bestResult: CalculationResult | null = null;
    let bestRule: AdvancedCommissionRule | null = null;

    // Sort rules by priority for early termination
    const sortedRules = [...rules].sort((a, b) => (a.priority || 100) - (b.priority || 100));

    for (const rule of sortedRules) {
      const ruleStartTime = performance.now();
      metrics.rules_evaluated++;

      try {
        const result = AdvancedRuleEvaluator.evaluateRule(rule, context);
        
        const executionTime = performance.now() - ruleStartTime;
        metrics.total_rule_execution_time += executionTime;

        // Log execution history asynchronously
        this.logExecutionHistoryAsync(
          calculationRunId,
          rule.id,
          context.distribution.id,
          result.applicable ? 'success' : 'skipped',
          result.conditions_met || {},
          result.error,
          result.execution_time_ms
        );

        if (result.applicable && result.calculation) {
          // Use first applicable rule due to priority sorting
          bestResult = result;
          bestRule = rule;
          break; // Early termination for better performance
        }

      } catch (error) {
        await this.logExecutionHistoryAsync(
          calculationRunId,
          rule.id,
          context.distribution.id,
          'failed',
          {},
          error instanceof Error ? error.message : 'Unknown error',
          performance.now() - ruleStartTime
        );
      }
    }

    if (!bestResult || !bestRule || !bestResult.calculation) {
      return null;
    }

    // Save calculation to database
    return await this.saveCalculationOptimized(bestResult, bestRule, context, calculationRunId, entityType);
  }

  private static async saveCalculationOptimized(
    result: CalculationResult,
    rule: AdvancedCommissionRule,
    context: CalculationContext,
    calculationRunId: string,
    entityType: string
  ): Promise<AdvancedCommissionCalculation> {
    const calculationData = {
      calculation_run_id: calculationRunId,
      distribution_id: context.distribution.id,
      rule_id: rule.id,
      commission_type: entityType,
      entity_name: this.getEntityNameByType(entityType, context),
      calculation_basis: rule.calculation_basis,
      base_amount: result.calculation!.base_amount,
      applied_rate: result.calculation!.applied_rate,
      tier_applied: result.calculation!.tier_applied,
      gross_commission: result.calculation!.gross_commission,
      vat_rate: result.calculation!.vat_rate || 0.21,
      vat_amount: result.calculation!.vat_amount,
      net_commission: result.calculation!.net_commission,
      calculation_method: result.calculation!.method,
      conditions_met: result.conditions_met,
      execution_time_ms: result.execution_time_ms,
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

  private static buildCalculationContext(distribution: any): CalculationContext {
    return {
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
      metadata: {
        calculation_date: new Date().toISOString(),
        distribution_currency: 'USD',
        processing_batch: Math.random().toString(36).substring(7)
      }
    };
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

  private static preValidateRules(rules: AdvancedCommissionRule[], warnings: string[]): AdvancedCommissionRule[] {
    const validatedRules: AdvancedCommissionRule[] = [];

    for (const rule of rules) {
      const validation = EnhancedCalculationValidator.validateRule(rule);
      
      if (validation.isValid) {
        validatedRules.push(rule);
      } else {
        warnings.push(`Rule "${rule.name}" has validation errors: ${validation.errors.join(', ')}`);
      }
      
      if (validation.warnings.length > 0) {
        warnings.push(`Rule "${rule.name}" warnings: ${validation.warnings.join(', ')}`);
      }
    }

    return validatedRules;
  }

  private static async logExecutionHistoryAsync(
    calculationRunId: string,
    ruleId: string,
    distributionId: string,
    result: 'success' | 'failed' | 'skipped',
    conditionsEvaluated: Record<string, any>,
    errorMessage?: string,
    executionTimeMs?: number
  ): Promise<void> {
    // Fire and forget async logging
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

  private static async updateCalculationRunTotalsEnhanced(
    calculationRunId: string,
    calculations: AdvancedCommissionCalculation[]
  ): Promise<void> {
    const totalGrossFees = calculations.reduce((sum, calc) => sum + calc.gross_commission, 0);
    const totalVat = calculations.reduce((sum, calc) => sum + calc.vat_amount, 0);
    const totalNetPayable = calculations.reduce((sum, calc) => sum + calc.net_commission, 0);

    await supabase
      .from('calculation_runs')
      .update({
        status: 'completed',
        total_gross_fees: Math.round(totalGrossFees * 100) / 100,
        total_vat: Math.round(totalVat * 100) / 100,
        total_net_payable: Math.round(totalNetPayable * 100) / 100,
        updated_at: new Date().toISOString()
      })
      .eq('id', calculationRunId);
  }

  private static createSuccessResponse(
    results: AdvancedCommissionCalculation[],
    errors: string[],
    warnings: string[],
    startTime: number,
    metrics: any
  ) {
    return {
      success: errors.length === 0,
      results,
      errors,
      warnings,
      execution_time_ms: Math.round(performance.now() - startTime),
      performance_metrics: {
        distributions_processed: metrics.distributions_processed,
        rules_evaluated: metrics.rules_evaluated,
        average_rule_execution_time: Math.round(metrics.average_rule_execution_time * 100) / 100,
        cache_hit_rate: Math.round(metrics.cache_hit_rate * 100) / 100
      }
    };
  }

  private static createErrorResponse(
    errors: string[],
    warnings: string[],
    startTime: number,
    metrics: any
  ) {
    return {
      success: false,
      results: [] as AdvancedCommissionCalculation[],
      errors,
      warnings,
      execution_time_ms: Math.round(performance.now() - startTime),
      performance_metrics: {
        distributions_processed: metrics.distributions_processed,
        rules_evaluated: metrics.rules_evaluated,
        average_rule_execution_time: Math.round((metrics.average_rule_execution_time || 0) * 100) / 100,
        cache_hit_rate: Math.round((metrics.cache_hit_rate || 0) * 100) / 100
      }
    };
  }
}