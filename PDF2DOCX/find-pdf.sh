#!/bin/bash

# PDF文件查找脚本
set -e

# 环境变量
WORKSPACE="${GITHUB_WORKSPACE:-$(pwd)}"
INPUT_DIR="${INPUT_DIR:-"${WORKSPACE}/input"}"

# 确保输入目录存在
mkdir -p "${INPUT_DIR}"

echo "=============================================="
echo "PDF文件查找脚本"
echo "查找目录: ${INPUT_DIR}"
echo "=============================================="

# 查找所有PDF文件
PDF_FILES=()
while IFS= read -r -d '' file; do
    PDF_FILES+=("$file")
done < <(find "${INPUT_DIR}" -type f -name "*.pdf" -print0 2>/dev/null || echo "")

# 检查是否找到PDF文件
if [ ${#PDF_FILES[@]} -eq 0 ]; then
    echo "未找到PDF文件在 ${INPUT_DIR} 目录"
    exit 0
fi

echo "找到 ${#PDF_FILES[@]} 个PDF文件:"
for i in "${!PDF_FILES[@]}"; do
    file="${PDF_FILES[$i]}"
    size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo "0")
    size_mb=$((size / 1024 / 1024))
    echo "[$((i + 1))] $(basename "$file") (${size_mb} MB)"
done
echo ""

# 输出找到的文件列表供其他脚本使用
echo "PDF_FILES_COUNT=${#PDF_FILES[@]}"
for file in "${PDF_FILES[@]}"; do
    echo "PDF_FILE=${file}"
done

echo ""
echo "PDF文件查找完成。找到 ${#PDF_FILES[@]} 个文件。"
