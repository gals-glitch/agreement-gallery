# Supabase Auth Configuration - Quick Setup

**Time Required:** 2 minutes
**Dashboard URL:** https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys

---

## 🚀 Quick Setup (Copy-Paste)

### **Step 1: Navigate to URL Configuration**
1. Go to: https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys
2. Click **Authentication** in left sidebar
3. Click **URL Configuration** tab

### **Step 2: Configure Site URL**
```
Site URL: https://your-production-domain.com
```

**Note:** If you don't have a production domain yet, use your Lovable preview URL temporarily.

### **Step 3: Add Redirect URLs**
Click **"Add redirect URL"** and add these one by one:

```
http://localhost:8081/*
http://127.0.0.1:8081/*
https://id-preview--*.lovable.app/*
```

**Important:** Include the `/*` wildcard at the end of each URL!

### **Step 4: Save Configuration**
Click **Save** button at the bottom of the page.

---

## 📸 Screenshot Guide

### **What You Should See:**

```
╔════════════════════════════════════════════╗
║ Authentication → URL Configuration        ║
╠════════════════════════════════════════════╣
║                                            ║
║ Site URL                                   ║
║ ┌────────────────────────────────────────┐ ║
║ │ https://your-production-domain.com     │ ║
║ └────────────────────────────────────────┘ ║
║                                            ║
║ Additional Redirect URLs                   ║
║ ┌────────────────────────────────────────┐ ║
║ │ http://localhost:8081/*                │ ║
║ │ http://127.0.0.1:8081/*                │ ║
║ │ https://id-preview--*.lovable.app/*    │ ║
║ └────────────────────────────────────────┘ ║
║                                            ║
║                                [ Save ]     ║
╚════════════════════════════════════════════╝
```

---

## ✅ Verification

After saving, test that redirects work:

1. **Test Local Dev:**
   ```bash
   # In your app at http://localhost:8081/auth
   # Click "Forgot password" → Enter email
   # Check email → Click link
   # Should redirect to http://localhost:8081/auth/reset
   ```

2. **Verify in Supabase Logs:**
   - Go to: **Logs** → **Auth Logs**
   - Look for `password_recovery` events
   - Check `redirect_to` field matches your localhost URL

---

## 🚨 Common Mistakes

### **❌ Mistake #1: Forgot the wildcard**
```
BAD:  http://localhost:8081
GOOD: http://localhost:8081/*
```
Without `/*`, only the exact URL matches. The wildcard allows any path.

### **❌ Mistake #2: Wrong port**
```
BAD:  http://localhost:3000/*    # Wrong port
GOOD: http://localhost:8081/*    # Correct port (Vite default)
```
Check your dev server port in terminal output.

### **❌ Mistake #3: HTTPS for localhost**
```
BAD:  https://localhost:8081/*   # Localhost doesn't need HTTPS
GOOD: http://localhost:8081/*    # Use HTTP for local dev
```

### **❌ Mistake #4: Site URL set to localhost**
```
BAD:  Site URL: http://localhost:8081
GOOD: Site URL: https://your-production-domain.com
```
Site URL should be your production domain. Use Additional Redirects for dev/preview.

---

## 🔄 Update Procedure (When Changing Environments)

### **Switching from Dev to Preview:**
1. Update `.env`:
   ```bash
   VITE_PUBLIC_APP_URL="https://id-preview--yourapp.lovable.app"
   ```
2. Restart dev server: `npm run dev`
3. Verify Supabase has preview URL in Additional Redirects
4. Test password reset

### **Deploying to Production:**
1. Update `.env` for production:
   ```bash
   VITE_PUBLIC_APP_URL="https://your-production-domain.com"
   ```
2. Update Supabase Site URL to production domain
3. Ensure production domain in Additional Redirects
4. Deploy app
5. Test password reset end-to-end

---

## 🎯 Why This Configuration?

| Setting | Purpose |
|---------|---------|
| **Site URL** | Default redirect for production; fallback if no `redirectTo` provided |
| **Additional Redirects** | Allowlist of permitted redirect targets; checked per-request |
| **Wildcard (`/*`)** | Allows any path under the domain (e.g., `/auth/reset`, `/auth/callback`) |

### **Flow:**
```
1. User requests password reset
2. Your code: redirectTo = "http://localhost:8081/auth/reset"
3. Supabase checks: Is this URL in Site URL or Additional Redirects?
4. If YES → Email sent with that redirect URL
5. If NO  → Error: "redirect URL not allowed"
```

---

## 🧪 Test Scenarios

### **Scenario 1: Local Development**
```bash
# .env
VITE_PUBLIC_APP_URL="http://localhost:8081"

# Supabase Additional Redirects
http://localhost:8081/*

# Expected Result:
# Reset email link → http://localhost:8081/auth/reset?access_token=...
✅ PASS
```

### **Scenario 2: Preview Deployment**
```bash
# .env
VITE_PUBLIC_APP_URL="https://id-preview--abc123.lovable.app"

# Supabase Additional Redirects
https://id-preview--*.lovable.app/*

# Expected Result:
# Reset email link → https://id-preview--abc123.lovable.app/auth/reset?access_token=...
✅ PASS
```

### **Scenario 3: Production**
```bash
# .env
VITE_PUBLIC_APP_URL="https://app.buligocapital.com"

# Supabase Site URL
https://app.buligocapital.com

# Supabase Additional Redirects
https://app.buligocapital.com/*

# Expected Result:
# Reset email link → https://app.buligocapital.com/auth/reset?access_token=...
✅ PASS
```

### **Scenario 4: Unauthorized Domain (Should Fail)**
```bash
# .env
VITE_PUBLIC_APP_URL="https://malicious-site.com"

# Supabase Additional Redirects
# (does not include malicious-site.com)

# Expected Result:
# Error: "redirect URL not allowed"
✅ PASS (security working correctly)
```

---

## 📞 Support

If redirects still don't work after configuration:

1. **Check browser console** for auth errors
2. **Check Supabase Logs** → Auth Logs for `password_recovery` events
3. **Verify environment variable** is loaded: `console.log(import.meta.env.VITE_PUBLIC_APP_URL)`
4. **Test in incognito** to rule out caching
5. **Wait 2-3 minutes** after saving Supabase config (propagation delay)

---

## 🔗 Quick Links

- **Supabase Dashboard:** https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys
- **Auth Settings:** https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys/auth/url-configuration
- **Auth Logs:** https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys/logs/auth-logs
- **Documentation:** https://supabase.com/docs/guides/auth/redirect-urls

---

_Configuration Guide Version: 1.0_
_Last Updated: 2025-10-16_
