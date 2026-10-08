param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path)

# Claude Code PostToolUse adapter (PROP-038): after Edit/Write changes framework, PM workspace, or governance entries, run the readme-index quick check.
# Warn through systemMessage only when indexes drift. Ordinary business code passes silently; large red/advisory files under {{APP_REPO_DIR}}/src receive a soft warning.
# Fail safe throughout: uncertainty or errors return {continue:true}; never block writes, since false PostToolUse blocks disrupt work.

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
if (-not [string]::IsNullOrEmpty($raw)) { $raw = $raw.TrimStart([char]0xFEFF) }  # Strip a leading stdin BOM from hosts that would otherwise cause JSON parsing to fail.
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

# Trigger only for framework, PM workspace, or governance entries, including Docs/3, Docs/7, and root status/README/AGENTS/TASKS.
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
  # Native subprocess: temporarily lower EAP to avoid PS5.1 stderr termination (known constraint #12); use $LASTEXITCODE as the outcome.
  $prev = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $checker 2>&1
  $code = $LASTEXITCODE
  $ErrorActionPreference = $prev
  if ($code -eq 0) { Pass $p4bMsg }
  $txt = ($out -join ' ')
  if ($txt.Length -gt 220) { $txt = $txt.Substring(0, 220) }
  $msg = "🟡 The readme-index quick check found index drift after framework edits. Run the full health check and fix it before completion:" + $txt
  if ($p4bMsg) { $msg = "$msg `n$p4bMsg" }
  Pass $msg
} catch {
  Pass $p4bMsg
}
