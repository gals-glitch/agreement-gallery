/**
 * Investors List Page with Source Tracking
 * Tickets: FE-101 (List + Filters)
 * Date: 2025-10-19
 */

import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Skeleton } from '@/components/ui/skeleton';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { useToast } from '@/hooks/use-toast';
import { SourceBadge } from '@/components/investors/SourceBadge';
import {
  InvestorWithSource,
  InvestorListFilters,
  INVESTOR_SOURCE_KIND_VALUES,
  INVESTOR_SOURCE_KIND_LABELS,
  InvestorSourceKind,
} from '@/types/investors';
import { supabase } from '@/integrations/supabase/client';
import { Link, useNavigate } from 'react-router-dom';
import { FileDown, Upload, Filter, X } from 'lucide-react';

const fetchInvestors = async (filters: InvestorListFilters) => {
  // Build query params
  const params = new URLSearchParams();
  if (filters.source_kind && filters.source_kind !== 'ALL') {
    params.append('source_kind', filters.source_kind);
  }
  if (filters.introduced_by_party_id) {
    params.append('introduced_by_party_id', filters.introduced_by_party_id);
  }
  if (filters.has_source !== undefined) {
    params.append('has_source', String(filters.has_source));
  }
  params.append('limit', String(filters.limit || 50));
  params.append('offset', String(filters.offset || 0));

  const { data: { session } } = await supabase.auth.getSession();
  if (!session) throw new Error('Not authenticated');

  const response = await fetch(
    `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/api-v1/investors?${params.toString()}`,
    {
      headers: {
        Authorization: `Bearer ${session.access_token}`,
        apikey: import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY,
        'Content-Type': 'application/json',
      },
    }
  );

  if (!response.ok) {
    const error = await response.json().catch(() => ({ message: response.statusText }));
    console.error('API Error:', error);
    throw new Error(error.message || error.error || 'Failed to fetch investors');
  }

  return response.json();
};

const fetchParties = async () => {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) throw new Error('Not authenticated');

  const response = await fetch(
    `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/api-v1/parties?limit=1000`,
    {
      headers: {
        Authorization: `Bearer ${session.access_token}`,
        apikey: import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY,
        'Content-Type': 'application/json',
      },
    }
  );

  if (!response.ok) {
    throw new Error('Failed to fetch parties');
  }

  const data = await response.json();
  return data.items || [];
};

