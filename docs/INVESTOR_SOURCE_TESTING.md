# Investor Source Linker - Testing Guide

**Version:** 1.5.0
**Date:** 2025-10-19
**Tickets:** API-110, FE-101, FE-102, FE-103

## Prerequisites

### 1. Set Environment Variables
```bash
export SUPABASE_URL="https://your-project.supabase.co"
export ANON_KEY="your-anon-key"
export TOKEN="your-jwt-token"  # Get from browser devtools after login
```

### 2. Verify Database Migration
```sql
-- Check migration applied
SELECT COUNT(*) FROM investors WHERE source_kind IS NOT NULL;

-- Check enum values
SELECT enum_range(NULL::investor_source_kind);

-- Check indexes exist
\d investors
```

---

## Manual Testing Scenarios

### Scenario 1: List Investors with Filters

#### Test 1.1: Get All Investors
```bash
curl -X GET "${SUPABASE_URL}/functions/v1/api-v1/investors" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json"
```

**Expected:**
- 200 OK
- `items` array with investor objects
- Each investor has `source_kind`, `introduced_by_party_id`, `source_linked_at` fields
- Default: all investors have `source_kind='NONE'`, `introduced_by_party_id=null`

---

#### Test 1.2: Filter by Source Kind (DISTRIBUTOR)
```bash
curl -X GET "${SUPABASE_URL}/functions/v1/api-v1/investors?source_kind=DISTRIBUTOR" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json"
```

**Expected:**
- 200 OK
- Only investors with `source_kind='DISTRIBUTOR'`
- `total` reflects filtered count

---

#### Test 1.3: Filter by Source Kind (NONE)
```bash
curl -X GET "${SUPABASE_URL}/functions/v1/api-v1/investors?source_kind=NONE" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json"
```

**Expected:**
- 200 OK
- Only investors with `source_kind='NONE'`
- Initially, this should return all investors

---

#### Test 1.4: Filter by Has Source (true)
```bash
curl -X GET "${SUPABASE_URL}/functions/v1/api-v1/investors?has_source=true" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json"
```

**Expected:**
- 200 OK
- Only investors where `introduced_by_party_id IS NOT NULL`
- Initially, should return 0 investors

---

#### Test 1.5: Filter by Introduced By Party
```bash
# First, get a party ID
curl -X GET "${SUPABASE_URL}/functions/v1/api-v1/parties?limit=1" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json"

# Use party ID from response
PARTY_ID="<party-id-from-response>"

curl -X GET "${SUPABASE_URL}/functions/v1/api-v1/investors?introduced_by_party_id=${PARTY_ID}" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json"
```

**Expected:**
- 200 OK
- Only investors with matching `introduced_by_party_id`

---

### Scenario 2: Create Investor with Source

#### Test 2.1: Create Investor with DISTRIBUTOR Source
```bash
# First, get a party to use as introducer
curl -X GET "${SUPABASE_URL}/functions/v1/api-v1/parties?limit=1" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json"

# Use party ID and entity ID from responses
PARTY_ID="<party-id>"
ENTITY_ID="<entity-id>"

curl -X POST "${SUPABASE_URL}/functions/v1/api-v1/investors" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Investor - Distributor",
    "party_entity_id": "'${ENTITY_ID}'",
    "email": "test.distributor@example.com",
    "source_kind": "DISTRIBUTOR",
    "introduced_by_party_id": "'${PARTY_ID}'"
  }'
```

**Expected:**
- 201 Created
- Response: `{"id": "new-investor-uuid"}`
- Verify: `source_kind='DISTRIBUTOR'`, `introduced_by_party_id=<party-id>`, `source_linked_at` is set

---

#### Test 2.2: Create Investor with REFERRER Source (No Party)
```bash
curl -X POST "${SUPABASE_URL}/functions/v1/api-v1/investors" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Investor - Referrer No Party",
    "party_entity_id": "'${ENTITY_ID}'",
    "email": "test.referrer@example.com",
    "source_kind": "REFERRER"
  }'
```

