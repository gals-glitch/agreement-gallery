/**
 * AgreementForm V2 - Compatible with redesigned agreements schema
 *
 * Schema: party_id, scope (FUND|DEAL), pricing_mode (TRACK|CUSTOM), selected_track (A|B|C), status
 *
 * Business Rules:
 * - FUND scope → MUST use TRACK pricing
 * - DEAL scope → CAN use TRACK or CUSTOM pricing
 * - TRACK pricing → MUST select track (A/B/C)
 * - Approved agreements → IMMUTABLE
 */

import { useState, useEffect } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Checkbox } from '@/components/ui/checkbox';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { AlertCircle, CheckCircle, TrendingUp, Lock, Info, Plus, FileText, Edit, Send, CheckSquare, XCircle, Calendar, DollarSign } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '@/components/ui/dialog';

// ============================================
// TYPES
// ============================================
type AgreementScope = 'FUND' | 'DEAL';
type PricingMode = 'TRACK' | 'CUSTOM';
type TrackCode = 'A' | 'B' | 'C';
type AgreementStatus = 'DRAFT' | 'AWAITING_APPROVAL' | 'APPROVED' | 'SUPERSEDED';

interface Party {
  id: number;
  name: string;
  active: boolean;
}

interface Fund {
  id: number;
  name: string;
}

interface Deal {
  id: number;
  name: string;
  fund_id: number | null;
}

interface FundTrack {
  id: number;
  fund_id: number;
  track_code: TrackCode;
  upfront_bps: number;
  deferred_bps: number;
  offset_months: number;
  tier_min: number | null;
  tier_max: number | null;
  seed_version: number;
}

interface AgreementFormData {
  party_id: string;
  scope: AgreementScope;
  fund_id: string;
  deal_id: string;
  pricing_mode: PricingMode;
  selected_track: TrackCode | '';
  custom_upfront_bps: string;
  custom_deferred_bps: string;
  effective_from: string;
  effective_to: string;
  vat_included: boolean;
}

interface Agreement {
  id: number;
  party_id: number;
  scope: AgreementScope;
  fund_id: number | null;
  deal_id: number | null;
  pricing_mode: PricingMode;
  selected_track: TrackCode | null;
  effective_from: string;
  effective_to: string | null;
  vat_included: boolean;
  status: AgreementStatus;
  created_at: string;
}

interface AgreementWithDetails extends Agreement {
  party_name: string;
  fund_name: string | null;
  deal_name: string | null;
  custom_upfront_bps: number | null;
  custom_deferred_bps: number | null;
}

interface RateSnapshot {
  id: number;
  agreement_id: number;
  resolved_upfront_bps: number;
  resolved_deferred_bps: number;
  vat_included: boolean;
  effective_from: string;
  effective_to: string | null;
  seed_version: number | null;
  created_at: string;
}

