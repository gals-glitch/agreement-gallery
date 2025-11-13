-- ============================================
-- PG-201: Agreement Documents Repository Migration
-- Purpose: Document version management for agreements with Supabase Storage integration
-- Date: 2025-10-19
-- Version: 1.5.0
-- ============================================
--
-- OVERVIEW:
-- This migration creates a complete document management system for agreements including:
-- 1. agreement_documents table for metadata and version tracking
-- 2. Storage bucket for secure file storage
-- 3. Storage policies for RLS-gated access
-- 4. Helper function for auto-incrementing version numbers
-- 5. De-duplication mechanism via SHA256 hashing
--
-- DESIGN DECISIONS:
-- - Version numbers are auto-incremented per agreement (1, 2, 3...)
-- - file_sha256 enables de-duplication detection across agreements
-- - storage_path points to Supabase Storage bucket 'agreement-docs'
-- - Tags array enables flexible categorization (e.g., ['signed', 'amendment', 'final'])
-- - uploaded_by tracks auth.users(id) for audit trail
-- - UNIQUE constraint on (agreement_id, version_number) prevents duplicate versions
-- - CASCADE DELETE: deleting agreement removes all associated documents
--
-- STORAGE BUCKET STRUCTURE:
-- agreement-docs/
--   {agreement_id}/
--     v{version_number}_{filename}
--   Example: agreement-docs/123/v1_agreement_signed.pdf
--
-- ROLLBACK INSTRUCTIONS:
-- To rollback this migration:
-- DROP POLICY IF EXISTS "Authenticated users can read agreement documents" ON storage.objects;
-- DROP POLICY IF EXISTS "Ops+ can upload agreement documents" ON storage.objects;
-- DROP POLICY IF EXISTS "Finance+ can update agreement documents" ON storage.objects;
-- DROP POLICY IF EXISTS "Admin can delete agreement documents" ON storage.objects;
-- DELETE FROM storage.buckets WHERE id = 'agreement-docs';
-- DROP FUNCTION IF EXISTS get_next_document_version(BIGINT);
-- DROP INDEX IF EXISTS idx_agreement_docs_sha256;
-- DROP INDEX IF EXISTS idx_agreement_docs_tags;
-- DROP INDEX IF EXISTS idx_agreement_docs_uploaded_by;
-- DROP INDEX IF EXISTS idx_agreement_docs_uploaded_at;
-- DROP TABLE IF EXISTS agreement_documents CASCADE;
--
-- ============================================

-- ============================================
-- STEP 1: Create agreement_documents table
-- ============================================

CREATE TABLE IF NOT EXISTS agreement_documents (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agreement_id      BIGINT NOT NULL REFERENCES agreements(id) ON DELETE CASCADE,
  file_sha256       TEXT NOT NULL,
  storage_path      TEXT NOT NULL,
  filename          TEXT NOT NULL,
  file_size_bytes   BIGINT NOT NULL CHECK (file_size_bytes > 0),
  mime_type         TEXT NOT NULL,
  version_number    INTEGER NOT NULL CHECK (version_number > 0),
  uploaded_by       UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  uploaded_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  tags              TEXT[],
  notes             TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Unique constraint: one version number per agreement
  CONSTRAINT agreement_documents_unique_version_ck UNIQUE (agreement_id, version_number)
);

COMMENT ON TABLE agreement_documents IS 'Document versions for agreements with storage metadata and version tracking';
COMMENT ON COLUMN agreement_documents.id IS 'Unique document ID (UUID)';
COMMENT ON COLUMN agreement_documents.agreement_id IS 'Foreign key to agreements table';
COMMENT ON COLUMN agreement_documents.file_sha256 IS 'SHA256 hash of file content for de-duplication and integrity verification';
COMMENT ON COLUMN agreement_documents.storage_path IS 'Full path in Supabase Storage (e.g., agreement-docs/123/v1_agreement.pdf)';
COMMENT ON COLUMN agreement_documents.filename IS 'Original filename uploaded by user';
COMMENT ON COLUMN agreement_documents.file_size_bytes IS 'File size in bytes';
COMMENT ON COLUMN agreement_documents.mime_type IS 'MIME type (e.g., application/pdf, image/png)';
COMMENT ON COLUMN agreement_documents.version_number IS 'Auto-incremented version number per agreement (1, 2, 3...)';
COMMENT ON COLUMN agreement_documents.uploaded_by IS 'User who uploaded this document (auth.users.id)';
COMMENT ON COLUMN agreement_documents.uploaded_at IS 'Timestamp when document was uploaded';
COMMENT ON COLUMN agreement_documents.tags IS 'Flexible tags for categorization (e.g., {signed, amendment, final})';
COMMENT ON COLUMN agreement_documents.notes IS 'Optional notes about this document version';

