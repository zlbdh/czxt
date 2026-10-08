param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path)

# Claude Code PreToolUse adapter (PROP-038 / issue CG / security and privacy rules / PROP-001 Class C path warning):
# (1) Edit/Write of suspected structured keys or credentials to non-.env files uses permissionDecision=ask for confirmation.
# (2) PROP-001: writes under Docs/6-历史归档/ at any depth, or to an existing historical APK under apk/, use permissionDecision=ask for the Class C boundary.
# Design: ASK only, never deny, to avoid false blocks. Require structured keys of length {20,} to avoid matching abbreviated documentation examples such as "sk-ant-...".
# .env and .env.local are allowed secret locations. Fail safe throughout: uncertainty or errors continue.

$ErrorActionPreference = "Stop"
try {
  $utf8 = [System.Text.UTF8Encoding]::new($false)
  [Console]::InputEncoding = $utf8
  [Console]::OutputEncoding = $utf8
  $OutputEncoding = $utf8
} catch {}

function Ask {
  param([string]$reason)
  [ordered]@{
    hookSpecificOutput = [ordered]@{
      hookEventName = "PreToolUse"
      permissionDecision = "ask"
      permissionDecisionReason = $reason
    }
  } | ConvertTo-Json -Depth 6 -Compress
  exit 0
}

# PROP-001 Class C path check: return a reason for ask on a match, otherwise $null to continue. Catch errors and return $null.
function Get-PathClassCReason {
  param([string]$FilePath, [string]$RepoRoot)
  try {
    if ([string]::IsNullOrWhiteSpace($FilePath)) { return $null }
    $fpN = ([string]$FilePath) -replace '\\', '/'
    # Class C: preserve historical archives under Docs/6-历史归档/ at any depth; ask for both creation and modification.
    if ($fpN -match '(^|/)Docs/6-历史归档/') {
      return "Write targets the historical archive Docs/6-历史归档/: $FilePath. Class C rules prohibit changing archived content; preserve the historical archive. If a change is necessary, follow PROP/ADR; otherwise cancel."
    }
    # Class C: ask before modifying an existing historical APK under apk/; allow creation of a new file.
    if ($fpN -match '(^|/)apk/') {
      $abs = $null
      try {
        if ([System.IO.Path]::IsPathRooted($FilePath)) {
          $abs = [System.IO.Path]::GetFullPath($FilePath)
        } elseif (-not [string]::IsNullOrWhiteSpace($RepoRoot)) {
          $abs = [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $FilePath))
        } else {
          $abs = [System.IO.Path]::GetFullPath($FilePath)
        }
      } catch { $abs = $null }
      if ($abs -and (Test-Path -LiteralPath $abs -PathType Leaf)) {
        return "Write targets an existing historical APK under apk/: $FilePath. Class C rules prohibit changing existing historical APK files. If necessary, follow PROP/ADR; otherwise cancel."
      }
    }
  } catch { return $null }
  return $null
}

function Allow {
  if ($script:fp) {
    $pcReason = Get-PathClassCReason -FilePath $script:fp -RepoRoot $Root
    if ($pcReason) { Ask $pcReason }
  }
  [ordered]@{ continue = $true } | ConvertTo-Json -Compress; exit 0
}

$raw = [Console]::In.ReadToEnd()
if (-not [string]::IsNullOrEmpty($raw)) { $raw = $raw.TrimStart([char]0xFEFF) }
if ([string]::IsNullOrWhiteSpace($raw)) { Allow }
try { $e = $raw | ConvertFrom-Json } catch { Allow }

$fp = ""
try { if ($e.tool_input.file_path) { $fp = [string]$e.tool_input.file_path } } catch {}
if ([string]::IsNullOrWhiteSpace($fp)) { Allow }

# Build the proposed text from Write content or Edit new_string.
$content = ""
try {
  if ($e.tool_input.content) { $content = [string]$e.tool_input.content }
  if ($e.tool_input.new_string) { $content = $content + "`n" + [string]$e.tool_input.new_string }
} catch {}
if ([string]::IsNullOrWhiteSpace($content)) { Allow }

# .env, .env.local, and .env.*.local are permitted secret locations, usually ignored by Git; allow them.
# Tracked examples such as .env.example and .env.local.example must not contain real keys.
$fpN = $fp -replace '\\', '/'
$baseName = ($fpN -split '/')[-1]
if ($baseName -match '^\.env$|^\.env\.local$|^\.env\..+\.local$') { Allow }

# Structured secret patterns require enough characters to avoid abbreviated documentation examples.
$patterns = @(
  'sk-ant-[A-Za-z0-9_\-]{20,}',
  'sk-[A-Za-z0-9]{32,}',
  'AKIA[0-9A-Z]{16}',
  '-----BEGIN [A-Z ]*PRIVATE KEY-----'
)
$hit = $null
foreach ($p in $patterns) { if ($content -match $p) { $hit = $p; break } }
if (-not $hit) { Allow }

$reason = "Suspected key or credential would be written to a non-.env file: $fp (matched pattern $hit). Issue CG and security/privacy rules prohibit secrets in tracked files or documentation. Placeholders and examples may proceed; store real keys in .env.local."
[ordered]@{
  hookSpecificOutput = [ordered]@{
    hookEventName = "PreToolUse"
    permissionDecision = "ask"
    permissionDecisionReason = $reason
  }
} | ConvertTo-Json -Depth 6 -Compress
