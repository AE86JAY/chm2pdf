#!/bin/bash
# 补丁管理脚本

set -e

ACTION="${1:-help}"
PATCH_NAME="${2}"

show_help() {
    cat << EOF
补丁管理工具

使用方法: $0 <命令> [参数]

命令:
  create <补丁名>      - 创建新补丁（基于git diff）
  apply                - 应用所有补丁
  list                 - 列出所有补丁
  info <补丁名>        - 查看补丁信息
  revert <补丁名>      - 撤销指定补丁
  verify               - 验证补丁状态
  help                 - 显示此帮助信息

功能说明:
  此工具支持管理CHM2PDF和PDF2DOCX功能相关的所有补丁。
  PDF2DOCX补丁提供了PDF转换为DOCX的完整功能集。

示例:
  $0 create fix-font-size
  $0 apply
  $0 list
  $0 info pdf2docx_feature
EOF
}

create_patch() {
    local patch_name="$1"
    if [ -z "$patch_name" ]; then
        echo "错误: 请提供补丁名称"
        show_help
        exit 1
    fi
    
    # 获取下一个补丁编号
    local last_num=$(ls patches/*.patch 2>/dev/null | grep -oE '[0-9]+' | sort -n | tail -1)
    local next_num=$((last_num + 1))
    local patch_num=$(printf "%03d" $next_num)
    
    local patch_file="patches/${patch_num}-${patch_name}.patch"
    
    echo "创建补丁: $patch_file"
    
    # 检查是否有未提交的更改
    if ! git diff --quiet; then
        # 生成补丁
        git diff --no-prefix > "$patch_file"
        
        # 添加补丁头信息
        {
            echo "From $(git rev-parse HEAD) $(date +%Y-%m-%d)"
            echo "From: $(git config user.name) <$(git config user.email)>"
            echo "Date: $(date)"
            echo "Subject: [PATCH ${patch_num}] ${patch_name}"
            echo ""
            echo "---"
            echo ""
            cat "$patch_file"
        } > "${patch_file}.tmp" && mv "${patch_file}.tmp" "$patch_file"
        
        echo "补丁创建成功: $patch_file"
        echo "请检查补丁内容并提交"
        
        # 显示补丁统计
        echo ""
        echo "补丁统计:"
        echo "  修改文件数: $(grep -c "^--- " "$patch_file")"
        echo "  总行数: $(wc -l < "$patch_file")"
    else
        echo "错误: 没有未提交的更改"
        exit 1
    fi
}

list_patches() {
    if [ -d "patches" ]; then
        echo "可用补丁:"
        echo "补丁文件 | 类型 | 描述"
        echo "---------|------|------"
        
        # 检查并显示所有补丁，兼容不同的命名格式
        for patch_file in $(ls patches/*.patch 2>/dev/null | sort -V); do
            if [ -f "$patch_file" ]; then
                local base_name=$(basename "$patch_file")
                local type="CHM2PDF"
                
                # 根据文件名或内容判断补丁类型
                if [[ "$base_name" == *"pdf2docx"* || "$base_name" == *"PDF2DOCX"* ]]; then
                    type="PDF2DOCX"
                fi
                
                # 获取描述信息
                local subject=""
                if head -n 10 "$patch_file" | grep -q "^Subject:"; then
                    subject=$(head -n 10 "$patch_file" | grep "^Subject:" | cut -d':' -f2- | sed 's/^ //')
                else
                    # 如果没有标准subject行，尝试从文件名提取
                    subject=$(echo "$base_name" | sed -E 's/^[0-9]+[-_]?//; s/\.patch$//; s/-/ /g')
                fi
                
                echo "$base_name | $type | $subject"
            fi
        done
        
        # 显示统计信息
        local total_patches=$(ls patches/*.patch 2>/dev/null | wc -l)
        local pdf2docx_patches=$(ls patches/*pdf2docx*.patch patches/*PDF2DOCX*.patch 2>/dev/null | wc -l)
        
        echo ""
        echo "补丁统计:"
        echo "  总计: $total_patches 个补丁"
        echo "  PDF2DOCX相关: $pdf2docx_patches 个补丁"
    else
        echo "补丁目录不存在"
    fi
}

apply_patches() {
    echo "应用所有补丁..."
    
    # 确保脚本有执行权限
    chmod +x patches/*.sh 2>/dev/null || true
    
    if [ -f "patches/apply-patches.sh" ]; then
        ./patches/apply-patches.sh
    else
        # 如果没有专用的应用脚本，使用patch命令直接应用
        echo "未找到专用补丁应用脚本，直接应用补丁..."
        local PATCH_COUNT=0
        local FAILED_PATCHES=()
        
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
                        FAILED_PATCHES+=($PATCH_NAME)
                    fi
                else
                    echo "  ⚠ 补丁不适用当前版本或已应用"
                fi
            fi
        done
        
        echo ""
        echo "补丁应用完成:"
        echo "  成功: $PATCH_COUNT"
        echo "  失败: ${#FAILED_PATCHES[@]}"
    fi
    
    # 确保PDF2DOCX脚本有执行权限
    if [ -d "PDF2DOCX" ]; then
        echo "设置PDF2DOCX脚本执行权限..."
        chmod +x PDF2DOCX/*.sh 2>/dev/null || true
    fi
}

patch_info() {
    local patch_name="$1"
    if [ -z "$patch_name" ]; then
        echo "错误: 请提供补丁名称"
        exit 1
    fi
    
    # 尝试多种文件匹配方式
    local patch_file="patches/${patch_name}.patch"
    if [ ! -f "$patch_file" ]; then
        patch_file=$(find patches -name "*${patch_name}*.patch" | head -1)
    fi
    
    if [ -f "$patch_file" ]; then
        local base_name=$(basename "$patch_file")
        local type="CHM2PDF"
        
        # 判断补丁类型
        if [[ "$base_name" == *"pdf2docx"* || "$base_name" == *"PDF2DOCX"* ]]; then
            type="PDF2DOCX"
        fi
        
        echo "补丁文件: $patch_file"
        echo "类型: $type"
        echo "大小: $(wc -l < "$patch_file") 行"
        echo ""
        echo "补丁信息:"
        
        # 显示补丁头信息
        if head -n 10 "$patch_file" | grep -q "^From:\|^Date:\|^Subject:"; then
            head -n 10 "$patch_file" | grep -E "^From:|^Date:|^Subject:"
        else
            echo "  [没有标准补丁头信息]"
        fi
        
        echo ""
        echo "修改的文件:"
        if grep -q "^--- " "$patch_file"; then
            grep "^--- " "$patch_file" | sed 's/^--- //'
        else
            # 对于非标准补丁格式，尝试提取文件路径信息
            grep -E "^[a-zA-Z0-9_\-\./]+" "$patch_file" | head -5
        fi
        
        echo ""
        echo "功能概述:"
        if [ "$type" == "PDF2DOCX" ]; then
            echo "  此补丁提供PDF到DOCX转换功能，包括字体调整、文件分割等特性"
        else
            echo "  此补丁提供CHM2PDF相关功能增强或修复"
        fi
        
        echo ""
        echo "预览内容（前20行）:"
        head -n 20 "$patch_file"
    else
        echo "错误: 找不到补丁文件 $patch_name"
    fi
}

revert_patch() {
    local patch_name="$1"
    if [ -z "$patch_name" ]; then
        echo "错误: 请提供补丁名称"
        exit 1
    fi
    
    local patch_file="patches/${patch_name}.patch"
    if [ ! -f "$patch_file" ]; then
        patch_file=$(find patches -name "*${patch_name}*.patch" | head -1)
    fi
    
    if [ -f "$patch_file" ]; then
        echo "撤销补丁: $(basename $patch_file)"
        patch -p1 --reverse --forward < "$patch_file" || echo "可能需要手动撤销"
    else
        echo "错误: 找不到补丁文件 $patch_name"
    fi
}

verify_patches() {
    echo "验证补丁状态..."
    
    if [ ! -d "patches" ]; then
        echo "补丁目录不存在"
        return
    fi
    
    for patch in patches/*.patch; do
        if [ -f "$patch" ]; then
            patch_name=$(basename "$patch")
            echo -n "检查 $patch_name: "
            
            if patch -p1 --forward --dry-run < "$patch" 2>&1 | grep -q "Skipping patch"; then
                echo "✓ 已应用"
            elif patch -p1 --forward --dry-run < "$patch" 2>&1 | grep -q "FAILED"; then
                echo "✗ 无法应用"
            else
                echo "○ 未应用"
            fi
        fi
    done
}

case "$ACTION" in
    create)
        create_patch "$PATCH_NAME"
        ;;
    apply)
        apply_patches
        ;;
    list)
        list_patches
        ;;
    info)
        patch_info "$PATCH_NAME"
        ;;
    revert)
        revert_patch "$PATCH_NAME"
        ;;
    verify)
        verify_patches
        ;;
    help|*)
        show_help
        ;;
esac