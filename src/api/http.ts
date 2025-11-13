/**
 * HTTP Wrapper - Global API Fetch Utilities
 * Provides centralized error handling, authentication, and toast integration
 * Updated: 2025-10-19 (ORC-002: Error Contract Standardization)
 */

import { supabase } from '@/integrations/supabase/client';
import { toast } from '@/hooks/use-toast';
import { showApiError, isApiError } from '@/lib/errorToast';
import type { ApiError } from '@/types/api';

// ============================================
// TYPES
// ============================================
export interface APIError {
  error: string;
  detail?: string;
  details?: any;
}

export interface FetchOptions extends RequestInit {
  skipAuth?: boolean;
  skipErrorToast?: boolean;
}

// ============================================
// CONFIGURATION
// ============================================
const API_BASE = import.meta.env.VITE_API_V1_BASE_URL || 'http://localhost:54321/functions/v1/api-v1';

// ============================================
// AUTHENTICATION
// ============================================
async function getAuthToken(): Promise<string> {
  try {
    const { data: { session }, error } = await supabase.auth.getSession();

    // Handle "Invalid Refresh Token" or similar auth errors
    if (error || !session) {
      // If we have an error message about refresh token, sign out
      if (error && error.message && error.message.includes('refresh')) {
        console.warn('Invalid refresh token detected, signing out...');
        await supabase.auth.signOut();
        toast({
          title: 'Session Expired',
          description: 'Please sign in again.',
          variant: 'destructive',
        });
        // Redirect will be handled by AuthContext
      }
      throw new Error('Not authenticated');
    }

    return session.access_token;
  } catch (error) {
    // If session retrieval fails, sign out
    console.error('Auth error:', error);
    await supabase.auth.signOut();
    throw new Error('Authentication failed');
  }
}

// ============================================
// ERROR MAPPING
// ============================================
function parse422(body: any): string[] {
  if (!body) return ['Validation failed'];
  if (Array.isArray(body)) return body.map(x => x.message || String(x));
  if (Array.isArray(body?.errors)) return body.errors.map((e: any) => e.message || JSON.stringify(e));
  if (body.details) {
    if (Array.isArray(body.details)) return body.details.map((d: any) => d.message || String(d));
    return [JSON.stringify(body.details)];
  }
  return [body.error || body.message || body.detail || 'Validation failed'];
}

function mapErrorToMessage(status: number, error: APIError): string {
  // Map common HTTP status codes to user-friendly messages
  switch (status) {
    case 401:
      return 'Authentication required. Please log in again.';
    case 403:
      return 'You do not have permission to perform this action.';
    case 404:
      return 'Resource not found.';
    case 409:
      return `Conflict: ${error.detail || error.error}`;
    case 422:
      // Validation errors - normalize both array and object shapes
      const messages = parse422(error);
      return messages.join('; ');
    case 500:
      return 'Server error. Please try again later.';
    default:
      return error.detail || error.error || 'An unexpected error occurred';
  }
}

