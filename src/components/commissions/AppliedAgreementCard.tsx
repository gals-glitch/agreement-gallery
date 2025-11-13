/**
 * Applied Agreement Card
 * UI-02: Commission Detail Enhancement
 *
 * Displays the agreement that was used to calculate a commission,
 * including rate details, VAT handling, and calculation breakdown.
 *
 * SCAFFOLD FILE - Ready to integrate into CommissionDetail page
 */

import { Card } from "@/components/ui/card";
import { Collapsible, CollapsibleTrigger, CollapsibleContent } from "@/components/ui/collapsible";
import { Badge } from "@/components/ui/badge";
import { format } from "date-fns";
import { ChevronDown, ChevronUp } from "lucide-react";
import { useState } from "react";

type AppliedAgreement = {
  agreement_id: number;
  effective_from: string;       // ISO date string
  effective_to?: string | null; // null = ongoing
  rate_bps: number;             // e.g., 100
  vat_percent: number;          // e.g., 17
};

type CommissionCalc = {
  contribution_amount: number;  // 100000
  base_amount: number;          // contribution used for calc (post filters)
  commission_amount: number;    // pre-VAT
  vat_amount: number;
  total_amount: number;         // commission + VAT
  computed_at: string;          // ISO timestamp
  formula_human?: string;       // optional override
};

interface AppliedAgreementCardProps {
  agreement: AppliedAgreement;
  calc: CommissionCalc;
}

export function AppliedAgreementCard({ agreement, calc }: AppliedAgreementCardProps) {
  const [isOpen, setIsOpen] = useState(true);

  const period =
    agreement.effective_from
      ? `${format(new Date(agreement.effective_from), "yyyy-MM-dd")} to ${
          agreement.effective_to
            ? format(new Date(agreement.effective_to), "yyyy-MM-dd")
            : "ongoing"
        }`
      : "—";

  const ratePct = (agreement.rate_bps / 100).toFixed(2); // 100 bps -> 1.00%

  // Detect pricing variant from calculation details (passed through snapshot_json)
  const pricingVariant = (calc as any).pricing_variant || 'BPS';

  // Generate formula based on pricing variant
  let formula: string;
  switch (pricingVariant) {
    case 'FIXED':
      formula = `Fixed: $${calc.commission_amount.toLocaleString()} + ${agreement.vat_percent}% VAT = $${calc.total_amount.toLocaleString()}`;
      break;

    case 'BPS_SPLIT':
      formula = calc.formula_human ??
        `$${calc.base_amount.toLocaleString()} × (${agreement.rate_bps} / 10,000) = $${calc.commission_amount.toLocaleString()} (upfront) + ${agreement.vat_percent}% VAT`;
      break;

    case 'MGMT_FEE':
      formula = `Blocked: Requires management fee ledger (coming soon)`;
      break;

    case 'BPS':
    default:
      formula = calc.formula_human ??
        `$${calc.base_amount.toLocaleString()} × (${agreement.rate_bps} / 10,000) = $${calc.commission_amount.toLocaleString()} + ${agreement.vat_percent}% VAT = $${calc.total_amount.toLocaleString()}`;
      break;
  }

  return (
    <Collapsible open={isOpen} onOpenChange={setIsOpen}>
      <Card>
        <CollapsibleTrigger className="w-full">
          <div className="p-4 w-full text-left">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <div className="font-medium">Applied Agreement</div>
                {isOpen ? (
                  <ChevronUp className="h-4 w-4 text-muted-foreground" />
                ) : (
                  <ChevronDown className="h-4 w-4 text-muted-foreground" />
                )}
              </div>
              <Badge variant="secondary">
                {ratePct}% + VAT {agreement.vat_percent}%
              </Badge>
            </div>
            <div className="text-sm text-muted-foreground mt-1">
              Agreement{" "}
              <a
                className="underline hover:text-primary"
                href={`/agreements/${agreement.agreement_id}`}
                onClick={(e) => e.stopPropagation()}
              >
                #{agreement.agreement_id}
              </a>{" "}
              • {period}
            </div>
          </div>
        </CollapsibleTrigger>
        <CollapsibleContent>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 p-4 pt-0">
            {/* Left Column: Agreement Details */}
            <Card className="p-4">
              <div className="text-xs uppercase tracking-wider text-muted-foreground mb-3">
                Agreement
              </div>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Rate:</span>
                  <span className="font-mono font-semibold">
                    {agreement.rate_bps} bps ({ratePct}%)
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">VAT handling:</span>
                  <span className="font-semibold">
                    {agreement.vat_percent}% on top
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Period:</span>
                  <span className="text-xs">{period}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-muted-foreground">Pricing Structure:</span>
                  <Badge variant="secondary">
                    {pricingVariant === 'BPS' && 'Upfront (bps)'}
                    {pricingVariant === 'BPS_SPLIT' && 'Upfront + Deferred'}
                    {pricingVariant === 'FIXED' && 'Fixed Fee'}
                    {pricingVariant === 'MGMT_FEE' && 'Mgmt Fee %'}
                  </Badge>
                </div>
              </div>
            </Card>

            {/* Right Column: Calculation Breakdown */}
            <Card className="p-4">
              <div className="text-xs uppercase tracking-wider text-muted-foreground mb-3">
                Calculation
              </div>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Contribution:</span>
                  <span className="font-mono font-semibold">
                    ${calc.contribution_amount.toLocaleString()}
                  </span>
                </div>
                <div className="mt-3 mb-3">
                  <div className="text-xs text-muted-foreground mb-1">Formula:</div>
                  <div className="bg-muted/50 p-2 rounded text-xs font-mono break-words">
                    {formula}
                  </div>
                </div>
                <div className="flex justify-between pt-2 border-t">
                  <span className="text-muted-foreground">Computed:</span>
                  <span className="text-xs">
                    {format(new Date(calc.computed_at), "yyyy-MM-dd HH:mm")}
                  </span>
                </div>
              </div>
              <div className="text-xs text-muted-foreground italic mt-4 p-2 bg-muted/30 rounded">
                ℹ️ This calculation is locked and cannot be changed.
              </div>
            </Card>
          </div>
        </CollapsibleContent>
      </Card>
    </Collapsible>
  );
}

