/**
 * CSV Import Endpoints (IMP-01)
 *
 * POST /import/parties?mode=preview|commit
 * POST /import/investors?mode=preview|commit
 * POST /import/agreements?mode=preview|commit
 * POST /import/contributions?mode=preview|commit
 *
 * Authentication: Service role key only
 */

import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';
import {
  validationError,
  forbiddenError,
  successResponse,
  internalError,
} from './errors.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// ============================================
// Main Handler (Router)
// ============================================

export async function handleImports(
  req: Request,
  supabase: SupabaseClient,
  userId: string,
  url: URL
): Promise<Response> {
  // Only allow service_role for imports
  if (userId !== 'SERVICE') {
    return forbiddenError('Imports require service_role key', corsHeaders);
  }

  const path = url.pathname.split('/');
  const entity = path[path.indexOf('import') + 1];
  const mode = url.searchParams.get('mode') || 'preview';

  if (!['parties', 'investors', 'agreements', 'contributions'].includes(entity)) {
    return validationError('Invalid entity. Must be: parties, investors, agreements, or contributions', corsHeaders);
  }

  if (!['preview', 'commit'].includes(mode)) {
    return validationError('Invalid mode. Must be: preview or commit', corsHeaders);
  }

  if (req.method === 'POST') {
    return await handleImport(req, supabase, entity, mode);
  }

  return validationError('Method not allowed', corsHeaders);
}

// ============================================
// Import Handler
// ============================================

async function handleImport(
  req: Request,
  supabase: SupabaseClient,
  entity: string,
  mode: string
): Promise<Response> {
  try {
    const body = await req.json();
    const rows = Array.isArray(body) ? body : body.rows;

    if (!rows || !Array.isArray(rows)) {
      return validationError('Request body must be an array of rows or {rows: [...]}', corsHeaders);
    }

    // Create import run record
    const { data: importRun, error: runError } = await supabase
      .from('import_runs')
      .insert({
        entity,
        mode,
        created_by: 'service_role',
        stats: {},
        errors: [],
      })
      .select()
      .single();

    if (runError || !importRun) {
      console.error('Failed to create import_run:', runError);
      return internalError('Failed to create import run', corsHeaders);
    }

    // Process based on entity type
    let result;
    switch (entity) {
      case 'parties':
        result = await importParties(supabase, rows, importRun.id, mode);
        break;
      case 'investors':
        result = await importInvestors(supabase, rows, importRun.id, mode);
        break;
      case 'agreements':
        result = await importAgreements(supabase, rows, importRun.id, mode);
        break;
      case 'contributions':
        result = await importContributions(supabase, rows, importRun.id, mode);
        break;
      default:
        return validationError('Invalid entity', corsHeaders);
    }

    // Update import run with results
    await supabase
      .from('import_runs')
      .update({
        stats: result.stats,
        errors: result.errors,
      })
      .eq('id', importRun.id);

    return successResponse({
      mode,
      entity,
      import_run_id: importRun.id,
      ...result,
    }, 200, corsHeaders);

  } catch (error) {
    console.error('Import error:', error);
    return internalError(error instanceof Error ? error.message : 'Unknown error', corsHeaders);
  }
}

// ============================================
// Entity-Specific Import Functions
// ============================================

async function importParties(
  supabase: SupabaseClient,
  rows: any[],
  importRunId: string,
  mode: string
) {
  const stats = { insert: 0, update: 0, skip: 0, errors: 0, matches: { exact: 0, fuzzy: 0, new: 0 } };
  const errors: any[] = [];

  for (let i = 0; i < rows.length; i++) {
    const row = rows[i];
    const rowNum = i + 1;

    // Validate required fields
    if (!row.name) {
      errors.push({ row: rowNum, field: 'name', message: 'Name is required' });
      stats.errors++;
      continue;
    }

    // Check for existing party (exact match)
    const { data: existing } = await supabase
      .from('parties')
      .select('id')
      .eq('name', row.name)
      .single();

    if (existing) {
      stats.matches.exact++;
      if (mode === 'commit') {
        // Update existing
        await supabase
          .from('parties')
          .update({
            email: row.email || null,
            notes: row.notes || null,
          })
          .eq('id', existing.id);
        stats.update++;
      } else {
        stats.skip++;  // In preview, existing = skip
      }
    } else {
      stats.matches.new++;
      if (mode === 'commit') {
        // Insert new
        await supabase
          .from('parties')
          .insert({
            name: row.name,
            email: row.email || null,
            notes: row.notes || null,
          });
        stats.insert++;
      } else {
        stats.insert++;  // Preview shows what WOULD be inserted
      }
    }
  }

  return { stats, errors };
}