// ============================================
// MAIN FETCH WRAPPER
// ============================================
export async function apiFetch<T>(
  endpoint: string,
  options: FetchOptions = {}
): Promise<T> {
  const {
    skipAuth = false,
    skipErrorToast = false,
    ...fetchOptions
  } = options;

  try {
    // Build headers
    const headers: HeadersInit = {
      'Content-Type': 'application/json',
      ...fetchOptions.headers,
    };

    // Add authentication if not skipped
    if (!skipAuth) {
      const token = await getAuthToken();
      headers['Authorization'] = `Bearer ${token}`;
      headers['apikey'] = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY || '';
    }

    // Make request
    const response = await fetch(`${API_BASE}${endpoint}`, {
      ...fetchOptions,
      headers,
    });

    // Handle non-OK responses
    if (!response.ok) {
      // Handle 400 with "Invalid Refresh Token" as 401
      if (response.status === 400) {
        const text = await response.text();
        if (/Invalid Refresh Token/i.test(text)) {
          console.warn('Invalid refresh token in 400 response, signing out...');
          await supabase.auth.signOut();
          toast({
            title: 'Session Expired',
            description: 'Please sign in again.',
            variant: 'destructive',
          });
          throw new Error('Invalid refresh token');
        }
      }

      // Parse error response (try new ApiError format first, then fall back to legacy)
      let error: ApiError | APIError;
      try {
        const errorBody = await response.json();

        // Check if it's the new ApiError format (has 'code' and 'timestamp')
        if (isApiError(errorBody)) {
          error = errorBody;

          // Show toast using new error mapper
          if (!skipErrorToast) {
            showApiError(error, toast);
          }

          // Throw with structured error
          throw new APIErrorException(response.status, error, error.message);
        } else {
          // Legacy format
          error = errorBody;
          const errorMessage = mapErrorToMessage(response.status, error);

          if (!skipErrorToast) {
            toast({
              title: 'Error',
              description: errorMessage,
              variant: 'destructive',
            });
          }

          throw new APIErrorException(response.status, error, errorMessage);
        }
      } catch (parseError) {
        // Failed to parse JSON - use generic error
        const fallbackError: APIError = {
          error: `HTTP ${response.status}: ${response.statusText}`,
        };
        const errorMessage = mapErrorToMessage(response.status, fallbackError);

        if (!skipErrorToast) {
          toast({
            title: 'Error',
            description: errorMessage,
            variant: 'destructive',
          });
        }

        throw new APIErrorException(response.status, fallbackError, errorMessage);
      }
    }

    // Handle 204 No Content (safe JSON parsing)
    if (response.status === 204) {
      return null as T;
    }

    // Parse and return JSON (with 204-safe handling)
    const text = await response.text();
    return text ? JSON.parse(text) : null;
  } catch (error) {
    // Handle network errors
    if (error instanceof APIErrorException) {
      throw error;
    }

    const errorMessage = error instanceof Error
      ? error.message
      : 'Network error. Please check your connection.';

    if (!skipErrorToast) {
      toast({
        title: 'Network Error',
        description: errorMessage,
        variant: 'destructive',
      });
    }

    throw error;
  }
}

// ============================================
// CUSTOM ERROR CLASS
// ============================================
export class APIErrorException extends Error {
  constructor(
    public status: number,
    public apiError: APIError | ApiError,
    message: string
  ) {
    super(message);
    this.name = 'APIErrorException';
  }
}

// ============================================
// CONVENIENCE METHODS
// ============================================
export const http = {
  get: <T>(endpoint: string, options?: FetchOptions) =>
    apiFetch<T>(endpoint, { ...options, method: 'GET' }),

  post: <T>(endpoint: string, data?: any, options?: FetchOptions) =>
    apiFetch<T>(endpoint, {
      ...options,
      method: 'POST',
      body: data ? JSON.stringify(data) : undefined,
    }),

  patch: <T>(endpoint: string, data: any, options?: FetchOptions) =>
    apiFetch<T>(endpoint, {
      ...options,
      method: 'PATCH',
      body: JSON.stringify(data),
    }),

  put: <T>(endpoint: string, data: any, options?: FetchOptions) =>
    apiFetch<T>(endpoint, {
      ...options,
      method: 'PUT',
      body: JSON.stringify(data),
    }),

  delete: <T>(endpoint: string, options?: FetchOptions) =>
    apiFetch<T>(endpoint, { ...options, method: 'DELETE' }),
};

// ============================================
// QUERY STRING BUILDER
// ============================================
export function buildQueryString(params: Record<string, any>): string {
  const filtered = Object.entries(params)
    .filter(([_, v]) => v !== undefined && v !== null && v !== '')
    .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(String(v))}`);

  return filtered.length > 0 ? `?${filtered.join('&')}` : '';
}
