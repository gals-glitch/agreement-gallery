# Vantage IR API Integration - ETL Setup

## ✅ Completed

### 1. API Authentication Configured
- **Authentication Method**: Custom headers (NOT Basic Auth or Bearer)
  - `Authorization: buligodata` (raw token, no prefix)
  - `X-com-vantageir-subscriptions-clientid: bexz40aUdxK5rQDSjS2BIUg==`
- **Credentials stored** in `.env`:
  ```bash
  VANTAGE_API_BASE_URL="https://buligoirapi.insightportal.info"
  VANTAGE_AUTH_TOKEN="buligodata"
  VANTAGE_CLIENT_ID="bexz40aUdxK5rQDSjS2BIUg=="
  ```

### 2. TypeScript Client Library Created
- **File**: `supabase/functions/_shared/vantageClient.ts`
- **Features**:
  - Type-safe API wrapper
  - All major endpoints covered (Accounts, Funds, CashFlows, Commitments, Contacts, AccountContactMap)
  - Incremental sync support via `GetbyDate` endpoints
  - Pagination helper for fetching all pages
  - Proper error handling

### 3. Type Definitions Generated
- **File**: `supabase/functions/_shared/vantageTypes.ts`
- **Coverage**: All response types from Swagger spec
  - `VantageAccount` → Maps to `investors`
  - `VantageFund` → Maps to `funds`/`deals`
  - `VantageCashFlow` → Maps to `transactions`
  - `VantageCommitment` → Maps to `transactions`
  - `VantageContact` → Can map to `parties` or separate table
  - `VantageAccountContactMap` → Maps to relationships

### 4. API Connection Verified
**Test Results** (from `test_vantage_api_correct.ps1`):
- ✅ **290 funds** available
- ✅ **2,097 accounts/investors** available
- ✅ **137,862 cash flow transactions** available
- ✅ Incremental sync endpoints working
- ✅ Pagination working

## 📊 Available Data

| Vantage Resource | Count | Maps To Your System |
|-----------------|-------|-------------------|
| Funds | 290 | `funds` + `deals` tables |
| Accounts (Investors) | 2,097 | `investors` table |
| Cash Flows (Transactions) | 137,862 | `transactions` table |
| Contacts | Unknown | `parties` table (optional) |
| Commitments | Unknown | `transactions` (type=CONTRIBUTION) |

## 🔧 Important API Quirks

### 1. Date Format Requirements
- **MUST use** `yyyyMMdd` format (e.g., `20240101`)
- **DO NOT use** `yyyy-MM-dd` format (will return "Unauthorized Access" error)
- Example:
  ```typescript
  const startDate = new Date().toISOString().replace(/-/g, '').split('T')[0]; // "20250105"
  ```

### 2. Authentication Gotchas
- No "Basic" or "Bearer" prefix on Authorization header
- Both headers are required for every request
- Token appears base64-encoded but use it verbatim
- Some endpoints may have network issues (contacts endpoint had intermittent errors)

### 3. Pagination
- Default page size varies by endpoint
- Use `per_page=100` for efficient fetching
- Always check `page_context.has_more_page` to fetch all data

## 🚀 Next Steps: Build ETL Pipeline

### Phase 1: Sync Infrastructure (1-2 days)
1. Create sync state tracking table:
   ```sql
   CREATE TABLE vantage_sync_state (
     resource TEXT PRIMARY KEY,
     last_sync_time TIMESTAMPTZ,
     last_sync_status TEXT,
     records_synced INT,
     errors JSONB
   );
   ```

2. Create Edge Function: `supabase/functions/vantage-sync/index.ts`
   - Orchestrates sync for all resources
   - Supports both full and incremental sync
   - Error handling and retry logic
   - Logging and monitoring

3. Implement sync for each resource:
   - `syncAccounts()` → `investors`
   - `syncFunds()` → `funds` + `deals`
   - `syncCashFlows()` → `transactions`
   - `syncCommitments()` → `transactions`

### Phase 2: Data Mapping & Transformation (2-3 days)
1. Create mapping functions for each resource:
   ```typescript
   function mapVantageAccountToInvestor(account: VantageAccount): InvestorInsert {
     return {
       external_id: String(account.investor_id), // For idempotency
       name: account.investor_name,
       email: account.email || null,
       country: account.country || null,
       currency: account.currency || 'USD',
       is_active: !account.inactive,
       notes: account.notes || null,
       // ... map other fields
     };
   }
   ```

