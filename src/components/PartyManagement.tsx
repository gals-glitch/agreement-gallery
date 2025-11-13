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
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from '@/components/ui/alert-dialog';
import { Users, Building2, UserPlus, Edit, Trash2, Mail, Phone, MapPin, DollarSign, Settings, Plus, Minus } from 'lucide-react';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from '@/hooks/use-toast';

interface Party {
  id: string;
  name: string;
  tags: string[];
  emails: string[];
  status: 'active' | 'inactive';
  created_at: string;
  updated_at: string;
  rules?: Rule[];
  sub_agents?: SubAgent[];
  investors?: { id: string; name: string; email: string | null }[];
}

interface Rule {
  id: string;
  name: string;
  entity_name?: string;
  entity_type: string;
  rule_type: string;
  base_rate?: number;
  fixed_amount?: number;
  min_amount?: number;
  max_amount?: number;
  calculation_basis: string;
  effective_from?: string;
  effective_to?: string;
  priority: number;
  is_active: boolean;
  requires_approval: boolean;
  created_at: string;
  updated_at: string;
  created_by?: string;
  lag_days: number;
  fund_name?: string;
  timing_mode?: string;
  currency: string;
  vat_rate_table?: string;
  vat_mode?: string;
  pdf_file_path?: string;
}

interface SubAgent {
  id: string;
  distributor_id: string;
  name: string;
  email?: string;
  split_percentage: number;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

interface PartyFormData {
  name: string;
  tags: string;
  emails: string;
  country: string;
  tax_id: string;
  status: 'active' | 'inactive';
}

interface SubAgentFormData {
  name: string;
  email: string;
  share_percentage: string;
  is_active: boolean;
}

const initialPartyForm: PartyFormData = {
  name: '',
  tags: '',
  emails: '',
  country: '',
  tax_id: '',
  status: 'active'
};

const initialSubAgentForm: SubAgentFormData = {
  name: '',
  email: '',
  share_percentage: '',
  is_active: true
};

export default function PartyManagement() {
  const [parties, setParties] = useState<Party[]>([]);
  const [loading, setLoading] = useState(true);
  const [partyForm, setPartyForm] = useState<PartyFormData>(initialPartyForm);
  const [subAgentForm, setSubAgentForm] = useState<SubAgentFormData>(initialSubAgentForm);
  const [editingParty, setEditingParty] = useState<Party | null>(null);
  const [selectedParty, setSelectedParty] = useState<Party | null>(null);
  const [isPartyDialogOpen, setIsPartyDialogOpen] = useState(false);
  const [isSubAgentDialogOpen, setIsSubAgentDialogOpen] = useState(false);
  const [activeTab, setActiveTab] = useState('overview');
  
  const { toast } = useToast();

  useEffect(() => {
    fetchParties();
  }, []);

  const fetchParties = async () => {
    try {
      const { data, error } = await supabase
        .from('parties')
        .select('*')
        .order('name');

      if (error) throw error;

      // Transform parties to component format
      const transformedParties: Party[] = (data || []).map(party => ({
        id: party.id,
        name: party.name,
        tags: [party.party_type], // Transform party_type to tags
        emails: party.email ? [party.email] : [],
        status: party.is_active ? 'active' : 'inactive',
        created_at: party.created_at,
        updated_at: party.updated_at
      }));

      setParties(transformedParties);
    } catch (error) {
      console.error('Error fetching parties:', error);
      toast({
        title: "Error",
        description: "Failed to load parties",
        variant: "destructive"
      });
    } finally {
      setLoading(false);
    }
  };

  const fetchPartyDetails = async (partyId: string) => {
    try {
      const party = parties.find(p => p.id === partyId);
      if (!party) return;

      // Fetch rules assigned via distributor_rules table
      const { data: distributorRulesData, error: distributorRulesError } = await supabase
        .from('distributor_rules')
        .select(`
          priority,
          is_active,
          advanced_commission_rules (*)
        `)
        .eq('distributor_id', partyId)
        .order('priority');

      if (distributorRulesError) throw distributorRulesError;

      // Transform the data to match Rule interface
      const rulesData = (distributorRulesData || []).map((dr: any) => ({
        ...dr.advanced_commission_rules,
        priority: dr.priority,
        is_active: dr.is_active
      }));

      // Fetch sub-agents for this party
      const { data: subAgentsData, error: subAgentsError } = await supabase
        .from('sub_agents')
        .select('*')
        .eq('distributor_id', partyId);

      if (subAgentsError) throw subAgentsError;

      // Fetch investors linked via agreements
      const { data: investorsData, error: investorsError } = await supabase
        .from('investor_agreement_links')
        .select(`
          investors (
            id,
            name
          )
        `)
        .eq('introduced_by_party_id', partyId)
        .eq('is_active', true);

      if (investorsError) throw investorsError;

      setSelectedParty({
        ...party,
        rules: (rulesData || []) as Rule[],
        sub_agents: (subAgentsData || []) as SubAgent[],
        investors: (investorsData || []).map((inv: any) => inv.investors)
      });
    } catch (error) {
      console.error('Error fetching party details:', error);
      toast({
        title: "Error",
        description: "Failed to load party details",
        variant: "destructive"
      });
    }
  };

  const handlePartySubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!partyForm.name.trim()) {
      toast({
        title: "Validation Error",
        description: "Party name is required",
        variant: "destructive"
      });
      return;
    }

