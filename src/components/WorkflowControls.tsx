import { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Textarea } from '@/components/ui/textarea';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { CheckCircle, XCircle, Clock, Lock, AlertTriangle } from 'lucide-react';
import { WorkflowEngine, WorkflowApproval } from '@/lib/workflowEngine';
import { useToast } from '@/hooks/use-toast';

export function WorkflowControls() {
  const [pendingApprovals, setPendingApprovals] = useState<WorkflowApproval[]>([]);
  const [selectedApproval, setSelectedApproval] = useState<WorkflowApproval | null>(null);
  const [rejectionReason, setRejectionReason] = useState('');
  const [loading, setLoading] = useState(false);
  const [showRejectDialog, setShowRejectDialog] = useState(false);
  const { toast } = useToast();

  useEffect(() => {
    loadPendingApprovals();
  }, []);

  const loadPendingApprovals = async () => {
    setLoading(true);
    try {
      // Mock user ID - in real app this would come from auth
      const userId = 'current-user-id';
      const approvals = await WorkflowEngine.getPendingApprovals(userId);
      setPendingApprovals(approvals);
    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to load pending approvals",
        variant: "destructive"
      });
    } finally {
      setLoading(false);
    }
  };

  const handleApprove = async (approvalId: string, isFirstApprover: boolean = true) => {
    setLoading(true);
    try {
      const userId = 'current-user-id'; // Mock user ID
      const result = await WorkflowEngine.approveWorkflowItem(approvalId, userId, isFirstApprover);
      
      if (result.success) {
        toast({
          title: "Success",
          description: result.executed ? "Item approved and executed" : "Item approved (awaiting second approval)"
        });
        loadPendingApprovals();
      } else {
        toast({
          title: "Error",
          description: result.error || "Failed to approve item",
          variant: "destructive"
        });
      }
    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to approve item",
        variant: "destructive"
      });
    } finally {
      setLoading(false);
    }
  };

  const handleReject = async () => {
    if (!selectedApproval || !rejectionReason.trim()) return;
    
    setLoading(true);
    try {
      const userId = 'current-user-id'; // Mock user ID
      const result = await WorkflowEngine.rejectWorkflowItem(
        selectedApproval.id,
        userId,
        rejectionReason
      );
      
      if (result.success) {
        toast({
          title: "Success",
          description: "Item rejected successfully"
        });
        setShowRejectDialog(false);
        setRejectionReason('');
        setSelectedApproval(null);
        loadPendingApprovals();
      } else {
        toast({
          title: "Error",
          description: result.error || "Failed to reject item",
          variant: "destructive"
        });
      }
    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to reject item",
        variant: "destructive"
      });
    } finally {
      setLoading(false);
    }
  };

  const handleLockRun = async (calculationRunId: string) => {
    setLoading(true);
    try {
      const userId = 'current-user-id'; // Mock user ID
      const result = await WorkflowEngine.lockCalculationRun(calculationRunId, userId);
      
      if (result.success) {
        toast({
          title: "Success",
          description: "Calculation run locked successfully"
        });
        loadPendingApprovals();
      } else {
        toast({
          title: "Error",
          description: result.error || "Failed to lock calculation run",
          variant: "destructive"
        });
      }
    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to lock calculation run",
        variant: "destructive"
      });
    } finally {
      setLoading(false);
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'pending_approval':
        return <Clock className="h-4 w-4 text-yellow-500" />;
      case 'approved':
        return <CheckCircle className="h-4 w-4 text-green-500" />;
      case 'rejected':
        return <XCircle className="h-4 w-4 text-red-500" />;
      case 'locked':
        return <Lock className="h-4 w-4 text-blue-500" />;
      default:
        return <AlertTriangle className="h-4 w-4 text-gray-500" />;
    }
  };

  const formatEntityType = (entityType: string) => {
    return entityType.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase());
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Workflow Management</h1>
        <p className="text-muted-foreground">
          Manage approvals, review pending items, and control calculation run states.
        </p>
      </div>

      <Tabs defaultValue="pending" className="space-y-4">
        <TabsList>
          <TabsTrigger value="pending">Pending Approvals</TabsTrigger>
          <TabsTrigger value="history">Approval History</TabsTrigger>
          <TabsTrigger value="settings">Workflow Settings</TabsTrigger>
        </TabsList>

        <TabsContent value="pending" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Pending Approvals</CardTitle>
              <CardDescription>
                Items requiring your approval or review
              </CardDescription>
            </CardHeader>
            <CardContent>
              {loading ? (
                <div className="text-center py-4">Loading...</div>
              ) : pendingApprovals.length === 0 ? (
                <div className="text-center py-8 text-muted-foreground">
                  No pending approvals found
                </div>
              ) : (
                <div className="space-y-4">
                  {pendingApprovals.map((approval) => (
                    <div
                      key={approval.id}
                      className="flex items-center justify-between p-4 border rounded-lg"
                    >
                      <div className="flex items-center space-x-4">
                        {getStatusIcon(approval.status)}
                        <div>
                          <div className="font-medium">
                            {formatEntityType(approval.entity_type)} - {approval.approval_type}
                          </div>
                          <div className="text-sm text-muted-foreground">
                            Requested: {new Date(approval.requested_at).toLocaleDateString()}
                          </div>
                          {approval.requires_two_person_approval && (
                            <Badge variant="outline" className="mt-1">
                              Two-Person Approval Required
                            </Badge>
                          )}
                        </div>
                      </div>
                      
                      <div className="flex items-center space-x-2">
                        <Badge variant="secondary">
                          {approval.status.replace('_', ' ')}
                        </Badge>
                        
                        {approval.status === 'pending_approval' && (
                          <div className="flex space-x-2">
                            <Button
                              size="sm"
                              onClick={() => handleApprove(approval.id, !approval.first_approver)}
                              disabled={loading}
                            >
                              Approve
                            </Button>
                            <Button
                              size="sm"
                              variant="outline"
                              onClick={() => {
                                setSelectedApproval(approval);
                                setShowRejectDialog(true);
                              }}
                              disabled={loading}
                            >
                              Reject
                            </Button>
                          </div>
                        )}
                        
                        {approval.status === 'approved' && approval.entity_type === 'calculation_run' && (
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => handleLockRun(approval.entity_id)}
                            disabled={loading}
                          >
                            <Lock className="h-4 w-4 mr-2" />
                            Lock Run
                          </Button>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="history" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Approval History</CardTitle>
              <CardDescription>
                View completed approvals and workflow activities
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="text-center py-8 text-muted-foreground">
                Approval history will be displayed here
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="settings" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Workflow Settings</CardTitle>
              <CardDescription>
                Configure approval rules and workflow parameters
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Alert>
                <AlertTriangle className="h-4 w-4" />
                <AlertDescription>
                  Workflow settings are configured at the system level. Contact your administrator to modify approval rules.
                </AlertDescription>
              </Alert>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* Rejection Dialog */}
      <Dialog open={showRejectDialog} onOpenChange={setShowRejectDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Reject Approval</DialogTitle>
            <DialogDescription>
              Please provide a reason for rejecting this approval request.
            </DialogDescription>
          </DialogHeader>
          <div className="py-4">
            <Textarea
              placeholder="Enter rejection reason..."
              value={rejectionReason}
              onChange={(e) => setRejectionReason(e.target.value)}
              rows={4}
            />
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowRejectDialog(false)}>
              Cancel
            </Button>
            <Button 
              variant="destructive" 
              onClick={handleReject}
              disabled={!rejectionReason.trim() || loading}
            >
              Reject
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}