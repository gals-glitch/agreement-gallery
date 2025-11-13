/**
 * VAT Rates Table Component
 * Displays a table of VAT rates with actions
 */

import { MoreHorizontal, Calendar, XCircle, Trash2 } from 'lucide-react';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { Button } from '@/components/ui/button';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { Badge } from '@/components/ui/badge';
import type { VatRate } from '@/types/vat';
import { formatDate, formatPercentage, getCountryFlag, getCountryName } from '@/types/vat';

interface VatRatesTableProps {
  rates: VatRate[];
  isLoading?: boolean;
  emptyMessage: string;
  readOnly?: boolean;
  onCloseRate?: (rate: VatRate) => void;
  onDeleteRate?: (rate: VatRate) => void;
}

export function VatRatesTable({
  rates,
  isLoading,
  emptyMessage,
  readOnly = false,
  onCloseRate,
  onDeleteRate,
}: VatRatesTableProps) {
  if (isLoading) {
    return (
      <div className="text-center py-8 text-muted-foreground">
        Loading VAT rates...
      </div>
    );
  }

  if (rates.length === 0) {
    return (
      <div className="text-center py-8 text-muted-foreground">
        {emptyMessage}
      </div>
    );
  }

  return (
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead>Country</TableHead>
          <TableHead>Rate</TableHead>
          <TableHead>Effective From</TableHead>
          <TableHead>Effective To</TableHead>
          <TableHead>Description</TableHead>
          {!readOnly && <TableHead className="text-right">Actions</TableHead>}
        </TableRow>
      </TableHeader>
      <TableBody>
        {rates.map((rate) => (
          <TableRow key={rate.id}>
            <TableCell>
              <div className="flex items-center gap-2">
                <span className="text-xl">{getCountryFlag(rate.country_code)}</span>
                <div>
                  <div className="font-medium">{rate.country_code}</div>
                  <div className="text-xs text-muted-foreground">
                    {getCountryName(rate.country_code)}
                  </div>
                </div>
              </div>
            </TableCell>
            <TableCell>
              <Badge variant="secondary" className="font-mono">
                {formatPercentage(rate.rate_percentage)}
              </Badge>
            </TableCell>
            <TableCell>{formatDate(rate.effective_from)}</TableCell>
            <TableCell>
              {rate.effective_to ? (
                formatDate(rate.effective_to)
              ) : (
                <Badge variant="outline">Current</Badge>
              )}
            </TableCell>
            <TableCell className="max-w-xs truncate">
              {rate.description || '-'}
            </TableCell>
            {!readOnly && (
              <TableCell className="text-right">
                <DropdownMenu>
                  <DropdownMenuTrigger asChild>
                    <Button variant="ghost" size="sm">
                      <MoreHorizontal className="h-4 w-4" />
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="end">
                    {!rate.effective_to && onCloseRate && (
                      <DropdownMenuItem onClick={() => onCloseRate(rate)}>
                        <Calendar className="mr-2 h-4 w-4" />
                        Close Rate
                      </DropdownMenuItem>
                    )}
                    {onDeleteRate && (
                      <DropdownMenuItem
                        onClick={() => onDeleteRate(rate)}
                        className="text-destructive"
                      >
                        <Trash2 className="mr-2 h-4 w-4" />
                        Delete
                      </DropdownMenuItem>
                    )}
                  </DropdownMenuContent>
                </DropdownMenu>
              </TableCell>
            )}
          </TableRow>
        ))}
      </TableBody>
    </Table>
  );
}
