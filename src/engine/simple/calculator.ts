/**
 * Simplified Fund VI calculation engine
 * No generic rules - just A/B/C tracks with upfront/deferred split
 */

import { supabase } from '@/integrations/supabase/client';
import { Money } from '@/domain/money';
import type {
  CalculationInput,
  CalculationOutput,
  FundVITrack,
  Agreement,
  Credit,
  FeeLine,
  Contribution,
  TrackKey,
  VatMode,
} from './types';

export class SimpleFeeCalculator {
  private tracks: Map<TrackKey, FundVITrack> = new Map();
  private agreements: Map<string, Agreement> = new Map();
  private credits: Map<string, Credit[]> = new Map();
  private vatRates: Map<string, number> = new Map();

  /**
   * Load config for a calculation run
   */
  async loadConfig(configVersion: string): Promise<void> {
    // Load Fund VI tracks
    const { data: tracksData, error: tracksError } = await supabase
      .from('fund_vi_tracks')
      .select('*')
      .eq('config_version', configVersion)
      .eq('is_active', true);

    if (tracksError) throw new Error(`Failed to load tracks: ${tracksError.message}`);
    
    tracksData?.forEach(track => {
      this.tracks.set(track.track_key as TrackKey, track as FundVITrack);
    });

    // Load VAT rates (simplified - using default IL rate)
    const { data: vatData } = await supabase
      .from('vat_rates')
      .select('*')
      .eq('country_code', 'IL')
      .eq('is_default', true)
      .single();

    if (vatData) {
      this.vatRates.set('IL', Number(vatData.rate));
    }
  }

  /**
   * Load agreements for contributors
   */
  async loadAgreements(investorIds: string[]): Promise<void> {
    const { data, error } = await supabase
      .from('agreements')
      .select('id, track_key, vat_mode')
      .in('introduced_by_party_id', investorIds)
      .eq('status', 'active');

    if (error) throw new Error(`Failed to load agreements: ${error.message}`);
    
    data?.forEach(agreement => {
      this.agreements.set(agreement.id, agreement as Agreement);
    });
  }

  /**
   * Load available credits for investors
   */
  async loadCredits(investorNames: string[]): Promise<void> {
    const { data, error } = await supabase
      .from('credits')
      .select('*')
      .in('investor_name', investorNames)
      .eq('status', 'active')
      .gt('remaining_balance', 0)
      .order('date_posted', { ascending: true }); // FIFO

    if (error) throw new Error(`Failed to load credits: ${error.message}`);
    
    data?.forEach(credit => {
      const key = `${credit.investor_name}|${credit.fund_name}`;
      if (!this.credits.has(key)) {
        this.credits.set(key, []);
      }
      this.credits.get(key)!.push(credit as Credit);
    });
  }

  /**
   * Determine track for a contribution (by raised amount or assigned track)
   */
  determineTrack(raisedAmount: number, assignedTrack?: TrackKey): FundVITrack {
    if (assignedTrack && this.tracks.has(assignedTrack)) {
      return this.tracks.get(assignedTrack)!;
    }

    // Find by raised amount
    for (const track of this.tracks.values()) {
      if (raisedAmount >= track.min_raised && 
          (track.max_raised === null || raisedAmount < track.max_raised)) {
        return track;
      }
    }

    // Default to Track A
    return this.tracks.get('A')!;
  }

  /**
   * Apply VAT (included or on-top)
   */
  applyVAT(feeGross: Money, mode: VatMode, rate: number): { vat: Money; net: Money } {
    if (mode === 'included') {
      // Fee includes VAT: net = gross / (1 + rate), vat = gross - net
      const net = feeGross.divide(1 + rate);
      const vat = feeGross.subtract(net);
      return { vat, net };
    } else {
      // VAT on top: vat = gross * rate, net = gross
      const vat = feeGross.multiply(rate);
      return { vat, net: feeGross };
    }
  }

  /**
   * Apply credits FIFO to a fee line
   */
  applyCredits(
    investorName: string,
    fundName: string,
    amountDue: Money
  ): { creditsApplied: Money; remaining: Money } {
    const key = `${investorName}|${fundName}`;
    const availableCredits = this.credits.get(key) || [];
    
    let remaining = amountDue;
    let creditsApplied = Money.zero();

    for (const credit of availableCredits) {
      if (remaining.isZero()) break;
      
      const creditBalance = new Money(credit.remaining_balance);
      const toApply = remaining.lessThan(creditBalance) ? remaining : creditBalance;
      
      creditsApplied = creditsApplied.add(toApply);
      remaining = remaining.subtract(toApply);
      credit.remaining_balance = creditBalance.subtract(toApply).toNumber();
    }

    return { creditsApplied, remaining };
  }

