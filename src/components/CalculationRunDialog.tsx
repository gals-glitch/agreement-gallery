import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Calendar } from '@/components/ui/calendar';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Badge } from '@/components/ui/badge';
import { CalendarIcon, Play, Settings, AlertTriangle, Info } from 'lucide-react';
import { format } from 'date-fns';
import { cn } from '@/lib/utils';
import type { Database } from '@/integrations/supabase/types';

type CalculationRun = Database['public']['Tables']['calculation_runs']['Row'];

interface RunDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onCreateRun: (data: CreateRunData) => Promise<void>;
  onRunCalculation: (runId: string, options: RunOptions) => Promise<void>;
  calculationRuns: CalculationRun[];
  mode: 'create' | 'run';
  selectedRunId?: string;
}

interface CreateRunData {
  name: string;
  period_start: string;
  period_end: string;
  scope_type: 'full' | 'incremental' | 'custom';
  scope_filters?: {
    fund_names?: string[];
    distributor_names?: string[];
    date_range_override?: { start: string; end: string };
  };
}

interface RunOptions {
  scope_type: 'full' | 'incremental' | 'custom';
  is_dry_run: boolean;
  scope_filters: {
    fund_names?: string[];
    distributor_names?: string[];
    date_range_override?: { start: string; end: string };
  };
}

