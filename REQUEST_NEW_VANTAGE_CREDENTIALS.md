# Request New Vantage API Credentials

## Current Situation

Your Vantage API credentials have expired or been rotated. You need to contact Vantage support to get fresh credentials.

## What Happened

- ✅ **Earlier today**: Successfully synced 2,097 investor accounts from Vantage
- ❌ **Now**: Getting `401 Unauthorized Access` errors
- **Diagnosis**: Token has expired or been rotated

## What to Request from Vantage Support

Contact your Vantage IR account manager or support team and request:

### 1. New Authentication Token
- **Field name**: Bearer token / Auth token
- **Previous value**: `buligodata`
- **What to ask**: "We need a new authentication token for API access. Our current token `buligodata` is returning 401 errors."

### 2. Client ID (may still be valid)
- **Field name**: Client ID / Subscription ID
- **Previous value**: `bexz40aUdxK5rQDSjS2BIUg==`
- **What to ask**: "Please confirm if our Client ID `bexz40aUdxK5rQDSjS2BIUg==` is still valid, or provide the updated value."

### 3. Additional Questions to Ask

**Token Lifespan:**
> "How long do API tokens remain valid? Is there an expiration period?"

**Token Rotation Policy:**
> "Do you rotate tokens automatically? If so, how often and will we be notified?"

**Long-term Access:**
> "Can you provide a longer-lived token or service account credentials for our automated daily sync?"

**Rate Limits:**
> "What are the rate limits for API calls? We sync ~2,100 accounts and 290 funds daily."

**IP Allowlisting:**
> "Do we need to allowlist IP addresses for Supabase Edge Functions?"
> (Supabase uses dynamic IPs from AWS - you may need their IP ranges)

## Contact Information

**Vantage IR Support:**
- Website: https://www.vantageir.com/
- API Base URL: https://buligoirapi.insightportal.info
- Your account: Buligo Capital

## Once You Get New Credentials

Run this command and follow the prompts:

```powershell
.\update_vantage_credentials.ps1
```

Or provide credentials directly:

```powershell
.\update_vantage_credentials.ps1 -AuthToken "new_token_here" -ClientId "new_client_id_here"
```

The script will:
1. Update Supabase secrets
2. Update .env file
3. Test the connection automatically

## Verification

After updating credentials, run:

```powershell
# Test direct API access
.\test_vantage_auth.ps1

# Test via Edge Function
.\test_edge_function.ps1
```

If both tests pass, you're ready to continue with the deployment.
