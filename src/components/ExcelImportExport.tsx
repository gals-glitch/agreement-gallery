import React, { useState, useCallback, useEffect } from 'react';
import { useDropzone } from 'react-dropzone';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Progress } from '@/components/ui/progress';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Badge } from '@/components/ui/badge';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Label } from '@/components/ui/label';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/hooks/useAuth';
import { ExcelProcessor, DISTRIBUTION_COLUMNS, type ColumnMapping, type ProcessedExcelData } from '@/lib/excel';

// Debug log to verify import is working
console.log('ExcelImportExport component loaded, DISTRIBUTION_COLUMNS:', DISTRIBUTION_COLUMNS?.length || 'undefined');
import { 
  Upload, 
  FileSpreadsheet, 
  CheckCircle, 
  XCircle, 
  AlertTriangle, 
  Download,
  Map, // Using Map icon instead of Mapping
  Eye,
  RefreshCcw,
  Trash2,
  ArrowLeft
} from 'lucide-react';
import { useNavigate } from 'react-router-dom';

interface ImportJob {
  id: string;
  file_name: string;
  status: 'pending' | 'processing' | 'completed' | 'failed';
  total_rows?: number;
  processed_rows?: number;
  success_count?: number;
  error_count?: number;
  progress_percentage?: number;
  validation_errors?: any[];
  created_at: string;
  error_message?: string;
}

