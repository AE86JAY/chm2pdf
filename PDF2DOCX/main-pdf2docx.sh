#!/bin/bash

# PDF2DOCX主脚本 - 协调整个PDF到DOCX的转换流程
set -e

# 环境变量
WORKSPACE="${GITHUB_WORKSPACE:-$(pwd)}"
INPUT_DIR="${INPUT_DIR:-"${WORKSPACE}/input"}"
OUTPUT_DIR="${OUTPUT_DIR:-"${WORKSPACE}/output"}"
TEMP_DIR="${TEMP_DIR:-"${WORKSPACE}/temp"}"

# 创建必要的目录
mkdir -p "${INPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"
mkdir -p "${TEMP_DIR}"

echo "=============================================="
echo "PDF到DOCX自动转换工具"
echo "工作目录: ${WORKSPACE}"
echo "输入目录: ${INPUT_DIR}"
echo "输出目录: ${OUTPUT_DIR}"
echo "=============================================="

# 设置执行权限
chmod +x "${WORKSPACE}/PDF2DOCX/find-pdf.sh"
chmod +x "${WORKSPACE}/PDF2DOCX/pdf-convert.sh"
chmod +x "${WORKSPACE}/PDF2DOCX/split-docx.sh"

# 查找PDF文件
echo "正在查找PDF文件..."
source "${WORKSPACE}/PDF2DOCX/find-pdf.sh"

# 获取找到的PDF文件数量
PDF_FILES_COUNT=$(echo "$PDF_FILES_COUNT" | grep -oP '\d+' || echo "0")

if [ "$PDF_FILES_COUNT" -eq 0 ]; then
    echo "未找到PDF文件，退出程序"
    exit 0
fi

echo "开始转换 $PDF_FILES_COUNT 个PDF文件..."
echo ""

# 提取PDF文件列表并转换
ALL_FILES=$(echo "$PDF_FILE" | grep -oP 'PDF_FILE=\K.*' || echo "")

# 如果没有从环境变量中获取到文件列表，则直接查找
if [ -z "$ALL_FILES" ]; then
    # 直接查找PDF文件
    while IFS= read -r -d '' file; do
        echo "正在处理: $(basename "$file")"
        "${WORKSPACE}/PDF2DOCX/pdf-convert.sh" "$file"
        echo ""
    done < <(find "${INPUT_DIR}" -type f -name "*.pdf" -print0 2>/dev/null || echo "")
else
    # 从环境变量处理文件列表
    for pdf_file in $ALL_FILES; do
        if [ -f "$pdf_file" ]; then
            echo "正在处理: $(basename "$pdf_file")"
            "${WORKSPACE}/PDF2DOCX/pdf-convert.sh" "$pdf_file"
            echo ""
        else
            echo "警告: 文件不存在: $pdf_file"
        fi
    done
fi

echo "=============================================="
echo "PDF到DOCX转换完成!"
echo "请在以下目录查看结果:"
echo "${OUTPUT_DIR}"
echo "=============================================="
