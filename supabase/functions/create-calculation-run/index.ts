// Supabase Edge Function: create-calculation-run
// Creates a calculation run with proper authentication and authorization

import { createClient } from 'npm:@supabase/supabase-js';
import { getAuthenticatedUser, getUserRoles, hasAnyRole } from '../_shared/auth.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
    const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

    const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
      auth: { persistSession: false }
    });

    // Authenticate user
    const user = await getAuthenticatedUser(req, supabase);
    const userRoles = await getUserRoles(supabase, user.id);

    // Check permissions
    if (!hasAnyRole(userRoles, ['admin', 'manager'])) {
      return new Response(
        JSON.stringify({ error: 'Insufficient permissions to create calculation runs' }),
        { status: 403, headers: { 'Content-Type': 'application/json', ...corsHeaders } }
      );
    }

    const { name, period_start, period_end } = await req.json();

    if (!name || !period_start || !period_end) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: name, period_start, period_end' }),
        { status: 400, headers: { 'Content-Type': 'application/json', ...corsHeaders } }
      );
    }

    const { data, error } = await supabase
      .from('calculation_runs')
      .insert([{ name, period_start, period_end, created_by: user.id }])
      .select()
      .single();

    if (error) {
      console.error('Insert error:', error);
      return new Response(JSON.stringify({ error: error.message }), {
        status: 400,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    return new Response(JSON.stringify({ run: data }), {
      status: 200,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  } catch (err) {
    console.error('Unhandled error:', err);
    return new Response(JSON.stringify({ error: 'Unexpected error creating calculation run' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }
});
