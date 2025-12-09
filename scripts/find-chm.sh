#!/bin/bash

# 查找CHM文件脚本
set -e

INPUT_DIR="${GITHUB_WORKSPACE}/input"
TEMP_DIR="${GITHUB_WORKSPACE}/temp"
CHM_LIST_FILE="${TEMP_DIR}/chm_files.txt"

# 创建文件列表
echo "Searching for CHM files in ${INPUT_DIR}..."
find "${INPUT_DIR}" -name "*.chm" -type f > "${CHM_LIST_FILE}" || true

# 检查文件数量
CHM_COUNT=$(wc -l < "${CHM_LIST_FILE}" || echo "0")

if [ "$CHM_COUNT" -eq 0 ]; then
    echo "No CHM files found in ${INPUT_DIR}"
    echo "" > "${CHM_LIST_FILE}"
else
    echo "Found $CHM_COUNT CHM file(s):"
    cat "${CHM_LIST_FILE}"
fi