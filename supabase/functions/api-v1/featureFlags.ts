/**
 * Feature Flags API Handler
 * Ticket: ORC-001
 * Date: 2025-10-19
 *
 * Endpoints:
 * - GET /api-v1/feature-flags - Returns all flags with enabled status for current user's role
 * - PUT /api-v1/feature-flags/:key - Update flag (admin-only)
 *
 * Middleware:
 * - checkFeatureFlag(key) - Returns 403 if flag disabled for user's role
 */

import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';

// ============================================
// TYPES
// ============================================
interface FeatureFlag {
  key: string;
  enabled: boolean;
  enabled_for_roles: string[] | null;
  description: string;
  rollout_percentage: number;
  created_at: string;
  updated_at: string;
}

interface FeatureFlagResponse {
  key: string;
  enabled: boolean;
  isEnabledForUser: boolean;
  description: string;
  enabled_for_roles: string[] | null;
  rollout_percentage: number;
}

interface UpdateFeatureFlagRequest {
  enabled?: boolean;
  enabled_for_roles?: string[];
  rollout_percentage?: number;
}

// ============================================
// HELPER: Get User Roles
// ============================================
async function getUserRoles(supabase: SupabaseClient, userId: string): Promise<string[]> {
  const { data, error } = await supabase
    .from('user_roles')
    .select('role_key')
    .eq('user_id', userId);

  if (error) return [];
  return data?.map((r: any) => r.role_key) || [];
}

// ============================================
// HELPER: Check if User Has Admin Role
// ============================================
function isAdmin(userRoles: string[]): boolean {
  return userRoles.includes('admin');
}

// ============================================
// HELPER: Check if Flag Enabled for User
// ============================================
function isFlagEnabledForUser(flag: FeatureFlag, userRoles: string[]): boolean {
  // If flag is globally disabled, return false
  if (!flag.enabled) {
    return false;
  }

  // If enabled_for_roles is NULL, flag is enabled for all roles
  if (flag.enabled_for_roles === null) {
    return true;
  }

  // Check if user has any of the required roles
  return flag.enabled_for_roles.some(role => userRoles.includes(role));
}

// ============================================
// HELPER: JSON Response
// ============================================
function jsonResponse(data: any, status = 200, corsHeaders: Record<string, string>) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

// ============================================
// MAIN HANDLER: Feature Flags
// ============================================
export async function handleFeatureFlags(
  req: Request,
  supabase: SupabaseClient,
  userId: string,
  key?: string,
  corsHeaders: Record<string, string> = {}
) {
  const userRoles = await getUserRoles(supabase, userId);

  switch (req.method) {
    case 'GET':
      return await handleGetFlags(supabase, userId, userRoles, corsHeaders);

    case 'PUT':
      if (!key) {
        return jsonResponse({ error: 'Flag key required' }, 400, corsHeaders);
      }
      return await handleUpdateFlag(supabase, userId, userRoles, key, req, corsHeaders);

    default:
      return jsonResponse({ error: 'Method not allowed' }, 405, corsHeaders);
  }
}

// ============================================
// GET /feature-flags - List All Flags
// ============================================
async function handleGetFlags(
  supabase: SupabaseClient,
  userId: string,
  userRoles: string[],
  corsHeaders: Record<string, string>
) {
  // Fetch all flags
  const { data: flags, error } = await supabase
    .from('feature_flags')
    .select('*')
    .order('key', { ascending: true });

  if (error) {
    return jsonResponse({ error: error.message }, 400, corsHeaders);
  }

  // Map flags to include isEnabledForUser
  const response: FeatureFlagResponse[] = (flags || []).map((flag: FeatureFlag) => ({
    key: flag.key,
    enabled: flag.enabled,
    isEnabledForUser: isFlagEnabledForUser(flag, userRoles),
    description: flag.description,
    enabled_for_roles: flag.enabled_for_roles,
    rollout_percentage: flag.rollout_percentage,
  }));

  return jsonResponse(response, 200, corsHeaders);
}

// ============================================
// PUT /feature-flags/:key - Update Flag
// ============================================
async function handleUpdateFlag(
  supabase: SupabaseClient,
  userId: string,
  userRoles: string[],
  key: string,
  req: Request,
  corsHeaders: Record<string, string>
) {
  // Check admin role
  if (!isAdmin(userRoles)) {
    return jsonResponse(
      { error: 'Unauthorized: requires admin role' },
      403,
      corsHeaders
    );
  }

  // Parse request body
  const body: UpdateFeatureFlagRequest = await req.json();

  // Build update object (only include provided fields)
  const updates: any = {
    updated_at: new Date().toISOString(),
  };

  if (body.enabled !== undefined) {
    updates.enabled = body.enabled;
  }

  if (body.enabled_for_roles !== undefined) {
    updates.enabled_for_roles = body.enabled_for_roles;
  }

  if (body.rollout_percentage !== undefined) {
    // Validate range
    if (body.rollout_percentage < 0 || body.rollout_percentage > 100) {
      return jsonResponse(
        { error: 'rollout_percentage must be between 0 and 100' },
        400,
        corsHeaders
      );
    }
    updates.rollout_percentage = body.rollout_percentage;
  }

  // Update flag
  const { data, error } = await supabase
    .from('feature_flags')
    .update(updates)
    .eq('key', key)
    .select()
    .single();

  if (error) {
    return jsonResponse({ error: error.message }, 400, corsHeaders);
  }

  return jsonResponse({ ok: true, flag: data }, 200, corsHeaders);
}

// ============================================
// MIDDLEWARE: Check Feature Flag
// ============================================
export async function checkFeatureFlag(
  supabase: SupabaseClient,
  userId: string,
  flagKey: string,
  corsHeaders: Record<string, string>
): Promise<Response | null> {
  const userRoles = await getUserRoles(supabase, userId);

  // Fetch flag
  const { data: flag, error } = await supabase
    .from('feature_flags')
    .select('*')
    .eq('key', flagKey)
    .single();

  if (error || !flag) {
    return jsonResponse(
      { error: `Feature flag '${flagKey}' not found` },
      404,
      corsHeaders
    );
  }

  // Check if enabled for user
  if (!isFlagEnabledForUser(flag, userRoles)) {
    return jsonResponse(
      { error: `Feature '${flagKey}' is not available for your account` },
      403,
      corsHeaders
    );
  }

  // Flag is enabled for user, return null (no error)
  return null;
}
