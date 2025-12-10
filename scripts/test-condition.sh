#!/bin/bash

# 测试条件判断语法
set -e

# 模拟变量
SPLIT_PAGES=10
PAGE_COUNT=20

# 使用最基本的bash语法测试条件判断
if [ "$SPLIT_PAGES" -ne 0 ] && [ "${PAGE_COUNT}" -gt "0" ]; then
    if [ "${PAGE_COUNT}" -gt "$SPLIT_PAGES" ]; then
        echo "PDF有${PAGE_COUNT}页，超过分割阈值${SPLIT_PAGES}页，开始分割..."
    else
        echo "PDF页数(${PAGE_COUNT})未超过分割阈值(${SPLIT_PAGES})，不进行分割。"
    fi
elif [ "${PAGE_COUNT}" -eq 0 ]; then
    echo "警告: PDF似乎有0页，转换可能失败。"
elif [ "$SPLIT_PAGES" -eq 0 ]; then
    echo "分割页数设置为0，不进行分割。"
fi

echo "语法测试通过!"