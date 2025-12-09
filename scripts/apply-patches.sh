#!/bin/bash
# 简化的补丁应用脚本

set -e

echo "开始应用补丁..."

# 检查是否在正确的目录
if [ ! -d "scripts" ]; then
    echo "错误: 请在仓库根目录运行此脚本"
    exit 1
fi

# 创建备份目录
BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# 备份原始脚本
echo "备份原始文件..."
cp scripts/*.sh "$BACKUP_DIR/" 2>/dev/null || true

# 应用所有补丁文件
PATCH_COUNT=0
FAILED_PATCHES=()

if [ -d "patches" ]; then
    # 按数字顺序排序补丁文件
    for patch_file in $(ls patches/*.patch 2>/dev/null | sort -V); do
        if [ -f "$patch_file" ]; then
            PATCH_NAME=$(basename "$patch_file")
            echo "应用补丁: $PATCH_NAME"
            
            # 尝试应用补丁
            if patch -p1 --forward --dry-run < "$patch_file" > /dev/null 2>&1; then
                if patch -p1 --forward < "$patch_file"; then
                    echo "  ✓ 应用成功"
                    PATCH_COUNT=$((PATCH_COUNT + 1))
                else
                    echo "  ✗ 应用失败"
                    FAILED_PATCHES+=("$PATCH_NAME")
                fi
            else
                echo "  ⚠ 补丁不适用当前版本"
            fi
        fi
    done
else
    echo "未找到补丁目录"
fi

echo ""
echo "补丁应用完成:"
echo "  成功: $PATCH_COUNT"
echo "  失败: ${#FAILED_PATCHES[@]}"

if [ ${#FAILED_PATCHES[@]} -gt 0 ]; then
    echo "失败的补丁:"
    for patch in "${FAILED_PATCHES[@]}"; do
        echo "  - $patch"
    done
fi

echo "原始文件备份在: $BACKUP_DIR"