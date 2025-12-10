# CHM 到 PDF 自动转换工作流

这个 GitHub Actions 工作流可以自动将 CHM 文件转换为 PDF 格式，支持大文件转换、分割 PDF 文件。

本项目代码基于 [DeepSeek](https://chat.deepseek.com/) 和[Trae CN](https://www.trae.cn/) AI生成]。

## 功能特性

- ✅ **自动检测 CHM 文件** - 自动扫描 `input` 目录中的 CHM 文件
- ✅ **大文件支持** - 专门优化支持超过 20MB 的大型 CHM 文件
- ✅ **智能分割** - 当 PDF 超过 10 页时自动拆分为多个文件
- ✅ **多格式输出** - 输出文件自动编号（如 `文件名_01.pdf`、`文件名_02.pdf`）
- ✅ **多种触发方式** - 支持手动触发、文件推送触发和定时触发
- ✅ **中文支持** - 内置中文字体，支持中文 CHM 文件
- ✅ **容错处理** - 多种转换方法备选，确保转换成功率

## 快速开始

### 1. 准备工作

1. Fork 或克隆此仓库到您的 GitHub 帐户
2. 在仓库根目录创建以下结构：
   ```
   your-repo/
   ├── .github/workflows/chm-to-pdf.yml
   ├── scripts/
   │   ├── chm-convert.sh
   │   ├── split-pdf.sh
   │   └── find-chm.sh
   └── input/          (创建此目录)
   ```

### 2. 添加 CHM 文件

将您要转换的 CHM 文件放入 `input` 目录：

```bash
# 在仓库根目录执行
mkdir -p input
cp /path/to/your/file.chm input/
```

### 3. 触发转换

#### 方式一：手动触发（推荐）
1. 访问您的仓库页面
2. 点击 "Actions" 标签页
3. 选择 "CHM to PDF Converter" 工作流
4. 点击 "Run workflow" 按钮

#### 方式二：自动触发
- 推送新的 CHM 文件到 `input` 目录
- 工作流会自动运行

#### 方式三：定时触发
- 每天 UTC 时间 02:00 自动运行检查新文件

### 4. 获取结果

转换完成后：
1. 在 Actions 页面查看运行详情
2. 下载 "converted-pdfs" Artifact
3. 或查看 `output` 目录中的 PDF 文件

## 文件结构

```
.github/
└── workflows/
    └── chm-to-pdf.yml    # GitHub Actions 工作流定义

scripts/
├── chm-convert.sh        # 主转换脚本
├── split-pdf.sh          # PDF 分割脚本
└── find-chm.sh           # CHM 文件查找脚本

input/                    # 输入目录（放置 CHM 文件）
output/                   # 输出目录（生成 PDF 文件）
temp/                     # 临时目录（工作流自动创建）
```

## 输出文件命名规则

- **单文件输出**：`原文件名.pdf`
- **多文件输出**（超过 10 页时自动分割）：
  - `原文件名_01.pdf`（第 1-10 页）
  - `原文件名_02.pdf`（第 11-20 页）
  - `原文件名_03.pdf`（第 21-30 页）
  - 以此类推...

## 支持的文件大小

- ✅ **小文件**：< 50MB
- ✅ **大文件**：50MB - 200MB（推荐）
- ⚠️ **超大文件**：> 200MB（可能需要调整超时设置）

## 转换方法优先级

工作流按以下顺序尝试转换 CHM 文件：

1. **首选方法**：Calibre 的 `ebook-convert`（最稳定）
2. **备用方法 1**：解压 CHM + wkhtmltopdf 转换 HTML
3. **备用方法 2**：Python 脚本处理

## 配置选项

### 环境变量

在工作流文件中可以调整以下参数：

```yaml
env:
  INPUT_DIR: 'input'           # 输入目录
  OUTPUT_DIR: 'output'         # 输出目录
  TEMP_DIR: 'temp'             # 临时目录
  MAX_PAGES: 10                # 单个PDF最大页数
```

### 定时任务配置

修改 `.github/workflows/chm-to-pdf.yml` 中的 `schedule` 部分：

```yaml
schedule:
  # 每天 UTC 时间 02:00 运行
  - cron: '0 2 * * *'
  
  # 每小时运行
  # - cron: '0 * * * *'
  
  # 每周一 03:00 运行
  # - cron: '0 3 * * 1'
```

## 常见问题

### Q: 转换失败怎么办？
**A**: 检查以下几点：
1. 确保 CHM 文件没有损坏
2. 查看工作流运行日志获取详细错误信息
3. 尝试手动运行 `ebook-convert` 命令测试

### Q: 超大文件（>200MB）无法转换？
**A**: 可以尝试：
1. 增加 GitHub Actions 超时时间
2. 使用更轻量的转换方法（方法2）
3. 考虑先在本地转换大文件

### Q: 转换后中文显示乱码？
**A**: 系统已安装中文字体，如果仍有问题：
1. 检查源文件编码
2. 尝试在转换命令中添加 `--encoding` 参数

### Q: 如何修改分割页数？
**A**: 修改 `scripts/split-pdf.sh` 中的 `MAX_PAGES` 变量：
```bash
MAX_PAGES=20  # 改为20页
```

### Q: 工作流超时？
**A**: GitHub Actions 默认超时为 6 小时，如需更长：
```yaml
# 在 jobs 部分添加
jobs:
  convert-chm:
    timeout-minutes: 360  # 6小时
```

## 技术细节

### 使用的工具

| 工具 | 用途 | 版本 |
|------|------|------|
| Calibre | CHM 转换主力工具 | 最新版 |
| wkhtmltopdf | HTML 转 PDF | 最新版 |
| p7zip | CHM 文件解压 | 最新版 |
| poppler-utils | PDF 处理 | 最新版 |
| Python3 + PyPDF2 | PDF 分割和操作 | Python 3.x |

### 转换流程

```
CHM文件 → 检测 → 转换尝试 → PDF生成 → 页面计数 → 分割判断 → 最终输出
     ↓          ↓          ↓         ↓          ↓           ↓
  输入目录   多种方法     Calibre    pdfinfo     >10页    编号输出
```

## 故障排除

### 1. "Unable to locate package" 错误
确保使用最新的 Ubuntu 版本（工作流使用 `ubuntu-latest`）

### 2. 内存不足错误
大型 CHM 文件可能需要更多内存：
- 考虑升级到更大的 runner
- 减少并发处理文件数量

### 3. 字体显示问题
如果字体显示不正确：
```bash
# 在工作流中添加字体安装步骤
sudo apt-get install -y fonts-wqy-zenhei fonts-noto-cjk-extra
```

### 4. 超时问题
调整工作流超时设置：
```yaml
jobs:
  convert-chm:
    runs-on: ubuntu-latest
    timeout-minutes: 360  # 6小时超时
```

## 贡献指南

欢迎提交 Issue 和 Pull Request！

1. Fork 仓库
2. 创建功能分支
3. 提交更改
4. 推送到分支
5. 创建 Pull Request

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件。

## 支持

如有问题或建议：
- 提交 [Issue](https://github.com/your-username/your-repo/issues)
- 查看工作流运行日志获取详细信息
- 参考 GitHub Actions 官方文档

---

**提示**：对于非常大的 CHM 文件（>500MB），建议先在本地测试转换，确保文件可以正常处理。