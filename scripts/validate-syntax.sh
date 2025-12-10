#!/bin/bash

echo "=== 验证脚本语法 ==="

# 检查每个脚本的语法
for script in apply-patches-fixed.sh apply-patches.sh chm-convert-simple.sh chm-convert.sh find-chm.sh split-pdf.sh; do
    echo -n "检查脚本: $script"
    
    # 使用bash -n检查语法
    if bash -n "scripts/$script" 2>/dev/null; then
        echo " ✓ 语法正确"
    else
        echo " ✗ 语法错误"
        bash -n "scripts/$script" 2>&1 | head -5
    fi
done

echo "=== 验证完成 ==="