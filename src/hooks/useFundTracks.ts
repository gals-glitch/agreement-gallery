import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { FundVITrack } from '@/domain/types';

/**
 * Hook to fetch active Fund VI tracks
 */
export function useFundTracks() {
  return useQuery({
    queryKey: ['fund_tracks'],
    queryFn: async (): Promise<FundVITrack[]> => {
      const { data, error } = await supabase
        .from('fund_vi_tracks')
        .select('*')
        .eq('is_active', true)
        .order('track_key');

      if (error) throw error;
      return data || [];
    },
    staleTime: 5 * 60 * 1000, // Cache for 5 minutes (tracks change rarely)
  });
}

/**
 * Hook to fetch a specific track by key
 */
export function useFundTrack(trackKey?: string) {
  return useQuery({
    queryKey: ['fund_tracks', trackKey],
    queryFn: async (): Promise<FundVITrack | null> => {
      if (!trackKey) return null;

      const { data, error } = await supabase
        .from('fund_vi_tracks')
        .select('*')
        .eq('track_key', trackKey)
        .eq('is_active', true)
        .maybeSingle();

      if (error) throw error;
      return data;
    },
    enabled: !!trackKey,
  });
}
