/**
 * Charge Compute Core Logic (P2-2)
 * Ticket: P2-2
 * Date: 2025-10-19
 *
 * Purpose:
 * Calculate referral fees on paid-in contributions using approved agreement snapshots.
 * This is the heart of P2 - it computes charges with proper precedence rules.
 *
 * Business Rules:
 * - Basis: % of paid-in contributions (NOT distributions)
 * - Order: base → discounts → VAT → cap clamp
 * - VAT Modes:
 *   - on_top: Add VAT after discounts (VAT = taxable × rate)
 *   - included: Treat total as VAT-inclusive (do NOT add additional VAT)
 *   - exempt: No VAT applied
 * - Term Selection:
 *   - Match by contribution.paid_in_date against term date windows (before/between/after)
 *   - Tie-break: Most specific (shortest duration; if equal, latest start_date)
 * - Currency Rounding: 2 decimal places, "half-up" (e.g., 1.225 → 1.23)
 * - Credits: Applied on submit (NOT during compute) via creditsEngine.ts FIFO
 *
 * Integration:
 * - Called when contribution is created/updated
 * - Creates/updates DRAFT charge (idempotent: one charge per contribution)
 * - Charge can be recomputed if still in DRAFT status
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';

// ============================================
// TYPES
// ============================================

interface Charge {
  id: string;
  investor_id: number;
  deal_id: number | null;
  fund_id: number | null;
  contribution_id: number;
  status: string;
  base_amount: number;
  discount_amount: number;
  vat_amount: number;
  total_amount: number;
  currency: string;
  snapshot_json: SnapshotJson;
  computed_at: string;
  created_at: string;
  updated_at: string;
}

interface SnapshotJson {
  agreement_id: number;
  agreement_version: number;
  term: Term;
  vat_rate: number;
  vat_mode: 'on_top' | 'included' | 'exempt';
  computed_rules: {
    is_gp: boolean;
    rate_pct: number;
    discounts: Discount[];
    cap: number | null;
  };
  contribution: {
    id: number;
    amount: number;
    paid_in_date: string;
    deal_id: number | null;
    fund_id: number | null;
  };
}

interface AgreementSnapshot {
  id: number;
  party_id: number;
  status: string;
  scope: 'FUND' | 'DEAL';
  pricing_mode: 'TRACK' | 'CUSTOM';
  selected_track: string | null;
  vat_included: boolean;
  effective_from: string;
  effective_to: string | null;
  snapshot_json?: {
    terms?: Term[];
    vat_rate?: number;
    resolved_upfront_bps?: number;
    resolved_deferred_bps?: number;
  };
}

interface Term {
  start_date: string | null;
  end_date: string | null;
  rate_pct: number;
  discounts?: Discount[];
  cap?: number;
  vat_mode: 'on_top' | 'included' | 'exempt';
}

interface Discount {
  type: 'percentage' | 'fixed';
  value: number;
  description?: string;
}

interface Contribution {
  id: number;
  investor_id: number;
  deal_id: number | null;
  fund_id: number | null;
  paid_in_date: string;
  amount: number;
  currency: string;
}

interface Investor {
  id: number;
  name: string;
  is_gp: boolean;
}

// ============================================
// MAIN FUNCTION: Compute Charge
// ============================================

/**
 * Compute charge for a contribution
 * Creates or updates a DRAFT charge with calculated fees
 *
 * Algorithm:
 * 1. Fetch contribution + investor + deal/fund
 * 2. Check if investor is GP (exclude from fees)
 * 3. Resolve approved agreement snapshot (deal-level first, then fund-level fallback)
 * 4. Select matching term by contribution date
 * 5. Calculate fee components: base → discounts → VAT → cap clamp
 * 6. Build snapshot_json (immutable record)
 * 7. Upsert DRAFT charge (idempotent: one charge per contribution)
 *
 * @param contributionId - UUID or number ID of the contribution
 * @returns Charge object or null if no approved agreement exists
 */
