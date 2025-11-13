import { CalculationContext, AdvancedCommissionRule, EnhancedCalculationResult } from '@/types/calculationEngine';
import { supabase } from '@/integrations/supabase/client';

export interface FundVDeferralConfig {
  defaultTotalRate: number; // 0.020 (2.0%)
  immediateRate: number;    // 0.012 (1.2%)
  deferralMonths: number;   // 24
  retroThreshold: number;   // 3,000,000
  retroTotalRate: number;   // 0.018 (1.8%)
}

export interface MFShareConfig {
  fund: string;
  year: number;
  mfPoolYear: number;
  isQuarterlyAccrual: boolean;
  firstYearStartDate?: string;
}

export class SpecializedCalculations {
  
  /**
   * Fund V Deferral Logic with Retroactive Threshold
   * Creates immediate (1.2%) and deferred (0.8% or 0.6%) commission lines
   * Handles $3M threshold with retroactive adjustment and true-up logic
   */
  static async calculateFundVDeferral(
    rule: AdvancedCommissionRule,
    context: CalculationContext,
    config: FundVDeferralConfig
  ): Promise<EnhancedCalculationResult[]> {
    const results: EnhancedCalculationResult[] = [];
    
    // Get cumulative contributions for this party in Fund V
    const cumulativeAmount = await this.getCumulativeContributions(
      rule.entity_name || '',
      'Fund V',
      context.distribution.distribution_date
    );
    
    const hitThreshold = cumulativeAmount >= config.retroThreshold;
    const totalRate = hitThreshold ? config.retroTotalRate : config.defaultTotalRate;
    const deferredRate = totalRate - config.immediateRate;
    
    const baseAmount = context.distribution.distribution_amount;
    const immediateAmount = baseAmount * config.immediateRate;
    const deferredAmount = baseAmount * deferredRate;
    
    // Create immediate line item
    results.push({
      rule_id: rule.id,
      entity_type: rule.entity_type,
      entity_name: rule.entity_name || '',
      applicable: true,
      calculation: {
        base_amount: baseAmount,
        applied_rate: config.immediateRate,
        gross_commission: immediateAmount,
        vat_rate: 0.21,
        vat_amount: immediateAmount * 0.21,
        net_commission: immediateAmount,
        method: 'fund_v_immediate'
      },
      execution_time_ms: 0,
      calculation_trace: {
        inputs: { baseAmount, rate: config.immediateRate, type: 'immediate' },
        rule_version: '1.0',
        formula_id: 'fund_v_immediate',
        timestamp: new Date().toISOString(),
        steps: [
          {
            step_name: 'Calculate Immediate Commission',
            description: 'Apply 1.2% immediate rate to contribution amount',
            input_values: { amount: baseAmount, rate: config.immediateRate },
            calculation: `${baseAmount} * ${config.immediateRate}`,
            result: immediateAmount
          }
        ]
      }
    });
    
    // Create deferred line item (due in 24 months)
    const deferredDueDate = new Date(context.distribution.distribution_date || new Date());
    deferredDueDate.setMonth(deferredDueDate.getMonth() + config.deferralMonths);
    
    results.push({
      rule_id: rule.id,
      entity_type: rule.entity_type,
      entity_name: rule.entity_name || '',
      applicable: true,
      calculation: {
        base_amount: baseAmount,
        applied_rate: deferredRate,
        gross_commission: deferredAmount,
        vat_rate: 0.21,
        vat_amount: deferredAmount * 0.21,
        net_commission: deferredAmount,
        method: 'fund_v_deferred'
      },
      execution_time_ms: 0,
      calculation_trace: {
        inputs: { 
          baseAmount, 
          rate: deferredRate, 
          type: 'deferred',
          deferredMonths: config.deferralMonths,
          hitThreshold,
          cumulativeAmount
        },
        rule_version: '1.0',
        formula_id: 'fund_v_deferred',
        timestamp: new Date().toISOString(),
        steps: [
          {
            step_name: 'Check Threshold',
            description: 'Determine if $3M threshold was hit',
            input_values: { cumulativeAmount, threshold: config.retroThreshold },
            calculation: `${cumulativeAmount} >= ${config.retroThreshold}`,
            result: hitThreshold ? 1 : 0
          },
          {
            step_name: 'Calculate Deferred Rate',
            description: 'Calculate deferred rate based on threshold',
            input_values: { totalRate, immediateRate: config.immediateRate },
            calculation: `${totalRate} - ${config.immediateRate}`,
            result: deferredRate
          },
          {
            step_name: 'Calculate Deferred Commission',
            description: 'Apply deferred rate to contribution amount',
            input_values: { amount: baseAmount, rate: deferredRate },
            calculation: `${baseAmount} * ${deferredRate}`,
            result: deferredAmount
          }
        ]
      }
    });
    
    // Handle true-up if threshold was hit and there are overpayments
    if (hitThreshold) {
      const trueUpAmount = await this.calculateTrueUpAmount(
        rule.entity_name || '',
        'Fund V',
        config,
        context.distribution.distribution_date
      );
      
      if (trueUpAmount > 0) {
        results.push({
          rule_id: rule.id,
          entity_type: rule.entity_type,
          entity_name: rule.entity_name || '',
          applicable: true,
          calculation: {
            base_amount: baseAmount,
            applied_rate: 0,
            gross_commission: -trueUpAmount,
            vat_rate: 0.21,
            vat_amount: -trueUpAmount * 0.21,
            net_commission: -trueUpAmount,
            method: 'fund_v_trueup'
          },
          execution_time_ms: 0,
          calculation_trace: {
            inputs: { trueUpAmount, type: 'true_up' },
            rule_version: '1.0',
            formula_id: 'fund_v_trueup',
            timestamp: new Date().toISOString(),
            steps: [
              {
                step_name: 'Calculate True-Up',
                description: 'Create negative adjustment for overpaid deferrals',
                input_values: { overpayment: trueUpAmount },
                calculation: `-(${trueUpAmount})`,
                result: -trueUpAmount
              }
            ]
          }
        });
      }
    }
    
    return results;
  }
  
