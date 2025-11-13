import { supabase } from '@/integrations/supabase/client';

export type WorkflowStatus = 'draft' | 'pending_approval' | 'approved' | 'rejected' | 'locked';
export type WorkflowAction = 'submit' | 'approve' | 'reject' | 'lock' | 'unlock';
export type EntityType = 'calculation_run' | 'commission_rule' | 'party' | 'discount';

export interface WorkflowTransition {
  from: WorkflowStatus;
  to: WorkflowStatus;
  action: WorkflowAction;
  requiredRole?: string;
  requiresTwoApprovers?: boolean;
}

export interface WorkflowApproval {
  id: string;
  entity_type: EntityType;
  entity_id: string;
  entity_data?: any;
  status: WorkflowStatus;
  requested_by: string;
  requested_at: string;
  first_approver?: string;
  second_approver?: string;
  approved_at?: string;
  rejection_reason?: string;
  requires_two_person_approval: boolean;
  approval_type: string;
}

export interface ApprovalRule {
  entity_type: EntityType;
  action: string;
  requires_approval: boolean;
  requires_two_approvers: boolean;
  min_approval_role: string;
}

export class WorkflowEngine {
  
  private static readonly WORKFLOW_TRANSITIONS: WorkflowTransition[] = [
    { from: 'draft', to: 'pending_approval', action: 'submit' },
    { from: 'pending_approval', to: 'approved', action: 'approve', requiredRole: 'checker' },
    { from: 'pending_approval', to: 'rejected', action: 'reject', requiredRole: 'checker' },
    { from: 'approved', to: 'locked', action: 'lock', requiredRole: 'manager' },
    { from: 'locked', to: 'approved', action: 'unlock', requiredRole: 'admin' }
  ];
  
  private static readonly APPROVAL_RULES: ApprovalRule[] = [
    {
      entity_type: 'calculation_run',
      action: 'execute',
      requires_approval: true,
      requires_two_approvers: true,
      min_approval_role: 'checker'
    },
    {
      entity_type: 'commission_rule',
      action: 'create',
      requires_approval: true,
      requires_two_approvers: false,
      min_approval_role: 'checker'
    },
    {
      entity_type: 'commission_rule',
      action: 'update',
      requires_approval: true,
      requires_two_approvers: true,
      min_approval_role: 'manager'
    },
    {
      entity_type: 'party',
      action: 'create',
      requires_approval: false,
      requires_two_approvers: false,
      min_approval_role: 'maker'
    },
    {
      entity_type: 'discount',
      action: 'create',
      requires_approval: true,
      requires_two_approvers: false,
      min_approval_role: 'checker'
    }
  ];
  
  /**
   * Submit an entity for approval workflow
   */
  static async submitForApproval(
    entityType: EntityType,
    entityId: string,
    action: string,
    entityData: any,
    requestedBy: string
  ): Promise<{ success: boolean; approvalId?: string; error?: string }> {
    try {
      const approvalRule = this.getApprovalRule(entityType, action);
      
      if (!approvalRule.requires_approval) {
        // Execute immediately if no approval required
        return await this.executeAction(entityType, entityId, action, entityData);
      }
      
      const { data: approval, error } = await supabase
        .from('workflow_approvals')
        .insert([{
          entity_type: entityType,
          entity_id: entityId,
          entity_data: entityData,
          status: 'pending_approval',
          requested_by: requestedBy,
          requires_two_person_approval: approvalRule.requires_two_approvers,
          approval_type: action
        }])
        .select()
        .single();
      
      if (error) {
        return { success: false, error: error.message };
      }
      
      // Log the submission
      await this.logWorkflowActivity({
        entity_type: entityType,
        entity_id: entityId,
        action: 'submitted_for_approval',
        performed_by: requestedBy,
        description: `${entityType} submitted for ${action} approval`
      });
      
      return { success: true, approvalId: approval.id };
    } catch (error) {
      return { success: false, error: (error as Error).message };
    }
  }
  
