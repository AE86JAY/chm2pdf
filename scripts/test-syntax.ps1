# PowerShell脚本，用于测试bash脚本的基本结构

# 脚本路径
$bashScript = "d:\ming\GitHub\chm2pdf\scripts\chm-convert.sh"

# 读取文件内容
$content = Get-Content -Raw $bashScript

# 检查换行符格式
$hasCrLf = $content -match "\r\n"
$hasLfOnly = $content -match "(?<!\r)\n"

Write-Host "=== 文件格式检查 ==="
if ($hasCrLf) {
    Write-Host "  ❌ 包含Windows换行符(CRLF)"
} else {
    Write-Host "  ✅ 仅包含Unix换行符(LF)"
}

# 检查条件判断部分
Write-Host "\n=== 条件判断结构检查 ==="
$lines = Get-Content $bashScript
$inCondition = $false
$conditionLines = @()

foreach ($line in $lines) {
    if ($line -match "# 使用最基本的bash语法重新编写条件判断") {
        $inCondition = $true
        continue
    }
    if ($inCondition) {
        $conditionLines += $line
        if ($line -match "^fi$" -and $conditionLines.Count -gt 5) {
            break
        }
    }
}

Write-Host "条件判断部分（共$($conditionLines.Count)行）："
foreach ($line in $conditionLines) {
    Write-Host "  $line"
}

# 检查关键语法元素
Write-Host "\n=== 关键语法元素检查 ==="
$hasIf = $content -match 'if \[ "\$SPLIT_PAGES"'
$hasElif1 = $content -match 'elif \[ "\${PAGE_COUNT}" -eq 0 \]; then'
$hasElif2 = $content -match 'elif \[ "\$SPLIT_PAGES" -eq 0 \]; then'
$hasFi = $content -match '^fi$'

Write-Host "  if 语句: $hasIf"
Write-Host "  elif PAGE_COUNT=0: $hasElif1"
Write-Host "  elif SPLIT_PAGES=0: $hasElif2"
Write-Host "  fi 语句: $hasFi"

Write-Host "\n=== 检查完成 ==="