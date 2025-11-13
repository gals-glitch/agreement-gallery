/**
 * VAT Rate Create Dialog Component
 */

import { useState } from 'react';
import { format } from 'date-fns';
import { Calendar as CalendarIcon } from 'lucide-react';

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
import { Textarea } from '@/components/ui/textarea';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Calendar } from '@/components/ui/calendar';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { cn } from '@/lib/utils';
import type { CreateVatRateRequest } from '@/types/vat';
import { COMMON_COUNTRIES } from '@/types/vat';

interface VatRateDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (payload: CreateVatRateRequest) => void;
  isLoading?: boolean;
}

export function VatRateDialog({ open, onOpenChange, onSubmit, isLoading }: VatRateDialogProps) {
  const [formData, setFormData] = useState<CreateVatRateRequest>({
    country_code: '',
    rate_percentage: 0,
    effective_from: format(new Date(), 'yyyy-MM-dd'),
    effective_to: null,
    description: '',
  });

  const [errors, setErrors] = useState<Record<string, string>>({});

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    // Validate
    const newErrors: Record<string, string> = {};

    if (!formData.country_code) {
      newErrors.country_code = 'Country is required';
    }

    if (formData.rate_percentage < 0 || formData.rate_percentage > 100) {
      newErrors.rate_percentage = 'Rate must be between 0 and 100';
    }

    if (!formData.effective_from) {
      newErrors.effective_from = 'Effective from date is required';
    }

    if (formData.effective_to && formData.effective_to <= formData.effective_from) {
      newErrors.effective_to = 'Effective to must be after effective from';
    }

    if (Object.keys(newErrors).length > 0) {
      setErrors(newErrors);
      return;
    }

    onSubmit(formData);
  };

  const handleReset = () => {
    setFormData({
      country_code: '',
      rate_percentage: 0,
      effective_from: format(new Date(), 'yyyy-MM-dd'),
      effective_to: null,
      description: '',
    });
    setErrors({});
  };

  return (
    <Dialog open={open} onOpenChange={(open) => { onOpenChange(open); if (!open) handleReset(); }}>
      <DialogContent className="sm:max-w-[500px]">
        <form onSubmit={handleSubmit}>
          <DialogHeader>
            <DialogTitle>Create New VAT Rate</DialogTitle>
            <DialogDescription>
              Add a new VAT rate configuration for a country
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            {/* Country Selection */}
            <div className="space-y-2">
              <Label htmlFor="country">Country *</Label>
              <Select
                value={formData.country_code}
                onValueChange={(value) => setFormData({ ...formData, country_code: value })}
              >
                <SelectTrigger className={errors.country_code ? 'border-destructive' : ''}>
                  <SelectValue placeholder="Select country" />
                </SelectTrigger>
                <SelectContent>
                  {COMMON_COUNTRIES.map((country) => (
                    <SelectItem key={country.code} value={country.code}>
                      <span className="flex items-center gap-2">
                        <span>{country.flag}</span>
                        <span>{country.name}</span>
                      </span>
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              {errors.country_code && (
                <p className="text-sm text-destructive">{errors.country_code}</p>
              )}
            </div>

            {/* Rate Percentage */}
            <div className="space-y-2">
              <Label htmlFor="rate">Rate (%) *</Label>
              <Input
                id="rate"
                type="number"
                step="0.01"
                min="0"
                max="100"
                value={formData.rate_percentage}
                onChange={(e) =>
                  setFormData({ ...formData, rate_percentage: parseFloat(e.target.value) || 0 })
                }
                className={errors.rate_percentage ? 'border-destructive' : ''}
              />
              {errors.rate_percentage && (
                <p className="text-sm text-destructive">{errors.rate_percentage}</p>
              )}
            </div>

            {/* Effective From */}
            <div className="space-y-2">
              <Label>Effective From *</Label>
              <Input
                type="date"
                value={formData.effective_from}
                onChange={(e) => setFormData({ ...formData, effective_from: e.target.value })}
                className={errors.effective_from ? 'border-destructive' : ''}
              />
              {errors.effective_from && (
                <p className="text-sm text-destructive">{errors.effective_from}</p>
              )}
            </div>

            {/* Effective To */}
            <div className="space-y-2">
              <Label>Effective To (optional)</Label>
              <Input
                type="date"
                value={formData.effective_to || ''}
                onChange={(e) =>
                  setFormData({ ...formData, effective_to: e.target.value || null })
                }
                className={errors.effective_to ? 'border-destructive' : ''}
              />
              <p className="text-xs text-muted-foreground">
                Leave blank for an open-ended rate
              </p>
              {errors.effective_to && (
                <p className="text-sm text-destructive">{errors.effective_to}</p>
              )}
            </div>

            {/* Description */}
            <div className="space-y-2">
              <Label htmlFor="description">Description</Label>
              <Textarea
                id="description"
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                placeholder="e.g., Standard VAT rate"
                rows={3}
              />
            </div>
          </div>

          <DialogFooter>
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>
              Cancel
            </Button>
            <Button type="submit" disabled={isLoading}>
              {isLoading ? 'Creating...' : 'Create Rate'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
