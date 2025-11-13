import { supabase } from '@/integrations/supabase/client';

export interface WorkflowApproval {
  id: string;
  entityType: 'rule' | 'calculation_run' | 'discount';
  entityId: string;
  approvalType: 'create' | 'update' | 'delete';
  status: 'pending' | 'approved' | 'rejected';
  requestedBy?: string;
  approvedBy?: string;
  rejectionReason?: string;
  requiresTwoPersonApproval: boolean;
  firstApprover?: string;
  secondApprover?: string;
  requestedAt: string;
  approvedAt?: string;
  entityData: any;
}

export interface ActivityLogEntry {
  id: string;
  entityType: string;
  entityId: string;
  action: 'create' | 'update' | 'delete' | 'approve' | 'reject';
  description: string;
  oldValues?: any;
  newValues?: any;
  performedBy?: string;
  performedAt: string;
}

export class WorkflowManager {
  
  /**
   * Submit entity for approval (Maker part of Maker/Checker workflow)
   */
  static async submitForApproval(
    entityType: WorkflowApproval['entityType'],
    entityId: string,
    approvalType: WorkflowApproval['approvalType'],
    entityData: any,
    requiresTwoPersonApproval: boolean = false,
    requestedBy?: string
  ): Promise<{ success: boolean; approvalId?: string; error?: string }> {
    try {
      const { data, error } = await supabase
        .from('workflow_approvals')
        .insert({
          entity_type: entityType,
          entity_id: entityId,
          approval_type: approvalType,
          entity_data: entityData,
          requires_two_person_approval: requiresTwoPersonApproval,
          requested_by: requestedBy,
          status: 'pending'
        })
        .select()
        .single();

      if (error) {
        return { success: false, error: error.message };
      }

      // Log the submission
      await this.logActivity({
        entityType,
        entityId,
        action: 'create',
        description: `Submitted ${entityType} for ${approvalType} approval`,
        newValues: entityData,
        performedBy: requestedBy
      });

      return { success: true, approvalId: data.id };
    } catch (error) {
      return { 
        success: false, 
        error: error instanceof Error ? error.message : 'Unknown error' 
      };
    }
  }

  /**
   * Approve an entity (Checker part of Maker/Checker workflow)
   */
  static async approveEntity(
    approvalId: string,
    approverId: string,
    isFirstApprover: boolean = true
  ): Promise<{ success: boolean; requiresSecondApproval?: boolean; error?: string }> {
    try {
      // Get the approval record
      const { data: approval, error: fetchError } = await supabase
        .from('workflow_approvals')
        .select('*')
        .eq('id', approvalId)
        .single();

      if (fetchError || !approval) {
        return { success: false, error: 'Approval record not found' };
      }

      if (approval.status !== 'pending') {
        return { success: false, error: 'Approval already processed' };
      }

      let updateData: any = {};

      if (approval.requires_two_person_approval) {
        if (isFirstApprover) {
          updateData = {
            first_approver: approverId,
            status: 'pending' // Still pending second approval
          };

          await this.logActivity({
            entityType: approval.entity_type,
            entityId: approval.entity_id,
            action: 'approve',
            description: `First approval granted for ${approval.entity_type} ${approval.approval_type}`,
            performedBy: approverId
          });

          return { success: true, requiresSecondApproval: true };
        } else {
          // Second approver
          updateData = {
            second_approver: approverId,
            approved_by: approverId,
            approved_at: new Date().toISOString(),
            status: 'approved'
          };
        }
      } else {
        // Single approval required
        updateData = {
          approved_by: approverId,
          approved_at: new Date().toISOString(),
          status: 'approved'
        };
      }

      // Update approval record
      const { error: updateError } = await supabase
        .from('workflow_approvals')
        .update(updateData)
        .eq('id', approvalId);

      if (updateError) {
        return { success: false, error: updateError.message };
      }

      // If fully approved, execute the actual entity operation
      if (updateData.status === 'approved') {
        await this.executeApprovedAction({
          ...approval,
          entityType: approval.entity_type as WorkflowApproval['entityType'],
          entityId: approval.entity_id,
          approvalType: approval.approval_type as WorkflowApproval['approvalType'],
          requiresTwoPersonApproval: approval.requires_two_person_approval,
          requestedAt: approval.requested_at,
          entityData: approval.entity_data
        } as WorkflowApproval);

        await this.logActivity({
          entityType: approval.entity_type,
          entityId: approval.entity_id,
          action: 'approve',
          description: `${approval.entity_type} ${approval.approval_type} approved and executed`,
          newValues: approval.entity_data,
          performedBy: approverId
        });
      }

      return { success: true, requiresSecondApproval: false };
    } catch (error) {
      return { 
        success: false, 
        error: error instanceof Error ? error.message : 'Unknown error' 
      };
    }
  }

