# PDF2DOCX功能测试脚本 (PowerShell版本)

Write-Host "=== PDF2DOCX功能完整性测试 ==="
Write-Host ""

# 检查必要目录是否存在
if (-not (Test-Path -Path "PDF2DOCX" -PathType Container)) {
    Write-Host "错误: PDF2DOCX目录不存在"
    Write-Host "请先应用补丁或确保文件已正确创建"
    exit 1
}

# 检查所有必要脚本是否存在
$required_scripts = @("PDF2DOCX/main-pdf2docx.sh", 
                      "PDF2DOCX/pdf-convert.sh", 
                      "PDF2DOCX/split-docx.sh", 
                      "PDF2DOCX/find-pdf.sh")

$missing_scripts = @()
$valid_scripts = @()

Write-Host "检查核心脚本文件..."
Write-Host "-------------------"

foreach ($script in $required_scripts) {
    if (Test-Path -Path $script -PathType Leaf) {
        Write-Host "✓ $script 存在"
        $valid_scripts += $script
        
        # 检查脚本头部是否包含正确的shebang
        $first_line = Get-Content -Path $script -TotalCount 1
        if ($first_line -match '#!/bin/bash') {
            Write-Host "  - ✓ shebang正确"
        } else {
            Write-Host "  - ⚠ shebang不正确"
        }
        
        # 检查文件大小是否合理（至少包含一些内容）
        $file_size = (Get-Item $script).Length
        if ($file_size -gt 100) {
            Write-Host "  - ✓ 文件大小合理 ($file_size 字节)"
        } else {
            Write-Host "  - ⚠ 文件可能内容较少 ($file_size 字节)"
        }
    } else {
        Write-Host "✗ $script 不存在"
        $missing_scripts += $script
    }
}

Write-Host ""

# 检查补丁文件是否存在
if (Test-Path -Path "patches/001_pdf2docx_feature.patch" -PathType Leaf) {
    Write-Host "✓ 补丁文件 patches/001_pdf2docx_feature.patch 存在"
    $line_count = (Get-Content -Path "patches/001_pdf2docx_feature.patch").Count
    Write-Host "  - 大小: $line_count 行"
    
    # 检查补丁内容
    $content = Get-Content -Path "patches/001_pdf2docx_feature.patch" -Raw
    if ($content -match "PDF2DOCX") {
        Write-Host "  - ✓ 包含PDF2DOCX相关内容"
    } else {
        Write-Host "  - ⚠ 可能不包含PDF2DOCX相关内容"
    }
} else {
    Write-Host "✗ 补丁文件不存在"
}

Write-Host ""

# 检查补丁管理脚本
$patch_scripts = @("patches/manage-patches.sh", "patches/apply-patches.sh")

Write-Host "检查补丁管理脚本..."
Write-Host "-------------------"

foreach ($script in $patch_scripts) {
    if (Test-Path -Path $script -PathType Leaf) {
        Write-Host "✓ $script 存在"
    } else {
        Write-Host "✗ $script 不存在"
    }
}

Write-Host ""

# 检查字体增强补丁
if (Test-Path -Path "PDF2DOCX/enhance-font-size.patch" -PathType Leaf) {
    Write-Host "✓ 字体增强补丁存在"
} else {
    Write-Host "⚠ 字体增强补丁不存在"
}

Write-Host ""

# 显示测试结果摘要
Write-Host "=== 测试结果摘要 ==="
Write-Host "核心脚本: ${valid_scripts.Count} 个存在, ${missing_scripts.Count} 个缺失"

if ($missing_scripts.Count -eq 0) {
    Write-Host ""
    Write-Host "PDF2DOCX功能文件结构完整!"
    Write-Host ""
    Write-Host "使用说明:"
    Write-Host "1. 确保已安装所需Python库: pip install pdfplumber python-docx"
    Write-Host "2. 在Linux/Mac环境下，确保脚本有执行权限"
    Write-Host "3. 运行主脚本开始转换: ./PDF2DOCX/main-pdf2docx.sh"
    Write-Host "4. 或使用补丁管理功能"
    exit 0
} else {
    Write-Host ""
    Write-Host "测试失败: 缺少核心脚本文件"
    Write-Host "请确保所有文件已正确创建或应用补丁"
    exit 1
}
