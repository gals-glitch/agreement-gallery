# Contributions API - Implementation Summary

**Status:** ✅ COMPLETE
**Date:** 2025-10-16
**API Version:** 1.0.0

---

## 🎯 Overview

Added comprehensive `/contributions` endpoints to the API V1 Edge Function with strict XOR validation (exactly one of `deal_id` or `fund_id` required).

**Key Features:**
- ✅ Single contribution creation with validation
- ✅ Batch contribution import with pre-validation
- ✅ Query with multiple filters (fund, deal, investor, date range, batch)
- ✅ Two-layer XOR enforcement (API + Database)
- ✅ Friendly 422 errors for validation failures
- ✅ PostgreSQL error mapping to HTTP status codes
- ✅ Comprehensive OpenAPI documentation

---

## 📋 What Was Implemented

### **1. Edge Function Handlers** (`supabase/functions/api-v1/index.ts`)

#### Helper Functions Added:
- `isXor(a, b)` - XOR logic check
- `mapPgErrorToHttp(err)` - Maps PostgreSQL errors to HTTP status codes
- `validateContributionPayload(p)` - Pre-validates contribution data

#### Endpoints:
- `GET /contributions` - List with filters
- `POST /contributions` - Create single contribution
- `POST /contributions/batch` - Batch import

### **2. Database Constraints** (`supabase/migrations/20251016000002_redesign_02_contributions.sql`)

Added explicit CHECK constraints:
```sql
-- XOR constraint (already existed, documented)
contributions_one_scope_ck: (deal_id XOR fund_id)

-- Additional safety constraints (new)
contributions_amount_pos_ck: amount > 0
contributions_paid_in_date_ck: paid_in_date IS NOT NULL
```

### **3. OpenAPI Documentation** (`docs/openapi.yaml`)

Added:
- `Contribution` schema
- `CreateContributionRequest` schema
- `/contributions` GET/POST endpoints with examples
- `/contributions/batch` POST endpoint with examples
- Error response schemas with validation examples

---

## 🚀 API Usage

### **Base URL:**
```
Production: https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1
Local Dev:  http://localhost:54321/functions/v1/api-v1
```

### **Authentication:**
All endpoints require Bearer token:
```bash
Authorization: Bearer <your-supabase-jwt-token>
```

---

## 📡 Endpoints

### **1. GET /contributions** - List Contributions

**Query Parameters:**
- `fund_id` - Filter by fund ID
- `deal_id` - Filter by deal ID
- `investor_id` - Filter by investor ID
- `from` - Filter by `paid_in_date >= from` (YYYY-MM-DD)
- `to` - Filter by `paid_in_date <= to` (YYYY-MM-DD)
- `batch` - Filter by source_batch identifier

**Example:**
```bash
GET /contributions?fund_id=5&from=2025-01-01&to=2025-12-31
```

**Response (200):**
```json
{
  "items": [
    {
      "id": 123,
      "investor_id": 1,
      "fund_id": 5,
      "deal_id": null,
      "paid_in_date": "2025-07-15",
      "amount": 250000,
      "currency": "USD",
      "fx_rate": null,
      "source_batch": "2025Q3",
      "created_at": "2025-10-16T12:00:00Z"
    }
  ],
  "total": 1
}
```

---

### **2. POST /contributions** - Create Single Contribution

**Request Body:**
```json
{
  "investor_id": 1,
  "deal_id": 10,
  "paid_in_date": "2025-07-15",
  "amount": 250000,
  "currency": "USD",
  "source_batch": "2025Q3"
}
```

**XOR Rule:** Exactly one of `deal_id` or `fund_id` must be set.

**Response (201):**
```json
{
  "id": 123
}
```

**Error (422) - XOR Violation:**
```json
{
  "error": "VALIDATION",
  "details": [
    "Exactly one of deal_id or fund_id is required."
  ]
}
```

---

### **3. POST /contributions/batch** - Batch Import

**Request Body:**
```json
[
  {
    "investor_id": 1,
    "deal_id": 10,
    "paid_in_date": "2025-07-15",
    "amount": 250000,
    "currency": "USD",
    "source_batch": "2025Q3"
  },
  {
    "investor_id": 2,
    "fund_id": 5,
    "paid_in_date": "2025-07-20",
    "amount": 150000,
    "currency": "USD",
    "source_batch": "2025Q3"
  }
]
```

**Response (201):**
```json
{
  "inserted": [123, 124]
}
```

