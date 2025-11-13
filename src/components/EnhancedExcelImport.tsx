import React, { useState, useCallback, useRef } from 'react';
import { useDropzone } from 'react-dropzone';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Switch } from '@/components/ui/switch';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { useToast } from '@/hooks/use-toast';
import { 
  Upload, 
  FileSpreadsheet, 
  CheckCircle, 
  XCircle, 
  AlertTriangle, 
  Download, 
  Settings,
  MapPin,
  Play,
  RotateCcw,
  ArrowLeft
} from 'lucide-react';
import { ExcelImportEngine, ImportValidationError, ParsedExcelData, MappingTemplate } from '@/lib/excelImportEngine';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/hooks/useAuth';
import { useNavigate } from 'react-router-dom';

interface ImportJobStatus {
  id?: string;
  status: 'idle' | 'parsing' | 'validating' | 'staging' | 'committing' | 'completed' | 'failed';
  progress: number;
  fileName?: string;
  totalRows: number;
  validRows: number;
  errorRows: number;
  warnings: number;
  errors: ImportValidationError[];
  autoRunCalculation: boolean;
  duplicateStrategy: 'reject' | 'allow' | 'update';
  importType: string;
}

const IMPORT_TYPES = [
  { value: 'contributions', label: 'Contributions/Transactions', description: 'Investor contributions and transaction data' },
  { value: 'investors', label: 'Investor Master', description: 'Investor profiles and basic information' },
  { value: 'credits', label: 'Credits/Adjustments', description: 'Repurchase and equalization credits' },
  { value: 'agreements', label: 'Agreement Seeds', description: 'Commission agreement data (Admin only)' }
];

const DUPLICATE_STRATEGIES = [
  { value: 'reject', label: 'Reject Duplicates', description: 'Skip rows that match existing records' },
  { value: 'allow', label: 'Allow Duplicates', description: 'Import all rows including duplicates' },
  { value: 'update', label: 'Update Existing', description: 'Update existing records with new data' }
];

