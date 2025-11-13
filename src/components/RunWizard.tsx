import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Calendar, ArrowRight, ArrowLeft, Check } from 'lucide-react';
import { CreateRunRequest } from '@/types/runs';

interface RunWizardProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (data: CreateRunRequest) => Promise<void>;
}

export function RunWizard({ open, onOpenChange, onSubmit }: RunWizardProps) {
  const [step, setStep] = useState(1);
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState<CreateRunRequest>({
    period_start: '',
    period_end: '',
    cut_off_label: '',
  });

  const handleNext = () => {
    if (step < 3) setStep(step + 1);
  };

  const handleBack = () => {
    if (step > 1) setStep(step - 1);
  };

  const handleSubmit = async () => {
    if (!formData.period_start || !formData.period_end || !formData.cut_off_label) {
      return;
    }

    setLoading(true);
    try {
      await onSubmit(formData);
      setStep(1);
      setFormData({ period_start: '', period_end: '', cut_off_label: '' });
      onOpenChange(false);
    } catch (error) {
      console.error('Failed to create run:', error);
    } finally {
      setLoading(false);
    }
  };

  const isStepValid = () => {
    switch (step) {
      case 1:
        return formData.period_start && formData.period_end && 
               new Date(formData.period_start) <= new Date(formData.period_end);
      case 2:
        return formData.cut_off_label.trim().length > 0;
      case 3:
        return true;
      default:
        return false;
    }
  };

  const resetWizard = () => {
    setStep(1);
    setFormData({ period_start: '', period_end: '', cut_off_label: '' });
  };

  return (
    <Dialog open={open} onOpenChange={(open) => {
      onOpenChange(open);
      if (!open) resetWizard();
    }}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Calendar className="w-5 h-5" />
            Create New Calculation Run
          </DialogTitle>
          <DialogDescription>
            Set up a new fee calculation run for a specific period
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-6">
          {/* Progress indicator */}
          <div className="flex items-center justify-center space-x-2">
            {[1, 2, 3].map((num) => (
              <div key={num} className="flex items-center">
                <div
                  className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium ${
                    num === step
                      ? 'bg-primary text-primary-foreground'
                      : num < step
                      ? 'bg-green-500 text-white'
                      : 'bg-muted text-muted-foreground'
                  }`}
                >
                  {num < step ? <Check className="w-4 h-4" /> : num}
                </div>
                {num < 3 && (
                  <div
                    className={`w-8 h-0.5 mx-1 ${
                      num < step ? 'bg-green-500' : 'bg-muted'
                    }`}
                  />
                )}
              </div>
            ))}
          </div>

          {/* Step 1: Period Dates */}
          {step === 1 && (
            <Card>
              <CardHeader>
                <CardTitle className="text-lg">Calculation Period</CardTitle>
                <CardDescription>
                  Define the start and end dates for this calculation run
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="period_start">Start Date</Label>
                    <Input
                      id="period_start"
                      type="date"
                      value={formData.period_start}
                      onChange={(e) => setFormData({ ...formData, period_start: e.target.value })}
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="period_end">End Date</Label>
                    <Input
                      id="period_end"
                      type="date"
                      value={formData.period_end}
                      onChange={(e) => setFormData({ ...formData, period_end: e.target.value })}
                    />
                  </div>
                </div>
                
                {formData.period_start && formData.period_end && (
                  <div className="text-sm text-muted-foreground mt-2">
                    Period duration: {
                      Math.ceil(
                        (new Date(formData.period_end).getTime() - new Date(formData.period_start).getTime()) 
                        / (1000 * 60 * 60 * 24)
                      )
                    } days
                  </div>
                )}
              </CardContent>
            </Card>
          )}

          {/* Step 2: Cut-off Label */}
          {step === 2 && (
            <Card>
              <CardHeader>
                <CardTitle className="text-lg">Run Label</CardTitle>
                <CardDescription>
                  Provide a descriptive label for this calculation run
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="cut_off_label">Label</Label>
                  <Input
                    id="cut_off_label"
                    placeholder="e.g., Q3 2024, October 2024, Year-end 2024"
                    value={formData.cut_off_label}
                    onChange={(e) => setFormData({ ...formData, cut_off_label: e.target.value })}
                  />
                </div>
                
                <div className="text-sm text-muted-foreground">
                  This label will be used to identify the run in reports and exports.
                </div>
              </CardContent>
            </Card>
          )}

          {/* Step 3: Confirmation */}
          {step === 3 && (
            <Card>
              <CardHeader>
                <CardTitle className="text-lg">Confirm Details</CardTitle>
                <CardDescription>
                  Review the run configuration before creating
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-3">
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Period:</span>
                    <span className="font-medium">
                      {formData.period_start} to {formData.period_end}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Label:</span>
                    <span className="font-medium">{formData.cut_off_label}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Status:</span>
                    <span className="font-medium">Draft (ready for calculation)</span>
                  </div>
                </div>
              </CardContent>
            </Card>
          )}

          {/* Navigation buttons */}
          <div className="flex justify-between pt-4">
            <Button
              variant="outline"
              onClick={handleBack}
              disabled={step === 1}
              className="gap-2"
            >
              <ArrowLeft className="w-4 h-4" />
              Back
            </Button>

            {step < 3 ? (
              <Button
                onClick={handleNext}
                disabled={!isStepValid()}
                className="gap-2"
              >
                Next
                <ArrowRight className="w-4 h-4" />
              </Button>
            ) : (
              <Button
                onClick={handleSubmit}
                disabled={!isStepValid() || loading}
                className="gap-2"
              >
                {loading ? 'Creating...' : 'Create Run'}
                <Check className="w-4 h-4" />
              </Button>
            )}
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}