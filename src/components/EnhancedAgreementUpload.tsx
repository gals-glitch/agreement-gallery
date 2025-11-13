import React, { useState, useCallback } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Textarea } from '@/components/ui/textarea';
import { Switch } from '@/components/ui/switch';
import { Calendar } from '@/components/ui/calendar';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Upload, FileText, CalendarIcon, Percent, Check, X } from 'lucide-react';
import { format } from 'date-fns';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from '@/hooks/use-toast';

interface AgreementForm {
  name: string;
  entity_name: string;
  entity_type: 'distributor' | 'referrer' | 'partner';
  fund_name: string;
  rule_type: 'percentage' | 'fixed_amount' | 'tiered';
  base_rate: string;
  fixed_amount: string;
  calculation_basis: 'distribution_amount' | 'cumulative_amount';
  vat_mode: 'included' | 'added';
  vat_rate_table: string;
  currency: string;
  timing_mode: 'immediate' | 'quarterly' | 'on_event';
  lag_days: string;
  min_amount: string;
  max_amount: string;
  effective_from: Date | null;
  effective_to: Date | null;
  description: string;
  is_active: boolean;
}

const initialForm: AgreementForm = {
  name: '',
  entity_name: '',
  entity_type: 'distributor',
  fund_name: '',
  rule_type: 'percentage',
  base_rate: '',
  fixed_amount: '',
  calculation_basis: 'distribution_amount',
  vat_mode: 'added',
  vat_rate_table: 'IL_STANDARD',
  currency: 'USD',
  timing_mode: 'quarterly',
  lag_days: '30',
  min_amount: '0',
  max_amount: '',
  effective_from: null,
  effective_to: null,
  description: '',
  is_active: true
};

