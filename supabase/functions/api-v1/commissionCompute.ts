/**
 * Commission Computation Engine
 *
 * Computes commissions owed TO distributors/referrers based on:
 * - Investor contributions (uploaded from external source)
 * - Commission agreements (investor-level OR party-level)
 * - VAT configuration
 *
 * Flow:
 * 1. Load contribution (investor, amount, date, fund/deal)
 * 2. Resolve party via investors.introduced_by
 * 3. Resolve approved commission agreement (investor-level PREFERRED, party-level FALLBACK)
 * 4. Compute base commission based on agreement type
 * 5. Compute VAT if applicable
 * 6. UPSERT commission row with snapshot
 *
 * Agreement Types (investor-level):
 * - simple_equity: transaction_amount × (equity_bps / 10000) × commission_rate
 * - upfront_promote: Separate rates for contributions vs. distributions
 * - tiered_by_deal_count: Rate varies based on investor's deal count
 * - deal_specific_limit: Only applies if within max_deals and specific deals
 * - flat_fee: One-time payment (likely already paid)
 *
 * Legacy Agreement Type (party-level):
 * - rate_bps based: transaction_amount × (rate_bps / 10000)
 */

import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';

// ============================================
// Types
// ============================================

// Legacy party-level commission structure (backward compatibility)
// Enhanced with pricing variants for flexible commission structures
interface PartyCommissionTermSnapshot {
  kind: 'distributor_commission';
  party_id: string;
  party_name: string;
  scope: {
    fund_id: number | null;
    deal_id: number | null;
  };
  terms: Array<{
    from: string;          // ISO date
    to: string | null;     // ISO date or null for open-ended
    rate_bps: number;      // Basis points (250 = 2.5%)
    vat_mode: 'on_top' | 'included';
    vat_rate: number;      // Decimal (0.2 = 20%)
  }>;
  vat_admin_snapshot?: {
    jurisdiction: string;
    rate: number;
    effective_at: string;
  };
  // Pricing variant fields (from agreement_custom_terms)
  pricing_variant?: 'BPS' | 'BPS_SPLIT' | 'FIXED' | 'MGMT_FEE';
  upfront_bps?: number;
  deferred_bps?: number;
  fixed_amount_cents?: number;
  mgmt_fee_bps?: number;
}

// Investor-level commission structures
interface SimpleEquitySnapshot {
  kind: 'distributor_commission';
  agreement_type: 'simple_equity';
  equity_bps: number;           // Basis points of equity (100 = 1%)
  commission_rate: number;      // Multiplier (1.0 = 100%, 0.5 = 50%)
  vat_mode: 'on_top' | 'included';
  vat_rate: number;             // Decimal (0.17 = 17%)
}

interface UpfrontPromoteSnapshot {
  kind: 'distributor_commission';
  agreement_type: 'upfront_promote';
  upfront_rate: number | null;  // Rate for contributions (e.g., 0.25 = 25%)
  promote_rate: number | null;  // Rate for distributions (e.g., 0.15 = 15%)
  vat_mode: 'on_top' | 'included';
  vat_rate: number;
}

interface TieredByDealCountSnapshot {
  kind: 'distributor_commission';
  agreement_type: 'tiered_by_deal_count';
  tiers: Array<{
    deal_range: string;         // e.g., "1", "2-3", "4-5", "6+"
    equity_bps: number;         // Basis points for this tier
  }>;
  vat_mode: 'on_top' | 'included';
  vat_rate: number;
}

interface DealSpecificLimitSnapshot {
  kind: 'distributor_commission';
  agreement_type: 'deal_specific_limit';
  equity_bps: number;
  max_deals: number;            // Maximum number of deals eligible
  specific_deals: string[];     // Array of deal names/codes (e.g., ["Perdido"])
  vat_mode: 'on_top' | 'included';
  vat_rate: number;
}

interface FlatFeeSnapshot {
  kind: 'distributor_commission';
  agreement_type: 'flat_fee';
  flat_fee: number;             // One-time payment amount
  currency: string;             // Currency code (e.g., "USD")
}

// Union type for all possible commission snapshots
type CommissionTermSnapshot =
  | PartyCommissionTermSnapshot
  | SimpleEquitySnapshot
  | UpfrontPromoteSnapshot
  | TieredByDealCountSnapshot
  | DealSpecificLimitSnapshot
  | FlatFeeSnapshot;

