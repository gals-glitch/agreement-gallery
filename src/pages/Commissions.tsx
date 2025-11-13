/**
 * Commissions List Page
 * MVP: Commissions Engine
 * Date: 2025-10-22
 *
 * Displays commissions with:
 * - Tab navigation by status (draft, pending, approved, paid, rejected)
 * - Filters for party, investor, and fund/deal
 * - Data table with inline actions
 * - Finance+ can submit DRAFT commissions
 * - Feature flag guard (commissions_engine)
 */

import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import { SidebarProvider, SidebarTrigger } from '@/components/ui/sidebar';
import { AppSidebar } from '@/components/AppSidebar';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Badge } from '@/components/ui/badge';
import { Skeleton } from '@/components/ui/skeleton';
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
import { ArrowLeft, TrendingUp, Send, AlertCircle } from 'lucide-react';
import { useAuth } from '@/hooks/useAuth';
import { useToast } from '@/hooks/use-toast';
import { commissionsApi, type CommissionStatus, type Commission } from '@/api/commissionsClient';
import { useFeatureFlag } from '@/hooks/useFeatureFlags';
import ComputeEligibleButton from '@/components/commissions/ComputeEligibleButton';

// ============================================
// HELPERS
// ============================================
const getStatusBadgeClass = (status: CommissionStatus) => {
  switch (status) {
    case 'draft':
      return 'bg-gray-500/10 text-gray-700 border-gray-200';
    case 'pending':
      return 'bg-yellow-500/10 text-yellow-700 border-yellow-200';
    case 'approved':
      return 'bg-green-500/10 text-green-700 border-green-200';
    case 'paid':
      return 'bg-blue-500/10 text-blue-700 border-blue-200';
    case 'rejected':
      return 'bg-red-500/10 text-red-700 border-red-200';
    default:
      return 'bg-gray-500/10 text-gray-700 border-gray-200';
  }
};

const formatCurrency = (amount: number) => {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
  }).format(amount);
};

// ============================================
// SKELETON LOADING STATE
// ============================================
function CommissionsTableSkeleton() {
  return (
    <div className="space-y-3">
      {[...Array(5)].map((_, i) => (
        <div key={i} className="flex items-center gap-4 p-4 border rounded-lg">
          <Skeleton className="h-4 w-[200px]" />
          <Skeleton className="h-4 w-[150px]" />
          <Skeleton className="h-4 w-[100px]" />
          <Skeleton className="h-4 w-[100px]" />
          <Skeleton className="h-4 w-[80px]" />
        </div>
      ))}
    </div>
  );
}

