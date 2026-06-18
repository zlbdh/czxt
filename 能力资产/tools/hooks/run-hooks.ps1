param(
  [ValidateSet("manual", "pre-commit", "pre-push", "chat-output", "file-watch", "scheduled")]
  [string]$Trigger = "manual",
  [ValidateSet("Check", "Apply")]
  [string]$Mode = "Check",
  [string]$Hook = "",
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path,
  [string]$TextPath = ""
)

$ErrorActionPreference = "Stop"
$manifestPath = Join-Path $PSScriptRoot "manifest.json"
if (-not (Test-Path -LiteralPath $manifestPath)) {
  throw "找不到 hooks manifest：$manifestPath"
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$selected = @($manifest.hooks | Where-Object {
  ($_.triggers -contains $Trigger) -and ([string]::IsNullOrWhiteSpace($Hook) -or $_.id -eq $Hook)
})

if ($selected.Count -eq 0) {
  Write-Host "🟡 没有匹配 hooks：Trigger=$Trigger Hook=$Hook" -ForegroundColor Yellow
  if (-not [string]::IsNullOrWhiteSpace($Hook)) {
    Write-Host "🔴 显式指定的 hook 不存在或不属于该 trigger：$Hook" -ForegroundColor Red
    exit 2
  }
  exit 0
}

$failures = @()
Write-Host "🪝 hooks runner: trigger=$Trigger mode=$Mode count=$($selected.Count)"

function Resolve-HookArgs {
  param([object[]]$RawArgs)
  $resolved = @()
  for ($i = 0; $i -lt @($RawArgs).Count; $i++) {
    $arg = @($RawArgs)[$i]
    if ($arg -eq "__TEXT_PATH__") {
      if (-not [string]::IsNullOrWhiteSpace($TextPath)) {
        $resolved += $TextPath
      } elseif ($resolved.Count -gt 0 -and $resolved[$resolved.Count - 1] -eq "-TextPath") {
        $resolved = @($resolved | Select-Object -First ($resolved.Count - 1))
      }
    } elseif ($arg -eq "__ROOT__") {
      $resolved += $Root
    } else {
      $resolved += $arg
    }
  }
  return $resolved
}

foreach ($item in $selected) {
  $scriptPath = Join-Path $Root $item.script
  if (-not (Test-Path -LiteralPath $scriptPath)) {
    $failures += "$($item.id): script not found $scriptPath"
    Write-Host "  🔴 $($item.id) script not found: $scriptPath" -ForegroundColor Red
    continue
  }

  $args = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $scriptPath)
  if ($Mode -eq "Apply" -and $item.applyArgs) {
    $args += @(Resolve-HookArgs @($item.applyArgs))
  } elseif ($item.checkArgs) {
    $args += @(Resolve-HookArgs @($item.checkArgs))
  }

  Write-Host "  ▶ $($item.id): $($item.description)"
  & powershell @args
  $code = $LASTEXITCODE
  $allowed = @($item.allowExitCodes)
  if ($allowed.Count -eq 0) { $allowed = @(0) }

  if ($allowed -notcontains $code) {
    $failures += "$($item.id): exit $code"
    Write-Host "  🔴 $($item.id) failed: exit $code" -ForegroundColor Red
  } else {
    Write-Host "  ✅ $($item.id) exit $code"
  }
}

if ($failures.Count -gt 0) {
  Write-Host ""
  Write-Host "🔴 hooks runner failed: $($failures.Count)" -ForegroundColor Red
  foreach ($failure in $failures) { Write-Host "  - $failure" -ForegroundColor Red }
  exit 10
}

Write-Host "✅ hooks runner passed"
exit 0
