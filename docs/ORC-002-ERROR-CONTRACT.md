# ORC-002: Error Contract Standardization

**Status:** Complete
**Date:** 2025-10-19
**Owner:** Orchestrator/Backend/Frontend

---

## Overview

Standardizes API error responses across all endpoints with consistent error codes, field-level validation details, and user-friendly toast notifications.

### Architecture

```
┌──────────────────┐
│  Backend API     │
│  errors.ts       │
│  ┌────────────┐  │
│  │ Factory    │  │
│  │ Functions  │  │
│  └────────────┘  │
└────────┬─────────┘
         │
         │ ApiError (JSON)
         │
┌────────▼─────────┐
│  Frontend        │
│  http.ts         │
│  ┌────────────┐  │
│  │ Global     │  │
│  │ Handler    │  │
│  └──────┬─────┘  │
│         │        │
│  ┌──────▼─────┐  │
│  │ errorToast │  │
│  │ Mapper     │  │
│  └──────┬─────┘  │
│         │        │
│  ┌──────▼─────┐  │
│  │  Toast UI  │  │
│  └────────────┘  │
└──────────────────┘
```

---

## Error Contract Specification

### ApiError Interface

```typescript
interface ApiErrorDetail {
  field?: string;      // Field name (e.g., 'investor_id', 'amount')
  row?: number;        // Row number for CSV/batch operations
  value?: any;         // Invalid value provided
  constraint?: string; // Constraint name (e.g., 'amount_positive')
  message?: string;    // Human-readable error message
}

interface ApiError {
  code: string;              // Error code (e.g., 'VALIDATION_ERROR')
  message: string;           // Human-readable summary
  details?: ApiErrorDetail[]; // Optional field-level errors
  timestamp: string;         // ISO 8601 timestamp
  requestId?: string;        // Optional request tracking ID
}
```

### Standard Error Codes

| Code | HTTP Status | Description | Use Case |
|------|-------------|-------------|----------|
| `VALIDATION_ERROR` | 422 | Input validation failure | Invalid field values, missing required fields |
| `FORBIDDEN` | 403 | Authorization failure | User lacks required role/permission |
| `CONFLICT` | 409 | Uniqueness violation | Duplicate email, unique constraint |
| `NOT_FOUND` | 404 | Resource not found | Invalid ID, deleted entity |
| `UNAUTHORIZED` | 401 | Authentication required | Missing/expired token |
| `INTERNAL_ERROR` | 500 | Server error | Database failure, unexpected exception |

---

## Implementation Details

### 1. Backend Error Factory

**File:** `supabase/functions/api-v1/errors.ts`

**Factory Functions:**

#### validationError()
```typescript
validationError(
  details: ApiErrorDetail[],
  corsHeaders?: Record<string, string>
): Response

// Example
return validationError([
  {
    field: 'amount',
    message: 'Must be a positive number',
    value: -100,
    constraint: 'amount_positive',
  },
  {
    field: 'investor_id',
    message: 'investor_id is required',
    value: null,
  }
], corsHeaders);
```

**Response (422):**
```json
{
  "code": "VALIDATION_ERROR",
  "message": "Validation failed: 2 error(s)",
  "details": [
    {
      "field": "amount",
      "message": "Must be a positive number",
      "value": -100,
      "constraint": "amount_positive"
    },
    {
      "field": "investor_id",
      "message": "investor_id is required",
      "value": null
    }
  ],
  "timestamp": "2025-10-19T10:30:00.000Z"
}
```

#### forbiddenError()
```typescript
forbiddenError(
  message: string,
  corsHeaders?: Record<string, string>
): Response

// Example
return forbiddenError('Requires manager or admin role to approve agreements', corsHeaders);
```

**Response (403):**
```json
{
  "code": "FORBIDDEN",
  "message": "Requires manager or admin role to approve agreements",
  "timestamp": "2025-10-19T10:30:00.000Z"
}
```

#### conflictError()
```typescript
conflictError(
  message: string,
  details?: ApiErrorDetail[],
  corsHeaders?: Record<string, string>
): Response

// Example
return conflictError('Duplicate email address', [
  { field: 'email', constraint: 'unique_email', value: 'john@example.com' }
], corsHeaders);
```

