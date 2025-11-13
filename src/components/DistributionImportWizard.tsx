import React, { useState, useCallback, useMemo } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Progress } from '@/components/ui/progress';
import { Upload, FileSpreadsheet, CheckCircle, AlertCircle, X, ArrowRight, ArrowLeft, Plus, Search } from 'lucide-react';
import * as XLSX from 'xlsx';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from '@/hooks/use-toast';

// Levenshtein distance for fuzzy matching
function levenshtein(a: string, b: string): number {
  const matrix: number[][] = [];
  for (let i = 0; i <= b.length; i++) matrix[i] = [i];
  for (let j = 0; j <= a.length; j++) matrix[0][j] = j;
  for (let i = 1; i <= b.length; i++) {
    for (let j = 1; j <= a.length; j++) {
      matrix[i][j] = b.charAt(i - 1) === a.charAt(j - 1)
        ? matrix[i - 1][j - 1]
        : Math.min(matrix[i - 1][j - 1] + 1, matrix[i][j - 1] + 1, matrix[i - 1][j] + 1);
    }
  }
  return matrix[b.length][a.length];
}

// Normalize for matching
const normalize = (s: string) => s.trim().replace(/\s+/g, ' ').toUpperCase();

interface Deal {
  id: string;
  code: string;
  name: string;
  fund_id: string;
}

interface Fund {
  id: string;
  name: string;
}

interface Investor {
  id: string;
  name: string;
}

interface ParsedRow {
  rowNumber: number;
  investor_id?: string;
  investor_name?: string;
  fund_id?: string;
  fund_name?: string;
  deal_code?: string;
  deal_name?: string;
  distribution_amount: number;
  distribution_date: string;
  rawData: Record<string, any>;
}

interface ValidationStatus {
  status: 'ok' | 'warning' | 'error';
  messages: string[];
  resolvedInvestorId?: string;
  resolvedFundId?: string;
  resolvedDealId?: string;
}

interface DealMapping {
  csvValue: string;
  matched?: Deal;
  suggestions: Deal[];
  selectedDealId?: string;
  createNew?: { name: string; code: string; fund_id: string };
}

interface Props {
  calculationRunId?: string;
  onUploadComplete?: () => void;
}

