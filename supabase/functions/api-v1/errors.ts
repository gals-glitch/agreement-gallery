/**
 * API Error Contract - Standardized Error Responses
 * Ticket: ORC-002
 * Date: 2025-10-19
 *
 * Provides:
 * - Consistent error response format across all API endpoints
 * - Factory functions for common HTTP error codes
 * - Type-safe error handling
 * - Field-level and row-level error details
 *
 * Standard Error Codes:
 * - VALIDATION_ERROR (422) - Input validation failures
 * - FORBIDDEN (403) - Authorization/permission failures
 * - CONFLICT (409) - Uniqueness/constraint violations
 * - NOT_FOUND (404) - Resource not found
 * - UNAUTHORIZED (401) - Authentication required
 * - INTERNAL_ERROR (500) - Server errors
 */

// ============================================
// TYPES
// ============================================
export interface ApiErrorDetail {
  field?: string;      // Field name (e.g., 'investor_id', 'amount')
  row?: number;        // Row number for CSV/batch operations
  value?: any;         // Invalid value provided
  constraint?: string; // Constraint name (e.g., 'amount_positive', 'unique_email')
  message?: string;    // Human-readable error message
}

export interface ApiError {
  code: string;              // Error code (e.g., 'VALIDATION_ERROR', 'FORBIDDEN')
  message: string;           // Human-readable summary
  details?: ApiErrorDetail[]; // Optional field-level or row-level errors
  timestamp: string;         // ISO 8601 timestamp
  requestId?: string;        // Optional request tracking ID
}

// ============================================
// ERROR CODES
// ============================================
export const ERROR_CODES = {
  VALIDATION_ERROR: 'VALIDATION_ERROR',
  FORBIDDEN: 'FORBIDDEN',
  CONFLICT: 'CONFLICT',
  NOT_FOUND: 'NOT_FOUND',
  UNAUTHORIZED: 'UNAUTHORIZED',
  INTERNAL_ERROR: 'INTERNAL_ERROR',
} as const;

// ============================================
// HELPER: Create Error Response
// ============================================
function createErrorResponse(
  code: string,
  message: string,
  statusCode: number,
  details?: ApiErrorDetail[],
  corsHeaders: Record<string, string> = {}
): Response {
  const error: ApiError = {
    code,
    message,
    details,
    timestamp: new Date().toISOString(),
  };

  return new Response(JSON.stringify(error), {
    status: statusCode,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}

// ============================================
// FACTORY: Validation Error (422)
// ============================================
export function validationError(
  details: ApiErrorDetail[],
  corsHeaders: Record<string, string> = {}
): Response {
  // Generate summary message from details
  const message =
    details.length === 1
      ? details[0].message || 'Validation failed'
      : `Validation failed: ${details.length} error(s)`;

  return createErrorResponse(
    ERROR_CODES.VALIDATION_ERROR,
    message,
    422,
    details,
    corsHeaders
  );
}

// ============================================
// FACTORY: Forbidden Error (403)
// ============================================
export function forbiddenError(
  message: string = 'You do not have permission to perform this action',
  corsHeaders: Record<string, string> = {}
): Response {
  return createErrorResponse(
    ERROR_CODES.FORBIDDEN,
    message,
    403,
    undefined,
    corsHeaders
  );
}

// ============================================
// FACTORY: Conflict Error (409)
// ============================================
export function conflictError(
  message: string,
  details?: ApiErrorDetail[],
  corsHeaders: Record<string, string> = {}
): Response {
  return createErrorResponse(
    ERROR_CODES.CONFLICT,
    message,
    409,
    details,
    corsHeaders
  );
}

// ============================================
// FACTORY: Not Found Error (404)
// ============================================
export function notFoundError(
  resource: string,
  corsHeaders: Record<string, string> = {}
): Response {
  return createErrorResponse(
    ERROR_CODES.NOT_FOUND,
    `${resource} not found`,
    404,
    undefined,
    corsHeaders
  );
}

// ============================================
// FACTORY: Unauthorized Error (401)
// ============================================
export function unauthorizedError(
  message: string = 'Authentication required',
  corsHeaders: Record<string, string> = {}
): Response {
  return createErrorResponse(
    ERROR_CODES.UNAUTHORIZED,
    message,
    401,
    undefined,
    corsHeaders
  );
}

// ============================================
// FACTORY: Internal Server Error (500)
// ============================================
export function internalError(
  message: string = 'An internal server error occurred',
  corsHeaders: Record<string, string> = {}
): Response {
  return createErrorResponse(
    ERROR_CODES.INTERNAL_ERROR,
    message,
    500,
    undefined,
    corsHeaders
  );
}

// ============================================
// HELPER: Map PostgreSQL Errors to API Errors
// ============================================
export function mapPgErrorToApiError(
  err: any,
  corsHeaders: Record<string, string> = {}
): Response {
  // Postgres error codes:
  // 23514 - check_violation (e.g., contributions_one_scope_ck)
  // 23503 - foreign_key_violation
  // 23505 - unique_violation
  // 23502 - not_null_violation

  const code = err?.code;
  const message = err?.message || 'Database error';

  switch (code) {
    case '23514': // CHECK constraint violation
      return validationError(
        [{ message: `Constraint violation: ${message}`, constraint: code }],
        corsHeaders
      );

    case '23502': // NOT NULL constraint violation
      return validationError(
        [{ message: `Required field missing: ${message}`, constraint: code }],
        corsHeaders
      );

    case '23503': // Foreign key violation
      return validationError(
        [{ message: `Invalid reference: ${message}`, constraint: code }],
        corsHeaders
      );

    case '23505': // Unique constraint violation
      return conflictError(
        `Duplicate entry: ${message}`,
        [{ constraint: code, message }],
        corsHeaders
      );

    default:
      // Unknown database error
      return internalError(
        `Database error: ${message}`,
        corsHeaders
      );
  }
}

// ============================================
// HELPER: Create Success Response
// ============================================
export function successResponse(
  data: any,
  statusCode: number = 200,
  corsHeaders: Record<string, string> = {}
): Response {
  return new Response(JSON.stringify(data), {
    status: statusCode,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}
