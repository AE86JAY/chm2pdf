#!/bin/bash

# 字体大小修复补丁 - 增强CSS控制
# 备份原脚本
cp "scripts/chm-convert.sh" "scripts/chm-convert.sh.backup2"

echo "创建字体大小增强补丁..."

# 创建补丁文件
cat > "patches/font-size-enhancement.patch" << 'EOF'
--- a/scripts/chm-convert.sh
+++ b/scripts/chm-convert.sh
@@ -100,6 +100,7 @@
     <style>
         body {
             font-family: Arial, sans-serif;
+            font-size: ''' + str(font_size) + '''pt !important;
             margin: 0;
             padding: 0;
             line-height: 1.6;
@@ -107,6 +108,20 @@
         .page-break {
             page-break-after: always;
             height: 0;
+        }
+        /* 强制覆盖所有元素的字体大小 */
+        * {
+            font-size: ''' + str(font_size) + '''pt !important;
+        }
+        /* 针对标题的特殊处理 */
+        h1, h2, h3, h4, h5, h6 {
+            font-size: ''' + str(int(font_size) + 2) + '''pt !important;
+        }
+        /* 针对代码和预格式化文本 */
+        code, pre {
+            font-family: 'Courier New', monospace !important;
+            font-size: ''' + str(int(font_size) - 1) + '''pt !important;
+        }
 EOF

 echo "补丁创建完成"
 echo "应用补丁..."

# 应用补丁到脚本
patch -p1 < "patches/font-size-enhancement.patch"

if [ $? -eq 0 ]; then
    echo "补丁应用成功"
else
    echo "补丁应用失败，使用手动修改方式"
    
    # 手动修改CSS部分
    sed -i '/font-size: ''' + str(font_size) + '''pt;/a\            font-size: ''' + str(font_size) + '''pt !important;' "scripts/chm-convert.sh"
    
    # 添加强制字体大小控制
    sed -i '/.page-break {/i\        /* 强制覆盖所有元素的字体大小 */\n        * {\n            font-size: ''' + str(font_size) + '''pt !important;\n        }\n        /* 针对标题的特殊处理 */\n        h1, h2, h3, h4, h5, h6 {\n            font-size: ''' + str(int(font_size) + 2) + '''pt !important;\n        }\n        /* 针对代码和预格式化文本 */\n        code, pre {\n            font-family: 'Courier New', monospace !important;\n            font-size: ''' + str(int(font_size) - 1) + '''pt !important;\n        }' "scripts/chm-convert.sh"
    
    echo "手动修改完成"
fi

echo "字体大小增强补丁应用完成"