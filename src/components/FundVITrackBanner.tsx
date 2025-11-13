/**
 * Fund VI Track Banner Component
 *
 * Displays informational banner on agreement forms when the selected fund is Fund VI.
 * Shows which track (A/B/C) rates are being used and links to the tracks configuration page.
 */

import { Alert, AlertDescription } from '@/components/ui/alert';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Info, GitBranch, ExternalLink } from 'lucide-react';
import { Link } from 'react-router-dom';
import { useFundTracks } from '@/hooks/useFundTracks';

interface FundVITrackBannerProps {
  fundId?: string;
  trackKey?: 'A' | 'B' | 'C';
  className?: string;
}

/**
 * Banner component that shows Fund VI track information
 * Only displays when fundId corresponds to Fund VI
 */
export function FundVITrackBanner({ fundId, trackKey, className }: FundVITrackBannerProps) {
  const { tracks, isLoading } = useFundTracks();

  // Don't render if no fundId provided
  if (!fundId) {
    return null;
  }

  // TODO: Replace with actual Fund VI ID lookup
  // For now, check if fund name/ID contains "Fund VI" or "6"
  const isFundVI = fundId.toLowerCase().includes('fund vi') || fundId.includes('6');

  if (!isFundVI) {
    return null;
  }

  // Find the specific track if trackKey is provided
  const track = trackKey ? tracks?.find(t => t.track_key === trackKey) : null;

  if (isLoading) {
    return (
      <Alert className={className}>
        <Info className="h-4 w-4" />
        <AlertDescription>Loading track information...</AlertDescription>
      </Alert>
    );
  }

  return (
    <Alert className={className}>
      <GitBranch className="h-4 w-4" />
      <AlertDescription className="flex items-center justify-between">
        <div className="flex items-center gap-2 flex-wrap">
          <span>
            Using Fund VI {trackKey ? `Track ${trackKey}` : 'track'} rates
          </span>
          {track && (
            <div className="flex items-center gap-2">
              <Badge variant="secondary">
                Upfront: {(track.upfront_rate_bps / 100).toFixed(2)}%
              </Badge>
              <Badge variant="secondary">
                Deferred: {(track.deferred_rate_bps / 100).toFixed(2)}%
              </Badge>
              <Badge variant="outline">v{track.config_version}</Badge>
            </div>
          )}
        </div>
        <Button variant="ghost" size="sm" asChild className="ml-4">
          <Link to="/fund-vi/tracks" className="flex items-center gap-1">
            View configurations
            <ExternalLink className="h-3 w-3" />
          </Link>
        </Button>
      </AlertDescription>
    </Alert>
  );
}

/**
 * Compact version of the banner for smaller spaces
 */
export function FundVITrackBannerCompact({ fundId, trackKey }: FundVITrackBannerProps) {
  if (!fundId) {
    return null;
  }

  const isFundVI = fundId.toLowerCase().includes('fund vi') || fundId.includes('6');

  if (!isFundVI) {
    return null;
  }

  return (
    <div className="flex items-center gap-2 text-sm text-muted-foreground">
      <GitBranch className="h-4 w-4" />
      <span>
        Fund VI {trackKey ? `Track ${trackKey}` : 'track'} rates apply
      </span>
      <Button variant="link" size="sm" asChild className="h-auto p-0">
        <Link to="/fund-vi/tracks">View details</Link>
      </Button>
    </div>
  );
}