async function importInvestors(
  supabase: SupabaseClient,
  rows: any[],
  importRunId: string,
  mode: string
) {
  const stats = { insert: 0, update: 0, skip: 0, errors: 0, matches: { exact: 0, fuzzy: 0, new: 0 } };
  const errors: any[] = [];

  for (let i = 0; i < rows.length; i++) {
    const row = rows[i];
    const rowNum = i + 1;

    // Validate required fields
    if (!row.name) {
      errors.push({ row: rowNum, field: 'name', message: 'Name is required' });
      stats.errors++;
      continue;
    }

    // Resolve party_id from introduced_by name
    let partyId = null;
    if (row.introduced_by) {
      const { data: party } = await supabase
        .rpc('resolve_party_id', { party_name: row.introduced_by });
      partyId = party;

      if (!partyId) {
        errors.push({ row: rowNum, field: 'introduced_by', message: `Party '${row.introduced_by}' not found` });
        stats.errors++;
        continue;
      }
    }

    // Check for existing investor (exact match)
    const { data: existing } = await supabase
      .from('investors')
      .select('id')
      .eq('name', row.name)
      .single();

    if (existing) {
      stats.matches.exact++;
      if (mode === 'commit') {
        // Update existing
        await supabase
          .from('investors')
          .update({
            email: row.email || null,
            introduced_by_party_id: partyId,
            notes: row.notes || `Imported: ${new Date().toISOString()}`,
          })
          .eq('id', existing.id);
        stats.update++;
      } else {
        stats.skip++;
      }
    } else {
      stats.matches.new++;
      if (mode === 'commit') {
        // Insert new
        await supabase
          .from('investors')
          .insert({
            name: row.name,
            email: row.email || null,
            introduced_by_party_id: partyId,
            notes: row.notes || `Imported: ${new Date().toISOString()}`,
          });
        stats.insert++;
      } else {
        stats.insert++;
      }
    }
  }

  return { stats, errors };
}

