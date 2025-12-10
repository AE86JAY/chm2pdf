#!/bin/bash

# 字体大小增强补丁应用脚本
# 创建备份文件（使用不同的备份文件名）
BACKUP_FILE="scripts/chm-convert.sh.backup-font-enhancement"

if [ -f "scripts/chm-convert.sh" ]; then
    echo "备份原脚本到: $BACKUP_FILE"
    cp "scripts/chm-convert.sh" "$BACKUP_FILE"
    echo "备份完成"
else
    echo "错误: 找不到 scripts/chm-convert.sh 文件"
    exit 1
fi

# 创建字体大小增强补丁
cat > "patches/font-size-enhancement.patch" << 'EOF'
--- a/scripts/chm-convert.sh
+++ b/scripts/chm-convert.sh
@@ -100,21 +100,59 @@
     <style>
         body {
             font-family: Arial, sans-serif;
-            font-size: ''' + str(font_size) + '''pt;
+            font-size: ''' + str(font_size) + '''pt !important;
             margin: 0;
             padding: 0;
             line-height: 1.6;
         }
+        
+        /* 强制覆盖所有元素的字体大小 */
+        * {
+            font-size: ''' + str(font_size) + '''pt !important;
+        }
+        
+        /* 标题字体大小增强 */
+        h1 {
+            font-size: calc(''' + str(font_size) + '''pt + 6pt) !important;
+            color: #333 !important;
+            margin-top: 30px !important;
+        }
+        h2 {
+            font-size: calc(''' + str(font_size) + '''pt + 4pt) !important;
+            color: #333 !important;
+            margin-top: 30px !important;
+        }
+        h3 {
+            font-size: calc(''' + str(font_size) + '''pt + 2pt) !important;
+            color: #333 !important;
+            margin-top: 30px !important;
+        }
+        h4, h5, h6 {
+            font-size: calc(''' + str(font_size) + '''pt + 1pt) !important;
+            color: #333 !important;
+            margin-top: 30px !important;
+        }
+        
+        /* 段落和文本 */
+        p {
+            font-size: ''' + str(font_size) + '''pt !important;
+            margin: 15px 0 !important;
+        }
+        
+        /* 代码和预格式化文本 */
+        code, pre {
+            font-family: 'Courier New', monospace !important;
+            font-size: calc(''' + str(font_size) + '''pt - 1pt) !important;
+        }
+        
+        /* 表格和列表 */
+        table, th, td {
+            font-size: ''' + str(font_size) + '''pt !important;
+        }
+        li {
+            font-size: ''' + str(font_size) + '''pt !important;
+        }
+        
+        /* 内联元素覆盖 */
+        span, div {
+            font-size: ''' + str(font_size) + '''pt !important;
+        }
+        
         .page-break {
             page-break-after: always;
             height: 0;
EOF

echo "创建补丁文件完成"

# 尝试应用补丁
echo "尝试应用补丁..."
if command -v patch >/dev/null 2>&1; then
    patch -p1 < "patches/font-size-enhancement.patch"
    if [ $? -eq 0 ]; then
        echo "补丁应用成功"
    else
        echo "补丁应用失败，使用sed进行手动修改"
        # 使用sed进行手动修改
        sed -i 's/font-size: ''' + str(font_size) + '''pt;/font-size: ''' + str(font_size) + '''pt !important;/g' "scripts/chm-convert.sh"
        
        # 在body样式后添加强制字体大小控制
        sed -i '/font-size: ''' + str(font_size) + '''pt !important;/a\\n        /* 强制覆盖所有元素的字体大小 */\n        * {\n            font-size: ''' + str(font_size) + '''pt !important;\n        }\n        \n        /* 标题字体大小增强 */\n        h1 {\n            font-size: calc(''' + str(font_size) + '''pt + 6pt) !important;\n            color: #333 !important;\n            margin-top: 30px !important;\n        }\n        h2 {\n            font-size: calc(''' + str(font_size) + '''pt + 4pt) !important;\n            color: #333 !important;\n            margin-top: 30px !important;\n        }\n        h3 {\n            font-size: calc(''' + str(font_size) + '''pt + 2pt) !important;\n            color: #333 !important;\n            margin-top: 30px !important;\n        }\n        h4, h5, h6 {\n            font-size: calc(''' + str(font_size) + '''pt + 1pt) !important;\n            color: #333 !important;\n            margin-top: 30px !important;\n        }\n        \n        /* 段落和文本 */\n        p {\n            font-size: ''' + str(font_size) + '''pt !important;\n            margin: 15px 0 !important;\n        }\n        \n        /* 代码和预格式化文本 */\n        code, pre {\n            font-family: 'Courier New', monospace !important;\n            font-size: calc(''' + str(font_size) + '''pt - 1pt) !important;\n        }\n        \n        /* 表格和列表 */\n        table, th, td {\n            font-size: ''' + str(font_size) + '''pt !important;\n        }\n        li {\n            font-size: ''' + str(font_size) + '''pt !important;\n        }\n        \n        /* 内联元素覆盖 */\n        span, div {\n            font-size: ''' + str(font_size) + '''pt !important;\n        }' "scripts/chm-convert.sh"
        
        echo "手动修改完成"
    fi
else
    echo "patch命令不可用，使用sed进行手动修改"
    # 使用sed进行手动修改
    sed -i 's/font-size: ''' + str(font_size) + '''pt;/font-size: ''' + str(font_size) + '''pt !important;/g' "scripts/chm-convert.sh"
    
    # 在body样式后添加强制字体大小控制
    sed -i '/font-size: ''' + str(font_size) + '''pt !important;/a\\n        /* 强制覆盖所有元素的字体大小 */\n        * {\n            font-size: ''' + str(font_size) + '''pt !important;\n        }\n        \n        /* 标题字体大小增强 */\n        h1 {\n            font-size: calc(''' + str(font_size) + '''pt + 6pt) !important;\n            color: #333 !important;\n            margin-top: 30px !important;\n        }\n        h2 {\n            font-size: calc(''' + str(font_size) + '''pt + 4pt) !important;\n            color: #333 !important;\n            margin-top: 30px !important;\n        }\n        h3 {\n            font-size: calc(''' + str(font_size) + '''pt + 2pt) !important;\n            color: #333 !important;\n            margin-top: 30px !important;\n        }\n        h4, h5, h6 {\n            font-size: calc(''' + str(font_size) + '''pt + 1pt) !important;\n            color: #333 !important;\n            margin-top: 30px !important;\n        }\n        \n        /* 段落和文本 */\n        p {\n            font-size: ''' + str(font_size) + '''pt !important;\n            margin: 15px 0 !important;\n        }\n        \n        /* 代码和预格式化文本 */\n        code, pre {\n            font-family: 'Courier New', monospace !important;\n            font-size: calc(''' + str(font_size) + '''pt - 1pt) !important;\n        }\n        \n        /* 表格和列表 */\n        table, th, td {\n            font-size: ''' + str(font_size) + '''pt !important;\n        }\n        li {\n            font-size: ''' + str(font_size) + '''pt !important;\n        }\n        \n        /* 内联元素覆盖 */\n        span, div {\n            font-size: ''' + str(font_size) + '''pt !important;\n        }' "scripts/chm-convert.sh"
    
    echo "手动修改完成"
fi

echo "字体大小增强补丁应用完成"
echo "原脚本已备份到: $BACKUP_FILE"
echo "修改后的脚本已保存"

# 验证修改
if grep -q "!important" "scripts/chm-convert.sh"; then
    echo "验证: 字体大小增强样式已成功添加"
else
    echo "警告: 可能未成功添加字体大小增强样式"
fi