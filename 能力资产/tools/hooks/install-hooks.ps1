param(
  [ValidateSet("Check", "Apply")]
  [string]$Mode = "Check",
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "..\scripts\check-os\framework-scope.ps1")

$repoPath = Join-Path $Root "{{APP_REPO_DIR}}"
$hooksDir = Join-Path $repoPath ".git\hooks"
$isTemplateRoot = Test-IsTemplateRoot -Root $Root

if (-not (Test-Path -LiteralPath $hooksDir)) {
  if ($isTemplateRoot -and $Mode -eq "Check") {
    Write-Host "🔎 hooks installer check（模板根模式）"
    Write-Host "  🟡 模板根未实例化 {{APP_REPO_DIR}}，跳过业务仓库 .git/hooks 检查"
    exit 5
  }
  throw "找不到 hooks 目录：$hooksDir"
}

# wrapper 模板（单引号 here-string = 字面，shell $ 不被 PowerShell 解析）；__TRIGGER__ 占位后替换。
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

# 接入的 git lifecycle wrapper：pre-commit（索引/ADR 一致性）+ pre-push（发布门禁 vitest+build）
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
        Write-Host "  ✅ $trigger wrapper 已安装且一致"
      } else {
        Write-Host "  🟡 $trigger wrapper 已存在但内容不同（运行 -Mode Apply 覆盖）" -ForegroundColor Yellow
        $issues += "$trigger wrapper 内容不同"
      }
    } else {
      Write-Host "  🟡 $trigger wrapper 尚未安装（运行 -Mode Apply 写入）" -ForegroundColor Yellow
      $issues += "$trigger wrapper 尚未安装"
    }
  } else {
    [System.IO.File]::WriteAllText($target, $wrapper + "`n", $utf8NoBom)
    Write-Host "  ✅ $trigger wrapper 已安装：$target"
  }
}

if (($Mode -eq "Check") -and ($issues.Count -gt 0)) {
  Write-Host ""
  Write-Host "🔴 hooks installer check 发现 $($issues.Count) 项漂移：" -ForegroundColor Red
  foreach ($issue in $issues) {
    Write-Host "  - $issue" -ForegroundColor Red
  }
  exit 10
}

exit 0
