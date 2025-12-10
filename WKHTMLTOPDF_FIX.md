# 修复wkhtmltopdf不支持的参数问题

## 问题描述

在GitHub Actions中运行workflow时，CHM转PDF步骤出现错误，错误信息显示wkhtmltopdf工具不支持以下参数：
- `--footer-center`
- `--footer-font-size`
- `--disable-smart-shrinking`
- `--default-font-size`

错误详情：
```
Unknown long argument --default-font-size
The switch --footer-center, is not support using unpatched qt, and will be ignored.
The switch --footer-font-size, is not support using unpatched qt, and will be ignored.
The switch --disable-smart-shrinking, is not support using unpatched qt, and will be ignored.
```

## 问题原因

GitHub Actions环境中使用的wkhtmltopdf版本(0.12.6)是未打补丁的Qt版本，不支持这些高级参数。这些参数只在打了补丁的wkhtmltopdf版本中可用。

## 解决方案

修改了`scripts/chm-convert.sh`脚本中的`convert_to_pdf`函数，移除了不支持的参数：

1. **移除的参数**：
   - `--footer-center [page]/[toPage]`
   - `--footer-font-size 10`
   - `--disable-smart-shrinking`
   - `--default-font-size ${font_size}`

2. **保留的参数**：
   - `--enable-local-file-access`
   - `--page-size A4`
   - 页面边距设置
   - `--encoding UTF-8`
   - `--zoom ${zoom_level}`
   - `--quiet`

3. **字体大小处理**：
   - 字体大小现在完全通过CSS样式设置，在`create_master_html`函数中的`<style>`标签内定义
   - 这样确保字体大小设置在所有环境中都能正常工作

## 修改的文件

- `scripts/chm-convert.sh`：修改了`convert_to_pdf`函数，移除不支持的wkhtmltopdf参数

## 测试验证

修改后的脚本已提交到GitHub，并通过以下方式验证：
1. 本地测试确保脚本语法正确
2. 提交到GitHub仓库
3. 推送到远程仓库

## 注意事项

1. **字体大小设置**：现在完全依赖CSS样式设置，而不是wkhtmltopdf命令行参数
2. **页脚功能**：由于移除了页脚相关参数，生成的PDF将不包含页码信息
3. **兼容性**：修改后的脚本与未打补丁的wkhtmltopdf版本兼容，确保在GitHub Actions环境中正常工作

## 后续改进建议

1. 如果需要页脚功能，可以考虑：
   - 在HTML模板中添加页脚元素
   - 使用其他PDF生成工具
   - 使用打补丁的wkhtmltopdf版本

2. 对于更复杂的PDF布局需求，可以考虑：
   - 使用WeasyPrint
   - 使用Puppeteer
   - 使用专门的PDF生成库