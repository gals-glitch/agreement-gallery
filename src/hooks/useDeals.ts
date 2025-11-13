import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { Deal } from '@/domain/types';

/**
 * Hook to fetch active deals with optional search
 */
export function useDeals(search = '') {
  return useQuery({
    queryKey: ['deals', search],
    queryFn: async (): Promise<Deal[]> => {
      let query = supabase
        .from('deals')
        .select('*')
        .eq('status', 'ACTIVE')
        .order('name');

      if (search) {
        query = query.ilike('name', `%${search}%`);
      }

      const { data, error } = await query;
      if (error) throw error;
      return (data || []) as Deal[];
    },
  });
}

/**
 * Hook to fetch a single deal by ID
 */
export function useDeal(id?: string) {
  return useQuery({
    queryKey: ['deals', id],
    queryFn: async (): Promise<Deal | null> => {
      if (!id) return null;

      const { data, error } = await supabase
        .from('deals')
        .select('*')
        .eq('id', id)
        .maybeSingle();

      if (error) throw error;
      return data as Deal | null;
    },
    enabled: !!id,
  });
}
