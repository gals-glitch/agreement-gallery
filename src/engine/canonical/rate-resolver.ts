import { supabase } from '@/integrations/supabase/client';

/**
 * Rate Resolution Engine
 * Handles Fund VI track lookup and agreement-level overrides
 */

export interface FundVITrack {
  id: string;
  track_key: string;
  min_raised: number;
  max_raised: number | null;
  upfront_rate_bps: number;
  deferred_rate_bps: number;
  deferred_offset_months: number;
  config_version: string;
  is_active: boolean;
}

export interface ResolvedRates {
  upfront_rate_bps: number;
  deferred_rate_bps: number;
  deferred_offset_months: number;
  source: 'fund_track' | 'agreement_override';
  track_key?: string;
}

export class RateResolver {
  private static tracksCache: FundVITrack[] | null = null;

  /**
   * Load Fund VI tracks configuration
   */
  static async loadTracks(configVersion: string = 'v1.0'): Promise<FundVITrack[]> {
    if (this.tracksCache) return this.tracksCache;

    const { data, error } = await supabase
      .from('fund_vi_tracks')
      .select('*')
      .eq('config_version', configVersion)
      .eq('is_active', true)
      .order('min_raised', { ascending: true });

    if (error) {
      throw new Error(`Failed to load fund VI tracks: ${error.message}`);
    }

    this.tracksCache = (data || []) as FundVITrack[];
    return this.tracksCache;
  }

  /**
   * Resolve rates for a contribution based on agreement and fund tracks
   * 
   * Logic:
   * - FUND scope: always use track_key → fund_vi_tracks
   * - DEAL scope: 
   *   - if inherit_fund_rates=true → use track_key → fund_vi_tracks
   *   - else → use agreement's upfront/deferred/offset overrides
   */
  static async resolveRates(
    agreement: any,
    totalRaised: number
  ): Promise<ResolvedRates> {
    const scope = agreement.applies_scope || 'FUND';

    // FUND-scoped: always use track
    if (scope === 'FUND') {
      return await this.resolveFromTrack(agreement.track_key, totalRaised);
    }

    // DEAL-scoped
    if (scope === 'DEAL') {
      // If inherit_fund_rates, use the track
      if (agreement.inherit_fund_rates === true) {
        return await this.resolveFromTrack(agreement.track_key, totalRaised);
      }

      // Otherwise, use agreement overrides
      return {
        upfront_rate_bps: agreement.upfront_rate_bps || 0,
        deferred_rate_bps: agreement.deferred_rate_bps || 0,
        deferred_offset_months: agreement.deferred_offset_months || 24,
        source: 'agreement_override',
      };
    }

    throw new Error(`Unknown scope: ${scope}`);
  }

  /**
   * Resolve rates from a fund track based on total raised
   */
  private static async resolveFromTrack(
    trackKey: string,
    totalRaised: number
  ): Promise<ResolvedRates> {
    const tracks = await this.loadTracks();

    // Find the track by key
    const track = tracks.find(t => t.track_key === trackKey);

    if (!track) {
      throw new Error(`Fund VI track not found: ${trackKey}`);
    }

    // Validate totalRaised is within track range
    if (totalRaised < track.min_raised) {
      console.warn(
        `Total raised ${totalRaised} is below track ${trackKey} minimum ${track.min_raised}`
      );
    }

    if (track.max_raised && totalRaised > track.max_raised) {
      console.warn(
        `Total raised ${totalRaised} exceeds track ${trackKey} maximum ${track.max_raised}`
      );
    }

    return {
      upfront_rate_bps: track.upfront_rate_bps,
      deferred_rate_bps: track.deferred_rate_bps,
      deferred_offset_months: track.deferred_offset_months,
      source: 'fund_track',
      track_key: trackKey,
    };
  }

  /**
   * Clear the tracks cache (useful for testing)
   */
  static clearCache(): void {
    this.tracksCache = null;
  }
}
