# Color Palette & Design System
**Application**: Agreement Gallery / Commission Management System
**Date**: November 11, 2025
**Design System**: shadcn/ui + Tailwind CSS

---

## Brand Colors

### Primary - Navy Blue
**Usage**: Primary actions, headers, links, focus states

| Variant | HSL | RGB | Hex | Usage |
|---------|-----|-----|-----|-------|
| Navy Blue | `212° 84% 19%` | `rgb(8, 39, 88)` | `#082758` | Primary buttons, main navigation |
| Navy Light | `212° 70% 30%` | `rgb(23, 57, 115)` | `#173973` | Hover states, secondary elements |

**Tailwind Classes**: `bg-primary`, `text-primary`, `border-primary`, `bg-custom-navy`

**CSS Variable**: `--navy-blue`, `--navy-light`

---

### Secondary - Golden Yellow
**Usage**: Accents, highlights, call-to-action elements

| Variant | HSL | RGB | Hex | Usage |
|---------|-----|-----|-----|-------|
| Golden Yellow | `49° 96% 51%` | `rgb(252, 203, 5)` | `#fccb05` | Secondary buttons, badges, highlights |
| Golden Light | `49° 96% 70%` | `rgb(253, 219, 102)` | `#fddb66` | Hover states, light accents |

**Tailwind Classes**: `bg-secondary`, `text-secondary`, `border-secondary`, `bg-custom-golden`

**CSS Variable**: `--golden-yellow`, `--golden-light`

---

## Semantic Colors (Light Mode)

### Background & Surfaces

| Color | HSL | RGB | Hex | Usage |
|-------|-----|-----|-----|-------|
| Background | `0° 0% 100%` | `rgb(255, 255, 255)` | `#ffffff` | Main page background |
| Card | `0° 0% 98%` | `rgb(250, 250, 250)` | `#fafafa` | Card backgrounds |
| Popover | `0° 0% 100%` | `rgb(255, 255, 255)` | `#ffffff` | Dropdown, tooltip backgrounds |
| Muted | `0° 0% 96%` | `rgb(245, 245, 245)` | `#f5f5f5` | Disabled states, subtle backgrounds |
| Input | `0° 0% 96%` | `rgb(245, 245, 245)` | `#f5f5f5` | Form input backgrounds |

**Tailwind Classes**: `bg-background`, `bg-card`, `bg-popover`, `bg-muted`, `bg-input`

---

### Text & Foreground

| Color | HSL | RGB | Hex | Usage |
|-------|-----|-----|-----|-------|
| Foreground | `212° 84% 19%` | `rgb(8, 39, 88)` | `#082758` | Primary text |
| Card Foreground | `212° 84% 19%` | `rgb(8, 39, 88)` | `#082758` | Text on cards |
| Muted Foreground | `212° 50% 45%` | `rgb(58, 90, 173)` | `#3a5aad` | Secondary text, hints |
| Primary Foreground | `0° 0% 100%` | `rgb(255, 255, 255)` | `#ffffff` | Text on primary buttons |
| Secondary Foreground | `212° 84% 19%` | `rgb(8, 39, 88)` | `#082758` | Text on secondary buttons |

**Tailwind Classes**: `text-foreground`, `text-card-foreground`, `text-muted-foreground`

---

### Interactive Elements

| Color | HSL | RGB | Hex | Usage |
|-------|-----|-----|-----|-------|
| Primary | `212° 84% 19%` | `rgb(8, 39, 88)` | `#082758` | Primary buttons, links |
| Secondary | `49° 96% 51%` | `rgb(252, 203, 5)` | `#fccb05` | Secondary buttons |
| Accent | `212° 84% 19%` | `rgb(8, 39, 88)` | `#082758` | Accent elements |
| Border | `0° 0% 90%` | `rgb(230, 230, 230)` | `#e6e6e6` | Borders, dividers |
| Ring | `212° 84% 19%` | `rgb(8, 39, 88)` | `#082758` | Focus rings |

**Tailwind Classes**: `bg-primary`, `bg-secondary`, `bg-accent`, `border`, `ring`

---

### Feedback & Status

| Color | HSL | RGB | Hex | Usage |
|-------|-----|-----|-----|-------|
| Destructive | `0° 84% 60%` | `rgb(235, 61, 61)` | `#eb3d3d` | Error states, delete actions |
| Destructive Foreground | `0° 0% 98%` | `rgb(250, 250, 250)` | `#fafafa` | Text on destructive buttons |

