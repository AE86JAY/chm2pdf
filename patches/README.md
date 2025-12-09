概述
本补丁系统允许您以非侵入式方式更新 CHM 转 PDF 工作流的脚本文件。通过补丁文件，您可以：

保持原始脚本的完整性

跟踪所有修改历史

轻松启用/禁用特定功能

实现版本间的平滑升级和回滚

目录结构
text
patches/
├── 001-add-font-config.patch      # 示例：添加字体配置补丁
├── 002-fix-page-split.patch       # 示例：修复分页问题补丁
├── 003-enhance-performance.patch  # 示例：性能优化补丁
├── apply-patches.sh               # 补丁应用脚本（自动应用所有补丁）
├── manage-patches.sh              # 补丁管理脚本（创建、查看、管理等）
├── README.md                      # 本文档
└── test-patches.sh               # 补丁测试脚本（可选）
补丁命名规则
补丁文件按以下格式命名：

text
{序号:3位数字}-{描述性名称}.patch
序号：从001开始递增，决定补丁应用顺序

描述性名称：使用连字符分隔的简短描述，如 add-font-config

示例：

001-add-font-config.patch

002-fix-pagination.patch

003-support-unicode.patch

补丁文件格式
补丁文件使用标准 Unified Diff 格式：

patch
From a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d Mon Sep 17 00:00:00 2001
From: 作者姓名 <邮箱>
Date: 创建日期
Subject: [PATCH 序号] 补丁描述

---
 修改的文件路径 | 修改行数
 1 file changed, X insertions(+), Y deletions(-)

diff --git a/原始文件路径 b/修改后文件路径
index 哈希值..哈希值 文件权限
--- a/原始文件路径
+++ b/修改后文件路径
@@ -行号,行数 +行号,行数 @@
 原始内容
-删除的行
+新增的行
 保持不变的内容
--
2.34.1
安装和设置
1. 初始设置
bash
# 克隆或创建仓库后，在根目录执行：
mkdir -p patches

# 将补丁脚本放入 patches 目录
cp apply-patches.sh patches/
cp manage-patches.sh patches/

