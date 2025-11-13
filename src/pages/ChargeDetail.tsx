/**
 * Charge Detail Page
 * Ticket: UI-02
 * Date: 2025-10-21
 *
 * Displays single charge with:
 * - Overview card with key metrics
 * - Breakdown accordion (base, discounts, VAT, caps, credits)
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
  DollarSign,
  Clock,
  AlertCircle,
  Receipt,
} from 'lucide-react';
import { useAuth } from '@/hooks/useAuth';
import { useToast } from '@/hooks/use-toast';
import { chargesApi, type ChargeStatus, type ChargeDetail } from '@/api/chargesClient';

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
          <DialogTitle>Reject Charge</DialogTitle>
          <DialogDescription id="reject-dialog-description">
            This action will reverse any credits applied and return the charge to REJECTED status.
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-4 py-4">
          <div className="space-y-2">
            <Label htmlFor="rejection-reason">Reason for Rejection *</Label>
            <Textarea
              id="rejection-reason"
              placeholder="Explain why this charge is being rejected (minimum 10 characters)"
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
            {isPending ? 'Rejecting...' : 'Reject Charge'}
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
  onConfirm: (paymentRef: string, paidAt?: string) => void;
  isPending: boolean;
}

function MarkPaidModal({ open, onClose, onConfirm, isPending }: MarkPaidModalProps) {
  const [paymentRef, setPaymentRef] = useState('');
  const [paidAt, setPaidAt] = useState('');

  const handleConfirm = () => {
    if (!paymentRef.trim()) {
      return;
    }
    onConfirm(paymentRef, paidAt || undefined);
  };

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent aria-describedby="mark-paid-dialog-description">
        <DialogHeader>
          <DialogTitle>Mark Charge as Paid</DialogTitle>
          <DialogDescription id="mark-paid-dialog-description">
            Record payment details for this charge.
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
          <div className="space-y-2">
            <Label htmlFor="paid-at">Paid At (Optional)</Label>
            <Input
              id="paid-at"
              type="datetime-local"
              value={paidAt}
              onChange={(e) => setPaidAt(e.target.value)}
            />
            <p className="text-xs text-muted-foreground">
              Leave blank to use current time
            </p>
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
export default function ChargeDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const { isFinanceOrAdmin, isAdmin } = useAuth();

  // Modal state
  const [rejectModalOpen, setRejectModalOpen] = useState(false);
  const [markPaidModalOpen, setMarkPaidModalOpen] = useState(false);

  // Fetch charge details
  const { data: charge, isLoading } = useQuery({
    queryKey: ['charge', id],
    queryFn: () => chargesApi.getCharge(id!),
    enabled: !!id,
  });

  // Submit mutation
  const submitMutation = useMutation({
    mutationFn: () => chargesApi.submitCharge(id!),
    onSuccess: () => {
      toast({
        title: 'Charge Submitted',
        description: 'The charge has been submitted for approval.',
      });
      queryClient.invalidateQueries({ queryKey: ['charge', id] });
      queryClient.invalidateQueries({ queryKey: ['charges'] });
    },
  });

  // Approve mutation
  const approveMutation = useMutation({
    mutationFn: () => chargesApi.approveCharge(id!),
    onSuccess: () => {
      toast({
        title: 'Charge Approved',
        description: 'The charge has been approved successfully.',
      });
      queryClient.invalidateQueries({ queryKey: ['charge', id] });
      queryClient.invalidateQueries({ queryKey: ['charges'] });
    },
  });

  // Reject mutation
  const rejectMutation = useMutation({
    mutationFn: (reason: string) => chargesApi.rejectCharge(id!, { reason }),
    onSuccess: (data) => {
      toast({
        title: 'Charge Rejected',
        description: `Credits reversed: ${formatCurrency(data.credits_reversed)}`,
      });
      setRejectModalOpen(false);
      queryClient.invalidateQueries({ queryKey: ['charge', id] });
      queryClient.invalidateQueries({ queryKey: ['charges'] });
    },
  });

  // Mark paid mutation
  const markPaidMutation = useMutation({
    mutationFn: ({ paymentRef, paidAt }: { paymentRef: string; paidAt?: string }) =>
      chargesApi.markPaidCharge(id!, { payment_ref: paymentRef, paid_at: paidAt }),
    onSuccess: () => {
      toast({
        title: 'Charge Marked as Paid',
        description: 'Payment has been recorded successfully.',
      });
      setMarkPaidModalOpen(false);
      queryClient.invalidateQueries({ queryKey: ['charge', id] });
      queryClient.invalidateQueries({ queryKey: ['charges'] });
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

  if (!charge) {
    return (
      <SidebarProvider>
        <div className="min-h-screen w-full flex bg-background">
          <AppSidebar />
          <div className="flex-1 flex items-center justify-center">
            <Card className="max-w-md">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <AlertCircle className="w-5 h-5 text-destructive" />
                  Charge Not Found
                </CardTitle>
                <CardDescription>
                  The charge you're looking for doesn't exist or you don't have permission to view
                  it.
                </CardDescription>
              </CardHeader>
              <CardContent>
                <Button onClick={() => navigate('/charges')}>
                  <ArrowLeft className="w-4 h-4 mr-2" />
                  Back to Charges
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
              <Button variant="ghost" size="sm" onClick={() => navigate('/charges')}>
                <ArrowLeft className="w-4 h-4 mr-2" />
                Back
              </Button>
              <Breadcrumb>
                <BreadcrumbList>
                  <BreadcrumbItem>
                    <BreadcrumbLink href="/charges">Charges</BreadcrumbLink>
                  </BreadcrumbItem>
                  <BreadcrumbSeparator />
                  <BreadcrumbItem>
                    <BreadcrumbPage>
                      {charge.status} #{charge.id.slice(0, 8)}
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
                    <CardTitle>Charge #{charge.id.slice(0, 8)}</CardTitle>
                    <Badge className={getStatusBadgeClass(charge.status)} variant="outline">
                      {charge.status}
                    </Badge>
                  </div>
                  {charge.rejected_at && charge.rejection_reason && (
                    <div className="text-sm text-destructive flex items-center gap-2">
                      <XCircle className="w-4 h-4" />
                      Rejected: {charge.rejection_reason}
                    </div>
                  )}
                </div>
                <CardDescription>
                  Created {formatDate(charge.created_at)}
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-6">
                {/* Key Metrics */}
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                  <div>
                    <p className="text-sm text-muted-foreground mb-1">Investor</p>
                    <p className="font-semibold">{charge.investor_name}</p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground mb-1">Fund/Deal</p>
                    <p className="font-semibold">{charge.fund_name || charge.deal_name || '-'}</p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground mb-1">Total Amount</p>
                    <p className="font-semibold text-lg">
                      {formatCurrency(charge.base_amount + charge.vat_amount)}
                    </p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground mb-1">Net Amount</p>
                    <p className="font-semibold text-lg text-primary">
                      {formatCurrency(charge.net_amount)}
                    </p>
                  </div>
                </div>

                <Separator />

                {/* Summary Row */}
                <div className="flex items-center justify-between text-sm">
                  <div>
                    <span className="text-muted-foreground">Credits Applied: </span>
                    <span className="font-medium">
                      {charge.credits_applied > 0 ? formatCurrency(charge.credits_applied) : 'None'}
                    </span>
                  </div>
                  {charge.payment_ref && (
                    <div>
                      <span className="text-muted-foreground">Payment Ref: </span>
                      <span className="font-medium">{charge.payment_ref}</span>
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>

            {/* Breakdown Accordion */}
            <Card>
              <CardHeader>
                <CardTitle>Calculation Breakdown</CardTitle>
              </CardHeader>
              <CardContent>
                <Accordion type="multiple" className="w-full" defaultValue={['base', 'vat']}>
                  {/* Base Calculation */}
                  {charge.breakdown?.base_calculation && (
                    <AccordionItem value="base">
                      <AccordionTrigger>Base Calculation</AccordionTrigger>
                      <AccordionContent className="space-y-2 pt-2">
                        <div className="flex justify-between">
                          <span className="text-muted-foreground">Contribution Amount:</span>
                          <span className="font-medium">
                            {formatCurrency(charge.breakdown.base_calculation.contribution_amount)}
                          </span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-muted-foreground">Rate:</span>
                          <span className="font-medium">
                            {(charge.breakdown.base_calculation.rate_bps / 100).toFixed(2)}%
                            ({charge.breakdown.base_calculation.rate_bps} bps)
                        </span>
                      </div>
                      <Separator />
                      <div className="flex justify-between font-semibold">
                        <span>Base Amount:</span>
                        <span>{formatCurrency(charge.breakdown.base_calculation.base_amount)}</span>
                      </div>
                    </AccordionContent>
                  </AccordionItem>
                  )}

                  {/* Discounts */}
                  {charge.breakdown?.discounts && charge.breakdown.discounts.length > 0 && (
                    <AccordionItem value="discounts">
                      <AccordionTrigger>Discounts Applied</AccordionTrigger>
                      <AccordionContent className="space-y-2 pt-2">
                        {charge.breakdown.discounts.map((discount, idx) => (
                          <div key={idx} className="flex justify-between">
                            <span className="text-muted-foreground">{discount.discount_name}:</span>
                            <span className="font-medium text-green-600">
                              -{formatCurrency(discount.amount)}
                            </span>
                          </div>
                        ))}
                      </AccordionContent>
                    </AccordionItem>
                  )}

                  {/* VAT */}
                  {charge.breakdown?.vat && (
                    <AccordionItem value="vat">
                      <AccordionTrigger>VAT</AccordionTrigger>
                      <AccordionContent className="space-y-2 pt-2">
                        <div className="flex justify-between">
                          <span className="text-muted-foreground">VAT Rate:</span>
                          <span className="font-medium">{charge.breakdown.vat.rate}%</span>
                        </div>
                        <Separator />
                        <div className="flex justify-between font-semibold">
                          <span>VAT Amount:</span>
                          <span>{formatCurrency(charge.breakdown.vat.amount)}</span>
                        </div>
                      </AccordionContent>
                    </AccordionItem>
                  )}

                  {/* Caps */}
                  {charge.breakdown?.caps && charge.breakdown.caps.length > 0 && (
                    <AccordionItem value="caps">
                      <AccordionTrigger>Caps</AccordionTrigger>
                      <AccordionContent className="space-y-2 pt-2">
                        {charge.breakdown.caps.map((cap, idx) => (
                          <div key={idx} className="flex justify-between">
                            <span className="text-muted-foreground">{cap.cap_type}:</span>
                            <span className="font-medium">
                              {formatCurrency(cap.cap_amount)}
                              {cap.applied && (
                                <Badge variant="secondary" className="ml-2">
                                  Applied
                                </Badge>
                              )}
                            </span>
                          </div>
                        ))}
                      </AccordionContent>
                    </AccordionItem>
                  )}

                  {/* Credits Applied */}
                  {charge.breakdown?.credits_applied && charge.breakdown.credits_applied.length > 0 && (
                    <AccordionItem value="credits">
                      <AccordionTrigger>Credits Applied</AccordionTrigger>
                      <AccordionContent className="space-y-2 pt-2">
                        {charge.breakdown.credits_applied.map((credit, idx) => (
                          <div key={idx} className="space-y-1">
                            <div className="flex justify-between">
                              <span className="text-sm font-medium">
                                Credit #{credit.credit_id.slice(0, 8)}
                              </span>
                              <span className="font-semibold text-green-600">
                                -{formatCurrency(credit.amount)}
                              </span>
                            </div>
                            <div className="text-xs text-muted-foreground">
                              {credit.credit_source} on {formatDate(credit.credit_date)}
                            </div>
                            {idx < charge.breakdown.credits_applied.length - 1 && <Separator />}
                          </div>
                        ))}
                        <Separator />
                        <div className="flex justify-between font-semibold pt-2">
                          <span>Total Credits:</span>
                          <span className="text-green-600">
                            -{formatCurrency(charge.credits_applied)}
                          </span>
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
                {charge.status === 'DRAFT' && isFinanceOrAdmin() && (
                  <Button
                    onClick={() => submitMutation.mutate()}
                    disabled={submitMutation.isPending}
                    aria-label="Submit charge for approval"
                  >
                    <Send className="w-4 h-4 mr-2" />
                    {submitMutation.isPending ? 'Submitting...' : 'Submit for Approval'}
                  </Button>
                )}

                {charge.status === 'PENDING' && isAdmin() && (
                  <>
                    <Button
                      onClick={() => approveMutation.mutate()}
                      disabled={approveMutation.isPending}
                      variant="default"
                      aria-label="Approve charge"
                    >
                      <CheckCircle className="w-4 h-4 mr-2" />
                      {approveMutation.isPending ? 'Approving...' : 'Approve'}
                    </Button>
                    <Button
                      onClick={() => setRejectModalOpen(true)}
                      disabled={rejectMutation.isPending}
                      variant="destructive"
                      aria-label="Reject charge"
                    >
                      <XCircle className="w-4 h-4 mr-2" />
                      Reject
                    </Button>
                  </>
                )}

                {charge.status === 'APPROVED' && isAdmin() && (
                  <Button
                    onClick={() => setMarkPaidModalOpen(true)}
                    disabled={markPaidMutation.isPending}
                    aria-label="Mark charge as paid"
                  >
                    <Receipt className="w-4 h-4 mr-2" />
                    Mark as Paid
                  </Button>
                )}

                {charge.status === 'PAID' && (
                  <div className="flex items-center gap-2 text-sm text-muted-foreground">
                    <CheckCircle className="w-4 h-4 text-green-600" />
                    <span>This charge has been paid and cannot be modified.</span>
                  </div>
                )}

                {charge.status === 'REJECTED' && (
                  <div className="flex items-center gap-2 text-sm text-muted-foreground">
                    <XCircle className="w-4 h-4 text-destructive" />
                    <span>This charge was rejected and cannot be resubmitted.</span>
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
                  {charge.audit_trail?.length > 0 ? (
                    charge.audit_trail.map((event, idx) => (
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
                        {idx < charge.audit_trail.length - 1 && <Separator className="mt-4" />}
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
        onConfirm={(paymentRef, paidAt) => markPaidMutation.mutate({ paymentRef, paidAt })}
        isPending={markPaidMutation.isPending}
      />
    </SidebarProvider>
  );
}