-- ============================================
-- STEP 2: Create indexes for performance
-- ============================================

-- Index on agreement_id for listing documents per agreement
CREATE INDEX IF NOT EXISTS idx_agreement_docs_agreement
  ON agreement_documents(agreement_id);

-- Index on file_sha256 for de-duplication lookups
CREATE INDEX IF NOT EXISTS idx_agreement_docs_sha256
  ON agreement_documents(file_sha256);

-- Index on tags for tag-based filtering (GIN index for array containment)
CREATE INDEX IF NOT EXISTS idx_agreement_docs_tags
  ON agreement_documents USING GIN(tags)
  WHERE tags IS NOT NULL;

-- Index on uploaded_by for user activity tracking
CREATE INDEX IF NOT EXISTS idx_agreement_docs_uploaded_by
  ON agreement_documents(uploaded_by);

-- Index on uploaded_at for chronological queries
CREATE INDEX IF NOT EXISTS idx_agreement_docs_uploaded_at
  ON agreement_documents(uploaded_at DESC);

-- Composite index for latest version queries
CREATE INDEX IF NOT EXISTS idx_agreement_docs_latest
  ON agreement_documents(agreement_id, version_number DESC);

-- ============================================
-- STEP 3: Create helper function for version auto-increment
-- ============================================

CREATE OR REPLACE FUNCTION get_next_document_version(p_agreement_id BIGINT)
RETURNS INTEGER AS $$
DECLARE
  next_version INTEGER;
BEGIN
  -- Get the maximum version_number for this agreement and add 1
  -- If no versions exist, start at 1
  SELECT COALESCE(MAX(version_number), 0) + 1
    INTO next_version
  FROM agreement_documents
  WHERE agreement_id = p_agreement_id;

  RETURN next_version;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_next_document_version IS 'Returns next version number for an agreement (max + 1, or 1 if none exist)';

-- ============================================
-- STEP 4: Create trigger for updated_at timestamp
-- ============================================

CREATE OR REPLACE FUNCTION update_agreement_documents_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname='agreement_documents_update_timestamp') THEN
    CREATE TRIGGER agreement_documents_update_timestamp
      BEFORE UPDATE ON agreement_documents
      FOR EACH ROW
      EXECUTE FUNCTION update_agreement_documents_timestamp();
  END IF;
END $$;

-- ============================================
-- STEP 5: Create Supabase Storage bucket
-- ============================================

-- Insert storage bucket (idempotent via ON CONFLICT)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'agreement-docs',
  'agreement-docs',
  false,  -- Private bucket (RLS-gated)
  52428800,  -- 50MB limit per file
  ARRAY[
    'application/pdf',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',  -- .docx
    'application/msword',  -- .doc
    'image/png',
    'image/jpeg',
    'image/gif',
    'text/plain'
  ]::text[]
)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

COMMENT ON TABLE storage.buckets IS 'Supabase Storage buckets configuration';

-- ============================================
-- STEP 6: Create storage policies for RLS
-- ============================================

-- Policy 1: Authenticated users can read (download) documents
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='storage' AND tablename='objects'
    AND policyname='Authenticated users can read agreement documents'
  ) THEN
    CREATE POLICY "Authenticated users can read agreement documents"
      ON storage.objects
      FOR SELECT
      TO authenticated
      USING (bucket_id = 'agreement-docs');
  END IF;
END $$;

-- Policy 2: Authenticated users can upload (insert) documents
-- In production, restrict this to ops+ role if needed
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='storage' AND tablename='objects'
    AND policyname='Authenticated users can upload agreement documents'
  ) THEN
    CREATE POLICY "Authenticated users can upload agreement documents"
      ON storage.objects
      FOR INSERT
      TO authenticated
      WITH CHECK (bucket_id = 'agreement-docs');
  END IF;
END $$;

