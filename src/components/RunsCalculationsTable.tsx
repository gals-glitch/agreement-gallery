import React, { useState } from 'react';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip';
import { Dialog } from '@/components/ui/dialog';
import { Target, Building2, Plus } from 'lucide-react';
import AgreementManagementEnhanced from './AgreementManagementEnhanced';

interface Calculation {
  id: string;
  entity_name: string;
  entity_id?: string;
  commission_type: string;
  base_amount: number;
  applied_rate: number;
  gross_commission: number;
  vat_amount: number;
  net_commission: number;
  scope?: 'FUND' | 'DEAL';
  deal_id?: string;
  deal_name?: string;
  deal_code?: string;
  has_agreement?: boolean;
}

interface Props {
  calculations: Calculation[];
  scopeFilter?: 'both' | 'FUND' | 'DEAL';
  dealFilter?: string;
}

export function RunsCalculationsTable({ calculations, scopeFilter = 'both', dealFilter = 'all' }: Props) {
  const [agreementDialogOpen, setAgreementDialogOpen] = useState(false);
  const [preselectPartyId, setPreselectPartyId] = useState<string | undefined>();

  // Filter calculations based on scope and deal
  const filteredCalculations = calculations.filter(calc => {
    if (scopeFilter !== 'both' && calc.scope !== scopeFilter) return false;
    if (dealFilter !== 'all' && calc.deal_id !== dealFilter) return false;
    return true;
  });

  const handleCreateAgreement = (partyId: string | undefined) => {
    setPreselectPartyId(partyId);
    setAgreementDialogOpen(true);
  };

  return (
    <>
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Party</TableHead>
            <TableHead>Scope</TableHead>
            <TableHead>Type</TableHead>
            <TableHead>Base Amount</TableHead>
            <TableHead>Rate</TableHead>
            <TableHead>Gross</TableHead>
            <TableHead>VAT</TableHead>
            <TableHead>Net</TableHead>
            <TableHead>Actions</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {filteredCalculations.length === 0 ? (
            <TableRow>
              <TableCell colSpan={9} className="text-center text-muted-foreground py-8">
                No calculations match the current filters
              </TableCell>
            </TableRow>
          ) : (
            filteredCalculations.map(calc => (
              <TableRow key={calc.id}>
                <TableCell className="font-medium">{calc.entity_name}</TableCell>
                <TableCell>
                  <TooltipProvider>
                    <Tooltip>
                      <TooltipTrigger asChild>
                        <Badge 
                          variant={calc.scope === 'DEAL' ? 'default' : 'secondary'}
                          className="gap-1 cursor-help"
                        >
                          {calc.scope === 'DEAL' ? (
                            <>
                              <Target className="w-3 h-3" />
                              DEAL
                            </>
                          ) : (
                            <>
                              <Building2 className="w-3 h-3" />
                              FUND
                            </>
                          )}
                        </Badge>
                      </TooltipTrigger>
                      <TooltipContent>
                        {calc.scope === 'DEAL' 
                          ? `Deal-specific fee for ${calc.deal_name || calc.deal_code}. Overrides fund-level agreement.`
                          : 'Fund-level fee. Applies to all distributions unless overridden by a deal-specific agreement.'
                        }
                      </TooltipContent>
                    </Tooltip>
                  </TooltipProvider>
                </TableCell>
                <TableCell>{calc.commission_type}</TableCell>
                <TableCell className="font-mono">${calc.base_amount.toLocaleString()}</TableCell>
                <TableCell>{(calc.applied_rate * 100).toFixed(3)}%</TableCell>
                <TableCell className="font-mono">${calc.gross_commission.toLocaleString()}</TableCell>
                <TableCell className="font-mono">${calc.vat_amount.toLocaleString()}</TableCell>
                <TableCell className="font-mono font-semibold">${calc.net_commission.toLocaleString()}</TableCell>
                <TableCell>
                  {!calc.has_agreement && (
                    <TooltipProvider>
                      <Tooltip>
                        <TooltipTrigger asChild>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => handleCreateAgreement(calc.entity_id)}
                            className="gap-1 h-8 px-2"
                          >
                            <Plus className="w-3 h-3" />
                            Agreement
                          </Button>
                        </TooltipTrigger>
                        <TooltipContent>
                          No agreement found for this party. Click to create one.
                        </TooltipContent>
                      </Tooltip>
                    </TooltipProvider>
                  )}
                </TableCell>
              </TableRow>
            ))
          )}
        </TableBody>
      </Table>

      {/* Agreement Dialog */}
      <Dialog open={agreementDialogOpen} onOpenChange={setAgreementDialogOpen}>
        <AgreementManagementEnhanced preselectPartyId={preselectPartyId} />
      </Dialog>
    </>
  );
}
