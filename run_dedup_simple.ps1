# Investor Deduplication Helper Script
# Simple version without special characters

$projectUrl = "https://supabase.com/dashboard/project/qwgicrdcoqdketqhxbys/sql/new"

Write-Host ""
Write-Host "=========================================="
Write-Host "Investor Deduplication - Step-by-Step"
Write-Host "=========================================="
Write-Host ""
Write-Host "This script will guide you through the dedup process."
Write-Host "Each step copies SQL to clipboard for you to paste in SQL Editor."
Write-Host ""
Write-Host "IMPORTANT: Keep the SQL Editor tab open from Step 3 to Step 4!"
Write-Host ""
Read-Host "Press Enter to begin"

# Step 0
Write-Host ""
Write-Host "=========================================="
Write-Host "STEP 0: Check Current State (Read-Only)"
Write-Host "=========================================="
Write-Host ""
Write-Host "This shows current investor counts and duplicate pairs."
Write-Host "Expected: ~2138 total, ~2097 vantage, ~41 DISTRIBUTOR, ~22 dup pairs"
Write-Host ""

Get-Content "dedup_step0_exact_count.sql" -Raw | Set-Clipboard
Write-Host "[OK] SQL copied to clipboard!"
Write-Host ""
Write-Host "Next:"
Write-Host "1. Open SQL Editor: $projectUrl"
Write-Host "2. Paste and run the query"
Write-Host "3. Review the counts"
Write-Host ""
Read-Host "Press Enter when done to continue to Step 1"

# Step 1
Write-Host ""
Write-Host "=========================================="
Write-Host "STEP 1: Create Schema Helpers"
Write-Host "=========================================="
Write-Host ""
Write-Host "Creates: investor_merge_log table, merged_into_id column"
Write-Host "Safe to run multiple times - uses IF NOT EXISTS"
Write-Host ""

Get-Content "dedup_step1_schema_helpers.sql" -Raw | Set-Clipboard
Write-Host "[OK] SQL copied to clipboard!"
Write-Host ""
Write-Host "Next:"
Write-Host "1. Paste in SQL Editor"
Write-Host "2. Run the query"
Write-Host "3. Verify all checks return 'true'"
Write-Host ""
Read-Host "Press Enter when done to continue to Step 2"

# Step 2
Write-Host ""
Write-Host "=========================================="
Write-Host "STEP 2: Create Merge Function"
Write-Host "=========================================="
Write-Host ""
Write-Host "Creates: merge_investors function"
Write-Host "This does the actual work of updating FKs and logging"
Write-Host ""

Get-Content "dedup_step2_merge_function.sql" -Raw | Set-Clipboard
Write-Host "[OK] SQL copied to clipboard!"
Write-Host ""
Write-Host "Next:"
Write-Host "1. Paste in SQL Editor"
Write-Host "2. Run the query"
Write-Host "3. Verify function was created successfully"
Write-Host ""
Read-Host "Press Enter when done to continue to Step 3"

# Step 3
Write-Host ""
Write-Host "=========================================="
Write-Host "STEP 3: Build Merge Plan"
Write-Host "=========================================="
Write-Host ""
Write-Host "IMPORTANT: Creates TEMP table - keep tab open!"
Write-Host ""
Write-Host "This finds the 22 duplicate pairs and shows them for review."
Write-Host "REVIEW the pairs carefully before Step 4!"
Write-Host ""

Get-Content "dedup_step3_build_plan.sql" -Raw | Set-Clipboard
Write-Host "[OK] SQL copied to clipboard!"
Write-Host ""
Write-Host "Next:"
Write-Host "1. Paste in SQL Editor"
Write-Host "2. Run the query"
Write-Host "3. REVIEW the 22 merge pairs carefully"
Write-Host "4. KEEP THIS TAB OPEN - temp table needed for Step 4"
Write-Host ""
$confirm = Read-Host "Have you reviewed the pairs and are they correct? Type 'yes' to continue"
if ($confirm -ne "yes") {
    Write-Host ""
    Write-Host "Please review the merge plan before continuing."
    Write-Host "Run this script again when ready to continue."
    Write-Host ""
    exit
}

Write-Host ""
Read-Host "Press Enter when ready to continue to Step 4 (THE DESTRUCTIVE STEP)"

# Step 4
Write-Host ""
Write-Host "=========================================="
Write-Host "STEP 4: EXECUTE MERGES (DESTRUCTIVE)"
Write-Host "=========================================="
Write-Host ""
Write-Host "WARNING: THIS WILL MODIFY YOUR DATABASE!"
Write-Host ""
Write-Host "This will:"
Write-Host "- Update all FK references"
Write-Host "- Soft-delete 22 DISTRIBUTOR records"
Write-Host "- Log everything in investor_merge_log"
Write-Host ""
Write-Host "Data is NOT lost - merged records are soft-deleted and logged."
Write-Host ""

$finalConfirm = Read-Host "Type 'EXECUTE' to proceed with merging"
if ($finalConfirm -ne "EXECUTE") {
    Write-Host ""
    Write-Host "Aborted. No changes made."
    Write-Host ""
    exit
}

Get-Content "dedup_step4_execute.sql" -Raw | Set-Clipboard
Write-Host ""
Write-Host "[OK] SQL copied to clipboard!"
Write-Host ""
Write-Host "Next:"
Write-Host "1. Paste in SQL Editor (SAME TAB as Step 3!)"
Write-Host "2. Run the query"
Write-Host "3. Wait for all 22 merges to complete"
Write-Host "4. Review the results (should show FK update counts)"
Write-Host ""
Read-Host "Press Enter when merges are complete to continue to Step 5"

# Step 5
Write-Host ""
Write-Host "=========================================="
Write-Host "STEP 5: Validate Results"
Write-Host "=========================================="
Write-Host ""
Write-Host "Verifies everything worked correctly."
Write-Host "Expected: 22 merged records, no duplicates, all FKs updated"
Write-Host ""

Get-Content "dedup_step5_validation.sql" -Raw | Set-Clipboard
Write-Host "[OK] SQL copied to clipboard!"
Write-Host ""
Write-Host "Next:"
Write-Host "1. Paste in SQL Editor"
Write-Host "2. Run the query"
Write-Host "3. Verify all checks pass"
Write-Host "4. Look for SUCCESS message"
Write-Host ""
Read-Host "Press Enter when done"

# Complete
Write-Host ""
Write-Host "=========================================="
Write-Host "DEDUPLICATION COMPLETE!"
Write-Host "=========================================="
Write-Host ""
Write-Host "Summary:"
Write-Host "- 22 DISTRIBUTOR records merged into Vantage records"
Write-Host "- All FK references updated"
Write-Host "- Merge log created for audit trail"
Write-Host "- Original data preserved (soft-delete)"
Write-Host ""
Write-Host "Next Steps:"
Write-Host "1. Refresh your app at http://localhost:8080/investors"
Write-Host "2. You should now see 2,116 active investors"
Write-Host "3. The 22 duplicate DISTRIBUTOR records are hidden (inactive)"
Write-Host ""
Write-Host "Documentation: See DEDUP_GUIDE.md for details"
Write-Host ""
