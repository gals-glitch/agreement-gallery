import { CalculationInput, CalculationOutput, FeeLine, Contribution, CommissionRule } from '@/domain/types';
import { Money } from '@/domain/money';
import { RuleLoader } from './rule-loader';
import { TierEngine } from './tier-engine';
import { VatEngine } from './vat-engine';
import { CreditEngine } from './credit-engine';
import { PrecedenceEngine } from './precedence-engine';
import { CreditsScopingEngine } from './credits-scoping-engine';

export class CanonicalCalculationEngine {
  /**
   * Main entry point for commission calculations
   * Enforces contribution-based calculation and deterministic processing
   */
  static async calculate(input: CalculationInput): Promise<CalculationOutput> {
    const warnings: string[] = [];
    const errors: string[] = [];

    try {
      // 1. Load ruleset (rules, VAT rates, credits)
      const investorNames = [...new Set(input.contributions.map(c => c.investor_name))];
      const ruleSet = await RuleLoader.loadRuleSet(input.calculation_run_id, investorNames);

      // 2. Validate all rules are contribution-based
      for (const rule of ruleSet.rules) {
        try {
          RuleLoader.assertContributionBasis(rule);
        } catch (error: any) {
          errors.push(error.message);
        }
      }

      if (errors.length > 0) {
        throw new Error(
          `Calculation aborted due to rule validation errors:\n${errors.join('\n')}`
        );
      }

      // 3. Process each contribution
      const feeLines: FeeLine[] = [];

      for (const contribution of input.contributions) {
        try {
          const lines = await this.processContribution(
            contribution,
            ruleSet.rules,
            ruleSet.vat_rates,
            ruleSet.credits,
            input.as_of_date
          );
          feeLines.push(...lines);
        } catch (error: any) {
          errors.push(`Contribution ${contribution.id}: ${error.message}`);
        }
      }

      // 4. Calculate totals with scope breakdown
      const totals = this.calculateTotalsWithBreakdown(feeLines);

      return {
        calculation_run_id: input.calculation_run_id,
        fee_lines: feeLines,
        total_gross: totals.total_gross,
        total_vat: totals.total_vat,
        total_net: totals.total_net,
        ruleset_version: ruleSet.version,
        ruleset_checksum: ruleSet.checksum,
        scope_breakdown: totals.scope_breakdown,
        warnings,
        errors,
      };
    } catch (error: any) {
      errors.push(error.message);
      
      return {
        calculation_run_id: input.calculation_run_id,
        fee_lines: [],
        total_gross: 0,
        total_vat: 0,
        total_net: 0,
        ruleset_version: '',
        ruleset_checksum: '',
        warnings,
        errors,
      };
    }
  }

  /**
   * Process a single contribution and generate fee lines for all applicable entities
   * Implements DEAL→FUND precedence logic
   */
  private static async processContribution(
    contribution: Contribution,
    rules: CommissionRule[],
    vatRates: any[],
    credits: any[],
    asOfDate: string
  ): Promise<FeeLine[]> {
    const feeLines: FeeLine[] = [];
    const selectedRules: Array<{ entityType: string; entityName: string; rule: CommissionRule }> = [];

    // Find applicable rules for each entity type
    const entityTypes = [
      { type: 'distributor', name: contribution.distributor_name },
      { type: 'referrer', name: contribution.referrer_name },
      { type: 'partner', name: contribution.partner_name },
    ].filter(e => e.name);

    for (const entity of entityTypes) {
      // Get all rules for this entity type and name
      const candidateRules = rules.filter(r => 
        r.entity_type === entity.type &&
        (!r.entity_name || r.entity_name === entity.name)
      );

      if (candidateRules.length === 0) continue;

      // Apply precedence: DEAL-scoped (matching deal_id) → FUND-scoped
      const rule = PrecedenceEngine.findApplicableRule(
        candidateRules,
        contribution.deal_id,
        contribution.fund_name
      );

      if (!rule) continue;

      selectedRules.push({ entityType: entity.type, entityName: entity.name!, rule });

      try {
        const feeLine = await this.calculateFeeLine(
          contribution,
          rule,
          entity.type,
          entity.name!,
          vatRates,
          credits,
          asOfDate
        );
        feeLines.push(feeLine);
      } catch (error: any) {
        console.error(`Failed to calculate fee for ${entity.type} ${entity.name}:`, error);
      }
    }

    // Validate no double-charging (safety check)
    PrecedenceEngine.validateNoDuplicateScope(selectedRules, contribution);

    return feeLines;
  }

