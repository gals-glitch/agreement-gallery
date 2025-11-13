/**
 * IMP-02: CSV Import Orchestration Script
 *
 * Usage:
 *   npm run import:all -- --dir "./imports" --mode preview
 *   npm run import:all -- --dir "./imports" --mode commit
 *
 * Imports CSVs in order:
 *   1. 01_parties.csv
 *   2. 02_investors.csv
 *   3. 03_agreements.csv
 *   4. 04_contributions.csv
 */

import * as fs from 'fs';
import * as path from 'path';

interface ImportRow {
  [key: string]: string | number | null;
}

interface ImportResult {
  mode: string;
  entity: string;
  import_run_id: string;
  stats: {
    insert: number;
    update: number;
    skip: number;
    errors: number;
    matches: {
      exact: number;
      fuzzy: number;
      new: number;
    };
  };
  errors: Array<{
    row: number;
    field: string;
    message: string;
  }>;
}

// Configuration
const SUPABASE_URL = process.env.SUPABASE_URL || process.env.VITE_SUPABASE_URL;
const SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const API_BASE = `${SUPABASE_URL}/functions/v1/api-v1`;

// CSV order (dependencies)
const IMPORT_ORDER = [
  { file: '01_parties.csv', entity: 'parties' },
  { file: '02_investors.csv', entity: 'investors' },
  { file: '03_agreements.csv', entity: 'agreements' },
  { file: '04_contributions.csv', entity: 'contributions' },
];

// ============================================
// CSV Parser (simple - assumes no escaped commas)
// ============================================

function parseCSV(filePath: string): ImportRow[] {
  const content = fs.readFileSync(filePath, 'utf-8');
  const lines = content.trim().split('\n');

  if (lines.length === 0) {
    return [];
  }

  // Parse header
  const header = lines[0].split(',').map(h => h.trim());

  // Parse rows
  const rows: ImportRow[] = [];
  for (let i = 1; i < lines.length; i++) {
    const values = lines[i].split(',').map(v => v.trim());
    const row: ImportRow = {};

    for (let j = 0; j < header.length; j++) {
      const value = values[j];
      // Convert to number if possible, null if empty, otherwise string
      if (value === '' || value === 'NULL') {
        row[header[j]] = null;
      } else if (!isNaN(Number(value))) {
        row[header[j]] = Number(value);
      } else {
        row[header[j]] = value;
      }
    }

    rows.push(row);
  }

  return rows;
}

// ============================================
// Import API Call
// ============================================

async function importEntity(
  entity: string,
  rows: ImportRow[],
  mode: string
): Promise<ImportResult> {
  const url = `${API_BASE}/import/${entity}?mode=${mode}`;

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${SERVICE_ROLE_KEY}`,
      'apikey': SERVICE_ROLE_KEY!,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(rows),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Import failed (${response.status}): ${errorText}`);
  }

  return await response.json();
}

// ============================================
// Pretty Print Results
// ============================================

function printResult(result: ImportResult) {
  const { entity, mode, stats, errors } = result;

  console.log(`\n${'='.repeat(60)}`);
  console.log(`Entity: ${entity.toUpperCase()} | Mode: ${mode.toUpperCase()}`);
  console.log(`${'='.repeat(60)}`);

  console.log(`\nStats:`);
  console.log(`  Insert: ${stats.insert}`);
  console.log(`  Update: ${stats.update}`);
  console.log(`  Skip: ${stats.skip}`);
  console.log(`  Errors: ${stats.errors}`);

  console.log(`\nMatches:`);
  console.log(`  Exact: ${stats.matches.exact}`);
  console.log(`  Fuzzy: ${stats.matches.fuzzy}`);
  console.log(`  New: ${stats.matches.new}`);

  if (errors.length > 0) {
    console.log(`\nErrors (${errors.length}):`);
    errors.slice(0, 10).forEach(err => {
      console.log(`  Row ${err.row}: ${err.field} - ${err.message}`);
    });
    if (errors.length > 10) {
      console.log(`  ... and ${errors.length - 10} more`);
    }
  }

  // Summary
  const totalProcessed = stats.insert + stats.update + stats.skip + stats.errors;
  const successRate = totalProcessed > 0
    ? Math.round(((stats.insert + stats.update) / totalProcessed) * 100)
    : 0;

  console.log(`\nSummary: ${totalProcessed} rows processed, ${successRate}% success`);

  return stats.errors === 0;
}

