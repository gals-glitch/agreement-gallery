import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Alert, AlertDescription } from '@/components/ui/alert';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Plus, DollarSign, TrendingUp, AlertCircle, Coins } from 'lucide-react';
import { CreateCreditModal } from '@/components/credits/CreateCreditModal';
import { Credit, CreditType, CreditStatus } from '@/types/transactions';

export default function Credits() {
  const [createModalOpen, setCreateModalOpen] = useState(false);
  const [selectedInvestor, setSelectedInvestor] = useState<string>('all');
  const [selectedType, setSelectedType] = useState<string>('all');
  const [selectedStatus, setSelectedStatus] = useState<string>('all');

  // Fetch credits
  const { data: credits, isLoading, refetch } = useQuery({
    queryKey: ['credits', selectedInvestor, selectedType, selectedStatus],
    queryFn: async () => {
      // TODO: Replace with actual API call
      // const params = new URLSearchParams();
      // if (selectedInvestor !== 'all') params.append('investor_id', selectedInvestor);
      // if (selectedType !== 'all') params.append('credit_type', selectedType);
      // if (selectedStatus !== 'all') params.append('status', selectedStatus);
      //
      // const response = await fetch(`/api-v1/credits?${params}`);
      // if (!response.ok) throw new Error('Failed to fetch credits');
      // const data = await response.json();
      // return data.credits;

      // Mock data
      return [
        {
          id: 1,
          investor_id: 1,
          investor_name: 'John Doe',
          credit_type: 'EARLY_BIRD' as CreditType,
          amount: 25000,
          currency: 'USD',
          status: 'AVAILABLE' as CreditStatus,
          created_at: '2025-01-15T10:30:00Z',
          created_by_name: 'Admin User',
        },
        {
          id: 2,
          investor_id: 2,
          investor_name: 'Jane Smith',
          credit_type: 'PROMOTIONAL' as CreditType,
          amount: 10000,
          currency: 'USD',
          status: 'APPLIED' as CreditStatus,
          created_at: '2025-02-01T14:20:00Z',
          created_by_name: 'Finance Team',
        },
      ] as Credit[];
    },
  });

  // Calculate summary totals
  const summary = React.useMemo(() => {
    if (!credits) return { available: 0, applied: 0, expired: 0 };

    return credits.reduce(
      (acc, credit) => {
        if (credit.status === 'AVAILABLE') acc.available += credit.amount;
        else if (credit.status === 'APPLIED') acc.applied += credit.amount;
        else if (credit.status === 'EXPIRED') acc.expired += credit.amount;
        return acc;
      },
      { available: 0, applied: 0, expired: 0 }
    );
  }, [credits]);

  const getCreditTypeBadge = (type: CreditType) => {
    const variants: Record<CreditType, { variant: 'default' | 'secondary'; label: string }> = {
      EARLY_BIRD: { variant: 'default', label: 'Early Bird' },
      PROMOTIONAL: { variant: 'secondary', label: 'Promotional' },
    };
    const config = variants[type];
    return <Badge variant={config.variant}>{config.label}</Badge>;
  };

  const getStatusBadge = (status: CreditStatus) => {
    const variants: Record<
      CreditStatus,
      { variant: 'default' | 'secondary' | 'destructive'; label: string }
    > = {
      AVAILABLE: { variant: 'default', label: 'Available' },
      APPLIED: { variant: 'secondary', label: 'Applied' },
      EXPIRED: { variant: 'destructive', label: 'Expired' },
    };
    const config = variants[status];
    return <Badge variant={config.variant}>{config.label}</Badge>;
  };

  return (
    <div className="container mx-auto p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Credits Management</h1>
          <p className="text-muted-foreground mt-1">
            Manage investor credits and track balances
          </p>
        </div>
        <Button onClick={() => setCreateModalOpen(true)}>
          <Plus className="mr-2 h-4 w-4" />
          Create Credit
        </Button>
      </div>

      {/* Info Banner */}
      <Alert>
        <AlertCircle className="h-4 w-4" />
        <AlertDescription>
          <strong>Note:</strong> Credit application logic is coming soon. Credits can be created
          and viewed, but automatic application to charges will be implemented in the next phase.
        </AlertDescription>
      </Alert>

      {/* Summary Cards */}
      <div className="grid gap-4 md:grid-cols-3">
        {/* Available Credits */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Available Credits</CardTitle>
            <Coins className="h-4 w-4 text-green-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              ${summary.available.toLocaleString()}
            </div>
            <p className="text-xs text-muted-foreground">
              Ready to be applied to charges
            </p>
          </CardContent>
        </Card>

        {/* Applied Credits */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Applied Credits</CardTitle>
            <TrendingUp className="h-4 w-4 text-blue-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              ${summary.applied.toLocaleString()}
            </div>
            <p className="text-xs text-muted-foreground">
              Currently applied to charges
            </p>
          </CardContent>
        </Card>

        {/* Expired Credits */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Expired Credits</CardTitle>
            <DollarSign className="h-4 w-4 text-red-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              ${summary.expired.toLocaleString()}
            </div>
            <p className="text-xs text-muted-foreground">
              No longer valid
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Filters and Table */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle>Credits List</CardTitle>
              <CardDescription>
                {credits?.length || 0} total credit{credits?.length !== 1 ? 's' : ''}
              </CardDescription>
            </div>

            {/* Filters */}
            <div className="flex items-center gap-2">
              <Select value={selectedType} onValueChange={setSelectedType}>
                <SelectTrigger className="w-[140px]">
                  <SelectValue placeholder="Type" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Types</SelectItem>
                  <SelectItem value="EARLY_BIRD">Early Bird</SelectItem>
                  <SelectItem value="PROMOTIONAL">Promotional</SelectItem>
                </SelectContent>
              </Select>

              <Select value={selectedStatus} onValueChange={setSelectedStatus}>
                <SelectTrigger className="w-[140px]">
                  <SelectValue placeholder="Status" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Status</SelectItem>
                  <SelectItem value="AVAILABLE">Available</SelectItem>
                  <SelectItem value="APPLIED">Applied</SelectItem>
                  <SelectItem value="EXPIRED">Expired</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Investor</TableHead>
                <TableHead>Type</TableHead>
                <TableHead>Amount</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Created</TableHead>
                <TableHead>Created By</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {isLoading ? (
                <TableRow>
                  <TableCell colSpan={6} className="text-center py-8 text-muted-foreground">
                    Loading credits...
                  </TableCell>
                </TableRow>
              ) : !credits || credits.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={6} className="text-center py-8">
                    <Coins className="h-12 w-12 mx-auto text-muted-foreground mb-2" />
                    <p className="text-muted-foreground">
                      No credits found. Create your first credit →
                    </p>
                  </TableCell>
                </TableRow>
              ) : (
                credits.map((credit) => (
                  <TableRow key={credit.id}>
                    <TableCell className="font-medium">{credit.investor_name}</TableCell>
                    <TableCell>{getCreditTypeBadge(credit.credit_type)}</TableCell>
                    <TableCell>
                      {credit.currency} ${credit.amount.toLocaleString()}
                    </TableCell>
                    <TableCell>{getStatusBadge(credit.status)}</TableCell>
                    <TableCell>
                      {new Date(credit.created_at).toLocaleDateString()}
                    </TableCell>
                    <TableCell className="text-muted-foreground">
                      {credit.created_by_name}
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      {/* Create Credit Modal */}
      <CreateCreditModal
        open={createModalOpen}
        onClose={() => setCreateModalOpen(false)}
        onSuccess={() => refetch()}
      />
    </div>
  );
}
