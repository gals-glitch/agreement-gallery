import React, { useState, useCallback } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Progress } from '@/components/ui/progress';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Upload, FileSpreadsheet, CheckCircle, AlertCircle, X, Users } from 'lucide-react';
import * as XLSX from 'xlsx';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from '@/hooks/use-toast';
import { EntitySelector } from '@/components/EntitySelector';

interface ContributionRow {
  InvestorId?: string;
  InvestorName: string;
  Fund: string;
  Deal?: string;
  ContributionDate: string;
  ContributionAmount: number;
  Currency: string;
  SourceFile?: string;
  Notes?: string;
  // Entity assignments
  DistributorName?: string;
  ReferrerName?: string;
  PartnerName?: string;
}

interface ValidationError {
  row: number;
  field: string;
  message: string;
  severity: 'error' | 'warning';
}

interface Props {
  calculationRunId?: string;
  onUploadComplete?: (data: ContributionRow[]) => void;
}

export function EntityValidatedUpload({ calculationRunId, onUploadComplete }: Props) {
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [uploadData, setUploadData] = useState<ContributionRow[]>([]);
  const [validationErrors, setValidationErrors] = useState<ValidationError[]>([]);
  const [entityValidation, setEntityValidation] = useState<{[key: string]: boolean}>({});
  const [isProcessing, setIsProcessing] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [uploadComplete, setUploadComplete] = useState(false);
  const [activeTab, setActiveTab] = useState('upload');
  
  const { toast } = useToast();

  const requiredColumns = [
    'InvestorName',
    'Fund', 
    'ContributionDate',
    'ContributionAmount',
    'Currency'
  ];

  const validateEntities = async (data: ContributionRow[]): Promise<ValidationError[]> => {
    try {
      // Get all entities from database
      const { data: entities, error } = await supabase
        .from('entities')
        .select('name, entity_type, is_active');

      if (error) throw error;

      const entityMap = new Map();
      entities.forEach(entity => {
        const key = `${entity.entity_type}:${entity.name}`;
        entityMap.set(key, entity.is_active);
      });

      const errors: ValidationError[] = [];
      const validation: {[key: string]: boolean} = {};

      data.forEach((row, index) => {
        // Validate distributor
        if (row.DistributorName) {
          const key = `distributor:${row.DistributorName}`;
          const isValid = entityMap.has(key);
          const isActive = entityMap.get(key);
          validation[`${index}-distributor`] = isValid && isActive;
          
          if (!isValid) {
            errors.push({
              row: index + 2,
              field: 'DistributorName',
              message: `Distributor "${row.DistributorName}" not found in entity database`,
              severity: 'error'
            });
          } else if (!isActive) {
            errors.push({
              row: index + 2,
              field: 'DistributorName',
              message: `Distributor "${row.DistributorName}" is inactive`,
              severity: 'warning'
            });
          }
        }

        // Validate referrer
        if (row.ReferrerName) {
          const key = `referrer:${row.ReferrerName}`;
          const isValid = entityMap.has(key);
          const isActive = entityMap.get(key);
          validation[`${index}-referrer`] = isValid && isActive;
          
          if (!isValid) {
            errors.push({
              row: index + 2,
              field: 'ReferrerName',
              message: `Referrer "${row.ReferrerName}" not found in entity database`,
              severity: 'error'
            });
          } else if (!isActive) {
            errors.push({
              row: index + 2,
              field: 'ReferrerName',
              message: `Referrer "${row.ReferrerName}" is inactive`,
              severity: 'warning'
            });
          }
        }

        // Validate partner
        if (row.PartnerName) {
          const key = `partner:${row.PartnerName}`;
          const isValid = entityMap.has(key);
          const isActive = entityMap.get(key);
          validation[`${index}-partner`] = isValid && isActive;
          
          if (!isValid) {
            errors.push({
              row: index + 2,
              field: 'PartnerName',
              message: `Partner "${row.PartnerName}" not found in entity database`,
              severity: 'error'
            });
          } else if (!isActive) {
            errors.push({
              row: index + 2,
              field: 'PartnerName',
              message: `Partner "${row.PartnerName}" is inactive`,
              severity: 'warning'
            });
          }
        }
      });

      setEntityValidation(validation);
      return errors;
    } catch (error) {
      console.error('Error validating entities:', error);
      return [{
        row: 0,
        field: 'system',
        message: 'Failed to validate entities against database',
        severity: 'error' as const
      }];
    }
  };

  const validateRow = (row: ContributionRow, index: number): ValidationError[] => {
    const errors: ValidationError[] = [];

    // Required fields validation
    if (!row.InvestorName?.trim()) {
      errors.push({ row: index + 2, field: 'InvestorName', message: 'Investor name is required', severity: 'error' });
    }
    
    if (!row.Fund?.trim()) {
      errors.push({ row: index + 2, field: 'Fund', message: 'Fund is required', severity: 'error' });
    }

    if (!row.ContributionDate) {
      errors.push({ row: index + 2, field: 'ContributionDate', message: 'Contribution date is required', severity: 'error' });
    } else {
      const date = new Date(row.ContributionDate);
      if (isNaN(date.getTime())) {
        errors.push({ row: index + 2, field: 'ContributionDate', message: 'Invalid date format (use YYYY-MM-DD)', severity: 'error' });
      }
    }

    if (!row.ContributionAmount || row.ContributionAmount <= 0) {
      errors.push({ row: index + 2, field: 'ContributionAmount', message: 'Contribution amount must be greater than 0', severity: 'error' });
    }

    if (!row.Currency?.trim()) {
      errors.push({ row: index + 2, field: 'Currency', message: 'Currency is required', severity: 'error' });
    }

    return errors;
  };

  const handleFileSelect = useCallback((event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      const validTypes = [
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'application/vnd.ms-excel'
      ];
      
      if (validTypes.includes(file.type)) {
        setSelectedFile(file);
        setUploadData([]);
        setValidationErrors([]);
        setEntityValidation({});
        setUploadComplete(false);
        setActiveTab('upload');
      } else {
        toast({
          title: "Invalid File Type",
          description: "Please select an Excel file (.xlsx or .xls)",
          variant: "destructive"
        });
      }
    }
  }, [toast]);

  const processExcelFile = async () => {
    if (!selectedFile) return;

    setIsProcessing(true);
    setUploadProgress(10);

    try {
      const data = await selectedFile.arrayBuffer();
      const workbook = XLSX.read(data);
      const sheetName = workbook.SheetNames[0];
      const worksheet = workbook.Sheets[sheetName];
      
      const jsonData = XLSX.utils.sheet_to_json(worksheet, { 
        header: 1,
        defval: ""
      }) as any[][];

      setUploadProgress(30);

      if (jsonData.length < 2) {
        throw new Error('Excel file must contain header row and at least one data row');
      }

      const headers = jsonData[0] as string[];
      const missingColumns = requiredColumns.filter(col => !headers.includes(col));
      
      if (missingColumns.length > 0) {
        throw new Error(`Missing required columns: ${missingColumns.join(', ')}`);
      }

      setUploadProgress(50);

      const rows: ContributionRow[] = jsonData.slice(1).map((row: any[]) => {
        const obj: any = {};
        headers.forEach((header, index) => {
          obj[header] = row[index];
        });
        return obj;
      }).filter(row => row.InvestorName);

      setUploadProgress(70);

      // Validate basic data
      const dataErrors: ValidationError[] = [];
      rows.forEach((row, index) => {
        const rowErrors = validateRow(row, index);
        dataErrors.push(...rowErrors);
      });

      // Validate entities
      const entityErrors = await validateEntities(rows);
      const allErrors = [...dataErrors, ...entityErrors];

      setValidationErrors(allErrors);
      setUploadData(rows);
      setUploadProgress(100);
      setActiveTab('review');

      const errorCount = allErrors.filter(e => e.severity === 'error').length;
      const warningCount = allErrors.filter(e => e.severity === 'warning').length;

      if (errorCount === 0) {
        toast({
          title: "File Processed Successfully",
          description: `${rows.length} records ready${warningCount > 0 ? ` (${warningCount} warnings)` : ''}`
        });
      } else {
        toast({
          title: "Validation Issues Found",
          description: `${errorCount} errors, ${warningCount} warnings found`,
          variant: "destructive"
        });
      }

    } catch (error) {
      console.error('Error processing Excel file:', error);
      toast({
        title: "Processing Error",
        description: error instanceof Error ? error.message : "Failed to process Excel file",
        variant: "destructive"
      });
    } finally {
      setIsProcessing(false);
    }
  };

  const handleImportData = async () => {
    const errors = validationErrors.filter(e => e.severity === 'error');
    if (errors.length > 0) {
      toast({
        title: "Cannot Import",
        description: "Please fix all errors before importing",
        variant: "destructive"
      });
      return;
    }

    if (!calculationRunId) {
      toast({
        title: "No Calculation Run",
        description: "Please select a calculation run first",
        variant: "destructive"
      });
      return;
    }

    setIsProcessing(true);
    setUploadProgress(0);

    try {
      const insertData = uploadData.map(row => ({
        calculation_run_id: calculationRunId,
        investor_name: row.InvestorName,
        fund_name: row.Fund,
        distribution_amount: row.ContributionAmount,
        distribution_date: row.ContributionDate,
        distributor_name: row.DistributorName || null,
        referrer_name: row.ReferrerName || null,
        partner_name: row.PartnerName || null
      }));

      setUploadProgress(30);

      const batchSize = 100;
      for (let i = 0; i < insertData.length; i += batchSize) {
        const batch = insertData.slice(i, i + batchSize);
        
        const { error } = await supabase
          .from('investor_distributions')
          .insert(batch);

        if (error) throw error;
        
        setUploadProgress(30 + (70 * (i + batch.length)) / insertData.length);
      }

      setUploadComplete(true);
      
      toast({
        title: "Import Successful",
        description: `${uploadData.length} records imported successfully`
      });

      onUploadComplete?.(uploadData);

    } catch (error) {
      console.error('Error importing data:', error);
      toast({
        title: "Import Error",
        description: "Failed to import contribution data",
        variant: "destructive"
      });
    } finally {
      setIsProcessing(false);
    }
  };

  const resetUpload = () => {
    setSelectedFile(null);
    setUploadData([]);
    setValidationErrors([]);
    setEntityValidation({});
    setUploadProgress(0);
    setUploadComplete(false);
    setActiveTab('upload');
  };

  const getRowValidationStatus = (index: number) => {
    const rowErrors = validationErrors.filter(e => e.row === index + 2);
    const hasErrors = rowErrors.some(e => e.severity === 'error');
    const hasWarnings = rowErrors.some(e => e.severity === 'warning');
    
    if (hasErrors) return 'error';
    if (hasWarnings) return 'warning';
    return 'valid';
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <FileSpreadsheet className="w-5 h-5" />
          Entity-Validated Upload
        </CardTitle>
        <CardDescription>
          Upload contribution data with automatic entity validation
        </CardDescription>
      </CardHeader>
      <CardContent>
        <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-4">
          <TabsList className="grid w-full grid-cols-3">
            <TabsTrigger value="upload">Upload File</TabsTrigger>
            <TabsTrigger value="review" disabled={!uploadData.length}>Review Data</TabsTrigger>
            <TabsTrigger value="entities" disabled={!uploadData.length}>Entity Guide</TabsTrigger>
          </TabsList>

          <TabsContent value="upload" className="space-y-4">
            {!selectedFile && (
              <div className="space-y-4">
                <div>
                  <Label htmlFor="excel-upload">Select Excel File</Label>
                  <Input
                    id="excel-upload"
                    type="file"
                    accept=".xlsx,.xls"
                    onChange={handleFileSelect}
                  />
                </div>
                
                <Alert>
                  <AlertCircle className="h-4 w-4" />
                  <AlertDescription>
                    <strong>Required columns:</strong> {requiredColumns.join(', ')}
                    <br />
                    <strong>Optional columns:</strong> InvestorId, Deal, SourceFile, Notes, DistributorName, ReferrerName, PartnerName
                    <br />
                    <strong>Entity validation:</strong> Distributor, Referrer, and Partner names will be validated against your entity database.
                  </AlertDescription>
                </Alert>
              </div>
            )}

            {selectedFile && !uploadData.length && (
              <div className="space-y-4">
                <div className="flex items-center gap-2">
                  <FileSpreadsheet className="w-4 h-4" />
                  <span className="text-sm">{selectedFile.name}</span>
                  <Button variant="outline" size="sm" onClick={resetUpload}>
                    <X className="w-4 h-4" />
                  </Button>
                </div>
                
                <Button onClick={processExcelFile} disabled={isProcessing}>
                  {isProcessing ? 'Processing...' : 'Process & Validate File'}
                </Button>
                
                {isProcessing && (
                  <div className="space-y-2">
                    <Progress value={uploadProgress} />
                    <p className="text-sm text-muted-foreground">Processing and validating data...</p>
                  </div>
                )}
              </div>
            )}
          </TabsContent>

          <TabsContent value="review" className="space-y-4">
            {uploadData.length > 0 && (
              <>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    {validationErrors.filter(e => e.severity === 'error').length === 0 ? (
                      <CheckCircle className="w-4 h-4 text-green-500" />
                    ) : (
                      <AlertCircle className="w-4 h-4 text-destructive" />
                    )}
                    <span className="text-sm">
                      {uploadData.length} rows processed •{' '}
                      {validationErrors.filter(e => e.severity === 'error').length} errors •{' '}
                      {validationErrors.filter(e => e.severity === 'warning').length} warnings
                    </span>
                  </div>
                  <div className="flex gap-2">
                    <Button variant="outline" onClick={resetUpload}>
                      Reset
                    </Button>
                    {!uploadComplete && (
                      <Button 
                        onClick={handleImportData} 
                        disabled={validationErrors.some(e => e.severity === 'error') || isProcessing}
                      >
                        {isProcessing ? 'Importing...' : 'Import Data'}
                      </Button>
                    )}
                  </div>
                </div>

                {isProcessing && (
                  <div className="space-y-2">
                    <Progress value={uploadProgress} />
                    <p className="text-sm text-muted-foreground">Importing to database...</p>
                  </div>
                )}

                {uploadComplete && (
                  <Alert>
                    <CheckCircle className="h-4 w-4" />
                    <AlertDescription>
                      Import completed successfully! {uploadData.length} records added.
                    </AlertDescription>
                  </Alert>
                )}

                {validationErrors.length > 0 && (
                  <Alert variant={validationErrors.some(e => e.severity === 'error') ? "destructive" : "default"}>
                    <AlertCircle className="h-4 w-4" />
                    <AlertDescription>
                      <strong>Validation Results:</strong>
                      <ul className="mt-2 list-disc list-inside text-sm space-y-1">
                        {validationErrors.slice(0, 8).map((error, index) => (
                          <li key={index} className={error.severity === 'error' ? 'text-destructive' : 'text-yellow-600'}>
                            Row {error.row}, {error.field}: {error.message}
                          </li>
                        ))}
                        {validationErrors.length > 8 && (
                          <li>... and {validationErrors.length - 8} more issues</li>
                        )}
                      </ul>
                    </AlertDescription>
                  </Alert>
                )}

                <ScrollArea className="h-[400px] border rounded">
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>Row</TableHead>
                        <TableHead>Investor</TableHead>
                        <TableHead>Fund</TableHead>
                        <TableHead>Amount</TableHead>
                        <TableHead>Entities</TableHead>
                        <TableHead>Status</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {uploadData.slice(0, 100).map((row, index) => {
                        const status = getRowValidationStatus(index);
                        
                        return (
                          <TableRow 
                            key={index} 
                            className={
                              status === 'error' ? 'bg-destructive/10' : 
                              status === 'warning' ? 'bg-yellow-50' : ''
                            }
                          >
                            <TableCell>{index + 2}</TableCell>
                            <TableCell>
                              <div>
                                <div className="font-medium">{row.InvestorName}</div>
                                <div className="text-sm text-muted-foreground">{row.Fund}</div>
                              </div>
                            </TableCell>
                            <TableCell>{row.Fund}</TableCell>
                            <TableCell>
                              {new Intl.NumberFormat('en-US', { 
                                style: 'currency', 
                                currency: row.Currency || 'USD' 
                              }).format(row.ContributionAmount)}
                            </TableCell>
                            <TableCell>
                              <div className="space-y-1 text-sm">
                                {row.DistributorName && (
                                  <div className={entityValidation[`${index}-distributor`] ? 'text-green-600' : 'text-destructive'}>
                                    D: {row.DistributorName}
                                  </div>
                                )}
                                {row.ReferrerName && (
                                  <div className={entityValidation[`${index}-referrer`] ? 'text-green-600' : 'text-destructive'}>
                                    R: {row.ReferrerName}
                                  </div>
                                )}
                                {row.PartnerName && (
                                  <div className={entityValidation[`${index}-partner`] ? 'text-green-600' : 'text-destructive'}>
                                    P: {row.PartnerName}
                                  </div>
                                )}
                              </div>
                            </TableCell>
                            <TableCell>
                              <Badge variant={
                                status === 'error' ? 'destructive' : 
                                status === 'warning' ? 'secondary' : 'default'
                              }>
                                {status === 'error' ? 'Error' : status === 'warning' ? 'Warning' : 'Valid'}
                              </Badge>
                            </TableCell>
                          </TableRow>
                        );
                      })}
                    </TableBody>
                  </Table>
                </ScrollArea>
              </>
            )}
          </TabsContent>

          <TabsContent value="entities" className="space-y-4">
            <div className="grid gap-6">
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Users className="w-4 h-4" />
                    Entity Management Guide
                  </CardTitle>
                  <CardDescription>
                    Ensure your entities are properly configured before uploading
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div>
                    <h4 className="font-medium mb-2">Before Uploading:</h4>
                    <ol className="list-decimal list-inside space-y-1 text-sm text-muted-foreground">
                      <li>Go to Entity Management to add distributors, referrers, and partners</li>
                      <li>Ensure all entities referenced in your Excel file exist and are active</li>
                      <li>Use exact name matching (case-sensitive)</li>
                      <li>Set up commission rates and contact information</li>
                    </ol>
                  </div>
                  
                  <div>
                    <h4 className="font-medium mb-2">Excel Column Format:</h4>
                    <ul className="list-disc list-inside space-y-1 text-sm text-muted-foreground">
                      <li><strong>DistributorName:</strong> Exact name from Entity Management</li>
                      <li><strong>ReferrerName:</strong> Exact name from Entity Management</li>
                      <li><strong>PartnerName:</strong> Exact name from Entity Management</li>
                    </ul>
                  </div>

                  <Button 
                    variant="outline" 
                    onClick={() => window.open('/entities', '_blank')}
                    className="w-full"
                  >
                    <Users className="w-4 h-4 mr-2" />
                    Open Entity Management
                  </Button>
                </CardContent>
              </Card>
            </div>
          </TabsContent>
        </Tabs>
      </CardContent>
    </Card>
  );
}