/**
 * Feature Flags Admin Page
 * Ticket: FE-001
 * Date: 2025-10-19
 *
 * Admin interface for managing feature flags
 */

import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useAuth } from "@/hooks/useAuth";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Switch } from "@/components/ui/switch";
import { Badge } from "@/components/ui/badge";
import { useToast } from "@/hooks/use-toast";
import { Shield, Flag, AlertCircle } from "lucide-react";
import { http } from "@/api/http";

interface FeatureFlag {
  key: string;
  enabled: boolean;
  enabled_for_roles: string[] | null;
  description: string;
  created_at: string;
  updated_at: string;
}

export default function FeatureFlagsPage() {
  const { isAdmin } = useAuth();
  const { toast } = useToast();
  const queryClient = useQueryClient();

  // Fetch feature flags
  const { data: flags, isLoading } = useQuery<FeatureFlag[]>({
    queryKey: ["feature-flags"],
    queryFn: async () => {
      const response = await http.get<FeatureFlag[]>("/feature-flags");
      return response || [];
    },
  });

  // Toggle flag mutation
  const toggleMutation = useMutation({
    mutationFn: async ({ key, enabled }: { key: string; enabled: boolean }) => {
      return http.patch(`/feature-flags/${key}`, { enabled });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["feature-flags"] });
      toast({
        title: "Success",
        description: "Feature flag updated successfully",
      });
    },
    onError: (error: any) => {
      toast({
        title: "Error",
        description: error.message || "Failed to update feature flag",
        variant: "destructive",
      });
    },
  });

  const handleToggle = (key: string, currentEnabled: boolean) => {
    toggleMutation.mutate({ key, enabled: !currentEnabled });
  };

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
      <div className="flex items-center gap-3">
        <Flag className="h-8 w-8 text-primary" />
        <div>
          <h1 className="text-3xl font-bold">Feature Flags</h1>
          <p className="text-muted-foreground">
            Manage feature rollout and access control
          </p>
        </div>
      </div>

      {/* Warning Banner */}
      <Card className="border-yellow-500/50 bg-yellow-50 dark:bg-yellow-950/20">
        <CardContent className="flex items-start gap-3 pt-6">
          <AlertCircle className="h-5 w-5 text-yellow-600 dark:text-yellow-500 mt-0.5" />
          <div className="flex-1">
            <p className="font-semibold text-yellow-800 dark:text-yellow-200">
              Production Environment
            </p>
            <p className="text-sm text-yellow-700 dark:text-yellow-300">
              Changes to feature flags take effect immediately for all users.
              Use caution when enabling/disabling features.
            </p>
          </div>
        </CardContent>
      </Card>

      {/* Feature Flags List */}
      <div className="grid gap-4">
        {isLoading ? (
          <Card>
            <CardContent className="py-12 text-center">
              <p className="text-muted-foreground">Loading feature flags...</p>
            </CardContent>
          </Card>
        ) : flags && flags.length > 0 ? (
          flags.map((flag) => (
            <Card key={flag.key}>
              <CardHeader>
                <div className="flex items-start justify-between">
                  <div className="space-y-1">
                    <CardTitle className="flex items-center gap-2">
                      {flag.key}
                      {flag.enabled && (
                        <Badge variant="default" className="ml-2">
                          Enabled
                        </Badge>
                      )}
                      {!flag.enabled && (
                        <Badge variant="secondary" className="ml-2">
                          Disabled
                        </Badge>
                      )}
                    </CardTitle>
                    <CardDescription>{flag.description}</CardDescription>
                    {flag.enabled_for_roles && flag.enabled_for_roles.length > 0 && (
                      <div className="flex items-center gap-2 mt-2">
                        <span className="text-xs text-muted-foreground">
                          Roles:
                        </span>
                        {flag.enabled_for_roles.map((role) => (
                          <Badge key={role} variant="outline" className="text-xs">
                            {role}
                          </Badge>
                        ))}
                      </div>
                    )}
                  </div>
                  <Switch
                    checked={flag.enabled}
                    onCheckedChange={() => handleToggle(flag.key, flag.enabled)}
                    disabled={toggleMutation.isPending}
                  />
                </div>
              </CardHeader>
            </Card>
          ))
        ) : (
          <Card>
            <CardContent className="py-12 text-center">
              <Flag className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
              <p className="text-muted-foreground">No feature flags found</p>
            </CardContent>
          </Card>
        )}
      </div>
    </div>
  );
}
