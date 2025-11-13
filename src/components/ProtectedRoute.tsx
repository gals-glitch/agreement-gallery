import { useAuth } from '@/hooks/useAuth';
import { Navigate, useLocation } from 'react-router-dom';
import { ReactNode } from 'react';

type AppRole = 'admin' | 'finance' | 'ops' | 'legal' | 'viewer' | 'auditor';

interface ProtectedRouteProps {
  children: ReactNode;
  requiredRoles?: AppRole[];
  requireAuth?: boolean;
}

export function ProtectedRoute({
  children,
  requiredRoles = [],
  requireAuth = true
}: ProtectedRouteProps) {
  const { user, loading, hasAnyRole, profile, roles } = useAuth();
  const location = useLocation();

  // DEBUG: Log role checking
  console.log('🔒 ProtectedRoute Debug:', {
    path: location.pathname,
    loading,
    user: user?.email,
    requiredRoles,
    userRoles: roles,
    hasAccess: requiredRoles.length === 0 || hasAnyRole(requiredRoles)
  });

  // Show loading spinner while checking auth OR while roles are loading
  // CRITICAL FIX: Also check if user exists but roles haven't loaded yet
  const rolesStillLoading = loading || (user && requiredRoles.length > 0 && roles.length === 0);

  if (rolesStillLoading) {
    console.log('⏳ Still loading auth/roles, showing spinner...');
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
      </div>
    );
  }

  // Redirect to auth if not authenticated and auth is required
  if (requireAuth && !user) {
    return <Navigate to="/auth" state={{ from: location }} replace />;
  }

  // Check if user profile is suspended
  if (user && profile && 'status' in profile && profile.status === 'suspended') {
    return <Navigate to="/suspended" replace />;
  }

  // Check role requirements
  if (requiredRoles.length > 0 && !hasAnyRole(requiredRoles)) {
    console.error('❌ Access Denied:', {
      requiredRoles,
      userRoles: roles,
      reason: 'User does not have any of the required roles'
    });
    return <Navigate to="/no-access" replace />;
  }

  return <>{children}</>;
}

// Convenience components for common role checks
export function AdminRoute({ children }: { children: ReactNode }) {
  return (
    <ProtectedRoute requiredRoles={['admin']}>
      {children}
    </ProtectedRoute>
  );
}

export function FinanceRoute({ children }: { children: ReactNode }) {
  return (
    <ProtectedRoute requiredRoles={['admin', 'finance']}>
      {children}
    </ProtectedRoute>
  );
}

export function OpsRoute({ children }: { children: ReactNode }) {
  return (
    <ProtectedRoute requiredRoles={['admin', 'finance', 'ops']}>
      {children}
    </ProtectedRoute>
  );
}