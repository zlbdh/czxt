param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path)

# Codex PreToolUse 适配器（PROP-038 镜像 / 与 claude/pre-write-guard.ps1 同源逻辑 + PROP-001 / 路径 C 类铁律软门禁）：
# (1) Edit/Write/apply_patch 若往「非 .env」文件写疑似密钥（结构化 key 模式）时，经 additionalContext 软提醒 Codex 模型确认。
# (2) PROP-001：写「Docs/6-历史归档/」（任意层级）或「已存在的 apk/ 历史 APK」时，同样经 additionalContext 软提醒（兜底 C 类铁律）。
# ⚠️ 与 Claude 版差异：Claude 用 permissionDecision=ask（真弹确认）；Codex 侧权限决策格式未核实，
#    故采用 Codex 已验证可靠的 additionalContext 软警告（注入上下文让模型自行复核），**非硬 block**，更保守。
#    PROP-001 的路径裁决在 Codex 侧亦走同一 additionalContext 软警告路径（不照搬 Claude 的 permissionDecision）。
# 全程 fail-safe：任何不确定/出错都放行（continue）。只认 {20,}+ 长度结构化 key（避免文档省略号误报）。

$ErrorActionPreference = "Stop"
try {
  $utf8 = [System.Text.UTF8Encoding]::new($false)
  [Console]::InputEncoding = $utf8
  [Console]::OutputEncoding = $utf8
  $OutputEncoding = $utf8
} catch {}

function Warn {
  param($ctx)
  [ordered]@{
    continue = $true
    systemMessage = $ctx
    hookSpecificOutput = [ordered]@{ hookEventName = "PreToolUse"; additionalContext = $ctx }
  } | ConvertTo-Json -Depth 6 -Compress
  exit 0
}

# PROP-001 路径 C 类裁决：对一组候选路径求是否命中（历史归档 / 已存在 apk）；命中返回软警告文案，否则 $null。
# Codex 侧按各自契约走 Warn（additionalContext 软警告），不照搬 Claude 的 permissionDecision。全程 fail-safe：异常吞掉返回 $null。
function Get-CodexPathClassCReason {
  param([string[]]$Candidates, [string]$RepoRoot)
  try {
    foreach ($cand in @($Candidates)) {
      if ([string]::IsNullOrWhiteSpace($cand)) { continue }
      $fpN = ([string]$cand) -replace '\\', '/'
      # C 类：历史归档不动（Docs/6-历史归档/ 任意层级）；新建/修改都软提醒。
      if ($fpN -match '(^|/)Docs/6-历史归档/') {
        return "⚠️ 写入命中『Docs/6-历史归档/』历史归档区：$cand。按三类行为铁律 C 类『改 Docs/6-历史归档/ 已归档的内容（历史就是历史）』——历史归档不动。若确属必要改动请走 PROP/ADR，否则请放弃此次写入。"
      }
      # C 类：改 apk/ 下已存在的历史 APK；仅「修改已存在」才软提醒，新建放行。
      if ($fpN -match '(^|/)apk/') {
        $abs = $null
        try {
          if ([System.IO.Path]::IsPathRooted($cand)) {
            $abs = [System.IO.Path]::GetFullPath($cand)
          } elseif (-not [string]::IsNullOrWhiteSpace($RepoRoot)) {
            $abs = [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $cand))
          } else {
            $abs = [System.IO.Path]::GetFullPath($cand)
          }
        } catch { $abs = $null }
        if ($abs -and (Test-Path -LiteralPath $abs -PathType Leaf)) {
          return "⚠️ 写入命中 apk/ 下已存在的历史 APK：$cand。按三类行为铁律 C 类『改 apk/ 下已存在的历史 APK 文件（历史归档不动）』。若确属必要请走 PROP/ADR，否则请放弃此次写入。"
        }
      }
    }
  } catch { return $null }
  return $null
}

function Allow {
  try {
    if ($script:paths -and $script:paths.Count -gt 0) {
      $pcReason = Get-CodexPathClassCReason -Candidates @($script:paths) -RepoRoot $Root
      if ($pcReason) { Warn $pcReason }
    }
  } catch {}
  [ordered]@{ continue = $true } | ConvertTo-Json -Compress; exit 0
}

$raw = [Console]::In.ReadToEnd()
if (-not [string]::IsNullOrEmpty($raw)) { $raw = $raw.TrimStart([char]0xFEFF) }
if ([string]::IsNullOrWhiteSpace($raw)) { Allow }
try { $e = $raw | ConvertFrom-Json } catch { Allow }

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

$content = ""
try {
  foreach ($cand in @($e.tool_input.content, $e.tool_input.new_string, $e.tool_input.patch, $e.tool_input.input, $e.tool_input.command, $e.content, $e.arguments.content, $e.arguments.patch, $e.arguments.input)) {
    if ($cand) { $content = $content + "`n" + [string]$cand }
  }
  if ($e.tool_input -is [string]) { $content = $content + "`n" + [string]$e.tool_input }
} catch {}
if ([string]::IsNullOrWhiteSpace($content)) { Allow }

foreach ($m in [regex]::Matches($content, '(?m)^\*\*\*\s+(?:Add|Update|Delete)\s+File:\s+(.+?)\s*$')) {
  Add-CandidatePath $m.Groups[1].Value
}
foreach ($m in [regex]::Matches($content, '(?m)^\*\*\*\s+Move\s+to:\s+(.+?)\s*$')) {
  Add-CandidatePath $m.Groups[1].Value
}
if ($paths.Count -eq 0) { Allow }

$nonEnvPaths = @()
foreach ($path in $paths) {
  $fpN = ([string]$path) -replace '\\', '/'
  $baseName = ($fpN -split '/')[-1]
  if ($baseName -notmatch '^\.env$|^\.env\.local$|^\.env\..+\.local$') { $nonEnvPaths += [string]$path }
}
if ($nonEnvPaths.Count -eq 0) { Allow }

$patterns = @(
  'sk-ant-[A-Za-z0-9_\-]{20,}',
  'sk-[A-Za-z0-9]{32,}',
  'AKIA[0-9A-Z]{16}',
  '-----BEGIN [A-Z ]*PRIVATE KEY-----'
)
$hit = $null
foreach ($p in $patterns) { if ($content -match $p) { $hit = $p; break } }
if (-not $hit) { Allow }

Warn ("⚠️ 疑似密钥/凭据将写入非 .env 文件：$($nonEnvPaths -join ', ')（命中模式 $hit）。按议题 CG + 安全与隐私铁律：密钥不进 git tracked 文件 / 不贴文档。若是占位或示例可继续；真实密钥请改放 .env.local 后再写。")
