/**
 * Feature Flags Hooks
 * Ticket: ORC-001
 * Date: 2025-10-19
 *
 * Provides React hooks for feature flag management:
 * - useFeatureFlags() - Fetch all flags
 * - useFeatureFlag(key) - Check if specific flag enabled for current user
 * - useUpdateFeatureFlag() - Update flag (admin-only)
 *
 * Uses TanStack Query with 5-minute cache for performance
 */

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { http } from '@/api/http';
import { toast } from '@/hooks/use-toast';

// ============================================
// TYPES
// ============================================
export interface FeatureFlag {
  key: string;
  enabled: boolean;
  isEnabledForUser: boolean;
  description: string;
  enabled_for_roles: string[] | null;
  rollout_percentage: number;
}

export interface UpdateFeatureFlagRequest {
  enabled?: boolean;
  enabled_for_roles?: string[];
  rollout_percentage?: number;
}

// ============================================
// QUERY KEYS
// ============================================
const FEATURE_FLAGS_KEY = ['feature-flags'] as const;

// ============================================
// HOOK: Fetch All Feature Flags
// ============================================
export function useFeatureFlags() {
  return useQuery<FeatureFlag[]>({
    queryKey: FEATURE_FLAGS_KEY,
    queryFn: async () => {
      const response = await http.get<FeatureFlag[]>('/feature-flags');
      return response;
    },
    staleTime: 5 * 60 * 1000, // 5 minutes
    gcTime: 10 * 60 * 1000,   // 10 minutes (formerly cacheTime)
    refetchOnWindowFocus: false,
  });
}

// ============================================
// HOOK: Check Single Feature Flag
// ============================================
export function useFeatureFlag(key: string) {
  const { data: flags, isLoading, error } = useFeatureFlags();

  const flag = flags?.find(f => f.key === key);

  return {
    isEnabled: flag?.isEnabledForUser ?? false,
    isLoading,
    error,
    flag,
  };
}

// ============================================
// HOOK: Update Feature Flag (Admin Only)
// ============================================
export function useUpdateFeatureFlag() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      key,
      updates,
    }: {
      key: string;
      updates: UpdateFeatureFlagRequest;
    }) => {
      return await http.patch<{ ok: boolean; flag: FeatureFlag }>(
        `/feature-flags/${key}`,
        updates
      );
    },
    onSuccess: (data, variables) => {
      // Invalidate and refetch flags
      queryClient.invalidateQueries({ queryKey: FEATURE_FLAGS_KEY });

      toast({
        title: 'Feature Flag Updated',
        description: `Flag '${variables.key}' has been updated successfully.`,
      });
    },
    onError: (error: any) => {
      // Error toast handled by http.ts global handler
      console.error('Failed to update feature flag:', error);
    },
  });
}

// ============================================
// HELPER: Get Flag Status (Non-Hook)
// ============================================
export function getFlagStatus(flags: FeatureFlag[] | undefined, key: string): boolean {
  return flags?.find(f => f.key === key)?.isEnabledForUser ?? false;
}
