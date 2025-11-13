import { supabase } from '@/integrations/supabase/client';

export interface CalculationTrace {
  id: string;
  calculationId: string;
  ruleId?: string;
  inputData: any;
  formulaUsed: string;
  calculationResult: any;
  executionOrder: number;
  createdAt: string;
}

export interface SubAgent {
  id: string;
  distributorId: string;
  name: string;
  email: string;
  splitPercentage: number;
  isActive: boolean;
}

export interface EnhancedCalculationResult {
  primaryAmount: number;
  subAgentSplits: Array<{
    subAgentId: string;
    amount: number;
    percentage: number;
  }>;
  totalSplitPercentage: number;
  traces: CalculationTrace[];
  exceptions: string[];
}

export class EnhancedCalculationEngine {
  
  /**
   * Calculate commissions with full support for multiple rules per distributor
   * and sub-agent splits
   */
  static async calculateDistributorCommissions(
    distributorId: string,
    distributionData: any[],
    calculationRunId: string
  ): Promise<EnhancedCalculationResult> {
    const result: EnhancedCalculationResult = {
      primaryAmount: 0,
      subAgentSplits: [],
      totalSplitPercentage: 0,
      traces: [],
      exceptions: []
    };

    try {
      // Get all active rules for this distributor
      const { data: distributorRules, error: rulesError } = await supabase
        .from('distributor_rules')
        .select(`
          *,
          rule:advanced_commission_rules!rule_id (*)
        `)
        .eq('distributor_id', distributorId)
        .eq('is_active', true)
        .order('priority', { ascending: true });

      if (rulesError) {
        result.exceptions.push(`Failed to fetch rules: ${rulesError.message}`);
        return result;
      }

      // Get sub-agents for this distributor
      const { data: subAgents, error: subAgentsError } = await supabase
        .from('sub_agents')
        .select('*')
        .eq('distributor_id', distributorId)
        .eq('is_active', true);

      if (subAgentsError) {
        result.exceptions.push(`Failed to fetch sub-agents: ${subAgentsError.message}`);
      }

      // Validate total split percentage
      const totalSplitPercentage = (subAgents || []).reduce(
        (sum, agent) => sum + agent.split_percentage, 
        0
      );

      if (totalSplitPercentage > 100) {
        result.exceptions.push(
          `Sub-agent split percentages total ${totalSplitPercentage}%, exceeding 100%`
        );
      }

      result.totalSplitPercentage = totalSplitPercentage;

      // Process each distribution through all applicable rules
      let totalCommission = 0;
      let executionOrder = 1;

      for (const distribution of distributionData) {
        for (const distributorRule of distributorRules || []) {
          const rule = distributorRule.rule;
          
          if (!rule || !rule.is_active) continue;

          // Check if rule conditions are met
          const conditionsResult = await this.evaluateRuleConditions(rule, distribution);
          
          const trace: CalculationTrace = {
            id: `trace_${Date.now()}_${executionOrder}`,
            calculationId: calculationRunId,
            ruleId: rule.id,
            inputData: {
              distribution,
              rule: rule,
              conditionsMet: conditionsResult.met
            },
            formulaUsed: '',
            calculationResult: { amount: 0, conditions: conditionsResult },
            executionOrder: executionOrder++,
            createdAt: new Date().toISOString()
          };

          if (conditionsResult.met) {
            // Calculate commission based on rule type
            const commissionAmount = await this.calculateRuleCommission(rule, distribution);
            
            trace.formulaUsed = this.generateFormulaDescription(rule, distribution);
            trace.calculationResult.amount = commissionAmount;
            
            totalCommission += commissionAmount;

            // Handle timing-based calculations
            if (rule.timing_mode === 'on-event') {
              // Add lag days for on-event payments
              const payableDate = new Date();
              payableDate.setDate(payableDate.getDate() + (rule.lag_days || 30));
              trace.calculationResult.payableDate = payableDate.toISOString();
            }
          } else {
            trace.formulaUsed = 'Rule conditions not met';
            result.exceptions.push(
              `Rule "${rule.name}" conditions not met for distribution ${distribution.id}: ${conditionsResult.reason}`
            );
          }

          result.traces.push(trace);
        }
      }

      result.primaryAmount = totalCommission;

      // Calculate sub-agent splits
      if (subAgents && subAgents.length > 0) {
        for (const subAgent of subAgents) {
          const splitAmount = (totalCommission * subAgent.split_percentage) / 100;
          result.subAgentSplits.push({
            subAgentId: subAgent.id,
            amount: splitAmount,
            percentage: subAgent.split_percentage
          });
        }

        // Adjust primary amount to account for sub-agent splits
        const totalSubAgentAmount = result.subAgentSplits.reduce(
          (sum, split) => sum + split.amount, 
          0
        );
        result.primaryAmount = totalCommission - totalSubAgentAmount;
      }

      // Persist calculation traces
      await this.persistCalculationTraces(result.traces);

    } catch (error) {
      result.exceptions.push(`Calculation engine error: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }

    return result;
  }

  /**
   * Evaluate rule conditions against distribution data
   */
  private static async evaluateRuleConditions(rule: any, distribution: any): Promise<{
    met: boolean;
    reason: string;
  }> {
    try {
      // Get rule conditions
      const { data: conditions, error } = await supabase
        .from('rule_conditions')
        .select('*')
        .eq('rule_id', rule.id);

      if (error) {
        return { met: false, reason: `Failed to fetch conditions: ${error.message}` };
      }

      if (!conditions || conditions.length === 0) {
        return { met: true, reason: 'No conditions specified' };
      }

      // Evaluate all conditions
      for (const condition of conditions) {
        const fieldValue = distribution[condition.field_name];
        let conditionMet = false;

        switch (condition.operator) {
          case 'equals':
            conditionMet = fieldValue === condition.value_text || 
                          fieldValue === condition.value_number;
            break;
          case 'greater_than':
            conditionMet = fieldValue > condition.value_number;
            break;
          case 'less_than':
            conditionMet = fieldValue < condition.value_number;
            break;
          case 'in':
            conditionMet = condition.value_array?.includes(fieldValue);
            break;
          case 'greater_equal':
            conditionMet = fieldValue >= condition.value_number;
            break;
          case 'less_equal':
            conditionMet = fieldValue <= condition.value_number;
            break;
          default:
            conditionMet = false;
        }

        if (condition.is_required && !conditionMet) {
          return { 
            met: false, 
            reason: `Required condition failed: ${condition.field_name} ${condition.operator} ${condition.value_text || condition.value_number || condition.value_date}` 
          };
        }
      }

      return { met: true, reason: 'All conditions met' };
    } catch (error) {
      return { 
        met: false, 
        reason: `Error evaluating conditions: ${error instanceof Error ? error.message : 'Unknown error'}` 
      };
    }
  }

  /**
   * Calculate commission amount based on rule configuration
   */
  private static async calculateRuleCommission(rule: any, distribution: any): Promise<number> {
    const baseAmount = distribution.distribution_amount || 0;
    
    if (rule.rule_type === 'fixed_amount') {
      return rule.fixed_amount || 0;
    }
    
    if (rule.rule_type === 'percentage') {
      const commission = baseAmount * (rule.base_rate || 0) / 100;
      
      // Apply min/max constraints
      if (rule.min_amount && commission < rule.min_amount) {
        return rule.min_amount;
      }
      if (rule.max_amount && commission > rule.max_amount) {
        return rule.max_amount;
      }
      
      return commission;
    }
    
    if (rule.rule_type === 'tiered') {
      return await this.calculateTieredCommission(rule.id, baseAmount);
    }
    
    return 0;
  }

  /**
   * Calculate tiered commission using commission_tiers table
   */
  private static async calculateTieredCommission(ruleId: string, amount: number): Promise<number> {
    try {
      const { data: tiers, error } = await supabase
        .from('commission_tiers')
        .select('*')
        .eq('rule_id', ruleId)
        .order('tier_order', { ascending: true });

      if (error || !tiers) return 0;

      let totalCommission = 0;
      let remainingAmount = amount;

      for (const tier of tiers) {
        if (remainingAmount <= 0) break;

        const tierAmount = Math.min(
          remainingAmount,
          (tier.max_threshold || Infinity) - tier.min_threshold
        );

        if (tierAmount > 0) {
          totalCommission += (tierAmount * tier.rate / 100) + (tier.fixed_amount || 0);
          remainingAmount -= tierAmount;
        }
      }

      return totalCommission;
    } catch (error) {
      return 0;
    }
  }

  /**
   * Generate human-readable formula description
   */
  private static generateFormulaDescription(rule: any, distribution: any): string {
    const baseAmount = distribution.distribution_amount || 0;
    
    if (rule.rule_type === 'fixed_amount') {
      return `Fixed Amount: $${rule.fixed_amount}`;
    }
    
    if (rule.rule_type === 'percentage') {
      return `${rule.base_rate}% of $${baseAmount} = $${(baseAmount * rule.base_rate / 100).toFixed(2)}`;
    }
    
    if (rule.rule_type === 'tiered') {
      return `Tiered calculation on $${baseAmount}`;
    }
    
    return 'Unknown calculation method';
  }

  /**
   * Persist calculation traces to database
   */
  private static async persistCalculationTraces(traces: CalculationTrace[]): Promise<void> {
    try {
      const { error } = await supabase
        .from('calculation_traces')
        .insert(
          traces.map(trace => ({
            calculation_id: trace.calculationId,
            rule_id: trace.ruleId,
            input_data: trace.inputData,
            formula_used: trace.formulaUsed,
            calculation_result: trace.calculationResult,
            execution_order: trace.executionOrder
          }))
        );

      if (error) {
        console.error('Failed to persist calculation traces:', error);
      }
    } catch (error) {
      console.error('Error persisting traces:', error);
    }
  }

  /**
   * Handle exception scenarios
   */
  static async handleCalculationExceptions(
    distributionData: any[],
    calculationRunId: string
  ): Promise<string[]> {
    const exceptions: string[] = [];

    for (const distribution of distributionData) {
      // Check for missing investor linkage
      if (!distribution.investor_name || distribution.investor_name.trim() === '') {
        exceptions.push(`Distribution ${distribution.id}: Missing investor name`);
      }

      // Check for missing rules
      const { data: rules, error } = await supabase
        .from('advanced_commission_rules')
        .select('id')
        .eq('entity_name', distribution.distributor_name)
        .eq('is_active', true);

      if (error || !rules || rules.length === 0) {
        exceptions.push(`Distribution ${distribution.id}: No active rules found for distributor ${distribution.distributor_name}`);
      }

      // Check for date range mismatches
      const distributionDate = new Date(distribution.distribution_date);
      if (rules) {
        for (const rule of rules) {
          const { data: ruleDetails } = await supabase
            .from('advanced_commission_rules')
            .select('effective_from, effective_to')
            .eq('id', rule.id)
            .single();

          if (ruleDetails) {
            const effectiveFrom = ruleDetails.effective_from ? new Date(ruleDetails.effective_from) : null;
            const effectiveTo = ruleDetails.effective_to ? new Date(ruleDetails.effective_to) : null;

            if (effectiveFrom && distributionDate < effectiveFrom) {
              exceptions.push(`Distribution ${distribution.id}: Date ${distribution.distribution_date} is before rule effective date`);
            }

            if (effectiveTo && distributionDate > effectiveTo) {
              exceptions.push(`Distribution ${distribution.id}: Date ${distribution.distribution_date} is after rule expiry date`);
            }
          }
        }
      }
    }

    return exceptions;
  }

  /**
   * Execute a complete calculation run for multiple distributors
   */
  static async executeCalculationRun(
    calculationRunId: string,
    distributionData: any[]
  ): Promise<{
    success: boolean;
    results: EnhancedCalculationResult[];
    totalExceptions: string[];
  }> {
    const results: EnhancedCalculationResult[] = [];
    const totalExceptions: string[] = [];

    try {
      // Get all unique distributors from the distribution data
      const distributorNames = [...new Set(distributionData.map(d => d.distributor_name))];
      
      for (const distributorName of distributorNames) {
        // Find distributor entity
        const { data: distributor } = await supabase
          .from('entities')
          .select('id')
          .eq('name', distributorName)
          .eq('entity_type', 'distributor')
          .single();

        if (!distributor) {
          totalExceptions.push(`Distributor not found: ${distributorName}`);
          continue;
        }

        // Get distributions for this distributor
        const distributorData = distributionData.filter(d => d.distributor_name === distributorName);
        
        // Calculate commissions for this distributor
        const result = await this.calculateDistributorCommissions(
          distributor.id,
          distributorData,
          calculationRunId
        );

        results.push(result);
        totalExceptions.push(...result.exceptions);
      }

      return {
        success: totalExceptions.length === 0,
        results,
        totalExceptions
      };
    } catch (error) {
      totalExceptions.push(`Execution error: ${error instanceof Error ? error.message : 'Unknown error'}`);
      return {
        success: false,
        results,
        totalExceptions
      };
    }
  }
}