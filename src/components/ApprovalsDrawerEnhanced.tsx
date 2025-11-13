/**
 * Enhanced Approvals Drawer
 * Feature: FEATURE_APPROVALS
 * Integrates with approvals-api Edge Function for multi-step workflow
 */

import React, { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Sheet, SheetContent, SheetHeader, SheetTitle } from '@/components/ui/sheet';
import { Badge } from '@/components/ui/badge';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import { Separator } from '@/components/ui/separator';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { CheckCircle, Clock, AlertCircle, FileText, XCircle, Send, ThumbsUp, ThumbsDown, Info } from 'lucide-react';
import { FeeRun } from '@/types/runs';
import { useToast } from '@/hooks/use-toast';
import {
  submitRunForApproval,
  approveStep,
  rejectStep,
  getApprovalStatus,
  canUserApproveStep,
  getStepDisplayName,
  getStepIcon,
  type ApprovalStep
} from '@/api/approvalsClient';
import { useFeatureFlag } from '@/lib/featureFlags';

interface ApprovalsDrawerEnhancedProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  run: FeeRun | null;
  onApprovalChange?: () => void;
}

export function ApprovalsDrawerEnhanced({ open, onOpenChange, run, onApprovalChange }: ApprovalsDrawerEnhancedProps) {
  const { toast } = useToast();
  const approvalsEnabled = useFeatureFlag('FEATURE_APPROVALS');

  const [approvals, setApprovals] = useState<ApprovalStep[]>([]);
  const [loading, setLoading] = useState(false);
  const [comment, setComment] = useState('');
  const [actioningStep, setActioningStep] = useState<string | null>(null);

  // Load approval status when drawer opens
  useEffect(() => {
    if (open && run && approvalsEnabled) {
      loadApprovalStatus();
    }
  }, [open, run?.id, approvalsEnabled]);

  const loadApprovalStatus = async () => {
    if (!run) return;

    try {
      const status = await getApprovalStatus(run.id);
      setApprovals(status.approvals);
    } catch (error) {
      console.error('Failed to load approval status:', error);
    }
  };

  const handleSubmit = async () => {
    if (!run) return;

    setLoading(true);
    try {
      await submitRunForApproval(run.id);

      toast({
        title: 'Submitted for Approval',
        description: 'Run has been submitted to the approval workflow.',
      });

      await loadApprovalStatus();
      onApprovalChange?.();
    } catch (error: any) {
      toast({
        title: 'Submission Failed',
        description: error.message || 'Failed to submit run for approval.',
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
    }
  };

  const handleApprove = async (step: ApprovalStep) => {
    if (!run) return;

    // Check permission
    const canApprove = await canUserApproveStep(step);
    if (!canApprove) {
      toast({
        title: 'Permission Denied',
        description: `You need ${step.approver_role} role to approve this step.`,
        variant: 'destructive',
      });
      return;
    }

    setActioningStep(step.step);
    try {
      await approveStep(run.id, step.step, comment || undefined);

      toast({
        title: 'Step Approved',
        description: `${getStepDisplayName(step.step)} has been approved.`,
      });

      setComment('');
      await loadApprovalStatus();
      onApprovalChange?.();
    } catch (error: any) {
      toast({
        title: 'Approval Failed',
        description: error.message || 'Failed to approve step.',
        variant: 'destructive',
      });
    } finally {
      setActioningStep(null);
    }
  };

  const handleReject = async (step: ApprovalStep) => {
    if (!run) return;

    if (!comment.trim()) {
      toast({
        title: 'Comment Required',
        description: 'Please provide a reason for rejection.',
        variant: 'destructive',
      });
      return;
    }

    // Check permission
    const canApprove = await canUserApproveStep(step);
    if (!canApprove) {
      toast({
        title: 'Permission Denied',
        description: `You need ${step.approver_role} role to reject this step.`,
        variant: 'destructive',
      });
      return;
    }

    setActioningStep(step.step);
    try {
      await rejectStep(run.id, step.step, comment);

      toast({
        title: 'Step Rejected',
        description: 'Run has been returned to In Progress status.',
        variant: 'destructive',
      });

      setComment('');
      await loadApprovalStatus();
      onApprovalChange?.();
    } catch (error: any) {
      toast({
        title: 'Rejection Failed',
        description: error.message || 'Failed to reject step.',
        variant: 'destructive',
      });
    } finally {
      setActioningStep(null);
    }
  };

  const getStatusBadgeVariant = (status: string) => {
    switch (status) {
      case 'approved': return 'default';
      case 'awaiting_approval': return 'secondary';
      case 'in_progress': return 'outline';
      case 'draft': return 'outline';
      default: return 'secondary';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'approved': return <CheckCircle className="h-4 w-4 text-green-500" />;
      case 'awaiting_approval': return <Clock className="h-4 w-4 text-yellow-500" />;
      case 'in_progress': return <Clock className="h-4 w-4 text-blue-500" />;
      case 'draft': return <FileText className="h-4 w-4 text-gray-500" />;
      case 'failed': return <AlertCircle className="h-4 w-4 text-red-500" />;
      default: return <Clock className="h-4 w-4 text-gray-500" />;
    }
  };

  const canSubmit = run && ['draft', 'in_progress', 'completed'].includes(run.status) && approvals.length === 0;
  const isAwaitingApproval = run?.status === 'awaiting_approval';
  const isApproved = run?.status === 'approved';

  // Feature flag check
  if (!approvalsEnabled) {
    return null;
  }

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent className="w-[400px] sm:w-[540px] overflow-y-auto">
        <SheetHeader>
          <SheetTitle className="flex items-center gap-2">
            <FileText className="h-5 w-5" />
            Approval Workflow
          </SheetTitle>
        </SheetHeader>

        <div className="mt-6 space-y-6">
          {/* Current Status */}
          <div className="flex items-center justify-between">
            <span className="text-sm font-medium">Current Status</span>
            <Badge variant={getStatusBadgeVariant(run?.status || 'draft')}>
              <span className="flex items-center gap-1">
                {getStatusIcon(run?.status || 'draft')}
                {run?.status?.replace('_', ' ').toUpperCase() || 'DRAFT'}
              </span>
            </Badge>
          </div>

          {/* Run Summary */}
          {run && (
            <div className="rounded-lg border p-4 space-y-2">
              <div className="text-sm font-medium">Run Summary</div>
              <div className="grid grid-cols-2 gap-2 text-sm">
                <span className="text-muted-foreground">Period:</span>
                <span>{run.period_start} to {run.period_end}</span>
                <span className="text-muted-foreground">Total Fees:</span>
                <span>${run.totals?.total?.toLocaleString() || '0'}</span>
                <span className="text-muted-foreground">Exceptions:</span>
                <span className={run.exceptions_count === 0 ? 'text-green-600' : 'text-red-600'}>
                  {run.exceptions_count || 0}
                </span>
              </div>
            </div>
          )}

          {/* Submit for Approval Button */}
          {canSubmit && (
            <Alert>
              <Info className="h-4 w-4" />
              <AlertDescription>
                This run is ready for approval. Submit it to start the approval workflow.
              </AlertDescription>
            </Alert>
          )}

          {canSubmit && (
            <Button
              onClick={handleSubmit}
              disabled={loading}
              className="w-full gap-2"
            >
              <Send className="h-4 w-4" />
              Submit for Approval
            </Button>
          )}

          {/* Approval Steps */}
          {approvals.length > 0 && (
            <>
              <Separator />

              <div className="space-y-4">
                <div className="text-sm font-medium">Approval Steps</div>

                {approvals.map((approval, index) => (
                  <div key={approval.id} className="space-y-3">
                    <div className="flex items-start gap-3">
                      <div className={`flex h-8 w-8 items-center justify-center rounded-full flex-shrink-0 ${
                        approval.status === 'approved'
                          ? 'bg-green-100'
                          : approval.status === 'rejected'
                          ? 'bg-red-100'
                          : 'bg-gray-100'
                      }`}>
                        {approval.status === 'approved' ? (
                          <CheckCircle className="h-4 w-4 text-green-600" />
                        ) : approval.status === 'rejected' ? (
                          <XCircle className="h-4 w-4 text-red-600" />
                        ) : (
                          <Clock className="h-4 w-4 text-gray-400" />
                        )}
                      </div>

                      <div className="flex-1 min-w-0">
                        <div className="flex items-center justify-between gap-2">
                          <div>
                            <div className="text-sm font-medium">
                              {getStepDisplayName(approval.step)}
                            </div>
                            <div className="text-xs text-muted-foreground">
                              Role: {approval.approver_role}
                            </div>
                          </div>
                          <Badge variant={approval.status === 'approved' ? 'default' : approval.status === 'rejected' ? 'destructive' : 'secondary'}>
                            {approval.status}
                          </Badge>
                        </div>

                        {approval.acted_by_user && (
                          <div className="text-xs text-muted-foreground mt-1">
                            {approval.status === 'approved' ? 'Approved' : 'Rejected'} by {approval.acted_by_user.email}
                            {approval.acted_at && ` on ${new Date(approval.acted_at).toLocaleString()}`}
                          </div>
                        )}

                        {approval.comment && (
                          <div className="mt-2 text-xs p-2 bg-muted rounded">
                            <span className="font-medium">Comment:</span> {approval.comment}
                          </div>
                        )}

                        {/* Action Buttons for Pending Steps */}
                        {approval.status === 'pending' && (
                          <div className="mt-3 space-y-2">
                            <Label htmlFor={`comment-${approval.id}`} className="text-xs">
                              Comment (optional for approve, required for reject)
                            </Label>
                            <Textarea
                              id={`comment-${approval.id}`}
                              placeholder="Add a comment..."
                              value={comment}
                              onChange={(e) => setComment(e.target.value)}
                              rows={2}
                              className="text-sm"
                            />

                            <div className="flex gap-2">
                              <Button
                                onClick={() => handleApprove(approval)}
                                disabled={actioningStep === approval.step}
                                size="sm"
                                variant="default"
                                className="flex-1 gap-1"
                              >
                                <ThumbsUp className="h-3 w-3" />
                                Approve
                              </Button>
                              <Button
                                onClick={() => handleReject(approval)}
                                disabled={actioningStep === approval.step}
                                size="sm"
                                variant="destructive"
                                className="flex-1 gap-1"
                              >
                                <ThumbsDown className="h-3 w-3" />
                                Reject
                              </Button>
                            </div>
                          </div>
                        )}
                      </div>
                    </div>

                    {index < approvals.length - 1 && <Separator />}
                  </div>
                ))}
              </div>
            </>
          )}

          {/* Approved Status */}
          {isApproved && (
            <>
              <Separator />
              <div className="text-center p-4 bg-green-50 rounded-lg">
                <CheckCircle className="h-6 w-6 text-green-600 mx-auto mb-2" />
                <div className="text-sm font-medium text-green-800">
                  Approved for Export
                </div>
                <div className="text-xs text-green-600 mt-1">
                  This run can now generate invoices and be exported
                </div>
              </div>
            </>
          )}
        </div>
      </SheetContent>
    </Sheet>
  );
}
