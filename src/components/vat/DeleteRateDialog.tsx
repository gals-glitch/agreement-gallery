/**
 * Delete VAT Rate Dialog Component
 */

import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog';
import type { VatRate } from '@/types/vat';

interface DeleteRateDialogProps {
  open: boolean;
  rate: VatRate | null;
  onOpenChange: (open: boolean) => void;
  onConfirm: () => void;
  isLoading?: boolean;
}

export function DeleteRateDialog({
  open,
  rate,
  onOpenChange,
  onConfirm,
  isLoading,
}: DeleteRateDialogProps) {
  if (!rate) return null;

  return (
    <AlertDialog open={open} onOpenChange={onOpenChange}>
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>Delete VAT Rate</AlertDialogTitle>
          <AlertDialogDescription>
            Are you sure you want to delete this VAT rate? This action cannot be undone.
          </AlertDialogDescription>
        </AlertDialogHeader>

        <div className="p-4 bg-muted rounded-md space-y-1">
          <div className="font-medium">
            {rate.country_code} - {rate.rate_percentage}%
          </div>
          <div className="text-sm text-muted-foreground">
            Effective: {rate.effective_from} to {rate.effective_to || 'Current'}
          </div>
          {rate.description && (
            <div className="text-sm text-muted-foreground">{rate.description}</div>
          )}
        </div>

        <AlertDialogFooter>
          <AlertDialogCancel>Cancel</AlertDialogCancel>
          <AlertDialogAction
            onClick={onConfirm}
            disabled={isLoading}
            className="bg-destructive hover:bg-destructive/90"
          >
            {isLoading ? 'Deleting...' : 'Delete'}
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}
