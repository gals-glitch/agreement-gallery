import { useState, useRef } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Upload, FileSpreadsheet, CheckCircle, AlertCircle } from 'lucide-react';
import { Alert, AlertDescription } from '@/components/ui/alert';
import * as XLSX from 'xlsx';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from '@/hooks/use-toast';

interface DistributionData {
  investor_name: string;
  fund_name?: string;
  distribution_amount: number;
  distributor_name?: string;
  referrer_name?: string;
  partner_name?: string;
  distribution_date?: string;
}

interface ExcelDistributionUploadProps {
  calculationRunId: string;
  onUploadComplete: (distributions: DistributionData[]) => void;
}

export function ExcelDistributionUpload({ calculationRunId, onUploadComplete }: ExcelDistributionUploadProps) {
  const [uploading, setUploading] = useState(false);
  const [uploadStatus, setUploadStatus] = useState<'idle' | 'success' | 'error'>('idle');
  const [errorMessage, setErrorMessage] = useState('');
  const [previewData, setPreviewData] = useState<DistributionData[]>([]);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const { toast } = useToast();

  const expectedColumns = [
    'investor_name',
    'fund_name',
    'distribution_amount',
    'distributor_name',
    'referrer_name',
    'partner_name',
    'distribution_date'
  ];

  const handleFileUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    setUploading(true);
    setUploadStatus('idle');
    setErrorMessage('');

    try {
      const arrayBuffer = await file.arrayBuffer();
      const workbook = XLSX.read(arrayBuffer, { type: 'array' });
      const sheetName = workbook.SheetNames[0];
      const worksheet = workbook.Sheets[sheetName];
      const jsonData = XLSX.utils.sheet_to_json(worksheet, { header: 1 }) as any[][];

      if (jsonData.length < 2) {
        throw new Error('Excel file must contain at least a header row and one data row');
      }

      const headers = jsonData[0].map((header: string) => 
        header.toLowerCase().replace(/\s+/g, '_').replace(/[^a-z0-9_]/g, '')
      );
      
      // Validate required columns
      const requiredColumns = ['investor_name', 'distribution_amount'];
      const missingColumns = requiredColumns.filter(col => !headers.includes(col));
      
      if (missingColumns.length > 0) {
        throw new Error(`Missing required columns: ${missingColumns.join(', ')}`);
      }

      // Parse data rows
      const distributions: DistributionData[] = [];
      for (let i = 1; i < jsonData.length; i++) {
        const row = jsonData[i];
        if (!row || row.length === 0) continue;

        const distribution: any = {};
        headers.forEach((header: string, index: number) => {
          const value = row[index];
          if (header === 'distribution_amount') {
            distribution[header] = parseFloat(value) || 0;
          } else if (header === 'distribution_date') {
            distribution[header] = value ? new Date(value).toISOString().split('T')[0] : null;
          } else {
            distribution[header] = value || null;
          }
        });

        if (distribution.investor_name && distribution.distribution_amount > 0) {
          distributions.push(distribution);
        }
      }

      if (distributions.length === 0) {
        throw new Error('No valid distribution data found in the Excel file');
      }

      setPreviewData(distributions);
      
      // Save to database
      const { error } = await supabase
        .from('investor_distributions')
        .insert(distributions.map(dist => ({
          ...dist,
          calculation_run_id: calculationRunId
        })));

      if (error) {
        throw new Error(`Database error: ${error.message}`);
      }

      setUploadStatus('success');
      onUploadComplete(distributions);
      toast({
        title: "Upload Successful",
        description: `Successfully uploaded ${distributions.length} distribution records.`,
      });

    } catch (error) {
      console.error('Upload error:', error);
      setUploadStatus('error');
      setErrorMessage(error instanceof Error ? error.message : 'Failed to upload file');
      toast({
        title: "Upload Failed",
        description: error instanceof Error ? error.message : 'Failed to upload file',
        variant: "destructive",
      });
    } finally {
      setUploading(false);
    }
  };

  const resetUpload = () => {
    setUploadStatus('idle');
    setPreviewData([]);
    setErrorMessage('');
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <FileSpreadsheet className="h-5 w-5" />
          Upload Distribution Data
        </CardTitle>
        <CardDescription>
          Upload an Excel file containing investor distribution data. Required columns: investor_name, distribution_amount.
          Optional: fund_name, distributor_name, referrer_name, partner_name, distribution_date.
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        {uploadStatus === 'idle' && (
          <div className="space-y-4">
            <div>
              <Label htmlFor="excel-file">Excel File</Label>
              <Input
                ref={fileInputRef}
                id="excel-file"
                type="file"
                accept=".xlsx,.xls"
                onChange={handleFileUpload}
                disabled={uploading}
                className="mt-1"
              />
            </div>
            
            <div className="text-sm text-muted-foreground">
              <p className="font-medium mb-2">Expected Excel columns:</p>
              <ul className="list-disc list-inside space-y-1">
                <li><strong>investor_name</strong> (required) - Name of the investor</li>
                <li><strong>distribution_amount</strong> (required) - Distribution amount in numbers</li>
                <li>fund_name - Name of the fund</li>
                <li>distributor_name - Name of the distributor</li>
                <li>referrer_name - Name of the referrer</li>
                <li>partner_name - Name of the partner</li>
                <li>distribution_date - Date of distribution (YYYY-MM-DD)</li>
              </ul>
            </div>

            {uploading && (
              <div className="flex items-center gap-2">
                <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-primary"></div>
                <span>Processing Excel file...</span>
              </div>
            )}
          </div>
        )}

        {uploadStatus === 'success' && (
          <div className="space-y-4">
            <Alert>
              <CheckCircle className="h-4 w-4" />
              <AlertDescription>
                Successfully uploaded {previewData.length} distribution records.
              </AlertDescription>
            </Alert>
            
            <div className="max-h-48 overflow-y-auto border rounded-md p-3">
              <h4 className="font-medium mb-2">Preview of uploaded data:</h4>
              <div className="text-sm space-y-1">
                {previewData.slice(0, 5).map((dist, index) => (
                  <div key={index} className="border-b pb-1">
                    <span className="font-medium">{dist.investor_name}</span> - 
                    <span className="text-green-600 ml-1">${dist.distribution_amount.toLocaleString()}</span>
                    {dist.distributor_name && <span className="text-muted-foreground ml-2">via {dist.distributor_name}</span>}
                  </div>
                ))}
                {previewData.length > 5 && (
                  <div className="text-muted-foreground">... and {previewData.length - 5} more records</div>
                )}
              </div>
            </div>

            <Button onClick={resetUpload} variant="outline">
              Upload Another File
            </Button>
          </div>
        )}

        {uploadStatus === 'error' && (
          <div className="space-y-4">
            <Alert variant="destructive">
              <AlertCircle className="h-4 w-4" />
              <AlertDescription>{errorMessage}</AlertDescription>
            </Alert>
            
            <Button onClick={resetUpload} variant="outline">
              Try Again
            </Button>
          </div>
        )}
      </CardContent>
    </Card>
  );
}