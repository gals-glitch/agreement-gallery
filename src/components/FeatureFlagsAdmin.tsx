/**
 * Feature Flags Admin Component
 * Ticket: ORC-001
 * Date: 2025-10-19
 *
 * Admin interface for managing feature flags:
 * - View all flags with their status
 * - Toggle flags on/off
 * - Configure role-based access
 * - Admin-only access (enforced by backend)
 */

import React, { useState } from 'react';
import {
  useFeatureFlags,
  useUpdateFeatureFlag,
  type FeatureFlag,
  type UpdateFeatureFlagRequest,
} from '@/hooks/useFeatureFlags';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { Switch } from '@/components/ui/switch';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Checkbox } from '@/components/ui/checkbox';
import { Label } from '@/components/ui/label';
import { Loader2 } from 'lucide-react';

// ============================================
// ROLE OPTIONS
// ============================================
const AVAILABLE_ROLES = [
  { value: 'viewer', label: 'Viewer' },
  { value: 'ops', label: 'Operations' },
  { value: 'finance', label: 'Finance' },
  { value: 'admin', label: 'Admin' },
];

// ============================================
// MAIN COMPONENT
// ============================================
export function FeatureFlagsAdmin() {
  const { data: flags, isLoading, error } = useFeatureFlags();
  const updateFlag = useUpdateFeatureFlag();

  const [editingFlag, setEditingFlag] = useState<FeatureFlag | null>(null);
  const [selectedRoles, setSelectedRoles] = useState<string[]>([]);

  // ============================================
  // HANDLERS
  // ============================================
  const handleToggleEnabled = (flag: FeatureFlag) => {
    updateFlag.mutate({
      key: flag.key,
      updates: { enabled: !flag.enabled },
    });
  };

  const handleOpenRolesDialog = (flag: FeatureFlag) => {
    setEditingFlag(flag);
    setSelectedRoles(flag.enabled_for_roles || []);
  };

  const handleSaveRoles = () => {
    if (!editingFlag) return;

    const updates: UpdateFeatureFlagRequest = {
      enabled_for_roles: selectedRoles.length > 0 ? selectedRoles : [],
    };

    updateFlag.mutate(
      {
        key: editingFlag.key,
        updates,
      },
      {
        onSuccess: () => {
          setEditingFlag(null);
          setSelectedRoles([]);
        },
      }
    );
  };

  const handleToggleRole = (role: string) => {
    setSelectedRoles(prev =>
      prev.includes(role)
        ? prev.filter(r => r !== role)
        : [...prev, role]
    );
  };

  // ============================================
  // LOADING STATE
  // ============================================
  if (isLoading) {
    return (
      <Card>
        <CardContent className="flex items-center justify-center p-8">
          <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
        </CardContent>
      </Card>
    );
  }

  // ============================================
  // ERROR STATE
  // ============================================
  if (error) {
    return (
      <Card>
        <CardContent className="p-8">
          <p className="text-destructive">
            Failed to load feature flags: {error.message}
          </p>
        </CardContent>
      </Card>
    );
  }

  // ============================================
  // RENDER
  // ============================================
  return (
    <>
      <Card>
        <CardHeader>
          <CardTitle>Feature Flags Management</CardTitle>
          <CardDescription>
            Control feature rollout and role-based access. Changes take effect immediately.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Feature</TableHead>
                <TableHead>Description</TableHead>
                <TableHead>Enabled</TableHead>
                <TableHead>Roles</TableHead>
                <TableHead>Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {flags?.map(flag => (
                <TableRow key={flag.key}>
                  <TableCell className="font-medium">
                    <code className="text-sm">{flag.key}</code>
                  </TableCell>
                  <TableCell className="text-sm text-muted-foreground">
                    {flag.description}
                  </TableCell>
                  <TableCell>
                    <Switch
                      checked={flag.enabled}
                      onCheckedChange={() => handleToggleEnabled(flag)}
                      disabled={updateFlag.isPending}
                    />
                  </TableCell>
                  <TableCell>
                    {flag.enabled_for_roles === null ? (
                      <Badge variant="secondary">All Roles</Badge>
                    ) : flag.enabled_for_roles.length === 0 ? (
                      <Badge variant="outline">No Roles</Badge>
                    ) : (
                      <div className="flex flex-wrap gap-1">
                        {flag.enabled_for_roles.map(role => (
                          <Badge key={role} variant="default" className="text-xs">
                            {role}
                          </Badge>
                        ))}
                      </div>
                    )}
                  </TableCell>
                  <TableCell>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => handleOpenRolesDialog(flag)}
                      disabled={updateFlag.isPending}
                    >
                      Edit Roles
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      {/* Roles Edit Dialog */}
      <Dialog open={!!editingFlag} onOpenChange={() => setEditingFlag(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Configure Role Access</DialogTitle>
            <DialogDescription>
              Select which roles can access the feature "{editingFlag?.key}".
              Leave all unchecked to disable for all roles.
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            {AVAILABLE_ROLES.map(role => (
              <div key={role.value} className="flex items-center space-x-2">
                <Checkbox
                  id={`role-${role.value}`}
                  checked={selectedRoles.includes(role.value)}
                  onCheckedChange={() => handleToggleRole(role.value)}
                />
                <Label
                  htmlFor={`role-${role.value}`}
                  className="text-sm font-normal cursor-pointer"
                >
                  {role.label}
                </Label>
              </div>
            ))}
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setEditingFlag(null)}>
              Cancel
            </Button>
            <Button onClick={handleSaveRoles} disabled={updateFlag.isPending}>
              {updateFlag.isPending && (
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              )}
              Save
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
