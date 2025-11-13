/**
 * VAT Snapshot Display Component
 * Shows immutable VAT snapshot data from agreement approval
 */

import { Lock, Info } from 'lucide-react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Alert, AlertDescription } from '@/components/ui/alert';
import type { AgreementRateSnapshot } from '@/types/vat';
import { formatDate, formatPercentage } from '@/types/vat';

interface VatSnapshotDisplayProps {
  snapshot: AgreementRateSnapshot | null;
}

export function VatSnapshotDisplay({ snapshot }: VatSnapshotDisplayProps) {
  if (!snapshot || snapshot.vat_rate_percent === null) {
    return null;
  }

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center gap-2">
          <Lock className="h-4 w-4 text-muted-foreground" />
          <CardTitle>VAT Snapshot</CardTitle>
        </div>
        <CardDescription>
          Immutable VAT rate captured at approval time
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <Alert>
          <Info className="h-4 w-4" />
          <AlertDescription>
            VAT rates are locked at approval and cannot be changed retroactively
          </AlertDescription>
        </Alert>

        <div className="grid grid-cols-2 gap-4">
          <div className="space-y-1">
            <div className="text-sm text-muted-foreground">VAT Rate</div>
            <Badge variant="secondary" className="font-mono text-lg">
              {formatPercentage(snapshot.vat_rate_percent)}
            </Badge>
          </div>

          <div className="space-y-1">
            <div className="text-sm text-muted-foreground">VAT Policy</div>
            <Badge variant="outline">{snapshot.vat_policy || 'N/A'}</Badge>
          </div>

          <div className="space-y-1">
            <div className="text-sm text-muted-foreground">Snapshotted At</div>
            <div className="text-sm font-medium">
              {snapshot.snapshotted_at
                ? formatDate(snapshot.snapshotted_at)
                : 'N/A'}
            </div>
          </div>

          <div className="space-y-1">
            <div className="text-sm text-muted-foreground">VAT Included</div>
            <Badge variant={snapshot.vat_included ? 'default' : 'secondary'}>
              {snapshot.vat_included ? 'Yes' : 'No'}
            </Badge>
          </div>
        </div>

        <div className="pt-4 border-t">
          <div className="text-sm text-muted-foreground">
            This VAT rate was captured on{' '}
            {formatDate(snapshot.approved_at)} and is immutable. Changes
            to current VAT rates will not affect this agreement.
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
