/**
 * Users & Roles Admin Page
 * Ticket: P1-A3a
 * Date: 2025-10-19
 *
 * Features:
 * - List all users with their assigned roles
 * - Grant and revoke roles via role chips
 * - Invite new users via email
 * - Search/filter users by email
 * - Admin-only access with RBAC enforcement
 */

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { http } from '@/api/http';
import { useAuth } from '@/hooks/useAuth';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from '@/components/ui/dialog';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
  DropdownMenuLabel,
  DropdownMenuSeparator,
} from '@/components/ui/dropdown-menu';
import { Plus, X, Shield, Mail, Search, Loader2, Users as UsersIcon } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';

// Type definitions
interface UserRecord {
  id: string;
  email: string;
  roles: string[];
  last_sign_in_at: string | null;
  created_at: string;
}

interface RoleDefinition {
  key: string;
  display_name: string;
  description: string;
}

interface UsersResponse {
  users: UserRecord[];
  total: number;
}

interface RolesResponse {
  roles: RoleDefinition[];
}

// Role badge color mapping
const ROLE_COLORS: Record<string, string> = {
  admin: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200',
  finance: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200',
  ops: 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200',
  legal: 'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200',
  viewer: 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200',
  auditor: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200',
};

export default function UsersPage() {
  const { isAdmin } = useAuth();
  const { toast } = useToast();
  const queryClient = useQueryClient();

  // Local state
  const [searchQuery, setSearchQuery] = useState('');
  const [inviteDialogOpen, setInviteDialogOpen] = useState(false);
  const [newUserEmail, setNewUserEmail] = useState('');
  const [emailError, setEmailError] = useState('');

  // Fetch users with search
  const { data: usersData, isLoading: isLoadingUsers, error: usersError } = useQuery<UsersResponse>({
    queryKey: ['admin-users', searchQuery],
    queryFn: async () => {
      const params = new URLSearchParams();
      if (searchQuery.trim()) {
        params.append('query', searchQuery.trim());
      }
      const response = await http.get<UsersResponse>(`/admin/users?${params.toString()}`);
      return response;
    },
    enabled: isAdmin(),
    retry: false,
  });

  // Fetch available roles
  const { data: rolesData } = useQuery<RolesResponse>({
    queryKey: ['admin-roles'],
    queryFn: async () => {
      const response = await http.get<RolesResponse>('/admin/roles');
      return response;
    },
    enabled: isAdmin(),
  });

  // Grant role mutation
  const grantRoleMutation = useMutation({
    mutationFn: async ({ userId, roleKey }: { userId: string; roleKey: string }) => {
      await http.post(`/admin/users/${userId}/roles`, { role_key: roleKey });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-users'] });
      toast({ title: 'Role granted successfully' });
    },
    onError: (error: any) => {
      toast({
        title: 'Failed to grant role',
        description: error.message || 'An error occurred',
        variant: 'destructive'
      });
    },
  });

  // Revoke role mutation
  const revokeRoleMutation = useMutation({
    mutationFn: async ({ userId, roleKey }: { userId: string; roleKey: string }) => {
      await http.delete(`/admin/users/${userId}/roles/${roleKey}`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-users'] });
      toast({ title: 'Role revoked successfully' });
    },
    onError: (error: any) => {
      toast({
        title: 'Failed to revoke role',
        description: error.message || 'An error occurred',
        variant: 'destructive'
      });
    },
  });

  // Invite user mutation
  const inviteUserMutation = useMutation({
    mutationFn: async (email: string) => {
      await http.post('/admin/users/invite', { email });
    },
    onSuccess: () => {
      toast({
        title: 'Invitation sent',
        description: `An invitation email has been sent to ${newUserEmail}`
      });
      setInviteDialogOpen(false);
      setNewUserEmail('');
      setEmailError('');
      queryClient.invalidateQueries({ queryKey: ['admin-users'] });
    },
    onError: (error: any) => {
      const errorMessage = error.message || 'Failed to send invitation';
      setEmailError(errorMessage);
      toast({
        title: 'Failed to invite user',
        description: errorMessage,
        variant: 'destructive'
      });
    },
  });

  // Handlers
  const handleGrantRole = (userId: string, roleKey: string) => {
    grantRoleMutation.mutate({ userId, roleKey });
  };

  const handleRevokeRole = (userId: string, roleKey: string) => {
    revokeRoleMutation.mutate({ userId, roleKey });
  };

  const handleInviteUser = () => {
    // Validate email
    setEmailError('');
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

    if (!newUserEmail.trim()) {
      setEmailError('Email is required');
      return;
    }

    if (!emailRegex.test(newUserEmail)) {
      setEmailError('Please enter a valid email address');
      return;
    }

    inviteUserMutation.mutate(newUserEmail);
  };

  const getAvailableRoles = (currentRoles: string[]): RoleDefinition[] => {
    if (!rolesData?.roles) return [];
    return rolesData.roles.filter(role => !currentRoles.includes(role.key));
  };

  const getRoleDisplayName = (roleKey: string): string => {
    const role = rolesData?.roles.find(r => r.key === roleKey);
    return role?.display_name || roleKey;
  };

  // Access control
  if (!isAdmin()) {
    return (
      <div className="container mx-auto p-6">
        <Card>
          <CardContent className="flex flex-col items-center justify-center py-12">
            <Shield className="h-12 w-12 text-muted-foreground mb-4" />
            <p className="text-lg font-semibold">Admin Access Required</p>
            <p className="text-sm text-muted-foreground">
              You need admin privileges to access this page
            </p>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="container mx-auto p-6 space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div className="flex items-center gap-3">
          <UsersIcon className="h-8 w-8 text-primary" />
          <div>
            <h1 className="text-3xl font-bold">Users & Roles</h1>
            <p className="text-sm text-muted-foreground">Manage user accounts and permissions</p>
          </div>
        </div>
        <Button onClick={() => setInviteDialogOpen(true)}>
          <Mail className="mr-2 h-4 w-4" />
          Invite User
        </Button>
      </div>

      {/* Search Bar */}
      <Card className="p-4">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <Input
            placeholder="Search by email..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pl-10"
          />
        </div>
      </Card>

      {/* Users Table */}
      <Card>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Email</TableHead>
              <TableHead>Roles</TableHead>
              <TableHead>Last Sign In</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {isLoadingUsers ? (
              <TableRow>
                <TableCell colSpan={3} className="text-center py-12">
                  <Loader2 className="h-6 w-6 animate-spin mx-auto mb-2" />
                  <p className="text-sm text-muted-foreground">Loading users...</p>
                </TableCell>
              </TableRow>
            ) : usersError ? (
              <TableRow>
                <TableCell colSpan={3} className="text-center py-12">
                  <Shield className="h-6 w-6 text-destructive mx-auto mb-2" />
                  <p className="text-sm text-destructive">Failed to load users</p>
                </TableCell>
              </TableRow>
            ) : !usersData?.users || usersData.users.length === 0 ? (
              <TableRow>
                <TableCell colSpan={3} className="text-center py-12">
                  <UsersIcon className="h-6 w-6 text-muted-foreground mx-auto mb-2" />
                  <p className="text-sm text-muted-foreground">
                    {searchQuery ? 'No users found matching your search' : 'No users found'}
                  </p>
                </TableCell>
              </TableRow>
            ) : (
              usersData.users.map((user) => {
                const availableRoles = getAvailableRoles(user.roles);

                return (
                  <TableRow key={user.id}>
                    <TableCell className="font-medium">{user.email}</TableCell>
                    <TableCell>
                      <div className="flex flex-wrap gap-1.5">
                        {user.roles.map((roleKey) => (
                          <Badge
                            key={roleKey}
                            variant="secondary"
                            className={`${ROLE_COLORS[roleKey] || ''} gap-1.5 pr-1`}
                          >
                            <Shield className="h-3 w-3" />
                            {getRoleDisplayName(roleKey)}
                            <button
                              onClick={() => handleRevokeRole(user.id, roleKey)}
                              className="ml-0.5 hover:bg-black/10 dark:hover:bg-white/10 rounded-sm p-0.5 transition-colors"
                              title={`Revoke ${roleKey} role`}
                              aria-label={`Revoke ${roleKey} role from ${user.email}`}
                            >
                              <X className="h-3 w-3" />
                            </button>
                          </Badge>
                        ))}

                        {/* Add Role Dropdown */}
                        {availableRoles.length > 0 && (
                          <DropdownMenu>
                            <DropdownMenuTrigger asChild>
                              <Button
                                variant="outline"
                                size="sm"
                                className="h-6 px-2 border-dashed"
                                title="Add role"
                                aria-label={`Add role to ${user.email}`}
                              >
                                <Plus className="h-3 w-3" />
                              </Button>
                            </DropdownMenuTrigger>
                            <DropdownMenuContent align="start">
                              <DropdownMenuLabel>Add Role</DropdownMenuLabel>
                              <DropdownMenuSeparator />
                              {availableRoles.map((role) => (
                                <DropdownMenuItem
                                  key={role.key}
                                  onClick={() => handleGrantRole(user.id, role.key)}
                                >
                                  <Shield className="mr-2 h-4 w-4" />
                                  <div className="flex flex-col">
                                    <span className="font-medium">{role.display_name}</span>
                                    <span className="text-xs text-muted-foreground">
                                      {role.description}
                                    </span>
                                  </div>
                                </DropdownMenuItem>
                              ))}
                            </DropdownMenuContent>
                          </DropdownMenu>
                        )}
                      </div>
                    </TableCell>
                    <TableCell className="text-muted-foreground">
                      {user.last_sign_in_at
                        ? new Date(user.last_sign_in_at).toLocaleDateString(undefined, {
                            year: 'numeric',
                            month: 'short',
                            day: 'numeric',
                          })
                        : 'Never'}
                    </TableCell>
                  </TableRow>
                );
              })
            )}
          </TableBody>
        </Table>
      </Card>

      {/* Invite User Dialog */}
      <Dialog open={inviteDialogOpen} onOpenChange={setInviteDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Invite New User</DialogTitle>
            <DialogDescription>
              Send an email invitation to a new user. They will receive a link to create their account.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="invite-email">Email Address</Label>
              <Input
                id="invite-email"
                placeholder="user@example.com"
                type="email"
                value={newUserEmail}
                onChange={(e) => {
                  setNewUserEmail(e.target.value);
                  setEmailError('');
                }}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' && !inviteUserMutation.isPending) {
                    handleInviteUser();
                  }
                }}
                aria-invalid={!!emailError}
                aria-describedby={emailError ? 'email-error' : undefined}
              />
              {emailError && (
                <p id="email-error" className="text-sm text-destructive">
                  {emailError}
                </p>
              )}
            </div>
          </div>
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => {
                setInviteDialogOpen(false);
                setNewUserEmail('');
                setEmailError('');
              }}
              disabled={inviteUserMutation.isPending}
            >
              Cancel
            </Button>
            <Button
              onClick={handleInviteUser}
              disabled={inviteUserMutation.isPending || !newUserEmail.trim()}
            >
              {inviteUserMutation.isPending ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  Sending...
                </>
              ) : (
                <>
                  <Mail className="mr-2 h-4 w-4" />
                  Send Invitation
                </>
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
