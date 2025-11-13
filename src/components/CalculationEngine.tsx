import React, { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { DatePickerWithRange } from '@/components/ui/date-picker';
import { Switch } from '@/components/ui/switch';
import { Label } from '@/components/ui/label';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { useToast } from '@/hooks/use-toast';
import { 
  Calculator, 
  Play, 
  Clock, 
  CheckCircle, 
  XCircle, 
  AlertTriangle,
  Eye,
  Download,
  RefreshCw,
  BarChart3,
  Filter,
  Calendar
} from 'lucide-react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/hooks/useAuth';
import { PrecisionDecimal, TieredCommissionCalculator } from '@/lib/precisionMath';
import { DateRange } from 'react-day-picker';
import { addDays, format } from 'date-fns';

interface CalculationRun {
  id: string;
  name: string;
  status: 'draft' | 'running' | 'completed' | 'failed' | 'submitted';
  scope_type: string;
  scope_filters: any;
  run_type: string;
  is_incremental: boolean;
  progress_percentage: number;
  period_start: string;
  period_end: string;
  total_gross_fees: number;
  total_vat: number;
  total_net_payable: number;
  started_by: string;
  created_at: string;
  completed_at?: string;
  error_message?: string;
}

interface CommissionCalculationSummary {
  id: string;
  entity_name: string;
  commission_type: string;
  base_amount: number;
  gross_commission: number;
  net_commission: number;
  vat_amount: number;
  applied_rate: number;
  tier_applied?: number;
  conditions_met: any;
}

const SCOPE_TYPES = [
  { value: 'full', label: 'Full Recalculation', description: 'Recalculate all transactions in period' },
  { value: 'incremental', label: 'Incremental', description: 'Only new/changed transactions since last run' },
  { value: 'fund', label: 'By Fund', description: 'Calculate specific fund(s) only' },
  { value: 'party', label: 'By Party', description: 'Calculate specific parties only' },
  { value: 'agreement', label: 'By Agreement', description: 'Calculate specific agreements only' }
];

const RUN_TYPES = [
  { value: 'manual', label: 'Manual Run', description: 'User-initiated calculation' },
  { value: 'auto', label: 'Auto Run', description: 'Triggered by import or schedule' },
  { value: 'scheduled', label: 'Scheduled Run', description: 'Daily scheduled calculation' }
];

export function CalculationEngine() {
  const { user, hasAnyRole } = useAuth();
  const { toast } = useToast();
  
  const [runs, setRuns] = useState<CalculationRun[]>([]);
  const [activeRun, setActiveRun] = useState<CalculationRun | null>(null);
  const [calculations, setCalculations] = useState<CommissionCalculationSummary[]>([]);
  const [loading, setLoading] = useState(false);
  
  // New run configuration
  const [newRun, setNewRun] = useState({
    name: '',
    scopeType: 'incremental',
    runType: 'manual',
    isIncremental: true,
    dateRange: {
      from: addDays(new Date(), -30),
      to: new Date()
    } as DateRange,
    scopeFilters: {},
    isDryRun: false
  });

  // Load calculation runs
  useEffect(() => {
    loadCalculationRuns();
  }, []);

  const loadCalculationRuns = async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('calculation_runs')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(20);

      if (error) throw error;
      setRuns((data || []).map(run => ({
        ...run,
        status: run.status as CalculationRun['status']
      })));
    } catch (error: any) {
      toast({
        title: "Failed to load calculation runs",
        description: error.message,
        variant: "destructive"
      });
    } finally {
      setLoading(false);
    }
  };

  // Load calculations for a specific run
  const loadCalculations = async (runId: string) => {
    try {
      const { data, error } = await supabase
        .from('advanced_commission_calculations')
        .select('*')
        .eq('calculation_run_id', runId)
        .order('entity_name');

      if (error) throw error;
      setCalculations(data || []);
    } catch (error: any) {
      toast({
        title: "Failed to load calculations",
        description: error.message,
        variant: "destructive"
      });
    }
  };

  // Start new calculation run
  const startCalculationRun = async () => {
    if (!user || !newRun.name.trim()) {
      toast({
        title: "Validation Error",
        description: "Please provide a name for the calculation run",
        variant: "destructive"
      });
      return;
    }

    try {
      setLoading(true);
      
      // Create calculation run
      const { data: run, error } = await supabase
        .from('calculation_runs')
        .insert({
          name: newRun.name,
          status: 'draft',
          scope_type: newRun.scopeType,
          scope_filters: newRun.scopeFilters,
          run_type: newRun.runType,
          is_incremental: newRun.isIncremental,
          period_start: newRun.dateRange.from?.toISOString().split('T')[0],
          period_end: newRun.dateRange.to?.toISOString().split('T')[0],
          started_by: user.id,
          progress_percentage: 0
        })
        .select()
        .single();

      if (error) throw error;

      toast({
        title: "Calculation run started",
        description: `Started calculation run: ${newRun.name}`,
      });

      // TODO: Trigger actual calculation process
      // For now, simulate progress
      simulateCalculationProgress(run.id);
      
      // Reset form
      setNewRun({
        name: '',
        scopeType: 'incremental',
        runType: 'manual',
        isIncremental: true,
        dateRange: {
          from: addDays(new Date(), -30),
          to: new Date()
        },
        scopeFilters: {},
        isDryRun: false
      });

      // Reload runs
      loadCalculationRuns();

    } catch (error: any) {
      toast({
        title: "Failed to start calculation",
        description: error.message,
        variant: "destructive"
      });
    } finally {
      setLoading(false);
    }
  };

  // Simulate calculation progress (replace with actual calculation logic)
  const simulateCalculationProgress = async (runId: string) => {
    const steps = [
      { progress: 10, status: 'Loading agreements...' },
      { progress: 25, status: 'Loading transactions...' },
      { progress: 40, status: 'Applying rules...' },
      { progress: 65, status: 'Calculating commissions...' },
      { progress: 80, status: 'Applying VAT...' },
      { progress: 95, status: 'Finalizing results...' },
      { progress: 100, status: 'Completed' }
    ];

    for (const step of steps) {
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      await supabase
        .from('calculation_runs')
        .update({ 
          progress_percentage: step.progress,
          status: step.progress === 100 ? 'completed' : 'running'
        })
        .eq('id', runId);
      
      // Reload runs to show progress
      loadCalculationRuns();
    }

    // Mark as completed
    await supabase
      .from('calculation_runs')
      .update({ 
        status: 'completed',
        completed_at: new Date().toISOString()
      })
      .eq('id', runId);

    loadCalculationRuns();
  };

  // Status helper functions for clean TypeScript 
  const getStatusHelpers = (status: CalculationRun['status']) => ({
    isCompleted: status === 'completed',
    isDraft: status === 'draft', 
    isRunning: status === 'running',
    isFailed: status === 'failed',
    isSubmitted: status === 'submitted'
  });

  // Status badge component with exhaustive switch
  const RunStatusBadge = ({ status }: { status: CalculationRun['status'] }) => {
    switch (status) {
      case 'draft':
        return <Badge className="bg-gray-500">Draft</Badge>;
      case 'running':
        return <Badge className="bg-blue-500">Running…</Badge>;
      case 'completed':
        return <Badge className="bg-green-500">Completed</Badge>;
      case 'failed':
        return <Badge className="bg-red-500">Failed</Badge>;
      case 'submitted':
        return <Badge className="bg-purple-500">Submitted</Badge>;
      default: {
        const _exhaustive: never = status;
        return _exhaustive;
      }
    }
  };

  // Legacy function kept for compatibility
  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed': return 'bg-green-500';
      case 'running': return 'bg-blue-500';
      case 'failed': return 'bg-red-500';
      case 'submitted': return 'bg-purple-500';
      default: return 'bg-gray-500';
    }
  };

  const canStartRun = hasAnyRole(['admin', 'finance', 'ops']);
  const canSubmitRun = hasAnyRole(['admin', 'finance']);

  return (
    <div className="space-y-6">
      {/* New Calculation Run */}
      {canStartRun && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Calculator className="w-5 h-5" />
              New Calculation Run
            </CardTitle>
            <CardDescription>
              Configure and start a new commission calculation run
            </CardDescription>
          </CardHeader>
          
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="runName">Run Name</Label>
                <input
                  id="runName"
                  type="text"
                  placeholder="e.g., Q4 2024 Commission Run"
                  value={newRun.name}
                  onChange={(e) => setNewRun(prev => ({ ...prev, name: e.target.value }))}
                  className="w-full px-3 py-2 border border-input bg-background rounded-md"
                />
              </div>
              
              <div className="space-y-2">
                <Label>Calculation Period</Label>
                <DatePickerWithRange
                  date={newRun.dateRange}
                  onDateChange={(range) => setNewRun(prev => ({ ...prev, dateRange: range || { from: undefined, to: undefined } }))}
                />
              </div>
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Scope Type</Label>
                <Select 
                  value={newRun.scopeType} 
                  onValueChange={(value) => setNewRun(prev => ({ ...prev, scopeType: value }))}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {SCOPE_TYPES.map(type => (
                      <SelectItem key={type.value} value={type.value}>
                        <div>
                          <div className="font-medium">{type.label}</div>
                          <div className="text-xs text-muted-foreground">{type.description}</div>
                        </div>
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              
              <div className="space-y-2">
                <Label>Run Type</Label>
                <Select 
                  value={newRun.runType} 
                  onValueChange={(value) => setNewRun(prev => ({ ...prev, runType: value }))}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {RUN_TYPES.map(type => (
                      <SelectItem key={type.value} value={type.value}>
                        <div>
                          <div className="font-medium">{type.label}</div>
                          <div className="text-xs text-muted-foreground">{type.description}</div>
                        </div>
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>
            
            <div className="flex items-center space-x-4">
              <div className="flex items-center space-x-2">
                <Switch
                  id="incremental"
                  checked={newRun.isIncremental}
                  onCheckedChange={(checked) => setNewRun(prev => ({ ...prev, isIncremental: checked }))}
                />
                <Label htmlFor="incremental">Incremental Calculation</Label>
              </div>
              
              <div className="flex items-center space-x-2">
                <Switch
                  id="dryRun"
                  checked={newRun.isDryRun}
                  onCheckedChange={(checked) => setNewRun(prev => ({ ...prev, isDryRun: checked }))}
                />
                <Label htmlFor="dryRun">Dry Run (Preview Only)</Label>
              </div>
            </div>
            
            <div className="flex justify-end">
              <Button
                onClick={startCalculationRun}
                disabled={loading || !newRun.name.trim()}
                className="gap-2"
              >
                <Play className="w-4 h-4" />
                Start Calculation
              </Button>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Calculation Runs History */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <div>
            <CardTitle>Calculation Runs</CardTitle>
            <CardDescription>
              History of commission calculation runs and their status
            </CardDescription>
          </div>
          <Button
            variant="outline"
            size="sm"
            onClick={loadCalculationRuns}
            className="gap-2"
          >
            <RefreshCw className="w-4 h-4" />
            Refresh
          </Button>
        </CardHeader>
        
        <CardContent>
          <div className="space-y-4">
            {runs.map(run => (
              <div key={run.id} className="border rounded-lg p-4 space-y-3">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <RunStatusBadge status={run.status} />
                    <span className="font-medium">{run.name}</span>
                    <span className="text-sm text-muted-foreground">
                      {format(new Date(run.created_at), 'MMM dd, yyyy HH:mm')}
                    </span>
                  </div>
                  
                  <div className="flex items-center gap-2">
                    {(() => {
                      const { isCompleted } = getStatusHelpers(run.status);
                      const showSubmit = isCompleted && canSubmitRun;
                      
                      return showSubmit ? (
                        <Button variant="outline" size="sm">
                          Submit for Approval
                        </Button>
                      ) : null;
                    })()}
                    <Button 
                      variant="outline" 
                      size="sm"
                      onClick={() => {
                        setActiveRun(run);
                        loadCalculations(run.id);
                      }}
                      className="gap-2"
                      disabled={getStatusHelpers(run.status).isRunning}
                    >
                      <Eye className="w-4 h-4" />
                      {(() => {
                        const { isRunning, isFailed } = getStatusHelpers(run.status);
                        if (isRunning) return 'Running…';
                        if (isFailed) return 'View Errors';
                        return 'View Details';
                      })()}
                    </Button>
                  </div>
                </div>
                
                {run.status === 'running' && (
                  <Progress value={run.progress_percentage} className="w-full" />
                )}
                
                <div className="grid grid-cols-2 md:grid-cols-5 gap-4 text-sm">
                  <div>
                    <span className="text-muted-foreground">Period:</span>
                    <div>{format(new Date(run.period_start), 'MMM dd')} - {format(new Date(run.period_end), 'MMM dd')}</div>
                  </div>
                  <div>
                    <span className="text-muted-foreground">Type:</span>
                    <div className="capitalize">{run.scope_type}</div>
                  </div>
                  <div>
                    <span className="text-muted-foreground">Gross Fees:</span>
                    <div className="font-mono">${(run.total_gross_fees || 0).toLocaleString()}</div>
                  </div>
                  <div>
                    <span className="text-muted-foreground">VAT:</span>
                    <div className="font-mono">${(run.total_vat || 0).toLocaleString()}</div>
                  </div>
                  <div>
                    <span className="text-muted-foreground">Net Payable:</span>
                    <div className="font-mono font-semibold">${(run.total_net_payable || 0).toLocaleString()}</div>
                  </div>
                </div>
                
                {run.error_message && (
                  <Alert variant="destructive">
                    <XCircle className="h-4 w-4" />
                    <AlertDescription>{run.error_message}</AlertDescription>
                  </Alert>
                )}
              </div>
            ))}
            
            {runs.length === 0 && !loading && (
              <div className="text-center py-8 text-muted-foreground">
                <Calculator className="w-12 h-12 mx-auto mb-4 opacity-50" />
                <p>No calculation runs found</p>
                <p className="text-sm">Start your first calculation run above</p>
              </div>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Calculation Details */}
      {activeRun && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <BarChart3 className="w-5 h-5" />
              Calculation Details: {activeRun.name}
            </CardTitle>
            <CardDescription>
              Detailed breakdown of commission calculations for this run
            </CardDescription>
          </CardHeader>
          
          <CardContent>
            <Tabs defaultValue="summary" className="w-full">
              <TabsList>
                <TabsTrigger value="summary">Summary</TabsTrigger>
                <TabsTrigger value="details">Line Items</TabsTrigger>
                <TabsTrigger value="audit">Audit Trail</TabsTrigger>
              </TabsList>
              
              <TabsContent value="summary">
                <div className="space-y-4">
                  <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                    <Card>
                      <CardHeader className="pb-2">
                        <CardTitle className="text-sm">Total Calculations</CardTitle>
                      </CardHeader>
                      <CardContent>
                        <div className="text-2xl font-bold">{calculations.length}</div>
                      </CardContent>
                    </Card>
                    
                    <Card>
                      <CardHeader className="pb-2">
                        <CardTitle className="text-sm">Gross Commissions</CardTitle>
                      </CardHeader>
                      <CardContent>
                        <div className="text-2xl font-bold">
                          ${calculations.reduce((sum, c) => sum + c.gross_commission, 0).toLocaleString()}
                        </div>
                      </CardContent>
                    </Card>
                    
                    <Card>
                      <CardHeader className="pb-2">
                        <CardTitle className="text-sm">Total VAT</CardTitle>
                      </CardHeader>
                      <CardContent>
                        <div className="text-2xl font-bold">
                          ${calculations.reduce((sum, c) => sum + c.vat_amount, 0).toLocaleString()}
                        </div>
                      </CardContent>
                    </Card>
                    
                    <Card>
                      <CardHeader className="pb-2">
                        <CardTitle className="text-sm">Net Payable</CardTitle>
                      </CardHeader>
                      <CardContent>
                        <div className="text-2xl font-bold text-green-600">
                          ${calculations.reduce((sum, c) => sum + c.net_commission, 0).toLocaleString()}
                        </div>
                      </CardContent>
                    </Card>
                  </div>
                </div>
              </TabsContent>
              
              <TabsContent value="details">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Entity</TableHead>
                      <TableHead>Type</TableHead>
                      <TableHead>Base Amount</TableHead>
                      <TableHead>Rate</TableHead>
                      <TableHead>Gross</TableHead>
                      <TableHead>VAT</TableHead>
                      <TableHead>Net</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {calculations.map(calc => (
                      <TableRow key={calc.id}>
                        <TableCell className="font-medium">{calc.entity_name}</TableCell>
                        <TableCell>{calc.commission_type}</TableCell>
                        <TableCell className="font-mono">${calc.base_amount.toLocaleString()}</TableCell>
                        <TableCell>{(calc.applied_rate * 100).toFixed(3)}%</TableCell>
                        <TableCell className="font-mono">${calc.gross_commission.toLocaleString()}</TableCell>
                        <TableCell className="font-mono">${calc.vat_amount.toLocaleString()}</TableCell>
                        <TableCell className="font-mono font-semibold">${calc.net_commission.toLocaleString()}</TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TabsContent>
              
              <TabsContent value="audit">
                <div className="space-y-4">
                  <Alert>
                    <AlertTriangle className="h-4 w-4" />
                    <AlertDescription>
                      Audit trail shows detailed step-by-step calculation process for compliance and verification.
                    </AlertDescription>
                  </Alert>
                  
                  <div className="text-center py-8 text-muted-foreground">
                    <Clock className="w-12 h-12 mx-auto mb-4 opacity-50" />
                    <p>Audit trail implementation in progress</p>
                    <p className="text-sm">Will show detailed calculation steps and rule versions</p>
                  </div>
                </div>
              </TabsContent>
            </Tabs>
          </CardContent>
        </Card>
      )}
    </div>
  );
}