-- Policy 3: Authenticated users can update document metadata
-- In production, restrict this to finance+ role if needed
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='storage' AND tablename='objects'
    AND policyname='Authenticated users can update agreement documents'
  ) THEN
    CREATE POLICY "Authenticated users can update agreement documents"
      ON storage.objects
      FOR UPDATE
      TO authenticated
      USING (bucket_id = 'agreement-docs')
      WITH CHECK (bucket_id = 'agreement-docs');
  END IF;
END $$;

-- Policy 4: Authenticated users can delete documents
-- In production, restrict this to admin role if needed
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='storage' AND tablename='objects'
    AND policyname='Authenticated users can delete agreement documents'
  ) THEN
    CREATE POLICY "Authenticated users can delete agreement documents"
      ON storage.objects
      FOR DELETE
      TO authenticated
      USING (bucket_id = 'agreement-docs');
  END IF;
END $$;

-- ============================================
-- STEP 7: Enable RLS on agreement_documents table
-- ============================================

ALTER TABLE agreement_documents ENABLE ROW LEVEL SECURITY;

-- Policy 1: All authenticated users can read documents metadata
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename='agreement_documents'
    AND policyname='Authenticated users can read agreement documents metadata'
  ) THEN
    CREATE POLICY "Authenticated users can read agreement documents metadata"
      ON agreement_documents
      FOR SELECT
      TO authenticated
      USING (true);
  END IF;
END $$;

-- Policy 2: Authenticated users can insert document metadata
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename='agreement_documents'
    AND policyname='Authenticated users can insert agreement documents metadata'
  ) THEN
    CREATE POLICY "Authenticated users can insert agreement documents metadata"
      ON agreement_documents
      FOR INSERT
      TO authenticated
      WITH CHECK (true);
  END IF;
END $$;

-- Policy 3: Authenticated users can update tags/notes
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename='agreement_documents'
    AND policyname='Authenticated users can update agreement documents metadata'
  ) THEN
    CREATE POLICY "Authenticated users can update agreement documents metadata"
      ON agreement_documents
      FOR UPDATE
      TO authenticated
      USING (true)
      WITH CHECK (true);
  END IF;
END $$;

-- Policy 4: Authenticated users can delete document metadata
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename='agreement_documents'
    AND policyname='Authenticated users can delete agreement documents metadata'
  ) THEN
    CREATE POLICY "Authenticated users can delete agreement documents metadata"
      ON agreement_documents
      FOR DELETE
      TO authenticated
      USING (true);
  END IF;
END $$;

-- ============================================
-- STEP 8: Create materialized view for latest versions (optional)
-- ============================================

-- Materialized view showing the latest version of each agreement's documents
CREATE MATERIALIZED VIEW IF NOT EXISTS agreement_documents_latest AS
SELECT DISTINCT ON (agreement_id)
  id,
  agreement_id,
  file_sha256,
  storage_path,
  filename,
  file_size_bytes,
  mime_type,
  version_number,
  uploaded_by,
  uploaded_at,
  tags,
  notes
FROM agreement_documents
ORDER BY agreement_id, version_number DESC;

CREATE UNIQUE INDEX IF NOT EXISTS idx_agreement_docs_latest_mv
  ON agreement_documents_latest(agreement_id);

COMMENT ON MATERIALIZED VIEW agreement_documents_latest IS 'Latest document version per agreement (refresh with: REFRESH MATERIALIZED VIEW CONCURRENTLY agreement_documents_latest)';

-- Note: This view needs to be refreshed after document uploads:
-- REFRESH MATERIALIZED VIEW CONCURRENTLY agreement_documents_latest;
-- Consider adding a trigger or scheduled job to refresh automatically

-- ============================================
-- VALIDATION QUERIES (for manual testing)
-- ============================================

-- Query 1: List all documents for an agreement
-- SELECT
--   ad.version_number,
--   ad.filename,
--   ad.file_size_bytes,
--   ad.mime_type,
--   ad.uploaded_at,
--   u.email AS uploaded_by_email,
--   ad.tags,
--   ad.notes
-- FROM agreement_documents ad
-- LEFT JOIN auth.users u ON ad.uploaded_by = u.id
-- WHERE ad.agreement_id = 123
-- ORDER BY ad.version_number DESC;

-- Query 2: Get next version number for an agreement
-- SELECT get_next_document_version(123);

-- Query 3: Find duplicate documents by SHA256
-- SELECT
--   file_sha256,
--   COUNT(*) AS duplicate_count,
--   array_agg(agreement_id) AS agreement_ids,
--   array_agg(filename) AS filenames
-- FROM agreement_documents
-- GROUP BY file_sha256
-- HAVING COUNT(*) > 1;

