#!/bin/bash

# 字体大小修复补丁 - 增强CSS控制
# 备份原脚本
cp "scripts/chm-convert.sh" "scripts/chm-convert.sh.backup-font-fix"

echo "开始应用字体大小增强补丁..."

# 创建增强的CSS样式补丁
cat > "patches/font-size-enhancement.css" << 'EOF'
/* 字体大小增强CSS */
body {
    font-size: ${FONT_SIZE}pt !important;
    font-family: Arial, sans-serif !important;
    line-height: 1.6 !important;
}

/* 强制覆盖所有元素的字体大小 */
* {
    font-size: ${FONT_SIZE}pt !important;
}

/* 标题字体大小增强 */
h1 {
    font-size: calc(${FONT_SIZE}pt + 6pt) !important;
}
h2 {
    font-size: calc(${FONT_SIZE}pt + 4pt) !important;
}
h3 {
    font-size: calc(${FONT_SIZE}pt + 2pt) !important;
}
h4, h5, h6 {
    font-size: calc(${FONT_SIZE}pt + 1pt) !important;
}

/* 代码和预格式化文本 */
code, pre {
    font-family: 'Courier New', monospace !important;
    font-size: calc(${FONT_SIZE}pt - 1pt) !important;
}

/* 表格和列表 */
table, th, td {
    font-size: ${FONT_SIZE}pt !important;
}
li {
    font-size: ${FONT_SIZE}pt !important;
}

/* 内联样式覆盖 */
span, div, p {
    font-size: ${FONT_SIZE}pt !important;
}
EOF

echo "创建CSS增强文件完成"

# 修改Python脚本中的CSS部分
python3 << 'EOF'
import re

# 读取原脚本
with open('scripts/chm-convert.sh', 'r', encoding='utf-8') as f:
    content = f.read()

# 找到CSS样式部分并替换
old_css = '''        body {
            font-family: Arial, sans-serif;
            font-size: ''' + str(font_size) + '''pt;
            margin: 0;
            padding: 0;
            line-height: 1.6;
        }
        .page-break {
            page-break-after: always;
            height: 0;
            margin: 0;
            padding: 0;
        }
        .content-page {
            padding: 20px;
        }
        h1, h2, h3 {
            color: #333;
            margin-top: 30px;
        }
        p {
            margin: 15px 0;
        }
        img {
            max-width: 100%;
            height: auto;
        }'''

new_css = '''        body {
            font-family: Arial, sans-serif !important;
            font-size: ''' + str(font_size) + '''pt !important;
            margin: 0 !important;
            padding: 0 !important;
            line-height: 1.6 !important;
        }
        .page-break {
            page-break-after: always !important;
            height: 0 !important;
            margin: 0 !important;
            padding: 0 !important;
        }
        .content-page {
            padding: 20px !important;
        }
        /* 强制字体大小控制 */
        * {
            font-size: ''' + str(font_size) + '''pt !important;
        }
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
        p {
            font-size: ''' + str(font_size) + '''pt !important;
            margin: 15px 0 !important;
        }
        code, pre {
            font-family: 'Courier New', monospace !important;
            font-size: calc(''' + str(font_size) + '''pt - 1pt) !important;
        }
        table, th, td {
            font-size: ''' + str(font_size) + '''pt !important;
        }
        li {
            font-size: ''' + str(font_size) + '''pt !important;
        }
        span, div {
            font-size: ''' + str(font_size) + '''pt !important;
        }
        img {
            max-width: 100% !important;
            height: auto !important;
        }'''

# 替换CSS内容
content = content.replace(old_css, new_css)

# 写入修改后的内容
with open('scripts/chm-convert.sh', 'w', encoding='utf-8') as f:
    f.write(content)

print("CSS样式增强完成")
EOF

echo "字体大小增强补丁应用完成"
echo "原脚本已备份为: scripts/chm-convert.sh.backup-font-fix"
echo "修改后的脚本已保存"