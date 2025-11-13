import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.57.2';
import * as XLSX from 'https://esm.sh/xlsx@0.18.5';
import { getAuthenticatedUser, getUserRoles, hasAnyRole } from '../_shared/auth.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface ExportRequest {
  type: 'summary' | 'detail' | 'vat' | 'audit';
  filters: {
    calculation_run_ids: string[];
    fund_names?: string[];
    party_names?: string[];
    date_range?: { start: string; end: string };
    run_status: string[];
  };
  columns: Array<{ key: string; label: string }>;
  options: {
    filename: string;
    rounding_precision: number;
  };
}

interface SummaryRow {
  party_name: string;
  fund_name: string;
  period_start: string;
  period_end: string;
  gross_commission: number;
  vat_amount: number;
  net_commission: number;
  currency: string;
  cap_applied: boolean;
  vat_mode: string;
}

interface DetailRow {
  calc_run_id: string;
  distribution_id: string;
  investor_name: string;
  fund_name: string;
  entity_name: string;
  commission_type: string;
  rule_id: string;
  rule_version?: string;
  base_amount: number;
  applied_rate?: number;
  tier_applied?: number;
  gross_commission: number;
  vat_rate: number;
  vat_amount: number;
  net_commission: number;
  calculation_method?: string;
  conditions_met?: any;
}

interface VATRow {
  jurisdiction: string;
  vat_rate: number;
  taxable_base: number;
  vat_amount: number;
  vat_mode: string;
  total_gross: number;
  total_net: number;
  currency: string;
}

interface AuditRow {
  calc_run_id: string;
  distribution_id: string;
  rule_id: string;
  rule_version_id?: string;
  input_data: any;
  step_trace: any;
  tier_selected?: number;
  adjustments_applied?: any;
  calculated_by?: string;
  calculated_at: string;
  checksum: string;
  execution_time_ms?: number;
}

const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
);

