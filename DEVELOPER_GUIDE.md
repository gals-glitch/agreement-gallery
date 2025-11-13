# Developer Quick Reference Guide

## Navigation Structure

### Sidebar Organization

The application sidebar is organized into 4 main sections:

#### 📊 DATA Section
Navigation items for data management:
```tsx
- Funds (Deals)      → /deals
- Parties            → /parties
- Investors          → /entities
- Contributions      → /contributions
- Fund VI Tracks     → /fund-vi/tracks
```

#### 🔄 WORKFLOW Section
Operational workflow items:
```tsx
- Agreements         → /parties
- Runs               → /runs
```

#### ⚙️ ADMIN Section
Admin-only features (role-gated):
```tsx
- Users & Roles      → /profile
- Settings           → /profile
- Feature Flags      → /profile
- VAT Settings       → /vat-settings (feature-flagged: vat_admin)
```

#### 📁 DOCS Section
Document management (feature-flagged):
```tsx
- Agreements (Docs)  → /documents (feature-flagged: docs_repository)
```

---

## Feature Flags

### How to Use Feature Flags in Components

```tsx
import { useFeatureFlag } from '@/hooks/useFeatureFlags';

function MyComponent() {
  const { isEnabled, isLoading } = useFeatureFlag('my_flag');

  if (isLoading) {
    return <Spinner />;
  }

  if (!isEnabled) {
    return null; // or fallback UI
  }

  return <FeatureContent />;
}
```

### Using FeatureGuard for Routes

```tsx
import { FeatureGuard } from '@/components/FeatureGuard';

<Route
  path="/my-feature"
  element={
    <ProtectedRoute>
      <FeatureGuard flag="my_feature" fallback={<NotFound />}>
        <MyFeaturePage />
      </FeatureGuard>
    </ProtectedRoute>
  }
/>
```

### Using FeatureGuard for UI Elements

```tsx
import { FeatureGuard } from '@/components/FeatureGuard';

<FeatureGuard flag="advanced_filters">
  <AdvancedFiltersPanel />
</FeatureGuard>
```

---

## Adding New Sidebar Items

### 1. Add to Appropriate Section Array

In `src/components/AppSidebar.tsx`:

```tsx
// For DATA section
const dataItems = [
  // ...existing items
  {
    title: "My New Feature",
    url: "/my-feature",
    icon: MyIcon,
    description: "Brief description",
    featureFlag: "my_feature_flag" // Optional
  }
];
```

### 2. Add Route to App.tsx

```tsx
// In src/App.tsx
import MyFeaturePage from "./pages/MyFeature";

// In router array:
{
  path: "/my-feature",
  element: (
    <ProtectedRoute requiredRoles={['admin', 'finance']}>
      <FeatureGuard flag="my_feature_flag" fallback={<NotFound />}>
        <MyFeaturePage />
      </FeatureGuard>
    </ProtectedRoute>
  )
}
```

### 3. Create the Page Component

```tsx
// src/pages/MyFeature.tsx
import { SidebarProvider, SidebarTrigger } from '@/components/ui/sidebar';
import { AppSidebar } from '@/components/AppSidebar';

export default function MyFeaturePage() {
  return (
    <SidebarProvider>
      <div className="min-h-screen w-full flex bg-background">
        <AppSidebar />

        <div className="flex-1 flex flex-col">
          {/* Header */}
          <div className="sticky top-0 z-20 bg-background/80 backdrop-blur border-b">
            <div className="px-4 py-3 flex items-center gap-3">
              <SidebarTrigger />
              <h1 className="text-lg font-semibold">My Feature</h1>
            </div>
          </div>

          {/* Main content */}
          <main className="flex-1 p-6">
            {/* Your content here */}
          </main>
        </div>
      </div>
    </SidebarProvider>
  );
}
```

---

## Role-Based Access Control

### Available Roles
- `admin` - Full system access
- `finance` - Financial operations
- `ops` - Operational tasks
- `legal` - Legal review
- `viewer` - Read-only access
- `auditor` - Audit access

### Using Role Checks

```tsx
import { useAuth } from '@/hooks/useAuth';

function MyComponent() {
  const { isAdmin, hasRole, hasAnyRole } = useAuth();

  // Check if user is admin
  if (isAdmin()) {
    return <AdminPanel />;
  }

  // Check specific role
  if (hasRole('finance')) {
    return <FinancePanel />;
  }

  // Check multiple roles
  if (hasAnyRole(['finance', 'ops'])) {
    return <OperationsPanel />;
  }

  return <ViewerPanel />;
}
```

### Protected Routes

```tsx
<ProtectedRoute requiredRoles={['admin', 'finance']}>
  <SensitivePage />
</ProtectedRoute>
```

---

## Fund VI Tracks Integration

### Displaying Track Information

```tsx
import { FundVITrackBanner } from '@/components/FundVITrackBanner';

// In your agreement form:
<form>
  <FundVITrackBanner
    fundId={agreement.fund_id}
    trackKey={agreement.track_key} // 'A', 'B', or 'C'
    className="mb-4"
  />

  {/* Rest of form */}
</form>
```

### Compact Banner Variant

```tsx
import { FundVITrackBannerCompact } from '@/components/FundVITrackBanner';

<FundVITrackBannerCompact
  fundId={agreement.fund_id}
  trackKey="A"
/>
```