# 设置执行权限
chmod +x patches/*.sh
2. 集成到 GitHub Actions
更新 .github/workflows/chm-to-pdf.yml，在依赖安装步骤后添加补丁应用步骤：

yaml
- name: Apply patches
  run: |
    if [ -f "patches/apply-patches.sh" ]; then
      chmod +x patches/apply-patches.sh
      ./patches/apply-patches.sh
    fi
使用方法
1. 创建新补丁
方法一：使用管理脚本（推荐）
bash
# 1. 首先对脚本进行修改
vim scripts/chm-convert.sh

# 2. 使用管理脚本创建补丁
./patches/manage-patches.sh create "功能描述"

# 示例：创建字体配置补丁
./patches/manage-patches.sh create "add-font-config"
# 这会生成 patches/001-add-font-config.patch
方法二：手动创建
bash
# 1. 确保有未提交的修改
git status

# 2. 生成补丁文件
git diff --no-prefix scripts/chm-convert.sh > patches/001-add-font-config.patch

# 3. 添加补丁头信息
echo "From $(git rev-parse HEAD) $(date)" > temp.patch
echo "From: $(git config user.name) <$(git config user.email)>" >> temp.patch
echo "Date: $(date)" >> temp.patch
echo "Subject: [PATCH 001] 添加字体配置功能" >> temp.patch
echo "" >> temp.patch
echo "---" >> temp.patch
echo " scripts/chm-convert.sh | 10 ++++++++++" >> temp.patch
echo " 1 file changed, 10 insertions(+)" >> temp.patch
echo "" >> temp.patch
cat patches/001-add-font-config.patch >> temp.patch
mv temp.patch patches/001-add-font-config.patch
2. 应用补丁
在本地应用：
bash
# 应用所有补丁
./patches/apply-patches.sh

# 或者使用管理脚本
./patches/manage-patches.sh apply
在 GitHub Actions 中：
补丁会在工作流运行时自动应用（如果设置了相应的步骤）。

3. 管理补丁
bash
# 列出所有补丁
./patches/manage-patches.sh list

# 查看补丁详细信息
./patches/manage-patches.sh info 001-add-font-config

# 验证补丁状态（哪些已应用，哪些未应用）
./patches/manage-patches.sh verify

# 撤销特定补丁
./patches/manage-patches.sh revert 001-add-font-config

# 撤销所有补丁（恢复到原始状态）
./patches/apply-patches.sh --revert-all
4. 测试补丁
bash
# 运行测试脚本（如果存在）
./patches/test-patches.sh

# 或者手动测试
./patches/apply-patches.sh
./scripts/chm-convert.sh --help
补丁应用流程
当执行 apply-patches.sh 时：

检查环境：验证是否在正确目录，检查所需工具

创建备份：在 backups/ 目录备份原始文件

按顺序应用：按数字顺序应用所有 .patch 文件

验证结果：检查补丁是否成功应用

清理：记录应用结果，必要时恢复失败

工作流集成
基本集成
在 GitHub Actions 工作流中添加以下步骤：

yaml
steps:
  # ... 其他步骤
  
  - name: Apply patches
    id: apply-patches
    run: |
      if [ -f "patches/apply-patches.sh" ]; then
        echo "开始应用补丁..."
        chmod +x patches/apply-patches.sh
        ./patches/apply-patches.sh
        echo "补丁应用完成"
      else
        echo "未找到补丁应用脚本，跳过补丁应用"
      fi
  
  - name: Verify patches
    run: |
      echo "验证脚本完整性..."
      bash -n scripts/chm-convert.sh && echo "✓ 脚本语法正确"
      
      # 检查补丁是否成功应用
      if [ -d "patches" ]; then
        echo "补丁统计:"
        ls patches/*.patch 2>/dev/null | wc -l | xargs echo "  补丁文件数:"
      fi
条件应用
通过工作流输入参数控制是否应用补丁：

yaml
on:
  workflow_dispatch:
    inputs:
      apply_patches:
        description: '是否应用补丁'
        required: false
        default: 'true'
        type: choice
        options:
          - 'true'
          - 'false'

jobs:
  convert-chm:
    steps:
      - name: Apply patches conditionally
        if: github.event.inputs.apply_patches == 'true'
        run: |
          [ -f "patches/apply-patches.sh" ] && ./patches/apply-patches.sh
故障排除
常见问题
1. 补丁应用失败
症状：patch: **** Only garbage was found in the patch input.

原因：补丁文件格式不正确

解决：

bash
# 重新生成补丁
./patches/manage-patches.sh create "正确描述"
# 或手动修复补丁文件格式
2. 补丁冲突
症状：Hunk #1 FAILED at line 10.

原因：文件已修改，与补丁不匹配

解决：

bash
# 查看冲突
./patches/manage-patches.sh verify

# 更新补丁或解决冲突
# 方法1：更新补丁
./patches/manage-patches.sh create "更新后的功能"

# 方法2：手动解决
vim scripts/chm-convert.sh  # 手动编辑
./patches/manage-patches.sh create "解决冲突后的版本"
3. 补丁顺序问题
症状：后续补丁依赖前面的补丁

解决：确保补丁按正确顺序编号，或合并相关补丁

调试技巧
详细输出：运行补丁应用时添加 -v 参数

bash
./patches/apply-patches.sh -v
检查备份：查看 backups/ 目录中的原始文件

测试单个补丁：

bash
patch -p1 --dry-run < patches/001-add-font-config.patch
查看补丁差异：

bash
./patches/manage-patches.sh info 001-add-font-config
最佳实践
1. 补丁设计原则
单一职责：每个补丁只解决一个问题

最小修改：只修改必要的部分

描述清晰：补丁标题和描述要明确

向后兼容：确保补丁不会破坏现有功能

测试充分：应用补丁后测试所有功能

2. 版本控制
补丁文件本身应该提交到版本控制

每个补丁应有对应的提交信息

记录补丁的应用条件和依赖

3. 文档要求
对于每个补丁，应在补丁文件中包含：

补丁目的：为什么需要这个补丁

修改内容：具体修改了哪些地方

影响范围：影响哪些功能

测试要求：如何验证补丁有效

依赖关系：是否需要其他补丁先应用

4. 补丁生命周期
text
创建 → 测试 → 应用 → 验证 → 维护 → 归档
示例工作流
场景：添加新功能
识别需求：需要添加字体大小配置功能

修改脚本：编辑 scripts/chm-convert.sh

创建补丁：

bash
./patches/manage-patches.sh create "add-font-config"
测试补丁：

bash
./patches/apply-patches.sh
./scripts/chm-convert.sh --test
提交补丁：

bash
git add patches/001-add-font-config.patch
git commit -m "添加字体配置功能补丁"
git push
验证效果：在 GitHub Actions 中运行工作流，确认功能正常

场景：修复问题
报告问题：发现 PDF 分页有问题

分析原因：确定问题在 split-pdf.sh 中

创建修复补丁：

bash
./patches/manage-patches.sh create "fix-page-split"
紧急应用：如果问题紧急，可以直接应用补丁：

bash
./patches/apply-patches.sh
高级功能
1. 补丁依赖管理
在补丁文件中添加依赖声明：

patch
# Depends: 001-add-font-config
# Conflicts: 002-old-feature
2. 条件补丁
创建只在特定条件下应用的补丁：

bash
# 在 apply-patches.sh 中添加条件判断
if [ "$FEATURE_FLAG" = "true" ]; then
    patch -p1 < patches/003-experimental-feature.patch
fi
3. 补丁回滚计划
对于可能引起问题的补丁，制定回滚计划：

bash
# 创建回滚脚本
cat > patches/rollback-plan.md << EOF
## 回滚计划：001-add-font-config

如果字体配置导致问题：
1. 撤销补丁：./patches/manage-patches.sh revert 001-add-font-config
2. 验证恢复：运行测试套件
3. 更新文档：标记功能为实验性

回滚后影响：
- 字体大小将恢复默认值
- 用户自定义设置将被忽略
EOF
相关文件
1. apply-patches.sh
主要功能：

自动应用所有补丁

备份原始文件

处理补丁冲突

生成应用报告

2. manage-patches.sh
主要功能：

创建新补丁

查看补丁信息

管理补丁生命周期

验证补丁状态

3. 工作流配置文件
位置：.github/workflows/chm-to-pdf.yml

集成补丁应用的步骤配置。

支持与贡献
获取帮助
查看本文档的故障排除部分

检查 GitHub Issues 中的已知问题

在工作流日志中查看详细错误信息

报告问题
如果发现补丁系统的问题，请提供：

补丁文件内容

错误信息

环境信息（GitHub Actions 或本地）

复现步骤

贡献补丁
欢迎提交改进补丁系统的补丁！

Fork 仓库

创建功能分支

提交补丁

创建 Pull Request

版本历史
版本	日期	说明
1.0.0	2024-01-15	初始版本，支持基本补丁功能
1.1.0	2024-01-20	添加补丁管理脚本和测试功能
1.2.0	2024-02-01	集成 GitHub Actions，添加条件应用
许可证
补丁系统遵循与主项目相同的许可证（MIT）。

注意：补丁系统设计为非侵入式更新机制。应用补丁后，原始脚本文件将被修改。所有修改都会在 backups/ 目录中保留备份，以便需要时恢复。