export function DistributionImportWizard({ calculationRunId, onUploadComplete }: Props) {
  const [step, setStep] = useState<'upload' | 'map' | 'deal-mapping' | 'preview' | 'complete'>('upload');
  const [file, setFile] = useState<File | null>(null);
  const [headers, setHeaders] = useState<string[]>([]);
  const [rows, setRows] = useState<any[]>([]);
  const [columnMapping, setColumnMapping] = useState<Record<string, string>>({});
  const [parsedRows, setParsedRows] = useState<ParsedRow[]>([]);
  const [dealMappings, setDealMappings] = useState<Record<string, DealMapping>>({});
  const [validationResults, setValidationResults] = useState<Record<number, ValidationStatus>>({});
  const [isProcessing, setIsProcessing] = useState(false);
  const [progress, setProgress] = useState(0);
  
  const [deals, setDeals] = useState<Deal[]>([]);
  const [funds, setFunds] = useState<Fund[]>([]);
  const [investors, setInvestors] = useState<Investor[]>([]);
  
  const { toast } = useToast();

  // Fetch reference data
  React.useEffect(() => {
    fetchReferenceData();
  }, []);

  const fetchReferenceData = async () => {
    try {
      const [dealsRes, fundsRes, investorsRes] = await Promise.all([
        supabase.from('deals').select('id, code, name, fund_id'),
        supabase.from('funds').select('id, name'),
        supabase.from('investors').select('id, name')
      ]);

      if (dealsRes.data) setDeals(dealsRes.data as Deal[]);
      if (fundsRes.data) setFunds(fundsRes.data as Fund[]);
      if (investorsRes.data) setInvestors(investorsRes.data as Investor[]);
    } catch (error) {
      console.error('Failed to fetch reference data:', error);
    }
  };

  // Step 1: Upload
  const handleFileSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
    const selectedFile = event.target.files?.[0];
    if (!selectedFile) return;
    
    const validTypes = ['application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'application/vnd.ms-excel'];
    if (!validTypes.includes(selectedFile.type)) {
      toast({ title: "Invalid file", description: "Please upload an Excel file", variant: "destructive" });
      return;
    }
    
    setFile(selectedFile);
    parseFile(selectedFile);
  };

  const parseFile = async (file: File) => {
    setIsProcessing(true);
    setProgress(10);
    
    try {
      const data = await file.arrayBuffer();
      const workbook = XLSX.read(data);
      const sheet = workbook.Sheets[workbook.SheetNames[0]];
      const jsonData = XLSX.utils.sheet_to_json(sheet, { header: 1, defval: '' }) as any[][];
      
      if (jsonData.length < 2) throw new Error('File must have headers and data');
      
      const parsedHeaders = jsonData[0].map((h: any) => String(h).trim());
      const parsedRows = jsonData.slice(1).filter(row => row.some(cell => cell !== ''));
      
      setHeaders(parsedHeaders);
      setRows(parsedRows);
      setProgress(100);
      
      // Auto-detect mappings
      autoDetectMappings(parsedHeaders);
      
      toast({ title: "File parsed", description: `${parsedRows.length} rows found` });
      setStep('map');
    } catch (error) {
      toast({ title: "Parse error", description: String(error), variant: "destructive" });
    } finally {
      setIsProcessing(false);
    }
  };

  // Step 2: Map columns
  const autoDetectMappings = (headers: string[]) => {
    const mappings: Record<string, string> = {};
    const variants: Record<string, string[]> = {
      investor_id: ['investor_id', 'investor id', 'investorid'],
      investor_name: ['investor_name', 'investor name', 'investor', 'client'],
      fund_id: ['fund_id', 'fund id', 'fundid'],
      fund_name: ['fund_name', 'fund name', 'fund'],
      deal_code: ['deal_code', 'deal code', 'deal', 'deal id', 'dealcode'],
      deal_name: ['deal_name', 'deal name'],
      distribution_amount: ['distribution_amount', 'amount', 'distribution', 'value'],
      distribution_date: ['distribution_date', 'date', 'dist_date']
    };
    
    headers.forEach(header => {
      const norm = normalize(header);
      for (const [field, vars] of Object.entries(variants)) {
        if (vars.some(v => normalize(v) === norm)) {
          mappings[header] = field;
          break;
        }
      }
    });
    
    setColumnMapping(mappings);
  };

  const handleMappingChange = (header: string, field: string) => {
    setColumnMapping(prev => ({ ...prev, [header]: field }));
  };

  const canProceedToDeals = useMemo(() => {
    const mapped = Object.values(columnMapping);
    const hasInvestor = mapped.includes('investor_id') || mapped.includes('investor_name');
    const hasFund = mapped.includes('fund_id') || mapped.includes('fund_name');
    const hasAmount = mapped.includes('distribution_amount');
    const hasDate = mapped.includes('distribution_date');
    return hasInvestor && hasFund && hasAmount && hasDate;
  }, [columnMapping]);

  const proceedToDeals = () => {
    // Parse rows with mappings
    const parsed: ParsedRow[] = rows.map((row, idx) => {
      const rowData: ParsedRow = { rowNumber: idx + 2, distribution_amount: 0, distribution_date: '', rawData: {} };
      
      headers.forEach((header, colIdx) => {
        const field = columnMapping[header];
        const value = row[colIdx];
        if (field) {
          (rowData as any)[field] = value;
        }
        rowData.rawData[header] = value;
      });
      
      return rowData;
    });
    
    setParsedRows(parsed);
    
    // Extract distinct deal values
    const distinctDeals = new Set<string>();
    parsed.forEach(row => {
      if (row.deal_code) distinctDeals.add(String(row.deal_code).trim());
      else if (row.deal_name) distinctDeals.add(String(row.deal_name).trim());
    });
    
    if (distinctDeals.size === 0) {
      // No deals, skip to preview
      setStep('preview');
      validateRows(parsed, {});
    } else {
      // Match deals
      const mappings: Record<string, DealMapping> = {};
      distinctDeals.forEach(val => {
        const exact = exactMatch(val, deals);
        const suggestions = exact ? [] : fuzzyMatch(val, deals);
        mappings[val] = { csvValue: val, matched: exact, suggestions };
      });
      setDealMappings(mappings);
      setStep('deal-mapping');
    }
  };

  // Deal matching
  const exactMatch = (input: string, allDeals: Deal[]): Deal | undefined => {
    const n = normalize(input);
    return allDeals.find(d => normalize(d.code) === n || normalize(d.name) === n);
  };

  const fuzzyMatch = (input: string, allDeals: Deal[]): Deal[] => {
    const n = normalize(input);
    return allDeals
      .map(d => ({ deal: d, score: Math.min(levenshtein(n, normalize(d.code)), levenshtein(n, normalize(d.name))) }))
      .filter(x => x.score <= 2)
      .sort((a, b) => a.score - b.score)
      .slice(0, 5)
      .map(x => x.deal);
  };

  const handleDealSelect = (csvValue: string, dealId: string) => {
    setDealMappings(prev => ({
      ...prev,
      [csvValue]: { ...prev[csvValue], selectedDealId: dealId, createNew: undefined }
    }));
  };

  const handleCreateDeal = (csvValue: string) => {
    // Open dialog - for now, set placeholder
    const newCode = csvValue.toUpperCase().replace(/\s+/g, '-');
    setDealMappings(prev => ({
      ...prev,
      [csvValue]: {
        ...prev[csvValue],
        createNew: { name: csvValue, code: newCode, fund_id: funds[0]?.id || '' },
        selectedDealId: undefined
      }
    }));
  };

  const canProceedToPreview = useMemo(() => {
    return Object.values(dealMappings).every(m => m.matched || m.selectedDealId || m.createNew);
  }, [dealMappings]);

  const proceedToPreview = () => {
    validateRows(parsedRows, dealMappings);
    setStep('preview');
  };

  // Validation
  const validateRows = (rows: ParsedRow[], dealMaps: Record<string, DealMapping>) => {
    const results: Record<number, ValidationStatus> = {};
    
    rows.forEach(row => {
      const messages: string[] = [];
      let status: 'ok' | 'warning' | 'error' = 'ok';
      
      // Resolve investor
      let resolvedInvestorId = row.investor_id;
      if (!resolvedInvestorId && row.investor_name) {
        const inv = investors.find(i => normalize(i.name) === normalize(row.investor_name!));
        if (inv) resolvedInvestorId = inv.id;
        else {
          messages.push('Investor name not found');
          status = 'error';
        }
      }
      
      // Resolve fund
      let resolvedFundId = row.fund_id;
      if (!resolvedFundId && row.fund_name) {
        const fund = funds.find(f => normalize(f.name) === normalize(row.fund_name!));
        if (fund) resolvedFundId = fund.id;
        else {
          messages.push('Fund name not found');
          status = 'error';
        }
      }
      
      // Resolve deal
      let resolvedDealId: string | undefined;
      const dealValue = row.deal_code || row.deal_name;
      if (dealValue) {
        const mapping = dealMaps[dealValue];
        if (mapping?.matched) resolvedDealId = mapping.matched.id;
        else if (mapping?.selectedDealId) resolvedDealId = mapping.selectedDealId;
        else if (mapping?.createNew) resolvedDealId = 'NEW';
        
        // Check fund mismatch
        if (resolvedDealId && resolvedDealId !== 'NEW' && resolvedFundId) {
          const deal = deals.find(d => d.id === resolvedDealId);
          if (deal && deal.fund_id !== resolvedFundId) {
            messages.push('Deal fund mismatch');
            status = 'error';
          }
        }
      }
      
      // Validate amount
      if (!row.distribution_amount || row.distribution_amount <= 0) {
        messages.push('Invalid amount');
        status = 'error';
      }
      
      // Validate date
      const dateVal = new Date(row.distribution_date);
      if (isNaN(dateVal.getTime())) {
        messages.push('Invalid date');
        status = 'error';
      }
      
      results[row.rowNumber] = {
        status: messages.length === 0 ? 'ok' : status,
        messages,
        resolvedInvestorId,
        resolvedFundId,
        resolvedDealId
      };
    });
    
    setValidationResults(results);
  };

  // Commit
  const handleCommit = async () => {
    setIsProcessing(true);
    setProgress(0);
    
    try {
      // Create new deals first
      const newDeals = Object.values(dealMappings).filter(m => m.createNew);
      const createdDealIds: Record<string, string> = {};
      
      for (const dealMap of newDeals) {
        if (!dealMap.createNew) continue;
        const { data, error } = await supabase.from('deals').insert({
          name: dealMap.createNew.name,
          code: dealMap.createNew.code,
          fund_id: dealMap.createNew.fund_id
        }).select().single();
        
        if (error) throw error;
        if (data) createdDealIds[dealMap.csvValue] = data.id;
      }
      
      setProgress(30);
      
      // Insert distributions
      const okRows = parsedRows.filter(r => validationResults[r.rowNumber]?.status === 'ok');
      const insertData = okRows.map(row => {
        const val = validationResults[row.rowNumber];
        const dealValue = row.deal_code || row.deal_name;
        let dealId = val.resolvedDealId;
        if (dealId === 'NEW' && dealValue) dealId = createdDealIds[dealValue];
        
        return {
          calculation_run_id: calculationRunId,
          investor_id: val.resolvedInvestorId,
          investor_name: row.investor_name || '',
          fund_name: row.fund_name || '',
          deal_id: dealId,
          distribution_amount: row.distribution_amount,
          distribution_date: row.distribution_date
        };
      });
      
      const batchSize = 100;
      for (let i = 0; i < insertData.length; i += batchSize) {
        const batch = insertData.slice(i, i + batchSize);
        const { error } = await supabase.from('investor_distributions').insert(batch);
        if (error) throw error;
        setProgress(30 + (70 * (i + batch.length)) / insertData.length);
      }
      
      toast({ title: "Import complete", description: `${okRows.length} distributions imported` });
      setStep('complete');
      onUploadComplete?.();
    } catch (error) {
      console.error(error);
      toast({ title: "Import failed", description: String(error), variant: "destructive" });
    } finally {
      setIsProcessing(false);
    }
  };

  const okCount = Object.values(validationResults).filter(v => v.status === 'ok').length;
  const errorCount = Object.values(validationResults).filter(v => v.status === 'error').length;

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <FileSpreadsheet className="w-5 h-5" />
          Distribution Import Wizard
        </CardTitle>
        <CardDescription>Step {step === 'upload' ? 1 : step === 'map' ? 2 : step === 'deal-mapping' ? 3 : step === 'preview' ? 4 : 5} of 5</CardDescription>
      </CardHeader>
      <CardContent>
        {step === 'upload' && (
          <div className="space-y-4">
            <div>
              <Label>Select CSV/Excel File</Label>
              <Input type="file" accept=".xlsx,.xls,.csv" onChange={handleFileSelect} />
            </div>
            <Alert>
              <AlertCircle className="h-4 w-4" />
              <AlertDescription>
                Required: investor (ID or name), fund (ID or name), amount, date<br />
                Optional: deal_code, deal_name
              </AlertDescription>
            </Alert>
            {isProcessing && <Progress value={progress} />}
          </div>
        )}

        {step === 'map' && (
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="font-semibold">Map Columns</h3>
              <div className="flex gap-2">
                <Button variant="outline" onClick={() => setStep('upload')}><ArrowLeft className="w-4 h-4 mr-2" />Back</Button>
                <Button onClick={proceedToDeals} disabled={!canProceedToDeals}>Next<ArrowRight className="w-4 h-4 ml-2" /></Button>
              </div>
            </div>
            <ScrollArea className="h-[400px]">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Excel Column</TableHead>
                    <TableHead>Maps To</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {headers.map(header => (
                    <TableRow key={header}>
                      <TableCell>{header}</TableCell>
                      <TableCell>
                        <Select value={columnMapping[header] || ''} onValueChange={v => handleMappingChange(header, v)}>
                          <SelectTrigger className="w-full">
                            <SelectValue placeholder="Not mapped" />
                          </SelectTrigger>
                          <SelectContent>
                            <SelectItem value="">Not mapped</SelectItem>
                            <SelectItem value="investor_id">Investor ID</SelectItem>
                            <SelectItem value="investor_name">Investor Name</SelectItem>
                            <SelectItem value="fund_id">Fund ID</SelectItem>
                            <SelectItem value="fund_name">Fund Name</SelectItem>
                            <SelectItem value="deal_code">Deal Code</SelectItem>
                            <SelectItem value="deal_name">Deal Name</SelectItem>
                            <SelectItem value="distribution_amount">Amount</SelectItem>
                            <SelectItem value="distribution_date">Date</SelectItem>
                          </SelectContent>
                        </Select>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </ScrollArea>
          </div>
        )}

        {step === 'deal-mapping' && (
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="font-semibold">Map Deals</h3>
              <div className="flex gap-2">
                <Button variant="outline" onClick={() => setStep('map')}><ArrowLeft className="w-4 h-4 mr-2" />Back</Button>
                <Button onClick={proceedToPreview} disabled={!canProceedToPreview}>Next<ArrowRight className="w-4 h-4 ml-2" /></Button>
              </div>
            </div>
            <ScrollArea className="h-[400px]">
              {Object.entries(dealMappings).map(([csvValue, mapping]) => (
                <Card key={csvValue} className="mb-4">
                  <CardHeader>
                    <CardTitle className="text-sm">CSV Value: {csvValue}</CardTitle>
                  </CardHeader>
                  <CardContent className="space-y-2">
                    {mapping.matched && (
                      <Alert>
                        <CheckCircle className="h-4 w-4" />
                        <AlertDescription>Exact match: {mapping.matched.code} - {mapping.matched.name}</AlertDescription>
                      </Alert>
                    )}
                    {!mapping.matched && mapping.suggestions.length > 0 && (
                      <div>
                        <Label>Suggestions:</Label>
                        <Select value={mapping.selectedDealId} onValueChange={v => handleDealSelect(csvValue, v)}>
                          <SelectTrigger><SelectValue placeholder="Select deal" /></SelectTrigger>
                          <SelectContent>
                            {mapping.suggestions.map(d => (
                              <SelectItem key={d.id} value={d.id}>{d.code} - {d.name}</SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                      </div>
                    )}
                    {!mapping.matched && mapping.suggestions.length === 0 && (
                      <Alert variant="destructive">
                        <AlertCircle className="h-4 w-4" />
                        <AlertDescription>No matches found</AlertDescription>
                      </Alert>
                    )}
                    <Button variant="outline" size="sm" onClick={() => handleCreateDeal(csvValue)}>
                      <Plus className="w-4 h-4 mr-2" />Create New Deal
                    </Button>
                    {mapping.createNew && (
                      <Alert>
                        <AlertDescription>Will create: {mapping.createNew.code}</AlertDescription>
                      </Alert>
                    )}
                  </CardContent>
                </Card>
              ))}
            </ScrollArea>
          </div>
        )}

        {step === 'preview' && (
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div className="flex gap-4">
                <Badge variant={okCount > 0 ? "default" : "secondary"}>{okCount} OK</Badge>
                <Badge variant={errorCount > 0 ? "destructive" : "secondary"}>{errorCount} Errors</Badge>
              </div>
              <div className="flex gap-2">
                <Button variant="outline" onClick={() => setStep(Object.keys(dealMappings).length > 0 ? 'deal-mapping' : 'map')}><ArrowLeft className="w-4 h-4 mr-2" />Back</Button>
                <Button onClick={handleCommit} disabled={okCount === 0 || isProcessing}>
                  {isProcessing ? 'Importing...' : `Import ${okCount} Rows`}
                </Button>
              </div>
            </div>
            {isProcessing && <Progress value={progress} />}
            <ScrollArea className="h-[400px]">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Row</TableHead>
                    <TableHead>Investor</TableHead>
                    <TableHead>Fund</TableHead>
                    <TableHead>Deal</TableHead>
                    <TableHead>Amount</TableHead>
                    <TableHead>Date</TableHead>
                    <TableHead>Status</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {parsedRows.slice(0, 100).map(row => {
                    const val = validationResults[row.rowNumber];
                    return (
                      <TableRow key={row.rowNumber}>
                        <TableCell>{row.rowNumber}</TableCell>
                        <TableCell>{row.investor_name}</TableCell>
                        <TableCell>{row.fund_name}</TableCell>
                        <TableCell>{row.deal_code || row.deal_name || '-'}</TableCell>
                        <TableCell>{row.distribution_amount}</TableCell>
                        <TableCell>{row.distribution_date}</TableCell>
                        <TableCell>
                          {val?.status === 'ok' && <Badge>OK</Badge>}
                          {val?.status === 'error' && <Badge variant="destructive">{val.messages.join(', ')}</Badge>}
                        </TableCell>
                      </TableRow>
                    );
                  })}
                </TableBody>
              </Table>
            </ScrollArea>
          </div>
        )}

        {step === 'complete' && (
          <Alert>
            <CheckCircle className="h-4 w-4" />
            <AlertDescription>Import completed successfully!</AlertDescription>
          </Alert>
        )}
      </CardContent>
    </Card>
  );
}
