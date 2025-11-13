import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';

export async function getAuthenticatedUser(req: Request, supabase: SupabaseClient) {
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    throw new Error('Missing authorization header');
  }

  const token = authHeader.replace('Bearer ', '');
  const { data: { user }, error } = await supabase.auth.getUser(token);

  if (error || !user) {
    throw new Error('Invalid or expired token');
  }

  return user;
}

export async function getUserRoles(supabase: SupabaseClient, userId: string): Promise<string[]> {
  // Handle service key - no roles needed (bypasses RBAC)
  if (userId === 'SERVICE') {
    return [];
  }

  const { data, error } = await supabase
    .from('user_roles')
    .select('role_key')
    .eq('user_id', userId);

  if (error) throw error;
  return data?.map((r: any) => r.role_key) || [];
}

export function hasAnyRole(userRoles: string[], requiredRoles: string[]): boolean {
  return requiredRoles.some(role => userRoles.includes(role));
}

/**
 * Check if request is authenticated via service key (for internal jobs/imports)
 *
 * Usage:
 * - Internal batch jobs can use x-service-key header instead of user JWT
 * - Service key bypasses RLS and RBAC checks
 * - Set SERVICE_API_KEY environment variable in Supabase
 *
 * @param req - Request object
 * @returns true if service key is valid, false otherwise
 */
export function isServiceKeyAuth(req: Request): boolean {
  const serviceKey = Deno.env.get('SERVICE_API_KEY');
  if (!serviceKey) {
    return false; // Service key not configured
  }

  const requestKey = req.headers.get('x-service-key');
  return requestKey === serviceKey;
}

/**
 * Get user ID or service role indicator from request
 *
 * Returns:
 * - User ID if authenticated via JWT
 * - "SERVICE" if authenticated via service key
 * - null if not authenticated
 *
 * @param req - Request object
 * @param supabase - Supabase client
 * @returns User ID, "SERVICE", or null
 */
export async function getAuthContext(req: Request, supabase: SupabaseClient): Promise<string | null> {
  // Check service key first (highest priority for internal jobs)
  if (isServiceKeyAuth(req)) {
    return 'SERVICE';
  }

  // Check JWT auth
  try {
    const user = await getAuthenticatedUser(req, supabase);
    return user.id;
  } catch {
    return null;
  }
}

/**
 * Check if request uses service role key (bypasses all auth)
 *
 * @param req - Request object
 * @returns true if using service role key
 */
export function isServiceRoleKey(req: Request): boolean {
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) return false;

  const token = authHeader.replace('Bearer ', '');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

  return serviceRoleKey && token === serviceRoleKey;
}

/**
 * Check if request has required roles (supports both JWT and service key)
 *
 * @param req - Request object
 * @param supabase - Supabase client
 * @param requiredRoles - Array of required roles (e.g., ['admin', 'finance'])
 * @returns true if authorized, false otherwise
 */
export async function hasRequiredRoles(
  req: Request,
  supabase: SupabaseClient,
  requiredRoles: string[]
): Promise<boolean> {
  // Service role key bypasses all RBAC checks
  if (isServiceRoleKey(req)) {
    return true;
  }

  // Custom service key bypasses all RBAC checks
  if (isServiceKeyAuth(req)) {
    return true;
  }

  // JWT auth: check user roles
  try {
    const user = await getAuthenticatedUser(req, supabase);
    const userRoles = await getUserRoles(supabase, user.id);
    return hasAnyRole(userRoles, requiredRoles);
  } catch {
    return false;
  }
}

/**
 * Authentication Guard - Unified dual-auth middleware (T04)
 *
 * Validates requests using either JWT tokens with role-based access control (RBAC)
 * or service key authentication for internal services.
 *
 * Use this guard at the start of endpoint handlers to enforce authentication and authorization.
 *
 * @param req - Request object
 * @param supabase - Supabase client instance
 * @param requiredRoles - Array of required roles (e.g., ['admin', 'finance', 'ops'])
 * @param options - Configuration options
 * @param options.allowServiceKey - If true, allows service key auth (default: true for compute/submit, false for approve/reject/mark-paid)
 * @returns AuthGuardResult with userId ('SERVICE' for service key, user UUID for JWT) and isServiceKey flag
 * @throws Error with specific message if authentication fails
 *
 * @example
 * // Finance+ roles or service key (for compute, submit)
 * const auth = await authGuard(req, supabase, ['admin', 'finance', 'ops'], { allowServiceKey: true });
 *
 * @example
 * // Admin only, no service key (for approve, reject, mark-paid)
 * const auth = await authGuard(req, supabase, ['admin'], { allowServiceKey: false });
 */
export interface AuthGuardResult {
  userId: string;
  isServiceKey: boolean;
}

export interface AuthGuardOptions {
  allowServiceKey?: boolean;
}

export async function authGuard(
  req: Request,
  supabase: SupabaseClient,
  requiredRoles: string[],
  options: AuthGuardOptions = { allowServiceKey: true }
): Promise<AuthGuardResult> {
  const { allowServiceKey = true } = options;

  // 1. Check service key first (if allowed)
  if (allowServiceKey && isServiceKeyAuth(req)) {
    return {
      userId: 'SERVICE',
      isServiceKey: true,
    };
  }

  // 2. If service key not allowed but provided, reject
  if (!allowServiceKey && isServiceKeyAuth(req)) {
    throw new Error('Service key not allowed for this operation (requires human authorization)');
  }

  // 3. Check service role key (if allowed)
  if (allowServiceKey && isServiceRoleKey(req)) {
    return {
      userId: 'SERVICE',
      isServiceKey: true,
    };
  }

  // 4. JWT authentication required
  let user;
  try {
    user = await getAuthenticatedUser(req, supabase);
  } catch (error: any) {
    throw new Error('Authentication required: Invalid or missing JWT token');
  }

  // 5. Check RBAC roles
  const userRoles = await getUserRoles(supabase, user.id);

  if (!hasAnyRole(userRoles, requiredRoles)) {
    throw new Error(`Insufficient permissions: requires one of [${requiredRoles.join(', ')}]`);
  }

  // 6. Success - return user ID
  return {
    userId: user.id,
    isServiceKey: false,
  };
}
