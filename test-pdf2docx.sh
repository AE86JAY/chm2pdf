#!/bin/bash
# PDF2DOCX功能测试脚本

echo "=== PDF2DOCX功能完整性测试 ==="
echo ""

# 检查必要目录是否存在
if [ ! -d "PDF2DOCX" ]; then
    echo "错误: PDF2DOCX目录不存在"
    echo "请先应用补丁: ./patches/apply-patches.sh"
    exit 1
fi

# 检查所有必要脚本是否存在
required_scripts=("PDF2DOCX/main-pdf2docx.sh" 
                  "PDF2DOCX/pdf-convert.sh" 
                  "PDF2DOCX/split-docx.sh" 
                  "PDF2DOCX/find-pdf.sh")

missing_scripts=()
valid_scripts=()

echo "检查核心脚本文件..."
echo "-------------------"

for script in "${required_scripts[@]}"; do
    if [ -f "$script" ]; then
        echo "✓ $script 存在"
        valid_scripts+=("$script")
        
        # 检查脚本头部是否包含正确的shebang
        if head -n 1 "$script" | grep -q '#!/bin/bash'; then
            echo "  - ✓ shebang正确"
        else
            echo "  - ⚠ shebang不正确"
        fi
        
        # 检查脚本是否有基本的函数定义或主要逻辑
        if grep -q -E 'function |\{|\<main\>|\[\[|if |for ' "$script"; then
            echo "  - ✓ 包含有效代码逻辑"
        else
            echo "  - ⚠ 可能缺少主要逻辑"
        fi
    else
        echo "✗ $script 不存在"
        missing_scripts+=("$script")
    fi
done

echo ""

# 检查补丁文件是否存在
if [ -f "patches/001_pdf2docx_feature.patch" ]; then
    echo "✓ 补丁文件 patches/001_pdf2docx_feature.patch 存在"
    echo "  - 大小: $(wc -l < "patches/001_pdf2docx_feature.patch") 行"
    
    # 检查补丁内容
    if grep -q "PDF2DOCX" "patches/001_pdf2docx_feature.patch"; then
        echo "  - ✓ 包含PDF2DOCX相关内容"
    else
        echo "  - ⚠ 可能不包含PDF2DOCX相关内容"
    fi
else
    echo "✗ 补丁文件不存在"
fi

echo ""

# 检查补丁管理脚本
patch_scripts=("patches/manage-patches.sh" "patches/apply-patches.sh")

echo "检查补丁管理脚本..."
echo "-------------------"

for script in "${patch_scripts[@]}"; do
    if [ -f "$script" ]; then
        echo "✓ $script 存在"
    else
        echo "✗ $script 不存在"
    fi
done

echo ""

# 检查字体增强补丁
if [ -f "PDF2DOCX/enhance-font-size.patch" ]; then
    echo "✓ 字体增强补丁存在"
else
    echo "⚠ 字体增强补丁不存在"
fi

echo ""

# 显示测试结果摘要
echo "=== 测试结果摘要 ==="
echo "核心脚本: ${#valid_scripts[@]} 个存在, ${#missing_scripts[@]} 个缺失"

if [ ${#missing_scripts[@]} -eq 0 ]; then
    echo ""
    echo "🎉 PDF2DOCX功能文件结构完整!"
    echo ""
    echo "使用说明:"
    echo "1. 确保已安装所需Python库: pip install pdfplumber python-docx"
    echo "2. 运行主脚本开始转换: ./PDF2DOCX/main-pdf2docx.sh"
    echo "3. 或使用补丁管理: ./patches/manage-patches.sh [命令]"
    exit 0
else
    echo ""
    echo "❌ 测试失败: 缺少核心脚本文件"
    echo "请应用补丁或重新创建缺失的文件"
    exit 1
fi
