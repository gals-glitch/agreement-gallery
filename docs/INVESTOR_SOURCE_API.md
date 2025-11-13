# Investor Source Linker API Documentation

**Version:** 1.5.0
**Date:** 2025-10-19
**Tickets:** API-110, FE-101, FE-102, FE-103

## Overview

The Investor Source Linker feature tracks how investors were introduced to the fund, providing attribution to distributors or referrers. This is an **optional** feature that does not block investor creation or updates.

## Database Schema

### Enum: `investor_source_kind`
```sql
CREATE TYPE investor_source_kind AS ENUM ('DISTRIBUTOR', 'REFERRER', 'NONE');
```

### Table: `investors`
New columns added:
- `source_kind` (investor_source_kind, NOT NULL, default 'NONE')
- `introduced_by_party_id` (BIGINT, nullable, FK to parties.id)
- `source_linked_at` (TIMESTAMPTZ, nullable)

**Constraints:**
- If `introduced_by_party_id` is set, `source_kind` must be `DISTRIBUTOR` or `REFERRER` (not `NONE`)
- Trigger auto-sets `source_linked_at` when `introduced_by_party_id` is first populated

## API Endpoints

### GET /api-v1/investors

Fetch investors with optional source-based filtering.

**Query Parameters:**
| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `source_kind` | string | Filter by source type | `DISTRIBUTOR`, `REFERRER`, `NONE`, `ALL` (default: all) |
| `introduced_by_party_id` | UUID | Filter by introducing party | `550e8400-e29b-41d4-a716-446655440000` |
| `has_source` | boolean | Filter by source presence | `true` (has party), `false` (no party) |
| `limit` | integer | Page size (max 1000) | `50` (default) |
| `offset` | integer | Page offset | `0` (default) |

**Response:**
```json
{
  "items": [
    {
      "id": "uuid",
      "name": "John Smith LP",
      "email": "john@example.com",
      "source_kind": "DISTRIBUTOR",
      "introduced_by_party_id": "party-uuid",
      "source_linked_at": "2025-10-19T10:00:00Z",
      "introduced_by_party": {
        "id": "party-uuid",
        "name": "Acme Capital Partners",
        "party_type": "distributor"
      },
      ...
    }
  ],
  "total": 120
}
```

**Example Requests:**
```bash
# Get all distributors
GET /api-v1/investors?source_kind=DISTRIBUTOR

# Get investors introduced by specific party
GET /api-v1/investors?introduced_by_party_id=550e8400-e29b-41d4-a716-446655440000

# Get investors with no source attribution
GET /api-v1/investors?has_source=false

# Combined filters
GET /api-v1/investors?source_kind=REFERRER&has_source=true&limit=100
```

---

### GET /api-v1/investors/:id

Fetch a single investor with joined party data.

**Response:**
```json
{
  "id": "uuid",
  "name": "John Smith LP",
  "source_kind": "DISTRIBUTOR",
  "introduced_by_party_id": "party-uuid",
  "source_linked_at": "2025-10-19T10:00:00Z",
  "introduced_by_party": {
    "id": "party-uuid",
    "name": "Acme Capital Partners",
    "party_type": "distributor"
  },
  ...
}
```

---

### POST /api-v1/investors

Create a new investor with optional source attribution.

**Request Body:**
```json
{
  "name": "Jane Doe LP",
  "party_entity_id": "entity-uuid",
  "email": "jane@example.com",
  "source_kind": "REFERRER",
  "introduced_by_party_id": "party-uuid"
}
```

**Validation Rules:**
- `source_kind` defaults to `NONE` if not provided
- `introduced_by_party_id` can be `null` for any `source_kind`
- If `introduced_by_party_id` is set, `source_kind` must not be `NONE`
- If `introduced_by_party_id` is set, party must exist in `parties` table

**Success Response (201):**
```json
{
  "id": "new-investor-uuid"
}
```

**Error Response (422):**
```json
{
  "code": "VALIDATION_ERROR",
  "message": "source_kind cannot be NONE when introduced_by_party_id is set",
  "details": [
    {
      "field": "source_kind",
      "message": "source_kind cannot be NONE when introduced_by_party_id is set",
      "value": "NONE"
    }
  ],
  "timestamp": "2025-10-19T10:00:00Z"
}
```

---

### PATCH /api-v1/investors/:id

Update an existing investor, including source fields.

**Request Body (partial update):**
```json
{
  "source_kind": "DISTRIBUTOR",
  "introduced_by_party_id": "party-uuid"
}
```

**Special Behaviors:**
- If `source_kind` is changed to `NONE`, `introduced_by_party_id` is automatically cleared
- If `introduced_by_party_id` is set for the first time, `source_linked_at` is auto-populated via trigger
- All source fields are optional—omitted fields are not updated

**Success Response (200):**
```json
{
  "ok": true
}
```

**Error Response (422) - Invalid Party:**
```json
{
  "code": "VALIDATION_ERROR",
  "message": "Invalid party ID - party not found",
  "details": [
    {
      "field": "introduced_by_party_id",
      "message": "Invalid party ID - party not found",
      "value": "invalid-uuid"
    }
  ],
  "timestamp": "2025-10-19T10:00:00Z"
}
```

---

### POST /api-v1/investors/source-import

Bulk backfill investor source data from CSV.