/**
 * INTEGRATION GUIDE
 *
 * 1. Add date-fns dependency if not already installed:
 *    npm install date-fns
 *
 * 2. Map your commission detail data to the expected props:
 *
 *    import { AppliedAgreementCard } from '@/components/commissions/AppliedAgreementCard';
 *
 *    // In your CommissionDetail page:
 *    const commission = ...; // from API
 *
 *    const agreementData = {
 *      agreement_id: commission.snapshot_json?.agreement_id,
 *      effective_from: commission.snapshot_json?.terms?.[0]?.from,
 *      effective_to: commission.snapshot_json?.terms?.[0]?.to,
 *      rate_bps: commission.snapshot_json?.terms?.[0]?.rate_bps || 0,
 *      vat_percent: (commission.snapshot_json?.terms?.[0]?.vat_rate || 0) * 100,
 *    };
 *
 *    const calcData = {
 *      contribution_amount: commission.contribution_amount,
 *      base_amount: commission.base_amount,
 *      commission_amount: commission.base_amount, // or pre-VAT amount
 *      vat_amount: commission.vat_amount,
 *      total_amount: commission.total_amount,
 *      computed_at: commission.computed_at,
 *    };
 *
 *    return (
 *      <div>
 *        {/* ... other commission detail cards ... *\/}
 *        <AppliedAgreementCard agreement={agreementData} calc={calcData} />
 *      </div>
 *    );
 *
 * 3. Ensure the commission API returns snapshot_json with this structure:
 *    {
 *      "agreement_id": 123,
 *      "terms": [{
 *        "rate_bps": 100,
 *        "from": "2020-01-01",
 *        "to": null,
 *        "vat_mode": "on_top",
 *        "vat_rate": 0.17
 *      }]
 *    }
 */