-- Query 4: List agreements with document counts
-- SELECT
--   a.id,
--   a.party_id,
--   a.status,
--   COUNT(ad.id) AS document_count,
--   MAX(ad.version_number) AS latest_version,
--   MAX(ad.uploaded_at) AS last_upload
-- FROM agreements a
-- LEFT JOIN agreement_documents ad ON a.id = ad.agreement_id
-- GROUP BY a.id, a.party_id, a.status
-- HAVING COUNT(ad.id) > 0
-- ORDER BY last_upload DESC;

-- Query 5: Test index usage with EXPLAIN
-- EXPLAIN (ANALYZE, BUFFERS)
-- SELECT * FROM agreement_documents
-- WHERE file_sha256 = 'abc123...';
-- Expected: Index Scan using idx_agreement_docs_sha256

-- Query 6: Find documents by tag
-- SELECT
--   ad.agreement_id,
--   ad.filename,
--   ad.version_number,
--   ad.tags
-- FROM agreement_documents ad
-- WHERE tags @> ARRAY['signed']::text[]
-- ORDER BY ad.uploaded_at DESC;
-- Expected: Bitmap Index Scan on idx_agreement_docs_tags

-- ============================================
-- EXAMPLE USAGE WORKFLOW
-- ============================================

-- UPLOAD WORKFLOW:
-- 1. Client uploads file to Supabase Storage:
--    const { data, error } = await supabase.storage
--      .from('agreement-docs')
--      .upload(`${agreementId}/v${nextVersion}_${filename}`, file);
--
-- 2. Client calculates SHA256 hash of file content
--
-- 3. Client gets next version number:
--    const { data: nextVersion } = await supabase.rpc('get_next_document_version', { p_agreement_id: 123 });
--
-- 4. Client inserts metadata:
--    await supabase.from('agreement_documents').insert({
--      agreement_id: 123,
--      file_sha256: calculatedHash,
--      storage_path: `123/v${nextVersion}_${filename}`,
--      filename: filename,
--      file_size_bytes: file.size,
--      mime_type: file.type,
--      version_number: nextVersion,
--      uploaded_by: userId,
--      tags: ['draft']
--    });
--
-- DOWNLOAD WORKFLOW:
-- 1. Client fetches document metadata:
--    const { data } = await supabase
--      .from('agreement_documents')
--      .select('*')
--      .eq('agreement_id', 123)
--      .order('version_number', { ascending: false });
--
-- 2. Client downloads file from storage:
--    const { data: blob } = await supabase.storage
--      .from('agreement-docs')
--      .download(storagePath);

-- ============================================
-- PERFORMANCE NOTES
-- ============================================
-- Index Strategy:
-- 1. idx_agreement_docs_agreement: Primary foreign key index for agreement lookups
--    High selectivity - each agreement has few documents (1-10 typically)
-- 2. idx_agreement_docs_sha256: Hash lookup for de-duplication checks
--    Very high selectivity - SHA256 collisions are virtually impossible
-- 3. idx_agreement_docs_tags: GIN index for array containment queries
--    Moderate selectivity - tags are low cardinality but flexible
-- 4. idx_agreement_docs_latest: Composite index for "latest version" queries
--    Optimizes the common pattern of fetching the most recent document
--
-- Storage Bucket Configuration:
-- - 50MB file size limit (configurable)
-- - Private bucket with RLS policies
-- - Allowed MIME types restrict uploads to documents/images only
-- - Path structure: agreement-docs/{agreement_id}/v{version}_filename
--
-- Materialized View Refresh:
-- - agreement_documents_latest should be refreshed after uploads
-- - Use REFRESH MATERIALIZED VIEW CONCURRENTLY to avoid locking
-- - Consider a trigger or scheduled job for automatic refresh
--
-- Write Performance:
-- - Minimal overhead: 6 indexes on metadata table (not storage)
-- - Storage writes are handled by Supabase Storage (separate from DB)
-- - Version number calculation is O(1) with index on (agreement_id, version_number)
--
-- Read Performance:
-- - Excellent: all common queries have dedicated indexes
-- - file_sha256 lookups are instant (unique hash)
-- - Tag filtering uses GIN index for fast array containment
-- - Latest version queries use composite index to avoid full scan
--
-- ============================================
-- END MIGRATION PG-201
-- ============================================
