$excelPath = "C:\Users\GalSamionov\OneDrive - Buligo Capital\Desktop\Party - Deal Mapping.xlsx"
$csvPath = "C:\Users\GalSamionov\OneDrive - Buligo Capital\Desktop\Party - Deal Mapping.csv"

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false

try {
    $workbook = $excel.Workbooks.Open($excelPath)
    $worksheet = $workbook.Sheets.Item(1)

    # Save as CSV (format code 6)
    $worksheet.SaveAs($csvPath, 6)

    Write-Host "Successfully converted to CSV: $csvPath"
}
catch {
    Write-Host "Error: $_"
}
finally {
    if ($workbook) { $workbook.Close($false) }
    $excel.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
}
