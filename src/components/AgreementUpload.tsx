import React, { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { Textarea } from "@/components/ui/textarea";
import { Upload, FileText, CheckCircle, AlertCircle, Clock, Building2 } from "lucide-react";
import { useToast } from "@/hooks/use-toast";

// Types for LP/GP structure and fee management
type AgreementType = "Finder" | "Investor" | "Intermediary" | "Local Partner";
type EntityType = "Limited Partnership (LP)" | "General Partner (US)" | "Local GP (50/50 Joint)" | "Management Company";
type FeeType = "Promote Distribution" | "Asset Management Fee" | "Success Fee" | "Finder Fee";
type PaymentTiming = "Immediate Payment" | "On Funding Close" | "On Realization (3-7 years)" | "Quarterly (Management)" | "Custom Milestone";
type Basis = "Percentage of Promote" | "Percentage of Management Fee" | "Fixed Amount" | "Hybrid Structure";

interface AgreementForm {
  type: AgreementType;
  entityType: EntityType;
  owner: string;
  feeType: FeeType;
  basis: Basis;
  paymentTiming: PaymentTiming;
  deal1Percent?: number;
  deal2Percent?: number;
  deal3Percent?: number;
  fixedAmount?: number;
  cap?: number;
  vatFlag: boolean;
  validFrom: string;
  validTo?: string;
  sideLetterTerms?: string;
  projectRealizationYears?: number;
  file?: File;
}

export function AgreementUpload() {
  const [open, setOpen] = useState(false);
  const [form, setForm] = useState<AgreementForm>({
    type: "Finder",
    entityType: "Limited Partnership (LP)",
    owner: "",
    feeType: "Promote Distribution",
    basis: "Percentage of Promote",
    paymentTiming: "On Realization (3-7 years)",
    vatFlag: false,
    validFrom: "",
    projectRealizationYears: 5,
  });
  const [uploading, setUploading] = useState(false);
  const [needsApproval, setNeedsApproval] = useState(false);
  const { toast } = useToast();

  const handleFileUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file && file.type === "application/pdf") {
      setForm(prev => ({ ...prev, file }));
    } else {
      toast({
        title: "Invalid file type",
        description: "Please upload a PDF file.",
        variant: "destructive",
      });
    }
  };

  const handleSubmit = async () => {
    // Validation
    if (!form.owner || !form.validFrom || !form.file) {
      toast({
        title: "Missing required fields",
        description: "Please fill in all required fields and upload a PDF.",
        variant: "destructive",
      });
      return;
    }

    setUploading(true);
    
    // Simulate upload process
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    setUploading(false);
    setNeedsApproval(true);
    
    toast({
      title: "Agreement uploaded successfully",
      description: "Pending Finance approval before activation.",
    });
  };

  const resetForm = () => {
    setForm({
      type: "Finder",
      entityType: "Limited Partnership (LP)",
      owner: "",
      feeType: "Promote Distribution",
      basis: "Percentage of Promote",
      paymentTiming: "On Realization (3-7 years)",
      vatFlag: false,
      validFrom: "",
      projectRealizationYears: 5,
    });
    setNeedsApproval(false);
    setOpen(false);
  };

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button className="gap-2">
          <Upload className="w-4 h-4" />
          Upload Agreement
        </Button>
      </DialogTrigger>
      <DialogContent className="sm:max-w-3xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Building2 className="w-5 h-5" />
            Upload LP/GP Agreement
          </DialogTitle>
          <DialogDescription>
            Upload and register agreements for LP/GP structures, intermediaries, and side letter terms.
          </DialogDescription>
        </DialogHeader>

        {needsApproval ? (
          <Card className="border-orange-200 bg-orange-50">
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-orange-800">
                <Clock className="w-5 h-5" />
                Pending Approval
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="text-sm text-orange-700">
                Agreement uploaded successfully. Waiting for Finance validation before activation.
              </div>
              <div className="flex items-center gap-2 flex-wrap">
                <Badge variant="outline" className="border-orange-300">
                  {form.owner}
                </Badge>
                <Badge variant="secondary">
                  {form.type}
                </Badge>
                <Badge>
                  {form.feeType}
                </Badge>
                <Badge variant="outline">
                  {form.paymentTiming}
                </Badge>
              </div>
              <Button onClick={resetForm} variant="outline" className="w-full">
                Upload Another Agreement
              </Button>
            </CardContent>
          </Card>
        ) : (
          <div className="space-y-6">
            {/* File Upload */}
            <div>
              <Label htmlFor="agreement-file">Agreement PDF *</Label>
              <div className="mt-2 border-2 border-dashed border-border rounded-lg p-6 text-center">
                <FileText className="w-8 h-8 mx-auto text-muted-foreground mb-2" />
                <div className="text-sm text-muted-foreground mb-2">
                  Upload signed agreement or side letter (PDF only)
                </div>
                <Input
                  id="agreement-file"
                  type="file"
                  accept=".pdf"
                  onChange={handleFileUpload}
                  className="hidden"
                />
                <Button
                  variant="outline"
                  onClick={() => document.getElementById('agreement-file')?.click()}
                >
                  Choose PDF File
                </Button>
                {form.file && (
                  <div className="mt-2 text-sm text-primary flex items-center justify-center gap-2">
                    <CheckCircle className="w-4 h-4" />
                    {form.file.name}
                  </div>
                )}
              </div>
            </div>

            <Separator />

            {/* Entity and Agreement Details */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label htmlFor="owner">Owner/Entity Name *</Label>
                <Input
                  id="owner"
                  value={form.owner}
                  onChange={(e) => setForm(prev => ({ ...prev, owner: e.target.value }))}
                  placeholder="e.g., Aventine Advisors LLC"
                />
              </div>
              <div>
                <Label htmlFor="entity-type">Entity Type *</Label>
                <Select value={form.entityType} onValueChange={(value: EntityType) => setForm(prev => ({ ...prev, entityType: value }))}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="Limited Partnership (LP)">Limited Partnership (LP)</SelectItem>
                    <SelectItem value="General Partner (US)">General Partner (US)</SelectItem>
                    <SelectItem value="Local GP (50/50 Joint)">Local GP (50/50 Joint)</SelectItem>
                    <SelectItem value="Management Company">Management Company</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div>
                <Label htmlFor="type">Agreement Type *</Label>
                <Select value={form.type} onValueChange={(value: AgreementType) => setForm(prev => ({ ...prev, type: value }))}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="Finder">Finder</SelectItem>
                    <SelectItem value="Investor">Investor</SelectItem>
                    <SelectItem value="Intermediary">Intermediary</SelectItem>
                    <SelectItem value="Local Partner">Local Partner</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div>
                <Label htmlFor="fee-type">Fee Type *</Label>
                <Select value={form.feeType} onValueChange={(value: FeeType) => setForm(prev => ({ ...prev, feeType: value }))}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="Promote Distribution">Promote Distribution</SelectItem>
                    <SelectItem value="Asset Management Fee">Asset Management Fee</SelectItem>
                    <SelectItem value="Success Fee">Success Fee</SelectItem>
                    <SelectItem value="Finder Fee">Finder Fee</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>

            {/* Fee Structure */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label htmlFor="basis">Fee Basis *</Label>
                <Select value={form.basis} onValueChange={(value: Basis) => setForm(prev => ({ ...prev, basis: value }))}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="Percentage of Promote">Percentage of Promote</SelectItem>
                    <SelectItem value="Percentage of Management Fee">Percentage of Management Fee</SelectItem>
                    <SelectItem value="Fixed Amount">Fixed Amount</SelectItem>
                    <SelectItem value="Hybrid Structure">Hybrid Structure</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div>
                <Label htmlFor="payment-timing">Payment Timing *</Label>
                <Select value={form.paymentTiming} onValueChange={(value: PaymentTiming) => setForm(prev => ({ ...prev, paymentTiming: value }))}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="Immediate Payment">Immediate Payment</SelectItem>
                    <SelectItem value="On Funding Close">On Funding Close</SelectItem>
                    <SelectItem value="On Realization (3-7 years)">On Realization (3-7 years)</SelectItem>
                    <SelectItem value="Quarterly (Management)">Quarterly (Management)</SelectItem>
                    <SelectItem value="Custom Milestone">Custom Milestone</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>

            {/* Deal Percentages */}
            <div>
              <Label>Fee Percentages by Deal/Project</Label>
              <div className="grid grid-cols-3 gap-3 mt-2">
                <div>
                  <Label htmlFor="deal1-percent" className="text-xs">Deal 1 %</Label>
                  <Input
                    id="deal1-percent"
                    type="number"
                    step="0.001"
                    value={form.deal1Percent || ""}
                    onChange={(e) => setForm(prev => ({ ...prev, deal1Percent: parseFloat(e.target.value) || undefined }))}
                    placeholder="2.5"
                  />
                </div>
                <div>
                  <Label htmlFor="deal2-percent" className="text-xs">Deal 2 %</Label>
                  <Input
                    id="deal2-percent"
                    type="number"
                    step="0.001"
                    value={form.deal2Percent || ""}
                    onChange={(e) => setForm(prev => ({ ...prev, deal2Percent: parseFloat(e.target.value) || undefined }))}
                    placeholder="2.5"
                  />
                </div>
                <div>
                  <Label htmlFor="deal3-percent" className="text-xs">Deal 3 %</Label>
                  <Input
                    id="deal3-percent"
                    type="number"
                    step="0.001"
                    value={form.deal3Percent || ""}
                    onChange={(e) => setForm(prev => ({ ...prev, deal3Percent: parseFloat(e.target.value) || undefined }))}
                    placeholder="2.5"
                  />
                </div>
              </div>
            </div>

            {/* Fixed Amount and Cap */}
            <div className="grid grid-cols-3 gap-4">
              <div>
                <Label htmlFor="fixed-amount">Fixed Amount (USD)</Label>
                <Input
                  id="fixed-amount"
                  type="number"
                  value={form.fixedAmount || ""}
                  onChange={(e) => setForm(prev => ({ ...prev, fixedAmount: parseInt(e.target.value) || undefined }))}
                  placeholder="250000"
                />
              </div>
              <div>
                <Label htmlFor="cap">Cap Amount (USD)</Label>
                <Input
                  id="cap"
                  type="number"
                  value={form.cap || ""}
                  onChange={(e) => setForm(prev => ({ ...prev, cap: parseInt(e.target.value) || undefined }))}
                  placeholder="1000000"
                />
              </div>
              <div>
                <Label htmlFor="realization-years">Project Realization (Years)</Label>
                <Input
                  id="realization-years"
                  type="number"
                  min="1"
                  max="10"
                  value={form.projectRealizationYears || ""}
                  onChange={(e) => setForm(prev => ({ ...prev, projectRealizationYears: parseInt(e.target.value) || undefined }))}
                  placeholder="5"
                />
              </div>
            </div>

            {/* Validity Period */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label htmlFor="valid-from">Valid From *</Label>
                <Input
                  id="valid-from"
                  type="date"
                  value={form.validFrom}
                  onChange={(e) => setForm(prev => ({ ...prev, validFrom: e.target.value }))}
                />
              </div>
              <div>
                <Label htmlFor="valid-to">Valid To (Optional)</Label>
                <Input
                  id="valid-to"
                  type="date"
                  value={form.validTo || ""}
                  onChange={(e) => setForm(prev => ({ ...prev, validTo: e.target.value || undefined }))}
                />
              </div>
            </div>

            {/* Side Letter Terms */}
            <div>
              <Label htmlFor="side-letter">Side Letter Terms (Optional)</Label>
              <Textarea
                id="side-letter"
                value={form.sideLetterTerms || ""}
                onChange={(e) => setForm(prev => ({ ...prev, sideLetterTerms: e.target.value || undefined }))}
                placeholder="Describe any special terms, conditions, or variations from standard agreement..."
                className="min-h-[80px]"
              />
            </div>

            {/* VAT Flag */}
            <div className="flex items-center space-x-2">
              <input
                id="vat-flag"
                type="checkbox"
                checked={form.vatFlag}
                onChange={(e) => setForm(prev => ({ ...prev, vatFlag: e.target.checked }))}
                className="rounded border-border"
              />
              <Label htmlFor="vat-flag">VAT Applicable</Label>
            </div>

            <Separator />

            {/* Actions */}
            <div className="flex gap-3">
              <Button
                onClick={handleSubmit}
                disabled={uploading || !form.owner || !form.validFrom || !form.file}
                className="flex-1"
              >
                {uploading ? (
                  <>
                    <AlertCircle className="w-4 h-4 mr-2 animate-spin" />
                    Uploading...
                  </>
                ) : (
                  <>
                    <Upload className="w-4 h-4 mr-2" />
                    Submit for Approval
                  </>
                )}
              </Button>
              <Button variant="outline" onClick={() => setOpen(false)}>
                Cancel
              </Button>
            </div>
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
}