**Error (422) - Validation Failure:**
```json
{
  "error": "VALIDATION",
  "details": [
    {
      "index": 0,
      "errors": ["Exactly one of deal_id or fund_id is required."]
    },
    {
      "index": 2,
      "errors": ["amount must be a positive number."]
    }
  ]
}
```

**Note:** Pre-validation ensures all rows are validated before insertion. If any row fails, the entire batch is rejected (no partial inserts).

---

## 🧪 Test Scenarios

### **Scenario 1: Valid Deal Contribution** ✅
```bash
POST /contributions
{
  "investor_id": 1,
  "deal_id": 10,
  "paid_in_date": "2025-07-15",
  "amount": 250000,
  "currency": "USD"
}
```
**Expected:** 201 Created

---

### **Scenario 2: Valid Fund Contribution** ✅
```bash
POST /contributions
{
  "investor_id": 1,
  "fund_id": 5,
  "paid_in_date": "2025-08-01",
  "amount": 100000
}
```
**Expected:** 201 Created

---

### **Scenario 3: Both deal_id and fund_id Set** ❌
```bash
POST /contributions
{
  "investor_id": 1,
  "deal_id": 10,
  "fund_id": 5,
  "paid_in_date": "2025-07-15",
  "amount": 1000
}
```
**Expected:** 422 Validation Error
```json
{
  "error": "VALIDATION",
  "details": ["Exactly one of deal_id or fund_id is required."]
}
```

---

### **Scenario 4: Neither deal_id nor fund_id Set** ❌
```bash
POST /contributions
{
  "investor_id": 1,
  "paid_in_date": "2025-07-15",
  "amount": 1000
}
```
**Expected:** 422 Validation Error
```json
{
  "error": "VALIDATION",
  "details": ["Exactly one of deal_id or fund_id is required."]
}
```

---

### **Scenario 5: Negative Amount** ❌
```bash
POST /contributions
{
  "investor_id": 1,
  "deal_id": 10,
  "paid_in_date": "2025-07-15",
  "amount": -1000
}
```
**Expected:** 422 Validation Error
```json
{
  "error": "VALIDATION",
  "details": ["amount must be a positive number."]
}
```

---

### **Scenario 6: Missing Required Fields** ❌
```bash
POST /contributions
{
  "investor_id": 1,
  "deal_id": 10
}
```
**Expected:** 422 Validation Error
```json
{
  "error": "VALIDATION",
  "details": [
    "paid_in_date is required (YYYY-MM-DD).",
    "amount must be a positive number."
  ]
}
```

---

## 🔒 Two-Layer Validation

### **Layer 1: API Validation** (Friendly)
- Validates before database insert
- Returns 422 with human-readable error messages
- Catches common mistakes early

### **Layer 2: Database Constraints** (Safety Net)
- PostgreSQL CHECK constraints enforce rules at DB level
- Prevents invalid data even if API validation is bypassed
- Returns 422 with constraint violation details

**Example Flow:**
```
1. User sends: { deal_id: 10, fund_id: 5, ... }
2. API validates: isXor(deal_id, fund_id) → false
3. API returns 422: "Exactly one of deal_id or fund_id is required."
4. (If API bypassed) DB rejects: contributions_one_scope_ck violation
5. API maps PG error to 422: "CHECK_VIOLATION"
```

---

## 📊 PostgreSQL Error Mapping

| PG Code | Constraint Type | HTTP Status | API Error |
|---------|----------------|-------------|-----------|
| 23514   | CHECK violation | 422         | CHECK_VIOLATION |
| 23502   | NOT NULL violation | 422         | NOT_NULL |
| 23503   | Foreign key violation | 422         | FOREIGN_KEY |
| 23505   | Unique violation | 409         | UNIQUE |
| Other   | Generic error | 400         | BAD_REQUEST |

---

## 🎁 Additional Features

### **Multi-Currency Support:**
```json
{
  "amount": 300000,
  "currency": "EUR",
  "fx_rate": 1.1
}
```

### **Batch Tracking:**
```json
{
  "source_batch": "2025Q3_import_001"
}
```
Query later: `GET /contributions?batch=2025Q3_import_001`

### **Date Range Filtering:**
```
GET /contributions?from=2025-01-01&to=2025-12-31
```

---

## 🎨 Frontend Implementation (v1.2.0)

### **Global HTTP Wrapper**
**File:** `src/api/http.ts` (170 lines)

Centralized HTTP client with:
- Automatic Bearer token injection
- Error handling with toast notifications
- HTTP status code mapping
- Type-safe responses

