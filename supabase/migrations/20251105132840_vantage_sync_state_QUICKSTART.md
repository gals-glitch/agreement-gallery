# Vantage Sync State - Quick Start Guide

**Migration:** `20251105132840_vantage_sync_state.sql`
**For:** ETL Developers & Frontend Engineers

---

## TL;DR

Track Vantage API sync status with `vantage_sync_state` table:
- One row per resource type (accounts, funds, cashflows, etc.)
- Records last sync time, status, metrics, and errors
- Helper functions for common operations
- Frontend can read status, backend (service_role) can write

---

## Table Schema (At a Glance)

```sql
CREATE TABLE vantage_sync_state (
  resource          TEXT PRIMARY KEY,           -- 'accounts', 'funds', etc.
  last_sync_time    TIMESTAMPTZ,                -- Last successful sync
  last_sync_status  TEXT NOT NULL,              -- 'success', 'failed', 'running', 'never_run'
  records_synced    INT DEFAULT 0,              -- Total records processed
  records_created   INT DEFAULT 0,              -- New records
  records_updated   INT DEFAULT 0,              -- Updated records
  errors            JSONB DEFAULT '[]',         -- Error details array
  started_at        TIMESTAMPTZ,                -- Sync start time
  completed_at      TIMESTAMPTZ,                -- Sync end time
  duration_ms       INT,                        -- Auto-calculated duration
  created_at        TIMESTAMPTZ DEFAULT now(),
  updated_at        TIMESTAMPTZ DEFAULT now()   -- Auto-updated
);
```

---

## Usage: ETL Process (Backend)

### Full ETL Flow with Error Handling

```typescript
import { createClient } from '@supabase/supabase-js';

// Use service_role for write access
const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!  // Secret key
);

async function syncVantageAccounts() {
  const resource = 'accounts';

  // 1. Start sync
  await supabase.rpc('start_vantage_sync', { p_resource: resource });

  try {
    // 2. Get last sync time for incremental sync
    const { data: syncState } = await supabase
      .from('vantage_sync_state')
      .select('last_sync_time')
      .eq('resource', resource)
      .single();

    // 3. Fetch from Vantage API
    const accounts = await fetchVantageAPI('/accounts', {
      modifiedSince: syncState?.last_sync_time
    });

    // 4. Process and upsert records
    let created = 0, updated = 0;
    for (const account of accounts) {
      const { isNew } = await upsertAccount(account);
      if (isNew) created++; else updated++;
    }

    // 5. Mark sync as complete
    await supabase.rpc('complete_vantage_sync', {
      p_resource: resource,
      p_records_synced: accounts.length,
      p_records_created: created,
      p_records_updated: updated
    });

    console.log(`✅ Synced ${accounts.length} accounts (${created} new, ${updated} updated)`);

  } catch (error) {
    // 6. Mark sync as failed
    await supabase.rpc('fail_vantage_sync', {
      p_resource: resource,
      p_errors: [{
        code: error.code || 'UNKNOWN_ERROR',
        message: error.message,
        timestamp: new Date().toISOString(),
        stack: error.stack
      }]
    });

    console.error(`❌ Sync failed:`, error);
    throw error;
  }
}
```

---

## Helper Functions (Backend)

### 1. Start Sync
```typescript
await supabase.rpc('start_vantage_sync', {
  p_resource: 'accounts'
});
// Sets status='running', records started_at
```

### 2. Complete Sync (Success)
```typescript
await supabase.rpc('complete_vantage_sync', {
  p_resource: 'accounts',
  p_records_synced: 150,
  p_records_created: 10,
  p_records_updated: 140
});
// Sets status='success', updates last_sync_time, clears errors
```

### 3. Fail Sync (Error)
```typescript
await supabase.rpc('fail_vantage_sync', {
  p_resource: 'accounts',
  p_errors: [
    {
      code: 'API_TIMEOUT',
      message: 'Request timed out after 30s',
      timestamp: '2025-11-05T10:30:00Z'
    }
  ]
});
// Sets status='failed', stores errors
```

---

## Usage: Display Sync Status (Frontend)

### Get Status for Single Resource

