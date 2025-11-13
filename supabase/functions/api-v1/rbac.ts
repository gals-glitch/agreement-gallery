/**
 * RBAC API Handler - Users & Roles Management
 * Ticket: P1-A3a
 * Date: 2025-10-19
 *
 * Endpoints:
 * - GET /admin/users - List all users with their roles
 * - POST /admin/users/:userId/roles - Grant role to user
 * - DELETE /admin/users/:userId/roles/:roleKey - Revoke role from user
 * - GET /admin/roles - List all available roles
 * - POST /admin/users/invite - Invite new user (uses Supabase Admin API)
 *
 * Security:
 * - All endpoints require authentication
 * - User management endpoints require 'admin' role
 * - GET /admin/roles available to all authenticated users
 */

import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import {
  validationError,
  forbiddenError,
  successResponse,
  mapPgErrorToApiError,
  notFoundError,
  type ApiErrorDetail,
} from './errors.ts';
import { getUserRoles, hasAnyRole } from '../_shared/auth.ts';

// ============================================
// TYPES
// ============================================
interface UserWithRoles {
  id: string;
  email: string;
  created_at: string;
  last_sign_in_at: string | null;
  roles: string[]; // Array of role_key values
}

interface Role {
  key: string;
  name: string;
  description: string | null;
}

interface GrantRoleRequest {
  role_key: string;
}

interface InviteUserRequest {
  email: string;
}

// ============================================
// MAIN HANDLER: RBAC
// ============================================
export async function handleRBAC(
  req: Request,
  supabase: SupabaseClient,
  userId: string,
  id: string | undefined,
  action: string | undefined,
  corsHeaders: Record<string, string> = {}
) {
  const url = new URL(req.url);
  const pathParts = url.pathname.split('/').filter(Boolean);

  // Clean path: remove 'api-v1' and 'admin'
  const cleanPath = pathParts.filter(p => p !== 'api-v1' && p !== 'admin');

  // Routes:
  // /admin/users -> cleanPath = ['users']
  // /admin/users/:userId/roles -> cleanPath = ['users', ':userId', 'roles']
  // /admin/users/:userId/roles/:roleKey -> cleanPath = ['users', ':userId', 'roles', ':roleKey']
  // /admin/roles -> cleanPath = ['roles']

  const resource = cleanPath[0]; // 'users' or 'roles'
  const resourceId = cleanPath[1]; // userId or undefined
  const subResource = cleanPath[2]; // 'roles' or undefined
  const subResourceId = cleanPath[3]; // roleKey or undefined

  // Route: GET /admin/roles
  if (resource === 'roles' && req.method === 'GET' && !resourceId) {
    return await handleGetRoles(supabase, corsHeaders);
  }

  // Route: GET /admin/users
  if (resource === 'users' && req.method === 'GET' && !resourceId) {
    return await handleGetUsers(supabase, userId, url, corsHeaders);
  }

  // Route: POST /admin/users/invite
  if (resource === 'users' && req.method === 'POST' && resourceId === 'invite') {
    return await handleInviteUser(supabase, userId, req, corsHeaders);
  }

  // Route: POST /admin/users/:userId/roles
  if (resource === 'users' && req.method === 'POST' && resourceId && subResource === 'roles' && !subResourceId) {
    return await handleGrantRole(supabase, userId, resourceId, req, corsHeaders);
  }

  // Route: DELETE /admin/users/:userId/roles/:roleKey
  if (resource === 'users' && req.method === 'DELETE' && resourceId && subResource === 'roles' && subResourceId) {
    return await handleRevokeRole(supabase, userId, resourceId, subResourceId, corsHeaders);
  }

  return notFoundError('Endpoint', corsHeaders);
}

// ============================================
// GET /admin/users - List all users with roles
// ============================================
async function handleGetUsers(
  supabase: SupabaseClient,
  currentUserId: string,
  url: URL,
  corsHeaders: Record<string, string>
) {
  // Check admin permission
  const roles = await getUserRoles(supabase, currentUserId);
  if (!hasAnyRole(roles, ['admin'])) {
    return forbiddenError('Requires admin role to list users', corsHeaders);
  }

  const query = url.searchParams.get('query');

  // Get all users from auth.users
  // Note: Supabase doesn't expose auth.users directly via PostgREST
  // We need to use the Admin API
  const { data: authUsers, error: authError } = await supabase.auth.admin.listUsers();

  if (authError) {
    return mapPgErrorToApiError(authError, corsHeaders);
  }

  // Get all user roles
  const { data: userRolesData, error: rolesError } = await supabase
    .from('user_roles')
    .select('user_id, role_key');

  if (rolesError) {
    return mapPgErrorToApiError(rolesError, corsHeaders);
  }

  // Group roles by user_id
  const rolesByUser = (userRolesData || []).reduce((acc, ur) => {
    if (!acc[ur.user_id]) {
      acc[ur.user_id] = [];
    }
    acc[ur.user_id].push(ur.role_key);
    return acc;
  }, {} as Record<string, string[]>);

  // Map users with roles
  let users: UserWithRoles[] = (authUsers.users || []).map(u => ({
    id: u.id,
    email: u.email || '',
    created_at: u.created_at,
    last_sign_in_at: u.last_sign_in_at || null,
    roles: rolesByUser[u.id] || [],
  }));

  // Apply query filter if provided
  if (query) {
    const lowerQuery = query.toLowerCase();
    users = users.filter(u => u.email.toLowerCase().includes(lowerQuery));
  }

  return successResponse(
    {
      users,
      total: users.length,
    },
    200,
    corsHeaders
  );
}