**Expected:**
- 201 Created
- `source_kind='REFERRER'`, `introduced_by_party_id=NULL`

---

#### Test 2.3: Create Investor with NONE Source
```bash
curl -X POST "${SUPABASE_URL}/functions/v1/api-v1/investors" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Investor - No Source",
    "party_entity_id": "'${ENTITY_ID}'",
    "email": "test.none@example.com",
    "source_kind": "NONE"
  }'
```

**Expected:**
- 201 Created
- `source_kind='NONE'`, `introduced_by_party_id=NULL`

---

#### Test 2.4: VALIDATION ERROR - Party Set with NONE Source
```bash
curl -X POST "${SUPABASE_URL}/functions/v1/api-v1/investors" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Invalid Investor",
    "party_entity_id": "'${ENTITY_ID}'",
    "source_kind": "NONE",
    "introduced_by_party_id": "'${PARTY_ID}'"
  }'
```

**Expected:**
- 422 Unprocessable Entity
- Error response:
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
  "timestamp": "..."
}
```

---

#### Test 2.5: VALIDATION ERROR - Invalid Party ID
```bash
curl -X POST "${SUPABASE_URL}/functions/v1/api-v1/investors" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Invalid Party Investor",
    "party_entity_id": "'${ENTITY_ID}'",
    "source_kind": "DISTRIBUTOR",
    "introduced_by_party_id": "00000000-0000-0000-0000-000000000000"
  }'
```

**Expected:**
- 422 Unprocessable Entity
- Error message: "Invalid party ID - party not found"

---

### Scenario 3: Update Investor Source

#### Test 3.1: Update Investor - Add Source Attribution
```bash
# Get an existing investor ID
INVESTOR_ID="<existing-investor-id>"

curl -X PATCH "${SUPABASE_URL}/functions/v1/api-v1/investors/${INVESTOR_ID}" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "source_kind": "DISTRIBUTOR",
    "introduced_by_party_id": "'${PARTY_ID}'"
  }'
```

**Expected:**
- 200 OK
- Response: `{"ok": true}`
- Verify: `source_kind='DISTRIBUTOR'`, `introduced_by_party_id=<party-id>`, `source_linked_at` is set (if first time)

---

#### Test 3.2: Update Investor - Change to NONE (Auto-Clear Party)
```bash
curl -X PATCH "${SUPABASE_URL}/functions/v1/api-v1/investors/${INVESTOR_ID}" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "source_kind": "NONE"
  }'
```

**Expected:**
- 200 OK
- Verify: `source_kind='NONE'`, `introduced_by_party_id=NULL` (auto-cleared)

---

#### Test 3.3: Update Investor - Change Party
```bash
# Get a different party ID
PARTY_ID_2="<another-party-id>"

curl -X PATCH "${SUPABASE_URL}/functions/v1/api-v1/investors/${INVESTOR_ID}" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "source_kind": "REFERRER",
    "introduced_by_party_id": "'${PARTY_ID_2}'"
  }'
```

**Expected:**
- 200 OK
- Verify: `source_kind='REFERRER'`, `introduced_by_party_id=<party-id-2>`
- `source_linked_at` should NOT change (only set on first link)

---

### Scenario 4: CSV Bulk Import

#### Test 4.1: Prepare Test CSV
Create `test-investor-sources.csv`:
```csv
investor_external_id,source_kind,party_name
Test Investor 1,DISTRIBUTOR,Acme Capital Partners
Test Investor 2,REFERRER,John Smith
Test Investor 3,NONE,
Invalid Investor,DISTRIBUTOR,Unknown Party
Test Investor 4,INVALID_KIND,
```

---

#### Test 4.2: Import CSV (Success + Errors)
```bash
# Convert CSV to JSON array (using jq or manually)
cat test-investor-sources.csv | jq -R -s -f csv_to_json.jq > import_payload.json

