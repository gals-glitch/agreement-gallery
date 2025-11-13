import { Money } from '@/domain/money';
import { Credit, CreditApplication } from '@/domain/types';

export interface CreditApplicationResult {
  final_amount: number;
  credits_applied: CreditApplication[];
  notes?: string;
}

export class CreditEngine {
  /**
   * Apply available credits to reduce fee amount
   * Credits are applied in FIFO order (oldest first) until exhausted or fee is zero
   */
  static applyCredits(
    feeAmount: number,
    availableCredits: Credit[]
  ): CreditApplicationResult {
    let remainingFee = new Money(feeAmount);
    const creditsApplied: CreditApplication[] = [];
    const creditNotes: string[] = [];

    // Sort credits by date (oldest first) and filter active ones with remaining balance
    const activeCredits = availableCredits
      .filter(c => c.status === 'active' && c.remaining_balance > 0)
      .sort((a, b) => new Date(a.date_posted).getTime() - new Date(b.date_posted).getTime());

    for (const credit of activeCredits) {
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

      creditNotes.push(
        `Applied ${credit.credit_type} credit ${credit.id.substring(0, 8)}: ${amountToApply.toFixed(2)} (remaining: ${newBalance.toFixed(2)})`
      );
    }

    return {
      final_amount: remainingFee.toInvoiceAmount(),
      credits_applied: creditsApplied,
      notes: creditNotes.length > 0 ? creditNotes.join('; ') : undefined,
    };
  }

  /**
   * Get available credits for an investor and fund
   */
  static getAvailableCredits(
    allCredits: Credit[],
    investorName: string,
    fundName?: string
  ): Credit[] {
    return allCredits.filter(
      c =>
        c.investor_name === investorName &&
        c.status === 'active' &&
        c.remaining_balance > 0 &&
        (!fundName || !c.fund_name || c.fund_name === fundName)
    );
  }
}