  /**
   * Management Fee Share Calculation
   * Calculates party's share of management fees based on investor ratios
   */
  static async calculateMFShare(
    rule: AdvancedCommissionRule,
    config: MFShareConfig
  ): Promise<EnhancedCalculationResult[]> {
    const results: EnhancedCalculationResult[] = [];
    
    // Get MF base data and calculate party ratio
    const { partyRatio, totalInvested } = await this.calculatePartyMFRatio(
      rule.entity_name || '',
      config.fund,
      config.year
    );
    
    const grossYear = config.mfPoolYear * partyRatio * (rule.base_rate || 0);
    
    if (config.isQuarterlyAccrual) {
      // Create quarterly accruals
      const quarters = this.getQuartersForYear(config.year);
      
      for (const quarter of quarters) {
        const quarterlyAmount = grossYear / 4; // Simple quarterly split for now
        
        results.push({
          rule_id: rule.id,
          entity_type: rule.entity_type,
          entity_name: rule.entity_name || '',
          applicable: true,
          calculation: {
            base_amount: config.mfPoolYear,
            applied_rate: partyRatio * (rule.base_rate || 0),
            gross_commission: quarterlyAmount,
            vat_rate: 0.21,
            vat_amount: quarterlyAmount * 0.21,
            net_commission: quarterlyAmount,
            method: 'mf_share_quarterly'
          },
          execution_time_ms: 0,
          calculation_trace: {
            inputs: { 
              mfPool: config.mfPoolYear,
              partyRatio,
              rate: rule.base_rate,
              quarter: quarter.name,
              year: config.year
            },
            rule_version: '1.0',
            formula_id: 'mf_share_quarterly',
            timestamp: new Date().toISOString(),
            steps: [
              {
                step_name: 'Calculate Party Ratio',
                description: 'Determine party share of fund investments',
                input_values: { totalInvested, partyInvested: totalInvested * partyRatio },
                calculation: `party_invested / total_invested`,
                result: partyRatio
              },
              {
                step_name: 'Calculate Quarterly MF Share',
                description: 'Apply party ratio and rate to quarterly MF pool',
                input_values: { 
                  mfPool: config.mfPoolYear, 
                  ratio: partyRatio, 
                  rate: rule.base_rate,
                  quarterlyFactor: 0.25
                },
                calculation: `${config.mfPoolYear} * ${partyRatio} * ${rule.base_rate} * 0.25`,
                result: quarterlyAmount
              }
            ]
          }
        });
      }
    } else {
      // Annual calculation
      results.push({
        rule_id: rule.id,
        entity_type: rule.entity_type,
        entity_name: rule.entity_name || '',
        applicable: true,
        calculation: {
          base_amount: config.mfPoolYear,
          applied_rate: partyRatio * (rule.base_rate || 0),
          gross_commission: grossYear,
          vat_rate: 0.21,
          vat_amount: grossYear * 0.21,
          net_commission: grossYear,
          method: 'mf_share_annual'
        },
        execution_time_ms: 0,
        calculation_trace: {
          inputs: { 
            mfPool: config.mfPoolYear,
            partyRatio,
            rate: rule.base_rate,
            year: config.year
          },
          rule_version: '1.0',
          formula_id: 'mf_share_annual',
          timestamp: new Date().toISOString(),
          steps: [
            {
              step_name: 'Calculate Annual MF Share',
              description: 'Apply party ratio and rate to annual MF pool',
              input_values: { 
                mfPool: config.mfPoolYear, 
                ratio: partyRatio, 
                rate: rule.base_rate
              },
              calculation: `${config.mfPoolYear} * ${partyRatio} * ${rule.base_rate}`,
              result: grossYear
            }
          ]
        }
      });
    }
    
    return results;
  }
  
