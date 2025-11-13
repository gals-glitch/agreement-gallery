/**
 * Contributions Page
 * List and manage paid-in capital contributions with batch import
 */

import React, { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import { Sheet, SheetContent, SheetDescription, SheetHeader, SheetTitle, SheetTrigger } from '@/components/ui/sheet';
import { useToast } from '@/hooks/use-toast';
import { contributionsAPI, type Contribution, type ContributionsQueryParams, type CreateContributionRequest, validateContributionBatch } from '@/api/contributions';
import { Upload, Filter, ArrowLeft, Download, DollarSign, Info, Receipt, ExternalLink } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { format } from 'date-fns';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { useAuth } from '@/hooks/useAuth';
import { useFeatureFlag } from '@/hooks/useFeatureFlags';
import { chargesApi } from '@/api/chargesClient';
import { useMutation } from '@tanstack/react-query';

export default function Contributions() {
  const navigate = useNavigate();
  const { toast } = useToast();
  const { isFinanceOrAdmin } = useAuth();
  const { isEnabled: chargesEnabled } = useFeatureFlag('charges_engine');

  // State
  const [contributions, setContributions] = useState<Contribution[]>([]);
  const [loading, setLoading] = useState(true);
  const [filters, setFilters] = useState<ContributionsQueryParams>({});
  const [importDrawerOpen, setImportDrawerOpen] = useState(false);
  const [csvText, setCsvText] = useState('');
  const [importing, setImporting] = useState(false);
  const [validationErrors, setValidationErrors] = useState<Array<{ index: number; errors: string[] }>>([]);
  const [contributionCharges, setContributionCharges] = useState<Record<string, string>>({});

  // Manual contribution form state
  const [manualFormOpen, setManualFormOpen] = useState(false);
  const [manualForm, setManualForm] = useState<Partial<CreateContributionRequest>>({
    currency: 'USD',
    paid_in_date: new Date().toISOString().split('T')[0],
    amount: 0,
  });
  const [scopeType, setScopeType] = useState<'deal' | 'fund'>('deal');

  // Dropdown data for manual form
  const [investors, setInvestors] = useState<Array<{ id: number; name: string }>>([]);
  const [deals, setDeals] = useState<Array<{ id: number; name: string }>>([]);
  const [funds, setFunds] = useState<Array<{ id: number; name: string }>>([]);
  const [investorSearch, setInvestorSearch] = useState('');
  const [dealSearch, setDealSearch] = useState('');
  const [fundSearch, setFundSearch] = useState('');

  // Compute charge mutation
  const computeChargeMutation = useMutation({
    mutationFn: (contributionId: string) => chargesApi.computeCharge(contributionId),
    onSuccess: (data, contributionId) => {
      toast({
        title: 'Charge Computed',
        description: 'Charge has been computed successfully.',
      });
      // Update local state with charge ID
      setContributionCharges(prev => ({ ...prev, [contributionId]: data.id }));
      // Navigate to charge detail
      navigate(`/charges/${data.id}`);
    },
  });

  // Fetch contributions with investor and deal names
  const fetchContributions = async () => {
    try {
      setLoading(true);
      const response = await contributionsAPI.list(filters);

      // Fetch investor and deal names separately using Supabase
      const { createClient } = await import('@supabase/supabase-js');
      const supabase = createClient(
        import.meta.env.VITE_SUPABASE_URL,
        import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY
      );

      // Get unique investor IDs
      const investorIds = [...new Set(response.items.map(c => c.investor_id))];
      const { data: investors } = await supabase
        .from('investors')
        .select('id, name')
        .in('id', investorIds);

      // Get unique deal IDs (excluding nulls)
      const dealIds = [...new Set(response.items.map(c => c.deal_id).filter(id => id !== null))];
      const { data: deals } = dealIds.length > 0 ? await supabase
        .from('deals')
        .select('id, name')
        .in('id', dealIds) : { data: [] };

      // Get unique fund IDs (excluding nulls)
      const fundIds = [...new Set(response.items.map(c => c.fund_id).filter(id => id !== null))];
      const { data: funds } = fundIds.length > 0 ? await supabase
        .from('funds')
        .select('id, name')
        .in('id', fundIds) : { data: [] };

      // Create lookup maps
      const investorMap = new Map((investors || []).map(inv => [inv.id, inv.name]));
      const dealMap = new Map((deals || []).map(deal => [deal.id, deal.name]));
      const fundMap = new Map((funds || []).map(fund => [fund.id, fund.name]));

      // Enrich contributions with names
      const enrichedContributions = response.items.map(c => ({
        ...c,
        investor_name: investorMap.get(c.investor_id),
        deal_name: c.deal_id ? dealMap.get(c.deal_id) : undefined,
        fund_name: c.fund_id ? fundMap.get(c.fund_id) : undefined,
      }));

      setContributions(enrichedContributions);
    } catch (error) {
      console.error('Failed to fetch contributions:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchContributions();
  }, [filters]);

  // Fetch dropdown data for manual form
  const fetchDropdownData = async () => {
    try {
      const { createClient } = await import('@supabase/supabase-js');
      const supabase = createClient(
        import.meta.env.VITE_SUPABASE_URL,
        import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY
      );

      // Fetch investors
      const { data: investorsData } = await supabase
        .from('investors')
        .select('id, name')
        .order('name');

      // Fetch deals
      const { data: dealsData } = await supabase
        .from('deals')
        .select('id, name')
        .order('name');

      // Fetch funds
      const { data: fundsData } = await supabase
        .from('funds')
        .select('id, name')
        .order('name');

      setInvestors(investorsData || []);
      setDeals(dealsData || []);
      setFunds(fundsData || []);
    } catch (error) {
      console.error('Failed to fetch dropdown data:', error);
    }
  };

  // Fetch dropdown data when manual form opens
  useEffect(() => {
    if (manualFormOpen) {
      fetchDropdownData();
    }
  }, [manualFormOpen]);

  // Handle filter changes
  const updateFilter = (key: keyof ContributionsQueryParams, value: any) => {
    setFilters(prev => ({
      ...prev,
      [key]: value || undefined, // Remove if empty
    }));
  };

  // Handle manual contribution submission
  const handleManualSubmit = async () => {
    // Prepare data based on scope type
    const contributionData: CreateContributionRequest = {
      investor_id: manualForm.investor_id!,
      paid_in_date: manualForm.paid_in_date!,
      amount: manualForm.amount!,
      currency: manualForm.currency || 'USD',
      fx_rate: manualForm.fx_rate,
      source_batch: manualForm.source_batch,
    };

    // Set either deal_id or fund_id based on scope type
    if (scopeType === 'deal') {
      contributionData.deal_id = manualForm.deal_id;
    } else {
      contributionData.fund_id = manualForm.fund_id;
    }

    // Validate
    const errors = validateContribution(contributionData);
    if (errors.length > 0) {
      toast({
        title: 'Validation Error',
        description: errors.join(', '),
        variant: 'destructive',
      });
      return;
    }

    try {
      setImporting(true);
      await contributionsAPI.batchCreate([contributionData]);

      toast({
        title: 'Contribution Created',
        description: 'Contribution has been recorded successfully.',
      });

      // Reset form and close
      setManualForm({
        currency: 'USD',
        paid_in_date: new Date().toISOString().split('T')[0],
        amount: 0,
      });
      setInvestorSearch('');
      setDealSearch('');
      setFundSearch('');
      setManualFormOpen(false);

      // Refresh list
      fetchContributions();
    } catch (error: any) {
      toast({
        title: 'Failed to Create Contribution',
        description: error.message || 'An error occurred',
        variant: 'destructive',
      });
    } finally {
      setImporting(false);
    }
  };

  // Handle CSV import
  const handleImport = async () => {
    if (!csvText.trim()) {
      toast({
        title: 'Validation Error',
        description: 'Please paste CSV data',
        variant: 'destructive',
      });
      return;
    }

    try {
      // Parse CSV
      const rows = csvText.trim().split('\n');
      const headers = rows[0].split(',').map(h => h.trim());

      // Map CSV to contribution objects
      const contributions: CreateContributionRequest[] = rows.slice(1).map(row => {
        const values = row.split(',').map(v => v.trim());
        const obj: any = {};
        headers.forEach((header, i) => {
          const value = values[i];
          if (header === 'investor_id' || header === 'deal_id' || header === 'fund_id') {
            obj[header] = value ? parseInt(value) : undefined;
          } else if (header === 'amount' || header === 'fx_rate') {
            obj[header] = value ? parseFloat(value) : undefined;
          } else {
            obj[header] = value || undefined;
          }
        });
        return obj;
      });

      // Client-side validation
      const errors = validateContributionBatch(contributions);
      if (errors.length > 0) {
        setValidationErrors(errors);
        toast({
          title: 'Validation Failed',
          description: `${errors.length} row(s) have errors. Please fix and try again.`,
          variant: 'destructive',
        });
        return;
      }

      // Submit batch
      setImporting(true);
      setValidationErrors([]);
      const response = await contributionsAPI.batchImport(contributions);

      toast({
        title: 'Import Successful',
        description: `Imported ${response.inserted.length} contribution(s)`,
      });

      // Reset and refresh
      setCsvText('');
      setImportDrawerOpen(false);
      fetchContributions();
    } catch (error: any) {
      console.error('Import failed:', error);
      toast({
        title: 'Import Failed',
        description: error.message || 'Failed to import contributions',
        variant: 'destructive',
      });
    } finally {
      setImporting(false);
    }
  };

  // Download CSV template
  const downloadTemplate = () => {
    const template = `investor_id,deal_id,fund_id,paid_in_date,amount,currency,fx_rate,source_batch
1,10,,2025-07-15,250000,USD,,2025Q3
2,,5,2025-07-20,100000,USD,,2025Q3
3,11,,2025-08-01,150000,EUR,1.1,2025Q3`;

    const blob = new Blob([template], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'contributions-template.csv';
    a.click();
    window.URL.revokeObjectURL(url);
  };

  // Format currency
  const formatCurrency = (amount: number, currency: string) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: currency || 'USD',
    }).format(amount);
  };

  return (
    <div className="max-w-7xl mx-auto px-4 py-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Button variant="ghost" size="sm" onClick={() => navigate('/')}>
            <ArrowLeft className="w-4 h-4 mr-2" />
            Back
          </Button>
          <div>
            <h1 className="text-3xl font-bold flex items-center gap-2">
              <DollarSign className="w-8 h-8 text-primary" />
              Contributions
            </h1>
            <p className="text-muted-foreground mt-1">
              Track paid-in capital for funds and deals
            </p>
          </div>
        </div>

        <div className="flex gap-2">
          <Sheet open={manualFormOpen} onOpenChange={setManualFormOpen}>
            <SheetTrigger asChild>
              <Button variant="default">
                <DollarSign className="w-4 h-4 mr-2" />
                New Contribution
              </Button>
            </SheetTrigger>
            <SheetContent className="w-[500px] overflow-y-auto">
              <SheetHeader>
                <SheetTitle>Add Contribution</SheetTitle>
                <SheetDescription>
                  Record a single capital contribution
                </SheetDescription>
              </SheetHeader>

              <div className="mt-6 space-y-4">
                {/* Investor Select */}
                <div>
                  <Label htmlFor="manual-investor">Investor *</Label>
                  <Input
                    id="manual-investor-search"
                    type="text"
                    value={investorSearch}
                    onChange={(e) => setInvestorSearch(e.target.value)}
                    placeholder="Search investor by name..."
                    className="mb-2"
                  />
                  <select
                    id="manual-investor"
                    className="w-full h-10 px-3 py-2 text-sm border rounded-md bg-background"
                    value={manualForm.investor_id || ''}
                    onChange={(e) => {
                      const id = parseInt(e.target.value);
                      setManualForm({ ...manualForm, investor_id: id || undefined });
                      const investor = investors.find(inv => inv.id === id);
                      if (investor) setInvestorSearch(investor.name);
                    }}
                    size={5}
                  >
                    <option value="">-- Select Investor --</option>
                    {investors
                      .filter(inv =>
                        investorSearch === '' ||
                        inv.name.toLowerCase().includes(investorSearch.toLowerCase())
                      )
                      .map(inv => (
                        <option key={inv.id} value={inv.id}>
                          {inv.name} (ID: {inv.id})
                        </option>
                      ))
                    }
                  </select>
                </div>

                {/* Scope Type Selection */}
                <div>
                  <Label>Scope *</Label>
                  <div className="flex gap-4 mt-2">
                    <label className="flex items-center gap-2">
                      <input
                        type="radio"
                        name="scope"
                        checked={scopeType === 'deal'}
                        onChange={() => {
                          setScopeType('deal');
                          setManualForm({ ...manualForm, fund_id: undefined });
                          setFundSearch('');
                        }}
                      />
                      Deal
                    </label>
                    <label className="flex items-center gap-2">
                      <input
                        type="radio"
                        name="scope"
                        checked={scopeType === 'fund'}
                        onChange={() => {
                          setScopeType('fund');
                          setManualForm({ ...manualForm, deal_id: undefined });
                          setDealSearch('');
                        }}
                      />
                      Fund
                    </label>
                  </div>
                </div>

                {/* Deal or Fund Select */}
                {scopeType === 'deal' ? (
                  <div>
                    <Label htmlFor="manual-deal">Deal *</Label>
                    <Input
                      id="manual-deal-search"
                      type="text"
                      value={dealSearch}
                      onChange={(e) => setDealSearch(e.target.value)}
                      placeholder="Search deal by name..."
                      className="mb-2"
                    />
                    <select
                      id="manual-deal"
                      className="w-full h-10 px-3 py-2 text-sm border rounded-md bg-background"
                      value={manualForm.deal_id || ''}
                      onChange={(e) => {
                        const id = parseInt(e.target.value);
                        setManualForm({ ...manualForm, deal_id: id || undefined });
                        const deal = deals.find(d => d.id === id);
                        if (deal) setDealSearch(deal.name);
                      }}
                      size={5}
                    >
                      <option value="">-- Select Deal --</option>
                      {deals
                        .filter(deal =>
                          dealSearch === '' ||
                          deal.name.toLowerCase().includes(dealSearch.toLowerCase())
                        )
                        .map(deal => (
                          <option key={deal.id} value={deal.id}>
                            {deal.name} (ID: {deal.id})
                          </option>
                        ))
                      }
                    </select>
                  </div>
                ) : (
                  <div>
                    <Label htmlFor="manual-fund">Fund *</Label>
                    <Input
                      id="manual-fund-search"
                      type="text"
                      value={fundSearch}
                      onChange={(e) => setFundSearch(e.target.value)}
                      placeholder="Search fund by name..."
                      className="mb-2"
                    />
                    <select
                      id="manual-fund"
                      className="w-full h-10 px-3 py-2 text-sm border rounded-md bg-background"
                      value={manualForm.fund_id || ''}
                      onChange={(e) => {
                        const id = parseInt(e.target.value);
                        setManualForm({ ...manualForm, fund_id: id || undefined });
                        const fund = funds.find(f => f.id === id);
                        if (fund) setFundSearch(fund.name);
                      }}
                      size={5}
                    >
                      <option value="">-- Select Fund --</option>
                      {funds
                        .filter(fund =>
                          fundSearch === '' ||
                          fund.name.toLowerCase().includes(fundSearch.toLowerCase())
                        )
                        .map(fund => (
                          <option key={fund.id} value={fund.id}>
                            {fund.name} (ID: {fund.id})
                          </option>
                        ))
                      }
                    </select>
                  </div>
                )}

                {/* Amount */}
                <div>
                  <Label htmlFor="manual-amount">Amount *</Label>
                  <Input
                    id="manual-amount"
                    type="number"
                    step="0.01"
                    value={manualForm.amount || ''}
                    onChange={(e) => setManualForm({ ...manualForm, amount: parseFloat(e.target.value) || 0 })}
                    placeholder="250000.00"
                  />
                  <p className="text-xs text-muted-foreground mt-1">
                    Enter amount in dollars (e.g., 250000 for $250,000)
                  </p>
                </div>

                {/* Currency */}
                <div>
                  <Label htmlFor="manual-currency">Currency</Label>
                  <Input
                    id="manual-currency"
                    value={manualForm.currency || 'USD'}
                    onChange={(e) => setManualForm({ ...manualForm, currency: e.target.value })}
                    placeholder="USD"
                  />
                </div>

                {/* Date */}
                <div>
                  <Label htmlFor="manual-date">Paid-in Date *</Label>
                  <Input
                    id="manual-date"
                    type="date"
                    value={manualForm.paid_in_date || ''}
                    onChange={(e) => setManualForm({ ...manualForm, paid_in_date: e.target.value })}
                  />
                </div>

                {/* FX Rate (Optional) */}
                <div>
                  <Label htmlFor="manual-fx">FX Rate (Optional)</Label>
                  <Input
                    id="manual-fx"
                    type="number"
                    step="0.0001"
                    value={manualForm.fx_rate || ''}
                    onChange={(e) => setManualForm({ ...manualForm, fx_rate: parseFloat(e.target.value) || undefined })}
                    placeholder="1.1"
                  />
                </div>

                {/* Batch (Optional) */}
                <div>
                  <Label htmlFor="manual-batch">Batch ID (Optional)</Label>
                  <Input
                    id="manual-batch"
                    value={manualForm.source_batch || ''}
                    onChange={(e) => setManualForm({ ...manualForm, source_batch: e.target.value })}
                    placeholder="e.g. 2025Q1"
                  />
                </div>

                {/* Actions */}
                <div className="flex justify-end gap-2 pt-4">
                  <Button
                    variant="outline"
                    onClick={() => {
                      setManualForm({
                        currency: 'USD',
                        paid_in_date: new Date().toISOString().split('T')[0],
                        amount: 0,
                      });
                      setInvestorSearch('');
                      setDealSearch('');
                      setFundSearch('');
                      setManualFormOpen(false);
                    }}
                  >
                    Cancel
                  </Button>
                  <Button
                    onClick={handleManualSubmit}
                    disabled={importing}
                  >
                    {importing ? 'Creating...' : 'Create Contribution'}
                  </Button>
                </div>
              </div>
            </SheetContent>
          </Sheet>

          <Sheet open={importDrawerOpen} onOpenChange={setImportDrawerOpen}>
            <SheetTrigger asChild>
              <Button variant="outline">
                <Upload className="w-4 h-4 mr-2" />
                Batch Import
              </Button>
            </SheetTrigger>
          <SheetContent className="w-[600px] sm:w-[700px] overflow-y-auto">
            <SheetHeader>
              <SheetTitle>Batch Import Contributions</SheetTitle>
              <SheetDescription>
                Paste CSV data or download a template to get started
              </SheetDescription>
            </SheetHeader>

            <div className="mt-6 space-y-4">
              {/* Template Download */}
              <div className="flex items-center justify-between p-4 border rounded-lg bg-muted/50">
                <div>
                  <p className="font-medium">CSV Template</p>
                  <p className="text-sm text-muted-foreground">
                    Download template with example data
                  </p>
                </div>
                <Button variant="outline" size="sm" onClick={downloadTemplate}>
                  <Download className="w-4 h-4 mr-2" />
                  Download
                </Button>
              </div>

              {/* XOR Rule Alert */}
              <Alert>
                <Info className="h-4 w-4" />
                <AlertDescription className="text-sm">
                  <strong>Important:</strong> Each contribution must have <strong>exactly one</strong> of <code className="bg-muted px-1 py-0.5 rounded">deal_id</code> or <code className="bg-muted px-1 py-0.5 rounded">fund_id</code>.
                  <br />
                  <span className="text-muted-foreground">✗ Both set: Invalid | ✗ Neither set: Invalid | ✓ One set: Valid</span>
                </AlertDescription>
              </Alert>

              {/* CSV Input */}
              <div>
                <Label htmlFor="csv-data">Paste CSV Data</Label>
                <textarea
                  id="csv-data"
                  className="w-full h-64 p-3 mt-2 font-mono text-sm border rounded-md resize-none"
                  placeholder="investor_id,deal_id,fund_id,paid_in_date,amount,currency,fx_rate,source_batch&#10;1,10,,2025-07-15,250000,USD,,2025Q3&#10;2,,5,2025-07-20,100000,USD,,2025Q3"
                  value={csvText}
                  onChange={(e) => setCsvText(e.target.value)}
                />
                <p className="text-xs text-muted-foreground mt-2">
                  Required columns: investor_id, paid_in_date, amount. Exactly one of deal_id or fund_id.
                </p>
              </div>

              {/* Validation Errors */}
              {validationErrors.length > 0 && (
                <div className="border border-destructive rounded-lg p-4 bg-destructive/10">
                  <h4 className="font-semibold text-destructive mb-2">
                    Validation Errors ({validationErrors.length} row(s))
                  </h4>
                  <div className="space-y-2 max-h-48 overflow-y-auto">
                    {validationErrors.map(({ index, errors }) => (
                      <button
                        key={index}
                        type="button"
                        className="text-sm w-full text-left hover:bg-destructive/20 p-2 rounded transition-colors"
                        onClick={() => {
                          // Scroll to the problematic row in the textarea
                          const textarea = document.getElementById('csv-data') as HTMLTextAreaElement;
                          if (textarea) {
                            const lines = textarea.value.split('\n');
                            const rowLine = lines.slice(0, index + 1).join('\n').length;
                            textarea.focus();
                            textarea.setSelectionRange(rowLine, rowLine + lines[index + 1]?.length || 0);
                            textarea.scrollTop = (index * 20); // Rough scroll position
                          }
                        }}
                      >
                        <span className="font-mono font-medium">Row {index + 2}:</span>{' '}
                        <span className="text-destructive">{errors.join(', ')}</span>
                        <span className="text-xs text-muted-foreground ml-2">(click to jump)</span>
                      </button>
                    ))}
                  </div>
                </div>
              )}

              {/* Actions */}
              <div className="flex justify-end gap-2 pt-4">
                <Button
                  variant="outline"
                  onClick={() => {
                    setCsvText('');
                    setValidationErrors([]);
                    setImportDrawerOpen(false);
                  }}
                >
                  Cancel
                </Button>
                <Button onClick={handleImport} disabled={importing || !csvText.trim()}>
                  {importing ? 'Importing...' : 'Import'}
                </Button>
              </div>
            </div>
          </SheetContent>
          </Sheet>
        </div>
      </div>

      {/* Summary Card */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <div>
            <CardTitle className="text-sm font-medium">
              Total Contributions
              {Object.keys(filters).length > 0 && (
                <Badge variant="secondary" className="ml-2 text-xs">
                  Filtered
                </Badge>
              )}
            </CardTitle>
            <CardDescription>
              {Object.keys(filters).length > 0 ? 'Filtered results' : 'All time paid-in capital'}
            </CardDescription>
          </div>
          <DollarSign className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">
            {contributions.length.toLocaleString()}
          </div>
          <p className="text-xs text-muted-foreground">
            {formatCurrency(
              contributions.reduce((sum, c) => sum + c.amount, 0),
              'USD'
            )}
          </p>
        </CardContent>
      </Card>

      {/* Filters */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Filter className="w-4 h-4" />
            Filters
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-6 gap-4">
            <div>
              <Label htmlFor="fund_id">Fund ID</Label>
              <Input
                id="fund_id"
                type="number"
                placeholder="e.g. 5"
                value={filters.fund_id || ''}
                onChange={(e) => updateFilter('fund_id', e.target.value ? parseInt(e.target.value) : undefined)}
              />
            </div>
            <div>
              <Label htmlFor="deal_id">Deal ID</Label>
              <Input
                id="deal_id"
                type="number"
                placeholder="e.g. 10"
                value={filters.deal_id || ''}
                onChange={(e) => updateFilter('deal_id', e.target.value ? parseInt(e.target.value) : undefined)}
              />
            </div>
            <div>
              <Label htmlFor="investor_id">Investor ID</Label>
              <Input
                id="investor_id"
                type="number"
                placeholder="e.g. 1"
                value={filters.investor_id || ''}
                onChange={(e) => updateFilter('investor_id', e.target.value ? parseInt(e.target.value) : undefined)}
              />
            </div>
            <div>
              <Label htmlFor="from">From Date</Label>
              <Input
                id="from"
                type="date"
                value={filters.from || ''}
                onChange={(e) => updateFilter('from', e.target.value)}
              />
            </div>
            <div>
              <Label htmlFor="to">To Date</Label>
              <Input
                id="to"
                type="date"
                value={filters.to || ''}
                onChange={(e) => updateFilter('to', e.target.value)}
              />
            </div>
            <div>
              <Label htmlFor="batch">Batch</Label>
              <Input
                id="batch"
                placeholder="e.g. 2025Q3"
                value={filters.batch || ''}
                onChange={(e) => updateFilter('batch', e.target.value)}
              />
            </div>
          </div>
          <div className="flex justify-end mt-4">
            <Button
              variant="outline"
              size="sm"
              onClick={() => setFilters({})}
            >
              Clear Filters
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Contributions Table */}
      <Card>
        <CardHeader>
          <CardTitle>All Contributions</CardTitle>
          <CardDescription>
            {loading ? 'Loading...' : `Showing ${contributions.length} contribution(s)`}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Date</TableHead>
                <TableHead>Investor</TableHead>
                <TableHead>Scope</TableHead>
                <TableHead className="text-right">Amount</TableHead>
                <TableHead>Currency</TableHead>
                <TableHead>Batch</TableHead>
                {chargesEnabled && <TableHead>Charge</TableHead>}
              </TableRow>
            </TableHeader>
            <TableBody>
              {loading ? (
                <TableRow>
                  <TableCell colSpan={chargesEnabled ? 7 : 6} className="text-center py-8">
                    <div className="flex items-center justify-center gap-2">
                      <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-primary"></div>
                      <span className="text-muted-foreground">Loading contributions...</span>
                    </div>
                  </TableCell>
                </TableRow>
              ) : contributions.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={chargesEnabled ? 7 : 6} className="text-center text-muted-foreground py-8">
                    No contributions found. Import your first batch to get started.
                  </TableCell>
                </TableRow>
              ) : (
                contributions.map((contribution) => {
                  // Check if this contribution has a charge (in local state or contribution data)
                  const chargeId = contributionCharges[contribution.id] || (contribution as any).charge_id;

                  return (
                    <TableRow key={contribution.id}>
                      <TableCell>
                        {format(new Date(contribution.paid_in_date), 'MMM d, yyyy')}
                      </TableCell>
                      <TableCell>
                        <span className="font-medium">
                          {contribution.investor_name || `ID ${contribution.investor_id}`}
                        </span>
                      </TableCell>
                      <TableCell>
                        {contribution.deal_id ? (
                          <Badge variant="default">
                            {contribution.deal_name || `Deal ${contribution.deal_id}`}
                          </Badge>
                        ) : (
                          <Badge variant="secondary">
                            {contribution.fund_name || `Fund ${contribution.fund_id}`}
                          </Badge>
                        )}
                      </TableCell>
                      <TableCell className="text-right font-mono">
                        {formatCurrency(contribution.amount, contribution.currency)}
                      </TableCell>
                      <TableCell>
                        <Badge variant="outline">{contribution.currency}</Badge>
                      </TableCell>
                      <TableCell>
                        {contribution.source_batch ? (
                          <Badge variant="outline">{contribution.source_batch}</Badge>
                        ) : (
                          <span className="text-muted-foreground">—</span>
                        )}
                      </TableCell>
                      {chargesEnabled && (
                        <TableCell>
                          {chargeId ? (
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => navigate(`/charges/${chargeId}`)}
                              className="gap-1"
                              aria-label={`View charge for contribution ${contribution.id}`}
                            >
                              <Receipt className="w-3 h-3" />
                              View Charge
                              <ExternalLink className="w-3 h-3" />
                            </Button>
                          ) : isFinanceOrAdmin() ? (
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => computeChargeMutation.mutate(contribution.id)}
                              disabled={computeChargeMutation.isPending}
                              className="gap-1"
                              aria-label={`Compute charge for contribution ${contribution.id}`}
                            >
                              <DollarSign className="w-3 h-3" />
                              {computeChargeMutation.isPending ? 'Computing...' : 'Compute Charge'}
                            </Button>
                          ) : (
                            <span className="text-xs text-muted-foreground">No charge yet</span>
                          )}
                        </TableCell>
                      )}
                    </TableRow>
                  );
                })
              )}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}
