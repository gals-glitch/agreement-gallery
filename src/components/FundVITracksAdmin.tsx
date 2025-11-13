/**
 * Fund VI Tracks Admin - Read-Only Display
 * Displays Fund VI Track A/B/C configurations (seeded data)
 *
 * To modify tracks, update seed data and re-run migrations.
 * This component is read-only to prevent runtime configuration drift.
 */

import { useState, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Badge } from '@/components/ui/badge';
import { useToast } from '@/hooks/use-toast';
import { Loader2, Lock, Info } from 'lucide-react';

interface Track {
  id: string;
  track_key: string;
  min_raised: number;
  max_raised: number | null;
  upfront_rate_bps: number;
  deferred_rate_bps: number;
  deferred_offset_months: number;
  config_version: string;
}

// Helper to format currency
const formatCurrency = (value: number | null): string => {
  if (value === null) return '∞';
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(value);
};

// Helper to format basis points as percentage
const formatBps = (bps: number): string => {
  return `${(bps / 100).toFixed(2)}%`;
};

// Color scheme for tracks
const trackColors = {
  A: 'border-blue-500 bg-blue-50 dark:bg-blue-950',
  B: 'border-green-500 bg-green-50 dark:bg-green-950',
  C: 'border-purple-500 bg-purple-50 dark:bg-purple-950',
};

export const FundVITracksAdmin = () => {
  const { toast } = useToast();
  const [tracks, setTracks] = useState<Track[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadTracks();
  }, []);

  const loadTracks = async () => {
    try {
      const { data, error } = await supabase
        .from('fund_vi_tracks')
        .select('*')
        .order('track_key');

      if (error) throw error;
      setTracks(data || []);
    } catch (error: any) {
      toast({
        title: 'Error loading tracks',
        description: error.message,
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center p-8">
        <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
      </div>
    );
  }

  return (
    <div className="space-y-6 p-6">
      {/* Header Section */}
      <div className="flex items-start justify-between">
        <div className="flex items-center gap-3">
          <div className="p-2 rounded-lg bg-primary/10">
            <Lock className="w-6 h-6 text-primary" />
          </div>
          <div>
            <h2 className="text-2xl font-bold">Fund VI Tracks Configuration</h2>
            <p className="text-sm text-muted-foreground">
              Read-only view of seeded track configurations
            </p>
          </div>
        </div>
      </div>

      {/* Info Banner */}
      <Alert>
        <Info className="h-4 w-4" />
        <AlertDescription>
          To modify tracks, update seed data and re-run migrations. Runtime editing is disabled to
          prevent configuration drift from the canonical source.
        </AlertDescription>
      </Alert>

      {/* Track Cards */}
      <div className="grid gap-6 md:grid-cols-3">
        {tracks.map((track) => {
          const colorClass = trackColors[track.track_key as keyof typeof trackColors] || trackColors.A;

          return (
            <Card key={track.id} className={`border-2 ${colorClass} transition-all`}>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <CardTitle className="flex items-center gap-2">
                    Track {track.track_key}
                    <Lock className="w-4 h-4 text-muted-foreground" />
                  </CardTitle>
                  <Badge variant="outline">v{track.config_version}</Badge>
                </div>
                <CardDescription>
                  Capital raised range: {formatCurrency(track.min_raised)} -{' '}
                  {track.max_raised ? formatCurrency(track.max_raised) : '∞'}
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                {/* Upfront Rate */}
                <div className="space-y-1">
                  <div className="flex items-center justify-between">
                    <span className="text-sm font-medium">Upfront Rate</span>
                    <Badge variant="secondary">{formatBps(track.upfront_rate_bps)}</Badge>
                  </div>
                  <p className="text-xs text-muted-foreground">{track.upfront_rate_bps} basis points</p>
                </div>

                {/* Deferred Rate */}
                <div className="space-y-1">
                  <div className="flex items-center justify-between">
                    <span className="text-sm font-medium">Deferred Rate</span>
                    <Badge variant="secondary">{formatBps(track.deferred_rate_bps)}</Badge>
                  </div>
                  <p className="text-xs text-muted-foreground">{track.deferred_rate_bps} basis points</p>
                </div>

                {/* Offset */}
                <div className="space-y-1">
                  <div className="flex items-center justify-between">
                    <span className="text-sm font-medium">Deferred Offset</span>
                    <Badge variant="secondary">{track.deferred_offset_months} months</Badge>
                  </div>
                  <p className="text-xs text-muted-foreground">Payment delay period</p>
                </div>

                {/* Min/Max Raised */}
                <div className="pt-3 border-t">
                  <div className="grid grid-cols-2 gap-3 text-sm">
                    <div>
                      <p className="text-xs text-muted-foreground mb-1">Min Raised</p>
                      <p className="font-medium">{formatCurrency(track.min_raised)}</p>
                    </div>
                    <div>
                      <p className="text-xs text-muted-foreground mb-1">Max Raised</p>
                      <p className="font-medium">
                        {track.max_raised ? formatCurrency(track.max_raised) : '∞'}
                      </p>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          );
        })}
      </div>

      {/* Metadata Card */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Configuration Metadata</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-3 gap-4 text-sm">
            <div>
              <p className="text-xs text-muted-foreground mb-1">Total Tracks</p>
              <p className="font-medium">{tracks.length}</p>
            </div>
            <div>
              <p className="text-xs text-muted-foreground mb-1">Configuration Version</p>
              <p className="font-medium">v{tracks[0]?.config_version || '1.0'}</p>
            </div>
            <div>
              <p className="text-xs text-muted-foreground mb-1">Status</p>
              <Badge className="bg-green-500">Active</Badge>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};
