#!/bin/bash

# 配置参数
DEFAULT_SPLIT_SIZE=10      # 默认分割大小（估算的页数）
DEFAULT_PARAGRAPHS_PER_PAGE=30  # 每页估算段落数
DEFAULT_DELETE_ORIGINAL=false  # 默认是否删除原始文件
DEFAULT_RETAIN_FORMATTING=true  # 默认是否保留格式
DEFAULT_PRESERVE_SECTIONS=true  # 默认是否保留节结构

# 检查输入参数
if [ $# -lt 2 ]; then
    echo "用法: $0 <输入DOCX文件> <输出目录> [分割大小]"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_DIR="$2"
SPLIT_SIZE="${3:-${SPLIT_PAGES:-$DEFAULT_SPLIT_SIZE}}"

# 从环境变量读取高级配置
PARAGRAPHS_PER_PAGE="${PARAGRAPHS_PER_PAGE:-$DEFAULT_PARAGRAPHS_PER_PAGE}"
DELETE_ORIGINAL="${DELETE_ORIGINAL:-$DEFAULT_DELETE_ORIGINAL}"
RETAIN_FORMATTING="${RETAIN_FORMATTING:-$DEFAULT_RETAIN_FORMATTING}"
PRESERVE_SECTIONS="${PRESERVE_SECTIONS:-$DEFAULT_PRESERVE_SECTIONS}"

# 检查输入文件是否存在
if [ ! -f "$INPUT_FILE" ]; then
    echo "错误: 输入文件 '$INPUT_FILE' 不存在"
    exit 1
fi

# 检查文件扩展名
FILE_EXTENSION="${INPUT_FILE##*.}"
if [ "$FILE_EXTENSION" != "docx" ] && [ "$FILE_EXTENSION" != "DOCX" ]; then
    echo "警告: 输入文件可能不是有效的DOCX文件"
fi

# 创建输出目录
mkdir -p "$OUTPUT_DIR"
if [ $? -ne 0 ]; then
    echo "错误: 无法创建输出目录 '$OUTPUT_DIR'"
    exit 1
fi

# 验证分割大小参数
if ! [[ "$SPLIT_SIZE" =~ ^[0-9]+$ ]] || [ "$SPLIT_SIZE" -lt 1 ]; then
    echo "警告: 无效的分割大小 '$SPLIT_SIZE'，使用默认值 '$DEFAULT_SPLIT_SIZE'"
    SPLIT_SIZE="$DEFAULT_SPLIT_SIZE"
fi

# 输出信息
echo "=============================================="
echo "DOCX文件分割工具 - 增强版"
echo "输入文件: $INPUT_FILE"
echo "输出目录: $OUTPUT_DIR"
echo "分割大小: $SPLIT_SIZE 页"
echo "高级配置:"
echo "  - 每页段落估算: $PARAGRAPHS_PER_PAGE"
echo "  - 保留格式: $RETAIN_FORMATTING"
echo "  - 保留节结构: $PRESERVE_SECTIONS"
echo "  - 删除原始文件: $DELETE_ORIGINAL"
echo "=============================================="

# 创建临时工作目录
WORKSPACE="${GITHUB_WORKSPACE:-$(pwd)}"
TEMP_DIR="${TEMP_DIR:-"${WORKSPACE}/temp"}"
JOB_ID=$(date +%s%N | md5sum | cut -c1-8 2>/dev/null || echo "temp")
WORK_DIR="${TEMP_DIR}/split_${JOB_ID}"
mkdir -p "${WORK_DIR}"

# 安装依赖库（如果需要）
echo "检查依赖..."
python3 -c "import docx" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "正在安装python-docx库..."
    python3 -m pip install python-docx --quiet
fi

# 使用Python进行文件分割
cat > "${WORK_DIR}/split_docx.py" << 'EOF'
#!/usr/bin/env python3
"""
DOCX文件分割脚本 - 增强版
"""

import os
import sys
import traceback
from docx import Document
from docx.shared import Inches

# 获取输入参数
input_file = sys.argv[1]
output_dir = sys.argv[2]
split_size = int(sys.argv[3])
paragraphs_per_page = int(sys.argv[4])
retain_formatting = sys.argv[5].lower() == 'true'
preserve_sections = sys.argv[6].lower() == 'true'

def copy_document_structure(source_doc, target_doc):
    """复制文档结构，包括样式、节等"""
    # 复制样式
    for style in source_doc.styles:
        try:
            # 检查样式是否已存在
            if style.name not in target_doc.styles:
                try:
                    new_style = target_doc.styles.add_style(style.name, style.type)
                    # 复制字体设置
                    if hasattr(style.font, 'name') and style.font.name:
                        new_style.font.name = style.font.name
                    if hasattr(style.font, 'size') and style.font.size:
                        new_style.font.size = style.font.size
                    if hasattr(style.font, 'bold'):
                        new_style.font.bold = style.font.bold
                    if hasattr(style.font, 'italic'):
                        new_style.font.italic = style.font.italic
                    if hasattr(style.font, 'underline'):
                        new_style.font.underline = style.font.underline
                except Exception:
                    # 某些样式可能无法复制，忽略错误
                    pass
        except Exception:
            # 忽略样式复制错误
            pass
    
    # 复制页面设置
    if preserve_sections and hasattr(source_doc, 'sections'):
        source_section = source_doc.sections[0]
        target_section = target_doc.sections[0]
        
        try:
            target_section.top_margin = source_section.top_margin
            target_section.bottom_margin = source_section.bottom_margin
            target_section.left_margin = source_section.left_margin
            target_section.right_margin = source_section.right_margin
        except Exception:
            # 忽略页面设置复制错误
            pass

def copy_paragraph_format(source_para, target_para, retain_format):
    """复制段落格式"""
    if not retain_format:
        return
        
    try:
        # 复制段落对齐方式
        if hasattr(source_para, 'alignment'):
            target_para.alignment = source_para.alignment
            
        # 复制段落间距
        if hasattr(source_para.paragraph_format, 'space_before') and source_para.paragraph_format.space_before:
            target_para.paragraph_format.space_before = source_para.paragraph_format.space_before
        if hasattr(source_para.paragraph_format, 'space_after') and source_para.paragraph_format.space_after:
            target_para.paragraph_format.space_after = source_para.paragraph_format.space_after
            
        # 复制缩进
        if hasattr(source_para.paragraph_format, 'left_indent') and source_para.paragraph_format.left_indent:
            target_para.paragraph_format.left_indent = source_para.paragraph_format.left_indent
    except Exception:
        # 忽略段落格式复制错误
        pass

def copy_run_format(source_run, target_run, retain_format):
    """复制文本运行格式"""
    if not retain_format:
        return
        
    try:
        # 复制基本格式
        target_run.bold = source_run.bold
        target_run.italic = source_run.italic
        target_run.underline = source_run.underline
        
        # 复制字体设置
        if hasattr(source_run.font, 'name') and source_run.font.name:
            target_run.font.name = source_run.font.name
        if hasattr(source_run.font, 'size') and source_run.font.size:
            target_run.font.size = source_run.font.size
        if hasattr(source_run.font, 'color') and source_run.font.color and hasattr(source_run.font.color, 'rgb') and source_run.font.color.rgb:
            target_run.font.color.rgb = source_run.font.color.rgb
    except Exception:
        # 忽略格式复制错误
        pass

def get_approximate_page_count(docx_path):
    """估算DOCX文件的页数"""
    try:
        doc = Document(docx_path)
        total_paragraphs = len(doc.paragraphs)
        # 使用段落数估算页数
        approx_pages = max(1, (total_paragraphs + paragraphs_per_page - 1) // paragraphs_per_page)
        return approx_pages
    except Exception as e:
        print(f"警告: 估算页数时出错: {e}")
        return 1

def main():
    print(f'开始分割文档: {input_file}')

    # 打开原始文档
    try:
        doc = Document(input_file)
        
        # 计算文档中的段落总数
        total_paragraphs = len(doc.paragraphs)
        print(f'文档包含 {total_paragraphs} 个段落')
        
        # 估算总页数
        estimated_pages = get_approximate_page_count(input_file)
        print(f'估算总页数: {estimated_pages} 页')
        
        # 根据分割大小计算每个分割文件的段落数
        paragraphs_per_split = split_size * paragraphs_per_page
        
        # 计算需要分割的文件数量
        num_splits = (total_paragraphs + paragraphs_per_split - 1) // paragraphs_per_split
        print(f'将分割为 {num_splits} 个文件')
        
        # 获取基本文件名
        base_name = os.path.splitext(os.path.basename(input_file))[0]
        
        # 创建分割文件
        for i in range(num_splits):
            print(f'创建分割文件 {i+1}/{num_splits}...')
            
            # 计算当前分割文件的段落范围
            start_idx = i * paragraphs_per_split
            end_idx = min((i + 1) * paragraphs_per_split, total_paragraphs)
            
            # 创建新文档
            new_doc = Document()
            
            # 复制文档结构
            copy_document_structure(doc, new_doc)
            
            # 复制段落到新文档
            for j in range(start_idx, end_idx):
                paragraph = doc.paragraphs[j]
                
                # 跳过空段落（可选项）
                # if not paragraph.text.strip():
                #     continue
                    
                # 添加标题说明当前分割范围
                if j == start_idx and i > 0:
                    title_para = new_doc.add_paragraph()
                    title_run = title_para.add_run(f'=== 文档分割部分 {i+1}/{num_splits} (段落 {start_idx+1}-{end_idx}) ===')
                    title_run.bold = True
                    title_para.alignment = 1  # 居中对齐
                
                new_para = new_doc.add_paragraph()
                
                # 复制段落文本和格式
                for run in paragraph.runs:
                    new_run = new_para.add_run(run.text)
                    # 复制格式
                    copy_run_format(run, new_run, retain_formatting)
                
                # 复制段落格式
                copy_paragraph_format(paragraph, new_para, retain_formatting)
            
            # 保存分割文件
            output_file = os.path.join(output_dir, f'{base_name}_part{i+1}.docx')
            new_doc.save(output_file)
            print(f'已保存: {output_file}')
        
        print(f'DOCX文件分割完成，共 {num_splits} 个文件')
        return 0
    except Exception as e:
        print(f'错误: 分割文档时出错: {e}')
        traceback.print_exc()
        return 1

if __name__ == '__main__':
    sys.exit(main())
EOF

# 运行Python脚本
echo "开始分割DOCX..."
python3 "${WORK_DIR}/split_docx.py" "$INPUT_FILE" "$OUTPUT_DIR" "$SPLIT_SIZE" "$PARAGRAPHS_PER_PAGE" "$RETAIN_FORMATTING" "$PRESERVE_SECTIONS"

# 检查执行结果
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
    echo "分割操作成功完成"
    # 删除原始文件（如果需要）
    if [ "$DELETE_ORIGINAL" = "true" ]; then
        echo "删除原始文件: $INPUT_FILE"
        rm -f "$INPUT_FILE"
    fi
else
    echo "分割操作失败，退出码: $EXIT_CODE"
fi

# 清理临时目录
echo "清理临时文件..."
rm -rf "$WORK_DIR"

echo "DOCX分割处理完成!"
exit $EXIT_CODE
