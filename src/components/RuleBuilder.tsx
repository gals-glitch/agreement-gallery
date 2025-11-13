import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Textarea } from '@/components/ui/textarea';
import { Switch } from '@/components/ui/switch';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Separator } from '@/components/ui/separator';
import { ScrollArea } from '@/components/ui/scroll-area';
import { useAdvancedCommissionCalculations } from '@/hooks/useAdvancedCommissionCalculations';
import { useToast } from '@/hooks/use-toast';
import { RuleType, EntityType, ConditionOperator, CalculationBasis } from '@/types/calculationEngine';
import {
  Plus,
  Trash2,
  Settings,
  Zap,
  Calculator,
  TrendingUp,
  AlertCircle,
  CheckCircle,
  X
} from 'lucide-react';

interface TierConfig {
  min_threshold: number;
  max_threshold?: number;
  rate: number;
  fixed_amount?: number;
  description?: string;
}

interface ConditionConfig {
  condition_group: number;
  field_name: string;
  operator: ConditionOperator;
  value: any;
  is_required: boolean;
}

interface AdditionalAgreement {
  id: string;
  name: string;
  percentage: number;
  minAmount: number;
  maxAmount?: number;
  conditions: string;
  effectiveDate: string;
  expiryDate: string;
  priority?: number;
}

