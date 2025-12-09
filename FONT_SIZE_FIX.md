# 字体大小修复说明

## 问题描述
在GitHub Actions的workflow中，虽然设置了字体大小参数，但在CHM转PDF的转换过程中，字体大小设置没有正确应用，生成的PDF文件仍然使用默认的字体大小。

## 修复内容
1. 备份了原始脚本文件到 `backups/` 目录
2. 修改了两个转换脚本以正确应用字体大小设置

### 修改的文件

#### 1. scripts/chm-convert.sh
- 在 `wkhtmltopdf` 命令中添加了 `--default-font-size` 参数
- 确保字体大小变量正确传递到Python脚本中

#### 2. scripts/chm-convert-simple.sh
- 添加了从环境变量读取字体大小的代码
- 将 `ebook-convert` 命令中的硬编码字体大小(12pt)替换为从环境变量读取的 `FONT_SIZE` 变量
- 添加了字体大小有效性验证

## 备份文件
- `backups/chm-convert.sh.backup` - 原始 chm-convert.sh 文件的备份
- `backups/chm-convert-simple.sh.backup` - 原始 chm-convert-simple.sh 文件的备份

## 验证方法
1. 在GitHub Actions中设置不同的字体大小参数(如8pt, 16pt, 24pt)
2. 运行workflow并检查生成的PDF文件的字体大小是否符合设置
3. 可以通过查看PDF文件的属性或直接打开PDF文件来验证字体大小

## 注意事项
- 字体大小有效范围为8-24pt，超出此范围的值将被重置为默认值12pt
- 如果未设置字体大小参数，将使用默认值12pt