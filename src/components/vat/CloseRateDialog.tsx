/**
 * Close VAT Rate Dialog Component
 */

import { useState, useEffect } from 'react';
import { format } from 'date-fns';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import type { VatRate } from '@/types/vat';

interface CloseRateDialogProps {
  open: boolean;
  rate: VatRate | null;
  onOpenChange: (open: boolean) => void;
  onConfirm: (effectiveTo: string) => void;
  isLoading?: boolean;
}

export function CloseRateDialog({
  open,
  rate,
  onOpenChange,
  onConfirm,
  isLoading,
}: CloseRateDialogProps) {
  const [effectiveTo, setEffectiveTo] = useState('');
  const [error, setError] = useState('');

  useEffect(() => {
    if (open && rate) {
      // Default to today
      setEffectiveTo(format(new Date(), 'yyyy-MM-dd'));
      setError('');
    }
  }, [open, rate]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    if (!effectiveTo) {
      setError('Effective to date is required');
      return;
    }

    if (rate && effectiveTo <= rate.effective_from) {
      setError('Effective to must be after effective from');
      return;
    }

    onConfirm(effectiveTo);
  };

  if (!rate) return null;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[425px]">
        <form onSubmit={handleSubmit}>
          <DialogHeader>
            <DialogTitle>Close VAT Rate</DialogTitle>
            <DialogDescription>
              Set an end date for this VAT rate. This will make it historical.
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label>Current Rate</Label>
              <div className="p-3 bg-muted rounded-md">
                <div className="font-medium">
                  {rate.country_code} - {rate.rate_percentage}%
                </div>
                <div className="text-sm text-muted-foreground">
                  Effective from: {rate.effective_from}
                </div>
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="effective-to">Effective To *</Label>
              <Input
                id="effective-to"
                type="date"
                value={effectiveTo}
                onChange={(e) => {
                  setEffectiveTo(e.target.value);
                  setError('');
                }}
                className={error ? 'border-destructive' : ''}
              />
              {error && <p className="text-sm text-destructive">{error}</p>}
              <p className="text-xs text-muted-foreground">
                The rate will become historical after this date
              </p>
            </div>
          </div>

          <DialogFooter>
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>
              Cancel
            </Button>
            <Button type="submit" disabled={isLoading}>
              {isLoading ? 'Closing...' : 'Close Rate'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
