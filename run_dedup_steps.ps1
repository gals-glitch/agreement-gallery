# Investor Deduplication Helper Script
# Guides you through each SQL file step-by-step
# Copies each file to clipboard when ready

$projectUrl = "https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys/sql/new"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Investor Deduplication - Step-by-Step" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script will guide you through the dedup process." -ForegroundColor White
Write-Host "Each step copies SQL to clipboard for you to paste in SQL Editor." -ForegroundColor White
Write-Host ""
Write-Host "IMPORTANT: Keep the SQL Editor tab open from Step 3 to Step 4!" -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to begin"

# Step 0
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "STEP 0: Check Current State (Read-Only)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This shows current investor counts and duplicate pairs." -ForegroundColor Gray
Write-Host "Expected: ~2138 total, ~2097 vantage, ~41 DISTRIBUTOR, ~22 dup pairs" -ForegroundColor Gray
Write-Host ""

Get-Content "dedup_step0_exact_count.sql" -Raw | Set-Clipboard
Write-Host "✓ SQL copied to clipboard!" -ForegroundColor Green
Write-Host ""
Write-Host "Next:" -ForegroundColor Yellow
Write-Host "1. Open SQL Editor: $projectUrl" -ForegroundColor White
Write-Host "2. Paste and run the query" -ForegroundColor White
Write-Host "3. Review the counts" -ForegroundColor White
Write-Host ""
Read-Host "Press Enter when done to continue to Step 1"

# Step 1
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "STEP 1: Create Schema Helpers" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Creates: investor_merge_log table, merged_into_id column" -ForegroundColor Gray
Write-Host "Safe to run multiple times - uses IF NOT EXISTS" -ForegroundColor Gray
Write-Host ""

Get-Content "dedup_step1_schema_helpers.sql" -Raw | Set-Clipboard
Write-Host "✓ SQL copied to clipboard!" -ForegroundColor Green
Write-Host ""
Write-Host "Next:" -ForegroundColor Yellow
Write-Host "1. Paste in SQL Editor" -ForegroundColor White
Write-Host "2. Run the query" -ForegroundColor White
Write-Host "3. Verify all checks return 'true'" -ForegroundColor White
Write-Host ""
Read-Host "Press Enter when done to continue to Step 2"

# Step 2
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "STEP 2: Create Merge Function" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Creates: merge_investors(src_id, dst_id, reason) function" -ForegroundColor Gray
Write-Host "This does the actual work of updating FKs and logging" -ForegroundColor Gray
Write-Host ""

Get-Content "dedup_step2_merge_function.sql" -Raw | Set-Clipboard
Write-Host "✓ SQL copied to clipboard!" -ForegroundColor Green
Write-Host ""
Write-Host "Next:" -ForegroundColor Yellow
Write-Host "1. Paste in SQL Editor" -ForegroundColor White
Write-Host "2. Run the query" -ForegroundColor White
Write-Host "3. Verify function was created successfully" -ForegroundColor White
Write-Host ""
Read-Host "Press Enter when done to continue to Step 3"

# Step 3
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "STEP 3: Build Merge Plan" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️ IMPORTANT: Creates TEMP table - keep tab open!" -ForegroundColor Yellow
Write-Host ""
Write-Host "This finds the 22 duplicate pairs and shows them for review." -ForegroundColor Gray
Write-Host "REVIEW the pairs carefully before Step 4!" -ForegroundColor Gray
Write-Host ""

Get-Content "dedup_step3_build_plan.sql" -Raw | Set-Clipboard
Write-Host "✓ SQL copied to clipboard!" -ForegroundColor Green
Write-Host ""
Write-Host "Next:" -ForegroundColor Yellow
Write-Host "1. Paste in SQL Editor" -ForegroundColor White
Write-Host "2. Run the query" -ForegroundColor White
Write-Host "3. REVIEW the 22 merge pairs carefully" -ForegroundColor White
Write-Host "4. KEEP THIS TAB OPEN (temp table needed for Step 4)" -ForegroundColor Red
Write-Host ""
$confirm = Read-Host "Have you reviewed the pairs and are they correct? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host ""
    Write-Host "⚠️ Please review the merge plan before continuing." -ForegroundColor Yellow
    Write-Host "Run this script again when ready to continue." -ForegroundColor Yellow
    Write-Host ""
    exit
}

