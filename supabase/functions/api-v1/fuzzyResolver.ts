/**
 * Fuzzy Resolver Service - RapidFuzz Name Matching (T07)
 * Ticket: P2 Move 2A
 * Date: 2025-10-21
 *
 * Purpose:
 * Match investor referrer names against parties table using fuzzy string matching.
 * Used during CSV import to automatically link referrers to existing parties.
 *
 * Matching Rules:
 * - Score ≥90: Auto-match (create link immediately)
 * - Score 80-89: Queue for review (insert into referrer_review_queue)
 * - Score <80: No match suggested
 *
 * Normalization:
 * - Lowercase
 * - Remove punctuation (.,!?;:)
 * - Remove company suffixes (LLC, Ltd, Inc, Corp, Co, LP, LLP, etc.)
 * - Remove extra whitespace
 * - Trim
 *
 * Endpoints:
 * - POST /api-v1/import/preview - Preview fuzzy matches for a name
 * - POST /api-v1/import/commit - Apply auto-matches and queue reviews
 */

import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import {
  validationError,
  forbiddenError,
  notFoundError,
  successResponse,
  mapPgErrorToApiError,
  type ApiErrorDetail,
} from './errors.ts';
import { authGuard, type AuthGuardResult } from '../_shared/auth.ts';

// Import RapidFuzz for fuzzy string matching
// Note: For Deno, we'll use a compatible library or implement simple Levenshtein
// For now, using a simple ratio-based approach (can be replaced with rapidfuzz later)

// ============================================
// TYPES
// ============================================

interface FuzzyMatch {
  party_id: number;
  name: string;
  score: number;
  action: 'auto' | 'review' | 'none';
}

interface PreviewRequest {
  name: string;
}

interface PreviewResponse {
  matches: FuzzyMatch[];
}

interface CommitRequest {
  matches: Array<{
    referrer_name: string;
    party_id: number;
    action: 'auto' | 'review';
    investor_id?: number; // Optional: link to investor
    import_batch_id?: string;
    import_row_number?: number;
  }>;
}

interface CommitResponse {
  created: number;
  queued_for_review: number;
  results: Array<{
    referrer_name: string;
    party_id: number;
    action: 'auto' | 'review';
    status: 'success' | 'error';
    error?: string;
  }>;
}

// ============================================
// NORMALIZATION HELPERS
// ============================================

const COMPANY_SUFFIXES = [
  'LLC', 'L.L.C', 'L.L.C.', 'LTD', 'LIMITED', 'INC', 'INCORPORATED',
  'CORP', 'CORPORATION', 'CO', 'COMPANY', 'LP', 'L.P', 'L.P.',
  'LLP', 'L.L.P', 'L.L.P.', 'PLLC', 'P.L.L.C', 'P.L.L.C.',
  'PC', 'P.C', 'P.C.', 'PA', 'P.A', 'P.A.',
];

/**
 * Normalize a name for fuzzy matching
 * - Lowercase
 * - Remove punctuation
 * - Remove company suffixes
 * - Remove extra whitespace
 * - Trim
 */
