/**
 * Feature Flags - Non-disruptive rollout controls
 *
 * All new features are gated behind flags to ensure:
 * - Safe rollback without code changes
 * - Gradual rollout to users
 * - A/B testing capability
 * - Compatibility mode for existing workflows
 */

import React from 'react';

export interface FeatureFlags {
  FEATURE_APPROVALS: boolean;
  FEATURE_INVOICES: boolean;
  FEATURE_SUCCESS_FEE: boolean;
  FEATURE_MGMT_FEE: boolean;
  FEATURE_IMPORT_STAGING: boolean;
  FEATURE_PAYOUT_SPLITS: boolean;
  FEATURE_REPORTS: boolean;
}

// Default flags (can be overridden by env vars or database config)
const DEFAULT_FLAGS: FeatureFlags = {
  FEATURE_APPROVALS: false,
  FEATURE_INVOICES: false,
  FEATURE_SUCCESS_FEE: false,
  FEATURE_MGMT_FEE: false,
  FEATURE_IMPORT_STAGING: false,
  FEATURE_PAYOUT_SPLITS: false,
  FEATURE_REPORTS: false,
};

// Runtime flag resolution (env vars take precedence)
function resolveFlags(): FeatureFlags {
  return {
    FEATURE_APPROVALS: import.meta.env.VITE_FEATURE_APPROVALS === 'true' || DEFAULT_FLAGS.FEATURE_APPROVALS,
    FEATURE_INVOICES: import.meta.env.VITE_FEATURE_INVOICES === 'true' || DEFAULT_FLAGS.FEATURE_INVOICES,
    FEATURE_SUCCESS_FEE: import.meta.env.VITE_FEATURE_SUCCESS_FEE === 'true' || DEFAULT_FLAGS.FEATURE_SUCCESS_FEE,
    FEATURE_MGMT_FEE: import.meta.env.VITE_FEATURE_MGMT_FEE === 'true' || DEFAULT_FLAGS.FEATURE_MGMT_FEE,
    FEATURE_IMPORT_STAGING: import.meta.env.VITE_FEATURE_IMPORT_STAGING === 'true' || DEFAULT_FLAGS.FEATURE_IMPORT_STAGING,
    FEATURE_PAYOUT_SPLITS: import.meta.env.VITE_FEATURE_PAYOUT_SPLITS === 'true' || DEFAULT_FLAGS.FEATURE_PAYOUT_SPLITS,
    FEATURE_REPORTS: import.meta.env.VITE_FEATURE_REPORTS === 'true' || DEFAULT_FLAGS.FEATURE_REPORTS,
  };
}

export const featureFlags = resolveFlags();

/**
 * Check if a feature is enabled
 * Usage: if (isFeatureEnabled('FEATURE_APPROVALS')) { ... }
 */
export function isFeatureEnabled(flag: keyof FeatureFlags): boolean {
  return featureFlags[flag];
}

/**
 * HOC to conditionally render components based on feature flag
 * Usage: export default withFeatureFlag('FEATURE_APPROVALS', ApprovalsDrawer);
 */
export function withFeatureFlag<P extends object>(
  flag: keyof FeatureFlags,
  Component: React.ComponentType<P>
): React.ComponentType<P> {
  return (props: P) => {
    if (!isFeatureEnabled(flag)) {
      return null;
    }
    return <Component {...props} />;
  };
}

/**
 * Hook to check feature flag in components
 * Usage: const approvalsEnabled = useFeatureFlag('FEATURE_APPROVALS');
 */
export function useFeatureFlag(flag: keyof FeatureFlags): boolean {
  return isFeatureEnabled(flag);
}
