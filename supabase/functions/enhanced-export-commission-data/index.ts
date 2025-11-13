import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.57.2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface EnhancedExportRequest {
  run_id: string;
  export_types: string[];
  include_metadata?: boolean;
  rounding_precision?: number;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    const { 
      run_id, 
      export_types,
      include_metadata = true,
      rounding_precision = 2 
    }: EnhancedExportRequest = await req.json();

    console.log(`Enhanced export for run ${run_id}, types:`, export_types);

    // 1. Fetch calculation run details
    const { data: calcRun, error: calcRunError } = await supabaseClient
      .from('calculation_runs')
      .select('*')
      .eq('id', run_id)
      .single();

    if (calcRunError || !calcRun) {
      throw new Error(`Calculation run not found: ${calcRunError?.message}`);
    }

    // 2. Fetch calculations for this run
    const { data: calculations, error: calcError } = await supabaseClient
      .from('advanced_commission_calculations')
      .select('*')
      .eq('calculation_run_id', run_id)
      .order('created_at');

    if (calcError) {
      throw new Error(`Failed to fetch calculations: ${calcError.message}`);
    }

    // 3. Generate exports with enhanced metadata and reconciliation
    const exports: Record<string, any> = {};
    let totalRoundingDiff = 0;

    for (const exportType of export_types) {
      const { data, metadata } = await generateEnhancedExport(
        calculations, 
        calcRun, 
        exportType,
        rounding_precision
      );

      // Calculate checksum for this export
      const checksum = await generateChecksum(data);
      
      // Track rounding differences
      if ('rounding_diff' in metadata && typeof metadata.rounding_diff === 'number') {
        totalRoundingDiff += metadata.rounding_diff;
      }

      exports[exportType] = {
        data,
        metadata: {
          ...metadata,
          checksum,
          export_type: exportType,
          generated_at: new Date().toISOString(),
          app_version: '1.0.0',
          rounding_precision
        }
      };

      // Store export job metadata
      if (include_metadata) {
        await supabaseClient
          .from('export_jobs')
          .insert({
            run_id,
            export_type: exportType,
            file_name: `run_${calcRun.name || run_id}_${new Date().toISOString().slice(0, 16).replace(/[T:]/g, '_')}_${exportType}.xlsx`,
            checksum,
            row_count: data.length,
            rounding_diff: ('rounding_diff' in metadata) ? metadata.rounding_diff || 0 : 0,
            created_by: (await supabaseClient.auth.getUser()).data.user?.id,
            app_version: '1.0.0',
            metadata: {
              columns: metadata.columns,
              totals: ('totals' in metadata) ? metadata.totals : null,
              reconciliation: ('reconciliation' in metadata) ? metadata.reconciliation : null
            }
          });
      }
    }

    // 4. Perform reconciliation checks
    const reconciliation = performReconciliationChecks(exports, totalRoundingDiff);

    // 5. Store checksums for replay capability
    if (export_types.length === 4) { // All export types
      const checksumData = {
        run_id,
        summary_checksum: exports.summary?.metadata.checksum || '',
        detail_checksum: exports.detail?.metadata.checksum || '',
        vat_checksum: exports.vat?.metadata.checksum || '',
        audit_checksum: exports.audit?.metadata.checksum || '',
        inputs_checksum: await generateInputsChecksum(supabaseClient, run_id)
      };

      await supabaseClient
        .from('calc_run_checksums')
        .upsert(checksumData);
    }

    const response = {
      run_id,
      exports,
      reconciliation,
      metadata: {
        total_exports: export_types.length,
        total_rounding_diff: totalRoundingDiff,
        reconciliation_status: reconciliation.status,
        generated_at: new Date().toISOString()
      }
    };

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error: any) {
    console.error('Enhanced export failed:', error);
    return new Response(
      JSON.stringify({ error: error.message }), 
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );
  }
});

async function generateEnhancedExport(
  calculations: any[],
  calcRun: any,
  exportType: string,
  precision: number
) {
  switch (exportType) {
    case 'summary':
      return generateSummaryExport(calculations, calcRun, precision);
    case 'detail':
      return generateDetailExport(calculations, precision);
    case 'vat':
      return generateVATExport(calculations, precision);
    case 'audit':
      return generateAuditExport(calculations, precision);
    default:
      throw new Error(`Unknown export type: ${exportType}`);
  }
}