**Usage Example:**
```typescript
import { http } from '@/api/http';

// GET request
const data = await http.get<MyType>('/endpoint');

// POST request
const result = await http.post('/endpoint', { field: 'value' });

// PATCH request
await http.patch('/endpoint/:id', { field: 'updated' });

// DELETE request
await http.delete('/endpoint/:id');
```

### **Contributions API Client**
**File:** `src/api/contributions.ts` (140 lines)

Type-safe client with validation:
```typescript
import { contributionsAPI } from '@/api/contributions';

// List contributions
const response = await contributionsAPI.list({
  fund_id: 5,
  from: '2025-01-01',
  to: '2025-12-31'
});

// Create single contribution
await contributionsAPI.create({
  investor_id: 1,
  deal_id: 10,
  paid_in_date: '2025-07-15',
  amount: 250000,
  currency: 'USD'
});

// Batch import with pre-validation
const batchData = [
  { investor_id: 1, deal_id: 10, ... },
  { investor_id: 2, fund_id: 5, ... }
];

const result = await contributionsAPI.batchImport(batchData);
// Returns: { inserted: [123, 124] }
```

### **Contributions Page**
**File:** `src/pages/Contributions.tsx` (430 lines)

Full-featured UI with:
- List view with 6 filters (fund, deal, investor, date range, batch)
- CSV import drawer with template download
- Client-side validation with per-row errors
- Summary card with totals
- Responsive table with currency formatting

**CSV Template:**
```csv
investor_id,deal_id,fund_id,paid_in_date,amount,currency,source_batch
1,10,,2025-07-15,250000,USD,2025Q3
2,,5,2025-07-20,150000,USD,2025Q3
```

### **Enhanced Deals Page**
**File:** `src/pages/Deals.tsx` (Modified)

Now includes:
- API integration via `dealsAPI`
- GP exclusion toggle (`exclude_gp_from_commission`)
- Scoreboard read-only fields (`equity_to_raise`, `raised_so_far`)
- Currency formatting with `Intl.NumberFormat`
- TrendingUp icons for financial data

## 📝 Files Modified

| File | Changes | Lines |
|------|---------|-------|
| **Backend** | | |
| `supabase/functions/api-v1/index.ts` | Added contributions handlers + helpers | +135 |
| `supabase/migrations/20251016000002_redesign_02_contributions.sql` | Added explicit CHECK constraints | +22 |
| `docs/openapi.yaml` | Added schemas + endpoints | +186 |
| **Frontend (v1.2.0)** | | |
| `src/api/http.ts` | Global HTTP wrapper | +170 |
| `src/api/contributions.ts` | Contributions API client | +140 |
| `src/pages/Contributions.tsx` | Contributions page with CSV import | +430 |
| `src/pages/Deals.tsx` | Enhanced with API integration | ~300 |
| `src/api/clientV2.ts` | Migrated all 6 API modules | ~100 |
| `src/App.tsx` | Added contributions route | +2 |
| `src/components/AppSidebar.tsx` | Added contributions menu item | +6 |
| **Documentation** | | |
| `docs/CONTRIBUTIONS-API.md` | This documentation | +600 |
| `docs/SESSION-2025-10-16.md` | Day 3 session summary | +828 |

**Total:** ~2,900+ lines added/modified

---

## ✅ Checklist

- [x] XOR validation at API layer
- [x] XOR validation at DB layer (CHECK constraint)
- [x] Single contribution endpoint
- [x] Batch import endpoint
- [x] Query with filters (fund, deal, investor, date, batch)
- [x] PostgreSQL error mapping
- [x] OpenAPI documentation with examples
- [x] Error response schemas
- [x] Test scenarios documented

---

## 🚀 Next Steps

### **For Testing:**
1. Deploy Edge Function: `supabase functions deploy api-v1`
2. Run migration: `supabase db push` (if not already applied)
3. Test with Postman/curl using examples above
4. Verify 422 errors for XOR violations

### **For Production:**
1. Ensure migration is applied to production database
2. Update environment variables if needed
3. Test batch import with real data
4. Monitor error logs for validation failures

---

## 📞 Support

**Documentation:**
- OpenAPI Spec: `docs/openapi.yaml`
- Database Schema: `supabase/migrations/20251016000002_redesign_02_contributions.sql`
- Edge Function: `supabase/functions/api-v1/index.ts`

**Common Issues:**
- **422 on valid data:** Check database constraints, verify FK references exist
- **401 Unauthorized:** Ensure Bearer token is valid
- **400 on batch:** Check JSON array format, ensure all required fields present

---

_Implementation completed: 2025-10-16_
_Version: 1.0_
_Status: Ready for deployment_
