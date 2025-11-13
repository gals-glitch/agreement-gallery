/**
 * Feature Guard Component
 * Ticket: ORC-001
 * Date: 2025-10-19
 *
 * Conditionally renders children based on feature flag status.
 * Use this component to wrap features that should be hidden when flag is off.
 *
 * Example usage:
 * ```tsx
 * <FeatureGuard flag="docs_repository">
 *   <DocumentsTab />
 * </FeatureGuard>
 * ```
 */

import React from 'react';
import { useFeatureFlag } from '@/hooks/useFeatureFlags';

// ============================================
// TYPES
// ============================================
interface FeatureGuardProps {
  flag: string;
  children: React.ReactNode;
  fallback?: React.ReactNode;
  showLoader?: boolean;
}

// ============================================
// COMPONENT
// ============================================
export function FeatureGuard({
  flag,
  children,
  fallback = null,
  showLoader = false,
}: FeatureGuardProps) {
  const { isEnabled, isLoading } = useFeatureFlag(flag);

  // Show loader during initial fetch (optional)
  if (isLoading && showLoader) {
    return <div className="animate-pulse">Loading...</div>;
  }

  // If flag is disabled, show fallback or nothing
  if (!isEnabled) {
    return <>{fallback}</>;
  }

  // Flag is enabled, render children
  return <>{children}</>;
}
