import React, { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Checkbox } from '@/components/ui/checkbox';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from '@/components/ui/alert-dialog';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { Calendar } from '@/components/ui/calendar';
import { cn } from '@/lib/utils';
import { format } from 'date-fns';
import { CalendarIcon, Plus, Edit, Trash2, Target, ArrowLeft, TrendingUp, Info } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { useNavigate } from 'react-router-dom';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { dealsAPI } from '@/api/clientV2';
import { supabase } from '@/integrations/supabase/client';
import type { Deal } from '@/types/api';

interface DealFormData {
  fund_id: string;
  name: string;
  address: string;
  status: string;
  close_date: Date | undefined;
  sector: string;
  year_built: string;
  units: string;
  sqft: string;
  income_producing: boolean;
  exclude_gp_from_commission: boolean;
}

const initialFormData: DealFormData = {
  fund_id: '',
  name: '',
  address: '',
  status: 'Active',
  close_date: undefined,
  sector: '',
  year_built: '',
  units: '',
  sqft: '',
  income_producing: false,
  exclude_gp_from_commission: false
};

export default function Deals() {
  const [deals, setDeals] = useState<Deal[]>([]);
  const [loading, setLoading] = useState(true);
  const [formData, setFormData] = useState<DealFormData>(initialFormData);
  const [editingDeal, setEditingDeal] = useState<Deal | null>(null);
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const navigate = useNavigate();
  
  const { toast } = useToast();

  useEffect(() => {
    fetchDeals();
  }, []);

  const fetchDeals = async () => {
    try {
      setLoading(true);
      const response = await dealsAPI.list();
      setDeals(response.items);
    } catch (error) {
      console.error('Error fetching deals:', error);
      toast({
        title: "Error",
        description: "Failed to load deals",
        variant: "destructive"
      });
    } finally {
      setLoading(false);
    }
  };

  const handleInputChange = (field: keyof DealFormData, value: any) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!formData.name.trim()) {
      toast({
        title: "Validation Error",
        description: "Deal name is required",
        variant: "destructive"
      });
      return;
    }

    try {
      const dealData: any = {
        fund_id: formData.fund_id ? parseInt(formData.fund_id) : undefined,
        name: formData.name.trim(),
        address: formData.address.trim() || undefined,
        status: formData.status || 'Active',
        close_date: formData.close_date ? format(formData.close_date, 'yyyy-MM-dd') : undefined,
        sector: formData.sector.trim() || undefined,
        year_built: formData.year_built ? parseInt(formData.year_built) : undefined,
        units: formData.units ? parseInt(formData.units) : undefined,
        sqft: formData.sqft ? parseInt(formData.sqft) : undefined,
        income_producing: formData.income_producing,
        exclude_gp_from_commission: formData.exclude_gp_from_commission
      };

      if (editingDeal) {
        await dealsAPI.update(editingDeal.id, dealData);
        toast({
          title: "Success",
          description: "Deal updated successfully"
        });
      } else {
        await dealsAPI.create(dealData);
        toast({
          title: "Success",
          description: "Deal created successfully"
        });
      }

      await fetchDeals();
      handleCloseDialog();
    } catch (error: any) {
      console.error('Error saving deal:', error);
      // Error toast is already handled by the http wrapper
    }
  };

  const handleEdit = (deal: Deal) => {
    setEditingDeal(deal);
    setFormData({
      fund_id: deal.fund_id?.toString() || '',
      name: deal.name,
      address: deal.address || '',
      status: deal.status || 'Active',
      close_date: deal.close_date ? new Date(deal.close_date) : undefined,
      sector: deal.sector || '',
      year_built: deal.year_built?.toString() || '',
      units: deal.units?.toString() || '',
      sqft: deal.sqft?.toString() || '',
      income_producing: deal.income_producing || false,
      exclude_gp_from_commission: deal.exclude_gp_from_commission || false
    });
    setIsDialogOpen(true);
  };

  const handleDelete = async (deal: Deal) => {
    try {
      const { error } = await supabase
        .from('deals')
        .delete()
        .eq('id', deal.id);

      if (error) throw error;
      
      toast({
        title: "Success",
        description: "Deal deleted successfully"
      });
      
      await fetchDeals();
    } catch (error) {
      console.error('Error deleting deal:', error);
      toast({
        title: "Error",
        description: "Failed to delete deal. It may be referenced by distributions or agreements.",
        variant: "destructive"
      });
    }
  };

  const handleCloseDialog = () => {
    setIsDialogOpen(false);
    setEditingDeal(null);
    setFormData(initialFormData);
  };

  const filteredDeals = deals.filter(deal =>
    deal.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    (deal.address && deal.address.toLowerCase().includes(searchQuery.toLowerCase()))
  );

  if (loading) {
    return (
      <div className="max-w-7xl mx-auto px-4 py-6">
        <div className="flex items-center justify-center h-64">
          <div className="text-center">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto"></div>
            <p className="mt-2 text-muted-foreground">Loading deals...</p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-7xl mx-auto px-4 py-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Button variant="ghost" size="sm" onClick={() => navigate('/')}>
            <ArrowLeft className="w-4 h-4 mr-2" />
            Back
          </Button>
          <div>
            <h1 className="text-3xl font-bold flex items-center gap-2">
              <Target className="w-8 h-8 text-primary" />
              Deals
            </h1>
            <p className="text-muted-foreground mt-1">
              Manage deal-level fee configurations
            </p>
          </div>
        </div>
        
        <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
          <DialogTrigger asChild>
            <Button onClick={() => setFormData(initialFormData)}>
              <Plus className="w-4 h-4 mr-2" />
              New Deal
            </Button>
          </DialogTrigger>
          <DialogContent className="sm:max-w-lg">
            <DialogHeader>
              <DialogTitle>
                {editingDeal ? 'Edit Deal' : 'Create New Deal'}
              </DialogTitle>
              <DialogDescription>
                {editingDeal ? 'Update' : 'Add a new'} deal to enable deal-scoped fee calculations
              </DialogDescription>
            </DialogHeader>
            
            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <Label htmlFor="name">Deal Name *</Label>
                <Input
                  id="name"
                  value={formData.name}
                  onChange={(e) => handleInputChange('name', e.target.value)}
                  placeholder="e.g., Project Alpha Series B"
                  required
                />
              </div>

              <div>
                <Label htmlFor="address">Address</Label>
                <Input
                  id="address"
                  value={formData.address}
                  onChange={(e) => handleInputChange('address', e.target.value)}
                  placeholder="e.g., 123 Main St, City, State"
                />
              </div>

              <div>
                <Label htmlFor="fund_id">Fund ID (Optional)</Label>
                <Input
                  id="fund_id"
                  type="number"
                  value={formData.fund_id}
                  onChange={(e) => handleInputChange('fund_id', e.target.value)}
                  placeholder="Fund identifier"
                />
              </div>

              <div>
                <Label>Close Date</Label>
                <Popover>
                  <PopoverTrigger asChild>
                    <Button
                      variant="outline"
                      className={cn(
                        "w-full justify-start text-left font-normal",
                        !formData.close_date && "text-muted-foreground"
                      )}
                    >
                      <CalendarIcon className="mr-2 h-4 w-4" />
                      {formData.close_date ? format(formData.close_date, "PPP") : <span>Pick a date</span>}
                    </Button>
                  </PopoverTrigger>
                  <PopoverContent className="w-auto p-0" align="start">
                    <Calendar
                      mode="single"
                      selected={formData.close_date}
                      onSelect={(date) => handleInputChange('close_date', date)}
                      initialFocus
                      className="pointer-events-auto"
                    />
                  </PopoverContent>
                </Popover>
              </div>

              <div className="flex items-center space-x-2 pt-2">
                <Checkbox
                  id="exclude_gp"
                  checked={formData.exclude_gp_from_commission}
                  onCheckedChange={(checked) =>
                    handleInputChange('exclude_gp_from_commission', checked)
                  }
                />
                <Label
                  htmlFor="exclude_gp"
                  className="text-sm font-normal cursor-pointer"
                >
                  Exclude GP investors from commission calculations
                </Label>
              </div>

              {editingDeal && (editingDeal.equity_to_raise || editingDeal.raised_so_far) && (
                <Alert>
                  <Info className="h-4 w-4" />
                  <AlertDescription className="text-xs">
                    <strong>Equity to Raise:</strong>{' '}
                    {editingDeal.equity_to_raise
                      ? new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', minimumFractionDigits: 0 }).format(editingDeal.equity_to_raise)
                      : 'N/A'}
                    {' | '}
                    <strong>Raised So Far:</strong>{' '}
                    {editingDeal.raised_so_far
                      ? new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', minimumFractionDigits: 0 }).format(editingDeal.raised_so_far)
                      : 'N/A'}
                    <br />
                    <span className="text-muted-foreground italic">
                      These amounts are sourced from Scoreboard imports and cannot be edited here.
                    </span>
                  </AlertDescription>
                </Alert>
              )}

              <div className="flex justify-end gap-2 pt-4">
                <Button type="button" variant="outline" onClick={handleCloseDialog}>
                  Cancel
                </Button>
                <Button type="submit">
                  {editingDeal ? 'Update' : 'Create'} Deal
                </Button>
              </div>
            </form>
          </DialogContent>
        </Dialog>
      </div>

      {/* Summary Card */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <div>
            <CardTitle className="text-sm font-medium">Total Deals</CardTitle>
            <CardDescription>Real estate investments and projects</CardDescription>
          </div>
          <Target className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">{deals.length}</div>
          <p className="text-xs text-muted-foreground">
            {deals.filter(d => d.status === 'ACTIVE' || d.status === 'Active').length} active
          </p>
        </CardContent>
      </Card>

      {/* Search */}
      <div className="flex gap-2">
        <Input
          placeholder="Search by name or address..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="max-w-sm"
        />
      </div>

      {/* Deals Table */}
      <Card>
        <CardHeader>
          <CardTitle>All Deals</CardTitle>
          <CardDescription>
            Manage deals for deal-scoped fee calculations
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Name</TableHead>
                <TableHead>Close Date</TableHead>
                <TableHead>Status</TableHead>
                <TableHead className="text-right">
                  <div>Equity to Raise</div>
                  <div className="text-xs font-normal text-muted-foreground">Source: Scoreboard</div>
                </TableHead>
                <TableHead className="text-right">
                  <div>Raised So Far</div>
                  <div className="text-xs font-normal text-muted-foreground">Source: Scoreboard</div>
                </TableHead>
                <TableHead>GP Excluded</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredDeals.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={7} className="text-center text-muted-foreground py-8">
                    No deals found. Create your first deal to get started.
                  </TableCell>
                </TableRow>
              ) : (
                filteredDeals.map((deal) => (
                  <TableRow key={deal.id}>
                    <TableCell>
                      <div className="font-medium">{deal.name}</div>
                      {deal.address && (
                        <div className="text-xs text-muted-foreground">
                          {deal.address}
                        </div>
                      )}
                      {deal.fund_id && (
                        <div className="text-xs text-muted-foreground">
                          Fund ID: {deal.fund_id}
                        </div>
                      )}
                    </TableCell>
                    <TableCell>
                      {deal.close_date
                        ? format(new Date(deal.close_date), 'MMM d, yyyy')
                        : <span className="text-muted-foreground">—</span>
                      }
                    </TableCell>
                    <TableCell>
                      <Badge variant={deal.status === 'ACTIVE' || deal.status === 'Active' ? 'default' : 'secondary'}>
                        {deal.status || 'Active'}
                      </Badge>
                    </TableCell>
                    <TableCell className="text-right font-mono text-sm">
                      {deal.equity_to_raise !== null && deal.equity_to_raise !== undefined ? (
                        <span className="flex items-center justify-end gap-1">
                          <TrendingUp className="w-3 h-3 text-muted-foreground" />
                          {new Intl.NumberFormat('en-US', {
                            style: 'currency',
                            currency: 'USD',
                            minimumFractionDigits: 0,
                            maximumFractionDigits: 0
                          }).format(deal.equity_to_raise)}
                        </span>
                      ) : (
                        <span className="text-muted-foreground">—</span>
                      )}
                    </TableCell>
                    <TableCell className="text-right font-mono text-sm">
                      {deal.raised_so_far !== null && deal.raised_so_far !== undefined ? (
                        <span className="flex items-center justify-end gap-1">
                          <TrendingUp className="w-3 h-3 text-green-500" />
                          {new Intl.NumberFormat('en-US', {
                            style: 'currency',
                            currency: 'USD',
                            minimumFractionDigits: 0,
                            maximumFractionDigits: 0
                          }).format(deal.raised_so_far)}
                        </span>
                      ) : (
                        <span className="text-muted-foreground">—</span>
                      )}
                    </TableCell>
                    <TableCell>
                      {deal.exclude_gp_from_commission ? (
                        <Badge variant="outline" className="text-xs">
                          Excluded
                        </Badge>
                      ) : (
                        <span className="text-muted-foreground text-xs">Included</span>
                      )}
                    </TableCell>
                    <TableCell className="text-right">
                      <div className="flex justify-end gap-2">
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => handleEdit(deal)}
                        >
                          <Edit className="w-4 h-4" />
                        </Button>
                        <AlertDialog>
                          <AlertDialogTrigger asChild>
                            <Button variant="ghost" size="sm">
                              <Trash2 className="w-4 h-4 text-destructive" />
                            </Button>
                          </AlertDialogTrigger>
                          <AlertDialogContent>
                            <AlertDialogHeader>
                              <AlertDialogTitle>Delete Deal</AlertDialogTitle>
                              <AlertDialogDescription>
                                Are you sure you want to delete "{deal.name}"? This action cannot be undone.
                                Any distributions or agreements linked to this deal may be affected.
                              </AlertDialogDescription>
                            </AlertDialogHeader>
                            <AlertDialogFooter>
                              <AlertDialogCancel>Cancel</AlertDialogCancel>
                              <AlertDialogAction
                                onClick={() => handleDelete(deal)}
                                className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
                              >
                                Delete
                              </AlertDialogAction>
                            </AlertDialogFooter>
                          </AlertDialogContent>
                        </AlertDialog>
                      </div>
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}
