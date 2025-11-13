/**
 * Commission Detail Page
 * MVP: Commissions Engine
 * Date: 2025-10-22
 *
 * Displays single commission with:
 * - Overview card with key metrics
 * - Breakdown accordion (base calculation, VAT)
 * - Actions panel with workflow buttons
 * - Audit timeline
 * - RBAC-gated actions
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
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from '@/components/ui/accordion';
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
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import {
  ArrowLeft,
  Send,
  CheckCircle,
  XCircle,
  TrendingUp,
  Clock,
  AlertCircle,
  Receipt,
} from 'lucide-react';
import { useAuth } from '@/hooks/useAuth';
import { useToast } from '@/hooks/use-toast';
import { commissionsApi, type CommissionStatus, type CommissionDetail } from '@/api/commissionsClient';
import { AppliedAgreementCard } from '@/components/commissions/AppliedAgreementCard';

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

const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
};

// ============================================
// REJECT MODAL
// ============================================
interface RejectModalProps {
  open: boolean;
  onClose: () => void;
  onConfirm: (reason: string) => void;
  isPending: boolean;
}

function RejectModal({ open, onClose, onConfirm, isPending }: RejectModalProps) {
  const [reason, setReason] = useState('');

  const handleConfirm = () => {
    if (reason.trim().length < 10) {
      return;
    }
    onConfirm(reason);
  };

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent aria-describedby="reject-dialog-description">
        <DialogHeader>
          <DialogTitle>Reject Commission</DialogTitle>
          <DialogDescription id="reject-dialog-description">
            This action will return the commission to REJECTED status.
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-4 py-4">
          <div className="space-y-2">
            <Label htmlFor="rejection-reason">Reason for Rejection *</Label>
            <Textarea
              id="rejection-reason"
              placeholder="Explain why this commission is being rejected (minimum 10 characters)"
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              rows={4}
              required
              aria-required="true"
            />
            <p className="text-xs text-muted-foreground">
              {reason.length} / 10 characters minimum
            </p>
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={onClose} disabled={isPending}>
            Cancel
          </Button>
          <Button
            variant="destructive"
            onClick={handleConfirm}
            disabled={isPending || reason.trim().length < 10}
          >
            {isPending ? 'Rejecting...' : 'Reject Commission'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

// ============================================
// MARK PAID MODAL
// ============================================
interface MarkPaidModalProps {
  open: boolean;
  onClose: () => void;
  onConfirm: (paymentRef: string) => void;
  isPending: boolean;
}

function MarkPaidModal({ open, onClose, onConfirm, isPending }: MarkPaidModalProps) {
  const [paymentRef, setPaymentRef] = useState('');

  const handleConfirm = () => {
    if (!paymentRef.trim()) {
      return;
    }
    onConfirm(paymentRef);
  };

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent aria-describedby="mark-paid-dialog-description">
        <DialogHeader>
          <DialogTitle>Mark Commission as Paid</DialogTitle>
          <DialogDescription id="mark-paid-dialog-description">
            Record payment details for this commission.
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-4 py-4">
          <div className="space-y-2">
            <Label htmlFor="payment-ref">Payment Reference *</Label>
            <Input
              id="payment-ref"
              placeholder="e.g., WIRE-001, CHECK-123"
              value={paymentRef}
              onChange={(e) => setPaymentRef(e.target.value)}
              required
              aria-required="true"
            />
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={onClose} disabled={isPending}>
            Cancel
          </Button>
          <Button onClick={handleConfirm} disabled={isPending || !paymentRef.trim()}>
            {isPending ? 'Processing...' : 'Mark as Paid'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

// ============================================
// MAIN COMPONENT
// ============================================
export default function CommissionDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const { isFinanceOrAdmin, isAdmin } = useAuth();

  // Modal state
  const [rejectModalOpen, setRejectModalOpen] = useState(false);
  const [markPaidModalOpen, setMarkPaidModalOpen] = useState(false);

  // Fetch commission details
  const { data: commissionResponse, isLoading } = useQuery({
    queryKey: ['commission', id],
    queryFn: () => commissionsApi.getCommission(id!),
    enabled: !!id,
  });

  const commission = commissionResponse?.data;

  // Submit mutation
  const submitMutation = useMutation({
    mutationFn: () => commissionsApi.submitCommission(id!),
    onSuccess: () => {
      toast({
        title: 'Commission Submitted',
        description: 'The commission has been submitted for approval.',
      });
      queryClient.invalidateQueries({ queryKey: ['commission', id] });
      queryClient.invalidateQueries({ queryKey: ['commissions'] });
    },
  });

  // Approve mutation
  const approveMutation = useMutation({
    mutationFn: () => commissionsApi.approveCommission(id!),
    onSuccess: () => {
      toast({
        title: 'Commission Approved',
        description: 'The commission has been approved successfully.',
      });
      queryClient.invalidateQueries({ queryKey: ['commission', id] });
      queryClient.invalidateQueries({ queryKey: ['commissions'] });
    },
  });

  // Reject mutation
  const rejectMutation = useMutation({
    mutationFn: (reason: string) => commissionsApi.rejectCommission(id!, { reason }),
    onSuccess: () => {
      toast({
        title: 'Commission Rejected',
        description: 'The commission has been rejected.',
      });
      setRejectModalOpen(false);
      queryClient.invalidateQueries({ queryKey: ['commission', id] });
      queryClient.invalidateQueries({ queryKey: ['commissions'] });
    },
  });

  // Mark paid mutation
  const markPaidMutation = useMutation({
    mutationFn: (paymentRef: string) =>
      commissionsApi.markPaidCommission(id!, { payment_ref: paymentRef }),
    onSuccess: () => {
      toast({
        title: 'Commission Marked as Paid',
        description: 'Payment has been recorded successfully.',
      });
      setMarkPaidModalOpen(false);
      queryClient.invalidateQueries({ queryKey: ['commission', id] });
      queryClient.invalidateQueries({ queryKey: ['commissions'] });
    },
  });

  if (isLoading) {
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

  if (!commission) {
    return (
      <SidebarProvider>
        <div className="min-h-screen w-full flex bg-background">
          <AppSidebar />
          <div className="flex-1 flex items-center justify-center">
            <Card className="max-w-md">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <AlertCircle className="w-5 h-5 text-destructive" />
                  Commission Not Found
                </CardTitle>
                <CardDescription>
                  The commission you're looking for doesn't exist or you don't have permission to view
                  it.
                </CardDescription>
              </CardHeader>
              <CardContent>
                <Button onClick={() => navigate('/commissions')}>
                  <ArrowLeft className="w-4 h-4 mr-2" />
                  Back to Commissions
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
            <div className="px-4 py-3 flex items-center gap-3">
              <SidebarTrigger />
              <Button variant="ghost" size="sm" onClick={() => navigate('/commissions')}>
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
                    <BreadcrumbLink href="/commissions">Commissions</BreadcrumbLink>
                  </BreadcrumbItem>
                  <BreadcrumbSeparator />
                  <BreadcrumbItem>
                    <BreadcrumbPage>
                      {commission.status.toUpperCase()} #{commission.id.slice(0, 8)}
                    </BreadcrumbPage>
                  </BreadcrumbItem>
                </BreadcrumbList>
              </Breadcrumb>
            </div>
          </div>

          {/* Main Content */}
          <main className="flex-1 p-6 space-y-6">
            {/* Overview Card */}
            <Card>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <CardTitle>Commission #{commission.id.slice(0, 8)}</CardTitle>
                    <Badge className={getStatusBadgeClass(commission.status)} variant="outline">
                      {commission.status.toUpperCase()}
                    </Badge>
                  </div>
                  {commission.rejected_at && commission.reject_reason && (
                    <div className="text-sm text-destructive flex items-center gap-2">
                      <XCircle className="w-4 h-4" />
                      Rejected: {commission.reject_reason}
                    </div>
                  )}
                </div>
                <CardDescription>
                  Created {formatDate(commission.created_at)}
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-6">
                {/* Key Metrics */}
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                  <div>
                    <p className="text-sm text-muted-foreground mb-1">Party Name</p>
                    <p className="font-semibold">{commission.party_name}</p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground mb-1">Investor Name</p>
                    <p className="font-semibold">{commission.investor_name}</p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground mb-1">Fund/Deal Name</p>
                    <p className="font-semibold">{commission.fund_name || commission.deal_name || '-'}</p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground mb-1">Contribution Amount</p>
                    <p className="font-semibold">{formatCurrency(commission.contribution_amount)}</p>
                  </div>
                </div>

                <Separator />

                {/* Amount Breakdown */}
                <div className="grid grid-cols-3 gap-4">
                  <div>
                    <p className="text-sm text-muted-foreground mb-1">Base Amount</p>
                    <p className="font-semibold text-lg">{formatCurrency(commission.base_amount)}</p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground mb-1">VAT Amount</p>
                    <p className="font-semibold text-lg">{formatCurrency(commission.vat_amount)}</p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground mb-1">Total Amount</p>
                    <p className="font-semibold text-lg text-primary">{formatCurrency(commission.total_amount)}</p>
                  </div>
                </div>

                <Separator />

                {/* Payment Reference */}
                {commission.payment_ref && (
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-muted-foreground">Payment Reference: </span>
                    <span className="font-medium">{commission.payment_ref}</span>
                  </div>
                )}
              </CardContent>
            </Card>

            {/* Applied Agreement Card */}
            {commission.snapshot_json && (
              <AppliedAgreementCard
                agreement={{
                  agreement_id: commission.snapshot_json.agreement_id || 0,
                  effective_from: commission.snapshot_json.terms?.[0]?.from || commission.created_at,
                  effective_to: commission.snapshot_json.terms?.[0]?.to || null,
                  rate_bps: commission.snapshot_json.terms?.[0]?.rate_bps || 0,
                  vat_percent: ((commission.snapshot_json.terms?.[0]?.vat_rate || 0) * 100),
                }}
                calc={{
                  contribution_amount: commission.contribution_amount,
                  base_amount: commission.base_amount,
                  commission_amount: commission.base_amount,
                  vat_amount: commission.vat_amount,
                  total_amount: commission.total_amount,
                  computed_at: commission.created_at,
                  pricing_variant: commission.snapshot_json.pricing_variant,
                }}
              />
            )}

            {/* Breakdown Accordion */}
            <Card>
              <CardHeader>
                <CardTitle>Calculation Breakdown</CardTitle>
              </CardHeader>
              <CardContent>
                <Accordion type="multiple" className="w-full" defaultValue={['base', 'vat']}>
                  {/* Base Calculation */}
                  {commission.breakdown?.base_calculation && (
                    <AccordionItem value="base">
                      <AccordionTrigger>Base Calculation</AccordionTrigger>
                      <AccordionContent className="space-y-2 pt-2">
                        <div className="flex justify-between">
                          <span className="text-muted-foreground">Contribution Amount:</span>
                          <span className="font-medium">
                            {formatCurrency(commission.breakdown.base_calculation.contribution_amount)}
                          </span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-muted-foreground">Rate:</span>
                          <span className="font-medium">
                            {(commission.breakdown.base_calculation.rate_bps / 100).toFixed(2)}%
                            ({commission.breakdown.base_calculation.rate_bps} bps)
                          </span>
                        </div>
                        <Separator />
                        <div className="flex justify-between font-semibold">
                          <span>Base Amount:</span>
                          <span>{formatCurrency(commission.breakdown.base_calculation.base_amount)}</span>
                        </div>
                      </AccordionContent>
                    </AccordionItem>
                  )}

                  {/* VAT */}
                  {commission.breakdown?.vat && (
                    <AccordionItem value="vat">
                      <AccordionTrigger>VAT</AccordionTrigger>
                      <AccordionContent className="space-y-2 pt-2">
                        <div className="flex justify-between">
                          <span className="text-muted-foreground">VAT Mode:</span>
                          <span className="font-medium">{commission.breakdown.vat.mode}</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-muted-foreground">VAT Rate:</span>
                          <span className="font-medium">{commission.breakdown.vat.rate}%</span>
                        </div>
                        <Separator />
                        <div className="flex justify-between font-semibold">
                          <span>VAT Amount:</span>
                          <span>{formatCurrency(commission.breakdown.vat.amount)}</span>
                        </div>
                      </AccordionContent>
                    </AccordionItem>
                  )}
                </Accordion>
              </CardContent>
            </Card>

            {/* Actions Panel */}
            <Card>
              <CardHeader>
                <CardTitle>Actions</CardTitle>
              </CardHeader>
              <CardContent className="flex flex-wrap gap-3">
                {commission.status === 'draft' && isFinanceOrAdmin() && (
                  <Button
                    onClick={() => submitMutation.mutate()}
                    disabled={submitMutation.isPending}
                    aria-label="Submit commission for approval"
                  >
                    <Send className="w-4 h-4 mr-2" />
                    {submitMutation.isPending ? 'Submitting...' : 'Submit for Approval'}
                  </Button>
                )}

                {commission.status === 'pending' && isAdmin() && (
                  <>
                    <Button
                      onClick={() => approveMutation.mutate()}
                      disabled={approveMutation.isPending}
                      variant="default"
                      aria-label="Approve commission"
                    >
                      <CheckCircle className="w-4 h-4 mr-2" />
                      {approveMutation.isPending ? 'Approving...' : 'Approve'}
                    </Button>
                    <Button
                      onClick={() => setRejectModalOpen(true)}
                      disabled={rejectMutation.isPending}
                      variant="destructive"
                      aria-label="Reject commission"
                    >
                      <XCircle className="w-4 h-4 mr-2" />
                      Reject
                    </Button>
                  </>
                )}

                {commission.status === 'approved' && isAdmin() && (
                  <Button
                    onClick={() => setMarkPaidModalOpen(true)}
                    disabled={markPaidMutation.isPending}
                    aria-label="Mark commission as paid"
                  >
                    <Receipt className="w-4 h-4 mr-2" />
                    Mark as Paid
                  </Button>
                )}

                {commission.status === 'paid' && (
                  <div className="flex items-center gap-2 text-sm text-muted-foreground">
                    <CheckCircle className="w-4 h-4 text-green-600" />
                    <span>This commission has been paid and cannot be modified.</span>
                  </div>
                )}

                {commission.status === 'rejected' && (
                  <div className="flex items-center gap-2 text-sm text-muted-foreground">
                    <XCircle className="w-4 h-4 text-destructive" />
                    <span>This commission was rejected and cannot be resubmitted.</span>
                  </div>
                )}
              </CardContent>
            </Card>

            {/* Audit Timeline */}
            <Card>
              <CardHeader>
                <CardTitle>Audit Timeline</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {commission.audit_trail?.length > 0 ? (
                    commission.audit_trail.map((event, idx) => (
                      <div key={idx} className="flex gap-4">
                        <div className="flex-shrink-0">
                          <Clock className="w-5 h-5 text-muted-foreground" />
                        </div>
                        <div className="flex-1">
                          <div className="flex items-center justify-between mb-1">
                            <span className="font-medium">{event.event}</span>
                            <span className="text-sm text-muted-foreground">
                              {formatDate(event.timestamp)}
                            </span>
                          </div>
                          <p className="text-sm text-muted-foreground">
                            By {event.user_name}
                            {event.details && ` - ${event.details}`}
                          </p>
                          {idx < commission.audit_trail.length - 1 && <Separator className="mt-4" />}
                        </div>
                      </div>
                    ))
                  ) : (
                    <p className="text-muted-foreground text-center py-4">
                      No audit trail events yet
                    </p>
                  )}
                </div>
              </CardContent>
            </Card>
          </main>
        </div>
      </div>

      {/* Modals */}
      <RejectModal
        open={rejectModalOpen}
        onClose={() => setRejectModalOpen(false)}
        onConfirm={(reason) => rejectMutation.mutate(reason)}
        isPending={rejectMutation.isPending}
      />
      <MarkPaidModal
        open={markPaidModalOpen}
        onClose={() => setMarkPaidModalOpen(false)}
        onConfirm={(paymentRef) => markPaidMutation.mutate(paymentRef)}
        isPending={markPaidMutation.isPending}
      />
    </SidebarProvider>
  );
}
