#!/bin/bash

# PDF分割脚本
set -e

PDF_FILE="$1"
MAX_PAGES="${2:-10}"  # 第二个参数为最大页数，默认为10

if [ ! -f "$PDF_FILE" ]; then
    echo "错误: PDF文件未找到: $PDF_FILE"
    exit 1
fi

WORKSPACE="${GITHUB_WORKSPACE}"
OUTPUT_DIR="${WORKSPACE}/output"

echo "PDF分割设置:"
echo "  输入文件: $(basename "$PDF_FILE")"
echo "  分割阈值: $MAX_PAGES 页 (0=不分割)"

# 如果最大页数为0，则不分割
if [ "$MAX_PAGES" -eq 0 ]; then
    echo "分割页数设置为0，跳过分割。"
    exit 0
fi

# 使用Python进行分割
cat > /tmp/split_pdf.py << EOF
import sys
import os
from PyPDF2 import PdfReader, PdfWriter

def split_pdf(input_path, output_dir, max_pages=10):
    """分割PDF文件"""
    
    reader = PdfReader(input_path)
    total_pages = len(reader.pages)
    
    if total_pages <= max_pages:
        print(f"PDF只有 {total_pages} 页，不需要分割")
        return False
    
    # 获取基础文件名
    base_name = os.path.splitext(os.path.basename(input_path))[0]
    
    # 计算需要分成几部分
    num_parts = (total_pages + max_pages - 1) // max_pages
    
    print(f"PDF总页数: {total_pages}")
    print(f"分割阈值: {max_pages} 页/文件")
    print(f"将分割为 {num_parts} 个文件")
    
    for part in range(num_parts):
        start_page = part * max_pages
        end_page = min((part + 1) * max_pages, total_pages)
        
        writer = PdfWriter()
        
        for page_num in range(start_page, end_page):
            writer.add_page(reader.pages[page_num])
        
        part_num = part + 1
        output_filename = f"{base_name}_{part_num:02d}.pdf"
        output_path = os.path.join(output_dir, output_filename)
        
        with open(output_path, 'wb') as output_file:
            writer.write(output_file)
        
        print(f"创建文件: {output_filename} (第 {start_page+1}-{end_page} 页)")
    
    # 删除原始文件
    os.remove(input_path)
    print(f"删除原始文件: {os.path.basename(input_path)}")
    
    return True

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("用法: python split_pdf.py <input.pdf> <max_pages> <output_dir>")
        sys.exit(1)
    
    input_pdf = sys.argv[1]
    max_pages = int(sys.argv[2])
    output_dir = sys.argv[3]
    
    split_pdf(input_pdf, output_dir, max_pages)
EOF

# 运行Python分割脚本
echo "开始分割PDF..."
python3 /tmp/split_pdf.py "$PDF_FILE" "$MAX_PAGES" "$OUTPUT_DIR"

if [ $? -eq 0 ]; then
    echo "PDF分割完成!"
else
    echo "PDF分割失败或不需要分割"
fi
