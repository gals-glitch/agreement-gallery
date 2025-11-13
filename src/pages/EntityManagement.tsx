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
import { Users, Building2, UserPlus, Edit, Trash2, Mail, Phone, MapPin, DollarSign } from 'lucide-react';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from '@/hooks/use-toast';

interface Entity {
  id: string;
  name: string;
  entity_type: 'distributor' | 'referrer' | 'partner';
  email?: string;
  phone?: string;
  address?: string;
  country?: string;
  tax_id?: string;
  commission_rate?: number;
  is_active: boolean;
  notes?: string;
  created_at: string;
  updated_at: string;
}

interface EntityFormData {
  name: string;
  entity_type: 'distributor' | 'referrer' | 'partner';
  email: string;
  phone: string;
  address: string;
  country: string;
  tax_id: string;
  commission_rate: string;
  is_active: boolean;
  notes: string;
}

const initialFormData: EntityFormData = {
  name: '',
  entity_type: 'distributor',
  email: '',
  phone: '',
  address: '',
  country: '',
  tax_id: '',
  commission_rate: '',
  is_active: true,
  notes: ''
};

export default function EntityManagement() {
  const [entities, setEntities] = useState<Entity[]>([]);
  const [loading, setLoading] = useState(true);
  const [formData, setFormData] = useState<EntityFormData>(initialFormData);
  const [editingEntity, setEditingEntity] = useState<Entity | null>(null);
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [activeTab, setActiveTab] = useState<'distributor' | 'referrer' | 'partner'>('distributor');
  
  const { toast } = useToast();

  useEffect(() => {
    fetchEntities();
  }, []);

  const fetchEntities = async () => {
    try {
      const { data, error } = await supabase
        .from('entities')
        .select('*')
        .order('name');

      if (error) throw error;
      setEntities(data || []);
    } catch (error) {
      console.error('Error fetching entities:', error);
      toast({
        title: "Error",
        description: "Failed to load entities",
        variant: "destructive"
      });
    } finally {
      setLoading(false);
    }
  };

  const handleInputChange = (field: keyof EntityFormData, value: string | boolean) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!formData.name.trim()) {
      toast({
        title: "Validation Error",
        description: "Entity name is required",
        variant: "destructive"
      });
      return;
    }

    try {
      const entityData = {
        name: formData.name.trim(),
        entity_type: formData.entity_type,
        email: formData.email || null,
        phone: formData.phone || null,
        address: formData.address || null,
        country: formData.country || null,
        tax_id: formData.tax_id || null,
        commission_rate: formData.commission_rate ? parseFloat(formData.commission_rate) : null,
        is_active: formData.is_active,
        notes: formData.notes || null
      };

      if (editingEntity) {
        const { error } = await supabase
          .from('entities')
          .update(entityData)
          .eq('id', editingEntity.id);

        if (error) throw error;
        
        toast({
          title: "Success",
          description: "Entity updated successfully"
        });
      } else {
        const { error } = await supabase
          .from('entities')
          .insert([entityData]);

        if (error) throw error;
        
        toast({
          title: "Success",
          description: "Entity created successfully"
        });
      }

      await fetchEntities();
      handleCloseDialog();
    } catch (error: any) {
      console.error('Error saving entity:', error);
      
      if (error.code === '23505') {
        toast({
          title: "Duplicate Entity",
          description: `An entity with this name already exists as a ${formData.entity_type}`,
          variant: "destructive"
        });
      } else {
        toast({
          title: "Error",
          description: "Failed to save entity",
          variant: "destructive"
        });
      }
    }
  };

  const handleEdit = (entity: Entity) => {
    setEditingEntity(entity);
    setFormData({
      name: entity.name,
      entity_type: entity.entity_type,
      email: entity.email || '',
      phone: entity.phone || '',
      address: entity.address || '',
      country: entity.country || '',
      tax_id: entity.tax_id || '',
      commission_rate: entity.commission_rate?.toString() || '',
      is_active: entity.is_active,
      notes: entity.notes || ''
    });
    setIsDialogOpen(true);
  };

  const handleDelete = async (entity: Entity) => {
    try {
      const { error } = await supabase
        .from('entities')
        .delete()
        .eq('id', entity.id);

      if (error) throw error;
      
      toast({
        title: "Success",
        description: "Entity deleted successfully"
      });
      
      await fetchEntities();
    } catch (error) {
      console.error('Error deleting entity:', error);
      toast({
        title: "Error",
        description: "Failed to delete entity",
        variant: "destructive"
      });
    }
  };

  const handleCloseDialog = () => {
    setIsDialogOpen(false);
    setEditingEntity(null);
    setFormData(initialFormData);
  };

  const getEntitiesByType = (type: 'distributor' | 'referrer' | 'partner') => {
    return entities.filter(entity => entity.entity_type === type);
  };

  const getEntityIcon = (type: string) => {
    switch (type) {
      case 'distributor': return Building2;
      case 'referrer': return Users;
      case 'partner': return UserPlus;
      default: return Users;
    }
  };

  const getEntityTypeColor = (type: string) => {
    switch (type) {
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
            <p className="mt-2 text-muted-foreground">Loading entities...</p>
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
          <h1 className="text-3xl font-bold">Entity Management</h1>
          <p className="text-muted-foreground">
            Manage distributors, referrers, and partners
          </p>
        </div>
        
        <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
          <DialogTrigger asChild>
            <Button onClick={() => setFormData({...initialFormData, entity_type: activeTab})}>
              <UserPlus className="w-4 h-4 mr-2" />
              Add {activeTab.charAt(0).toUpperCase() + activeTab.slice(1)}
            </Button>
          </DialogTrigger>
          <DialogContent className="sm:max-w-2xl">
            <DialogHeader>
              <DialogTitle>
                {editingEntity ? 'Edit' : 'Add'} Entity
              </DialogTitle>
              <DialogDescription>
                {editingEntity ? 'Update' : 'Create a new'} {formData.entity_type} entity
              </DialogDescription>
            </DialogHeader>
            
            <form onSubmit={handleSubmit} className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label htmlFor="name">Name *</Label>
                  <Input
                    id="name"
                    value={formData.name}
                    onChange={(e) => handleInputChange('name', e.target.value)}
                    placeholder="Entity name"
                    required
                  />
                </div>
                
                <div>
                  <Label htmlFor="entity_type">Type *</Label>
                  <Select
                    value={formData.entity_type}
                    onValueChange={(value) => handleInputChange('entity_type', value)}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="distributor">Distributor</SelectItem>
                      <SelectItem value="referrer">Referrer</SelectItem>
                      <SelectItem value="partner">Partner</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label htmlFor="email">Email</Label>
                  <Input
                    id="email"
                    type="email"
                    value={formData.email}
                    onChange={(e) => handleInputChange('email', e.target.value)}
                    placeholder="email@example.com"
                  />
                </div>
                
                <div>
                  <Label htmlFor="phone">Phone</Label>
                  <Input
                    id="phone"
                    value={formData.phone}
                    onChange={(e) => handleInputChange('phone', e.target.value)}
                    placeholder="+1 (555) 123-4567"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label htmlFor="country">Country</Label>
                  <Input
                    id="country"
                    value={formData.country}
                    onChange={(e) => handleInputChange('country', e.target.value)}
                    placeholder="United States"
                  />
                </div>
                
                <div>
                  <Label htmlFor="tax_id">Tax ID</Label>
                  <Input
                    id="tax_id"
                    value={formData.tax_id}
                    onChange={(e) => handleInputChange('tax_id', e.target.value)}
                    placeholder="Tax identification number"
                  />
                </div>
              </div>

              <div>
                <Label htmlFor="address">Address</Label>
                <Input
                  id="address"
                  value={formData.address}
                  onChange={(e) => handleInputChange('address', e.target.value)}
                  placeholder="Full address"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label htmlFor="commission_rate">Commission Rate (%)</Label>
                  <Input
                    id="commission_rate"
                    type="number"
                    step="0.01"
                    min="0"
                    max="100"
                    value={formData.commission_rate}
                    onChange={(e) => handleInputChange('commission_rate', e.target.value)}
                    placeholder="5.00"
                  />
                </div>
                
                <div className="flex items-center space-x-2 pt-6">
                  <Switch
                    id="is_active"
                    checked={formData.is_active}
                    onCheckedChange={(checked) => handleInputChange('is_active', checked)}
                  />
                  <Label htmlFor="is_active">Active</Label>
                </div>
              </div>

              <div>
                <Label htmlFor="notes">Notes</Label>
                <Textarea
                  id="notes"
                  value={formData.notes}
                  onChange={(e) => handleInputChange('notes', e.target.value)}
                  placeholder="Additional notes..."
                  rows={3}
                />
              </div>

              <div className="flex justify-end gap-2 pt-4">
                <Button type="button" variant="outline" onClick={handleCloseDialog}>
                  Cancel
                </Button>
                <Button type="submit">
                  {editingEntity ? 'Update' : 'Create'} Entity
                </Button>
              </div>
            </form>
          </DialogContent>
        </Dialog>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {(['distributor', 'referrer', 'partner'] as const).map((type) => {
          const typeEntities = getEntitiesByType(type);
          const activeCount = typeEntities.filter(e => e.is_active).length;
          const IconComponent = getEntityIcon(type);
          
          return (
            <Card key={type}>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium capitalize">
                  {type}s
                </CardTitle>
                <IconComponent className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{typeEntities.length}</div>
                <p className="text-xs text-muted-foreground">
                  {activeCount} active, {typeEntities.length - activeCount} inactive
                </p>
              </CardContent>
            </Card>
          );
        })}
      </div>

      {/* Entity Tables */}
      <Tabs value={activeTab} onValueChange={(value) => setActiveTab(value as any)} className="space-y-4">
        <TabsList>
          <TabsTrigger value="distributor">Distributors</TabsTrigger>
          <TabsTrigger value="referrer">Referrers</TabsTrigger>
          <TabsTrigger value="partner">Partners</TabsTrigger>
        </TabsList>

        {(['distributor', 'referrer', 'partner'] as const).map((type) => (
          <TabsContent key={type} value={type}>
            <Card>
              <CardHeader>
                <CardTitle className="capitalize">{type}s</CardTitle>
                <CardDescription>
                  Manage {type} entities and their details
                </CardDescription>
              </CardHeader>
              <CardContent>
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Name</TableHead>
                      <TableHead>Contact</TableHead>
                      <TableHead>Location</TableHead>
                      <TableHead>Commission</TableHead>
                      <TableHead>Status</TableHead>
                      <TableHead>Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {getEntitiesByType(type).map((entity) => (
                      <TableRow key={entity.id}>
                        <TableCell>
                          <div>
                            <div className="font-medium">{entity.name}</div>
                            {entity.tax_id && (
                              <div className="text-sm text-muted-foreground">
                                Tax ID: {entity.tax_id}
                              </div>
                            )}
                          </div>
                        </TableCell>
                        <TableCell>
                          <div className="space-y-1">
                            {entity.email && (
                              <div className="flex items-center gap-1 text-sm">
                                <Mail className="w-3 h-3" />
                                {entity.email}
                              </div>
                            )}
                            {entity.phone && (
                              <div className="flex items-center gap-1 text-sm">
                                <Phone className="w-3 h-3" />
                                {entity.phone}
                              </div>
                            )}
                          </div>
                        </TableCell>
                        <TableCell>
                          {entity.country && (
                            <div className="flex items-center gap-1 text-sm">
                              <MapPin className="w-3 h-3" />
                              {entity.country}
                            </div>
                          )}
                        </TableCell>
                        <TableCell>
                          {entity.commission_rate && (
                            <div className="flex items-center gap-1">
                              <DollarSign className="w-3 h-3" />
                              {entity.commission_rate}%
                            </div>
                          )}
                        </TableCell>
                        <TableCell>
                          <Badge variant={entity.is_active ? "default" : "secondary"}>
                            {entity.is_active ? "Active" : "Inactive"}
                          </Badge>
                        </TableCell>
                        <TableCell>
                          <div className="flex items-center gap-2">
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => handleEdit(entity)}
                            >
                              <Edit className="w-3 h-3" />
                            </Button>
                            <AlertDialog>
                              <AlertDialogTrigger asChild>
                                <Button variant="outline" size="sm">
                                  <Trash2 className="w-3 h-3" />
                                </Button>
                              </AlertDialogTrigger>
                              <AlertDialogContent>
                                <AlertDialogHeader>
                                  <AlertDialogTitle>Delete Entity</AlertDialogTitle>
                                  <AlertDialogDescription>
                                    Are you sure you want to delete "{entity.name}"? This action cannot be undone.
                                  </AlertDialogDescription>
                                </AlertDialogHeader>
                                <AlertDialogFooter>
                                  <AlertDialogCancel>Cancel</AlertDialogCancel>
                                  <AlertDialogAction onClick={() => handleDelete(entity)}>
                                    Delete
                                  </AlertDialogAction>
                                </AlertDialogFooter>
                              </AlertDialogContent>
                            </AlertDialog>
                          </div>
                        </TableCell>
                      </TableRow>
                    ))}
                    {getEntitiesByType(type).length === 0 && (
                      <TableRow>
                        <TableCell colSpan={6} className="text-center py-8 text-muted-foreground">
                          No {type}s found. Add your first {type} to get started.
                        </TableCell>
                      </TableRow>
                    )}
                  </TableBody>
                </Table>
              </CardContent>
            </Card>
          </TabsContent>
        ))}
      </Tabs>
    </div>
  );
}