  /**
   * Approve a pending workflow item
   */
  static async approveWorkflowItem(
    approvalId: string,
    approverId: string,
    isFirstApprover: boolean = true
  ): Promise<{ success: boolean; executed?: boolean; error?: string }> {
    try {
      const { data: approval, error: fetchError } = await supabase
        .from('workflow_approvals')
        .select('*')
        .eq('id', approvalId)
        .single();
      
      if (fetchError || !approval) {
        return { success: false, error: 'Approval not found' };
      }
      
      if (approval.status !== 'pending_approval') {
        return { success: false, error: 'Item is not pending approval' };
      }
      
      // Check if user can approve (not the requester)
      if (approval.requested_by === approverId) {
        return { success: false, error: 'Cannot approve your own submission' };
      }
      
      let updateData: any = {};
      let shouldExecute = false;
      
      if (approval.requires_two_person_approval) {
        if (isFirstApprover && !approval.first_approver) {
          updateData = { first_approver: approverId };
        } else if (!isFirstApprover && approval.first_approver && !approval.second_approver) {
          updateData = {
            second_approver: approverId,
            status: 'approved',
            approved_at: new Date().toISOString(),
            approved_by: approverId
          };
          shouldExecute = true;
        } else {
          return { success: false, error: 'Invalid approval state' };
        }
      } else {
        updateData = {
          first_approver: approverId,
          status: 'approved',
          approved_at: new Date().toISOString(),
          approved_by: approverId
        };
        shouldExecute = true;
      }
      
      const { error: updateError } = await supabase
        .from('workflow_approvals')
        .update(updateData)
        .eq('id', approvalId);
      
      if (updateError) {
        return { success: false, error: updateError.message };
      }
      
      // Log the approval
      await this.logWorkflowActivity({
        entity_type: approval.entity_type,
        entity_id: approval.entity_id,
        action: shouldExecute ? 'approved_and_executed' : 'partially_approved',
        performed_by: approverId,
        description: `${approval.entity_type} ${shouldExecute ? 'fully' : 'partially'} approved`
      });
      
      // Execute the action if fully approved
      if (shouldExecute) {
        const executeResult = await this.executeAction(
          approval.entity_type as EntityType,
          approval.entity_id,
          approval.approval_type,
          approval.entity_data
        );
        
        return { success: true, executed: executeResult.success };
      }
      
      return { success: true, executed: false };
    } catch (error) {
      return { success: false, error: (error as Error).message };
    }
  }
  
  /**
   * Reject a pending workflow item
   */
  static async rejectWorkflowItem(
    approvalId: string,
    rejectorId: string,
    rejectionReason: string
  ): Promise<{ success: boolean; error?: string }> {
    try {
      const { data: approval, error: fetchError } = await supabase
        .from('workflow_approvals')
        .select('*')
        .eq('id', approvalId)
        .single();
      
      if (fetchError || !approval) {
        return { success: false, error: 'Approval not found' };
      }
      
      if (approval.status !== 'pending_approval') {
        return { success: false, error: 'Item is not pending approval' };
      }
      
      const { error: updateError } = await supabase
        .from('workflow_approvals')
        .update({
          status: 'rejected',
          approved_by: rejectorId,
          approved_at: new Date().toISOString(),
          rejection_reason: rejectionReason
        })
        .eq('id', approvalId);
      
      if (updateError) {
        return { success: false, error: updateError.message };
      }
      
      // Log the rejection
      await this.logWorkflowActivity({
        entity_type: approval.entity_type,
        entity_id: approval.entity_id,
        action: 'rejected',
        performed_by: rejectorId,
        description: `${approval.entity_type} rejected: ${rejectionReason}`
      });
      
      return { success: true };
    } catch (error) {
      return { success: false, error: (error as Error).message };
    }
  }
  
  /**
   * Lock a calculation run (make it immutable)
   */
  static async lockCalculationRun(
    calculationRunId: string,
    lockerId: string
  ): Promise<{ success: boolean; error?: string }> {
    try {
      // Check if run is approved
      const { data: run, error: fetchError } = await supabase
        .from('calculation_runs')
        .select('status')
        .eq('id', calculationRunId)
        .single();
      
      if (fetchError || !run) {
        return { success: false, error: 'Calculation run not found' };
      }
      
      if (run.status !== 'approved') {
        return { success: false, error: 'Can only lock approved calculation runs' };
      }
      
      const { error: updateError } = await supabase
        .from('calculation_runs')
        .update({ status: 'locked' })
        .eq('id', calculationRunId);
      
      if (updateError) {
        return { success: false, error: updateError.message };
      }
      
      // Log the locking
      await this.logWorkflowActivity({
        entity_type: 'calculation_run',
        entity_id: calculationRunId,
        action: 'locked',
        performed_by: lockerId,
        description: 'Calculation run locked and made immutable'
      });
      
      return { success: true };
    } catch (error) {
      return { success: false, error: (error as Error).message };
    }
  }
  