export function ExcelImportExport() {
  const navigate = useNavigate();
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [parsedData, setParsedData] = useState<ProcessedExcelData | null>(null);
  const [columnMapping, setColumnMapping] = useState<ColumnMapping>({});
  const [showMappingDialog, setShowMappingDialog] = useState(false);
  const [showPreviewDialog, setShowPreviewDialog] = useState(false);
  const [isProcessing, setIsProcessing] = useState(false);
  const [importJobs, setImportJobs] = useState<ImportJob[]>([]);
  const [activeTab, setActiveTab] = useState('upload');
  const { toast } = useToast();
  const { user } = useAuth();

  // Load import jobs
  const loadImportJobs = useCallback(async () => {
    if (!user) return;
    
    const { data, error } = await supabase
      .from('excel_import_jobs')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(10);
    
    if (error) {
      console.error('Error loading import jobs:', error);
    } else {
      setImportJobs((data || []) as ImportJob[]);
    }
  }, [user]);

  useEffect(() => {
    loadImportJobs();
  }, [loadImportJobs]);

  // File upload handling
  const onDrop = useCallback(async (acceptedFiles: File[]) => {
    const file = acceptedFiles[0];
    if (!file) return;

    setSelectedFile(file);
    setIsProcessing(true);

    try {
      const parsed = await ExcelProcessor.parseExcelFile(file);
      setParsedData(parsed);
      
      // Auto-map columns where possible
      const autoMapping: ColumnMapping = {};
      parsed.headers.forEach(header => {
        const normalizedHeader = header.toLowerCase().trim();
        const matchedColumn = DISTRIBUTION_COLUMNS.find(col => 
          col.label.toLowerCase().includes(normalizedHeader) ||
          normalizedHeader.includes(col.label.toLowerCase()) ||
          col.key.toLowerCase().includes(normalizedHeader)
        );
        if (matchedColumn) {
          autoMapping[header] = matchedColumn.key;
        }
      });
      
      setColumnMapping(autoMapping);
      setShowMappingDialog(true);
      
      toast({
        title: "File parsed successfully",
        description: `Found ${parsed.totalRows} rows with ${parsed.headers.length} columns.`,
      });
    } catch (error) {
      toast({
        title: "Failed to parse file",
        description: error instanceof Error ? error.message : "Unknown error",
        variant: "destructive",
      });
    } finally {
      setIsProcessing(false);
    }
  }, [toast]);

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: {
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': ['.xlsx'],
      'application/vnd.ms-excel': ['.xls'],
      'text/csv': ['.csv']
    },
    maxSize: 20 * 1024 * 1024, // 20MB
    multiple: false
  });

  // Column mapping handlers
  const updateColumnMapping = (excelColumn: string, fieldKey: string) => {
    setColumnMapping(prev => ({
      ...prev,
      [excelColumn]: fieldKey
    }));
  };

  const removeColumnMapping = (excelColumn: string) => {
    setColumnMapping(prev => {
      const newMapping = { ...prev };
      delete newMapping[excelColumn];
      return newMapping;
    });
  };

  // Preview data with mapping
  const getPreviewData = () => {
    if (!parsedData) return [];
    
    const validationErrors = ExcelProcessor.validateData(parsedData.data, columnMapping);
    const transformedData = ExcelProcessor.transformData(parsedData.data.slice(0, 5), columnMapping);
    
    return transformedData.map((row, index) => ({
      ...row,
      _hasErrors: validationErrors.some(err => err.row === (parsedData.data[index]?._rowNumber || index + 1))
    }));
  };

  // Import data to database
  const handleImport = async () => {
    if (!parsedData || !user) return;

    setIsProcessing(true);

    try {
      // Validate data
      const validationErrors = ExcelProcessor.validateData(parsedData.data, columnMapping);
      
      if (validationErrors.length > 0) {
        toast({
          title: "Validation failed",
          description: `Found ${validationErrors.length} validation errors. Please fix them before importing.`,
          variant: "destructive",
        });
        setIsProcessing(false);
        return;
      }

      // Upload file to storage first
      const fileExt = selectedFile!.name.split('.').pop();
      const fileName = `${Date.now()}_${selectedFile!.name}`;
      const filePath = `${user.id}/${fileName}`;

      const { error: uploadError } = await supabase.storage
        .from('excel-files')
        .upload(filePath, selectedFile!);

      if (uploadError) {
        throw new Error(`File upload failed: ${uploadError.message}`);
      }

      // Create import job record
      const { data: job, error: jobError } = await supabase
        .from('excel_import_jobs')
        .insert([{
          user_id: user.id,
          file_name: selectedFile!.name,
          file_path: filePath,
          total_rows: parsedData.totalRows,
          column_mapping: columnMapping,
          status: 'processing'
        }])
        .select()
        .single();

      if (jobError) {
        throw new Error(`Failed to create import job: ${jobError.message}`);
      }

      // Transform and insert data
      const transformedData = ExcelProcessor.transformData(parsedData.data, columnMapping);
      const distributionData = transformedData.map(row => ({
        ...row,
        import_job_id: job.id,
        created_at: new Date().toISOString()
      }));

      const { error: insertError } = await supabase
        .from('investor_distributions')
        .insert(distributionData);

      if (insertError) {
        // Update job status to failed
        await supabase
          .from('excel_import_jobs')
          .update({ 
            status: 'failed', 
            error_message: insertError.message,
            completed_at: new Date().toISOString()
          })
          .eq('id', job.id);
        
        throw new Error(`Failed to import data: ${insertError.message}`);
      }

      // Update job status to completed
      await supabase
        .from('excel_import_jobs')
        .update({ 
          status: 'completed', 
          processed_rows: parsedData.totalRows,
          success_count: parsedData.totalRows,
          progress_percentage: 100,
          completed_at: new Date().toISOString()
        })
        .eq('id', job.id);

      toast({
        title: "Import successful",
        description: `Successfully imported ${parsedData.totalRows} investor distributions.`,
      });

      // Reset form
      setSelectedFile(null);
      setParsedData(null);
      setColumnMapping({});
      setShowMappingDialog(false);
      loadImportJobs();
      setActiveTab('history');

    } catch (error) {
      toast({
        title: "Import failed",
        description: error instanceof Error ? error.message : "Unknown error",
        variant: "destructive",
      });
    } finally {
      setIsProcessing(false);
    }
  };

  // Download template
  const downloadTemplate = () => {
    try {
      const template = ExcelProcessor.generateTemplate();
      const blob = new Blob([template], { 
        type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' 
      });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'investor_distributions_template.xlsx';
      a.click();
      URL.revokeObjectURL(url);
      
      toast({
        title: "Template downloaded",
        description: "Use this template to format your data correctly.",
      });
    } catch (error) {
      toast({
        title: "Download failed",
        description: "Failed to generate template",
        variant: "destructive",
      });
    }
  };

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
            <h2 className="text-2xl font-bold">Excel Import/Export</h2>
            <p className="text-muted-foreground">
              Import investor distributions from Excel files or export calculation results
            </p>
          </div>
        </div>
        <Button onClick={downloadTemplate} variant="outline" className="gap-2">
          <Download className="w-4 h-4" />
          Download Template
        </Button>
      </div>

      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList className="grid w-full grid-cols-3">
          <TabsTrigger value="upload">Upload</TabsTrigger>
          <TabsTrigger value="history">Import History</TabsTrigger>
          <TabsTrigger value="export">Export</TabsTrigger>
        </TabsList>

        <TabsContent value="upload" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Upload className="w-5 h-5" />
                Upload Excel File
              </CardTitle>
              <CardDescription>
                Upload an Excel file containing investor distribution data. Supported formats: .xlsx, .xls, .csv
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div
                {...getRootProps()}
                className={`border-2 border-dashed rounded-lg p-8 text-center transition-colors cursor-pointer
                  ${isDragActive ? 'border-primary bg-primary/10' : 'border-muted-foreground/25 hover:border-primary/50'}
                  ${isProcessing ? 'pointer-events-none opacity-50' : ''}`}
              >
                <input {...getInputProps()} />
                <FileSpreadsheet className="w-12 h-12 mx-auto mb-4 text-muted-foreground" />
                {isDragActive ? (
                  <p className="text-lg">Drop the file here...</p>
                ) : (
                  <div className="space-y-2">
                    <p className="text-lg">Drag & drop an Excel file here, or click to select</p>
                    <p className="text-sm text-muted-foreground">
                      Maximum file size: 20MB • Formats: .xlsx, .xls, .csv
                    </p>
                  </div>
                )}
                {isProcessing && (
                  <div className="mt-4">
                    <div className="animate-spin w-6 h-6 border-2 border-primary border-t-transparent rounded-full mx-auto"></div>
                    <p className="mt-2 text-sm">Processing file...</p>
                  </div>
                )}
              </div>

              {selectedFile && !isProcessing && (
                <div className="mt-4 p-4 bg-muted rounded-lg">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <FileSpreadsheet className="w-4 h-4" />
                      <span className="font-medium">{selectedFile.name}</span>
                      <Badge variant="secondary">
                        {(selectedFile.size / 1024 / 1024).toFixed(2)} MB
                      </Badge>
                    </div>
                    <Button 
                      variant="ghost" 
                      size="sm" 
                      onClick={() => {
                        setSelectedFile(null);
                        setParsedData(null);
                        setColumnMapping({});
                      }}
                    >
                      <Trash2 className="w-4 h-4" />
                    </Button>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="history" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center justify-between">
                <span>Import History</span>
                <Button variant="outline" size="sm" onClick={loadImportJobs}>
                  <RefreshCcw className="w-4 h-4 mr-2" />
                  Refresh
                </Button>
              </CardTitle>
              <CardDescription>
                View your recent Excel import jobs and their status
              </CardDescription>
            </CardHeader>
            <CardContent>
              {importJobs.length === 0 ? (
                <div className="text-center py-8 text-muted-foreground">
                  No import jobs yet. Start by uploading an Excel file.
                </div>
              ) : (
                <div className="space-y-4">
                  {importJobs.map((job) => (
                    <div key={job.id} className="border rounded-lg p-4">
                      <div className="flex items-center justify-between mb-2">
                        <div className="flex items-center gap-2">
                          <FileSpreadsheet className="w-4 h-4" />
                          <span className="font-medium">{job.file_name}</span>
                        </div>
                        <div className="flex items-center gap-2">
                          {job.status === 'completed' && <CheckCircle className="w-4 h-4 text-green-600" />}
                          {job.status === 'failed' && <XCircle className="w-4 h-4 text-red-600" />}
                          {job.status === 'processing' && <div className="w-4 h-4 animate-spin border-2 border-primary border-t-transparent rounded-full" />}
                          <Badge variant={
                            job.status === 'completed' ? 'default' :
                            job.status === 'failed' ? 'destructive' :
                            'secondary'
                          }>
                            {job.status}
                          </Badge>
                        </div>
                      </div>
                      
                      {job.status === 'processing' && job.progress_percentage !== undefined && (
                        <Progress value={job.progress_percentage} className="mb-2" />
                      )}
                      
                      <div className="text-sm text-muted-foreground space-y-1">
                        <div>Created: {new Date(job.created_at).toLocaleString()}</div>
                        {job.total_rows && (
                          <div>
                            Rows: {job.processed_rows || 0} / {job.total_rows}
                            {job.success_count && ` (${job.success_count} successful)`}
                            {job.error_count && ` (${job.error_count} errors)`}
                          </div>
                        )}
                        {job.error_message && (
                          <Alert className="mt-2">
                            <AlertTriangle className="h-4 w-4" />
                            <AlertDescription>{job.error_message}</AlertDescription>
                          </Alert>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="export" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Export Calculations</CardTitle>
              <CardDescription>
                Export commission calculation results to Excel format
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="text-center py-8 text-muted-foreground">
                Export functionality will be integrated with the calculation engine
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* Column Mapping Dialog */}
      <Dialog open={showMappingDialog} onOpenChange={setShowMappingDialog}>
        <DialogContent className="max-w-4xl max-h-[80vh]">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <Map className="w-5 h-5" />
              Map Excel Columns
            </DialogTitle>
            <DialogDescription>
              Map your Excel columns to the expected fields. Required fields are marked with a red asterisk.
            </DialogDescription>
          </DialogHeader>
          
          <ScrollArea className="max-h-96">
            <div className="space-y-4">
              {parsedData?.headers.map((header) => (
                <div key={header} className="flex items-center gap-4">
                  <div className="min-w-48">
                    <Label className="text-sm font-medium">{header}</Label>
                  </div>
                  <Select
                    value={columnMapping[header] || ''}
                    onValueChange={(value) => {
                      if (value === 'unmapped') {
                        removeColumnMapping(header);
                      } else {
                        updateColumnMapping(header, value);
                      }
                    }}
                  >
                    <SelectTrigger className="w-64">
                      <SelectValue placeholder="Select field..." />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="unmapped">
                        <span className="text-muted-foreground">Don't map</span>
                      </SelectItem>
                      {DISTRIBUTION_COLUMNS.map((col) => (
                        <SelectItem key={col.key} value={col.key}>
                          <span className="flex items-center gap-2">
                            {col.label}
                            {col.required && <span className="text-red-500">*</span>}
                          </span>
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              ))}
            </div>
          </ScrollArea>
          
          <div className="flex items-center justify-between pt-4 border-t">
            <Button 
              variant="outline" 
              onClick={() => setShowPreviewDialog(true)}
              disabled={Object.keys(columnMapping).length === 0}
              className="gap-2"
            >
              <Eye className="w-4 h-4" />
              Preview Data
            </Button>
            <div className="flex gap-2">
              <Button variant="outline" onClick={() => setShowMappingDialog(false)}>
                Cancel
              </Button>
              <Button 
                onClick={handleImport}
                disabled={isProcessing || Object.keys(columnMapping).length === 0}
                className="gap-2"
              >
                {isProcessing ? (
                  <div className="w-4 h-4 animate-spin border-2 border-current border-t-transparent rounded-full" />
                ) : (
                  <Upload className="w-4 h-4" />
                )}
                Import Data
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* Data Preview Dialog */}
      <Dialog open={showPreviewDialog} onOpenChange={setShowPreviewDialog}>
        <DialogContent className="max-w-6xl max-h-[80vh]">
          <DialogHeader>
            <DialogTitle>Data Preview</DialogTitle>
            <DialogDescription>
              Preview of how your data will be imported (showing first 5 rows)
            </DialogDescription>
          </DialogHeader>
          
          <ScrollArea className="max-h-96">
            <Table>
              <TableHeader>
                <TableRow>
                  {DISTRIBUTION_COLUMNS.map((col) => (
                    <TableHead key={col.key}>
                      {col.label}
                      {col.required && <span className="text-red-500 ml-1">*</span>}
                    </TableHead>
                  ))}
                </TableRow>
              </TableHeader>
              <TableBody>
                {getPreviewData().map((row, index) => (
                  <TableRow key={index} className={row._hasErrors ? 'bg-red-50' : ''}>
                    {DISTRIBUTION_COLUMNS.map((col) => (
                      <TableCell key={col.key}>
                        {row[col.key] || (
                          <span className="text-muted-foreground italic">empty</span>
                        )}
                      </TableCell>
                    ))}
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </ScrollArea>
        </DialogContent>
      </Dialog>
    </div>
  );
}