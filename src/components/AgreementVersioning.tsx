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
import { 
  GitBranch, 
  Clock, 
  User, 
  FileText, 
  Eye, 
  Download,
  AlertTriangle,
  CheckCircle,
  Edit3,
  Archive,
  Calendar
} from "lucide-react";
import { useToast } from "@/hooks/use-toast";

interface AgreementVersion {
  id: string;
  agreementId: string;
  version: string;
  status: "Draft" | "Active" | "Superseded" | "Archived";
  effectiveDate: string;
  createdBy: string;
  createdAt: string;
  approvedBy?: string;
  approvedAt?: string;
  changeReason: string;
  sideLetterTerms: {
    caps?: { amount: number; currency: string };
    floors?: { amount: number; currency: string };
    tiers?: Array<{ min: number; max?: number; rate: number }>;
    sunsets?: { date: string; conditions: string };
    clawbacks?: { conditions: string; percentage: number };
    eligibilityStart?: string;
    eligibilityEnd?: string;
    terminationConditions?: string;
    multiReferrerRules?: {
      type: "proportional" | "priority";
      rules: Array<{ referrerId: string; share: number; priority?: number }>;
    };
  };
}

interface EligibilityLifecycle {
  agreementId: string;
  startDate: string;
  endDate?: string;
  terminationConditions: string[];
  minimumHoldTime?: number; // months
  earlyRedemptionPenalty?: number;
  status: "Active" | "Terminated" | "Suspended";
}

const MOCK_VERSIONS: AgreementVersion[] = [
  {
    id: "V-001",
    agreementId: "AG-101",
    version: "1.3",
    status: "Active",
    effectiveDate: "2024-01-01",
    createdBy: "Sarah Johnson",
    createdAt: "2023-12-15T10:30:00Z",
    approvedBy: "Michael Chen",
    approvedAt: "2023-12-20T14:45:00Z",
    changeReason: "Added clawback provisions and updated tier structure",
    sideLetterTerms: {
      caps: { amount: 1000000, currency: "USD" },
      tiers: [
        { min: 0, max: 500000, rate: 0.015 },
        { min: 500000, max: 1000000, rate: 0.012 },
        { min: 1000000, rate: 0.01 }
      ],
      clawbacks: { conditions: "If promote reverses below preferred return", percentage: 0.5 },
      multiReferrerRules: {
        type: "proportional",
        rules: [
          { referrerId: "REF-001", share: 0.6 },
          { referrerId: "REF-002", share: 0.4 }
        ]
      }
    }
  },
  {
    id: "V-002",
    agreementId: "AG-101", 
    version: "1.2",
    status: "Superseded",
    effectiveDate: "2023-06-01",
    createdBy: "David Wilson",
    createdAt: "2023-05-20T09:15:00Z",
    approvedBy: "Michael Chen",
    approvedAt: "2023-05-25T16:30:00Z",
    changeReason: "Updated fee basis calculation methodology",
    sideLetterTerms: {
      caps: { amount: 800000, currency: "USD" },
      tiers: [
        { min: 0, max: 500000, rate: 0.02 },
        { min: 500000, rate: 0.015 }
      ]
    }
  }
];

const MOCK_ELIGIBILITY: EligibilityLifecycle[] = [
  {
    agreementId: "AG-101",
    startDate: "2024-01-01",
    terminationConditions: [
      "Investor redeems before minimum hold period",
      "Material breach of investment terms",
      "Fund termination or liquidation"
    ],
    minimumHoldTime: 24,
    earlyRedemptionPenalty: 0.02,
    status: "Active"
  }
];