**Tailwind Classes**: `bg-destructive`, `text-destructive`, `border-destructive`

**Status Colors** (Not in theme, use standard Tailwind):
- Success: `bg-green-500` - `#10b981`
- Warning: `bg-yellow-500` - `#eab308`
- Info: `bg-blue-500` - `#3b82f6`

---

## Dark Mode Colors

### Background & Surfaces (Dark)

| Color | HSL | RGB | Hex | Usage |
|-------|-----|-----|-----|-------|
| Background | `212° 84% 19%` | `rgb(8, 39, 88)` | `#082758` | Main dark background |
| Card | `212° 70% 25%` | `rgb(19, 48, 108)` | `#13306c` | Dark card backgrounds |
| Popover | `212° 84% 19%` | `rgb(8, 39, 88)` | `#082758` | Dark dropdown backgrounds |
| Muted | `212° 60% 25%` | `rgb(26, 52, 102)` | `#1a3466` | Dark muted backgrounds |
| Input | `212° 60% 25%` | `rgb(26, 52, 102)` | `#1a3466` | Dark input backgrounds |

---

### Text & Foreground (Dark)

| Color | HSL | RGB | Hex | Usage |
|-------|-----|-----|-----|-------|
| Foreground | `0° 0% 98%` | `rgb(250, 250, 250)` | `#fafafa` | Light text on dark background |
| Muted Foreground | `0° 0% 65%` | `rgb(166, 166, 166)` | `#a6a6a6` | Secondary text in dark mode |

---

### Interactive Elements (Dark)

| Color | HSL | RGB | Hex | Usage |
|-------|-----|-----|-----|-------|
| Primary | `49° 96% 51%` | `rgb(252, 203, 5)` | `#fccb05` | Golden yellow primary in dark |
| Primary Foreground | `212° 84% 19%` | `rgb(8, 39, 88)` | `#082758` | Navy text on golden button |
| Secondary | `212° 60% 35%` | `rgb(36, 68, 136)` | `#244488` | Navy secondary in dark |
| Border | `212° 60% 30%` | `rgb(31, 58, 115)` | `#1f3a73` | Dark borders |
| Ring | `49° 96% 51%` | `rgb(252, 203, 5)` | `#fccb05` | Golden focus rings |

---

## Sidebar Colors

### Light Mode Sidebar

| Color | HSL | RGB | Hex | Usage |
|-------|-----|-----|-----|-------|
| Sidebar Background | `0° 0% 100%` | `rgb(255, 255, 255)` | `#ffffff` | Sidebar background |
| Sidebar Foreground | `212° 84% 19%` | `rgb(8, 39, 88)` | `#082758` | Sidebar text |
| Sidebar Primary | `49° 96% 51%` | `rgb(252, 203, 5)` | `#fccb05` | Active nav item |
| Sidebar Accent | `0° 0% 96%` | `rgb(245, 245, 245)` | `#f5f5f5` | Hover states |
| Sidebar Border | `0° 0% 90%` | `rgb(230, 230, 230)` | `#e6e6e6` | Sidebar borders |

**Tailwind Classes**: `bg-sidebar`, `text-sidebar-foreground`, `bg-sidebar-primary`

---

### Dark Mode Sidebar

| Color | HSL | RGB | Hex | Usage |
|-------|-----|-----|-----|-------|
| Sidebar Background | `212° 84% 19%` | `rgb(8, 39, 88)` | `#082758` | Dark sidebar background |
| Sidebar Foreground | `0° 0% 98%` | `rgb(250, 250, 250)` | `#fafafa` | Light sidebar text |
| Sidebar Primary | `49° 96% 51%` | `rgb(252, 203, 5)` | `#fccb05` | Active nav item (golden) |
| Sidebar Accent | `212° 60% 35%` | `rgb(36, 68, 136)` | `#244488` | Hover states |
| Sidebar Border | `212° 60% 30%` | `rgb(31, 58, 115)` | `#1f3a73` | Dark sidebar borders |

---

## Gradients

### Primary Gradient (Navy)
```css
background: linear-gradient(135deg, hsl(212, 84%, 19%), hsl(212, 70%, 30%));
```
**From**: `#082758` (Navy Blue)
**To**: `#173973` (Navy Light)
**Tailwind**: `bg-gradient-primary`
**Usage**: Hero sections, primary call-to-action cards