```typescript
import { createClient } from '@supabase/supabase-js';

// Use anon key for read-only access
const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
);

const { data: syncState } = await supabase
  .from('vantage_sync_state')
  .select('*')
  .eq('resource', 'accounts')
  .single();

console.log(`
  Resource: ${syncState.resource}
  Status: ${syncState.last_sync_status}
  Last Sync: ${syncState.last_sync_time}
  Duration: ${syncState.duration_ms}ms
  Records: ${syncState.records_synced}
`);
```

### Display in UI Component

```tsx
import { useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase';

function SyncStatusBadge({ resource }: { resource: string }) {
  const [state, setState] = useState<any>(null);

  useEffect(() => {
    async function loadStatus() {
      const { data } = await supabase
        .from('vantage_sync_state')
        .select('last_sync_status, last_sync_time, duration_ms')
        .eq('resource', resource)
        .single();
      setState(data);
    }
    loadStatus();
  }, [resource]);

  if (!state) return <span>Loading...</span>;

  const statusColors = {
    success: 'green',
    failed: 'red',
    running: 'yellow',
    never_run: 'gray'
  };

  const timeSince = state.last_sync_time
    ? Math.round((Date.now() - new Date(state.last_sync_time).getTime()) / 1000 / 60)
    : null;

  return (
    <div className={`badge badge-${statusColors[state.last_sync_status]}`}>
      {state.last_sync_status === 'success' && (
        <>✅ Synced {timeSince} min ago ({state.duration_ms}ms)</>
      )}
      {state.last_sync_status === 'failed' && (
        <>❌ Failed</>
      )}
      {state.last_sync_status === 'running' && (
        <>⏳ Running...</>
      )}
      {state.last_sync_status === 'never_run' && (
        <>⚪ Not synced yet</>
      )}
    </div>
  );
}
```

---

## Common Queries

### Get All Sync States (Dashboard)
```sql
SELECT
  resource,
  last_sync_status,
  last_sync_time,
  duration_ms,
  records_synced
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

### Find Failed Syncs
```sql
SELECT resource, last_sync_status, errors
FROM vantage_sync_state
WHERE last_sync_status = 'failed';
```

### Check for Stale Syncs (>24 hours)
```sql
SELECT
  resource,
  last_sync_time,
  EXTRACT(EPOCH FROM (now() - last_sync_time))/3600 AS hours_ago
FROM vantage_sync_state
WHERE last_sync_time < now() - INTERVAL '24 hours'
ORDER BY last_sync_time ASC;
```

### Monitor Performance (Slowest Syncs)
```sql
SELECT
  resource,
  duration_ms,
  records_synced,
  ROUND(records_synced::NUMERIC / NULLIF(duration_ms, 0) * 1000, 2) AS records_per_second
FROM vantage_sync_state
WHERE duration_ms IS NOT NULL
ORDER BY duration_ms DESC
LIMIT 5;
```

---

## Error Handling Best Practices

### Error Object Structure

```typescript
interface SyncError {
  code: string;           // Error code (e.g., 'API_TIMEOUT', 'PARSE_ERROR')
  message: string;        // Human-readable message
  timestamp?: string;     // ISO 8601 timestamp
  record_id?: string;     // ID of problematic record (if applicable)
  stack?: string;         // Stack trace (for debugging)
  context?: any;          // Additional context data
}
```

### Example Error Logging

```typescript
try {
  await processVantageRecord(record);
} catch (error) {
  errors.push({
    code: 'PROCESSING_ERROR',
    message: `Failed to process record: ${error.message}`,
    timestamp: new Date().toISOString(),
    record_id: record.id,
    context: {
      recordType: record.type,
      attemptNumber: 3
    }
  });
}

// At end of sync
if (errors.length > 0) {
  await supabase.rpc('fail_vantage_sync', {
    p_resource: resource,
    p_errors: errors
  });
}
```

---

## Status Transitions

```
never_run ──> running ──> success ──┐
                   │                 │
                   └──> failed ──────┘
                            │
                            └──> running (retry)
