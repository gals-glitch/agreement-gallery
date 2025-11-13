import { Credit, CreditApplication } from '@/domain/types';
import { Money } from '@/domain/money';

/**
 * Credits Scoping Engine
 * Handles scope-aware credit application:
 * - FUND-scoped credits can net both FUND and DEAL fee lines
 * - DEAL-scoped credits can only net DEAL fee lines matching the same deal_id
 */
export class CreditsScopingEngine {
  /**
   * Get available credits for a fee line, respecting scope rules
   * 
   * @param allCredits - All active credits for the investor
   * @param investorName - Investor name
   * @param fundName - Fund name (optional)
   * @param feeLineScope - Scope of the fee line ('FUND' or 'DEAL')
   * @param dealId - Deal ID of the fee line (required if scope is DEAL)
   * @returns Filtered credits that can be applied to this fee line
   */
  static getApplicableCredits(
    allCredits: Credit[],
    investorName: string,
    fundName: string | null | undefined,
    feeLineScope: 'FUND' | 'DEAL',
    dealId?: string | null
  ): Credit[] {
    return allCredits.filter(credit => {
      // Must match investor
      if (credit.investor_name !== investorName) return false;
      
      // Must be active with remaining balance
      if (credit.status !== 'active' || credit.remaining_balance <= 0) return false;
      
      // Check fund match (if credit has fund restriction)
      if (credit.fund_name && fundName && credit.fund_name !== fundName) return false;

      // FUND-scoped credits can net both FUND and DEAL fee lines
      if (credit.scope === 'FUND') {
        return true;
      }

      // DEAL-scoped credits can only net DEAL fee lines with matching deal_id
      if (credit.scope === 'DEAL') {
        // Fee line must also be DEAL-scoped
        if (feeLineScope !== 'DEAL') return false;
        
        // Deal IDs must match
        if (!dealId || !credit.deal_id || credit.deal_id !== dealId) return false;
        
        return true;
      }

      return false;
    });
  }

  /**
   * Apply credits to a fee amount using FIFO order (date, then id)
   * 
   * @param feeAmount - Amount to net against
   * @param applicableCredits - Credits that can be applied (already filtered by scope)
   * @returns Final amount after credits and list of credit applications
   */
  static applyCredits(
    feeAmount: number,
    applicableCredits: Credit[]
  ): {
    final_amount: number;
    credits_applied: CreditApplication[];
    notes?: string;
  } {
    let remainingFee = new Money(feeAmount);
    const creditsApplied: CreditApplication[] = [];
    const creditNotes: string[] = [];

    // Sort credits FIFO: oldest date first, then by ID
    const sortedCredits = [...applicableCredits]
      .sort((a, b) => {
        const dateA = new Date(a.date_posted).getTime();
        const dateB = new Date(b.date_posted).getTime();
        if (dateA !== dateB) return dateA - dateB;
        return a.id.localeCompare(b.id);
      });

    for (const credit of sortedCredits) {
      if (remainingFee.lessThanOrEqual(Money.zero())) break;

      const creditBalance = new Money(credit.remaining_balance);
      const amountToApply = remainingFee.lessThan(creditBalance)
        ? remainingFee
        : creditBalance;

      const newBalance = creditBalance.subtract(amountToApply);

      creditsApplied.push({
        credit_id: credit.id,
        amount_applied: amountToApply.toInvoiceAmount(),
        remaining_balance: newBalance.toInvoiceAmount(),
      });

      remainingFee = remainingFee.subtract(amountToApply);

      const scopeLabel = credit.scope === 'DEAL' ? `DEAL(${credit.deal_id?.substring(0, 8)})` : 'FUND';
      creditNotes.push(
        `Applied ${scopeLabel} ${credit.credit_type} credit ${credit.id.substring(0, 8)}: ${amountToApply.toFixed(2)} (remaining: ${newBalance.toFixed(2)})`
      );
    }

    return {
      final_amount: remainingFee.toInvoiceAmount(),
      credits_applied: creditsApplied,
      notes: creditNotes.length > 0 ? creditNotes.join('; ') : undefined,
    };
  }

  /**
   * Persist credit applications to the database
   */
  static async persistCreditApplications(
    creditsApplied: CreditApplication[],
    calculationRunId: string,
    distributionId: string,
    supabase: any
  ): Promise<void> {
    if (creditsApplied.length === 0) return;

    const records = creditsApplied.map(ca => ({
      credit_id: ca.credit_id,
      calculation_run_id: calculationRunId,
      distribution_id: distributionId,
      applied_amount: ca.amount_applied,
      applied_date: new Date().toISOString().split('T')[0],
    }));

    const { error: insertError } = await supabase
      .from('credit_applications')
      .insert(records);

    if (insertError) {
      console.error('Failed to persist credit applications:', insertError);
      throw insertError;
    }

    // Update remaining balances on credits
    for (const ca of creditsApplied) {
      const { error: updateError } = await supabase
        .from('credits')
        .update({ remaining_balance: ca.remaining_balance })
        .eq('id', ca.credit_id);

      if (updateError) {
        console.error(`Failed to update credit ${ca.credit_id}:`, updateError);
      }
    }
  }
}
