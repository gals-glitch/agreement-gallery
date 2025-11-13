/**
 * Agreement Documents API Handlers
 * Ticket: API-210
 * Date: 2025-10-19
 *
 * Endpoints:
 * - POST /agreements/:id/documents - Create document record + get signed upload URL
 * - POST /agreements/documents/:docId/versions - Upload new version (with de-dup)
 * - GET /agreements/documents - List/search documents
 * - GET /agreements/documents/:id/versions - List versions for a document
 * - GET /agreements/documents/:id/download - Get signed download URL
 */

import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';
import {
  validationError,
  forbiddenError,
  conflictError,
  notFoundError,
  successResponse,
  mapPgErrorToApiError,
  type ApiErrorDetail,
} from './errors.ts';
import { getUserRoles, hasAnyRole } from '../_shared/auth.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// ============================================
// TYPES
// ============================================
interface CreateDocumentRequest {
  agreement_id: string;
  filename: string;
  mime_type: string;
  file_size_bytes: number;
  tags?: string[];
  notes?: string;
}

interface UploadVersionRequest {
  file: File;
  tags?: string[];
  notes?: string;
}

interface DocumentSearchParams {
  agreement_id?: string;
  party_id?: string;
  scope?: string;
  fund_id?: string;
  deal_id?: string;
  tag?: string;
  search?: string;
  limit?: number;
  offset?: number;
}

// ============================================
// MAIN HANDLER
// ============================================
export async function handleAgreementDocs(
  req: Request,
  supabase: SupabaseClient,
  userId: string,
  pathParts: string[]
): Promise<Response> {
  const method = req.method;
  const url = new URL(req.url);

  // Parse path structure
  // /agreements/:id/documents - Create document
  // /agreements/documents - List/search documents
  // /agreements/documents/:id/versions - List versions or upload new version
  // /agreements/documents/:id/download - Download document

  if (pathParts[0] === 'agreements') {
    if (pathParts[1] && pathParts[1] !== 'documents') {
      // /agreements/:id/documents
      const agreementId = pathParts[1];
      if (pathParts[2] === 'documents' && method === 'POST') {
        return await handleCreateDocument(req, supabase, userId, agreementId);
      }
    } else if (pathParts[1] === 'documents') {
      // /agreements/documents/*
      if (!pathParts[2]) {
        // /agreements/documents - List/search
        if (method === 'GET') {
          return await handleListDocuments(req, supabase, url);
        }
      } else {
        const docId = pathParts[2];
        const action = pathParts[3];

        if (action === 'versions') {
          if (method === 'GET') {
            // GET /agreements/documents/:id/versions - List versions
            return await handleListVersions(supabase, docId);
          } else if (method === 'POST') {
            // POST /agreements/documents/:id/versions - Upload new version
            return await handleUploadVersion(req, supabase, userId, docId);
          }
        } else if (action === 'download') {
          if (method === 'GET') {
            // GET /agreements/documents/:id/download
            return await handleDownload(supabase, url, docId);
          }
        }
      }
    }
  }

  return notFoundError('Endpoint', corsHeaders);
}

// ============================================
// POST /agreements/:id/documents
// Create document record + get signed upload URL
// ============================================
async function handleCreateDocument(
  req: Request,
  supabase: SupabaseClient,
  userId: string,
  agreementId: string
): Promise<Response> {
  try {
    const body = await req.json() as CreateDocumentRequest;

    // Validate request
    const errors: ApiErrorDetail[] = [];
    if (!body.filename) {
      errors.push({ field: 'filename', message: 'Filename is required' });
    }
    if (!body.mime_type) {
      errors.push({ field: 'mime_type', message: 'MIME type is required' });
    }
    if (!body.file_size_bytes || body.file_size_bytes <= 0) {
      errors.push({ field: 'file_size_bytes', message: 'File size must be positive' });
    }
    if (errors.length > 0) {
      return validationError(errors, corsHeaders);
    }

    // Verify agreement exists
    const { data: agreement, error: agreementError } = await supabase
      .from('agreements')
      .select('id')
      .eq('id', agreementId)
      .single();

    if (agreementError || !agreement) {
      return notFoundError('Agreement', corsHeaders);
    }

    // Get next version number
    const { data: nextVersionData, error: versionError } = await supabase
      .rpc('get_next_document_version', { p_agreement_id: parseInt(agreementId) });

    if (versionError) {
      return mapPgErrorToApiError(versionError, corsHeaders);
    }

    const versionNumber = nextVersionData || 1;

    // Generate storage path
    const storagePath = `${agreementId}/v${versionNumber}_${body.filename}`;

    // Create signed upload URL (5 minutes expiry)
    const { data: uploadData, error: uploadError } = await supabase.storage
      .from('agreement-docs')
      .createSignedUploadUrl(storagePath, {
        upsert: false, // Don't overwrite existing files
      });

    if (uploadError) {
      return mapPgErrorToApiError(uploadError, corsHeaders);
    }

    // Return upload URL and metadata for client to complete upload
    return successResponse(
      {
        upload_url: uploadData.signedUrl,
        storage_path: storagePath,
        version_number: versionNumber,
        agreement_id: agreementId,
        expires_at: new Date(Date.now() + 5 * 60 * 1000).toISOString(),
      },
      200,
      corsHeaders
    );
  } catch (error) {
    console.error('Create document error:', error);
    return mapPgErrorToApiError(error, corsHeaders);
  }
}