  /**
   * Calculate a single fee line using the canonical engine stages
   * Now with rate resolution from fund_vi_tracks or agreement overrides
   */
  private static async calculateFeeLine(
    contribution: Contribution,
    rule: CommissionRule,
    entityType: string,
    entityName: string,
    vatRates: any[],
    allCredits: any[],
    asOfDate: string
  ): Promise<FeeLine> {
    const baseAmount = contribution.distribution_amount;

    // Stage 1: Calculate base fee (with tiers if applicable)
    let feeCalc;
    if (rule.rule_type === 'tiered' && rule.tiers && rule.tiers.length > 0) {
      feeCalc = TierEngine.calculateTiered(baseAmount, rule.tiers, true);
    } else if (rule.rule_type === 'percentage') {
      const rate = rule.base_rate || 0;
      const fee = new Money(baseAmount).percentage(rate);
      feeCalc = {
        base_amount: baseAmount,
        applied_rate: rate,
        fee_gross: fee.toInvoiceAmount(),
        calculation_method: 'percentage',
      };
    } else if (rule.rule_type === 'fixed_amount') {
      feeCalc = {
        base_amount: baseAmount,
        applied_rate: 0,
        fee_gross: rule.fixed_amount || 0,
        calculation_method: 'fixed_amount',
      };
    } else {
      throw new Error(`Unsupported rule type: ${rule.rule_type}`);
    }

    // Stage 2: Apply caps (min/max)
    const capped = TierEngine.applyCaps(
      feeCalc.fee_gross,
      rule.min_amount,
      rule.max_amount
    );

    // Stage 3: Apply VAT
    const vatRate = VatEngine.getApplicableRate(vatRates, 'IL', asOfDate);
    const vatCalc = VatEngine.calculate(
      capped.capped_fee,
      vatRate,
      rule.vat_mode
    );

    // Stage 4: Apply credits with scope awareness
    const feeLineScope = rule.applies_scope || 'FUND';
    const applicableCredits = CreditsScopingEngine.getApplicableCredits(
      allCredits,
      contribution.investor_name,
      contribution.fund_name,
      feeLineScope as 'FUND' | 'DEAL',
      contribution.deal_id
    );
    const creditCalc = CreditsScopingEngine.applyCredits(
      vatCalc.total_payable,
      applicableCredits
    );

    // Build fee line
    const notes = [
      feeCalc.notes,
      capped.notes,
      creditCalc.notes,
    ].filter(Boolean).join('; ');

    return {
      contribution_id: contribution.id,
      rule_id: rule.id,
      rule_version: rule.rule_version,
      entity_type: entityType,
      entity_name: entityName,
      base_amount: feeCalc.base_amount,
      applied_rate: feeCalc.applied_rate,
      tier_applied: feeCalc.tier_applied,
      fee_gross: vatCalc.fee_gross,
      vat_rate: vatCalc.vat_rate,
      vat_amount: vatCalc.vat_amount,
      fee_net: vatCalc.fee_net,
      total_payable: creditCalc.final_amount,
      credits_applied: creditCalc.credits_applied,
      calculation_method: feeCalc.calculation_method,
      notes: notes || undefined,
      // Add scope information for exports and UI
      scope: rule.applies_scope || 'FUND',
      deal_id: contribution.deal_id,
      deal_code: contribution.deal_code,
      deal_name: contribution.deal_name,
    };
  }

  /**
   * Calculate totals from fee lines, including scope breakdown
   */
  private static calculateTotalsWithBreakdown(feeLines: FeeLine[]) {
    const totalGross = Money.sum(feeLines.map(l => new Money(l.fee_gross)));
    const totalVat = Money.sum(feeLines.map(l => new Money(l.vat_amount)));
    const totalNet = Money.sum(feeLines.map(l => new Money(l.total_payable)));

    // Calculate scope breakdown
    const fundLines = feeLines.filter(l => l.scope === 'FUND');
    const dealLines = feeLines.filter(l => l.scope === 'DEAL');

    const fundGross = Money.sum(fundLines.map(l => new Money(l.fee_gross)));
    const fundVat = Money.sum(fundLines.map(l => new Money(l.vat_amount)));
    const fundNet = Money.sum(fundLines.map(l => new Money(l.total_payable)));

    const dealGross = Money.sum(dealLines.map(l => new Money(l.fee_gross)));
    const dealVat = Money.sum(dealLines.map(l => new Money(l.vat_amount)));
    const dealNet = Money.sum(dealLines.map(l => new Money(l.total_payable)));

    return {
      total_gross: totalGross.toInvoiceAmount(),
      total_vat: totalVat.toInvoiceAmount(),
      total_net: totalNet.toInvoiceAmount(),
      scope_breakdown: {
        FUND: {
          gross: fundGross.toInvoiceAmount(),
          vat: fundVat.toInvoiceAmount(),
          net: fundNet.toInvoiceAmount(),
          count: fundLines.length,
        },
        DEAL: {
          gross: dealGross.toInvoiceAmount(),
          vat: dealVat.toInvoiceAmount(),
          net: dealNet.toInvoiceAmount(),
          count: dealLines.length,
        },
      },
    };
  }
}