  /**
   * Promote-linked Payout Calculation
   * Calculates commission based on realized promote events
   */
  static async calculatePromotePayout(
    rule: AdvancedCommissionRule,
    realizedAmount: number,
    dealName: string,
    eventDate: string
  ): Promise<EnhancedCalculationResult> {
    const grossCommission = realizedAmount * (rule.base_rate || 0);
    const cappedCommission = Math.min(grossCommission, rule.max_amount || Infinity);
    const finalCommission = Math.max(cappedCommission, rule.min_amount);
    
    return {
      rule_id: rule.id,
      entity_type: rule.entity_type,
      entity_name: rule.entity_name || '',
      applicable: true,
      calculation: {
        base_amount: realizedAmount,
        applied_rate: rule.base_rate || 0,
        gross_commission: finalCommission,
        vat_rate: 0.21,
        vat_amount: finalCommission * 0.21,
        net_commission: finalCommission,
        method: 'promote_payout'
      },
      execution_time_ms: 0,
      calculation_trace: {
        inputs: { 
          realizedAmount,
          rate: rule.base_rate,
          dealName,
          eventDate,
          minAmount: rule.min_amount,
          maxAmount: rule.max_amount
        },
        rule_version: '1.0',
        formula_id: 'promote_payout',
        timestamp: new Date().toISOString(),
        steps: [
          {
            step_name: 'Calculate Gross Commission',
            description: 'Apply rate to realized amount',
            input_values: { amount: realizedAmount, rate: rule.base_rate },
            calculation: `${realizedAmount} * ${rule.base_rate}`,
            result: grossCommission
          },
          {
            step_name: 'Apply Caps and Minimums',
            description: 'Ensure commission is within defined limits',
            input_values: { 
              gross: grossCommission, 
              min: rule.min_amount, 
              max: rule.max_amount 
            },
            calculation: `min(max(${grossCommission}, ${rule.min_amount}), ${rule.max_amount})`,
            result: finalCommission
          }
        ]
      }
    };
  }
  
  // Helper methods
  private static async getCumulativeContributions(
    entityName: string,
    fund: string,
    upToDate?: string
  ): Promise<number> {
    const { data, error } = await supabase
      .from('investor_distributions')
      .select('distribution_amount')
      .eq('fund_name', fund)
      .eq('distributor_name', entityName)
      .lte('distribution_date', upToDate || new Date().toISOString());
    
    if (error) {
      console.error('Error fetching cumulative contributions:', error);
      return 0;
    }
    
    return data?.reduce((sum, item) => sum + (item.distribution_amount || 0), 0) || 0;
  }
  
  private static async calculateTrueUpAmount(
    entityName: string,
    fund: string,
    config: FundVDeferralConfig,
    upToDate?: string
  ): Promise<number> {
    // Get all previously paid deferrals for this entity
    const { data, error } = await supabase
      .from('advanced_commission_calculations')
      .select('gross_commission')
      .eq('entity_name', entityName)
      .eq('calculation_method', 'fund_v_deferred')
      .lte('created_at', upToDate || new Date().toISOString());
    
    if (error) {
      console.error('Error fetching deferral payments:', error);
      return 0;
    }
    
    const totalPaidDeferrals = data?.reduce((sum, item) => sum + (item.gross_commission || 0), 0) || 0;
    const cumulativeAmount = await this.getCumulativeContributions(entityName, fund, upToDate);
    const correctDeferralAmount = cumulativeAmount * (config.retroTotalRate - config.immediateRate);
    
    return Math.max(0, totalPaidDeferrals - correctDeferralAmount);
  }
  
  private static async calculatePartyMFRatio(
    entityName: string,
    fund: string,
    year: number
  ): Promise<{ partyRatio: number; totalInvested: number }> {
    // This would query the MF base data - simplified for now
    // In reality, this would calculate based on the party's investors vs total fund investors
    return { partyRatio: 0.15, totalInvested: 100000000 }; // Mock data
  }
  
  private static getQuartersForYear(year: number) {
    return [
      { name: 'Q1', startDate: `${year}-01-01`, endDate: `${year}-03-31` },
      { name: 'Q2', startDate: `${year}-04-01`, endDate: `${year}-06-30` },
      { name: 'Q3', startDate: `${year}-07-01`, endDate: `${year}-09-30` },
      { name: 'Q4', startDate: `${year}-10-01`, endDate: `${year}-12-31` }
    ];
  }
}