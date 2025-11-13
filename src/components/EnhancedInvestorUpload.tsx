import React, { useState, useRef } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Progress } from "@/components/ui/progress";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Upload, Download, FileSpreadsheet, CheckCircle, XCircle, AlertTriangle } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { useToast } from "@/hooks/use-toast";
import * as XLSX from 'xlsx';

interface InvestorUploadData {
  name: string;
  email?: string;
  phone?: string;
  address?: string;
  tax_id?: string;
  country?: string;
  party_entity_name: string;
  investor_type: string;
  kyc_status: string;
  investment_capacity?: number;
  risk_profile?: string;
  notes?: string;
  status?: 'pending' | 'success' | 'error';
  error_message?: string;
}

interface ValidationError {
  row: number;
  field: string;
  message: string;
}

const EnhancedInvestorUpload = () => {
  const [uploadData, setUploadData] = useState<InvestorUploadData[]>([]);
  const [validationErrors, setValidationErrors] = useState<ValidationError[]>([]);
  const [isProcessing, setIsProcessing] = useState(false);
  const [progress, setProgress] = useState(0);
  const [partyEntities, setPartyEntities] = useState<{[key: string]: string}>({});
  const fileInputRef = useRef<HTMLInputElement>(null);
  const { toast } = useToast();

  React.useEffect(() => {
    fetchPartyEntities();
  }, []);

  const fetchPartyEntities = async () => {
    try {
      const { data, error } = await supabase
        .from('entities')
        .select('id, name')
        ;

      if (error) throw error;

      const entityMap = data?.reduce((acc, entity) => {
        acc[entity.name.toLowerCase()] = entity.id;
        return acc;
      }, {} as {[key: string]: string}) || {};

      setPartyEntities(entityMap);
    } catch (error) {
      console.error('Failed to fetch party entities:', error);
    }
  };

  const downloadTemplate = () => {
    const template = [
      {
        name: 'John Doe',
        email: 'john.doe@example.com',
        phone: '+1-555-0123',
        address: '123 Main St, City, State 12345',
        tax_id: 'TAX123456',
        country: 'USA',
        party_entity_name: 'ABC Distributor',
        investor_type: 'individual',
        kyc_status: 'pending',
        investment_capacity: 100000,
        risk_profile: 'moderate',
        notes: 'High-value client'
      }
    ];

    const ws = XLSX.utils.json_to_sheet(template);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'Investors Template');
    XLSX.writeFile(wb, 'investors_template.xlsx');
  };

  const handleFileUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (e) => {
      try {
        const data = new Uint8Array(e.target?.result as ArrayBuffer);
        const workbook = XLSX.read(data, { type: 'array' });
        const sheetName = workbook.SheetNames[0];
        const worksheet = workbook.Sheets[sheetName];
        const jsonData = XLSX.utils.sheet_to_json(worksheet) as any[];

        const formattedData: InvestorUploadData[] = jsonData.map((row, index) => ({
          name: row.name || '',
          email: row.email || '',
          phone: row.phone || '',
          address: row.address || '',
          tax_id: row.tax_id || '',
          country: row.country || '',
          party_entity_name: row.party_entity_name || '',
          investor_type: row.investor_type || 'individual',
          kyc_status: row.kyc_status || 'pending',
          investment_capacity: row.investment_capacity ? Number(row.investment_capacity) : undefined,
          risk_profile: row.risk_profile || '',
          notes: row.notes || '',
          status: 'pending'
        }));

        setUploadData(formattedData);
        validateData(formattedData);
        
        toast({
          title: "File Uploaded",
          description: `Loaded ${formattedData.length} investor records`,
        });
      } catch (error) {
        toast({
          title: "Upload Error",
          description: "Failed to process the uploaded file",
          variant: "destructive",
        });
      }
    };
    reader.readAsArrayBuffer(file);
  };

  const validateData = (data: InvestorUploadData[]) => {
    const errors: ValidationError[] = [];

    data.forEach((row, index) => {
      // Validate required fields
      if (!row.name?.trim()) {
        errors.push({ row: index + 1, field: 'name', message: 'Name is required' });
      }

      if (!row.party_entity_name?.trim()) {
        errors.push({ row: index + 1, field: 'party_entity_name', message: 'Party entity name is required' });
      } else {
        // Check if party entity exists
        const entityId = partyEntities[row.party_entity_name.toLowerCase()];
        if (!entityId) {
          errors.push({ row: index + 1, field: 'party_entity_name', message: 'Party entity not found in database' });
        }
      }

      // Validate email format
      if (row.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(row.email)) {
        errors.push({ row: index + 1, field: 'email', message: 'Invalid email format' });
      }

      // Validate investor type
      if (!['individual', 'institutional', 'corporate'].includes(row.investor_type)) {
        errors.push({ row: index + 1, field: 'investor_type', message: 'Invalid investor type' });
      }

      // Validate KYC status
      if (!['pending', 'approved', 'rejected'].includes(row.kyc_status)) {
        errors.push({ row: index + 1, field: 'kyc_status', message: 'Invalid KYC status' });
      }

      // Validate investment capacity
      if (row.investment_capacity && (isNaN(row.investment_capacity) || row.investment_capacity < 0)) {
        errors.push({ row: index + 1, field: 'investment_capacity', message: 'Investment capacity must be a positive number' });
      }
    });

    setValidationErrors(errors);
  };

  const processUpload = async () => {
    if (validationErrors.length > 0) {
      toast({
        title: "Validation Errors",
        description: "Please fix all validation errors before proceeding",
        variant: "destructive",
      });
      return;
    }

    setIsProcessing(true);
    setProgress(0);

    const updatedData = [...uploadData];
    let successCount = 0;
    let errorCount = 0;

    for (let i = 0; i < updatedData.length; i++) {
      try {
        const row = updatedData[i];
        const entityId = partyEntities[row.party_entity_name.toLowerCase()];

        if (!entityId) {
          throw new Error('Party entity not found');
        }

        const investorData = {
          name: row.name,
          email: row.email || null,
          phone: row.phone || null,
          address: row.address || null,
          tax_id: row.tax_id || null,
          country: row.country || null,
          party_entity_id: entityId,
          investor_type: row.investor_type,
          kyc_status: row.kyc_status,
          investment_capacity: row.investment_capacity || null,
          risk_profile: row.risk_profile || null,
          notes: row.notes || null,
          is_active: true
        };

        const { error } = await supabase
          .from('investors')
          .insert([investorData]);

        if (error) throw error;

        updatedData[i].status = 'success';
        successCount++;
      } catch (error) {
        updatedData[i].status = 'error';
        updatedData[i].error_message = error instanceof Error ? error.message : 'Unknown error';
        errorCount++;
      }

      setProgress(((i + 1) / updatedData.length) * 100);
      setUploadData([...updatedData]);
    }

    setIsProcessing(false);
    toast({
      title: "Upload Complete",
      description: `${successCount} investors created successfully, ${errorCount} errors`,
      variant: errorCount > 0 ? "destructive" : "default",
    });
  };

  const getStatusIcon = (status?: string) => {
    switch (status) {
      case 'success': return <CheckCircle className="h-4 w-4 text-green-500" />;
      case 'error': return <XCircle className="h-4 w-4 text-red-500" />;
      default: return <AlertTriangle className="h-4 w-4 text-yellow-500" />;
    }
  };

  const getStatusBadge = (status?: string) => {
    switch (status) {
      case 'success': return <Badge variant="default" className="bg-green-100 text-green-700">Success</Badge>;
      case 'error': return <Badge variant="destructive">Error</Badge>;
      default: return <Badge variant="secondary">Pending</Badge>;
    }
  };

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <FileSpreadsheet className="h-5 w-5" />
            Enhanced Investor Upload
          </CardTitle>
          <CardDescription>
            Upload investor data with party entity relationships from Excel files
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex gap-4">
            <div className="flex-1">
              <Label htmlFor="file">Upload Excel File</Label>
              <Input
                id="file"
                type="file"
                ref={fileInputRef}
                onChange={handleFileUpload}
                accept=".xlsx,.xls"
                className="mt-1"
              />
            </div>
            <div className="flex items-end gap-2">
              <Button variant="outline" onClick={downloadTemplate}>
                <Download className="mr-2 h-4 w-4" />
                Download Template
              </Button>
              <Button onClick={() => fileInputRef.current?.click()}>
                <Upload className="mr-2 h-4 w-4" />
                Upload File
              </Button>
            </div>
          </div>

          {validationErrors.length > 0 && (
            <Alert variant="destructive">
              <AlertTriangle className="h-4 w-4" />
              <AlertDescription>
                Found {validationErrors.length} validation errors. Please review and fix before processing.
              </AlertDescription>
            </Alert>
          )}

          {uploadData.length > 0 && (
            <div className="space-y-4">
              <div className="flex justify-between items-center">
                <div>
                  <p className="text-sm text-muted-foreground">
                    {uploadData.length} investors loaded
                  </p>
                  {validationErrors.length > 0 && (
                    <p className="text-sm text-red-600">
                      {validationErrors.length} validation errors found
                    </p>
                  )}
                </div>
                <Button 
                  onClick={processUpload} 
                  disabled={isProcessing || validationErrors.length > 0}
                >
                  {isProcessing ? 'Processing...' : 'Process Upload'}
                </Button>
              </div>

              {isProcessing && (
                <div className="space-y-2">
                  <Progress value={progress} className="w-full" />
                  <p className="text-sm text-muted-foreground">
                    Processing investors... {Math.round(progress)}%
                  </p>
                </div>
              )}
            </div>
          )}
        </CardContent>
      </Card>

      {validationErrors.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-red-600">Validation Errors</CardTitle>
          </CardHeader>
          <CardContent>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Row</TableHead>
                  <TableHead>Field</TableHead>
                  <TableHead>Error</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {validationErrors.map((error, index) => (
                  <TableRow key={index}>
                    <TableCell>{error.row}</TableCell>
                    <TableCell>{error.field}</TableCell>
                    <TableCell>{error.message}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      )}

      {uploadData.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Upload Preview</CardTitle>
            <CardDescription>
              Review the investor data before processing
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Status</TableHead>
                  <TableHead>Name</TableHead>
                  <TableHead>Party Entity</TableHead>
                  <TableHead>Type</TableHead>
                  <TableHead>KYC Status</TableHead>
                  <TableHead>Investment Capacity</TableHead>
                  <TableHead>Error</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {uploadData.map((investor, index) => (
                  <TableRow key={index}>
                    <TableCell>
                      <div className="flex items-center gap-2">
                        {getStatusIcon(investor.status)}
                        {getStatusBadge(investor.status)}
                      </div>
                    </TableCell>
                    <TableCell>{investor.name}</TableCell>
                    <TableCell>{investor.party_entity_name}</TableCell>
                    <TableCell>{investor.investor_type}</TableCell>
                    <TableCell>{investor.kyc_status}</TableCell>
                    <TableCell>
                      {investor.investment_capacity ? `$${investor.investment_capacity.toLocaleString()}` : '-'}
                    </TableCell>
                    <TableCell className="text-red-600 text-sm">
                      {investor.error_message}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      )}
    </div>
  );
};

export default EnhancedInvestorUpload;