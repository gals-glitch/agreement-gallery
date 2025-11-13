# Frontend Integration Quick Start

**Version:** 1.0
**Audience:** Frontend Developers
**Time:** 5-minute read

---

## 🚀 Setup (One-Time)

### **1. Environment Variable**
Add to `.env`:
```bash
VITE_API_V1_BASE_URL=https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/api-v1
```

### **2. Import API Client**
```typescript
import { partiesAPI, fundsAPI, dealsAPI, agreementsAPI, runsAPI } from '@/api/clientV2';
```

### **3. Import Types**
```typescript
import type { Agreement, AgreementStatus, CreateAgreementRequest } from '@/types/api';
```

---

## 📦 Common Patterns

### **List with Pagination**
```typescript
const { items, total } = await partiesAPI.list({
  active: true,
  limit: 50,
  offset: 0,
});
```

### **Create Resource**
```typescript
const { id } = await agreementsAPI.create({
  party_id: 1,
  scope: 'FUND',
  fund_id: 1,
  pricing_mode: 'TRACK',
  selected_track: 'B',
  effective_from: '2025-07-01',
  vat_included: false,
});
```

### **Workflow Actions**
```typescript
// Submit for approval
await agreementsAPI.submit(id);

// Approve (requires manager role)
await agreementsAPI.approve(id);

// Create amendment
const { new_agreement_id } = await agreementsAPI.amend(id);
```

### **Error Handling**
```typescript
try {
  await agreementsAPI.approve(id);
} catch (error) {
  if (error.message.includes('Unauthorized')) {
    toast({ title: 'Permission Denied', description: 'You need manager role' });
  } else if (error.message.includes('not awaiting approval')) {
    toast({ title: 'Invalid State', description: 'Agreement must be submitted first' });
  } else {
    toast({ title: 'Error', description: error.message });
  }
}
```

---

## 🎨 UI Component Guidelines

### **AgreementForm - Key Rules**

#### **1. Scope Picker**
```tsx
<Select
  value={scope}
  onValueChange={setScope}
  disabled={hasApprovalHistory}  // ← Disable after any approval
>
  <SelectItem value="FUND">Fund-Level</SelectItem>
  <SelectItem value="DEAL">Deal-Level</SelectItem>
</Select>
```

#### **2. Pricing Mode Picker**
```tsx
<Select
  value={pricingMode}
  onValueChange={setPricingMode}
  disabled={scope === 'FUND' || hasApprovalHistory}  // ← FUND must use TRACK
>
  <SelectItem value="TRACK">Track-Based</SelectItem>
  <SelectItem value="CUSTOM" disabled={scope === 'FUND'}>
    Custom Rates (Deal Only)
  </SelectItem>
</Select>
```

#### **3. Track Selector (Track Mode)**
```tsx
{pricingMode === 'TRACK' && (
  <div>
    <Select value={selectedTrack} onValueChange={setSelectedTrack}>
      {tracks.map(track => (
        <SelectItem key={track.track_code} value={track.track_code}>
          Track {track.track_code}
        </SelectItem>
      ))}
    </Select>

    {/* Read-only rates display */}
    {selectedTrack && (
      <Alert>
        <InfoIcon className="h-4 w-4" />
        <AlertDescription>
          Rates derived from Track {selectedTrack} (read-only).
          Upfront: {currentTrack.upfront_bps} bps, Deferred: {currentTrack.deferred_bps} bps.
          To change, create an amendment.
        </AlertDescription>
      </Alert>
    )}
  </div>
)}
```

#### **4. Custom Rates Input (Custom Mode - Deal Only)**
```tsx
{pricingMode === 'CUSTOM' && scope === 'DEAL' && (
  <div>
    <Label>Upfront Rate (bps)</Label>
    <Input
      type="number"
      value={customUpfrontBps}
      onChange={(e) => setCustomUpfrontBps(parseInt(e.target.value))}
      disabled={status !== 'DRAFT'}
    />

    <Label>Deferred Rate (bps)</Label>
    <Input
      type="number"
      value={customDeferredBps}
      onChange={(e) => setCustomDeferredBps(parseInt(e.target.value))}
      disabled={status !== 'DRAFT'}
    />
  </div>
)}
```

