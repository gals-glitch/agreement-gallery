import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { getAuthenticatedUser, getUserRoles, hasAnyRole } from '../_shared/auth.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Authenticate user
    const user = await getAuthenticatedUser(req, supabase)
    const userRoles = await getUserRoles(supabase, user.id)
    
    console.log(`Authenticated user: ${user.id}, roles: ${userRoles.join(', ')}`)

    const url = new URL(req.url)
    const pathParts = url.pathname.split('/').filter(Boolean)
    const method = req.method
    const runId = pathParts[1] // fee-runs-api/[runId]/...
    const action = pathParts[2] // calculate, progress, etc.

    console.log(`Fee Runs API: ${method} ${url.pathname}`)

    // GET /fee-runs-api - List all runs
    if (method === 'GET' && !runId) {
      const { data: runs, error } = await supabase
        .from('calculation_runs')
        .select('*')
        .order('created_at', { ascending: false })

      if (error) {
        console.error('Error listing runs:', error)
        return new Response(JSON.stringify({ error: error.message }), {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        })
      }

      // Transform to match expected format
      const transformedRuns = runs.map((run: any) => ({
        id: run.id,
        period_start: run.period_start,
        period_end: run.period_end,
        cut_off_label: run.name,
        status: run.status,
        totals: run.total_gross_fees ? {
          base: run.total_gross_fees,
          vat: run.total_vat || 0,
          net: run.total_net_payable || 0,
          total: run.total_gross_fees + (run.total_vat || 0)
        } : undefined,
        exceptions_count: 0, // TODO: Calculate from exceptions table
        created_at: run.created_at,
        updated_at: run.updated_at,
        progress_percentage: run.progress_percentage || 0
      }))

      return new Response(JSON.stringify({ data: transformedRuns }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // POST /fee-runs-api - Create new run
    if (method === 'POST' && !runId) {
      // Check permissions for create operation
      if (!hasAnyRole(userRoles, ['admin', 'manager'])) {
        return new Response(
          JSON.stringify({ error: 'Insufficient permissions to create runs' }), 
          { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      let body;
      try {
        const text = await req.text()
        body = text ? JSON.parse(text) : {}
      } catch (e) {
        body = {}
      }
      const { period_start, period_end, cut_off_label } = body

      const { data: run, error } = await supabase
        .from('calculation_runs')
        .insert({
          name: cut_off_label,
          period_start,
          period_end,
          status: 'draft',
          created_by: user.id
        })
        .select()
        .single()

      if (error) {
        console.error('Error creating run:', error)
        return new Response(JSON.stringify({ error: error.message }), {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        })
      }

      return new Response(JSON.stringify({ id: (run as any).id }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // GET /fee-runs-api/{id} - Get single run
    if (method === 'GET' && runId && !action) {
      const { data: run, error } = await supabase
        .from('calculation_runs')
        .select('*')
        .eq('id', runId)
        .single()

      if (error) {
        console.error('Error getting run:', error)
        return new Response(JSON.stringify({ error: error.message }), {
          status: 404,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        })
      }

      const transformedRun = {
        id: (run as any).id,
        period_start: (run as any).period_start,
        period_end: (run as any).period_end,
        cut_off_label: (run as any).name,
        status: (run as any).status,
        totals: (run as any).total_gross_fees ? {
          base: (run as any).total_gross_fees,
          vat: (run as any).total_vat || 0,
          net: (run as any).total_net_payable || 0,
          total: (run as any).total_gross_fees + ((run as any).total_vat || 0)
        } : undefined,
        exceptions_count: 0,
        created_at: (run as any).created_at,
        updated_at: (run as any).updated_at,
        progress_percentage: (run as any).progress_percentage || 0
      }

      return new Response(JSON.stringify({ data: transformedRun }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // POST /fee-runs-api/{id}/calculate - Start calculation
    if (method === 'POST' && runId && action === 'calculate') {
      // Check permissions for calculate operation
      if (!hasAnyRole(userRoles, ['admin', 'manager'])) {
        return new Response(
          JSON.stringify({ error: 'Insufficient permissions to calculate runs' }), 
          { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      try {
        // 1. Load inputs (distributions) for this run
        const { data: distributions, error: distError } = await supabase
          .from('investor_distributions')
          .select('*')
          .eq('calculation_run_id', runId)

        if (distError) throw distError

        // 2. Load configuration
        const { data: tracks, error: tracksError } = await supabase
          .from('fund_vi_tracks')
          .select('*')
          .eq('is_active', true)

        if (tracksError) throw tracksError

        const config_version = tracks?.[0]?.config_version || 'v1.0'

        // 3. Compute run hash (deterministic)
        const { computeRunHash } = await import('./hash-utils.ts')
        const run_hash = await computeRunHash({
          config_version,
          inputs: distributions || [],
          settings: { vat_mode: 'added', rounding: 'HALF_EVEN' }
        })

        // 4. TODO: Perform actual calculations here
        // For now, mock the outputs
        const mockOutputs = {
          fee_lines: [],
          total_gross: 0,
          total_vat: 0,
          total_net: 0,
          scope_breakdown: {
            FUND: { gross: 0, vat: 0, net: 0, count: 0 },
            DEAL: { gross: 0, vat: 0, net: 0, count: 0 }
          }
        }

        // 5. Store run_record atomically
        const { error: recordError } = await supabase
          .from('run_records')
          .insert({
            calculation_run_id: runId,
            config_version,
            run_hash,
            inputs: { distributions: distributions || [] },
            outputs: mockOutputs,
            scope_breakdown: mockOutputs.scope_breakdown,
            created_by: user.id
          })

        if (recordError) {
          console.error('Error storing run record:', recordError)
        }

        // 6. Update run status
        const { error: updateError } = await supabase
          .from('calculation_runs')
          .update({ 
            status: 'reviewed',
            progress_percentage: 100,
            started_by: user.id,
            total_gross_fees: mockOutputs.total_gross,
            total_vat: mockOutputs.total_vat,
            total_net_payable: mockOutputs.total_net
          })
          .eq('id', runId)

        if (updateError) throw updateError

        console.log(`Calculation complete for run ${runId}, hash: ${run_hash}`)

        return new Response(JSON.stringify({ 
          jobId: `job_${runId}_${Date.now()}`,
          run_hash 
        }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        })
      } catch (error: any) {
        console.error('Calculation failed:', error)
        return new Response(JSON.stringify({ error: error.message }), {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        })
      }
    }

    // GET /fee-runs-api/{id}/progress - Get calculation progress
    if (method === 'GET' && runId && action === 'progress') {
      const { data: run, error } = await supabase
        .from('calculation_runs')
        .select('progress_percentage, status')
        .eq('id', runId)
        .single()

      if (error) {
        console.error('Error getting progress:', error)
        return new Response(JSON.stringify({ error: error.message }), {
          status: 404,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        })
      }

      const progress = (run as any)?.progress_percentage || 0

      return new Response(JSON.stringify({ 
        data: {
          step: progress < 20 ? 'import' : progress < 40 ? 'match' : progress < 80 ? 'calculate' : progress < 95 ? 'review' : 'export',
          percent: progress,
          eta_sec: progress < 100 ? Math.max(10, (100 - progress) * 3) : undefined,
          counters: {
            distributions_processed: Math.floor(progress * 1.2),
            calculations_completed: Math.floor(progress * 0.8),
            exceptions_found: 0 // TODO: Get actual count
          }
        }
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // GET /fee-runs-api/{id}/summary - Get run summary with scope breakdown
    if (method === 'GET' && runId && action === 'summary') {
      const { data: run, error } = await supabase
        .from('calculation_runs')
        .select('total_gross_fees, total_vat, total_net_payable')
        .eq('id', runId)
        .single()

      if (error) {
        console.error('Error getting summary:', error)
        return new Response(JSON.stringify({ error: error.message }), {
          status: 404,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        })
      }

      // Try to get scope breakdown from run_record
      const { data: record } = await supabase
        .from('run_records')
        .select('scope_breakdown')
        .eq('calculation_run_id', runId)
        .single()

      const scopeBreakdown = record?.scope_breakdown

      return new Response(JSON.stringify({ 
        data: {
          totals: (run as any).total_gross_fees ? {
            base: (run as any).total_gross_fees,
            vat: (run as any).total_vat || 0,
            net: (run as any).total_net_payable || 0,
            total: (run as any).total_gross_fees + ((run as any).total_vat || 0)
          } : undefined,
          scope_breakdown: scopeBreakdown,
          exceptions_count: 0 // TODO: Calculate actual count
        }
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // GET /fee-runs-api/{id}/detail - Get stored run outputs for re-export
    if (method === 'GET' && runId && action === 'detail') {
      const { data: record, error } = await supabase
        .from('run_records')
        .select('*')
        .eq('calculation_run_id', runId)
        .single()

      if (error) {
        console.error('Error getting run detail:', error)
        return new Response(JSON.stringify({ error: error.message }), {
          status: 404,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        })
      }

      return new Response(JSON.stringify({ 
        data: {
          run_hash: record.run_hash,
          config_version: record.config_version,
          inputs: record.inputs,
          outputs: record.outputs,
          scope_breakdown: record.scope_breakdown,
          created_at: record.created_at
        }
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // POST /fee-runs-api/{id}/approve - Approve run (reviewed/approved)
    if (method === 'POST' && runId && action === 'approve') {
      // Check permissions for approve operation
      if (!hasAnyRole(userRoles, ['admin', 'manager'])) {
        return new Response(
          JSON.stringify({ error: 'Insufficient permissions to approve runs' }), 
          { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      let body;
      try {
        const text = await req.text()
        body = text ? JSON.parse(text) : {}
      } catch (e) {
        body = {}
      }
      const { stage } = body // 'reviewed' or 'approved'

      const { error } = await supabase
        .from('calculation_runs')
        .update({ 
          status: stage,
          progress_percentage: stage === 'approved' ? 100 : undefined
        })
        .eq('id', runId)

      if (error) {
        console.error('Error approving run:', error)
        return new Response(JSON.stringify({ error: error.message }), {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        })
      }

      return new Response(JSON.stringify({ success: true }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // GET /fee-runs-api/{id}/exceptions - Get exceptions
    if (method === 'GET' && runId && action === 'exceptions') {
      // Mock exceptions for now - TODO: Create exceptions table
      const mockExceptions = [
        {
          id: 'ex-001',
          code: 'MISSING_INVESTOR_DATA',
          severity: 'high',
          message: 'Investor "Omega Holdings LLC" missing tax residency information',
          entity_type: 'investor',
          entity_id: 'inv-001',
          suggested_fix: 'Update investor profile with tax residency',
          resolved: false,
        }
      ]

      return new Response(JSON.stringify({ data: mockExceptions }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // POST /fee-runs-api/{id}/resolve-exception - Resolve exception
    if (method === 'POST' && runId && action === 'resolve-exception') {
      let body;
      try {
        const text = await req.text()
        body = text ? JSON.parse(text) : {}
      } catch (e) {
        body = {}
      }
      const { exceptionId } = body

      // TODO: Mark exception as resolved in database
      console.log(`Resolved exception ${exceptionId} for run ${runId}`)

      return new Response(JSON.stringify({ success: true }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    return new Response(JSON.stringify({ error: 'Not found' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })

  } catch (error) {
    console.error('Unexpected error:', error)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})