/**
 * System Settings Admin Page
 * Ticket: P1-A3b
 * Date: 2025-10-19
 *
 * Features:
 * - Organization settings (name, currency, timezone, invoice prefix)
 * - VAT configuration link
 * - Admin quick links
 * - Admin-only edit permissions with read-only view for others
 */

import { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import { http } from '@/api/http';
import { useAuth } from '@/hooks/useAuth';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Separator } from '@/components/ui/separator';
import { useToast } from '@/hooks/use-toast';
import {
  Building,
  DollarSign,
  Receipt,
  Shield,
  Settings as SettingsIcon,
  Flag,
  Users,
  Loader2,
  Save,
  ExternalLink,
  Clock,
} from 'lucide-react';

// Type definitions
interface OrgSettings {
  org_name: string;
  default_currency: string;
  timezone: string;
  invoice_prefix: string;
}

interface SettingsResponse {
  settings: OrgSettings;
}

// Currency options
const CURRENCIES = [
  { value: 'USD', label: 'USD ($)', symbol: '$' },
  { value: 'EUR', label: 'EUR (€)', symbol: '€' },
  { value: 'GBP', label: 'GBP (£)', symbol: '£' },
  { value: 'ILS', label: 'ILS (₪)', symbol: '₪' },
];

// Common timezones
const TIMEZONES = [
  { value: 'UTC', label: 'UTC (Coordinated Universal Time)' },
  { value: 'America/New_York', label: 'Eastern Time (US & Canada)' },
  { value: 'America/Chicago', label: 'Central Time (US & Canada)' },
  { value: 'America/Denver', label: 'Mountain Time (US & Canada)' },
  { value: 'America/Los_Angeles', label: 'Pacific Time (US & Canada)' },
  { value: 'Europe/London', label: 'London (GMT/BST)' },
  { value: 'Europe/Paris', label: 'Central European Time' },
  { value: 'Asia/Jerusalem', label: 'Israel Time' },
  { value: 'Asia/Dubai', label: 'Dubai Time' },
  { value: 'Asia/Tokyo', label: 'Tokyo Time' },
  { value: 'Australia/Sydney', label: 'Sydney Time' },
];