export default function Investors() {
  const navigate = useNavigate();
  const { toast } = useToast();
  const [filters, setFilters] = useState<InvestorListFilters>({
    source_kind: 'ALL',
    limit: 50,
    offset: 0,
  });
  const [showAddDialog, setShowAddDialog] = useState(false);
  const [newInvestorName, setNewInvestorName] = useState('');

  const { data, isLoading, error } = useQuery({
    queryKey: ['investors', filters],
    queryFn: () => fetchInvestors(filters),
  });

  const { data: parties } = useQuery({
    queryKey: ['parties-all'],
    queryFn: fetchParties,
  });

  const investors: InvestorWithSource[] = data?.items || [];
  const total: number = data?.total || 0;

  const handleFilterChange = (key: keyof InvestorListFilters, value: any) => {
    setFilters((prev) => ({ ...prev, [key]: value, offset: 0 }));
  };

  const handleClearFilters = () => {
    setFilters({
      source_kind: 'ALL',
      limit: 50,
      offset: 0,
    });
  };

  const hasActiveFilters =
    (filters.source_kind && filters.source_kind !== 'ALL') ||
    filters.introduced_by_party_id ||
    filters.has_source !== undefined;

  return (
    <div className="container mx-auto py-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Investors</h1>
          <p className="text-muted-foreground">
            Manage investor records and source attribution
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" size="sm">
            <FileDown className="h-4 w-4 mr-2" />
            Export
          </Button>
          <Button variant="outline" size="sm">
            <Upload className="h-4 w-4 mr-2" />
            Import Sources
          </Button>
          <Button size="sm" onClick={() => setShowAddDialog(true)}>Add Investor</Button>
        </div>
      </div>

      {/* Filters Card */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle className="flex items-center gap-2">
                <Filter className="h-5 w-5" />
                Filters
              </CardTitle>
              <CardDescription>
                Filter investors by source type and attribution
              </CardDescription>
            </div>
            {hasActiveFilters && (
              <Button variant="ghost" size="sm" onClick={handleClearFilters}>
                <X className="h-4 w-4 mr-2" />
                Clear Filters
              </Button>
            )}
          </div>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {/* Source Kind Filter */}
            <div className="space-y-2">
              <Label htmlFor="source-kind-filter">Source Type</Label>
              <Select
                value={filters.source_kind || 'ALL'}
                onValueChange={(value) => handleFilterChange('source_kind', value)}
              >
                <SelectTrigger id="source-kind-filter">
                  <SelectValue placeholder="All sources" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="ALL">All Sources</SelectItem>
                  {INVESTOR_SOURCE_KIND_VALUES.map((kind) => (
                    <SelectItem key={kind} value={kind}>
                      {INVESTOR_SOURCE_KIND_LABELS[kind]}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            {/* Introduced By Party Filter */}
            <div className="space-y-2">
              <Label htmlFor="party-filter">Introduced By</Label>
              <Select
                value={filters.introduced_by_party_id || 'ALL'}
                onValueChange={(value) =>
                  handleFilterChange('introduced_by_party_id', value === 'ALL' ? undefined : value)
                }
              >
                <SelectTrigger id="party-filter">
                  <SelectValue placeholder="All parties" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="ALL">All Parties</SelectItem>
                  {parties?.map((party: any) => (
                    <SelectItem key={party.id} value={party.id}>
                      {party.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            {/* Has Source Filter */}
            <div className="space-y-2">
              <Label htmlFor="has-source-filter">Source Status</Label>
              <Select
                value={
                  filters.has_source === undefined
                    ? 'ALL'
                    : filters.has_source
                    ? 'HAS_SOURCE'
                    : 'NO_SOURCE'
                }
                onValueChange={(value) =>
                  handleFilterChange(
                    'has_source',
                    value === 'ALL' ? undefined : value === 'HAS_SOURCE'
                  )
                }
              >
                <SelectTrigger id="has-source-filter">
                  <SelectValue placeholder="All investors" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="ALL">All Investors</SelectItem>
                  <SelectItem value="HAS_SOURCE">Has Source Attribution</SelectItem>
                  <SelectItem value="NO_SOURCE">No Source Attribution</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Results Card */}
      <Card>
        <CardHeader>
          <CardTitle>
            {total} Investor{total !== 1 ? 's' : ''}
          </CardTitle>
          <CardDescription>
            {hasActiveFilters
              ? 'Filtered results'
              : 'Showing all investors'}
          </CardDescription>
        </CardHeader>
        <CardContent>
          {error && (
            <div className="p-4 bg-red-50 border border-red-200 rounded-md text-red-800">
              Error loading investors: {error.message}
            </div>
          )}

          {isLoading ? (
            <div className="space-y-3">
              {[...Array(5)].map((_, i) => (
                <div key={i} className="flex items-center space-x-4">
                  <Skeleton className="h-12 w-full" />
                </div>
              ))}
            </div>
          ) : investors.length === 0 ? (
            <div className="text-center py-12 text-muted-foreground">
              No investors found. {hasActiveFilters && 'Try adjusting your filters.'}
            </div>
          ) : (
            <div className="rounded-md border">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Name</TableHead>
                    <TableHead>Email</TableHead>
                    <TableHead>Source Kind</TableHead>
                    <TableHead>Introduced By</TableHead>
                    <TableHead>Linked Date</TableHead>
                    <TableHead className="text-right">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {investors.map((investor) => (
                    <TableRow key={investor.id}>
                      <TableCell className="font-medium">
                        <div>
                          <Link
                            to={`/investors/${investor.id}`}
                            className="hover:underline text-blue-600"
                          >
                            {investor.name}
                          </Link>
                          {!investor.is_active && (
                            <Badge variant="outline" className="mt-1">
                              Inactive
                            </Badge>
                          )}
                        </div>
                      </TableCell>
                      <TableCell className="text-muted-foreground">
                        {investor.email || '—'}
                      </TableCell>
                      <TableCell>
                        <SourceBadge sourceKind={investor.source_kind} />
                      </TableCell>
                      <TableCell>
                        {investor.introduced_by_party ? (
                          <Link
                            to={`/parties/${investor.introduced_by_party.id}`}
                            className="text-blue-600 hover:underline"
                          >
                            {investor.introduced_by_party.name}
                          </Link>
                        ) : (
                          <span className="text-muted-foreground">—</span>
                        )}
                      </TableCell>
                      <TableCell className="text-muted-foreground text-sm">
                        {investor.source_linked_at
                          ? new Date(investor.source_linked_at).toLocaleDateString()
                          : '—'}
                      </TableCell>
                      <TableCell className="text-right">
                        <Button variant="ghost" size="sm" asChild>
                          <Link to={`/investors/${investor.id}`}>View</Link>
                        </Button>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Add Investor Dialog */}
      <Dialog open={showAddDialog} onOpenChange={setShowAddDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Add New Investor</DialogTitle>
            <DialogDescription>
              Create a new investor record. You can add more details after creation.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="investor-name">Investor Name *</Label>
              <Input
                id="investor-name"
                value={newInvestorName}
                onChange={(e) => setNewInvestorName(e.target.value)}
                placeholder="Enter investor name"
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => {
              setShowAddDialog(false);
              setNewInvestorName('');
            }}>
              Cancel
            </Button>
            <Button onClick={async () => {
              if (!newInvestorName.trim()) {
                toast({
                  title: 'Validation Error',
                  description: 'Investor name is required',
                  variant: 'destructive',
                });
                return;
              }

              try {
                const { data: newInvestor, error } = await supabase
                  .from('investors')
                  .insert({ name: newInvestorName.trim() })
                  .select()
                  .single();

                if (error) throw error;

                toast({
                  title: 'Success',
                  description: 'Investor created successfully',
                });

                setShowAddDialog(false);
                setNewInvestorName('');

                // Navigate to the new investor's detail page
                navigate(`/investors/${newInvestor.id}`);
              } catch (error: any) {
                toast({
                  title: 'Error',
                  description: error.message || 'Failed to create investor',
                  variant: 'destructive',
                });
              }
            }}>
              Create Investor
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
