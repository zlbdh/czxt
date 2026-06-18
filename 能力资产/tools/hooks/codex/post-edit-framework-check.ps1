param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path)

# Codex PostToolUse 适配器（PROP-038 镜像 / 与 claude/post-edit-framework-check.ps1 同源逻辑）：
# Edit/Write/apply_patch 改 framework/PM 工作区/治理入口后跑 readme-index 快检，**仅漂移时**经 additionalContext（Codex 可靠读取，同 SessionStart 注入）+ systemMessage 软提醒。
# 普通业务代码静默放行；触碰 {{APP_REPO_DIR}}/src 红/软区大文件时仅软提醒。全程 fail-safe：任何不确定/出错都 {continue:true}，绝不 block。

$ErrorActionPreference = "Stop"
try {
  $utf8 = [System.Text.UTF8Encoding]::new($false)
  [Console]::InputEncoding = $utf8
  [Console]::OutputEncoding = $utf8
  $OutputEncoding = $utf8
} catch {}

function Pass {
  param($ctx)
  $o = [ordered]@{ continue = $true }
  if ($ctx) {
    $o.systemMessage = $ctx
    $o.hookSpecificOutput = [ordered]@{ hookEventName = "PostToolUse"; additionalContext = $ctx }
  }
  $o | ConvertTo-Json -Depth 6 -Compress
  exit 0
}

$raw = [Console]::In.ReadToEnd()
if (-not [string]::IsNullOrEmpty($raw)) { $raw = $raw.TrimStart([char]0xFEFF) }
if ([string]::IsNullOrWhiteSpace($raw)) { Pass }
try { $e = $raw | ConvertFrom-Json } catch { Pass }

# 健壮读取 file_path；apply_patch 这类工具没有单独 file_path 时，从 patch header 解析路径。
$paths = New-Object System.Collections.Generic.List[string]
function Add-CandidatePath {
  param($Value)
  if ($Value) {
    $s = [string]$Value
    if (-not [string]::IsNullOrWhiteSpace($s)) { $script:paths.Add($s.Trim()) | Out-Null }
  }
}
try {
  foreach ($cand in @($e.tool_input.file_path, $e.tool_input.path, $e.file_path, $e.arguments.file_path, $e.params.file_path)) {
    Add-CandidatePath $cand
  }
} catch {}

$patchText = ""
try {
  foreach ($cand in @($e.tool_input.patch, $e.tool_input.input, $e.tool_input.command, $e.arguments.patch, $e.arguments.input)) {
    if ($cand) { $patchText = $patchText + "`n" + [string]$cand }
  }
  if ($e.tool_input -is [string]) { $patchText = $patchText + "`n" + [string]$e.tool_input }
} catch {}
if (-not [string]::IsNullOrWhiteSpace($patchText)) {
  foreach ($m in [regex]::Matches($patchText, '(?m)^\*\*\*\s+(?:Add|Update|Delete)\s+File:\s+(.+?)\s*$')) {
    Add-CandidatePath $m.Groups[1].Value
  }
  foreach ($m in [regex]::Matches($patchText, '(?m)^\*\*\*\s+Move\s+to:\s+(.+?)\s*$')) {
    Add-CandidatePath $m.Groups[1].Value
  }
}
if ($paths.Count -eq 0) { Pass }

$p4bMsg = $null
try {
  $p4bHelper = Join-Path $Root "能力资产\tools\hooks\shared\p4b-touch-warning.ps1"
  if (Test-Path -LiteralPath $p4bHelper -PathType Leaf) {
    . $p4bHelper
    $p4bMsg = Get-P4bTouchedWarning -Root $Root -Paths @($paths)
  }
} catch {
  $p4bMsg = $null
}

$rootN = ([System.IO.Path]::GetFullPath($Root) -replace '\\', '/').TrimEnd('/')
function Test-FrameworkPath {
  param([string]$Path)
  try {
    if ([System.IO.Path]::IsPathRooted($Path)) {
      $fpAbsN = ([System.IO.Path]::GetFullPath($Path) -replace '\\', '/')
    } else {
      $fpAbsN = ([System.IO.Path]::GetFullPath((Join-Path $Root $Path)) -replace '\\', '/')
    }
  } catch {
    $fpAbsN = $Path -replace '\\', '/'
  }
  $rel = $fpAbsN
  if ($fpAbsN.StartsWith($rootN, [System.StringComparison]::OrdinalIgnoreCase)) {
    $rel = $fpAbsN.Substring($rootN.Length).TrimStart('/')
  }
  return ($rel.StartsWith("操作系统/", [System.StringComparison]::OrdinalIgnoreCase) -or
          $rel.StartsWith("能力资产/", [System.StringComparison]::OrdinalIgnoreCase) -or
          $rel.StartsWith("确认改动/", [System.StringComparison]::OrdinalIgnoreCase) -or
          $rel.StartsWith("交接区/", [System.StringComparison]::OrdinalIgnoreCase) -or
          $rel.StartsWith("PM工作区/", [System.StringComparison]::OrdinalIgnoreCase) -or
          $rel.StartsWith("Docs/3-开发文档/", [System.StringComparison]::OrdinalIgnoreCase) -or
          $rel.StartsWith("Docs/7-复盘/", [System.StringComparison]::OrdinalIgnoreCase) -or
          ($rel -in @("状态.md", "CHANGELOG.md", "README.md", "AGENTS.md", "TASKS.md")))
}
$isFw = $false
foreach ($path in $paths) {
  if (Test-FrameworkPath $path) { $isFw = $true; break }
}
if (-not $isFw) { Pass $p4bMsg }

try {
  $checker = Join-Path $Root "能力资产\tools\scripts\check-readme-indexes.ps1"
  if (-not (Test-Path -LiteralPath $checker)) { Pass $p4bMsg }
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
