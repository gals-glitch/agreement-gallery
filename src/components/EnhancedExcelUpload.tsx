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
import { Upload, FileSpreadsheet, CheckCircle, AlertCircle, X } from 'lucide-react';
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
  // Additional PRD fields
  DistributorName?: string;
  ReferrerName?: string;
  PartnerName?: string;
}

interface ValidationError {
  row: number;
  field: string;
  message: string;
}

interface Props {
  calculationRunId?: string;
  onUploadComplete?: (data: ContributionRow[]) => void;
  autoRunCalculation?: boolean;
  onAutoRunTriggered?: (runId: string) => void;
}

export function EnhancedExcelUpload({ 
  calculationRunId, 
  onUploadComplete, 
  autoRunCalculation = false,
  onAutoRunTriggered 
}: Props) {
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [uploadData, setUploadData] = useState<ContributionRow[]>([]);
  const [validationErrors, setValidationErrors] = useState<ValidationError[]>([]);
  const [isProcessing, setIsProcessing] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [uploadComplete, setUploadComplete] = useState(false);
  
  const { toast } = useToast();

  const requiredColumns = [
    'InvestorName',
    'Fund', 
    'ContributionDate',
    'ContributionAmount',
    'Currency'
  ];

  const validateRow = (row: ContributionRow, index: number): ValidationError[] => {
    const errors: ValidationError[] = [];

    // Required fields validation
    if (!row.InvestorName?.trim()) {
      errors.push({ row: index + 2, field: 'InvestorName', message: 'Investor name is required' });
    }
    
    if (!row.Fund?.trim()) {
      errors.push({ row: index + 2, field: 'Fund', message: 'Fund is required' });
    }

    if (!row.ContributionDate) {
      errors.push({ row: index + 2, field: 'ContributionDate', message: 'Contribution date is required' });
    } else {
      // Validate date format
      const date = new Date(row.ContributionDate);
      if (isNaN(date.getTime())) {
        errors.push({ row: index + 2, field: 'ContributionDate', message: 'Invalid date format (use YYYY-MM-DD)' });
      }
    }

    if (!row.ContributionAmount || row.ContributionAmount <= 0) {
      errors.push({ row: index + 2, field: 'ContributionAmount', message: 'Contribution amount must be greater than 0' });
    }

    if (!row.Currency?.trim()) {
      errors.push({ row: index + 2, field: 'Currency', message: 'Currency is required' });
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
        setUploadComplete(false);
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
      
      // Convert to JSON with header row
      const jsonData = XLSX.utils.sheet_to_json(worksheet, { 
        header: 1,
        defval: ""
      }) as any[][];

      setUploadProgress(30);

      if (jsonData.length < 2) {
        throw new Error('Excel file must contain header row and at least one data row');
      }

      // Get headers and validate required columns
      const headers = jsonData[0] as string[];
      const missingColumns = requiredColumns.filter(col => !headers.includes(col));
      
      if (missingColumns.length > 0) {
        throw new Error(`Missing required columns: ${missingColumns.join(', ')}`);
      }

      setUploadProgress(50);

      // Convert to objects
      const rows: ContributionRow[] = jsonData.slice(1).map((row: any[]) => {
        const obj: any = {};
        headers.forEach((header, index) => {
          obj[header] = row[index];
        });
        return obj;
      }).filter(row => row.InvestorName); // Filter out empty rows

      setUploadProgress(70);

      // Validate each row
      const allErrors: ValidationError[] = [];
      rows.forEach((row, index) => {
        const rowErrors = validateRow(row, index);
        allErrors.push(...rowErrors);
      });

      setValidationErrors(allErrors);
      setUploadData(rows);
      setUploadProgress(100);

      if (allErrors.length === 0) {
        toast({
          title: "File Processed Successfully",
          description: `${rows.length} contribution records ready for import`
        });
      } else {
        toast({
          title: "Validation Errors Found",
          description: `${allErrors.length} errors found. Please review before importing.`,
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
    if (validationErrors.length > 0) {
      toast({
        title: "Cannot Import",
        description: "Please fix validation errors before importing",
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
      // Prepare data for database insertion
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

      // Insert in batches to avoid timeout
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
        description: `${uploadData.length} contribution records imported successfully`
      });

      onUploadComplete?.(uploadData);

      // Trigger auto-run if enabled
      if (autoRunCalculation && calculationRunId && onAutoRunTriggered) {
        setTimeout(() => {
          onAutoRunTriggered(calculationRunId);
        }, 1000); // Small delay to let the UI update
      }

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
    setUploadProgress(0);
    setUploadComplete(false);
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <FileSpreadsheet className="w-5 h-5" />
          Excel Contribution Import
        </CardTitle>
        <CardDescription>
          Upload contribution data from Excel file per PRD template
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        
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
                Required columns: {requiredColumns.join(', ')}
                <br />
                Optional columns: InvestorId, Deal, SourceFile, Notes, DistributorName, ReferrerName, PartnerName
                {autoRunCalculation && (
                  <>
                    <br />
                    <span className="text-green-600 font-medium">Auto-run enabled: Calculations will start automatically after import</span>
                  </>
                )}
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
              {isProcessing ? 'Processing...' : 'Process File'}
            </Button>
            
            {isProcessing && (
              <div className="space-y-2">
                <Progress value={uploadProgress} />
                <p className="text-sm text-muted-foreground">Processing Excel file...</p>
              </div>
            )}
          </div>
        )}

        {uploadData.length > 0 && (
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                {validationErrors.length === 0 ? (
                  <CheckCircle className="w-4 h-4 text-green-500" />
                ) : (
                  <AlertCircle className="w-4 h-4 text-destructive" />
                )}
                <span className="text-sm">
                  {uploadData.length} rows processed
                  {validationErrors.length > 0 && ` • ${validationErrors.length} errors`}
                </span>
              </div>
              <div className="flex gap-2">
                <Button variant="outline" onClick={resetUpload}>
                  Reset
                </Button>
                {!uploadComplete && (
                  <Button 
                    onClick={handleImportData} 
                    disabled={validationErrors.length > 0 || isProcessing}
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
                  Import completed successfully! {uploadData.length} contribution records added.
                </AlertDescription>
              </Alert>
            )}

            {validationErrors.length > 0 && (
              <Alert variant="destructive">
                <AlertCircle className="h-4 w-4" />
                <AlertDescription>
                  {validationErrors.length} validation errors found:
                  <ul className="mt-2 list-disc list-inside text-sm">
                    {validationErrors.slice(0, 5).map((error, index) => (
                      <li key={index}>
                        Row {error.row}, {error.field}: {error.message}
                      </li>
                    ))}
                    {validationErrors.length > 5 && (
                      <li>... and {validationErrors.length - 5} more errors</li>
                    )}
                  </ul>
                </AlertDescription>
              </Alert>
            )}

            <ScrollArea className="h-[300px] border rounded">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Row</TableHead>
                    <TableHead>Investor Name</TableHead>
                    <TableHead>Fund</TableHead>
                    <TableHead>Amount</TableHead>
                    <TableHead>Date</TableHead>
                    <TableHead>Currency</TableHead>
                    <TableHead>Status</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {uploadData.slice(0, 50).map((row, index) => {
                    const rowErrors = validationErrors.filter(e => e.row === index + 2);
                    const hasErrors = rowErrors.length > 0;
                    
                    return (
                      <TableRow key={index} className={hasErrors ? 'bg-destructive/10' : ''}>
                        <TableCell>{index + 2}</TableCell>
                        <TableCell>{row.InvestorName}</TableCell>
                        <TableCell>{row.Fund}</TableCell>
                        <TableCell>
                          {new Intl.NumberFormat('en-US', { 
                            style: 'currency', 
                            currency: row.Currency || 'USD' 
                          }).format(row.ContributionAmount)}
                        </TableCell>
                        <TableCell>{row.ContributionDate}</TableCell>
                        <TableCell>{row.Currency}</TableCell>
                        <TableCell>
                          {hasErrors ? (
                            <Badge variant="destructive">Error</Badge>
                          ) : (
                            <Badge variant="secondary">Valid</Badge>
                          )}
                        </TableCell>
                      </TableRow>
                    );
                  })}
                </TableBody>
              </Table>
            </ScrollArea>
          </div>
        )}
      </CardContent>
    </Card>
  );
}