#### **5. Status Ribbon**
```tsx
<div className="flex items-center gap-2">
  <Badge variant={getStatusVariant(status)}>
    {status}
  </Badge>

  {status === 'DRAFT' && (
    <Button onClick={() => agreementsAPI.submit(id)}>
      Submit for Approval
    </Button>
  )}

  {status === 'AWAITING_APPROVAL' && canApprove && (
    <>
      <Button onClick={() => agreementsAPI.approve(id)}>
        Approve
      </Button>
      <Button variant="outline" onClick={() => handleReject()}>
        Reject
      </Button>
    </>
  )}

  {status === 'APPROVED' && (
    <Button onClick={() => agreementsAPI.amend(id)}>
      Create Amendment
    </Button>
  )}
</div>
```

#### **6. Snapshot Panel (After Approval)**
```tsx
{status === 'APPROVED' && agreement.snapshot && (
  <Card>
    <CardHeader>
      <CardTitle>Rate Snapshot (Locked)</CardTitle>
    </CardHeader>
    <CardContent>
      <dl>
        <dt>Upfront Rate:</dt>
        <dd>{agreement.snapshot.resolved_upfront_bps} bps</dd>

        <dt>Deferred Rate:</dt>
        <dd>{agreement.snapshot.resolved_deferred_bps} bps</dd>

        <dt>Seed Version:</dt>
        <dd>{agreement.snapshot.seed_version}</dd>

        <dt>Approved At:</dt>
        <dd>{formatDate(agreement.snapshot.approved_at)}</dd>
      </dl>
    </CardContent>
  </Card>
)}
```

---

### **DealsForm - Read-Only Scoreboard Fields**

```tsx
{/* Read-only fields */}
<div className="grid grid-cols-2 gap-4">
  <div>
    <Label>Equity to Raise (Read-Only)</Label>
    <Input
      value={formatCurrency(deal.equity_to_raise)}
      disabled
      className="bg-muted"
    />
    <p className="text-xs text-muted-foreground">
      Updated via CSV scoreboard import
    </p>
  </div>

  <div>
    <Label>Raised So Far (Read-Only)</Label>
    <Input
      value={formatCurrency(deal.raised_so_far)}
      disabled
      className="bg-muted"
    />
  </div>
</div>

{/* Editable toggle */}
<div className="flex items-center gap-2">
  <Switch
    checked={deal.exclude_gp_from_commission}
    onCheckedChange={(checked) => updateDeal({ exclude_gp_from_commission: checked })}
  />
  <Label>Exclude GP from commission</Label>
</div>
```

---

### **RunsPage - Approval Workflow**

```tsx
<div className="flex items-center gap-2">
  <Badge variant={getRunStatusVariant(run.status)}>
    {run.status.replace('_', ' ')}
  </Badge>

  {run.status === 'DRAFT' && (
    <Button onClick={() => runsAPI.submit(run.id)}>
      Submit for Approval
    </Button>
  )}

  {run.status === 'AWAITING_APPROVAL' && canApprove && (
    <>
      <Button onClick={() => runsAPI.approve(run.id)}>
        Approve
      </Button>
      <Button variant="outline" onClick={() => handleReject()}>
        Reject
      </Button>
    </>
  )}

  {run.status === 'APPROVED' && (
    <Button
      onClick={() => runsAPI.generate(run.id)}
      disabled={isGenerating}
    >
      {isGenerating ? 'Generating...' : 'Generate Calculation'}
    </Button>
  )}
</div>
```

---

## 🎭 Status Badge Variants

```typescript
function getStatusVariant(status: AgreementStatus): string {
  switch (status) {
    case 'DRAFT': return 'secondary';
    case 'AWAITING_APPROVAL': return 'warning';
    case 'APPROVED': return 'success';
    case 'SUPERSEDED': return 'outline';
    default: return 'default';
  }
}
```

---

## 🔒 RBAC Helper