export default function SettingsPage() {
  const { isAdmin } = useAuth();
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const navigate = useNavigate();

  // Local state for form
  const [formData, setFormData] = useState<OrgSettings>({
    org_name: '',
    default_currency: 'USD',
    timezone: 'UTC',
    invoice_prefix: 'BC-',
  });

  const [hasChanges, setHasChanges] = useState(false);

  // Fetch org settings
  const {
    data: settingsData,
    isLoading: isLoadingSettings,
    error: settingsError,
  } = useQuery<SettingsResponse>({
    queryKey: ['admin-settings'],
    queryFn: async () => {
      const response = await http.get<SettingsResponse>('/admin/settings');
      return response;
    },
  });

  // Update form when data loads
  useEffect(() => {
    if (settingsData?.settings) {
      setFormData(settingsData.settings);
    }
  }, [settingsData]);

  // Update settings mutation
  const updateSettingsMutation = useMutation({
    mutationFn: async (data: OrgSettings) => {
      await http.put('/admin/settings', data);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-settings'] });
      toast({ title: 'Settings saved successfully' });
      setHasChanges(false);
    },
    onError: (error: any) => {
      toast({
        title: 'Failed to save settings',
        description: error.message || 'An error occurred',
        variant: 'destructive',
      });
    },
  });

  // Handlers
  const handleFieldChange = (field: keyof OrgSettings, value: string) => {
    setFormData((prev) => ({ ...prev, [field]: value }));
    setHasChanges(true);
  };

  const handleSaveSettings = () => {
    updateSettingsMutation.mutate(formData);
  };

  const handleResetForm = () => {
    if (settingsData?.settings) {
      setFormData(settingsData.settings);
      setHasChanges(false);
    }
  };

  // Access control - Settings can be viewed by anyone, but only admins can edit
  const canEdit = isAdmin();

  return (
    <div className="container mx-auto p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center gap-3">
        <SettingsIcon className="h-8 w-8 text-primary" />
        <div>
          <h1 className="text-3xl font-bold">System Settings</h1>
          <p className="text-sm text-muted-foreground">Configure system-wide settings and preferences</p>
        </div>
      </div>

      <Tabs defaultValue="organization" className="space-y-6">
        <TabsList className="grid w-full grid-cols-3 max-w-md">
          <TabsTrigger value="organization" className="gap-2">
            <Building className="h-4 w-4" />
            Organization
          </TabsTrigger>
          <TabsTrigger value="vat" className="gap-2">
            <Receipt className="h-4 w-4" />
            VAT
          </TabsTrigger>
          <TabsTrigger value="links" className="gap-2">
            <Shield className="h-4 w-4" />
            Links
          </TabsTrigger>
        </TabsList>

        {/* Organization Tab */}
        <TabsContent value="organization" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Building className="h-5 w-5" />
                Organization Settings
              </CardTitle>
              <CardDescription>
                Configure your organization's basic information and defaults
              </CardDescription>
            </CardHeader>
            <CardContent>
              {isLoadingSettings ? (
                <div className="flex items-center justify-center py-12">
                  <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
                  <span className="ml-3 text-sm text-muted-foreground">Loading settings...</span>
                </div>
              ) : settingsError ? (
                <div className="flex items-center justify-center py-12">
                  <Shield className="h-6 w-6 text-destructive" />
                  <span className="ml-3 text-sm text-destructive">Failed to load settings</span>
                </div>
              ) : (
                <div className="space-y-6">
                  {/* Organization Name */}
                  <div className="space-y-2">
                    <Label htmlFor="org_name" className="flex items-center gap-2">
                      <Building className="h-4 w-4" />
                      Organization Name
                    </Label>
                    <Input
                      id="org_name"
                      value={formData.org_name}
                      onChange={(e) => handleFieldChange('org_name', e.target.value)}
                      disabled={!canEdit}
                      placeholder="Your Organization Name"
                    />
                    <p className="text-xs text-muted-foreground">
                      This name appears in invoices and system communications
                    </p>
                  </div>

                  <Separator />

                  {/* Default Currency */}
                  <div className="space-y-2">
                    <Label htmlFor="currency" className="flex items-center gap-2">
                      <DollarSign className="h-4 w-4" />
                      Default Currency
                    </Label>
                    <Select
                      value={formData.default_currency}
                      onValueChange={(value) => handleFieldChange('default_currency', value)}
                      disabled={!canEdit}
                    >
                      <SelectTrigger id="currency">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        {CURRENCIES.map((currency) => (
                          <SelectItem key={currency.value} value={currency.value}>
                            {currency.label}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    <p className="text-xs text-muted-foreground">
                      Default currency for new transactions and calculations
                    </p>
                  </div>

                  <Separator />

                  {/* Timezone */}
                  <div className="space-y-2">
                    <Label htmlFor="timezone" className="flex items-center gap-2">
                      <Clock className="h-4 w-4" />
                      Timezone
                    </Label>
                    <Select
                      value={formData.timezone}
                      onValueChange={(value) => handleFieldChange('timezone', value)}
                      disabled={!canEdit}
                    >
                      <SelectTrigger id="timezone">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        {TIMEZONES.map((tz) => (
                          <SelectItem key={tz.value} value={tz.value}>
                            {tz.label}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    <p className="text-xs text-muted-foreground">
                      Default timezone for date/time displays and reports
                    </p>
                  </div>

                  <Separator />

                  {/* Invoice Prefix */}
                  <div className="space-y-2">
                    <Label htmlFor="invoice_prefix" className="flex items-center gap-2">
                      <Receipt className="h-4 w-4" />
                      Invoice Prefix
                    </Label>
                    <Input
                      id="invoice_prefix"
                      value={formData.invoice_prefix}
                      onChange={(e) => handleFieldChange('invoice_prefix', e.target.value)}
                      disabled={!canEdit}
                      placeholder="BC-"
                      maxLength={10}
                    />
                    <p className="text-xs text-muted-foreground">
                      Prefix for invoice numbers (e.g., BC-2024-001)
                    </p>
                  </div>

                  {/* Action Buttons */}
                  {canEdit && (
                    <>
                      <Separator />
                      <div className="flex gap-3">
                        <Button
                          onClick={handleSaveSettings}
                          disabled={!hasChanges || updateSettingsMutation.isPending}
                        >
                          {updateSettingsMutation.isPending ? (
                            <>
                              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                              Saving...
                            </>
                          ) : (
                            <>
                              <Save className="mr-2 h-4 w-4" />
                              Save Settings
                            </>
                          )}
                        </Button>
                        <Button
                          variant="outline"
                          onClick={handleResetForm}
                          disabled={!hasChanges || updateSettingsMutation.isPending}
                        >
                          Reset
                        </Button>
                      </div>
                    </>
                  )}

                  {!canEdit && (
                    <>
                      <Separator />
                      <div className="rounded-lg bg-muted p-4">
                        <div className="flex items-center gap-2 text-sm text-muted-foreground">
                          <Shield className="h-4 w-4" />
                          <span>You are viewing in read-only mode. Admin role required to edit settings.</span>
                        </div>
                      </div>
                    </>
                  )}
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        {/* VAT Tab */}
        <TabsContent value="vat" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Receipt className="h-5 w-5" />
                VAT Configuration
              </CardTitle>
              <CardDescription>
                Manage temporal VAT rates for your organization
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="rounded-lg border border-border bg-muted/50 p-6">
                <div className="space-y-4">
                  <div className="flex items-start gap-3">
                    <Receipt className="h-5 w-5 text-primary mt-0.5" />
                    <div className="space-y-2 flex-1">
                      <h3 className="font-medium">Temporal VAT Rates</h3>
                      <p className="text-sm text-muted-foreground">
                        VAT rates are managed temporally with effective date ranges. Changes to rates do not
                        affect existing agreement snapshots - only new agreements created after the effective
                        date will use the updated rates.
                      </p>
                    </div>
                  </div>

                  <Separator />

                  <div className="space-y-3">
                    <h4 className="text-sm font-medium">Current Configuration</h4>
                    <ul className="space-y-2 text-sm text-muted-foreground">
                      <li className="flex items-center gap-2">
                        <div className="h-1.5 w-1.5 rounded-full bg-primary" />
                        View and manage active VAT rates
                      </li>
                      <li className="flex items-center gap-2">
                        <div className="h-1.5 w-1.5 rounded-full bg-primary" />
                        Schedule future rate changes
                      </li>
                      <li className="flex items-center gap-2">
                        <div className="h-1.5 w-1.5 rounded-full bg-primary" />
                        Review historical rates and overlaps
                      </li>
                    </ul>
                  </div>
                </div>
              </div>

              <Button
                onClick={() => navigate('/vat-settings')}
                className="w-full sm:w-auto"
              >
                <Receipt className="mr-2 h-4 w-4" />
                Manage VAT Rates
                <ExternalLink className="ml-2 h-4 w-4" />
              </Button>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Links Tab */}
        <TabsContent value="links" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Shield className="h-5 w-5" />
                Admin Quick Links
              </CardTitle>
              <CardDescription>
                Quick access to administrative features and tools
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid gap-3 sm:grid-cols-2">
                {/* Feature Flags */}
                <Button
                  variant="outline"
                  onClick={() => navigate('/admin/feature-flags')}
                  className="h-auto justify-start p-4 flex-col items-start gap-2"
                >
                  <div className="flex items-center gap-2 w-full">
                    <Flag className="h-5 w-5 text-primary" />
                    <span className="font-semibold">Feature Flags</span>
                  </div>
                  <p className="text-xs text-muted-foreground text-left">
                    Toggle features and experimental functionality
                  </p>
                </Button>

                {/* Users & Roles */}
                <Button
                  variant="outline"
                  onClick={() => navigate('/admin/users')}
                  className="h-auto justify-start p-4 flex-col items-start gap-2"
                >
                  <div className="flex items-center gap-2 w-full">
                    <Users className="h-5 w-5 text-primary" />
                    <span className="font-semibold">Users & Roles</span>
                  </div>
                  <p className="text-xs text-muted-foreground text-left">
                    Manage user accounts and permissions
                  </p>
                </Button>

                {/* VAT Settings */}
                <Button
                  variant="outline"
                  onClick={() => navigate('/vat-settings')}
                  className="h-auto justify-start p-4 flex-col items-start gap-2"
                >
                  <div className="flex items-center gap-2 w-full">
                    <Receipt className="h-5 w-5 text-primary" />
                    <span className="font-semibold">VAT Settings</span>
                  </div>
                  <p className="text-xs text-muted-foreground text-left">
                    Configure temporal VAT rates
                  </p>
                </Button>

                {/* Settings (current page) */}
                <Button
                  variant="outline"
                  disabled
                  className="h-auto justify-start p-4 flex-col items-start gap-2 opacity-50"
                >
                  <div className="flex items-center gap-2 w-full">
                    <SettingsIcon className="h-5 w-5 text-muted-foreground" />
                    <span className="font-semibold">Settings</span>
                  </div>
                  <p className="text-xs text-muted-foreground text-left">
                    Current page - Organization configuration
                  </p>
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
