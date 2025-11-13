/**
 * Approvals API Client
 * Feature: FEATURE_APPROVALS
 * Handles workflow approval operations for calculation runs
 */

import { supabase } from '@/integrations/supabase/client';

export interface ApprovalStep {
  id: string;
  run_id: string;
  step: 'ops_review' | 'finance_review' | 'final_approval';
  approver_role: 'ops' | 'finance' | 'manager' | 'admin';
  status: 'pending' | 'approved' | 'rejected';
  comment?: string | null;
  acted_by?: string | null;
  acted_at?: string | null;
  created_at: string;
  acted_by_user?: { email: string };
}

export interface ApprovalStatus {
  run: {
    id: string;
    name: string;
    status: string;
  };
  approvals: ApprovalStep[];
}

const APPROVALS_API_URL = `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/approvals-api`;

/**
 * Submit a run for approval
 * Transitions run from draft/in_progress/completed → awaiting_approval
 */
export async function submitRunForApproval(runId: string): Promise<{ success: boolean; message: string; steps: ApprovalStep[] }> {
  const { data: { session } } = await supabase.auth.getSession();

  if (!session) {
    throw new Error('Not authenticated');
  }

  const response = await fetch(`${APPROVALS_API_URL}/${runId}/submit`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${session.access_token}`,
      'Content-Type': 'application/json',
    },
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.error || 'Failed to submit for approval');
  }

  return response.json();
}

/**
 * Approve a specific step
 */
export async function approveStep(
  runId: string,
  step: string,
  comment?: string
): Promise<{ success: boolean; message: string; all_approved: boolean; run_status: string }> {
  const { data: { session } } = await supabase.auth.getSession();

  if (!session) {
    throw new Error('Not authenticated');
  }

  const response = await fetch(`${APPROVALS_API_URL}/${runId}/approve`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${session.access_token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ step, comment }),
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.error || 'Failed to approve step');
  }

  return response.json();
}

/**
 * Reject a specific step
 */
export async function rejectStep(
  runId: string,
  step: string,
  comment: string
): Promise<{ success: boolean; message: string; run_status: string }> {
  const { data: { session } } = await supabase.auth.getSession();

  if (!session) {
    throw new Error('Not authenticated');
  }

  const response = await fetch(`${APPROVALS_API_URL}/${runId}/reject`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${session.access_token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ step, comment }),
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.error || 'Failed to reject step');
  }

  return response.json();
}

/**
 * Get approval status for a run
 */
export async function getApprovalStatus(runId: string): Promise<ApprovalStatus> {
  const { data: { session } } = await supabase.auth.getSession();

  if (!session) {
    throw new Error('Not authenticated');
  }

  const response = await fetch(`${APPROVALS_API_URL}/${runId}/status`, {
    method: 'GET',
    headers: {
      'Authorization': `Bearer ${session.access_token}`,
      'Content-Type': 'application/json',
    },
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.error || 'Failed to get approval status');
  }

  return response.json();
}

/**
 * Helper: Check if user can approve a specific step
 */
export async function canUserApproveStep(step: ApprovalStep): Promise<boolean> {
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    return false;
  }

  // Check user roles
  const { data: userRoles } = await supabase
    .from('user_roles')
    .select('role')
    .eq('user_id', user.id);

  if (!userRoles) {
    return false;
  }

  const roles = userRoles.map(r => r.role);

  // Admin can approve anything
  if (roles.includes('admin')) {
    return true;
  }

  // Check specific role match
  return roles.includes(step.approver_role);
}

/**
 * Helper: Get step display name
 */
export function getStepDisplayName(step: string): string {
  const names: Record<string, string> = {
    'ops_review': 'Operations Review',
    'finance_review': 'Finance Review',
    'final_approval': 'Final Approval',
  };
  return names[step] || step;
}

/**
 * Helper: Get step icon
 */
export function getStepIcon(status: string): string {
  const icons: Record<string, string> = {
    'pending': '⏳',
    'approved': '✅',
    'rejected': '❌',
  };
  return icons[status] || '?';
}
