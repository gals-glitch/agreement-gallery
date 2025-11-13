import { useState, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { OptimizedCalculationEngine } from '@/lib/optimizedCalculationEngine';
import { AdvancedCommissionRule, AdvancedCommissionCalculation } from '@/types/calculationEngine';

export interface CalculationRun {
  id: string;
  name: string;
  period_start: string;
  period_end: string;
  status: 'draft' | 'calculating' | 'completed' | 'approved';
  total_gross_fees: number;
  total_vat: number;
  total_net_payable: number;
  created_at: string;
  updated_at: string;
}

export interface InvestorDistribution {
  id: string;
  calculation_run_id: string;
  investor_name: string;
  fund_name?: string;
  distribution_amount: number;
  distributor_name?: string;
  referrer_name?: string;
  partner_name?: string;
  distribution_date?: string;
  created_at: string;
}

export function useAdvancedCommissionCalculations() {
  const [calculationRuns, setCalculationRuns] = useState<CalculationRun[]>([]);
  const [distributions, setDistributions] = useState<InvestorDistribution[]>([]);
  const [commissionRules, setCommissionRules] = useState<AdvancedCommissionRule[]>([]);
  const [calculations, setCalculations] = useState<AdvancedCommissionCalculation[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      setLoading(true);
      const [runsResponse, rulesResponse] = await Promise.all([
        supabase.from('calculation_runs').select('*').order('created_at', { ascending: false }),
        supabase.from('advanced_commission_rules').select(`
          *,
          commission_tiers(*),
          rule_conditions(*)
        `).eq('is_active', true)
      ]);

      if (runsResponse.error) throw runsResponse.error;
      if (rulesResponse.error) throw rulesResponse.error;

      setCalculationRuns((runsResponse.data as CalculationRun[]) || []);
      setCommissionRules((rulesResponse.data as AdvancedCommissionRule[]) || []);
    } catch (error) {
      console.error('Error fetching data:', error);
    } finally {
      setLoading(false);
    }
  };

  const createCalculationRun = async (data: {
    name: string;
    period_start: string;
    period_end: string;
    scope_type?: string;
    scope_filters?: any;
  }) => {
    try {
      const { data: fnData, error } = await supabase.functions.invoke('create-calculation-run', {
        body: data,
      });

      if (error) throw error;
      const newRun = (fnData as any)?.run as CalculationRun;
      if (!newRun) throw new Error('No run returned from server');

      setCalculationRuns(prev => [newRun, ...prev]);
      return newRun;
    } catch (error) {
      console.error('Error creating calculation run:', error);
      throw error;
    }
  };

  const fetchDistributions = async (calculationRunId: string) => {
    try {
      const { data, error } = await supabase
        .from('investor_distributions')
        .select('*')
        .eq('calculation_run_id', calculationRunId)
        .order('created_at', { ascending: false });

      if (error) throw error;
      setDistributions((data as InvestorDistribution[]) || []);
      return data || [];
    } catch (error) {
      console.error('Error fetching distributions:', error);
      throw error;
    }
  };

  const runCommissionCalculations = async (calculationRunId: string) => {
    try {
      // Clear existing calculations for this run
      await supabase
        .from('advanced_commission_calculations')
        .delete()
        .eq('calculation_run_id', calculationRunId);

      // Get distribution data for this calculation run
      const { data: distributions } = await supabase
        .from('investor_distributions')
        .select('*')
        .eq('calculation_run_id', calculationRunId);

      // Use the optimized calculation engine
      const result = await OptimizedCalculationEngine.executeCalculationRun(calculationRunId);
      
      if (!result.success) {
        throw new Error(`Calculation failed: ${result.errors.join(', ')}`);
      }

      // Refresh data
      await fetchCalculations(calculationRunId);
      await fetchData();
      
      return {
        calculations: result.results,
        performance_metrics: result.performance_metrics,
        warnings: result.warnings
      };
    } catch (error) {
      console.error('Error running calculations:', error);
      throw error;
    }
  };

  const fetchCalculations = async (calculationRunId: string) => {
    try {
      const { data, error } = await supabase
        .from('advanced_commission_calculations')
        .select('*')
        .eq('calculation_run_id', calculationRunId)
        .order('created_at', { ascending: false });

      if (error) throw error;
      setCalculations((data as AdvancedCommissionCalculation[]) || []);
      return data || [];
    } catch (error) {
      console.error('Error fetching calculations:', error);
      throw error;
    }
  };

  const approveCalculation = async (calculationRunId: string) => {
    try {
      const { error } = await supabase
        .from('calculation_runs')
        .update({ status: 'approved' })
        .eq('id', calculationRunId);

      if (error) throw error;
      await fetchData();
    } catch (error) {
      console.error('Error approving calculation:', error);
      throw error;
    }
  };

  const createCommissionRule = async (ruleData: Partial<AdvancedCommissionRule>) => {
    try {
      // Simplified validation for now - proper validation would be in EnhancedCalculationEngine
      if (!ruleData.name || !ruleData.entity_type || !ruleData.rule_type) {
        throw new Error('Rule validation failed: missing required fields');
      }

      const { data: newRule, error } = await supabase
        .from('advanced_commission_rules')
        .insert([ruleData as any]) // Type assertion for insert
        .select(`
          *,
          commission_tiers(*),
          rule_conditions(*)
        `)
        .single();

      if (error) throw error;
      
      setCommissionRules(prev => [newRule as AdvancedCommissionRule, ...prev]);
      return newRule;
    } catch (error) {
      console.error('Error creating commission rule:', error);
      throw error;
    }
  };

  const updateCommissionRule = async (ruleId: string, updates: Partial<AdvancedCommissionRule>) => {
    try {
      const { data: updatedRule, error } = await supabase
        .from('advanced_commission_rules')
        .update(updates)
        .eq('id', ruleId)
        .select(`
          *,
          commission_tiers(*),
          rule_conditions(*)
        `)
        .single();

      if (error) throw error;
      
      setCommissionRules(prev => 
        prev.map(rule => rule.id === ruleId ? updatedRule as AdvancedCommissionRule : rule)
      );
      return updatedRule;
    } catch (error) {
      console.error('Error updating commission rule:', error);
      throw error;
    }
  };

  const deleteCommissionRule = async (ruleId: string) => {
    try {
      const { error } = await supabase
        .from('advanced_commission_rules')
        .delete()
        .eq('id', ruleId);

      if (error) throw error;
      
      setCommissionRules(prev => prev.filter(rule => rule.id !== ruleId));
    } catch (error) {
      console.error('Error deleting commission rule:', error);
      throw error;
    }
  };

  return {
    calculationRuns,
    distributions,
    commissionRules,
    calculations,
    loading,
    createCalculationRun,
    fetchDistributions,
    runCommissionCalculations,
    fetchCalculations,
    approveCalculation,
    createCommissionRule,
    updateCommissionRule,
    deleteCommissionRule,
    refetch: fetchData
  };
}