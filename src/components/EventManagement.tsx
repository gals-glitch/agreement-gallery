import React, { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Badge } from '@/components/ui/badge';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from '@/components/ui/alert-dialog';
import { Calendar, DollarSign, Plus, Edit, Trash2, TrendingUp, Building2 } from 'lucide-react';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from '@/hooks/use-toast';

interface RealizedPromoteEvent {
  id: string;
  deal: string;
  realized_date: string;
  realized_amount: number;
  currency: string;
  source: string;
  created_at: string;
  notes?: string;
}

interface MFBaseEvent {
  id: string;
  year: number;
  fund: string;
  investor_id: string;
  investor_name: string;
  invested_live_amount: number;
  mf_pool_year: number;
  created_at: string;
}

interface RealizedPromoteFormData {
  deal: string;
  realized_date: string;
  realized_amount: string;
  currency: string;
  source: string;
  notes: string;
}

interface MFBaseFormData {
  year: string;
  fund: string;
  investor_id: string;
  investor_name: string;
  invested_live_amount: string;
  mf_pool_year: string;
}

const initialRealizedPromoteForm: RealizedPromoteFormData = {
  deal: '',
  realized_date: '',
  realized_amount: '',
  currency: 'USD',
  source: '',
  notes: ''
};

const initialMFBaseForm: MFBaseFormData = {
  year: new Date().getFullYear().toString(),
  fund: '',
  investor_id: '',
  investor_name: '',
  invested_live_amount: '',
  mf_pool_year: ''
};

