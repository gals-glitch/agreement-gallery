/**
 * Transactions Page
 * Ticket: PG-401
 * Date: 2025-10-19
 *
 * STUB NOTICE: This is Phase 2 stub work. Displays transaction list with
 * filters. Calculation logic for charge creation will be added in Phase 3.
 */

import { useState } from 'react';
import { Navigate } from 'react-router-dom';
import { format } from 'date-fns';
import { Plus, Filter, Download } from 'lucide-react';
import { FeatureGuard } from '@/components/FeatureGuard';
import { SidebarProvider, SidebarTrigger } from '@/components/ui/sidebar';
import { AppSidebar } from '@/components/AppSidebar';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Badge } from '@/components/ui/badge';
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
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { useTransactions } from '@/hooks/useTransactions';
import type { TransactionType, TransactionFilters } from '@/types/transactions';
import { CreateTransactionModal } from '@/components/CreateTransactionModal';

export default function TransactionsPage() {
  const [filters, setFilters] = useState<TransactionFilters>({
    limit: 50,
    offset: 0,
  });
  const [showFilters, setShowFilters] = useState(false);
  const [showCreateModal, setShowCreateModal] = useState(false);

  const { data, isLoading, error } = useTransactions(filters);

  const handleFilterChange = (key: keyof TransactionFilters, value: any) => {
    setFilters((prev) => ({
      ...prev,
      [key]: value === 'all' ? undefined : value,
      offset: 0, // Reset pagination on filter change
    }));
  };

  const getTypeBadgeVariant = (type: TransactionType) => {
    switch (type) {
      case 'CONTRIBUTION':
        return 'default'; // Green
      case 'REPURCHASE':
        return 'secondary'; // Blue
      default:
        return 'outline';
    }
  };

  return (
    <FeatureGuard flag="charges_engine" fallback={<Navigate to="/404" />}>
      <SidebarProvider>
        <AppSidebar />
        <main className="flex-1 p-6 overflow-auto">
          <SidebarTrigger className="mb-4" />

          {/* Header */}
          <div className="flex items-center justify-between mb-6">
            <div>
              <h1 className="text-3xl font-bold">Transactions</h1>
              <p className="text-muted-foreground">
                Track investor capital movements (contributions and repurchases)
              </p>
            </div>
            <Button onClick={() => setShowCreateModal(true)}>
              <Plus className="w-4 h-4 mr-2" />
              Create Transaction
            </Button>
          </div>

          {/* Info Banner */}
          <Alert className="mb-6">
            <AlertDescription>
              <strong>Note:</strong> Charge calculations coming soon. Transactions are currently
              recorded for future processing in Phase 3.
            </AlertDescription>
          </Alert>

          {/* Filters Card */}
          <Card className="mb-6">
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle>Filters</CardTitle>
                <Button variant="ghost" size="sm" onClick={() => setShowFilters(!showFilters)}>
                  <Filter className="w-4 h-4 mr-2" />
                  {showFilters ? 'Hide' : 'Show'} Filters
                </Button>
              </div>
            </CardHeader>
            {showFilters && (
              <CardContent className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div>
                  <Label htmlFor="type-filter">Type</Label>
                  <Select
                    value={filters.type || 'all'}
                    onValueChange={(value) => handleFilterChange('type', value)}
                  >
                    <SelectTrigger id="type-filter">
                      <SelectValue placeholder="All Types" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All Types</SelectItem>
                      <SelectItem value="CONTRIBUTION">Contribution</SelectItem>
                      <SelectItem value="REPURCHASE">Repurchase</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div>
                  <Label htmlFor="from-date">From Date</Label>
                  <Input
                    id="from-date"
                    type="date"
                    value={filters.from || ''}
                    onChange={(e) => handleFilterChange('from', e.target.value)}
                  />
                </div>

                <div>
                  <Label htmlFor="to-date">To Date</Label>
                  <Input
                    id="to-date"
                    type="date"
                    value={filters.to || ''}
                    onChange={(e) => handleFilterChange('to', e.target.value)}
                  />
                </div>
              </CardContent>
            )}
          </Card>

          {/* Transactions Table */}
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle>All Transactions</CardTitle>
                  <CardDescription>
                    {data?.total_count || 0} total transactions
                  </CardDescription>
                </div>
                <Button variant="outline" size="sm">
                  <Download className="w-4 h-4 mr-2" />
                  Export CSV
                </Button>
              </div>
            </CardHeader>
            <CardContent>
              {isLoading ? (
                <div className="text-center py-8 text-muted-foreground">Loading...</div>
              ) : error ? (
                <div className="text-center py-8 text-red-500">
                  Error loading transactions: {error.message}
                </div>
              ) : data && data.transactions.length > 0 ? (
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Date</TableHead>
                      <TableHead>Investor</TableHead>
                      <TableHead>Type</TableHead>
                      <TableHead>Fund/Deal</TableHead>
                      <TableHead className="text-right">Amount</TableHead>
                      <TableHead>Source</TableHead>
                      <TableHead className="text-right">Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {data.transactions.map((transaction) => (
                      <TableRow key={transaction.id}>
                        <TableCell>
                          {format(new Date(transaction.transaction_date), 'MMM dd, yyyy')}
                        </TableCell>
                        <TableCell>
                          <div className="font-medium">{transaction.investor?.name || 'Unknown'}</div>
                          <div className="text-sm text-muted-foreground">
                            {transaction.investor?.email}
                          </div>
                        </TableCell>
                        <TableCell>
                          <Badge variant={getTypeBadgeVariant(transaction.type)}>
                            {transaction.type}
                          </Badge>
                        </TableCell>
                        <TableCell>
                          {transaction.fund?.name || transaction.deal?.name || '-'}
                        </TableCell>
                        <TableCell className="text-right font-mono">
                          {transaction.currency} {transaction.amount.toLocaleString('en-US', {
                            minimumFractionDigits: 2,
                            maximumFractionDigits: 2,
                          })}
                        </TableCell>
                        <TableCell>
                          <span className="text-sm text-muted-foreground capitalize">
                            {transaction.source.toLowerCase().replace('_', ' ')}
                          </span>
                        </TableCell>
                        <TableCell className="text-right">
                          <Button variant="ghost" size="sm">
                            View Details
                          </Button>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              ) : (
                <div className="text-center py-12">
                  <p className="text-muted-foreground mb-4">
                    No transactions yet. Create your first transaction.
                  </p>
                  <Button onClick={() => setShowCreateModal(true)}>
                    <Plus className="w-4 h-4 mr-2" />
                    Create Transaction
                  </Button>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Create Transaction Modal */}
          {showCreateModal && (
            <CreateTransactionModal
              open={showCreateModal}
              onClose={() => setShowCreateModal(false)}
            />
          )}
        </main>
      </SidebarProvider>
    </FeatureGuard>
  );
}
