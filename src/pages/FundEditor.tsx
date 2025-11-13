/**
 * Fund Editor (Vantage-style)
 *
 * Terminology: "Fund" in Vantage = Deal record in our DB
 * This editor provides comprehensive deal management with:
 * - Fund Information (basic attributes + scoreboard fields RO)
 * - Fund Profile (strategy, risk, pricing)
 * - Fees Earned (preferred return, carry, admin fees)
 * - Fund Closings (grid with auto-sum)
 * - Wire Instructions
 * - Import/Export capabilities
 */

import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from '@/components/ui/accordion';
import { useToast } from '@/hooks/use-toast';
import { ArrowLeft, Save, Upload, Plus, Trash2 } from 'lucide-react';

// Placeholder: we'll implement API clients shortly
interface Deal {
  id: number;
  name: string;
  short_name?: string;
  // ... full interface to be defined
}

export default function FundEditor() {
  const navigate = useNavigate();
  const { toast } = useToast();

  // State
  const [deals, setDeals] = useState<Deal[]>([]);
  const [selectedDealId, setSelectedDealId] = useState<number | null>(null);
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState<any>({});

  // Fetch deals list for dropdown
  useEffect(() => {
    fetchDeals();
  }, []);

  const fetchDeals = async () => {
    try {
      setLoading(true);
      // TODO: Implement dealsAPI.list()
      // const response = await dealsAPI.list();
      // setDeals(response.items);

      // Placeholder
      setDeals([
        { id: 1, name: 'Project Alpha', short_name: 'PA' },
        { id: 2, name: 'Project Beta', short_name: 'PB' },
      ]);
    } catch (error) {
      console.error('Failed to fetch deals:', error);
      toast({
        title: 'Error',
        description: 'Failed to load funds',
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
    }
  };

  // Load selected deal data
  const loadDeal = async (dealId: number) => {
    try {
      setLoading(true);
      // TODO: Implement dealsAPI.get(dealId)
      // const deal = await dealsAPI.get(dealId);
      // setFormData(deal);

      // Placeholder
      setFormData({
        id: dealId,
        name: 'Project Alpha',
        short_name: 'PA',
        equity_to_raise: 10000000,
        raised_so_far: 7500000,
      });

      toast({
        title: 'Fund Loaded',
        description: 'Fund data loaded successfully',
      });
    } catch (error) {
      console.error('Failed to load deal:', error);
      toast({
        title: 'Error',
        description: 'Failed to load fund data',
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
    }
  };

  // Handlers
  const handleSelectDeal = (dealId: string) => {
    const id = parseInt(dealId);
    setSelectedDealId(id);
    loadDeal(id);
  };

  const handleSave = async () => {
    if (!selectedDealId) {
      toast({
        title: 'No Fund Selected',
        description: 'Please select a fund to save',
        variant: 'destructive',
      });
      return;
    }

    try {
      setLoading(true);
      // TODO: Implement dealsAPI.update(selectedDealId, formData)
      // await dealsAPI.update(selectedDealId, formData);

      toast({
        title: 'Saved',
        description: 'Fund data saved successfully',
      });
    } catch (error) {
      console.error('Failed to save deal:', error);
      toast({
        title: 'Error',
        description: 'Failed to save fund data',
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
    }
  };

  const handleImport = () => {
    toast({
      title: 'Import',
      description: 'CSV import feature coming soon',
    });
  };

  const handleAdd = () => {
    toast({
      title: 'Add Fund',
      description: 'Add new fund feature coming soon',
    });
  };

  const handleDelete = () => {
    if (!selectedDealId) {
      toast({
        title: 'No Fund Selected',
        description: 'Please select a fund to delete',
        variant: 'destructive',
      });
      return;
    }

    // TODO: Implement confirmation dialog + soft delete
    toast({
      title: 'Delete',
      description: 'Delete fund feature coming soon',
    });
  };

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
            <h1 className="text-3xl font-bold">Fund Editor</h1>
            <p className="text-muted-foreground mt-1">
              Manage fund properties, closings, and attributes
            </p>
          </div>
        </div>
      </div>

      {/* Select Fund + Actions */}
      <Card>
        <CardHeader>
          <CardTitle>Select Fund</CardTitle>
          <CardDescription>
            Choose a fund to view and edit its details
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex items-center gap-3">
            <div className="flex-1">
              <Select
                value={selectedDealId?.toString()}
                onValueChange={handleSelectDeal}
                disabled={loading}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select a fund..." />
                </SelectTrigger>
                <SelectContent>
                  {deals.map(deal => (
                    <SelectItem key={deal.id} value={deal.id.toString()}>
                      {deal.name} {deal.short_name ? `(${deal.short_name})` : ''}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="flex gap-2">
              <Button
                variant="outline"
                size="sm"
                onClick={handleImport}
                disabled={loading}
              >
                <Upload className="w-4 h-4 mr-2" />
                Import
              </Button>
              <Button
                variant="outline"
                size="sm"
                onClick={handleAdd}
                disabled={loading}
              >
                <Plus className="w-4 h-4 mr-2" />
                Add
              </Button>
              <Button
                variant="default"
                size="sm"
                onClick={handleSave}
                disabled={!selectedDealId || loading}
              >
                <Save className="w-4 h-4 mr-2" />
                Save
              </Button>
              <Button
                variant="destructive"
                size="sm"
                onClick={handleDelete}
                disabled={!selectedDealId || loading}
              >
                <Trash2 className="w-4 h-4 mr-2" />
                Delete
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Fund Sections (Accordion) */}
      {selectedDealId && (
        <Accordion type="multiple" defaultValue={['info', 'profile', 'fees', 'closings']} className="space-y-4">
          {/* Fund Information */}
          <AccordionItem value="info">
            <Card>
              <AccordionTrigger className="px-6 py-4 hover:no-underline">
                <CardTitle>Fund Information</CardTitle>
              </AccordionTrigger>
              <AccordionContent>
                <CardContent>
                  <div className="text-sm text-muted-foreground">
                    Fund Information section coming soon...
                  </div>
                </CardContent>
              </AccordionContent>
            </Card>
          </AccordionItem>

          {/* Fund Profile */}
          <AccordionItem value="profile">
            <Card>
              <AccordionTrigger className="px-6 py-4 hover:no-underline">
                <CardTitle>Fund Profile</CardTitle>
              </AccordionTrigger>
              <AccordionContent>
                <CardContent>
                  <div className="text-sm text-muted-foreground">
                    Fund Profile section coming soon...
                  </div>
                </CardContent>
              </AccordionContent>
            </Card>
          </AccordionItem>

          {/* Fees Earned */}
          <AccordionItem value="fees">
            <Card>
              <AccordionTrigger className="px-6 py-4 hover:no-underline">
                <CardTitle>Fees Earned</CardTitle>
              </AccordionTrigger>
              <AccordionContent>
                <CardContent>
                  <div className="text-sm text-muted-foreground">
                    Fees Earned section coming soon...
                  </div>
                </CardContent>
              </AccordionContent>
            </Card>
          </AccordionItem>

          {/* Fund Closings */}
          <AccordionItem value="closings">
            <Card>
              <AccordionTrigger className="px-6 py-4 hover:no-underline">
                <CardTitle>Fund Closings</CardTitle>
              </AccordionTrigger>
              <AccordionContent>
                <CardContent>
                  <div className="text-sm text-muted-foreground">
                    Fund Closings grid coming soon...
                  </div>
                </CardContent>
              </AccordionContent>
            </Card>
          </AccordionItem>
        </Accordion>
      )}

      {/* Empty State */}
      {!selectedDealId && (
        <Card>
          <CardContent className="py-12">
            <div className="text-center text-muted-foreground">
              <p className="text-lg font-medium">No Fund Selected</p>
              <p className="text-sm mt-1">
                Select a fund from the dropdown above to view and edit its details
              </p>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
