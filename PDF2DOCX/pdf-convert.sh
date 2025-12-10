#!/bin/bash

# PDF转DOCX脚本（完整转换所有页面）
set -e

# ==============================================
# 配置部分（从环境变量读取）
# ==============================================
# 默认值
DEFAULT_FONT_SIZE=12
DEFAULT_SPLIT_PAGES=10

# 从环境变量读取或使用默认值
FONT_SIZE="${FONT_SIZE:-$DEFAULT_FONT_SIZE}"
SPLIT_PAGES="${SPLIT_PAGES:-$DEFAULT_SPLIT_PAGES}"

# 验证字体大小有效性
if ! [[ "$FONT_SIZE" =~ ^[0-9]+$ ]] || [ "$FONT_SIZE" -lt 8 ] || [ "$FONT_SIZE" -gt 24 ]; then
    echo "警告: 字体大小 $FONT_SIZE 无效，使用默认值 $DEFAULT_FONT_SIZE"
    FONT_SIZE="$DEFAULT_FONT_SIZE"
fi

# 验证分割页数有效性
if ! [[ "$SPLIT_PAGES" =~ ^[0-9]+$ ]] || [ "$SPLIT_PAGES" -lt 0 ]; then
    echo "警告: 分割页数 $SPLIT_PAGES 无效，使用默认值 $DEFAULT_SPLIT_PAGES"
    SPLIT_PAGES="$DEFAULT_SPLIT_PAGES"
fi

echo "=============================================="
echo "PDF转DOCX转换"
echo "配置参数:"
echo "  - 字体大小: ${FONT_SIZE}pt"
echo "  - 分割页数: ${SPLIT_PAGES} (0=不分割)"
echo "=============================================="

# 参数：PDF文件路径
PDF_FILE="$1"
PDF_FILE_SIZE=$(stat -c%s "$PDF_FILE" 2>/dev/null || stat -f%z "$PDF_FILE")

echo "处理文件: $(basename "$PDF_FILE")"
echo "文件大小: $((PDF_FILE_SIZE / 1024 / 1024)) MB"

# 环境变量
WORKSPACE="${GITHUB_WORKSPACE:-$(pwd)}"
INPUT_DIR="${INPUT_DIR:-"${WORKSPACE}/input"}"
OUTPUT_DIR="${OUTPUT_DIR:-"${WORKSPACE}/output"}"
TEMP_DIR="${TEMP_DIR:-"${WORKSPACE}/temp"}"

# 创建临时工作目录
JOB_ID=$(date +%s%N | md5sum | cut -c1-8 2>/dev/null || echo "temp")
WORK_DIR="${TEMP_DIR}/work_${JOB_ID}"
mkdir -p "${WORK_DIR}"
mkdir -p "${OUTPUT_DIR}"

# 生成输出文件路径
BASE_NAME=$(basename "$PDF_FILE" .pdf)
DOCX_OUTPUT="${OUTPUT_DIR}/${BASE_NAME}.docx"

# 创建Python脚本来处理PDF到DOCX的转换
cat > "${WORK_DIR}/convert_pdf_to_docx.py" << EOF
#!/usr/bin/env python3
"""
PDF到DOCX转换脚本 - 确保转换所有页面并支持字体大小调整
"""

import os
import sys
import pdfplumber
from docx import Document
from docx.shared import Pt, Inches
from docx.enum.text import WD_ALIGN_PARAGRAPH

font_size = ${FONT_SIZE}