    try {
      const partyType = partyForm.tags.split(',')[0]?.trim() || 'distributor';
      const validPartyType = ['distributor', 'referrer', 'partner'].includes(partyType) 
        ? partyType as 'distributor' | 'referrer' | 'partner'
        : 'distributor';
        
      const partyData = {
        name: partyForm.name.trim(),
        party_type: validPartyType,
        email: partyForm.emails.split(',')[0]?.trim() || null,
        is_active: partyForm.status === 'active'
      };

      if (editingParty) {
        const { error } = await supabase
          .from('parties')
          .update(partyData)
          .eq('id', editingParty.id);

        if (error) throw error;
        
        toast({
          title: "Success",
          description: "Party updated successfully"
        });
      } else {
        const { error } = await supabase
          .from('parties')
          .insert(partyData);

        if (error) throw error;
        
        toast({
          title: "Success",
          description: "Party created successfully"
        });
      }

      await fetchParties();
      handleClosePartyDialog();
    } catch (error: any) {
      console.error('Error saving party:', error);
      toast({
        title: "Error",
        description: "Failed to save party",
        variant: "destructive"
      });
    }
  };

  const handleSubAgentSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!subAgentForm.name.trim() || !subAgentForm.share_percentage) {
      toast({
        title: "Validation Error",
        description: "Name and share percentage are required",
        variant: "destructive"
      });
      return;
    }

    const sharePercentage = parseFloat(subAgentForm.share_percentage);
    if (sharePercentage <= 0 || sharePercentage > 100) {
      toast({
        title: "Validation Error",
        description: "Share percentage must be between 0 and 100",
        variant: "destructive"
      });
      return;
    }

    // Validate total doesn't exceed 100%
    const currentTotal = (selectedParty?.sub_agents || [])
      .filter(sa => sa.is_active)
      .reduce((sum, sa) => sum + sa.split_percentage, 0);

    if (currentTotal + sharePercentage > 100) {
      toast({
        title: "Validation Error",
        description: `Total sub-agent shares would exceed 100% (current: ${currentTotal}%)`,
        variant: "destructive"
      });
      return;
    }

    try {
      const subAgentData = {
        distributor_id: selectedParty!.id,
        name: subAgentForm.name.trim(),
        email: subAgentForm.email.trim() || null,
        split_percentage: sharePercentage,
        is_active: subAgentForm.is_active
      };

      const { error } = await supabase
        .from('sub_agents')
        .insert([subAgentData]);

      if (error) throw error;
      
      toast({
        title: "Success",
        description: "Sub-agent added successfully"
      });

      await fetchPartyDetails(selectedParty!.id);
      setSubAgentForm(initialSubAgentForm);
      setIsSubAgentDialogOpen(false);
    } catch (error: any) {
      console.error('Error saving sub-agent:', error);
      toast({
        title: "Error",
        description: "Failed to save sub-agent",
        variant: "destructive"
      });
    }
  };

  const handleDeleteSubAgent = async (subAgentId: string) => {
    try {
      const { error } = await supabase
        .from('sub_agents')
        .delete()
        .eq('id', subAgentId);

      if (error) throw error;
      
      toast({
        title: "Success",
        description: "Sub-agent deleted successfully"
      });
      
      await fetchPartyDetails(selectedParty!.id);
    } catch (error) {
      console.error('Error deleting sub-agent:', error);
      toast({
        title: "Error",
        description: "Failed to delete sub-agent",
        variant: "destructive"
      });
    }
  };

  const handleClosePartyDialog = () => {
    setIsPartyDialogOpen(false);
    setEditingParty(null);
    setPartyForm(initialPartyForm);
  };

  const getPartyTypeColor = (tags: string[]) => {
    const primaryTag = tags[0]?.toLowerCase();
    switch (primaryTag) {
      case 'distributor': return 'default';
      case 'referrer': return 'secondary';
      case 'partner': return 'outline';
      default: return 'default';
    }
  };

  if (loading) {
    return (
      <div className="max-w-7xl mx-auto px-4 py-6">
        <div className="flex items-center justify-center h-64">
          <div className="text-center">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto"></div>
            <p className="mt-2 text-muted-foreground">Loading parties...</p>
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
          <h1 className="text-3xl font-bold">Party Management</h1>
          <p className="text-muted-foreground">
            Manage parties, rules, and sub-agent hierarchies
          </p>
        </div>
        
        <Dialog open={isPartyDialogOpen} onOpenChange={setIsPartyDialogOpen}>
          <DialogTrigger asChild>
            <Button>
              <UserPlus className="w-4 h-4 mr-2" />
              Add Party
            </Button>
          </DialogTrigger>
          <DialogContent className="sm:max-w-2xl">
            <DialogHeader>
              <DialogTitle>
                {editingParty ? 'Edit' : 'Add'} Party
              </DialogTitle>
              <DialogDescription>
                {editingParty ? 'Update' : 'Create a new'} party entity
              </DialogDescription>
            </DialogHeader>
            
            <form onSubmit={handlePartySubmit} className="space-y-4">
              <div>
                <Label htmlFor="name">Name *</Label>
                <Input
                  id="name"
                  value={partyForm.name}
                  onChange={(e) => setPartyForm(prev => ({ ...prev, name: e.target.value }))}
                  placeholder="Party name"
                  required
                />
              </div>
              
              <div>
                <Label htmlFor="tags">Tags (comma-separated)</Label>
                <Input
                  id="tags"
                  value={partyForm.tags}
                  onChange={(e) => setPartyForm(prev => ({ ...prev, tags: e.target.value }))}
                  placeholder="distributor, tier-1, premium"
                />
              </div>

              <div>
                <Label htmlFor="emails">Notification Emails (comma-separated)</Label>
                <Input
                  id="emails"
                  value={partyForm.emails}
                  onChange={(e) => setPartyForm(prev => ({ ...prev, emails: e.target.value }))}
                  placeholder="contact@party.com, admin@party.com"
                />
              </div>

              <div>
                <Label htmlFor="country">Country</Label>
                <Input
                  id="country"
                  value={partyForm.country}
                  onChange={(e) => setPartyForm(prev => ({ ...prev, country: e.target.value }))}
                  placeholder="United States"
                />
              </div>

              <div>
                <Label htmlFor="tax_id">Tax ID</Label>
                <Input
                  id="tax_id"
                  value={partyForm.tax_id}
                  onChange={(e) => setPartyForm(prev => ({ ...prev, tax_id: e.target.value }))}
                  placeholder="XX-XXXXXXX"
                />
              </div>

              <div className="flex items-center space-x-2">
                <Switch
                  id="status"
                  checked={partyForm.status === 'active'}
                  onCheckedChange={(checked) => setPartyForm(prev => ({ 
                    ...prev, 
                    status: checked ? 'active' : 'inactive' 
                  }))}
                />
                <Label htmlFor="status">Active</Label>
              </div>

              <div className="flex justify-end gap-2 pt-4">
                <Button type="button" variant="outline" onClick={handleClosePartyDialog}>
                  Cancel
                </Button>
                <Button type="submit">
                  {editingParty ? 'Update' : 'Create'} Party
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
            <CardTitle className="text-sm font-medium">Total Parties</CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{parties.length}</div>
            <p className="text-xs text-muted-foreground">
              {parties.filter(p => p.status === 'active').length} active
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Distributors</CardTitle>
            <Building2 className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {parties.filter(p => p.tags.includes('distributor')).length}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Referrers</CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {parties.filter(p => p.tags.includes('referrer')).length}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Partners</CardTitle>
            <UserPlus className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {parties.filter(p => p.tags.includes('partner')).length}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Parties Table */}
      <Card>
        <CardHeader>
          <CardTitle>Parties</CardTitle>
          <CardDescription>
            Click on a party to view details, rules, and sub-agents
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Name</TableHead>
                <TableHead>Tags</TableHead>
                <TableHead>Contact</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {parties.map((party) => (
                <TableRow key={party.id} className="cursor-pointer hover:bg-muted/50">
                  <TableCell onClick={() => {
                    setSelectedParty(party);
                    fetchPartyDetails(party.id);
                  }}>
                    <div className="font-medium">{party.name}</div>
                  </TableCell>
                  <TableCell>
                    <div className="flex gap-1 flex-wrap">
                      {party.tags.map((tag, index) => (
                        <Badge key={index} variant={getPartyTypeColor(party.tags)}>
                          {tag}
                        </Badge>
                      ))}
                    </div>
                  </TableCell>
                  <TableCell>
                    {party.emails.length > 0 && (
                      <div className="flex items-center gap-1 text-sm">
                        <Mail className="w-3 h-3" />
                        {party.emails[0]}
                      </div>
                    )}
                  </TableCell>
                  <TableCell>
                    <Badge variant={party.status === 'active' ? 'default' : 'secondary'}>
                      {party.status}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <div className="flex gap-2">
                      <Button size="sm" variant="outline" onClick={() => {
                        setEditingParty(party);
                        setPartyForm({
                          name: party.name,
                          tags: party.tags.join(', '),
                          emails: party.emails.join(', '),
                          status: party.status
                        });
                        setIsPartyDialogOpen(true);
                      }}>
                        <Edit className="w-4 h-4" />
                      </Button>
                      <Button size="sm" variant="outline" onClick={() => {
                        setSelectedParty(party);
                        fetchPartyDetails(party.id);
                      }}>
                        <Settings className="w-4 h-4" />
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      {/* Party Details Dialog */}
      <Dialog open={!!selectedParty} onOpenChange={() => setSelectedParty(null)}>
        <DialogContent className="sm:max-w-4xl max-h-[80vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <Building2 className="w-5 h-5" />
              {selectedParty?.name}
            </DialogTitle>
            <DialogDescription>
              Party details, rules, and sub-agent management
            </DialogDescription>
          </DialogHeader>
          
          <Tabs value={activeTab} onValueChange={setActiveTab}>
            <TabsList className="grid w-full grid-cols-4">
              <TabsTrigger value="overview">Overview</TabsTrigger>
              <TabsTrigger value="rules">Rules ({selectedParty?.rules?.length || 0})</TabsTrigger>
              <TabsTrigger value="investors">Investors ({selectedParty?.investors?.length || 0})</TabsTrigger>
              <TabsTrigger value="sub-agents">Sub-Agents ({selectedParty?.sub_agents?.length || 0})</TabsTrigger>
            </TabsList>
            
            <TabsContent value="overview" className="space-y-4">
              <Card>
                <CardHeader>
                  <CardTitle className="text-sm">Party Information</CardTitle>
                </CardHeader>
                <CardContent className="space-y-2">
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Name:</span>
                    <span>{selectedParty?.name}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Tags:</span>
                    <div className="flex gap-1">
                      {selectedParty?.tags.map((tag, index) => (
                        <Badge key={index} variant="outline">{tag}</Badge>
                      ))}
                    </div>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Status:</span>
                    <Badge variant={selectedParty?.status === 'active' ? 'default' : 'secondary'}>
                      {selectedParty?.status}
                    </Badge>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Emails:</span>
                    <div className="text-right">
                      {selectedParty?.emails.map((email, index) => (
                        <div key={index}>{email}</div>
                      ))}
                    </div>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>
            
            <TabsContent value="rules" className="space-y-4">
              <Card>
                <CardHeader>
                  <CardTitle className="text-sm">Assigned Commission Rules</CardTitle>
                  <CardDescription>
                    Rules are assigned via Distributor Rules Management
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  {selectedParty?.rules && selectedParty.rules.length > 0 ? (
                    <Table>
                      <TableHeader>
                        <TableRow>
                          <TableHead>Priority</TableHead>
                          <TableHead>Rule Name</TableHead>
                          <TableHead>Type</TableHead>
                          <TableHead>Rate</TableHead>
                          <TableHead>Status</TableHead>
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {selectedParty.rules.map((rule) => (
                          <TableRow key={rule.id}>
                            <TableCell>{rule.priority}</TableCell>
                            <TableCell className="font-medium">{rule.name}</TableCell>
                            <TableCell>{rule.rule_type}</TableCell>
                            <TableCell>
                              {rule.base_rate ? `${rule.base_rate}%` : 'Variable'}
                            </TableCell>
                            <TableCell>
                              <Badge variant={rule.is_active ? 'default' : 'secondary'}>
                                {rule.is_active ? 'Active' : 'Inactive'}
                              </Badge>
                            </TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  ) : (
                    <div className="text-center text-muted-foreground py-8">
                      No rules assigned yet. Use Distributor Rules Management to assign rules.
                    </div>
                  )}
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="investors" className="space-y-4">
              <Card>
                <CardHeader>
                  <CardTitle className="text-sm">Linked Investors</CardTitle>
                  <CardDescription>
                    Investors introduced by this party via agreements
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  {selectedParty?.investors && selectedParty.investors.length > 0 ? (
                    <Table>
                      <TableHeader>
                        <TableRow>
                          <TableHead>Name</TableHead>
                          <TableHead>Email</TableHead>
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {selectedParty.investors.map((investor) => (
                          <TableRow key={investor.id}>
                            <TableCell className="font-medium">{investor.name}</TableCell>
                            <TableCell>{investor.email || '—'}</TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  ) : (
                    <div className="text-center text-muted-foreground py-8">
                      No investors linked yet. Link investors via Investor Agreement Links.
                    </div>
                  )}
                </CardContent>
              </Card>
            </TabsContent>
            
            <TabsContent value="sub-agents" className="space-y-4">
              <Card>
                <CardHeader>
                  <div className="flex items-center justify-between">
                    <CardTitle className="text-sm">Sub-Agents</CardTitle>
                    <Dialog open={isSubAgentDialogOpen} onOpenChange={setIsSubAgentDialogOpen}>
                      <DialogTrigger asChild>
                        <Button size="sm">
                          <Plus className="w-4 h-4 mr-2" />
                          Add Sub-Agent
                        </Button>
                      </DialogTrigger>
                      <DialogContent>
                        <DialogHeader>
                          <DialogTitle>Add Sub-Agent</DialogTitle>
                          <DialogDescription>
                            Add a new sub-agent with commission split
                          </DialogDescription>
                        </DialogHeader>
                        
                        <form onSubmit={handleSubAgentSubmit} className="space-y-4">
                          <div>
                            <Label htmlFor="sub-name">Name *</Label>
                            <Input
                              id="sub-name"
                              value={subAgentForm.name}
                              onChange={(e) => setSubAgentForm(prev => ({ ...prev, name: e.target.value }))}
                              placeholder="Sub-agent name"
                              required
                            />
                          </div>
                          
                          <div>
                            <Label htmlFor="sub-email">Email</Label>
                            <Input
                              id="sub-email"
                              type="email"
                              value={subAgentForm.email}
                              onChange={(e) => setSubAgentForm(prev => ({ ...prev, email: e.target.value }))}
                              placeholder="email@example.com"
                            />
                          </div>

                          <div>
                            <Label htmlFor="sub-percentage">Share Percentage *</Label>
                            <Input
                              id="sub-percentage"
                              type="number"
                              step="0.01"
                              min="0"
                              max="100"
                              value={subAgentForm.share_percentage}
                              onChange={(e) => setSubAgentForm(prev => ({ ...prev, share_percentage: e.target.value }))}
                              placeholder="30.00"
                              required
                            />
                          </div>

                          <div className="flex items-center space-x-2">
                            <Switch
                              id="sub-active"
                              checked={subAgentForm.is_active}
                              onCheckedChange={(checked) => setSubAgentForm(prev => ({ 
                                ...prev, 
                                is_active: checked 
                              }))}
                            />
                            <Label htmlFor="sub-active">Active</Label>
                          </div>

                          <div className="flex justify-end gap-2 pt-4">
                            <Button type="button" variant="outline" onClick={() => setIsSubAgentDialogOpen(false)}>
                              Cancel
                            </Button>
                            <Button type="submit">
                              Add Sub-Agent
                            </Button>
                          </div>
                        </form>
                      </DialogContent>
                    </Dialog>
                  </div>
                </CardHeader>
                <CardContent>
                  {selectedParty?.sub_agents && selectedParty.sub_agents.length > 0 ? (
                    <div className="space-y-4">
                      <div className="text-sm text-muted-foreground">
                         Total allocation: {selectedParty.sub_agents
                           .filter(sa => sa.is_active)
                           .reduce((sum, sa) => sum + sa.split_percentage, 0)
                         }%
                      </div>
                      <Table>
                        <TableHeader>
                          <TableRow>
                            <TableHead>Name</TableHead>
                            <TableHead>Email</TableHead>
                            <TableHead>Share %</TableHead>
                            <TableHead>Status</TableHead>
                            <TableHead>Actions</TableHead>
                          </TableRow>
                        </TableHeader>
                        <TableBody>
                          {selectedParty.sub_agents.map((subAgent) => (
                            <TableRow key={subAgent.id}>
                              <TableCell className="font-medium">{subAgent.name}</TableCell>
                              <TableCell>{subAgent.email || '—'}</TableCell>
                              <TableCell>{subAgent.split_percentage}%</TableCell>
                              <TableCell>
                                <Badge variant={subAgent.is_active ? 'default' : 'secondary'}>
                                  {subAgent.is_active ? 'Active' : 'Inactive'}
                                </Badge>
                              </TableCell>
                              <TableCell>
                                <AlertDialog>
                                  <AlertDialogTrigger asChild>
                                    <Button size="sm" variant="outline">
                                      <Trash2 className="w-4 h-4" />
                                    </Button>
                                  </AlertDialogTrigger>
                                  <AlertDialogContent>
                                    <AlertDialogHeader>
                                      <AlertDialogTitle>Delete Sub-Agent</AlertDialogTitle>
                                      <AlertDialogDescription>
                                        Are you sure you want to delete this sub-agent? This action cannot be undone.
                                      </AlertDialogDescription>
                                    </AlertDialogHeader>
                                    <AlertDialogFooter>
                                      <AlertDialogCancel>Cancel</AlertDialogCancel>
                                      <AlertDialogAction onClick={() => handleDeleteSubAgent(subAgent.id)}>
                                        Delete
                                      </AlertDialogAction>
                                    </AlertDialogFooter>
                                  </AlertDialogContent>
                                </AlertDialog>
                              </TableCell>
                            </TableRow>
                          ))}
                        </TableBody>
                      </Table>
                    </div>
                  ) : (
                    <div className="text-center text-muted-foreground py-8">
                      No sub-agents configured
                    </div>
                  )}
                </CardContent>
              </Card>
            </TabsContent>
          </Tabs>
        </DialogContent>
      </Dialog>
    </div>
  );
}