interface ComputeResult {
  id?: string;                   // Commission ID (primary key)
  commission_id: string;         // Alias for backward compatibility
  status: string;                // Commission status (draft, approved, etc.)
  party_id?: string;             // Party receiving commission
  party_name?: string;           // Party name
  investor_id?: number;          // Investor who made contribution
  investor_name?: string;        // Investor name
  base_amount: number;           // Base commission amount (before VAT)
  vat_amount: number;            // VAT amount
  total_amount: number;          // Total amount (base + VAT)
  currency: string;              // Currency code
  snapshot_json: CommissionTermSnapshot; // Agreement snapshot
  is_investor_level?: boolean;   // Whether this uses investor-level agreement
  agreement_type?: string;       // Type of agreement used
  error?: string;                // Error message if computation failed
}

// ============================================
// Utility: Round to 2 decimal places
// ============================================

function round2(value: number): number {
  return Math.round(value * 100) / 100;
}

// ============================================
// Helper: Get investor's deal count
// ============================================

async function getInvestorDealCount(
  supabase: SupabaseClient,
  investorId: number
): Promise<number> {
  // Count distinct deals this investor has contributed to
  const { data, error } = await supabase
    .from('contributions')
    .select('deal_id', { count: 'exact', head: false })
    .eq('investor_id', investorId)
    .not('deal_id', 'is', null);

  if (error) {
    console.error('Failed to get investor deal count:', error);
    return 1; // Default to 1 on error
  }

  // Get unique deal count
  const uniqueDeals = new Set(data.map(c => c.deal_id));
  return uniqueDeals.size || 1;
}

// ============================================
// Helper: Check if deal matches specific deals list
// ============================================

async function isDealInSpecificList(
  supabase: SupabaseClient,
  dealId: number | null,
  specificDealNames: string[]
): Promise<boolean> {
  if (!dealId || specificDealNames.length === 0) {
    return false;
  }

  // Fetch deal name
  const { data: deal, error } = await supabase
    .from('deals')
    .select('name, code')
    .eq('id', dealId)
    .single();

  if (error || !deal) {
    return false;
  }

  // Check if deal name or code matches any in the specific list
  return specificDealNames.some(
    specificName =>
      deal.name?.toLowerCase().includes(specificName.toLowerCase()) ||
      deal.code?.toLowerCase().includes(specificName.toLowerCase())
  );
}

// ============================================
// Helper: Parse deal range and check if count matches
// ============================================

function isDealCountInRange(dealCount: number, rangeStr: string): boolean {
  if (rangeStr.includes('-')) {
    const [min, max] = rangeStr.split('-').map(s => parseInt(s.trim()));
    return dealCount >= min && dealCount <= max;
  } else if (rangeStr.includes('+')) {
    const min = parseInt(rangeStr.replace('+', '').trim());
    return dealCount >= min;
  } else {
    return dealCount === parseInt(rangeStr.trim());
  }
}

// ============================================
// Core: Compute Commission for Contribution
// ============================================