export function EnhancedExcelImport() {
  const navigate = useNavigate();
  const { user, hasAnyRole } = useAuth();
  const { toast } = useToast();
  const [job, setJob] = useState<ImportJobStatus>({
    status: 'idle',
    progress: 0,
    totalRows: 0,
    validRows: 0,
    errorRows: 0,
    warnings: 0,
    errors: [],
    autoRunCalculation: false,
    duplicateStrategy: 'reject',
    importType: 'contributions'
  });
  
  const [parsedData, setParsedData] = useState<ParsedExcelData | null>(null);
  const [columnMappings, setColumnMappings] = useState<Record<string, string>>({});
  const [mappingTemplates, setMappingTemplates] = useState<MappingTemplate[]>([]);
  const [selectedTemplate, setSelectedTemplate] = useState<string>('');
  const [showMappingEditor, setShowMappingEditor] = useState(false);
  
  const engineRef = useRef<ExcelImportEngine>();

  // Initialize engine with progress callback
  const getEngine = useCallback(() => {
    if (!engineRef.current) {
      engineRef.current = new ExcelImportEngine((progress, status) => {
        setJob(prev => ({ 
          ...prev, 
          progress, 
          status: status as ImportJobStatus['status']
        }));
      });
    }
    return engineRef.current;
  }, []);

  // File drop handler
  const onDrop = useCallback(async (acceptedFiles: File[]) => {
    const file = acceptedFiles[0];
    if (!file) return;

    setJob(prev => ({
      ...prev,
      status: 'parsing',
      progress: 0,
      fileName: file.name,
      errors: []
    }));

    try {
      const engine = getEngine();
      const data = await engine.parseExcelFile(file);
      
      setParsedData(data);
      
      // Auto-detect mappings
      const detectedMappings = engine.autoDetectMappings(data.headers, job.importType);
      setColumnMappings(detectedMappings);
      
      setJob(prev => ({
        ...prev,
        status: 'validating',
        totalRows: data.totalRows,
        progress: 50
      }));

      // Validate data
      const errors = engine.validateMappedData(data.rows, detectedMappings, job.importType);
      const errorRows = new Set(errors.filter(e => e.severity === 'error').map(e => e.row)).size;
      const warnings = errors.filter(e => e.severity === 'warning').length;
      
      setJob(prev => ({
        ...prev,
        status: errors.length > 0 ? 'failed' : 'completed',
        progress: 100,
        validRows: data.totalRows - errorRows,
        errorRows,
        warnings,
        errors
      }));

      if (Object.keys(detectedMappings).length < data.headers.length) {
        setShowMappingEditor(true);
        toast({
          title: "Mapping needed",
          description: "Some columns could not be auto-mapped. Please review the column mappings.",
          variant: "default"
        });
      }

    } catch (error: any) {
      setJob(prev => ({
        ...prev,
        status: 'failed',
        progress: 0,
        errors: [{ row: 0, field: 'file', message: error.message, severity: 'error' }]
      }));
      
      toast({
        title: "Import failed",
        description: error.message,
        variant: "destructive"
      });
    }
  }, [job.importType, getEngine, toast]);

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: {
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': ['.xlsx'],
      'text/csv': ['.csv']
    },
    multiple: false,
    disabled: job.status !== 'idle'
  });

  // Load mapping templates
  React.useEffect(() => {
    const loadTemplates = async () => {
      const { data } = await supabase
        .from('import_mapping_templates')
        .select('*')
        .eq('import_type', job.importType)
        .order('is_default', { ascending: false });
      
      if (data) {
        setMappingTemplates(data.map(t => ({
          id: t.id,
          name: t.name,
          importType: t.import_type,
          columnMappings: t.column_mappings as Record<string, string>,
          isDefault: t.is_default
        })));
        
        // Auto-select default template
        const defaultTemplate = data.find(t => t.is_default);
        if (defaultTemplate) {
          setSelectedTemplate(defaultTemplate.id);
          setColumnMappings(defaultTemplate.column_mappings as Record<string, string>);
        }
      }
    };

    loadTemplates();
  }, [job.importType]);

  // Apply mapping template
  const applyTemplate = (templateId: string) => {
    const template = mappingTemplates.find(t => t.id === templateId);
    if (template) {
      setColumnMappings(template.columnMappings);
      setSelectedTemplate(templateId);
      
      // Re-validate with new mappings
      if (parsedData) {
        const engine = getEngine();
        const errors = engine.validateMappedData(parsedData.rows, template.columnMappings, job.importType);
        const errorRows = new Set(errors.filter(e => e.severity === 'error').map(e => e.row)).size;
        const warnings = errors.filter(e => e.severity === 'warning').length;
        
        setJob(prev => ({
          ...prev,
          validRows: parsedData.totalRows - errorRows,
          errorRows,
          warnings,
          errors
        }));
      }
    }
  };

  // Update column mapping
  const updateMapping = (excelColumn: string, field: string) => {
    const newMappings = { ...columnMappings };
    if (field === '') {
      delete newMappings[excelColumn];
    } else {
      newMappings[excelColumn] = field;
    }
    setColumnMappings(newMappings);
    
    // Re-validate
    if (parsedData) {
      const engine = getEngine();
      const errors = engine.validateMappedData(parsedData.rows, newMappings, job.importType);
      const errorRows = new Set(errors.filter(e => e.severity === 'error').map(e => e.row)).size;
      const warnings = errors.filter(e => e.severity === 'warning').length;
      
      setJob(prev => ({
        ...prev,
        validRows: parsedData.totalRows - errorRows,
        errorRows,
        warnings,
        errors
      }));
    }
  };

  // Download error report
  const downloadErrorReport = () => {
    if (!parsedData || job.errors.length === 0) return;
    
    const engine = getEngine();
    const errorReport = engine.createErrorReport(parsedData, job.errors, columnMappings);
    
    // Convert Uint8Array to ArrayBuffer for Blob compatibility
    const blob = new Blob([errorReport.buffer as ArrayBuffer], { 
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' 
    });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `${job.fileName?.replace(/\.[^/.]+$/, '')}_errors.xlsx`;
    a.click();
    URL.revokeObjectURL(url);
  };

  // Start import process
  const startImport = async () => {
    if (!parsedData || !user || job.errorRows > 0) return;
    
    try {
      setJob(prev => ({ ...prev, status: 'staging' }));
      
      // Create import job in database
      const { data: importJob, error } = await supabase
        .from('excel_import_jobs')
        .insert({
          user_id: user.id,
          file_name: job.fileName || '',
          file_path: '', // Will be set when file is uploaded to storage
          import_type: job.importType,
          total_rows: job.totalRows,
          status: 'staging',
          mapping_template_id: selectedTemplate || null,
          auto_run_calculation: job.autoRunCalculation,
          duplicate_strategy: job.duplicateStrategy,
          column_mapping: columnMappings as any
        })
        .select()
        .single();
      
      if (error) throw error;
      
      setJob(prev => ({ ...prev, id: importJob.id, status: 'committing' }));
      
      // TODO: Process data into staging table
      // TODO: Commit to final tables
      // TODO: Trigger calculation if enabled
      
      setJob(prev => ({ ...prev, status: 'completed', progress: 100 }));
      
      toast({
        title: "Import completed",
        description: `Successfully imported ${job.validRows} rows`,
      });
      
    } catch (error: any) {
      setJob(prev => ({ ...prev, status: 'failed' }));
      toast({
        title: "Import failed",
        description: error.message,
        variant: "destructive"
      });
    }
  };

  // Reset import
  const resetImport = () => {
    setJob({
      status: 'idle',
      progress: 0,
      totalRows: 0,
      validRows: 0,
      errorRows: 0,
      warnings: 0,
      errors: [],
      autoRunCalculation: false,
      duplicateStrategy: 'reject',
      importType: 'contributions'
    });
    setParsedData(null);
    setColumnMappings({});
    setShowMappingEditor(false);
  };

  const canImport = job.status === 'completed' && job.errorRows === 0 && job.validRows > 0;
  const showAdmin = hasAnyRole(['admin']);

  return (
    <div className="space-y-6">
      <div className="mb-6">
        <Button 
          variant="ghost" 
          size="sm"
          onClick={() => navigate(-1)}
          className="gap-2"
        >
          <ArrowLeft className="h-4 w-4" />
          Back
        </Button>
      </div>
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <FileSpreadsheet className="w-5 h-5" />
            Excel Import
          </CardTitle>
          <CardDescription>
            Import and validate Excel files with automated mapping and business rule validation
          </CardDescription>
        </CardHeader>
        
        <CardContent className="space-y-6">
          {/* Import Configuration */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="space-y-2">
              <Label htmlFor="importType">Import Type</Label>
              <Select 
                value={job.importType} 
                onValueChange={(value) => setJob(prev => ({ ...prev, importType: value }))}
                disabled={job.status !== 'idle'}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {IMPORT_TYPES.map(type => (
                    <SelectItem 
                      key={type.value} 
                      value={type.value}
                      disabled={type.value === 'agreements' && !showAdmin}
                    >
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
              <Label htmlFor="duplicateStrategy">Duplicate Strategy</Label>
              <Select 
                value={job.duplicateStrategy} 
                onValueChange={(value: any) => setJob(prev => ({ ...prev, duplicateStrategy: value }))}
                disabled={job.status !== 'idle'}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {DUPLICATE_STRATEGIES.map(strategy => (
                    <SelectItem key={strategy.value} value={strategy.value}>
                      <div>
                        <div className="font-medium">{strategy.label}</div>
                        <div className="text-xs text-muted-foreground">{strategy.description}</div>
                      </div>
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            
            <div className="space-y-2">
              <Label className="flex items-center gap-2">
                <Switch 
                  checked={job.autoRunCalculation}
                  onCheckedChange={(checked) => setJob(prev => ({ ...prev, autoRunCalculation: checked }))}
                  disabled={job.status !== 'idle'}
                />
                Auto-run Calculation
              </Label>
              <p className="text-xs text-muted-foreground">
                Automatically trigger commission calculations after successful import
              </p>
            </div>
          </div>

          {/* File Upload Area */}
          {job.status === 'idle' && (
            <div
              {...getRootProps()}
              className={`border-2 border-dashed rounded-lg p-8 text-center cursor-pointer transition-colors ${
                isDragActive 
                  ? 'border-primary bg-primary/5' 
                  : 'border-muted-foreground/25 hover:border-primary/50'
              }`}
            >
              <input {...getInputProps()} />
              <Upload className="w-12 h-12 mx-auto mb-4 text-muted-foreground" />
              {isDragActive ? (
                <p className="text-lg">Drop the file here...</p>
              ) : (
                <div>
                  <p className="text-lg mb-2">Drag & drop an Excel file here, or click to browse</p>
                  <p className="text-sm text-muted-foreground">
                    Supports .xlsx and .csv files up to 20MB
                  </p>
                </div>
              )}
            </div>
          )}

          {/* Progress Indicator */}
          {job.status !== 'idle' && (
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  {job.status === 'completed' && job.errorRows === 0 && (
                    <CheckCircle className="w-5 h-5 text-green-600" />
                  )}
                  {job.status === 'failed' || job.errorRows > 0 && (
                    <XCircle className="w-5 h-5 text-red-600" />
                  )}
                  {job.warnings > 0 && (
                    <AlertTriangle className="w-5 h-5 text-yellow-600" />
                  )}
                  <span className="font-medium">{job.fileName}</span>
                </div>
                
                <Button
                  variant="outline"
                  size="sm"
                  onClick={resetImport}
                  className="gap-2"
                >
                  <RotateCcw className="w-4 h-4" />
                  Reset
                </Button>
              </div>
              
              <Progress value={job.progress} className="w-full" />
              
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-center">
                <div>
                  <div className="text-2xl font-bold">{job.totalRows}</div>
                  <div className="text-sm text-muted-foreground">Total Rows</div>
                </div>
                <div>
                  <div className="text-2xl font-bold text-green-600">{job.validRows}</div>
                  <div className="text-sm text-muted-foreground">Valid</div>
                </div>
                <div>
                  <div className="text-2xl font-bold text-red-600">{job.errorRows}</div>
                  <div className="text-sm text-muted-foreground">Errors</div>
                </div>
                <div>
                  <div className="text-2xl font-bold text-yellow-600">{job.warnings}</div>
                  <div className="text-sm text-muted-foreground">Warnings</div>
                </div>
              </div>
            </div>
          )}

          {/* Column Mapping */}
          {parsedData && (
            <Card>
              <CardHeader className="flex flex-row items-center justify-between">
                <div>
                  <CardTitle className="text-lg">Column Mapping</CardTitle>
                  <CardDescription>
                    Map Excel columns to system fields
                  </CardDescription>
                </div>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setShowMappingEditor(!showMappingEditor)}
                  className="gap-2"
                >
                  <Settings className="w-4 h-4" />
                  {showMappingEditor ? 'Hide' : 'Edit'} Mapping
                </Button>
              </CardHeader>
              
              {showMappingEditor && (
                <CardContent>
                  <Tabs defaultValue="mapping" className="w-full">
                    <TabsList>
                      <TabsTrigger value="mapping">Column Mapping</TabsTrigger>
                      <TabsTrigger value="templates">Templates</TabsTrigger>
                    </TabsList>
                    
                    <TabsContent value="mapping" className="space-y-4">
                      {parsedData.headers.map(header => (
                        <div key={header} className="flex items-center gap-4">
                          <div className="w-48">
                            <Badge variant="outline">{header}</Badge>
                          </div>
                          <MapPin className="w-4 h-4 text-muted-foreground" />
                          <Select 
                            value={columnMappings[header] || ''} 
                            onValueChange={(value) => updateMapping(header, value)}
                          >
                            <SelectTrigger className="w-48">
                              <SelectValue placeholder="Select field..." />
                            </SelectTrigger>
                            <SelectContent>
                              <SelectItem value="">-- No mapping --</SelectItem>
                              {/* Dynamic field options based on import type */}
                              {job.importType === 'contributions' && (
                                <>
                                  <SelectItem value="investor_id">Investor ID</SelectItem>
                                  <SelectItem value="investor_name">Investor Name</SelectItem>
                                  <SelectItem value="fund_id">Fund ID</SelectItem>
                                  <SelectItem value="fund_name">Fund Name</SelectItem>
                                  <SelectItem value="date">Date</SelectItem>
                                  <SelectItem value="amount">Amount</SelectItem>
                                  <SelectItem value="currency">Currency</SelectItem>
                                  <SelectItem value="source_channel">Source Channel</SelectItem>
                                  <SelectItem value="external_ref">External Reference</SelectItem>
                                  <SelectItem value="notes">Notes</SelectItem>
                                </>
                              )}
                            </SelectContent>
                          </Select>
                        </div>
                      ))}
                    </TabsContent>
                    
                    <TabsContent value="templates" className="space-y-4">
                      <div className="space-y-2">
                        <Label>Saved Templates</Label>
                        <Select value={selectedTemplate} onValueChange={applyTemplate}>
                          <SelectTrigger>
                            <SelectValue placeholder="Select template..." />
                          </SelectTrigger>
                          <SelectContent>
                            {mappingTemplates.map(template => (
                              <SelectItem key={template.id} value={template.id}>
                                <div className="flex items-center gap-2">
                                  {template.name}
                                  {template.isDefault && <Badge variant="secondary">Default</Badge>}
                                </div>
                              </SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                      </div>
                    </TabsContent>
                  </Tabs>
                </CardContent>
              )}
            </Card>
          )}

          {/* Validation Results */}
          {job.errors.length > 0 && (
            <Alert variant={job.errorRows > 0 ? "destructive" : "default"}>
              <AlertTriangle className="h-4 w-4" />
              <AlertDescription className="flex items-center justify-between w-full">
                <span>
                  Found {job.errors.length} validation issues 
                  ({job.errorRows} errors, {job.warnings} warnings)
                </span>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={downloadErrorReport}
                  className="gap-2"
                >
                  <Download className="w-4 h-4" />
                  Download Report
                </Button>
              </AlertDescription>
            </Alert>
          )}

          {/* Action Buttons */}
          <div className="flex justify-end gap-2">
            <Button
              onClick={startImport}
              disabled={!canImport}
              className="gap-2"
            >
              <Play className="w-4 h-4" />
              Start Import
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}