// ============================================
// GET /admin/roles - List all available roles
// ============================================
async function handleGetRoles(
  supabase: SupabaseClient,
  corsHeaders: Record<string, string>
) {
  // Available to all authenticated users (for UI chips)
  const { data: roles, error } = await supabase
    .from('roles')
    .select('key, name, description')
    .order('name', { ascending: true });

  if (error) {
    return mapPgErrorToApiError(error, corsHeaders);
  }

  return successResponse(
    {
      roles: roles || [],
    },
    200,
    corsHeaders
  );
}

// ============================================
// POST /admin/users/:userId/roles - Grant role
// ============================================
async function handleGrantRole(
  supabase: SupabaseClient,
  currentUserId: string,
  targetUserId: string,
  req: Request,
  corsHeaders: Record<string, string>
) {
  // Check admin permission
  const roles = await getUserRoles(supabase, currentUserId);
  if (!hasAnyRole(roles, ['admin'])) {
    return forbiddenError('Requires admin role to grant roles', corsHeaders);
  }

  const body: GrantRoleRequest = await req.json();

  // Validate role_key
  if (!body.role_key) {
    return validationError(
      [{ field: 'role_key', message: 'role_key is required', value: body.role_key }],
      corsHeaders
    );
  }

  // Verify role exists
  const { data: role, error: roleError } = await supabase
    .from('roles')
    .select('key')
    .eq('key', body.role_key)
    .single();

  if (roleError || !role) {
    return validationError(
      [{ field: 'role_key', message: `Role '${body.role_key}' not found`, value: body.role_key }],
      corsHeaders
    );
  }

  // Check if user already has this role (idempotent)
  const { data: existingRole } = await supabase
    .from('user_roles')
    .select('user_id, role_key')
    .eq('user_id', targetUserId)
    .eq('role_key', body.role_key)
    .single();

  if (existingRole) {
    // Already has role, return success (idempotent)
    return successResponse({ ok: true, message: 'User already has this role' }, 200, corsHeaders);
  }

  // Grant role
  const { error: insertError } = await supabase
    .from('user_roles')
    .insert({
      user_id: targetUserId,
      role_key: body.role_key,
      granted_by: currentUserId,
      granted_at: new Date().toISOString(),
    });

  if (insertError) {
    return mapPgErrorToApiError(insertError, corsHeaders);
  }

  // Audit log
  await supabase
    .from('audit_log')
    .insert({
      event_type: 'role.granted',
      actor_id: currentUserId,
      target_id: targetUserId,
      entity_type: 'user_role',
      entity_id: body.role_key,
      payload: {
        user_id: targetUserId,
        role_key: body.role_key,
      },
    });

  return successResponse({ ok: true }, 200, corsHeaders);
}

// ============================================
// DELETE /admin/users/:userId/roles/:roleKey - Revoke role
// ============================================
async function handleRevokeRole(
  supabase: SupabaseClient,
  currentUserId: string,
  targetUserId: string,
  roleKey: string,
  corsHeaders: Record<string, string>
) {
  // Check admin permission
  const roles = await getUserRoles(supabase, currentUserId);
  if (!hasAnyRole(roles, ['admin'])) {
    return forbiddenError('Requires admin role to revoke roles', corsHeaders);
  }

  // Delete role assignment (idempotent - success even if doesn't exist)
  const { error: deleteError } = await supabase
    .from('user_roles')
    .delete()
    .eq('user_id', targetUserId)
    .eq('role_key', roleKey);

  if (deleteError) {
    return mapPgErrorToApiError(deleteError, corsHeaders);
  }

  // Audit log
  await supabase
    .from('audit_log')
    .insert({
      event_type: 'role.revoked',
      actor_id: currentUserId,
      target_id: targetUserId,
      entity_type: 'user_role',
      entity_id: roleKey,
      payload: {
        user_id: targetUserId,
        role_key: roleKey,
      },
    });

  return successResponse({ ok: true }, 200, corsHeaders);
}

// ============================================
// POST /admin/users/invite - Invite new user
// ============================================
async function handleInviteUser(
  supabase: SupabaseClient,
  currentUserId: string,
  req: Request,
  corsHeaders: Record<string, string>
) {
  // Check admin permission
  const roles = await getUserRoles(supabase, currentUserId);
  if (!hasAnyRole(roles, ['admin'])) {
    return forbiddenError('Requires admin role to invite users', corsHeaders);
  }

  const body: InviteUserRequest = await req.json();

  // Validate email
  if (!body.email || !body.email.includes('@')) {
    return validationError(
      [{ field: 'email', message: 'Valid email address is required', value: body.email }],
      corsHeaders
    );
  }

  // Invite user using Supabase Admin API
  const { data, error } = await supabase.auth.admin.inviteUserByEmail(body.email);

  if (error) {
    return mapPgErrorToApiError(error, corsHeaders);
  }

  // Audit log
  await supabase
    .from('audit_log')
    .insert({
      event_type: 'user.invited',
      actor_id: currentUserId,
      entity_type: 'user',
      entity_id: data.user?.id || null,
      payload: {
        email: body.email,
      },
    });

  return successResponse(
    {
      ok: true,
      user_id: data.user?.id,
      email: body.email,
      message: 'User invited successfully',
    },
    201,
    corsHeaders
  );
}
