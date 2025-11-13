/**
 * Run Workflow State Machine
 * Defines valid transitions and capabilities for calculation runs
 */

export type RunStatus = 'DRAFT' | 'IN_PROGRESS' | 'AWAITING_APPROVAL' | 'APPROVED';

export const statusLabel: Record<RunStatus, string> = {
  DRAFT: 'Draft',
  IN_PROGRESS: 'In Progress',
  AWAITING_APPROVAL: 'Awaiting Approval',
  APPROVED: 'Approved',
};

export const statusVariant: Record<RunStatus, 'default' | 'secondary' | 'destructive' | 'outline'> = {
  DRAFT: 'outline',
  IN_PROGRESS: 'secondary',
  AWAITING_APPROVAL: 'default',
  APPROVED: 'default',
};

/**
 * Can submit a run for approval
 */
export function canSubmit(status: RunStatus): boolean {
  return status === 'DRAFT' || status === 'IN_PROGRESS';
}

/**
 * Can approve a run (requires RBAC check externally)
 */
export function canApprove(status: RunStatus): boolean {
  return status === 'AWAITING_APPROVAL';
}

/**
 * Can reject a run (requires RBAC check externally)
 */
export function canReject(status: RunStatus): boolean {
  return status === 'AWAITING_APPROVAL';
}

/**
 * Can generate final calculations (only after approval)
 */
export function canGenerate(status: RunStatus): boolean {
  return status === 'APPROVED';
}
