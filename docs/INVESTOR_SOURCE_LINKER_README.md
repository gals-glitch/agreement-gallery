# Investor Source Linker - Feature Documentation

**Version:** 1.5.0
**Release Date:** 2025-10-19
**Feature Tickets:** PG-101, API-110, FE-101, FE-102, FE-103

---

## Table of Contents
1. [Overview](#overview)
2. [Business Value](#business-value)
3. [Architecture](#architecture)
4. [Implementation Summary](#implementation-summary)
5. [File Structure](#file-structure)
6. [Usage Guide](#usage-guide)
7. [Testing](#testing)
8. [Deployment Checklist](#deployment-checklist)
9. [FAQ](#faq)

---

## Overview

The **Investor Source Linker** feature enables tracking of how investors were introduced to the fund, providing attribution to distributors or referrers. This is a fully **optional enhancement** that does not block existing workflows—users can continue to save investors with or without source attribution.

### Key Features
- **Source Type Classification**: Tag investors as sourced through DISTRIBUTOR, REFERRER, or NONE
- **Party Attribution**: Link investors to the specific party (distributor/referrer) who introduced them
- **Filterable List View**: Filter investors by source type, introducing party, or source presence
- **CSV Bulk Import**: Backfill source data from CSV with row-level error handling
- **Audit Trail**: Timestamp when source linkage was first established

---

## Business Value

### Problems Solved
1. **Attribution Tracking**: Know which distributors/referrers bring in investors
2. **Commission Calculations**: Accurate fee attribution for referring parties
3. **Reporting**: Generate reports on investor acquisition channels
4. **Relationship Management**: Understand investor-party connections

### Success Metrics
- **Data Completeness**: Percentage of investors with source attribution
- **Time Saved**: Reduced manual lookup time for investor origins
- **Accuracy**: Reduction in commission attribution errors

---

## Architecture

### Database Layer (PG-101)

**New Enum Type:**
```sql
CREATE TYPE investor_source_kind AS ENUM ('DISTRIBUTOR', 'REFERRER', 'NONE');
```

**New Columns on `investors` Table:**
| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `source_kind` | `investor_source_kind` | No | `'NONE'` | How investor was sourced |
| `introduced_by_party_id` | `BIGINT` | Yes | `NULL` | FK to `parties.id` |
| `source_linked_at` | `TIMESTAMPTZ` | Yes | `NULL` | When linkage was established |

**Constraints:**
- If `introduced_by_party_id` is set, `source_kind` must be `DISTRIBUTOR` or `REFERRER` (enforced via CHECK constraint)
- Trigger auto-populates `source_linked_at` on first party linkage

**Indexes:**
- `idx_investors_source_kind` - Filter by source type
- `idx_investors_introduced_by` - Filter by introducing party (partial index)
- `idx_investors_source_composite` - Combined filters

---

### API Layer (API-110)

**Endpoints:**
- `GET /api-v1/investors` - List with filters
- `GET /api-v1/investors/:id` - Get single with joined party data
- `POST /api-v1/investors` - Create with source fields
- `PATCH /api-v1/investors/:id` - Update source fields
- `POST /api-v1/investors/source-import` - CSV bulk backfill

**Error Contract:**
All endpoints use standardized `ApiError` format with field-level and row-level validation.

---

### Frontend Layer (FE-101, FE-102, FE-103)

**Components:**
- `src/pages/Investors.tsx` - List view with filters
- `src/components/investors/SourceBadge.tsx` - Color-coded badge
- `src/components/investors/InvestorSourceSection.tsx` - Form section
- `src/components/investors/InvestorSourceCSVImport.tsx` - CSV import modal

**Types:**
- `src/types/investors.ts` - TypeScript interfaces and enums

---

## Implementation Summary

### Backend Implementation (Deno/Supabase Edge Functions)

**File:** `supabase/functions/api-v1/index.ts`

**New Functions:**
- `handleInvestors()` - Main investor CRUD handler
- `handleInvestorSourceImport()` - CSV import handler

**Key Logic:**
```typescript
// Validation: Party must exist if set
if (introduced_by_party_id) {
  const party = await fetchParty(introduced_by_party_id);
  if (!party) return validationError([...]);
}

// Auto-clear party if source_kind is NONE
if (source_kind === 'NONE') {
  introduced_by_party_id = null;
}
```

**CSV Import Flow:**
1. Parse JSON array from request body
2. Validate each row independently
3. Lookup investor by `name` (external_id)
4. Lookup party by `party_name` (case-insensitive)
5. Update investor in transaction
6. Return `{ success_count, errors: [...] }`

---

### Frontend Implementation (React + TypeScript)

**Investors List Page:**
- TanStack Query for data fetching
- Three filter dropdowns: Source Type, Introduced By, Source Status
- Table columns: Name, Email, Source Kind (badge), Introduced By (link), Linked Date, Actions
- Responsive design with loading skeletons

**Investor Form - Source Section:**
- Conditional party selector (only shown when source_kind ≠ NONE)
- Auto-clear party when switching to NONE
- Info alert when source_kind is NONE
- Help text explaining source types

**CSV Import Modal:**
- File upload → Parse CSV → Preview table → Import → Results
- Row-level status indicators (valid/warning/error)
- Summary badges showing counts
- Progress indicator during import
- Detailed error messages with row numbers

---

## File Structure

```
agreement-gallery-main/
├── supabase/
│   ├── migrations/
│   │   └── 20251019100001_investor_source_fields.sql  [PG-101]
│   └── functions/
│       └── api-v1/
│           ├── index.ts                               [API-110 - Updated]
│           └── errors.ts                              [Existing error contract]
│
├── src/
│   ├── types/
│   │   └── investors.ts                               [NEW - Type definitions]
│   ├── components/
│   │   └── investors/
│       │       ├── SourceBadge.tsx                    [FE-101 - Badge component]
│       │       ├── InvestorSourceSection.tsx          [FE-102 - Form section]
│       │       └── InvestorSourceCSVImport.tsx        [FE-103 - CSV import]
│   └── pages/
│       └── Investors.tsx                              [FE-101 - List page]
│
└── docs/
    ├── INVESTOR_SOURCE_API.md                         [API documentation]
    ├── INVESTOR_SOURCE_TESTING.md                     [Testing guide]
    └── INVESTOR_SOURCE_LINKER_README.md               [This file]
```

---

## Usage Guide

### For Ops Users

#### 1. Viewing Investor Sources
1. Navigate to `/investors`
2. Check the **Source Kind** column (badge):
   - Blue "Distributor" = sourced through distribution channel
   - Green "Referrer" = referred by individual/party
   - Gray "None" = direct or unknown
3. Check the **Introduced By** column for party name (clickable link)

#### 2. Filtering Investors
Use the filters card at the top of the page:
- **Source Type**: Filter by Distributor, Referrer, None, or All
- **Introduced By**: Filter by specific party
- **Source Status**: Filter by Has Source (party set) or No Source

#### 3. Adding Source Information
When creating or editing an investor:
1. Scroll to "Investor Source (Optional)" section
2. Select Source Type (Distributor/Referrer/None)
3. If Distributor or Referrer selected, optionally select introducing party
4. Save form
   - If source is "None", you'll see an info toast (non-blocking)
   - Otherwise, save proceeds normally

#### 4. Bulk Importing Sources (CSV)
1. Click "Import Sources" button on investors list
2. Prepare CSV with format:
   ```csv
   investor_external_id,source_kind,party_name
   John Doe LP,DISTRIBUTOR,Acme Capital Partners
   Jane Smith LP,REFERRER,Bob Johnson
   ```
3. Upload CSV file
4. Review preview table (shows validation status per row)
5. Click "Import Valid Rows"
6. Review results and close

---

### For Developers

#### Backend: Adding Source Fields to Investor Payload
```typescript
// POST /api-v1/investors
const payload = {
  name: 'New Investor',
  party_entity_id: 'entity-uuid',
  source_kind: 'DISTRIBUTOR',           // Optional, defaults to 'NONE'
  introduced_by_party_id: 'party-uuid', // Optional, must be valid party
};
```

#### Frontend: Using SourceBadge Component
```tsx
import { SourceBadge } from '@/components/investors/SourceBadge';

<SourceBadge sourceKind={investor.source_kind} />
```

#### Frontend: Using InvestorSourceSection Component
```tsx
import { InvestorSourceSection } from '@/components/investors/InvestorSourceSection';

const [sourceData, setSourceData] = useState({
  source_kind: 'NONE',
  introduced_by_party_id: null,
});

<InvestorSourceSection
  value={sourceData}
  onChange={setSourceData}
  disabled={isSubmitting}
/>
```

---

## Testing

### Unit Tests
```bash
# Backend (Deno)
cd supabase/functions/api-v1
deno test --allow-net --allow-env

# Frontend (Vitest)
npm run test
```

### Integration Tests
```bash
# Run against staging environment
SUPABASE_URL=https://staging.supabase.co npm run test:integration
```

### Manual Testing
See [`docs/INVESTOR_SOURCE_TESTING.md`](./INVESTOR_SOURCE_TESTING.md) for:
- cURL command examples
- Test scenarios with expected results
- CSV import test cases
- UI testing checklist

---

## Deployment Checklist

### Pre-Deployment
- [ ] Database migration `20251019100001_investor_source_fields.sql` reviewed and tested
- [ ] Backend API endpoints tested in dev environment
- [ ] Frontend components tested in dev environment
- [ ] CSV import tested with sample data
- [ ] Performance tests passed (10k+ investors)
- [ ] Accessibility audit passed (WCAG AA)
- [ ] Code review approved
- [ ] Documentation reviewed

### Deployment Steps
1. **Apply Database Migration:**
   ```bash
   supabase db push
   ```

2. **Deploy Edge Functions:**
   ```bash
   supabase functions deploy api-v1
   ```

3. **Deploy Frontend:**
   ```bash
   npm run build
   npm run deploy
   ```

4. **Verify Deployment:**
   - Check `/investors` page loads
   - Test filters work
   - Test create/edit investor with source
   - Test CSV import
   - Check browser console for errors

### Post-Deployment
- [ ] Run smoke tests in production
- [ ] Verify existing investors have `source_kind='NONE'`
- [ ] Monitor error logs for 24 hours
- [ ] Send announcement to ops team with usage guide
- [ ] Schedule training session (if needed)

---

## FAQ

### Q: Is source attribution required?
**A:** No, it's completely optional. Users can save investors with `source_kind='NONE'` and `introduced_by_party_id=NULL`.

### Q: What happens if I delete a party that's linked to investors?
**A:** The foreign key has `ON DELETE SET NULL`, so the investor's `introduced_by_party_id` will be set to `NULL`, but the investor record is preserved.

### Q: Can I change an investor's source attribution later?
**A:** Yes, use the PATCH endpoint or edit the investor in the UI. The `source_linked_at` timestamp only records the first linkage.

### Q: How do I backfill source data for existing investors?
**A:** Use the CSV import tool (`POST /api-v1/investors/source-import`) or manually edit each investor.

### Q: What if I import a CSV with invalid data?
**A:** The import validates each row independently. Valid rows are imported, invalid rows are skipped and reported in the error list.

### Q: Can I filter by multiple source types at once?
**A:** Not currently. The `source_kind` filter is single-select. Use multiple API calls if needed, or add a multi-select filter in a future enhancement.

### Q: Is there a history of source attribution changes?
**A:** No audit trail is currently implemented. Only the latest `source_kind` and `introduced_by_party_id` are stored. Future enhancement could add history tracking.

### Q: Does this affect commission calculations?
**A:** This feature provides the data foundation for commission attribution, but the actual calculation logic is in a separate module. Integration TBD.

### Q: Can I export investors with source data?
**A:** The GET endpoint returns source fields, so yes. A dedicated export feature (Excel/CSV) is planned for a future release.

---

## Support & Contact

- **Feature Owner:** Investor Management Team
- **Slack Channel:** #investor-source-linker
- **JIRA Project:** BCFMS (Buligo Capital Fee Management System)
- **Documentation:** [Confluence - Investor Source Linker](https://confluence.internal/investor-source)

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.5.0 | 2025-10-19 | Initial release (PG-101, API-110, FE-101, FE-102, FE-103) |

---

## Future Enhancements

- [ ] Add external_id field to investors for better CSV matching
- [ ] Implement fuzzy party name matching in CSV import
- [ ] Add bulk edit action in investors list UI
- [ ] Track source attribution change history
- [ ] Add source analytics dashboard
- [ ] Integrate with commission calculation engine
- [ ] Export investors with source data to Excel

---

## License

© 2025 Buligo Capital. Internal use only.