export async function computeCharge(
  contributionId: string | number
): Promise<Charge | null> {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );

  // 1. Fetch contribution + investor + deal/fund
  const { data: contribution, error: contribError } = await supabase
    .from('contributions')
    .select(`
      *,
      investor:investors(*)
    `)
    .eq('id', contributionId)
    .single();

  if (contribError || !contribution) {
    throw new Error(`Contribution not found: ${contributionId}`);
  }

  const investor = contribution.investor as unknown as Investor;

  // 2. Check if investor is GP (exclude from fees)
  const isGP = await checkIfGP(supabase, contribution.investor_id);

  // 3. Resolve approved agreement snapshot (deal-level first, then fund-level fallback)
  const snapshot = await resolveAgreementSnapshot(
    supabase,
    contribution.investor_id,
    contribution.deal_id,
    contribution.fund_id
  );

  if (!snapshot) {
    console.log(`No approved agreement for investor ${contribution.investor_id}`);
    return null; // No charge created
  }

  // 4. Select matching term by contribution date
  const term = selectTerm(snapshot, contribution.paid_in_date);

  if (!term) {
    console.log(`No matching term for date ${contribution.paid_in_date}`);
    return null; // No charge created
  }

  // 5. Calculate fee components
  let base_amount = 0;
  let discount_amount = 0;
  let vat_amount = 0;
  let total_amount = 0;

  // Get VAT rate from snapshot or default
  const vat_rate = snapshot.snapshot_json?.vat_rate || 0;

  if (!isGP) {
    // Base fee = contribution amount × rate percentage
    base_amount = round(contribution.amount * (term.rate_pct / 100));

    // Discounts (if any in term)
    discount_amount = calculateDiscounts(term, contribution.amount);

    // Taxable amount (base - discounts)
    const taxable = base_amount - discount_amount;

    // VAT calculation
    if (term.vat_mode === 'on_top') {
      vat_amount = round(taxable * vat_rate);
    } else if (term.vat_mode === 'included') {
      vat_amount = 0; // Total already includes VAT
    } else if (term.vat_mode === 'exempt') {
      vat_amount = 0;
    }

    // Total before cap
    total_amount = taxable + vat_amount;

    // Apply cap if specified
    if (term.cap && total_amount > term.cap) {
      total_amount = term.cap;
    }

    // Final rounding
    total_amount = round(total_amount);
  }
  // else: GP investor → all amounts = 0

  // 6. Build snapshot_json (immutable record)
  const snapshot_json: SnapshotJson = {
    agreement_id: snapshot.id,
    agreement_version: 1, // TODO: Add versioning to agreements table
    term: term,
    vat_rate: vat_rate,
    vat_mode: term.vat_mode,
    computed_rules: {
      is_gp: isGP,
      rate_pct: term.rate_pct,
      discounts: term.discounts || [],
      cap: term.cap || null,
    },
    contribution: {
      id: contribution.id,
      amount: contribution.amount,
      paid_in_date: contribution.paid_in_date,
      deal_id: contribution.deal_id,
      fund_id: contribution.fund_id,
    }
  };

  // 7. Upsert DRAFT charge (idempotent: one charge per contribution)
  const { data: existingCharge } = await supabase
    .from('charges')
    .select('id')
    .eq('contribution_id', contributionId)
    .single();

  const chargeData = {
    investor_id: contribution.investor_id,
    deal_id: contribution.deal_id,
    fund_id: contribution.fund_id,
    contribution_id: contribution.id,
    status: 'DRAFT',
    base_amount,
    discount_amount,
    vat_amount,
    total_amount,
    currency: contribution.currency || 'USD',
    snapshot_json,
    computed_at: new Date().toISOString(),
  };

  if (existingCharge) {
    // Update existing DRAFT charge (only if still DRAFT)
    const { data: charge, error } = await supabase
      .from('charges')
      .update(chargeData)
      .eq('id', existingCharge.id)
      .eq('status', 'DRAFT') // Only update if still DRAFT
      .select()
      .single();

    if (error) {
      console.warn(`Charge ${existingCharge.id} not DRAFT or error, skipping update:`, error);
      // Fetch and return the existing charge instead
      const { data: existingChargeData } = await supabase
        .from('charges')
        .select('*')
        .eq('id', existingCharge.id)
        .single();
      return existingChargeData as Charge | null;
    }

    return charge as Charge;
  } else {
    // Create new DRAFT charge
    const { data: charge, error } = await supabase
      .from('charges')
      .insert(chargeData)
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to create charge: ${error.message}`);
    }

    return charge as Charge;
  }
}

// ============================================
// HELPER FUNCTIONS
// ============================================

/**
 * Check if investor is GP (excluded from fees)
 *
 * Business Rule:
 * - GP investors are identified by is_gp flag on investors table
 * - GP investors receive charges with $0 fees (but charge still created for audit trail)
 *
 * @param supabase - Supabase client instance
 * @param investorId - Investor ID to check
 * @returns true if investor is GP, false otherwise
 */
async function checkIfGP(supabase: any, investorId: number): Promise<boolean> {
  const { data: investor } = await supabase
    .from('investors')
    .select('is_gp')
    .eq('id', investorId)
    .single();

  return investor?.is_gp || false;
}

/**
 * Resolve approved agreement snapshot
 *
 * Precedence Rules:
 * 1. Deal-level agreement (if contribution is deal-scoped)
 * 2. Fund-level agreement (fallback)
 *
 * Only APPROVED agreements are considered.
 * Latest version is used (order by id DESC).
 *
 * @param supabase - Supabase client instance
 * @param investorId - Investor ID
 * @param dealId - Deal ID (may be null)
 * @param fundId - Fund ID (may be null)
 * @returns Agreement snapshot or null if no approved agreement found
 */
async function resolveAgreementSnapshot(
  supabase: any,
  investorId: number,
  dealId: number | null,
  fundId: number | null
): Promise<AgreementSnapshot | null> {
  // Try deal-level agreement first (if contribution is deal-scoped)
  if (dealId) {
    const { data: dealAgreements } = await supabase
      .from('agreements')
      .select('*')
      .eq('party_id', investorId) // Note: agreements use party_id, not investor_id
      .eq('deal_id', dealId)
      .eq('status', 'APPROVED')
      .order('id', { ascending: false })
      .limit(1);

    if (dealAgreements && dealAgreements.length > 0) {
      return dealAgreements[0] as AgreementSnapshot;
    }
  }

  // Fallback to fund-level agreement
  if (fundId) {
    const { data: fundAgreements } = await supabase
      .from('agreements')
      .select('*')
      .eq('party_id', investorId)
      .eq('fund_id', fundId)
      .eq('status', 'APPROVED')
      .order('id', { ascending: false })
      .limit(1);

    if (fundAgreements && fundAgreements.length > 0) {
      return fundAgreements[0] as AgreementSnapshot;
    }
  }

  return null; // No approved agreement found
}

/**
 * Select matching term by contribution date
 *
 * Algorithm:
 * 1. Filter terms that match the contribution date (date >= start AND date <= end)
 * 2. If multiple matches, tie-break by:
 *    a. Shortest duration (most specific)
 *    b. If equal duration, latest start_date
 *
 * Date Handling:
 * - Null start_date = beginning of time (matches all dates before end_date)
 * - Null end_date = end of time (matches all dates after start_date)
 *
 * @param snapshot - Agreement snapshot containing terms
 * @param contributionDate - Contribution paid_in_date
 * @returns Matching term or null if no match
 */
function selectTerm(
  snapshot: AgreementSnapshot,
  contributionDate: string
): Term | null {
  const date = new Date(contributionDate);

  // Build terms from snapshot
  const terms = buildTermsFromSnapshot(snapshot);

  if (terms.length === 0) {
    return null;
  }

  // Filter terms that match the contribution date
  const matchingTerms = terms.filter(term => {
    const start = term.start_date ? new Date(term.start_date) : new Date(0);
    const end = term.end_date ? new Date(term.end_date) : new Date('9999-12-31');
    return date >= start && date <= end;
  });

  if (matchingTerms.length === 0) {
    return null;
  }

  if (matchingTerms.length === 1) {
    return matchingTerms[0];
  }

  // Tie-break: shortest duration (most specific)
  matchingTerms.sort((a, b) => {
    const aStart = a.start_date ? new Date(a.start_date) : new Date(0);
    const aEnd = a.end_date ? new Date(a.end_date) : new Date('9999-12-31');
    const bStart = b.start_date ? new Date(b.start_date) : new Date(0);
    const bEnd = b.end_date ? new Date(b.end_date) : new Date('9999-12-31');

    const aDuration = aEnd.getTime() - aStart.getTime();
    const bDuration = bEnd.getTime() - bStart.getTime();

    if (aDuration !== bDuration) {
      return aDuration - bDuration; // Shortest first (most specific)
    }

    // If equal duration, latest start_date wins
    return bStart.getTime() - aStart.getTime();
  });

  return matchingTerms[0];
}

/**
 * Build terms array from agreement snapshot
 *
 * For MVP: Create a single term from the agreement's resolved rates
 * Future: Support multiple terms with date ranges
 *
 * @param snapshot - Agreement snapshot
 * @returns Array of terms
 */
function buildTermsFromSnapshot(snapshot: AgreementSnapshot): Term[] {
  // For MVP: Use resolved rates from snapshot_json or calculate from pricing_mode
  const resolvedUpfrontBps = snapshot.snapshot_json?.resolved_upfront_bps || 0;
  const resolvedDeferredBps = snapshot.snapshot_json?.resolved_deferred_bps || 0;

  // Calculate total rate percentage (upfront + deferred)
  const ratePct = (resolvedUpfrontBps + resolvedDeferredBps) / 100; // Convert bps to percentage

  // For MVP: Create a single term covering the agreement's effective date range
  const term: Term = {
    start_date: snapshot.effective_from,
    end_date: snapshot.effective_to,
    rate_pct: ratePct,
    discounts: [], // MVP: No discounts yet
    cap: undefined, // MVP: No caps yet
    vat_mode: snapshot.vat_included ? 'included' : 'on_top',
  };

  return [term];
}

/**
 * Calculate discounts (if any in term)
 *
 * Discount Types:
 * - percentage: Discount as % of contribution amount
 * - fixed: Discount as fixed currency amount
 *
 * Multiple Discounts: Sum all discounts (additive)
 *
 * @param term - Term containing discount rules
 * @param contributionAmount - Contribution amount (basis for percentage discounts)
 * @returns Total discount amount
 */
function calculateDiscounts(term: Term, contributionAmount: number): number {
  if (!term.discounts || term.discounts.length === 0) {
    return 0;
  }

  // Sum all discounts (future: support different discount strategies)
  let totalDiscount = 0;
  for (const discount of term.discounts) {
    if (discount.type === 'percentage') {
      totalDiscount += round(contributionAmount * (discount.value / 100));
    } else if (discount.type === 'fixed') {
      totalDiscount += discount.value;
    }
  }

  return round(totalDiscount);
}

/**
 * Round to 2 decimal places using "half-up" rounding
 *
 * JavaScript's Math.round rounds to nearest integer.
 * To round to 2 decimals:
 * 1. Multiply by 100 (shift decimal 2 places right)
 * 2. Round to nearest integer
 * 3. Divide by 100 (shift decimal 2 places left)
 *
 * Examples:
 * - 1.225 → 122.5 → 123 → 1.23
 * - 1.224 → 122.4 → 122 → 1.22
 *
 * @param value - Number to round
 * @returns Rounded value (2 decimal places)
 */
function round(value: number): number {
  return Math.round(value * 100) / 100;
}

// ============================================
// HELPER: Get Charge by Contribution ID
// ============================================

/**
 * Get existing charge for a contribution (for UI display)
 *
 * @param contributionId - Contribution ID
 * @returns Charge or null if not found
 */
export async function getChargeByContribution(
  contributionId: string | number
): Promise<Charge | null> {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );

  const { data: charge, error } = await supabase
    .from('charges')
    .select('*')
    .eq('contribution_id', contributionId)
    .single();

  if (error || !charge) {
    return null;
  }

  return charge as Charge;
}

// ============================================
// HELPER: Batch Compute Charges
// ============================================

/**
 * Compute charges for multiple contributions
 * Useful for bulk processing or recalculations
 *
 * @param contributionIds - Array of contribution IDs
 * @returns Array of charges (null entries if no agreement found)
 */
export async function batchComputeCharges(
  contributionIds: (string | number)[]
): Promise<(Charge | null)[]> {
  const charges: (Charge | null)[] = [];

  for (const contributionId of contributionIds) {
    try {
      const charge = await computeCharge(contributionId);
      charges.push(charge);
    } catch (error) {
      console.error(`Failed to compute charge for contribution ${contributionId}:`, error);
      charges.push(null);
    }
  }

  return charges;
}