// ============================================
// Main
// ============================================

async function main() {
  // Parse command line args
  const args = process.argv.slice(2);
  let dir = '.';
  let mode = 'preview';

  for (let i = 0; i < args.length; i += 2) {
    if (args[i] === '--dir') {
      dir = args[i + 1];
    } else if (args[i] === '--mode') {
      mode = args[i + 1];
    }
  }

  // Validate
  if (!['preview', 'commit'].includes(mode)) {
    console.error('Error: mode must be "preview" or "commit"');
    process.exit(1);
  }

  if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
    console.error('Error: Missing environment variables');
    console.error('  SUPABASE_URL:', SUPABASE_URL ? 'OK' : 'MISSING');
    console.error('  SUPABASE_SERVICE_ROLE_KEY:', SERVICE_ROLE_KEY ? 'OK' : 'MISSING');
    process.exit(1);
  }

  console.log(`\n${'='.repeat(60)}`);
  console.log(`CSV IMPORT ORCHESTRATION`);
  console.log(`${'='.repeat(60)}`);
  console.log(`Directory: ${dir}`);
  console.log(`Mode: ${mode.toUpperCase()}`);
  console.log(`API: ${API_BASE}`);
  console.log(`${'='.repeat(60)}`);

  const results: ImportResult[] = [];
  let hasErrors = false;

  // Process each entity in order
  for (const { file, entity } of IMPORT_ORDER) {
    const filePath = path.join(dir, file);

    // Check if file exists
    if (!fs.existsSync(filePath)) {
      console.log(`\nSkipping ${entity}: File not found (${filePath})`);
      continue;
    }

    console.log(`\nProcessing ${entity} from ${file}...`);

    try {
      // Parse CSV
      const rows = parseCSV(filePath);
      console.log(`  Loaded ${rows.length} rows`);

      if (rows.length === 0) {
        console.log(`  Skipping empty file`);
        continue;
      }

      // Import
      const result = await importEntity(entity, rows, mode);
      results.push(result);

      // Print result
      const success = printResult(result);
      if (!success) {
        hasErrors = true;
      }

    } catch (error) {
      console.error(`\n❌ Error processing ${entity}:`, error);
      hasErrors = true;
      if (mode === 'commit') {
        console.error(`\nStopping on error in commit mode`);
        process.exit(1);
      }
    }
  }

  // Final summary
  console.log(`\n${'='.repeat(60)}`);
  console.log(`FINAL SUMMARY`);
  console.log(`${'='.repeat(60)}`);

  const totalStats = results.reduce((acc, r) => ({
    insert: acc.insert + r.stats.insert,
    update: acc.update + r.stats.update,
    skip: acc.skip + r.stats.skip,
    errors: acc.errors + r.stats.errors,
  }), { insert: 0, update: 0, skip: 0, errors: 0 });

  console.log(`\nTotal across all entities:`);
  console.log(`  Insert: ${totalStats.insert}`);
  console.log(`  Update: ${totalStats.update}`);
  console.log(`  Skip: ${totalStats.skip}`);
  console.log(`  Errors: ${totalStats.errors}`);

  if (mode === 'preview') {
    console.log(`\n⚠️  PREVIEW MODE - No changes were made`);
    console.log(`\nTo commit these changes, run:`);
    console.log(`  npm run import:all -- --dir "${dir}" --mode commit`);
  } else {
    console.log(`\n✅ COMMIT COMPLETE`);
  }

  process.exit(hasErrors ? 1 : 0);
}

main().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});