  /**
   * Get pending approvals for a user (based on their role)
   */
  static async getPendingApprovals(userId: string): Promise<WorkflowApproval[]> {
    const { data, error } = await supabase
      .from('workflow_approvals')
      .select('*')
      .eq('status', 'pending_approval')
      .neq('requested_by', userId); // Don't show user's own submissions
    
    if (error) {
      console.error('Error fetching pending approvals:', error);
      return [];
    }
    
    return (data || []).map(item => ({
      ...item,
      entity_type: item.entity_type as EntityType,
      status: item.status as WorkflowStatus
    }));
  }
  
  /**
   * Get workflow history for an entity
   */
  static async getWorkflowHistory(entityType: EntityType, entityId: string) {
    const { data, error } = await supabase
      .from('activity_log')
      .select('*')
      .eq('entity_type', entityType)
      .eq('entity_id', entityId)
      .order('performed_at', { ascending: false });
    
    if (error) {
      console.error('Error fetching workflow history:', error);
      return [];
    }
    
    return data || [];
  }
  
  // Private helper methods
  private static getApprovalRule(entityType: EntityType, action: string): ApprovalRule {
    return this.APPROVAL_RULES.find(
      rule => rule.entity_type === entityType && rule.action === action
    ) || {
      entity_type: entityType,
      action,
      requires_approval: false,
      requires_two_approvers: false,
      min_approval_role: 'maker'
    };
  }
  
  private static async executeAction(
    entityType: EntityType,
    entityId: string,
    action: string,
    entityData: any
  ): Promise<{ success: boolean; error?: string }> {
    try {
      switch (entityType) {
        case 'calculation_run':
          if (action === 'execute') {
            return await this.executeCalculationRun(entityId, entityData);
          }
          break;
        
        case 'commission_rule':
          if (action === 'create') {
            return await this.createCommissionRule(entityData);
          } else if (action === 'update') {
            return await this.updateCommissionRule(entityId, entityData);
          }
          break;
        
        case 'party':
          if (action === 'create') {
            return await this.createParty(entityData);
          }
          break;
        
        case 'discount':
          if (action === 'create') {
            return await this.createDiscount(entityData);
          }
          break;
      }
      
      return { success: false, error: 'Unknown action type' };
    } catch (error) {
      return { success: false, error: (error as Error).message };
    }
  }
  
  private static async executeCalculationRun(
    calculationRunId: string,
    _entityData: any
  ): Promise<{ success: boolean; error?: string }> {
    // This would trigger the actual calculation engine
    const { error } = await supabase
      .from('calculation_runs')
      .update({ status: 'approved' })
      .eq('id', calculationRunId);
    
    return { success: !error, error: error?.message };
  }
  
  private static async createCommissionRule(entityData: any): Promise<{ success: boolean; error?: string }> {
    const { error } = await supabase
      .from('advanced_commission_rules')
      .insert([entityData]);
    
    return { success: !error, error: error?.message };
  }
  
  private static async updateCommissionRule(
    ruleId: string,
    entityData: any
  ): Promise<{ success: boolean; error?: string }> {
    const { error } = await supabase
      .from('advanced_commission_rules')
      .update(entityData)
      .eq('id', ruleId);
    
    return { success: !error, error: error?.message };
  }
  
  private static async createParty(entityData: any): Promise<{ success: boolean; error?: string }> {
    const { error } = await supabase
      .from('entities')
      .insert([entityData]);
    
    return { success: !error, error: error?.message };
  }
  
  private static async createDiscount(entityData: any): Promise<{ success: boolean; error?: string }> {
    const { error } = await supabase
      .from('discounts')
      .insert([entityData]);
    
    return { success: !error, error: error?.message };
  }
  
  private static async logWorkflowActivity(activity: {
    entity_type: string;
    entity_id: string;
    action: string;
    performed_by: string;
    description: string;
  }) {
    await supabase
      .from('activity_log')
      .insert([activity]);
  }
}