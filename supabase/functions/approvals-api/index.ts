// Approvals API Edge Function
// Feature: FEATURE_APPROVALS
// Handles workflow approval transitions for calculation runs

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface ApprovalStep {
  step: 'ops_review' | 'finance_review' | 'final_approval';
  approver_role: 'ops' | 'finance' | 'manager' | 'admin';
  status: 'pending' | 'approved' | 'rejected';
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Authenticate user
    const authHeader = req.headers.get('Authorization')!;
    const token = authHeader.replace('Bearer ', '');
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);

    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const url = new URL(req.url);
    const pathParts = url.pathname.split('/');
    const runId = pathParts[pathParts.length - 2]; // e.g., /approvals-api/{runId}/submit
    const action = pathParts[pathParts.length - 1]; // submit, approve, reject

    // Route handling
    switch (action) {
      case 'submit':
        return await handleSubmit(supabase, runId, user.id);
      case 'approve':
        return await handleApprove(supabase, runId, user.id, req);
      case 'reject':
        return await handleReject(supabase, runId, user.id, req);
      case 'status':
        return await handleGetStatus(supabase, runId);
      default:
        return new Response(JSON.stringify({ error: 'Invalid action' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
    }
  } catch (error) {
    console.error('Error:', error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});

// Submit run for approval (draft/in_progress → awaiting_approval)
async function handleSubmit(supabase: any, runId: string, userId: string) {
  // Check run exists and is in valid state
  const { data: run, error: runError } = await supabase
    .from('calculation_runs')
    .select('id, status, created_by')
    .eq('id', runId)
    .single();

  if (runError || !run) {
    return new Response(JSON.stringify({ error: 'Run not found' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  if (!['draft', 'in_progress', 'completed'].includes(run.status)) {
    return new Response(
      JSON.stringify({ error: `Cannot submit run with status: ${run.status}` }),
      {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }

  // Update run status
  const { error: updateError } = await supabase
    .from('calculation_runs')
    .update({ status: 'awaiting_approval', updated_at: new Date().toISOString() })
    .eq('id', runId);

  if (updateError) {
    throw updateError;
  }

  // Create approval steps
  const approvalSteps: ApprovalStep[] = [
    { step: 'ops_review', approver_role: 'ops', status: 'pending' },
    { step: 'finance_review', approver_role: 'finance', status: 'pending' },
    { step: 'final_approval', approver_role: 'manager', status: 'pending' },
  ];

  const { error: insertError } = await supabase
    .from('workflow_approvals')
    .insert(
      approvalSteps.map((step) => ({
        run_id: runId,
        ...step,
        created_at: new Date().toISOString(),
      }))
    );

  if (insertError) {
    throw insertError;
  }

  return new Response(
    JSON.stringify({
      success: true,
      message: 'Run submitted for approval',
      run_id: runId,
      steps: approvalSteps,
    }),
    {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}

// Approve a specific step
async function handleApprove(supabase: any, runId: string, userId: string, req: Request) {
  const body = await req.json();
  const { step, comment } = body;

  // Check user has appropriate role
  const { data: userRoles } = await supabase
    .from('user_roles')
    .select('role')
    .eq('user_id', userId);

  const roles = userRoles?.map((r: any) => r.role) || [];

  // Get the approval record
  const { data: approval, error: approvalError } = await supabase
    .from('workflow_approvals')
    .select('*')
    .eq('run_id', runId)
    .eq('step', step)
    .eq('status', 'pending')
    .single();

  if (approvalError || !approval) {
    return new Response(JSON.stringify({ error: 'Approval step not found or already processed' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // RBAC check
  if (!roles.includes(approval.approver_role) && !roles.includes('admin')) {
    return new Response(
      JSON.stringify({ error: `Unauthorized: requires ${approval.approver_role} role` }),
      {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }

  // Update approval step
  const { error: updateError } = await supabase
    .from('workflow_approvals')
    .update({
      status: 'approved',
      acted_by: userId,
      acted_at: new Date().toISOString(),
      comment: comment || null,
    })
    .eq('id', approval.id);

  if (updateError) {
    throw updateError;
  }

  // Check if all steps are approved
  const { data: allApprovals } = await supabase
    .from('workflow_approvals')
    .select('status')
    .eq('run_id', runId);

  const allApproved = allApprovals?.every((a: any) => a.status === 'approved');

  if (allApproved) {
    // Update run status to approved
    await supabase
      .from('calculation_runs')
      .update({ status: 'approved', updated_at: new Date().toISOString() })
      .eq('id', runId);
  }

  return new Response(
    JSON.stringify({
      success: true,
      message: `Step ${step} approved`,
      run_id: runId,
      all_approved: allApproved,
      run_status: allApproved ? 'approved' : 'awaiting_approval',
    }),
    {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}

// Reject a step (revert to in_progress)
async function handleReject(supabase: any, runId: string, userId: string, req: Request) {
  const body = await req.json();
  const { step, comment } = body;

  if (!comment) {
    return new Response(JSON.stringify({ error: 'Comment required for rejection' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // Get the approval record
  const { data: approval } = await supabase
    .from('workflow_approvals')
    .select('*')
    .eq('run_id', runId)
    .eq('step', step)
    .eq('status', 'pending')
    .single();

  if (!approval) {
    return new Response(JSON.stringify({ error: 'Approval step not found' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // Update approval step
  await supabase
    .from('workflow_approvals')
    .update({
      status: 'rejected',
      acted_by: userId,
      acted_at: new Date().toISOString(),
      comment,
    })
    .eq('id', approval.id);

  // Revert run status to in_progress
  await supabase
    .from('calculation_runs')
    .update({ status: 'in_progress', updated_at: new Date().toISOString() })
    .eq('id', runId);

  return new Response(
    JSON.stringify({
      success: true,
      message: `Step ${step} rejected`,
      run_id: runId,
      run_status: 'in_progress',
      comment,
    }),
    {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}

// Get approval status for a run
async function handleGetStatus(supabase: any, runId: string) {
  const { data: approvals, error } = await supabase
    .from('workflow_approvals')
    .select(`
      *,
      acted_by_user:auth.users!workflow_approvals_acted_by_fkey(email)
    `)
    .eq('run_id', runId)
    .order('created_at', { ascending: true });

  if (error) {
    throw error;
  }

  const { data: run } = await supabase
    .from('calculation_runs')
    .select('id, name, status')
    .eq('id', runId)
    .single();

  return new Response(
    JSON.stringify({
      run,
      approvals: approvals || [],
    }),
    {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}
