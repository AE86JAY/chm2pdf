#!/bin/bash
# 自动应用所有补丁脚本

set -e

echo "=== 开始应用CHM2PDF和PDF2DOCX补丁系统 ==="

# 检查是否在正确的目录
if [ ! -d "patches" ]; then
    echo "错误: 请在仓库根目录运行此脚本"
    exit 1
fi

# 创建备份目录
BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# 备份原始文件
echo "备份原始文件..."
cp -f scripts/*.sh "$BACKUP_DIR/" 2>/dev/null || true
cp -f *.sh "$BACKUP_DIR/" 2>/dev/null || true

# 确保必要的目录存在
mkdir -p PDF2DOCX 2>/dev/null || true

# 应用所有补丁文件
PATCH_COUNT=0
FAILED_PATCHES=()

# 按数字顺序排序补丁文件
for patch_file in $(ls patches/*.patch 2>/dev/null | sort -V); do
    if [ -f "$patch_file" ]; then
        PATCH_NAME=$(basename "$patch_file")
        echo ""
        echo "应用补丁: $PATCH_NAME"
        
        # 判断补丁类型
        PATCH_TYPE="CHM2PDF"
        if [[ "$PATCH_NAME" == *"pdf2docx"* || "$PATCH_NAME" == *"PDF2DOCX"* ]]; then
            PATCH_TYPE="PDF2DOCX"
        fi
        
        echo "  类型: $PATCH_TYPE"
        
        # 先试运行检查
        if patch -p1 --forward --dry-run < "$patch_file" > /dev/null 2>&1; then
            echo "  试运行成功，开始正式应用..."
            
            # 正式应用补丁
            if patch -p1 --forward < "$patch_file" ; then
                echo "  ✓ 应用成功"
                PATCH_COUNT=$((PATCH_COUNT + 1))
            else
                echo "  ✗ 应用失败"
                FAILED_PATCHES+=($PATCH_NAME)
            fi
        else
            echo "  ⚠ 补丁不适用当前版本或已应用"
            
            # 尝试显示更多信息
            patch -p1 --forward --dry-run < "$patch_file" 2>&1 | head -5 || true
        fi
    fi
done

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

# 设置所有脚本的执行权限
echo ""
echo "设置脚本执行权限..."
chmod +x scripts/*.sh 2>/dev/null || true
chmod +x PDF2DOCX/*.sh 2>/dev/null || true
chmod +x *.sh 2>/dev/null || true

# 验证PDF2DOCX目录是否创建成功
if [ -d "PDF2DOCX" ]; then
    echo ""
    echo "PDF2DOCX目录已创建/更新，包含以下文件:"
    ls -la PDF2DOCX/ 2>/dev/null || echo "  [空目录]"
fi

echo ""
echo "原始文件备份在: $BACKUP_DIR"
echo ""
echo "提示: 运行 ./patches/manage-patches.sh list 查看所有补丁"
if [ -d "PDF2DOCX" ] && [ -f "PDF2DOCX/main-pdf2docx.sh" ]; then
    echo "      运行 ./PDF2DOCX/main-pdf2docx.sh 开始PDF到DOCX转换"
fi
