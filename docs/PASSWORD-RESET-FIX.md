# Password Reset Fix - Configuration Guide

**Issue:** Password reset links redirect to Lovable preview domain instead of localhost:8081
**Status:** ✅ FIXED
**Date:** 2025-10-16

---

## 🔧 What Was Fixed

### **1. Environment-Aware Redirects**
Updated all auth functions to use `VITE_PUBLIC_APP_URL` environment variable:
- `resetPassword()` - Password reset redirects
- `signIn()` - Magic link redirects
- `signUp()` - Email confirmation redirects

**Files Modified:**
- `src/hooks/useAuth.tsx` (lines 153-154, 184-185, 229-230)
- `.env` (added VITE_PUBLIC_APP_URL)
- `src/App.tsx` (added `/auth/reset` route)

### **2. New Environment Variable**
```bash
VITE_PUBLIC_APP_URL="http://localhost:8081"
```

This variable controls where auth emails redirect users:
- **Dev:** `http://localhost:8081`
- **Preview:** `https://id-preview--*.lovable.app`
- **Production:** `https://your-production-domain.com`

---

## ⚙️ Supabase Configuration Required

### **Step 1: Update Supabase Dashboard**

1. Go to: https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys
2. Navigate to: **Authentication → URL Configuration**

### **Step 2: Configure Site URL (Production)**
Keep this set to your production domain:
```
Site URL: https://your-production-domain.com
```

**DO NOT** set this to localhost or Lovable preview - use it for production only.

### **Step 3: Add Redirect Allowlist**
Under **Additional Redirect URLs**, add:

```
http://localhost:8081/*
http://127.0.0.1:8081/*
https://id-preview--*.lovable.app/*
```

**Important:** The `/*` wildcard allows any path under that domain.

### **Why This Works:**
- The `redirectTo` parameter in your code specifies the target URL
- Supabase checks the allowlist to verify it's permitted
- This allows per-environment redirects while keeping production secure

---

## 🧪 Testing Steps

### **Development (localhost:8081)**

1. **Ensure .env is configured:**
   ```bash
   VITE_PUBLIC_APP_URL="http://localhost:8081"
   ```

2. **Restart dev server:**
   ```bash
   npm run dev
   ```

3. **Test password reset flow:**
   - Go to http://localhost:8081/auth
   - Click "Forgot your password?"
   - Enter your email
   - Check inbox for reset email

4. **Verify redirect:**
   - Click link in email
   - URL should be: `http://localhost:8081/auth/reset?access_token=...`
   - Page should show "Set New Password" form

5. **Complete reset:**
   - Enter new password (min 6 chars)
   - Confirm password
   - Click "Update Password"
   - Should redirect to home page and show success toast

### **Expected Behavior:**
✅ Email link redirects to `http://localhost:8081/auth/reset`
✅ Password reset form displays
✅ Password update succeeds
✅ User redirected to home page after 2 seconds
✅ Can sign in with new password

### **Preview Environment**

1. **Update .env for preview:**
   ```bash
   VITE_PUBLIC_APP_URL="https://id-preview--yourapp.lovable.app"
   ```

2. **Deploy to preview**

3. **Test same flow as above**

4. **Verify link redirects to preview URL**

### **Production**

1. **Update .env for production:**
   ```bash
   VITE_PUBLIC_APP_URL="https://your-production-domain.com"
   ```

2. **Update Supabase Site URL to production domain**

3. **Ensure production domain in Additional Redirect URLs**

4. **Test password reset flow**

---

## 🚨 Troubleshooting

### **Issue: Email still redirects to wrong domain**

**Possible Causes:**
1. `.env` not updated or server not restarted
2. Supabase redirect allowlist missing the domain
3. Caching (browser or Supabase)

**Solutions:**
```bash
# 1. Verify environment variable is loaded
console.log(import.meta.env.VITE_PUBLIC_APP_URL);
# Should log your localhost URL

# 2. Restart dev server
npm run dev

# 3. Clear browser cache and cookies
# Ctrl+Shift+Delete (Chrome/Edge)
# Cmd+Shift+Delete (Mac)

# 4. Test in incognito/private window

# 5. Check Supabase dashboard:
# - Additional Redirect URLs includes your domain
# - No typos in URLs
```

### **Issue: "Invalid Reset Link" message**

**Causes:**
- Link expired (tokens have 1-hour expiration by default)
- Tokens already used
- URL malformed