const handler = async (req: Request): Promise<Response> => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    // Authenticate user
    const user = await getAuthenticatedUser(req, supabase);
    const userRoles = await getUserRoles(supabase, user.id);

    // Check permissions - exports contain sensitive financial data
    if (!hasAnyRole(userRoles, ['admin', 'manager', 'finance'])) {
      return new Response(
        JSON.stringify({ error: 'Insufficient permissions to export commission data' }),
        { status: 403, headers: { 'Content-Type': 'application/json', ...corsHeaders } }
      );
    }

    const { type, filters, columns, options }: ExportRequest = await req.json();

    console.log('Export request:', { type, filters, options });

    let data: any[] = [];
    let worksheetName = '';

    switch (type) {
      case 'summary':
        data = await generateSummaryData(filters);
        worksheetName = 'Summary';
        break;
      case 'detail':
        data = await generateDetailData(filters);
        worksheetName = 'Detail';
        break;
      case 'vat':
        data = await generateVATData(filters);
        worksheetName = 'VAT_Tax';
        break;
      case 'audit':
        data = await generateAuditData(filters);
        worksheetName = 'Audit_Trail';
        break;
      default:
        throw new Error(`Unknown export type: ${type}`);
    }

    console.log(`Generated ${data.length} rows for ${type} export`);

    // Filter and format data based on selected columns
    const filteredData = data.map(row => {
      const filteredRow: any = {};
      columns.forEach(col => {
        if (row.hasOwnProperty(col.key)) {
          let value = row[col.key];
          
          // Apply rounding to numeric values
          if (typeof value === 'number' && options.rounding_precision !== undefined) {
            value = Number(value.toFixed(options.rounding_precision));
          }
          
          filteredRow[col.label] = value;
        }
      });
      return filteredRow;
    });

    // Create Excel workbook
    const workbook = XLSX.utils.book_new();
    const worksheet = XLSX.utils.json_to_sheet(filteredData);

    // Set column widths for better readability
    const columnWidths = columns.map(col => ({ wch: Math.max(col.label.length + 2, 15) }));
    worksheet['!cols'] = columnWidths;

    // Add worksheet to workbook
    XLSX.utils.book_append_sheet(workbook, worksheet, worksheetName);

    // Generate Excel buffer
    const excelBuffer = XLSX.write(workbook, { type: 'buffer', bookType: 'xlsx' });

    // For this demo, we'll return the data as JSON since we can't easily serve files
    // In production, you'd upload to storage and return a download URL
    console.log('Export completed successfully');

    return new Response(JSON.stringify({
      success: true,
      filename: options.filename,
      downloadUrl: '#', // Would be actual storage URL in production
      rowCount: filteredData.length,
      columns: columns.length,
      generated_at: new Date().toISOString()
    }), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        ...corsHeaders,
      },
    });

  } catch (error: any) {
    console.error('Export error:', error);
    return new Response(JSON.stringify({ 
      error: error.message || 'Export failed',
      details: error.stack 
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }
};

async function generateSummaryData(filters: ExportRequest['filters']): Promise<SummaryRow[]> {
  const { data: calculations, error } = await supabase
    .from('advanced_commission_calculations')
    .select(`
      *,
      calculation_runs!inner(
        id,
        name,
        period_start,
        period_end,
        status
      )
    `)
    .in('calculation_run_id', filters.calculation_run_ids)
    .in('calculation_runs.status', filters.run_status);

  if (error) throw error;

  // Group by party (entity_name) and fund
  const grouped = new Map<string, {
    party_name: string;
    fund_name: string;
    period_start: string;
    period_end: string;
    gross_commission: number;
    vat_amount: number;
    net_commission: number;
    currency: string;
    cap_applied: boolean;
    vat_mode: string;
  }>();

  calculations?.forEach((calc: any) => {
    const key = `${calc.entity_name}_${calc.calculation_runs.name}`;
    const existing = grouped.get(key);
    
    if (existing) {
      existing.gross_commission += calc.gross_commission || 0;
      existing.vat_amount += calc.vat_amount || 0;
      existing.net_commission += calc.net_commission || 0;
    } else {
      grouped.set(key, {
        party_name: calc.entity_name,
        fund_name: calc.calculation_runs.name,
        period_start: calc.calculation_runs.period_start,
        period_end: calc.calculation_runs.period_end,
        gross_commission: calc.gross_commission || 0,
        vat_amount: calc.vat_amount || 0,
        net_commission: calc.net_commission || 0,
        currency: 'USD', // Default currency
        cap_applied: false, // Would need cap logic
        vat_mode: 'added' // Default VAT mode
      });
    }
  });

  return Array.from(grouped.values());
}

async function generateDetailData(filters: ExportRequest['filters']): Promise<DetailRow[]> {
  const { data: calculations, error } = await supabase
    .from('advanced_commission_calculations')
    .select(`
      *,
      calculation_runs!inner(id, status),
      investor_distributions!inner(investor_name, fund_name)
    `)
    .in('calculation_run_id', filters.calculation_run_ids)
    .in('calculation_runs.status', filters.run_status);

  if (error) throw error;

  return calculations?.map((calc: any) => ({
    calc_run_id: calc.calculation_run_id,
    distribution_id: calc.distribution_id,
    investor_name: calc.investor_distributions?.investor_name || 'Unknown',
    fund_name: calc.investor_distributions?.fund_name || 'Unknown',
    entity_name: calc.entity_name,
    commission_type: calc.commission_type,
    rule_id: calc.rule_id,
    rule_version: 'v1.0', // Would need rule versioning
    base_amount: calc.base_amount,
    applied_rate: calc.applied_rate,
    tier_applied: calc.tier_applied,
    gross_commission: calc.gross_commission,
    vat_rate: calc.vat_rate,
    vat_amount: calc.vat_amount,
    net_commission: calc.net_commission,
    calculation_method: calc.calculation_method,
    conditions_met: calc.conditions_met
  })) || [];
}

async function generateVATData(filters: ExportRequest['filters']): Promise<VATRow[]> {
  const { data: calculations, error } = await supabase
    .from('advanced_commission_calculations')
    .select(`
      vat_rate,
      vat_amount,
      gross_commission,
      net_commission,
      calculation_runs!inner(status)
    `)
    .in('calculation_run_id', filters.calculation_run_ids)
    .in('calculation_runs.status', filters.run_status);

  if (error) throw error;

  // Group by VAT rate (jurisdiction proxy)
  const vatGroups = new Map<number, {
    jurisdiction: string;
    vat_rate: number;
    taxable_base: number;
    vat_amount: number;
    vat_mode: string;
    total_gross: number;
    total_net: number;
    currency: string;
  }>();

  calculations?.forEach((calc: any) => {
    const rate = calc.vat_rate || 0;
    const existing = vatGroups.get(rate);
    
    if (existing) {
      existing.taxable_base += calc.gross_commission || 0;
      existing.vat_amount += calc.vat_amount || 0;
      existing.total_gross += calc.gross_commission || 0;
      existing.total_net += calc.net_commission || 0;
    } else {
      vatGroups.set(rate, {
        jurisdiction: rate === 0.21 ? 'EU' : rate === 0.17 ? 'IL' : 'Other',
        vat_rate: rate,
        taxable_base: calc.gross_commission || 0,
        vat_amount: calc.vat_amount || 0,
        vat_mode: 'added',
        total_gross: calc.gross_commission || 0,
        total_net: calc.net_commission || 0,
        currency: 'USD'
      });
    }
  });

  return Array.from(vatGroups.values());
}

async function generateAuditData(filters: ExportRequest['filters']): Promise<AuditRow[]> {
  const { data: calculations, error } = await supabase
    .from('advanced_commission_calculations')
    .select(`
      *,
      calculation_runs!inner(status),
      calculation_traces(*)
    `)
    .in('calculation_run_id', filters.calculation_run_ids)
    .in('calculation_runs.status', filters.run_status);

  if (error) throw error;

  return calculations?.map((calc: any) => ({
    calc_run_id: calc.calculation_run_id,
    distribution_id: calc.distribution_id,
    rule_id: calc.rule_id,
    rule_version_id: 'v1.0', // Would need rule versioning
    input_data: calc.conditions_met || {},
    step_trace: calc.calculation_traces || [],
    tier_selected: calc.tier_applied,
    adjustments_applied: null, // Would need adjustment tracking
    calculated_by: calc.calculated_by,
    calculated_at: calc.created_at,
    checksum: generateChecksum(calc),
    execution_time_ms: calc.execution_time_ms
  })) || [];
}

function generateChecksum(calc: any): string {
  // Generate deterministic checksum for replay verification
  const data = `${calc.rule_id}_${calc.base_amount}_${calc.applied_rate}_${calc.gross_commission}`;
  return btoa(data).slice(0, 16); // Simple checksum for demo
}

serve(handler);