  /**
   * Reject an entity approval
   */
  static async rejectEntity(
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
        return { success: false, error: 'Approval record not found' };
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

      await this.logActivity({
        entityType: approval.entity_type,
        entityId: approval.entity_id,
        action: 'reject',
        description: `${approval.entity_type} ${approval.approval_type} rejected: ${rejectionReason}`,
        performedBy: rejectorId
      });

      return { success: true };
    } catch (error) {
      return { 
        success: false, 
        error: error instanceof Error ? error.message : 'Unknown error' 
      };
    }
  }

  /**
   * Execute the approved action on the actual entity
   */
  private static async executeApprovedAction(approval: WorkflowApproval): Promise<void> {
    try {
      switch (approval.entityType) {
        case 'rule':
          await this.executeRuleAction(approval);
          break;
        case 'calculation_run':
          await this.executeCalculationRunAction(approval);
          break;
        case 'discount':
          await this.executeDiscountAction(approval);
          break;
      }
    } catch (error) {
      console.error('Failed to execute approved action:', error);
      throw error;
    }
  }

  /**
   * Execute rule-related actions
   */
  private static async executeRuleAction(approval: WorkflowApproval): Promise<void> {
    switch (approval.approvalType) {
      case 'create':
        await supabase
          .from('advanced_commission_rules')
          .insert(approval.entityData);
        break;
      case 'update':
        await supabase
          .from('advanced_commission_rules')
          .update(approval.entityData)
          .eq('id', approval.entityId);
        break;
      case 'delete':
        await supabase
          .from('advanced_commission_rules')
          .update({ is_active: false })
          .eq('id', approval.entityId);
        break;
    }
  }

  /**
   * Execute calculation run actions
   */
  private static async executeCalculationRunAction(approval: WorkflowApproval): Promise<void> {
    switch (approval.approvalType) {
      case 'create':
        await supabase
          .from('calculation_runs')
          .insert(approval.entityData);
        break;
      case 'update':
        await supabase
          .from('calculation_runs')
          .update(approval.entityData)
          .eq('id', approval.entityId);
        break;
      case 'delete':
        await supabase
          .from('calculation_runs')
          .update({ status: 'cancelled' })
          .eq('id', approval.entityId);
        break;
    }
  }

  /**
   * Execute discount actions
   */
  private static async executeDiscountAction(approval: WorkflowApproval): Promise<void> {
    switch (approval.approvalType) {
      case 'create':
        await supabase
          .from('discounts')
          .insert(approval.entityData);
        break;
      case 'update':
        await supabase
          .from('discounts')
          .update(approval.entityData)
          .eq('id', approval.entityId);
        break;
      case 'delete':
        await supabase
          .from('discounts')
          .update({ status: 'Expired' })
          .eq('id', approval.entityId);
        break;
    }
  }

  /**
   * Log activity in the activity log
   */
  static async logActivity(activity: Omit<ActivityLogEntry, 'id' | 'performedAt'>): Promise<void> {
    try {
      await supabase
        .from('activity_log')
        .insert({
          entity_type: activity.entityType,
          entity_id: activity.entityId,
          action: activity.action,
          description: activity.description,
          old_values: activity.oldValues,
          new_values: activity.newValues,
          performed_by: activity.performedBy
        });
    } catch (error) {
      console.error('Failed to log activity:', error);
    }
  }

  /**
   * Get pending approvals for a user
   */
  static async getPendingApprovals(userId?: string): Promise<WorkflowApproval[]> {
    try {
      let query = supabase
        .from('workflow_approvals')
        .select('*')
        .eq('status', 'pending')
        .order('requested_at', { ascending: false });

      // In a real implementation, you'd filter by user permissions
      const { data, error } = await query;

      if (error) {
        console.error('Failed to fetch pending approvals:', error);
        return [];
      }

      return (data || []).map(item => ({
        id: item.id,
        entityType: item.entity_type as WorkflowApproval['entityType'],
        entityId: item.entity_id,
        approvalType: item.approval_type as WorkflowApproval['approvalType'],
        status: item.status as WorkflowApproval['status'],
        requestedBy: item.requested_by,
        approvedBy: item.approved_by,
        rejectionReason: item.rejection_reason,
        requiresTwoPersonApproval: item.requires_two_person_approval,
        firstApprover: item.first_approver,
        secondApprover: item.second_approver,
        requestedAt: item.requested_at,
        approvedAt: item.approved_at,
        entityData: item.entity_data
      }));
    } catch (error) {
      console.error('Failed to fetch pending approvals:', error);
      return [];
    }
  }

  /**
   * Get activity history for an entity
   */
  static async getActivityHistory(
    entityType: string,
    entityId: string
  ): Promise<ActivityLogEntry[]> {
    try {
      const { data, error } = await supabase
        .from('activity_log')
        .select('*')
        .eq('entity_type', entityType)
        .eq('entity_id', entityId)
        .order('performed_at', { ascending: false });

      if (error) {
        console.error('Failed to fetch activity history:', error);
        return [];
      }

      return (data || []).map(item => ({
        id: item.id,
        entityType: item.entity_type,
        entityId: item.entity_id,
        action: item.action as ActivityLogEntry['action'],
        description: item.description,
        oldValues: item.old_values,
        newValues: item.new_values,
        performedBy: item.performed_by,
        performedAt: item.performed_at
      }));
    } catch (error) {
      console.error('Failed to fetch activity history:', error);
      return [];
    }
  }

  /**
   * Get rule change history
   */
  static async getRuleChangeHistory(ruleId: string): Promise<ActivityLogEntry[]> {
    return this.getActivityHistory('rule', ruleId);
  }
}