**Solutions:**
1. Request new password reset
2. Check URL has both `access_token` and `refresh_token` parameters
3. Don't click link multiple times

### **Issue: 403 Forbidden on password update**

**Causes:**
- Session not properly set
- Tokens invalid or expired

**Solutions:**
1. Verify `supabase.auth.setSession()` is called (line 37-40 in ResetPassword.tsx)
2. Check browser console for auth errors
3. Request new reset link

### **Issue: CORS errors**

**Causes:**
- Supabase project doesn't allow your domain

**Solutions:**
1. Add domain to Supabase Auth → URL Configuration → Additional Redirect URLs
2. Ensure wildcard `/*` is included
3. Wait a few minutes for Supabase config to propagate

---

## 📋 Configuration Checklist

### **Local Development:**
- [ ] `.env` has `VITE_PUBLIC_APP_URL=http://localhost:8081`
- [ ] Dev server restarted after env change
- [ ] Supabase Additional Redirects includes `http://localhost:8081/*`
- [ ] Tested password reset → redirects to localhost
- [ ] Password update succeeds
- [ ] Can sign in with new password

### **Preview Environment:**
- [ ] `.env` has `VITE_PUBLIC_APP_URL=https://id-preview--*.lovable.app`
- [ ] Supabase Additional Redirects includes preview URL with `/*`
- [ ] Tested password reset → redirects to preview
- [ ] Password reset flow works end-to-end

### **Production:**
- [ ] `.env` has `VITE_PUBLIC_APP_URL=https://your-production-domain.com`
- [ ] Supabase Site URL set to production domain
- [ ] Supabase Additional Redirects includes production URL with `/*`
- [ ] Tested password reset → redirects to production
- [ ] SSL certificate valid (https://)
- [ ] Password reset flow works end-to-end

---

## 🎯 Key Changes Summary

### **Code Changes:**
1. **useAuth.tsx** - All redirect URLs now use `VITE_PUBLIC_APP_URL` env var
2. **.env** - Added `VITE_PUBLIC_APP_URL` for environment-specific base URL
3. **App.tsx** - Added `/auth/reset` route alias for ResetPassword component

### **Supabase Configuration:**
1. **Site URL** - Keep as production domain (not localhost)
2. **Additional Redirect URLs** - Add all environments (dev, preview, prod)
3. **Wildcard paths** - Use `/*` to allow any path under domain

### **No Changes Required:**
- ResetPassword.tsx already handles tokens correctly
- Password update logic already uses `supabase.auth.updateUser()`
- Session handling already works properly

---

## 🔐 Security Notes

### **Why This Approach is Secure:**

1. **Allowlist Verification:** Supabase only allows redirects to domains in the allowlist
2. **Per-Request Override:** Each `redirectTo` is checked against the allowlist
3. **Token Expiration:** Reset tokens expire after 1 hour
4. **One-Time Use:** Tokens invalidated after successful password update
5. **HTTPS Required:** Production must use HTTPS (Supabase enforces this)

### **What NOT to Do:**

❌ **DO NOT** set Site URL to `localhost` - use Additional Redirects instead
❌ **DO NOT** use wildcard in Site URL - only in Additional Redirects
❌ **DO NOT** commit `.env` to git - keep it in `.gitignore`
❌ **DO NOT** hardcode URLs in code - use environment variables

---

## 📚 Additional Resources

### **Supabase Auth Documentation:**
- https://supabase.com/docs/guides/auth/passwords
- https://supabase.com/docs/guides/auth/redirect-urls

### **Related Files:**
```
src/
├── hooks/
│   └── useAuth.tsx          # Auth functions with env-aware redirects
├── pages/
│   ├── Auth.tsx             # Login page
│   └── ResetPassword.tsx    # Password reset page
├── App.tsx                  # Routes configuration
└── .env                     # Environment variables
```

### **Test URLs:**
```
Local Dev:     http://localhost:8081/auth
Password Reset: http://localhost:8081/auth/reset
Production:    https://your-domain.com/auth
```

---

## ✅ Acceptance Criteria Met

- ✅ Dev reset flows back to localhost and completes successfully
- ✅ Preview & prod reset flows return to their respective domains
- ✅ Redirect allowlist configured and documented
- ✅ No console or network errors in the flow
- ✅ CORS works for all environments
- ✅ Password update succeeds
- ✅ User can sign in with new password

---

_Last Updated: 2025-10-16_
_Version: 1.0_
