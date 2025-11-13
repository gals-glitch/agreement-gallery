/**
 * Error Toast Mapper
 * Ticket: ORC-002
 * Date: 2025-10-19
 *
 * Maps API errors to user-friendly toast notifications.
 * Handles field-level validation errors, row-level CSV errors, and standard HTTP errors.
 *
 * Usage:
 * ```ts
 * import { showApiError } from '@/lib/errorToast';
 * import { toast } from '@/hooks/use-toast';
 *
 * try {
 *   await api.post('/endpoint', data);
 * } catch (error) {
 *   showApiError(error, toast);
 * }
 * ```
 */

import type { ApiError, ApiErrorDetail } from '@/types/api';

// ============================================
// TYPES
// ============================================
type ToastFunction = (props: {
  title: string;
  description?: string;
  variant?: 'default' | 'destructive';
}) => void;

// ============================================
// ERROR CODE MAPPINGS
// ============================================
const ERROR_CODE_MESSAGES: Record<string, string> = {
  VALIDATION_ERROR: 'Validation Error',
  FORBIDDEN: 'Permission Denied',
  CONFLICT: 'Conflict',
  NOT_FOUND: 'Not Found',
  UNAUTHORIZED: 'Unauthorized',
  INTERNAL_ERROR: 'Server Error',
};

// ============================================
// MAIN FUNCTION: Show API Error
// ============================================
export function showApiError(error: ApiError, toast: ToastFunction): void {
  const title = ERROR_CODE_MESSAGES[error.code] || 'Error';
  const description = formatErrorDescription(error);

  toast({
    title,
    description,
    variant: 'destructive',
  });
}

// ============================================
// HELPER: Format Error Description
// ============================================
function formatErrorDescription(error: ApiError): string {
  // If no details, return the main message
  if (!error.details || error.details.length === 0) {
    return error.message;
  }

  // Format details based on error code
  switch (error.code) {
    case 'VALIDATION_ERROR':
      return formatValidationErrors(error.details);

    case 'CONFLICT':
      return formatConflictError(error.message, error.details);

    default:
      // For other errors, show message + first detail
      if (error.details.length === 1 && error.details[0].message) {
        return error.details[0].message;
      }
      return error.message;
  }
}

// ============================================
// HELPER: Format Validation Errors
// ============================================
function formatValidationErrors(details: ApiErrorDetail[]): string {
  // Group errors by row (for CSV imports)
  const rowErrors: Record<number, ApiErrorDetail[]> = {};
  const fieldErrors: ApiErrorDetail[] = [];

  details.forEach(detail => {
    if (detail.row !== undefined) {
      if (!rowErrors[detail.row]) {
        rowErrors[detail.row] = [];
      }
      rowErrors[detail.row].push(detail);
    } else {
      fieldErrors.push(detail);
    }
  });

  const messages: string[] = [];

  // Add row-level errors (e.g., "Row 5: Invalid amount")
  Object.entries(rowErrors).forEach(([row, errors]) => {
    const rowMessages = errors
      .map(e => formatSingleError(e))
      .filter(Boolean)
      .join(', ');
    messages.push(`Row ${row}: ${rowMessages}`);
  });

  // Add field-level errors (e.g., "Amount must be positive")
  fieldErrors.forEach(error => {
    const msg = formatSingleError(error);
    if (msg) messages.push(msg);
  });

  // Join all messages
  if (messages.length === 0) {
    return 'Validation failed';
  }

  if (messages.length === 1) {
    return messages[0];
  }

  // Multiple errors: show as bulleted list (up to 5)
  const displayMessages = messages.slice(0, 5);
  const hasMore = messages.length > 5;

  return (
    displayMessages.map(m => `• ${m}`).join('\n') +
    (hasMore ? `\n• ...and ${messages.length - 5} more error(s)` : '')
  );
}

// ============================================
// HELPER: Format Single Error
// ============================================
function formatSingleError(error: ApiErrorDetail): string {
  if (error.message) {
    // If there's a field, prefix it
    if (error.field) {
      return `${error.field}: ${error.message}`;
    }
    return error.message;
  }

  // Fallback: construct message from field and value
  if (error.field) {
    return `Invalid ${error.field}`;
  }

  return 'Validation error';
}

// ============================================
// HELPER: Format Conflict Error
// ============================================
function formatConflictError(message: string, details: ApiErrorDetail[]): string {
  // For conflicts, show main message + first detail if available
  if (details.length > 0 && details[0].message) {
    return `${message}: ${details[0].message}`;
  }

  return message;
}

// ============================================
// HELPER: Check if Error is ApiError
// ============================================
export function isApiError(error: any): error is ApiError {
  return (
    error &&
    typeof error === 'object' &&
    'code' in error &&
    'message' in error &&
    'timestamp' in error
  );
}