export function EnhancedAgreementUpload() {
  const [isOpen, setIsOpen] = useState(false);
  const [form, setForm] = useState<AgreementForm>(initialForm);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [uploading, setUploading] = useState(false);
  const [validationErrors, setValidationErrors] = useState<string[]>([]);
  
  const { toast } = useToast();

  const validateForm = (): boolean => {
    const errors: string[] = [];

    if (!form.name.trim()) errors.push('Agreement name is required');
    if (!form.entity_name.trim()) errors.push('Entity name is required');
    if (!form.fund_name.trim()) errors.push('Fund name is required');
    
    if (form.rule_type === 'percentage' && (!form.base_rate || parseFloat(form.base_rate) <= 0)) {
      errors.push('Base rate must be greater than 0 for percentage rules');
    }
    
    if (form.rule_type === 'fixed_amount' && (!form.fixed_amount || parseFloat(form.fixed_amount) <= 0)) {
      errors.push('Fixed amount must be greater than 0 for fixed amount rules');
    }

    if (form.effective_from && form.effective_to && form.effective_from > form.effective_to) {
      errors.push('Effective from date must be before effective to date');
    }

    if (form.max_amount && form.min_amount && parseFloat(form.max_amount) < parseFloat(form.min_amount)) {
      errors.push('Maximum amount must be greater than minimum amount');
    }

    setValidationErrors(errors);
    return errors.length === 0;
  };

  const handleFileSelect = useCallback((event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      if (file.type === 'application/pdf') {
        setSelectedFile(file);
      } else {
        toast({
          title: "Invalid File Type",
          description: "Please select a PDF file",
          variant: "destructive"
        });
      }
    }
  }, [toast]);

  const uploadPdfFile = async (file: File): Promise<string | null> => {
    try {
      const fileExt = 'pdf';
      const fileName = `${Date.now()}-${Math.random().toString(36).substring(2)}.${fileExt}`;
      const filePath = `agreements/${fileName}`;

      const { error: uploadError } = await supabase.storage
        .from('agreements')
        .upload(filePath, file);

      if (uploadError) throw uploadError;

      return filePath;
    } catch (error) {
      console.error('Error uploading PDF:', error);
      return null;
    }
  };

  const handleSubmit = async () => {
    if (!validateForm()) {
      toast({
        title: "Validation Error",
        description: "Please fix the validation errors before submitting",
        variant: "destructive"
      });
      return;
    }

    setUploading(true);

    try {
      // Upload PDF file if selected
      let pdfFilePath: string | null = null;
      if (selectedFile) {
        pdfFilePath = await uploadPdfFile(selectedFile);
        if (!pdfFilePath) {
          throw new Error('Failed to upload PDF file');
        }
      }

      // Create agreement rule
      const ruleData = {
        name: form.name,
        entity_name: form.entity_name,
        entity_type: form.entity_type,
        fund_name: form.fund_name,
        rule_type: form.rule_type,
        base_rate: form.base_rate ? parseFloat(form.base_rate) : null,
        fixed_amount: form.fixed_amount ? parseFloat(form.fixed_amount) : null,
        calculation_basis: form.calculation_basis,
        vat_mode: form.vat_mode,
        vat_rate_table: form.vat_rate_table,
        currency: form.currency,
        timing_mode: form.timing_mode,
        lag_days: parseInt(form.lag_days),
        min_amount: parseFloat(form.min_amount),
        max_amount: form.max_amount ? parseFloat(form.max_amount) : null,
        effective_from: form.effective_from ? format(form.effective_from, 'yyyy-MM-dd') : null,
        effective_to: form.effective_to ? format(form.effective_to, 'yyyy-MM-dd') : null,
        description: form.description,
        is_active: form.is_active,
        pdf_file_path: pdfFilePath
      };

      const { error } = await supabase
        .from('advanced_commission_rules')
        .insert([ruleData]);

      if (error) throw error;

      toast({
        title: "Success",
        description: "Agreement uploaded and rule created successfully"
      });

      // Reset form
      setForm(initialForm);
      setSelectedFile(null);
      setIsOpen(false);
      setValidationErrors([]);

    } catch (error) {
      console.error('Error creating agreement:', error);
      toast({
        title: "Error",
        description: "Failed to create agreement",
        variant: "destructive"
      });
    } finally {
      setUploading(false);
    }
  };

  return (
    <Dialog open={isOpen} onOpenChange={setIsOpen}>
      <DialogTrigger asChild>
        <Button variant="outline" className="gap-2">
          <Upload className="w-4 h-4" />
          Upload Agreement
        </Button>
      </DialogTrigger>
      <DialogContent className="sm:max-w-4xl max-h-[90vh]">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <FileText className="w-5 h-5" />
            Upload Agreement & Create Rule
          </DialogTitle>
          <DialogDescription>
            Upload a PDF agreement and configure commission calculation rules per PRD specifications
          </DialogDescription>
        </DialogHeader>
        
        <ScrollArea className="max-h-[70vh] pr-4">
          <div className="space-y-6">
            {/* Validation Errors */}
            {validationErrors.length > 0 && (
              <Card className="border-destructive">
                <CardHeader>
                  <CardTitle className="text-destructive flex items-center gap-2">
                    <X className="w-4 h-4" />
                    Validation Errors
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <ul className="list-disc list-inside space-y-1 text-sm">
                    {validationErrors.map((error, index) => (
                      <li key={index} className="text-destructive">{error}</li>
                    ))}
                  </ul>
                </CardContent>
              </Card>
            )}

            {/* PDF Upload */}
            <Card>
              <CardHeader>
                <CardTitle>Agreement PDF</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  <Label htmlFor="pdf-upload">Upload PDF Agreement (Optional)</Label>
                  <Input
                    id="pdf-upload"
                    type="file"
                    accept=".pdf"
                    onChange={handleFileSelect}
                  />
                  {selectedFile && (
                    <div className="flex items-center gap-2 text-sm text-muted-foreground">
                      <FileText className="w-4 h-4" />
                      {selectedFile.name}
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>

            {/* Basic Information */}
            <Card>
              <CardHeader>
                <CardTitle>Basic Information</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <Label htmlFor="name">Agreement Name *</Label>
                    <Input
                      id="name"
                      value={form.name}
                      onChange={(e) => setForm({ ...form, name: e.target.value })}
                      placeholder="e.g., Aventine Distributor Agreement"
                    />
                  </div>
                  <div>
                    <Label htmlFor="entity_name">Entity Name *</Label>
                    <Input
                      id="entity_name"
                      value={form.entity_name}
                      onChange={(e) => setForm({ ...form, entity_name: e.target.value })}
                      placeholder="e.g., Aventine Advisors"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <Label htmlFor="entity_type">Entity Type *</Label>
                    <Select
                      value={form.entity_type}
                      onValueChange={(value: 'distributor' | 'referrer' | 'partner') => 
                        setForm({ ...form, entity_type: value })
                      }
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
                  <div>
                    <Label htmlFor="fund_name">Fund Name *</Label>
                    <Input
                      id="fund_name"
                      value={form.fund_name}
                      onChange={(e) => setForm({ ...form, fund_name: e.target.value })}
                      placeholder="e.g., Fund VI"
                    />
                  </div>
                </div>

                <div>
                  <Label htmlFor="description">Description</Label>
                  <Textarea
                    id="description"
                    value={form.description}
                    onChange={(e) => setForm({ ...form, description: e.target.value })}
                    placeholder="Agreement description and special terms"
                  />
                </div>
              </CardContent>
            </Card>

            {/* Commission Rules */}
            <Card>
              <CardHeader>
                <CardTitle>Commission Configuration</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-3 gap-4">
                  <div>
                    <Label htmlFor="rule_type">Rule Type *</Label>
                    <Select
                      value={form.rule_type}
                      onValueChange={(value: 'percentage' | 'fixed_amount' | 'tiered') => 
                        setForm({ ...form, rule_type: value })
                      }
                    >
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="percentage">Percentage</SelectItem>
                        <SelectItem value="fixed_amount">Fixed Amount</SelectItem>
                        <SelectItem value="tiered">Tiered</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <div>
                    <Label htmlFor="calculation_basis">Calculation Basis</Label>
                    <Select
                      value={form.calculation_basis}
                      onValueChange={(value: 'distribution_amount' | 'cumulative_amount') => 
                        setForm({ ...form, calculation_basis: value })
                      }
                    >
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="distribution_amount">Distribution Amount</SelectItem>
                        <SelectItem value="cumulative_amount">Cumulative Amount</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <div>
                    <Label htmlFor="currency">Currency</Label>
                    <Select
                      value={form.currency}
                      onValueChange={(value) => setForm({ ...form, currency: value })}
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
                </div>

                {form.rule_type === 'percentage' && (
                  <div className="grid grid-cols-3 gap-4">
                    <div>
                      <Label htmlFor="base_rate">Base Rate (%) *</Label>
                      <div className="relative">
                        <Input
                          id="base_rate"
                          type="number"
                          step="0.01"
                          min="0"
                          max="100"
                          value={form.base_rate}
                          onChange={(e) => setForm({ ...form, base_rate: e.target.value })}
                          placeholder="1.5"
                        />
                        <Percent className="absolute right-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-muted-foreground" />
                      </div>
                    </div>
                  </div>
                )}

                {form.rule_type === 'fixed_amount' && (
                  <div className="grid grid-cols-3 gap-4">
                    <div>
                      <Label htmlFor="fixed_amount">Fixed Amount *</Label>
                      <Input
                        id="fixed_amount"
                        type="number"
                        step="0.01"
                        min="0"
                        value={form.fixed_amount}
                        onChange={(e) => setForm({ ...form, fixed_amount: e.target.value })}
                        placeholder="1000.00"
                      />
                    </div>
                  </div>
                )}

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <Label htmlFor="min_amount">Minimum Amount</Label>
                    <Input
                      id="min_amount"
                      type="number"
                      step="0.01"
                      min="0"
                      value={form.min_amount}
                      onChange={(e) => setForm({ ...form, min_amount: e.target.value })}
                      placeholder="0"
                    />
                  </div>
                  <div>
                    <Label htmlFor="max_amount">Maximum Amount</Label>
                    <Input
                      id="max_amount"
                      type="number"
                      step="0.01"
                      min="0"
                      value={form.max_amount}
                      onChange={(e) => setForm({ ...form, max_amount: e.target.value })}
                      placeholder="Optional"
                    />
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* VAT Configuration */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Percent className="w-4 h-4" />
                  VAT Configuration
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <Label htmlFor="vat_mode">VAT Mode *</Label>
                    <Select
                      value={form.vat_mode}
                      onValueChange={(value: 'included' | 'added') => 
                        setForm({ ...form, vat_mode: value })
                      }
                    >
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="added">VAT Added</SelectItem>
                        <SelectItem value="included">VAT Included</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <div>
                    <Label htmlFor="vat_rate_table">VAT Rate Table</Label>
                    <Select
                      value={form.vat_rate_table}
                      onValueChange={(value) => setForm({ ...form, vat_rate_table: value })}
                    >
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="IL_STANDARD">IL Standard</SelectItem>
                        <SelectItem value="US_STANDARD">US Standard</SelectItem>
                        <SelectItem value="EU_STANDARD">EU Standard</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Timing Configuration */}
            <Card>
              <CardHeader>
                <CardTitle>Timing & Dates</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <Label htmlFor="timing_mode">Payment Timing</Label>
                    <Select
                      value={form.timing_mode}
                      onValueChange={(value: 'immediate' | 'quarterly' | 'on_event') => 
                        setForm({ ...form, timing_mode: value })
                      }
                    >
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="immediate">Immediate</SelectItem>
                        <SelectItem value="quarterly">Quarterly</SelectItem>
                        <SelectItem value="on_event">On Event</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <div>
                    <Label htmlFor="lag_days">Lag Days</Label>
                    <Input
                      id="lag_days"
                      type="number"
                      min="0"
                      value={form.lag_days}
                      onChange={(e) => setForm({ ...form, lag_days: e.target.value })}
                      placeholder="30"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <Label>Effective From</Label>
                    <Popover>
                      <PopoverTrigger asChild>
                        <Button variant="outline" className="w-full justify-start text-left font-normal">
                          <CalendarIcon className="mr-2 h-4 w-4" />
                          {form.effective_from ? format(form.effective_from, "PPP") : "Select date"}
                        </Button>
                      </PopoverTrigger>
                      <PopoverContent className="w-auto p-0">
                        <Calendar
                          mode="single"
                          selected={form.effective_from || undefined}
                          onSelect={(date) => setForm({ ...form, effective_from: date || null })}
                          initialFocus
                        />
                      </PopoverContent>
                    </Popover>
                  </div>
                  <div>
                    <Label>Effective To</Label>
                    <Popover>
                      <PopoverTrigger asChild>
                        <Button variant="outline" className="w-full justify-start text-left font-normal">
                          <CalendarIcon className="mr-2 h-4 w-4" />
                          {form.effective_to ? format(form.effective_to, "PPP") : "Select date (optional)"}
                        </Button>
                      </PopoverTrigger>
                      <PopoverContent className="w-auto p-0">
                        <Calendar
                          mode="single"
                          selected={form.effective_to || undefined}
                          onSelect={(date) => setForm({ ...form, effective_to: date || null })}
                          initialFocus
                        />
                      </PopoverContent>
                    </Popover>
                  </div>
                </div>

                <div className="flex items-center space-x-2">
                  <Switch
                    id="is_active"
                    checked={form.is_active}
                    onCheckedChange={(checked) => setForm({ ...form, is_active: checked })}
                  />
                  <Label htmlFor="is_active">Agreement is active</Label>
                </div>
              </CardContent>
            </Card>
          </div>
        </ScrollArea>

        <div className="flex gap-2 justify-end pt-4 border-t">
          <Button variant="outline" onClick={() => setIsOpen(false)}>
            Cancel
          </Button>
          <Button onClick={handleSubmit} disabled={uploading}>
            {uploading ? 'Creating...' : 'Create Agreement'}
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}