// ============================================
// POST /agreements/documents/:docId/versions
// Upload new version with de-duplication
// ============================================
async function handleUploadVersion(
  req: Request,
  supabase: SupabaseClient,
  userId: string,
  agreementId: string
): Promise<Response> {
  try {
    // Parse multipart form data
    const formData = await req.formData();
    const file = formData.get('file') as File;
    const fileSha256 = formData.get('file_sha256') as string;
    const tagsStr = formData.get('tags') as string;
    const notes = formData.get('notes') as string;

    // Validate
    const errors: ApiErrorDetail[] = [];
    if (!file) {
      errors.push({ field: 'file', message: 'File is required' });
    }
    if (!fileSha256) {
      errors.push({ field: 'file_sha256', message: 'SHA-256 hash is required' });
    }
    if (errors.length > 0) {
      return validationError(errors, corsHeaders);
    }

    // Parse tags
    const tags = tagsStr ? JSON.parse(tagsStr) : [];

    // Check for duplicate by SHA-256
    const { data: existingDoc, error: dupCheckError } = await supabase
      .from('agreement_documents')
      .select('id, agreement_id, filename, version_number')
      .eq('file_sha256', fileSha256)
      .limit(1)
      .maybeSingle();

    if (dupCheckError) {
      return mapPgErrorToApiError(dupCheckError, corsHeaders);
    }

    if (existingDoc) {
      // Duplicate detected - return existing document info
      return conflictError(
        'Duplicate document detected (identical file already uploaded)',
        [
          {
            field: 'file_sha256',
            value: fileSha256,
            message: `This file already exists as version ${existingDoc.version_number} of agreement ${existingDoc.agreement_id}`,
          },
        ],
        corsHeaders
      );
    }

    // Get next version number
    const { data: nextVersionData, error: versionError } = await supabase
      .rpc('get_next_document_version', { p_agreement_id: parseInt(agreementId) });

    if (versionError) {
      return mapPgErrorToApiError(versionError, corsHeaders);
    }

    const versionNumber = nextVersionData || 1;

    // Generate storage path
    const storagePath = `${agreementId}/v${versionNumber}_${file.name}`;

    // Upload to storage
    const { error: uploadError } = await supabase.storage
      .from('agreement-docs')
      .upload(storagePath, file, {
        contentType: file.type,
        upsert: false,
      });

    if (uploadError) {
      return mapPgErrorToApiError(uploadError, corsHeaders);
    }

    // Insert metadata
    const { data: document, error: insertError } = await supabase
      .from('agreement_documents')
      .insert({
        agreement_id: parseInt(agreementId),
        file_sha256: fileSha256,
        storage_path: storagePath,
        filename: file.name,
        file_size_bytes: file.size,
        mime_type: file.type,
        version_number: versionNumber,
        uploaded_by: userId,
        tags: tags,
        notes: notes || null,
      })
      .select('id, version_number, storage_path')
      .single();

    if (insertError) {
      // Rollback storage upload
      await supabase.storage.from('agreement-docs').remove([storagePath]);
      return mapPgErrorToApiError(insertError, corsHeaders);
    }

    // Refresh materialized view
    await supabase.rpc('refresh_materialized_view_concurrently', {
      view_name: 'agreement_documents_latest',
    }).catch(() => {
      // Non-critical - log but don't fail
      console.warn('Failed to refresh materialized view');
    });

    return successResponse(
      {
        document_id: document.id,
        version_number: document.version_number,
        storage_path: document.storage_path,
      },
      201,
      corsHeaders
    );
  } catch (error) {
    console.error('Upload version error:', error);
    return mapPgErrorToApiError(error, corsHeaders);
  }
}