**Response (409):**
```json
{
  "code": "CONFLICT",
  "message": "Duplicate email address",
  "details": [
    {
      "field": "email",
      "constraint": "unique_email",
      "value": "john@example.com"
    }
  ],
  "timestamp": "2025-10-19T10:30:00.000Z"
}
```

#### notFoundError()
```typescript
notFoundError(
  resource: string,
  corsHeaders?: Record<string, string>
): Response

// Example
return notFoundError('Agreement', corsHeaders);
```

**Response (404):**
```json
{
  "code": "NOT_FOUND",
  "message": "Agreement not found",
  "timestamp": "2025-10-19T10:30:00.000Z"
}
```

#### mapPgErrorToApiError()
```typescript
mapPgErrorToApiError(
  err: any,
  corsHeaders?: Record<string, string>
): Response

// Example
const { error } = await supabase.from('contributions').insert(data);
if (error) return mapPgErrorToApiError(error, corsHeaders);
```

**Maps PostgreSQL error codes:**
- `23514` (CHECK violation) → `VALIDATION_ERROR` (422)
- `23502` (NOT NULL violation) → `VALIDATION_ERROR` (422)
- `23503` (Foreign key violation) → `VALIDATION_ERROR` (422)
- `23505` (Unique violation) → `CONFLICT` (409)
- Other → `INTERNAL_ERROR` (500)

---

### 2. Backend Integration

**File:** `supabase/functions/api-v1/index.ts`

**Before (Old Format):**
```typescript
// POST /contributions
const body = await req.json();
if (!body.investor_id) {
  return jsonResponse({ error: 'investor_id is required' }, 422);
}

const { error } = await supabase.from('contributions').insert(data);
if (error) return jsonResponse({ error: error.message }, 400);
```

**After (New Error Contract):**
```typescript
// POST /contributions
const body = await req.json();
const v = validateContributionPayload(body);
if (!v.ok) return validationError(v.details, corsHeaders);

const { error } = await supabase.from('contributions').insert(data);
if (error) return mapPgErrorToApiError(error, corsHeaders);
```

**Validation Function:**
```typescript
function validateContributionPayload(p: any): { ok: true } | { ok: false; details: ApiErrorDetail[] } {
  const details: ApiErrorDetail[] = [];

  if (!p.investor_id) {
    details.push({
      field: 'investor_id',
      message: 'investor_id is required',
      value: p.investor_id,
    });
  }

  if (typeof p.amount !== 'number' || !(p.amount > 0)) {
    details.push({
      field: 'amount',
      message: 'amount must be a positive number',
      value: p.amount,
      constraint: 'amount_positive',
    });
  }

  if (details.length) return { ok: false, details };
  return { ok: true };
}
```

**Updated Endpoints:**
- `POST /contributions` - Single contribution validation
- `POST /contributions/batch` - CSV import with row-level errors
- `POST /agreements/:id/approve` - RBAC forbidden error
- `POST /runs/:id/approve` - RBAC forbidden error

---

### 3. Frontend Error Types

**File:** `src/types/api.ts`

```typescript
export interface ApiErrorDetail {
  field?: string;
  row?: number;
  value?: any;
  constraint?: string;
  message?: string;
}

export interface ApiError {
  code: string;
  message: string;
  details?: ApiErrorDetail[];
  timestamp: string;
  requestId?: string;
}
```

---

### 4. Frontend Toast Mapper

**File:** `src/lib/errorToast.ts`

**Function Signature:**
```typescript
function showApiError(error: ApiError, toast: ToastFunction): void
```

**Error Code → Toast Title Mapping:**
| Error Code | Toast Title |
|------------|-------------|
| `VALIDATION_ERROR` | "Validation Error" |
| `FORBIDDEN` | "Permission Denied" |
| `CONFLICT` | "Conflict" |
| `NOT_FOUND` | "Not Found" |
| `UNAUTHORIZED` | "Unauthorized" |
| `INTERNAL_ERROR` | "Server Error" |

