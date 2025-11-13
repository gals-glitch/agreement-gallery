# Commission Data Import Guide

## 📋 Overview

This guide will help you import your distributors (parties), investors, and commission agreements into the system.

---

## 📁 Files

1. **`01_parties_template.csv`** - Your distributors/referrers
2. **`02_investors_template.csv`** - Investors with party relationships
3. **`03_agreements_template.csv`** - Commission agreements with rates and terms
4. **`../import_data.sql`** - Import script (in parent folder)

---

## 🔧 Step-by-Step Instructions

### Step 1: Prepare Your CSV Files

1. **Open each template CSV in Excel**
2. **Replace the example rows** with your actual data
3. **Save as CSV** (keep the same filenames)

#### Parties Template (01_parties_template.csv)

| Column | Description | Example |
|--------|-------------|---------|
| party_name | Name of distributor/referrer | "Kuperman Capital" |
| contact_email | Contact email (optional) | "info@kuperman.com" |
| contact_phone | Phone number (optional) | "+972-50-1234567" |
| notes | Any notes (optional) | "Primary distributor" |

#### Investors Template (02_investors_template.csv)

| Column | Description | Example |
|--------|-------------|---------|
| investor_name | Full name of investor | "Rakefet Kuperman" |
| party_name | **Must match** a party_name from parties CSV | "Kuperman Capital" |
| email | Email (optional) | "rakefet@email.com" |
| phone | Phone (optional) | "+972-54-9876543" |
| notes | Any notes (optional) | "VIP investor" |

⚠️ **Important**: The `party_name` must exactly match a name from the parties CSV!

#### Agreements Template (03_agreements_template.csv)

| Column | Description | Example | Required |
|--------|-------------|---------|----------|
| party_name | **Must match** a party_name from parties CSV | "Kuperman Capital" | ✅ Yes |
| scope_type | FUND or DEAL | "DEAL" | ✅ Yes |
| fund_id | Fund ID (if scope_type=FUND) | 1 | If FUND |
| deal_id | Deal ID (if scope_type=DEAL) | 1 | If DEAL |
| rate_bps | Commission rate in basis points (100 = 1%) | 100 | ✅ Yes |
| vat_mode | "on_top" or "included" | "on_top" | ✅ Yes |
| vat_rate | VAT rate as decimal (0.20 = 20%) | 0.20 | ✅ Yes |
| effective_from | Start date (YYYY-MM-DD) | "2020-01-01" | ✅ Yes |
| effective_to | End date (YYYY-MM-DD) or leave empty for open-ended | "2025-12-31" or empty | No |
| status | APPROVED or DRAFT | "APPROVED" | ✅ Yes |

⚠️ **Important**:
- Set **exactly one** of `fund_id` OR `deal_id` (not both!)
- Leave the other one empty
- Most common: Use DEAL scope with a deal_id

---

### Step 2: Convert CSV to SQL INSERT Statements

Once your CSV files are ready, convert them to SQL INSERT statements:

#### Option A: Manual Conversion

Open each CSV in Excel and create INSERT statements like this:

**For Parties:**
```sql
INSERT INTO temp_parties VALUES
('Kuperman Capital', 'info@kuperman.com', '+972-50-1234567', 'Primary distributor'),
('Partner Capital', 'info@partnercapital.com', '+1-212-555-0100', 'Strategic partner');
```

**For Investors:**
```sql
INSERT INTO temp_investors VALUES
('Rakefet Kuperman', 'Kuperman Capital', 'rakefet@email.com', '+972-54-9876543', 'VIP investor'),
('David Levi', 'Partner Capital', 'david.levi@email.com', '+1-917-555-0200', 'Introduced Q1 2024');
```

**For Agreements:**
```sql
INSERT INTO temp_agreements VALUES
('Kuperman Capital', 'DEAL', NULL, 1, 100, 'on_top', 0.20, '2020-01-01', NULL, 'APPROVED'),
('Partner Capital', 'FUND', 1, NULL, 150, 'on_top', 0.20, '2024-01-01', '2024-12-31', 'APPROVED');
```

---

### Step 3: Run the Import Script

1. **Open** `import_data.sql` in a text editor
2. **Find the sections** marked `-- PASTE YOUR ... CSV DATA HERE`
3. **Paste your INSERT statements** into each section:
   - Step 1: Parties data
   - Step 2: Investors data
   - Step 3: Agreements data
4. **Open Supabase SQL Editor**: https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys/sql/new
5. **Paste the entire modified script** and click **Run**

---

### Step 4: Verify the Import

After running the script, check the output tables:

#### ✅ Import Summary
```
parties_imported: 10
investors_imported: 35
agreements_imported: 10
```

#### ✅ Verification Checks
- **Investors Missing Party Links**: Should be 0
- **Duplicate Party Names**: Should be 0
- **Agreement Scope Validation**: All should say "OK"

---

## 📊 Example: Complete Import

Here's a complete example for **2 distributors**:

### Parties CSV:
```
party_name,contact_email,contact_phone,notes
"Kuperman Capital","info@kuperman.com","+972-50-1234567","Tel Aviv based"
"Global Partners","contact@globalpartners.com","+1-212-555-0100","NYC based"
```

### Investors CSV:
```
investor_name,party_name,email,phone,notes
"Rakefet Kuperman","Kuperman Capital","rakefet@email.com","+972-54-1111111","VIP"
"David Levi","Kuperman Capital","david@email.com","+972-54-2222222","Regular"
"Sarah Cohen","Global Partners","sarah@email.com","+1-917-555-0200","High net worth"
```

### Agreements CSV:
```
party_name,scope_type,fund_id,deal_id,rate_bps,vat_mode,vat_rate,effective_from,effective_to,status
"Kuperman Capital","DEAL",,1,100,"on_top",0.20,"2020-01-01",,"APPROVED"
"Global Partners","DEAL",,1,150,"on_top",0.20,"2024-01-01","2025-12-31","APPROVED"
```

---

## 🆘 Troubleshooting

### Error: "violates foreign key constraint"
- **Cause**: Party name in investors/agreements doesn't match any party
- **Fix**: Check spelling, ensure party was imported first

### Error: "violates check constraint"
- **Cause**: Both fund_id and deal_id are set (or both are NULL)
- **Fix**: Set exactly ONE of fund_id OR deal_id

### Error: "duplicate key value"
- **Cause**: Party or investor name already exists
- **Fix**: The script uses `ON CONFLICT DO NOTHING`, so duplicates are skipped

### Missing Data After Import
- Check the verification queries at the end of the script
- Look for the investor name in the `temp_investors` table

---

## 🎯 Next Steps After Import

1. ✅ **Verify data** in the UI:
   - Go to **Parties** page → should see all distributors
   - Go to **Investors** page → check `introduced_by` links

2. ✅ **Test commission computation**:
   - Go to **Contributions** page
   - Find a contribution from a linked investor
   - Compute commission → should work!

3. ✅ **Check Feature Flags**:
   - Go to **Admin** → **Feature Flags**
   - Ensure `commissions_engine` is enabled

---

## 📞 Need Help?

If you encounter issues:
1. Check the verification queries in the import script output
2. Run: `SELECT * FROM parties ORDER BY created_at DESC LIMIT 10;`
3. Run: `SELECT * FROM investors WHERE introduced_by IS NOT NULL LIMIT 10;`
4. Run: `SELECT * FROM agreements WHERE kind = 'distributor_commission';`

Good luck with your import! 🚀
