param(
  [ValidateSet("Check", "Apply")]
  [string]$Mode = "Check",
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
)

$ErrorActionPreference = "Stop"
try {
  $consoleUtf8 = New-Object System.Text.UTF8Encoding($false)
  [Console]::InputEncoding = $consoleUtf8
  [Console]::OutputEncoding = $consoleUtf8
  $OutputEncoding = $consoleUtf8
} catch {
}
. (Join-Path $PSScriptRoot "..\scripts\check-os\framework-scope.ps1")

$repoPath = Join-Path $Root "{{APP_REPO_DIR}}"
$hooksDir = Join-Path $repoPath ".git\hooks"
$isTemplateRoot = Test-IsTemplateRoot -Root $Root

if (-not (Test-Path -LiteralPath $hooksDir)) {
  if ($isTemplateRoot -and $Mode -eq "Check") {
    Write-Host "🔎 hooks installer check (template root mode)"
    Write-Host "  🟡 The template root has not instantiated {{APP_REPO_DIR}}; skip the business repository .git/hooks check"
    exit 5
  }
  throw "Hooks directory not found: $hooksDir"
}

# Wrapper template: a literal single-quoted here-string prevents PowerShell from expanding shell $ values. Replace __TRIGGER__ afterward.
$wrapperTemplate = @'
#!/bin/sh
ROOT_POSIX="$(cd "$(dirname "$0")/../../.." && pwd)"
if command -v cygpath >/dev/null 2>&1; then
  ROOT="$(cygpath -w "$ROOT_POSIX")"
elif command -v wslpath >/dev/null 2>&1; then
  ROOT="$(wslpath -w "$ROOT_POSIX")"
else
  ROOT="$ROOT_POSIX"
fi
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$ROOT/能力资产/tools/hooks/run-hooks.ps1" -Trigger __TRIGGER__ -Mode Check -Root "$ROOT"
exit $?
'@

# Git lifecycle wrappers: pre-commit checks index/ADR consistency; pre-push runs the vitest/build release gate.
$triggers = @("pre-commit", "pre-push")
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

if ($Mode -eq "Check") {
  Write-Host "🔎 hooks installer check（pre-commit + pre-push wrapper）"
}

$issues = @()

foreach ($trigger in $triggers) {
  $target = Join-Path $hooksDir $trigger
  $wrapper = $wrapperTemplate.Replace("__TRIGGER__", $trigger)

  if ($Mode -eq "Check") {
    Write-Host "  target: $target"
    if (Test-Path -LiteralPath $target) {
      $existing = Get-Content -LiteralPath $target -Raw -Encoding UTF8
      if ($existing.Trim() -eq $wrapper.Trim()) {
        Write-Host "  ✅ $trigger wrapper is installed and matches"
      } else {
        Write-Host "  🟡 $trigger wrapper exists with different content (run -Mode Apply to replace it)" -ForegroundColor Yellow
        $issues += "$trigger wrapper content differs"
      }
    } else {
      Write-Host "  🟡 $trigger wrapper is not installed (run -Mode Apply to write it)" -ForegroundColor Yellow
      $issues += "$trigger wrapper is not installed"
    }
  } else {
    [System.IO.File]::WriteAllText($target, $wrapper + "`n", $utf8NoBom)
    Write-Host "  ✅ $trigger wrapper installed: $target"
  }
}

if (($Mode -eq "Check") -and ($issues.Count -gt 0)) {
  Write-Host ""
  Write-Host "🔴 hooks installer check found $($issues.Count) drift issues:" -ForegroundColor Red
  foreach ($issue in $issues) {
    Write-Host "  - $issue" -ForegroundColor Red
  }
  exit 10
}

exit 0
