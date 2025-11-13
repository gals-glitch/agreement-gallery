import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Plus, Edit, Trash2, Users, Building2 } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { useToast } from "@/hooks/use-toast";

interface Investor {
  id: string;
  name: string;
  email?: string;
  phone?: string;
  address?: string;
  tax_id?: string;
  country?: string;
  party_entity_id: string;
  investor_type: string;
  kyc_status: string;
  investment_capacity?: number;
  risk_profile?: string;
  is_active: boolean;
  notes?: string;
  party_entity_name?: string;
}

interface PartyEntity {
  id: string;
  name: string;
  entity_type: string;
}

const InvestorManagement = () => {
  const [investors, setInvestors] = useState<Investor[]>([]);
  const [partyEntities, setPartyEntities] = useState<PartyEntity[]>([]);
  const [loading, setLoading] = useState(true);
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [editingInvestor, setEditingInvestor] = useState<Investor | null>(null);
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    phone: '',
    address: '',
    tax_id: '',
    country: '',
    party_entity_id: '',
    investor_type: 'individual',
    kyc_status: 'pending',
    investment_capacity: '',
    risk_profile: '',
    notes: ''
  });
  const { toast } = useToast();

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      await fetchPartyEntities();
      await fetchInvestors();
    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to fetch data",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const fetchPartyEntities = async () => {
    // Fetch party entities (distributors, referrers, partners)
    const { data: entitiesData, error: entitiesError } = await supabase
      .from('entities')
      .select('id, name, entity_type')
            .order('name');

    if (entitiesError) throw entitiesError;
    setPartyEntities(entitiesData || []);
  };

  const fetchInvestors = async () => {
    // Fetch investors with party entity names
    const { data: investorsData, error: investorsError } = await supabase
      .from('investors')
      .select(`
        *,
        entities:party_entity_id (
          name
        )
      `)
      .order('name');

    if (investorsError) throw investorsError;
    
    const formattedInvestors = investorsData?.map(investor => ({
      ...investor,
      party_entity_name: investor.entities?.name || 'Unknown'
    })) || [];
    
    setInvestors(formattedInvestors);
  };

  const validateForm = () => {
    if (!formData.name.trim()) {
      toast({
        title: "Validation Error",
        description: "Investor name is required",
        variant: "destructive",
      });
      return false;
    }

    if (!formData.party_entity_id) {
      toast({
        title: "Validation Error", 
        description: "Party entity is required - cannot save investor without an introducer",
        variant: "destructive",
      });
      return false;
    }

    return true;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) {
      return;
    }
    
    try {
      const investorData = {
        ...formData,
        investment_capacity: formData.investment_capacity ? Number(formData.investment_capacity) : null,
        is_active: true
      };

      let investorId = editingInvestor?.id;

      if (editingInvestor) {
        const { error } = await supabase
          .from('investors')
          .update(investorData)
          .eq('id', editingInvestor.id);

        if (error) throw error;

        toast({
          title: "Success",
          description: "Investor updated successfully",
        });
      } else {
        const { data, error } = await supabase
          .from('investors')
          .insert([investorData])
          .select('id')
          .single();

        if (error) throw error;
        investorId = data.id;

        toast({
          title: "Success",
          description: "Investor created successfully. Remember to create an agreement link for this investor.",
        });
      }

      setIsDialogOpen(false);
      setEditingInvestor(null);
      resetForm();
      fetchData();
    } catch (error: any) {
      const errorMessage = error.message.includes('introducer') 
        ? error.message 
        : "Failed to save investor";
      
      toast({
        title: "Error",
        description: errorMessage,
        variant: "destructive",
      });
    }
  };

  const handleEdit = (investor: Investor) => {
    setEditingInvestor(investor);
    setFormData({
      name: investor.name,
      email: investor.email || '',
      phone: investor.phone || '',
      address: investor.address || '',
      tax_id: investor.tax_id || '',
      country: investor.country || '',
      party_entity_id: investor.party_entity_id,
      investor_type: investor.investor_type,
      kyc_status: investor.kyc_status,
      investment_capacity: investor.investment_capacity?.toString() || '',
      risk_profile: investor.risk_profile || '',
      notes: investor.notes || ''
    });
    setIsDialogOpen(true);
  };

  const handleDelete = async (investorId: string) => {
    if (!confirm('Are you sure you want to delete this investor?')) return;

    try {
      const { error } = await supabase
        .from('investors')
        .delete()
        .eq('id', investorId);

      if (error) throw error;

      toast({
        title: "Success",
        description: "Investor deleted successfully",
      });
      fetchData();
    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to delete investor",
        variant: "destructive",
      });
    }
  };

  const resetForm = () => {
    setFormData({
      name: '',
      email: '',
      phone: '',
      address: '',
      tax_id: '',
      country: '',
      party_entity_id: '',
      investor_type: 'individual',
      kyc_status: 'pending',
      investment_capacity: '',
      risk_profile: '',
      notes: ''
    });
  };

  const getKycStatusColor = (status: string) => {
    switch (status) {
      case 'approved': return 'default';
      case 'pending': return 'secondary';
      case 'rejected': return 'destructive';
      default: return 'secondary';
    }
  };

  const getInvestorTypeColor = (type: string) => {
    switch (type) {
      case 'individual': return 'default';
      case 'institutional': return 'secondary';
      case 'corporate': return 'outline';
      default: return 'secondary';
    }
  };

  if (loading) {
    return <div className="flex justify-center p-8">Loading...</div>;
  }

  const totalInvestors = investors.length;
  const activeInvestors = investors.filter(i => i.is_active).length;
  const approvedInvestors = investors.filter(i => i.kyc_status === 'approved').length;

  return (
    <div className="space-y-6">
      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Investors</CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{totalInvestors}</div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Active Investors</CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{activeInvestors}</div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">KYC Approved</CardTitle>
            <Building2 className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{approvedInvestors}</div>
          </CardContent>
        </Card>
      </div>

      {/* Main Content */}
      <Card>
        <CardHeader>
          <div className="flex justify-between items-center">
            <div>
              <CardTitle>Investor Management</CardTitle>
              <CardDescription>
                Manage investors and their relationships with party entities
              </CardDescription>
            </div>
            <Dialog open={isDialogOpen} onOpenChange={(open) => {
              setIsDialogOpen(open);
              if (open) {
                fetchPartyEntities(); // Refresh party entities when dialog opens
              }
            }}>
              <DialogTrigger asChild>
                <Button onClick={() => { resetForm(); setEditingInvestor(null); }}>
                  <Plus className="mr-2 h-4 w-4" />
                  Add Investor
                </Button>
              </DialogTrigger>
              <DialogContent className="max-w-2xl max-h-[80vh] overflow-y-auto">
                <DialogHeader>
                  <DialogTitle>
                    {editingInvestor ? 'Edit Investor' : 'Add New Investor'}
                  </DialogTitle>
                  <DialogDescription>
                    {editingInvestor ? 'Update investor information' : 'Create a new investor record'}
                  </DialogDescription>
                </DialogHeader>
                <form onSubmit={handleSubmit} className="space-y-4">
                  <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <Label htmlFor="name">Name *</Label>
                      <Input
                        id="name"
                        value={formData.name}
                        onChange={(e) => setFormData({...formData, name: e.target.value})}
                        required
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="party_entity_id">
                        Party Entity *
                        <span className="text-sm font-normal text-muted-foreground ml-2">
                          (Required - who introduced this investor)
                        </span>
                      </Label>
                      <Select 
                        value={formData.party_entity_id} 
                        onValueChange={(value) => setFormData({...formData, party_entity_id: value})}
                        required
                      >
                        <SelectTrigger>
                          <SelectValue placeholder="Select party entity" />
                        </SelectTrigger>
                        <SelectContent>
                          {partyEntities.map((entity) => (
                            <SelectItem key={entity.id} value={entity.id}>
                              {entity.name} ({entity.entity_type})
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                      {partyEntities.length === 0 && (
                        <div className="text-xs text-muted-foreground flex items-center gap-2">
                          No active parties found. 
                          <Button type="button" size="sm" variant="outline" onClick={() => window.open('/entities', '_blank')}>
                            Create Party
                          </Button>
                        </div>
                      )}
                      <div className="text-xs text-blue-600 bg-blue-50 p-2 rounded">
                        💡 After creating an investor, you'll need to create an agreement link with an introducing party.
                      </div>
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <Label htmlFor="email">Email</Label>
                      <Input
                        id="email"
                        type="email"
                        value={formData.email}
                        onChange={(e) => setFormData({...formData, email: e.target.value})}
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="phone">Phone</Label>
                      <Input
                        id="phone"
                        value={formData.phone}
                        onChange={(e) => setFormData({...formData, phone: e.target.value})}
                      />
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <Label htmlFor="investor_type">Investor Type</Label>
                      <Select 
                        value={formData.investor_type} 
                        onValueChange={(value) => setFormData({...formData, investor_type: value})}
                      >
                        <SelectTrigger>
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="individual">Individual</SelectItem>
                          <SelectItem value="institutional">Institutional</SelectItem>
                          <SelectItem value="corporate">Corporate</SelectItem>
                        </SelectContent>
                      </Select>
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="kyc_status">KYC Status</Label>
                      <Select 
                        value={formData.kyc_status} 
                        onValueChange={(value) => setFormData({...formData, kyc_status: value})}
                      >
                        <SelectTrigger>
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="pending">Pending</SelectItem>
                          <SelectItem value="approved">Approved</SelectItem>
                          <SelectItem value="rejected">Rejected</SelectItem>
                        </SelectContent>
                      </Select>
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <Label htmlFor="investment_capacity">Investment Capacity</Label>
                      <Input
                        id="investment_capacity"
                        type="number"
                        value={formData.investment_capacity}
                        onChange={(e) => setFormData({...formData, investment_capacity: e.target.value})}
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="risk_profile">Risk Profile</Label>
                      <Select 
                        value={formData.risk_profile} 
                        onValueChange={(value) => setFormData({...formData, risk_profile: value})}
                      >
                        <SelectTrigger>
                          <SelectValue placeholder="Select risk profile" />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="conservative">Conservative</SelectItem>
                          <SelectItem value="moderate">Moderate</SelectItem>
                          <SelectItem value="aggressive">Aggressive</SelectItem>
                        </SelectContent>
                      </Select>
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <Label htmlFor="tax_id">Tax ID</Label>
                      <Input
                        id="tax_id"
                        value={formData.tax_id}
                        onChange={(e) => setFormData({...formData, tax_id: e.target.value})}
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="country">Country</Label>
                      <Input
                        id="country"
                        value={formData.country}
                        onChange={(e) => setFormData({...formData, country: e.target.value})}
                      />
                    </div>
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="address">Address</Label>
                    <Textarea
                      id="address"
                      value={formData.address}
                      onChange={(e) => setFormData({...formData, address: e.target.value})}
                      rows={2}
                    />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="notes">Notes</Label>
                    <Textarea
                      id="notes"
                      value={formData.notes}
                      onChange={(e) => setFormData({...formData, notes: e.target.value})}
                      rows={3}
                    />
                  </div>

                  <DialogFooter>
                    <Button type="button" variant="outline" onClick={() => setIsDialogOpen(false)}>
                      Cancel
                    </Button>
                    <Button type="submit">
                      {editingInvestor ? 'Update' : 'Create'} Investor
                    </Button>
                  </DialogFooter>
                </form>
              </DialogContent>
            </Dialog>
          </div>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Name</TableHead>
                <TableHead>Party Entity</TableHead>
                <TableHead>Type</TableHead>
                <TableHead>KYC Status</TableHead>
                <TableHead>Investment Capacity</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {investors.map((investor) => (
                <TableRow key={investor.id}>
                  <TableCell className="font-medium">{investor.name}</TableCell>
                  <TableCell>{investor.party_entity_name}</TableCell>
                  <TableCell>
                    <Badge variant={getInvestorTypeColor(investor.investor_type)}>
                      {investor.investor_type}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <Badge variant={getKycStatusColor(investor.kyc_status)}>
                      {investor.kyc_status}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    {investor.investment_capacity ? `$${investor.investment_capacity.toLocaleString()}` : '-'}
                  </TableCell>
                  <TableCell>
                    <Badge variant={investor.is_active ? 'default' : 'secondary'}>
                      {investor.is_active ? 'Active' : 'Inactive'}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <div className="flex space-x-2">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handleEdit(investor)}
                      >
                        <Edit className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handleDelete(investor.id)}
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
};

export default InvestorManagement;