/**
 * Agreements Management Page
 * Features: List, Filter, Create, Edit, Approve/Reject, Version History
 * Date: 2025-11-11
 */

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from '@/hooks/use-toast';
import { AppSidebar } from '@/components/AppSidebar';
import { SidebarProvider } from '@/components/ui/sidebar';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
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
import { Badge } from '@/components/ui/badge';
import { Skeleton } from '@/components/ui/skeleton';
import { Textarea } from '@/components/ui/textarea';
import {
  Plus,
  Filter,
  X,
  CheckCircle,
  XCircle,
  Edit,
  Eye,
  Clock,
} from 'lucide-react';

// ============================================
// TYPES
// ============================================

interface Agreement {
  id: string;
  party_id: string;
  investor_id: number | null;
  kind: 'investor_fee' | 'distributor_commission';
  scope: 'INVESTOR' | 'FUND' | 'DEAL';
  pricing_mode: 'CUSTOM' | 'TRACK';
  status: 'DRAFT' | 'AWAITING_APPROVAL' | 'APPROVED' | 'REJECTED';
  effective_from: string;
  effective_to: string | null;
  vat_included: boolean;
  snapshot_json: Record<string, any>;
  created_at: string;
  updated_at: string;
  party?: {
    id: string;
    name: string;
    party_type: string;
  };
  investor?: {
    id: number;
    name: string;
  };
  fund?: {
    id: number;
    name: string;
  };
  deal?: {
    id: number;
    name: string;
  };
  custom_terms?: {
    upfront_bps: number;
    deferred_bps: number;
    pricing_variant: string;
    fixed_amount_cents: number | null;
  };
}

interface AgreementFilters {
  status?: string;
  party_id?: string;
  kind?: string;
  scope?: string;
  limit: number;
  offset: number;
}

interface CreateAgreementData {
  party_id: string;
  investor_id?: number;
  kind: 'investor_fee' | 'distributor_commission';
  scope: 'INVESTOR' | 'FUND' | 'DEAL';
  fund_id?: number;
  deal_id?: number;
  pricing_mode: 'CUSTOM';
  effective_from: string;
  effective_to?: string;
  vat_included: boolean;
  custom_terms: {
    upfront_bps: number;
    deferred_bps: number;
    pricing_variant: 'BPS' | 'BPS_SPLIT' | 'FIXED' | 'MGMT_FEE';
    fixed_amount_cents?: number;
  };
}

// ============================================
// API FUNCTIONS
// ============================================

const fetchAgreements = async (filters: AgreementFilters) => {
  const params = new URLSearchParams();
  if (filters.status && filters.status !== 'ALL') params.append('status', filters.status);
  if (filters.party_id && filters.party_id !== 'ALL') params.append('party_id', filters.party_id);
  if (filters.kind && filters.kind !== 'ALL') params.append('kind', filters.kind);
  params.append('limit', String(filters.limit));
  params.append('offset', String(filters.offset));

  const { data: { session } } = await supabase.auth.getSession();
  if (!session) throw new Error('Not authenticated');

  const response = await fetch(
    `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/api-v1/agreements?${params.toString()}`,
    {
      headers: {
        Authorization: `Bearer ${session.access_token}`,
        apikey: import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY,
      },
    }
  );

  if (!response.ok) {
    throw new Error('Failed to fetch agreements');
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
      },
    }
  );

  if (!response.ok) throw new Error('Failed to fetch parties');
  const data = await response.json();
  return data.items || [];
};

const createAgreement = async (data: CreateAgreementData) => {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) throw new Error('Not authenticated');

  console.log('Creating agreement with data:', data);

  const response = await fetch(
    `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/api-v1/agreements`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${session.access_token}`,
        apikey: import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(data),
    }
  );

  if (!response.ok) {
    const error = await response.json().catch(() => ({ message: response.statusText }));
    console.error('Agreement creation failed:', error);
    throw new Error(error.message || error.error || 'Failed to create agreement');
  }

  return response.json();
};

const approveAgreement = async (agreementId: string) => {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) throw new Error('Not authenticated');

  const response = await fetch(
    `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/api-v1/agreements/${agreementId}/approve`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${session.access_token}`,
        apikey: import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY,
      },
    }
  );

  if (!response.ok) {
    const error = await response.json().catch(() => ({ message: response.statusText }));
    throw new Error(error.message || 'Failed to approve agreement');
  }

  return response.json();
};

