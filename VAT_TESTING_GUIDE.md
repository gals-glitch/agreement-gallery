# VAT System - Manual Testing Guide

## Quick Start

### Prerequisites
1. Admin user account
2. `vat_admin` feature flag enabled for admin role
3. Supabase project URL and anon key
4. Valid auth token (from browser DevTools or API)

---

## Test Scenarios

### Scenario 1: Create First VAT Rate

**Objective:** Create UK VAT rate successfully

```bash
# Get your auth token from browser (localStorage.getItem('sb-xxx-auth-token'))
export TOKEN="your-token-here"
export API_URL="https://your-project.supabase.co/functions/v1/api-v1"

# Create UK VAT rate
curl -X POST "$API_URL/vat-rates" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "country_code": "GB",
    "rate_percentage": 20.00,
    "effective_from": "2011-01-04",
    "effective_to": null,
    "description": "UK Standard VAT rate (20%)"
  }'
```

**Expected Result:**
- Status: 201 Created
- Response contains created VAT rate with ID

---

### Scenario 2: Test Overlap Validation

**Objective:** Verify overlap prevention

```bash
# Try to create overlapping rate (should fail)
curl -X POST "$API_URL/vat-rates" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "country_code": "GB",
    "rate_percentage": 22.00,
    "effective_from": "2020-01-01",
    "effective_to": null,
    "description": "Should fail - overlaps with existing rate"
  }'
```

**Expected Result:**
- Status: 409 Conflict
- Error message: "VAT rate overlaps with existing rate for GB"
- Details array contains field-level error

---

### Scenario 3: List VAT Rates

**Objective:** Retrieve all rates

```bash
# List all rates
curl "$API_URL/vat-rates" \
  -H "Authorization: Bearer $TOKEN"

# List only current rates
curl "$API_URL/vat-rates?active=true" \
  -H "Authorization: Bearer $TOKEN"

# List rates for specific country
curl "$API_URL/vat-rates?country_code=GB" \
  -H "Authorization: Bearer $TOKEN"
```

**Expected Result:**
- Status: 200 OK
- Response: `{ "vat_rates": [...] }`

---

### Scenario 4: Get Current Rate

**Objective:** Get active rate for a country

```bash
curl "$API_URL/vat-rates/current?country_code=GB" \
  -H "Authorization: Bearer $TOKEN"
```

**Expected Result:**
- Status: 200 OK
- Response contains current UK rate (20%)

```bash
# Test non-existent country
curl "$API_URL/vat-rates/current?country_code=XX" \
  -H "Authorization: Bearer $TOKEN"
```

**Expected Result:**
- Status: 404 Not Found
- Error message: "Current VAT rate for XX not found"

---

### Scenario 5: Close VAT Rate

**Objective:** Set end date for a rate

```bash
# First, get the rate ID from list endpoint
export RATE_ID="uuid-from-list-response"

# Close the rate
curl -X PATCH "$API_URL/vat-rates/$RATE_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "effective_to": "2025-12-31"
  }'
```

**Expected Result:**
- Status: 200 OK
- Response contains updated rate with effective_to set

---

### Scenario 6: Create Scheduled Rate

**Objective:** Create future rate

```bash
# Create rate starting in future
curl -X POST "$API_URL/vat-rates" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "country_code": "GB",
    "rate_percentage": 22.00,
    "effective_from": "2026-01-01",
    "effective_to": null,
    "description": "UK VAT rate increase (22%)"
  }'
```

**Expected Result:**
- Status: 201 Created
- Rate created with future effective_from

---

### Scenario 7: Delete VAT Rate

**Objective:** Delete unused rate

```bash
# Delete the scheduled rate
curl -X DELETE "$API_URL/vat-rates/$RATE_ID" \
  -H "Authorization: Bearer $TOKEN"
```

**Expected Result:**
- Status: 204 No Content (if unused)
- Status: 409 Conflict (if referenced in snapshots)

---

