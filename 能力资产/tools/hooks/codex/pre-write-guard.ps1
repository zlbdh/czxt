param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path)

# Codex PreToolUse adapter (PROP-038), sharing logic with claude/pre-write-guard.ps1 and PROP-001 Class C path warnings.
# (1) Edit/Write/apply_patch of suspected structured secrets to non-.env files supplies an additionalContext warning for model review.
# (2) PROP-001: writes under Docs/6-历史归档/ at any depth or to existing historical APKs under apk/ receive the same Class C additionalContext warning.
# Difference from Claude: Claude uses permissionDecision=ask for an actual confirmation; Codex's permission-decision format has not been verified.
# Use the verified Codex additionalContext soft warning so the model can review it; this is not a hard block.
# PROP-001 path decisions follow that same Codex warning route without copying Claude's permissionDecision format.
# Fail safe: uncertainty or errors continue. Recognize only structured keys of length {20,}+ to avoid abbreviated documentation examples.

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

# PROP-001 Class C check over candidate paths: return a warning for an archive or existing APK match, otherwise $null.
# Codex uses its own Warn/additionalContext contract, not Claude permissionDecision. Catch errors and return $null.
function Get-CodexPathClassCReason {
  param([string[]]$Candidates, [string]$RepoRoot)
  try {
    foreach ($cand in @($Candidates)) {
      if ([string]::IsNullOrWhiteSpace($cand)) { continue }
      $fpN = ([string]$cand) -replace '\\', '/'
      # Class C: preserve historical archives under Docs/6-历史归档/ at any depth; warn on both creation and modification.
      if ($fpN -match '(^|/)Docs/6-历史归档/') {
        return "⚠️ Write targets the historical archive Docs/6-历史归档/: $cand. Class C rules prohibit changing archived content; preserve the historical archive. If necessary, follow PROP/ADR; otherwise abandon this write."
      }
      # Class C: warn before modifying existing historical APKs under apk/; allow new files.
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
          return "⚠️ Write targets an existing historical APK under apk/: $cand. Class C rules prohibit changing existing historical APK files. If necessary, follow PROP/ADR; otherwise abandon this write."
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

Warn ("⚠️ Suspected key or credential would be written to non-.env files: $($nonEnvPaths -join ', ') (matched pattern $hit). Issue CG and security/privacy rules prohibit secrets in tracked files or documentation. Placeholders and examples may proceed; move real keys to .env.local before writing.")
