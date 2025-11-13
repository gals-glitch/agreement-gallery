import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Checkbox } from '@/components/ui/checkbox';
import { Badge } from '@/components/ui/badge';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Calendar } from '@/components/ui/calendar';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { Separator } from '@/components/ui/separator';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { 
  Download, 
  FileSpreadsheet, 
  CalendarIcon, 
  Filter, 
  Settings,
  Info,
  CheckCircle,
  Clock,
  AlertTriangle,
  ArrowLeft
} from 'lucide-react';
import { format } from 'date-fns';
import { cn } from '@/lib/utils';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';
import { useAdvancedCommissionCalculations, type CalculationRun } from '@/hooks/useAdvancedCommissionCalculations';
import { useNavigate } from 'react-router-dom';

interface ExportJob {
  id: string;
  type: 'summary' | 'detail' | 'vat' | 'audit';
  status: 'queued' | 'running' | 'completed' | 'failed';
  progress: number;
  filename?: string;
  downloadUrl?: string;
  createdAt: Date;
  completedAt?: Date;
  errorMessage?: string;
  estimatedCompletion?: Date;
}

interface ExportFilters {
  calculationRunIds: string[];
  fundNames: string[];
  partyNames: string[];
  dateRange?: { start: Date; end: Date };
  runStatus: string[];
}

interface ColumnConfig {
  [key: string]: {
    enabled: boolean;
    label: string;
    required?: boolean;
  };
}

const exportTypes = [
  {
    id: 'summary' as const,
    label: 'Summary Report',
    description: 'Party × Fund × Period totals (Net/Gross, VAT, Caps)',
    icon: FileSpreadsheet,
    color: 'bg-blue-500'
  },
  {
    id: 'detail' as const,
    label: 'Detail Report', 
    description: 'Line-by-line commission breakdown with references',
    icon: FileSpreadsheet,
    color: 'bg-green-500'
  },
  {
    id: 'vat' as const,
    label: 'VAT/Tax Report',
    description: 'Jurisdiction rates, taxable base, VAT calculations',
    icon: FileSpreadsheet,
    color: 'bg-orange-500'
  },
  {
    id: 'audit' as const,
    label: 'Audit Trail',
    description: 'Full calculation trace with inputs and rule versions',
    icon: FileSpreadsheet,
    color: 'bg-purple-500'
  }
];

const defaultColumns = {
  summary: {
    'party_name': { enabled: true, label: 'Party Name', required: true },
    'fund_name': { enabled: true, label: 'Fund Name', required: true },
    'period_start': { enabled: true, label: 'Period Start', required: true },
    'period_end': { enabled: true, label: 'Period End', required: true },
    'gross_commission': { enabled: true, label: 'Gross Commission', required: true },
    'vat_amount': { enabled: true, label: 'VAT Amount' },
    'net_commission': { enabled: true, label: 'Net Commission', required: true },
    'currency': { enabled: true, label: 'Currency' },
    'cap_applied': { enabled: true, label: 'Cap Applied' },
    'vat_mode': { enabled: true, label: 'VAT Mode' }
  },
  detail: {
    'calc_run_id': { enabled: true, label: 'Calculation Run ID', required: true },
    'distribution_id': { enabled: true, label: 'Distribution ID', required: true },
    'investor_name': { enabled: true, label: 'Investor Name', required: true },
    'fund_name': { enabled: true, label: 'Fund Name', required: true },
    'entity_name': { enabled: true, label: 'Entity Name', required: true },
    'commission_type': { enabled: true, label: 'Commission Type', required: true },
    'rule_id': { enabled: true, label: 'Rule ID', required: true },
    'rule_version': { enabled: false, label: 'Rule Version' },
    'base_amount': { enabled: true, label: 'Base Amount', required: true },
    'applied_rate': { enabled: true, label: 'Applied Rate' },
    'tier_applied': { enabled: false, label: 'Tier Applied' },
    'gross_commission': { enabled: true, label: 'Gross Commission', required: true },
    'vat_rate': { enabled: true, label: 'VAT Rate' },
    'vat_amount': { enabled: true, label: 'VAT Amount' },
    'net_commission': { enabled: true, label: 'Net Commission', required: true },
    'calculation_method': { enabled: false, label: 'Calculation Method' },
    'conditions_met': { enabled: false, label: 'Conditions Met' }
  },
  vat: {
    'jurisdiction': { enabled: true, label: 'Jurisdiction', required: true },
    'vat_rate': { enabled: true, label: 'VAT Rate', required: true },
    'taxable_base': { enabled: true, label: 'Taxable Base', required: true },
    'vat_amount': { enabled: true, label: 'VAT Amount', required: true },
    'vat_mode': { enabled: true, label: 'VAT Mode', required: true },
    'total_gross': { enabled: true, label: 'Total Gross' },
    'total_net': { enabled: true, label: 'Total Net' },
    'currency': { enabled: true, label: 'Currency' }
  },
  audit: {
    'calc_run_id': { enabled: true, label: 'Calculation Run ID', required: true },
    'distribution_id': { enabled: true, label: 'Distribution ID', required: true },
    'rule_id': { enabled: true, label: 'Rule ID', required: true },
    'rule_version_id': { enabled: true, label: 'Rule Version ID', required: true },
    'input_data': { enabled: true, label: 'Input Data', required: true },
    'step_trace': { enabled: true, label: 'Step Trace', required: true },
    'tier_selected': { enabled: true, label: 'Tier Selected' },
    'adjustments_applied': { enabled: true, label: 'Adjustments Applied' },
    'calculated_by': { enabled: true, label: 'Calculated By' },
    'calculated_at': { enabled: true, label: 'Calculated At', required: true },
    'checksum': { enabled: true, label: 'Checksum', required: true },
    'execution_time_ms': { enabled: false, label: 'Execution Time (ms)' }
  }
};