function generateSummaryExport(calculations: any[], calcRun: any, precision: number) {
  // Group by entity and sum amounts
  const summary = calculations.reduce((acc, calc) => {
    const key = `${calc.commission_type}_${calc.entity_name}`;
    if (!acc[key]) {
      acc[key] = {
        entity_type: calc.commission_type,
        entity_name: calc.entity_name,
        gross_commission: 0,
        vat_amount: 0,
        net_commission: 0,
        line_count: 0
      };
    }
    acc[key].gross_commission += parseFloat(calc.gross_commission || 0);
    acc[key].vat_amount += parseFloat(calc.vat_amount || 0);
    acc[key].net_commission += parseFloat(calc.net_commission || 0);
    acc[key].line_count += 1;
    return acc;
  }, {});

  const data = Object.values(summary).map((row: any) => ({
    ...row,
    gross_commission: parseFloat(row.gross_commission.toFixed(precision)),
    vat_amount: parseFloat(row.vat_amount.toFixed(precision)),
    net_commission: parseFloat(row.net_commission.toFixed(precision))
  }));

  const totals = data.reduce((acc, row: any) => ({
    gross_commission: acc.gross_commission + row.gross_commission,
    vat_amount: acc.vat_amount + row.vat_amount,
    net_commission: acc.net_commission + row.net_commission,
    line_count: acc.line_count + row.line_count
  }), { gross_commission: 0, vat_amount: 0, net_commission: 0, line_count: 0 });

  return {
    data,
    metadata: {
      columns: ['entity_type', 'entity_name', 'gross_commission', 'vat_amount', 'net_commission', 'line_count'],
      totals,
      row_count: data.length,
      export_type: 'summary'
    }
  };
}

function generateDetailExport(calculations: any[], precision: number) {
  const data = calculations.map(calc => ({
    calculation_id: calc.id,
    entity_type: calc.commission_type,
    entity_name: calc.entity_name,
    base_amount: parseFloat((calc.base_amount || 0).toFixed(precision)),
    applied_rate: calc.applied_rate,
    gross_commission: parseFloat((calc.gross_commission || 0).toFixed(precision)),
    vat_rate: calc.vat_rate,
    vat_amount: parseFloat((calc.vat_amount || 0).toFixed(precision)),
    net_commission: parseFloat((calc.net_commission || 0).toFixed(precision)),
    rule_id: calc.rule_id,
    calculated_at: calc.created_at
  }));

  const totals = data.reduce((acc, row) => ({
    gross_commission: acc.gross_commission + row.gross_commission,
    vat_amount: acc.vat_amount + row.vat_amount,
    net_commission: acc.net_commission + row.net_commission
  }), { gross_commission: 0, vat_amount: 0, net_commission: 0 });

  return {
    data,
    metadata: {
      columns: ['calculation_id', 'entity_type', 'entity_name', 'base_amount', 'applied_rate', 'gross_commission', 'vat_rate', 'vat_amount', 'net_commission', 'rule_id', 'calculated_at'],
      totals,
      row_count: data.length,
      export_type: 'detail'
    }
  };
}

function generateVATExport(calculations: any[], precision: number) {
  // Group by VAT rate
  const vatSummary = calculations.reduce((acc, calc) => {
    const rate = calc.vat_rate || 0;
    const key = rate.toString();
    if (!acc[key]) {
      acc[key] = {
        vat_rate: rate,
        gross_amount: 0,
        vat_amount: 0,
        net_amount: 0,
        line_count: 0
      };
    }
    acc[key].gross_amount += parseFloat(calc.gross_commission || 0);
    acc[key].vat_amount += parseFloat(calc.vat_amount || 0);
    acc[key].net_amount += parseFloat(calc.net_commission || 0);
    acc[key].line_count += 1;
    return acc;
  }, {});

  const data = Object.values(vatSummary).map((row: any) => ({
    ...row,
    gross_amount: parseFloat(row.gross_amount.toFixed(precision)),
    vat_amount: parseFloat(row.vat_amount.toFixed(precision)),
    net_amount: parseFloat(row.net_amount.toFixed(precision))
  }));

  const totals = data.reduce((acc, row: any) => ({
    gross_amount: acc.gross_amount + row.gross_amount,
    vat_amount: acc.vat_amount + row.vat_amount,
    net_amount: acc.net_amount + row.net_amount
  }), { gross_amount: 0, vat_amount: 0, net_amount: 0 });

  return {
    data,
    metadata: {
      columns: ['vat_rate', 'gross_amount', 'vat_amount', 'net_amount', 'line_count'],
      totals,
      row_count: data.length,
      export_type: 'vat'
    }
  };
}

