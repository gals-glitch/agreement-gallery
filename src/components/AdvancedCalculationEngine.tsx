import React, { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Separator } from "@/components/ui/separator";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { 
  Calculator,
  TrendingUp,
  DollarSign,
  Percent,
  Layers,
  Clock,
  AlertTriangle,
  CheckCircle,
  RotateCcw,
  Download,
  Eye,
  Settings,
  Globe,
  Receipt,
  Coins
} from "lucide-react";
import { useToast } from "@/hooks/use-toast";

interface WaterfallConfig {
  id: string;
  name: string;
  type: "DEAL_BY_DEAL" | "WHOLE_OF_FUND";
  preferredReturn: number;
  catchUpRate: number;
  gpCarry: number;
  lpShare: number;
  hurdles: Array<{
    threshold: number;
    gpShare: number;
    lpShare: number;
  }>;
}

interface FeeCalculationRule {
  id: string;
  name: string;
  basis: "COMMITTED_CAPITAL" | "INVESTED_CAPITAL" | "NAV" | "DISTRIBUTIONS";
  baseRate: number;
  stepDowns: Array<{
    afterYear: number;
    rate: number;
  }>;
  prorationRules: {
    partialPeriods: boolean;
    dailyProration: boolean;
    minimumFee?: number;
  };
}

interface CurrencyConfig {
  baseCurrency: "USD" | "EUR" | "GBP" | "ILS";
  sourceCurrencies: string[];
  fxRateSource: "BLOOMBERG" | "REUTERS" | "ECB" | "MANUAL";
  rateDate: "TRADE_DATE" | "SETTLEMENT_DATE" | "QUARTER_END";
  roundingPolicy: "STANDARD" | "BANKERS" | "UP" | "DOWN";
  roundingPrecision: number;
}

interface TaxConfig {
  vatRate: number;
  vatApplicable: boolean;
  withholdingTax: number;
  grossUpRules: boolean;
  taxFormRequirements: Array<{
    jurisdiction: string;
    formType: "W8" | "W9" | "TAX_CERT";
    required: boolean;
  }>;
}

interface ClawbackProvision {
  id: string;
  name: string;
  conditions: string[];
  percentageClawback: number;
  triggerThreshold: number;
  lookbackPeriod: number; // months
  priority: "SENIOR" | "JUNIOR" | "PARI_PASSU";
}

const MOCK_WATERFALL_CONFIGS: WaterfallConfig[] = [
  {
    id: "WF-001",
    name: "Standard Real Estate Waterfall",
    type: "DEAL_BY_DEAL",
    preferredReturn: 0.08,
    catchUpRate: 0.08,
    gpCarry: 0.20,
    lpShare: 0.80,
    hurdles: [
      { threshold: 1.0, gpShare: 0.20, lpShare: 0.80 },
      { threshold: 1.25, gpShare: 0.25, lpShare: 0.75 },
      { threshold: 1.5, gpShare: 0.30, lpShare: 0.70 }
    ]
  },
  {
    id: "WF-002", 
    name: "Private Equity Fund Waterfall",
    type: "WHOLE_OF_FUND",
    preferredReturn: 0.06,
    catchUpRate: 0.06,
    gpCarry: 0.20,
    lpShare: 0.80,
    hurdles: [
      { threshold: 1.0, gpShare: 0.20, lpShare: 0.80 }
    ]
  }
];

const MOCK_FEE_RULES: FeeCalculationRule[] = [
  {
    id: "FEE-001",
    name: "Standard Management Fee",
    basis: "COMMITTED_CAPITAL",
    baseRate: 0.02,
    stepDowns: [
      { afterYear: 5, rate: 0.015 },
      { afterYear: 8, rate: 0.01 }
    ],
    prorationRules: {
      partialPeriods: true,
      dailyProration: true,
      minimumFee: 10000
    }
  },
  {
    id: "FEE-002",
    name: "Invested Capital Fee",
    basis: "INVESTED_CAPITAL", 
    baseRate: 0.015,
    stepDowns: [
      { afterYear: 3, rate: 0.01 }
    ],
    prorationRules: {
      partialPeriods: true,
      dailyProration: false
    }
  }
];

const MOCK_CLAWBACKS: ClawbackProvision[] = [
  {
    id: "CB-001",
    name: "Promote Reversal Clawback",
    conditions: [
      "Fund IRR falls below preferred return",
      "Distributions reverse due to impairments"
    ],
    percentageClawback: 0.5,
    triggerThreshold: -0.02,
    lookbackPeriod: 12,
    priority: "SENIOR"
  }
];