export function RuleBuilder() {
  const [ruleName, setRuleName] = useState('');
  const [description, setDescription] = useState('');
  const [ruleType, setRuleType] = useState<RuleType>('percentage');
  const [entityType, setEntityType] = useState<EntityType>('distributor');
  const [entityName, setEntityName] = useState('');
  const [fundName, setFundName] = useState('');
  const [baseRate, setBaseRate] = useState<number>(0);
  const [fixedAmount, setFixedAmount] = useState<number>(0);
  const [minAmount, setMinAmount] = useState<number>(0);
  const [maxAmount, setMaxAmount] = useState<number | undefined>();
  const [calculationBasis, setCalculationBasis] = useState<CalculationBasis>('distribution_amount');
  const [priority, setPriority] = useState<number>(100);
  const [requiresApproval, setRequiresApproval] = useState(false);
  
  // Tiers for tiered rules
  const [tiers, setTiers] = useState<TierConfig[]>([
    { min_threshold: 0, max_threshold: 100000, rate: 0.01, description: 'Tier 1: 0-100K' }
  ]);
  
  // Conditions for conditional rules
  const [conditions, setConditions] = useState<ConditionConfig[]>([]);
  
  // Additional agreements for multiple percentage configurations
  const [additionalAgreements, setAdditionalAgreements] = useState<Record<string, AdditionalAgreement>>({});
  
  const { createCommissionRule, commissionRules } = useAdvancedCommissionCalculations();
  const { toast } = useToast();

  const addTier = () => {
    const lastTier = tiers[tiers.length - 1];
    const newMinThreshold = lastTier?.max_threshold || 0;
    
    setTiers([...tiers, {
      min_threshold: newMinThreshold,
      max_threshold: newMinThreshold + 100000,
      rate: 0.01,
      description: `Tier ${tiers.length + 1}`
    }]);
  };

  const removeTier = (index: number) => {
    if (tiers.length > 1) {
      setTiers(tiers.filter((_, i) => i !== index));
    }
  };

  const updateTier = (index: number, field: keyof TierConfig, value: any) => {
    const newTiers = [...tiers];
    newTiers[index] = { ...newTiers[index], [field]: value };
    setTiers(newTiers);
  };

  const addCondition = () => {
    setConditions([...conditions, {
      condition_group: 1,
      field_name: 'distribution_amount',
      operator: 'greater_than',
      value: 0,
      is_required: true
    }]);
  };

  const removeCondition = (index: number) => {
    setConditions(conditions.filter((_, i) => i !== index));
  };

  const updateCondition = (index: number, field: keyof ConditionConfig, value: any) => {
    const newConditions = [...conditions];
    newConditions[index] = { ...newConditions[index], [field]: value };
    setConditions(newConditions);
  };

  const handleSubmit = async () => {
    try {
      if (!ruleName || !entityType || !ruleType) {
        toast({
          title: "Validation Error",
          description: "Please fill in all required fields.",
          variant: "destructive",
        });
        return;
      }

      const ruleData = {
        name: ruleName,
        description: description || undefined,
        rule_type: ruleType,
        entity_type: entityType,
        entity_name: entityName || undefined,
        fund_name: fundName || undefined,
        base_rate: ruleType === 'percentage' || ruleType === 'hybrid' ? baseRate / 100 : undefined,
        fixed_amount: ruleType === 'fixed_amount' || ruleType === 'hybrid' ? fixedAmount : undefined,
        min_amount: minAmount,
        max_amount: maxAmount,
        calculation_basis: calculationBasis,
        priority,
        is_active: true,
        requires_approval: requiresApproval
      };

      const result = await createCommissionRule(ruleData);
      
      // Create tiers if it's a tiered rule
      if (ruleType === 'tiered' && result?.id) {
        // TODO: Implement tier creation via separate API call
        console.log('Tiers to create:', tiers);
      }
      
      // Create conditions if any
      if (conditions.length > 0 && result?.id) {
        // TODO: Implement condition creation via separate API call
        console.log('Conditions to create:', conditions);
      }

      toast({
        title: "Success",
        description: "Commission rule created successfully.",
      });

      // Reset form
      resetForm();

    } catch (error) {
      toast({
        title: "Error",
        description: error instanceof Error ? error.message : "Failed to create rule.",
        variant: "destructive",
      });
    }
  };

  const resetForm = () => {
    setRuleName('');
    setDescription('');
    setRuleType('percentage');
    setEntityType('distributor');
    setEntityName('');
    setFundName('');
    setBaseRate(0);
    setFixedAmount(0);
    setMinAmount(0);
    setMaxAmount(undefined);
    setCalculationBasis('distribution_amount');
    setPriority(100);
    setRequiresApproval(false);
    setTiers([{ min_threshold: 0, max_threshold: 100000, rate: 0.01, description: 'Tier 1: 0-100K' }]);
    setConditions([]);
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold tracking-tight">Advanced Rule Builder</h2>
          <p className="text-muted-foreground">
            Create sophisticated commission calculation rules with conditional logic and tiered structures
          </p>
        </div>
        <Badge variant="secondary" className="gap-2">
          <Zap className="h-3 w-3" />
          {commissionRules.length} Active Rules
        </Badge>
      </div>

      <div className="grid gap-6 lg:grid-cols-3">
        {/* Rule Configuration */}
        <div className="lg:col-span-2 space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Settings className="h-5 w-5" />
                Basic Configuration
              </CardTitle>
              <CardDescription>Define the fundamental properties of your commission rule</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label htmlFor="rule-name">Rule Name *</Label>
                  <Input
                    id="rule-name"
                    value={ruleName}
                    onChange={(e) => setRuleName(e.target.value)}
                    placeholder="e.g., Premium Distributor Rate"
                  />
                </div>
                <div>
                  <Label htmlFor="priority">Priority</Label>
                  <Input
                    id="priority"
                    type="number"
                    value={priority}
                    onChange={(e) => setPriority(Number(e.target.value))}
                    placeholder="100"
                  />
                </div>
              </div>

              <div>
                <Label htmlFor="description">Description</Label>
                <Textarea
                  id="description"
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  placeholder="Describe when and how this rule applies..."
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label htmlFor="rule-type">Rule Type *</Label>
                  <Select value={ruleType} onValueChange={(value: RuleType) => setRuleType(value)}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="percentage">Percentage</SelectItem>
                      <SelectItem value="fixed_amount">Fixed Amount</SelectItem>
                      <SelectItem value="tiered">Tiered Structure</SelectItem>
                      <SelectItem value="hybrid">Hybrid (Fixed + %)</SelectItem>
                      <SelectItem value="conditional">Conditional Logic</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div>
                  <Label htmlFor="entity-type">Entity Type *</Label>
                  <Select value={entityType} onValueChange={(value: EntityType) => setEntityType(value)}>
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
                  <Label htmlFor="entity-name">Entity Name</Label>
                  <Input
                    id="entity-name"
                    value={entityName}
                    onChange={(e) => setEntityName(e.target.value)}
                    placeholder="Leave empty for all entities"
                  />
                </div>
                <div>
                  <Label htmlFor="fund-name">Fund Name</Label>
                  <Input
                    id="fund-name"
                    value={fundName}
                    onChange={(e) => setFundName(e.target.value)}
                    placeholder="Leave empty for all funds"
                  />
                </div>
              </div>

              <div>
                <Label htmlFor="calculation-basis">Calculation Basis</Label>
                <Select value={calculationBasis} onValueChange={(value: CalculationBasis) => setCalculationBasis(value)}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="distribution_amount">Distribution Amount</SelectItem>
                    <SelectItem value="cumulative_amount">Cumulative Amount</SelectItem>
                    <SelectItem value="monthly_volume">Monthly Volume</SelectItem>
                    <SelectItem value="quarterly_volume">Quarterly Volume</SelectItem>
                    <SelectItem value="annual_volume">Annual Volume</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div className="flex items-center space-x-2">
                <Switch
                  id="requires-approval"
                  checked={requiresApproval}
                  onCheckedChange={setRequiresApproval}
                />
                <Label htmlFor="requires-approval">Requires Approval</Label>
              </div>
            </CardContent>
          </Card>

          {/* Rule Type Specific Configuration */}
          <Tabs value={ruleType} className="space-y-4">
            <TabsContent value="percentage" className="space-y-4">
              <Card>
                <CardHeader>
                  <CardTitle>Multiple Agreement Configuration</CardTitle>
                  <CardDescription>
                    Create multiple percentage-based agreements with different rates and conditions
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-6">
                  {/* Primary Agreement */}
                  <div className="border rounded-lg p-4 bg-muted/50">
                    <div className="flex items-center justify-between mb-4">
                      <h4 className="font-medium">Primary Agreement</h4>
                      <Badge variant="default">Main</Badge>
                    </div>
                    <div className="grid grid-cols-3 gap-4">
                      <div>
                        <Label htmlFor="base-rate">Commission Rate (%)</Label>
                        <Input
                          id="base-rate"
                          type="number"
                          step="0.01"
                          value={baseRate}
                          onChange={(e) => setBaseRate(Number(e.target.value))}
                          placeholder="2.5"
                        />
                      </div>
                      <div>
                        <Label htmlFor="min-amount">Minimum Amount</Label>
                        <Input
                          id="min-amount"
                          type="number"
                          value={minAmount}
                          onChange={(e) => setMinAmount(Number(e.target.value))}
                          placeholder="0"
                        />
                      </div>
                      <div>
                        <Label htmlFor="max-amount">Maximum Amount</Label>
                        <Input
                          id="max-amount"
                          type="number"
                          value={maxAmount || ''}
                          onChange={(e) => setMaxAmount(e.target.value ? Number(e.target.value) : undefined)}
                          placeholder="No limit"
                        />
                      </div>
                    </div>
                  </div>

                  {/* Additional Agreements Section */}
                  <div className="space-y-4">
                    <div className="flex items-center justify-between">
                      <div>
                        <h4 className="font-medium">Additional Agreements</h4>
                        <p className="text-sm text-muted-foreground">
                          Add multiple agreements with different percentage rates
                        </p>
                      </div>
                      <Button
                        type="button"
                        variant="outline"
                        size="sm"
                        onClick={() => {
                          const newAgreement = {
                            id: Date.now().toString(),
                            name: `Agreement ${Object.keys(additionalAgreements).length + 1}`,
                            percentage: 1.0,
                            minAmount: 0,
                            maxAmount: undefined,
                            conditions: '',
                            effectiveDate: '',
                            expiryDate: ''
                          };
                          setAdditionalAgreements(prev => ({
                            ...prev,
                            [newAgreement.id]: newAgreement
                          }));
                        }}
                        className="gap-2"
                      >
                        <Plus className="h-4 w-4" />
                        Add Agreement
                      </Button>
                    </div>

                    {/* Dynamic Additional Agreements */}
                    {Object.entries(additionalAgreements).map(([id, agreement]) => (
                      <div key={id} className="border rounded-lg p-4 space-y-4">
                        <div className="flex items-center justify-between">
                          <Input
                            value={agreement.name}
                            onChange={(e) => setAdditionalAgreements(prev => ({
                              ...prev,
                              [id]: { ...agreement, name: e.target.value }
                            }))}
                            placeholder="Agreement name"
                            className="font-medium max-w-xs"
                          />
                          <Button
                            type="button"
                            variant="ghost"
                            size="sm"
                            onClick={() => {
                              setAdditionalAgreements(prev => {
                                const updated = { ...prev };
                                delete updated[id];
                                return updated;
                              });
                            }}
                          >
                            <Trash2 className="h-4 w-4" />
                          </Button>
                        </div>
                        
                        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                          <div>
                            <Label>Percentage (%)</Label>
                            <Input
                              type="number"
                              step="0.01"
                              value={agreement.percentage}
                              onChange={(e) => setAdditionalAgreements(prev => ({
                                ...prev,
                                [id]: { ...agreement, percentage: Number(e.target.value) }
                              }))}
                              placeholder="1.5"
                            />
                          </div>
                          <div>
                            <Label>Min Amount</Label>
                            <Input
                              type="number"
                              value={agreement.minAmount}
                              onChange={(e) => setAdditionalAgreements(prev => ({
                                ...prev,
                                [id]: { ...agreement, minAmount: Number(e.target.value) }
                              }))}
                              placeholder="0"
                            />
                          </div>
                          <div>
                            <Label>Max Amount</Label>
                            <Input
                              type="number"
                              value={agreement.maxAmount || ''}
                              onChange={(e) => setAdditionalAgreements(prev => ({
                                ...prev,
                                [id]: { ...agreement, maxAmount: e.target.value ? Number(e.target.value) : undefined }
                              }))}
                              placeholder="No limit"
                            />
                          </div>
                          <div>
                            <Label>Priority</Label>
                            <Select
                              value={agreement.priority?.toString() || '100'}
                              onValueChange={(value) => setAdditionalAgreements(prev => ({
                                ...prev,
                                [id]: { ...agreement, priority: Number(value) }
                              }))}
                            >
                              <SelectTrigger>
                                <SelectValue />
                              </SelectTrigger>
                              <SelectContent>
                                <SelectItem value="1">High (1)</SelectItem>
                                <SelectItem value="50">Medium (50)</SelectItem>
                                <SelectItem value="100">Normal (100)</SelectItem>
                                <SelectItem value="200">Low (200)</SelectItem>
                              </SelectContent>
                            </Select>
                          </div>
                        </div>

                        <div className="grid grid-cols-2 gap-4">
                          <div>
                            <Label>Effective Date</Label>
                            <Input
                              type="date"
                              value={agreement.effectiveDate}
                              onChange={(e) => setAdditionalAgreements(prev => ({
                                ...prev,
                                [id]: { ...agreement, effectiveDate: e.target.value }
                              }))}
                            />
                          </div>
                          <div>
                            <Label>Expiry Date (Optional)</Label>
                            <Input
                              type="date"
                              value={agreement.expiryDate}
                              onChange={(e) => setAdditionalAgreements(prev => ({
                                ...prev,
                                [id]: { ...agreement, expiryDate: e.target.value }
                              }))}
                            />
                          </div>
                        </div>

                        <div>
                          <Label>Special Conditions</Label>
                          <Textarea
                            value={agreement.conditions}
                            onChange={(e) => setAdditionalAgreements(prev => ({
                              ...prev,
                              [id]: { ...agreement, conditions: e.target.value }
                            }))}
                            placeholder="Describe any special conditions for this agreement..."
                            rows={2}
                          />
                        </div>
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="fixed_amount" className="space-y-4">
              <Card>
                <CardHeader>
                  <CardTitle>Fixed Amount Configuration</CardTitle>
                </CardHeader>
                <CardContent>
                  <div>
                    <Label htmlFor="fixed-amount">Fixed Commission Amount</Label>
                    <Input
                      id="fixed-amount"
                      type="number"
                      value={fixedAmount}
                      onChange={(e) => setFixedAmount(Number(e.target.value))}
                      placeholder="1000"
                    />
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="tiered" className="space-y-4">
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center justify-between">
                    <span>Tiered Structure Configuration</span>
                    <Button onClick={addTier} size="sm" variant="outline" className="gap-2">
                      <Plus className="h-4 w-4" />
                      Add Tier
                    </Button>
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <ScrollArea className="h-64">
                    <div className="space-y-4">
                      {tiers.map((tier, index) => (
                        <div key={index} className="p-4 border rounded-lg space-y-3">
                          <div className="flex items-center justify-between">
                            <h4 className="font-medium">Tier {index + 1}</h4>
                            {tiers.length > 1 && (
                              <Button
                                onClick={() => removeTier(index)}
                                size="sm"
                                variant="ghost"
                                className="text-red-500 hover:text-red-700"
                              >
                                <Trash2 className="h-4 w-4" />
                              </Button>
                            )}
                          </div>
                          <div className="grid grid-cols-2 gap-3">
                            <div>
                              <Label>Min Threshold</Label>
                              <Input
                                type="number"
                                value={tier.min_threshold}
                                onChange={(e) => updateTier(index, 'min_threshold', Number(e.target.value))}
                              />
                            </div>
                            <div>
                              <Label>Max Threshold</Label>
                              <Input
                                type="number"
                                value={tier.max_threshold || ''}
                                onChange={(e) => updateTier(index, 'max_threshold', e.target.value ? Number(e.target.value) : undefined)}
                                placeholder="No limit"
                              />
                            </div>
                          </div>
                          <div className="grid grid-cols-2 gap-3">
                            <div>
                              <Label>Rate (%)</Label>
                              <Input
                                type="number"
                                step="0.01"
                                value={tier.rate * 100}
                                onChange={(e) => updateTier(index, 'rate', Number(e.target.value) / 100)}
                              />
                            </div>
                            <div>
                              <Label>Description</Label>
                              <Input
                                value={tier.description || ''}
                                onChange={(e) => updateTier(index, 'description', e.target.value)}
                                placeholder="Tier description"
                              />
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  </ScrollArea>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="hybrid" className="space-y-4">
              <Card>
                <CardHeader>
                  <CardTitle>Hybrid Configuration (Fixed + Percentage)</CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <Label htmlFor="fixed-part">Fixed Amount</Label>
                      <Input
                        id="fixed-part"
                        type="number"
                        value={fixedAmount}
                        onChange={(e) => setFixedAmount(Number(e.target.value))}
                        placeholder="500"
                      />
                    </div>
                    <div>
                      <Label htmlFor="percentage-part">Percentage (%)</Label>
                      <Input
                        id="percentage-part"
                        type="number"
                        step="0.01"
                        value={baseRate}
                        onChange={(e) => setBaseRate(Number(e.target.value))}
                        placeholder="1.0"
                      />
                    </div>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="conditional" className="space-y-4">
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center justify-between">
                    <span>Conditional Logic</span>
                    <Button onClick={addCondition} size="sm" variant="outline" className="gap-2">
                      <Plus className="h-4 w-4" />
                      Add Condition
                    </Button>
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <ScrollArea className="h-64">
                    <div className="space-y-4">
                      {conditions.map((condition, index) => (
                        <div key={index} className="p-4 border rounded-lg space-y-3">
                          <div className="flex items-center justify-between">
                            <h4 className="font-medium">Condition {index + 1}</h4>
                            <Button
                              onClick={() => removeCondition(index)}
                              size="sm"
                              variant="ghost"
                              className="text-red-500 hover:text-red-700"
                            >
                              <X className="h-4 w-4" />
                            </Button>
                          </div>
                          <div className="grid grid-cols-3 gap-3">
                            <div>
                              <Label>Field</Label>
                              <Select
                                value={condition.field_name}
                                onValueChange={(value) => updateCondition(index, 'field_name', value)}
                              >
                                <SelectTrigger>
                                  <SelectValue />
                                </SelectTrigger>
                                <SelectContent>
                                  <SelectItem value="distribution_amount">Distribution Amount</SelectItem>
                                  <SelectItem value="fund_name">Fund Name</SelectItem>
                                  <SelectItem value="investor_name">Investor Name</SelectItem>
                                  <SelectItem value="cumulative_amount">Cumulative Amount</SelectItem>
                                </SelectContent>
                              </Select>
                            </div>
                            <div>
                              <Label>Operator</Label>
                              <Select
                                value={condition.operator}
                                onValueChange={(value: ConditionOperator) => updateCondition(index, 'operator', value)}
                              >
                                <SelectTrigger>
                                  <SelectValue />
                                </SelectTrigger>
                                <SelectContent>
                                  <SelectItem value="equals">Equals</SelectItem>
                                  <SelectItem value="greater_than">Greater Than</SelectItem>
                                  <SelectItem value="less_than">Less Than</SelectItem>
                                  <SelectItem value="greater_equal">Greater or Equal</SelectItem>
                                  <SelectItem value="less_equal">Less or Equal</SelectItem>
                                  <SelectItem value="between">Between</SelectItem>
                                </SelectContent>
                              </Select>
                            </div>
                            <div>
                              <Label>Value</Label>
                              <Input
                                value={condition.value}
                                onChange={(e) => updateCondition(index, 'value', e.target.value)}
                                placeholder="Enter value"
                              />
                            </div>
                          </div>
                        </div>
                      ))}
                      {conditions.length === 0 && (
                        <div className="text-center text-muted-foreground py-8">
                          No conditions added yet. Click "Add Condition" to create conditional logic.
                        </div>
                      )}
                    </div>
                  </ScrollArea>
                </CardContent>
              </Card>
            </TabsContent>
          </Tabs>
        </div>

        {/* Preview and Actions */}
        <div className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Calculator className="h-5 w-5" />
                Rule Preview
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="space-y-2">
                <div className="flex justify-between text-sm">
                  <span className="text-muted-foreground">Type:</span>
                  <Badge variant="outline">{ruleType}</Badge>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-muted-foreground">Entity:</span>
                  <span>{entityType}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-muted-foreground">Priority:</span>
                  <span>{priority}</span>
                </div>
                {ruleType === 'percentage' && (
                  <div className="flex justify-between text-sm">
                    <span className="text-muted-foreground">Rate:</span>
                    <span>{baseRate}%</span>
                  </div>
                )}
                {ruleType === 'tiered' && (
                  <div className="flex justify-between text-sm">
                    <span className="text-muted-foreground">Tiers:</span>
                    <span>{tiers.length}</span>
                  </div>
                )}
              </div>
              
              <Separator />
              
              <div className="flex items-center gap-2 text-sm">
                {requiresApproval ? (
                  <>
                    <AlertCircle className="h-4 w-4 text-yellow-500" />
                    <span>Requires Approval</span>
                  </>
                ) : (
                  <>
                    <CheckCircle className="h-4 w-4 text-green-500" />
                    <span>Auto-Approve</span>
                  </>
                )}
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Actions</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <Button onClick={handleSubmit} className="w-full gap-2">
                <Plus className="h-4 w-4" />
                Create Rule
              </Button>
              <Button onClick={resetForm} variant="outline" className="w-full">
                Reset Form
              </Button>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <TrendingUp className="h-5 w-5" />
                Existing Rules
              </CardTitle>
            </CardHeader>
            <CardContent>
              <ScrollArea className="h-32">
                <div className="space-y-2">
                  {commissionRules.map((rule) => (
                    <div key={rule.id} className="text-sm p-2 border rounded">
                      <p className="font-medium">{rule.name}</p>
                      <p className="text-muted-foreground">{rule.entity_type} • {rule.rule_type}</p>
                    </div>
                  ))}
                  {commissionRules.length === 0 && (
                    <p className="text-muted-foreground text-center py-4">No rules created yet</p>
                  )}
                </div>
              </ScrollArea>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}