/**
 * Contributions Page - Temporary Direct DB Version
 * Uses direct Supabase queries until Edge Function is deployed
 */

import React, { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';
import { ArrowLeft, DollarSign } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { format } from 'date-fns';

interface Contribution {
  id: number;
  investor_id: number;
  deal_id: number | null;
  fund_id: number | null;
  paid_in_date: string;
  amount: number;
  currency: string;
  fx_rate: number | null;
  source_batch: string | null;
  created_at: string;
}

export default function ContributionsTemp() {
  const navigate = useNavigate();
  const { toast } = useToast();

  // State
  const [contributions, setContributions] = useState<Contribution[]>([]);
  const [loading, setLoading] = useState(true);
  const [filters, setFilters] = useState({
    fund_id: '',
    deal_id: '',
    investor_id: '',
    from: '',
    to: '',
    batch: '',
  });

  // Fetch contributions
  const fetchContributions = async () => {
    try {
      setLoading(true);

      let query = supabase
        .from('contributions')
        .select('*')
        .order('paid_in_date', { ascending: true });

      // Apply filters
      if (filters.fund_id) query = query.eq('fund_id', parseInt(filters.fund_id));
      if (filters.deal_id) query = query.eq('deal_id', parseInt(filters.deal_id));
      if (filters.investor_id) query = query.eq('investor_id', parseInt(filters.investor_id));
      if (filters.from) query = query.gte('paid_in_date', filters.from);
      if (filters.to) query = query.lte('paid_in_date', filters.to);
      if (filters.batch) query = query.eq('source_batch', filters.batch);

      const { data, error } = await query;

      if (error) throw error;
      setContributions(data || []);
    } catch (error: any) {
      console.error('Failed to fetch contributions:', error);
      toast({
        title: 'Error',
        description: 'Failed to load contributions',
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchContributions();
  }, [filters]);

  // Handle filter changes
  const updateFilter = (key: string, value: string) => {
    setFilters(prev => ({
      ...prev,
      [key]: value || '',
    }));
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
            <Badge variant="secondary" className="mt-2">
              Direct DB Mode (Temporary)
            </Badge>
          </div>
        </div>
      </div>

      {/* Summary Card */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <div>
            <CardTitle className="text-sm font-medium">Total Contributions</CardTitle>
            <CardDescription>All time paid-in capital</CardDescription>
          </div>
          <DollarSign className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">{contributions.length}</div>
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
          <CardTitle>Filters</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-6 gap-4">
            <div>
              <Label htmlFor="fund_id">Fund ID</Label>
              <Input
                id="fund_id"
                type="number"
                placeholder="e.g. 5"
                value={filters.fund_id}
                onChange={(e) => updateFilter('fund_id', e.target.value)}
              />
            </div>
            <div>
              <Label htmlFor="deal_id">Deal ID</Label>
              <Input
                id="deal_id"
                type="number"
                placeholder="e.g. 10"
                value={filters.deal_id}
                onChange={(e) => updateFilter('deal_id', e.target.value)}
              />
            </div>
            <div>
              <Label htmlFor="investor_id">Investor ID</Label>
              <Input
                id="investor_id"
                type="number"
                placeholder="e.g. 1"
                value={filters.investor_id}
                onChange={(e) => updateFilter('investor_id', e.target.value)}
              />
            </div>
            <div>
              <Label htmlFor="from">From Date</Label>
              <Input
                id="from"
                type="date"
                value={filters.from}
                onChange={(e) => updateFilter('from', e.target.value)}
              />
            </div>
            <div>
              <Label htmlFor="to">To Date</Label>
              <Input
                id="to"
                type="date"
                value={filters.to}
                onChange={(e) => updateFilter('to', e.target.value)}
              />
            </div>
            <div>
              <Label htmlFor="batch">Batch</Label>
              <Input
                id="batch"
                placeholder="e.g. 2025Q3"
                value={filters.batch}
                onChange={(e) => updateFilter('batch', e.target.value)}
              />
            </div>
          </div>
          <div className="flex justify-end mt-4">
            <Button
              variant="outline"
              size="sm"
              onClick={() => setFilters({
                fund_id: '',
                deal_id: '',
                investor_id: '',
                from: '',
                to: '',
                batch: '',
              })}
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
              </TableRow>
            </TableHeader>
            <TableBody>
              {loading ? (
                <TableRow>
                  <TableCell colSpan={6} className="text-center py-8">
                    <div className="flex items-center justify-center gap-2">
                      <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-primary"></div>
                      <span className="text-muted-foreground">Loading contributions...</span>
                    </div>
                  </TableCell>
                </TableRow>
              ) : contributions.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={6} className="text-center text-muted-foreground py-8">
                    No contributions found. Check the database or adjust filters.
                  </TableCell>
                </TableRow>
              ) : (
                contributions.map((contribution) => (
                  <TableRow key={contribution.id}>
                    <TableCell>
                      {format(new Date(contribution.paid_in_date), 'MMM d, yyyy')}
                    </TableCell>
                    <TableCell>
                      <span className="font-medium">ID {contribution.investor_id}</span>
                    </TableCell>
                    <TableCell>
                      {contribution.deal_id ? (
                        <Badge variant="default">Deal {contribution.deal_id}</Badge>
                      ) : (
                        <Badge variant="secondary">Fund {contribution.fund_id}</Badge>
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
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      {/* Info Banner */}
      <Card className="border-blue-200 bg-blue-50">
        <CardContent className="pt-6">
          <p className="text-sm text-blue-800">
            <strong>Note:</strong> This page is using direct database queries.
            Once the Edge Function is deployed, the full API with batch import will be available.
          </p>
        </CardContent>
      </Card>
    </div>
  );
}