---

### Secondary Gradient (Golden)
```css
background: linear-gradient(135deg, hsl(49, 96%, 51%), hsl(49, 96%, 70%));
```
**From**: `#fccb05` (Golden Yellow)
**To**: `#fddb66` (Golden Light)
**Tailwind**: `bg-gradient-secondary`
**Usage**: Accent cards, promotional banners

---

### Card Gradient (Subtle)
```css
background: linear-gradient(135deg, hsl(0, 0%, 98%), hsl(0, 0%, 96%));
```
**From**: `#fafafa` (Card)
**To**: `#f5f5f5` (Muted)
**Tailwind**: `bg-gradient-card`
**Usage**: Subtle card backgrounds, hover effects

---

## Shadows

### Primary Shadow (Navy)
```css
box-shadow: 0 8px 32px hsl(212, 84%, 19%, 0.3);
```
**Color**: Navy Blue with 30% opacity
**Tailwind**: `shadow-primary`
**Usage**: Primary buttons, important cards

---

### Card Shadow (Subtle)
```css
box-shadow: 0 4px 24px rgba(0, 0, 0, 0.1);
```
**Color**: Black with 10% opacity
**Tailwind**: `shadow-card`
**Usage**: Cards, popovers, elevated elements

---

## Border Radius

| Name | Value | Tailwind | Usage |
|------|-------|----------|-------|
| Default | `0.8rem` (12.8px) | `rounded-lg` | Buttons, cards |
| Medium | `0.6rem` (9.6px) | `rounded-md` | Inputs, smaller cards |
| Small | `0.4rem` (6.4px) | `rounded-sm` | Badges, tags |

**CSS Variable**: `--radius: 0.8rem`

---

## Usage Guidelines

### Primary Navy Blue (`#082758`)
**Use for**:
- Primary action buttons
- Main navigation items
- Page headers
- Important links
- Focus states

**Do NOT use for**:
- Large background areas (too dark)
- Body text (poor contrast on white)

---

### Golden Yellow (`#fccb05`)
**Use for**:
- Secondary action buttons
- Call-to-action elements
- Status badges (pending, active)
- Accent highlights
- Icons for attention

**Do NOT use for**:
- Primary text (poor readability)
- Large background areas (too bright)

---

### Muted Gray (`#f5f5f5`)
**Use for**:
- Disabled states
- Form input backgrounds
- Subtle card backgrounds
- Dividers

**Do NOT use for**:
- Important content (too subtle)
- Calls to action

---

### Destructive Red (`#eb3d3d`)
**Use for**:
- Delete buttons
- Error messages
- Destructive confirmations
- Failed status badges

**Do NOT use for**:
- Positive actions
- Decorative elements

---

## Color Combinations

### High Contrast (Accessible)
- **Navy text on white**: `text-foreground bg-background` ✅ WCAG AAA
- **White text on navy**: `text-primary-foreground bg-primary` ✅ WCAG AAA
- **Navy text on golden**: `text-secondary-foreground bg-secondary` ✅ WCAG AA

### Medium Contrast
- **Muted text on white**: `text-muted-foreground bg-background` ✅ WCAG AA
- **Golden on navy**: `bg-secondary text-secondary-foreground` ✅ WCAG AA

### Avoid
- **Golden text on white**: Poor contrast ❌
- **Light gray text on white**: Accessibility fail ❌

---

## Status Color System

### Commission/Agreement Status
| Status | Background | Text | Border |
|--------|-----------|------|--------|
| DRAFT | `bg-gray-100` | `text-gray-700` | `border-gray-300` |
| PENDING | `bg-yellow-100` | `text-yellow-800` | `border-yellow-300` |
| AWAITING_APPROVAL | `bg-blue-100` | `text-blue-800` | `border-blue-300` |
| APPROVED | `bg-green-100` | `text-green-800` | `border-green-300` |
| PAID | `bg-green-200` | `text-green-900` | `border-green-400` |
| REJECTED | `bg-red-100` | `text-red-800` | `border-red-300` |

---

### Source Type Badges
| Source Type | Color | Class |
|------------|-------|-------|
| NONE | Gray | `bg-gray-100 text-gray-700` |
| ORGANIC | Green | `bg-green-100 text-green-700` |
| VANTAGE_IR | Blue | `bg-blue-100 text-blue-700` |
| DISTRIBUTOR | Purple | `bg-purple-100 text-purple-700` |
| REFERRER | Orange | `bg-orange-100 text-orange-700` |
| OTHER | Gray | `bg-gray-100 text-gray-700` |