**Request Body:**
```json
[
  {
    "investor_external_id": "INV001",
    "source_kind": "DISTRIBUTOR",
    "party_name": "Acme Capital Partners"
  },
  {
    "investor_external_id": "INV002",
    "source_kind": "REFERRER",
    "party_name": "John Smith"
  },
  {
    "investor_external_id": "INV003",
    "source_kind": "NONE"
  }
]
```

**Field Definitions:**
- `investor_external_id` (string, required): Investor name (used for lookup)
- `source_kind` (string, required): Must be `DISTRIBUTOR`, `REFERRER`, or `NONE`
- `party_name` (string, optional): Party name (case-insensitive lookup)

**Success Response (200):**
```json
{
  "success_count": 2,
  "errors": [
    {
      "row": 3,
      "field": "party_name",
      "message": "Party not found: Unknown Party",
      "value": "Unknown Party"
    }
  ]
}
```

**Validation:**
- Each row is validated independently
- Invalid rows are skipped (not imported)
- Valid rows are imported even if some rows fail
- Party lookup is case-insensitive and trims whitespace

**Error Types:**
- `investor_external_id` not found: Investor doesn't exist in database
- `source_kind` invalid: Must be one of the enum values
- `party_name` not found: Party doesn't exist in database (only if provided)

---

## Error Contract

All endpoints follow the standardized error contract:

```typescript
interface ApiError {
  code: string;              // e.g., "VALIDATION_ERROR", "NOT_FOUND"
  message: string;           // Human-readable summary
  details?: ApiErrorDetail[]; // Field-level or row-level errors
  timestamp: string;         // ISO 8601 timestamp
}

interface ApiErrorDetail {
  field?: string;      // Field name (e.g., 'introduced_by_party_id')
  row?: number;        // Row number for CSV operations (1-indexed)
  value?: any;         // Invalid value provided
  constraint?: string; // Constraint name (e.g., 'investors_source_consistency_ck')
  message?: string;    // Human-readable error message
}
```

**HTTP Status Codes:**
- `200` OK - Success
- `201` Created - Resource created
- `400` Bad Request - Generic client error
- `401` Unauthorized - Missing or invalid auth token
- `403` Forbidden - Insufficient permissions
- `404` Not Found - Resource not found
- `422` Unprocessable Entity - Validation error
- `500` Internal Server Error - Server error

---

## Frontend Components

### SourceBadge
Displays color-coded badge for investor source type.

**Usage:**
```tsx
import { SourceBadge } from '@/components/investors/SourceBadge';

<SourceBadge sourceKind="DISTRIBUTOR" />
```

**Variants:**
- `DISTRIBUTOR`: Blue badge with Building icon
- `REFERRER`: Green badge with User icon
- `NONE`: Gray badge with Minus icon

---

### InvestorSourceSection
Form section for editing investor source attribution.

**Usage:**
```tsx
import { InvestorSourceSection } from '@/components/investors/InvestorSourceSection';

<InvestorSourceSection
  value={{
    source_kind: 'DISTRIBUTOR',
    introduced_by_party_id: 'party-uuid'
  }}
  onChange={(value) => setSourceData(value)}
  disabled={false}
/>
```

**Features:**
- Source type selector (DISTRIBUTOR / REFERRER / NONE)
- Party selector (filtered by active parties)
- Auto-clears party when source_kind is set to NONE
- Info alert when source_kind is NONE
- Help text explaining source types

---

### InvestorSourceCSVImport
Modal dialog for bulk CSV import.

**Usage:**
```tsx
import { InvestorSourceCSVImport } from '@/components/investors/InvestorSourceCSVImport';

<InvestorSourceCSVImport
  open={isImportModalOpen}
  onOpenChange={setIsImportModalOpen}
/>
```

**Features:**
- CSV file upload
- Client-side preview and validation
- Row-level error display
- Batch import with progress indicator
- Summary of success/error counts

---

## Testing

See [INVESTOR_SOURCE_TESTING.md](./INVESTOR_SOURCE_TESTING.md) for:
- Manual testing steps
- cURL examples
- Integration test scenarios
- CSV import test cases

---

## Migration Notes

- All existing investors have `source_kind='NONE'` and `introduced_by_party_id=NULL`
- Migration is fully backward compatible—no data loss
- Indexes created for efficient querying:
  - `idx_investors_source_kind` (on `source_kind`)
  - `idx_investors_introduced_by` (partial, on `introduced_by_party_id`)
  - `idx_investors_source_composite` (on `source_kind, introduced_by_party_id`)

---

## Known Limitations

1. **External ID Lookup**: CSV import uses investor `name` field for lookup (not a dedicated external_id column)
2. **Party Name Matching**: Case-insensitive exact match only (no fuzzy matching)
3. **No Bulk Edit UI**: Must use CSV import for bulk updates (no multi-select edit in UI)
4. **No History Tracking**: Changing source attribution does not create an audit trail (only `updated_at` timestamp)

---

## Future Enhancements

- Add external_id field to investors table for more robust CSV matching
- Implement fuzzy party name matching with confirmation UI
- Add bulk edit action in investors list view
- Track source attribution history in separate audit table
- Add source attribution analytics dashboard
- Export investors with source data to Excel

---

## Support

For questions or issues:
- Slack: #investor-source-linker
- Email: engineering@buligocapital.com
- Jira: Project BCFMS, Component "Investor Management"
