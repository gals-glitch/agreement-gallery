/**
 * Investor Detail Page
 * Shows comprehensive investor information including:
 * - Basic info and source tracking
 * - Contributions history
 * - Related commissions
 * - Active agreements
 */

import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useNavigate, useParams } from 'react-router-dom';
import { SidebarProvider, SidebarTrigger } from '@/components/ui/sidebar';
import { AppSidebar } from '@/components/AppSidebar';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Skeleton } from '@/components/ui/skeleton';
import { Separator } from '@/components/ui/separator';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import {
  Breadcrumb,
  BreadcrumbItem,
  BreadcrumbLink,
  BreadcrumbList,
  BreadcrumbPage,
  BreadcrumbSeparator,
} from '@/components/ui/breadcrumb';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Label } from '@/components/ui/label';
import {
  ArrowLeft,
  User,
  Mail,
  Phone,
  MapPin,
  Building,
  AlertCircle,
  DollarSign,
  FileText,
  TrendingUp,
  Edit,
} from 'lucide-react';
import { SourceBadge } from '@/components/investors/SourceBadge';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from '@/hooks/use-toast';
import type { InvestorWithSource, InvestorSourceKind } from '@/types/investors';
import { INVESTOR_SOURCE_KIND_VALUES, INVESTOR_SOURCE_KIND_LABELS } from '@/types/investors';

// ============================================
// API FUNCTIONS
// ============================================

const fetchInvestor = async (id: string): Promise<InvestorWithSource> => {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) throw new Error('Not authenticated');

  const response = await fetch(
    `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/api-v1/investors/${id}`,
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
    throw new Error(error.message || 'Failed to fetch investor');
  }

  return response.json();
};

const fetchInvestorContributions = async (investorId: string) => {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) throw new Error('Not authenticated');

  const response = await fetch(
    `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/api-v1/contributions?investor_id=${investorId}&limit=100`,
    {
      headers: {
        Authorization: `Bearer ${session.access_token}`,
        apikey: import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY,
        'Content-Type': 'application/json',
      },
    }
  );

  if (!response.ok) {
    throw new Error('Failed to fetch contributions');
  }

  const data = await response.json();
  return data.items || [];
};

const fetchInvestorCommissions = async (investorId: string) => {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) throw new Error('Not authenticated');

  const response = await fetch(
    `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/api-v1/commissions?investor_id=${investorId}&limit=100`,
    {
      headers: {
        Authorization: `Bearer ${session.access_token}`,
        apikey: import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY,
        'Content-Type': 'application/json',
      },
    }
  );

  if (!response.ok) {
    throw new Error('Failed to fetch commissions');
  }

  const data = await response.json();
  return data.data || [];
};

