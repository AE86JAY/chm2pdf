# 字体大小修复补丁说明

## 问题分析

虽然wkhtmltopdf参数问题已经解决，但字体大小修改仍然没有生效。主要原因是：

1. **CSS优先级问题**：CHM文件中的内联样式或HTML标签可能覆盖了我们的CSS设置
2. **样式覆盖不足**：原有的CSS样式没有足够的`!important`规则来强制覆盖
3. **特定元素未覆盖**：某些特定元素（如标题、代码块等）可能需要单独设置

## 解决方案

### 补丁1：增强CSS字体控制

已创建补丁文件增强CSS样式控制：

1. **添加`!important`规则**：确保字体大小设置在所有情况下都能生效
2. **全局覆盖**：使用`*`选择器强制覆盖所有元素的字体大小
3. **特定元素增强**：为标题、代码、表格等特定元素设置专门的字体大小
4. **内联样式覆盖**：添加针对内联样式的特殊处理

### 补丁2：创建字体大小增强脚本

已创建`patches/apply-font-enhancement.sh`脚本，包含：

1. **自动备份**：备份原脚本到`scripts/chm-convert.sh.backup-font-enhancement`
2. **补丁应用**：尝试使用patch命令应用补丁
3. **手动修改**：如果patch不可用，使用sed进行手动修改
4. **验证机制**：验证修改是否成功应用

## 应用方法

### 方法1：直接运行补丁脚本
```bash
chmod +x patches/apply-font-enhancement.sh
./patches/apply-font-enhancement.sh
```

### 方法2：手动应用修改
如果补丁脚本运行失败，可以手动修改`scripts/chm-convert.sh`文件中的CSS部分：

1. 在`<style>`标签内添加强制字体大小控制
2. 为所有CSS属性添加`!important`规则
3. 添加针对特定元素的字体大小设置

## 修改内容

### 增强的CSS样式包括：

1. **全局字体控制**：
   ```css
   * {
       font-size: ${FONT_SIZE}pt !important;
   }
   ```

2. **标题字体增强**：
   ```css
   h1 { font-size: calc(${FONT_SIZE}pt + 6pt) !important; }
   h2 { font-size: calc(${FONT_SIZE}pt + 4pt) !important; }
   h3 { font-size: calc(${FONT_SIZE}pt + 2pt) !important; }
   ```

3. **特定元素覆盖**：
   - 段落、代码、表格、列表等元素
   - 内联样式覆盖
   - CHM特定类名处理

## 预期效果

应用此补丁后，字体大小设置应该能够：

1. **强制生效**：通过`!important`规则确保字体大小设置不被覆盖
2. **全面覆盖**：覆盖所有HTML元素和CHM特定内容
3. **保持可读性**：标题和代码等元素保持适当的字体大小比例

## 验证方法

1. 运行GitHub Actions workflow
2. 检查"Process CHM files"步骤是否成功完成
3. 下载生成的PDF文件验证字体大小
4. 查看PDF中的文本是否按照设置的字体大小显示

## 备份文件

- 原脚本备份：`scripts/chm-convert.sh.backup-font-enhancement`
- 补丁文件：`patches/font-size-enhancement.patch`
- 应用脚本：`patches/apply-font-enhancement.sh`

## 注意事项

1. 此补丁主要针对CSS样式控制，不涉及wkhtmltopdf命令行参数
2. 如果仍然无效，可能需要考虑其他PDF生成工具
3. 建议在应用补丁后重新运行workflow进行测试