**Toast Description Formatting:**

**Single Error:**
```
Description: "amount: Must be a positive number"
```

**Multiple Errors:**
```
Description:
• amount: Must be a positive number
• investor_id: investor_id is required
```

**Row-Level Errors (CSV Import):**
```
Description:
• Row 5: amount: Invalid value
• Row 12: investor_id: Missing required field
• Row 18: deal_id/fund_id: Exactly one required
```

**More than 5 Errors:**
```
Description:
• Row 5: amount: Invalid value
• Row 12: investor_id: Missing
• Row 18: deal_id: Required
• Row 23: amount: Must be positive
• Row 31: paid_in_date: Invalid format
• ...and 10 more error(s)
```

---

### 5. Frontend HTTP Client Integration

**File:** `src/api/http.ts`

**Updated Error Handling:**
```typescript
// Parse error response
if (!response.ok) {
  const errorBody = await response.json();

  // Check if it's the new ApiError format
  if (isApiError(errorBody)) {
    // Use new error mapper
    if (!skipErrorToast) {
      showApiError(errorBody, toast);
    }
    throw new APIErrorException(response.status, errorBody, errorBody.message);
  } else {
    // Fall back to legacy format
    const errorMessage = mapErrorToMessage(response.status, errorBody);
    if (!skipErrorToast) {
      toast({ title: 'Error', description: errorMessage, variant: 'destructive' });
    }
    throw new APIErrorException(response.status, errorBody, errorMessage);
  }
}
```

**Type Guard:**
```typescript
function isApiError(error: any): error is ApiError {
  return (
    error &&
    typeof error === 'object' &&
    'code' in error &&
    'message' in error &&
    'timestamp' in error
  );
}
```

---

## Testing Instructions

### Manual Testing

#### 1. Backend Validation Errors

**Test Single Field Error:**
```bash
curl -X POST http://localhost:54321/functions/v1/api-v1/contributions \
  -H "Authorization: Bearer YOUR_JWT" \
  -H "Content-Type: application/json" \
  -d '{
    "investor_id": 1,
    "fund_id": 1,
    "paid_in_date": "2025-01-01",
    "amount": -100
  }'
```

**Expected Response (422):**
```json
{
  "code": "VALIDATION_ERROR",
  "message": "amount must be a positive number",
  "details": [
    {
      "field": "amount",
      "message": "amount must be a positive number",
      "value": -100,
      "constraint": "amount_positive"
    }
  ],
  "timestamp": "2025-10-19T10:30:00.000Z"
}
```

**Test Multiple Validation Errors:**
```bash
curl -X POST http://localhost:54321/functions/v1/api-v1/contributions \
  -H "Authorization: Bearer YOUR_JWT" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": -100
  }'
```

**Expected Response (422):**
```json
{
  "code": "VALIDATION_ERROR",
  "message": "Validation failed: 3 error(s)",
  "details": [
    {
      "field": "deal_id/fund_id",
      "message": "Exactly one of deal_id or fund_id is required",
      "value": { "deal_id": null, "fund_id": null }
    },
    {
      "field": "investor_id",
      "message": "investor_id is required",
      "value": null
    },
    {
      "field": "paid_in_date",
      "message": "paid_in_date is required (YYYY-MM-DD format)",
      "value": null
    }
  ],
  "timestamp": "2025-10-19T10:30:00.000Z"
}
```

#### 2. Batch Validation Errors (CSV Import)

**Test Row-Level Errors:**
```bash
curl -X POST http://localhost:54321/functions/v1/api-v1/contributions/batch \
  -H "Authorization: Bearer YOUR_JWT" \
  -H "Content-Type: application/json" \
  -d '[
    {
      "investor_id": 1,
      "fund_id": 1,
      "paid_in_date": "2025-01-01",
      "amount": 1000
    },
    {
      "investor_id": 1,
      "fund_id": 1,
      "paid_in_date": "2025-01-01",
      "amount": -500
    },
    {
      "investor_id": null,
      "fund_id": 1,
      "paid_in_date": "2025-01-01",
      "amount": 1000
    }
  ]'
```