  /**
   * Calculate fees for a single contribution
   */
  calculateContribution(
    contribution: Contribution,
    track: FundVITrack,
    agreement: Agreement
  ): FeeLine[] {
    const baseAmount = new Money(contribution.distribution_amount);
    const vatRate = this.vatRates.get('IL') || 0.17;
    const lines: FeeLine[] = [];

    // Upfront fee
    const upfrontRate = track.upfront_rate_bps / 10000;
    const upfrontGross = baseAmount.multiply(upfrontRate);
    const upfrontVAT = this.applyVAT(upfrontGross, agreement.vat_mode, vatRate);
    const upfrontCredits = this.applyCredits(
      contribution.investor_name,
      contribution.fund_name,
      upfrontGross.add(upfrontVAT.vat)
    );

    lines.push({
      contribution_id: contribution.id,
      investor_name: contribution.investor_name,
      fund_name: contribution.fund_name,
      track_key: track.track_key,
      line_type: 'upfront',
      base_amount: baseAmount.toNumber(),
      rate_bps: track.upfront_rate_bps,
      fee_gross: upfrontGross.toNumber(),
      vat_amount: upfrontVAT.vat.toNumber(),
      fee_net: upfrontVAT.net.toNumber(),
      credits_applied: upfrontCredits.creditsApplied.toNumber(),
      total_payable: upfrontCredits.remaining.toNumber(),
      payment_date: contribution.distribution_date,
    });

    // Deferred fee (+24 months)
    if (track.deferred_rate_bps > 0) {
      const deferredRate = track.deferred_rate_bps / 10000;
      const deferredGross = baseAmount.multiply(deferredRate);
      const deferredVAT = this.applyVAT(deferredGross, agreement.vat_mode, vatRate);
      const deferredDate = new Date(contribution.distribution_date);
      deferredDate.setMonth(deferredDate.getMonth() + track.deferred_offset_months);
      const deferredCredits = this.applyCredits(
        contribution.investor_name,
        contribution.fund_name,
        deferredGross.add(deferredVAT.vat)
      );

      lines.push({
        contribution_id: contribution.id,
        investor_name: contribution.investor_name,
        fund_name: contribution.fund_name,
        track_key: track.track_key,
        line_type: 'deferred',
        base_amount: baseAmount.toNumber(),
        rate_bps: track.deferred_rate_bps,
        fee_gross: deferredGross.toNumber(),
        vat_amount: deferredVAT.vat.toNumber(),
        fee_net: deferredVAT.net.toNumber(),
        credits_applied: deferredCredits.creditsApplied.toNumber(),
        total_payable: deferredCredits.remaining.toNumber(),
        payment_date: deferredDate.toISOString().split('T')[0],
      });
    }

    return lines;
  }

  /**
   * Main calculation entry point
   */
  async calculate(input: CalculationInput): Promise<CalculationOutput> {
    // Load configuration
    await this.loadConfig(input.config_version);
    
    const investorNames = [...new Set(input.contributions.map(c => c.investor_name))];
    await this.loadCredits(investorNames);

    // Calculate all fee lines
    const allLines: FeeLine[] = [];
    
    for (const contribution of input.contributions) {
      // For MVP: assume all contributions are Track A (can enhance later)
      const track = this.determineTrack(contribution.distribution_amount, 'A');
      
      // For MVP: use default VAT mode 'added'
      const agreement: Agreement = {
        id: 'default',
        investor_id: contribution.investor_id,
        fund_id: contribution.fund_name,
        track_key: track.track_key,
        vat_mode: 'added',
      };

      const lines = this.calculateContribution(contribution, track, agreement);
      allLines.push(...lines);
    }

    // Calculate totals
    const totals = allLines.reduce(
      (acc, line) => ({
        gross: acc.gross + line.fee_gross,
        vat: acc.vat + line.vat_amount,
        net: acc.net + line.fee_net,
        credits: acc.credits + line.credits_applied,
        payable: acc.payable + line.total_payable,
      }),
      { gross: 0, vat: 0, net: 0, credits: 0, payable: 0 }
    );

    return {
      run_id: input.run_id,
      config_version: input.config_version,
      fee_lines: allLines,
      total_gross: totals.gross,
      total_vat: totals.vat,
      total_net: totals.net,
      total_credits: totals.credits,
      total_payable: totals.payable,
    };
  }
}
