# Stream 4 & 5 Implementation Guide

## Overview
This document covers the implementation of:
- **Stream 4:** Sidebar/routing reorganization with feature flag guards
- **Stream 5:** Fund VI Tracks read-only display page

Implementation Date: 2025-10-19
Status: Complete

---

## Stream 4: Sidebar/Routing Polish

### Changes Made

#### 1. Sidebar Reorganization (`src/components/AppSidebar.tsx`)

**New Structure:**
```
📊 DATA
  - Funds (Deals)
  - Parties
  - Investors
  - Contributions
  - Fund VI Tracks

🔄 WORKFLOW
  - Agreements
  - Runs

⚙️ ADMIN (admin-only)
  - Users & Roles
  - Settings
  - Feature Flags
  - VAT Settings (flag: vat_admin)

📁 DOCS (flag: docs_repository)
  - Agreements (Docs)
```

**Key Features:**
- Logical grouping of navigation items by function
- Visual section headers with icons
- Role-based visibility (ADMIN section only for admins)
- Feature flag guards for VAT Settings and Docs Repository
- Responsive design with collapse support

#### 2. Feature Flag Guards

**Sidebar Implementation:**
```tsx
function SidebarNavItem({ item, state, getNavClass }) {
  const { isEnabled } = useFeatureFlag(item.featureFlag || '');

  // If feature flag is specified and not enabled, don't render
  if (item.featureFlag && !isEnabled) {
    return null;
  }

  return (
    <SidebarMenuItem>
      <NavLink to={item.url}>
        {/* Navigation content */}
      </NavLink>
    </SidebarMenuItem>
  );
}
```

**Route Guards (`src/App.tsx`):**
```tsx
// Feature-flagged routes
{
  path: "/vat-settings",
  element: (
    <ProtectedRoute requiredRoles={['admin']}>
      <FeatureGuard flag="vat_admin" fallback={<NotFound />}>
        <VATSettingsPage />
      </FeatureGuard>
    </ProtectedRoute>
  )
},
{
  path: "/documents",
  element: (
    <ProtectedRoute>
      <FeatureGuard flag="docs_repository" fallback={<NotFound />}>
        <DocumentsPage />
      </FeatureGuard>
    </ProtectedRoute>
  )
}
```

#### 3. New Pages Created

**VAT Settings Page (`src/pages/VATSettings.tsx`)**
- Placeholder page for VAT rate configuration
- Only accessible when `vat_admin` flag is ON
- Admin-only route protection

**Documents Repository Page (`src/pages/Documents.tsx`)**
- Placeholder for document management interface
- Only accessible when `docs_repository` flag is ON
- Features planned: search, PDF viewer, version control

---

## Stream 5: Fund VI Tracks (Read-Only Display)

### Changes Made

#### 1. Read-Only Component (`src/components/FundVITracksAdmin.tsx`)

**Key Features:**
- Complete rewrite from editable to read-only
- Lock icon indicators throughout UI
- Info banner explaining modification process
- Color-coded track cards (A=blue, B=green, C=purple)
- Formatted display of rates and thresholds
- Configuration metadata card

**Data Displayed:**
- Track name (A/B/C)
- Upfront rate (in bps and %)
- Deferred rate (in bps and %)
- Deferred offset (months)
- Min/Max capital raised
- Configuration version
- Active status

**UI Enhancements:**
```tsx
// Color scheme per track
const trackColors = {
  A: 'border-blue-500 bg-blue-50 dark:bg-blue-950',
  B: 'border-green-500 bg-green-50 dark:bg-green-950',
  C: 'border-purple-500 bg-purple-50 dark:bg-purple-950',
};

// Currency formatting
const formatCurrency = (value: number | null): string => {
  if (value === null) return '∞';
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(value);
};
```

#### 2. Fund VI Track Banner (`src/components/FundVITrackBanner.tsx`)

**Purpose:** Show track information on agreement forms when Fund VI is selected.

**Features:**
- Auto-detects Fund VI from fundId
- Displays applicable track rates
- Links to track configuration page
- Compact variant for smaller spaces

**Usage Example:**
```tsx
import { FundVITrackBanner } from '@/components/FundVITrackBanner';

// In agreement form:
<FundVITrackBanner
  fundId={selectedFundId}
  trackKey="A"
  className="mb-4"
/>
```

#### 3. Fund VI Tracks Page (`src/pages/FundVITracks.tsx`)

**Route:** `/fund-vi/tracks`
- Protected route (finance + admin only)
- Consistent page layout with sidebar
- Breadcrumb navigation
- Renders `FundVITracksAdmin` component

---

## Feature Flags

### Required Flags