// ============================================
// MAIN COMPONENT
// ============================================
export default function CommissionsPage() {
  const navigate = useNavigate();
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const { isFinanceOrAdmin, isAdmin } = useAuth();
  const { isEnabled: commissionsEnabled, isLoading: flagsLoading } = useFeatureFlag('commissions_engine');

  // State
  const [activeTab, setActiveTab] = useState<CommissionStatus>('draft');
  const [partyFilter, setPartyFilter] = useState<string>('all');
  const [investorFilter, setInvestorFilter] = useState<string>('all');
  const [fundDealFilter, setFundDealFilter] = useState<string>('all');

  // Fetch commissions
  const { data: commissionsData, isLoading } = useQuery({
    queryKey: ['commissions', activeTab, partyFilter, investorFilter, fundDealFilter],
    queryFn: () =>
      commissionsApi.listCommissions({
        status: activeTab,
        party_id: partyFilter !== 'all' ? partyFilter : undefined,
        investor_id: investorFilter !== 'all' ? investorFilter : undefined,
        fund_id: fundDealFilter !== 'all' ? parseInt(fundDealFilter) : undefined,
      }),
    enabled: commissionsEnabled,
  });

  // Submit commission mutation
  const submitCommissionMutation = useMutation({
    mutationFn: (commissionId: string) => commissionsApi.submitCommission(commissionId),
    onSuccess: (data) => {
      toast({
        title: 'Commission Submitted',
        description: 'The commission has been submitted successfully.',
      });
      queryClient.invalidateQueries({ queryKey: ['commissions'] });
    },
    onError: (error: any) => {
      // Error toast handled by http.ts
      console.error('Failed to submit commission:', error);
    },
  });

  // Feature flag check
  if (flagsLoading) {
    return (
      <SidebarProvider>
        <div className="min-h-screen w-full flex bg-background">
          <AppSidebar />
          <div className="flex-1 flex items-center justify-center">
            <div className="text-center">
              <Skeleton className="h-8 w-[200px] mx-auto mb-4" />
              <Skeleton className="h-4 w-[300px] mx-auto" />
            </div>
          </div>
        </div>
      </SidebarProvider>
    );
  }

  if (!commissionsEnabled) {
    return (
      <SidebarProvider>
        <div className="min-h-screen w-full flex bg-background">
          <AppSidebar />
          <div className="flex-1 flex items-center justify-center">
            <Card className="max-w-md">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <AlertCircle className="w-5 h-5 text-muted-foreground" />
                  Feature Not Enabled
                </CardTitle>
                <CardDescription>
                  The commissions engine is currently disabled. Please contact your administrator.
                </CardDescription>
              </CardHeader>
            </Card>
          </div>
        </div>
      </SidebarProvider>
    );
  }

  // Render functions
  const renderCommissionRow = (commission: Commission) => (
    <TableRow
      key={commission.id}
      className="cursor-pointer hover:bg-muted/50"
      onClick={() => navigate(`/commissions/${commission.id}`)}
    >
      <TableCell className="font-medium">{commission.party_name}</TableCell>
      <TableCell>{commission.investor_name}</TableCell>
      <TableCell>{commission.fund_name || commission.deal_name || '-'}</TableCell>
      <TableCell className="text-right">{formatCurrency(commission.contribution_amount)}</TableCell>
      <TableCell className="text-right">{formatCurrency(commission.base_amount)}</TableCell>
      <TableCell className="text-right">{formatCurrency(commission.vat_amount)}</TableCell>
      <TableCell className="text-right font-semibold">
        {formatCurrency(commission.total_amount)}
      </TableCell>
      <TableCell>
        <Badge className={getStatusBadgeClass(commission.status)} variant="outline">
          {commission.status.toUpperCase()}
        </Badge>
      </TableCell>
      <TableCell onClick={(e) => e.stopPropagation()}>
        {commission.status === 'draft' && isFinanceOrAdmin() && (
          <Button
            size="sm"
            variant="outline"
            onClick={() => submitCommissionMutation.mutate(commission.id)}
            disabled={submitCommissionMutation.isPending}
            aria-label={`Submit commission for ${commission.party_name}`}
          >
            <Send className="w-3 h-3 mr-1" />
            Submit
          </Button>
        )}
      </TableCell>
    </TableRow>
  );

  const commissions = commissionsData?.data || [];
  const total = commissionsData?.total || 0;

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
                <Button variant="ghost" size="sm" onClick={() => navigate('/')}>
                  <ArrowLeft className="w-4 h-4 mr-2" />
                  Back
                </Button>
                <div className="flex items-center gap-2">
                  <TrendingUp className="w-5 h-5 text-primary" />
                  <h1 className="text-lg font-semibold">Commissions</h1>
                </div>
              </div>
              <ComputeEligibleButton
                canCompute={isFinanceOrAdmin()}
                onAfterCompute={() => queryClient.invalidateQueries({ queryKey: ['commissions'] })}
              />
            </div>
          </div>

          {/* Main Content */}
          <main className="flex-1 p-6">
            <Card>
              <CardHeader>
                <CardTitle>Commissions Queue</CardTitle>
                <CardDescription>
                  Manage distributor commissions across different statuses. Finance can submit drafts, admins can
                  approve or reject.
                </CardDescription>
              </CardHeader>
              <CardContent>
                {/* Tabs */}
                <Tabs value={activeTab} onValueChange={(v) => setActiveTab(v as CommissionStatus)}>
                  <TabsList className="grid w-full grid-cols-5 mb-6">
                    <TabsTrigger value="draft">
                      Draft
                      {activeTab === 'draft' && total > 0 && (
                        <Badge variant="secondary" className="ml-2">
                          {total}
                        </Badge>
                      )}
                    </TabsTrigger>
                    <TabsTrigger value="pending">
                      Pending
                      {activeTab === 'pending' && total > 0 && (
                        <Badge variant="secondary" className="ml-2">
                          {total}
                        </Badge>
                      )}
                    </TabsTrigger>
                    <TabsTrigger value="approved">
                      Approved
                      {activeTab === 'approved' && total > 0 && (
                        <Badge variant="secondary" className="ml-2">
                          {total}
                        </Badge>
                      )}
                    </TabsTrigger>
                    <TabsTrigger value="paid">
                      Paid
                      {activeTab === 'paid' && total > 0 && (
                        <Badge variant="secondary" className="ml-2">
                          {total}
                        </Badge>
                      )}
                    </TabsTrigger>
                    <TabsTrigger value="rejected">
                      Rejected
                      {activeTab === 'rejected' && total > 0 && (
                        <Badge variant="secondary" className="ml-2">
                          {total}
                        </Badge>
                      )}
                    </TabsTrigger>
                  </TabsList>

                  {/* Filters */}
                  <div className="flex gap-4 mb-6">
                    <div className="flex-1">
                      <Select value={partyFilter} onValueChange={setPartyFilter}>
                        <SelectTrigger aria-label="Filter by party">
                          <SelectValue placeholder="All Parties" />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="all">All Parties</SelectItem>
                          {/* TODO: Populate from parties list */}
                        </SelectContent>
                      </Select>
                    </div>
                    <div className="flex-1">
                      <Select value={investorFilter} onValueChange={setInvestorFilter}>
                        <SelectTrigger aria-label="Filter by investor">
                          <SelectValue placeholder="All Investors" />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="all">All Investors</SelectItem>
                          {/* TODO: Populate from investors list */}
                        </SelectContent>
                      </Select>
                    </div>
                    <div className="flex-1">
                      <Select value={fundDealFilter} onValueChange={setFundDealFilter}>
                        <SelectTrigger aria-label="Filter by fund or deal">
                          <SelectValue placeholder="All Funds/Deals" />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="all">All Funds/Deals</SelectItem>
                          {/* TODO: Populate from funds/deals list */}
                        </SelectContent>
                      </Select>
                    </div>
                  </div>

                  {/* Table Content */}
                  <TabsContent value={activeTab} className="mt-0">
                    {isLoading ? (
                      <CommissionsTableSkeleton />
                    ) : commissions.length === 0 ? (
                      <div className="text-center py-12 text-muted-foreground">
                        <TrendingUp className="w-12 h-12 mx-auto mb-4 opacity-50" />
                        <p className="text-lg font-medium mb-2">No commissions found</p>
                        <p className="text-sm">
                          {activeTab === 'draft'
                            ? 'Compute new commissions from the Contributions page.'
                            : `There are no ${activeTab} commissions at the moment.`}
                        </p>
                      </div>
                    ) : (
                      <div className="rounded-md border">
                        <Table>
                          <TableHeader>
                            <TableRow>
                              <TableHead>Party</TableHead>
                              <TableHead>Investor</TableHead>
                              <TableHead>Fund/Deal</TableHead>
                              <TableHead className="text-right">Contribution</TableHead>
                              <TableHead className="text-right">Base</TableHead>
                              <TableHead className="text-right">VAT</TableHead>
                              <TableHead className="text-right">Total</TableHead>
                              <TableHead>Status</TableHead>
                              <TableHead>Actions</TableHead>
                            </TableRow>
                          </TableHeader>
                          <TableBody>
                            {commissions.map((commission) => renderCommissionRow(commission))}
                          </TableBody>
                        </Table>
                      </div>
                    )}

                    {/* Pagination placeholder */}
                    {commissions.length > 0 && (
                      <div className="flex items-center justify-between mt-4">
                        <p className="text-sm text-muted-foreground">
                          Showing {commissions.length} of {total} commissions
                        </p>
                        {/* TODO: Add pagination controls if needed */}
                      </div>
                    )}
                  </TabsContent>
                </Tabs>
              </CardContent>
            </Card>
          </main>
        </div>
      </div>
    </SidebarProvider>
  );
}
