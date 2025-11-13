# Vantage ETL Sync State - Database Documentation

**Migration:** `20251105132840_vantage_sync_state.sql`
**Ticket:** ETL-001
**Date:** 2025-11-05

---

## Table of Contents

1. [Schema Overview](#schema-overview)
2. [Table Structure](#table-structure)
3. [Indexes and Performance](#indexes-and-performance)
4. [Sample Queries with EXPLAIN](#sample-queries-with-explain)
5. [Helper Functions](#helper-functions)
6. [Usage Patterns](#usage-patterns)
7. [RLS Policies](#rls-policies)
8. [Monitoring and Alerts](#monitoring-and-alerts)

---

## Schema Overview

The `vantage_sync_state` table tracks ETL synchronization operations for Vantage API resources. It provides:

- **Single source of truth** for sync state per resource type
- **Incremental sync support** via `last_sync_time` timestamp
- **Progress tracking** with separate `started_at` / `completed_at` timestamps
- **Error logging** with flexible JSONB structure
- **Performance monitoring** via `duration_ms` metric

### Entity Relationship

```
vantage_sync_state (standalone table)
├── resource (PK) → 'accounts', 'funds', 'cashflows', etc.
├── Tracks state for external Vantage API resources
└── No foreign keys (intentionally decoupled from domain tables)
```

**Design Decision:** This table is intentionally isolated from domain tables (accounts, funds, etc.) to avoid circular dependencies and allow independent evolution of sync infrastructure.

---

## Table Structure

### Column Definitions

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `resource` | TEXT | NOT NULL | - | Primary key: resource type being synced |
| `last_sync_time` | TIMESTAMPTZ | NULL | - | Last successful sync timestamp (for incremental) |
| `last_sync_status` | TEXT | NOT NULL | 'never_run' | Current status: never_run, running, success, failed |
| `records_synced` | INT | NOT NULL | 0 | Total records processed in last sync |
| `records_created` | INT | NOT NULL | 0 | New records created in last sync |
| `records_updated` | INT | NOT NULL | 0 | Existing records updated in last sync |
| `errors` | JSONB | NOT NULL | '[]' | Array of error objects from last sync |
| `started_at` | TIMESTAMPTZ | NULL | - | When current/last sync started |
| `completed_at` | TIMESTAMPTZ | NULL | - | When sync completed (NULL if running) |
| `duration_ms` | INT | NULL | - | Sync duration in milliseconds (auto-calculated) |
| `created_at` | TIMESTAMPTZ | NOT NULL | now() | Row creation timestamp |
| `updated_at` | TIMESTAMPTZ | NOT NULL | now() | Row update timestamp (auto-updated) |

### Constraints

1. **CHECK: `last_sync_status`**
   Valid values: 'success', 'failed', 'running', 'never_run'

2. **CHECK: `records_synced >= 0`**
   Prevents negative record counts

3. **CHECK: `records_created >= 0`**
   Prevents negative creation counts

4. **CHECK: `records_updated >= 0`**
   Prevents negative update counts

5. **CHECK: `duration_ms >= 0`**
   Prevents negative durations

6. **CHECK: `valid_sync_timerange`**
   Ensures `completed_at >= started_at` when both are set

7. **CHECK: `running_incomplete`**
   If status is 'running', `completed_at` must be NULL

8. **CHECK: `errors_is_array`**
   Ensures `errors` column contains valid JSON array

### Seeded Resources

The migration pre-populates rows for common Vantage resources:

- `accounts` - Vantage account entities
- `funds` - Fund structures
- `cashflows` - Cash movement transactions
- `commitments` - Investment commitments
- `investors` - Investor entities
- `investments` - Investment positions
- `valuations` - Asset valuations

---

## Indexes and Performance

### Index Strategy

#### 1. `idx_vantage_sync_status` (Partial Index)
```sql
CREATE INDEX idx_vantage_sync_status
  ON vantage_sync_state(last_sync_status)
  WHERE last_sync_status != 'success';
```

**Purpose:** Find failed or running syncs
**Selectivity:** High (partial index excludes successful syncs)
**Use Cases:**
- Dashboard showing current failures
- Monitoring alerts for stuck syncs
- Admin troubleshooting

**Why Partial?** Most syncs succeed. Indexing only failures saves 70-80% of index space.

#### 2. `idx_vantage_sync_last_time` (Descending)
```sql
CREATE INDEX idx_vantage_sync_last_time
  ON vantage_sync_state(last_sync_time DESC NULLS LAST);
```

**Purpose:** Find stale syncs (oldest last_sync_time)
**Selectivity:** Medium (7 rows typically)
**Use Cases:**
- Alert on syncs that haven't run in 24+ hours
- Dashboard showing "last synced" timestamps
- Scheduling next sync batch

**Why DESC NULLS LAST?** Most recent syncs are queried most often. NULL values (never synced) sorted to end.

#### 3. `idx_vantage_sync_duration` (Partial Index)
```sql
CREATE INDEX idx_vantage_sync_duration
  ON vantage_sync_state(duration_ms DESC)
  WHERE duration_ms IS NOT NULL;
```

**Purpose:** Identify slow syncs for performance monitoring
**Selectivity:** High (excludes running syncs)
**Use Cases:**
- Performance dashboard showing slowest syncs
- Alert on syncs exceeding SLA (e.g., > 5 minutes)
- Capacity planning

---

## Sample Queries with EXPLAIN

### Query 1: Get Current Status for All Resources

```sql
SELECT
  resource,
  last_sync_status AS status,
  last_sync_time,
  records_synced,
  duration_ms,
  CASE
    WHEN last_sync_status = 'running' THEN
      EXTRACT(EPOCH FROM (now() - started_at))::INT
    ELSE NULL
  END AS running_seconds
FROM vantage_sync_state
ORDER BY
  CASE last_sync_status
    WHEN 'failed' THEN 1
    WHEN 'running' THEN 2
    WHEN 'never_run' THEN 3
    WHEN 'success' THEN 4
  END,
  resource;
```

**Expected EXPLAIN Output:**
```
Sort  (cost=1.18..1.20 rows=7 width=72)
  Sort Key: (CASE ... END), resource
  ->  Seq Scan on vantage_sync_state  (cost=0.00..1.09 rows=7 width=72)
```

**Estimated Rows:** 7 (all resources)
**Cost:** Very low (< 2.0) - sequential scan is optimal for small tables
**Index Usage:** None needed - table is small enough for seq scan

---

### Query 2: Find Failed Syncs with Errors

```sql
SELECT
  resource,
  last_sync_status,
  completed_at,
  duration_ms,
  jsonb_array_length(errors) AS error_count,
  errors
FROM vantage_sync_state
WHERE last_sync_status = 'failed'
ORDER BY completed_at DESC;
```

**Expected EXPLAIN Output:**
```
Sort  (cost=1.16..1.16 rows=1 width=72)
  Sort Key: completed_at DESC
  ->  Index Scan using idx_vantage_sync_status on vantage_sync_state
      (cost=0.13..1.15 rows=1 width=72)
        Index Cond: (last_sync_status = 'failed'::text)
```

**Estimated Rows:** 0-2 (typically few failures)
**Cost:** ~1.2
**Index Usage:** `idx_vantage_sync_status` (partial index)
**Performance:** Index seek + sort is optimal for filtered query

---

### Query 3: Check for Stale Syncs (Last Sync > 24 Hours Ago)

```sql
SELECT
  resource,
  last_sync_time,
  last_sync_status,
  EXTRACT(EPOCH FROM (now() - last_sync_time))/3600 AS hours_since_sync
FROM vantage_sync_state
WHERE
  last_sync_time IS NOT NULL
  AND last_sync_time < now() - INTERVAL '24 hours'
ORDER BY last_sync_time ASC;
```

**Expected EXPLAIN Output:**
```
Sort  (cost=1.15..1.16 rows=1 width=48)
  Sort Key: last_sync_time
  ->  Seq Scan on vantage_sync_state  (cost=0.00..1.14 rows=1 width=48)
        Filter: ((last_sync_time IS NOT NULL)
                 AND (last_sync_time < (now() - '24:00:00'::interval)))
```

**Estimated Rows:** 0-3 (depends on sync schedule)
**Cost:** ~1.2
**Index Usage:** `idx_vantage_sync_last_time` considered but seq scan chosen (small table)
**Note:** Could use index scan if table grows, but seq scan is optimal for 7 rows

---

### Query 4: Get Incremental Sync Timestamp for Resource

```sql
SELECT last_sync_time
FROM vantage_sync_state
WHERE resource = 'accounts';
```

**Expected EXPLAIN Output:**
```
Index Scan using vantage_sync_state_pkey on vantage_sync_state
  (cost=0.13..8.15 rows=1 width=8)
  Index Cond: (resource = 'accounts'::text)
```

**Estimated Rows:** 1 (exactly one match)
**Cost:** ~8.2
**Index Usage:** Primary key index (implicit B-tree on `resource`)
**Performance:** Single-row lookup via PK - optimal

---

### Query 5: Monitor Performance - Slowest Syncs

```sql
SELECT
  resource,
  duration_ms,
  ROUND(duration_ms / 1000.0, 2) AS duration_seconds,
  records_synced,
  ROUND(records_synced::NUMERIC / NULLIF(duration_ms, 0) * 1000, 2) AS records_per_second,
  completed_at
FROM vantage_sync_state
WHERE duration_ms IS NOT NULL
ORDER BY duration_ms DESC
LIMIT 5;
```

**Expected EXPLAIN Output:**
```
Limit  (cost=1.15..1.15 rows=5 width=56)
  ->  Sort  (cost=1.15..1.17 rows=6 width=56)
        Sort Key: duration_ms DESC
        ->  Index Scan using idx_vantage_sync_duration on vantage_sync_state
            (cost=0.13..1.11 rows=6 width=56)
              Index Cond: (duration_ms IS NOT NULL)
```

**Estimated Rows:** 5 (LIMIT)
**Cost:** ~1.2
**Index Usage:** `idx_vantage_sync_duration` (DESC partial index)
**Performance:** Index provides pre-sorted data - very efficient

---

### Query 6: Aggregate Sync Statistics

```sql
SELECT
  COUNT(*) AS total_resources,
  COUNT(*) FILTER (WHERE last_sync_status = 'success') AS successful,
  COUNT(*) FILTER (WHERE last_sync_status = 'failed') AS failed,
  COUNT(*) FILTER (WHERE last_sync_status = 'running') AS running,
  COUNT(*) FILTER (WHERE last_sync_status = 'never_run') AS never_run,
  SUM(records_synced) AS total_records_synced,
  AVG(duration_ms) FILTER (WHERE duration_ms IS NOT NULL) AS avg_duration_ms,
  MAX(duration_ms) AS max_duration_ms
FROM vantage_sync_state;
```

**Expected EXPLAIN Output:**
```
Aggregate  (cost=1.12..1.13 rows=1 width=96)
  ->  Seq Scan on vantage_sync_state  (cost=0.00..1.07 rows=7 width=12)
```

**Estimated Rows:** 1 (aggregate result)
**Cost:** ~1.2
**Index Usage:** None (aggregate requires full scan)
**Performance:** Seq scan optimal for aggregating all rows

---

## Helper Functions

### 1. `start_vantage_sync(resource TEXT)`

Marks a sync as started (status = 'running').

```sql
SELECT start_vantage_sync('accounts');
```

**Effect:**
- Sets `last_sync_status = 'running'`
- Sets `started_at = now()`
- Clears `completed_at` and `duration_ms`
- Creates row if doesn't exist (upsert)

**Use Case:** Call at the beginning of ETL process

---

### 2. `complete_vantage_sync(resource, records_synced, records_created, records_updated)`

Marks a sync as successfully completed.

```sql
SELECT complete_vantage_sync('accounts', 150, 10, 140);
```

**Effect:**
- Sets `last_sync_status = 'success'`
- Updates `last_sync_time = now()`
- Records metrics: `records_synced`, `records_created`, `records_updated`
- Sets `completed_at = now()`
- Clears `errors = []`
- Auto-calculates `duration_ms` via trigger

**Use Case:** Call after successful ETL completion

---

### 3. `fail_vantage_sync(resource, errors JSONB)`

Marks a sync as failed with error details.

```sql
SELECT fail_vantage_sync(
  'accounts',
  '[
    {"code": "API_TIMEOUT", "message": "Vantage API request timed out after 30s", "timestamp": "2025-11-05T10:30:00Z"},
    {"code": "PARSE_ERROR", "message": "Invalid JSON in record ID 12345", "record_id": "12345"}
  ]'::jsonb
);
```

**Effect:**
- Sets `last_sync_status = 'failed'`
- Sets `completed_at = now()`
- Stores `errors` array
- Does NOT update `last_sync_time` (failed sync shouldn't advance watermark)
- Auto-calculates `duration_ms` via trigger

**Use Case:** Call in catch block when ETL encounters errors

---

## Usage Patterns

### ETL Process Flow

```typescript
// 1. Start sync
await supabase.rpc('start_vantage_sync', { p_resource: 'accounts' });

try {
  // 2. Get last sync time for incremental sync
  const { data } = await supabase
    .from('vantage_sync_state')
    .select('last_sync_time')
    .eq('resource', 'accounts')
    .single();

  const lastSyncTime = data?.last_sync_time;

  // 3. Fetch from Vantage API (incremental if lastSyncTime exists)
  const vantageData = await fetchVantageAccounts({
    modifiedSince: lastSyncTime
  });

  // 4. Upsert to database
  let created = 0, updated = 0;
  for (const record of vantageData) {
    const result = await upsertAccount(record);
    if (result.isNew) created++;
    else updated++;
  }

  // 5. Mark as complete
  await supabase.rpc('complete_vantage_sync', {
    p_resource: 'accounts',
    p_records_synced: vantageData.length,
    p_records_created: created,
    p_records_updated: updated
  });

} catch (error) {
  // 6. Mark as failed with errors
  await supabase.rpc('fail_vantage_sync', {
    p_resource: 'accounts',
    p_errors: [{
      code: error.code || 'UNKNOWN_ERROR',
      message: error.message,
      timestamp: new Date().toISOString()
    }]
  });
  throw error;
}
```

---

### Monitoring Dashboard Query

```sql
-- Get dashboard overview
WITH sync_health AS (
  SELECT
    resource,
    last_sync_status,
    last_sync_time,
    EXTRACT(EPOCH FROM (now() - last_sync_time))/3600 AS hours_since_sync,
    duration_ms,
    records_synced,
    jsonb_array_length(errors) AS error_count,
    CASE
      WHEN last_sync_status = 'failed' THEN 'red'
      WHEN last_sync_status = 'running' AND started_at < now() - INTERVAL '30 minutes' THEN 'red'
      WHEN last_sync_time < now() - INTERVAL '24 hours' THEN 'yellow'
      WHEN last_sync_status = 'never_run' THEN 'yellow'
      ELSE 'green'
    END AS health_indicator
  FROM vantage_sync_state
)
SELECT * FROM sync_health
ORDER BY
  CASE health_indicator
    WHEN 'red' THEN 1
    WHEN 'yellow' THEN 2
    WHEN 'green' THEN 3
  END,
  resource;
```

---

## RLS Policies

### Authenticated Users (Read-Only)

```sql
-- Policy: vantage_sync_state_select_all
-- Allows: All authenticated users
-- Actions: SELECT
-- Purpose: Frontend can display sync status in UI
```

Example frontend query:
```typescript
const { data: syncState } = await supabase
  .from('vantage_sync_state')
  .select('resource, last_sync_status, last_sync_time, duration_ms')
  .eq('resource', 'accounts')
  .single();

// Display in UI: "Last synced 2 hours ago (150 records in 3.2s)"
```

---

### Service Role (Read-Write)

```sql
-- Policies: vantage_sync_state_{insert|update|delete}_service
-- Allows: service_role only
-- Actions: INSERT, UPDATE, DELETE
-- Purpose: ETL processes run with service_role credentials
```

ETL processes use service_role client:
```typescript
import { createClient } from '@supabase/supabase-js';

const supabaseService = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY // Secret key with full access
);

await supabaseService.rpc('complete_vantage_sync', { ... });
```

---

## Monitoring and Alerts

### Alert Conditions

1. **Stuck Sync (>30 minutes in 'running' state)**
   ```sql
   SELECT resource, started_at,
          EXTRACT(EPOCH FROM (now() - started_at))/60 AS minutes_running
   FROM vantage_sync_state
   WHERE last_sync_status = 'running'
     AND started_at < now() - INTERVAL '30 minutes';
   ```

2. **Stale Sync (>24 hours since last successful sync)**
   ```sql
   SELECT resource, last_sync_time,
          EXTRACT(EPOCH FROM (now() - last_sync_time))/3600 AS hours_since_sync
   FROM vantage_sync_state
   WHERE last_sync_time < now() - INTERVAL '24 hours'
      OR (last_sync_status = 'never_run' AND created_at < now() - INTERVAL '24 hours');
   ```

3. **Repeated Failures (failed 3+ times in a row)**
   ```sql
   SELECT resource, last_sync_status, completed_at, errors
   FROM vantage_sync_state
   WHERE last_sync_status = 'failed';
   -- Application logic tracks consecutive failures
   ```

4. **Performance Degradation (duration_ms > 5 minutes)**
   ```sql
   SELECT resource, duration_ms, completed_at, records_synced
   FROM vantage_sync_state
   WHERE duration_ms > 300000  -- 5 minutes in ms
   ORDER BY completed_at DESC;
   ```

---

## Migration Rollback

To rollback this migration:

```bash
psql -f supabase/migrations/20251105132840_vantage_sync_state_rollback.sql
```

**WARNING:** This will delete all sync state history. Only use if completely removing sync tracking.

---

## Testing

### Manual Testing Sequence

```sql
-- 1. Check initial state
SELECT * FROM vantage_sync_state ORDER BY resource;

-- 2. Start a sync
SELECT start_vantage_sync('accounts');

-- 3. Verify running state
SELECT resource, last_sync_status, started_at, completed_at
FROM vantage_sync_state WHERE resource = 'accounts';
-- Expected: status='running', started_at=now(), completed_at=NULL

-- 4. Complete the sync
SELECT complete_vantage_sync('accounts', 100, 10, 90);

-- 5. Verify success state
SELECT resource, last_sync_status, last_sync_time, duration_ms,
       records_synced, records_created, records_updated
FROM vantage_sync_state WHERE resource = 'accounts';
-- Expected: status='success', last_sync_time=now(), duration_ms>0

-- 6. Test failure scenario
SELECT start_vantage_sync('funds');
SELECT fail_vantage_sync('funds', '[{"code":"TEST_ERROR","message":"Test failure"}]'::jsonb);

-- 7. Verify failure state
SELECT resource, last_sync_status, completed_at, errors
FROM vantage_sync_state WHERE resource = 'funds';
-- Expected: status='failed', errors array has 1 element

-- 8. Verify constraints
-- Try invalid status (should fail)
INSERT INTO vantage_sync_state (resource, last_sync_status)
VALUES ('test', 'invalid_status');
-- Expected: ERROR: check constraint "vantage_sync_state_last_sync_status_check" violated

-- Try negative duration (should fail)
INSERT INTO vantage_sync_state (resource, duration_ms)
VALUES ('test', -100);
-- Expected: ERROR: check constraint "vantage_sync_state_duration_ms_check" violated
```

---

## Performance Characteristics

### Table Size Estimates

- **Rows:** 7-20 (one per resource type)
- **Row Size:** ~200-500 bytes (depends on errors JSONB)
- **Total Size:** < 10 KB (negligible)
- **Index Size:** < 5 KB per index (3 indexes)

### Query Performance Expectations

| Query Type | Expected Time | Index Used |
|------------|---------------|------------|
| Single resource lookup | < 1 ms | Primary key |
| All resources scan | < 2 ms | Sequential scan |
| Failed syncs filter | < 2 ms | idx_vantage_sync_status |
| Slowest syncs | < 2 ms | idx_vantage_sync_duration |
| Stale syncs check | < 2 ms | idx_vantage_sync_last_time |

**Conclusion:** All queries execute in sub-millisecond range. No performance concerns.

---

## Future Enhancements

### Potential Additions (Not Implemented Yet)

1. **Sync History Table**
   - Track complete history of sync runs (not just last run)
   - Enable trend analysis and historical reporting
   - Partition by month for large-scale deployments

2. **Sync Schedules**
   - Store expected sync frequency per resource
   - Enable automated alerting on missed schedules

3. **Dependency Tracking**
   - Model dependencies between resources (e.g., accounts must sync before investments)
   - Enforce sync order in orchestration layer

4. **Retry Logic Metadata**
   - Track retry attempts and backoff intervals
   - Store retry strategy per resource

5. **Webhook Notifications**
   - Trigger webhooks on sync completion/failure
   - Enable integration with external monitoring systems

---

## Questions or Issues?

For questions about this schema, contact the data engineering team or refer to:
- Ticket: ETL-001
- Migration: `20251105132840_vantage_sync_state.sql`
- Rollback: `20251105132840_vantage_sync_state_rollback.sql`
