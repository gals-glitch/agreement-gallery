/**
 * RunHeader - Workflow actions and status display for calculation runs
 * Supports: Submit, Approve, Reject (with comment), Generate
 */

import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogDescription } from '@/components/ui/dialog';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import { runsAPI } from '@/api/clientV2';
import { useToast } from '@/hooks/use-toast';
import { statusLabel, statusVariant, canSubmit, canApprove, canReject, canGenerate, type RunStatus } from '@/lib/runWorkflow';
import { Loader2, CheckCircle, Send, XCircle, Play } from 'lucide-react';

interface RunHeaderProps {
  run: {
    id: number;
    status: RunStatus;
    period_from: string;
    period_to: string;
  };
  hasApprovalRole: boolean;
  onChanged: () => void; // Refetch run data
}

export default function RunHeader({ run, hasApprovalRole, onChanged }: RunHeaderProps) {
  const [rejectOpen, setRejectOpen] = useState(false);
  const [comment, setComment] = useState('');
  const [loading, setLoading] = useState(false);
  const { toast } = useToast();

  /**
   * Safe action wrapper with loading state and error handling
   */
  const safe = async (fn: () => Promise<any>, okMsg: string) => {
    try {
      setLoading(true);
      await fn();
      toast({
        title: 'Success',
        description: okMsg,
      });
      onChanged();
    } catch (e: any) {
      // Error toast already handled by http wrapper
      console.error('Action failed:', e);
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = () => {
    safe(() => runsAPI.submit(run.id), 'Run submitted for approval');
  };

  const handleApprove = () => {
    safe(() => runsAPI.approve(run.id, {}), 'Run approved successfully');
  };

  const handleReject = () => {
    if (!comment.trim()) return;

    safe(
      () => runsAPI.reject(run.id, comment.trim()),
      'Run rejected and returned to draft'
    ).then(() => {
      setRejectOpen(false);
      setComment('');
    });
  };

  const handleGenerate = async () => {
    try {
      setLoading(true);
      const res = await runsAPI.generate(run.id);

      toast({
        title: 'Generation Complete',
        description: 'Calculation results generated successfully',
      });

      // If API returns export URL/handle, you can surface it here:
      // Example: window.open(res.export_url, '_blank');
      // Or show a download link in a dialog

      console.log('Generate response:', res);
      onChanged();
    } catch (e: any) {
      // Error toast already handled by http wrapper
      console.error('Generation failed:', e);
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      <div className="flex items-center justify-between gap-3 p-4 bg-card border rounded-lg">
        <div className="flex items-center gap-3">
          <h2 className="text-xl font-semibold">Run #{run.id}</h2>
          <Badge variant={statusVariant[run.status]}>
            {statusLabel[run.status]}
          </Badge>
          <span className="text-sm text-muted-foreground">
            {run.period_from} → {run.period_to}
          </span>
        </div>

        <div className="flex items-center gap-2">
          <Button
            variant="secondary"
            size="sm"
            disabled={!canSubmit(run.status) || loading}
            onClick={handleSubmit}
            title={canSubmit(run.status) ? 'Submit run for approval' : 'Cannot submit in current state'}
          >
            {loading ? <Loader2 className="w-4 h-4 mr-2 animate-spin" /> : <Send className="w-4 h-4 mr-2" />}
            Submit
          </Button>

          <Button
            variant="default"
            size="sm"
            disabled={!hasApprovalRole || !canApprove(run.status) || loading}
            onClick={handleApprove}
            title={
              !hasApprovalRole
                ? 'Requires Finance/Admin role'
                : !canApprove(run.status)
                ? 'Run must be awaiting approval'
                : 'Approve run'
            }
          >
            {loading ? <Loader2 className="w-4 h-4 mr-2 animate-spin" /> : <CheckCircle className="w-4 h-4 mr-2" />}
            Approve
          </Button>

          <Button
            variant="destructive"
            size="sm"
            disabled={!hasApprovalRole || !canReject(run.status) || loading}
            onClick={() => setRejectOpen(true)}
            title={
              !hasApprovalRole
                ? 'Requires Finance/Admin role'
                : !canReject(run.status)
                ? 'Run must be awaiting approval'
                : 'Reject run with comment'
            }
          >
            <XCircle className="w-4 h-4 mr-2" />
            Reject
          </Button>

          <Button
            variant="default"
            size="sm"
            className="bg-green-600 hover:bg-green-700"
            disabled={!canGenerate(run.status) || loading}
            onClick={handleGenerate}
            title={
              !canGenerate(run.status)
                ? 'Only enabled after approval'
                : 'Generate final calculations'
            }
          >
            {loading ? <Loader2 className="w-4 h-4 mr-2 animate-spin" /> : <Play className="w-4 h-4 mr-2" />}
            Generate
          </Button>
        </div>
      </div>

      {/* Reject Dialog */}
      <Dialog open={rejectOpen} onOpenChange={setRejectOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Reject Run</DialogTitle>
            <DialogDescription>
              Provide a reason for rejecting this calculation run. The run will return to draft status.
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-2">
            <Label htmlFor="reject-comment">Comment (Required)</Label>
            <Textarea
              id="reject-comment"
              placeholder="Add a short reviewer comment explaining why this run is being rejected..."
              value={comment}
              onChange={(e) => setComment(e.target.value)}
              rows={4}
            />
          </div>

          <DialogFooter>
            <Button variant="ghost" onClick={() => setRejectOpen(false)}>
              Cancel
            </Button>
            <Button
              variant="destructive"
              disabled={!comment.trim() || loading}
              onClick={handleReject}
            >
              {loading && <Loader2 className="w-4 h-4 mr-2 animate-spin" />}
              Reject Run
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
