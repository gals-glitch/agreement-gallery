import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Calendar } from '@/components/ui/calendar';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { DistributionImportWizard } from './DistributionImportWizard';
import { CalculationRunDialog } from './CalculationRunDialog';
import { ExportCenter } from './ExportCenter';
import { RunContextBanner, JobsIcon, ExportShortcutMenu, RoundingDisclosure } from './UIEnhancements';
import { useAdvancedCommissionCalculations } from '@/hooks/useAdvancedCommissionCalculations';
import { useToast } from '@/hooks/use-toast';
import { format } from 'date-fns';
import {
  Calculator,
  Play,
  Download,
  TrendingUp,
  DollarSign,
  Users,
  FileText,
  Plus,
  CheckCircle,
  CalendarIcon,
  Eye,
  Settings,
  MoreHorizontal
} from 'lucide-react';
import { Switch } from '@/components/ui/switch';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu';
import { cn } from '@/lib/utils';

// Force refresh to clear import cache

export function FeeCalculationDashboard() {
  const [selectedCalculation, setSelectedCalculation] = useState<any>(null);
  const [selectedRunId, setSelectedRunId] = useState<string>('');
  const [showCreateRun, setShowCreateRun] = useState(false);
  const [showRunDialog, setShowRunDialog] = useState(false);
  const [autoRunCalculation, setAutoRunCalculation] = useState(true);
  
  const { 
    calculationRuns, 
    distributions, 
    calculations, 
    loading, 
    createCalculationRun,
    fetchDistributions,
    runCommissionCalculations,
    fetchCalculations,
    approveCalculation
  } = useAdvancedCommissionCalculations();
  
  const { toast } = useToast();

  const currentRun = calculationRuns.find(run => run.id === selectedRunId) || calculationRuns[0];

  useEffect(() => {
    if (currentRun) {
      setSelectedRunId(currentRun.id);
      fetchDistributions(currentRun.id);
      fetchCalculations(currentRun.id);
    }
  }, [currentRun?.id]);

  const handleCreateRun = async (data: any) => {
    try {
      const newRun = await createCalculationRun({
        name: data.name,
        period_start: data.period_start,
        period_end: data.period_end,
        scope_type: data.scope_type || 'incremental',
        scope_filters: data.scope_filters || {},
      });
      
      setSelectedRunId(newRun.id);
      
      toast({
        title: "Success",
        description: "Calculation run created successfully.",
      });
    } catch (error: any) {
      console.error('Create run failed:', error);
      toast({
        title: "Error",
        description: error?.message || error?.error || "Failed to create calculation run.",
        variant: "destructive",
      });
      throw error;
    }
  };

  const handleRunCalculations = async (runId: string, options?: any) => {
    try {
      console.log('Running calculations for run:', runId, 'with options:', options);
      
      // Use the passed runId or fall back to current run
      const targetRunId = runId || currentRun?.id;
      if (!targetRunId) return;
      
      await runCommissionCalculations(targetRunId);
      await fetchCalculations(targetRunId);
      
      const isDryRun = options?.is_dry_run;
      toast({
        title: "Success",
        description: isDryRun 
          ? "Preview calculations completed successfully."
          : "Commission calculations completed successfully.",
      });
    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to run calculations.",
        variant: "destructive",
      });
    }
  };

  const handleAutoRunTriggered = async (runId: string) => {
    console.log('Auto-run triggered for run:', runId);
    toast({
      title: "Auto-run Started",
      description: "Commission calculations started automatically after import.",
    });
    
    // Run with default incremental scope
    await handleRunCalculations(runId, { 
      scope_type: 'incremental', 
      is_dry_run: false 
    });
  };

  const handleApproveCalculations = async () => {
    if (!currentRun) return;
    
    try {
      await approveCalculation(currentRun.id);
      
      toast({
        title: "Success",
        description: "Calculations approved successfully.",
      });
    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to approve calculations.",
        variant: "destructive",
      });
    }
  };

  const handleUploadComplete = async () => {
    if (currentRun) {
      await fetchDistributions(currentRun.id);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center p-8">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Run Context Banner */}
      <RunContextBanner 
        draftRun={currentRun?.status === 'draft' ? {
          id: currentRun.id,
          name: currentRun.name,
          status: currentRun.status,
          progress: 0 // TODO: Connect to actual progress
        } : undefined}
        onOpenRun={(runId) => setSelectedRunId(runId)}
      />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold tracking-tight">Commission Calculations</h2>
           <p className="text-muted-foreground">
             Manage distribution uploads and calculate commissions automatically
           </p>
        </div>
        <div className="flex gap-2">
          <JobsIcon 
            pendingCount={0} // TODO: Connect to actual job count
            onClick={() => {/* TODO: Navigate to jobs page */}}
          />
          <Button onClick={() => setShowCreateRun(true)} className="gap-2">
            <Plus className="h-4 w-4" />
            New Calculation Run
          </Button>
          {currentRun && (
            <Button 
              variant="outline" 
              onClick={() => setShowRunDialog(true)} 
              className="gap-2"
              disabled={distributions.length === 0}
            >
              <Play className="h-4 w-4" />
              Run Calculations
            </Button>
          )}
        </div>
      </div>

      {/* Calculation Run Selection */}
      <Card>
        <CardHeader>
          <CardTitle>Select Calculation Run</CardTitle>
          <CardDescription>Choose or create a calculation period</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex gap-4 items-end">
            <div className="flex-1">
              <Label htmlFor="run-select">Calculation Run</Label>
              <Select value={selectedRunId} onValueChange={setSelectedRunId}>
                <SelectTrigger>
                  <SelectValue placeholder="Select a calculation run" />
                </SelectTrigger>
                <SelectContent>
                  {calculationRuns.map((run) => (
                    <SelectItem key={run.id} value={run.id}>
                      {run.name} ({format(new Date(run.period_start), 'MMM dd')} - {format(new Date(run.period_end), 'MMM dd, yyyy')})
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            {currentRun && (
              <Badge variant={currentRun.status === 'approved' ? 'default' : 'secondary'}>
                {currentRun.status}
              </Badge>
            )}
          </div>
        </CardContent>
      </Card>

      {currentRun && (
        <>
          {/* Summary Cards */}
          <div className="grid gap-4 md:grid-cols-4">
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Gross Fees</CardTitle>
                <DollarSign className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold" title={`Exact: $${(currentRun.total_gross_fees || 0).toFixed(6)}`}>
                  ${(currentRun.total_gross_fees || 0).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                </div>
                <p className="text-xs text-muted-foreground">
                  Next Estimated Payout
                </p>
              </CardContent>
            </Card>
            
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">VAT</CardTitle>
                <TrendingUp className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold" title={`Exact: $${(currentRun.total_vat || 0).toFixed(6)}`}>
                  ${(currentRun.total_vat || 0).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                </div>
                <p className="text-xs text-muted-foreground flex items-center gap-1">
                  <span className="inline-block w-2 h-2 bg-orange-500 rounded-full" title="Added on top"></span>
                  VAT Added
                </p>
              </CardContent>
            </Card>
            
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Net Payable</CardTitle>
                <Calculator className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold" title={`Exact: $${(currentRun.total_net_payable || 0).toFixed(6)}`}>
                  ${(currentRun.total_net_payable || 0).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                </div>
                <p className="text-xs text-muted-foreground">
                  Total Due
                </p>
                {/* Rounding Disclosure */}
                <RoundingDisclosure
                  grossTotal={currentRun.total_gross_fees || 0}
                  netTotal={currentRun.total_net_payable || 0}
                  vatTotal={currentRun.total_vat || 0}
                  onViewDetails={() => {/* TODO: Navigate to summary export */}}
                />
              </CardContent>
            </Card>
            
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Distributions</CardTitle>
                <Users className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{distributions.length}</div>
              </CardContent>
            </Card>
          </div>

          {/* Upload & Calculation Controls */}
          <div className="grid gap-6 md:grid-cols-2">
            <DistributionImportWizard 
              calculationRunId={currentRun.id}
              onUploadComplete={handleUploadComplete}
            />
            
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Calculator className="h-5 w-5" />
                  Calculation Settings
                </CardTitle>
                <CardDescription>
                  Configure calculation behavior and run options
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="flex items-center justify-between">
                  <div className="space-y-0.5">
                    <Label className="text-sm font-medium">Auto-run after import</Label>
                    <p className="text-xs text-muted-foreground">
                      Automatically start calculations when import completes
                    </p>
                  </div>
                  <Switch
                    checked={autoRunCalculation}
                    onCheckedChange={setAutoRunCalculation}
                  />
                </div>

                <div className="space-y-2">
                  <Button 
                    onClick={() => setShowRunDialog(true)}
                    className="w-full gap-2"
                    disabled={distributions.length === 0 || currentRun.status === 'approved'}
                  >
                    <Settings className="h-4 w-4" />
                    Advanced Run Options
                  </Button>

                   {calculations.length > 0 && currentRun.status !== 'approved' && (
                     <Button 
                       onClick={handleApproveCalculations}
                       variant="outline" 
                       className="w-full gap-2"
                     >
                       <CheckCircle className="h-4 w-4" />
                       Approve Calculations
                     </Button>
                   )}
                </div>
                
                <div className="text-sm text-muted-foreground">
                  <p>Status: <Badge variant="outline">{currentRun.status}</Badge></p>
                  <p>Calculations: {calculations.length}</p>
                  <p>Auto-run: <Badge variant={autoRunCalculation ? "default" : "secondary"}>
                    {autoRunCalculation ? "Enabled" : "Disabled"}
                  </Badge></p>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Results & Export Tabs */}
          <Tabs defaultValue="distributions" className="space-y-4">
            <TabsList>
              <TabsTrigger value="distributions">Distributions ({distributions.length})</TabsTrigger>
              <TabsTrigger value="calculations">Calculations ({calculations.length})</TabsTrigger>
              <TabsTrigger value="exports">Export Center</TabsTrigger>
            </TabsList>
            
            <TabsContent value="distributions" className="space-y-4">
              <Card>
                <CardHeader>
                  <CardTitle>Distribution Data</CardTitle>
                  <CardDescription>Uploaded investor distribution records</CardDescription>
                </CardHeader>
                <CardContent>
                  <ScrollArea className="h-64">
                    <div className="space-y-2">
                      {distributions.map((dist) => (
                        <div 
                          key={dist.id} 
                          className="flex items-center justify-between p-3 border rounded-lg hover:bg-muted/50 cursor-pointer transition-colors group"
                          onClick={() => {/* TODO: Open distribution details */}}
                        >
                          <div className="space-y-1 flex-1">
                            <div className="flex items-center gap-2">
                              <p className="font-medium">{dist.investor_name}</p>
                              <div className="flex gap-1">
                                {/* VAT Badge */}
                                <Badge variant="outline" className="text-xs px-1.5 py-0.5 bg-orange-50 text-orange-700 border-orange-200">
                                  VAT Added
                                </Badge>
                                {/* Trigger Badge */}
                                <Badge variant="outline" className="text-xs px-1.5 py-0.5 bg-blue-50 text-blue-700 border-blue-200">
                                  Quarterly
                                </Badge>
                              </div>
                            </div>
                            <p className="text-sm text-muted-foreground">
                              {dist.fund_name && `${dist.fund_name} • `}
                              {dist.distributor_name && `Dist: ${dist.distributor_name}`}
                              {dist.referrer_name && ` • Ref: ${dist.referrer_name}`}
                            </p>
                          </div>
                          <div className="text-right">
                            <p className="font-semibold" title={`Exact: $${dist.distribution_amount.toFixed(6)}`}>
                              ${dist.distribution_amount.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                            </p>
                            <p className="text-xs text-muted-foreground">
                              {dist.distribution_date ? format(new Date(dist.distribution_date), 'MMM dd, yyyy') : '—'}
                            </p>
                          </div>
                        </div>
                      ))}
                      {distributions.length === 0 && (
                        <div className="text-center text-muted-foreground py-8">
                          <p className="text-lg">—</p>
                          <p className="text-sm mt-1" title="Upload an Excel file to add distributions">
                            No distributions uploaded yet
                          </p>
                        </div>
                      )}
                    </div>
                  </ScrollArea>
                </CardContent>
              </Card>
            </TabsContent>
            
            <TabsContent value="calculations" className="space-y-4">
              <Card>
                <CardHeader>
                  <CardTitle>Commission Calculations</CardTitle>
                  <CardDescription>Calculated commission results</CardDescription>
                </CardHeader>
                <CardContent>
                  <ScrollArea className="h-64">
                    <div className="space-y-2">
                      {calculations.map((calc) => (
                        <div 
                          key={calc.id} 
                          className="flex items-center justify-between p-3 border rounded-lg hover:bg-muted/50 cursor-pointer transition-colors group"
                          onClick={() => {/* TODO: Open calculation details */}}
                        >
                          <div className="space-y-1 flex-1">
                            <div className="flex items-center gap-2">
                              <p className="font-medium">{calc.entity_name}</p>
                              <div className="flex gap-1">
                                {/* Commission Type Badge */}
                                <Badge variant="outline" className="text-xs px-1.5 py-0.5">
                                  {calc.commission_type}
                                </Badge>
                                {/* Status Badge */}
                                <Badge variant={calc.status === 'calculated' ? 'default' : 'secondary'} className="text-xs px-1.5 py-0.5">
                                  {calc.status}
                                </Badge>
                              </div>
                            </div>
                            <p className="text-sm text-muted-foreground">
                              Base Rate: {((calc.applied_rate || 0) * 100).toFixed(2)}%
                              {calc.calculation_method && ` • ${calc.calculation_method}`}
                            </p>
                          </div>
                          <div className="text-right">
                            <div className="flex items-center gap-2">
                              <div className="text-right">
                                <p className="font-semibold text-green-600" title={`Gross: $${calc.gross_commission.toFixed(6)} | VAT: $${calc.vat_amount.toFixed(6)}`}>
                                  ${calc.net_commission.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                                </p>
                                <p className="text-xs text-muted-foreground">
                                  Net • ${calc.gross_commission.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} gross
                                </p>
                              </div>
                              <ExportShortcutMenu
                                calculationRunId={currentRun.id}
                                entityName={calc.entity_name}
                                onExport={(type) => {/* TODO: Trigger export with entity filter */}}
                                disabled={currentRun.status !== 'approved'}
                              />
                            </div>
                          </div>
                        </div>
                      ))}
                      {calculations.length === 0 && (
                        <div className="text-center text-muted-foreground py-8">
                          <p className="text-lg">—</p>
                          <p className="text-sm mt-1" title="Upload distributions and run calculations">
                            No calculations yet
                          </p>
                        </div>
                      )}
                    </div>
                  </ScrollArea>
                </CardContent>
              </Card>
            </TabsContent>
            
            <TabsContent value="exports" className="space-y-4">
              <ExportCenter />
            </TabsContent>
          </Tabs>
        </>
      )}

    </div>
  );
}