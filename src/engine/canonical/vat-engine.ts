import { Money } from '@/domain/money';
import { VatMode, VatRate } from '@/domain/types';

export interface VatCalculationResult {
  fee_gross: number;
  vat_amount: number;
  fee_net: number;
  total_payable: number;
  vat_rate: number;
}

export class VatEngine {
  /**
   * Calculate VAT for a fee amount based on mode (included vs on-top)
   * 
   * INCLUDED: fee_gross already contains VAT → extract it
   *   net = gross / (1 + rate)
   *   vat = gross - net
   *   total = gross
   * 
   * ON_TOP: fee_gross is net → add VAT
   *   net = gross
   *   vat = gross * rate
   *   total = gross + vat
   */
  static calculate(
    feeGross: number,
    vatRate: number,
    vatMode: VatMode
  ): VatCalculationResult {
    const grossAmount = new Money(feeGross);
    const rate = new Money(vatRate);

    if (vatMode === 'included') {
      // VAT is included in the fee amount
      const netAmount = grossAmount.divide(rate.add(new Money(1)).toNumber());
      const vatAmount = grossAmount.subtract(netAmount);

      return {
        fee_gross: grossAmount.toInvoiceAmount(),
        vat_amount: vatAmount.toInvoiceAmount(),
        fee_net: netAmount.toInvoiceAmount(),
        total_payable: grossAmount.toInvoiceAmount(),
        vat_rate: vatRate,
      };
    } else {
      // VAT is added on top
      const netAmount = grossAmount;
      const vatAmount = netAmount.multiply(rate.toNumber());
      const totalAmount = netAmount.add(vatAmount);

      return {
        fee_gross: grossAmount.toInvoiceAmount(),
        vat_amount: vatAmount.toInvoiceAmount(),
        fee_net: netAmount.toInvoiceAmount(),
        total_payable: totalAmount.toInvoiceAmount(),
        vat_rate: vatRate,
      };
    }
  }

  /**
   * Get applicable VAT rate for a country and date from vat_rates table
   */
  static getApplicableRate(
    vatRates: VatRate[],
    countryCode: string,
    asOfDate: string
  ): number {
    const date = new Date(asOfDate);
    
    // Find rates for the country
    const countryRates = vatRates.filter(r => r.country_code === countryCode);
    
    if (countryRates.length === 0) {
      // Try to find default rate
      const defaultRate = vatRates.find(r => r.is_default);
      if (defaultRate) return defaultRate.rate;
      throw new Error(`No VAT rate found for country ${countryCode} and no default rate exists`);
    }

    // Find rate effective on the date
    const applicableRate = countryRates.find(r => {
      const effectiveFrom = new Date(r.effective_from);
      const effectiveTo = r.effective_to ? new Date(r.effective_to) : null;
      
      return (
        effectiveFrom <= date &&
        (!effectiveTo || effectiveTo >= date)
      );
    });

    if (!applicableRate) {
      throw new Error(
        `No VAT rate effective on ${asOfDate} for country ${countryCode}`
      );
    }

    return applicableRate.rate;
  }
}