export function CalculationRunDialog({ 
  open, 
  onOpenChange, 
  onCreateRun, 
  onRunCalculation,
  calculationRuns,
  mode,
  selectedRunId 
}: RunDialogProps) {
  // Create mode state
  const [newRunName, setNewRunName] = useState('');
  const [newRunPeriodStart, setNewRunPeriodStart] = useState<Date>();
  const [newRunPeriodEnd, setNewRunPeriodEnd] = useState<Date>();
  
  // Run mode state
  const [scopeType, setScopeType] = useState<'full' | 'incremental' | 'custom'>('incremental');
  const [isDryRun, setIsDryRun] = useState(false);
  const [customDateStart, setCustomDateStart] = useState<Date>();
  const [customDateEnd, setCustomDateEnd] = useState<Date>();
  const [selectedFunds, setSelectedFunds] = useState<string[]>([]);
  const [selectedDistributors, setSelectedDistributors] = useState<string[]>([]);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const selectedRun = calculationRuns.find(run => run.id === selectedRunId);

  const handleCreateRun = async () => {
    if (!newRunName || !newRunPeriodStart || !newRunPeriodEnd) {
      return;
    }

    setIsSubmitting(true);
    try {
      const scopeFilters = scopeType === 'custom' ? {
        fund_names: selectedFunds.length > 0 ? selectedFunds : undefined,
        distributor_names: selectedDistributors.length > 0 ? selectedDistributors : undefined,
        date_range_override: customDateStart && customDateEnd ? {
          start: format(customDateStart, 'yyyy-MM-dd'),
          end: format(customDateEnd, 'yyyy-MM-dd')
        } : undefined
      } : undefined;

      await onCreateRun({
        name: newRunName,
        period_start: format(newRunPeriodStart, 'yyyy-MM-dd'),
        period_end: format(newRunPeriodEnd, 'yyyy-MM-dd'),
        scope_type: scopeType,
        scope_filters: scopeFilters
      });
      
      // Reset form
      setNewRunName('');
      setNewRunPeriodStart(undefined);
      setNewRunPeriodEnd(undefined);
      setScopeType('incremental');
      setSelectedFunds([]);
      setSelectedDistributors([]);
      onOpenChange(false);
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleRunCalculation = async () => {
    if (!selectedRunId) return;

    setIsSubmitting(true);
    try {
      const scopeFilters = {
        fund_names: selectedFunds.length > 0 ? selectedFunds : undefined,
        distributor_names: selectedDistributors.length > 0 ? selectedDistributors : undefined,
        date_range_override: customDateStart && customDateEnd ? {
          start: format(customDateStart, 'yyyy-MM-dd'),
          end: format(customDateEnd, 'yyyy-MM-dd')
        } : undefined
      };

      await onRunCalculation(selectedRunId, {
        scope_type: scopeType,
        is_dry_run: isDryRun,
        scope_filters: scopeFilters
      });
      
      onOpenChange(false);
    } finally {
      setIsSubmitting(false);
    }
  };

  const getScopeDescription = () => {
    switch (scopeType) {
      case 'full':
        return 'Recalculate all distributions in the period. Slower but ensures complete accuracy.';
      case 'incremental':
        return 'Only calculate new/modified distributions since last run. Faster for regular processing.';
      case 'custom':
        return 'Apply custom filters to limit scope. Useful for testing specific scenarios.';
      default:
        return '';
    }
  };

  const getDryRunDescription = () => {
    return isDryRun 
      ? 'Preview mode: calculations will be performed but not saved. Good for testing rules.'
      : 'Live mode: calculations will be saved and can be approved for payment processing.';
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            {mode === 'create' ? (
              <>
                <Settings className="h-5 w-5" />
                Create New Calculation Run
              </>
            ) : (
              <>
                <Play className="h-5 w-5" />
                Run Calculations: {selectedRun?.name}
              </>
            )}
          </DialogTitle>
          <DialogDescription>
            {mode === 'create' 
              ? 'Set up a new period for commission calculations with scope options'
              : 'Configure calculation scope and execution options'
            }
          </DialogDescription>
        </DialogHeader>
        
        <div className="space-y-6">
          {mode === 'create' && (
            <>
              {/* Basic Run Details */}
              <div className="space-y-4">
                <div>
                  <Label htmlFor="run-name">Run Name</Label>
                  <Input
                    id="run-name"
                    value={newRunName}
                    onChange={(e) => setNewRunName(e.target.value)}
                    placeholder="Q1 2024 Commissions"
                  />
                </div>
                
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <Label>Period Start</Label>
                    <Popover>
                      <PopoverTrigger asChild>
                        <Button
                          variant="outline"
                          className={cn(
                            "w-full justify-start text-left font-normal",
                            !newRunPeriodStart && "text-muted-foreground"
                          )}
                        >
                          <CalendarIcon className="mr-2 h-4 w-4" />
                          {newRunPeriodStart ? format(newRunPeriodStart, "PPP") : "Pick start date"}
                        </Button>
                      </PopoverTrigger>
                      <PopoverContent className="w-auto p-0" align="start">
                        <Calendar
                          mode="single"
                          selected={newRunPeriodStart}
                          onSelect={setNewRunPeriodStart}
                          initialFocus
                          className="pointer-events-auto"
                        />
                      </PopoverContent>
                    </Popover>
                  </div>
                  
                  <div>
                    <Label>Period End</Label>
                    <Popover>
                      <PopoverTrigger asChild>
                        <Button
                          variant="outline"
                          className={cn(
                            "w-full justify-start text-left font-normal",
                            !newRunPeriodEnd && "text-muted-foreground"
                          )}
                        >
                          <CalendarIcon className="mr-2 h-4 w-4" />
                          {newRunPeriodEnd ? format(newRunPeriodEnd, "PPP") : "Pick end date"}
                        </Button>
                      </PopoverTrigger>
                      <PopoverContent className="w-auto p-0" align="start">
                        <Calendar
                          mode="single"
                          selected={newRunPeriodEnd}
                          onSelect={setNewRunPeriodEnd}
                          initialFocus
                          className="pointer-events-auto"
                        />
                      </PopoverContent>
                    </Popover>
                  </div>
                </div>
              </div>
            </>
          )}

          {mode === 'run' && selectedRun && (
            <Card>
              <CardHeader>
                <CardTitle className="text-base">Run Details</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-2 gap-4 text-sm">
                  <div>
                    <Label className="text-xs text-muted-foreground">Period</Label>
                    <p>{format(new Date(selectedRun.period_start), 'MMM dd')} - {format(new Date(selectedRun.period_end), 'MMM dd, yyyy')}</p>
                  </div>
                  <div>
                    <Label className="text-xs text-muted-foreground">Status</Label>
                    <p><Badge variant="outline">{selectedRun.status}</Badge></p>
                  </div>
                </div>
              </CardContent>
            </Card>
          )}

          {/* Scope Configuration */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Calculation Scope</CardTitle>
              <CardDescription>Choose what to include in this calculation run</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <Label>Scope Type</Label>
                <Select value={scopeType} onValueChange={(value: any) => setScopeType(value)}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="incremental">
                      <div className="flex items-center gap-2">
                        <Badge variant="secondary">Recommended</Badge>
                        Incremental
                      </div>
                    </SelectItem>
                    <SelectItem value="full">Full Rebuild</SelectItem>
                    <SelectItem value="custom">Custom Scope</SelectItem>
                  </SelectContent>
                </Select>
                <p className="text-xs text-muted-foreground mt-1">
                  {getScopeDescription()}
                </p>
              </div>

              {scopeType === 'custom' && (
                <div className="space-y-4 border-t pt-4">
                  <div>
                    <Label>Custom Date Range (Optional)</Label>
                    <div className="grid grid-cols-2 gap-2 mt-1">
                      <Popover>
                        <PopoverTrigger asChild>
                          <Button
                            variant="outline"
                            size="sm"
                            className={cn(
                              "justify-start text-left font-normal",
                              !customDateStart && "text-muted-foreground"
                            )}
                          >
                            <CalendarIcon className="mr-2 h-4 w-4" />
                            {customDateStart ? format(customDateStart, "MMM dd") : "Start"}
                          </Button>
                        </PopoverTrigger>
                        <PopoverContent className="w-auto p-0" align="start">
                          <Calendar
                            mode="single"
                            selected={customDateStart}
                            onSelect={setCustomDateStart}
                            initialFocus
                            className="pointer-events-auto"
                          />
                        </PopoverContent>
                      </Popover>
                      
                      <Popover>
                        <PopoverTrigger asChild>
                          <Button
                            variant="outline"
                            size="sm"
                            className={cn(
                              "justify-start text-left font-normal",
                              !customDateEnd && "text-muted-foreground"
                            )}
                          >
                            <CalendarIcon className="mr-2 h-4 w-4" />
                            {customDateEnd ? format(customDateEnd, "MMM dd") : "End"}
                          </Button>
                        </PopoverTrigger>
                        <PopoverContent className="w-auto p-0" align="start">
                          <Calendar
                            mode="single"
                            selected={customDateEnd}
                            onSelect={setCustomDateEnd}
                            initialFocus
                            className="pointer-events-auto"
                          />
                        </PopoverContent>
                      </Popover>
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <Label>Funds (Optional)</Label>
                      <Input 
                        placeholder="Enter fund names..." 
                        className="text-sm"
                        onKeyDown={(e) => {
                          if (e.key === 'Enter' && e.currentTarget.value.trim()) {
                            setSelectedFunds(prev => [...prev, e.currentTarget.value.trim()]);
                            e.currentTarget.value = '';
                          }
                        }}
                      />
                      {selectedFunds.length > 0 && (
                        <div className="flex flex-wrap gap-1 mt-2">
                          {selectedFunds.map((fund, index) => (
                            <Badge key={index} variant="secondary" className="text-xs">
                              {fund}
                              <button 
                                onClick={() => setSelectedFunds(prev => prev.filter((_, i) => i !== index))}
                                className="ml-1 hover:text-destructive"
                              >
                                ×
                              </button>
                            </Badge>
                          ))}
                        </div>
                      )}
                    </div>
                    
                    <div>
                      <Label>Distributors (Optional)</Label>
                      <Input 
                        placeholder="Enter distributor names..." 
                        className="text-sm"
                        onKeyDown={(e) => {
                          if (e.key === 'Enter' && e.currentTarget.value.trim()) {
                            setSelectedDistributors(prev => [...prev, e.currentTarget.value.trim()]);
                            e.currentTarget.value = '';
                          }
                        }}
                      />
                      {selectedDistributors.length > 0 && (
                        <div className="flex flex-wrap gap-1 mt-2">
                          {selectedDistributors.map((dist, index) => (
                            <Badge key={index} variant="secondary" className="text-xs">
                              {dist}
                              <button 
                                onClick={() => setSelectedDistributors(prev => prev.filter((_, i) => i !== index))}
                                className="ml-1 hover:text-destructive"
                              >
                                ×
                              </button>
                            </Badge>
                          ))}
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>

          {mode === 'run' && (
            <Card>
              <CardHeader>
                <CardTitle className="text-base">Execution Options</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="flex items-center justify-between">
                  <div className="space-y-0.5">
                    <Label>Dry Run Mode</Label>
                    <p className="text-xs text-muted-foreground">
                      {getDryRunDescription()}
                    </p>
                  </div>
                  <Switch
                    checked={isDryRun}
                    onCheckedChange={setIsDryRun}
                  />
                </div>
                
                {isDryRun && (
                  <Alert>
                    <Info className="h-4 w-4" />
                    <AlertDescription>
                      Dry run results will be shown but not saved. Perfect for testing rule changes.
                    </AlertDescription>
                  </Alert>
                )}
              </CardContent>
            </Card>
          )}

          {/* Performance Warning */}
          {scopeType === 'full' && (
            <Alert>
              <AlertTriangle className="h-4 w-4" />
              <AlertDescription>
                Full rebuild may take several minutes for large datasets. Consider incremental runs for regular processing.
              </AlertDescription>
            </Alert>
          )}

          {/* Action Buttons */}
          <div className="flex justify-end gap-2 pt-4 border-t">
            <Button variant="outline" onClick={() => onOpenChange(false)}>
              Cancel
            </Button>
            <Button 
              onClick={mode === 'create' ? handleCreateRun : handleRunCalculation}
              disabled={isSubmitting || (mode === 'create' && (!newRunName || !newRunPeriodStart || !newRunPeriodEnd))}
            >
              {isSubmitting ? 'Processing...' : mode === 'create' ? 'Create Run' : isDryRun ? 'Preview Results' : 'Run Calculations'}
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}