def convert_pdf_to_docx(pdf_path, docx_output):
    """将PDF文件转换为DOCX文件"""
    
    print(f"开始转换: {pdf_path} -> {docx_output}")
    
    # 创建新的Word文档
    doc = Document()
    
    # 设置页面边距
    sections = doc.sections
    for section in sections:
        section.top_margin = Inches(1.0)
        section.bottom_margin = Inches(1.0)
        section.left_margin = Inches(1.25)
        section.right_margin = Inches(1.25)
    
    # 打开PDF文件
    try:
        with pdfplumber.open(pdf_path) as pdf:
            total_pages = len(pdf.pages)
            print(f"PDF总页数: {total_pages}")
            
            # 遍历每一页
            for page_num, page in enumerate(pdf.pages, 1):
                print(f"处理第 {page_num}/{total_pages} 页...")
                
                # 提取文本
                text = page.extract_text()
                
                if text:
                    # 添加页码
                    page_header = doc.add_paragraph()
                    page_header.add_run(f"第 {page_num} 页")
                    page_header.alignment = WD_ALIGN_PARAGRAPH.CENTER
                    
                    # 设置段落字体大小
                    for run in page_header.runs:
                        run.font.size = Pt(font_size - 2)
                    
                    # 按行分割文本并添加到文档
                    lines = text.split('\n')
                    for line in lines:
                        if line.strip():
                            paragraph = doc.add_paragraph(line.strip())
                            
                            # 设置段落字体大小
                            for run in paragraph.runs:
                                run.font.size = Pt(font_size)
                
                # 在页面之间添加分页符（除了最后一页）
                if page_num < total_pages:
                    doc.add_page_break()
        
        # 保存DOCX文件
        doc.save(docx_output)
        print(f"DOCX文件已保存: {docx_output}")
        return True, total_pages
        
    except Exception as e:
        print(f"转换过程出错: {e}")
        return False, 0

def main():
    if len(sys.argv) != 3:
        print("Usage: python convert_pdf_to_docx.py <pdf_file> <docx_output>")
        sys.exit(1)
    
    pdf_file = sys.argv[1]
    docx_output = sys.argv[2]
    
    success, page_count = convert_pdf_to_docx(pdf_file, docx_output)
    
    if success:
        print(f"转换成功，总页数: {page_count}")
        return page_count
    else:
        print("转换失败")
        sys.exit(1)

if __name__ == "__main__":
    page_count = main()
    print(f"PAGE_COUNT:{page_count}")  # 输出页数供bash脚本使用
EOF

echo "开始PDF到DOCX转换..."

# 安装必要的Python库
echo "安装必要的Python库..."
pip3 install pdfplumber python-docx > /dev/null 2>&1 || echo "Python库安装失败或已安装"

# 运行转换脚本
echo "执行转换脚本..."
PAGE_COUNT=$(python3 "${WORK_DIR}/convert_pdf_to_docx.py" "$PDF_FILE" "$DOCX_OUTPUT")
PAGE_COUNT=$(echo "$PAGE_COUNT" | grep -oP 'PAGE_COUNT:\K\d+')

# 检查转换结果
if [ -f "$DOCX_OUTPUT" ] && [ -s "$DOCX_OUTPUT" ]; then
    DOCX_SIZE=$(stat -c%s "$DOCX_OUTPUT" 2>/dev/null || stat -f%z "$DOCX_OUTPUT")
    echo "DOCX创建成功: $(basename "$DOCX_OUTPUT")"
    echo "DOCX大小: $((DOCX_SIZE / 1024)) KB"
    echo "DOCX页数: ${PAGE_COUNT:-"未知"}"
    
    # 根据分割页数设置决定是否分割
    echo "分割设置: ${SPLIT_PAGES}页 (0=不分割)"
    
    # 确保PAGE_COUNT是有效的数字
    if ! echo "${PAGE_COUNT:-0}" | grep -qE '^[0-9]+$'; then
        PAGE_COUNT=0
    fi
    
    # 使用基本的bash语法进行条件判断
    if [ "$SPLIT_PAGES" -ne 0 ] && [ "${PAGE_COUNT}" -gt "0" ]; then
        if [ "${PAGE_COUNT}" -gt "$SPLIT_PAGES" ]; then
            echo "DOCX页数超过分割阈值，开始分割..."
            # 如果split-docx.sh存在，则调用它
            if [ -f "${WORKSPACE}/PDF2DOCX/split-docx.sh" ]; then
                "${WORKSPACE}/PDF2DOCX/split-docx.sh" "${DOCX_OUTPUT}" "${SPLIT_PAGES}"
            else
                echo "警告: split-docx.sh不存在，跳过分割"
            fi
        else
            echo "DOCX页数(${PAGE_COUNT})未超过分割阈值(${SPLIT_PAGES})，不进行分割。"
        fi
    elif [ "${PAGE_COUNT}" -eq 0 ]; then
        echo "警告: 无法确定DOCX页数，跳过分割"
    elif [ "$SPLIT_PAGES" -eq 0 ]; then
        echo "分割页数设置为0，不进行分割。"
    fi
else
    echo "创建DOCX文件失败"
    rm -rf "$WORK_DIR"
    exit 1
fi

# 清理临时文件
rm -rf "$WORK_DIR"
echo "转换成功完成!"
echo "=============================================="