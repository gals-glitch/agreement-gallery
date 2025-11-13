import React from 'react';
import { useForm } from 'react-hook-form';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { useToast } from '@/hooks/use-toast';
import { CreditType } from '@/types/transactions';

interface CreateCreditFormData {
  investor_id: number;
  credit_type: CreditType;
  amount: number;
  currency: string;
  notes?: string;
}

interface CreateCreditModalProps {
  open: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

export function CreateCreditModal({ open, onClose, onSuccess }: CreateCreditModalProps) {
  const { toast } = useToast();
  const {
    register,
    handleSubmit,
    setValue,
    watch,
    reset,
    formState: { errors, isSubmitting },
  } = useForm<CreateCreditFormData>({
    defaultValues: {
      currency: 'USD',
      credit_type: 'EARLY_BIRD',
    },
  });

  const creditType = watch('credit_type');

  const onSubmit = async (data: CreateCreditFormData) => {
    try {
      // TODO: Replace with actual API call
      // const response = await fetch('/api-v1/credits', {
      //   method: 'POST',
      //   headers: { 'Content-Type': 'application/json' },
      //   body: JSON.stringify(data),
      // });
      //
      // if (!response.ok) {
      //   const error = await response.json();
      //   throw new Error(error.message || 'Failed to create credit');
      // }

      // Simulated API call
      await new Promise(resolve => setTimeout(resolve, 1000));

      toast({
        title: 'Credit created',
        description: `${data.credit_type} credit of ${data.currency} ${data.amount.toLocaleString()} created successfully.`,
      });

      reset();
      onSuccess();
      onClose();
    } catch (error) {
      console.error('Create credit error:', error);
      toast({
        title: 'Failed to create credit',
        description: error instanceof Error ? error.message : 'An error occurred',
        variant: 'destructive',
      });
    }
  };

  const handleClose = () => {
    reset();
    onClose();
  };

  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle>Create Credit</DialogTitle>
        </DialogHeader>

        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4 py-4">
          {/* Investor ID */}
          <div className="space-y-2">
            <Label htmlFor="investor_id">
              Investor ID <span className="text-destructive">*</span>
            </Label>
            <Input
              id="investor_id"
              type="number"
              placeholder="Enter investor ID"
              {...register('investor_id', {
                required: 'Investor ID is required',
                valueAsNumber: true,
                min: { value: 1, message: 'Investor ID must be positive' },
              })}
              disabled={isSubmitting}
            />
            {errors.investor_id && (
              <p className="text-sm text-destructive">{errors.investor_id.message}</p>
            )}
          </div>

          {/* Credit Type */}
          <div className="space-y-2">
            <Label htmlFor="credit_type">
              Credit Type <span className="text-destructive">*</span>
            </Label>
            <Select
              value={creditType}
              onValueChange={(value) => setValue('credit_type', value as CreditType)}
              disabled={isSubmitting}
            >
              <SelectTrigger>
                <SelectValue placeholder="Select credit type" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="EARLY_BIRD">Early Bird</SelectItem>
                <SelectItem value="PROMOTIONAL">Promotional</SelectItem>
              </SelectContent>
            </Select>
            <p className="text-xs text-muted-foreground">
              {creditType === 'EARLY_BIRD'
                ? 'Credit for early commitments or participation'
                : 'Promotional or marketing-related credit'}
            </p>
          </div>

          {/* Amount */}
          <div className="space-y-2">
            <Label htmlFor="amount">
              Amount <span className="text-destructive">*</span>
            </Label>
            <Input
              id="amount"
              type="number"
              step="0.01"
              placeholder="0.00"
              {...register('amount', {
                required: 'Amount is required',
                valueAsNumber: true,
                min: { value: 0.01, message: 'Amount must be greater than 0' },
              })}
              disabled={isSubmitting}
            />
            {errors.amount && (
              <p className="text-sm text-destructive">{errors.amount.message}</p>
            )}
          </div>

          {/* Currency */}
          <div className="space-y-2">
            <Label htmlFor="currency">Currency</Label>
            <Select
              value={watch('currency')}
              onValueChange={(value) => setValue('currency', value)}
              disabled={isSubmitting}
            >
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="USD">USD ($)</SelectItem>
                <SelectItem value="EUR">EUR (€)</SelectItem>
                <SelectItem value="GBP">GBP (£)</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {/* Notes */}
          <div className="space-y-2">
            <Label htmlFor="notes">Notes (Optional)</Label>
            <Textarea
              id="notes"
              placeholder="Add notes about this credit..."
              rows={3}
              {...register('notes')}
              disabled={isSubmitting}
            />
          </div>

          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={handleClose}
              disabled={isSubmitting}
            >
              Cancel
            </Button>
            <Button type="submit" disabled={isSubmitting}>
              {isSubmitting ? 'Creating...' : 'Create Credit'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
