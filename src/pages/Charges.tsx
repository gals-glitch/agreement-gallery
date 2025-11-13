/**
 * Charges List Page
 * Ticket: UI-01
 * Date: 2025-10-21
 *
 * Displays charges with:
 * - Tab navigation by status (Draft, Pending, Approved, Paid, Rejected)
 * - Filters for investor and fund/deal
 * - Data table with inline actions
 * - Finance+ can submit DRAFT charges
 * - Feature flag guard (charges_engine)
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
import { ArrowLeft, DollarSign, Send, AlertCircle } from 'lucide-react';
import { useAuth } from '@/hooks/useAuth';
import { useToast } from '@/hooks/use-toast';
import { chargesApi, type ChargeStatus, type Charge } from '@/api/chargesClient';
import { useFeatureFlag } from '@/hooks/useFeatureFlags';

// ============================================
// HELPERS
// ============================================
const getStatusBadgeClass = (status: ChargeStatus) => {
  switch (status) {
    case 'DRAFT':
      return 'bg-gray-500/10 text-gray-700 border-gray-200';
    case 'PENDING':
      return 'bg-yellow-500/10 text-yellow-700 border-yellow-200';
    case 'APPROVED':
      return 'bg-green-500/10 text-green-700 border-green-200';
    case 'PAID':
      return 'bg-blue-500/10 text-blue-700 border-blue-200';
    case 'REJECTED':
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
function ChargesTableSkeleton() {
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
export default function ChargesPage() {
  const navigate = useNavigate();
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const { isFinanceOrAdmin, isAdmin } = useAuth();
  const { isEnabled: chargesEnabled, isLoading: flagsLoading } = useFeatureFlag('charges_engine');

  // State
  const [activeTab, setActiveTab] = useState<ChargeStatus>('DRAFT');
  const [investorFilter, setInvestorFilter] = useState<string>('all');
  const [fundDealFilter, setFundDealFilter] = useState<string>('all');

  // Fetch charges
  const { data: chargesData, isLoading } = useQuery({
    queryKey: ['charges', activeTab, investorFilter, fundDealFilter],
    queryFn: () =>
      chargesApi.listCharges({
        status: activeTab,
        investor_id: investorFilter !== 'all' ? investorFilter : undefined,
        fund_id: fundDealFilter !== 'all' ? fundDealFilter : undefined,
      }),
    enabled: chargesEnabled,
  });

  // Submit charge mutation
  const submitChargeMutation = useMutation({
    mutationFn: (chargeId: string) => chargesApi.submitCharge(chargeId),
    onSuccess: (data) => {
      toast({
        title: 'Charge Submitted',
        description: 'The charge has been submitted successfully.',
      });
      queryClient.invalidateQueries({ queryKey: ['charges'] });
    },
    onError: (error: any) => {
      // Error toast handled by http.ts
      console.error('Failed to submit charge:', error);
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

  if (!chargesEnabled) {
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
                  The charges engine is currently disabled. Please contact your administrator.
                </CardDescription>
              </CardHeader>
            </Card>
          </div>
        </div>
      </SidebarProvider>
    );
  }

  // Render functions
  const renderChargeRow = (charge: Charge) => (
    <TableRow
      key={charge.id}
      className="cursor-pointer hover:bg-muted/50"
      onClick={() => navigate(`/charges/${charge.id}`)}
    >
      <TableCell className="font-medium">{charge.investor_name}</TableCell>
      <TableCell>{charge.fund_name || charge.deal_name || '-'}</TableCell>
      <TableCell className="text-right">{formatCurrency(charge.base_amount)}</TableCell>
      <TableCell className="text-right">
        {charge.discount_amount ? formatCurrency(charge.discount_amount) : '-'}
      </TableCell>
      <TableCell className="text-right">{formatCurrency(charge.vat_amount)}</TableCell>
      <TableCell className="text-right">
        {charge.credits_applied > 0 ? formatCurrency(charge.credits_applied) : '-'}
      </TableCell>
      <TableCell className="text-right font-semibold">
        {formatCurrency(charge.net_amount)}
      </TableCell>
      <TableCell>
        <Badge className={getStatusBadgeClass(charge.status)} variant="outline">
          {charge.status}
        </Badge>
      </TableCell>
      <TableCell onClick={(e) => e.stopPropagation()}>
        {charge.status === 'DRAFT' && isFinanceOrAdmin() && (
          <Button
            size="sm"
            variant="outline"
            onClick={() => submitChargeMutation.mutate(charge.id)}
            disabled={submitChargeMutation.isPending}
            aria-label={`Submit charge for ${charge.investor_name}`}
          >
            <Send className="w-3 h-3 mr-1" />
            Submit
          </Button>
        )}
      </TableCell>
    </TableRow>
  );

  const charges = chargesData?.data || [];
  const total = chargesData?.total || 0;

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
                  <DollarSign className="w-5 h-5 text-primary" />
                  <h1 className="text-lg font-semibold">Charges</h1>
                </div>
              </div>
              {isFinanceOrAdmin() && (
                <Button onClick={() => navigate('/contributions')} aria-label="Compute new charge">
                  <DollarSign className="w-4 h-4 mr-2" />
                  Compute New Charge
                </Button>
              )}
            </div>
          </div>

          {/* Main Content */}
          <main className="flex-1 p-6">
            <Card>
              <CardHeader>
                <CardTitle>Charges Queue</CardTitle>
                <CardDescription>
                  Manage charges across different statuses. Finance can submit drafts, admins can
                  approve or reject.
                </CardDescription>
              </CardHeader>
              <CardContent>
                {/* Tabs */}
                <Tabs value={activeTab} onValueChange={(v) => setActiveTab(v as ChargeStatus)}>
                  <TabsList className="grid w-full grid-cols-5 mb-6">
                    <TabsTrigger value="DRAFT">
                      Draft
                      {activeTab === 'DRAFT' && total > 0 && (
                        <Badge variant="secondary" className="ml-2">
                          {total}
                        </Badge>
                      )}
                    </TabsTrigger>
                    <TabsTrigger value="PENDING">
                      Pending
                      {activeTab === 'PENDING' && total > 0 && (
                        <Badge variant="secondary" className="ml-2">
                          {total}
                        </Badge>
                      )}
                    </TabsTrigger>
                    <TabsTrigger value="APPROVED">
                      Approved
                      {activeTab === 'APPROVED' && total > 0 && (
                        <Badge variant="secondary" className="ml-2">
                          {total}
                        </Badge>
                      )}
                    </TabsTrigger>
                    <TabsTrigger value="PAID">
                      Paid
                      {activeTab === 'PAID' && total > 0 && (
                        <Badge variant="secondary" className="ml-2">
                          {total}
                        </Badge>
                      )}
                    </TabsTrigger>
                    <TabsTrigger value="REJECTED">
                      Rejected
                      {activeTab === 'REJECTED' && total > 0 && (
                        <Badge variant="secondary" className="ml-2">
                          {total}
                        </Badge>
                      )}
                    </TabsTrigger>
                  </TabsList>

                  {/* Filters */}
                  <div className="flex gap-4 mb-6">
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
                      <ChargesTableSkeleton />
                    ) : charges.length === 0 ? (
                      <div className="text-center py-12 text-muted-foreground">
                        <DollarSign className="w-12 h-12 mx-auto mb-4 opacity-50" />
                        <p className="text-lg font-medium mb-2">No charges found</p>
                        <p className="text-sm">
                          {activeTab === 'DRAFT'
                            ? 'Compute new charges from the Contributions page.'
                            : `There are no ${activeTab.toLowerCase()} charges at the moment.`}
                        </p>
                      </div>
                    ) : (
                      <div className="rounded-md border">
                        <Table>
                          <TableHeader>
                            <TableRow>
                              <TableHead>Investor</TableHead>
                              <TableHead>Fund/Deal</TableHead>
                              <TableHead className="text-right">Base Amount</TableHead>
                              <TableHead className="text-right">Discount</TableHead>
                              <TableHead className="text-right">VAT</TableHead>
                              <TableHead className="text-right">Credits Applied</TableHead>
                              <TableHead className="text-right">Net Amount</TableHead>
                              <TableHead>Status</TableHead>
                              <TableHead>Actions</TableHead>
                            </TableRow>
                          </TableHeader>
                          <TableBody>
                            {charges.map((charge) => renderChargeRow(charge))}
                          </TableBody>
                        </Table>
                      </div>
                    )}

                    {/* Pagination placeholder */}
                    {charges.length > 0 && (
                      <div className="flex items-center justify-between mt-4">
                        <p className="text-sm text-muted-foreground">
                          Showing {charges.length} of {total} charges
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
