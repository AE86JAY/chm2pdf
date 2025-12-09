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

示例:
  $0 create fix-font-size
  $0 apply
  $0 list
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
        echo "编号 | 补丁文件 | 描述"
        echo "----|----------|------"
        for patch in patches/*.patch; do
            if [ -f "$patch" ]; then
                patch_num=$(basename "$patch" | cut -d'-' -f1)
                patch_desc=$(basename "$patch" | cut -d'-' -f2- | sed 's/.patch$//')
                subject=$(head -n 10 "$patch" | grep "^Subject:" | cut -d':' -f2- | sed 's/^ //')
                echo "$patch_num | $(basename $patch) | $subject"
            fi
        done
    else
        echo "补丁目录不存在"
    fi
}

apply_patches() {
    echo "应用所有补丁..."
    if [ -f "patches/apply-patches.sh" ]; then
        ./patches/apply-patches.sh
    else
        echo "错误: 找不到补丁应用脚本"
        exit 1
    fi
}

patch_info() {
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
        echo "补丁文件: $patch_file"
        echo "大小: $(wc -l < "$patch_file") 行"
        echo ""
        echo "补丁信息:"
        head -n 10 "$patch_file"
        echo ""
        echo "修改的文件:"
        grep "^--- " "$patch_file" | sed 's/^--- //'
        echo ""
        echo "预览前50行:"
        head -n 50 "$patch_file" | tail -n 40
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