### Scenario 8: Agreement Approval Snapshot

**Objective:** Verify VAT captured on approval

**Prerequisites:**
1. Create party with country = 'GB'
2. Create agreement for that party
3. Submit agreement for approval

```bash
# Get agreement ID
export AGREEMENT_ID="uuid-here"

# Approve agreement (as manager/admin)
curl -X POST "$API_URL/agreements/$AGREEMENT_ID/approve" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
```

**Verification:**
```sql
-- Check snapshot was created
SELECT
  agreement_id,
  vat_rate_percent,
  vat_policy,
  vat_included,
  snapshotted_at
FROM agreement_rate_snapshots
WHERE agreement_id = 'your-agreement-id';
```

**Expected Result:**
- `vat_rate_percent` = 20.00 (from GB current rate)
- `vat_policy` = 'INCLUSIVE' or 'EXCLUSIVE' (based on agreement.vat_included)
- `snapshotted_at` = timestamp of approval

---

### Scenario 9: Snapshot Immutability

**Objective:** Verify changing VAT rate doesn't affect old agreements

1. Create and approve agreement (captures 20% VAT)
2. Change GB VAT rate to 22%
3. Query old agreement snapshot

```sql
-- Verify old agreement still shows 20%
SELECT vat_rate_percent
FROM agreement_rate_snapshots
WHERE agreement_id = 'old-agreement-id';
-- Should return 20.00, not 22.00
```

**Expected Result:**
- Old snapshot unchanged (20%)
- New agreements will capture 22%

---

### Scenario 10: RBAC Enforcement

**Objective:** Verify admin-only access

**Test 1: Non-admin user**
```bash
# Use token from non-admin user
export NON_ADMIN_TOKEN="token-from-viewer-user"

curl -X POST "$API_URL/vat-rates" \
  -H "Authorization: Bearer $NON_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "country_code": "US",
    "rate_percentage": 0,
    "effective_from": "2025-01-01"
  }'
```

**Expected Result:**
- Status: 403 Forbidden
- Error: "VAT rate creation requires admin role"

**Test 2: Feature flag disabled**
1. Disable `vat_admin` feature flag
2. Try to access /vat-settings in browser

**Expected Result:**
- 404 Not Found or access denied

---

## Frontend Testing Checklist

### Navigation
- [ ] Log in as admin user
- [ ] Access `/vat-settings` URL directly
- [ ] Verify page loads (feature flag must be ON)
- [ ] Verify sidebar shows "VAT Settings" link (admin-only)

### Current Rates Section
- [ ] Verify table displays current rates
- [ ] Verify country flag and name show correctly
- [ ] Verify "Actions" dropdown has "Close Rate" and "Delete" options
- [ ] Click "Close Rate" → dialog opens
- [ ] Click "Delete" → confirmation dialog opens

### Create VAT Rate
- [ ] Click "New VAT Rate" button
- [ ] Dialog opens with form fields:
  - Country selector (dropdown with flags)
  - Rate percentage input (0-100)
  - Effective from date picker
  - Effective to date picker (optional)
  - Description textarea
- [ ] Submit without country → validation error
- [ ] Submit with rate > 100 → validation error
- [ ] Submit with effective_to < effective_from → validation error
- [ ] Submit valid data → success toast
- [ ] New rate appears in appropriate section

### Close VAT Rate
- [ ] Select "Close Rate" from current rate
- [ ] Dialog shows rate details
- [ ] Enter effective_to date
- [ ] Click "Close Rate" → success toast
- [ ] Rate moves from Current to Historical section

### Delete VAT Rate
- [ ] Select "Delete" from scheduled rate
- [ ] Confirmation dialog shows rate details
- [ ] Click "Delete" → success toast
- [ ] Rate removed from table
- [ ] Try to delete referenced rate → error toast "Cannot delete"

### Sections Display
- [ ] Current section shows rates with effective_to = NULL
- [ ] Historical section shows rates with effective_to in past
- [ ] Scheduled section shows rates with effective_from in future
- [ ] Each section shows "No rates" message when empty