```

**Rules:**
- `never_run` → `running`: First sync starts
- `running` → `success`: Sync completes without errors
- `running` → `failed`: Sync encounters errors
- `success`/`failed` → `running`: Next sync starts

---

## Monitoring & Alerts

### Alert Conditions

1. **Stuck Sync:** `status='running'` for > 30 minutes
   ```sql
   SELECT resource FROM vantage_sync_state
   WHERE last_sync_status = 'running'
     AND started_at < now() - INTERVAL '30 minutes';
   ```

2. **Stale Sync:** No successful sync in 24+ hours
   ```sql
   SELECT resource FROM vantage_sync_state
   WHERE last_sync_time < now() - INTERVAL '24 hours'
      OR last_sync_status = 'never_run';
   ```

3. **Slow Sync:** `duration_ms` > 5 minutes
   ```sql
   SELECT resource FROM vantage_sync_state
   WHERE duration_ms > 300000;
   ```

---

## RLS (Row Level Security)

### Who Can Do What?

| Role | SELECT | INSERT | UPDATE | DELETE |
|------|--------|--------|--------|--------|
| Authenticated Users | ✅ Yes | ❌ No | ❌ No | ❌ No |
| Service Role | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |

**Frontend:** Read-only access (display sync status)
**Backend ETL:** Full access via service_role credentials

---

## Deployment

### Apply Migration
```bash
# Via Supabase CLI
supabase db push

# Or via SQL
psql -h your-db-host -U postgres -d your-db \
  -f supabase/migrations/20251105132840_vantage_sync_state.sql
```

### Rollback (if needed)
```bash
psql -h your-db-host -U postgres -d your-db \
  -f supabase/migrations/20251105132840_vantage_sync_state_rollback.sql
```

---

## Testing

### Manual Test Sequence

```sql
-- 1. Check initial state
SELECT * FROM vantage_sync_state WHERE resource = 'accounts';

-- 2. Start a test sync
SELECT start_vantage_sync('accounts');

-- 3. Verify status is 'running'
SELECT last_sync_status, started_at FROM vantage_sync_state WHERE resource = 'accounts';

-- 4. Complete the sync
SELECT complete_vantage_sync('accounts', 100, 10, 90);

-- 5. Verify success state
SELECT * FROM vantage_sync_state WHERE resource = 'accounts';
-- Expected: status='success', last_sync_time=now(), duration_ms calculated

-- 6. Test failure scenario
SELECT start_vantage_sync('funds');
SELECT fail_vantage_sync('funds', '[{"code":"TEST","message":"Test error"}]'::jsonb);

-- 7. Verify failure state
SELECT last_sync_status, errors FROM vantage_sync_state WHERE resource = 'funds';
-- Expected: status='failed', errors array populated
```

---

## Performance Notes

- **Table Size:** < 10 KB (7-20 rows)
- **Query Speed:** All queries < 2 ms
- **Indexes:** 3 strategic indexes (status, time, duration)
- **Scalability:** Handles 100+ resources easily

---

## Files Reference

| File | Purpose |
|------|---------|
| `20251105132840_vantage_sync_state.sql` | Main migration (apply this) |
| `20251105132840_vantage_sync_state_rollback.sql` | Rollback script (if needed) |
| `20251105132840_vantage_sync_state_DOCUMENTATION.md` | Full documentation with EXPLAIN plans |
| `20251105132840_vantage_sync_state_VALIDATION.md` | Requirements checklist & validation |
| `20251105132840_vantage_sync_state_QUICKSTART.md` | This quick start guide |

---

## Need Help?

- **Full Docs:** See `_DOCUMENTATION.md` for EXPLAIN plans and advanced queries
- **Validation:** See `_VALIDATION.md` for requirements checklist
- **Ticket:** ETL-001

---

## Key Takeaways

1. ✅ Use helper functions (`start_vantage_sync`, `complete_vantage_sync`, `fail_vantage_sync`)
2. ✅ Always wrap ETL in try-catch to handle failures
3. ✅ Use `last_sync_time` for incremental syncs
4. ✅ Store detailed errors in JSONB array
5. ✅ Frontend reads via anon key, backend writes via service_role
6. ✅ Monitor for stuck syncs (>30 min) and stale syncs (>24 hrs)
