#!/bin/bash

# CHM转PDF脚本（完整转换所有页面）
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

# 验证分割页数有效性
if ! [[ "$SPLIT_PAGES" =~ ^[0-9]+$ ]] || [ "$SPLIT_PAGES" -lt 0 ]; then
    echo "警告: 分割页数 $SPLIT_PAGES 无效，使用默认值 $DEFAULT_SPLIT_PAGES"
    SPLIT_PAGES="$DEFAULT_SPLIT_PAGES"
fi

echo "=============================================="
echo "CHM转PDF转换"
echo "配置参数:"
echo "  - 字体大小: ${FONT_SIZE}pt"
echo "  - 缩放比例: ${ZOOM_LEVEL}"
echo "  - 分割页数: ${SPLIT_PAGES} (0=不分割)"
echo "=============================================="

# 参数：CHM文件路径
CHM_FILE="$1"
CHM_FILE_SIZE=$(stat -c%s "$CHM_FILE" 2>/dev/null || stat -f%z "$CHM_FILE")

echo "处理文件: $(basename "$CHM_FILE")"
echo "文件大小: $((CHM_FILE_SIZE / 1024 / 1024)) MB"

# 环境变量
WORKSPACE="${GITHUB_WORKSPACE}"
INPUT_DIR="${WORKSPACE}/input"
OUTPUT_DIR="${WORKSPACE}/output"
TEMP_DIR="${WORKSPACE}/temp"

# 创建临时工作目录
JOB_ID=$(date +%s%N | md5sum | cut -c1-8)
WORK_DIR="${TEMP_DIR}/work_${JOB_ID}"
mkdir -p "${WORK_DIR}"
mkdir -p "${OUTPUT_DIR}"

# 生成输出文件路径
BASE_NAME=$(basename "$CHM_FILE" .chm)
PDF_OUTPUT="${OUTPUT_DIR}/${BASE_NAME}.pdf"

# 创建Python脚本来处理完整转换
cat > "${WORK_DIR}/convert_full.py" << EOF
#!/usr/bin/env python3
"""
CHM完整转换脚本 - 确保转换所有页面
"""

import os
import sys
import tempfile
import subprocess
import re
from pathlib import Path

font_size = ${FONT_SIZE}
zoom_level = ${ZOOM_LEVEL}

def extract_chm_to_html(chm_path, output_dir):
    """解压CHM文件并提取所有HTML内容"""
    
    # 确保输出目录存在
    os.makedirs(output_dir, exist_ok=True)
    
    # 使用7z解压CHM文件
    print(f"Extracting {chm_path} to {output_dir}")
    cmd = ['7z', 'x', chm_path, f'-o{output_dir}', '-y']
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if result.returncode != 0:
        print(f"Extraction failed: {result.stderr}")
        return False
    
    return True

def find_all_html_files(directory):
    """查找目录中的所有HTML文件"""
    html_files = []
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.lower().endswith(('.html', '.htm')):
                html_files.append(os.path.join(root, file))
    
    # 按路径排序，确保一致性
    html_files.sort()
    return html_files

def find_hhc_file(directory):
    """查找.hhc文件（CHM目录文件）"""
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.lower().endswith('.hhc'):
                return os.path.join(root, file)
    return None

