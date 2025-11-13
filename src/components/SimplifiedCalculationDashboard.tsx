import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Calendar } from '@/components/ui/calendar';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Separator } from '@/components/ui/separator';
import { useAdvancedCommissionCalculations } from '@/hooks/useAdvancedCommissionCalculations';
import { useToast } from '@/hooks/use-toast';
import { format } from 'date-fns';
import {
  Calculator,
  Play,
  Upload,
  DollarSign,
  CheckCircle,
  CalendarIcon,
  FileSpreadsheet,
  ArrowRight,
  Users,
  Plus,
  Settings,
  Eye,
  TrendingUp,
  History,
  AlertTriangle,
  Clock,
  FileText,
  Download,
  Trash2,
  RotateCcw,
  Filter,
  Target,
  Building2,
  Info
} from 'lucide-react';
import { cn } from '@/lib/utils';
import { ExcelDistributionUpload } from '@/components/ExcelDistributionUpload';
import { RunsHeader } from './RunsHeader';
import { RunWizard } from './RunWizard';
import { ApprovalsDrawerEnhanced } from './ApprovalsDrawerEnhanced';
import { runsApi } from '@/api/runsClient';
import { useFeatureFlag } from '@/lib/featureFlags';
import { FeeRun, ExceptionItem } from '@/types/runs';
import { ExportV2Generator } from '@/lib/exportV2';
import { supabase } from '@/integrations/supabase/client';