**Expected Response (422):**
```json
{
  "code": "VALIDATION_ERROR",
  "message": "Validation failed: 2 error(s)",
  "details": [
    {
      "field": "amount",
      "message": "amount must be a positive number",
      "value": -500,
      "constraint": "amount_positive",
      "row": 2
    },
    {
      "field": "investor_id",
      "message": "investor_id is required",
      "value": null,
      "row": 3
    }
  ],
  "timestamp": "2025-10-19T10:30:00.000Z"
}
```

#### 3. Authorization Errors

**Test Forbidden (non-admin approving agreement):**
```bash
curl -X POST http://localhost:54321/functions/v1/api-v1/agreements/123/approve \
  -H "Authorization: Bearer VIEWER_JWT"
```

**Expected Response (403):**
```json
{
  "code": "FORBIDDEN",
  "message": "Requires manager or admin role to approve agreements",
  "timestamp": "2025-10-19T10:30:00.000Z"
}
```

#### 4. Frontend Toast Testing

**Test Validation Error Toast:**
1. Create a form that submits invalid data
2. Submit the form
3. Verify toast appears with:
   - Title: "Validation Error"
   - Description: Field-level error messages

**Example Code:**
```tsx
import { http } from '@/api/http';
import { toast } from '@/hooks/use-toast';

async function handleSubmit(data: any) {
  try {
    await http.post('/contributions', data);
    toast({ title: 'Success', description: 'Contribution created' });
  } catch (error) {
    // Error toast automatically shown by http.ts
    console.error(error);
  }
}
```

**Test CSV Import Errors:**
1. Upload a CSV with errors in rows 5, 12, 18
2. Submit the import
3. Verify toast shows:
   ```
   Title: Validation Error
   Description:
   • Row 5: amount: Must be positive
   • Row 12: investor_id: Required
   • Row 18: deal_id/fund_id: Exactly one required
   ```

---

## Integration Examples

### Example 1: Form Validation

**Backend:**
```typescript
// POST /deals
async function handleDeals(req: Request, supabase: any) {
  const body = await req.json();

  // Validate input
  const details: ApiErrorDetail[] = [];

  if (!body.name || body.name.trim().length === 0) {
    details.push({
      field: 'name',
      message: 'Deal name is required',
      value: body.name,
    });
  }

  if (body.close_date && !isValidDate(body.close_date)) {
    details.push({
      field: 'close_date',
      message: 'Invalid date format (expected YYYY-MM-DD)',
      value: body.close_date,
    });
  }

  if (details.length) {
    return validationError(details, corsHeaders);
  }

  // Insert deal
  const { data, error } = await supabase.from('deals').insert(body).select();
  if (error) return mapPgErrorToApiError(error, corsHeaders);

  return successResponse({ id: data.id }, 201, corsHeaders);
}
```

**Frontend:**
```tsx
import { http } from '@/api/http';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';

function CreateDealForm() {
  const [name, setName] = useState('');
  const [closeDate, setCloseDate] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);

    try {
      const { id } = await http.post<{ id: number }>('/deals', {
        name,
        close_date: closeDate,
      });

      toast({
        title: 'Deal Created',
        description: `Deal #${id} created successfully`,
      });

      // Reset form
      setName('');
      setCloseDate('');
    } catch (error) {
      // Error toast automatically shown by http.ts
      console.error('Failed to create deal:', error);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <Input
        value={name}
        onChange={e => setName(e.target.value)}
        placeholder="Deal Name"
      />
      <Input
        type="date"
        value={closeDate}
        onChange={e => setCloseDate(e.target.value)}
      />
      <Button type="submit" disabled={isSubmitting}>
        Create Deal
      </Button>
    </form>
  );
}
```

**Toast Behavior:**
- **Success:** Green toast with "Deal Created" title
- **Validation Error:** Red toast with field-level errors:
  ```
  Title: Validation Error
  Description: name: Deal name is required
  ```
- **Server Error:** Red toast with generic message

### Example 2: CSV Import with Row Errors

**Backend:**
```typescript
// POST /contributions/batch
async function handleContributionsBatch(req: Request, supabase: any) {
  const body = await req.json();

  if (!Array.isArray(body)) {
    return validationError([{ message: 'Request body must be an array' }], corsHeaders);
  }

  // Validate all rows
  const pre = body.map((row, i) => ({ row: i, v: validateContributionPayload(row) }));
  const bad = pre.filter(r => !r.v.ok);

  if (bad.length) {
    const allDetails: ApiErrorDetail[] = bad.flatMap(b =>
      (b.v as any).details.map((d: ApiErrorDetail) => ({
        ...d,
        row: b.row + 1, // 1-indexed for display
      }))
    );

    return validationError(allDetails, corsHeaders);
  }

  // Insert all rows
  const { data, error } = await supabase.from('contributions').insert(body);
  if (error) return mapPgErrorToApiError(error, corsHeaders);

  return successResponse({ inserted: data.length }, 201, corsHeaders);
}
```

**Frontend:**
```tsx
import { http } from '@/api/http';
import Papa from 'papaparse';