export function ExportCenter() {
  const navigate = useNavigate();
  const { calculationRuns, loading } = useAdvancedCommissionCalculations();
  const [selectedType, setSelectedType] = useState<'summary' | 'detail' | 'vat' | 'audit'>('summary');
  const [filters, setFilters] = useState<ExportFilters>({
    calculationRunIds: [],
    fundNames: [],
    partyNames: [],
    runStatus: ['approved']
  });
  const [columns, setColumns] = useState<ColumnConfig>(defaultColumns.summary);
  const [customFilename, setCustomFilename] = useState('');
  const [roundingPrecision, setRoundingPrecision] = useState(2);
  const [exportJobs, setExportJobs] = useState<ExportJob[]>([]);
  const [isExporting, setIsExporting] = useState(false);

  const { toast } = useToast();

  if (loading) {
    return (
      <div className="flex items-center justify-center p-8">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
      </div>
    );
  }

  const handleTypeChange = (type: 'summary' | 'detail' | 'vat' | 'audit') => {
    setSelectedType(type);
    setColumns(defaultColumns[type]);
  };

  const handleColumnToggle = (columnId: string, enabled: boolean) => {
    setColumns(prev => ({
      ...prev,
      [columnId]: { ...prev[columnId], enabled }
    }));
  };

  const addFilterValue = (filterType: keyof ExportFilters, value: string) => {
    if (filterType === 'calculationRunIds' || filterType === 'fundNames' || filterType === 'partyNames' || filterType === 'runStatus') {
      setFilters(prev => ({
        ...prev,
        [filterType]: [...prev[filterType], value]
      }));
    }
  };

  const removeFilterValue = (filterType: keyof ExportFilters, value: string) => {
    if (filterType === 'calculationRunIds' || filterType === 'fundNames' || filterType === 'partyNames' || filterType === 'runStatus') {
      setFilters(prev => ({
        ...prev,
        [filterType]: prev[filterType].filter(v => v !== value)
      }));
    }
  };

  const generateFilename = () => {
    if (customFilename) return `${customFilename}.xlsx`;
    
    const timestamp = format(new Date(), 'yyyyMMdd_HHmm');
    const fundPart = filters.fundNames.length === 1 ? `_${filters.fundNames[0]}` : '';
    return `run${fundPart}_${timestamp}_${selectedType}.xlsx`;
  };

  const handleExport = async () => {
    setIsExporting(true);
    
    try {
      // Create export job
      const exportJob: ExportJob = {
        id: crypto.randomUUID(),
        type: selectedType,
        status: 'queued',
        progress: 0,
        createdAt: new Date(),
        estimatedCompletion: new Date(Date.now() + 5 * 60 * 1000) // 5 minutes estimate
      };

      setExportJobs(prev => [exportJob, ...prev]);

      const exportPayload = {
        type: selectedType,
        filters: {
          calculation_run_ids: filters.calculationRunIds,
          fund_names: filters.fundNames.length > 0 ? filters.fundNames : undefined,
          party_names: filters.partyNames.length > 0 ? filters.partyNames : undefined,
          date_range: filters.dateRange ? {
            start: format(filters.dateRange.start, 'yyyy-MM-dd'),
            end: format(filters.dateRange.end, 'yyyy-MM-dd')
          } : undefined,
          run_status: filters.runStatus
        },
        columns: Object.entries(columns)
          .filter(([_, config]) => config.enabled)
          .map(([key, config]) => ({ key, label: config.label })),
        options: {
          filename: generateFilename(),
          rounding_precision: roundingPrecision
        }
      };

      console.log('Starting export with payload:', exportPayload);

      // Call export function
      const { data, error } = await supabase.functions.invoke('export-commission-data', {
        body: exportPayload
      });

      if (error) throw error;

      // Update job status
      setExportJobs(prev => prev.map(job => 
        job.id === exportJob.id 
          ? { ...job, status: 'completed', progress: 100, filename: data.filename, downloadUrl: data.downloadUrl, completedAt: new Date() }
          : job
      ));

      toast({
        title: "Export Started",
        description: `${selectedType.charAt(0).toUpperCase() + selectedType.slice(1)} export is being generated.`
      });

    } catch (error: any) {
      console.error('Export failed:', error);
      
      setExportJobs(prev => prev.map(job => 
        job.id === exportJobs[0]?.id 
          ? { ...job, status: 'failed', errorMessage: error.message }
          : job
      ));

      toast({
        title: "Export Failed",
        description: error?.message || "Failed to start export",
        variant: "destructive"
      });
    } finally {
      setIsExporting(false);
    }
  };

  const approvedRuns = calculationRuns.filter(run => run.status === 'approved');
  const enabledColumns = Object.entries(columns).filter(([_, config]) => config.enabled);
  const requiredColumns = Object.entries(columns).filter(([_, config]) => config.required);

  // Ensure we have at least one approved run selected
  const hasValidSelection = filters.calculationRunIds.length > 0 && 
    filters.calculationRunIds.every(id => approvedRuns.some(run => run.id === id));

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Button 
            variant="ghost" 
            size="sm"
            onClick={() => navigate(-1)}
            className="gap-2"
          >
            <ArrowLeft className="h-4 w-4" />
            Back
          </Button>
          <div>
            <h2 className="text-2xl font-bold tracking-tight">Export Center</h2>
            <p className="text-muted-foreground">
              Generate finance-ready reports with custom filters and formatting
            </p>
          </div>
        </div>
        <div className="flex items-center gap-3">
          <Badge variant="outline" className="px-3 py-1">
            {approvedRuns.length} approved runs available
          </Badge>
          {approvedRuns.length === 0 && (
            <Badge variant="destructive" className="px-3 py-1">
              No approved runs - exports disabled
            </Badge>
          )}
        </div>
      </div>

      {/* Approval Gate Alert */}
      {approvedRuns.length === 0 && (
        <Alert>
          <AlertTriangle className="h-4 w-4" />
          <AlertDescription>
            Exports are only available for approved calculation runs. Please complete the approval workflow in the Calculations page before generating exports.
          </AlertDescription>
        </Alert>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Column - Export Type & Filters */}
        <div className="lg:col-span-2 space-y-6">
          {/* Export Type Selection */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <FileSpreadsheet className="h-5 w-5" />
                Export Type
              </CardTitle>
              <CardDescription>Choose the type of report to generate</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {exportTypes.map((type) => (
                  <div
                    key={type.id}
                    className={cn(
                      "p-4 border rounded-lg cursor-pointer transition-all",
                      selectedType === type.id 
                        ? "border-primary bg-primary/5" 
                        : "border-border hover:border-primary/50"
                    )}
                    onClick={() => handleTypeChange(type.id)}
                  >
                    <div className="flex items-start gap-3">
                      <div className={cn("p-2 rounded-md text-white", type.color)}>
                        <type.icon className="h-4 w-4" />
                      </div>
                      <div className="flex-1">
                        <h3 className="font-medium">{type.label}</h3>
                        <p className="text-sm text-muted-foreground mt-1">
                          {type.description}
                        </p>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>

          {/* Filters */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Filter className="h-5 w-5" />
                Filters
              </CardTitle>
              <CardDescription>Narrow down your export scope</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              {/* Approved Calculation Runs */}
              <div>
                <Label className="flex items-center gap-2">
                  Approved Calculation Runs
                  <CheckCircle className="h-4 w-4 text-green-500" />
                </Label>
                <Select 
                  value="" 
                  onValueChange={(value) => addFilterValue('calculationRunIds', value)}
                  disabled={approvedRuns.length === 0}
                >
                  <SelectTrigger>
                    <SelectValue placeholder={
                      approvedRuns.length === 0 
                        ? "No approved runs available" 
                        : "Select approved run to export..."
                    } />
                  </SelectTrigger>
                  <SelectContent>
                    {approvedRuns.map((run) => (
                      <SelectItem key={run.id} value={run.id}>
                        <div className="flex items-center gap-2">
                          <CheckCircle className="h-3 w-3 text-green-500" />
                          {run.name} ({format(new Date(run.period_start), 'MMM dd')} - {format(new Date(run.period_end), 'MMM dd, yyyy')})
                        </div>
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                {filters.calculationRunIds.length > 0 && (
                  <div className="flex flex-wrap gap-1 mt-2">
                    {filters.calculationRunIds.map((runId) => {
                      const run = calculationRuns.find(r => r.id === runId);
                      const isApproved = approvedRuns.some(r => r.id === runId);
                      return (
                        <Badge 
                          key={runId} 
                          variant={isApproved ? "default" : "destructive"} 
                          className="text-xs flex items-center gap-1"
                        >
                          {isApproved && <CheckCircle className="h-3 w-3" />}
                          {run?.name || runId.slice(0, 8)}
                          <button 
                            onClick={() => removeFilterValue('calculationRunIds', runId)}
                            className="ml-1 hover:text-destructive"
                          >
                            ×
                          </button>
                        </Badge>
                      );
                    })}
                  </div>
                )}
                {filters.calculationRunIds.length > 0 && !hasValidSelection && (
                  <p className="text-sm text-destructive mt-1">
                    ⚠️ Only approved runs can be exported. Please select approved runs only.
                  </p>
                )}
              </div>

              {/* Fund Names */}
              <div>
                <Label>Fund Names (Optional)</Label>
                <Input 
                  placeholder="Enter fund name and press Enter..." 
                  onKeyDown={(e) => {
                    if (e.key === 'Enter' && e.currentTarget.value.trim()) {
                      addFilterValue('fundNames', e.currentTarget.value.trim());
                      e.currentTarget.value = '';
                    }
                  }}
                />
                {filters.fundNames.length > 0 && (
                  <div className="flex flex-wrap gap-1 mt-2">
                    {filters.fundNames.map((fund, index) => (
                      <Badge key={index} variant="secondary" className="text-xs">
                        {fund}
                        <button 
                          onClick={() => removeFilterValue('fundNames', fund)}
                          className="ml-1 hover:text-destructive"
                        >
                          ×
                        </button>
                      </Badge>
                    ))}
                  </div>
                )}
              </div>

              {/* Party Names */}
              <div>
                <Label>Party Names (Optional)</Label>
                <Input 
                  placeholder="Enter party name and press Enter..." 
                  onKeyDown={(e) => {
                    if (e.key === 'Enter' && e.currentTarget.value.trim()) {
                      addFilterValue('partyNames', e.currentTarget.value.trim());
                      e.currentTarget.value = '';
                    }
                  }}
                />
                {filters.partyNames.length > 0 && (
                  <div className="flex flex-wrap gap-1 mt-2">
                    {filters.partyNames.map((party, index) => (
                      <Badge key={index} variant="secondary" className="text-xs">
                        {party}
                        <button 
                          onClick={() => removeFilterValue('partyNames', party)}
                          className="ml-1 hover:text-destructive"
                        >
                          ×
                        </button>
                      </Badge>
                    ))}
                  </div>
                )}
              </div>

              {/* Date Range */}
              <div>
                <Label>Date Range (Optional)</Label>
                <div className="grid grid-cols-2 gap-2 mt-1">
                  <Popover>
                    <PopoverTrigger asChild>
                      <Button
                        variant="outline"
                        size="sm"
                        className={cn(
                          "justify-start text-left font-normal",
                          !filters.dateRange?.start && "text-muted-foreground"
                        )}
                      >
                        <CalendarIcon className="mr-2 h-4 w-4" />
                        {filters.dateRange?.start ? format(filters.dateRange.start, "MMM dd") : "Start date"}
                      </Button>
                    </PopoverTrigger>
                    <PopoverContent className="w-auto p-0" align="start">
                      <Calendar
                        mode="single"
                        selected={filters.dateRange?.start}
                        onSelect={(date) => setFilters(prev => ({
                          ...prev,
                          dateRange: { ...prev.dateRange, start: date } as any
                        }))}
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
                          !filters.dateRange?.end && "text-muted-foreground"
                        )}
                      >
                        <CalendarIcon className="mr-2 h-4 w-4" />
                        {filters.dateRange?.end ? format(filters.dateRange.end, "MMM dd") : "End date"}
                      </Button>
                    </PopoverTrigger>
                    <PopoverContent className="w-auto p-0" align="start">
                      <Calendar
                        mode="single"
                        selected={filters.dateRange?.end}
                        onSelect={(date) => setFilters(prev => ({
                          ...prev,
                          dateRange: { ...prev.dateRange, end: date } as any
                        }))}
                        initialFocus
                        className="pointer-events-auto"
                      />
                    </PopoverContent>
                  </Popover>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Right Column - Configuration & Actions */}
        <div className="space-y-6">
          {/* Column Configuration */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Settings className="h-5 w-5" />
                Columns
              </CardTitle>
              <CardDescription>Select columns to include in export</CardDescription>
            </CardHeader>
            <CardContent>
              <ScrollArea className="h-48">
                <div className="space-y-2">
                  {Object.entries(columns).map(([columnId, config]) => (
                    <div key={columnId} className="flex items-center space-x-2">
                      <Checkbox
                        id={columnId}
                        checked={config.enabled}
                        onCheckedChange={(checked) => handleColumnToggle(columnId, !!checked)}
                        disabled={config.required}
                      />
                      <Label 
                        htmlFor={columnId} 
                        className={cn(
                          "text-sm flex-1",
                          config.required && "font-medium"
                        )}
                      >
                        {config.label}
                        {config.required && <span className="text-red-500 ml-1">*</span>}
                      </Label>
                    </div>
                  ))}
                </div>
              </ScrollArea>
              <div className="text-xs text-muted-foreground mt-2">
                {enabledColumns.length} of {Object.keys(columns).length} columns selected
                ({requiredColumns.length} required)
              </div>
            </CardContent>
          </Card>

          {/* Export Options */}
          <Card>
            <CardHeader>
              <CardTitle>Export Options</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <Label htmlFor="filename">Custom Filename (Optional)</Label>
                <Input
                  id="filename"
                  value={customFilename}
                  onChange={(e) => setCustomFilename(e.target.value)}
                  placeholder="Leave blank for auto-generated"
                />
                <p className="text-xs text-muted-foreground mt-1">
                  Preview: {generateFilename()}
                </p>
              </div>

              <div>
                <Label htmlFor="precision">Rounding Precision</Label>
                <Select value={roundingPrecision.toString()} onValueChange={(value) => setRoundingPrecision(parseInt(value))}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="0">0 decimal places</SelectItem>
                    <SelectItem value="2">2 decimal places</SelectItem>
                    <SelectItem value="4">4 decimal places</SelectItem>
                    <SelectItem value="6">6 decimal places</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <Alert>
                <Info className="h-4 w-4" />
                <AlertDescription className="text-xs">
                  Numbers will be rounded to {roundingPrecision} decimal places for display. 
                  Full precision is maintained for calculations.
                </AlertDescription>
              </Alert>

              <Button 
                onClick={handleExport}
                disabled={isExporting || !hasValidSelection || approvedRuns.length === 0}
                className="w-full gap-2"
              >
                <Download className="h-4 w-4" />
                {isExporting 
                  ? 'Generating...' 
                  : !hasValidSelection
                    ? 'Select approved runs to export'
                    : `Export ${selectedType.charAt(0).toUpperCase() + selectedType.slice(1)}`
                }
              </Button>
            </CardContent>
          </Card>

          {/* Recent Exports */}
          {exportJobs.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle>Recent Exports</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  {exportJobs.slice(0, 5).map((job) => (
                    <div key={job.id} className="flex items-center justify-between p-2 border rounded">
                      <div className="flex items-center gap-2">
                        {job.status === 'completed' && <CheckCircle className="h-4 w-4 text-green-500" />}
                        {job.status === 'running' && <Clock className="h-4 w-4 text-blue-500" />}
                        {job.status === 'failed' && <AlertTriangle className="h-4 w-4 text-red-500" />}
                        
                        <div>
                          <p className="text-sm font-medium">{job.type}</p>
                          <p className="text-xs text-muted-foreground">
                            {format(job.createdAt, 'MMM dd, HH:mm')}
                          </p>
                        </div>
                      </div>
                      
                      {job.status === 'completed' && job.downloadUrl && (
                        <Button size="sm" variant="outline" asChild>
                          <a href={job.downloadUrl} download={job.filename}>
                            <Download className="h-3 w-3" />
                          </a>
                        </Button>
                      )}
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}
        </div>
      </div>
    </div>
  );
}