export default function EventManagement() {
  const [realizedPromoteEvents, setRealizedPromoteEvents] = useState<RealizedPromoteEvent[]>([]);
  const [mfBaseEvents, setMFBaseEvents] = useState<MFBaseEvent[]>([]);
  const [loading, setLoading] = useState(true);
  const [realizedPromoteForm, setRealizedPromoteForm] = useState<RealizedPromoteFormData>(initialRealizedPromoteForm);
  const [mfBaseForm, setMFBaseForm] = useState<MFBaseFormData>(initialMFBaseForm);
  const [editingRealizedPromote, setEditingRealizedPromote] = useState<RealizedPromoteEvent | null>(null);
  const [editingMFBase, setEditingMFBase] = useState<MFBaseEvent | null>(null);
  const [isRealizedPromoteDialogOpen, setIsRealizedPromoteDialogOpen] = useState(false);
  const [isMFBaseDialogOpen, setIsMFBaseDialogOpen] = useState(false);
  const [activeTab, setActiveTab] = useState('realized-promote');
  
  const { toast } = useToast();

  useEffect(() => {
    fetchEvents();
  }, []);

  const fetchEvents = async () => {
    try {
      // Note: These tables don't exist yet in the schema, so we'll simulate the data structure
      // In a real implementation, these would be actual database calls
      
      // For now, we'll use empty arrays and show the UI structure
      setRealizedPromoteEvents([]);
      setMFBaseEvents([]);
      
    } catch (error) {
      console.error('Error fetching events:', error);
      toast({
        title: "Error",
        description: "Failed to load events",
        variant: "destructive"
      });
    } finally {
      setLoading(false);
    }
  };

  const handleRealizedPromoteSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!realizedPromoteForm.deal.trim() || !realizedPromoteForm.realized_date || !realizedPromoteForm.realized_amount) {
      toast({
        title: "Validation Error",
        description: "Deal, realized date, and amount are required",
        variant: "destructive"
      });
      return;
    }

    const amount = parseFloat(realizedPromoteForm.realized_amount);
    if (amount <= 0) {
      toast({
        title: "Validation Error",
        description: "Amount must be greater than 0",
        variant: "destructive"
      });
      return;
    }

    try {
      // This would be a real database insert in production
      const eventData = {
        deal: realizedPromoteForm.deal.trim(),
        realized_date: realizedPromoteForm.realized_date,
        realized_amount: amount,
        currency: realizedPromoteForm.currency,
        source: realizedPromoteForm.source.trim() || 'Manual Entry',
        notes: realizedPromoteForm.notes || null
      };

      // Simulate successful creation
      const newEvent: RealizedPromoteEvent = {
        id: Math.random().toString(36).substr(2, 9),
        ...eventData,
        created_at: new Date().toISOString()
      };

      setRealizedPromoteEvents(prev => [newEvent, ...prev]);
      
      toast({
        title: "Success",
        description: "Realized promote event created successfully"
      });

      setRealizedPromoteForm(initialRealizedPromoteForm);
      setIsRealizedPromoteDialogOpen(false);
    } catch (error: any) {
      console.error('Error saving realized promote event:', error);
      toast({
        title: "Error",
        description: "Failed to save realized promote event",
        variant: "destructive"
      });
    }
  };

  const handleMFBaseSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!mfBaseForm.fund.trim() || !mfBaseForm.investor_name.trim() || !mfBaseForm.invested_live_amount || !mfBaseForm.mf_pool_year) {
      toast({
        title: "Validation Error",
        description: "All fields are required",
        variant: "destructive"
      });
      return;
    }

    const investedAmount = parseFloat(mfBaseForm.invested_live_amount);
    const poolAmount = parseFloat(mfBaseForm.mf_pool_year);
    
    if (investedAmount <= 0 || poolAmount <= 0) {
      toast({
        title: "Validation Error",
        description: "Amounts must be greater than 0",
        variant: "destructive"
      });
      return;
    }

    try {
      // This would be a real database insert in production
      const eventData = {
        year: parseInt(mfBaseForm.year),
        fund: mfBaseForm.fund.trim(),
        investor_id: mfBaseForm.investor_id.trim() || Math.random().toString(36).substr(2, 9),
        investor_name: mfBaseForm.investor_name.trim(),
        invested_live_amount: investedAmount,
        mf_pool_year: poolAmount
      };

      // Simulate successful creation
      const newEvent: MFBaseEvent = {
        id: Math.random().toString(36).substr(2, 9),
        ...eventData,
        created_at: new Date().toISOString()
      };

      setMFBaseEvents(prev => [newEvent, ...prev]);
      
      toast({
        title: "Success",
        description: "Management fee base event created successfully"
      });

      setMFBaseForm(initialMFBaseForm);
      setIsMFBaseDialogOpen(false);
    } catch (error: any) {
      console.error('Error saving MF base event:', error);
      toast({
        title: "Error",
        description: "Failed to save management fee base event",
        variant: "destructive"
      });
    }
  };

  const handleDeleteRealizedPromote = async (eventId: string) => {
    try {
      // This would be a real database delete in production
      setRealizedPromoteEvents(prev => prev.filter(e => e.id !== eventId));
      
      toast({
        title: "Success",
        description: "Realized promote event deleted successfully"
      });
    } catch (error) {
      console.error('Error deleting realized promote event:', error);
      toast({
        title: "Error",
        description: "Failed to delete realized promote event",
        variant: "destructive"
      });
    }
  };

  const handleDeleteMFBase = async (eventId: string) => {
    try {
      // This would be a real database delete in production
      setMFBaseEvents(prev => prev.filter(e => e.id !== eventId));
      
      toast({
        title: "Success",
        description: "Management fee base event deleted successfully"
      });
    } catch (error) {
      console.error('Error deleting MF base event:', error);
      toast({
        title: "Error",
        description: "Failed to delete management fee base event",
        variant: "destructive"
      });
    }
  };

  const getTotalRealizedAmount = () => {
    return realizedPromoteEvents.reduce((sum, event) => sum + event.realized_amount, 0);
  };

  const getTotalMFPool = () => {
    const uniqueYearFunds = new Map();
    mfBaseEvents.forEach(event => {
      const key = `${event.year}-${event.fund}`;
      if (!uniqueYearFunds.has(key) || uniqueYearFunds.get(key) < event.mf_pool_year) {
        uniqueYearFunds.set(key, event.mf_pool_year);
      }
    });
    return Array.from(uniqueYearFunds.values()).reduce((sum, amount) => sum + amount, 0);
  };

  if (loading) {
    return (
      <div className="max-w-7xl mx-auto px-4 py-6">
        <div className="flex items-center justify-center h-64">
          <div className="text-center">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto"></div>
            <p className="mt-2 text-muted-foreground">Loading events...</p>
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
          <h1 className="text-3xl font-bold">Event Management</h1>
          <p className="text-muted-foreground">
            Manage realized promote and management fee base events
          </p>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Realized Events</CardTitle>
            <TrendingUp className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{realizedPromoteEvents.length}</div>
            <p className="text-xs text-muted-foreground">
              Total promote events
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Realized</CardTitle>
            <DollarSign className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              ${getTotalRealizedAmount().toLocaleString()}
            </div>
            <p className="text-xs text-muted-foreground">
              Across all deals
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">MF Base Events</CardTitle>
            <Building2 className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{mfBaseEvents.length}</div>
            <p className="text-xs text-muted-foreground">
              Management fee records
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total MF Pool</CardTitle>
            <DollarSign className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              ${getTotalMFPool().toLocaleString()}
            </div>
            <p className="text-xs text-muted-foreground">
              All funds combined
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Event Management Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-4">
        <TabsList>
          <TabsTrigger value="realized-promote">Realized Promote</TabsTrigger>
          <TabsTrigger value="mf-base">Management Fee Base</TabsTrigger>
        </TabsList>

        <TabsContent value="realized-promote">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle>Realized Promote Events</CardTitle>
                  <CardDescription>
                    Track deal realizations and promote distributions
                  </CardDescription>
                </div>
                <Dialog open={isRealizedPromoteDialogOpen} onOpenChange={setIsRealizedPromoteDialogOpen}>
                  <DialogTrigger asChild>
                    <Button>
                      <Plus className="w-4 h-4 mr-2" />
                      Add Realized Event
                    </Button>
                  </DialogTrigger>
                  <DialogContent className="sm:max-w-2xl">
                    <DialogHeader>
                      <DialogTitle>Add Realized Promote Event</DialogTitle>
                      <DialogDescription>
                        Record a new deal realization event
                      </DialogDescription>
                    </DialogHeader>
                    
                    <form onSubmit={handleRealizedPromoteSubmit} className="space-y-4">
                      <div className="grid grid-cols-2 gap-4">
                        <div>
                          <Label htmlFor="deal">Deal Name *</Label>
                          <Input
                            id="deal"
                            value={realizedPromoteForm.deal}
                            onChange={(e) => setRealizedPromoteForm(prev => ({ ...prev, deal: e.target.value }))}
                            placeholder="Deal name"
                            required
                          />
                        </div>
                        
                        <div>
                          <Label htmlFor="realized_date">Realized Date *</Label>
                          <Input
                            id="realized_date"
                            type="date"
                            value={realizedPromoteForm.realized_date}
                            onChange={(e) => setRealizedPromoteForm(prev => ({ ...prev, realized_date: e.target.value }))}
                            required
                          />
                        </div>
                      </div>

                      <div className="grid grid-cols-2 gap-4">
                        <div>
                          <Label htmlFor="realized_amount">Realized Amount *</Label>
                          <Input
                            id="realized_amount"
                            type="number"
                            step="0.01"
                            min="0"
                            value={realizedPromoteForm.realized_amount}
                            onChange={(e) => setRealizedPromoteForm(prev => ({ ...prev, realized_amount: e.target.value }))}
                            placeholder="1000000.00"
                            required
                          />
                        </div>
                        
                        <div>
                          <Label htmlFor="currency">Currency</Label>
                          <Select
                            value={realizedPromoteForm.currency}
                            onValueChange={(value) => setRealizedPromoteForm(prev => ({ ...prev, currency: value }))}
                          >
                            <SelectTrigger>
                              <SelectValue />
                            </SelectTrigger>
                            <SelectContent>
                              <SelectItem value="USD">USD</SelectItem>
                              <SelectItem value="EUR">EUR</SelectItem>
                              <SelectItem value="GBP">GBP</SelectItem>
                              <SelectItem value="ILS">ILS</SelectItem>
                            </SelectContent>
                          </Select>
                        </div>
                      </div>

                      <div>
                        <Label htmlFor="source">Source</Label>
                        <Input
                          id="source"
                          value={realizedPromoteForm.source}
                          onChange={(e) => setRealizedPromoteForm(prev => ({ ...prev, source: e.target.value }))}
                          placeholder="Source documentation or reference"
                        />
                      </div>

                      <div>
                        <Label htmlFor="notes">Notes</Label>
                        <Input
                          id="notes"
                          value={realizedPromoteForm.notes}
                          onChange={(e) => setRealizedPromoteForm(prev => ({ ...prev, notes: e.target.value }))}
                          placeholder="Additional notes..."
                        />
                      </div>

                      <div className="flex justify-end gap-2 pt-4">
                        <Button type="button" variant="outline" onClick={() => setIsRealizedPromoteDialogOpen(false)}>
                          Cancel
                        </Button>
                        <Button type="submit">
                          Create Event
                        </Button>
                      </div>
                    </form>
                  </DialogContent>
                </Dialog>
              </div>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Deal</TableHead>
                    <TableHead>Realized Date</TableHead>
                    <TableHead>Amount</TableHead>
                    <TableHead>Currency</TableHead>
                    <TableHead>Source</TableHead>
                    <TableHead>Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {realizedPromoteEvents.map((event) => (
                    <TableRow key={event.id}>
                      <TableCell className="font-medium">{event.deal}</TableCell>
                      <TableCell>
                        {new Date(event.realized_date).toLocaleDateString()}
                      </TableCell>
                      <TableCell className="font-medium">
                        {event.realized_amount.toLocaleString()}
                      </TableCell>
                      <TableCell>
                        <Badge variant="outline">{event.currency}</Badge>
                      </TableCell>
                      <TableCell>{event.source}</TableCell>
                      <TableCell>
                        <div className="flex gap-2">
                          <Button size="sm" variant="outline">
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
                                <AlertDialogTitle>Delete Event</AlertDialogTitle>
                                <AlertDialogDescription>
                                  Are you sure you want to delete this realized promote event? This action cannot be undone.
                                </AlertDialogDescription>
                              </AlertDialogHeader>
                              <AlertDialogFooter>
                                <AlertDialogCancel>Cancel</AlertDialogCancel>
                                <AlertDialogAction onClick={() => handleDeleteRealizedPromote(event.id)}>
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
              {realizedPromoteEvents.length === 0 && (
                <div className="text-center text-muted-foreground py-8">
                  No realized promote events recorded
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="mf-base">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle>Management Fee Base</CardTitle>
                  <CardDescription>
                    Track investor live capital for management fee calculations
                  </CardDescription>
                </div>
                <Dialog open={isMFBaseDialogOpen} onOpenChange={setIsMFBaseDialogOpen}>
                  <DialogTrigger asChild>
                    <Button>
                      <Plus className="w-4 h-4 mr-2" />
                      Add MF Base
                    </Button>
                  </DialogTrigger>
                  <DialogContent className="sm:max-w-2xl">
                    <DialogHeader>
                      <DialogTitle>Add Management Fee Base</DialogTitle>
                      <DialogDescription>
                        Record investor live capital for management fee calculations
                      </DialogDescription>
                    </DialogHeader>
                    
                    <form onSubmit={handleMFBaseSubmit} className="space-y-4">
                      <div className="grid grid-cols-2 gap-4">
                        <div>
                          <Label htmlFor="year">Year *</Label>
                          <Input
                            id="year"
                            type="number"
                            min="2000"
                            max="2100"
                            value={mfBaseForm.year}
                            onChange={(e) => setMFBaseForm(prev => ({ ...prev, year: e.target.value }))}
                            required
                          />
                        </div>
                        
                        <div>
                          <Label htmlFor="fund">Fund *</Label>
                          <Input
                            id="fund"
                            value={mfBaseForm.fund}
                            onChange={(e) => setMFBaseForm(prev => ({ ...prev, fund: e.target.value }))}
                            placeholder="Fund VI"
                            required
                          />
                        </div>
                      </div>

                      <div className="grid grid-cols-2 gap-4">
                        <div>
                          <Label htmlFor="investor_id">Investor ID</Label>
                          <Input
                            id="investor_id"
                            value={mfBaseForm.investor_id}
                            onChange={(e) => setMFBaseForm(prev => ({ ...prev, investor_id: e.target.value }))}
                            placeholder="Auto-generated if empty"
                          />
                        </div>
                        
                        <div>
                          <Label htmlFor="investor_name">Investor Name *</Label>
                          <Input
                            id="investor_name"
                            value={mfBaseForm.investor_name}
                            onChange={(e) => setMFBaseForm(prev => ({ ...prev, investor_name: e.target.value }))}
                            placeholder="Investor name"
                            required
                          />
                        </div>
                      </div>

                      <div className="grid grid-cols-2 gap-4">
                        <div>
                          <Label htmlFor="invested_live_amount">Invested Live Amount *</Label>
                          <Input
                            id="invested_live_amount"
                            type="number"
                            step="0.01"
                            min="0"
                            value={mfBaseForm.invested_live_amount}
                            onChange={(e) => setMFBaseForm(prev => ({ ...prev, invested_live_amount: e.target.value }))}
                            placeholder="5000000.00"
                            required
                          />
                        </div>
                        
                        <div>
                          <Label htmlFor="mf_pool_year">MF Pool Year *</Label>
                          <Input
                            id="mf_pool_year"
                            type="number"
                            step="0.01"
                            min="0"
                            value={mfBaseForm.mf_pool_year}
                            onChange={(e) => setMFBaseForm(prev => ({ ...prev, mf_pool_year: e.target.value }))}
                            placeholder="10000000.00"
                            required
                          />
                        </div>
                      </div>

                      <div className="flex justify-end gap-2 pt-4">
                        <Button type="button" variant="outline" onClick={() => setIsMFBaseDialogOpen(false)}>
                          Cancel
                        </Button>
                        <Button type="submit">
                          Create Record
                        </Button>
                      </div>
                    </form>
                  </DialogContent>
                </Dialog>
              </div>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Year</TableHead>
                    <TableHead>Fund</TableHead>
                    <TableHead>Investor</TableHead>
                    <TableHead>Live Amount</TableHead>
                    <TableHead>MF Pool</TableHead>
                    <TableHead>Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {mfBaseEvents.map((event) => (
                    <TableRow key={event.id}>
                      <TableCell className="font-medium">{event.year}</TableCell>
                      <TableCell>{event.fund}</TableCell>
                      <TableCell>{event.investor_name}</TableCell>
                      <TableCell className="font-medium">
                        ${event.invested_live_amount.toLocaleString()}
                      </TableCell>
                      <TableCell className="font-medium">
                        ${event.mf_pool_year.toLocaleString()}
                      </TableCell>
                      <TableCell>
                        <div className="flex gap-2">
                          <Button size="sm" variant="outline">
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
                                <AlertDialogTitle>Delete Record</AlertDialogTitle>
                                <AlertDialogDescription>
                                  Are you sure you want to delete this management fee base record? This action cannot be undone.
                                </AlertDialogDescription>
                              </AlertDialogHeader>
                              <AlertDialogFooter>
                                <AlertDialogCancel>Cancel</AlertDialogCancel>
                                <AlertDialogAction onClick={() => handleDeleteMFBase(event.id)}>
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
              {mfBaseEvents.length === 0 && (
                <div className="text-center text-muted-foreground py-8">
                  No management fee base records
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}