function generateAuditExport(calculations: any[], precision: number) {
  const data = calculations.map(calc => ({
    calculation_id: calc.id,
    input_ref: calc.input_ref,
    rule_id: calc.rule_id,
    rule_version: calc.rule_version,
    rule_snapshot: calc.rule_snapshot,
    base_amount: parseFloat((calc.base_amount || 0).toFixed(precision)),
    tier_applied: calc.tier_applied,
    applied_rate: calc.applied_rate,
    amount_before_cap: parseFloat((calc.amount_before_cap || 0).toFixed(precision)),
    cap_remaining: parseFloat((calc.cap_remaining || 0).toFixed(precision)),
    gross_commission: parseFloat((calc.gross_commission || 0).toFixed(precision)),
    vat_amount: parseFloat((calc.vat_amount || 0).toFixed(precision)),
    net_commission: parseFloat((calc.net_commission || 0).toFixed(precision)),
    actor_id: calc.actor_id,
    started_at: calc.started_at,
    finished_at: calc.finished_at,
    execution_time_ms: calc.execution_time_ms
  }));

  return {
    data,
    metadata: {
      columns: ['calculation_id', 'input_ref', 'rule_id', 'rule_version', 'rule_snapshot', 'base_amount', 'tier_applied', 'applied_rate', 'amount_before_cap', 'cap_remaining', 'gross_commission', 'vat_amount', 'net_commission', 'actor_id', 'started_at', 'finished_at', 'execution_time_ms'],
      row_count: data.length,
      export_type: 'audit'
    }
  };
}

function performReconciliationChecks(exports: Record<string, any>, totalRoundingDiff: number) {
  const checks = [];
  
  // Check if summary and detail totals match
  if (exports.summary && exports.detail) {
    const summaryTotal = exports.summary.metadata.totals.net_commission;
    const detailTotal = exports.detail.metadata.totals.net_commission;
    const diff = Math.abs(summaryTotal - detailTotal);
    
    checks.push({
      check: 'summary_detail_reconciliation',
      status: diff <= Math.abs(totalRoundingDiff) + 0.01 ? 'PASS' : 'FAIL',
      expected: summaryTotal,
      actual: detailTotal,
      difference: diff
    });
  }

  // Check if VAT totals match summary VAT
  if (exports.summary && exports.vat) {
    const summaryVAT = exports.summary.metadata.totals.vat_amount;
    const vatTotal = exports.vat.metadata.totals.vat_amount;
    const diff = Math.abs(summaryVAT - vatTotal);
    
    checks.push({
      check: 'summary_vat_reconciliation',
      status: diff <= 0.01 ? 'PASS' : 'FAIL',
      expected: summaryVAT,
      actual: vatTotal,
      difference: diff
    });
  }

  const allPassed = checks.every(check => check.status === 'PASS');
  
  return {
    status: allPassed ? 'PASS' : 'FAIL',
    checks,
    total_rounding_diff: totalRoundingDiff
  };
}

async function generateChecksum(data: any[]): Promise<string> {
  const normalizedData = data
    .sort((a, b) => JSON.stringify(a).localeCompare(JSON.stringify(b)))
    .map(row => JSON.stringify(row, Object.keys(row).sort()))
    .join('\n');
  
  const encoder = new TextEncoder();
  const dataBytes = encoder.encode(normalizedData);
  const hashBuffer = await crypto.subtle.digest('SHA-256', dataBytes);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}

async function generateInputsChecksum(supabaseClient: any, runId: string): Promise<string> {
  // Get all distributions used in this calculation run
  const { data: distributions } = await supabaseClient
    .from('investor_distributions')
    .select('id')
    .eq('calculation_run_id', runId)
    .order('id');

  const inputIds = (distributions || []).map((d: any) => d.id).sort();
  return generateChecksum(inputIds);
}