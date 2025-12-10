# Simple PDF2DOCX test script

Write-Host "PDF2DOCX Functionality Test"
Write-Host ""

# Check PDF2DOCX directory
if (Test-Path "PDF2DOCX") {
    Write-Host "PDF2DOCX directory exists: OK"
} else {
    Write-Host "PDF2DOCX directory does not exist: FAILED"
}

# Check main scripts
$scripts = @("PDF2DOCX/main-pdf2docx.sh", 
            "PDF2DOCX/pdf-convert.sh", 
            "PDF2DOCX/split-docx.sh", 
            "PDF2DOCX/find-pdf.sh")

Write-Host ""
Write-Host "Checking core scripts:"

foreach ($script in $scripts) {
    if (Test-Path $script) {
        Write-Host "${script}: OK"
    } else {
        Write-Host "${script}: MISSING"
    }
}

# Check patch files
Write-Host ""
Write-Host "Checking patch files:"

if (Test-Path "patches/001_pdf2docx_feature.patch") {
    Write-Host "001_pdf2docx_feature.patch: OK"
} else {
    Write-Host "001_pdf2docx_feature.patch: MISSING"
}

if (Test-Path "PDF2DOCX/enhance-font-size.patch") {
    Write-Host "enhance-font-size.patch: OK"
} else {
    Write-Host "enhance-font-size.patch: MISSING"
}

Write-Host ""
Write-Host "Test completed."