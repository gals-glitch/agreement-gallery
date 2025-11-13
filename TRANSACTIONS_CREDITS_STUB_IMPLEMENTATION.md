# Transactions & Credits Ledger - STUB Implementation
**Ticket:** PG-401
**Date:** 2025-10-19
**Status:** ✅ Backend Complete, ⚠️ Frontend Remaining

---

## What's Been Implemented

### ✅ Backend (Complete)

1. **Database Migration**: `supabase/migrations/20251019100004_transactions_credits.sql`
   - Tables: `transactions`, `credits_ledger`, `credit_applications`
   - ENUMs: `transaction_type`, `transaction_source`, `credit_type`, `credit_status`
   - Indexes for performance
   - RLS policies (viewers+ read, finance+ write)

2. **API Endpoints**:
   - `supabase/functions/api-v1/transactions.ts`
     - `POST /transactions` - Create transaction (validates, inserts, returns stub message)
     - `GET /transactions` - List with filters (investor, type, fund, deal, date range, batch)
     - `GET /transactions/:id` - Detail view with joins

   - `supabase/functions/api-v1/credits.ts`
     - `POST /credits` - Create credit (validates, inserts with AVAILABLE status)
     - `GET /credits` - List with filters + balance summary

3. **API Router**: `supabase/functions/api-v1/index.ts`
   - Routes added for `transactions` and `credits`
   - Imports wired up

4. **TypeScript Types**: `src/types/transactions.ts`
   - All transaction and credit types
   - Request/response interfaces
   - Filter types

5. **React Query Hooks**: `src/hooks/useTransactions.ts`
   - `useTransactions(filters)` - Fetch list
   - `useTransaction(id)` - Fetch single
   - `useCreateTransaction()` - Create mutation
   - `useCredits(filters)` - Fetch list + balance
   - `useCreateCredit()` - Create mutation

### ⚠️ Frontend (Remaining)

The following files need to be created:

---

## Remaining Frontend Files

### 1. Credits Page

**File:** `src/pages/Credits.tsx`

```tsx
/**
 * Credits Page
 * Ticket: PG-401
 * Date: 2025-10-19
 */

import { useState } from 'react';
import { Navigate } from 'react-router-dom';
import { format } from 'date-fns';
import { Plus, DollarSign } from 'lucide-react';
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
import { useCredits } from '@/hooks/useTransactions';
import type { CreditType, CreditStatus } from '@/types/transactions';
import { CreateCreditModal } from '@/components/CreateCreditModal';

export default function CreditsPage() {
  const [showCreateModal, setShowCreateModal] = useState(false);
  const { data, isLoading, error } = useCredits();

  const getTypeBadgeVariant = (type: CreditType) => {
    return type === 'EARLY_BIRD' ? 'default' : 'secondary';
  };

  const getStatusBadgeVariant = (status: CreditStatus) => {
    switch (status) {
      case 'AVAILABLE':
        return 'default';
      case 'APPLIED':
        return 'secondary';
      case 'EXPIRED':
        return 'destructive';
      default:
        return 'outline';
    }
  };

  return (
    <FeatureGuard flag="credits_management" fallback={<Navigate to="/404" />}>
      <SidebarProvider>
        <AppSidebar />
        <main className="flex-1 p-6 overflow-auto">
          <SidebarTrigger className="mb-4" />

          {/* Header */}
          <div className="flex items-center justify-between mb-6">
            <div>
              <h1 className="text-3xl font-bold">Credits Management</h1>
              <p className="text-muted-foreground">
                Track investor credits for future charge application
              </p>
            </div>
            <Button onClick={() => setShowCreateModal(true)}>
              <Plus className="w-4 h-4 mr-2" />
              Create Credit
            </Button>
          </div>

          {/* Info Banner */}
          <Alert className="mb-6">
            <AlertDescription>
              <strong>Note:</strong> Credit application logic coming soon. Credits are currently
              tracked for future application to charges in Phase 3.
            </AlertDescription>
          </Alert>

          {/* Summary Cards */}
          {data && (
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
              <Card>
                <CardHeader className="pb-2">
                  <CardTitle className="text-sm font-medium">Available Credits</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold text-green-600">
                    {data.balance.currency} {data.balance.total_available.toLocaleString()}
                  </div>
                </CardContent>
              </Card>
              <Card>
                <CardHeader className="pb-2">
                  <CardTitle className="text-sm font-medium">Applied Credits</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold text-blue-600">
                    {data.balance.currency} {data.balance.total_applied.toLocaleString()}
                  </div>
                </CardContent>
              </Card>
              <Card>
                <CardHeader className="pb-2">
                  <CardTitle className="text-sm font-medium">Expired Credits</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold text-red-600">
                    {data.balance.currency} {data.balance.total_expired.toLocaleString()}
                  </div>
                </CardContent>
              </Card>
            </div>
          )}

          {/* Credits Table */}
          <Card>
            <CardHeader>
              <CardTitle>All Credits</CardTitle>
              <CardDescription>{data?.total_count || 0} total credits</CardDescription>
            </CardHeader>
            <CardContent>
              {isLoading ? (
                <div className="text-center py-8 text-muted-foreground">Loading...</div>
              ) : error ? (
                <div className="text-center py-8 text-red-500">
                  Error loading credits: {error.message}
                </div>
              ) : data && data.credits.length > 0 ? (
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Investor</TableHead>
                      <TableHead>Credit Type</TableHead>
                      <TableHead className="text-right">Original Amount</TableHead>
                      <TableHead className="text-right">Remaining</TableHead>
                      <TableHead>Status</TableHead>
                      <TableHead>Created</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {data.credits.map((credit) => (
                      <TableRow key={credit.id}>
                        <TableCell>
                          <div className="font-medium">{credit.investor?.name || 'Unknown'}</div>
                        </TableCell>
                        <TableCell>
                          <Badge variant={getTypeBadgeVariant(credit.credit_type)}>
                            {credit.credit_type.replace('_', ' ')}
                          </Badge>
                        </TableCell>
                        <TableCell className="text-right font-mono">
                          {credit.currency} {credit.original_amount.toLocaleString()}
                        </TableCell>
                        <TableCell className="text-right font-mono">
                          {credit.currency} {credit.remaining_amount.toLocaleString()}
                        </TableCell>
                        <TableCell>
                          <Badge variant={getStatusBadgeVariant(credit.status)}>
                            {credit.status}
                          </Badge>
                        </TableCell>
                        <TableCell>{format(new Date(credit.created_at), 'MMM dd, yyyy')}</TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              ) : (
                <div className="text-center py-12">
                  <p className="text-muted-foreground mb-4">
                    No credits yet. Create your first credit.
                  </p>
                  <Button onClick={() => setShowCreateModal(true)}>
                    <Plus className="w-4 h-4 mr-2" />
                    Create Credit
                  </Button>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Create Credit Modal */}
          {showCreateModal && (
            <CreateCreditModal open={showCreateModal} onClose={() => setShowCreateModal(false)} />
          )}
        </main>
      </SidebarProvider>
    </FeatureGuard>
  );
}
```

