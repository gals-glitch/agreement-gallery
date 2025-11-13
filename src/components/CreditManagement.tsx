import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Separator } from '@/components/ui/separator';
import { Calendar } from '@/components/ui/calendar';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { CalendarIcon, Plus, CreditCard, TrendingDown, TrendingUp, DollarSign } from 'lucide-react';
import { format } from 'date-fns';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from '@/hooks/use-toast';

interface Credit {
  id: string;
  investor_id: string;
  investor_name: string;
  fund_name: string | null;
  credit_type: 'repurchase' | 'equalisation';
  amount: number;
  remaining_balance: number;
  currency: string;
  date_posted: string;
  status: 'active' | 'exhausted' | 'cancelled';
  apply_policy: string;
  notes: string | null;
  created_at: string;
}

interface CreditApplication {
  id: string;
  credit_id: string;
  calculation_run_id: string | null;
  distribution_id: string | null;
  applied_amount: number;
  applied_date: string;
  notes: string | null;
}

export function CreditManagement() {
  const [credits, setCredits] = useState<Credit[]>([]);
  const [applications, setApplications] = useState<CreditApplication[]>([]);
  const [loading, setLoading] = useState(true);
  const [showNewCreditDialog, setShowNewCreditDialog] = useState(false);
  const [newCredit, setNewCredit] = useState({
    investor_name: '',
    fund_name: '',
    credit_type: 'repurchase' as 'repurchase' | 'equalisation',
    amount: '',
    currency: 'USD',
    date_posted: new Date(),
    notes: ''
  });
  
  const { toast } = useToast();

  useEffect(() => {
    fetchCredits();
    fetchApplications();
  }, []);

  const fetchCredits = async () => {
    try {
      const { data, error } = await supabase
        .from('credits')
        .select('*')
        .order('date_posted', { ascending: false });

      if (error) throw error;
      setCredits((data || []) as Credit[]);
    } catch (error) {
      console.error('Error fetching credits:', error);
      toast({
        title: "Error",
        description: "Failed to fetch credits",
        variant: "destructive"
      });
    } finally {
      setLoading(false);
    }
  };

  const fetchApplications = async () => {
    try {
      const { data, error } = await supabase
        .from('credit_applications')
        .select('*')
        .order('applied_date', { ascending: false });

      if (error) throw error;
      setApplications(data || []);
    } catch (error) {
      console.error('Error fetching credit applications:', error);
    }
  };

  const handleCreateCredit = async () => {
    if (!newCredit.investor_name || !newCredit.amount) {
      toast({
        title: "Validation Error",
        description: "Investor name and amount are required",
        variant: "destructive"
      });
      return;
    }

    try {
      const amount = parseFloat(newCredit.amount);
      const creditData = {
        investor_id: crypto.randomUUID(), // In real app, would lookup actual investor ID
        investor_name: newCredit.investor_name,
        fund_name: newCredit.fund_name || null,
        credit_type: newCredit.credit_type,
        amount,
        remaining_balance: amount,
        currency: newCredit.currency,
        date_posted: format(newCredit.date_posted, 'yyyy-MM-dd'),
        notes: newCredit.notes || null
      };

      const { error } = await supabase
        .from('credits')
        .insert([creditData]);

      if (error) throw error;

      toast({
        title: "Success",
        description: "Credit created successfully"
      });

      setShowNewCreditDialog(false);
      setNewCredit({
        investor_name: '',
        fund_name: '',
        credit_type: 'repurchase',
        amount: '',
        currency: 'USD',
        date_posted: new Date(),
        notes: ''
      });
      fetchCredits();
    } catch (error) {
      console.error('Error creating credit:', error);
      toast({
        title: "Error",
        description: "Failed to create credit",
        variant: "destructive"
      });
    }
  };

  const getCreditsStatistics = () => {
    const totalRepurchaseCredits = credits
      .filter(c => c.credit_type === 'repurchase' && c.status === 'active')
      .reduce((sum, c) => sum + c.remaining_balance, 0);
    
    const totalEqualisationCredits = credits
      .filter(c => c.credit_type === 'equalisation' && c.status === 'active')
      .reduce((sum, c) => sum + c.remaining_balance, 0);
    
    const totalApplied = applications
      .reduce((sum, a) => sum + a.applied_amount, 0);

    return {
      totalRepurchaseCredits,
      totalEqualisationCredits,
      totalActiveCredits: totalRepurchaseCredits + totalEqualisationCredits,
      totalApplied,
      activeCreditsCount: credits.filter(c => c.status === 'active').length
    };
  };

  const stats = getCreditsStatistics();

  if (loading) {
    return <div>Loading...</div>;
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">Credit Management</h1>
          <p className="text-muted-foreground">
            Manage repurchase and equalisation credits per PRD requirements
          </p>
        </div>
        <Dialog open={showNewCreditDialog} onOpenChange={setShowNewCreditDialog}>
          <DialogTrigger asChild>
            <Button className="gap-2">
              <Plus className="w-4 h-4" />
              Post New Credit
            </Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Post New Credit</DialogTitle>
              <DialogDescription>
                Create a new repurchase or equalisation credit
              </DialogDescription>
            </DialogHeader>
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label htmlFor="investor_name">Investor Name</Label>
                  <Input
                    id="investor_name"
                    value={newCredit.investor_name}
                    onChange={(e) => setNewCredit({ ...newCredit, investor_name: e.target.value })}
                    placeholder="Enter investor name"
                  />
                </div>
                <div>
                  <Label htmlFor="fund_name">Fund Name</Label>
                  <Input
                    id="fund_name"
                    value={newCredit.fund_name}
                    onChange={(e) => setNewCredit({ ...newCredit, fund_name: e.target.value })}
                    placeholder="Enter fund name"
                  />
                </div>
              </div>
              
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label htmlFor="credit_type">Credit Type</Label>
                  <Select
                    value={newCredit.credit_type}
                    onValueChange={(value: 'repurchase' | 'equalisation') => 
                      setNewCredit({ ...newCredit, credit_type: value })
                    }
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="repurchase">Repurchase Credit</SelectItem>
                      <SelectItem value="equalisation">Equalisation Interest</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div>
                  <Label htmlFor="amount">Amount</Label>
                  <Input
                    id="amount"
                    type="number"
                    step="0.01"
                    value={newCredit.amount}
                    onChange={(e) => setNewCredit({ ...newCredit, amount: e.target.value })}
                    placeholder="0.00"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label htmlFor="currency">Currency</Label>
                  <Select
                    value={newCredit.currency}
                    onValueChange={(value) => setNewCredit({ ...newCredit, currency: value })}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="USD">USD</SelectItem>
                      <SelectItem value="EUR">EUR</SelectItem>
                      <SelectItem value="GBP">GBP</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div>
                  <Label>Date Posted</Label>
                  <Popover>
                    <PopoverTrigger asChild>
                      <Button variant="outline" className="w-full justify-start text-left font-normal">
                        <CalendarIcon className="mr-2 h-4 w-4" />
                        {format(newCredit.date_posted, "PPP")}
                      </Button>
                    </PopoverTrigger>
                    <PopoverContent className="w-auto p-0">
                      <Calendar
                        mode="single"
                        selected={newCredit.date_posted}
                        onSelect={(date) => date && setNewCredit({ ...newCredit, date_posted: date })}
                        initialFocus
                      />
                    </PopoverContent>
                  </Popover>
                </div>
              </div>

              <div>
                <Label htmlFor="notes">Notes</Label>
                <Textarea
                  id="notes"
                  value={newCredit.notes}
                  onChange={(e) => setNewCredit({ ...newCredit, notes: e.target.value })}
                  placeholder="Additional notes or context"
                />
              </div>

              <div className="flex gap-2 justify-end">
                <Button variant="outline" onClick={() => setShowNewCreditDialog(false)}>
                  Cancel
                </Button>
                <Button onClick={handleCreateCredit}>
                  Create Credit
                </Button>
              </div>
            </div>
          </DialogContent>
        </Dialog>
      </div>

      {/* Statistics Cards */}
      <div className="grid grid-cols-4 gap-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Active Credits</CardTitle>
            <DollarSign className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(stats.totalActiveCredits)}
            </div>
            <p className="text-xs text-muted-foreground">
              {stats.activeCreditsCount} active credits
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Repurchase Credits</CardTitle>
            <TrendingDown className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(stats.totalRepurchaseCredits)}
            </div>
            <p className="text-xs text-muted-foreground">
              Available for netting
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Equalisation Credits</CardTitle>
            <TrendingUp className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(stats.totalEqualisationCredits)}
            </div>
            <p className="text-xs text-muted-foreground">
              Interest adjustments
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Applied</CardTitle>
            <CreditCard className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(stats.totalApplied)}
            </div>
            <p className="text-xs text-muted-foreground">
              Already netted
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Credits List */}
      <Card>
        <CardHeader>
          <CardTitle>Active Credits</CardTitle>
        </CardHeader>
        <CardContent>
          <ScrollArea className="h-[400px]">
            <div className="space-y-4">
              {credits.map((credit) => (
                <div key={credit.id} className="border rounded-lg p-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <div className="font-medium">{credit.investor_name}</div>
                      <div className="text-sm text-muted-foreground">
                        {credit.fund_name && `${credit.fund_name} • `}
                        Posted: {format(new Date(credit.date_posted), 'MMM dd, yyyy')}
                      </div>
                    </div>
                    <div className="text-right">
                      <div className="font-medium">
                        {new Intl.NumberFormat('en-US', { 
                          style: 'currency', 
                          currency: credit.currency 
                        }).format(credit.remaining_balance)}
                      </div>
                      <div className="flex gap-2">
                        <Badge 
                          variant={credit.credit_type === 'repurchase' ? 'destructive' : 'secondary'}
                        >
                          {credit.credit_type}
                        </Badge>
                        <Badge 
                          variant={credit.status === 'active' ? 'default' : 'secondary'}
                        >
                          {credit.status}
                        </Badge>
                      </div>
                    </div>
                  </div>
                  {credit.notes && (
                    <div className="mt-2 text-sm text-muted-foreground">
                      {credit.notes}
                    </div>
                  )}
                </div>
              ))}
            </div>
          </ScrollArea>
        </CardContent>
      </Card>
    </div>
  );
}