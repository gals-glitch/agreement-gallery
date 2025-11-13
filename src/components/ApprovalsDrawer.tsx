import React from 'react';
import { Button } from '@/components/ui/button';
import { Sheet, SheetContent, SheetHeader, SheetTitle } from '@/components/ui/sheet';
import { Badge } from '@/components/ui/badge';
import { CheckCircle, Clock, AlertCircle, FileText } from 'lucide-react';
import { FeeRun } from '@/types/runs';
import { useToast } from '@/hooks/use-toast';

interface ApprovalsDrawerProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  run: FeeRun | null;
  onApprovalChange?: () => void;
}

export function ApprovalsDrawer({ open, onOpenChange, run, onApprovalChange }: ApprovalsDrawerProps) {
  const { toast } = useToast();

  const handleApprove = async (stage: 'reviewed' | 'approved') => {
    if (!run) return;

    try {
      const response = await fetch(`https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/fee-runs-api/${run.id}/approve`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${localStorage.getItem('supabase.auth.token')}`,
        },
        body: JSON.stringify({ stage }),
      });

      if (!response.ok) throw new Error('Failed to approve run');

      toast({
        title: stage === 'reviewed' ? 'Run Reviewed' : 'Run Approved',
        description: `Run ${run.id.slice(0, 8)} has been ${stage}.`,
      });

      onApprovalChange?.();
    } catch (error) {
      toast({
        title: 'Error',
        description: `Failed to ${stage === 'reviewed' ? 'review' : 'approve'} run.`,
        variant: 'destructive',
      });
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'approved': return <CheckCircle className="h-4 w-4 text-green-500" />;
      case 'reviewed': return <CheckCircle className="h-4 w-4 text-blue-500" />;
      case 'draft': return <Clock className="h-4 w-4 text-yellow-500" />;
      case 'failed': return <AlertCircle className="h-4 w-4 text-red-500" />;
      default: return <Clock className="h-4 w-4 text-gray-500" />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'approved': return 'bg-green-100 text-green-800';
      case 'reviewed': return 'bg-blue-100 text-blue-800';
      case 'draft': return 'bg-yellow-100 text-yellow-800';
      case 'failed': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const canReview = run?.status === 'draft';
  const canApprove = run?.status === 'reviewed';

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent className="w-[400px] sm:w-[540px]">
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
            <Badge className={getStatusColor(run?.status || 'draft')}>
              <span className="flex items-center gap-1">
                {getStatusIcon(run?.status || 'draft')}
                {run?.status?.toUpperCase() || 'DRAFT'}
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

          {/* Approval Timeline */}
          <div className="space-y-4">
            <div className="text-sm font-medium">Approval Timeline</div>
            
            <div className="space-y-3">
              {/* Draft Stage */}
              <div className="flex items-center gap-3">
                <div className="flex h-8 w-8 items-center justify-center rounded-full bg-green-100">
                  <CheckCircle className="h-4 w-4 text-green-600" />
                </div>
                <div className="flex-1">
                  <div className="text-sm font-medium">Draft Created</div>
                  <div className="text-xs text-muted-foreground">
                    {run?.created_at ? new Date(run.created_at).toLocaleString() : 'N/A'}
                  </div>
                </div>
              </div>

              {/* Review Stage */}
              <div className="flex items-center gap-3">
                <div className={`flex h-8 w-8 items-center justify-center rounded-full ${
                  run?.status === 'reviewed' || run?.status === 'approved' 
                    ? 'bg-blue-100' 
                    : 'bg-gray-100'
                }`}>
                  {run?.status === 'reviewed' || run?.status === 'approved' ? (
                    <CheckCircle className="h-4 w-4 text-blue-600" />
                  ) : (
                    <Clock className="h-4 w-4 text-gray-400" />
                  )}
                </div>
                <div className="flex-1">
                  <div className="text-sm font-medium">Finance Review (Miri)</div>
                  <div className="text-xs text-muted-foreground">
                    {run?.status === 'reviewed' || run?.status === 'approved' 
                      ? 'Reviewed' 
                      : 'Pending review'}
                  </div>
                </div>
              </div>

              {/* Approval Stage */}
              <div className="flex items-center gap-3">
                <div className={`flex h-8 w-8 items-center justify-center rounded-full ${
                  run?.status === 'approved' 
                    ? 'bg-green-100' 
                    : 'bg-gray-100'
                }`}>
                  {run?.status === 'approved' ? (
                    <CheckCircle className="h-4 w-4 text-green-600" />
                  ) : (
                    <Clock className="h-4 w-4 text-gray-400" />
                  )}
                </div>
                <div className="flex-1">
                  <div className="text-sm font-medium">Final Approval (Rivka)</div>
                  <div className="text-xs text-muted-foreground">
                    {run?.status === 'approved' 
                      ? 'Approved for export' 
                      : 'Pending approval'}
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="space-y-3 pt-4 border-t">
            {canReview && (
              <Button 
                onClick={() => handleApprove('reviewed')}
                className="w-full"
                variant="outline"
              >
                Mark as Reviewed (Finance)
              </Button>
            )}
            
            {canApprove && (
              <Button 
                onClick={() => handleApprove('approved')}
                className="w-full"
              >
                Final Approval (Export Ready)
              </Button>
            )}

            {run?.status === 'approved' && (
              <div className="text-center p-3 bg-green-50 rounded-lg">
                <CheckCircle className="h-5 w-5 text-green-600 mx-auto mb-1" />
                <div className="text-sm font-medium text-green-800">
                  Approved for Export
                </div>
                <div className="text-xs text-green-600">
                  This run can now be exported from Export Center
                </div>
              </div>
            )}
          </div>
        </div>
      </SheetContent>
    </Sheet>
  );
}