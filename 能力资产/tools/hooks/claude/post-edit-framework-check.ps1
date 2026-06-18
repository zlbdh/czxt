param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path)

# Claude Code PostToolUse 适配器（PROP-038）：Edit/Write 改 framework/PM 工作区/治理入口后，跑 readme-index 快检，
# 仅在索引漂移时非阻塞提醒（systemMessage）；普通业务代码静默放行，触碰 {{APP_REPO_DIR}}/src 红/软区大文件时仅软提醒。
# 全程 fail-safe：任何不确定 / 出错都输出 {continue:true}，绝不 block 写操作（PostToolUse 误 block 会很扰）。

$ErrorActionPreference = "Stop"
try {
  $utf8 = [System.Text.UTF8Encoding]::new($false)
  [Console]::InputEncoding = $utf8
  [Console]::OutputEncoding = $utf8
  $OutputEncoding = $utf8
} catch {}

function Pass {
  param($msg)
  $o = [ordered]@{ continue = $true }
  if ($msg) { $o.systemMessage = $msg }
  $o | ConvertTo-Json -Depth 5 -Compress
  exit 0
}

$raw = [Console]::In.ReadToEnd()
if (-not [string]::IsNullOrEmpty($raw)) { $raw = $raw.TrimStart([char]0xFEFF) }  # 防个别宿主在 stdin 头塞 BOM 导致 JSON 解析失败
if ([string]::IsNullOrWhiteSpace($raw)) { Pass }
try { $e = $raw | ConvertFrom-Json } catch { Pass }

$fp = ""
try { if ($e.tool_input.file_path) { $fp = [string]$e.tool_input.file_path } } catch {}
if ([string]::IsNullOrWhiteSpace($fp)) { Pass }

$p4bMsg = $null
try {
  $p4bHelper = Join-Path $Root "能力资产\tools\hooks\shared\p4b-touch-warning.ps1"
  if (Test-Path -LiteralPath $p4bHelper -PathType Leaf) {
    . $p4bHelper
    $p4bMsg = Get-P4bTouchedWarning -Root $Root -Paths @($fp)
  }
} catch {
  $p4bMsg = $null
}

# 仅对 framework / PM 工作区 / 治理入口文件触发（含 Docs/3、Docs/7、根状态/README/AGENTS/TASKS）
$rootN = ([System.IO.Path]::GetFullPath($Root) -replace '\\', '/').TrimEnd('/')
try {
  if ([System.IO.Path]::IsPathRooted($fp)) {
    $fpAbsN = ([System.IO.Path]::GetFullPath($fp) -replace '\\', '/')
  } else {
    $fpAbsN = ([System.IO.Path]::GetFullPath((Join-Path $Root $fp)) -replace '\\', '/')
  }
} catch {
  $fpAbsN = $fp -replace '\\', '/'
}
$rel = $fpAbsN
if ($fpAbsN.StartsWith($rootN, [System.StringComparison]::OrdinalIgnoreCase)) {
  $rel = $fpAbsN.Substring($rootN.Length).TrimStart('/')
}
$isFw = $rel.StartsWith("操作系统/", [System.StringComparison]::OrdinalIgnoreCase) -or
        $rel.StartsWith("能力资产/", [System.StringComparison]::OrdinalIgnoreCase) -or
        $rel.StartsWith("确认改动/", [System.StringComparison]::OrdinalIgnoreCase) -or
        $rel.StartsWith("交接区/", [System.StringComparison]::OrdinalIgnoreCase) -or
        $rel.StartsWith("PM工作区/", [System.StringComparison]::OrdinalIgnoreCase) -or
        $rel.StartsWith("Docs/3-开发文档/", [System.StringComparison]::OrdinalIgnoreCase) -or
        $rel.StartsWith("Docs/7-复盘/", [System.StringComparison]::OrdinalIgnoreCase) -or
        ($rel -in @("状态.md", "CHANGELOG.md", "README.md", "AGENTS.md", "TASKS.md"))
if (-not $isFw) { Pass $p4bMsg }

try {
  $checker = Join-Path $Root "能力资产\tools\scripts\check-readme-indexes.ps1"
  if (-not (Test-Path -LiteralPath $checker)) { Pass $p4bMsg }
  # 原生子进程调用：临时降 EAP 防 PS5.1 stderr 误终止（已知技术约束 #12），真实成败看 $LASTEXITCODE
  $prev = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $checker 2>&1
  $code = $LASTEXITCODE
  $ErrorActionPreference = $prev
  if ($code -eq 0) { Pass $p4bMsg }
  $txt = ($out -join ' ')
  if ($txt.Length -gt 220) { $txt = $txt.Substring(0, 220) }
  $msg = "🟡 改 framework 后 readme-index 快检发现索引漂移，收尾前请跑完整体检并修：" + $txt
  if ($p4bMsg) { $msg = "$msg `n$p4bMsg" }
  Pass $msg
} catch {
  Pass $p4bMsg
}