export function AdvancedCalculationEngine() {
  const [selectedConfig, setSelectedConfig] = useState<"waterfall" | "fees" | "currency" | "tax" | "clawbacks">("waterfall");
  const [calculationRunning, setCalculationRunning] = useState(false);
  const [calculationResults, setCalculationResults] = useState<any>(null);
  const [newConfigDialogOpen, setNewConfigDialogOpen] = useState(false);
  const { toast } = useToast();

  const runAdvancedCalculation = async () => {
    setCalculationRunning(true);
    
    toast({
      title: "Advanced calculation started",
      description: "Running waterfall, fee, and tax calculations with multi-currency support...",
    });

    // Simulate complex calculation
    await new Promise(resolve => setTimeout(resolve, 5000));

    const mockResults = {
      grossFees: 245000,
      vatAmount: 49000,
      withholdingTax: 12250,
      netPayable: 183750,
      currencyBreakdown: {
        USD: 150000,
        EUR: 75000,
        GBP: 20000
      },
      clawbacksApplied: 15000,
      calculations: 87,
      exceptions: 3
    };

    setCalculationResults(mockResults);
    setCalculationRunning(false);
    
    toast({
      title: "Calculation complete",
      description: `Processed ${mockResults.calculations} calculations with ${mockResults.exceptions} exceptions.`,
    });
  };

  const exportCalculationDetails = () => {
    toast({
      title: "Export started",
      description: "Generating detailed calculation breakdown with drill-down explanations...",
    });
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Calculator className="w-5 h-5" />
            Advanced Calculation Engine
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex gap-3">
            <Button 
              onClick={runAdvancedCalculation}
              disabled={calculationRunning}
              className="gap-2"
            >
              {calculationRunning ? (
                <>
                  <RotateCcw className="w-4 h-4 animate-spin" />
                  Calculating...
                </>
              ) : (
                <>
                  <Calculator className="w-4 h-4" />
                  Run Advanced Calculation
                </>
              )}
            </Button>
            
            {calculationResults && (
              <Button variant="outline" onClick={exportCalculationDetails} className="gap-2">
                <Download className="w-4 h-4" />
                Export Details
              </Button>
            )}
            
            <Dialog open={newConfigDialogOpen} onOpenChange={setNewConfigDialogOpen}>
              <DialogTrigger asChild>
                <Button variant="outline" className="gap-2">
                  <Settings className="w-4 h-4" />
                  Configure Rules
                </Button>
              </DialogTrigger>
              <DialogContent className="sm:max-w-2xl">
                <DialogHeader>
                  <DialogTitle>Configure Calculation Rules</DialogTitle>
                  <DialogDescription>
                    Set up waterfall mechanics, fee structures, and tax configurations.
                  </DialogDescription>
                </DialogHeader>
                
                <div className="space-y-4">
                  <div>
                    <Label>Configuration Type</Label>
                    <Select>
                      <SelectTrigger>
                        <SelectValue placeholder="Select configuration type" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="waterfall">Waterfall Structure</SelectItem>
                        <SelectItem value="fee">Fee Calculation Rule</SelectItem>
                        <SelectItem value="currency">Currency & FX Settings</SelectItem>
                        <SelectItem value="tax">Tax Configuration</SelectItem>
                        <SelectItem value="clawback">Clawback Provision</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  
                  <div className="flex gap-3">
                    <Button className="flex-1">Create Configuration</Button>
                    <Button variant="outline" onClick={() => setNewConfigDialogOpen(false)}>
                      Cancel
                    </Button>
                  </div>
                </div>
              </DialogContent>
            </Dialog>
          </div>
        </CardContent>
      </Card>

      {/* Results Summary */}
      {calculationResults && (
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <Card className="border-green-200 bg-green-50">
            <CardContent className="p-4">
              <div className="flex items-center gap-2">
                <DollarSign className="w-4 h-4 text-green-600" />
                <div className="text-sm text-green-700">Gross Fees</div>
              </div>
              <div className="text-2xl font-bold text-green-600">
                ${calculationResults.grossFees.toLocaleString()}
              </div>
            </CardContent>
          </Card>

          <Card className="border-orange-200 bg-orange-50">
            <CardContent className="p-4">
              <div className="flex items-center gap-2">
                <Receipt className="w-4 h-4 text-orange-600" />
                <div className="text-sm text-orange-700">VAT & Tax</div>
              </div>
              <div className="text-2xl font-bold text-orange-600">
                ${(calculationResults.vatAmount + calculationResults.withholdingTax).toLocaleString()}
              </div>
            </CardContent>
          </Card>

          <Card className="border-blue-200 bg-blue-50">
            <CardContent className="p-4">
              <div className="flex items-center gap-2">
                <TrendingUp className="w-4 h-4 text-blue-600" />
                <div className="text-sm text-blue-700">Net Payable</div>
              </div>
              <div className="text-2xl font-bold text-blue-600">
                ${calculationResults.netPayable.toLocaleString()}
              </div>
            </CardContent>
          </Card>

          <Card className="border-red-200 bg-red-50">
            <CardContent className="p-4">
              <div className="flex items-center gap-2">
                <AlertTriangle className="w-4 h-4 text-red-600" />
                <div className="text-sm text-red-700">Clawbacks</div>
              </div>
              <div className="text-2xl font-bold text-red-600">
                ${calculationResults.clawbacksApplied.toLocaleString()}
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Configuration Tabs */}
      <Card>
        <CardHeader>
          <CardTitle>Calculation Configurations</CardTitle>
        </CardHeader>
        <CardContent>
          <Tabs value={selectedConfig} onValueChange={(value: any) => setSelectedConfig(value)}>
            <TabsList className="grid w-full grid-cols-5">
              <TabsTrigger value="waterfall">Waterfall</TabsTrigger>
              <TabsTrigger value="fees">Fee Rules</TabsTrigger>
              <TabsTrigger value="currency">Currency</TabsTrigger>
              <TabsTrigger value="tax">Tax</TabsTrigger>
              <TabsTrigger value="clawbacks">Clawbacks</TabsTrigger>
            </TabsList>

            <TabsContent value="waterfall" className="space-y-4">
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <h3 className="text-lg font-medium">Waterfall Structures</h3>
                  <Button variant="outline" size="sm" className="gap-2">
                    <Layers className="w-4 h-4" />
                    Add Waterfall
                  </Button>
                </div>
                
                {MOCK_WATERFALL_CONFIGS.map((config) => (
                  <Card key={config.id} className="border">
                    <CardContent className="p-4">
                      <div className="flex items-start justify-between">
                        <div className="space-y-2">
                          <div className="flex items-center gap-2">
                            <span className="font-medium">{config.name}</span>
                            <Badge variant="outline">{config.type}</Badge>
                          </div>
                          
                          <div className="grid grid-cols-2 gap-4 text-sm">
                            <div>
                              <span className="text-muted-foreground">Preferred Return:</span>
                              <span className="ml-2">{(config.preferredReturn * 100)}%</span>
                            </div>
                            <div>
                              <span className="text-muted-foreground">GP Carry:</span>
                              <span className="ml-2">{(config.gpCarry * 100)}%</span>
                            </div>
                            <div>
                              <span className="text-muted-foreground">Catch-up Rate:</span>
                              <span className="ml-2">{(config.catchUpRate * 100)}%</span>
                            </div>
                            <div>
                              <span className="text-muted-foreground">Hurdles:</span>
                              <span className="ml-2">{config.hurdles.length} defined</span>
                            </div>
                          </div>
                          
                          <div className="text-xs text-muted-foreground">
                            <div className="font-medium mb-1">Hurdle Structure:</div>
                            {config.hurdles.map((hurdle, index) => (
                              <div key={index}>
                                {hurdle.threshold}x: GP {(hurdle.gpShare * 100)}% / LP {(hurdle.lpShare * 100)}%
                              </div>
                            ))}
                          </div>
                        </div>
                        
                        <div className="flex gap-2">
                          <Button variant="outline" size="sm" className="gap-1">
                            <Eye className="w-3 h-3" />
                            View
                          </Button>
                          <Button variant="outline" size="sm" className="gap-1">
                            <Settings className="w-3 h-3" />
                            Edit
                          </Button>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            </TabsContent>

            <TabsContent value="fees" className="space-y-4">
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <h3 className="text-lg font-medium">Fee Calculation Rules</h3>
                  <Button variant="outline" size="sm" className="gap-2">
                    <Percent className="w-4 h-4" />
                    Add Fee Rule
                  </Button>
                </div>
                
                {MOCK_FEE_RULES.map((rule) => (
                  <Card key={rule.id} className="border">
                    <CardContent className="p-4">
                      <div className="flex items-start justify-between">
                        <div className="space-y-2">
                          <div className="flex items-center gap-2">
                            <span className="font-medium">{rule.name}</span>
                            <Badge variant="outline">{rule.basis}</Badge>
                          </div>
                          
                          <div className="grid grid-cols-2 gap-4 text-sm">
                            <div>
                              <span className="text-muted-foreground">Base Rate:</span>
                              <span className="ml-2">{(rule.baseRate * 100)}%</span>
                            </div>
                            <div>
                              <span className="text-muted-foreground">Step-downs:</span>
                              <span className="ml-2">{rule.stepDowns.length} defined</span>
                            </div>
                            <div>
                              <span className="text-muted-foreground">Proration:</span>
                              <span className="ml-2">{rule.prorationRules.partialPeriods ? "Enabled" : "Disabled"}</span>
                            </div>
                            {rule.prorationRules.minimumFee && (
                              <div>
                                <span className="text-muted-foreground">Min Fee:</span>
                                <span className="ml-2">${rule.prorationRules.minimumFee.toLocaleString()}</span>
                              </div>
                            )}
                          </div>
                          
                          {rule.stepDowns.length > 0 && (
                            <div className="text-xs text-muted-foreground">
                              <div className="font-medium mb-1">Step-down Schedule:</div>
                              {rule.stepDowns.map((stepDown, index) => (
                                <div key={index}>
                                  After Year {stepDown.afterYear}: {(stepDown.rate * 100)}%
                                </div>
                              ))}
                            </div>
                          )}
                        </div>
                        
                        <div className="flex gap-2">
                          <Button variant="outline" size="sm" className="gap-1">
                            <Eye className="w-3 h-3" />
                            View
                          </Button>
                          <Button variant="outline" size="sm" className="gap-1">
                            <Settings className="w-3 h-3" />
                            Edit
                          </Button>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            </TabsContent>

            <TabsContent value="currency" className="space-y-4">
              <Card className="border">
                <CardContent className="p-4">
                  <div className="space-y-4">
                    <h3 className="text-lg font-medium">Multi-Currency Configuration</h3>
                    
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <Label>Base Currency</Label>
                        <Select defaultValue="USD">
                          <SelectTrigger>
                            <SelectValue />
                          </SelectTrigger>
                          <SelectContent>
                            <SelectItem value="USD">USD - US Dollar</SelectItem>
                            <SelectItem value="EUR">EUR - Euro</SelectItem>
                            <SelectItem value="GBP">GBP - British Pound</SelectItem>
                            <SelectItem value="ILS">ILS - Israeli Shekel</SelectItem>
                          </SelectContent>
                        </Select>
                      </div>
                      
                      <div>
                        <Label>FX Rate Source</Label>
                        <Select defaultValue="BLOOMBERG">
                          <SelectTrigger>
                            <SelectValue />
                          </SelectTrigger>
                          <SelectContent>
                            <SelectItem value="BLOOMBERG">Bloomberg</SelectItem>
                            <SelectItem value="REUTERS">Reuters</SelectItem>
                            <SelectItem value="ECB">European Central Bank</SelectItem>
                            <SelectItem value="MANUAL">Manual Entry</SelectItem>
                          </SelectContent>
                        </Select>
                      </div>
                      
                      <div>
                        <Label>Rate Date</Label>
                        <Select defaultValue="QUARTER_END">
                          <SelectTrigger>
                            <SelectValue />
                          </SelectTrigger>
                          <SelectContent>
                            <SelectItem value="TRADE_DATE">Trade Date</SelectItem>
                            <SelectItem value="SETTLEMENT_DATE">Settlement Date</SelectItem>
                            <SelectItem value="QUARTER_END">Quarter End</SelectItem>
                          </SelectContent>
                        </Select>
                      </div>
                      
                      <div>
                        <Label>Rounding Policy</Label>
                        <Select defaultValue="STANDARD">
                          <SelectTrigger>
                            <SelectValue />
                          </SelectTrigger>
                          <SelectContent>
                            <SelectItem value="STANDARD">Standard</SelectItem>
                            <SelectItem value="BANKERS">Bankers Rounding</SelectItem>
                            <SelectItem value="UP">Round Up</SelectItem>
                            <SelectItem value="DOWN">Round Down</SelectItem>
                          </SelectContent>
                        </Select>
                      </div>
                    </div>
                    
                    <div>
                      <Label>Rounding Precision (Decimal Places)</Label>
                      <Input type="number" defaultValue="2" min="0" max="6" />
                    </div>
                  </div>
                </CardContent>
              </Card>
              
              {calculationResults && (
                <Card className="border">
                  <CardHeader>
                    <CardTitle className="text-sm">Current Calculation Currency Breakdown</CardTitle>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-2">
                      {Object.entries(calculationResults.currencyBreakdown).map(([currency, amount]) => (
                        <div key={currency} className="flex justify-between">
                          <span className="text-muted-foreground">{currency}:</span>
                          <span className="font-medium">{currency === "USD" ? "$" : currency} {(amount as number).toLocaleString()}</span>
                        </div>
                      ))}
                    </div>
                  </CardContent>
                </Card>
              )}
            </TabsContent>

            <TabsContent value="tax" className="space-y-4">
              <Card className="border">
                <CardContent className="p-4">
                  <div className="space-y-4">
                    <h3 className="text-lg font-medium">Tax Configuration</h3>
                    
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <Label>VAT Rate (%)</Label>
                        <Input type="number" defaultValue="20" step="0.1" />
                      </div>
                      
                      <div>
                        <Label>Withholding Tax Rate (%)</Label>
                        <Input type="number" defaultValue="5" step="0.1" />
                      </div>
                      
                      <div className="flex items-center space-x-2">
                        <input type="checkbox" id="vat-applicable" defaultChecked />
                        <Label htmlFor="vat-applicable">VAT Applicable</Label>
                      </div>
                      
                      <div className="flex items-center space-x-2">
                        <input type="checkbox" id="gross-up" />
                        <Label htmlFor="gross-up">Gross-up Rules</Label>
                      </div>
                    </div>
                    
                    <div>
                      <Label>Tax Form Requirements</Label>
                      <div className="space-y-2 mt-2">
                        <div className="flex items-center justify-between p-2 border rounded">
                          <span className="text-sm">US Entities - W-9 Form</span>
                          <Badge variant="default">Required</Badge>
                        </div>
                        <div className="flex items-center justify-between p-2 border rounded">
                          <span className="text-sm">Non-US Entities - W-8 Form</span>
                          <Badge variant="default">Required</Badge>
                        </div>
                        <div className="flex items-center justify-between p-2 border rounded">
                          <span className="text-sm">Israeli Entities - Tax Certificate</span>
                          <Badge variant="secondary">Optional</Badge>
                        </div>
                      </div>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="clawbacks" className="space-y-4">
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <h3 className="text-lg font-medium">Clawback Provisions</h3>
                  <Button variant="outline" size="sm" className="gap-2">
                    <RotateCcw className="w-4 h-4" />
                    Add Clawback
                  </Button>
                </div>
                
                {MOCK_CLAWBACKS.map((clawback) => (
                  <Card key={clawback.id} className="border">
                    <CardContent className="p-4">
                      <div className="flex items-start justify-between">
                        <div className="space-y-2">
                          <div className="flex items-center gap-2">
                            <span className="font-medium">{clawback.name}</span>
                            <Badge variant="outline">{clawback.priority}</Badge>
                          </div>
                          
                          <div className="grid grid-cols-2 gap-4 text-sm">
                            <div>
                              <span className="text-muted-foreground">Clawback %:</span>
                              <span className="ml-2">{(clawback.percentageClawback * 100)}%</span>
                            </div>
                            <div>
                              <span className="text-muted-foreground">Trigger Threshold:</span>
                              <span className="ml-2">{(clawback.triggerThreshold * 100)}%</span>
                            </div>
                            <div>
                              <span className="text-muted-foreground">Lookback Period:</span>
                              <span className="ml-2">{clawback.lookbackPeriod} months</span>
                            </div>
                            <div>
                              <span className="text-muted-foreground">Conditions:</span>
                              <span className="ml-2">{clawback.conditions.length} defined</span>
                            </div>
                          </div>
                          
                          <div className="text-xs text-muted-foreground">
                            <div className="font-medium mb-1">Trigger Conditions:</div>
                            {clawback.conditions.map((condition, index) => (
                              <div key={index} className="flex items-start gap-1">
                                <span>•</span>
                                <span>{condition}</span>
                              </div>
                            ))}
                          </div>
                        </div>
                        
                        <div className="flex gap-2">
                          <Button variant="outline" size="sm" className="gap-1">
                            <Eye className="w-3 h-3" />
                            View
                          </Button>
                          <Button variant="outline" size="sm" className="gap-1">
                            <Settings className="w-3 h-3" />
                            Edit
                          </Button>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            </TabsContent>
          </Tabs>
        </CardContent>
      </Card>
    </div>
  );
}