| Flag Key | Description | Default | Routes Affected |
|----------|-------------|---------|-----------------|
| `vat_admin` | VAT Settings admin interface | OFF | `/vat-settings` |
| `docs_repository` | Document repository system | OFF | `/documents` |

### How to Enable/Disable

**Using Supabase:**
```sql
-- Enable VAT admin for all admins
UPDATE feature_flags
SET enabled = true, enabled_for_roles = ARRAY['admin']
WHERE key = 'vat_admin';

-- Enable docs repository for everyone
UPDATE feature_flags
SET enabled = true, enabled_for_roles = NULL, rollout_percentage = 100
WHERE key = 'docs_repository';
```

**Frontend Check:**
```tsx
import { useFeatureFlag } from '@/hooks/useFeatureFlags';

const { isEnabled } = useFeatureFlag('vat_admin');
if (isEnabled) {
  // Show VAT Settings
}
```

---

## Testing Checklist

### Stream 4: Sidebar & Routing

- [ ] **Sidebar Structure**
  - [ ] DATA section displays with all items
  - [ ] WORKFLOW section displays with all items
  - [ ] ADMIN section only visible to admin users
  - [ ] DOCS section hidden when `docs_repository` flag is OFF
  - [ ] Section icons render correctly
  - [ ] Sidebar collapses/expands properly
  - [ ] Active route highlighted correctly

- [ ] **Feature Flag Guards**
  - [ ] VAT Settings menu item hidden when `vat_admin` flag OFF
  - [ ] VAT Settings menu item visible when `vat_admin` flag ON (admin only)
  - [ ] Agreements (Docs) hidden when `docs_repository` flag OFF
  - [ ] Agreements (Docs) visible when `docs_repository` flag ON
  - [ ] Direct URL access to `/vat-settings` redirects to 404 when flag OFF
  - [ ] Direct URL access to `/documents` redirects to 404 when flag OFF

- [ ] **Route Protection**
  - [ ] Non-admin users cannot access `/vat-settings`
  - [ ] All users can access `/documents` when flag is ON
  - [ ] 404 page displays for invalid routes
  - [ ] No console errors on navigation

- [ ] **Responsive Behavior**
  - [ ] Sidebar works on mobile (sheet mode)
  - [ ] Sidebar works on tablet
  - [ ] Sidebar works on desktop
  - [ ] Icons and labels display correctly when collapsed

### Stream 5: Fund VI Tracks

- [ ] **Data Display**
  - [ ] All 3 tracks (A, B, C) load and display
  - [ ] Track cards show correct color borders
  - [ ] Upfront rates display correctly (bps and %)
  - [ ] Deferred rates display correctly (bps and %)
  - [ ] Offset months display correctly
  - [ ] Min/Max raised amounts format properly
  - [ ] Configuration version displays
  - [ ] Status badge shows "Active"

- [ ] **Read-Only State**
  - [ ] No input fields present
  - [ ] No save/edit buttons present
  - [ ] Lock icons visible on cards
  - [ ] Info banner displays with correct message
  - [ ] All data is display-only

- [ ] **Responsive Layout**
  - [ ] 3-column grid on desktop
  - [ ] Stacks on mobile
  - [ ] Cards remain readable at all sizes
  - [ ] Text doesn't overflow

- [ ] **Navigation**
  - [ ] Route `/fund-vi/tracks` accessible
  - [ ] Back button navigates to home
  - [ ] Sidebar integration works
  - [ ] Direct URL access works

- [ ] **Banner Component**
  - [ ] Banner displays when fund is Fund VI
  - [ ] Banner hidden for non-Fund VI funds
  - [ ] Track rates display correctly
  - [ ] Link to tracks page works
  - [ ] Compact variant renders properly

---

## Manual Testing Steps

### 1. Test Feature Flag Toggling

```bash
# In Supabase SQL Editor:

-- 1. Disable vat_admin flag
UPDATE feature_flags SET enabled = false WHERE key = 'vat_admin';

-- Expected: "VAT Settings" disappears from ADMIN section
-- Expected: /vat-settings route returns 404

-- 2. Enable vat_admin flag for admins only
UPDATE feature_flags SET enabled = true, enabled_for_roles = ARRAY['admin'] WHERE key = 'vat_admin';

-- Expected: "VAT Settings" appears in ADMIN section (admin only)
-- Expected: /vat-settings route accessible (admin only)

-- 3. Test docs_repository flag
UPDATE feature_flags SET enabled = true WHERE key = 'docs_repository';

-- Expected: "Agreements (Docs)" appears in sidebar
-- Expected: /documents route accessible
```

### 2. Test Role-Based Access