# Or create JSON manually:
cat > import_payload.json << 'EOF'
[
  {
    "investor_external_id": "Test Investor 1",
    "source_kind": "DISTRIBUTOR",
    "party_name": "Acme Capital Partners"
  },
  {
    "investor_external_id": "Test Investor 2",
    "source_kind": "REFERRER",
    "party_name": "John Smith"
  },
  {
    "investor_external_id": "Test Investor 3",
    "source_kind": "NONE"
  },
  {
    "investor_external_id": "Invalid Investor",
    "source_kind": "DISTRIBUTOR",
    "party_name": "Unknown Party"
  },
  {
    "investor_external_id": "Test Investor 4",
    "source_kind": "INVALID_KIND"
  }
]
EOF

curl -X POST "${SUPABASE_URL}/functions/v1/api-v1/investors/source-import" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d @import_payload.json
```

**Expected:**
- 200 OK
- Response:
```json
{
  "success_count": 3,
  "errors": [
    {
      "row": 4,
      "field": "investor_external_id",
      "message": "Investor not found: Invalid Investor",
      "value": "Invalid Investor"
    },
    {
      "row": 5,
      "field": "source_kind",
      "message": "source_kind must be DISTRIBUTOR, REFERRER, or NONE",
      "value": "INVALID_KIND"
    }
  ]
}
```

---

### Scenario 5: Frontend UI Testing

#### Test 5.1: Investors List Page
1. Navigate to `/investors`
2. Verify columns:
   - Name
   - Email
   - Source Kind (badge with color)
   - Introduced By (party name as link)
   - Linked Date
   - Actions
3. Test filters:
   - Source Type dropdown (All, Distributor, Referrer, None)
   - Introduced By dropdown (All Parties, specific parties)
   - Source Status dropdown (All, Has Source, No Source)
4. Verify filter combinations work correctly
5. Click "Clear Filters" button

---

#### Test 5.2: Investor Form - Source Section
1. Click "Add Investor" or edit existing investor
2. Locate "Investor Source (Optional)" card
3. Test source_kind selector:
   - Select "Distributor" → Party selector appears
   - Select "Referrer" → Party selector appears
   - Select "None" → Party selector hidden, info alert shown
4. Test party selector:
   - Dropdown populates with active parties
   - Select a party
   - Change source_kind to "None" → Party selection cleared
5. Save form:
   - With source_kind="None" → Info toast: "Investor saved without source attribution"
   - With source_kind="Distributor" + party → No toast
   - With invalid party → Field-level error

---

#### Test 5.3: CSV Import Modal
1. Click "Import Sources" button on investors list page
2. Upload CSV file (use test CSV from Test 4.1)
3. Verify preview table shows:
   - Row number
   - Status badge (Valid / Warning / Error)
   - Investor ID, Source Kind, Party Name
   - Error messages for invalid rows
4. Verify summary badges:
   - X Valid (green)
   - X Warnings (yellow)
   - X Errors (red)
5. Click "Import Valid Rows"
6. Verify progress indicator
7. Verify completion screen:
   - Success count
   - Error list (if any)
8. Close modal
9. Verify investors list refreshes

---

## Integration Tests

### Test Suite 1: Source Field Validation
```typescript
describe('Investor Source Validation', () => {
  it('allows creating investor with source_kind=NONE', async () => {
    const result = await createInvestor({
      name: 'Test',
      party_entity_id: entityId,
      source_kind: 'NONE',
    });
    expect(result.status).toBe(201);
  });

  it('allows creating investor with source_kind=DISTRIBUTOR and party', async () => {
    const result = await createInvestor({
      name: 'Test',
      party_entity_id: entityId,
      source_kind: 'DISTRIBUTOR',
      introduced_by_party_id: partyId,
    });
    expect(result.status).toBe(201);
  });

  it('rejects creating investor with source_kind=NONE and party set', async () => {
    const result = await createInvestor({
      name: 'Test',
      party_entity_id: entityId,
      source_kind: 'NONE',
      introduced_by_party_id: partyId,
    });
    expect(result.status).toBe(422);
    expect(result.body.code).toBe('VALIDATION_ERROR');
  });
});
```

---

### Test Suite 2: Filter Logic
```typescript
describe('Investor Source Filters', () => {
  it('filters by source_kind=DISTRIBUTOR', async () => {
    const result = await fetchInvestors({ source_kind: 'DISTRIBUTOR' });
    expect(result.items.every(i => i.source_kind === 'DISTRIBUTOR')).toBe(true);
  });

  it('filters by has_source=true', async () => {
    const result = await fetchInvestors({ has_source: true });
    expect(result.items.every(i => i.introduced_by_party_id !== null)).toBe(true);
  });

  it('combines filters correctly (AND logic)', async () => {
    const result = await fetchInvestors({
      source_kind: 'REFERRER',
      has_source: true,
    });
    expect(result.items.every(i =>
      i.source_kind === 'REFERRER' && i.introduced_by_party_id !== null
    )).toBe(true);
  });
});
```

---

### Test Suite 3: CSV Import
```typescript
describe('CSV Source Import', () => {
  it('imports valid rows and skips errors', async () => {
    const result = await importSources([
      { investor_external_id: 'Valid', source_kind: 'DISTRIBUTOR', party_name: 'Acme' },
      { investor_external_id: 'Invalid', source_kind: 'BAD', party_name: '' },
    ]);

    expect(result.success_count).toBe(1);
    expect(result.errors.length).toBe(1);
    expect(result.errors[0].row).toBe(2);
  });
});
```

---

## Performance Testing

### Test Load: 10,000 Investors with Filters
```bash
# Seed database with test data
for i in {1..10000}; do
  curl -X POST "${SUPABASE_URL}/functions/v1/api-v1/investors" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{
      "name": "Investor '${i}'",
      "party_entity_id": "'${ENTITY_ID}'",
      "source_kind": "'$((i % 3 == 0 ? 'DISTRIBUTOR' : i % 3 == 1 ? 'REFERRER' : 'NONE'))'",
      "introduced_by_party_id": "'$((i % 3 == 0 ? PARTY_ID : null))'"
    }' &
