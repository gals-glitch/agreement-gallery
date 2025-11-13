# Password Reset Fix - Quick Start

**Time:** 2 minutes to configure + 3 minutes to test
**Status:** ✅ Code Fixed, ⏳ Supabase Config Needed

---

## ⚡ 2-Minute Setup

### **Step 1: Verify Environment Variable (✅ Already Done)**
The `.env` file already has:
```bash
VITE_PUBLIC_APP_URL="http://localhost:8081"
```

Dev server already restarted automatically.

### **Step 2: Configure Supabase (⏳ Your Turn - 2 minutes)**

1. **Open Supabase Dashboard:**
   ```
   https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys
   ```

2. **Navigate to:**
   ```
   Authentication → URL Configuration
   ```

3. **Add these to "Additional Redirect URLs":**
   ```
   http://localhost:8081/*
   http://127.0.0.1:8081/*
   https://id-preview--*.lovable.app/*
   ```

4. **Click Save**

**That's it!** The fix is now complete.

---

## 🧪 3-Minute Test

### **Test the Fix:**

1. **Open app:**
   ```
   http://localhost:8081/auth
   ```

2. **Click "Forgot your password?"**

3. **Enter your email and submit**

4. **Check your inbox**

5. **Click the reset link**

**Expected Result:**
- ✅ Redirects to `http://localhost:8081/auth/reset`
- ✅ Shows "Set New Password" form
- ✅ Can enter new password
- ✅ Password updates successfully
- ✅ Redirects to home page
- ✅ Can sign in with new password

---

## 🎯 Quick Troubleshooting

### **Issue: Still redirects to wrong URL**

**Fix:**
1. Check Supabase → Additional Redirect URLs includes `http://localhost:8081/*`
2. Wait 2-3 minutes (Supabase config propagation)
3. Test in incognito window (clears cache)

### **Issue: "Invalid Reset Link"**

**Fix:**
1. Request new password reset (links expire after 1 hour)
2. Don't click the link multiple times

### **Issue: Can't update password**

**Fix:**
1. Check browser console for errors
2. Verify password is at least 6 characters
3. Make sure passwords match

---

## 📊 What Changed

| Component | Change | Status |
|-----------|--------|--------|
| Code | Updated auth redirects | ✅ Done |
| .env | Added VITE_PUBLIC_APP_URL | ✅ Done |
| Dev Server | Auto-restarted | ✅ Done |
| Supabase Config | Add redirect URLs | ⏳ Manual |

**Your Action:** Just the Supabase configuration (2 minutes)

---

## 📚 Full Documentation

For detailed information, see:
- **PASSWORD-RESET-SUMMARY.md** - Overview and results
- **PASSWORD-RESET-FIX.md** - Full technical details
- **SUPABASE-AUTH-CONFIG.md** - Supabase setup guide

---

## ✅ Checklist

- [x] Code updated
- [x] Environment variable added
- [x] Dev server restarted
- [ ] **→ Configure Supabase redirect URLs** (Your turn!)
- [ ] **→ Test password reset flow**

---

_Quick Start Guide_
_Version: 1.0_
_Updated: 2025-10-16_