---

### 2. Create Transaction Modal

**File:** `src/components/CreateTransactionModal.tsx`

```tsx
/**
 * Create Transaction Modal
 * Ticket: PG-401
 * Date: 2025-10-19
 */

import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { useCreateTransaction } from '@/hooks/useTransactions';
import type { CreateTransactionRequest, TransactionType } from '@/types/transactions';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Textarea } from '@/components/ui/textarea';

interface CreateTransactionModalProps {
  open: boolean;
  onClose: () => void;
}

export function CreateTransactionModal({ open, onClose }: CreateTransactionModalProps) {
  const { register, handleSubmit, setValue, watch, formState: { errors } } = useForm<CreateTransactionRequest>();
  const createTransaction = useCreateTransaction();
  const [scopeType, setScopeType] = useState<'fund' | 'deal'>('fund');

  const onSubmit = async (data: CreateTransactionRequest) => {
    await createTransaction.mutateAsync(data);
    onClose();
  };

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle>Create Transaction</DialogTitle>
          <DialogDescription>
            Record a new investor transaction (contribution or repurchase)
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
          {/* Investor ID */}
          <div>
            <Label htmlFor="investor_id">Investor ID *</Label>
            <Input
              id="investor_id"
              type="number"
              {...register('investor_id', { required: true, valueAsNumber: true })}
              placeholder="e.g., 123"
            />
            {errors.investor_id && <p className="text-sm text-red-500">Required</p>}
          </div>

          {/* Type */}
          <div>
            <Label htmlFor="type">Type *</Label>
            <Select onValueChange={(value) => setValue('type', value as TransactionType)}>
              <SelectTrigger id="type">
                <SelectValue placeholder="Select type" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="CONTRIBUTION">Contribution</SelectItem>
                <SelectItem value="REPURCHASE">Repurchase</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {/* Amount */}
          <div>
            <Label htmlFor="amount">Amount *</Label>
            <Input
              id="amount"
              type="number"
              step="0.01"
              {...register('amount', { required: true, valueAsNumber: true, min: 0.01 })}
              placeholder="0.00"
            />
            {errors.amount && <p className="text-sm text-red-500">Must be positive</p>}
          </div>

          {/* Currency */}
          <div>
            <Label htmlFor="currency">Currency</Label>
            <Input
              id="currency"
              {...register('currency')}
              placeholder="USD"
              defaultValue="USD"
            />
          </div>

          {/* Transaction Date */}
          <div>
            <Label htmlFor="transaction_date">Date *</Label>
            <Input
              id="transaction_date"
              type="date"
              {...register('transaction_date', { required: true })}
            />
            {errors.transaction_date && <p className="text-sm text-red-500">Required</p>}
          </div>

          {/* Scope Selector */}
          <div>
            <Label>Scope *</Label>
            <div className="flex gap-2 mb-2">
              <Button
                type="button"
                variant={scopeType === 'fund' ? 'default' : 'outline'}
                size="sm"
                onClick={() => setScopeType('fund')}
              >
                Fund
              </Button>
              <Button
                type="button"
                variant={scopeType === 'deal' ? 'default' : 'outline'}
                size="sm"
                onClick={() => setScopeType('deal')}
              >
                Deal
              </Button>
            </div>

            {scopeType === 'fund' ? (
              <Input
                type="number"
                {...register('fund_id', { valueAsNumber: true })}
                placeholder="Fund ID"
              />
            ) : (
              <Input
                type="number"
                {...register('deal_id', { valueAsNumber: true })}
                placeholder="Deal ID"
              />
            )}
          </div>

          {/* Notes */}
          <div>
            <Label htmlFor="notes">Notes</Label>
            <Textarea id="notes" {...register('notes')} placeholder="Optional notes" rows={3} />
          </div>

          <DialogFooter>
            <Button type="button" variant="outline" onClick={onClose}>
              Cancel
            </Button>
            <Button type="submit" disabled={createTransaction.isPending}>
              {createTransaction.isPending ? 'Creating...' : 'Create Transaction'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
```