// ============================================
// COMPONENT
// ============================================
export default function AgreementFormV2() {
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const [viewMode, setViewMode] = useState<'list' | 'create'>('list');
  const [editingAgreementId, setEditingAgreementId] = useState<number | null>(null);
  const [viewingAgreement, setViewingAgreement] = useState<AgreementWithDetails | null>(null);
  const [formData, setFormData] = useState<AgreementFormData>({
    party_id: '',
    scope: 'FUND',
    fund_id: '',
    deal_id: '',
    pricing_mode: 'TRACK',
    selected_track: '',
    custom_upfront_bps: '',
    custom_deferred_bps: '',
    effective_from: new Date().toISOString().split('T')[0],
    effective_to: '',
    vat_included: false,
  });

  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  // ============================================
  // DATA FETCHING
  // ============================================
  const { data: parties = [] } = useQuery({
    queryKey: ['parties-active'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('parties')
        .select('id, name, active')
        .eq('active', true)
        .order('name');
      if (error) throw error;
      return (data || []) as Party[];
    },
  });

  const { data: funds = [] } = useQuery({
    queryKey: ['funds'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('funds')
        .select('id, name')
        .order('name');
      if (error) throw error;
      return (data || []) as Fund[];
    },
  });

  const { data: deals = [] } = useQuery({
    queryKey: ['deals-active'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('deals')
        .select('id, name, fund_id')
        .eq('status', 'ACTIVE')
        .order('name');
      if (error) throw error;
      return (data || []) as Deal[];
    },
  });

  const { data: fundTracks = [] } = useQuery({
    queryKey: ['fund-tracks', formData.fund_id || formData.deal_id],
    queryFn: async () => {
      let targetFundId: number | null = null;

      if (formData.scope === 'FUND' && formData.fund_id) {
        targetFundId = parseInt(formData.fund_id);
      } else if (formData.scope === 'DEAL' && formData.deal_id) {
        const deal = deals.find(d => d.id === parseInt(formData.deal_id));
        targetFundId = deal?.fund_id || null;
      }

      if (!targetFundId) return [];

      const { data, error } = await supabase
        .from('fund_tracks')
        .select('*')
        .eq('fund_id', targetFundId)
        .order('track_code');

      if (error) throw error;
      return (data || []) as FundTrack[];
    },
    enabled: !!(formData.fund_id || formData.deal_id),
  });

  const { data: agreements = [], isLoading: agreementsLoading } = useQuery({
    queryKey: ['agreements-with-details'],
    queryFn: async () => {
      // Fetch agreements
      const { data: agreementsData, error: agreementsError } = await supabase
        .from('agreements')
        .select('*')
        .order('created_at', { ascending: false });

      if (agreementsError) throw agreementsError;

      // Fetch related data
      const { data: partiesData } = await supabase.from('parties').select('id, name');
      const { data: fundsData } = await supabase.from('funds').select('id, name');
      const { data: dealsData } = await supabase.from('deals').select('id, name');
      const { data: customTermsData } = await supabase.from('agreement_custom_terms').select('*');

      // Map to details
      return (agreementsData || []).map((agreement): AgreementWithDetails => {
        const party = partiesData?.find(p => p.id === agreement.party_id);
        const fund = agreement.fund_id ? fundsData?.find(f => f.id === agreement.fund_id) : null;
        const deal = agreement.deal_id ? dealsData?.find(d => d.id === agreement.deal_id) : null;
        const customTerms = customTermsData?.find(ct => ct.agreement_id === agreement.id);

        return {
          ...agreement,
          party_name: party?.name || 'Unknown',
          fund_name: fund?.name || null,
          deal_name: deal?.name || null,
          custom_upfront_bps: customTerms?.upfront_bps || null,
          custom_deferred_bps: customTerms?.deferred_bps || null,
        };
      });
    },
  });

  const { data: snapshot } = useQuery({
    queryKey: ['agreement-snapshot', viewingAgreement?.id],
    queryFn: async () => {
      if (!viewingAgreement) return null;

      const { data, error } = await supabase
        .from('agreement_rate_snapshots')
        .select('*')
        .eq('agreement_id', viewingAgreement.id)
        .single();

      if (error) throw error;
      return data as RateSnapshot;
    },
    enabled: !!viewingAgreement && viewingAgreement.status === 'APPROVED',
  });

  // ============================================
  // BUSINESS LOGIC
  // ============================================

  // Auto-set pricing mode based on scope
  useEffect(() => {
    if (formData.scope === 'FUND') {
      // FUND must use TRACK
      setFormData(prev => ({ ...prev, pricing_mode: 'TRACK' }));
    }
    // DEAL can use either TRACK or CUSTOM (no auto-change)
  }, [formData.scope]);

  // Clear target when scope changes
  useEffect(() => {
    setFormData(prev => ({
      ...prev,
      fund_id: '',
      deal_id: '',
      selected_track: '',
    }));
  }, [formData.scope]);

  // Get selected track details
  const selectedTrackDetails = fundTracks.find(t => t.track_code === formData.selected_track);

  // ============================================
  // WORKFLOW ACTIONS
  // ============================================

  const handleEdit = (agreement: AgreementWithDetails) => {
    // Load agreement data into form
    setFormData({
      party_id: agreement.party_id.toString(),
      scope: agreement.scope,
      fund_id: agreement.fund_id?.toString() || '',
      deal_id: agreement.deal_id?.toString() || '',
      pricing_mode: agreement.pricing_mode,
      selected_track: (agreement.selected_track as TrackCode) || '',
      custom_upfront_bps: agreement.custom_upfront_bps?.toString() || '',
      custom_deferred_bps: agreement.custom_deferred_bps?.toString() || '',
      effective_from: agreement.effective_from,
      effective_to: agreement.effective_to || '',
      vat_included: agreement.vat_included,
    });
    setEditingAgreementId(agreement.id);
    setViewMode('create');
  };

  const handleSubmitForApproval = async (agreementId: number) => {
    try {
      const { error } = await supabase
        .from('agreements')
        .update({ status: 'AWAITING_APPROVAL' })
        .eq('id', agreementId);

      if (error) throw error;

      toast({
        title: 'Success',
        description: 'Agreement submitted for approval',
      });

      queryClient.invalidateQueries({ queryKey: ['agreements-with-details'] });
    } catch (error) {
      console.error('Submit error:', error);
      toast({
        title: 'Error',
        description: error instanceof Error ? error.message : 'Failed to submit agreement',
        variant: 'destructive',
      });
    }
  };

  const handleApprove = async (agreementId: number) => {
    try {
      // Get the agreement to create snapshot
      const agreement = agreements.find(a => a.id === agreementId);
      if (!agreement) throw new Error('Agreement not found');

      // Determine resolved rates
      let resolved_upfront_bps: number;
      let resolved_deferred_bps: number;
      let seed_version: number | null = null;

      if (agreement.pricing_mode === 'TRACK' && agreement.selected_track) {
        // Get track details
        const { data: trackData, error: trackError } = await supabase
          .from('fund_tracks')
          .select('*')
          .eq('fund_id', agreement.fund_id || 0)
          .eq('track_code', agreement.selected_track)
          .single();

        if (trackError) throw trackError;

        resolved_upfront_bps = trackData.upfront_bps;
        resolved_deferred_bps = trackData.deferred_bps;
        seed_version = trackData.seed_version;
      } else {
        // Custom rates
        resolved_upfront_bps = agreement.custom_upfront_bps!;
        resolved_deferred_bps = agreement.custom_deferred_bps!;
      }

      // Update agreement status
      const { error: updateError } = await supabase
        .from('agreements')
        .update({ status: 'APPROVED' })
        .eq('id', agreementId);

      if (updateError) throw updateError;

      // Create snapshot
      const { error: snapshotError } = await supabase
        .from('agreement_rate_snapshots')
        .insert([{
          agreement_id: agreementId,
          resolved_upfront_bps,
          resolved_deferred_bps,
          vat_included: agreement.vat_included,
          effective_from: agreement.effective_from,
          effective_to: agreement.effective_to,
          seed_version,
        }]);

      if (snapshotError) throw snapshotError;

      toast({
        title: 'Success',
        description: 'Agreement approved and snapshot created',
      });

      queryClient.invalidateQueries({ queryKey: ['agreements-with-details'] });
    } catch (error) {
      console.error('Approve error:', error);
      toast({
        title: 'Error',
        description: error instanceof Error ? error.message : 'Failed to approve agreement',
        variant: 'destructive',
      });
    }
  };

  const handleReject = async (agreementId: number) => {
    try {
      const { error } = await supabase
        .from('agreements')
        .update({ status: 'DRAFT' })
        .eq('id', agreementId);

      if (error) throw error;

      toast({
        title: 'Success',
        description: 'Agreement rejected and returned to draft',
      });

      queryClient.invalidateQueries({ queryKey: ['agreements-with-details'] });
    } catch (error) {
      console.error('Reject error:', error);
      toast({
        title: 'Error',
        description: error instanceof Error ? error.message : 'Failed to reject agreement',
        variant: 'destructive',
      });
    }
  };

  // ============================================
  // VALIDATION
  // ============================================
  const validate = (): boolean => {
    const newErrors: Record<string, string> = {};

    if (!formData.party_id) {
      newErrors.party_id = 'Party is required';
    }

    if (formData.scope === 'FUND' && !formData.fund_id) {
      newErrors.fund_id = 'Fund is required for FUND scope';
    }

    if (formData.scope === 'DEAL' && !formData.deal_id) {
      newErrors.deal_id = 'Deal is required for DEAL scope';
    }

    if (formData.pricing_mode === 'TRACK' && !formData.selected_track) {
      newErrors.selected_track = 'Track is required for TRACK pricing';
    }

    if (formData.pricing_mode === 'CUSTOM') {
      if (!formData.custom_upfront_bps || parseFloat(formData.custom_upfront_bps) < 0) {
        newErrors.custom_upfront_bps = 'Upfront rate must be >= 0';
      }
      if (!formData.custom_deferred_bps || parseFloat(formData.custom_deferred_bps) < 0) {
        newErrors.custom_deferred_bps = 'Deferred rate must be >= 0';
      }
    }

    if (!formData.effective_from) {
      newErrors.effective_from = 'Effective from date is required';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  // ============================================
  // SUBMIT
  // ============================================
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!validate()) {
      toast({
        title: 'Validation Error',
        description: 'Please fix the errors before submitting',
        variant: 'destructive',
      });
      return;
    }

    setIsSubmitting(true);

    try {
      // Prepare agreement data
      const agreementData: any = {
        party_id: parseInt(formData.party_id),
        scope: formData.scope,
        pricing_mode: formData.pricing_mode,
        effective_from: formData.effective_from,
        effective_to: formData.effective_to || null,
        vat_included: formData.vat_included,
        status: 'DRAFT',
      };

      // Add scope-specific fields
      if (formData.scope === 'FUND') {
        agreementData.fund_id = parseInt(formData.fund_id);
        agreementData.deal_id = null;
      } else {
        agreementData.deal_id = parseInt(formData.deal_id);
        agreementData.fund_id = null;
      }

      // Add pricing-specific fields
      if (formData.pricing_mode === 'TRACK') {
        agreementData.selected_track = formData.selected_track;
      } else {
        agreementData.selected_track = null;
      }

      if (editingAgreementId) {
        // Update existing agreement
        const { error: agreementError } = await supabase
          .from('agreements')
          .update(agreementData)
          .eq('id', editingAgreementId);

        if (agreementError) throw agreementError;

        // Handle custom pricing update
        if (formData.pricing_mode === 'CUSTOM') {
          // Check if custom terms already exist
          const { data: existingTerms } = await supabase
            .from('agreement_custom_terms')
            .select('*')
            .eq('agreement_id', editingAgreementId)
            .single();

          const termsData = {
            upfront_bps: parseInt(formData.custom_upfront_bps),
            deferred_bps: parseInt(formData.custom_deferred_bps),
          };

          if (existingTerms) {
            // Update existing terms
            const { error: termsError } = await supabase
              .from('agreement_custom_terms')
              .update(termsData)
              .eq('agreement_id', editingAgreementId);

            if (termsError) throw termsError;
          } else {
            // Insert new terms
            const { error: termsError } = await supabase
              .from('agreement_custom_terms')
              .insert([{ agreement_id: editingAgreementId, ...termsData }]);

            if (termsError) throw termsError;
          }
        } else {
          // If switched from CUSTOM to TRACK, delete custom terms
          await supabase
            .from('agreement_custom_terms')
            .delete()
            .eq('agreement_id', editingAgreementId);
        }

        toast({
          title: 'Success',
          description: 'Agreement updated successfully',
        });
      } else {
        // Insert new agreement
        const { data: agreement, error: agreementError } = await supabase
          .from('agreements')
          .insert([agreementData])
          .select()
          .single();

        if (agreementError) throw agreementError;

        // If custom pricing, insert custom terms
        if (formData.pricing_mode === 'CUSTOM') {
          const { error: termsError } = await supabase
            .from('agreement_custom_terms')
            .insert([{
              agreement_id: agreement.id,
              upfront_bps: parseInt(formData.custom_upfront_bps),
              deferred_bps: parseInt(formData.custom_deferred_bps),
            }]);

          if (termsError) throw termsError;
        }

        toast({
          title: 'Success',
          description: 'Agreement created successfully',
        });
      }

      // Refresh agreements list
      queryClient.invalidateQueries({ queryKey: ['agreements-with-details'] });

      // Reset form and return to list view
      setFormData({
        party_id: '',
        scope: 'FUND',
        fund_id: '',
        deal_id: '',
        pricing_mode: 'TRACK',
        selected_track: '',
        custom_upfront_bps: '',
        custom_deferred_bps: '',
        effective_from: new Date().toISOString().split('T')[0],
        effective_to: '',
        vat_included: false,
      });
      setEditingAgreementId(null);
      setViewMode('list');
    } catch (error) {
      console.error('Submit error:', error);
      toast({
        title: 'Error',
        description: error instanceof Error ? error.message : 'Failed to save agreement',
        variant: 'destructive',
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  // ============================================
  // HELPER FUNCTIONS
  // ============================================
  const getStatusBadge = (status: AgreementStatus) => {
    switch (status) {
      case 'DRAFT':
        return <Badge variant="outline">Draft</Badge>;
      case 'AWAITING_APPROVAL':
        return <Badge variant="secondary">Awaiting Approval</Badge>;
      case 'APPROVED':
        return <Badge variant="default" className="bg-green-600">Approved</Badge>;
      case 'SUPERSEDED':
        return <Badge variant="destructive">Superseded</Badge>;
    }
  };

  // ============================================
  // RENDER
  // ============================================

  if (viewMode === 'list') {
    return (
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle>Agreements</CardTitle>
              <CardDescription>
                Manage commission agreements for parties
              </CardDescription>
            </div>
            <Button onClick={() => setViewMode('create')}>
              <Plus className="w-4 h-4 mr-2" />
              New Agreement
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          {agreementsLoading ? (
            <div className="text-center py-8 text-muted-foreground">
              Loading agreements...
            </div>
          ) : agreements.length === 0 ? (
            <div className="text-center py-8">
              <FileText className="w-12 h-12 mx-auto text-muted-foreground mb-3" />
              <p className="text-muted-foreground">No agreements found</p>
              <Button variant="link" onClick={() => setViewMode('create')}>
                Create your first agreement
              </Button>
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Party</TableHead>
                  <TableHead>Scope</TableHead>
                  <TableHead>Target</TableHead>
                  <TableHead>Pricing</TableHead>
                  <TableHead>Rates</TableHead>
                  <TableHead>Effective</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {agreements.map((agreement) => (
                  <TableRow key={agreement.id}>
                    <TableCell className="font-medium">
                      {agreement.party_name}
                    </TableCell>
                    <TableCell>
                      <Badge variant="outline">
                        {agreement.scope}
                      </Badge>
                    </TableCell>
                    <TableCell>
                      {agreement.scope === 'FUND'
                        ? agreement.fund_name
                        : agreement.deal_name}
                    </TableCell>
                    <TableCell>
                      {agreement.pricing_mode === 'TRACK' ? (
                        <span className="flex items-center gap-1">
                          <TrendingUp className="w-3 h-3" />
                          Track {agreement.selected_track}
                        </span>
                      ) : (
                        <span className="flex items-center gap-1">
                          <Edit className="w-3 h-3" />
                          Custom
                        </span>
                      )}
                    </TableCell>
                    <TableCell className="text-sm">
                      {agreement.pricing_mode === 'CUSTOM' && agreement.custom_upfront_bps !== null ? (
                        <span>
                          {(agreement.custom_upfront_bps / 100).toFixed(2)}% / {(agreement.custom_deferred_bps! / 100).toFixed(2)}%
                        </span>
                      ) : (
                        <span className="text-muted-foreground">Track rates</span>
                      )}
                    </TableCell>
                    <TableCell className="text-sm">
                      {new Date(agreement.effective_from).toLocaleDateString()}
                      {agreement.effective_to && (
                        <> → {new Date(agreement.effective_to).toLocaleDateString()}</>
                      )}
                    </TableCell>
                    <TableCell>
                      {getStatusBadge(agreement.status)}
                    </TableCell>
                    <TableCell>
                      <div className="flex gap-1">
                        {agreement.status === 'DRAFT' && (
                          <>
                            <Button
                              variant="ghost"
                              size="sm"
                              title="Edit"
                              onClick={() => handleEdit(agreement)}
                            >
                              <Edit className="w-4 h-4" />
                            </Button>
                            <Button
                              variant="ghost"
                              size="sm"
                              title="Submit for Approval"
                              onClick={() => handleSubmitForApproval(agreement.id)}
                            >
                              <Send className="w-4 h-4" />
                            </Button>
                          </>
                        )}
                        {agreement.status === 'AWAITING_APPROVAL' && (
                          <>
                            <Button
                              variant="ghost"
                              size="sm"
                              title="Approve"
                              onClick={() => handleApprove(agreement.id)}
                            >
                              <CheckSquare className="w-4 h-4 text-green-600" />
                            </Button>
                            <Button
                              variant="ghost"
                              size="sm"
                              title="Reject"
                              onClick={() => handleReject(agreement.id)}
                            >
                              <XCircle className="w-4 h-4 text-red-600" />
                            </Button>
                          </>
                        )}
                        {agreement.status === 'APPROVED' && (
                          <Button
                            variant="ghost"
                            size="sm"
                            title="View Details"
                            onClick={() => setViewingAgreement(agreement)}
                          >
                            <FileText className="w-4 h-4" />
                          </Button>
                        )}
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}

          {/* View Agreement Dialog */}
          <Dialog open={!!viewingAgreement} onOpenChange={(open) => !open && setViewingAgreement(null)}>
            <DialogContent className="max-w-2xl">
              <DialogHeader>
                <DialogTitle className="flex items-center gap-2">
                  <Lock className="w-5 h-5" />
                  Agreement Details (Approved)
                </DialogTitle>
                <DialogDescription>
                  Immutable snapshot of approved agreement
                </DialogDescription>
              </DialogHeader>

              {viewingAgreement && (
                <div className="space-y-4">
                  {/* Agreement Info */}
                  <div className="grid grid-cols-2 gap-4 p-4 bg-muted rounded-lg">
                    <div>
                      <Label className="text-sm text-muted-foreground">Party</Label>
                      <p className="font-medium">{viewingAgreement.party_name}</p>
                    </div>
                    <div>
                      <Label className="text-sm text-muted-foreground">Scope</Label>
                      <p className="font-medium">
                        <Badge variant="outline">{viewingAgreement.scope}</Badge>
                      </p>
                    </div>
                    <div>
                      <Label className="text-sm text-muted-foreground">Target</Label>
                      <p className="font-medium">
                        {viewingAgreement.scope === 'FUND'
                          ? viewingAgreement.fund_name
                          : viewingAgreement.deal_name}
                      </p>
                    </div>
                    <div>
                      <Label className="text-sm text-muted-foreground">Pricing Mode</Label>
                      <p className="font-medium">
                        {viewingAgreement.pricing_mode === 'TRACK' ? (
                          <span className="flex items-center gap-1">
                            <TrendingUp className="w-3 h-3" />
                            Track {viewingAgreement.selected_track}
                          </span>
                        ) : (
                          <span className="flex items-center gap-1">
                            <Edit className="w-3 h-3" />
                            Custom
                          </span>
                        )}
                      </p>
                    </div>
                  </div>

                  <Separator />

                  {/* Snapshot Rates */}
                  {snapshot ? (
                    <div className="space-y-3">
                      <div className="flex items-center gap-2">
                        <DollarSign className="w-5 h-5 text-green-600" />
                        <h3 className="font-semibold">Rate Snapshot (Locked)</h3>
                      </div>
                      <Alert className="bg-green-50 border-green-200">
                        <CheckCircle className="h-4 w-4 text-green-600" />
                        <AlertTitle>Approved Rates</AlertTitle>
                        <AlertDescription>
                          <div className="grid grid-cols-2 gap-3 mt-3">
                            <div>
                              <Label className="text-xs text-muted-foreground">Upfront Rate</Label>
                              <p className="text-lg font-bold text-green-700">
                                {(snapshot.resolved_upfront_bps / 100).toFixed(2)}%
                              </p>
                              <p className="text-xs text-muted-foreground">
                                {snapshot.resolved_upfront_bps} bps
                              </p>
                            </div>
                            <div>
                              <Label className="text-xs text-muted-foreground">Deferred Rate</Label>
                              <p className="text-lg font-bold text-green-700">
                                {(snapshot.resolved_deferred_bps / 100).toFixed(2)}%
                              </p>
                              <p className="text-xs text-muted-foreground">
                                {snapshot.resolved_deferred_bps} bps
                              </p>
                            </div>
                          </div>
                        </AlertDescription>
                      </Alert>

                      <div className="grid grid-cols-2 gap-4 p-4 bg-muted rounded-lg text-sm">
                        <div>
                          <Label className="text-xs text-muted-foreground flex items-center gap-1">
                            <Calendar className="w-3 h-3" />
                            Effective From
                          </Label>
                          <p className="font-medium">
                            {new Date(snapshot.effective_from).toLocaleDateString()}
                          </p>
                        </div>
                        <div>
                          <Label className="text-xs text-muted-foreground flex items-center gap-1">
                            <Calendar className="w-3 h-3" />
                            Effective To
                          </Label>
                          <p className="font-medium">
                            {snapshot.effective_to
                              ? new Date(snapshot.effective_to).toLocaleDateString()
                              : 'Open-ended'}
                          </p>
                        </div>
                        <div>
                          <Label className="text-xs text-muted-foreground">VAT Included</Label>
                          <p className="font-medium">{snapshot.vat_included ? 'Yes' : 'No'}</p>
                        </div>
                        {snapshot.seed_version && (
                          <div>
                            <Label className="text-xs text-muted-foreground">Seed Version</Label>
                            <p className="font-medium">{snapshot.seed_version}</p>
                          </div>
                        )}
                        <div className="col-span-2">
                          <Label className="text-xs text-muted-foreground">Snapshot Created</Label>
                          <p className="font-medium">
                            {new Date(snapshot.created_at).toLocaleString()}
                          </p>
                        </div>
                      </div>
                    </div>
                  ) : (
                    <Alert variant="destructive">
                      <AlertCircle className="h-4 w-4" />
                      <AlertDescription>
                        No snapshot found. This is unexpected for an approved agreement.
                      </AlertDescription>
                    </Alert>
                  )}
                </div>
              )}
            </DialogContent>
          </Dialog>
        </CardContent>
      </Card>
    );
  }

  // Create Form View
  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <div>
            <CardTitle>{editingAgreementId ? 'Edit Agreement' : 'Create Agreement'}</CardTitle>
            <CardDescription>
              {editingAgreementId
                ? 'Update agreement details (DRAFT only)'
                : 'Define commission agreement for a party on a fund or deal'}
            </CardDescription>
          </div>
          <Button
            variant="outline"
            onClick={() => {
              setViewMode('list');
              setEditingAgreementId(null);
            }}
          >
            Back to List
          </Button>
        </div>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit} className="space-y-6">
          {/* Party Selection */}
          <div className="space-y-2">
            <Label htmlFor="party_id">
              Party <span className="text-destructive">*</span>
            </Label>
            <Select
              value={formData.party_id}
              onValueChange={(value) => setFormData({ ...formData, party_id: value })}
            >
              <SelectTrigger className={errors.party_id ? 'border-destructive' : ''}>
                <SelectValue placeholder="Select party" />
              </SelectTrigger>
              <SelectContent>
                {parties.map((party) => (
                  <SelectItem key={party.id} value={party.id.toString()}>
                    {party.name}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            {errors.party_id && (
              <p className="text-sm text-destructive">{errors.party_id}</p>
            )}
          </div>

          {/* Scope Selection */}
          <div className="space-y-2">
            <Label htmlFor="scope">
              Scope <span className="text-destructive">*</span>
            </Label>
            <Select
              value={formData.scope}
              onValueChange={(value: AgreementScope) => setFormData({ ...formData, scope: value })}
            >
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="FUND">Fund-wide</SelectItem>
                <SelectItem value="DEAL">Deal-specific</SelectItem>
              </SelectContent>
            </Select>
            <p className="text-sm text-muted-foreground">
              {formData.scope === 'FUND'
                ? 'Applies to all deals in the fund'
                : 'Applies only to the selected deal'}
            </p>
          </div>

          {/* Fund/Deal Selection */}
          {formData.scope === 'FUND' ? (
            <div className="space-y-2">
              <Label htmlFor="fund_id">
                Fund <span className="text-destructive">*</span>
              </Label>
              <Select
                value={formData.fund_id}
                onValueChange={(value) => setFormData({ ...formData, fund_id: value })}
              >
                <SelectTrigger className={errors.fund_id ? 'border-destructive' : ''}>
                  <SelectValue placeholder="Select fund" />
                </SelectTrigger>
                <SelectContent>
                  {funds.map((fund) => (
                    <SelectItem key={fund.id} value={fund.id.toString()}>
                      {fund.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              {errors.fund_id && (
                <p className="text-sm text-destructive">{errors.fund_id}</p>
              )}
            </div>
          ) : (
            <div className="space-y-2">
              <Label htmlFor="deal_id">
                Deal <span className="text-destructive">*</span>
              </Label>
              <Select
                value={formData.deal_id}
                onValueChange={(value) => setFormData({ ...formData, deal_id: value })}
              >
                <SelectTrigger className={errors.deal_id ? 'border-destructive' : ''}>
                  <SelectValue placeholder="Select deal" />
                </SelectTrigger>
                <SelectContent>
                  {deals.map((deal) => (
                    <SelectItem key={deal.id} value={deal.id.toString()}>
                      {deal.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              {errors.deal_id && (
                <p className="text-sm text-destructive">{errors.deal_id}</p>
              )}
            </div>
          )}

          <Separator />

          {/* Pricing Mode */}
          <div className="space-y-2">
            <Label htmlFor="pricing_mode">
              Pricing Mode <span className="text-destructive">*</span>
            </Label>
            <Select
              value={formData.pricing_mode}
              onValueChange={(value: PricingMode) => setFormData({ ...formData, pricing_mode: value, selected_track: '', custom_upfront_bps: '', custom_deferred_bps: '' })}
              disabled={formData.scope === 'FUND'}
            >
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="TRACK">Track (A/B/C)</SelectItem>
                <SelectItem value="CUSTOM">Custom Rates</SelectItem>
              </SelectContent>
            </Select>
            {formData.scope === 'FUND' && (
              <Alert>
                <Info className="h-4 w-4" />
                <AlertDescription>
                  Fund-wide agreements must use Track pricing
                </AlertDescription>
              </Alert>
            )}
          </div>

          {/* Track Selection (if TRACK mode) */}
          {formData.pricing_mode === 'TRACK' && (
            <>
              <div className="space-y-2">
                <Label htmlFor="selected_track">
                  Track <span className="text-destructive">*</span>
                </Label>
                <Select
                  value={formData.selected_track}
                  onValueChange={(value: TrackCode) => setFormData({ ...formData, selected_track: value })}
                  disabled={fundTracks.length === 0}
                >
                  <SelectTrigger className={errors.selected_track ? 'border-destructive' : ''}>
                    <SelectValue placeholder="Select track" />
                  </SelectTrigger>
                  <SelectContent>
                    {fundTracks.map((track) => (
                      <SelectItem key={track.id} value={track.track_code}>
                        Track {track.track_code} - {(track.upfront_bps / 100).toFixed(2)}% / {(track.deferred_bps / 100).toFixed(2)}%
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                {errors.selected_track && (
                  <p className="text-sm text-destructive">{errors.selected_track}</p>
                )}
                {fundTracks.length === 0 && (formData.fund_id || formData.deal_id) && (
                  <Alert variant="destructive">
                    <AlertCircle className="h-4 w-4" />
                    <AlertDescription>
                      No tracks found for this fund. Please ensure Fund VI tracks are seeded.
                    </AlertDescription>
                  </Alert>
                )}
              </div>

              {/* Track Details */}
              {selectedTrackDetails && (
                <Alert>
                  <TrendingUp className="h-4 w-4" />
                  <AlertTitle>Track {selectedTrackDetails.track_code} Rates</AlertTitle>
                  <AlertDescription>
                    <div className="grid grid-cols-2 gap-2 mt-2 text-sm">
                      <div>Upfront: <strong>{(selectedTrackDetails.upfront_bps / 100).toFixed(2)}%</strong></div>
                      <div>Deferred: <strong>{(selectedTrackDetails.deferred_bps / 100).toFixed(2)}%</strong></div>
                      <div className="col-span-2 text-muted-foreground">
                        Seed Version: {selectedTrackDetails.seed_version} | Offset: {selectedTrackDetails.offset_months} months
                      </div>
                    </div>
                  </AlertDescription>
                </Alert>
              )}
            </>
          )}

          {/* Custom Rates (if CUSTOM mode) */}
          {formData.pricing_mode === 'CUSTOM' && (
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="custom_upfront_bps">
                  Upfront Rate (bps) <span className="text-destructive">*</span>
                </Label>
                <Input
                  id="custom_upfront_bps"
                  type="number"
                  min="0"
                  step="1"
                  placeholder="e.g., 180 for 1.80%"
                  value={formData.custom_upfront_bps}
                  onChange={(e) => setFormData({ ...formData, custom_upfront_bps: e.target.value })}
                  className={errors.custom_upfront_bps ? 'border-destructive' : ''}
                />
                {errors.custom_upfront_bps && (
                  <p className="text-sm text-destructive">{errors.custom_upfront_bps}</p>
                )}
              </div>
              <div className="space-y-2">
                <Label htmlFor="custom_deferred_bps">
                  Deferred Rate (bps) <span className="text-destructive">*</span>
                </Label>
                <Input
                  id="custom_deferred_bps"
                  type="number"
                  min="0"
                  step="1"
                  placeholder="e.g., 80 for 0.80%"
                  value={formData.custom_deferred_bps}
                  onChange={(e) => setFormData({ ...formData, custom_deferred_bps: e.target.value })}
                  className={errors.custom_deferred_bps ? 'border-destructive' : ''}
                />
                {errors.custom_deferred_bps && (
                  <p className="text-sm text-destructive">{errors.custom_deferred_bps}</p>
                )}
              </div>
            </div>
          )}

          <Separator />

          {/* Effective Dates */}
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="effective_from">
                Effective From <span className="text-destructive">*</span>
              </Label>
              <Input
                id="effective_from"
                type="date"
                value={formData.effective_from}
                onChange={(e) => setFormData({ ...formData, effective_from: e.target.value })}
                className={errors.effective_from ? 'border-destructive' : ''}
              />
              {errors.effective_from && (
                <p className="text-sm text-destructive">{errors.effective_from}</p>
              )}
            </div>
            <div className="space-y-2">
              <Label htmlFor="effective_to">Effective To (Optional)</Label>
              <Input
                id="effective_to"
                type="date"
                value={formData.effective_to}
                onChange={(e) => setFormData({ ...formData, effective_to: e.target.value })}
              />
            </div>
          </div>

          {/* VAT */}
          <div className="flex items-center space-x-2">
            <Checkbox
              id="vat_included"
              checked={formData.vat_included}
              onCheckedChange={(checked) => setFormData({ ...formData, vat_included: checked as boolean })}
            />
            <Label htmlFor="vat_included" className="cursor-pointer">
              VAT included in rates
            </Label>
          </div>

          {/* Submit */}
          <div className="flex justify-end gap-2">
            <Button
              type="button"
              variant="outline"
              onClick={() => {
                setFormData({
                  party_id: '',
                  scope: 'FUND',
                  fund_id: '',
                  deal_id: '',
                  pricing_mode: 'TRACK',
                  selected_track: '',
                  custom_upfront_bps: '',
                  custom_deferred_bps: '',
                  effective_from: new Date().toISOString().split('T')[0],
                  effective_to: '',
                  vat_included: false,
                });
                setErrors({});
                setEditingAgreementId(null);
              }}
            >
              {editingAgreementId ? 'Cancel' : 'Reset'}
            </Button>
            <Button type="submit" disabled={isSubmitting}>
              {isSubmitting
                ? editingAgreementId ? 'Updating...' : 'Creating...'
                : editingAgreementId ? 'Update Agreement' : 'Create Agreement'}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