const rejectAgreement = async (agreementId: string, reason: string) => {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) throw new Error('Not authenticated');

  console.log('Rejecting agreement', agreementId, 'with comment:', reason);

  const response = await fetch(
    `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/api-v1/agreements/${agreementId}/reject`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${session.access_token}`,
        apikey: import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ comment: reason }),
    }
  );

  if (!response.ok) {
    const error = await response.json().catch(() => ({ message: response.statusText }));
    console.error('Reject agreement error response:', error);
    throw new Error(error.error || error.message || 'Failed to reject agreement');
  }

  return response.json();
};

// ============================================
// MAIN COMPONENT
// ============================================

export default function AgreementsPage() {
  const { toast } = useToast();
  const queryClient = useQueryClient();

  // State
  const [filters, setFilters] = useState<AgreementFilters>({
    status: 'ALL',
    kind: 'ALL',
    limit: 50,
    offset: 0,
  });

  const [createModalOpen, setCreateModalOpen] = useState(false);
  const [rejectModalOpen, setRejectModalOpen] = useState(false);
  const [selectedAgreementId, setSelectedAgreementId] = useState<string | null>(null);
  const [rejectReason, setRejectReason] = useState('');

  // Create agreement form state
  const [formData, setFormData] = useState<Partial<CreateAgreementData>>({
    kind: 'distributor_commission',
    scope: 'INVESTOR',
    pricing_mode: 'CUSTOM',
    vat_included: false,
    effective_from: new Date().toISOString().split('T')[0],
    custom_terms: {
      upfront_bps: 100,
      deferred_bps: 0,
      pricing_variant: 'BPS',
    },
  });

  // Queries
  const { data, isLoading, error } = useQuery({
    queryKey: ['agreements', filters],
    queryFn: () => fetchAgreements(filters),
  });

  const { data: parties = [] } = useQuery({
    queryKey: ['parties-all'],
    queryFn: fetchParties,
  });

  const agreements: Agreement[] = data?.items || [];
  const total: number = data?.total || 0;

  // Mutations
  const createMutation = useMutation({
    mutationFn: createAgreement,
    onSuccess: () => {
      toast({
        title: 'Agreement Created',
        description: 'The agreement has been created successfully in DRAFT status.',
      });
      setCreateModalOpen(false);
      queryClient.invalidateQueries({ queryKey: ['agreements'] });
    },
    onError: (error: Error) => {
      toast({
        title: 'Creation Failed',
        description: error.message,
        variant: 'destructive',
      });
    },
  });

  const approveMutation = useMutation({
    mutationFn: approveAgreement,
    onSuccess: () => {
      toast({
        title: 'Agreement Approved',
        description: 'The agreement has been approved successfully.',
      });
      queryClient.invalidateQueries({ queryKey: ['agreements'] });
    },
    onError: (error: Error) => {
      toast({
        title: 'Approval Failed',
        description: error.message,
        variant: 'destructive',
      });
    },
  });

  const rejectMutation = useMutation({
    mutationFn: ({ agreementId, reason }: { agreementId: string; reason: string }) =>
      rejectAgreement(agreementId, reason),
    onSuccess: () => {
      toast({
        title: 'Agreement Rejected',
        description: 'The agreement has been rejected.',
      });
      setRejectModalOpen(false);
      setRejectReason('');
      queryClient.invalidateQueries({ queryKey: ['agreements'] });
    },
    onError: (error: Error) => {
      toast({
        title: 'Rejection Failed',
        description: error.message,
        variant: 'destructive',
      });
    },
  });

  // Handlers
  const handleFilterChange = (key: keyof AgreementFilters, value: any) => {
    setFilters((prev) => ({ ...prev, [key]: value, offset: 0 }));
  };

  const handleClearFilters = () => {
    setFilters({
      status: 'ALL',
      kind: 'ALL',
      limit: 50,
      offset: 0,
    });
  };

  const handleCreateAgreement = () => {
    if (!formData.party_id) {
      toast({
        title: 'Validation Error',
        description: 'Please select a party',
        variant: 'destructive',
      });
      return;
    }

    createMutation.mutate(formData as CreateAgreementData);
  };

  const handleApprove = (agreementId: string) => {
    approveMutation.mutate(agreementId);
  };

  const handleRejectClick = (agreementId: string) => {
    setSelectedAgreementId(agreementId);
    setRejectModalOpen(true);
  };

  const handleRejectConfirm = () => {
    if (!selectedAgreementId) return;
    if (!rejectReason.trim()) {
      toast({
        title: 'Validation Error',
        description: 'Please provide a reason for rejection',
        variant: 'destructive',
      });
      return;
    }

    rejectMutation.mutate({
      agreementId: selectedAgreementId,
      reason: rejectReason,
    });
  };

  const hasActiveFilters =
    (filters.status && filters.status !== 'ALL') ||
    (filters.party_id && filters.party_id !== 'ALL') ||
    (filters.kind && filters.kind !== 'ALL');

  const getStatusBadge = (status: string) => {
    const variants: Record<string, string> = {
      DRAFT: 'bg-gray-100 text-gray-700 border-gray-300',
      AWAITING_APPROVAL: 'bg-blue-100 text-blue-800 border-blue-300',
      APPROVED: 'bg-green-100 text-green-800 border-green-300',
      REJECTED: 'bg-red-100 text-red-800 border-red-300',
    };

    return (
      <Badge className={variants[status] || 'bg-gray-100 text-gray-700'}>
        {status}
      </Badge>
    );
  };

  const getPricingVariantLabel = (variant: string) => {
    const labels: Record<string, string> = {
      BPS: 'Basis Points',
      BPS_SPLIT: 'Upfront + Deferred',
      FIXED: 'Fixed Fee',
      MGMT_FEE: 'Management Fee',
    };
    return labels[variant] || variant;
  };

  return (
    <SidebarProvider>
      <div className="min-h-screen w-full flex bg-background">
        <AppSidebar />
        <div className="flex-1 p-6 space-y-6">
          {/* Header */}
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold tracking-tight">Agreements</h1>
              <p className="text-muted-foreground">
                Manage commission agreements and approval workflows
              </p>
            </div>
            <Button onClick={() => setCreateModalOpen(true)}>
              <Plus className="h-4 w-4 mr-2" />
              Create Agreement
            </Button>
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
                  <CardDescription>Filter agreements by status, party, or type</CardDescription>
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
              <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                {/* Status Filter */}
                <div className="space-y-2">
                  <Label htmlFor="status-filter">Status</Label>
                  <Select
                    value={filters.status || 'ALL'}
                    onValueChange={(value) => handleFilterChange('status', value)}
                  >
                    <SelectTrigger id="status-filter">
                      <SelectValue placeholder="All statuses" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="ALL">All Statuses</SelectItem>
                      <SelectItem value="DRAFT">Draft</SelectItem>
                      <SelectItem value="AWAITING_APPROVAL">Awaiting Approval</SelectItem>
                      <SelectItem value="APPROVED">Approved</SelectItem>
                      <SelectItem value="REJECTED">Rejected</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                {/* Party Filter */}
                <div className="space-y-2">
                  <Label htmlFor="party-filter">Party</Label>
                  <Select
                    value={filters.party_id || 'ALL'}
                    onValueChange={(value) =>
                      handleFilterChange('party_id', value === 'ALL' ? undefined : value)
                    }
                  >
                    <SelectTrigger id="party-filter">
                      <SelectValue placeholder="All parties" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="ALL">All Parties</SelectItem>
                      {parties.map((party: any) => (
                        <SelectItem key={party.id} value={party.id}>
                          {party.name}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                {/* Kind Filter */}
                <div className="space-y-2">
                  <Label htmlFor="kind-filter">Type</Label>
                  <Select
                    value={filters.kind || 'ALL'}
                    onValueChange={(value) => handleFilterChange('kind', value)}
                  >
                    <SelectTrigger id="kind-filter">
                      <SelectValue placeholder="All types" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="ALL">All Types</SelectItem>
                      <SelectItem value="distributor_commission">Distributor Commission</SelectItem>
                      <SelectItem value="investor_fee">Investor Fee</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                {/* Scope Filter */}
                <div className="space-y-2">
                  <Label htmlFor="scope-filter">Scope</Label>
                  <Select
                    value={filters.scope || 'ALL'}
                    onValueChange={(value) => handleFilterChange('scope', value)}
                  >
                    <SelectTrigger id="scope-filter">
                      <SelectValue placeholder="All scopes" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="ALL">All Scopes</SelectItem>
                      <SelectItem value="INVESTOR">Investor-Level</SelectItem>
                      <SelectItem value="FUND">Fund-Level</SelectItem>
                      <SelectItem value="DEAL">Deal-Level</SelectItem>
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
                {total} Agreement{total !== 1 ? 's' : ''}
              </CardTitle>
              <CardDescription>
                {hasActiveFilters ? 'Filtered results' : 'Showing all agreements'}
              </CardDescription>
            </CardHeader>
            <CardContent>
              {error && (
                <div className="p-4 bg-red-50 border border-red-200 rounded-md text-red-800">
                  Error loading agreements: {(error as Error).message}
                </div>
              )}

              {isLoading ? (
                <div className="space-y-3">
                  {[...Array(5)].map((_, i) => (
                    <Skeleton key={i} className="h-20 w-full" />
                  ))}
                </div>
              ) : agreements.length === 0 ? (
                <div className="text-center py-12 text-muted-foreground">
                  No agreements found. {hasActiveFilters && 'Try adjusting your filters.'}
                </div>
              ) : (
                <div className="rounded-md border">
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>Party</TableHead>
                        <TableHead>Type</TableHead>
                        <TableHead>Scope</TableHead>
                        <TableHead>Terms</TableHead>
                        <TableHead>Effective Dates</TableHead>
                        <TableHead>Status</TableHead>
                        <TableHead className="text-right">Actions</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {agreements.map((agreement) => (
                        <TableRow key={agreement.id}>
                          <TableCell className="font-medium">
                            {agreement.party?.name || `Party ${agreement.party_id}`}
                          </TableCell>
                          <TableCell>
                            <Badge variant="outline">
                              {agreement.kind === 'distributor_commission'
                                ? 'Commission'
                                : 'Fee'}
                            </Badge>
                          </TableCell>
                          <TableCell>
                            <div className="flex flex-col gap-1">
                              <span className="text-sm font-medium">{agreement.scope}</span>
                              {agreement.investor && (
                                <span className="text-xs text-muted-foreground">
                                  {agreement.investor.name}
                                </span>
                              )}
                              {agreement.fund && (
                                <span className="text-xs text-muted-foreground">
                                  {agreement.fund.name}
                                </span>
                              )}
                              {agreement.deal && (
                                <span className="text-xs text-muted-foreground">
                                  {agreement.deal.name}
                                </span>
                              )}
                            </div>
                          </TableCell>
                          <TableCell>
                            {agreement.custom_terms && (
                              <div className="flex flex-col gap-1">
                                <span className="text-sm">
                                  {agreement.custom_terms.upfront_bps / 100}% upfront
                                </span>
                                {agreement.custom_terms.deferred_bps > 0 && (
                                  <span className="text-xs text-muted-foreground">
                                    {agreement.custom_terms.deferred_bps / 100}% deferred
                                  </span>
                                )}
                                <Badge variant="outline" className="text-xs w-fit">
                                  {getPricingVariantLabel(agreement.custom_terms.pricing_variant)}
                                </Badge>
                              </div>
                            )}
                          </TableCell>
                          <TableCell>
                            <div className="flex flex-col gap-1 text-sm">
                              <span>From: {new Date(agreement.effective_from).toLocaleDateString()}</span>
                              <span className="text-xs text-muted-foreground">
                                To: {agreement.effective_to ? new Date(agreement.effective_to).toLocaleDateString() : 'Open-ended'}
                              </span>
                            </div>
                          </TableCell>
                          <TableCell>{getStatusBadge(agreement.status)}</TableCell>
                          <TableCell className="text-right">
                            <div className="flex justify-end gap-2">
                              {agreement.status === 'AWAITING_APPROVAL' && (
                                <>
                                  <Button
                                    variant="ghost"
                                    size="sm"
                                    onClick={() => handleApprove(agreement.id)}
                                    disabled={approveMutation.isPending}
                                  >
                                    <CheckCircle className="h-4 w-4 text-green-600" />
                                  </Button>
                                  <Button
                                    variant="ghost"
                                    size="sm"
                                    onClick={() => handleRejectClick(agreement.id)}
                                    disabled={rejectMutation.isPending}
                                  >
                                    <XCircle className="h-4 w-4 text-red-600" />
                                  </Button>
                                </>
                              )}
                              <Button variant="ghost" size="sm">
                                <Eye className="h-4 w-4" />
                              </Button>
                            </div>
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Create Agreement Modal */}
          <Dialog open={createModalOpen} onOpenChange={setCreateModalOpen}>
            <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
              <DialogHeader>
                <DialogTitle>Create New Agreement</DialogTitle>
                <DialogDescription>
                  Create a new commission agreement for a distributor or referrer
                </DialogDescription>
              </DialogHeader>

              <div className="space-y-4 py-4">
                {/* Party Selection */}
                <div className="space-y-2">
                  <Label htmlFor="create-party">Party *</Label>
                  <Select
                    value={formData.party_id}
                    onValueChange={(value) => setFormData({ ...formData, party_id: value })}
                  >
                    <SelectTrigger id="create-party">
                      <SelectValue placeholder="Select party..." />
                    </SelectTrigger>
                    <SelectContent>
                      {parties.map((party: any) => (
                        <SelectItem key={party.id} value={party.id}>
                          {party.name}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                {/* Scope */}
                <div className="space-y-2">
                  <Label htmlFor="create-scope">Scope *</Label>
                  <Select
                    value={formData.scope || 'INVESTOR'}
                    onValueChange={(value: any) => {
                      const newFormData: any = { ...formData, scope: value };
                      // Set pricing_mode based on scope constraints
                      if (value === 'FUND') {
                        newFormData.pricing_mode = 'TRACK';
                      } else if (value === 'INVESTOR') {
                        newFormData.pricing_mode = 'CUSTOM';
                      }
                      setFormData(newFormData);
                    }}
                  >
                    <SelectTrigger id="create-scope">
                      <SelectValue placeholder="Select agreement scope" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="INVESTOR">Investor-Level</SelectItem>
                      <SelectItem value="FUND">Fund-Level</SelectItem>
                      <SelectItem value="DEAL">Deal-Level</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                {/* Conditional: Investor selection for INVESTOR scope */}
                {formData.scope === 'INVESTOR' && (
                  <div className="space-y-2">
                    <Label htmlFor="create-investor">Investor (Optional)</Label>
                    <Input
                      id="create-investor"
                      type="number"
                      value={formData.investor_id || ''}
                      onChange={(e) =>
                        setFormData({
                          ...formData,
                          investor_id: e.target.value ? parseInt(e.target.value) : undefined,
                        })
                      }
                      placeholder="Enter investor ID"
                    />
                    <p className="text-xs text-muted-foreground">
                      Leave empty to create a party-level template
                    </p>
                  </div>
                )}

                {/* Conditional: Fund selection for FUND scope */}
                {formData.scope === 'FUND' && (
                  <div className="space-y-2">
                    <Label htmlFor="create-fund">Fund *</Label>
                    <Input
                      id="create-fund"
                      type="number"
                      value={formData.fund_id || ''}
                      onChange={(e) =>
                        setFormData({
                          ...formData,
                          fund_id: e.target.value ? parseInt(e.target.value) : undefined,
                        })
                      }
                      placeholder="Enter fund ID"
                    />
                  </div>
                )}

                {/* Conditional: Deal selection for DEAL scope */}
                {formData.scope === 'DEAL' && (
                  <div className="space-y-2">
                    <Label htmlFor="create-deal">Deal *</Label>
                    <Input
                      id="create-deal"
                      type="number"
                      value={formData.deal_id || ''}
                      onChange={(e) =>
                        setFormData({
                          ...formData,
                          deal_id: e.target.value ? parseInt(e.target.value) : undefined,
                        })
                      }
                      placeholder="Enter deal ID"
                    />
                  </div>
                )}

                {/* Pricing Variant - Only for CUSTOM pricing (INVESTOR and DEAL scopes) */}
                {formData.pricing_mode === 'CUSTOM' && (
                  <div className="space-y-2">
                    <Label htmlFor="create-pricing-variant">Pricing Structure *</Label>
                    <Select
                      value={formData.custom_terms?.pricing_variant || 'BPS'}
                      onValueChange={(value: any) =>
                        setFormData({
                          ...formData,
                          custom_terms: { ...formData.custom_terms!, pricing_variant: value },
                        })
                      }
                    >
                      <SelectTrigger id="create-pricing-variant">
                        <SelectValue placeholder="Select pricing structure" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="BPS">Basis Points (Single Rate)</SelectItem>
                        <SelectItem value="BPS_SPLIT">Upfront + Deferred Split</SelectItem>
                        <SelectItem value="FIXED">Fixed Fee per Contribution</SelectItem>
                        <SelectItem value="MGMT_FEE">Management Fee (Coming Soon)</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                )}

                {/* Commission Rate - Only for CUSTOM pricing */}
                {formData.pricing_mode === 'CUSTOM' && (
                  <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <Label htmlFor="create-upfront-bps">Upfront Rate (BPS) *</Label>
                      <Input
                        id="create-upfront-bps"
                        type="number"
                        value={formData.custom_terms?.upfront_bps || 0}
                        onChange={(e) =>
                          setFormData({
                            ...formData,
                            custom_terms: {
                              ...formData.custom_terms!,
                              upfront_bps: parseInt(e.target.value) || 0,
                            },
                          })
                        }
                        placeholder="100 = 1%"
                      />
                      <p className="text-xs text-muted-foreground">
                        100 basis points = 1%
                      </p>
                    </div>

                    {formData.custom_terms?.pricing_variant === 'BPS_SPLIT' && (
                      <div className="space-y-2">
                        <Label htmlFor="create-deferred-bps">Deferred Rate (BPS)</Label>
                        <Input
                          id="create-deferred-bps"
                          type="number"
                          value={formData.custom_terms?.deferred_bps || 0}
                          onChange={(e) =>
                            setFormData({
                              ...formData,
                              custom_terms: {
                                ...formData.custom_terms!,
                                deferred_bps: parseInt(e.target.value) || 0,
                              },
                            })
                          }
                          placeholder="50 = 0.5%"
                        />
                      </div>
                    )}

                    {formData.custom_terms?.pricing_variant === 'FIXED' && (
                      <div className="space-y-2">
                        <Label htmlFor="create-fixed-amount">Fixed Amount (USD)</Label>
                        <Input
                          id="create-fixed-amount"
                          type="number"
                          value={(formData.custom_terms?.fixed_amount_cents || 0) / 100}
                          onChange={(e) =>
                            setFormData({
                              ...formData,
                              custom_terms: {
                                ...formData.custom_terms!,
                                fixed_amount_cents: Math.round(parseFloat(e.target.value) * 100),
                              },
                            })
                          }
                          placeholder="1000.00"
                        />
                      </div>
                    )}
                  </div>
                )}

                {/* Effective Dates */}
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="create-effective-from">Effective From *</Label>
                    <Input
                      id="create-effective-from"
                      type="date"
                      value={formData.effective_from}
                      onChange={(e) =>
                        setFormData({ ...formData, effective_from: e.target.value })
                      }
                    />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="create-effective-to">Effective To (Optional)</Label>
                    <Input
                      id="create-effective-to"
                      type="date"
                      value={formData.effective_to || ''}
                      onChange={(e) =>
                        setFormData({ ...formData, effective_to: e.target.value || undefined })
                      }
                    />
                  </div>
                </div>
              </div>

              <DialogFooter>
                <Button variant="outline" onClick={() => setCreateModalOpen(false)}>
                  Cancel
                </Button>
                <Button
                  onClick={handleCreateAgreement}
                  disabled={createMutation.isPending}
                >
                  {createMutation.isPending ? 'Creating...' : 'Create Agreement'}
                </Button>
              </DialogFooter>
            </DialogContent>
          </Dialog>

          {/* Reject Agreement Modal */}
          <Dialog open={rejectModalOpen} onOpenChange={setRejectModalOpen}>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>Reject Agreement</DialogTitle>
                <DialogDescription>
                  Please provide a reason for rejecting this agreement
                </DialogDescription>
              </DialogHeader>

              <div className="py-4">
                <Textarea
                  value={rejectReason}
                  onChange={(e) => setRejectReason(e.target.value)}
                  placeholder="Enter rejection reason..."
                  rows={4}
                />
              </div>

              <DialogFooter>
                <Button variant="outline" onClick={() => setRejectModalOpen(false)}>
                  Cancel
                </Button>
                <Button
                  variant="destructive"
                  onClick={handleRejectConfirm}
                  disabled={rejectMutation.isPending}
                >
                  {rejectMutation.isPending ? 'Rejecting...' : 'Reject Agreement'}
                </Button>
              </DialogFooter>
            </DialogContent>
          </Dialog>
        </div>
      </div>
    </SidebarProvider>
  );
}
