/**
 * Investor Source Section Component
 * For use in Investor Create/Edit forms
 * Ticket: FE-102
 * Date: 2025-10-19
 */

import { useState, useEffect } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Label } from '@/components/ui/label';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { InfoIcon } from 'lucide-react';
import {
  InvestorSourceKind,
  INVESTOR_SOURCE_KIND_VALUES,
  INVESTOR_SOURCE_KIND_LABELS,
  InvestorSourceFormData,
} from '@/types/investors';
import { supabase } from '@/integrations/supabase/client';

interface InvestorSourceSectionProps {
  value: InvestorSourceFormData;
  onChange: (value: InvestorSourceFormData) => void;
  disabled?: boolean;
}

const fetchParties = async () => {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) throw new Error('Not authenticated');

  const response = await fetch(
    `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/api-v1/parties?limit=1000&active=true`,
    {
      headers: {
        Authorization: `Bearer ${session.access_token}`,
        'Content-Type': 'application/json',
      },
    }
  );

  if (!response.ok) {
    throw new Error('Failed to fetch parties');
  }

  const data = await response.json();
  return data.items || [];
};

export function InvestorSourceSection({
  value,
  onChange,
  disabled = false,
}: InvestorSourceSectionProps) {
  const { data: parties, isLoading: isLoadingParties } = useQuery({
    queryKey: ['parties-active'],
    queryFn: fetchParties,
  });

  const [showInfoToast, setShowInfoToast] = useState(false);

  useEffect(() => {
    // Show info toast if source_kind is NONE
    if (value.source_kind === 'NONE') {
      setShowInfoToast(true);
    } else {
      setShowInfoToast(false);
    }
  }, [value.source_kind]);

  const handleSourceKindChange = (sourceKind: InvestorSourceKind) => {
    onChange({
      source_kind: sourceKind,
      // Clear party if changing to NONE
      introduced_by_party_id: sourceKind === 'NONE' ? null : value.introduced_by_party_id,
    });
  };

  const handlePartyChange = (partyId: string) => {
    onChange({
      source_kind: value.source_kind,
      introduced_by_party_id: partyId === 'NONE' ? null : partyId,
    });
  };

  const showPartySelector = value.source_kind !== 'NONE';

  return (
    <Card>
      <CardHeader>
        <CardTitle>Investor Source (Optional)</CardTitle>
        <CardDescription>
          Track how this investor was introduced to the fund
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Source Kind Selector */}
        <div className="space-y-2">
          <Label htmlFor="source-kind">Source Type</Label>
          <Select
            value={value.source_kind}
            onValueChange={handleSourceKindChange}
            disabled={disabled}
          >
            <SelectTrigger id="source-kind">
              <SelectValue placeholder="Select source type" />
            </SelectTrigger>
            <SelectContent>
              {INVESTOR_SOURCE_KIND_VALUES.map((kind) => (
                <SelectItem key={kind} value={kind}>
                  {INVESTOR_SOURCE_KIND_LABELS[kind]}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
          <p className="text-sm text-muted-foreground">
            Select how this investor was sourced
          </p>
        </div>

        {/* Party Selector (conditional) */}
        {showPartySelector && (
          <div className="space-y-2">
            <Label htmlFor="introduced-by-party">
              Introduced By Party {value.source_kind === 'DISTRIBUTOR' && '(Distributor)'}
              {value.source_kind === 'REFERRER' && '(Referrer)'}
            </Label>
            <Select
              value={value.introduced_by_party_id || 'NONE'}
              onValueChange={handlePartyChange}
              disabled={disabled || isLoadingParties}
            >
              <SelectTrigger id="introduced-by-party">
                <SelectValue placeholder="Select party (optional)" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="NONE">None Selected</SelectItem>
                {parties?.map((party: any) => (
                  <SelectItem key={party.id} value={party.id}>
                    {party.name} ({party.party_type})
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            <p className="text-sm text-muted-foreground">
              Optional: Select the party who introduced this investor
            </p>
          </div>
        )}

        {/* Info Alert */}
        {showInfoToast && (
          <Alert>
            <InfoIcon className="h-4 w-4" />
            <AlertDescription>
              Investor will be saved without source attribution. You can add this later if needed.
            </AlertDescription>
          </Alert>
        )}

        {/* Help Text */}
        <div className="rounded-lg bg-muted p-4 text-sm space-y-2">
          <p className="font-medium">Source Type Guide:</p>
          <ul className="list-disc list-inside space-y-1 text-muted-foreground">
            <li>
              <strong>Distributor:</strong> Investor sourced through a distribution channel
            </li>
            <li>
              <strong>Referrer:</strong> Investor referred by an individual or party
            </li>
            <li>
              <strong>None:</strong> Direct investor or unknown source
            </li>
          </ul>
        </div>
      </CardContent>
    </Card>
  );
}
