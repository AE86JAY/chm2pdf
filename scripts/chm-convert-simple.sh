#!/bin/bash

# 简化的CHM转PDF脚本
set -e

# ==============================================
# 配置部分（从环境变量读取）
# ==============================================
# 默认值
DEFAULT_FONT_SIZE=12
DEFAULT_ZOOM_LEVEL=1.0
DEFAULT_SPLIT_PAGES=10

# 从环境变量读取或使用默认值
FONT_SIZE="${FONT_SIZE:-$DEFAULT_FONT_SIZE}"
ZOOM_LEVEL="${ZOOM_LEVEL:-$DEFAULT_ZOOM_LEVEL}"
SPLIT_PAGES="${SPLIT_PAGES:-$DEFAULT_SPLIT_PAGES}"

# 验证字体大小有效性
if ! [[ "$FONT_SIZE" =~ ^[0-9]+$ ]] || [ "$FONT_SIZE" -lt 8 ] || [ "$FONT_SIZE" -gt 24 ]; then
    echo "警告: 字体大小 $FONT_SIZE 无效，使用默认值 $DEFAULT_FONT_SIZE"
    FONT_SIZE="$DEFAULT_FONT_SIZE"
fi

CHM_FILE="$1"
WORKSPACE="${GITHUB_WORKSPACE}"
OUTPUT_DIR="${WORKSPACE}/output"
BASE_NAME=$(basename "$CHM_FILE" .chm)
PDF_OUTPUT="${OUTPUT_DIR}/${BASE_NAME}.pdf"

echo "Converting CHM to PDF (simple method)..."
echo "Font size: ${FONT_SIZE}pt"

# 使用Calibre进行完整转换
if command -v ebook-convert &> /dev/null; then
    echo "Using Calibre's ebook-convert with full content extraction..."
    
    # 创建一个临时目录用于解压
    TEMP_DIR=$(mktemp -d)
    
    # 使用ebook-convert，启用所有内容提取选项
    ebook-convert "$CHM_FILE" "$PDF_OUTPUT" \
        --pdf-page-margin-left 10 \
        --pdf-page-margin-right 10 \
        --pdf-page-margin-top 15 \
        --pdf-page-margin-bottom 15 \
        --pdf-default-font-size ${FONT_SIZE} \
        --pdf-header-template " " \
        --pdf-footer-template '<p style="text-align:center; font-size: 10pt;">Page <i>_PAGENUM_</i> of <i>_SECTIONPAGES_</i></p>' \
        --chapter "//*[((name()='h1') or (name()='h2'))]" \
        --chapter-mark "pagebreak" \
        --page-breaks-before "//*[name()='h1' or name()='h2' or @class='pagebreak']" \
        --max-levels 0 \
        --no-chapters-in-toc \
        --breadth-first \
        --dont-split-on-page-breaks \
        --flow-size 0 \
        --margin-left 10 \
        --margin-right 10 \
        --margin-top 15 \
        --margin-bottom 15 \
        --embed-all-fonts \
        --subset-embedded-fonts \
        --paper-size a4 \
        --pdf-add-toc \
        --toc-threshold 0 \
        --linearize-tables \
        --base-font-size ${FONT_SIZE} \
        --verbose
    
    if [ $? -eq 0 ] && [ -f "$PDF_OUTPUT" ]; then
        echo "Conversion completed successfully!"
        
        # 检查页数
        if command -v pdfinfo &> /dev/null; then
            PAGE_COUNT=$(pdfinfo "$PDF_OUTPUT" 2>/dev/null | grep "Pages:" | awk '{print $2}')
            echo "Pages converted: ${PAGE_COUNT:-"unknown"}"
        fi
        
        # 清理临时目录
        rm -rf "$TEMP_DIR"
        exit 0
    else
        echo "Calibre conversion failed"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
else
    echo "ebook-convert not found. Please install Calibre."
    exit 1
fi