```typescript
import { useAuth } from '@/hooks/useAuth';

function useCanApprove() {
  const { user, roles } = useAuth();
  return roles.includes('manager') || roles.includes('admin');
}

// Usage in component
const canApprove = useCanApprove();

<Button
  onClick={() => agreementsAPI.approve(id)}
  disabled={!canApprove}
>
  {canApprove ? 'Approve' : 'Requires Manager Role'}
</Button>
```

---

## 🚨 Guard Logic (Disable Edits After Approval)

```typescript
const hasApprovalHistory = useMemo(() => {
  return agreement.status !== 'DRAFT';
}, [agreement.status]);

// Disable ALL form inputs when hasApprovalHistory = true
<Input disabled={hasApprovalHistory} />
<Select disabled={hasApprovalHistory} />
```

---

## 📊 Common Queries

### **Get Tracks for Fund**
```typescript
const tracks = await fundTracksAPI.list(fundId);

// Display in dropdown
<Select>
  {tracks.map(track => (
    <SelectItem key={track.track_code} value={track.track_code}>
      Track {track.track_code} - {track.upfront_bps}bps / {track.deferred_bps}bps
    </SelectItem>
  ))}
</Select>
```

### **Get Agreement with Snapshot**
```typescript
const agreement = await agreementsAPI.get(id);

if (agreement.snapshot) {
  // Display locked rates
  console.log('Locked Upfront:', agreement.snapshot.resolved_upfront_bps);
  console.log('Locked Deferred:', agreement.snapshot.resolved_deferred_bps);
}
```

### **Filter Agreements by Party**
```typescript
const { items } = await agreementsAPI.list({
  party_id: partyId,
  status: 'APPROVED',
});
```

---

## ⚠️ Common Mistakes

### **❌ Don't:**
```typescript
// Don't call API without await
agreementsAPI.submit(id); // Missing await!

// Don't allow FUND + CUSTOM
if (scope === 'FUND' && pricingMode === 'CUSTOM') {
  // This will fail API validation - prevent it in UI
}

// Don't forget to handle 403 on approve
await agreementsAPI.approve(id); // May throw 403 if user lacks permission
```

### **✅ Do:**
```typescript
// Always await API calls
await agreementsAPI.submit(id);

// Disable CUSTOM for FUND scope
<SelectItem value="CUSTOM" disabled={scope === 'FUND'}>

// Handle RBAC errors gracefully
try {
  await agreementsAPI.approve(id);
} catch (error) {
  if (error.message.includes('Unauthorized')) {
    showToast('Permission denied - requires manager role');
  }
}
```

---

## 🧪 Testing Helpers

### **Mock API Client (Vitest)**
```typescript
vi.mock('@/api/clientV2', () => ({
  agreementsAPI: {
    create: vi.fn().mockResolvedValue({ id: 1 }),
    submit: vi.fn().mockResolvedValue({ status: 'AWAITING_APPROVAL' }),
    approve: vi.fn().mockResolvedValue({ status: 'APPROVED' }),
  },
}));
```

### **Test RBAC Logic**
```typescript
it('disables approve button for non-managers', () => {
  const { getByText } = render(<AgreementForm />, {
    user: { roles: ['ops'] } // Not manager
  });

  const approveBtn = getByText('Approve');
  expect(approveBtn).toBeDisabled();
});
```

---

## 📞 Quick Support

- **API returns 404:** Check `VITE_API_V1_BASE_URL` is set
- **CORS error:** Verify Edge Function deployed
- **403 on approve:** User needs `manager` or `admin` role
- **400 "FUND must use TRACK":** Check scope/pricing logic in form
- **Snapshot missing:** Agreement not approved yet

---

## 🎯 Checklist Before PR

- [ ] Scope/pricing pickers disabled after approval
- [ ] Track mode shows read-only rates banner
- [ ] Custom rates only available for DEAL scope
- [ ] Scoreboard fields (equity_to_raise) disabled
- [ ] Generate button only enabled when status=APPROVED
- [ ] RBAC check for approve/reject buttons
- [ ] Error handling for 403/400/404
- [ ] Loading states for async actions
- [ ] Success/error toasts
- [ ] Snapshot panel displayed for APPROVED agreements

---

_Quick Start Version: 1.0_
_Last Updated: 2025-10-16_
