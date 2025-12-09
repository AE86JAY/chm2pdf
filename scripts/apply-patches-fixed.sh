#!/bin/bash
# 修复的补丁应用脚本

set -e

echo "=== 开始应用补丁 ==="

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
cp -f scripts/*.sh "$BACKUP_DIR/" 2>/dev/null || true
cp -f .github/workflows/*.yml "$BACKUP_DIR/" 2>/dev/null || true

# 安装补丁工具（如果需要）
if ! command -v patch &> /dev/null; then
    echo "安装补丁工具..."
    sudo apt-get update && sudo apt-get install -y patch || {
        echo "无法安装补丁工具"
        exit 1
    }
fi

PATCH_COUNT=0
FAILED_PATCHES=()

if [ -d "patches" ]; then
    # 按数字顺序排序补丁文件
    for patch_file in $(ls patches/*.patch 2>/dev/null | sort -V); do
        if [ -f "$patch_file" ]; then
            PATCH_NAME=$(basename "$patch_file")
            echo ""
            echo "应用补丁: $PATCH_NAME"
            
            # 检查补丁内容
            echo "补丁内容摘要:"
            head -5 "$patch_file" | grep -E "Subject:|From:|Date:"
            
            # 先试运行检查
            if patch -p1 --forward --dry-run < "$patch_file" > /dev/null 2>&1; then
                echo "  试运行成功，开始正式应用..."
                
                # 正式应用补丁
                if patch -p1 --forward < "$patch_file" ; then
                    echo "  ✓ 应用成功"
                    PATCH_COUNT=$((PATCH_COUNT + 1))
                else
                    echo "  ✗ 应用失败"
                    FAILED_PATCHES+=("$PATCH_NAME")
                fi
            else
                echo "  ⚠ 补丁不适用当前版本"
                
                # 尝试显示更多信息
                patch -p1 --forward --dry-run < "$patch_file" 2>&1 | head -5
            fi
        fi
    done
else
    echo "未找到补丁目录"
fi

echo ""
echo "=== 补丁应用完成 ==="
echo "  成功: $PATCH_COUNT"
echo "  失败: ${#FAILED_PATCHES[@]}"

if [ ${#FAILED_PATCHES[@]} -gt 0 ]; then
    echo "失败的补丁:"
    for patch in "${FAILED_PATCHES[@]}"; do
        echo "  - $patch"
    done
fi

echo "原始文件备份在: $BACKUP_DIR"

# 验证脚本语法
echo ""
echo "=== 验证脚本语法 ==="
for script in scripts/*.sh; do
    if [ -f "$script" ]; then
        if bash -n "$script"; then
            echo "  ✓ $script: 语法正确"
        else
            echo "  ✗ $script: 语法错误"
        fi
    fi
done

echo ""
echo "应用补丁后的文件状态:"
ls -la scripts/*.sh 2>/dev/null | head -10