async function importAgreements(
  supabase: SupabaseClient,
  rows: any[],
  importRunId: string,
  mode: string
) {
  const stats = { insert: 0, update: 0, skip: 0, errors: 0, matches: { exact: 0, fuzzy: 0, new: 0 } };
  const errors: any[] = [];

  for (let i = 0; i < rows.length; i++) {
    const row = rows[i];
    const rowNum = i + 1;

    // Validate required fields
    if (!row.party_name || !row.deal_name || !row.effective_from) {
      errors.push({ row: rowNum, field: 'required', message: 'party_name, deal_name, and effective_from are required' });
      stats.errors++;
      continue;
    }

    // Resolve party_id
    const { data: partyId } = await supabase
      .rpc('resolve_party_id', { party_name: row.party_name });

    if (!partyId) {
      errors.push({ row: rowNum, field: 'party_name', message: `Party '${row.party_name}' not found` });
      stats.errors++;
      continue;
    }

    // Resolve deal_id
    const { data: dealId } = await supabase
      .rpc('resolve_deal_id', { deal_name: row.deal_name });

    if (!dealId) {
      errors.push({ row: rowNum, field: 'deal_name', message: `Deal '${row.deal_name}' not found` });
      stats.errors++;
      continue;
    }

    // Check for overlapping agreements (same party + deal + overlapping dates)
    const { data: overlapping } = await supabase
      .from('agreements')
      .select('id, effective_from, effective_to')
      .eq('party_id', partyId)
      .eq('deal_id', dealId)
      .or(`effective_to.is.null,effective_to.gte.${row.effective_from}`)
      .lte('effective_from', row.effective_to || '9999-12-31');

    if (overlapping && overlapping.length > 0) {
      errors.push({ row: rowNum, field: 'dates', message: `Agreement overlaps with existing agreement ${overlapping[0].id}` });
      stats.errors++;
      continue;
    }

    // Prepare agreement data
    const agreementData = {
      party_id: partyId,
      deal_id: dealId,
      effective_from: row.effective_from,
      effective_to: row.effective_to || null,
      kind: row.kind || 'INVESTOR',
      pricing_mode: row.pricing_mode || 'CUSTOM',
      status: 'DRAFT',  // Imported agreements start as DRAFT
      snapshot_json: {
        rate_bps: row.rate_bps || 100,
        vat_mode: row.vat_mode || 'on_top',
        vat_rate: row.vat_rate || 0.17,
        imported: true,
        imported_at: new Date().toISOString(),
      },
    };

    stats.matches.new++;
    if (mode === 'commit') {
      await supabase
        .from('agreements')
        .insert(agreementData);
      stats.insert++;
    } else {
      stats.insert++;
    }
  }

  return { stats, errors };
}

async function importContributions(
  supabase: SupabaseClient,
  rows: any[],
  importRunId: string,
  mode: string
) {
  const stats = { insert: 0, update: 0, skip: 0, errors: 0, matches: { exact: 0, fuzzy: 0, new: 0 } };
  const errors: any[] = [];

  for (let i = 0; i < rows.length; i++) {
    const row = rows[i];
    const rowNum = i + 1;

    // Validate required fields
    if (!row.investor_name || !row.deal_name || !row.amount || !row.paid_in_date) {
      errors.push({ row: rowNum, field: 'required', message: 'investor_name, deal_name, amount, and paid_in_date are required' });
      stats.errors++;
      continue;
    }

    // Resolve investor_id
    const { data: investors } = await supabase
      .from('investors')
      .select('id')
      .eq('name', row.investor_name);

    let investorId = investors?.[0]?.id;

    // Create investor if missing
    if (!investorId && mode === 'commit') {
      const { data: newInvestor } = await supabase
        .from('investors')
        .insert({
          name: row.investor_name,
          notes: `Auto-created from contribution import: ${new Date().toISOString()}`,
        })
        .select()
        .single();
      investorId = newInvestor?.id;
    }

    if (!investorId) {
      errors.push({ row: rowNum, field: 'investor_name', message: `Investor '${row.investor_name}' not found` });
      stats.errors++;
      continue;
    }

    // Resolve deal_id
    const { data: dealId } = await supabase
      .rpc('resolve_deal_id', { deal_name: row.deal_name });

    if (!dealId) {
      errors.push({ row: rowNum, field: 'deal_name', message: `Deal '${row.deal_name}' not found` });
      stats.errors++;
      continue;
    }

    // Check for duplicate contribution (same investor + deal + amount + date)
    const { data: existing } = await supabase
      .from('contributions')
      .select('id')
      .eq('investor_id', investorId)
      .eq('deal_id', dealId)
      .eq('amount', row.amount)
      .eq('paid_in_date', row.paid_in_date)
      .single();

    if (existing) {
      stats.matches.exact++;
      stats.skip++;
      continue;
    }

    stats.matches.new++;
    if (mode === 'commit') {
      await supabase
        .from('contributions')
        .insert({
          investor_id: investorId,
          deal_id: dealId,
          fund_id: null,  // Optional, resolve later if fund_name provided
          amount: row.amount,
          paid_in_date: row.paid_in_date,
          currency: row.currency || 'USD',
        });
      stats.insert++;
    } else {
      stats.insert++;
    }
  }

  return { stats, errors };
}