function normalizeName(name: string): string {
  if (!name) return '';

  // Lowercase
  let normalized = name.toLowerCase();

  // Remove punctuation (except spaces and hyphens)
  normalized = normalized.replace(/[.,!?;:()[\]{}'"]/g, ' ');

  // Remove company suffixes
  for (const suffix of COMPANY_SUFFIXES) {
    const pattern = new RegExp(`\\b${suffix.toLowerCase()}\\b`, 'g');
    normalized = normalized.replace(pattern, '');
  }

  // Remove extra whitespace
  normalized = normalized.replace(/\s+/g, ' ').trim();

  return normalized;
}

/**
 * Calculate Jaro-Winkler similarity (simplified)
 * Returns a score between 0 and 100
 *
 * This is a simplified implementation. For production, consider using a library like:
 * - https://deno.land/x/fuzzball or
 * - https://deno.land/x/string_similarity
 */
function calculateSimilarity(str1: string, str2: string): number {
  // Normalize both strings
  const s1 = normalizeName(str1);
  const s2 = normalizeName(str2);

  if (s1 === s2) return 100;
  if (s1.length === 0 || s2.length === 0) return 0;

  // Simple token-based similarity (Jaccard index)
  const tokens1 = new Set(s1.split(' '));
  const tokens2 = new Set(s2.split(' '));

  const intersection = new Set([...tokens1].filter(x => tokens2.has(x)));
  const union = new Set([...tokens1, ...tokens2]);

  const jaccardScore = (intersection.size / union.size) * 100;

  // Boost score if one string contains the other
  if (s1.includes(s2) || s2.includes(s1)) {
    return Math.min(jaccardScore + 20, 100);
  }

  // Simple Levenshtein-based boost for short strings
  if (s1.length < 10 && s2.length < 10) {
    const levenshteinDistance = calculateLevenshtein(s1, s2);
    const maxLength = Math.max(s1.length, s2.length);
    const levenshteinScore = ((maxLength - levenshteinDistance) / maxLength) * 100;
    return Math.max(jaccardScore, levenshteinScore);
  }

  return jaccardScore;
}

/**
 * Calculate Levenshtein distance (edit distance)
 */
function calculateLevenshtein(str1: string, str2: string): number {
  const matrix: number[][] = [];

  for (let i = 0; i <= str2.length; i++) {
    matrix[i] = [i];
  }

  for (let j = 0; j <= str1.length; j++) {
    matrix[0][j] = j;
  }

  for (let i = 1; i <= str2.length; i++) {
    for (let j = 1; j <= str1.length; j++) {
      if (str2.charAt(i - 1) === str1.charAt(j - 1)) {
        matrix[i][j] = matrix[i - 1][j - 1];
      } else {
        matrix[i][j] = Math.min(
          matrix[i - 1][j - 1] + 1, // substitution
          matrix[i][j - 1] + 1,     // insertion
          matrix[i - 1][j] + 1      // deletion
        );
      }
    }
  }

  return matrix[str2.length][str1.length];
}

/**
 * Determine match action based on score
 * - ≥90: auto
 * - 80-89: review
 * - <80: none
 */
function getMatchAction(score: number): 'auto' | 'review' | 'none' {
  if (score >= 90) return 'auto';
  if (score >= 80) return 'review';
  return 'none';
}

// ============================================
// ENDPOINT: POST /import/preview
// ============================================
/**
 * Preview fuzzy matches for a referrer name
 *
 * Request:
 * {
 *   "name": "Acme Corporation"
 * }
 *
 * Response:
 * {
 *   "data": {
 *     "matches": [
 *       { "party_id": 123, "name": "Acme Corp LLC", "score": 92, "action": "auto" },
 *       { "party_id": 456, "name": "Acme Industries", "score": 85, "action": "review" }
 *     ]
 *   }
 * }
 */
export async function handlePreviewMatch(
  req: Request,
  supabase: SupabaseClient,
  corsHeaders: Record<string, string>
): Promise<Response> {
  // Auth: Finance+ roles OR service key
  let auth: AuthGuardResult;
  try {
    auth = await authGuard(req, supabase, ['admin', 'finance', 'ops'], { allowServiceKey: true });
  } catch (error: any) {
    return forbiddenError(error.message, corsHeaders);
  }

  // Parse request body
  const body: PreviewRequest = await req.json().catch(() => ({}));

  if (!body.name || typeof body.name !== 'string' || body.name.trim().length === 0) {
    return validationError(
      [{ field: 'name', message: 'name is required and must be a non-empty string', value: body.name }],
      corsHeaders
    );
  }

  const inputName = body.name.trim();

  // Fetch all parties from database
  const { data: parties, error: partiesError } = await supabase
    .from('parties')
    .select('id, name');

  if (partiesError) {
    return mapPgErrorToApiError(partiesError, corsHeaders);
  }

  if (!parties || parties.length === 0) {
    return successResponse({ data: { matches: [] } }, 200, corsHeaders);
  }

  // Calculate fuzzy match scores
  const matches: FuzzyMatch[] = parties
    .map(party => ({
      party_id: party.id,
      name: party.name,
      score: calculateSimilarity(inputName, party.name),
      action: getMatchAction(calculateSimilarity(inputName, party.name)),
    }))
    .filter(match => match.score >= 80) // Only return scores ≥80
    .sort((a, b) => b.score - a.score) // Sort by score descending
    .slice(0, 10); // Limit to top 10 matches

  return successResponse({ data: { matches } }, 200, corsHeaders);
}

// ============================================
// ENDPOINT: POST /import/commit
// ============================================
/**
 * Commit fuzzy matches: auto-apply or queue for review
 *
 * Request:
 * {
 *   "matches": [
 *     {
 *       "referrer_name": "Acme Corporation",
 *       "party_id": 123,
 *       "action": "auto",
 *       "investor_id": 456,
 *       "import_batch_id": "batch-123",
 *       "import_row_number": 5
 *     }
 *   ]
 * }
 *
 * Response:
 * {
 *   "data": {
 *     "created": 1,
 *     "queued_for_review": 0,
 *     "results": [
 *       { "referrer_name": "Acme Corporation", "party_id": 123, "action": "auto", "status": "success" }
 *     ]
 *   }
 * }
 */
export async function handleCommitMatches(
  req: Request,
  supabase: SupabaseClient,
  corsHeaders: Record<string, string>
): Promise<Response> {
  // Auth: Finance+ roles OR service key
  let auth: AuthGuardResult;
  try {
    auth = await authGuard(req, supabase, ['admin', 'finance', 'ops'], { allowServiceKey: true });
  } catch (error: any) {
    return forbiddenError(error.message, corsHeaders);
  }

  // Parse request body
  const body: CommitRequest = await req.json().catch(() => ({}));

  if (!Array.isArray(body.matches) || body.matches.length === 0) {
    return validationError(
      [{ field: 'matches', message: 'matches must be a non-empty array', value: body.matches }],
      corsHeaders
    );
  }

  let created = 0;
  let queuedForReview = 0;
  const results: CommitResponse['results'] = [];

  for (const match of body.matches) {
    try {
      if (match.action === 'auto') {
        // Auto-apply: Update investor source fields immediately (if investor_id provided)
        if (match.investor_id) {
          const { error: updateError } = await supabase
            .from('investors')
            .update({
              source_party_id: match.party_id,
              updated_at: new Date().toISOString(),
            })
            .eq('id', match.investor_id);

          if (updateError) {
            throw new Error(`Failed to update investor: ${updateError.message}`);
          }
        }

        // Log auto-match to audit_log
        await supabase
          .from('audit_log')
          .insert({
            event_type: 'referrer.auto_matched',
            actor_id: auth.isServiceKey ? null : auth.userId,
            entity_type: 'investor',
            entity_id: match.investor_id ? String(match.investor_id) : null,
            payload: {
              referrer_name: match.referrer_name,
              party_id: match.party_id,
              import_batch_id: match.import_batch_id,
            },
          });

        created++;
        results.push({
          referrer_name: match.referrer_name,
          party_id: match.party_id,
          action: 'auto',
          status: 'success',
        });
      } else if (match.action === 'review') {
        // Queue for review
        // First, get party name for reference
        const { data: party } = await supabase
          .from('parties')
          .select('name')
          .eq('id', match.party_id)
          .single();

        // Recalculate score for audit trail
        const score = party ? calculateSimilarity(match.referrer_name, party.name) : 0;

        const { error: insertError } = await supabase
          .from('referrer_review_queue')
          .insert({
            referrer_name: match.referrer_name,
            suggested_party_id: match.party_id,
            suggested_party_name: party?.name || null,
            fuzzy_score: score,
            status: 'pending',
            investor_id: match.investor_id || null,
            import_batch_id: match.import_batch_id || null,
            import_row_number: match.import_row_number || null,
          });

        if (insertError) {
          throw new Error(`Failed to queue for review: ${insertError.message}`);
        }

        queuedForReview++;
        results.push({
          referrer_name: match.referrer_name,
          party_id: match.party_id,
          action: 'review',
          status: 'success',
        });
      }
    } catch (error: any) {
      results.push({
        referrer_name: match.referrer_name,
        party_id: match.party_id,
        action: match.action,
        status: 'error',
        error: error.message || 'Unknown error',
      });
    }
  }

  return successResponse(
    {
      data: {
        created,
        queued_for_review: queuedForReview,
        results,
      },
    },
    200,
    corsHeaders
  );
}