---

### 3. Create Credit Modal

**File:** `src/components/CreateCreditModal.tsx`

```tsx
/**
 * Create Credit Modal
 * Ticket: PG-401
 * Date: 2025-10-19
 */

import { useForm } from 'react-hook-form';
import { useCreateCredit } from '@/hooks/useTransactions';
import type { CreateCreditRequest, CreditType } from '@/types/transactions';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';

interface CreateCreditModalProps {
  open: boolean;
  onClose: () => void;
}

export function CreateCreditModal({ open, onClose }: CreateCreditModalProps) {
  const { register, handleSubmit, setValue, formState: { errors } } = useForm<CreateCreditRequest>();
  const createCredit = useCreateCredit();

  const onSubmit = async (data: CreateCreditRequest) => {
    await createCredit.mutateAsync(data);
    onClose();
  };

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle>Create Credit</DialogTitle>
          <DialogDescription>Create a new investor credit</DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
          {/* Investor ID */}
          <div>
            <Label htmlFor="investor_id">Investor ID *</Label>
            <Input
              id="investor_id"
              type="number"
              {...register('investor_id', { required: true, valueAsNumber: true })}
              placeholder="e.g., 123"
            />
            {errors.investor_id && <p className="text-sm text-red-500">Required</p>}
          </div>

          {/* Credit Type */}
          <div>
            <Label htmlFor="credit_type">Credit Type *</Label>
            <Select onValueChange={(value) => setValue('credit_type', value as CreditType)}>
              <SelectTrigger id="credit_type">
                <SelectValue placeholder="Select type" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="EARLY_BIRD">Early Bird</SelectItem>
                <SelectItem value="PROMOTIONAL">Promotional</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {/* Amount */}
          <div>
            <Label htmlFor="amount">Amount *</Label>
            <Input
              id="amount"
              type="number"
              step="0.01"
              {...register('amount', { required: true, valueAsNumber: true, min: 0.01 })}
              placeholder="0.00"
            />
            {errors.amount && <p className="text-sm text-red-500">Must be positive</p>}
          </div>

          {/* Currency */}
          <div>
            <Label htmlFor="currency">Currency</Label>
            <Input
              id="currency"
              {...register('currency')}
              placeholder="USD"
              defaultValue="USD"
            />
          </div>

          <DialogFooter>
            <Button type="button" variant="outline" onClick={onClose}>
              Cancel
            </Button>
            <Button type="submit" disabled={createCredit.isPending}>
              {createCredit.isPending ? 'Creating...' : 'Create Credit'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
```

---

### 4. App Routes (App.tsx)

Add these routes to `src/App.tsx`:

```tsx
// Import pages
import TransactionsPage from "./pages/Transactions";
import CreditsPage from "./pages/Credits";

// Add routes (in the router array):
{
  path: "/transactions",
  element: (
    <ProtectedRoute requiredRoles={['admin', 'finance']}>
      <FeatureGuard flag="charges_engine" fallback={<NotFound />}>
        <TransactionsPage />
      </FeatureGuard>
    </ProtectedRoute>
  )
},
{
  path: "/credits",
  element: (
    <ProtectedRoute requiredRoles={['admin', 'finance']}>
      <FeatureGuard flag="credits_management" fallback={<NotFound />}>
        <CreditsPage />
      </FeatureGuard>
    </ProtectedRoute>
  )
},
```