done
wait

# Test query performance
time curl -X GET "${SUPABASE_URL}/functions/v1/api-v1/investors?source_kind=DISTRIBUTOR&limit=100" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Expected:**
- Response time < 500ms for filtered queries
- Indexes used (verify with EXPLAIN ANALYZE in psql)

---

## Regression Tests

### Test: Existing Save Flows Still Work
```bash
# Save investor without source fields (backward compatibility)
curl -X POST "${SUPABASE_URL}/functions/v1/api-v1/investors" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Legacy Investor",
    "party_entity_id": "'${ENTITY_ID}'",
    "email": "legacy@example.com"
  }'
```

**Expected:**
- 201 Created
- `source_kind` defaults to 'NONE'
- No errors or warnings

---

## Acceptance Criteria Verification

- [ ] Can save/update investors with or without source information (no blocking validation)
- [ ] Filters correctly show/hide investors based on source_kind, source presence, and introducing party
- [ ] CSV importer handles errors gracefully with clear per-row feedback
- [ ] No console errors, warnings, or accessibility violations
- [ ] All tests pass (unit, integration, E2E)
- [ ] Code follows project conventions (linting, formatting, naming)

---

## Troubleshooting

### Issue: "Investor not found" in CSV Import
**Solution:** Check that `investor_external_id` matches the exact `name` field in the investors table (case-sensitive).

### Issue: "Party not found" in CSV Import
**Solution:** Verify party name matches exactly (case-insensitive, but whitespace matters). Trim spaces in CSV.

### Issue: Database constraint violation
**Solution:** Check that `introduced_by_party_id` references a valid party. Run:
```sql
SELECT id, name FROM parties WHERE id = '<party-id>';
```

### Issue: Filters not working
**Solution:** Clear browser cache and verify query params in network tab. Check API response has correct filter logic.

---

## Support Contacts

- **Backend Issues:** #backend-api Slack channel
- **Frontend Issues:** #frontend-dev Slack channel
- **Database Issues:** DBA team (dba@buligocapital.com)
- **QA/Testing:** qa-team@buligocapital.com
