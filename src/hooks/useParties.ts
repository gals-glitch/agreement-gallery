import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { Party } from '@/domain/types';
import { useToast } from '@/hooks/use-toast';

/**
 * Hook to fetch introducing parties (active parties only)
 * Used in Agreement modals and anywhere introducers are needed
 * Note: party_type has been removed from schema - all parties are generic now
 */
export function useIntroducingParties(search = '') {
  return useQuery({
    queryKey: ['parties', 'introducers', search],
    queryFn: async (): Promise<Party[]> => {
      let query = supabase
        .from('parties')
        .select('*')
        .eq('active', true)
        .order('name');

      if (search) {
        query = query.ilike('name', `%${search}%`);
      }

      const { data, error } = await query;
      if (error) throw error;
      return (data || []) as Party[];
    },
    staleTime: 0, // Always refetch for modals
  });
}

/**
 * Hook to fetch all parties with optional filters
 */
export function useParties(filters?: {
  search?: string;
  active?: boolean;
}) {
  return useQuery({
    queryKey: ['parties', filters],
    queryFn: async (): Promise<Party[]> => {
      let query = supabase
        .from('parties')
        .select('*')
        .order('name');

      if (filters?.search) {
        query = query.ilike('name', `%${filters.search}%`);
      }

      if (filters?.active !== undefined) {
        query = query.eq('active', filters.active);
      }

      const { data, error } = await query;
      if (error) throw error;
      return (data || []) as Party[];
    },
  });
}

/**
 * Hook to create a new party
 */
export function useCreateParty() {
  const queryClient = useQueryClient();
  const { toast } = useToast();

  return useMutation({
    mutationFn: async (party: Omit<Party, 'id' | 'created_at' | 'updated_at'>) => {
      const { data, error } = await supabase
        .from('parties')
        .insert([party])
        .select()
        .single();

      if (error) throw error;
      return data as Party;
    },
    onSuccess: () => {
      // Invalidate all party queries
      queryClient.invalidateQueries({ queryKey: ['parties'] });
      toast({
        title: 'Success',
        description: 'Party created successfully',
      });
    },
    onError: (error: Error) => {
      toast({
        title: 'Error',
        description: error.message || 'Failed to create party',
        variant: 'destructive',
      });
    },
  });
}

/**
 * Hook to update an existing party
 */
export function useUpdateParty() {
  const queryClient = useQueryClient();
  const { toast } = useToast();

  return useMutation({
    mutationFn: async ({ id, ...updates }: Partial<Party> & { id: string }) => {
      const { data, error } = await supabase
        .from('parties')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;
      return data as Party;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['parties'] });
      toast({
        title: 'Success',
        description: 'Party updated successfully',
      });
    },
    onError: (error: Error) => {
      toast({
        title: 'Error',
        description: error.message || 'Failed to update party',
        variant: 'destructive',
      });
    },
  });
}

/**
 * Hook to delete a party
 */
export function useDeleteParty() {
  const queryClient = useQueryClient();
  const { toast } = useToast();

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from('parties')
        .delete()
        .eq('id', id);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['parties'] });
      toast({
        title: 'Success',
        description: 'Party deleted successfully',
      });
    },
    onError: (error: Error) => {
      toast({
        title: 'Error',
        description: error.message || 'Failed to delete party',
        variant: 'destructive',
      });
    },
  });
}
