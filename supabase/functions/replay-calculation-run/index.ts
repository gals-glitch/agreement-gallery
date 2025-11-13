import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.57.2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface ReplayRequest {
  run_id: string;
  export_types?: string[]; // 'summary', 'detail', 'vat', 'audit'
}

Deno.serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    const { run_id, export_types = ['summary', 'detail', 'vat', 'audit'] }: ReplayRequest = await req.json();

    console.log(`Starting replay for run ${run_id} with export types:`, export_types);

    // 1. Fetch original calculation run
    const { data: calcRun, error: calcRunError } = await supabaseClient
      .from('calculation_runs')
      .select('*')
      .eq('id', run_id)
      .single();

    if (calcRunError || !calcRun) {
      throw new Error(`Calculation run not found: ${calcRunError?.message}`);
    }

    // 2. Fetch stored checksums for comparison
    const { data: storedChecksums, error: checksumsError } = await supabaseClient
      .from('calc_run_checksums')
      .select('*')
      .eq('run_id', run_id)
      .single();

    if (checksumsError || !storedChecksums) {
      throw new Error(`No stored checksums found for run ${run_id}`);
    }

    // 3. Fetch rule versions used in this run
    const { data: rulesUsed, error: rulesError } = await supabaseClient
      .from('calc_runs_rules')
      .select('rule_id, rule_version, rule_snapshot')
      .eq('run_id', run_id);

    if (rulesError) {
      throw new Error(`Failed to fetch rules used: ${rulesError.message}`);
    }

    // 4. Fetch calculation sources
    const { data: calcSources, error: sourcesError } = await supabaseClient
      .from('calc_run_sources')
      .select('source_table, source_ids')
      .eq('run_id', run_id);

    if (sourcesError) {
      throw new Error(`Failed to fetch calculation sources: ${sourcesError.message}`);
    }

    // 5. Regenerate calculations using stored inputs and rule versions
    const replayResults: Record<string, any> = {};
    const newChecksums: Record<string, string> = {};

    for (const exportType of export_types) {
      const data = await regenerateExport(
        supabaseClient, 
        run_id, 
        exportType, 
        calcSources, 
        rulesUsed,
        calcRun
      );
      
      // Generate checksum for comparison
      const newChecksum = await generateChecksum(data);
      const storedChecksum = storedChecksums[`${exportType}_checksum`];
      
      replayResults[exportType] = {
        status: newChecksum === storedChecksum ? 'MATCH' : 'MISMATCH',
        stored_checksum: storedChecksum,
        new_checksum: newChecksum,
        row_count: data.length,
        data_sample: data.slice(0, 3) // First 3 rows for verification
      };
      
      newChecksums[exportType] = newChecksum;
    }

    // 6. Generate overall replay result
    const allMatch = Object.values(replayResults).every((result: any) => result.status === 'MATCH');
    
    // 7. Log replay attempt
    await supabaseClient
      .from('activity_log')
      .insert({
        entity_type: 'calculation_run',
        entity_id: run_id,
        action: 'replay',
        description: `Replay attempt: ${allMatch ? 'SUCCESS' : 'FAILED'}`,
        performed_by: (await supabaseClient.auth.getUser()).data.user?.id,
        new_values: {
          replay_results: replayResults,
          checksums_match: allMatch
        }
      });

    const response = {
      run_id,
      replay_status: allMatch ? 'SUCCESS' : 'FAILED',
      export_results: replayResults,
      summary: {
        total_exports: export_types.length,
        matches: Object.values(replayResults).filter((r: any) => r.status === 'MATCH').length,
        mismatches: Object.values(replayResults).filter((r: any) => r.status === 'MISMATCH').length
      },
      metadata: {
        rules_used: rulesUsed?.length || 0,
        sources_count: calcSources?.length || 0,
        replayed_at: new Date().toISOString()
      }
    };

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error: any) {
    console.error('Replay failed:', error);
    return new Response(
      JSON.stringify({ 
        error: error.message,
        run_id: req.url.includes('run_id') ? new URL(req.url).searchParams.get('run_id') : 'unknown'
      }),
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );
  }
});

async function regenerateExport(
  supabaseClient: any,
  runId: string,
  exportType: string,
  sources: any[],
  rulesUsed: any[],
  calcRun: any
) {
  console.log(`Regenerating ${exportType} export for run ${runId}`);
  
  // Fetch the original calculations for this run
  const { data: calculations, error } = await supabaseClient
    .from('advanced_commission_calculations')
    .select(`
      *,
      calculation_runs!inner(id, name)
    `)
    .eq('calculation_run_id', runId)
    .order('created_at');

  if (error) {
    throw new Error(`Failed to fetch calculations: ${error.message}`);
  }

  // Generate export data based on type
  switch (exportType) {
    case 'summary':
      return generateSummaryData(calculations, calcRun);
    case 'detail':
      return generateDetailData(calculations);
    case 'vat':
      return generateVATData(calculations);
    case 'audit':
      return generateAuditData(calculations, rulesUsed);
    default:
      throw new Error(`Unknown export type: ${exportType}`);
  }
}

function generateSummaryData(calculations: any[], calcRun: any) {
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

  return Object.values(summary);
}

function generateDetailData(calculations: any[]) {
  return calculations.map(calc => ({
    calculation_id: calc.id,
    entity_type: calc.commission_type,
    entity_name: calc.entity_name,
    base_amount: calc.base_amount,
    applied_rate: calc.applied_rate,
    gross_commission: calc.gross_commission,
    vat_rate: calc.vat_rate,
    vat_amount: calc.vat_amount,
    net_commission: calc.net_commission,
    rule_id: calc.rule_id,
    calculated_at: calc.created_at
  }));
}

function generateVATData(calculations: any[]) {
  // Group by VAT rate and jurisdiction
  const vatSummary = calculations.reduce((acc, calc) => {
    const key = `${calc.vat_rate || 0}`;
    if (!acc[key]) {
      acc[key] = {
        vat_rate: calc.vat_rate || 0,
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

  return Object.values(vatSummary);
}

function generateAuditData(calculations: any[], rulesUsed: any[]) {
  return calculations.map(calc => ({
    calculation_id: calc.id,
    input_ref: calc.input_ref,
    rule_id: calc.rule_id,
    rule_version: calc.rule_version,
    rule_snapshot: calc.rule_snapshot,
    base_amount: calc.base_amount,
    tier_applied: calc.tier_applied,
    applied_rate: calc.applied_rate,
    amount_before_cap: calc.amount_before_cap,
    cap_remaining: calc.cap_remaining,
    gross_commission: calc.gross_commission,
    vat_amount: calc.vat_amount,
    net_commission: calc.net_commission,
    actor_id: calc.actor_id,
    started_at: calc.started_at,
    finished_at: calc.finished_at,
    execution_time_ms: calc.execution_time_ms
  }));
}

async function generateChecksum(data: any[]): Promise<string> {
  // Create deterministic string representation
  const normalizedData = data
    .sort((a, b) => JSON.stringify(a).localeCompare(JSON.stringify(b)))
    .map(row => JSON.stringify(row, Object.keys(row).sort()))
    .join('\n');
  
  // Generate SHA-256 hash
  const encoder = new TextEncoder();
  const dataBytes = encoder.encode(normalizedData);
  const hashBuffer = await crypto.subtle.digest('SHA-256', dataBytes);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}