Write-Host ""
Read-Host "Press Enter when ready to continue to Step 4 (THE DESTRUCTIVE STEP)"

# Step 4
Write-Host ""
Write-Host "==========================================" -ForegroundColor Red
Write-Host "STEP 4: EXECUTE MERGES (DESTRUCTIVE)" -ForegroundColor Red
Write-Host "==========================================" -ForegroundColor Red
Write-Host ""
Write-Host "⚠️ THIS WILL MODIFY YOUR DATABASE!" -ForegroundColor Yellow
Write-Host ""
Write-Host "This will:" -ForegroundColor Gray
Write-Host "- Update all FK references (agreements, transactions, etc.)" -ForegroundColor Gray
Write-Host "- Soft-delete 22 DISTRIBUTOR records" -ForegroundColor Gray
Write-Host "- Log everything in investor_merge_log" -ForegroundColor Gray
Write-Host ""
Write-Host "Data is NOT lost - merged records are soft-deleted and logged." -ForegroundColor Green
Write-Host ""

$finalConfirm = Read-Host "Type 'EXECUTE' to proceed with merging"
if ($finalConfirm -ne "EXECUTE") {
    Write-Host ""
    Write-Host "Aborted. No changes made." -ForegroundColor Yellow
    Write-Host ""
    exit
}

Get-Content "dedup_step4_execute.sql" -Raw | Set-Clipboard
Write-Host ""
Write-Host "✓ SQL copied to clipboard!" -ForegroundColor Green
Write-Host ""
Write-Host "Next:" -ForegroundColor Yellow
Write-Host "1. Paste in SQL Editor (SAME TAB as Step 3!)" -ForegroundColor White
Write-Host "2. Run the query" -ForegroundColor White
Write-Host "3. Wait for all 22 merges to complete" -ForegroundColor White
Write-Host "4. Review the results (should show FK update counts)" -ForegroundColor White
Write-Host ""
Read-Host "Press Enter when merges are complete to continue to Step 5"

# Step 5
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "STEP 5: Validate Results" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Verifies everything worked correctly." -ForegroundColor Gray
Write-Host "Expected: 22 merged records, no duplicates, all FKs updated" -ForegroundColor Gray
Write-Host ""

Get-Content "dedup_step5_validation.sql" -Raw | Set-Clipboard
Write-Host "✓ SQL copied to clipboard!" -ForegroundColor Green
Write-Host ""
Write-Host "Next:" -ForegroundColor Yellow
Write-Host "1. Paste in SQL Editor" -ForegroundColor White
Write-Host "2. Run the query" -ForegroundColor White
Write-Host "3. Verify all checks pass" -ForegroundColor White
Write-Host "4. Look for SUCCESS message" -ForegroundColor White
Write-Host ""
Read-Host "Press Enter when done"

# Complete
Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "DEDUPLICATION COMPLETE!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor White
Write-Host "- 22 DISTRIBUTOR records merged into Vantage records" -ForegroundColor Green
Write-Host "- All FK references updated" -ForegroundColor Green
Write-Host "- Merge log created for audit trail" -ForegroundColor Green
Write-Host "- Original data preserved (soft-delete)" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Refresh your app at http://localhost:8080/investors" -ForegroundColor White
Write-Host "2. You should now see 2,116 active investors (2097 + 19)" -ForegroundColor White
Write-Host "3. The 22 duplicate DISTRIBUTOR records are hidden (inactive)" -ForegroundColor White
Write-Host ""
Write-Host "Documentation: See DEDUP_GUIDE.md for details" -ForegroundColor Cyan
Write-Host ""