2. Implement upsert logic (idempotent):
   ```sql
   INSERT INTO investors (external_id, name, email, ...)
   VALUES ($1, $2, $3, ...)
   ON CONFLICT (external_id)
   DO UPDATE SET
     name = EXCLUDED.name,
     email = EXCLUDED.email,
     updated_at = now();
   ```

3. Handle transaction type mapping:
   ```typescript
   // CashFlow.transaction_type → our transaction_type
   'Contribution' | 'Paid In' → 'CONTRIBUTION'
   'Distribution' | 'Repurchase' → 'REPURCHASE'
   'Capital Call' → 'CONTRIBUTION'
   ```

### Phase 3: Scheduled Automation (1 day)
1. Set up Supabase Cron job:
   ```sql
   SELECT cron.schedule(
     'vantage-daily-sync',
     '0 2 * * *', -- 2 AM every day
     $$
     SELECT net.http_post(
       url := 'https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/vantage-sync',
       headers := '{"Authorization": "Bearer <service_role_key>"}'::jsonb,
       body := '{"mode": "incremental"}'::jsonb
     );
     $$
   );
   ```

2. Add manual trigger endpoint for on-demand sync
3. Implement webhook support (if Vantage provides)

### Phase 4: Monitoring & Alerts (1 day)
1. Add sync status dashboard in frontend
2. Email notifications for sync failures
3. Metrics:
   - Records synced per resource
   - Sync duration
   - Error rate
   - Data freshness (last successful sync time)

## 📝 Data Mapping Reference

### Account → Investor
| Vantage Field | Your Field | Transformation |
|--------------|-----------|---------------|
| `investor_id` | `external_id` | String cast |
| `investor_name` | `name` | Direct |
| `email` | `email` | Direct |
| `country` | `country` | Direct |
| `currency` | `currency` | Default to 'USD' if null |
| `inactive` | `is_active` | Invert boolean |
| `notes` | `notes` | Direct |
| `updated_time` | Sync metadata | Track for incremental |

### Fund → Fund/Deal
| Vantage Field | Your Field | Transformation |
|--------------|-----------|---------------|
| `fund_id` | `external_id` | String cast |
| `shortname` | `code` | Direct |
| `fundname` | `name` | Direct |
| `inception_date` | `inception_date` | Parse date |
| `currency` | `currency` | Direct |
| `strategy` | Metadata | Store in JSONB |
| `sector` | Metadata | Store in JSONB |

### CashFlow → Transaction
| Vantage Field | Your Field | Transformation |
|--------------|-----------|---------------|
| `cashflow_detailid` | `external_id` | String cast |
| `account_id` | `investor_id` | Lookup from external_id |
| `fund_id` | `fund_id` | Lookup from external_id |
| `transaction_date` | `transaction_date` | Parse date |
| `transaction_amount` | `amount` | Direct |
| `transaction_type` | `transaction_type` | Map to CONTRIBUTION/REPURCHASE |
| `comments` | `notes` | Direct |

## 🔒 Security Considerations
- Credentials stored in environment variables (not in code)
- Use Supabase service role key for sync operations
- Implement rate limiting to avoid overwhelming Vantage API
- Log all API calls for audit trail
- Never expose Vantage credentials to frontend

## 📚 Testing Strategy
1. Unit tests for mapping functions
2. Integration tests for sync logic (use test data)
3. Dry-run mode for testing without committing to database
4. Validation checks:
   - No duplicate records created
   - All required fields populated
   - Foreign key relationships maintained
   - Transaction totals reconcile

## ⚠️ Known Issues & Workarounds
1. **Contacts endpoint**: Intermittent network errors
   - Workaround: Implement retry logic with exponential backoff
2. **Date format**: Must be `yyyyMMdd`
   - Workaround: Helper function to format dates correctly
3. **Large datasets**: 137K+ transactions
   - Workaround: Use pagination and batch processing

## 📖 Resources
- Vantage Swagger UI: https://buligoirapi.insightportal.info/
- Test script: `test_vantage_api_correct.ps1`
- Client library: `supabase/functions/_shared/vantageClient.ts`
- Type definitions: `supabase/functions/_shared/vantageTypes.ts`

---

**Status**: ✅ Ready for Phase 1 implementation
**Last Updated**: 2025-11-05
**Tested By**: Claude Code with PowerShell test suite
