import { supabase } from '@/integrations/supabase/client';
import { CommissionRule, VatRate, Credit } from '@/domain/types';
import { sha256Hex } from '@/domain/hash';
import { stableStringify } from '@/domain/stableJson';

export interface RuleSet {
  rules: CommissionRule[];
  vat_rates: VatRate[];
  credits: Credit[];
  version: string;
  checksum: string;
}

export class RuleLoader {
  /**
   * Load active commission rules with their tiers and conditions
   */
  static async loadActiveRules(
    entityType?: string,
    entityName?: string,
    fundName?: string,
    asOfDate?: string
  ): Promise<CommissionRule[]> {
    let query = supabase
      .from('advanced_commission_rules')
      .select(`
        *,
        tiers:commission_tiers(*),
        conditions:rule_conditions(*)
      `)
      .eq('is_active', true)
      .is('archived_at', null);

    if (entityType) {
      query = query.eq('entity_type', entityType);
    }

    if (entityName) {
      query = query.eq('entity_name', entityName);
    }

    if (fundName) {
      query = query.eq('fund_name', fundName);
    }

    if (asOfDate) {
      const date = asOfDate;
      query = query.or(`effective_from.is.null,effective_from.lte.${date}`)
        .or(`effective_to.is.null,effective_to.gte.${date}`);
    }

    const { data, error } = await query.order('priority', { ascending: false });

    if (error) {
      throw new Error(`Failed to load rules: ${error.message}`);
    }

    return (data || []) as unknown as CommissionRule[];
  }

  /**
   * Load VAT rates
   */
  static async loadVatRates(): Promise<VatRate[]> {
    const { data, error } = await supabase
      .from('vat_rates')
      .select('*')
      .order('effective_from', { ascending: false });

    if (error) {
      throw new Error(`Failed to load VAT rates: ${error.message}`);
    }

    return (data || []) as VatRate[];
  }

  /**
   * Load available credits for investors
   */
  static async loadCredits(investorNames?: string[]): Promise<Credit[]> {
    let query = supabase
      .from('credits')
      .select('*')
      .eq('status', 'active')
      .gt('remaining_balance', 0);

    if (investorNames && investorNames.length > 0) {
      query = query.in('investor_name', investorNames);
    }

    const { data, error } = await query;

    if (error) {
      throw new Error(`Failed to load credits: ${error.message}`);
    }

    return (data || []) as Credit[];
  }

  /**
   * Load complete ruleset for a calculation run
   */
  static async loadRuleSet(
    calculationRunId: string,
    investorNames: string[]
  ): Promise<RuleSet> {
    // Load all active rules
    const rules = await this.loadActiveRules();

    // Load VAT rates
    const vat_rates = await this.loadVatRates();

    // Load credits for the investors in this run
    const credits = await this.loadCredits(investorNames);

    // Generate version and checksum
    const version = new Date().toISOString();
    const checksum = await this.generateChecksum({ rules, vat_rates, credits });

    // Store the ruleset snapshot for the calculation run
    await this.storeRulesetSnapshot(calculationRunId, rules, version, checksum);

    return {
      rules,
      vat_rates,
      credits,
      version,
      checksum,
    };
  }

  /**
   * Generate deterministic checksum for ruleset
   * Works in browser and Node environments
   */
  static async generateChecksum(data: any): Promise<string> {
    return sha256Hex(stableStringify(data));
  }

  /**
   * Store ruleset snapshot for audit trail
   */
  private static async storeRulesetSnapshot(
    calculationRunId: string,
    rules: CommissionRule[],
    version: string,
    checksum: string
  ): Promise<void> {
    // Store each rule snapshot in calc_runs_rules
    const snapshots = rules.map(rule => ({
      run_id: calculationRunId,
      rule_id: rule.id,
      rule_version: rule.rule_version,
      rule_snapshot: rule as any,
    }));

    if (snapshots.length > 0) {
      const { error } = await supabase
        .from('calc_runs_rules')
        .insert(snapshots);

      if (error) {
        console.error('Failed to store ruleset snapshot:', error);
      }
    }
  }

  /**
   * Assert that a rule's basis is 'distribution_amount' (business requirement)
   */
  static assertContributionBasis(rule: CommissionRule): void {
    if (rule.calculation_basis !== 'distribution_amount') {
      throw new Error(
        `Rule ${rule.id} (${rule.name}) uses ${rule.calculation_basis} basis. ` +
        `Only 'distribution_amount' (contribution) basis is allowed per business requirements.`
      );
    }
  }

  /**
   * Validate rule checksum hasn't changed
   */
  static validateChecksum(rule: CommissionRule, expectedChecksum: string): void {
    if (rule.rule_checksum !== expectedChecksum) {
      throw new Error(
        `Rule ${rule.id} checksum mismatch. ` +
        `Expected: ${expectedChecksum}, Got: ${rule.rule_checksum}. ` +
        `Rule may have been modified since calculation started.`
      );
    }
  }
}