def parse_hhc_file(hhc_path):
    """解析.hhc文件获取目录结构"""
    try:
        with open(hhc_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        # 查找所有URL引用
        urls = re.findall(r'[Uu][Rr][Ll]="([^"]+)"', content)
        return urls
    except Exception as e:
        print(f"Failed to parse HHC file: {e}")
        return []

def create_master_html(html_files, hhc_urls, output_file, extracted_dir):
    """创建主HTML文件，包含所有内容"""
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write('''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Complete CHM Document</title>
    <style>
        /* 强制字体大小控制 - 确保在所有情况下生效 */
        body {
            font-family: Arial, sans-serif !important;
            font-size: ''' + str(font_size) + '''pt !important;
            margin: 0 !important;
            padding: 0 !important;
            line-height: 1.6 !important;
        }
        
        /* 强制覆盖所有元素的字体大小 */
        * {
            font-size: ''' + str(font_size) + '''pt !important;
        }
        
        /* 标题字体大小增强 */
        h1 {
            font-size: calc(''' + str(font_size) + '''pt + 6pt) !important;
            color: #333 !important;
            margin-top: 30px !important;
        }
        h2 {
            font-size: calc(''' + str(font_size) + '''pt + 4pt) !important;
            color: #333 !important;
            margin-top: 30px !important;
        }
        h3 {
            font-size: calc(''' + str(font_size) + '''pt + 2pt) !important;
            color: #333 !important;
            margin-top: 30px !important;
        }
        h4, h5, h6 {
            font-size: calc(''' + str(font_size) + '''pt + 1pt) !important;
            color: #333 !important;
            margin-top: 30px !important;
        }
        
        /* 段落和文本 */
        p {
            font-size: ''' + str(font_size) + '''pt !important;
            margin: 15px 0 !important;
        }
        
        /* 代码和预格式化文本 */
        code, pre {
            font-family: 'Courier New', monospace !important;
            font-size: calc(''' + str(font_size) + '''pt - 1pt) !important;
        }
        
        /* 表格和列表 */
        table, th, td {
            font-size: ''' + str(font_size) + '''pt !important;
        }
        li {
            font-size: ''' + str(font_size) + '''pt !important;
        }
        
        /* 内联元素覆盖 */
        span, div {
            font-size: ''' + str(font_size) + '''pt !important;
        }
        
        /* 布局样式 */
        .page-break {
            page-break-after: always !important;
            height: 0 !important;
            margin: 0 !important;
            padding: 0 !important;
        }
        .content-page {
            padding: 20px !important;
        }
        img {
            max-width: 100% !important;
            height: auto !important;
        }
        
        /* 移除所有内联样式 */
        [style*="font-size"], [style*="font-size"] * {
            font-size: ''' + str(font_size) + '''pt !important;
        }
        
        /* 针对特定CHM内容的特殊处理 */
        .chm-content, .chm-body, .chm-text {
            font-size: ''' + str(font_size) + '''pt !important;
        }
    </style>
</head>
<body>
''')
        
        # 添加标题页
        f.write(f'''
    <div class="content-page">
        <h1>CHM Document Conversion</h1>
        <p>Source: {os.path.basename(html_files[0] if html_files else "Unknown")}</p>
        <p>Font size: {font_size}pt</p>
        <p>Converted on: {subprocess.check_output(["date"]).decode().strip()}</p>
        <hr>
    </div>
    <div class="page-break"></div>
''')
        
        # 如果有HHC文件，按照目录顺序添加内容
        if hhc_urls:
            print(f"Found {len(hhc_urls)} entries in HHC file")
            for url in hhc_urls:
                # 尝试找到对应的HTML文件
                for html_file in html_files:
                    if url in html_file or os.path.basename(html_file) in url:
                        try:
                            with open(html_file, 'r', encoding='utf-8', errors='ignore') as hf:
                                html_content = hf.read()
                            
                            # 清理HTML，移除不需要的标签
                            # 这里可以添加更多的HTML清理逻辑
                            f.write(f'    <div class="content-page">\n')
                            f.write(f'        {html_content}\n')
                            f.write(f'    </div>\n')
                            f.write(f'    <div class="page-break"></div>\n')
                            break
                        except Exception as e:
                            print(f"Error processing {html_file}: {e}")
                            continue
        else:
            # 如果没有HHC，按文件顺序添加所有HTML内容
            print(f"Processing {len(html_files)} HTML files in order")
            for i, html_file in enumerate(html_files):
                try:
                    with open(html_file, 'r', encoding='utf-8', errors='ignore') as hf:
                        html_content = hf.read()
                    
                    f.write(f'    <div class="content-page">\n')
                    f.write(f'        <!-- File {i+1}: {os.path.basename(html_file)} -->\n')
                    f.write(f'        {html_content}\n')
                    f.write(f'    </div>\n')
                    f.write(f'    <div class="page-break"></div>\n')
                    
                    # 每处理10个文件报告一次进度
                    if (i + 1) % 10 == 0:
                        print(f"  Processed {i+1}/{len(html_files)} files")
                        
                except Exception as e:
                    print(f"Error reading {html_file}: {e}")
                    continue
        
        f.write('''
</body>
</html>
''')
    
    return True

def convert_to_pdf(html_file, pdf_output):
    """使用wkhtmltopdf将HTML转换为PDF"""
    
    print(f"Converting to PDF: {pdf_output}")
    
    # wkhtmltopdf命令参数 - 移除不支持的参数
    cmd = [
        'wkhtmltopdf',
        '--enable-local-file-access',
        '--page-size', 'A4',
        '--margin-top', '20mm',
        '--margin-bottom', '20mm',
        '--margin-left', '15mm',
        '--margin-right', '15mm',
        '--encoding', 'UTF-8',
        '--zoom', str(zoom_level),
        '--quiet',
        html_file,
        pdf_output
    ]
    
    try:
        result = subprocess.run(cmd, check=True, capture_output=True, text=True)
        if result.stderr:
            print(f"wkhtmltopdf warnings: {result.stderr}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"PDF conversion failed: {e}")
        print(f"STDERR: {e.stderr}")
        return False

def main():
    if len(sys.argv) != 4:
        print("Usage: python convert_full.py <chm_file> <pdf_output> <work_dir>")
        sys.exit(1)
    
    chm_file = sys.argv[1]
    pdf_output = sys.argv[2]
    work_dir = sys.argv[3]
    
    # 解压CHM文件
    extract_dir = os.path.join(work_dir, "extracted")
    if not extract_chm_to_html(chm_file, extract_dir):
        print("Failed to extract CHM file")
        sys.exit(1)
    
    # 查找所有HTML文件
    html_files = find_all_html_files(extract_dir)
    print(f"Found {len(html_files)} HTML files")
    
    if not html_files:
        print("No HTML files found in extracted CHM")
        sys.exit(1)
    
    # 查找并解析HHC文件（如果有）
    hhc_file = find_hhc_file(extract_dir)
    hhc_urls = []
    if hhc_file:
        print(f"Found HHC file: {hhc_file}")
        hhc_urls = parse_hhc_file(hhc_file)
    
    # 创建主HTML文件
    master_html = os.path.join(work_dir, "master.html")
    if not create_master_html(html_files, hhc_urls, master_html, extract_dir):
        print("Failed to create master HTML")
        sys.exit(1)
    
    # 转换为PDF
    if convert_to_pdf(master_html, pdf_output):
        # 检查生成的PDF
        if os.path.exists(pdf_output) and os.path.getsize(pdf_output) > 0:
            # 尝试获取页数
            try:
                from PyPDF2 import PdfReader
                with open(pdf_output, 'rb') as f:
                    pdf = PdfReader(f)
                    page_count = len(pdf.pages)
                    print(f"Successfully created PDF with {page_count} pages")
            except:
                print("Successfully created PDF (unable to get page count)")
        else:
            print("PDF file was created but is empty")
            sys.exit(1)
    else:
        print("PDF conversion failed")
        sys.exit(1)

if __name__ == "__main__":
    main()
EOF

echo "开始CHM到PDF转换..."

# 安装必要的Python库
pip3 install PyPDF2 beautifulsoup4 lxml > /dev/null 2>&1 || echo "Python库安装失败或已安装"

# 运行完整的转换脚本
python3 "${WORK_DIR}/convert_full.py" "$CHM_FILE" "$PDF_OUTPUT" "$WORK_DIR"

# 检查转换结果
if [ -f "$PDF_OUTPUT" ] && [ -s "$PDF_OUTPUT" ]; then
    PDF_SIZE=$(stat -c%s "$PDF_OUTPUT" 2>/dev/null || stat -f%z "$PDF_OUTPUT")
    echo "PDF创建成功: $(basename "$PDF_OUTPUT")"
    echo "PDF大小: $((PDF_SIZE / 1024)) KB"
    
    # 获取页数
    if command -v pdfinfo &> /dev/null; then
        PAGE_COUNT=$(pdfinfo "$PDF_OUTPUT" 2>/dev/null | grep "Pages:" | awk '{print $2}')
    fi
    
    if [ -z "$PAGE_COUNT" ]; then
        # 使用Python获取页数
        python3 -c "
try:
    from PyPDF2 import PdfReader
    with open('$PDF_OUTPUT', 'rb') as f:
        pdf = PdfReader(f)
        print(len(pdf.pages))
except:
    print('0')
        " > "${WORK_DIR}/page_count.txt"
        PAGE_COUNT=$(cat "${WORK_DIR}/page_count.txt")
    fi
    
    echo "PDF页数: ${PAGE_COUNT:-"未知"}"
    
    # 根据分割页数设置决定是否分割
    echo "分割设置: ${SPLIT_PAGES}页 (0=不分割)"
    
    # 确保PAGE_COUNT是有效的数字
    if ! echo "${PAGE_COUNT:-0}" | grep -qE '^[0-9]+$'; then
        PAGE_COUNT=0
    fi
    
    # 使用最基本的bash语法重新编写条件判断
    if [ "$SPLIT_PAGES" -ne 0 ] && [ "${PAGE_COUNT}" -gt "0" ]; then
        if [ "${PAGE_COUNT}" -gt "$SPLIT_PAGES" ]; then
            echo "PDF有${PAGE_COUNT}页，超过分割阈值${SPLIT_PAGES}页，开始分割..."
            "${WORKSPACE}/scripts/split-pdf.sh" "${PDF_OUTPUT}" "${SPLIT_PAGES}"
        else
            echo "PDF页数(${PAGE_COUNT})未超过分割阈值(${SPLIT_PAGES})，不进行分割。"
        fi
    elif [ "${PAGE_COUNT}" -eq 0 ]; then
        echo "警告: PDF似乎有0页，转换可能失败。"
    elif [ "$SPLIT_PAGES" -eq 0 ]; then
        echo "分割页数设置为0，不进行分割。"
    fi
else
    echo "创建PDF文件失败"
    rm -rf "$WORK_DIR"
    exit 1
fi

# 清理临时文件
rm -rf "$WORK_DIR"
echo "转换成功完成!"
echo "=============================================="