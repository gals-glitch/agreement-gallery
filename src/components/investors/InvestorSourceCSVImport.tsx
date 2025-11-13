/**
 * Investor Source CSV Import Component
 * Backfill tool for bulk updating investor source attribution
 * Ticket: FE-103
 * Date: 2025-10-19
 */

import { useState } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { ScrollArea } from '@/components/ui/scroll-area';
import { supabase } from '@/integrations/supabase/client';
import {
  InvestorSourceImportRow,
  InvestorSourceImportResponse,
  InvestorSourceImportPreviewRow,
} from '@/types/investors';
import { AlertCircle, CheckCircle2, Upload, FileDown, AlertTriangle } from 'lucide-react';
import Papa from 'papaparse';

interface InvestorSourceCSVImportProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

const importInvestorSources = async (rows: InvestorSourceImportRow[]) => {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) throw new Error('Not authenticated');

  const response = await fetch(
    `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/api-v1/investors/source-import`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${session.access_token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(rows),
    }
  );

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.message || 'Failed to import sources');
  }

  return response.json() as Promise<InvestorSourceImportResponse>;
};

export function InvestorSourceCSVImport({ open, onOpenChange }: InvestorSourceCSVImportProps) {
  const [csvFile, setCsvFile] = useState<File | null>(null);
  const [previewData, setPreviewData] = useState<InvestorSourceImportPreviewRow[]>([]);
  const [importResult, setImportResult] = useState<InvestorSourceImportResponse | null>(null);
  const [step, setStep] = useState<'upload' | 'preview' | 'importing' | 'complete'>('upload');

  const queryClient = useQueryClient();

  const { mutate: runImport, isPending: isImporting } = useMutation({
    mutationFn: importInvestorSources,
    onSuccess: (result) => {
      setImportResult(result);
      setStep('complete');
      queryClient.invalidateQueries({ queryKey: ['investors'] });
    },
  });

  const handleFileChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      setCsvFile(file);
      parseCSV(file);
    }
  };

  const parseCSV = (file: File) => {
    Papa.parse(file, {
      header: true,
      skipEmptyLines: true,
      complete: (results) => {
        const rows = results.data as any[];

        // Map and validate rows
        const preview: InvestorSourceImportPreviewRow[] = rows.map((row, index) => {
          const previewRow: InvestorSourceImportPreviewRow = {
            investor_external_id: row.investor_external_id || '',
            source_kind: row.source_kind || '',
            party_name: row.party_name || undefined,
            status: 'valid',
          };

          // Validate required fields
          if (!previewRow.investor_external_id) {
            previewRow.status = 'error';
            previewRow.error_message = 'Missing investor_external_id';
          } else if (!previewRow.source_kind) {
            previewRow.status = 'error';
            previewRow.error_message = 'Missing source_kind';
          } else if (!['DISTRIBUTOR', 'REFERRER', 'NONE'].includes(previewRow.source_kind as any)) {
            previewRow.status = 'error';
            previewRow.error_message = 'Invalid source_kind (must be DISTRIBUTOR, REFERRER, or NONE)';
          } else if (
            (previewRow.source_kind === 'DISTRIBUTOR' || previewRow.source_kind === 'REFERRER') &&
            !previewRow.party_name
          ) {
            previewRow.status = 'warning';
            previewRow.error_message = 'Party name recommended for distributor/referrer';
          }

          return previewRow;
        });

        setPreviewData(preview);
        setStep('preview');
      },
      error: (error) => {
        console.error('CSV parse error:', error);
        alert('Failed to parse CSV file. Please check the format.');
      },
    });
  };

  const handleImport = () => {
    // Only import valid rows
    const validRows = previewData.filter((row) => row.status !== 'error');
    const importRows: InvestorSourceImportRow[] = validRows.map((row) => ({
      investor_external_id: row.investor_external_id,
      source_kind: row.source_kind as any,
      party_name: row.party_name,
    }));

    setStep('importing');
    runImport(importRows);
  };

  const handleClose = () => {
    setCsvFile(null);
    setPreviewData([]);
    setImportResult(null);
    setStep('upload');
    onOpenChange(false);
  };

  const validCount = previewData.filter((r) => r.status === 'valid').length;
  const warningCount = previewData.filter((r) => r.status === 'warning').length;
  const errorCount = previewData.filter((r) => r.status === 'error').length;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-4xl max-h-[90vh] overflow-hidden flex flex-col">
        <DialogHeader>
          <DialogTitle>Import Investor Source Data (CSV)</DialogTitle>
          <DialogDescription>
            Bulk update investor source attribution from a CSV file
          </DialogDescription>
        </DialogHeader>

        <div className="flex-1 overflow-y-auto space-y-4">
          {/* Step: Upload */}
          {step === 'upload' && (
            <div className="space-y-4">
              <Alert>
                <FileDown className="h-4 w-4" />
                <AlertTitle>CSV Format</AlertTitle>
                <AlertDescription>
                  <p className="mb-2">Your CSV file should have these columns:</p>
                  <code className="block bg-muted p-2 rounded text-sm">
                    investor_external_id,source_kind,party_name
                  </code>
                  <ul className="mt-2 list-disc list-inside text-sm space-y-1">
                    <li><strong>investor_external_id:</strong> Investor name (required)</li>
                    <li><strong>source_kind:</strong> DISTRIBUTOR, REFERRER, or NONE (required)</li>
                    <li><strong>party_name:</strong> Party name who introduced the investor (optional)</li>
                  </ul>
                </AlertDescription>
              </Alert>

              <div className="space-y-2">
                <Label htmlFor="csv-file">Select CSV File</Label>
                <Input
                  id="csv-file"
                  type="file"
                  accept=".csv"
                  onChange={handleFileChange}
                />
              </div>
            </div>
          )}

          {/* Step: Preview */}
          {step === 'preview' && (
            <div className="space-y-4">
              <Alert>
                <AlertCircle className="h-4 w-4" />
                <AlertTitle>Preview & Validation</AlertTitle>
                <AlertDescription>
                  <div className="flex gap-4 mt-2">
                    <Badge variant="default" className="bg-green-100 text-green-800">
                      <CheckCircle2 className="h-3 w-3 mr-1" />
                      {validCount} Valid
                    </Badge>
                    <Badge variant="secondary" className="bg-yellow-100 text-yellow-800">
                      <AlertTriangle className="h-3 w-3 mr-1" />
                      {warningCount} Warnings
                    </Badge>
                    <Badge variant="destructive">
                      <AlertCircle className="h-3 w-3 mr-1" />
                      {errorCount} Errors
                    </Badge>
                  </div>
                </AlertDescription>
              </Alert>

              <ScrollArea className="h-96 rounded-md border">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead className="w-12">Row</TableHead>
                      <TableHead>Status</TableHead>
                      <TableHead>Investor ID</TableHead>
                      <TableHead>Source Kind</TableHead>
                      <TableHead>Party Name</TableHead>
                      <TableHead>Message</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {previewData.map((row, index) => (
                      <TableRow key={index}>
                        <TableCell>{index + 1}</TableCell>
                        <TableCell>
                          {row.status === 'valid' && (
                            <Badge variant="default" className="bg-green-100 text-green-800">
                              Valid
                            </Badge>
                          )}
                          {row.status === 'warning' && (
                            <Badge variant="secondary" className="bg-yellow-100 text-yellow-800">
                              Warning
                            </Badge>
                          )}
                          {row.status === 'error' && (
                            <Badge variant="destructive">Error</Badge>
                          )}
                        </TableCell>
                        <TableCell className="font-mono text-sm">
                          {row.investor_external_id}
                        </TableCell>
                        <TableCell>{row.source_kind}</TableCell>
                        <TableCell>{row.party_name || '—'}</TableCell>
                        <TableCell className="text-sm text-muted-foreground">
                          {row.error_message || '—'}
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </ScrollArea>
            </div>
          )}

          {/* Step: Importing */}
          {step === 'importing' && (
            <div className="space-y-4 py-8">
              <div className="text-center">
                <Upload className="h-12 w-12 mx-auto mb-4 animate-pulse text-blue-500" />
                <h3 className="text-lg font-medium">Importing...</h3>
                <p className="text-sm text-muted-foreground">
                  Updating investor source data
                </p>
              </div>
              <Progress value={undefined} className="w-full" />
            </div>
          )}

          {/* Step: Complete */}
          {step === 'complete' && importResult && (
            <div className="space-y-4">
              <Alert className="bg-green-50 border-green-200">
                <CheckCircle2 className="h-4 w-4 text-green-600" />
                <AlertTitle className="text-green-800">Import Complete</AlertTitle>
                <AlertDescription className="text-green-700">
                  Successfully updated {importResult.success_count} investor(s)
                  {importResult.errors.length > 0 &&
                    ` with ${importResult.errors.length} error(s)`}
                </AlertDescription>
              </Alert>

              {importResult.errors.length > 0 && (
                <div className="space-y-2">
                  <h4 className="font-medium text-sm">Errors:</h4>
                  <ScrollArea className="h-48 rounded-md border p-4">
                    {importResult.errors.map((error, index) => (
                      <div key={index} className="text-sm text-red-600 mb-2">
                        Row {error.row}: {error.message}
                        {error.field && ` (Field: ${error.field})`}
                      </div>
                    ))}
                  </ScrollArea>
                </div>
              )}
            </div>
          )}
        </div>

        <DialogFooter>
          {step === 'upload' && (
            <Button variant="outline" onClick={handleClose}>
              Cancel
            </Button>
          )}
          {step === 'preview' && (
            <>
              <Button
                variant="outline"
                onClick={() => {
                  setCsvFile(null);
                  setPreviewData([]);
                  setStep('upload');
                }}
              >
                Back
              </Button>
              <Button
                onClick={handleImport}
                disabled={validCount === 0}
              >
                Import {validCount} Valid Row{validCount !== 1 ? 's' : ''}
              </Button>
            </>
          )}
          {step === 'complete' && (
            <Button onClick={handleClose}>Close</Button>
          )}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