// ============================================
// GET /agreements/documents
// List/search documents with filters
// ============================================
async function handleListDocuments(
  req: Request,
  supabase: SupabaseClient,
  url: URL
): Promise<Response> {
  try {
    // Parse query parameters
    const agreementId = url.searchParams.get('agreement_id');
    const partyId = url.searchParams.get('party_id');
    const scope = url.searchParams.get('scope');
    const fundId = url.searchParams.get('fund_id');
    const dealId = url.searchParams.get('deal_id');
    const tag = url.searchParams.get('tag');
    const search = url.searchParams.get('search');
    const limit = parseInt(url.searchParams.get('limit') || '50');
    const offset = parseInt(url.searchParams.get('offset') || '0');

    // Build query - join with agreements to enable party/fund/deal filtering
    // Simplified query to avoid nested join issues
    let query = supabase
      .from('agreement_documents')
      .select(
        `
        *,
        agreements!agreement_documents_agreement_id_fkey(
          id,
          party_id,
          scope,
          fund_id,
          deal_id
        )
      `,
        { count: 'exact' }
      )
      .order('uploaded_at', { ascending: false })
      .range(offset, offset + limit - 1);

    // Apply filters
    if (agreementId) {
      query = query.eq('agreement_id', parseInt(agreementId));
    }
    if (tag) {
      query = query.contains('tags', [tag]);
    }
    if (search) {
      query = query.or(`filename.ilike.%${search}%,notes.ilike.%${search}%`);
    }

    const { data, error, count } = await query;

    if (error) {
      return mapPgErrorToApiError(error, corsHeaders);
    }

    // Post-filter by party/scope/fund/deal (since they're in joined table)
    let filtered = data || [];
    if (partyId) {
      filtered = filtered.filter((d: any) => d.agreements?.party_id === parseInt(partyId));
    }
    if (scope) {
      filtered = filtered.filter((d: any) => d.agreements?.scope === scope);
    }
    if (fundId) {
      filtered = filtered.filter((d: any) => d.agreements?.fund_id === parseInt(fundId));
    }
    if (dealId) {
      filtered = filtered.filter((d: any) => d.agreements?.deal_id === parseInt(dealId));
    }

    return successResponse(
      {
        documents: filtered,
        total_count: filtered.length, // Use filtered length since we post-filtered
      },
      200,
      corsHeaders
    );
  } catch (error) {
    console.error('List documents error:', error);
    return mapPgErrorToApiError(error, corsHeaders);
  }
}

// ============================================
// GET /agreements/documents/:id/versions
// List all versions for a document's agreement
// ============================================
async function handleListVersions(
  supabase: SupabaseClient,
  documentId: string
): Promise<Response> {
  try {
    // Get the agreement_id from the document
    const { data: doc, error: docError } = await supabase
      .from('agreement_documents')
      .select('agreement_id')
      .eq('id', documentId)
      .single();

    if (docError || !doc) {
      return notFoundError('Document', corsHeaders);
    }

    // Get all versions for this agreement
    const { data: versions, error: versionsError } = await supabase
      .from('agreement_documents')
      .select(
        `
        id,
        version_number,
        filename,
        file_size_bytes,
        mime_type,
        uploaded_at,
        uploaded_by,
        tags,
        notes,
        uploader:auth.users!agreement_documents_uploaded_by_fkey(email)
      `
      )
      .eq('agreement_id', doc.agreement_id)
      .order('version_number', { ascending: false });

    if (versionsError) {
      return mapPgErrorToApiError(versionsError, corsHeaders);
    }

    // Format response
    const formattedVersions = (versions || []).map((v: any) => ({
      id: v.id,
      version_number: v.version_number,
      filename: v.filename,
      file_size_bytes: v.file_size_bytes,
      mime_type: v.mime_type,
      uploaded_at: v.uploaded_at,
      uploaded_by_email: v.uploader?.email || 'Unknown',
      tags: v.tags,
      notes: v.notes,
    }));

    return successResponse(formattedVersions, 200, corsHeaders);
  } catch (error) {
    console.error('List versions error:', error);
    return mapPgErrorToApiError(error, corsHeaders);
  }
}

// ============================================
// GET /agreements/documents/:id/download
// Get signed download URL
// ============================================
async function handleDownload(
  supabase: SupabaseClient,
  url: URL,
  documentId: string
): Promise<Response> {
  try {
    const versionParam = url.searchParams.get('version'); // 'latest' or version number

    // Get document record
    let query = supabase
      .from('agreement_documents')
      .select('id, storage_path, filename, version_number')
      .eq('agreement_id', documentId);

    if (versionParam && versionParam !== 'latest') {
      query = query.eq('version_number', parseInt(versionParam));
    }

    query = query.order('version_number', { ascending: false }).limit(1);

    const { data: document, error: docError } = await query.maybeSingle();

    if (docError || !document) {
      return notFoundError('Document version', corsHeaders);
    }

    // Generate signed download URL (5 minutes expiry)
    const { data: downloadData, error: downloadError } = await supabase.storage
      .from('agreement-docs')
      .createSignedUrl(document.storage_path, 300); // 5 minutes

    if (downloadError) {
      return mapPgErrorToApiError(downloadError, corsHeaders);
    }

    return successResponse(
      {
        download_url: downloadData.signedUrl,
        filename: document.filename,
        version_number: document.version_number,
        expires_at: new Date(Date.now() + 5 * 60 * 1000).toISOString(),
      },
      200,
      corsHeaders
    );
  } catch (error) {
    console.error('Download error:', error);
    return mapPgErrorToApiError(error, corsHeaders);
  }
}