const fetchInvestorAgreements = async (investorId: string) => {
  const { data, error } = await supabase
    .from('agreements')
    .select(`
      id,
      kind,
      scope,
      pricing_mode,
      status,
      effective_from,
      effective_to,
      snapshot_json,
      party_id
    `)
    .eq('investor_id', investorId)
    .eq('status', 'APPROVED')
    .order('effective_from', { ascending: false });

  if (error) {
    console.error('Error fetching agreements:', error);
    return [];
  }

  // Fetch party details separately to avoid ambiguous relationship error
  if (data && data.length > 0) {
    const partyIds = [...new Set(data.map(a => a.party_id))];
    const { data: partiesData } = await supabase
      .from('parties')
      .select('id, name, party_type')
      .in('id', partyIds);

    // Map party data back to agreements
    const partiesMap = new Map(partiesData?.map(p => [p.id, p]) || []);
    return data.map(agreement => ({
      ...agreement,
      party: partiesMap.get(agreement.party_id)
    }));
  }

  return data || [];
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

const updateInvestorSource = async (investorId: string, sourceKind: InvestorSourceKind, introducedByPartyId: string | null) => {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) throw new Error('Not authenticated');

  // Step 1: Update investor source
  const response = await fetch(
    `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/api-v1/investors/${investorId}`,
    {
      method: 'PATCH',
      headers: {
        Authorization: `Bearer ${session.access_token}`,
        apikey: import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        source_kind: sourceKind,
        introduced_by_party_id: introducedByPartyId,
      }),
    }
  );

  if (!response.ok) {
    const error = await response.json().catch(() => ({ message: response.statusText }));
    throw new Error(error.message || 'Failed to update investor source');
  }

  const updatedInvestor = await response.json();

  // Step 2: If assigning a distributor, ensure an agreement exists
  if (sourceKind === 'DISTRIBUTOR' && introducedByPartyId) {
    // Check if an agreement already exists
    const { data: existingAgreements } = await supabase
      .from('agreements')
      .select('id, status')
      .eq('investor_id', investorId)
      .eq('party_id', introducedByPartyId)
      .eq('kind', 'distributor_commission');

    // If no APPROVED or DRAFT agreement exists, create one
    const hasActiveAgreement = existingAgreements?.some(
      (a: any) => a.status === 'APPROVED' || a.status === 'DRAFT' || a.status === 'AWAITING_APPROVAL'
    );

    if (!hasActiveAgreement) {
      // Create a default distributor commission agreement
      const agreementResponse = await fetch(
        `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/api-v1/agreements`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${session.access_token}`,
            apikey: import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            party_id: introducedByPartyId,
            investor_id: investorId,
            kind: 'distributor_commission',
            scope: 'INVESTOR',
            pricing_mode: 'CUSTOM',
            effective_from: new Date().toISOString().split('T')[0],
            vat_included: false,
            custom_terms: {
              upfront_bps: 100, // Default 1% commission
              deferred_bps: 0,
              caps_json: null,
              tiers_json: null,
            },
          }),
        }
      );

      if (!agreementResponse.ok) {
        const error = await agreementResponse.json().catch(() => ({ message: agreementResponse.statusText }));
        console.warn('Failed to create agreement:', error);
        // Don't throw - we still want to show the investor update succeeded
        return { investor: updatedInvestor, agreementId: null };
      }

      const createdAgreement = await agreementResponse.json();
      return { investor: updatedInvestor, agreementId: createdAgreement.id };
    }
  }

  return { investor: updatedInvestor, agreementId: null };
};

// ============================================
// HELPERS
// ============================================

const formatCurrency = (amount: number) => {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
  }).format(amount);
};

const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });
};

// ============================================
// MAIN COMPONENT
// ============================================

export default function InvestorDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { toast } = useToast();
  const queryClient = useQueryClient();

  // Modal state
  const [editModalOpen, setEditModalOpen] = useState(false);
  const [editSourceKind, setEditSourceKind] = useState<InvestorSourceKind>('NONE');
  const [editPartyId, setEditPartyId] = useState<string | null>(null);

  // Connect to Distributor dialog state
  const [connectModalOpen, setConnectModalOpen] = useState(false);
  const [connectSourceKind, setConnectSourceKind] = useState<InvestorSourceKind>('REFERRAL');
  const [connectPartyId, setConnectPartyId] = useState<string>('');
  const [isConnecting, setIsConnecting] = useState(false);

  // Approve-backfill dialog state
  const [showAfterLinkageDialog, setShowAfterLinkageDialog] = useState(false);
  const [lastCreatedAgreementId, setLastCreatedAgreementId] = useState<string | null>(null);
  const [isApproving, setIsApproving] = useState(false);
  const [isRecomputing, setIsRecomputing] = useState(false);

  // Fetch investor details
  const { data: investor, isLoading: isLoadingInvestor } = useQuery({
    queryKey: ['investor', id],
    queryFn: () => fetchInvestor(id!),
    enabled: !!id,
  });

  // Fetch contributions
  const { data: contributions = [], isLoading: isLoadingContributions } = useQuery({
    queryKey: ['investor-contributions', id],
    queryFn: () => fetchInvestorContributions(id!),
    enabled: !!id,
  });

  // Fetch commissions
  const { data: commissions = [], isLoading: isLoadingCommissions } = useQuery({
    queryKey: ['investor-commissions', id],
    queryFn: () => fetchInvestorCommissions(id!),
    enabled: !!id,
  });

  // Fetch agreements
  const { data: agreements = [], isLoading: isLoadingAgreements } = useQuery({
    queryKey: ['investor-agreements', id],
    queryFn: () => fetchInvestorAgreements(id!),
    enabled: !!id,
  });

  // Fetch parties for editing
  const { data: parties = [] } = useQuery({
    queryKey: ['parties'],
    queryFn: fetchParties,
  });

  // Update investor source mutation
  const updateSourceMutation = useMutation({
    mutationFn: () => updateInvestorSource(id!, editSourceKind, editPartyId),
    onSuccess: (result) => {
      // Determine if we assigned a distributor
      const assignedDistributor = editSourceKind === 'DISTRIBUTOR' && editPartyId;

      // If agreement was created, show approve-backfill dialog
      if (result.agreementId) {
        setLastCreatedAgreementId(result.agreementId);
        setShowAfterLinkageDialog(true);
        setEditModalOpen(false);
      } else {
        // No agreement created, just show success toast
        toast({
          title: 'Investor Updated',
          description: assignedDistributor
            ? 'Source information has been updated and default agreement created (if needed).'
            : 'Source information has been updated successfully.',
        });
        setEditModalOpen(false);
      }

      queryClient.invalidateQueries({ queryKey: ['investor', id] });
      queryClient.invalidateQueries({ queryKey: ['investor-agreements', id] });
    },
    onError: (error: Error) => {
      toast({
        title: 'Update Failed',
        description: error.message,
        variant: 'destructive',
      });
    },
  });

  // Handle edit button click
  const handleEditClick = () => {
    if (investor) {
      setEditSourceKind(investor.source_kind);
      setEditPartyId(investor.introduced_by_party_id);
      setEditModalOpen(true);
    }
  };

  // Handle connect to distributor
  const handleConnectDistributor = async () => {
    if (!connectPartyId || !id) {
      toast({
        title: 'Validation Error',
        description: 'Please select a party/distributor',
        variant: 'destructive',
      });
      return;
    }

    setIsConnecting(true);
    try {
      // Use the API to update source and create agreement
      const result = await updateInvestorSource(id, connectSourceKind, connectPartyId);

      // If agreement was created, show approve-backfill dialog
      if (result.agreementId) {
        setLastCreatedAgreementId(result.agreementId);
        setShowAfterLinkageDialog(true);
        setConnectModalOpen(false);

        toast({
          title: 'Distributor Linked',
          description: 'A default commission agreement was created in DRAFT status.',
        });
      } else {
        // No agreement created, just show success toast
        toast({
          title: 'Success',
          description: 'Investor linked to distributor successfully',
        });
        setConnectModalOpen(false);
      }

      // Reset form
      setConnectSourceKind('REFERRAL');
      setConnectPartyId('');

      // Refresh data
      queryClient.invalidateQueries({ queryKey: ['investor', id] });
      queryClient.invalidateQueries({ queryKey: ['investor-agreements', id] });
    } catch (error) {
      toast({
        title: 'Connection Failed',
        description: error instanceof Error ? error.message : 'Unknown error',
        variant: 'destructive',
      });
    } finally {
      setIsConnecting(false);
    }
  };

  // Handle approve agreement
  const handleApproveAgreement = async () => {
    if (!lastCreatedAgreementId) return;

    setIsApproving(true);
    try {
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) throw new Error('Not authenticated');

      // Step 1: Submit the agreement (DRAFT -> AWAITING_APPROVAL)
      const submitResponse = await fetch(
        `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/api-v1/agreements/${lastCreatedAgreementId}/submit`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${session.access_token}`,
            apikey: import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY,
          },
        }
      );

      if (!submitResponse.ok) {
        const error = await submitResponse.json().catch(() => ({ message: submitResponse.statusText }));
        console.error('Agreement submission error:', error);
        throw new Error(error.message || error.error || 'Failed to submit agreement');
      }

      // Step 2: Approve the agreement (AWAITING_APPROVAL -> APPROVED)
      const approveResponse = await fetch(
        `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/api-v1/agreements/${lastCreatedAgreementId}/approve`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${session.access_token}`,
            apikey: import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY,
          },
        }
      );

      if (!approveResponse.ok) {
        const error = await approveResponse.json().catch(() => ({ message: approveResponse.statusText }));
        console.error('Agreement approval error:', error);
        throw new Error(error.message || error.error || 'Failed to approve agreement');
      }

      toast({
        title: 'Agreement Approved',
        description: 'The commission agreement is now active.',
      });

      setShowAfterLinkageDialog(false);
      queryClient.invalidateQueries({ queryKey: ['investor-agreements', id] });
    } catch (error) {
      toast({
        title: 'Approval Failed',
        description: error instanceof Error ? error.message : 'Unknown error',
        variant: 'destructive',
      });
    } finally {
      setIsApproving(false);
    }
  };

  // Handle recompute past commissions
  const handleRecomputeCommissions = async () => {
    setIsRecomputing(true);
    try {
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) throw new Error('Not authenticated');

      // Fetch all contribution IDs for this investor
      const contributionIds = contributions.map((c: any) => c.id);

      if (contributionIds.length === 0) {
        toast({
          title: 'No Contributions',
          description: 'This investor has no contributions to recompute.',
        });
        return;
      }

      const response = await fetch(
        `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/api-v1/commissions/batch-compute`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${session.access_token}`,
            apikey: import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ contribution_ids: contributionIds }),
        }
      );

      if (!response.ok) {
        const error = await response.json().catch(() => ({ message: response.statusText }));
        throw new Error(error.message || 'Failed to recompute commissions');
      }

      const result = await response.json();

      toast({
        title: 'Commissions Recomputed',
        description: `Successfully recomputed ${result.count || contributionIds.length} commission(s) for past contributions.`,
      });

      queryClient.invalidateQueries({ queryKey: ['investor-commissions', id] });
      setShowAfterLinkageDialog(false);
    } catch (error) {
      toast({
        title: 'Recompute Failed',
        description: error instanceof Error ? error.message : 'Unknown error',
        variant: 'destructive',
      });
    } finally {
      setIsRecomputing(false);
    }
  };

  // Calculate totals
  const totalContributions = contributions.reduce((sum: number, c: any) => sum + (c.amount || 0), 0);
  const totalCommissions = commissions.reduce((sum: number, c: any) => sum + (c.total_amount || 0), 0);

  if (isLoadingInvestor) {
    return (
      <SidebarProvider>
        <div className="min-h-screen w-full flex bg-background">
          <AppSidebar />
          <div className="flex-1 p-6">
            <Skeleton className="h-8 w-[300px] mb-6" />
            <Card>
              <CardHeader>
                <Skeleton className="h-6 w-[200px]" />
              </CardHeader>
              <CardContent className="space-y-4">
                <Skeleton className="h-4 w-full" />
                <Skeleton className="h-4 w-full" />
                <Skeleton className="h-4 w-3/4" />
              </CardContent>
            </Card>
          </div>
        </div>
      </SidebarProvider>
    );
  }

  if (!investor) {
    return (
      <SidebarProvider>
        <div className="min-h-screen w-full flex bg-background">
          <AppSidebar />
          <div className="flex-1 flex items-center justify-center">
            <Card className="max-w-md">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <AlertCircle className="w-5 h-5 text-destructive" />
                  Investor Not Found
                </CardTitle>
                <CardDescription>
                  The investor you're looking for doesn't exist or you don't have permission to view it.
                </CardDescription>
              </CardHeader>
              <CardContent>
                <Button onClick={() => navigate('/investors')}>
                  <ArrowLeft className="w-4 h-4 mr-2" />
                  Back to Investors
                </Button>
              </CardContent>
            </Card>
          </div>
        </div>
      </SidebarProvider>
    );
  }

  return (
    <SidebarProvider>
      <div className="min-h-screen w-full flex bg-background">
        <AppSidebar />

        <div className="flex-1 flex flex-col">
          {/* Header */}
          <div className="sticky top-0 z-20 bg-background/80 backdrop-blur border-b border-border">
            <div className="px-4 py-3 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <SidebarTrigger />
                <Button variant="ghost" size="sm" onClick={() => navigate('/investors')}>
                  <ArrowLeft className="w-4 h-4 mr-2" />
                  Back
                </Button>
                <Breadcrumb>
                  <BreadcrumbList>
                    <BreadcrumbItem>
                      <BreadcrumbLink href="/">Home</BreadcrumbLink>
                    </BreadcrumbItem>
                    <BreadcrumbSeparator />
                    <BreadcrumbItem>
                      <BreadcrumbLink href="/investors">Investors</BreadcrumbLink>
                    </BreadcrumbItem>
                    <BreadcrumbSeparator />
                    <BreadcrumbItem>
                      <BreadcrumbPage>{investor.name}</BreadcrumbPage>
                    </BreadcrumbItem>
                  </BreadcrumbList>
                </Breadcrumb>
              </div>
              <Button variant="outline" size="sm" onClick={handleEditClick}>
                <Edit className="w-4 h-4 mr-2" />
                Edit Source
              </Button>
            </div>
          </div>

          {/* Main Content */}
          <main className="flex-1 p-6 space-y-6">
            {/* Overview Card */}
            <Card>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <User className="w-6 h-6 text-muted-foreground" />
                    <CardTitle>{investor.name}</CardTitle>
                    {!investor.is_active && (
                      <Badge variant="destructive">Inactive</Badge>
                    )}
                  </div>
                  <SourceBadge sourceKind={investor.source_kind} />
                </div>
                <CardDescription>Investor ID: {investor.id}</CardDescription>
              </CardHeader>
              <CardContent className="space-y-6">
                {/* Contact Information */}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {investor.email && (
                    <div className="flex items-center gap-2">
                      <Mail className="w-4 h-4 text-muted-foreground" />
                      <span className="text-sm">{investor.email}</span>
                    </div>
                  )}
                  {investor.phone && (
                    <div className="flex items-center gap-2">
                      <Phone className="w-4 h-4 text-muted-foreground" />
                      <span className="text-sm">{investor.phone}</span>
                    </div>
                  )}
                  {investor.country && (
                    <div className="flex items-center gap-2">
                      <MapPin className="w-4 h-4 text-muted-foreground" />
                      <span className="text-sm">{investor.country}</span>
                    </div>
                  )}
                  {investor.tax_id && (
                    <div className="flex items-center gap-2">
                      <FileText className="w-4 h-4 text-muted-foreground" />
                      <span className="text-sm">Tax ID: {investor.tax_id}</span>
                    </div>
                  )}
                </div>

                <Separator />

                {/* Source Information */}
                <div>
                  <h3 className="text-sm font-medium mb-3">Source Information</h3>
                  <div className="space-y-2">
                    <div className="flex justify-between text-sm">
                      <span className="text-muted-foreground">Source Type:</span>
                      <SourceBadge sourceKind={investor.source_kind} />
                    </div>
                    {investor.introduced_by_party && (
                      <div className="flex justify-between text-sm">
                        <span className="text-muted-foreground">Introduced By:</span>
                        <span className="font-medium">{investor.introduced_by_party.name}</span>
                      </div>
                    )}
                    {investor.source_linked_at && (
                      <div className="flex justify-between text-sm">
                        <span className="text-muted-foreground">Linked At:</span>
                        <span>{formatDate(investor.source_linked_at)}</span>
                      </div>
                    )}
                  </div>
                </div>

                <Separator />

                {/* Financial Summary */}
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-sm text-muted-foreground mb-1">Total Contributions</p>
                    <p className="text-2xl font-bold">{formatCurrency(totalContributions)}</p>
                    <p className="text-xs text-muted-foreground">{contributions.length} contributions</p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground mb-1">Related Commissions</p>
                    <p className="text-2xl font-bold">{formatCurrency(totalCommissions)}</p>
                    <p className="text-xs text-muted-foreground">{commissions.length} commissions</p>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Contributions Table */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <DollarSign className="w-5 h-5" />
                  Contributions
                </CardTitle>
                <CardDescription>
                  {contributions.length} contribution{contributions.length !== 1 ? 's' : ''} totaling {formatCurrency(totalContributions)}
                </CardDescription>
              </CardHeader>
              <CardContent>
                {isLoadingContributions ? (
                  <div className="space-y-2">
                    <Skeleton className="h-10 w-full" />
                    <Skeleton className="h-10 w-full" />
                    <Skeleton className="h-10 w-full" />
                  </div>
                ) : contributions.length === 0 ? (
                  <div className="text-center py-8 text-muted-foreground">
                    No contributions found for this investor
                  </div>
                ) : (
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>Date</TableHead>
                        <TableHead>Fund/Deal</TableHead>
                        <TableHead className="text-right">Amount</TableHead>
                        <TableHead>Currency</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {contributions.map((contribution: any) => (
                        <TableRow key={contribution.id}>
                          <TableCell>{formatDate(contribution.paid_in_date || contribution.created_at)}</TableCell>
                          <TableCell>
                            {contribution.fund_name || contribution.deal_name || '-'}
                          </TableCell>
                          <TableCell className="text-right font-mono">
                            {formatCurrency(contribution.amount)}
                          </TableCell>
                          <TableCell>{contribution.currency || 'USD'}</TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                )}
              </CardContent>
            </Card>

            {/* Active Agreements */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <FileText className="w-5 h-5" />
                  Active Agreements
                </CardTitle>
                <CardDescription>
                  Commission agreements that apply to this investor's contributions
                </CardDescription>
              </CardHeader>
              <CardContent>
                {isLoadingAgreements ? (
                  <div className="space-y-2">
                    <Skeleton className="h-10 w-full" />
                    <Skeleton className="h-10 w-full" />
                  </div>
                ) : agreements.length === 0 ? (
                  <div className="text-center py-8">
                    <p className="text-muted-foreground mb-4">
                      No active agreements found for this investor
                    </p>
                    {investor.introduced_by_party ? (
                      <p className="text-sm text-muted-foreground">
                        This investor is linked to <span className="font-medium">{investor.introduced_by_party.name}</span> but no approved agreement exists yet.
                      </p>
                    ) : (
                      <div className="space-y-2">
                        <p className="text-sm text-muted-foreground">
                          This investor is not linked to any distributor/referrer.
                        </p>
                        <Button variant="outline" size="sm" onClick={() => setConnectModalOpen(true)}>
                          Connect to Distributor
                        </Button>
                      </div>
                    )}
                  </div>
                ) : (
                  <div className="space-y-4">
                    {agreements.map((agreement: any) => (
                      <Card key={agreement.id} className="border-l-4 border-l-blue-500">
                        <CardContent className="pt-4">
                          <div className="space-y-3">
                            <div className="flex items-start justify-between">
                              <div>
                                <h4 className="font-medium text-lg">
                                  Agreement with {agreement.party?.name || 'Unknown Party'}
                                </h4>
                                <p className="text-sm text-muted-foreground">
                                  {agreement.kind === 'distributor_commission' ? 'Distributor Commission' : agreement.kind}
                                </p>
                              </div>
                              <Badge variant="outline" className="bg-green-50">
                                {agreement.status}
                              </Badge>
                            </div>

                            <Separator />

                            <div className="grid grid-cols-2 gap-4 text-sm">
                              <div>
                                <p className="text-muted-foreground">Distributor/Referrer:</p>
                                <p className="font-medium">{agreement.party?.name || '-'}</p>
                              </div>
                              <div>
                                <p className="text-muted-foreground">Pricing Mode:</p>
                                <p className="font-medium capitalize">{agreement.pricing_mode}</p>
                              </div>
                              <div>
                                <p className="text-muted-foreground">Effective From:</p>
                                <p className="font-medium">{formatDate(agreement.effective_from)}</p>
                              </div>
                              <div>
                                <p className="text-muted-foreground">Effective To:</p>
                                <p className="font-medium">
                                  {agreement.effective_to ? formatDate(agreement.effective_to) : 'Ongoing'}
                                </p>
                              </div>
                            </div>

                            {agreement.snapshot_json?.terms?.[0] && (
                              <>
                                <Separator />
                                <div className="bg-muted/50 p-3 rounded">
                                  <p className="text-xs font-medium text-muted-foreground mb-2">Commission Terms:</p>
                                  <div className="grid grid-cols-2 gap-2 text-sm">
                                    <div>
                                      <span className="text-muted-foreground">Rate: </span>
                                      <span className="font-mono font-semibold">
                                        {agreement.snapshot_json.terms[0].rate_bps} bps
                                        ({(agreement.snapshot_json.terms[0].rate_bps / 100).toFixed(2)}%)
                                      </span>
                                    </div>
                                    <div>
                                      <span className="text-muted-foreground">VAT: </span>
                                      <span className="font-medium">
                                        {(agreement.snapshot_json.terms[0].vat_rate * 100).toFixed(0)}%
                                        ({agreement.snapshot_json.terms[0].vat_mode})
                                      </span>
                                    </div>
                                  </div>
                                  {agreement.snapshot_json.pricing_variant && agreement.snapshot_json.pricing_variant !== 'BPS' && (
                                    <div className="mt-2">
                                      <Badge variant="secondary">
                                        {agreement.snapshot_json.pricing_variant === 'FIXED' && 'Fixed Fee'}
                                        {agreement.snapshot_json.pricing_variant === 'BPS_SPLIT' && 'Upfront + Deferred'}
                                        {agreement.snapshot_json.pricing_variant === 'MGMT_FEE' && 'Mgmt Fee %'}
                                      </Badge>
                                    </div>
                                  )}
                                </div>
                              </>
                            )}

                            <div className="flex justify-end">
                              <Button
                                variant="ghost"
                                size="sm"
                                onClick={() => navigate(`/agreements/${agreement.id}`)}
                                disabled
                              >
                                View Agreement Details
                              </Button>
                            </div>
                          </div>
                        </CardContent>
                      </Card>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>

            {/* Commissions Table */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <TrendingUp className="w-5 h-5" />
                  Commissions Generated for Distributor
                </CardTitle>
                <CardDescription>
                  Commissions paid to the distributor/referrer based on this investor's contributions
                  {' • '}
                  {commissions.length} commission{commissions.length !== 1 ? 's' : ''} totaling {formatCurrency(totalCommissions)}
                </CardDescription>
              </CardHeader>
              <CardContent>
                {isLoadingCommissions ? (
                  <div className="space-y-2">
                    <Skeleton className="h-10 w-full" />
                    <Skeleton className="h-10 w-full" />
                    <Skeleton className="h-10 w-full" />
                  </div>
                ) : commissions.length === 0 ? (
                  <div className="text-center py-8 text-muted-foreground">
                    No commissions found for this investor's contributions
                  </div>
                ) : (
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>Party</TableHead>
                        <TableHead>Status</TableHead>
                        <TableHead className="text-right">Amount</TableHead>
                        <TableHead>Created</TableHead>
                        <TableHead></TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {commissions.map((commission: any) => (
                        <TableRow key={commission.id}>
                          <TableCell className="font-medium">{commission.party_name}</TableCell>
                          <TableCell>
                            <Badge variant="outline" className="capitalize">
                              {commission.status}
                            </Badge>
                          </TableCell>
                          <TableCell className="text-right font-mono">
                            {formatCurrency(commission.total_amount)}
                          </TableCell>
                          <TableCell>{formatDate(commission.created_at)}</TableCell>
                          <TableCell>
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => navigate(`/commissions/${commission.id}`)}
                            >
                              View
                            </Button>
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                )}
              </CardContent>
            </Card>

            {/* Additional Info Card */}
            {investor.notes && (
              <Card>
                <CardHeader>
                  <CardTitle>Notes</CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-sm whitespace-pre-wrap">{investor.notes}</p>
                </CardContent>
              </Card>
            )}
          </main>
        </div>
      </div>

      {/* Edit Source Modal */}
      <Dialog open={editModalOpen} onOpenChange={setEditModalOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Edit Investor Source</DialogTitle>
            <DialogDescription>
              Update the distributor/referrer information for this investor
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="source-kind">Source Type</Label>
              <Select
                value={editSourceKind}
                onValueChange={(value) => setEditSourceKind(value as InvestorSourceKind)}
              >
                <SelectTrigger id="source-kind">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {INVESTOR_SOURCE_KIND_VALUES.map((kind) => (
                    <SelectItem key={kind} value={kind}>
                      {INVESTOR_SOURCE_KIND_LABELS[kind]}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            {(editSourceKind === 'DISTRIBUTOR' || editSourceKind === 'REFERRER') && (
              <div className="space-y-2">
                <Label htmlFor="party">
                  {editSourceKind === 'DISTRIBUTOR' ? 'Distributor' : 'Referrer'}
                </Label>
                <Select
                  value={editPartyId || 'none'}
                  onValueChange={(value) => setEditPartyId(value === 'none' ? null : value)}
                >
                  <SelectTrigger id="party">
                    <SelectValue placeholder={`Select ${editSourceKind.toLowerCase()}...`} />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="none">None</SelectItem>
                    {parties.map((party: any) => (
                      <SelectItem key={party.id} value={party.id}>
                        {party.name}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                <p className="text-xs text-muted-foreground">
                  This will determine which agreements apply to this investor's contributions
                </p>
              </div>
            )}
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setEditModalOpen(false)}>
              Cancel
            </Button>
            <Button
              onClick={() => updateSourceMutation.mutate()}
              disabled={updateSourceMutation.isPending}
            >
              {updateSourceMutation.isPending ? 'Saving...' : 'Save Changes'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Approve & Backfill Dialog */}
      <Dialog open={showAfterLinkageDialog} onOpenChange={setShowAfterLinkageDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Distributor Linked</DialogTitle>
            <DialogDescription>
              A default commission agreement was created in <strong>DRAFT</strong> status.
              You can approve it now and optionally recompute commissions for past contributions.
            </DialogDescription>
          </DialogHeader>

          <div className="py-4 space-y-3">
            <div className="rounded-md bg-blue-50 border border-blue-200 p-3">
              <p className="text-sm text-blue-900">
                <strong>Note:</strong> The agreement must be approved before commissions can be calculated.
                {contributions.length > 0 && (
                  <> This investor has {contributions.length} contribution(s) that can be recomputed.</>
                )}
              </p>
            </div>
          </div>

          <DialogFooter className="flex gap-2">
            <Button
              variant="outline"
              onClick={() => {
                setShowAfterLinkageDialog(false);
                toast({
                  title: 'Agreement Created',
                  description: 'The agreement is in DRAFT status. You can approve it later from the agreements list.',
                });
              }}
            >
              Skip for Now
            </Button>

            <Button
              onClick={handleApproveAgreement}
              disabled={isApproving || isRecomputing}
            >
              {isApproving ? 'Approving...' : 'Approve Agreement'}
            </Button>

            {contributions.length > 0 && (
              <Button
                variant="secondary"
                onClick={handleRecomputeCommissions}
                disabled={isApproving || isRecomputing}
              >
                {isRecomputing ? 'Recomputing...' : 'Recompute Past Commissions'}
              </Button>
            )}
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Connect to Distributor Dialog */}
      <Dialog open={connectModalOpen} onOpenChange={setConnectModalOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Connect to Distributor/Referrer</DialogTitle>
            <DialogDescription>
              Link this investor to a party (distributor, referrer, or direct contact) and specify the source type.
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            {/* Source Kind Selection */}
            <div className="space-y-2">
              <Label htmlFor="connect-source-kind">Source Type *</Label>
              <Select
                value={connectSourceKind}
                onValueChange={(value) => setConnectSourceKind(value as InvestorSourceKind)}
              >
                <SelectTrigger id="connect-source-kind">
                  <SelectValue placeholder="Select source type" />
                </SelectTrigger>
                <SelectContent>
                  {INVESTOR_SOURCE_KIND_VALUES.map((kind) => (
                    <SelectItem key={kind} value={kind}>
                      {INVESTOR_SOURCE_KIND_LABELS[kind]}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              <p className="text-xs text-muted-foreground">
                How did this investor come to you?
              </p>
            </div>

            {/* Party Selection */}
            <div className="space-y-2">
              <Label htmlFor="connect-party">Party/Distributor *</Label>
              <Select
                value={connectPartyId}
                onValueChange={setConnectPartyId}
              >
                <SelectTrigger id="connect-party">
                  <SelectValue placeholder="Select party" />
                </SelectTrigger>
                <SelectContent>
                  {parties?.map((party: any) => (
                    <SelectItem key={party.id} value={String(party.id)}>
                      {party.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              <p className="text-xs text-muted-foreground">
                The party/distributor who introduced this investor
              </p>
            </div>
          </div>

          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => {
                setConnectModalOpen(false);
                setConnectSourceKind('REFERRAL');
                setConnectPartyId('');
              }}
              disabled={isConnecting}
            >
              Cancel
            </Button>
            <Button
              onClick={handleConnectDistributor}
              disabled={isConnecting || !connectPartyId}
            >
              {isConnecting ? 'Connecting...' : 'Connect to Distributor'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </SidebarProvider>
  );
}
