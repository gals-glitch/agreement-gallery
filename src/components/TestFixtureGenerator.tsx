import React, { useState } from 'react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { Download, FileSpreadsheet, Database, TestTube } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import * as XLSX from 'xlsx';

interface FixtureConfig {
  name: string;
  description: string;
  generator: () => any[];
  rows: number;
  type: 'contributions' | 'agreements' | 'errors' | 'credits';
}

export function TestFixtureGenerator() {
  const { toast } = useToast();
  const [generating, setGenerating] = useState<string | null>(null);

  const generateContributionsFundA = () => {
    const rows = [];
    const baseDate = new Date('2024-01-01');
    
    for (let i = 0; i < 5000; i++) {
      // Create threshold testing cases around 100k
      const isThresholdCase = i < 100;
      const baseAmount = isThresholdCase ? 
        99000 + (Math.random() * 2000) : // Around 100k threshold
        Math.random() * 500000; // Regular amounts
        
      const distributionDate = new Date(baseDate);
      distributionDate.setDate(distributionDate.getDate() + Math.floor(Math.random() * 365));
      
      rows.push({
        investor_name: `Investor_A_${i + 1}`,
        fund_name: 'Fund A',
        distribution_amount: baseAmount,
        distribution_date: distributionDate.toISOString().split('T')[0],
        distributor_name: `Distributor_${(i % 10) + 1}`,
        referrer_name: i % 3 === 0 ? `Referrer_${(i % 5) + 1}` : '',
        partner_name: i % 4 === 0 ? `Partner_${(i % 3) + 1}` : '',
        contribution_type: Math.random() > 0.2 ? 'contribution' : 'commitment', // 80% contributions
        currency: 'USD',
        jurisdiction: 'IL' // Israeli VAT
      });
    }
    
    return rows;
  };

  const generateContributionsFundB = () => {
    const rows = [];
    const baseDate = new Date('2024-01-01');
    
    for (let i = 0; i < 5000; i++) {
      const distributionDate = new Date(baseDate);
      distributionDate.setDate(distributionDate.getDate() + Math.floor(Math.random() * 365));
      
      rows.push({
        investor_name: `Investor_B_${i + 1}`,
        fund_name: 'Fund B',
        distribution_amount: Math.random() * 300000,
        distribution_date: distributionDate.toISOString().split('T')[0],
        distributor_name: `Distributor_Split_${(i % 5) + 1}`, // For sub-agent split testing
        referrer_name: '',
        partner_name: '',
        contribution_type: 'contribution',
        currency: 'USD',
        jurisdiction: 'US', // US no VAT
        has_sub_agent: i % 2 === 0 // 50% have sub-agents
      });
    }
    
    return rows;
  };

  const generateAgreementsSeed = () => {
    return [
      {
        name: 'Fund A Distributor Tiered',
        entity_type: 'distributor',
        entity_name: 'Distributor_1',
        fund_name: 'Fund A',
        rule_type: 'tiered',
        tier_1_rate: 0.01,
        tier_1_threshold: 100000,
        tier_2_rate: 0.015,
        cap_amount: 1000000,
        vat_mode: 'added',
        vat_rate: 0.17,
        jurisdiction: 'IL'
      },
      {
        name: 'Fund A Referrer Fixed',
        entity_type: 'referrer',
        entity_name: 'Referrer_1',
        fund_name: 'Fund A',
        rule_type: 'fixed',
        fixed_amount: 1000,
        vat_mode: 'not_applicable',
        jurisdiction: 'US'
      },
      {
        name: 'Fund B Distributor Percentage',
        entity_type: 'distributor', 
        entity_name: 'Distributor_Split_1',
        fund_name: 'Fund B',
        rule_type: 'percentage',
        base_rate: 0.02,
        sub_agent_split: 0.30, // 70/30 split
        vat_mode: 'included',
        vat_rate: 0.17
      },
      {
        name: 'Management Fee Rule',
        entity_type: 'distributor',
        rule_type: 'percentage',
        base_rate: 0.005,
        calculation_basis: 'management_fee',
        timing_mode: 'quarterly'
      },
      {
        name: 'Promote Share Rule',
        entity_type: 'distributor',
        rule_type: 'percentage',
        base_rate: 0.20,
        calculation_basis: 'promote_share',
        timing_mode: 'on_exit'
      },
      {
        name: 'Discount Rule Template',
        rule_type: 'discount',
        discount_type: 'percentage',
        percentage: 0.0025, // -0.25%
        applies_to: 'base_rate'
      },
      {
        name: 'Credit Netting Rule',
        rule_type: 'credit',
        credit_type: 'fixed',
        apply_policy: 'net_against_future_payables',
        timing: 'before_vat'
      }
    ];
  };

  const generateBadRows = () => {
    return [
      // Invalid dates
      { investor_name: 'Bad_1', distribution_amount: 1000, distribution_date: '2024-13-01', error: 'invalid_date' },
      { investor_name: 'Bad_2', distribution_amount: 1000, distribution_date: 'not-a-date', error: 'invalid_date' },
      
      // Invalid amounts
      { investor_name: 'Bad_3', distribution_amount: -1000, distribution_date: '2024-01-01', error: 'negative_amount' },
      { investor_name: 'Bad_4', distribution_amount: 'not-a-number', distribution_date: '2024-01-01', error: 'invalid_amount' },
      
      // Missing required fields
      { investor_name: '', distribution_amount: 1000, distribution_date: '2024-01-01', error: 'missing_investor' },
      { investor_name: 'Bad_6', distribution_amount: 1000, distribution_date: '', error: 'missing_date' },
      
      // Duplicates
      { investor_name: 'Duplicate_1', fund_name: 'Fund A', distribution_amount: 1000, distribution_date: '2024-01-01' },
      { investor_name: 'Duplicate_1', fund_name: 'Fund A', distribution_amount: 1000, distribution_date: '2024-01-01' },
      
      // Business rule violations
      { investor_name: 'Future_1', distribution_amount: 1000, distribution_date: '2025-12-31', error: 'future_date' },
      { investor_name: 'Large_1', distribution_amount: 100000000, distribution_date: '2024-01-01', error: 'amount_too_large' }
    ];
  };

  const generateCreditsDiscounts = () => {
    return [
      // Credits for investor Y
      {
        investor_name: 'Investor_Y',
        fund_name: 'Fund A',
        credit_type: 'fixed',
        amount: 500,
        apply_policy: 'net_against_future_payables',
        effective_date: '2024-01-01'
      },
      
      // Discounts for investor X  
      {
        investor_name: 'Investor_X',
        fund_name: 'Fund A',
        discount_type: 'percentage',
        percentage: 0.0025, // -0.25%
        effective_date: '2024-01-01',
        expiry_date: '2024-12-31'
      },
      
      // Additional test cases
      {
        investor_name: 'Investor_Credit_Test',
        fund_name: 'Fund B',
        credit_type: 'percentage',
        percentage: 0.01,
        apply_policy: 'immediate_offset'
      }
    ];
  };

  const fixtures: FixtureConfig[] = [
    {
      name: 'contributions_fundA_5k.xlsx',
      description: '5k Fund A contributions with 100 threshold cases, IL VAT',
      generator: generateContributionsFundA,
      rows: 5000,
      type: 'contributions'
    },
    {
      name: 'contributions_fundB_5k.xlsx', 
      description: '5k Fund B contributions with sub-agent splits, US no-VAT',
      generator: generateContributionsFundB,
      rows: 5000,
      type: 'contributions'
    },
    {
      name: 'agreements_seed.xlsx',
      description: '7 rule types for comprehensive agreement testing',
      generator: generateAgreementsSeed,
      rows: 7,
      type: 'agreements'
    },
    {
      name: 'bad_rows.xlsx',
      description: 'Invalid data for validation testing',
      generator: generateBadRows,
      rows: 100,
      type: 'errors'
    },
    {
      name: 'credits_discounts.xlsx',
      description: 'Credits and discounts for Y/X investor examples',
      generator: generateCreditsDiscounts,
      rows: 20,
      type: 'credits'
    }
  ];

  const generateAndDownload = async (fixture: FixtureConfig) => {
    setGenerating(fixture.name);
    
    try {
      // Generate data
      await new Promise(resolve => setTimeout(resolve, 1000)); // Simulate generation time
      const data = fixture.generator();
      
      // Create workbook
      const wb = XLSX.utils.book_new();
      const ws = XLSX.utils.json_to_sheet(data);
      
      // Add some styling and metadata
      ws['!cols'] = [
        { width: 20 }, // investor_name
        { width: 15 }, // fund_name  
        { width: 15 }, // distribution_amount
        { width: 12 }, // distribution_date
        { width: 20 }, // distributor_name
        { width: 20 }, // referrer_name
        { width: 20 }  // partner_name
      ];
      
      XLSX.utils.book_append_sheet(wb, ws, 'Data');
      
      // Add metadata sheet
      const metadata = [
        { property: 'Generated', value: new Date().toISOString() },
        { property: 'Rows', value: data.length },
        { property: 'Purpose', value: fixture.description },
        { property: 'Type', value: fixture.type }
      ];
      const metaWs = XLSX.utils.json_to_sheet(metadata);
      XLSX.utils.book_append_sheet(wb, metaWs, 'Metadata');
      
      // Download
      XLSX.writeFile(wb, fixture.name);
      
      toast({
        title: 'Fixture Generated',
        description: `${fixture.name} downloaded successfully`
      });
      
    } catch (error) {
      toast({
        title: 'Generation Failed',
        description: `Failed to generate ${fixture.name}`,
        variant: 'destructive'
      });
    } finally {
      setGenerating(null);
    }
  };

  const getTypeIcon = (type: FixtureConfig['type']) => {
    switch (type) {
      case 'contributions': return <Database className="h-4 w-4" />;
      case 'agreements': return <FileSpreadsheet className="h-4 w-4" />;
      case 'errors': return <TestTube className="h-4 w-4" />;
      case 'credits': return <Download className="h-4 w-4" />;
    }
  };

  const getTypeBadge = (type: FixtureConfig['type']) => {
    const colors = {
      contributions: 'default',
      agreements: 'secondary', 
      errors: 'destructive',
      credits: 'outline'
    } as const;
    
    return <Badge variant={colors[type]}>{type}</Badge>;
  };

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold mb-2">Test Fixture Generator</h2>
        <p className="text-muted-foreground">Generate Excel files for validation testing</p>
      </div>
      
      <div className="grid gap-4">
        {fixtures.map((fixture) => (
          <Card key={fixture.name}>
            <CardHeader className="pb-3">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  {getTypeIcon(fixture.type)}
                  <CardTitle className="text-lg">{fixture.name}</CardTitle>
                  {getTypeBadge(fixture.type)}
                </div>
                <div className="flex items-center gap-2">
                  <Badge variant="outline">{fixture.rows.toLocaleString()} rows</Badge>
                  <Button 
                    onClick={() => generateAndDownload(fixture)}
                    disabled={generating === fixture.name}
                    size="sm"
                  >
                    {generating === fixture.name ? (
                      <>
                        <Progress className="h-4 w-4 mr-2" />
                        Generating...
                      </>
                    ) : (
                      <>
                        <Download className="h-4 w-4 mr-2" />
                        Generate
                      </>
                    )}
                  </Button>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <p className="text-muted-foreground">{fixture.description}</p>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}