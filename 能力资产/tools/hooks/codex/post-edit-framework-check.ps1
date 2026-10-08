param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path)

# Codex PostToolUse adapter (PROP-038), sharing logic with claude/post-edit-framework-check.ps1.
# After Edit/Write/apply_patch changes framework, PM workspace, or governance entries, run readme-index. Only drift produces a soft warning through additionalContext and systemMessage, using the verified SessionStart injection mechanism.
# Ordinary business code passes silently; large red/advisory files under {{APP_REPO_DIR}}/src receive a soft warning. Fail safe: uncertainty or errors return {continue:true}, never block.

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

# Read file_path defensively; parse patch headers for tools such as apply_patch that lack a separate file_path.
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
  $msg = "🟡 The readme-index quick check found index drift after framework edits. Run the full health check and fix it before completion:" + $txt
  if ($p4bMsg) { $msg = "$msg `n$p4bMsg" }
  Pass $msg
} catch {
  Pass $p4bMsg
}
