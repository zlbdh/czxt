param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path)

$ErrorActionPreference = "Stop"
$failures = @()

function Add-Failure([string]$Message) {
  $script:failures += $Message
  Write-Host "  🔴 $Message" -ForegroundColor Red
}

function Read-Text([string]$Rel) {
  $path = Join-Path $Root $Rel
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    Add-Failure "smoke 语义锚点缺文件：$Rel"
    return ""
  }
  return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

$packagePath = Join-Path $Root "{{APP_REPO_DIR}}\package.json"
if (Test-Path -LiteralPath $packagePath -PathType Leaf) {
  $package = Get-Content -LiteralPath $packagePath -Raw -Encoding UTF8 | ConvertFrom-Json
  $version = "v$($package.version)"
  $strategy = Read-Text "Docs/4-测试文档/测试策略.md"
  if ($strategy -notmatch [regex]::Escape($version) -or $strategy -notmatch 'smoke-results\.md') {
    Add-Failure "测试策略未指向 package.json 当前版本 $version 的 smoke-results"
  }
}

$superseded = @(
  "Docs/4-测试文档/smoke截图/v3.18.0-recurrence第一刀/smoke-results.md",
  "Docs/4-测试文档/smoke截图/v3.34.0-F钠盐控制调味用量/smoke-results.md",
  "Docs/4-测试文档/smoke截图/v3.34.0-F钠盐控制调味用量-修复复跑/smoke-results.md",
  "Docs/4-测试文档/smoke截图/v3.34.0-F钠盐控制调味用量-第三轮/smoke-results.md",
  "Docs/4-测试文档/smoke截图/v3.36.0-G周期预约ACTION_RE补词/smoke-results.md",
  "Docs/4-测试文档/smoke截图/v3.36.0-G周期预约ACTION_RE补词-修复复跑/smoke-results.md",
  "Docs/4-测试文档/smoke截图/v3.36.0-G周期预约ACTION_RE补词-最终复跑/smoke-results.md",
  "Docs/4-测试文档/smoke截图/v3.8.1-W-3-习惯偏好集成LLM/smoke-results.md"
)

foreach ($rel in $superseded) {
  $text = Read-Text $rel
  if ($text -notmatch "历史失败轮|多轮历史记录" -or $text -notmatch "不代表当前发布状态") {
    Add-Failure "历史失败 smoke 缺 superseded 说明：$rel"
  }
}

$final336 = Read-Text "Docs/4-测试文档/smoke截图/v3.36.0-G周期预约ACTION_RE补词-yearly加固第五轮/smoke-results.md"
if ($final336 -notmatch "最终发布轮" -or $final336 -notmatch "commit/tag/push 完成") {
  Add-Failure "v3.36.0 第五轮 smoke 未声明最终发布轮"
}

if ($failures.Count -gt 0) { exit 10 }
Write-Host "  ✅ smoke 历史语义锚点对齐"
exit 0