export async function computeCommissionForContribution({
  supabase,
  contributionId,
}: {
  supabase: SupabaseClient;
  contributionId: number;
}): Promise<ComputeResult> {

  // ============================================
  // STEP 1: Load contribution with relationships
  // ============================================

  const { data: contribution, error: contribError } = await supabase
    .from('contributions')
    .select(`
      id,
      investor_id,
      fund_id,
      deal_id,
      amount,
      paid_in_date,
      currency,
      investors!contributions_investor_id_fkey(
        id,
        name,
        introduced_by_party_id
      )
    `)
    .eq('id', contributionId)
    .single();

  if (contribError || !contribution) {
    throw new Error(`Contribution ${contributionId} not found: ${contribError?.message || 'Unknown error'}`);
  }

  const investor = contribution.investors as any;
  const partyId = investor?.introduced_by_party_id;

  if (!partyId) {
    throw new Error(`Contribution ${contributionId}: investor has no introduced_by_party_id`);
  }

  // ============================================
  // STEP 2: Resolve party details
  // ============================================

  const { data: party, error: partyError } = await supabase
    .from('parties')
    .select('id, name')
    .eq('id', partyId)
    .single();

  if (partyError || !party) {
    throw new Error(`Party ${partyId} not found: ${partyError?.message || 'Unknown error'}`);
  }

  // ============================================
  // STEP 3: Resolve approved commission agreement
  // ============================================

  // PRIORITY 1: Look for investor-level agreement (investor_id IS NOT NULL)
  // PRIORITY 2: Fall back to party-level agreement (investor_id IS NULL)

  let agreement: any = null;

  // Try investor-level agreement first
  const { data: investorAgreements, error: investorAgreementError } = await supabase
    .from('agreements')
    .select('id, snapshot_json, effective_from, effective_to, investor_id')
    .eq('kind', 'distributor_commission')
    .eq('investor_id', contribution.investor_id)
    .eq('status', 'APPROVED')
    .lte('effective_from', contribution.paid_in_date)
    .or(`effective_to.is.null,effective_to.gte.${contribution.paid_in_date}`);

  if (investorAgreementError) {
    throw new Error(`Investor agreement lookup failed: ${investorAgreementError.message}`);
  }

  if (investorAgreements && investorAgreements.length > 0) {
    // Found investor-level agreement - use the most recent one
    agreement = investorAgreements.reduce((best, current) => {
      return new Date(current.effective_from) > new Date(best.effective_from) ? current : best;
    });
  } else {
    // Fall back to party-level agreement (legacy behavior)
    let agreementQuery = supabase
      .from('agreements')
      .select('id, snapshot_json, effective_from, effective_to, investor_id')
      .eq('kind', 'distributor_commission')
      .eq('party_id', partyId)
      .is('investor_id', null)  // Only party-level agreements
      .eq('status', 'APPROVED')
      .lte('effective_from', contribution.paid_in_date);

    // Match scope: fund OR deal
    if (contribution.fund_id) {
      agreementQuery = agreementQuery.eq('fund_id', contribution.fund_id);
    } else if (contribution.deal_id) {
      agreementQuery = agreementQuery.eq('deal_id', contribution.deal_id);
    } else {
      throw new Error(`Contribution ${contributionId} has neither fund_id nor deal_id`);
    }

    // effective_to filter: null (open-ended) OR >= contribution date
    agreementQuery = agreementQuery.or(`effective_to.is.null,effective_to.gte.${contribution.paid_in_date}`);

    const { data: partyAgreements, error: partyAgreementError } = await agreementQuery;

    if (partyAgreementError) {
      throw new Error(`Party agreement lookup failed: ${partyAgreementError.message}`);
    }

    if (!partyAgreements || partyAgreements.length === 0) {
      throw new Error(
        `No approved commission agreement found for investor ${investor.name} (${contribution.investor_id}) ` +
        `or party ${party.name} (${partyId}) ` +
        `and ${contribution.fund_id ? 'fund ' + contribution.fund_id : 'deal ' + contribution.deal_id} ` +
        `as of ${contribution.paid_in_date}`
      );
    }

    // If multiple agreements match, choose most specific (deal over fund) and latest start date
    agreement = partyAgreements.reduce((best, current) => {
      if (current.deal_id && !best.deal_id) return current; // Deal-specific wins
      if (!current.deal_id && best.deal_id) return best;
      // Tie-break by latest effective_from
      return new Date(current.effective_from) > new Date(best.effective_from) ? current : best;
    });
  }

  // ============================================
  // STEP 4: Parse snapshot and compute commission
  // ============================================

  const snapshot = agreement.snapshot_json as CommissionTermSnapshot;
  const contributionAmount = Number(contribution.amount);

  let baseAmount = 0;
  let vatAmount = 0;
  let computationDetails: any = {};

  // Determine if this is investor-level or party-level agreement
  const isInvestorLevel = agreement.investor_id !== null;

  if (isInvestorLevel) {
    // ============================================
    // INVESTOR-LEVEL AGREEMENT COMPUTATION
    // ============================================

    const agreementType = (snapshot as any).agreement_type;

    if (!agreementType) {
      throw new Error(
        `Agreement ${agreement.id} is investor-level but missing agreement_type in snapshot_json`
      );
    }

    switch (agreementType) {
      case 'simple_equity': {
        // Calculation: transaction_amount × (equity_bps / 10000) × commission_rate
        const snap = snapshot as SimpleEquitySnapshot;
        baseAmount = round2(contributionAmount * (snap.equity_bps / 10000) * snap.commission_rate);

        computationDetails = {
          agreement_type: 'simple_equity',
          equity_bps: snap.equity_bps,
          commission_rate: snap.commission_rate,
          calculation: `${contributionAmount} × (${snap.equity_bps} / 10000) × ${snap.commission_rate} = ${baseAmount}`
        };

        // VAT calculation
        if (snap.vat_mode === 'on_top' && snap.vat_rate > 0) {
          vatAmount = round2(baseAmount * snap.vat_rate);
        }
        break;
      }

      case 'upfront_promote': {
        // Calculation depends on transaction type (contribution vs distribution)
        const snap = snapshot as UpfrontPromoteSnapshot;

        // For now, assume contributions use upfront_rate
        // TODO: Distinguish between contributions and distributions
        const applicableRate = snap.upfront_rate;

        if (applicableRate === null) {
          throw new Error(
            `Agreement ${agreement.id} has upfront_promote type but upfront_rate is null for contribution`
          );
        }

        baseAmount = round2(contributionAmount * applicableRate);

        computationDetails = {
          agreement_type: 'upfront_promote',
          transaction_type: 'contribution',
          upfront_rate: snap.upfront_rate,
          promote_rate: snap.promote_rate,
          applied_rate: applicableRate,
          calculation: `${contributionAmount} × ${applicableRate} = ${baseAmount}`
        };

        // VAT calculation
        if (snap.vat_mode === 'on_top' && snap.vat_rate > 0) {
          vatAmount = round2(baseAmount * snap.vat_rate);
        }
        break;
      }

      case 'tiered_by_deal_count': {
        // Calculation: Look up current deal count for investor, apply corresponding tier
        const snap = snapshot as TieredByDealCountSnapshot;

        // Get investor's actual deal count
        const investorDealCount = await getInvestorDealCount(supabase, contribution.investor_id);

        // Find applicable tier based on deal count
        let applicableTier = snap.tiers.find(tier =>
          isDealCountInRange(investorDealCount, tier.deal_range)
        );

        if (!applicableTier) {
          // Use last tier as fallback
          applicableTier = snap.tiers[snap.tiers.length - 1];
        }

        baseAmount = round2(contributionAmount * (applicableTier.equity_bps / 10000));

        computationDetails = {
          agreement_type: 'tiered_by_deal_count',
          investor_deal_count: investorDealCount,
          applied_tier: applicableTier,
          all_tiers: snap.tiers,
          calculation: `${contributionAmount} × (${applicableTier.equity_bps} / 10000) = ${baseAmount}`
        };

        // VAT calculation
        if (snap.vat_mode === 'on_top' && snap.vat_rate > 0) {
          vatAmount = round2(baseAmount * snap.vat_rate);
        }
        break;
      }

      case 'deal_specific_limit': {
        // Calculation: Only apply if investor hasn't exceeded max_deals and deal is in specific list
        const snap = snapshot as DealSpecificLimitSnapshot;

        // Get investor's deal count
        const investorDealCount = await getInvestorDealCount(supabase, contribution.investor_id);

        // Check if deal is in specific deals list
        const dealMatches = await isDealInSpecificList(
          supabase,
          contribution.deal_id,
          snap.specific_deals
        );

        // Apply commission only if within limits
        if (investorDealCount <= snap.max_deals && dealMatches) {
          baseAmount = round2(contributionAmount * (snap.equity_bps / 10000));
        } else {
          baseAmount = 0; // No commission - exceeded limits or wrong deal
        }

        computationDetails = {
          agreement_type: 'deal_specific_limit',
          equity_bps: snap.equity_bps,
          max_deals: snap.max_deals,
          investor_deal_count: investorDealCount,
          specific_deals: snap.specific_deals,
          deal_matches: dealMatches,
          applies: investorDealCount <= snap.max_deals && dealMatches,
          calculation: baseAmount > 0
            ? `${contributionAmount} × (${snap.equity_bps} / 10000) = ${baseAmount}`
            : 'No commission - limit exceeded or deal not in specific list'
        };

        // VAT calculation
        if (snap.vat_mode === 'on_top' && snap.vat_rate > 0) {
          vatAmount = round2(baseAmount * snap.vat_rate);
        }
        break;
      }

      case 'flat_fee': {
        // One-time payment (likely already paid)
        const snap = snapshot as FlatFeeSnapshot;

        // Flat fees are typically one-time, not per-contribution
        // Return 0 to indicate no additional commission owed
        baseAmount = 0;

        computationDetails = {
          agreement_type: 'flat_fee',
          flat_fee: snap.flat_fee,
          currency: snap.currency,
          note: 'Flat fee is one-time payment, not per-contribution'
        };
        break;
      }

      default:
        throw new Error(
          `Unknown agreement_type '${agreementType}' in agreement ${agreement.id}`
        );
    }

  } else {
    // ============================================
    // PARTY-LEVEL AGREEMENT COMPUTATION (ENHANCED)
    // ============================================

    const partySnapshot = snapshot as PartyCommissionTermSnapshot;

    // Determine pricing variant from snapshot or default to BPS for backward compatibility
    const pricingVariant = partySnapshot.pricing_variant || 'BPS';

    switch (pricingVariant) {
      case 'BPS': {
        // UPFRONT BPS ONLY (Current behavior)
        if (!partySnapshot.terms || partySnapshot.terms.length === 0) {
          throw new Error(`Agreement ${agreement.id} has no terms in snapshot_json`);
        }

        // Find term that covers contribution.paid_in_date
        const applicableTerm = partySnapshot.terms.find(term => {
          const termFrom = new Date(term.from);
          const termTo = term.to ? new Date(term.to) : null;
          const contribDate = new Date(contribution.paid_in_date);

          return contribDate >= termFrom && (!termTo || contribDate < termTo);
        });

        if (!applicableTerm) {
          throw new Error(
            `No term in agreement ${agreement.id} covers date ${contribution.paid_in_date}. ` +
            `Available terms: ${partySnapshot.terms.map(t => `${t.from} to ${t.to || 'open'}`).join(', ')}`
          );
        }

        // Base commission = amount × (rate_bps / 10,000)
        const rateBps = applicableTerm.rate_bps;
        baseAmount = round2(contributionAmount * rateBps / 10000);

        computationDetails = {
          agreement_type: 'party_level_bps',
          pricing_variant: 'BPS',
          rate_bps: rateBps,
          applicable_term: applicableTerm,
          calculation: `${contributionAmount} × (${rateBps} / 10000) = ${baseAmount}`
        };

        // VAT calculation
        if (applicableTerm.vat_mode === 'on_top' && applicableTerm.vat_rate > 0) {
          vatAmount = round2(baseAmount * applicableTerm.vat_rate);
        }
        break;
      }

      case 'BPS_SPLIT': {
        // UPFRONT + DEFERRED BPS (Future: schedule deferred payment)
        if (!partySnapshot.terms || partySnapshot.terms.length === 0) {
          throw new Error(`Agreement ${agreement.id} has no terms in snapshot_json`);
        }

        const applicableTerm = partySnapshot.terms.find(term => {
          const termFrom = new Date(term.from);
          const termTo = term.to ? new Date(term.to) : null;
          const contribDate = new Date(contribution.paid_in_date);

          return contribDate >= termFrom && (!termTo || contribDate < termTo);
        });

        if (!applicableTerm) {
          throw new Error(`No term covers date ${contribution.paid_in_date} for agreement ${agreement.id}`);
        }

        // For now: Only compute UPFRONT portion
        // TODO: Implement deferred payment scheduling
        const upfrontBps = partySnapshot.upfront_bps || applicableTerm.rate_bps;
        const deferredBps = partySnapshot.deferred_bps || 0;

        baseAmount = round2(contributionAmount * upfrontBps / 10000);

        computationDetails = {
          agreement_type: 'party_level_bps_split',
          pricing_variant: 'BPS_SPLIT',
          upfront_bps: upfrontBps,
          deferred_bps: deferredBps,
          calculation: `${contributionAmount} × (${upfrontBps} / 10000) = ${baseAmount} (upfront only, deferred not scheduled yet)`
        };

        // VAT on upfront portion
        if (applicableTerm.vat_mode === 'on_top' && applicableTerm.vat_rate > 0) {
          vatAmount = round2(baseAmount * applicableTerm.vat_rate);
        }
        break;
      }

      case 'FIXED': {
        // FIXED DOLLAR AMOUNT per contribution
        const fixedAmountCents = partySnapshot.fixed_amount_cents;

        if (!fixedAmountCents || fixedAmountCents <= 0) {
          throw new Error(`Agreement ${agreement.id} has FIXED pricing but no valid fixed_amount_cents`);
        }

        // Convert cents to dollars
        baseAmount = round2(fixedAmountCents / 100);

        computationDetails = {
          agreement_type: 'party_level_fixed',
          pricing_variant: 'FIXED',
          fixed_amount_usd: baseAmount,
          calculation: `Fixed: $${baseAmount.toLocaleString()} per contribution`
        };

        // VAT on fixed amount
        const vatRate = partySnapshot.terms?.[0]?.vat_rate || 0;
        const vatMode = partySnapshot.terms?.[0]?.vat_mode || null;

        if (vatMode === 'on_top' && vatRate > 0) {
          vatAmount = round2(baseAmount * vatRate);
        }
        break;
      }

      case 'MGMT_FEE': {
        // MANAGEMENT FEE PERCENTAGE (Not computable yet - requires mgmt fee ledger)
        throw new Error(
          `Agreement ${agreement.id} uses MGMT_FEE pricing which requires a management fee ledger. ` +
          `This feature is not yet implemented. Commission computation blocked.`
        );
      }

      default:
        throw new Error(`Unknown pricing_variant '${pricingVariant}' in agreement ${agreement.id}`);
    }
  }

  const totalAmount = round2(baseAmount + vatAmount);

  // ============================================
  // STEP 5: UPSERT commission row
  // ============================================

  const commissionData = {
    party_id: partyId,
    investor_id: contribution.investor_id,
    contribution_id: contributionId,
    deal_id: contribution.deal_id || null,
    fund_id: contribution.fund_id || null,
    status: 'draft',
    base_amount: baseAmount,
    vat_amount: vatAmount,
    total_amount: totalAmount,
    currency: contribution.currency,
    snapshot_json: {
      ...snapshot,
      computation_details: computationDetails,  // Include calculation breakdown
      contribution_date: contribution.paid_in_date,
      contribution_amount: contributionAmount,
      is_investor_level: isInvestorLevel,
      agreement_id: agreement.id,
    },
    computed_at: new Date().toISOString(),
  };

  const { data: commission, error: upsertError } = await supabase
    .from('commissions')
    .upsert(commissionData, {
      onConflict: 'contribution_id,party_id',
      ignoreDuplicates: false,
    })
    .select()
    .single();

  if (upsertError) {
    throw new Error(`Failed to upsert commission: ${upsertError.message}`);
  }

  // ============================================
  // STEP 6: Return result
  // ============================================

  return {
    id: commission.id, // Use 'id' for consistency with GET endpoint
    commission_id: commission.id, // Keep for backward compat
    status: commission.status,
    party_id: commission.party_id,
    party_name: party.name,
    investor_id: contribution.investor_id,
    investor_name: investor.name,
    base_amount: commission.base_amount,
    vat_amount: commission.vat_amount,
    total_amount: commission.total_amount,
    currency: commission.currency,
    snapshot_json: commission.snapshot_json,
    is_investor_level: isInvestorLevel,
    agreement_type: isInvestorLevel ? (snapshot as any).agreement_type : 'party_level_legacy',
  };
}

// ============================================
// Batch Compute
// ============================================

export async function batchComputeCommissions({
  supabase,
  contributionIds,
}: {
  supabase: SupabaseClient;
  contributionIds: number[];
}): Promise<{ results: ComputeResult[] }> {

  const results: ComputeResult[] = [];

  for (const contributionId of contributionIds) {
    try {
      const result = await computeCommissionForContribution({
        supabase,
        contributionId,
      });
      results.push(result);
    } catch (error) {
      // Log error but continue processing other contributions
      console.error(`Failed to compute commission for contribution ${contributionId}:`, error);
      results.push({
        commission_id: '',
        status: 'error',
        base_amount: 0,
        vat_amount: 0,
        total_amount: 0,
        currency: 'USD',
        snapshot_json: {} as CommissionTermSnapshot,
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  }

  return { results };
}