export function SimplifiedCalculationDashboard() {
  const [activeTab, setActiveTab] = useState('runs');
  const approvalsEnabled = useFeatureFlag('FEATURE_APPROVALS');

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

  // New runs management state
  const [runs, setRuns] = useState<FeeRun[]>([]);
  const [selectedRun, setSelectedRun] = useState<FeeRun | null>(null);
  const [showWizard, setShowWizard] = useState(false);
  const [progress, setProgress] = useState<number | undefined>();
  const [exceptions, setExceptions] = useState<ExceptionItem[]>([]);
  const [runsLoading, setRunsLoading] = useState(true);
  const [approvalsDrawerOpen, setApprovalsDrawerOpen] = useState(false);
  
  // PR-4: Filters state
  const [scopeFilter, setScopeFilter] = useState<'both' | 'FUND' | 'DEAL'>('both');
  const [dealFilter, setDealFilter] = useState<string>('all');
  const [deals, setDeals] = useState<Array<{ id: string; name: string; code: string }>>([]);

  // Get the most recent calculation run or null if none exists
  const currentRun = calculationRuns[0] || null;

  // Load runs and deals on mount
  useEffect(() => {
    loadRuns();
    loadDeals();
  }, []);

  // Progress polling
  useEffect(() => {
    if (!selectedRun || selectedRun.status !== 'draft' || progress === 100) return;

    const interval = setInterval(async () => {
      try {
        const result = await runsApi.getProgress(selectedRun.id);
        setProgress(result.data.percent);
        
        if (result.data.percent >= 100) {
          // Refresh run data
          const updatedRun = await runsApi.getRun(selectedRun.id);
          setSelectedRun(updatedRun.data);
          loadRuns(); // Refresh the list
        }
      } catch (error) {
        console.error('Failed to fetch progress:', error);
        clearInterval(interval);
      }
    }, 3000);

    return () => clearInterval(interval);
  }, [selectedRun?.id, progress]);

  useEffect(() => {
    if (currentRun) {
      fetchDistributions(currentRun.id);
      fetchCalculations(currentRun.id);
    }
  }, [currentRun?.id]);

  const loadRuns = async () => {
    try {
      setRunsLoading(true);
      const result = await runsApi.listRuns();
      setRuns(result.data);
      
      // Auto-select first run if none selected
      if (!selectedRun && result.data.length > 0) {
        setSelectedRun(result.data[0]);
        setProgress(result.data[0].progress_percentage);
        loadExceptions(result.data[0].id);
      }
    } catch (error) {
      console.error('Failed to load runs:', error);
    } finally {
      setRunsLoading(false);
    }
  };

  const loadExceptions = async (runId: string) => {
    try {
      const result = await runsApi.getExceptions(runId);
      setExceptions(result.data);
    } catch (error) {
      console.error('Failed to load exceptions:', error);
    }
  };

  const loadDeals = async () => {
    try {
      const { data, error } = await supabase
        .from('deals')
        .select('id, name')
        .eq('status', 'ACTIVE')
        .order('name');
      
      if (error) throw error;
      setDeals(data || []);
    } catch (error) {
      console.error('Failed to load deals:', error);
    }
  };

  const handleCreateNewRun = async (data: any) => {
    try {
      const result = await runsApi.createRun(data);
      await loadRuns();
      
      // Select the new run
      const newRun = runs.find(r => r.id === result.id);
      if (newRun) {
        setSelectedRun(newRun);
        setProgress(0);
      }
    } catch (error) {
      console.error('Failed to create run:', error);
    }
  };

  const handleStartCalculation = async () => {
    if (!selectedRun) return;
    
    try {
      await runsApi.startCalculate(selectedRun.id);
      setProgress(5);
    } catch (error) {
      console.error('Failed to start calculation:', error);
    }
  };

  const handleSelectRun = (run: FeeRun) => {
    setSelectedRun(run);
    setProgress(run.progress_percentage);
    loadExceptions(run.id);
  };

  const handleResolveException = async (exceptionId: string) => {
    if (!selectedRun) return;
    
    try {
      await runsApi.resolveException(selectedRun.id, exceptionId);
      await loadExceptions(selectedRun.id);
    } catch (error) {
      console.error('Failed to resolve exception:', error);
    }
  };

  const handleRunCalculations = async () => {
    if (!currentRun) {
      // Create a default calculation run if none exists
      try {
        const today = new Date();
        await createCalculationRun({
          name: `Calculation ${format(today, 'MMM yyyy')}`,
          period_start: format(new Date(today.getFullYear(), today.getMonth(), 1), 'yyyy-MM-dd'),
          period_end: format(today, 'yyyy-MM-dd'),
        });
      } catch (error) {
        toast({
          title: "Error",
          description: "Failed to create calculation run.",
          variant: "destructive",
        });
        return;
      }
    }
    
    const runId = currentRun?.id || calculationRuns[0]?.id;
    if (!runId) return;
    
    try {
      await runCommissionCalculations(runId);
      await fetchCalculations(runId);
      
      toast({
        title: "Calculations Complete",
        description: "Commission calculations have been processed successfully.",
      });
    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to run calculations.",
        variant: "destructive",
      });
    }
  };

  const handleApproveCalculations = async () => {
    if (!currentRun) return;
    
    try {
      await approveCalculation(currentRun.id);
      
      toast({
        title: "Approved",
        description: "Calculations have been approved and finalized.",
      });
    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to approve calculations.",
        variant: "destructive",
      });
    }
  };

  const handleExportRun = async () => {
    if (!selectedRun) return;

    try {
      toast({
        title: "Generating Export",
        description: "Fetching run data...",
      });

      // Fetch run detail with outputs
      const detail = await runsApi.getRunDetail(selectedRun.id);

      // TODO: Fetch actual fee lines and credits from database
      // For now, use mock data structure
      const exportData = {
        run: {
          run_id: selectedRun.id,
          run_name: selectedRun.cut_off_label,
          period_start: selectedRun.period_start,
          period_end: selectedRun.period_end,
          created_at: selectedRun.created_at,
          status: selectedRun.status,
          run_hash: detail.data.run_hash,
          config_version: detail.data.config_version,
        },
        totals: {
          total_gross: selectedRun.totals?.base || 0,
          total_vat: selectedRun.totals?.vat || 0,
          total_net: selectedRun.totals?.net || 0,
        },
        scope_breakdown: detail.data.scope_breakdown || {
          FUND: { gross: 0, vat: 0, net: 0, count: 0 },
          DEAL: { gross: 0, vat: 0, net: 0, count: 0 },
        },
        fee_lines: detail.data.outputs?.fee_lines || [],
        credits_applied: [],
        fund_tracks: [],
      };

      // Generate and download workbook
      const wb = ExportV2Generator.generateWorkbook(exportData);
      const filename = ExportV2Generator.generateFilename(
        selectedRun.cut_off_label,
        selectedRun.id
      );
      
      ExportV2Generator.downloadWorkbook(wb, filename);

      toast({
        title: "Export Complete",
        description: `Downloaded ${filename}`,
      });
    } catch (error) {
      console.error('Export failed:', error);
      toast({
        title: "Export Failed",
        description: "Failed to generate export file.",
        variant: "destructive",
      });
    }
  };

  return (
    <div className="space-y-6">
      {/* Runs Header */}
      <RunsHeader 
        selectedRun={selectedRun}
        onStartCalculation={handleStartCalculation}
        onCreateRun={() => setShowWizard(true)}
        progress={progress}
      />

      {/* Header with key metrics */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Gross Fees</CardTitle>
            <DollarSign className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">${currentRun?.total_gross_fees?.toLocaleString() || '0'}</div>
            <p className="text-xs text-muted-foreground">
              {calculations.length} calculations
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total VAT</CardTitle>
            <TrendingUp className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">${currentRun?.total_vat?.toLocaleString() || '0'}</div>
            <p className="text-xs text-muted-foreground">
              VAT amount
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Net Payable</CardTitle>
            <CheckCircle className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">${currentRun?.total_net_payable?.toLocaleString() || '0'}</div>
            <p className="text-xs text-muted-foreground">
              After VAT
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Distributions</CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{distributions.length}</div>
            <p className="text-xs text-muted-foreground">
              Total distributions
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Main Content Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
        <TabsList className="grid w-full grid-cols-4">
          <TabsTrigger value="runs" className="gap-2">
            <History className="w-4 h-4" />
            Runs
          </TabsTrigger>
          <TabsTrigger value="upload" className="gap-2">
            <Upload className="w-4 h-4" />
            Upload & Calculate
          </TabsTrigger>
          <TabsTrigger value="results" className="gap-2">
            <FileText className="w-4 h-4" />
            Results
          </TabsTrigger>
          <TabsTrigger value="settings" className="gap-2">
            <Settings className="w-4 h-4" />
            Settings
          </TabsTrigger>
        </TabsList>

        {/* Runs Tab */}
        <TabsContent value="runs" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Calculation Runs History</CardTitle>
              <CardDescription>
                Select a run to view details or create a new calculation run
              </CardDescription>
            </CardHeader>
            <CardContent>
              {runsLoading ? (
                <div className="flex items-center justify-center py-8">
                  <div className="text-sm text-muted-foreground">Loading runs...</div>
                </div>
              ) : runs.length === 0 ? (
                <div className="text-center py-8">
                  <Clock className="w-12 h-12 mx-auto mb-4 text-muted-foreground" />
                  <h3 className="text-lg font-semibold mb-2">No runs yet</h3>
                  <p className="text-muted-foreground mb-4">Create your first calculation run to get started</p>
                  <Button onClick={() => setShowWizard(true)} className="gap-2">
                    <Play className="w-4 h-4" />
                    Create New Run
                  </Button>
                </div>
              ) : (
                <div className="space-y-2">
                  {runs.map((run) => (
                    <div
                      key={run.id}
                      className={`p-4 border rounded-lg cursor-pointer transition-colors ${
                        selectedRun?.id === run.id ? 'border-primary bg-primary/5' : 'hover:border-muted-foreground/50'
                      }`}
                      onClick={() => handleSelectRun(run)}
                    >
                      <div className="flex items-center justify-between">
                        <div>
                          <div className="flex items-center gap-2 mb-1">
                            <h4 className="font-medium">{run.cut_off_label}</h4>
                            <Badge variant={
                              run.status === 'approved' ? 'default' :
                              run.status === 'awaiting_approval' ? 'secondary' :
                              run.status === 'invoiced' ? 'default' :
                              run.status === 'completed' ? 'outline' :
                              'secondary'
                            }>
                              {run.status === 'awaiting_approval' ? 'AWAITING APPROVAL' :
                               run.status === 'in_progress' ? 'IN PROGRESS' :
                               run.status?.toUpperCase() || 'DRAFT'}
                            </Badge>
                            {run.exceptions_count ? (
                              <Badge variant="destructive" className="gap-1">
                                <AlertTriangle className="w-3 h-3" />
                                {run.exceptions_count}
                              </Badge>
                            ) : null}
                          </div>
                          <div className="text-sm text-muted-foreground">
                            {run.period_start} to {run.period_end} • Created {new Date(run.created_at).toLocaleDateString()}
                          </div>
                          {run.totals && (
                            <div className="text-sm mt-1">
                              <span className="text-muted-foreground">Total: </span>
                              <span className="font-medium">${run.totals.total.toLocaleString()}</span>
                            </div>
                          )}
                        </div>
                        
                         <div className="flex items-center gap-2">
                           {run.progress_percentage !== undefined && run.progress_percentage < 100 && (
                             <div className="text-sm text-muted-foreground">
                               {run.progress_percentage}%
                             </div>
                           )}
                           {approvalsEnabled && (
                             <Button
                               variant="ghost"
                               size="sm"
                               onClick={(e) => {
                                 e.stopPropagation();
                                 setSelectedRun(run);
                                 setApprovalsDrawerOpen(true);
                               }}
                             >
                               <Users className="w-4 h-4" />
                             </Button>
                           )}
                         </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="upload" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Upload Distribution Data</CardTitle>
              <CardDescription>
                Upload an Excel file with investor names and distribution amounts. The system will automatically find related parties and calculate commissions.
              </CardDescription>
            </CardHeader>
            <CardContent>
              <ExcelDistributionUpload 
                calculationRunId={currentRun?.id || 'temp'} 
                onUploadComplete={(distributions) => {
                  if (currentRun) {
                    fetchDistributions(currentRun.id);
                  }
                  // Auto-calculate after upload
                  setTimeout(() => {
                    handleRunCalculations();
                    setActiveTab('results');
                  }, 1000);
                  
                  toast({
                    title: "Upload Complete",
                    description: `Successfully uploaded ${distributions.length} distributions. Calculating commissions...`,
                  });
                }}
              />
            </CardContent>
          </Card>

          {distributions.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle>Uploaded Distributions ({distributions.length})</CardTitle>
                <CardDescription>Preview of uploaded distribution data</CardDescription>
              </CardHeader>
              <CardContent>
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Investor</TableHead>
                      <TableHead>Fund</TableHead>
                      <TableHead>Amount</TableHead>
                      <TableHead>Distributor</TableHead>
                      <TableHead>Date</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {distributions.slice(0, 5).map((dist) => (
                      <TableRow key={dist.id}>
                        <TableCell className="font-medium">{dist.investor_name}</TableCell>
                        <TableCell>{dist.fund_name}</TableCell>
                        <TableCell>${dist.distribution_amount.toLocaleString()}</TableCell>
                        <TableCell>{dist.distributor_name}</TableCell>
                        <TableCell>{dist.distribution_date ? format(new Date(dist.distribution_date), 'MMM dd, yyyy') : 'N/A'}</TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
                {distributions.length > 5 && (
                  <div className="text-center pt-4">
                    <p className="text-sm text-muted-foreground">
                      Showing 5 of {distributions.length} distributions
                    </p>
                  </div>
                )}
                
                <div className="pt-4">
                  <Button onClick={handleRunCalculations} className="gap-2" size="lg">
                    <Calculator className="h-5 w-5" />
                    Calculate Commissions Now
                  </Button>
                </div>
              </CardContent>
            </Card>
          )}
        </TabsContent>

        <TabsContent value="results" className="space-y-4">
          {selectedRun && (
            <>
              {/* Filters Card */}
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Filter className="w-5 h-5" />
                    Filters
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <Label>Scope</Label>
                      <Select value={scopeFilter} onValueChange={(v: any) => setScopeFilter(v)}>
                        <SelectTrigger>
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="both">
                            <div className="flex items-center gap-2">
                              <Filter className="w-4 h-4" />
                              Both (FUND + DEAL)
                            </div>
                          </SelectItem>
                          <SelectItem value="FUND">
                            <div className="flex items-center gap-2">
                              <Building2 className="w-4 h-4" />
                              FUND only
                            </div>
                          </SelectItem>
                          <SelectItem value="DEAL">
                            <div className="flex items-center gap-2">
                              <Target className="w-4 h-4" />
                              DEAL only
                            </div>
                          </SelectItem>
                        </SelectContent>
                      </Select>
                    </div>

                    <div className="space-y-2">
                      <Label>Deal</Label>
                      <Select value={dealFilter} onValueChange={setDealFilter}>
                        <SelectTrigger>
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="all">All Deals</SelectItem>
                          {deals.map((deal) => (
                            <SelectItem key={deal.id} value={deal.id}>
                              {deal.name}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </div>
                  </div>
                </CardContent>
              </Card>

              {/* Run Results Card */}
              <Card>
                <CardHeader>
                  <div className="flex items-center justify-between">
                    <div>
                      <CardTitle>Run Results</CardTitle>
                      <CardDescription>
                        {selectedRun.cut_off_label} • {selectedRun.status}
                      </CardDescription>
                    </div>
                    <Button 
                      onClick={handleExportRun}
                      variant="outline"
                      className="gap-2"
                    >
                      <Download className="w-4 h-4" />
                      Export XLSX
                    </Button>
                  </div>
                </CardHeader>
              </Card>

              {/* Precedence Banner */}
              {(() => {
                // Check if both FUND and DEAL agreements exist for any party
                const hasBothScopes = calculations.some((c: any) => c.scope === 'FUND') && 
                                     calculations.some((c: any) => c.scope === 'DEAL');
                
                // Check if same party has both FUND and DEAL
                const partyScopes = new Map<string, Set<string>>();
                calculations.forEach((c: any) => {
                  if (!partyScopes.has(c.entity_name)) {
                    partyScopes.set(c.entity_name, new Set());
                  }
                  partyScopes.get(c.entity_name)?.add(c.scope);
                });
                
                const partiesWithBoth = Array.from(partyScopes.entries())
                  .filter(([_, scopes]) => scopes.has('FUND') && scopes.has('DEAL'))
                  .map(([party]) => party);

                if (partiesWithBoth.length > 0) {
                  return (
                    <Alert>
                      <Info className="h-4 w-4" />
                      <AlertDescription>
                        <strong>Precedence Applied:</strong> {partiesWithBoth.join(', ')} {partiesWithBoth.length === 1 ? 'has' : 'have'} both FUND and DEAL agreements. 
                        DEAL-scoped fees override FUND fees for rows with a deal_id. No duplicate charges.
                      </AlertDescription>
                    </Alert>
                  );
                }
              })()}

              {/* Tabs for different views */}
              <Tabs defaultValue="overview" className="space-y-4">
                <TabsList>
                  <TabsTrigger value="overview">Overview</TabsTrigger>
                  <TabsTrigger value="calculations">Calculations</TabsTrigger>
                  <TabsTrigger value="exceptions">Exceptions</TabsTrigger>
                  <TabsTrigger value="approvals">Approvals</TabsTrigger>
                </TabsList>

                <TabsContent value="overview">
...
                </TabsContent>

                <TabsContent value="calculations">
                  <Card>
...
                  </Card>
                </TabsContent>

                <TabsContent value="exceptions">
                  <Card>
...
                  </Card>
                </TabsContent>

                <TabsContent value="approvals">
                  <Card>
...
                  </Card>
                </TabsContent>
              </Tabs>
            </>
          )}
        </TabsContent>

        <TabsContent value="settings" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Calculation Settings</CardTitle>
              <CardDescription>
                Configure calculation preferences and default values
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="text-center py-8 text-muted-foreground">
                Settings panel coming soon
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* Wizard for creating new runs */}
      <RunWizard
        open={showWizard}
        onOpenChange={setShowWizard}
        onSubmit={handleCreateNewRun}
      />

      {/* Approvals Drawer */}
      <ApprovalsDrawerEnhanced
        open={approvalsDrawerOpen}
        onOpenChange={setApprovalsDrawerOpen}
        run={selectedRun}
        onApprovalChange={() => {
          // Refresh runs data when approval changes
          loadRuns();
          if (selectedRun) {
            loadExceptions(selectedRun.id);
          }
        }}
      />
    </div>
  );
}