### Info Banner
- [ ] Banner displays at top of page
- [ ] Message explains immutability of snapshots
- [ ] Info icon visible

---

## Troubleshooting

### Issue: 401 Unauthorized
**Solution:** Check auth token is valid and not expired

### Issue: 403 Forbidden
**Solution:** Verify user has admin role in `user_roles` table

### Issue: 404 Not Found
**Solution:** Check feature flag `vat_admin` is enabled

### Issue: Overlap not detected
**Solution:** Verify `check_vat_overlap_trigger()` is active:
```sql
SELECT * FROM pg_trigger WHERE tgname = 'vat_rates_overlap_check';
```

### Issue: Snapshot not created
**Solution:** Verify `snapshot_rates_on_approval()` trigger is active:
```sql
SELECT * FROM pg_trigger WHERE tgname = 'snapshot_rates_on_approval_trigger';
```

### Issue: Frontend errors
**Solution:** Check browser console for errors, verify API endpoints are correct

---

## Test Data Seed Script

```sql
-- Insert test VAT rates for multiple countries
INSERT INTO vat_rates (country_code, rate_percentage, effective_from, effective_to, description)
VALUES
  -- UK rates
  ('GB', 17.50, '1991-04-01', '2011-01-04', 'UK Standard VAT (17.5%) - Historical'),
  ('GB', 20.00, '2011-01-04', NULL, 'UK Standard VAT (20%) - Current'),

  -- US (no federal VAT)
  ('US', 0.00, '2000-01-01', NULL, 'US - No federal VAT/GST'),

  -- Germany
  ('DE', 19.00, '2007-01-01', NULL, 'Germany Standard VAT (19%)'),

  -- France
  ('FR', 20.00, '2014-01-01', NULL, 'France Standard VAT (20%)'),

  -- Scheduled rate (future)
  ('GB', 22.00, '2026-01-01', NULL, 'UK VAT increase (22%) - Scheduled')
ON CONFLICT (country_code, effective_from) DO NOTHING;
```

---

## Success Criteria

A complete test is successful when:

1. **CRUD Operations**
   - [x] Create, Read, Update, Delete all work
   - [x] Validation errors are clear
   - [x] Success/error toasts display

2. **Overlap Prevention**
   - [x] Overlapping rates rejected
   - [x] Error message explains conflict

3. **Snapshot Integration**
   - [x] Agreement approval captures VAT
   - [x] Snapshot includes all required fields
   - [x] Old snapshots unchanged when rates change

4. **RBAC**
   - [x] Admin users can perform all operations
   - [x] Non-admin users blocked from CUD operations
   - [x] Feature flag gates entire UI

5. **UI/UX**
   - [x] All sections display correctly
   - [x] Forms validate properly
   - [x] Dialogs open/close smoothly
   - [x] Loading states show
   - [x] Error messages are user-friendly

---

## Next Steps After Testing

1. **Enable Feature Flag**
   ```sql
   UPDATE feature_flags
   SET enabled = true, enabled_for_roles = ARRAY['admin']
   WHERE key = 'vat_admin';
   ```

2. **Grant Admin Roles**
   ```sql
   INSERT INTO user_roles (user_id, role)
   VALUES ('admin-user-id', 'admin')
   ON CONFLICT DO NOTHING;
   ```

3. **Monitor Usage**
   - Check logs for API errors
   - Monitor snapshot creation rate
   - Track VAT rate changes

4. **Document for Users**
   - Create user guide for VAT management
   - Document rate change procedures
   - Establish approval workflows

---

## Support

For issues or questions:
- Check `VAT_IMPLEMENTATION_SUMMARY.md` for architecture details
- Review migration `20251019100003_vat_and_snapshots.sql` for database schema
- Contact: [Your support channel]

**Test Status:** READY FOR TESTING
**Last Updated:** 2025-10-19
