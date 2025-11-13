import { supabase } from '@/integrations/supabase/client';

/**
 * Agreement Loader
 * Handles loading agreements for calculations with proper scope filtering
 */

export interface Agreement {
  id: string;
  name: string;
  agreement_type: string;
  applies_scope: 'FUND' | 'DEAL';
  deal_id?: string | null;
  effective_from: string;
  effective_to: string | null;
  introduced_by_party_id: string;
  status: string;
  inherit_fund_rates?: boolean;
  upfront_rate_bps?: number | null;
  deferred_rate_bps?: number | null;
  deferred_offset_months?: number | null;
  track_key?: string | null;
  vat_mode?: string;
}

export class AgreementLoader {
  /**
   * Load active agreements for a calculation run
   * Includes both FUND and DEAL scoped agreements
   */
  static async loadActiveAgreements(
    asOfDate: string,
    fundName?: string,
    dealId?: string
  ): Promise<Agreement[]> {
    let query = supabase
      .from('agreements')
      .select('*')
      .eq('status', 'active')
      .lte('effective_from', asOfDate)
      .or(`effective_to.is.null,effective_to.gte.${asOfDate}`);

    const { data, error } = await query;

    if (error) {
      throw new Error(`Failed to load agreements: ${error.message}`);
    }

    return (data || []) as Agreement[];
  }

  /**
   * Find the applicable agreement for a party based on scope precedence
   * DEAL-scoped agreements (matching deal_id) take priority over FUND-scoped
   */
  static findApplicableAgreement(
    agreements: Agreement[],
    partyId: string,
    fundName: string,
    dealId: string | null | undefined,
    asOfDate: string
  ): Agreement | null {
    // Filter agreements for this party
    const partyAgreements = agreements.filter(
      a => a.introduced_by_party_id === partyId
    );

    if (partyAgreements.length === 0) return null;

    // 1. Try DEAL-scoped agreement (if dealId present)
    if (dealId) {
      const dealAgreement = partyAgreements.find(
        a => a.applies_scope === 'DEAL' && a.deal_id === dealId
      );

      if (dealAgreement) return dealAgreement;
    }

    // 2. Fallback to FUND-scoped agreement
    const fundAgreement = partyAgreements.find(
      a => a.applies_scope === 'FUND' && !a.deal_id
    );

    return fundAgreement || null;
  }

  /**
   * Check if there's a potential double-charge scenario
   * Returns true if both FUND and DEAL agreements exist for the same party
   */
  static hasMultipleScopesForParty(
    agreements: Agreement[],
    partyId: string
  ): boolean {
    const partyAgreements = agreements.filter(
      a => a.introduced_by_party_id === partyId
    );

    const hasFund = partyAgreements.some(a => a.applies_scope === 'FUND');
    const hasDeal = partyAgreements.some(a => a.applies_scope === 'DEAL');

    return hasFund && hasDeal;
  }
}
