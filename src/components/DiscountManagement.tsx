import React, { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Textarea } from '@/components/ui/textarea';
import { Switch } from '@/components/ui/switch';
import { Badge } from '@/components/ui/badge';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from '@/components/ui/alert-dialog';
import { Percent, Plus, Edit, Trash2, TrendingDown } from 'lucide-react';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from '@/hooks/use-toast';

interface Discount {
  id: string;
  investor_name: string;
  fund_name: string;
  discount_type: string;
  percentage?: number;
  amount: number;
  effective_date: string;
  expiry_date?: string;
  is_refunded_via_distributions: boolean;
  status: string;
  notes?: string;
  created_at: string;
  updated_at: string;
}

interface DiscountFormData {
  investor_name: string;
  fund_name: string;
  discount_type: string;
  percentage: string;
  amount: string;
  effective_date: string;
  expiry_date: string;
  is_refunded_via_distributions: boolean;
  notes: string;
}

const initialFormData: DiscountFormData = {
  investor_name: '',
  fund_name: '',
  discount_type: 'percentage',
  percentage: '',
  amount: '',
  effective_date: '',
  expiry_date: '',
  is_refunded_via_distributions: false,
  notes: ''
};

// Discount Management Component
export default function DiscountManagement() {
  const [discounts, setDiscounts] = useState<Discount[]>([]);
  const [loading, setLoading] = useState(true);
  const [formData, setFormData] = useState<DiscountFormData>(initialFormData);
  const [editingDiscount, setEditingDiscount] = useState<Discount | null>(null);
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  
  const { toast } = useToast();

  useEffect(() => {
    fetchDiscounts();
  }, []);

  const fetchDiscounts = async () => {
    try {
      const { data, error } = await supabase
        .from('discounts')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      setDiscounts(data || []);
    } catch (error) {
      console.error('Error fetching discounts:', error);
      toast({
        title: "Error",
        description: "Failed to load discounts",
        variant: "destructive"
      });
    } finally {
      setLoading(false);
    }
  };

  const handleInputChange = (field: keyof DiscountFormData, value: string | boolean) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!formData.investor_name.trim() || !formData.fund_name.trim()) {
      toast({
        title: "Validation Error",
        description: "Investor name and fund name are required",
        variant: "destructive"
      });
      return;
    }

    if (formData.discount_type === 'percentage' && !formData.percentage) {
      toast({
        title: "Validation Error",
        description: "Percentage is required for percentage discounts",
        variant: "destructive"
      });
      return;
    }

    if (formData.discount_type === 'fixed_amount' && !formData.amount) {
      toast({
        title: "Validation Error",
        description: "Amount is required for fixed amount discounts",
        variant: "destructive"
      });
      return;
    }

    if (!formData.effective_date) {
      toast({
        title: "Validation Error",
        description: "Effective date is required",
        variant: "destructive"
      });
      return;
    }

    try {
      const discountData = {
        investor_name: formData.investor_name.trim(),
        fund_name: formData.fund_name.trim(),
        discount_type: formData.discount_type,
        percentage: formData.discount_type === 'percentage' ? parseFloat(formData.percentage) : null,
        amount: formData.discount_type === 'fixed_amount' ? parseFloat(formData.amount) : 0,
        effective_date: formData.effective_date,
        expiry_date: formData.expiry_date || null,
        is_refunded_via_distributions: formData.is_refunded_via_distributions,
        notes: formData.notes || null,
        status: 'Active' as const
      };

      if (editingDiscount) {
        const { error } = await supabase
          .from('discounts')
          .update(discountData)
          .eq('id', editingDiscount.id);

        if (error) throw error;
        
        toast({
          title: "Success",
          description: "Discount updated successfully"
        });
      } else {
        const { error } = await supabase
          .from('discounts')
          .insert([discountData]);

        if (error) throw error;
        
        toast({
          title: "Success",
          description: "Discount created successfully"
        });
      }

      await fetchDiscounts();
      handleCloseDialog();
    } catch (error: any) {
      console.error('Error saving discount:', error);
      toast({
        title: "Error",
        description: "Failed to save discount",
        variant: "destructive"
      });
    }
  };

  const handleEdit = (discount: Discount) => {
    setEditingDiscount(discount);
    setFormData({
      investor_name: discount.investor_name,
      fund_name: discount.fund_name,
      discount_type: discount.discount_type,
      percentage: discount.percentage?.toString() || '',
      amount: discount.amount.toString(),
      effective_date: discount.effective_date,
      expiry_date: discount.expiry_date || '',
      is_refunded_via_distributions: discount.is_refunded_via_distributions,
      notes: discount.notes || ''
    });
    setIsDialogOpen(true);
  };

  const handleDelete = async (discount: Discount) => {
    try {
      const { error } = await supabase
        .from('discounts')
        .delete()
        .eq('id', discount.id);

      if (error) throw error;
      
      toast({
        title: "Success",
        description: "Discount deleted successfully"
      });
      
      await fetchDiscounts();
    } catch (error) {
      console.error('Error deleting discount:', error);
      toast({
        title: "Error",
        description: "Failed to delete discount",
        variant: "destructive"
      });
    }
  };

  const handleCloseDialog = () => {
    setIsDialogOpen(false);
    setEditingDiscount(null);
    setFormData(initialFormData);
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'Active': return 'default';
      case 'Expired': return 'secondary';
      case 'Used': return 'outline';
      default: return 'default';
    }
  };

  const formatDiscountValue = (discount: Discount) => {
    if (discount.discount_type === 'percentage') {
      return `${discount.percentage}%`;
    } else {
      return `$${discount.amount.toLocaleString()}`;
    }
  };

  const getTotalDiscountValue = () => {
    return discounts
      .filter(d => d.status === 'Active')
      .reduce((sum, d) => {
        if (d.discount_type === 'fixed_amount') {
          return sum + d.amount;
        }
        return sum; // Percentage discounts would need base amounts to calculate
      }, 0);
  };

  if (loading) {
    return (
      <div className="max-w-7xl mx-auto px-4 py-6">
        <div className="flex items-center justify-center h-64">
          <div className="text-center">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto"></div>
            <p className="mt-2 text-muted-foreground">Loading discounts...</p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-7xl mx-auto px-4 py-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Discount Management</h1>
          <p className="text-muted-foreground">
            Manage investor discounts and concessions
          </p>
        </div>
        
        <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
          <DialogTrigger asChild>
            <Button>
              <Plus className="w-4 h-4 mr-2" />
              Add Discount
            </Button>
          </DialogTrigger>
          <DialogContent className="sm:max-w-2xl">
            <DialogHeader>
              <DialogTitle>
                {editingDiscount ? 'Edit' : 'Add'} Discount
              </DialogTitle>
              <DialogDescription>
                {editingDiscount ? 'Update' : 'Create a new'} discount configuration
              </DialogDescription>
            </DialogHeader>
            
            <form onSubmit={handleSubmit} className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label htmlFor="investor_name">Investor Name *</Label>
                  <Input
                    id="investor_name"
                    value={formData.investor_name}
                    onChange={(e) => handleInputChange('investor_name', e.target.value)}
                    placeholder="Investor name"
                    required
                  />
                </div>
                
                <div>
                  <Label htmlFor="fund_name">Fund Name *</Label>
                  <Input
                    id="fund_name"
                    value={formData.fund_name}
                    onChange={(e) => handleInputChange('fund_name', e.target.value)}
                    placeholder="Fund name"
                    required
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label htmlFor="discount_type">Discount Type *</Label>
                  <Select
                    value={formData.discount_type}
                    onValueChange={(value) => handleInputChange('discount_type', value)}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="percentage">Percentage</SelectItem>
                      <SelectItem value="fixed_amount">Fixed Amount</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                
                {formData.discount_type === 'percentage' ? (
                  <div>
                    <Label htmlFor="percentage">Percentage *</Label>
                    <Input
                      id="percentage"
                      type="number"
                      step="0.01"
                      min="0"
                      max="100"
                      value={formData.percentage}
                      onChange={(e) => handleInputChange('percentage', e.target.value)}
                      placeholder="10.00"
                      required={formData.discount_type === 'percentage'}
                    />
                  </div>
                ) : (
                  <div>
                    <Label htmlFor="amount">Amount ($) *</Label>
                    <Input
                      id="amount"
                      type="number"
                      step="0.01"
                      min="0"
                      value={formData.amount}
                      onChange={(e) => handleInputChange('amount', e.target.value)}
                      placeholder="10000.00"
                      required={formData.discount_type === 'fixed_amount'}
                    />
                  </div>
                )}
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label htmlFor="effective_date">Effective Date *</Label>
                  <Input
                    id="effective_date"
                    type="date"
                    value={formData.effective_date}
                    onChange={(e) => handleInputChange('effective_date', e.target.value)}
                    required
                  />
                </div>
                
                <div>
                  <Label htmlFor="expiry_date">Expiry Date</Label>
                  <Input
                    id="expiry_date"
                    type="date"
                    value={formData.expiry_date}
                    onChange={(e) => handleInputChange('expiry_date', e.target.value)}
                  />
                </div>
              </div>

              <div className="flex items-center space-x-2">
                <Switch
                  id="is_refunded_via_distributions"
                  checked={formData.is_refunded_via_distributions}
                  onCheckedChange={(checked) => handleInputChange('is_refunded_via_distributions', checked)}
                />
                <Label htmlFor="is_refunded_via_distributions">Refunded via distributions</Label>
              </div>

              <div>
                <Label htmlFor="notes">Notes</Label>
                <Textarea
                  id="notes"
                  value={formData.notes}
                  onChange={(e) => handleInputChange('notes', e.target.value)}
                  placeholder="Additional notes or conditions..."
                  rows={3}
                />
              </div>

              <div className="flex justify-end gap-2 pt-4">
                <Button type="button" variant="outline" onClick={handleCloseDialog}>
                  Cancel
                </Button>
                <Button type="submit">
                  {editingDiscount ? 'Update' : 'Create'} Discount
                </Button>
              </div>
            </form>
          </DialogContent>
        </Dialog>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Discounts</CardTitle>
            <Percent className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{discounts.length}</div>
            <p className="text-xs text-muted-foreground">
              {discounts.filter(d => d.status === 'Active').length} active
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Percentage Discounts</CardTitle>
            <TrendingDown className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {discounts.filter(d => d.discount_type === 'percentage').length}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Fixed Amount</CardTitle>
            <TrendingDown className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {discounts.filter(d => d.discount_type === 'fixed_amount').length}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Value</CardTitle>
            <TrendingDown className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              ${getTotalDiscountValue().toLocaleString()}
            </div>
            <p className="text-xs text-muted-foreground">Fixed amounts only</p>
          </CardContent>
        </Card>
      </div>

      {/* Discounts Table */}
      <Card>
        <CardHeader>
          <CardTitle>Discounts</CardTitle>
          <CardDescription>
            Manage investor discounts and concessions
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Investor</TableHead>
                <TableHead>Fund</TableHead>
                <TableHead>Type</TableHead>
                <TableHead>Value</TableHead>
                <TableHead>Effective Date</TableHead>
                <TableHead>Expiry Date</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {discounts.map((discount) => (
                <TableRow key={discount.id}>
                  <TableCell>
                    <div className="font-medium">{discount.investor_name}</div>
                  </TableCell>
                  <TableCell>{discount.fund_name}</TableCell>
                  <TableCell>
                    <Badge variant="outline">
                      {discount.discount_type === 'percentage' ? 'Percentage' : 'Fixed Amount'}
                    </Badge>
                  </TableCell>
                  <TableCell className="font-medium">
                    {formatDiscountValue(discount)}
                  </TableCell>
                  <TableCell>
                    {new Date(discount.effective_date).toLocaleDateString()}
                  </TableCell>
                  <TableCell>
                    {discount.expiry_date 
                      ? new Date(discount.expiry_date).toLocaleDateString() 
                      : '—'
                    }
                  </TableCell>
                  <TableCell>
                    <Badge variant={getStatusColor(discount.status)}>
                      {discount.status}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <div className="flex gap-2">
                      <Button size="sm" variant="outline" onClick={() => handleEdit(discount)}>
                        <Edit className="w-4 h-4" />
                      </Button>
                      <AlertDialog>
                        <AlertDialogTrigger asChild>
                          <Button size="sm" variant="outline">
                            <Trash2 className="w-4 h-4" />
                          </Button>
                        </AlertDialogTrigger>
                        <AlertDialogContent>
                          <AlertDialogHeader>
                            <AlertDialogTitle>Delete Discount</AlertDialogTitle>
                            <AlertDialogDescription>
                              Are you sure you want to delete this discount? This action cannot be undone.
                            </AlertDialogDescription>
                          </AlertDialogHeader>
                          <AlertDialogFooter>
                            <AlertDialogCancel>Cancel</AlertDialogCancel>
                            <AlertDialogAction onClick={() => handleDelete(discount)}>
                              Delete
                            </AlertDialogAction>
                          </AlertDialogFooter>
                        </AlertDialogContent>
                      </AlertDialog>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
          {discounts.length === 0 && (
            <div className="text-center text-muted-foreground py-8">
              No discounts configured
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}