function CSVImport() {
  const handleFileUpload = async (file: File) => {
    Papa.parse(file, {
      header: true,
      complete: async (results) => {
        try {
          const { inserted } = await http.post<{ inserted: number }>(
            '/contributions/batch',
            results.data
          );

          toast({
            title: 'Import Successful',
            description: `Imported ${inserted} contributions`,
          });
        } catch (error) {
          // Error toast automatically shown with row numbers
          console.error('Import failed:', error);
        }
      },
    });
  };

  return <input type="file" accept=".csv" onChange={e => handleFileUpload(e.target.files[0])} />;
}
```

**Toast Behavior:**
- **Success:** Green toast with "Import Successful" + count
- **Row Errors:** Red toast with row-specific errors:
  ```
  Title: Validation Error
  Description:
  • Row 5: amount: Must be positive
  • Row 12: investor_id: Required
  • Row 18: deal_id/fund_id: Exactly one required
  ```

---

## Migration Path

### Phase 1: Backend Migration (Complete)
- ✅ Created error factory functions
- ✅ Updated contributions endpoints
- ✅ Updated RBAC endpoints (agreements, runs)
- ✅ Added PostgreSQL error mapper

### Phase 2: Frontend Migration (Complete)
- ✅ Created ApiError types
- ✅ Created toast mapper
- ✅ Updated http.ts global handler
- ✅ Backward compatibility with legacy errors

### Phase 3: Endpoint Rollout
**Next Steps:**
1. Update remaining endpoints (parties, funds, deals, fund-tracks)
2. Add validation functions for each entity
3. Test error responses in production
4. Monitor error logs for unexpected formats

### Phase 4: Deprecate Legacy Format
**After 2 releases:**
1. Remove legacy `APIError` interface
2. Remove legacy error mapping in http.ts
3. Update all documentation to show only new format

---

## Troubleshooting

### Issue: Toast not showing field-level errors
**Solution:** Verify error response has `details` array:
```json
{
  "code": "VALIDATION_ERROR",
  "message": "Validation failed",
  "details": [
    { "field": "amount", "message": "Must be positive" }
  ]
}
```

### Issue: Row numbers not showing in CSV errors
**Solution:** Ensure backend adds `row` to each detail:
```typescript
const allDetails = bad.flatMap(b =>
  b.v.details.map(d => ({ ...d, row: b.row + 1 }))
);
```

### Issue: Generic "Server Error" instead of validation details
**Solution:** Check backend is using `validationError()` not `internalError()`:
```typescript
// WRONG
if (!body.name) return internalError('Name required', corsHeaders);

// CORRECT
if (!body.name) {
  return validationError([{ field: 'name', message: 'Name is required' }], corsHeaders);
}
```

---

## Future Enhancements

- **Request ID Tracking:** Generate unique `requestId` for error correlation in logs
- **Localization:** Support multi-language error messages
- **Error Analytics:** Track most common errors per endpoint
- **Client-Side Validation:** Mirror backend validation rules in frontend
- **Error Recovery:** Provide "Try Again" buttons in toast for transient errors
- **Structured Logging:** Log errors with full context (user, endpoint, payload)
