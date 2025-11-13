/**
 * VAT Settings Page
 * Ticket: FE-501
 * Date: 2025-10-19
 *
 * Admin page for managing VAT rates with temporal validity
 * - Feature-flagged behind 'vat_admin' (admin-only)
 * - CRUD operations for VAT rates
 * - Current, Historical, and Scheduled rate sections
 * - Overlap validation and warnings
 */

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Plus, Info, ArrowLeft, Receipt } from 'lucide-react';
import { toast } from 'sonner';
import { useNavigate } from 'react-router-dom';

import { SidebarProvider, SidebarTrigger } from '@/components/ui/sidebar';
import { AppSidebar } from '@/components/AppSidebar';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Alert, AlertDescription } from '@/components/ui/alert';

import { listVatRates, createVatRate, updateVatRate, deleteVatRate } from '@/api/vatClient';
import type { VatRate, CreateVatRateRequest } from '@/types/vat';
import { isCurrentRate, isHistoricalRate, isScheduledRate } from '@/types/vat';

import { VatRatesTable } from '@/components/vat/VatRatesTable';
import { VatRateDialog } from '@/components/vat/VatRateDialog';
import { CloseRateDialog } from '@/components/vat/CloseRateDialog';
import { DeleteRateDialog } from '@/components/vat/DeleteRateDialog';

export default function VATSettingsPage() {
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  // Dialog states
  const [createDialogOpen, setCreateDialogOpen] = useState(false);
  const [closeDialogState, setCloseDialogState] = useState<{ open: boolean; rate: VatRate | null }>({
    open: false,
    rate: null,
  });
  const [deleteDialogState, setDeleteDialogState] = useState<{ open: boolean; rate: VatRate | null }>({
    open: false,
    rate: null,
  });

  // Queries
  const { data: allRates = [], isLoading } = useQuery({
    queryKey: ['vat-rates'],
    queryFn: () => listVatRates(),
  });

  // Categorize rates
  const currentRates = allRates.filter(isCurrentRate);
  const historicalRates = allRates.filter(isHistoricalRate);
  const scheduledRates = allRates.filter(isScheduledRate);

  // Mutations
  const createMutation = useMutation({
    mutationFn: createVatRate,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['vat-rates'] });
      toast.success('VAT rate created successfully');
      setCreateDialogOpen(false);
    },
    onError: (error: Error) => {
      toast.error(error.message || 'Failed to create VAT rate');
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, payload }: { id: string; payload: { effective_to: string | null } }) =>
      updateVatRate(id, payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['vat-rates'] });
      toast.success('VAT rate closed successfully');
      setCloseDialogState({ open: false, rate: null });
    },
    onError: (error: Error) => {
      toast.error(error.message || 'Failed to close VAT rate');
    },
  });

  const deleteMutation = useMutation({
    mutationFn: deleteVatRate,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['vat-rates'] });
      toast.success('VAT rate deleted successfully');
      setDeleteDialogState({ open: false, rate: null });
    },
    onError: (error: Error) => {
      toast.error(error.message || 'Failed to delete VAT rate');
    },
  });

  // Handlers
  const handleCreate = (payload: CreateVatRateRequest) => {
    createMutation.mutate(payload);
  };

  const handleCloseRate = (rate: VatRate) => {
    setCloseDialogState({ open: true, rate });
  };

  const handleConfirmClose = (effectiveTo: string) => {
    if (closeDialogState.rate) {
      updateMutation.mutate({
        id: closeDialogState.rate.id,
        payload: { effective_to: effectiveTo },
      });
    }
  };

  const handleDeleteRate = (rate: VatRate) => {
    setDeleteDialogState({ open: true, rate });
  };

  const handleConfirmDelete = () => {
    if (deleteDialogState.rate) {
      deleteMutation.mutate(deleteDialogState.rate.id);
    }
  };

  return (
    <SidebarProvider>
      <div className="min-h-screen w-full flex bg-background">
        <AppSidebar />

        <div className="flex-1 flex flex-col">
          <div className="sticky top-0 z-20 bg-background/80 backdrop-blur border-b border-border">
            <div className="px-4 py-3 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <SidebarTrigger />
                <Button variant="ghost" size="sm" onClick={() => navigate('/')}>
                  <ArrowLeft className="w-4 h-4 mr-2" />
                  Back
                </Button>
                <div className="flex items-center gap-2">
                  <Receipt className="w-5 h-5" />
                  <h1 className="text-lg font-semibold">VAT Configuration</h1>
                </div>
              </div>
              <Button onClick={() => setCreateDialogOpen(true)}>
                <Plus className="mr-2 h-4 w-4" />
                New VAT Rate
              </Button>
            </div>
          </div>

          <main className="flex-1 p-6">
            <div className="max-w-6xl mx-auto space-y-6">
              {/* Info Banner */}
              <Alert>
                <Info className="h-4 w-4" />
                <AlertDescription>
                  VAT rates are snapshotted at agreement approval time and cannot be changed retroactively.
                  Historical rates are immutable to preserve financial integrity.
                </AlertDescription>
              </Alert>

              {/* Current Rates Section */}
              <Card>
                <CardHeader>
                  <CardTitle>Current Rates</CardTitle>
                  <CardDescription>
                    Active VAT rates (effective_to is NULL or in the future)
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <VatRatesTable
                    rates={currentRates}
                    isLoading={isLoading}
                    emptyMessage="No current VAT rates defined"
                    onCloseRate={handleCloseRate}
                    onDeleteRate={handleDeleteRate}
                  />
                </CardContent>
              </Card>

              {/* Scheduled Rates Section */}
              <Card>
                <CardHeader>
                  <CardTitle>Scheduled Rates</CardTitle>
                  <CardDescription>
                    Future VAT rates (effective_from is in the future)
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <VatRatesTable
                    rates={scheduledRates}
                    isLoading={isLoading}
                    emptyMessage="No scheduled VAT rates"
                    onCloseRate={handleCloseRate}
                    onDeleteRate={handleDeleteRate}
                  />
                </CardContent>
              </Card>

              {/* Historical Rates Section */}
              <Card>
                <CardHeader>
                  <CardTitle>Historical Rates</CardTitle>
                  <CardDescription>
                    Expired VAT rates (effective_to is in the past)
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <VatRatesTable
                    rates={historicalRates}
                    isLoading={isLoading}
                    emptyMessage="No historical VAT rates"
                    readOnly
                  />
                </CardContent>
              </Card>
            </div>
          </main>
        </div>
      </div>

      {/* Dialogs */}
      <VatRateDialog
        open={createDialogOpen}
        onOpenChange={setCreateDialogOpen}
        onSubmit={handleCreate}
        isLoading={createMutation.isPending}
      />

      <CloseRateDialog
        open={closeDialogState.open}
        rate={closeDialogState.rate}
        onOpenChange={(open) => setCloseDialogState({ open, rate: null })}
        onConfirm={handleConfirmClose}
        isLoading={updateMutation.isPending}
      />

      <DeleteRateDialog
        open={deleteDialogState.open}
        rate={deleteDialogState.rate}
        onOpenChange={(open) => setDeleteDialogState({ open, rate: null })}
        onConfirm={handleConfirmDelete}
        isLoading={deleteMutation.isPending}
      />
    </SidebarProvider>
  );
}