---

### 5. AppSidebar Navigation

Add these items to `src/components/AppSidebar.tsx` in the DATA section:

```tsx
import { Receipt, Coins } from "lucide-react";

// In dataItems array:
{
  title: "Transactions",
  url: "/transactions",
  icon: Receipt,
  description: "Capital movements",
  featureFlag: "charges_engine"
},
{
  title: "Credits",
  url: "/credits",
  icon: Coins,
  description: "Credit ledger",
  featureFlag: "credits_management"
},
```

---

## Setup Steps

### 1. Apply Migration

```bash
# From project root
cd supabase
supabase db reset  # OR apply specific migration
```

### 2. Enable Feature Flags (Admin Panel)

As admin user, enable flags in database:
```sql
UPDATE feature_flags SET enabled = TRUE WHERE key IN ('charges_engine', 'credits_management');
```

### 3. Test API Endpoints

```bash
# Create transaction
curl -X POST https://your-project.supabase.co/functions/v1/api-v1/transactions \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "investor_id": 1,
    "type": "CONTRIBUTION",
    "amount": 50000,
    "currency": "USD",
    "transaction_date": "2025-01-15",
    "fund_id": 1,
    "notes": "Initial investment"
  }'

# List transactions
curl https://your-project.supabase.co/functions/v1/api-v1/transactions?type=CONTRIBUTION \
  -H "Authorization: Bearer YOUR_TOKEN"

# Create credit
curl -X POST https://your-project.supabase.co/functions/v1/api-v1/credits \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "investor_id": 1,
    "credit_type": "EARLY_BIRD",
    "amount": 5000,
    "currency": "USD"
  }'

# List credits
curl https://your-project.supabase.co/functions/v1/api-v1/credits \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## Future Work (Phase 3)

1. **Calculation Engine**:
   - POST /transactions with type=CONTRIBUTION → auto-create draft charge
   - POST /transactions with type=REPURCHASE → auto-create credit in credits_ledger

2. **Credit Application**:
   - POST /charges/:id/apply-credit → apply available credits to charges
   - Auto-decrement `remaining_amount` in credits_ledger
   - Create entries in `credit_applications` table

3. **CSV Import**:
   - POST /transactions/batch → bulk import with per-row error tracking
   - Idempotency via batch_id

---

## Troubleshooting

### Migration Fails

- **Issue**: Foreign key constraint errors
- **Fix**: Ensure `parties`, `funds`, `deals` tables exist from earlier migrations

### API Returns 404

- **Issue**: Routes not registered
- **Fix**: Verify imports in `index.ts` and restart Edge Functions

### Feature Flag Not Working

- **Issue**: Page shows 404 even when logged in
- **Fix**: Check flag enabled AND user role in `enabled_for_roles` array

---

## File Checklist

- [x] `supabase/migrations/20251019100004_transactions_credits.sql`
- [x] `supabase/functions/api-v1/transactions.ts`
- [x] `supabase/functions/api-v1/credits.ts`
- [x] `supabase/functions/api-v1/index.ts` (updated)
- [x] `src/types/transactions.ts`
- [x] `src/hooks/useTransactions.ts`
- [x] `src/pages/Transactions.tsx`
- [ ] `src/pages/Credits.tsx` **(CREATE THIS)**
- [ ] `src/components/CreateTransactionModal.tsx` **(CREATE THIS)**
- [ ] `src/components/CreateCreditModal.tsx` **(CREATE THIS)**
- [ ] `src/App.tsx` (add routes) **(UPDATE THIS)**
- [ ] `src/components/AppSidebar.tsx` (add nav items) **(UPDATE THIS)**

---

## Testing Workflow

1. **As Admin**, enable feature flags in Profile page
2. Navigate to **/transactions**
3. Click "Create Transaction"
4. Fill form:
   - Investor ID: 1
   - Type: CONTRIBUTION
   - Amount: 50000
   - Date: Today
   - Fund ID: 1
5. Submit → Should see success toast "Transaction recorded (calculation pending)"
6. Verify in table
7. Navigate to **/credits**
8. Click "Create Credit"
9. Fill form:
   - Investor ID: 1
   - Type: EARLY_BIRD
   - Amount: 5000
10. Submit → Should see in table with status AVAILABLE
11. Check summary cards show correct totals

---

## API Documentation

See `docs/WORKFLOWS-API.md` for complete endpoint specs (to be added).

---

**END OF STUB IMPLEMENTATION GUIDE**