---

## Implementation Examples

### Button Variants
```tsx
// Primary button (Navy)
<Button className="bg-primary text-primary-foreground hover:bg-primary/90">
  Approve Agreement
</Button>

// Secondary button (Golden)
<Button variant="secondary" className="bg-secondary text-secondary-foreground">
  Recompute Commissions
</Button>

// Destructive button (Red)
<Button variant="destructive">
  Delete Agreement
</Button>

// Outline button
<Button variant="outline">
  Cancel
</Button>
```

---

### Card with Gradient
```tsx
<Card className="bg-gradient-card shadow-card">
  <CardHeader>
    <CardTitle className="text-foreground">Active Agreements</CardTitle>
  </CardHeader>
  <CardContent>
    Content here
  </CardContent>
</Card>
```

---

### Status Badge
```tsx
// Approved status
<Badge className="bg-green-100 text-green-800 border-green-300">
  APPROVED
</Badge>

// Pending status
<Badge className="bg-yellow-100 text-yellow-800 border-yellow-300">
  PENDING
</Badge>
```

---

### Custom Brand Colors
```tsx
// Navy background
<div className="bg-custom-navy text-white">
  Navy Background
</div>

// Golden accent
<div className="bg-custom-golden text-custom-navy">
  Golden Accent
</div>
```

---

## Accessibility

### Contrast Ratios (WCAG 2.1)

| Combination | Ratio | WCAG AA | WCAG AAA |
|-------------|-------|---------|----------|
| Navy on White | 13.5:1 | ✅ Pass | ✅ Pass |
| White on Navy | 13.5:1 | ✅ Pass | ✅ Pass |
| Golden on White | 1.8:1 | ❌ Fail | ❌ Fail |
| Navy on Golden | 7.5:1 | ✅ Pass | ✅ Pass |
| Muted text on White | 4.8:1 | ✅ Pass | ⚠️ AA Large |

**Note**: Always test color combinations with actual users and automated tools.

---

## Color Naming Convention

### HSL Format
All colors use HSL (Hue, Saturation, Lightness) for better manipulation:
```css
/* Format: H S L */
--primary: 212 84% 19%;  /* Navy Blue */
```

**Benefits**:
- Easy to create variants (adjust lightness)
- Better for dark mode (adjust all colors systematically)
- CSS color-mix() support

---

### CSS Variable Usage
```css
/* Define in :root */
:root {
  --primary: 212 84% 19%;
}

/* Use with hsl() */
.button {
  background: hsl(var(--primary));
}

/* Use with transparency */
.button-hover {
  background: hsl(var(--primary) / 0.9);
}
```

---

## Quick Reference

### Tailwind Classes
```css
/* Backgrounds */
bg-primary          /* Navy blue */
bg-secondary        /* Golden yellow */
bg-muted           /* Light gray */
bg-destructive     /* Red */

/* Text */
text-foreground          /* Navy text */
text-muted-foreground    /* Gray text */
text-primary-foreground  /* White text */

/* Borders */
border              /* Light gray border */
border-primary      /* Navy border */
border-secondary    /* Golden border */

/* Custom */
bg-custom-navy      /* Navy blue */
bg-custom-golden    /* Golden yellow */
```

---

### HSL Values (Copy-Paste Ready)
```css
/* Brand Colors */
--navy-blue: 212 84% 19%;          /* #082758 */
--golden-yellow: 49 96% 51%;       /* #fccb05 */
--navy-light: 212 70% 30%;         /* #173973 */
--golden-light: 49 96% 70%;        /* #fddb66 */

/* Neutrals */
--white: 0 0% 100%;                /* #ffffff */
--gray-98: 0 0% 98%;              /* #fafafa */
--gray-96: 0 0% 96%;              /* #f5f5f5 */
--gray-90: 0 0% 90%;              /* #e6e6e6 */

/* Feedback */
--red: 0 84% 60%;                 /* #eb3d3d */
--green: 142 71% 45%;             /* #10b981 */
--yellow: 48 96% 53%;             /* #eab308 */
--blue: 221 83% 53%;              /* #3b82f6 */
```

---

**Document Version**: 1.0
**Last Updated**: November 11, 2025
**Maintained By**: Design Team
**Framework**: Tailwind CSS v3 + shadcn/ui