### Fetching Track Data Directly

```tsx
import { useFundTracks } from '@/hooks/useFundTracks';

function MyComponent() {
  const { tracks, isLoading, error } = useFundTracks();

  if (isLoading) return <Spinner />;
  if (error) return <Error />;

  const trackA = tracks?.find(t => t.track_key === 'A');

  return (
    <div>
      Upfront Rate: {trackA.upfront_rate_bps} bps
    </div>
  );
}
```

---

## Common Patterns

### Standard Page Layout

```tsx
<SidebarProvider>
  <div className="min-h-screen w-full flex bg-background">
    <AppSidebar />

    <div className="flex-1 flex flex-col">
      {/* Sticky header */}
      <div className="sticky top-0 z-20 bg-background/80 backdrop-blur border-b">
        <div className="px-4 py-3 flex items-center gap-3">
          <SidebarTrigger />
          <Button variant="ghost" size="sm" onClick={() => navigate('/')}>
            <ArrowLeft className="w-4 h-4 mr-2" />
            Back
          </Button>
          <h1 className="text-lg font-semibold">Page Title</h1>
        </div>
      </div>

      {/* Scrollable main content */}
      <main className="flex-1 p-6">
        <div className="max-w-6xl mx-auto">
          {/* Content */}
        </div>
      </main>
    </div>
  </div>
</SidebarProvider>
```

### Loading States

```tsx
if (isLoading) {
  return (
    <div className="flex items-center justify-center p-8">
      <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
    </div>
  );
}
```

### Empty States

```tsx
if (!data || data.length === 0) {
  return (
    <div className="text-center py-12 text-muted-foreground">
      <Icon className="w-12 h-12 mx-auto mb-4 opacity-50" />
      <p className="text-lg font-medium mb-2">No Items Found</p>
      <p className="text-sm">Create your first item to get started.</p>
      <Button className="mt-4">Create Item</Button>
    </div>
  );
}
```

### Error States

```tsx
if (error) {
  return (
    <Alert variant="destructive">
      <AlertCircle className="h-4 w-4" />
      <AlertTitle>Error</AlertTitle>
      <AlertDescription>{error.message}</AlertDescription>
    </Alert>
  );
}
```

---

## Styling Guidelines

### Color-Coded Elements

Use consistent color coding for different entity types:

```tsx
// Track colors (Fund VI)
const trackColors = {
  A: 'border-blue-500 bg-blue-50 dark:bg-blue-950',
  B: 'border-green-500 bg-green-50 dark:bg-green-950',
  C: 'border-purple-500 bg-purple-50 dark:bg-purple-950',
};

// Status colors
const statusColors = {
  active: 'bg-green-500',
  pending: 'bg-yellow-500',
  archived: 'bg-gray-500',
  error: 'bg-red-500',
};
```

### Responsive Grid Layouts

```tsx
{/* 3 columns on desktop, 2 on tablet, 1 on mobile */}
<div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
  {items.map(item => <Card key={item.id}>{/* ... */}</Card>)}
</div>
```

### Icon Sizing

```tsx
{/* Header icons */}
<Icon className="w-5 h-5" />

{/* Card/button icons */}
<Icon className="w-4 h-4" />

{/* Large decorative icons */}
<Icon className="w-12 h-12" />
```

---

## Data Formatting

### Currency

```tsx
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

### Basis Points

```tsx
const formatBps = (bps: number): string => {
  return `${(bps / 100).toFixed(2)}%`;
};
```

### Dates

```tsx
const formatDate = (dateString: string): string => {
  return new Date(dateString).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });
};
```

---

## Testing Considerations

### Feature Flag Testing

Always test both states:
1. Flag OFF - feature should be hidden/inaccessible
2. Flag ON - feature should be visible/accessible

### Role-Based Testing

Test with different user roles:
1. Admin - should see all features
2. Finance - should see finance features only
3. Viewer - should have limited access

### Responsive Testing

Test at breakpoints:
- Mobile: < 768px
- Tablet: 768px - 1024px
- Desktop: > 1024px

---

## Accessibility Checklist

- [ ] All interactive elements keyboard accessible
- [ ] Proper heading hierarchy (h1, h2, h3)
- [ ] ARIA labels for icons and buttons
- [ ] Focus indicators visible
- [ ] Color contrast meets WCAG AA
- [ ] Screen reader tested
- [ ] Form labels properly associated
- [ ] Error messages descriptive

---

## Common Gotchas

1. **Feature flags cache for 5 minutes** - Use force refresh if testing flag changes
2. **Sidebar state persists in cookie** - Clear cookies if sidebar behaves oddly
3. **Route protection is layered** - Both ProtectedRoute AND FeatureGuard may be needed
4. **Fund VI detection uses string matching** - Will need proper fund type lookup later
5. **Dark mode affects color classes** - Always include dark: variants

---

## Quick Commands

```bash
# Start dev server
npm run dev

# Build for production
npm run build

# Run linter
npm run lint

# Format code
npm run format

# Type check
npm run type-check
```

---

## Support Resources

- **Feature Flags:** See `STREAM_4_5_IMPLEMENTATION.md`
- **API Documentation:** See `/docs/api`
- **Component Library:** shadcn-ui docs
- **Database Schema:** See `/docs/schema`
