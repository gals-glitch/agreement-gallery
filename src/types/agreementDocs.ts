/**
 * Agreement Documents Types
 * Ticket: FE-201
 * Date: 2025-10-19
 *
 * TypeScript types for agreement documents repository
 */

// ============================================
// DOCUMENT TYPES
// ============================================

export interface AgreementDocument {
  id: string;
  agreement_id: number | string;
  file_sha256: string;
  storage_path: string;
  filename: string;
  file_size_bytes: number;
  mime_type: string;
  version_number: number;
  latest_version: number;
  uploaded_by: string;
  uploaded_at: string;
  tags: string[] | null;
  notes: string | null;
  created_at?: string;
  updated_at?: string;

  // Joined data from agreements table
  agreement?: {
    id: number;
    party_id: number;
    scope: 'FUND' | 'DEAL';
    fund_id: number | null;
    deal_id: number | null;
    party: {
      name: string;
    };
    fund?: {
      name: string;
    };
    deal?: {
      name: string;
    };
  };
}

export interface DocumentVersion {
  id: string;
  version_number: number;
  filename: string;
  file_size_bytes: number;
  mime_type: string;
  uploaded_at: string;
  uploaded_by_email: string;
  tags: string[] | null;
  notes: string | null;
}

// Extended version with user name for UI display
export interface AgreementDocumentVersion extends Omit<DocumentVersion, 'uploaded_by_email'> {
  document_id: string;
  uploaded_by: string;
  uploaded_by_name: string;
}

// ============================================
// API REQUEST/RESPONSE TYPES
// ============================================

export interface CreateDocumentRequest {
  agreement_id: string;
  filename: string;
  mime_type: string;
  file_size_bytes: number;
  tags?: string[];
  notes?: string;
}

export interface CreateDocumentResponse {
  upload_url: string;
  storage_path: string;
  version_number: number;
  agreement_id: string;
  expires_at: string;
}

export interface UploadVersionRequest {
  file: File;
  file_sha256: string;
  tags?: string[];
  notes?: string;
}

export interface UploadVersionResponse {
  document_id: string;
  version_number: number;
  storage_path: string;
}

export interface ListDocumentsParams {
  agreement_id?: string;
  party_id?: string;
  scope?: 'FUND' | 'DEAL';
  fund_id?: string;
  deal_id?: string;
  tag?: string;
  search?: string;
  limit?: number;
  offset?: number;
}

export interface ListDocumentsResponse {
  documents: AgreementDocument[];
  total_count: number;
}

export interface DownloadDocumentParams {
  version?: string | number; // 'latest' or version number
}

export interface DownloadDocumentResponse {
  download_url: string;
  filename: string;
  version_number: number;
  expires_at: string;
}

// ============================================
// UI STATE TYPES
// ============================================

export interface DocumentFilters {
  party_id: string | null;
  scope: 'FUND' | 'DEAL' | null;
  fund_id: string | null;
  deal_id: string | null;
  tags: string[];
  search: string;
}

export interface PaginationState {
  page: number;
  pageSize: number;
  total: number;
}

// ============================================
// MODAL TYPES
// ============================================

export interface PdfViewerModalProps {
  open: boolean;
  onClose: () => void;
  document: AgreementDocument | null;
  versions: DocumentVersion[];
  currentVersion: number;
  onVersionChange: (version: number) => void;
  onDownload: (version: number) => void;
}

export interface UploadVersionModalProps {
  open: boolean;
  onClose: () => void;
  agreementId: string;
  onSuccess: () => void;
}

export interface VersionsListModalProps {
  open: boolean;
  onClose: () => void;
  documentId: string;
  versions: DocumentVersion[];
  onDownload: (version: number) => void;
}

// ============================================
// HELPER FUNCTIONS
// ============================================

export function formatFileSize(bytes: number): string {
  if (bytes === 0) return '0 Bytes';

  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));

  return `${Math.round((bytes / Math.pow(k, i)) * 100) / 100} ${sizes[i]}`;
}

export function formatDate(dateString: string): string {
  return new Date(dateString).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

export async function calculateSHA256(file: File): Promise<string> {
  const buffer = await file.arrayBuffer();
  const hashBuffer = await crypto.subtle.digest('SHA-256', buffer);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
  return hashHex;
}

// Alias for backward compatibility
export const calculateFileSHA256 = calculateSHA256;