export function AgreementVersioning() {
  const [selectedVersion, setSelectedVersion] = useState<AgreementVersion | null>(null);
  const [newVersionDialogOpen, setNewVersionDialogOpen] = useState(false);
  const [newVersionForm, setNewVersionForm] = useState({
    changeReason: "",
    effectiveDate: "",
    sideLetterTerms: ""
  });
  const { toast } = useToast();

  const handleCreateNewVersion = async () => {
    if (!newVersionForm.changeReason || !newVersionForm.effectiveDate) {
      toast({
        title: "Missing required fields",
        description: "Please provide change reason and effective date.",
        variant: "destructive"
      });
      return;
    }

    // Simulate version creation
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    toast({
      title: "New version created",
      description: "Agreement version 1.4 created and pending approval.",
    });
    
    setNewVersionDialogOpen(false);
    setNewVersionForm({ changeReason: "", effectiveDate: "", sideLetterTerms: "" });
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <GitBranch className="w-5 h-5" />
            Agreement Versioning & Governance
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex gap-3">
            <Dialog open={newVersionDialogOpen} onOpenChange={setNewVersionDialogOpen}>
              <DialogTrigger asChild>
                <Button className="gap-2">
                  <Edit3 className="w-4 h-4" />
                  Create New Version
                </Button>
              </DialogTrigger>
              <DialogContent className="sm:max-w-2xl">
                <DialogHeader>
                  <DialogTitle>Create Agreement Version</DialogTitle>
                  <DialogDescription>
                    Create a new version with immutable audit trail and structured side letter terms.
                  </DialogDescription>
                </DialogHeader>
                
                <div className="space-y-4">
                  <div>
                    <Label htmlFor="change-reason">Change Reason *</Label>
                    <Textarea
                      id="change-reason"
                      value={newVersionForm.changeReason}
                      onChange={(e) => setNewVersionForm(prev => ({ ...prev, changeReason: e.target.value }))}
                      placeholder="Describe the reason for this version change..."
                    />
                  </div>
                  
                  <div>
                    <Label htmlFor="effective-date">Effective Date *</Label>
                    <Input
                      id="effective-date"
                      type="date"
                      value={newVersionForm.effectiveDate}
                      onChange={(e) => setNewVersionForm(prev => ({ ...prev, effectiveDate: e.target.value }))}
                    />
                  </div>
                  
                  <div>
                    <Label htmlFor="side-letter">Structured Side Letter Terms (JSON)</Label>
                    <Textarea
                      id="side-letter"
                      value={newVersionForm.sideLetterTerms}
                      onChange={(e) => setNewVersionForm(prev => ({ ...prev, sideLetterTerms: e.target.value }))}
                      placeholder='{"caps": {"amount": 1000000, "currency": "USD"}, "tiers": [{"min": 0, "max": 500000, "rate": 0.015}]}'
                      className="font-mono text-sm"
                      rows={6}
                    />
                  </div>
                  
                  <div className="flex gap-3">
                    <Button onClick={handleCreateNewVersion} className="flex-1">
                      Create Version
                    </Button>
                    <Button variant="outline" onClick={() => setNewVersionDialogOpen(false)}>
                      Cancel
                    </Button>
                  </div>
                </div>
              </DialogContent>
            </Dialog>
            
            <Button variant="outline" className="gap-2">
              <Archive className="w-4 h-4" />
              Archive Old Versions
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Version History */}
      <Card>
        <CardHeader>
          <CardTitle>Version History</CardTitle>
        </CardHeader>
        <CardContent>
          <ScrollArea className="h-96">
            <div className="space-y-4">
              {MOCK_VERSIONS.map((version) => (
                <Card key={version.id} className="border">
                  <CardContent className="p-4">
                    <div className="flex items-start justify-between">
                      <div className="space-y-2">
                        <div className="flex items-center gap-2">
                          <span className="font-medium">Version {version.version}</span>
                          <Badge variant={version.status === "Active" ? "default" : "secondary"}>
                            {version.status}
                          </Badge>
                          {version.status === "Active" && (
                            <Badge variant="outline" className="gap-1">
                              <CheckCircle className="w-3 h-3" />
                              Current
                            </Badge>
                          )}
                        </div>
                        
                        <div className="text-sm text-muted-foreground space-y-1">
                          <div className="flex items-center gap-2">
                            <Calendar className="w-3 h-3" />
                            Effective: {new Date(version.effectiveDate).toLocaleDateString()}
                          </div>
                          <div className="flex items-center gap-2">
                            <User className="w-3 h-3" />
                            Created by: {version.createdBy}
                          </div>
                          {version.approvedBy && (
                            <div className="flex items-center gap-2">
                              <CheckCircle className="w-3 h-3" />
                              Approved by: {version.approvedBy}
                            </div>
                          )}
                        </div>
                        
                        <div className="text-sm">
                          <strong>Change Reason:</strong> {version.changeReason}
                        </div>
                        
                        {/* Side Letter Terms Preview */}
                        {version.sideLetterTerms && (
                          <div className="mt-3 space-y-2">
                            <div className="text-sm font-medium">Side Letter Terms:</div>
                            <div className="grid grid-cols-2 gap-3 text-xs">
                              {version.sideLetterTerms.caps && (
                                <div className="flex justify-between">
                                  <span className="text-muted-foreground">Cap:</span>
                                  <span>${version.sideLetterTerms.caps.amount.toLocaleString()}</span>
                                </div>
                              )}
                              {version.sideLetterTerms.tiers && (
                                <div className="flex justify-between">
                                  <span className="text-muted-foreground">Tiers:</span>
                                  <span>{version.sideLetterTerms.tiers.length} defined</span>
                                </div>
                              )}
                              {version.sideLetterTerms.clawbacks && (
                                <div className="flex justify-between">
                                  <span className="text-muted-foreground">Clawback:</span>
                                  <span>{(version.sideLetterTerms.clawbacks.percentage * 100)}%</span>
                                </div>
                              )}
                              {version.sideLetterTerms.multiReferrerRules && (
                                <div className="flex justify-between">
                                  <span className="text-muted-foreground">Multi-Referrer:</span>
                                  <span>{version.sideLetterTerms.multiReferrerRules.type}</span>
                                </div>
                              )}
                            </div>
                          </div>
                        )}
                      </div>
                      
                      <div className="flex gap-2">
                        <Button 
                          variant="outline" 
                          size="sm"
                          onClick={() => setSelectedVersion(version)}
                          className="gap-1"
                        >
                          <Eye className="w-3 h-3" />
                          View
                        </Button>
                        <Button variant="outline" size="sm" className="gap-1">
                          <Download className="w-3 h-3" />
                          Export
                        </Button>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          </ScrollArea>
        </CardContent>
      </Card>

      {/* Eligibility Lifecycle */}
      <Card>
        <CardHeader>
          <CardTitle>Eligibility Lifecycle Management</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {MOCK_ELIGIBILITY.map((eligibility) => (
              <Card key={eligibility.agreementId} className="border">
                <CardContent className="p-4">
                  <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <div className="font-medium">Agreement: {eligibility.agreementId}</div>
                      <div className="flex items-center gap-2">
                        <Badge variant={eligibility.status === "Active" ? "default" : "secondary"}>
                          {eligibility.status}
                        </Badge>
                        <span className="text-sm text-muted-foreground">
                          Start: {new Date(eligibility.startDate).toLocaleDateString()}
                        </span>
                        {eligibility.endDate && (
                          <span className="text-sm text-muted-foreground">
                            End: {new Date(eligibility.endDate).toLocaleDateString()}
                          </span>
                        )}
                      </div>
                      {eligibility.minimumHoldTime && (
                        <div className="text-sm">
                          <span className="text-muted-foreground">Min Hold:</span> {eligibility.minimumHoldTime} months
                        </div>
                      )}
                      {eligibility.earlyRedemptionPenalty && (
                        <div className="text-sm">
                          <span className="text-muted-foreground">Early Penalty:</span> {(eligibility.earlyRedemptionPenalty * 100)}%
                        </div>
                      )}
                    </div>
                    
                    <div>
                      <div className="text-sm font-medium mb-2">Termination Conditions:</div>
                      <ul className="text-xs text-muted-foreground space-y-1">
                        {eligibility.terminationConditions.map((condition, index) => (
                          <li key={index} className="flex items-start gap-1">
                            <AlertTriangle className="w-3 h-3 mt-0.5 text-orange-500" />
                            {condition}
                          </li>
                        ))}
                      </ul>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Version Details Dialog */}
      <Dialog open={!!selectedVersion} onOpenChange={() => setSelectedVersion(null)}>
        <DialogContent className="sm:max-w-4xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Version {selectedVersion?.version} Details</DialogTitle>
            <DialogDescription>
              Complete version information with structured side letter terms
            </DialogDescription>
          </DialogHeader>
          
          {selectedVersion && (
            <div className="space-y-6">
              <div className="grid grid-cols-2 gap-4">
                <Card>
                  <CardHeader>
                    <CardTitle className="text-sm">Version Metadata</CardTitle>
                  </CardHeader>
                  <CardContent className="space-y-2 text-sm">
                    <div className="flex justify-between">
                      <span className="text-muted-foreground">Status:</span>
                      <Badge variant={selectedVersion.status === "Active" ? "default" : "secondary"}>
                        {selectedVersion.status}
                      </Badge>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-muted-foreground">Effective Date:</span>
                      <span>{new Date(selectedVersion.effectiveDate).toLocaleDateString()}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-muted-foreground">Created By:</span>
                      <span>{selectedVersion.createdBy}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-muted-foreground">Created At:</span>
                      <span>{new Date(selectedVersion.createdAt).toLocaleString()}</span>
                    </div>
                    {selectedVersion.approvedBy && (
                      <>
                        <div className="flex justify-between">
                          <span className="text-muted-foreground">Approved By:</span>
                          <span>{selectedVersion.approvedBy}</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-muted-foreground">Approved At:</span>
                          <span>{new Date(selectedVersion.approvedAt!).toLocaleString()}</span>
                        </div>
                      </>
                    )}
                  </CardContent>
                </Card>
                
                <Card>
                  <CardHeader>
                    <CardTitle className="text-sm">Change Information</CardTitle>
                  </CardHeader>
                  <CardContent>
                    <div className="text-sm">
                      <div className="font-medium mb-2">Reason for Change:</div>
                      <div className="text-muted-foreground">{selectedVersion.changeReason}</div>
                    </div>
                  </CardContent>
                </Card>
              </div>
              
              {/* Structured Side Letter Terms */}
              {selectedVersion.sideLetterTerms && (
                <Card>
                  <CardHeader>
                    <CardTitle className="text-sm">Structured Side Letter Terms</CardTitle>
                  </CardHeader>
                  <CardContent>
                    <div className="grid grid-cols-2 gap-4 text-sm">
                      {selectedVersion.sideLetterTerms.caps && (
                        <div>
                          <div className="font-medium mb-1">Caps & Limits</div>
                          <div className="text-muted-foreground">
                            Amount: {selectedVersion.sideLetterTerms.caps.currency} {selectedVersion.sideLetterTerms.caps.amount.toLocaleString()}
                          </div>
                        </div>
                      )}
                      
                      {selectedVersion.sideLetterTerms.tiers && (
                        <div>
                          <div className="font-medium mb-1">Tier Structure</div>
                          <div className="space-y-1">
                            {selectedVersion.sideLetterTerms.tiers.map((tier, index) => (
                              <div key={index} className="text-xs text-muted-foreground">
                                ${tier.min.toLocaleString()}{tier.max ? ` - $${tier.max.toLocaleString()}` : '+'}: {(tier.rate * 100)}%
                              </div>
                            ))}
                          </div>
                        </div>
                      )}
                      
                      {selectedVersion.sideLetterTerms.clawbacks && (
                        <div>
                          <div className="font-medium mb-1">Clawback Provisions</div>
                          <div className="text-xs text-muted-foreground">
                            <div>Percentage: {(selectedVersion.sideLetterTerms.clawbacks.percentage * 100)}%</div>
                            <div>Conditions: {selectedVersion.sideLetterTerms.clawbacks.conditions}</div>
                          </div>
                        </div>
                      )}
                      
                      {selectedVersion.sideLetterTerms.multiReferrerRules && (
                        <div>
                          <div className="font-medium mb-1">Multi-Referrer Rules</div>
                          <div className="text-xs text-muted-foreground">
                            <div>Type: {selectedVersion.sideLetterTerms.multiReferrerRules.type}</div>
                            <div className="space-y-1 mt-1">
                              {selectedVersion.sideLetterTerms.multiReferrerRules.rules.map((rule, index) => (
                                <div key={index}>
                                  {rule.referrerId}: {(rule.share * 100)}%{rule.priority && ` (Priority: ${rule.priority})`}
                                </div>
                              ))}
                            </div>
                          </div>
                        </div>
                      )}
                    </div>
                  </CardContent>
                </Card>
              )}
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}