1. **As Admin:**
   - Navigate to sidebar
   - Verify ADMIN section visible
   - Verify all 4 admin items visible (when flags ON)
   - Click "VAT Settings" - should navigate successfully
   - Click "Feature Flags" - should navigate successfully

2. **As Finance User:**
   - Navigate to sidebar
   - Verify ADMIN section NOT visible
   - Verify no access to `/vat-settings` (even with flag ON)

3. **As Viewer:**
   - Verify limited navigation options
   - Verify no admin routes accessible

### 3. Test Fund VI Tracks Page

1. Navigate to `/fund-vi/tracks`
2. Verify:
   - Lock icon in header
   - Info banner displays
   - 3 cards display (A, B, C)
   - Each card has color border
   - All rates display correctly
   - No edit controls present
3. Test responsive:
   - Resize to mobile - cards should stack
   - Resize to tablet - cards should adjust
   - Resize to desktop - 3-column grid

### 4. Test Fund VI Banner Integration

1. Open agreement form (when implemented)
2. Select Fund VI from fund dropdown
3. Verify banner appears with track info
4. Click "View configurations" link
5. Verify navigation to `/fund-vi/tracks`

---

## File Changes Summary

### Modified Files
- `src/App.tsx` - Added routes with FeatureGuard wrappers
- `src/components/AppSidebar.tsx` - Complete reorganization with sections
- `src/components/FundVITracksAdmin.tsx` - Converted to read-only display
- `src/pages/FundVITracks.tsx` - Updated with new component

### New Files
- `src/pages/VATSettings.tsx` - VAT admin placeholder page
- `src/pages/Documents.tsx` - Document repository placeholder page
- `src/components/FundVITrackBanner.tsx` - Banner component for forms

### Dependencies
- No new dependencies required
- Uses existing: `useFeatureFlag`, `useAuth`, shadcn-ui components

---

## Accessibility Notes

### Keyboard Navigation
- All sidebar items keyboard accessible
- Focus management in sidebar collapse/expand
- Proper tab order maintained

### Screen Readers
- Section labels announced correctly
- Lock icons have descriptive titles
- Alert banners have proper ARIA labels
- Links have descriptive text

### Color Contrast
- Track color borders meet WCAG AA standards
- Text remains readable on colored backgrounds
- Dark mode support included

---

## Known Limitations

1. **Fund VI Detection:** Currently uses string matching on fundId. Should be replaced with proper fund type lookup.
2. **Backend Endpoint:** No dedicated API endpoint created (using direct Supabase query). Consider creating `/api-v1/fund-vi/tracks` for consistency.
3. **Placeholder Pages:** VAT Settings and Documents pages are placeholders only.
4. **Banner Integration:** FundVITrackBanner needs to be manually integrated into agreement forms.

---

## Future Enhancements

### Stream 4
- [ ] Add search/filter to sidebar
- [ ] Implement recently visited pages
- [ ] Add keyboard shortcuts panel
- [ ] Implement user preferences for sidebar state

### Stream 5
- [ ] Add track comparison view
- [ ] Implement track history/audit log
- [ ] Add export functionality for track configurations
- [ ] Create track versioning system

---

## Rollback Instructions

If issues arise, rollback in this order:

1. **Disable Feature Flags:**
```sql
UPDATE feature_flags SET enabled = false WHERE key IN ('vat_admin', 'docs_repository');
```

2. **Revert Code Changes:**
```bash
git revert <commit-hash>  # Revert sidebar changes
git revert <commit-hash>  # Revert route changes
```

3. **Remove New Routes:**
- Comment out `/vat-settings` and `/documents` routes in App.tsx
- Sidebar will gracefully hide disabled items

---

## Support & Troubleshooting

### Issue: Feature flags not updating
**Solution:** Check browser cache. Feature flags cache for 5 minutes. Force refresh or wait.

### Issue: Sidebar items not appearing
**Solution:**
1. Check user role in database
2. Verify feature flag status
3. Clear browser localStorage
4. Check console for errors

### Issue: Fund VI tracks not loading
**Solution:**
1. Verify `fund_vi_tracks` table has data
2. Check Supabase RLS policies
3. Verify user has read access
4. Check network tab for errors

---

## Performance Considerations

- Feature flags cached for 5 minutes
- Sidebar renders only visible items
- Fund VI tracks query optimized with `.order()`
- No unnecessary re-renders on flag changes

---

## Security Notes

- Route protection layered: ProtectedRoute + FeatureGuard
- Admin-only routes enforce role check
- Feature flags respect role-based enablement
- Direct URL access blocked when flags disabled

---

## Contact

For questions or issues:
- Frontend Lead: [Your Name]
- Feature Flags: See ORC-001 documentation
- Fund VI Tracks: See database schema docs
